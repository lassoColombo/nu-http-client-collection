# Auto-generated client for ticketmaster publish api vv2
# Source: https://api.apis.guru/v2/specs/ticketmaster.com/publish/v2/openapi.json
# Auth: --token flag or $env.TICKETMASTER_PUBLISH_API_TOKEN

const BASE_URL = "http://localhost//www.ticketmaster.com/publish/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TICKETMASTER_PUBLISH_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://localhost//www.ticketmaster.com/publish/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["attraction" "event" "venue"] }
def related-entity-type-completer [] { ["attraction" "event" "venue"] }
def source-completer [] { ["ticketmaster"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "publish-attractions publish" } } | get name | first)
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

# Publish an attractions
#
# POST /publish/v2/attractions
# operationId: publishAttraction
# --classifications item shape: {genre?: record, primary?: bool, segment?: record, subGenre?: record, subType?: record, type?: record}
# --images item shape: {attribution?: string, domains?: list<string>, fallback?: bool, height?: int, ratio?: "16_9"|"3_2"|"4_3", url?: string, width?: int}
# --source shape: {id?: string, name?: string}
export def "publish-attractions publish" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tmps-correlation-id: string # Unique correlation id to be able to trace the request in our system
  --active: oneof<nothing, bool> # Indicate if the entity is active, inactive entity won't appear in Discovery API (default: false)
  --additional-infos: record # Additional informations of the entity - multi-lingual fields (e.g. en-us: additionalInfo)
  --classifications: list # Attraction's classifications — item shape: {genre?: record, primary?: bool, segment?: record, subGenre?: record, subType?: record, type?: record}
  --descriptions: record # Descriptions of the entity - multi-lingual fields (e.g. en-us: description)
  --discoverable: oneof<nothing, bool> # True if the entity is dicoverable in discovery API (default: false)
  --images: list # Images of the entity — item shape: {attribution?: string, domains?: list<string>, fallback?: bool, height?: int, ratio?: "16_9"|"3_2"|"4_3", url?: string, width?: int}
  --names: record # Names of the entity - multi-lingual fields (e.g. en-us: name)
  --references: record # References of this entity in an other system. Reference is the exact same entity (e.g. sourceName: id)
  --relationships: list # Relationships on the entity, like if the entity is a duplicate of another one
  --body-source: record # Source — shape: {id?: string, name?: string}
  --test: oneof<nothing, bool> # Indicate if this is a test entity, by default test entities won't appear in discovery API (default: false)
  type: string@type-completer # Type of the entity
  --url: string # URL of a web site detail page of the entity
  --version: int # Version of the entity. Version is to avoid updated an entity with an older version (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/publish/v2/attractions")
  let req_body = {"active": $active, "additionalInfos": $additional_infos, "classifications": $classifications, "descriptions": $descriptions, "discoverable": $discoverable, "images": $images, "names": $names, "references": $references, "relationships": $relationships, "source": $body_source, "test": $test, "type": $type, "url": $url, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"TMPS-Correlation-Id": $tmps_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Publish a patch on an attraction
#
# PATCH /publish/v2/attractions/{id}
# operationId: patchAttraction
# --changes item shape: {from?: string, op: "add"|"remove"|"replace"|"move"|"copy"|"test", path: string, value?: record}
export def "publish-attractions update" [
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
  --tmps-correlation-id: string # Unique correlation id to be able to trace the request in our system
  changes: list # List of changes to apply to the related entity — item shape: {from?: string, op: "add"|"remove"|"replace"|"move"|"copy"|"test", path: string, value?: record}
  related_entity_id: string # Id of the entity to apply the augmentation data.
  related_entity_type: string@related-entity-type-completer # The type of the entity to apply the augmentation data.
  --score: float # The confidence (%) level of the accuracy of this augmention data. 100 is the better (format: float)
  --body-source: string # The source where the augementation data came from
  version_number: int # Vesion of this augmentation data. This field is to avoid updating entity with old data. (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/publish/v2/attractions/{id}"))
  let req_body = {"changes": $changes, "relatedEntityId": $related_entity_id, "relatedEntityType": $related_entity_type, "score": $score, "source": $body_source, "versionNumber": $version_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"TMPS-Correlation-Id": $tmps_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Publish a video on an attraction
#
# POST /publish/v2/attractions/{id}/videos
# operationId: publishAttractionVideos
# --licensingInformation shape: {license: string, regionRestriction?: record}
# --source shape: {id?: string, name?: string}
export def "publish-attractions-videos publish" [
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
  --tmps-correlation-id: string # Unique correlation id to be able to trace the request in our system
  --embed-url: string # The url of the embeded video
  licensing_information: record # This class defines an entitlement data on the Publish API — shape: {license: string, regionRestriction?: record}
  --body-source: record # Source — shape: {id?: string, name?: string}
  url: string # The url of the video
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/publish/v2/attractions/{id}/videos"))
  let req_body = {"embedUrl": $embed_url, "licensingInformation": $licensing_information, "source": $body_source, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"TMPS-Correlation-Id": $tmps_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Publish entitlements on an entity
#
# POST /publish/v2/entitlements
# operationId: publishEntitlements
# --relatedEntitySource shape: {id?: string, name?: string}
export def "publish-entitlements publish" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tmps-correlation-id: string # Unique correlation id to be able to trace the request in our system
  data: record # The actual entitlements information to add to the entity
  --related-entity-id: string # Id of the entity to add this extionsion to. If the relatedEntityId is Null, a relatedEntitySource MUST be provided
  --related-entity-source: record # Source — shape: {id?: string, name?: string}
  related_entity_type: string@related-entity-type-completer # The type of the entity to add this entitlement to
  --body-source: string@source-completer # Source of the extension, where it came from
  --version-number: int # Version of the entitlements. Version is to prevent to override an entitlements with an older one (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/publish/v2/entitlements")
  let req_body = {"data": $data, "relatedEntityId": $related_entity_id, "relatedEntitySource": $related_entity_source, "relatedEntityType": $related_entity_type, "source": $body_source, "versionNumber": $version_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"TMPS-Correlation-Id": $tmps_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Publish an event
#
# POST /publish/v2/events
# operationId: publishEvent
# --attractions item shape: {active?: bool, additionalInfos?: record, classifications?: list, descriptions?: record, discoverable?: bool, images?: list, names?: record, references?: record, relationships?: list, source?: record, test?: bool, type: "event"|"venue"|"attraction", url?: string, version?: int}
# --classifications item shape: {genre?: record, primary?: bool, segment?: record, subGenre?: record, subType?: record, type?: record}
# --dates shape: {access?: record, end?: record, start?: record, status?: record, timezone?: string}
# --images item shape: {attribution?: string, domains?: list<string>, fallback?: bool, height?: int, ratio?: "16_9"|"3_2"|"4_3", url?: string, width?: int}
# --location shape: {latitude?: float, longitude?: float}
# --place shape: {address?: record, area?: record, city?: record, country?: record, location?: record, names?: record, postalCode?: string, state?: record}
# --priceRanges item shape: {currency?: string, max?: float, min?: float, type?: "standard"}
# --promoter shape: {descriptions?: record, id?: string, names?: record}
# --publicVisibility shape: {endDateTime?: string, startDateTime?: string, visible?: bool}
# --sales shape: {presales?: list, public?: record}
# --source shape: {id?: string, name?: string}
# --venue shape: {accessibleSeatingDetails?: record, active?: bool, additionalInfos?: record, address?: record, boxOfficeInfo?: record, city?: record, country?: record, currency?: string, descriptions?: record, discoverable?: bool, distance?: float, dma?: list, generalInfo?: record, images?: list, location?: record, markets?: list, names?: record, parkingDetails?: record, postalCode?: string, references?: record, relationships?: list, social?: record, source?: record, state?: record, test?: bool, ... (5 more fields)}
export def "publish-events publish" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tmps-correlation-id: string # Unique correlation id to be able to trace the request in our system
  --active: oneof<nothing, bool> # Indicate if the entity is active, inactive entity won't appear in Discovery API (default: false)
  --additional-infos: record # Additional informations of the entity - multi-lingual fields (e.g. en-us: additionalInfo)
  --attractions: list # Ordered Attraction related to the event — item shape: {active?: bool, additionalInfos?: record, classifications?: list, descriptions?: record, discoverable?: bool, images?: list, names?: record, references?: record, relationships?: list, source?: record, test?: bool, type: "event"|"venue"|"attraction", url?: string, version?: int}
  --classifications: list # Event's classifications — item shape: {genre?: record, primary?: bool, segment?: record, subGenre?: record, subType?: record, type?: record}
  --dates: record # Event's Dates — shape: {access?: record, end?: record, start?: record, status?: record, timezone?: string}
  --descriptions: record # Descriptions of the entity - multi-lingual fields (e.g. en-us: description)
  --discoverable: oneof<nothing, bool> # True if the entity is dicoverable in discovery API (default: false)
  --distance: float # format: double
  --images: list # Images of the entity — item shape: {attribution?: string, domains?: list<string>, fallback?: bool, height?: int, ratio?: "16_9"|"3_2"|"4_3", url?: string, width?: int}
  --infos: record # Any information related to the event - multi-lingual fields (e.g. en-us: info)
  --location: record # Location — shape: {latitude?: float, longitude?: float}
  --names: record # Names of the entity - multi-lingual fields (e.g. en-us: name)
  --place: record # Place — shape: {address?: record, area?: record, city?: record, country?: record, location?: record, names?: record, postalCode?: string, state?: record}
  --please-notes: record # Any notes related to the event - multi-lingual fields (e.g. en-us: note)
  --price-ranges: list # Price ranges of this event — item shape: {currency?: string, max?: float, min?: float, type?: "standard"}
  --promoter: record # Promoter — shape: {descriptions?: record, id?: string, names?: record}
  --public-visibility: record # The class defines the public visibility period on the Discovery/Publish API. — shape: {endDateTime?: string, startDateTime?: string, visible?: bool}
  --references: record # References of this entity in an other system. Reference is the exact same entity (e.g. sourceName: id)
  --relationships: list # Relationships on the entity, like if the entity is a duplicate of another one
  --sales: record # Event's Sales Dates — shape: {presales?: list, public?: record}
  --body-source: record # Source — shape: {id?: string, name?: string}
  --test: oneof<nothing, bool> # Indicate if this is a test entity, by default test entities won't appear in discovery API (default: false)
  type: string@type-completer # Type of the entity
  --units: string
  --url: string # URL of a web site detail page of the entity
  --venue: record # Venue — shape: {accessibleSeatingDetails?: record, active?: bool, additionalInfos?: record, address?: record, boxOfficeInfo?: record, city?: record, country?: record, currency?: string, descriptions?: record, discoverable?: bool, distance?: float, dma?: list, generalInfo?: record, images?: list, location?: record, markets?: list, names?: record, parkingDetails?: record, postalCode?: string, references?: record, relationships?: list, social?: record, source?: record, state?: record, test?: bool, ... (5 more fields)}
  --version: int # Version of the entity. Version is to avoid updated an entity with an older version (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/publish/v2/events")
  let req_body = {"active": $active, "additionalInfos": $additional_infos, "attractions": $attractions, "classifications": $classifications, "dates": $dates, "descriptions": $descriptions, "discoverable": $discoverable, "distance": $distance, "images": $images, "infos": $infos, "location": $location, "names": $names, "place": $place, "pleaseNotes": $please_notes, "priceRanges": $price_ranges, "promoter": $promoter, "publicVisibility": $public_visibility, "references": $references, "relationships": $relationships, "sales": $sales, "source": $body_source, "test": $test, "type": $type, "units": $units, "url": $url, "venue": $venue, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"TMPS-Correlation-Id": $tmps_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Publish a patch on an event
#
# PATCH /publish/v2/events/{id}
# operationId: patchEvent
# --changes item shape: {from?: string, op: "add"|"remove"|"replace"|"move"|"copy"|"test", path: string, value?: record}
export def "publish-events update" [
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
  --tmps-correlation-id: string # Unique correlation id to be able to trace the request in our system
  changes: list # List of changes to apply to the related entity — item shape: {from?: string, op: "add"|"remove"|"replace"|"move"|"copy"|"test", path: string, value?: record}
  related_entity_id: string # Id of the entity to apply the augmentation data.
  related_entity_type: string@related-entity-type-completer # The type of the entity to apply the augmentation data.
  --score: float # The confidence (%) level of the accuracy of this augmention data. 100 is the better (format: float)
  --body-source: string # The source where the augementation data came from
  version_number: int # Vesion of this augmentation data. This field is to avoid updating entity with old data. (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/publish/v2/events/{id}"))
  let req_body = {"changes": $changes, "relatedEntityId": $related_entity_id, "relatedEntityType": $related_entity_type, "score": $score, "source": $body_source, "versionNumber": $version_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"TMPS-Correlation-Id": $tmps_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Publish a video on an event
#
# POST /publish/v2/events/{id}/videos
# operationId: publishEventVideos
# --licensingInformation shape: {license: string, regionRestriction?: record}
# --source shape: {id?: string, name?: string}
export def "publish-events-videos publish" [
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
  --tmps-correlation-id: string # Unique correlation id to be able to trace the request in our system
  --embed-url: string # The url of the embeded video
  licensing_information: record # This class defines an entitlement data on the Publish API — shape: {license: string, regionRestriction?: record}
  --body-source: record # Source — shape: {id?: string, name?: string}
  url: string # The url of the video
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/publish/v2/events/{id}/videos"))
  let req_body = {"embedUrl": $embed_url, "licensingInformation": $licensing_information, "source": $body_source, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"TMPS-Correlation-Id": $tmps_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Publish extension on an entity
#
# POST /publish/v2/extensions
# operationId: publishExtension
# --relatedEntitySource shape: {id?: string, name?: string}
export def "publish-extensions publish" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tmps-correlation-id: string # Unique correlation id to be able to trace the request in our system
  data: record # The actual information to add to the entity
  --related-entity-id: string # Id of the entity to add this extionsion to. If the relatedEntityId is Null, a relatedEntitySource MUST be provided
  --related-entity-source: record # Source — shape: {id?: string, name?: string}
  related_entity_type: string@related-entity-type-completer # The type of the entity to add this extensions to
  --body-source: string # Source of the extension, where it came from
  type: string # The type of the extension. This represent the data sent
  --version-number: int # Version of the extensions. Version is to prevent to override an extension with an older one (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/publish/v2/extensions")
  let req_body = {"data": $data, "relatedEntityId": $related_entity_id, "relatedEntitySource": $related_entity_source, "relatedEntityType": $related_entity_type, "source": $body_source, "type": $type, "versionNumber": $version_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"TMPS-Correlation-Id": $tmps_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Publish a venue
#
# POST /publish/v2/venues
# operationId: publishVenue
# --address shape: {line1s?: record, line2s?: record, line3s?: record}
# --boxOfficeInfo shape: {acceptedPaymentDetails?: record, openHoursDetails?: record, phoneNumberDetails?: record, willCallDetails?: record}
# --city shape: {names?: record}
# --country shape: {countryCode?: string, names?: record}
# --dma item shape: {id?: int}
# --generalInfo shape: {childRules?: record, generalRules?: record}
# --images item shape: {attribution?: string, domains?: list<string>, fallback?: bool, height?: int, ratio?: "16_9"|"3_2"|"4_3", url?: string, width?: int}
# --location shape: {latitude?: float, longitude?: float}
# --markets item shape: {id?: string}
# --social shape: {twitter?: record}
# --source shape: {id?: string, name?: string}
# --state shape: {names?: record, stateCode?: string}
export def "publish-venues publish" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tmps-correlation-id: string # Unique correlation id to be able to trace the request in our system
  --accessible-seating-details: record # Venue accessible seating details - multi-lingual fields (e.g. en-us:seatingDetails)
  --active: oneof<nothing, bool> # Indicate if the entity is active, inactive entity won't appear in Discovery API (default: false)
  --additional-infos: record # Additional informations of the entity - multi-lingual fields (e.g. en-us: additionalInfo)
  --address: record # Address — shape: {line1s?: record, line2s?: record, line3s?: record}
  --box-office-info: record # Venue box office information — shape: {acceptedPaymentDetails?: record, openHoursDetails?: record, phoneNumberDetails?: record, willCallDetails?: record}
  --city: record # City — shape: {names?: record}
  --country: record # Country — shape: {countryCode?: string, names?: record}
  --currency: string # Default currency of ticket prices for events in this venue
  --descriptions: record # Descriptions of the entity - multi-lingual fields (e.g. en-us: description)
  --discoverable: oneof<nothing, bool> # True if the entity is dicoverable in discovery API (default: false)
  --distance: float # format: double
  --dma: list # The list of associated DMAs (Designated Market Areas) of the venue — item shape: {id?: int}
  --general-info: record # Venue general information — shape: {childRules?: record, generalRules?: record}
  --images: list # Images of the entity — item shape: {attribution?: string, domains?: list<string>, fallback?: bool, height?: int, ratio?: "16_9"|"3_2"|"4_3", url?: string, width?: int}
  --location: record # Location — shape: {latitude?: float, longitude?: float}
  --markets: list # Markets of the venue — item shape: {id?: string}
  --names: record # Names of the entity - multi-lingual fields (e.g. en-us: name)
  --parking-details: record # Venue parking info - multi-lingual fields (e.g. en-us:parkingDetails)
  --postal-code: string # Postal code / zipcode of the venue
  --references: record # References of this entity in an other system. Reference is the exact same entity (e.g. sourceName: id)
  --relationships: list # Relationships on the entity, like if the entity is a duplicate of another one
  --social: record # Social networks data — shape: {twitter?: record}
  --body-source: record # Source — shape: {id?: string, name?: string}
  --state: record # State — shape: {names?: record, stateCode?: string}
  --test: oneof<nothing, bool> # Indicate if this is a test entity, by default test entities won't appear in discovery API (default: false)
  --timezone: string # Timezone of the venue
  type: string@type-completer # Type of the entity
  --units: string
  --url: string # URL of a web site detail page of the entity
  --version: int # Version of the entity. Version is to avoid updated an entity with an older version (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/publish/v2/venues")
  let req_body = {"accessibleSeatingDetails": $accessible_seating_details, "active": $active, "additionalInfos": $additional_infos, "address": $address, "boxOfficeInfo": $box_office_info, "city": $city, "country": $country, "currency": $currency, "descriptions": $descriptions, "discoverable": $discoverable, "distance": $distance, "dma": $dma, "generalInfo": $general_info, "images": $images, "location": $location, "markets": $markets, "names": $names, "parkingDetails": $parking_details, "postalCode": $postal_code, "references": $references, "relationships": $relationships, "social": $social, "source": $body_source, "state": $state, "test": $test, "timezone": $timezone, "type": $type, "units": $units, "url": $url, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"TMPS-Correlation-Id": $tmps_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Publish a patch on a venue
#
# PATCH /publish/v2/venues/{id}
# operationId: patchVenue
# --changes item shape: {from?: string, op: "add"|"remove"|"replace"|"move"|"copy"|"test", path: string, value?: record}
export def "publish-venues update" [
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
  --tmps-correlation-id: string # Unique correlation id to be able to trace the request in our system
  changes: list # List of changes to apply to the related entity — item shape: {from?: string, op: "add"|"remove"|"replace"|"move"|"copy"|"test", path: string, value?: record}
  related_entity_id: string # Id of the entity to apply the augmentation data.
  related_entity_type: string@related-entity-type-completer # The type of the entity to apply the augmentation data.
  --score: float # The confidence (%) level of the accuracy of this augmention data. 100 is the better (format: float)
  --body-source: string # The source where the augementation data came from
  version_number: int # Vesion of this augmentation data. This field is to avoid updating entity with old data. (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/publish/v2/venues/{id}"))
  let req_body = {"changes": $changes, "relatedEntityId": $related_entity_id, "relatedEntityType": $related_entity_type, "score": $score, "source": $body_source, "versionNumber": $version_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"TMPS-Correlation-Id": $tmps_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
