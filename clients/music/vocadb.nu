# Auto-generated client for VocaDbWeb v1.0
# Source: https://api.apis.guru/v2/specs/vocadb.net/1.0/openapi.json
# Auth: --token flag or $env.VOCADBWEB_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VOCADBWEB_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def editEvent-completer [] { ["Created" "Deleted" "Restored" "Updated"] }
def entryType-completer [] { ["Album" "Artist" "DiscussionTopic" "PV" "ReleaseEvent" "ReleaseEventSeries" "Song" "SongList" "Tag" "Undefined" "User" "Venue"] }
def fields-completer [] { ["ArchivedVersion" "Entry" "None"] }
def entryFields-completer [] { ["AdditionalNames" "Description" "MainPicture" "Names" "None" "PVs" "Tags" "WebLinks"] }
def lang-completer [] { ["Default" "English" "Japanese" "Romaji"] }
def sortRule-completer [] { ["CreateDate" "CreateDateDescending"] }
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def discTypes-completer [] { ["Album" "Artbook" "Compilation" "EP" "Fanmade" "Game" "Instrumental" "Other" "Single" "SplitAlbum" "Unknown" "Video"] }
def artistParticipationStatus-completer [] { ["Everything" "OnlyCollaborations" "OnlyMainAlbums"] }
def status-completer [] { ["Approved" "Draft" "Finished" "Locked"] }
def sort-completer [] { ["AdditionDate" "CollectionCount" "Name" "NameThenReleaseDate" "None" "RatingAverage" "RatingTotal" "ReleaseDate" "ReleaseDateWithNulls"] }
def nameMatchMode-completer [] { ["Auto" "Exact" "Partial" "StartsWith" "Words"] }
def fields-completer-1 [] { ["AdditionalNames" "Artists" "Description" "Discs" "Identifiers" "MainPicture" "Names" "None" "PVs" "ReleaseEvent" "Tags" "Tracks" "WebLinks"] }
def languagePreference-completer [] { ["Default" "English" "Japanese" "Romaji"] }
def songFields-completer [] { ["AdditionalNames" "Albums" "Artists" "Bpm" "Lyrics" "MainPicture" "Names" "None" "PVs" "ReleaseEvent" "Tags" "ThumbUrl" "WebLinks"] }
def fields-completer-2 [] { ["AdditionalNames" "Albums" "Artists" "Bpm" "Lyrics" "MainPicture" "Names" "None" "PVs" "ReleaseEvent" "Tags" "ThumbUrl" "WebLinks"] }
def sort-completer-1 [] { ["AdditionDate" "AdditionDateAsc" "ArtistType" "FollowerCount" "Name" "None" "ReleaseDate" "SongCount" "SongRating"] }
def fields-completer-3 [] { ["AdditionalNames" "ArtistLinks" "ArtistLinksReverse" "BaseVoicebank" "Description" "MainPicture" "Names" "None" "Tags" "WebLinks"] }
def relations-completer [] { ["All" "LatestAlbums" "LatestEvents" "LatestSongs" "None" "PopularAlbums" "PopularSongs"] }
def fields-completer-4 [] { ["Entry" "None"] }
def fields-completer-5 [] { ["LastTopic" "None" "TopicCount"] }
def fields-completer-6 [] { ["All" "CommentCount" "Comments" "Content" "LastComment" "None"] }
def sort-completer-2 [] { ["DateCreated" "LastCommentDate" "Name" "None"] }
def entryTypes-completer [] { ["Album" "Artist" "DiscussionTopic" "Nothing" "PV" "ReleaseEvent" "ReleaseEventSeries" "Song" "SongList" "Tag" "User" "Venue"] }
def sort-completer-3 [] { ["ActivityDate" "AdditionDate" "Name" "None"] }
def fields-completer-7 [] { ["AdditionalNames" "Description" "MainPicture" "Names" "None" "PVs" "Tags" "WebLinks"] }
def fields-completer-8 [] { ["AdditionalNames" "AliasedTo" "Description" "MainPicture" "Names" "None" "Parent" "RelatedTags" "TranslatedDescription" "WebLinks"] }
def service-completer [] { ["Bandcamp" "Bilibili" "Creofuga" "File" "LocalFile" "NicoNicoDouga" "Piapro" "SoundCloud" "Vimeo" "Youtube"] }
def fields-completer-9 [] { ["AdditionalNames" "Description" "Events" "MainPicture" "Names" "None" "WebLinks"] }
def category-completer [] { ["AlbumRelease" "Anniversary" "Club" "Concert" "Contest" "Convention" "Festival" "Other" "Unspecified"] }
def sort-completer-4 [] { ["AdditionDate" "Date" "Name" "None" "SeriesName" "VenueName"] }
def fields-completer-10 [] { ["AdditionalNames" "Artists" "Description" "MainPicture" "Names" "None" "PVs" "Series" "SongList" "Tags" "Venue" "WebLinks"] }
def sortDirection-completer [] { ["Ascending" "Descending"] }
def reportType-completer [] { ["Duplicate" "Inappropriate" "InvalidInfo" "Other"] }
def featuredCategory-completer [] { ["Concerts" "Nothing" "Other" "Pools" "VocaloidRanking"] }
def sort-completer-5 [] { ["CreateDate" "Date" "Name" "None"] }
def fields-completer-11 [] { ["Description" "Events" "MainPicture" "None" "Tags"] }
def pvServices-completer [] { ["Bandcamp" "Bilibili" "Creofuga" "File" "LocalFile" "NicoNicoDouga" "Nothing" "Piapro" "SoundCloud" "Vimeo" "Youtube"] }
def sort-completer-6 [] { ["AdditionDate" "FavoritedTimes" "Name" "None" "PublishDate" "RatingScore" "SongType" "TagUsageCount"] }
def pvService-completer [] { ["Bandcamp" "Bilibili" "Creofuga" "File" "LocalFile" "NicoNicoDouga" "Piapro" "SoundCloud" "Vimeo" "Youtube"] }
def filterBy-completer [] { ["CreateDate" "Popularity" "PublishDate"] }
def vocalist-completer [] { ["Nothing" "Other" "UTAU" "Vocaloid"] }
def userFields-completer [] { ["KnownLanguages" "MainPicture" "None" "OldUsernames"] }
def rating-completer [] { ["Dislike" "Favorite" "Like" "Nothing"] }
def sort-completer-7 [] { ["AdditionDate" "Name" "Nothing" "UsageCount"] }
def target-completer [] { ["Album" "AlbumArtist" "AlbumSong" "All" "Artist" "ArtistSong" "Event" "Nothing" "Song" "SongList"] }
def groups-completer [] { ["Admin" "Limited" "Moderator" "Nothing" "Regular" "Trusted"] }
def sort-completer-8 [] { ["Group" "Name" "RegisterDate"] }
def fields-completer-12 [] { ["KnownLanguages" "MainPicture" "None" "OldUsernames"] }
def collectionStatus-completer [] { ["Nothing" "Ordered" "Owned" "Wishlisted"] }
def mediaType-completer [] { ["DigitalDownload" "Other" "PhysicalDisc"] }
def purchaseStatuses-completer [] { ["All" "Nothing" "Ordered" "Owned" "Wishlisted"] }
def albumTypes-completer [] { ["Album" "Artbook" "Compilation" "EP" "Fanmade" "Game" "Instrumental" "Other" "Single" "SplitAlbum" "Unknown" "Video"] }
def relationshipType-completer [] { ["Attending" "Interested"] }
def artistType-completer [] { ["Animator" "Band" "CeVIO" "Character" "Circle" "CoverArtist" "Illustrator" "Label" "Lyricist" "OtherGroup" "OtherIndividual" "OtherVocalist" "OtherVoiceSynthesizer" "Producer" "SynthesizerV" "UTAU" "Unknown" "Utaite" "Vocalist" "Vocaloid"] }
def inbox-completer [] { ["Nothing" "Notifications" "Received" "Sent"] }
def artistGrouping-completer [] { ["And" "Or"] }
def sort-completer-9 [] { ["AdditionDate" "FavoritedTimes" "Name" "None" "PublishDate" "RatingDate" "RatingScore"] }
def reportType-completer-1 [] { ["MaliciousIP" "Other" "RemovePermissions" "Spamming"] }
def fields-completer-13 [] { ["AdditionalNames" "Description" "Events" "Names" "None" "WebLinks"] }
def sortRule-completer-1 [] { ["Distance" "Name" "None"] }
def distanceUnit-completer [] { ["Kilometers" "Miles"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --before: string # format: date-time
  --since: string # format: date-time
  --userId: int # format: int32
  --editEvent: string@editEvent-completer
  --entryType: string@entryType-completer
  --maxResults: int # format: int32, default: 50
  --getTotalCount: oneof<nothing, bool> # default: false
  --qp-fields: string@fields-completer
  --entryFields: string@entryFields-completer
  --lang: string@lang-completer
  --sortRule: string@sortRule-completer
]: nothing -> record<items: table<archivedVersion: record, author: record, createDate: string, editEvent: string, entry: record>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "editEvent" $editEvent "scalar") (serialize-qp "entryType" $entryType "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "entryFields" $entryFields "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "sortRule" $sortRule "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/activityEntries" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --discTypes: string@discTypes-completer
  --tagName: list
  --tagId: list
  --childTags: oneof<nothing, bool> # default: false
  --artistId: list
  --artistParticipationStatus: string@artistParticipationStatus-completer
  --childVoicebanks: oneof<nothing, bool> # default: false
  --includeMembers: oneof<nothing, bool> # default: false
  --barcode: string
  --status: string@status-completer
  --releaseDateAfter: string # format: date-time
  --releaseDateBefore: string # format: date-time
  --advancedFilters: list
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer
  --preferAccurateMatches: oneof<nothing, bool> # default: false
  --deleted: oneof<nothing, bool> # default: false
  --nameMatchMode: string@nameMatchMode-completer
  --qp-fields: string@fields-completer-1
  --lang: string@lang-completer
]: nothing -> record<items: table<additionalNames: string, artistString: string, artists: list, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list, id: int, identifiers: list, mainPicture: record, mergedTo: int, name: string, names: list, pvs: list, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, tags: list, tracks: list, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "discTypes" $discTypes "scalar") (serialize-qp "tagName[]" $tagName "multi") (serialize-qp "tagId[]" $tagId "multi") (serialize-qp "childTags" $childTags "scalar") (serialize-qp "artistId[]" $artistId "multi") (serialize-qp "artistParticipationStatus" $artistParticipationStatus "scalar") (serialize-qp "childVoicebanks" $childVoicebanks "scalar") (serialize-qp "includeMembers" $includeMembers "scalar") (serialize-qp "barcode" $barcode "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "releaseDateAfter" $releaseDateAfter "scalar") (serialize-qp "releaseDateBefore" $releaseDateBefore "scalar") (serialize-qp "advancedFilters" $advancedFilters "multi") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "preferAccurateMatches" $preferAccurateMatches "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/albums" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/albums/comments/{commentId}
export def "albums-comments delete" [
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/albums/comments/($commentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/albums/comments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "albums-comments post-by-commentId" [
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/albums/comments/($commentId)")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --nameMatchMode: string@nameMatchMode-completer
  --maxResults: int # format: int32, default: 15
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/albums/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --languagePreference: string@languagePreference-completer
  --qp-fields: string@fields-completer-1
]: nothing -> table<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languagePreference" $languagePreference "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/albums/new" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ignoreIds: list
  --languagePreference: string@languagePreference-completer
  --qp-fields: string@fields-completer-1
]: nothing -> table<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignoreIds[]" $ignoreIds "multi") (serialize-qp "languagePreference" $languagePreference "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/albums/top" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notes" $notes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/albums/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-1
  --songFields: string@songFields-completer
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, artistString: string, artists: table<artist: record, categories: string, effectiveRoles: string, isSupport: bool, name: string, roles: string>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: table<discNumber: int, id: int, mediaType: string, name: string>, id: int, identifiers: table<value: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: table<language: string, value: string>, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>>, status: string, tags: table<count: int, tag: record>, tracks: table<discNumber: int, id: int, name: string, rating: string, song: record, trackNumber: int>, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "songFields" $songFields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/albums/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/albums/($id)/comments")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/albums/{id}/comments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "albums-comments post-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --body-id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/albums/($id)/comments")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $body_id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --languageCode: string
]: nothing -> table<albumId: int, date: string, id: int, languageCode: string, text: string, title: string, user: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languageCode" $languageCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/albums/($id)/reviews" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/albums/{id}/reviews
#
# --user shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
export def "albums-reviews post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --albumId: int # format: int32
  --date: string # format: date-time
  --body-id: int # format: int32
  --languageCode: string # nullable
  --text: string # nullable
  --title: string # nullable
  --user: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
]: any -> record<albumId: int, date: string, id: int, languageCode: string, text: string, title: string, user: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/albums/($id)/reviews")
  let body = {albumId: $albumId, date: $date, id: $body_id, languageCode: $languageCode, text: $text, title: $title, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/albums/{id}/reviews/{reviewId}
export def "albums-reviews delete" [
  reviewId: int
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/albums/($id)/reviews/($reviewId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> table<discNumber: int, id: int, name: string, rating: string, song: record<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, trackNumber: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/albums/($id)/tracks" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --field: list
  --discNumber: int # format: int32
  --lang: string@lang-completer
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "field[]" $field "multi") (serialize-qp "discNumber" $discNumber "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/albums/($id)/tracks/fields" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --languagePreference: string@languagePreference-completer
]: nothing -> table<album: record<additionalNames: string, artistString: string, artists: list, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list, id: int, identifiers: list, mainPicture: record, mergedTo: int, name: string, names: list, pvs: list, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, tags: list, tracks: list, version: int, webLinks: list>, mediaType: string, purchaseStatus: string, rating: int, user: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languagePreference" $languagePreference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/albums/($id)/user-collections" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --artistTypes: string
  --allowBaseVoicebanks: oneof<nothing, bool> # default: true
  --tagName: list
  --tagId: list
  --childTags: oneof<nothing, bool> # default: false
  --followedByUserId: int # format: int32
  --status: string@status-completer
  --advancedFilters: list
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-1
  --preferAccurateMatches: oneof<nothing, bool> # default: false
  --nameMatchMode: string@nameMatchMode-completer
  --qp-fields: string@fields-completer-3
  --lang: string@lang-completer
]: nothing -> record<items: table<additionalNames: string, artistLinks: list, artistLinksReverse: list, artistType: string, baseVoicebank: record, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record, mergedTo: int, name: string, names: list, pictureMime: string, relations: record, releaseDate: string, status: string, tags: list, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "artistTypes" $artistTypes "scalar") (serialize-qp "allowBaseVoicebanks" $allowBaseVoicebanks "scalar") (serialize-qp "tagName[]" $tagName "multi") (serialize-qp "tagId[]" $tagId "multi") (serialize-qp "childTags" $childTags "scalar") (serialize-qp "followedByUserId" $followedByUserId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "advancedFilters" $advancedFilters "multi") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "preferAccurateMatches" $preferAccurateMatches "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/artists" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/artists/comments/{commentId}
export def "artists-comments delete" [
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/artists/comments/($commentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/artists/comments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "artists-comments post-by-commentId" [
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/artists/comments/($commentId)")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --nameMatchMode: string@nameMatchMode-completer
  --maxResults: int # format: int32, default: 15
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/artists/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notes" $notes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/artists/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-3
  --relations: string@relations-completer
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, artistLinks: table<artist: record, linkType: string>, artistLinksReverse: table<artist: record, linkType: string>, artistType: string, baseVoicebank: record<additionalNames: string, artistType: string, deleted: bool, id: int, name: string, pictureMime: string, releaseDate: string, status: string, version: int>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: table<language: string, value: string>, pictureMime: string, relations: record<latestAlbums: list<record>, latestEvents: list<record>, latestSongs: list<record>, popularAlbums: list<record>, popularSongs: list<record>>, releaseDate: string, status: string, tags: table<count: int, tag: record>, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "relations" $relations "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/artists/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/artists/($id)/comments")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/artists/{id}/comments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "artists-comments post-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --body-id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/artists/($id)/comments")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $body_id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --before: string # format: date-time
  --since: string # format: date-time
  --userId: int # format: int32
  --entryType: string@entryType-completer
  --maxResults: int # format: int32, default: 50
  --getTotalCount: oneof<nothing, bool> # default: false
  --qp-fields: string@fields-completer-4
  --entryFields: string@entryFields-completer
  --lang: string@lang-completer
  --sortRule: string@sortRule-completer
]: nothing -> record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "entryType" $entryType "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "entryFields" $entryFields "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "sortRule" $sortRule "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/comments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/comments/{entryType}-comments
export def "comments get" [
  entryType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --entryId: int # format: int32
]: nothing -> record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entryId" $entryId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/comments/($entryType)-comments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/comments/{entryType}-comments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "comments post-by-entryType" [
  entryType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/comments/($entryType)-comments")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/comments/{entryType}-comments/{commentId}
