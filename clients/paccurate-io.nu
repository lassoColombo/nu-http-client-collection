# Auto-generated client for paccurate.io v0.1.1
# Source: https://api.apis.guru/v2/specs/paccurate.io/0.1.1/swagger.json
# Auth: --token flag or $env.PACCURATE_IO_TOKEN

const BASE_URL = "https://localhost"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PACCURATE_IO_TOKEN | default "" }
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

def base-url-completer [] { ["https://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def placement-style-completer [] { ["corner" "default" "mound" "orb" "wedge"] }
def template-completer [] { ["boat.tmpl" "demo.tmpl" "shipapp.tmpl"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api create" } } | get name | first)
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

# a pure-JSON endpoint for packing requests.
#
# POST /
# --boxTypes item shape: {dimensions: any, name?: string, price?: int, rateTable?: any, weightMax: float, weightTare?: float}
# --itemSets item shape: {color?: string, dimensions: any, name?: string, refId?: int, sequence?: string, weight: float, quantity?: int}
# --rules item shape: {itemRefId?: int, operation: "exclude"|"exclude-all"|"pack-as-is"|"irregular"|"lock-orientation", options?: record, parameters?: list<string>, targetItemRefIds?: list<int>}
export def "api create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowable-overhang: float # The amount an item can overhang lower items that it is placed upon. The units are whatever units the box and item dimensions are given in. By convention, inches. (default: -1)
  --box-type-sets: list<string> # predefined box types to be used, separated by commas. Will be overridden by boxTypes. Acceptable values are "fedex"--FedEx OneRate"usps"--USPS Priority Flat Rate"pallet"--full-, half-, and quarter-sized 48"x40" pallets.
  --box-types: list # box type definitions for packing, will override boxTypeSets defined. — item shape: {dimensions: any, name?: string, price?: int, rateTable?: any, weightMax: float, weightTare?: float}
  --cohort-max: int # the maximum number of contiguous cohorts for a given item type within a single container. E.g., if you pack 40 chairs in a single container, a cohortMax of 2 could yield one (all 40 chairs in a single block if space is availabe) or two (say, 25 chairs in one corner and 15 in the other) contiguous cohorts. (default: 2)
  --cohort-packing: oneof<nothing, bool> # if selected, will ensure that all like items will be packed together, in no more than [cohortMax] different groups within a single container. (default: false)
  --coord-order: list<int> # If placementStyle is set to "default", coordOrder sets the placement priority of axes ascendingly. "0,1,2" would search for placement points along the Z(length,"2"), then Y(width,"1"), and finally X(height"0"). Keep in mind that in the default rendering the "up" direction is X and the other axes follow the right-hand rule. This is useful for different packing methods. E.g., Utilizing "2,0,1" would pack a shipping container first in the Y(width) direction, then in the X(height) direction, and finally in the Z(length) direction, replication a floor-to-ceiling, front-to-back loading method.
  --corners: oneof<nothing, bool> # only pack items at valid corner points of other items (optimal) (default: true)
  --eye: any # The x,y,z coordinates of the virtual eye looking at the package for visualization purposes. Default is isometric, "1,1,1". To generate a side view, one could use "0.001,1.0,0.001".
  --img-size: int # width of rendered SVGs in pixels. (default: 400)
  --include-images: oneof<nothing, bool> # include inline images, default is always on (default: true)
  --include-scripts: oneof<nothing, bool> # include inline javascripts and styles for base template (default: true)
  --interlock: oneof<nothing, bool> # alternates layFlat orientation by layer, so as to create an interlocked placement pattern and improve item stability. (default: false)
  --item-sets: list # item set definitions if not creating random items. — item shape: {color?: string, dimensions: any, name?: string, refId?: int, sequence?: string, weight: float, quantity?: int}
  --key: string # issued API key.
  --lay-flat: oneof<nothing, bool> # aligns all items laying flat. If possible, it may create a "brick-laying" pattern to increase stability. (default: false)
  --max-sequence-distance: int # This is the maximum distance allowable between two sequence values of items packed in a common box. E.g., "Distance" for an item sequence composed of aisle/bin combinations of "0401" and "1228" has a sequence distance of \|1228 - 401\| = 827
  --n: int # number of random items to generate and the quantity of each if "random" is set to true. a value of 5 would create 5 different items with a quantity of 5 each, making the total item quantity equal to n&sup2; (default: 5)
  --pack-origin: any # the x,y,z coordinates of an optional packing origin. A packing origin is used to create more balanced packing for situations where load needs to be considered. E.g., for a 40"x48" pallet, a packOrigin representing the middle of the pallet, "0,20,24", would cause placement to minimize the distance of the packed items from the center of the pallet.
  --placement-style: string@placement-style-completer # How to place items. 'default' will defer to coordOrder, 'corner' minimizes distance to rear, bottom corner, 'wedge' minimizes distance to middle of bottom, back edge, 'mound' minimizes distance to center of carton bottom. (default: default)
  --random: oneof<nothing, bool> # create random items (default: false)
  --random-max-dimension: int # maximum item dimension along a single axis for randomly generated items. (default: 10)
  --random-max-weight: int # maximum item weight for randomly generated items. (default: 10)
  --rules: list # Array of packing rules. — item shape: {itemRefId?: int, operation: "exclude"|"exclude-all"|"pack-as-is"|"irregular"|"lock-orientation", options?: record, parameters?: list<string>, targetItemRefIds?: list<int>}
  --seed: oneof<nothing, bool> # if random is selected, seed the random number generator to deterministically generate random items to pack. (default: true)
  --sequence-heat-map: oneof<nothing, bool> # Colorize items solely by their sequence value, light when sequence is high, dark when it is low. Useful for indicating item bin location, weight, or other sequence property that may not be apparent from the default visualization. (default: false)
  --sequence-sort: oneof<nothing, bool> # Whether or not the items should be initially sorted by their sequence value instead of their volume. This is not always useful, as the default "biggest-first" volume sort is very effective for items, and constraining by maxSequenceDistance is applied regardless of this field. That said, for doing custom pre-sorts such as weight-based instead of volume based, this value should be set to true. (default: false)
  --template: string@template-completer # template name for markup generation.
  --usable-space: float # estimate of percentage space in boxes that is usable, i.e., not packing material. (default: 0.5)
  --zone: int # [experimental] the shipping zone in order to use basic zone-based price optimization.
]: any -> record<boxes: table<dimensions: record, name: string, price: int, rateTable: record, weightMax: float, weightTare: float, dimensionalWeight: float, dimensionalWeightUsed: bool, id: int, items: list, svg: string, volumeMax: float, volumeRemaining: float, volumeUsed: float, volumeUtilization: float, weightNet: float, weightRemaining: float, weightUsed: float, weightUtilization: float>, built: string, leftovers: table<color: string, dimensions: record, name: string, refId: int, sequence: string, weight: float, index: int, message: string, origin: record>, lenBoxes: int, lenItems: int, lenLeftovers: int, packTime: float, renderTime: float, scripts: string, styles: string, svgs: string, title: string, totalCost: int, totalTime: float, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"allowableOverhang": $allowable_overhang, "boxTypeSets": $box_type_sets, "boxTypes": $box_types, "cohortMax": $cohort_max, "cohortPacking": $cohort_packing, "coordOrder": $coord_order, "corners": $corners, "eye": $eye, "imgSize": $img_size, "includeImages": $include_images, "includeScripts": $include_scripts, "interlock": $interlock, "itemSets": $item_sets, "key": $key, "layFlat": $lay_flat, "maxSequenceDistance": $max_sequence_distance, "n": $n, "packOrigin": $pack_origin, "placementStyle": $placement_style, "random": $random, "randomMaxDimension": $random_max_dimension, "randomMaxWeight": $random_max_weight, "rules": $rules, "seed": $seed, "sequenceHeatMap": $sequence_heat_map, "sequenceSort": $sequence_sort, "template": $template, "usableSpace": $usable_space, "zone": $zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
