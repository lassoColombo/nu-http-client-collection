# Auto-generated client for paccurate.io v0.1.1
# Source: https://api.apis.guru/v2/specs/paccurate.io/0.1.1/swagger.json
# Auth: --token flag or $env.PACCURATE_IO_TOKEN

const BASE_URL = "https://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PACCURATE_IO_TOKEN | default "" }
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

def base-url-completer [] { ["https://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def placementStyle-completer [] { ["corner" "default" "mound" "orb" "wedge"] }
def template-completer [] { ["boat.tmpl" "demo.tmpl" "shipapp.tmpl"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api post" } } | get name | first)
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
# --rules item shape: {itemRefId?: int, operation: "exclude"|"exclude-all"|"pack-as-is"|"irregular"|"lock-orientation", options?: record, parameters?: list, targetItemRefIds?: list}
export def "api post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowableOverhang: float # The amount an item can overhang lower items that it is placed upon. The units are whatever units the box and item dimensions are given in. By convention, inches. (default: -1)
  --boxTypeSets: list # predefined box types to be used, separated by commas. Will be overridden by boxTypes. Acceptable values are <ul><li>"fedex"--FedEx OneRate</li><li>"usps"--USPS Priority Flat Rate</li><li>"pallet"--full-, half-, and quarter-sized 48"x40" pallets.
  --boxTypes: list # box type definitions for packing, will override boxTypeSets defined. — item shape: {dimensions: any, name?: string, price?: int, rateTable?: any, weightMax: float, weightTare?: float}
  --cohortMax: int # the maximum number of contiguous cohorts for a given item type within a single container. E.g., if you pack 40 chairs in a single container, a cohortMax of 2 could yield one (all 40 chairs in a single block if space is availabe) or two (say, 25 chairs in one corner and 15 in the other) contiguous cohorts. (default: 2)
  --cohortPacking: oneof<nothing, bool> # if selected, will ensure that all like items will be packed together, in no more than [cohortMax] different groups within a single container. (default: false)
  --coordOrder: list # If placementStyle is set to "default", coordOrder sets the placement priority of axes ascendingly. "0,1,2" would search for placement points along the Z(length,"2"), then Y(width,"1"), and finally X(height"0"). Keep in mind that in the default rendering the "up" direction is X and the other axes follow the right-hand rule. This is useful for different packing methods. E.g., Utilizing "2,0,1" would pack a shipping container first in the Y(width) direction, then in the X(height) direction, and finally in the Z(length) direction, replication a floor-to-ceiling, front-to-back loading method.
  --corners: oneof<nothing, bool> # only pack items at valid corner points of other items (optimal) (default: true)
  --eye: any # The x,y,z coordinates of the virtual eye looking at the package for visualization purposes. Default is isometric, "1,1,1". To generate a side view, one could use "0.001,1.0,0.001".
  --imgSize: int # width of rendered SVGs in pixels. (default: 400)
  --includeImages: oneof<nothing, bool> # include inline images, default is always on (default: true)
  --includeScripts: oneof<nothing, bool> # include inline javascripts and styles for base template (default: true)
  --interlock: oneof<nothing, bool> # alternates layFlat orientation by layer, so as to create an interlocked placement pattern and improve item stability. (default: false)
  --itemSets: list # item set definitions if not creating random items. — item shape: {color?: string, dimensions: any, name?: string, refId?: int, sequence?: string, weight: float, quantity?: int}
  --key: string # issued API key.
  --layFlat: oneof<nothing, bool> # aligns all items laying flat. If possible, it may create a "brick-laying" pattern to increase stability. (default: false)
  --maxSequenceDistance: int # This is the maximum distance allowable between two sequence values of items packed in a common box. E.g., "Distance" for an item sequence composed of aisle/bin combinations of "0401" and "1228" has a sequence distance of \|1228 - 401\| = 827
  --n: int # number of random items to generate and the quantity of each if "random" is set to true. a value of 5 would create 5 different items with a quantity of 5 each, making the total item quantity equal to n&sup2; (default: 5)
  --packOrigin: any # the x,y,z coordinates of an optional packing origin. A packing origin is used to create more balanced packing for situations where load needs to be considered. E.g., for a 40"x48" pallet, a packOrigin representing the middle of the pallet, "0,20,24", would cause placement to minimize the distance of the packed items from the center of the pallet.
  --placementStyle: string@placementStyle-completer # How to place items. 'default' will defer to coordOrder, 'corner' minimizes distance to rear, bottom corner, 'wedge' minimizes distance to middle of bottom, back edge, 'mound' minimizes distance to center of carton bottom. (default: default)
  --random: oneof<nothing, bool> # create random items (default: false)
  --randomMaxDimension: int # maximum item dimension along a single axis for randomly generated items. (default: 10)
  --randomMaxWeight: int # maximum item weight for randomly generated items. (default: 10)
  --rules: list # Array of packing rules. — item shape: {itemRefId?: int, operation: "exclude"|"exclude-all"|"pack-as-is"|"irregular"|"lock-orientation", options?: record, parameters?: list, targetItemRefIds?: list}
  --seed: oneof<nothing, bool> # if random is selected, seed the random number generator to deterministically generate random items to pack. (default: true)
  --sequenceHeatMap: oneof<nothing, bool> # Colorize items solely by their sequence value, light when sequence is high, dark when it is low. Useful for indicating item bin location, weight, or other sequence property that may not be apparent from the default visualization. (default: false)
  --sequenceSort: oneof<nothing, bool> # Whether or not the items should be initially sorted by their sequence value instead of their volume. This is not always useful, as the default "biggest-first" volume sort is very effective for items, and constraining by maxSequenceDistance is applied regardless of this field. That said, for doing custom pre-sorts such as weight-based instead of volume based, this value should be set to true. (default: false)
  --template: string@template-completer # template name for markup generation.
  --usableSpace: float # estimate of percentage space in boxes that is usable, i.e., not packing material. (default: 0.5)
  --zone: int # <b>[experimental]</b> the shipping zone in order to use basic zone-based price optimization.
]: any -> record<boxes: table<dimensions: record, name: string, price: int, rateTable: record, weightMax: float, weightTare: float, dimensionalWeight: float, dimensionalWeightUsed: bool, id: int, items: list, svg: string, volumeMax: float, volumeRemaining: float, volumeUsed: float, volumeUtilization: float, weightNet: float, weightRemaining: float, weightUsed: float, weightUtilization: float>, built: string, leftovers: table<color: string, dimensions: record, name: string, refId: int, sequence: string, weight: float, index: int, message: string, origin: record>, lenBoxes: int, lenItems: int, lenLeftovers: int, packTime: float, renderTime: float, scripts: string, styles: string, svgs: string, title: string, totalCost: int, totalTime: float, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let body = {allowableOverhang: $allowableOverhang, boxTypeSets: $boxTypeSets, boxTypes: $boxTypes, cohortMax: $cohortMax, cohortPacking: $cohortPacking, coordOrder: $coordOrder, corners: $corners, eye: $eye, imgSize: $imgSize, includeImages: $includeImages, includeScripts: $includeScripts, interlock: $interlock, itemSets: $itemSets, key: $key, layFlat: $layFlat, maxSequenceDistance: $maxSequenceDistance, n: $n, packOrigin: $packOrigin, placementStyle: $placementStyle, random: $random, randomMaxDimension: $randomMaxDimension, randomMaxWeight: $randomMaxWeight, rules: $rules, seed: $seed, sequenceHeatMap: $sequenceHeatMap, sequenceSort: $sequenceSort, template: $template, usableSpace: $usableSpace, zone: $zone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