export def "comments delete" [
  entryType: string
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/comments/($entryType)-comments/($commentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/comments/{entryType}-comments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "comments post-by-entryType-commentId" [
  entryType: string
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/comments/($entryType)-comments/($commentId)")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/discussions/comments/{commentId}
export def "discussions-comments delete" [
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/discussions/comments/($commentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/discussions/comments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "discussions-comments post" [
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/discussions/comments/($commentId)")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-5
]: nothing -> table<description: string, id: int, lastTopicAuthor: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, lastTopicDate: string, name: string, topicCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/discussions/folders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/discussions/folders
#
# --lastTopicAuthor shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
export def "discussions-folders post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  --id: int # format: int32
  --lastTopicAuthor: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --lastTopicDate: string # nullable, format: date-time
  --name: string # nullable
  --topicCount: int # format: int32
]: any -> record<description: string, id: int, lastTopicAuthor: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, lastTopicDate: string, name: string, topicCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/discussions/folders")
  let body = {description: $description, id: $id, lastTopicAuthor: $lastTopicAuthor, lastTopicDate: $lastTopicDate, name: $name, topicCount: $topicCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/discussions/folders/{folderId}/topics
#
# DEPRECATED
@deprecated
export def "discussions-folders-topics get" [
  folderId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-6
]: nothing -> table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, commentCount: int, comments: list<record>, content: string, created: string, folderId: int, id: int, lastComment: record<author: record, authorName: string, created: string, entry: record, id: int, message: string>, locked: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/discussions/folders/($folderId)/topics" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/discussions/folders/{folderId}/topics
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --comments item shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
# --lastComment shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
export def "discussions-folders-topics post" [
  folderId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --commentCount: int # format: int32
  --comments: list # nullable — item shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
  --content: string # nullable
  --created: string # format: date-time
  --body-folderId: int # format: int32
  --id: int # format: int32
  --lastComment: record # shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
  --locked: oneof<nothing, bool>
  --name: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, commentCount: int, comments: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, content: string, created: string, folderId: int, id: int, lastComment: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string>, locked: bool, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/discussions/folders/($folderId)/topics")
  let body = {author: $author, commentCount: $commentCount, comments: $comments, content: $content, created: $created, folderId: $body_folderId, id: $id, lastComment: $lastComment, locked: $locked, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --folderId: int # format: int32
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-2
  --qp-fields: string@fields-completer-6
]: nothing -> record<items: table<author: record, commentCount: int, comments: list, content: string, created: string, folderId: int, id: int, lastComment: record, locked: bool, name: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "folderId" $folderId "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/discussions/topics" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/discussions/topics/{topicId}
export def "discussions-topics delete" [
  topicId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/discussions/topics/($topicId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/discussions/topics/{topicId}
export def "discussions-topics get" [
  topicId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-6
]: nothing -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, commentCount: int, comments: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, content: string, created: string, folderId: int, id: int, lastComment: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string>, locked: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/discussions/topics/($topicId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/discussions/topics/{topicId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --comments item shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
# --lastComment shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
export def "discussions-topics post" [
  topicId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --commentCount: int # format: int32
  --comments: list # nullable — item shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
  --content: string # nullable
  --created: string # format: date-time
  --folderId: int # format: int32
  --id: int # format: int32
  --lastComment: record # shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
  --locked: oneof<nothing, bool>
  --name: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/discussions/topics/($topicId)")
  let body = {author: $author, commentCount: $commentCount, comments: $comments, content: $content, created: $created, folderId: $folderId, id: $id, lastComment: $lastComment, locked: $locked, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/discussions/topics/{topicId}/comments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "discussions-topics-comments post" [
  topicId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/discussions/topics/($topicId)/comments")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --tagName: list
  --tagId: list
  --childTags: oneof<nothing, bool> # default: false
  --entryTypes: string@entryTypes-completer
  --status: string@status-completer
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-3
  --nameMatchMode: string@nameMatchMode-completer
  --qp-fields: string@fields-completer-7
  --lang: string@lang-completer
]: nothing -> record<items: table<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "tagName[]" $tagName "multi") (serialize-qp "tagId[]" $tagId "multi") (serialize-qp "childTags" $childTags "scalar") (serialize-qp "entryTypes" $entryTypes "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/entries" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --nameMatchMode: string@nameMatchMode-completer
  --maxResults: int # format: int32, default: 10
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/entries/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/entry-types/{entryType}/{subType}/tag
export def "entry-types-tag get" [
  entryType: string
  subType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-8
]: nothing -> record<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/entry-types/($entryType)/($subType)/tag" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string
  --author: string
  --service: string@service-completer
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --lang: string@lang-completer
]: nothing -> record<items: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, song: record, thumbUrl: string, url: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "service" $service "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/pvs/for-songs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --qp-fields: string@fields-completer-9
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --nameMatchMode: string@nameMatchMode-completer
  --lang: string@lang-completer
]: nothing -> record<items: table<additionalNames: string, category: string, description: string, events: list, id: int, mainPicture: record, name: string, names: list, status: string, urlSlug: string, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/releaseEventSeries" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
  --hardDelete: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notes" $notes "scalar") (serialize-qp "hardDelete" $hardDelete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/releaseEventSeries/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-9
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, category: string, description: string, events: table<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<language: string, value: string>, status: string, urlSlug: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/releaseEventSeries/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<category: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, status: string, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/releaseEventSeries/($id)/for-edit")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --nameMatchMode: string@nameMatchMode-completer
  --seriesId: int # format: int32, default: 0
  --afterDate: string # format: date-time
  --beforeDate: string # format: date-time
  --category: string@category-completer
  --userCollectionId: int # format: int32
  --tagId: list
  --childTags: oneof<nothing, bool> # default: false
  --artistId: list
  --childVoicebanks: oneof<nothing, bool> # default: false
  --includeMembers: oneof<nothing, bool> # default: false
  --status: string@status-completer
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-4
  --qp-fields: string@fields-completer-10
  --lang: string@lang-completer
  --sortDirection: string@sortDirection-completer
]: nothing -> record<items: table<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "seriesId" $seriesId "scalar") (serialize-qp "afterDate" $afterDate "scalar") (serialize-qp "beforeDate" $beforeDate "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "userCollectionId" $userCollectionId "scalar") (serialize-qp "tagId[]" $tagId "multi") (serialize-qp "childTags" $childTags "scalar") (serialize-qp "artistId[]" $artistId "multi") (serialize-qp "childVoicebanks" $childVoicebanks "scalar") (serialize-qp "includeMembers" $includeMembers "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "sortDirection" $sortDirection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/releaseEvents" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --maxResults: int # format: int32, default: 10
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/releaseEvents/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/releaseEvents/{eventId}/albums
export def "release-events-albums get" [
  eventId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-1
  --lang: string@lang-completer
]: nothing -> table<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/releaseEvents/($eventId)/albums" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/releaseEvents/{eventId}/published-songs
export def "release-events-published-songs get" [
  eventId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/releaseEvents/($eventId)/published-songs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/releaseEvents/{eventId}/reports
export def "release-events-reports post" [
  eventId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportType: string@reportType-completer
  --notes: string
  --versionNumber: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportType" $reportType "scalar") (serialize-qp "notes" $notes "scalar") (serialize-qp "versionNumber" $versionNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/releaseEvents/($eventId)/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
  --hardDelete: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notes" $notes "scalar") (serialize-qp "hardDelete" $hardDelete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/releaseEvents/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-10
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, artists: table<artist: record, effectiveRoles: string, id: int, name: string, roles: string>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<language: string, value: string>, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list<record>>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: table<count: int, tag: record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record<formatted: string, hasValue: bool, latitude: float, longitude: float>, deleted: bool, description: string, events: list<record>, id: int, name: string, names: list<record>, status: string, version: int, webLinks: list<record>>, venueName: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/releaseEvents/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/resources/{cultureCode}
export def "resources get" [
  cultureCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --setNames: list
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "setNames[]" $setNames "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/resources/($cultureCode)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/songLists
#
# --mainPicture shape: {mime?: string, name?: string, urlOriginal?: string, urlSmallThumb?: string, urlThumb?: string, urlTinyThumb?: string}
# --songLinks item shape: {notes?: string, order?: int, song?: record, songInListId?: int}
export def "song-lists post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --deleted: oneof<nothing, bool>
  --description: string # nullable
  --eventDate: string # nullable, format: date-time
  --featuredCategory: string@featuredCategory-completer
  --id: int # format: int32
  --mainPicture: record # shape: {mime?: string, name?: string, urlOriginal?: string, urlSmallThumb?: string, urlThumb?: string, urlTinyThumb?: string}
  --name: string # nullable
  --songLinks: list # nullable — item shape: {notes?: string, order?: int, song?: record, songInListId?: int}
  --status: string@status-completer
  --updateNotes: string # nullable
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/songLists")
  let body = {deleted: $deleted, description: $description, eventDate: $eventDate, featuredCategory: $featuredCategory, id: $id, mainPicture: $mainPicture, name: $name, songLinks: $songLinks, status: $status, updateNotes: $updateNotes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/songLists/comments/{commentId}
export def "song-lists-comments delete" [
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/songLists/comments/($commentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/songLists/comments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "song-lists-comments post-by-commentId" [
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/songLists/comments/($commentId)")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --tagId: list
  --childTags: oneof<nothing, bool> # default: false
  --nameMatchMode: string@nameMatchMode-completer
  --featuredCategory: string@featuredCategory-completer
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-5
  --qp-fields: string@fields-completer-11
  --lang: string@lang-completer
]: nothing -> record<items: table<author: record, deleted: bool, description: string, eventDate: string, events: list, featuredCategory: string, id: int, latestComments: list, mainPicture: record, name: string, status: string, tags: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "tagId[]" $tagId "multi") (serialize-qp "childTags" $childTags "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "featuredCategory" $featuredCategory "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/songLists/featured" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --nameMatchMode: string@nameMatchMode-completer
  --featuredCategory: string@featuredCategory-completer
  --maxResults: int # format: int32, default: 10
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "featuredCategory" $featuredCategory "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/songLists/featured/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
  --hardDelete: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notes" $notes "scalar") (serialize-qp "hardDelete" $hardDelete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/songLists/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/songLists/{listId}/comments
export def "song-lists-comments get" [
  listId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/songLists/($listId)/comments")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/songLists/{listId}/comments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "song-lists-comments post-by-listId" [
  listId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/songLists/($listId)/comments")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/songLists/{listId}/songs
export def "song-lists-songs get" [
  listId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --songTypes: string
  --pvServices: string@pvServices-completer
  --tagId: list
  --artistId: list
  --childVoicebanks: oneof<nothing, bool> # default: false
  --advancedFilters: list
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-6
  --nameMatchMode: string@nameMatchMode-completer
  --qp-fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> record<items: table<notes: string, order: int, song: record>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "songTypes" $songTypes "scalar") (serialize-qp "pvServices" $pvServices "scalar") (serialize-qp "tagId[]" $tagId "multi") (serialize-qp "artistId[]" $artistId "multi") (serialize-qp "childVoicebanks" $childVoicebanks "scalar") (serialize-qp "advancedFilters" $advancedFilters "multi") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/songLists/($listId)/songs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --songTypes: string
  --afterDate: string # format: date-time
  --beforeDate: string # format: date-time
  --tagName: list
  --tagId: list
  --childTags: oneof<nothing, bool> # default: false
  --unifyTypesAndTags: oneof<nothing, bool> # default: false
  --artistId: list
  --artistParticipationStatus: string@artistParticipationStatus-completer
  --childVoicebanks: oneof<nothing, bool> # default: false
  --includeMembers: oneof<nothing, bool> # default: false
  --onlyWithPvs: oneof<nothing, bool> # default: false
  --pvServices: string@pvServices-completer
  --since: int # format: int32
  --minScore: int # format: int32
  --userCollectionId: int # format: int32
  --releaseEventId: int # format: int32
  --parentSongId: int # format: int32
  --status: string@status-completer
  --advancedFilters: list
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-6
  --preferAccurateMatches: oneof<nothing, bool> # default: false
  --nameMatchMode: string@nameMatchMode-completer
  --qp-fields: string@fields-completer-2
  --lang: string@lang-completer
  --minMilliBpm: int # format: int32
  --maxMilliBpm: int # format: int32
  --minLength: int # format: int32
  --maxLength: int # format: int32
]: nothing -> record<items: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "songTypes" $songTypes "scalar") (serialize-qp "afterDate" $afterDate "scalar") (serialize-qp "beforeDate" $beforeDate "scalar") (serialize-qp "tagName[]" $tagName "multi") (serialize-qp "tagId[]" $tagId "multi") (serialize-qp "childTags" $childTags "scalar") (serialize-qp "unifyTypesAndTags" $unifyTypesAndTags "scalar") (serialize-qp "artistId[]" $artistId "multi") (serialize-qp "artistParticipationStatus" $artistParticipationStatus "scalar") (serialize-qp "childVoicebanks" $childVoicebanks "scalar") (serialize-qp "includeMembers" $includeMembers "scalar") (serialize-qp "onlyWithPvs" $onlyWithPvs "scalar") (serialize-qp "pvServices" $pvServices "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "minScore" $minScore "scalar") (serialize-qp "userCollectionId" $userCollectionId "scalar") (serialize-qp "releaseEventId" $releaseEventId "scalar") (serialize-qp "parentSongId" $parentSongId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "advancedFilters" $advancedFilters "multi") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "preferAccurateMatches" $preferAccurateMatches "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "minMilliBpm" $minMilliBpm "scalar") (serialize-qp "maxMilliBpm" $maxMilliBpm "scalar") (serialize-qp "minLength" $minLength "scalar") (serialize-qp "maxLength" $maxLength "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/songs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pvService: string@pvService-completer
  --pvId: string
  --qp-fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, albums: table<additionalNames: string, artistString: string, coverPictureMime: string, createDate: string, deleted: bool, discType: string, id: int, name: string, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, version: int>, artistString: string, artists: table<artist: record, categories: string, effectiveRoles: string, id: int, isCustomName: bool, isSupport: bool, name: string, roles: string>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: table<cultureCode: string, id: int, source: string, translationType: string, url: string, value: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: table<language: string, value: string>, originalVersionId: int, publishDate: string, pvServices: string, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>>, songType: string, status: string, tags: table<count: int, tag: record>, thumbUrl: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pvService" $pvService "scalar") (serialize-qp "pvId" $pvId "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/songs/byPv" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/songs/comments/{commentId}
export def "songs-comments delete" [
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/songs/comments/($commentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/songs/comments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "songs-comments post-by-commentId" [
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/songs/comments/($commentId)")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --languagePreference: string@languagePreference-completer
  --qp-fields: string@fields-completer-2
]: nothing -> table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languagePreference" $languagePreference "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/songs/highlighted" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/songs/lyrics/{lyricsId}
export def "songs-lyrics get" [
  lyricsId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<cultureCode: string, id: int, source: string, translationType: string, url: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/songs/lyrics/($lyricsId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --nameMatchMode: string@nameMatchMode-completer
  --maxResults: int # format: int32, default: 15
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/songs/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --durationHours: int # format: int32
  --startDate: string # format: date-time
  --filterBy: string@filterBy-completer
  --vocalist: string@vocalist-completer
  --maxResults: int # format: int32, default: 25
  --qp-fields: string@fields-completer-2
  --languagePreference: string@languagePreference-completer
]: nothing -> table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "durationHours" $durationHours "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "filterBy" $filterBy "scalar") (serialize-qp "vocalist" $vocalist "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "languagePreference" $languagePreference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/songs/top-rated" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notes" $notes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/songs/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, albums: table<additionalNames: string, artistString: string, coverPictureMime: string, createDate: string, deleted: bool, discType: string, id: int, name: string, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, version: int>, artistString: string, artists: table<artist: record, categories: string, effectiveRoles: string, id: int, isCustomName: bool, isSupport: bool, name: string, roles: string>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: table<cultureCode: string, id: int, source: string, translationType: string, url: string, value: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: table<language: string, value: string>, originalVersionId: int, publishDate: string, pvServices: string, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>>, songType: string, status: string, tags: table<count: int, tag: record>, thumbUrl: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/songs/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/songs/($id)/comments")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/songs/{id}/comments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "songs-comments post-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --body-id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/songs/($id)/comments")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $body_id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/songs/($id)/derived" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --userFields: string@userFields-completer
  --lang: string@lang-completer
]: nothing -> table<date: string, rating: string, song: record<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, user: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userFields" $userFields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/songs/($id)/ratings" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/songs/{id}/ratings
export def "songs-ratings post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rating: string@rating-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/songs/($id)/ratings")
  let body = {rating: $rating} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> record<artistMatches: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, likeMatches: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, tagMatches: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/songs/($id)/related" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --allowChildren: oneof<nothing, bool> # default: true
  --categoryName: string # default: 
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --nameMatchMode: string@nameMatchMode-completer
  --qp-sort: string@sort-completer-7
  --preferAccurateMatches: oneof<nothing, bool> # default: false
  --qp-fields: string@fields-completer-8
  --lang: string@lang-completer
  --target: string@target-completer
]: nothing -> record<items: table<additionalNames: string, aliasedTo: record, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record, name: string, names: list, parent: record, relatedTags: list, status: string, targets: int, translatedDescription: record, urlSlug: string, usageCount: int, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "allowChildren" $allowChildren "scalar") (serialize-qp "categoryName" $categoryName "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "preferAccurateMatches" $preferAccurateMatches "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "target" $target "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tags" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/tags
export def "tags post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-8
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/tags/byName/($name)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --nameMatchMode: string@nameMatchMode-completer
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tags/categoryNames" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/tags/comments/{commentId}
export def "tags-comments delete" [
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/comments/($commentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/tags/comments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "tags-comments post-by-commentId" [
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/comments/($commentId)")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --allowAliases: oneof<nothing, bool> # default: true
  --maxResults: int # format: int32, default: 10
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "allowAliases" $allowAliases "scalar") (serialize-qp "maxResults" $maxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tags/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --categoryName: string
  --entryType: string@entryType-completer
  --maxResults: int # format: int32, default: 15
  --lang: string@lang-completer
]: nothing -> table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "categoryName" $categoryName "scalar") (serialize-qp "entryType" $entryType "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tags/top" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
  --hardDelete: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notes" $notes "scalar") (serialize-qp "hardDelete" $hardDelete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/tags/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-8
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/tags/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/tags/{tagId}/children
export def "tags-children get" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-8
  --lang: string@lang-completer
]: nothing -> table<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: list<record>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/tags/($tagId)/children" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/tags/{tagId}/comments
export def "tags-comments get" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($tagId)/comments")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/tags/{tagId}/comments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "tags-comments post-by-tagId" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($tagId)/comments")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/tags/{tagId}/reports
export def "tags-reports post" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportType: string@reportType-completer
  --notes: string
  --versionNumber: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportType" $reportType "scalar") (serialize-qp "notes" $notes "scalar") (serialize-qp "versionNumber" $versionNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/tags/($tagId)/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --groups: string@groups-completer
  --joinDateAfter: string # format: date-time
  --joinDateBefore: string # format: date-time
  --nameMatchMode: string@nameMatchMode-completer
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-8
  --includeDisabled: oneof<nothing, bool> # default: false
  --onlyVerified: oneof<nothing, bool> # default: false
  --knowsLanguage: string
  --qp-fields: string@fields-completer-12
]: nothing -> record<items: table<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "groups" $groups "scalar") (serialize-qp "joinDateAfter" $joinDateAfter "scalar") (serialize-qp "joinDateBefore" $joinDateBefore "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDisabled" $includeDisabled "scalar") (serialize-qp "onlyVerified" $onlyVerified "scalar") (serialize-qp "knowsLanguage" $knowsLanguage "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/users" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-12
]: nothing -> record<active: bool, groupId: string, id: int, knownLanguages: table<cultureCode: string, proficiency: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: table<date: string, oldName: string>, verifiedArtist: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/users/current" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/users/current/album-collection-statuses/{albumId}
export def "users-current-album-collection-statuses get" [
  albumId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<album: record<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>>, mediaType: string, purchaseStatus: string, rating: int, user: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/current/album-collection-statuses/($albumId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/users/current/albums/{albumId}
export def "users-current-albums post" [
  albumId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --collectionStatus: string@collectionStatus-completer
  --mediaType: string@mediaType-completer
  --rating: int # format: int32
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "collectionStatus" $collectionStatus "scalar") (serialize-qp "mediaType" $mediaType "scalar") (serialize-qp "rating" $rating "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/users/current/albums/($albumId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/users/current/followedArtists/{artistId}
export def "users-current-followed-artists get" [
  artistId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<artist: record<additionalNames: string, artistLinks: list<record>, artistLinksReverse: list<record>, artistType: string, baseVoicebank: record<additionalNames: string, artistType: string, deleted: bool, id: int, name: string, pictureMime: string, releaseDate: string, status: string, version: int>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pictureMime: string, relations: record<latestAlbums: list, latestEvents: list, latestSongs: list, popularAlbums: list, popularSongs: list>, releaseDate: string, status: string, tags: list<record>, version: int, webLinks: list<record>>, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/current/followedArtists/($artistId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/users/current/followedTags/{tagId}
export def "users-current-followed-tags delete" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/current/followedTags/($tagId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/users/current/followedTags/{tagId}
export def "users-current-followed-tags post" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/current/followedTags/($tagId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/users/current/ratedSongs/{songId}
export def "users-current-rated-songs get" [
  songId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/current/ratedSongs/($songId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/users/current/refreshEntryEdit
export def "users-current-refresh-entry-edit post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --entryType: string@entryType-completer
  --entryId: int # format: int32
]: nothing -> record<time: string, userId: int, userName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entryType" $entryType "scalar") (serialize-qp "entryId" $entryId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/users/current/refreshEntryEdit" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/users/current/songTags/{songId}
export def "users-current-song-tags post" [
  songId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/current/songTags/($songId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/users/messages/{messageId}
export def "users-messages get-by-messageId" [
  messageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<body: string, createdFormatted: string, highPriority: bool, id: int, inbox: string, read: bool, receiver: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, sender: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/messages/($messageId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --nameMatchMode: string@nameMatchMode-completer
  --maxResults: int # format: int32, default: 10
  --includeDisabled: oneof<nothing, bool> # default: false
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "includeDisabled" $includeDisabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/users/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/users/profileComments/{commentId}
export def "users-profile-comments delete" [
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/profileComments/($commentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/users/profileComments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "users-profile-comments post-by-commentId" [
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/profileComments/($commentId)")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string@fields-completer-12
]: nothing -> record<active: bool, groupId: string, id: int, knownLanguages: table<cultureCode: string, proficiency: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: table<date: string, oldName: string>, verifiedArtist: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/users/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/users/{id}/album-collection-statuses/{albumId}
export def "users-album-collection-statuses get" [
  id: int
  albumId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<album: record<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>>, mediaType: string, purchaseStatus: string, rating: int, user: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/album-collection-statuses/($albumId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --tagId: int # format: int32
  --tag: string
  --artistId: int # format: int32
  --purchaseStatuses: string@purchaseStatuses-completer
  --releaseEventId: int # format: int32, default: 0
  --albumTypes: string@albumTypes-completer
  --advancedFilters: list
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer
  --nameMatchMode: string@nameMatchMode-completer
  --qp-fields: string@fields-completer-1
  --lang: string@lang-completer
  --mediaType: string@mediaType-completer
]: nothing -> record<items: table<album: record, mediaType: string, purchaseStatus: string, rating: int, user: record>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "tagId" $tagId "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "artistId" $artistId "scalar") (serialize-qp "purchaseStatuses" $purchaseStatuses "scalar") (serialize-qp "releaseEventId" $releaseEventId "scalar") (serialize-qp "albumTypes" $albumTypes "scalar") (serialize-qp "advancedFilters" $advancedFilters "multi") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "mediaType" $mediaType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/users/($id)/albums" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --relationshipType: string@relationshipType-completer
]: nothing -> table<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "relationshipType" $relationshipType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/users/($id)/events" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --tagId: list
  --artistType: string@artistType-completer
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-1
  --nameMatchMode: string@nameMatchMode-completer
  --qp-fields: string@fields-completer-3
  --lang: string@lang-completer
]: nothing -> record<items: table<artist: record, id: int>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "tagId[]" $tagId "multi") (serialize-qp "artistType" $artistType "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/users/($id)/followedArtists" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/users/{id}/followedArtists/{artistId}
export def "users-followed-artists get" [
  id: int
  artistId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<artist: record<additionalNames: string, artistLinks: list<record>, artistLinksReverse: list<record>, artistType: string, baseVoicebank: record<additionalNames: string, artistType: string, deleted: bool, id: int, name: string, pictureMime: string, releaseDate: string, status: string, version: int>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pictureMime: string, relations: record<latestAlbums: list, latestEvents: list, latestSongs: list, popularAlbums: list, popularSongs: list>, releaseDate: string, status: string, tags: list<record>, version: int, webLinks: list<record>>, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/followedArtists/($artistId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --messageId: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "messageId" $messageId "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/users/($id)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --inbox: string@inbox-completer
  --unread: oneof<nothing, bool> # default: false
  --anotherUserId: int # format: int32
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
]: nothing -> record<items: table<body: string, createdFormatted: string, highPriority: bool, id: int, inbox: string, read: bool, receiver: record, sender: record, subject: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "inbox" $inbox "scalar") (serialize-qp "unread" $unread "scalar") (serialize-qp "anotherUserId" $anotherUserId "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/users/($id)/messages" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/users/{id}/messages
#
# --receiver shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --sender shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
export def "users-messages post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-body: string # nullable
  --createdFormatted: string # nullable
  --highPriority: oneof<nothing, bool>
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
  let full_url = (build-url $base $"/api/users/($id)/messages")
  let body = {body: $body_body, createdFormatted: $createdFormatted, highPriority: $highPriority, id: $body_id, inbox: $inbox, read: $read, receiver: $receiver, sender: $sender, subject: $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
]: nothing -> record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/users/($id)/profileComments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/users/{id}/profileComments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
export def "users-profile-comments post-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --authorName: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, discType?: "Unknown"|"Album"|"Single"|"EP"|"SplitAlbum"|"Compilation"|"Video"|"Artbook"|"Game"|"Fanmade"|"Instrumental"|"Other", entryType?: "Undefined"|"Album"|"Artist"|"DiscussionTopic"|"PV"|"ReleaseEvent"|"ReleaseEventSeries"|"Song"|"SongList"|"Tag"|"User"|"Venue", eventCategory?: "Unspecified"|"AlbumRelease"|"Anniversary"|"Club"|"Concert"|"Contest"|"Convention"|"Other"|"Festival", id?: int, mainPicture?: record, name?: string, names?: list, pvs?: list, releaseEventSeriesName?: string, songListFeaturedCategory?: "Nothing"|"Concerts"|"VocaloidRanking"|"Pools"|"Other", songType?: "Unspecified"|"Original"|"Remaster"|"Remix"|"Cover"|"Arrangement"|"Instrumental"|"Mashup"|"MusicPV"|"DramaPV"|"Live"|"Illustration"|"Other", status?: "Draft"|"Finished"|"Approved"|"Locked", tagCategoryName?: string, tags?: list, urlSlug?: string, version?: int, webLinks?: list}
  --body-id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/profileComments")
  let body = {author: $author, authorName: $authorName, created: $created, entry: $entry, id: $body_id, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --tagName: string
  --tagId: list
  --artistId: list
  --childVoicebanks: oneof<nothing, bool> # default: false
  --artistGrouping: string@artistGrouping-completer
  --rating: string@rating-completer
  --songListId: int # format: int32
  --groupByRating: oneof<nothing, bool> # default: true
  --pvServices: string@pvServices-completer
  --advancedFilters: list
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-9
  --nameMatchMode: string@nameMatchMode-completer
  --qp-fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> record<items: table<date: string, rating: string, song: record, user: record>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "tagName" $tagName "scalar") (serialize-qp "tagId[]" $tagId "multi") (serialize-qp "artistId[]" $artistId "multi") (serialize-qp "childVoicebanks" $childVoicebanks "scalar") (serialize-qp "artistGrouping" $artistGrouping "scalar") (serialize-qp "rating" $rating "scalar") (serialize-qp "songListId" $songListId "scalar") (serialize-qp "groupByRating" $groupByRating "scalar") (serialize-qp "pvServices" $pvServices "scalar") (serialize-qp "advancedFilters" $advancedFilters "multi") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/users/($id)/ratedSongs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/users/{id}/ratedSongs/{songId}
export def "users-rated-songs get" [
  id: int
  songId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/ratedSongs/($songId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/users/{id}/reports
export def "users-reports post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --reason: string # nullable
  --reportType: string@reportType-completer-1
]: any -> bool {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/reports")
  let body = {reason: $reason, reportType: $reportType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/users/{id}/settings/{settingName}
export def "users-settings post" [
  id: int
  settingName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/users/($id)/settings/($settingName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --tagId: list
  --childTags: oneof<nothing, bool> # default: false
  --nameMatchMode: string@nameMatchMode-completer
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-5
  --qp-fields: string@fields-completer-11
]: nothing -> record<items: table<author: record, deleted: bool, description: string, eventDate: string, events: list, featuredCategory: string, id: int, latestComments: list, mainPicture: record, name: string, status: string, tags: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "tagId[]" $tagId "multi") (serialize-qp "childTags" $childTags "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/users/($id)/songLists" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-query: string # default: 
  --qp-fields: string@fields-completer-13
  --start: int # format: int32, default: 0
  --maxResults: int # format: int32, default: 10
  --getTotalCount: oneof<nothing, bool> # default: false
  --nameMatchMode: string@nameMatchMode-completer
  --lang: string@lang-completer
  --sortRule: string@sortRule-completer-1
  --latitude: float # format: double
  --longitude: float # format: double
  --radius: float # format: double
  --distanceUnit: string@distanceUnit-completer
]: nothing -> record<items: table<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "getTotalCount" $getTotalCount "scalar") (serialize-qp "nameMatchMode" $nameMatchMode "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "sortRule" $sortRule "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/venues" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
  --hardDelete: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notes" $notes "scalar") (serialize-qp "hardDelete" $hardDelete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/venues/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/venues/{id}/reports
export def "venues-reports post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportType: string@reportType-completer
  --notes: string
  --versionNumber: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportType" $reportType "scalar") (serialize-qp "notes" $notes "scalar") (serialize-qp "versionNumber" $versionNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/venues/($id)/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
