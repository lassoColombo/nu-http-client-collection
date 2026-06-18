# Auto-generated client for NetBox API v2.8
# Source: https://api.apis.guru/v2/specs/netboxdemo.com/2.8/openapi.json
# Auth: --token flag or $env.NETBOX_API_TOKEN

const BASE_URL = "https://netboxdemo.com/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NETBOX_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://netboxdemo.com/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def connection-status-completer [] { ["false" "true"] }
def term-side-completer [] { ["A" "Z"] }
def status-completer [] { ["active" "decommissioned" "deprovisioning" "offline" "planned" "provisioning"] }
def length-unit-completer [] { ["cm" "ft" "in" "m"] }
def status-completer-1 [] { ["connected" "decommissioning" "planned"] }
def type-completer [] { ["aoc" "cat3" "cat5" "cat5e" "cat6" "cat6a" "cat7" "coaxial" "dac-active" "dac-passive" "mmf" "mmf-om1" "mmf-om2" "mmf-om3" "mmf-om4" "mrj21-trunk" "power" "smf" "smf-os1" "smf-os2"] }
def type-completer-1 [] { ["db-25" "de-9" "other" "rj-11" "rj-12" "rj-45" "usb-a" "usb-b" "usb-c" "usb-micro-a" "usb-micro-b" "usb-mini-a" "usb-mini-b"] }
def subdevice-role-completer [] { ["child" "parent"] }
def face-completer [] { ["front" "rear"] }
def status-completer-2 [] { ["active" "decommissioning" "failed" "inventory" "offline" "planned" "staged"] }
def type-completer-2 [] { ["110-punch" "8p8c" "bnc" "fc" "lc" "lc-apc" "lsh" "lsh-apc" "mpo" "mrj21" "mtrj" "sc" "sc-apc" "st"] }
def type-completer-3 [] { ["1000base-t" "1000base-x-gbic" "1000base-x-sfp" "100base-tx" "100gbase-x-cfp" "100gbase-x-cfp2" "100gbase-x-cfp4" "100gbase-x-cpak" "100gbase-x-qsfp28" "10gbase-cx4" "10gbase-t" "10gbase-x-sfpp" "10gbase-x-x2" "10gbase-x-xenpak" "10gbase-x-xfp" "128gfc-sfp28" "16gfc-sfpp" "1gfc-sfp" "2.5gbase-t" "200gbase-x-cfp2" "200gbase-x-qsfp56" "25gbase-x-sfp28" "2gfc-sfp" "32gfc-sfp28" "400gbase-x-osfp" "400gbase-x-qsfpdd" "40gbase-x-qsfpp" "4gfc-sfp" "50gbase-x-sfp28" "5gbase-t" "8gfc-sfpp" "cdma" "cisco-flexstack" "cisco-flexstack-plus" "cisco-stackwise" "cisco-stackwise-plus" "e1" "e3" "extreme-summitstack" "extreme-summitstack-128" "extreme-summitstack-256" "extreme-summitstack-512" "gsm" "ieee802.11a" "ieee802.11ac" "ieee802.11ad" "ieee802.11ax" "ieee802.11g" "ieee802.11n" "infiniband-ddr" "infiniband-edr" "infiniband-fdr" "infiniband-fdr10" "infiniband-hdr" "infiniband-ndr" "infiniband-qdr" "infiniband-sdr" "infiniband-xdr" "juniper-vcp" "lag" "lte" "other" "sonet-oc12" "sonet-oc192" "sonet-oc1920" "sonet-oc3" "sonet-oc3840" "sonet-oc48" "sonet-oc768" "t1" "t3" "virtual"] }
def mode-completer [] { ["access" "tagged" "tagged-all"] }
def phase-completer [] { ["single-phase" "three-phase"] }
def status-completer-3 [] { ["active" "failed" "offline" "planned"] }
def supply-completer [] { ["ac" "dc"] }
def type-completer-4 [] { ["primary" "redundant"] }
def feed-leg-completer [] { ["A" "B" "C"] }
def type-completer-5 [] { ["CS6360C" "CS6364C" "CS8164C" "CS8264C" "CS8364C" "CS8464C" "hdot-cx" "iec-60309-2p-e-4h" "iec-60309-2p-e-6h" "iec-60309-2p-e-9h" "iec-60309-3p-e-4h" "iec-60309-3p-e-6h" "iec-60309-3p-e-9h" "iec-60309-3p-n-e-4h" "iec-60309-3p-n-e-6h" "iec-60309-3p-n-e-9h" "iec-60309-p-n-e-4h" "iec-60309-p-n-e-6h" "iec-60309-p-n-e-9h" "iec-60320-c13" "iec-60320-c15" "iec-60320-c19" "iec-60320-c5" "iec-60320-c7" "ita-e" "ita-f" "ita-g" "ita-h" "ita-i" "ita-j" "ita-k" "ita-l" "ita-m" "ita-n" "ita-o" "nema-1-15r" "nema-10-30r" "nema-10-50r" "nema-14-20r" "nema-14-30r" "nema-14-50r" "nema-14-60r" "nema-5-15r" "nema-5-20r" "nema-5-30r" "nema-5-50r" "nema-6-15r" "nema-6-20r" "nema-6-30r" "nema-6-50r" "nema-l1-15r" "nema-l10-30r" "nema-l14-20r" "nema-l14-30r" "nema-l14-50r" "nema-l14-60r" "nema-l21-20r" "nema-l21-30r" "nema-l5-15r" "nema-l5-20r" "nema-l5-30r" "nema-l5-50r" "nema-l6-15r" "nema-l6-20r" "nema-l6-30r" "nema-l6-50r"] }
def type-completer-6 [] { ["cs6361c" "cs6365c" "cs8165c" "cs8265c" "cs8365c" "cs8465c" "iec-60309-2p-e-4h" "iec-60309-2p-e-6h" "iec-60309-2p-e-9h" "iec-60309-3p-e-4h" "iec-60309-3p-e-6h" "iec-60309-3p-e-9h" "iec-60309-3p-n-e-4h" "iec-60309-3p-n-e-6h" "iec-60309-3p-n-e-9h" "iec-60309-p-n-e-4h" "iec-60309-p-n-e-6h" "iec-60309-p-n-e-9h" "iec-60320-c14" "iec-60320-c16" "iec-60320-c20" "iec-60320-c6" "iec-60320-c8" "ita-e" "ita-ef" "ita-f" "ita-g" "ita-h" "ita-i" "ita-j" "ita-k" "ita-l" "ita-m" "ita-n" "ita-o" "nema-1-15p" "nema-10-30p" "nema-10-50p" "nema-14-20p" "nema-14-30p" "nema-14-50p" "nema-14-60p" "nema-5-15p" "nema-5-20p" "nema-5-30p" "nema-5-50p" "nema-6-15p" "nema-6-20p" "nema-6-30p" "nema-6-50p" "nema-l1-15p" "nema-l10-30p" "nema-l14-20p" "nema-l14-30p" "nema-l14-50p" "nema-l14-60p" "nema-l21-20p" "nema-l21-30p" "nema-l5-15p" "nema-l5-20p" "nema-l5-30p" "nema-l5-50p" "nema-l6-15p" "nema-l6-20p" "nema-l6-30p" "nema-l6-50p"] }
def outer-unit-completer [] { ["in" "mm"] }
def status-completer-4 [] { ["active" "available" "deprecated" "planned" "reserved"] }
def type-completer-7 [] { ["2-post-frame" "4-post-cabinet" "4-post-frame" "wall-cabinet" "wall-frame"] }
def width-completer [] { ["10" "19" "21" "23"] }
def render-completer [] { ["json" "svg"] }
def status-completer-5 [] { ["active" "planned" "retired"] }
def template-language-completer [] { ["django" "jinja2"] }
def role-completer [] { ["anycast" "carp" "glbp" "hsrp" "loopback" "secondary" "vip" "vrrp"] }
def status-completer-6 [] { ["active" "deprecated" "dhcp" "reserved"] }
def status-completer-7 [] { ["active" "container" "deprecated" "reserved"] }
def protocol-completer [] { ["tcp" "udp"] }
def status-completer-8 [] { ["active" "deprecated" "reserved"] }
def status-completer-9 [] { ["active" "decommissioning" "failed" "offline" "planned" "staged"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "circuits-circuit-terminations list" } } | get name | first)
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

# Call to super to allow for caching
#
# GET /circuits/circuit-terminations/
# operationId: circuits_circuit-terminations_list
export def "circuits-circuit-terminations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --term-side: string
  --port-speed: string
  --upstream-speed: string
  --xconnect-id: string
  --q: string
  --circuit-id: string
  --site-id: string
  --site: string
  --term-side-n: string
  --port-speed-n: string
  --port-speed-lte: string
  --port-speed-lt: string
  --port-speed-gte: string
  --port-speed-gt: string
  --upstream-speed-n: string
  --upstream-speed-lte: string
  --upstream-speed-lt: string
  --upstream-speed-gte: string
  --upstream-speed-gt: string
  --xconnect-id-n: string
  --xconnect-id-ic: string
  --xconnect-id-nic: string
  --xconnect-id-iew: string
  --xconnect-id-niew: string
  --xconnect-id-isw: string
  --xconnect-id-nisw: string
  --xconnect-id-ie: string
  --xconnect-id-nie: string
  --circuit-id-n: string
  --site-id-n: string
  --site-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<cable: record, circuit: record, connected_endpoint: record, connected_endpoint_type: string, connection_status: record, description: string, id: int, port_speed: int, pp_info: string, site: record, term_side: string, upstream_speed: int, xconnect_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term_side" $term_side "scalar") (serialize-qp "port_speed" $port_speed "scalar") (serialize-qp "upstream_speed" $upstream_speed "scalar") (serialize-qp "xconnect_id" $xconnect_id "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "circuit_id" $circuit_id "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "term_side__n" $term_side_n "scalar") (serialize-qp "port_speed__n" $port_speed_n "scalar") (serialize-qp "port_speed__lte" $port_speed_lte "scalar") (serialize-qp "port_speed__lt" $port_speed_lt "scalar") (serialize-qp "port_speed__gte" $port_speed_gte "scalar") (serialize-qp "port_speed__gt" $port_speed_gt "scalar") (serialize-qp "upstream_speed__n" $upstream_speed_n "scalar") (serialize-qp "upstream_speed__lte" $upstream_speed_lte "scalar") (serialize-qp "upstream_speed__lt" $upstream_speed_lt "scalar") (serialize-qp "upstream_speed__gte" $upstream_speed_gte "scalar") (serialize-qp "upstream_speed__gt" $upstream_speed_gt "scalar") (serialize-qp "xconnect_id__n" $xconnect_id_n "scalar") (serialize-qp "xconnect_id__ic" $xconnect_id_ic "scalar") (serialize-qp "xconnect_id__nic" $xconnect_id_nic "scalar") (serialize-qp "xconnect_id__iew" $xconnect_id_iew "scalar") (serialize-qp "xconnect_id__niew" $xconnect_id_niew "scalar") (serialize-qp "xconnect_id__isw" $xconnect_id_isw "scalar") (serialize-qp "xconnect_id__nisw" $xconnect_id_nisw "scalar") (serialize-qp "xconnect_id__ie" $xconnect_id_ie "scalar") (serialize-qp "xconnect_id__nie" $xconnect_id_nie "scalar") (serialize-qp "circuit_id__n" $circuit_id_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/circuits/circuit-terminations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /circuits/circuit-terminations/
#
# operationId: circuits_circuit-terminations_create
# --cable shape: {label?: string}
export def "circuits-circuit-terminations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  circuit: int
  --connection-status: oneof<nothing, bool>
  --description: string
  port_speed: int
  --pp-info: string
  site: int
  term_side: string@term-side-completer
  --upstream-speed: int # Upstream speed, if different from port speed (nullable)
  --xconnect-id: string
]: any -> record<cable: record<id: int, label: string, url: string>, circuit: record<cid: string, id: int, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, id: int, port_speed: int, pp_info: string, site: record<id: int, name: string, slug: string, url: string>, term_side: string, upstream_speed: int, xconnect_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/circuits/circuit-terminations/")
  let req_body = {"cable": $cable, "circuit": $circuit, "connection_status": $connection_status, "description": $description, "port_speed": $port_speed, "pp_info": $pp_info, "site": $site, "term_side": $term_side, "upstream_speed": $upstream_speed, "xconnect_id": $xconnect_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /circuits/circuit-terminations/{id}/
#
# operationId: circuits_circuit-terminations_delete
export def "circuits-circuit-terminations delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/circuit-terminations/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /circuits/circuit-terminations/{id}/
# operationId: circuits_circuit-terminations_read
export def "circuits-circuit-terminations get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cable: record<id: int, label: string, url: string>, circuit: record<cid: string, id: int, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, id: int, port_speed: int, pp_info: string, site: record<id: int, name: string, slug: string, url: string>, term_side: string, upstream_speed: int, xconnect_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/circuit-terminations/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /circuits/circuit-terminations/{id}/
#
# operationId: circuits_circuit-terminations_partial_update
# --cable shape: {label?: string}
export def "circuits-circuit-terminations update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  circuit: int
  --connection-status: oneof<nothing, bool>
  --description: string
  port_speed: int
  --pp-info: string
  site: int
  term_side: string@term-side-completer
  --upstream-speed: int # Upstream speed, if different from port speed (nullable)
  --xconnect-id: string
]: any -> record<cable: record<id: int, label: string, url: string>, circuit: record<cid: string, id: int, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, id: int, port_speed: int, pp_info: string, site: record<id: int, name: string, slug: string, url: string>, term_side: string, upstream_speed: int, xconnect_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/circuit-terminations/{id}/"))
  let req_body = {"cable": $cable, "circuit": $circuit, "connection_status": $connection_status, "description": $description, "port_speed": $port_speed, "pp_info": $pp_info, "site": $site, "term_side": $term_side, "upstream_speed": $upstream_speed, "xconnect_id": $xconnect_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /circuits/circuit-terminations/{id}/
#
# operationId: circuits_circuit-terminations_update
# --cable shape: {label?: string}
export def "circuits-circuit-terminations update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  circuit: int
  --connection-status: oneof<nothing, bool>
  --description: string
  port_speed: int
  --pp-info: string
  site: int
  term_side: string@term-side-completer
  --upstream-speed: int # Upstream speed, if different from port speed (nullable)
  --xconnect-id: string
]: any -> record<cable: record<id: int, label: string, url: string>, circuit: record<cid: string, id: int, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, id: int, port_speed: int, pp_info: string, site: record<id: int, name: string, slug: string, url: string>, term_side: string, upstream_speed: int, xconnect_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/circuit-terminations/{id}/"))
  let req_body = {"cable": $cable, "circuit": $circuit, "connection_status": $connection_status, "description": $description, "port_speed": $port_speed, "pp_info": $pp_info, "site": $site, "term_side": $term_side, "upstream_speed": $upstream_speed, "xconnect_id": $xconnect_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /circuits/circuit-types/
# operationId: circuits_circuit-types_list
export def "circuits-circuit-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --q: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<circuit_count: int, description: string, id: int, name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/circuits/circuit-types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /circuits/circuit-types/
#
# operationId: circuits_circuit-types_create
export def "circuits-circuit-types create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<circuit_count: int, description: string, id: int, name: string, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/circuits/circuit-types/")
  let req_body = {"description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /circuits/circuit-types/{id}/
#
# operationId: circuits_circuit-types_delete
export def "circuits-circuit-types delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/circuit-types/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /circuits/circuit-types/{id}/
# operationId: circuits_circuit-types_read
export def "circuits-circuit-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<circuit_count: int, description: string, id: int, name: string, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/circuit-types/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /circuits/circuit-types/{id}/
#
# operationId: circuits_circuit-types_partial_update
export def "circuits-circuit-types update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<circuit_count: int, description: string, id: int, name: string, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/circuit-types/{id}/"))
  let req_body = {"description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /circuits/circuit-types/{id}/
#
# operationId: circuits_circuit-types_update
export def "circuits-circuit-types update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<circuit_count: int, description: string, id: int, name: string, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/circuit-types/{id}/"))
  let req_body = {"description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /circuits/circuits/
# operationId: circuits_circuits_list
export def "circuits-circuits list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --cid: string
  --install-date: string
  --commit-rate: string
  --tenant-group-id: string
  --tenant-group: string
  --tenant-id: string
  --tenant: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --provider-id: string
  --provider: string
  --type-id: string
  --type: string
  --status: string
  --site-id: string
  --site: string
  --region-id: string
  --region: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --cid-n: string
  --cid-ic: string
  --cid-nic: string
  --cid-iew: string
  --cid-niew: string
  --cid-isw: string
  --cid-nisw: string
  --cid-ie: string
  --cid-nie: string
  --install-date-n: string
  --install-date-lte: string
  --install-date-lt: string
  --install-date-gte: string
  --install-date-gt: string
  --commit-rate-n: string
  --commit-rate-lte: string
  --commit-rate-lt: string
  --commit-rate-gte: string
  --commit-rate-gt: string
  --tenant-group-id-n: string
  --tenant-group-n: string
  --tenant-id-n: string
  --tenant-n: string
  --provider-id-n: string
  --provider-n: string
  --type-id-n: string
  --type-n: string
  --status-n: string
  --site-id-n: string
  --site-n: string
  --region-id-n: string
  --region-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<cid: string, comments: string, commit_rate: int, created: string, custom_fields: record, description: string, id: int, install_date: string, last_updated: string, provider: record, status: record, tags: list, tenant: record, termination_a: record, termination_z: record, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "cid" $cid "scalar") (serialize-qp "install_date" $install_date "scalar") (serialize-qp "commit_rate" $commit_rate "scalar") (serialize-qp "tenant_group_id" $tenant_group_id "scalar") (serialize-qp "tenant_group" $tenant_group "scalar") (serialize-qp "tenant_id" $tenant_id "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "provider_id" $provider_id "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "type_id" $type_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "cid__n" $cid_n "scalar") (serialize-qp "cid__ic" $cid_ic "scalar") (serialize-qp "cid__nic" $cid_nic "scalar") (serialize-qp "cid__iew" $cid_iew "scalar") (serialize-qp "cid__niew" $cid_niew "scalar") (serialize-qp "cid__isw" $cid_isw "scalar") (serialize-qp "cid__nisw" $cid_nisw "scalar") (serialize-qp "cid__ie" $cid_ie "scalar") (serialize-qp "cid__nie" $cid_nie "scalar") (serialize-qp "install_date__n" $install_date_n "scalar") (serialize-qp "install_date__lte" $install_date_lte "scalar") (serialize-qp "install_date__lt" $install_date_lt "scalar") (serialize-qp "install_date__gte" $install_date_gte "scalar") (serialize-qp "install_date__gt" $install_date_gt "scalar") (serialize-qp "commit_rate__n" $commit_rate_n "scalar") (serialize-qp "commit_rate__lte" $commit_rate_lte "scalar") (serialize-qp "commit_rate__lt" $commit_rate_lt "scalar") (serialize-qp "commit_rate__gte" $commit_rate_gte "scalar") (serialize-qp "commit_rate__gt" $commit_rate_gt "scalar") (serialize-qp "tenant_group_id__n" $tenant_group_id_n "scalar") (serialize-qp "tenant_group__n" $tenant_group_n "scalar") (serialize-qp "tenant_id__n" $tenant_id_n "scalar") (serialize-qp "tenant__n" $tenant_n "scalar") (serialize-qp "provider_id__n" $provider_id_n "scalar") (serialize-qp "provider__n" $provider_n "scalar") (serialize-qp "type_id__n" $type_id_n "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "status__n" $status_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/circuits/circuits/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /circuits/circuits/
#
# operationId: circuits_circuits_create
export def "circuits-circuits create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cid: string
  --comments: string
  --commit-rate: int # nullable
  --custom-fields: record # default: {}
  --description: string
  --install-date: string # nullable, format: date
  provider: int
  --status: string@status-completer
  --tags: list<string>
  --tenant: int # nullable
  type: int
]: any -> record<cid: string, comments: string, commit_rate: int, created: string, custom_fields: record, description: string, id: int, install_date: string, last_updated: string, provider: record<circuit_count: int, id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, termination_a: record<connected_endpoint: record<cable: int, connection_status: record, device: record, id: int, name: string, url: string>, id: int, port_speed: int, site: record<id: int, name: string, slug: string, url: string>, upstream_speed: int, url: string, xconnect_id: string>, termination_z: record<connected_endpoint: record<cable: int, connection_status: record, device: record, id: int, name: string, url: string>, id: int, port_speed: int, site: record<id: int, name: string, slug: string, url: string>, upstream_speed: int, url: string, xconnect_id: string>, type: record<circuit_count: int, id: int, name: string, slug: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/circuits/circuits/")
  let req_body = {"cid": $cid, "comments": $comments, "commit_rate": $commit_rate, "custom_fields": $custom_fields, "description": $description, "install_date": $install_date, "provider": $provider, "status": $status, "tags": $tags, "tenant": $tenant, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /circuits/circuits/{id}/
#
# operationId: circuits_circuits_delete
export def "circuits-circuits delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/circuits/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /circuits/circuits/{id}/
# operationId: circuits_circuits_read
export def "circuits-circuits get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cid: string, comments: string, commit_rate: int, created: string, custom_fields: record, description: string, id: int, install_date: string, last_updated: string, provider: record<circuit_count: int, id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, termination_a: record<connected_endpoint: record<cable: int, connection_status: record, device: record, id: int, name: string, url: string>, id: int, port_speed: int, site: record<id: int, name: string, slug: string, url: string>, upstream_speed: int, url: string, xconnect_id: string>, termination_z: record<connected_endpoint: record<cable: int, connection_status: record, device: record, id: int, name: string, url: string>, id: int, port_speed: int, site: record<id: int, name: string, slug: string, url: string>, upstream_speed: int, url: string, xconnect_id: string>, type: record<circuit_count: int, id: int, name: string, slug: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/circuits/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /circuits/circuits/{id}/
#
# operationId: circuits_circuits_partial_update
export def "circuits-circuits update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cid: string
  --comments: string
  --commit-rate: int # nullable
  --custom-fields: record # default: {}
  --description: string
  --install-date: string # nullable, format: date
  provider: int
  --status: string@status-completer
  --tags: list<string>
  --tenant: int # nullable
  type: int
]: any -> record<cid: string, comments: string, commit_rate: int, created: string, custom_fields: record, description: string, id: int, install_date: string, last_updated: string, provider: record<circuit_count: int, id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, termination_a: record<connected_endpoint: record<cable: int, connection_status: record, device: record, id: int, name: string, url: string>, id: int, port_speed: int, site: record<id: int, name: string, slug: string, url: string>, upstream_speed: int, url: string, xconnect_id: string>, termination_z: record<connected_endpoint: record<cable: int, connection_status: record, device: record, id: int, name: string, url: string>, id: int, port_speed: int, site: record<id: int, name: string, slug: string, url: string>, upstream_speed: int, url: string, xconnect_id: string>, type: record<circuit_count: int, id: int, name: string, slug: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/circuits/{id}/"))
  let req_body = {"cid": $cid, "comments": $comments, "commit_rate": $commit_rate, "custom_fields": $custom_fields, "description": $description, "install_date": $install_date, "provider": $provider, "status": $status, "tags": $tags, "tenant": $tenant, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /circuits/circuits/{id}/
#
# operationId: circuits_circuits_update
export def "circuits-circuits update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cid: string
  --comments: string
  --commit-rate: int # nullable
  --custom-fields: record # default: {}
  --description: string
  --install-date: string # nullable, format: date
  provider: int
  --status: string@status-completer
  --tags: list<string>
  --tenant: int # nullable
  type: int
]: any -> record<cid: string, comments: string, commit_rate: int, created: string, custom_fields: record, description: string, id: int, install_date: string, last_updated: string, provider: record<circuit_count: int, id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, termination_a: record<connected_endpoint: record<cable: int, connection_status: record, device: record, id: int, name: string, url: string>, id: int, port_speed: int, site: record<id: int, name: string, slug: string, url: string>, upstream_speed: int, url: string, xconnect_id: string>, termination_z: record<connected_endpoint: record<cable: int, connection_status: record, device: record, id: int, name: string, url: string>, id: int, port_speed: int, site: record<id: int, name: string, slug: string, url: string>, upstream_speed: int, url: string, xconnect_id: string>, type: record<circuit_count: int, id: int, name: string, slug: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/circuits/{id}/"))
  let req_body = {"cid": $cid, "comments": $comments, "commit_rate": $commit_rate, "custom_fields": $custom_fields, "description": $description, "install_date": $install_date, "provider": $provider, "status": $status, "tags": $tags, "tenant": $tenant, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /circuits/providers/
# operationId: circuits_providers_list
export def "circuits-providers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --asn: string
  --account: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --asn-n: string
  --asn-lte: string
  --asn-lt: string
  --asn-gte: string
  --asn-gt: string
  --account-n: string
  --account-ic: string
  --account-nic: string
  --account-iew: string
  --account-niew: string
  --account-isw: string
  --account-nisw: string
  --account-ie: string
  --account-nie: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<account: string, admin_contact: string, asn: int, circuit_count: int, comments: string, created: string, custom_fields: record, id: int, last_updated: string, name: string, noc_contact: string, portal_url: string, slug: string, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "asn" $asn "scalar") (serialize-qp "account" $account "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "asn__n" $asn_n "scalar") (serialize-qp "asn__lte" $asn_lte "scalar") (serialize-qp "asn__lt" $asn_lt "scalar") (serialize-qp "asn__gte" $asn_gte "scalar") (serialize-qp "asn__gt" $asn_gt "scalar") (serialize-qp "account__n" $account_n "scalar") (serialize-qp "account__ic" $account_ic "scalar") (serialize-qp "account__nic" $account_nic "scalar") (serialize-qp "account__iew" $account_iew "scalar") (serialize-qp "account__niew" $account_niew "scalar") (serialize-qp "account__isw" $account_isw "scalar") (serialize-qp "account__nisw" $account_nisw "scalar") (serialize-qp "account__ie" $account_ie "scalar") (serialize-qp "account__nie" $account_nie "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/circuits/providers/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /circuits/providers/
#
# operationId: circuits_providers_create
export def "circuits-providers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: string
  --admin-contact: string
  --asn: int # 32-bit autonomous system number (nullable)
  --comments: string
  --custom-fields: record # default: {}
  name: string
  --noc-contact: string
  --portal-url: string # format: uri
  slug: string # format: slug
  --tags: list<string>
]: any -> record<account: string, admin_contact: string, asn: int, circuit_count: int, comments: string, created: string, custom_fields: record, id: int, last_updated: string, name: string, noc_contact: string, portal_url: string, slug: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/circuits/providers/")
  let req_body = {"account": $account, "admin_contact": $admin_contact, "asn": $asn, "comments": $comments, "custom_fields": $custom_fields, "name": $name, "noc_contact": $noc_contact, "portal_url": $portal_url, "slug": $slug, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /circuits/providers/{id}/
#
# operationId: circuits_providers_delete
export def "circuits-providers delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/providers/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /circuits/providers/{id}/
# operationId: circuits_providers_read
export def "circuits-providers get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account: string, admin_contact: string, asn: int, circuit_count: int, comments: string, created: string, custom_fields: record, id: int, last_updated: string, name: string, noc_contact: string, portal_url: string, slug: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/providers/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /circuits/providers/{id}/
#
# operationId: circuits_providers_partial_update
export def "circuits-providers update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: string
  --admin-contact: string
  --asn: int # 32-bit autonomous system number (nullable)
  --comments: string
  --custom-fields: record # default: {}
  name: string
  --noc-contact: string
  --portal-url: string # format: uri
  slug: string # format: slug
  --tags: list<string>
]: any -> record<account: string, admin_contact: string, asn: int, circuit_count: int, comments: string, created: string, custom_fields: record, id: int, last_updated: string, name: string, noc_contact: string, portal_url: string, slug: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/providers/{id}/"))
  let req_body = {"account": $account, "admin_contact": $admin_contact, "asn": $asn, "comments": $comments, "custom_fields": $custom_fields, "name": $name, "noc_contact": $noc_contact, "portal_url": $portal_url, "slug": $slug, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /circuits/providers/{id}/
#
# operationId: circuits_providers_update
export def "circuits-providers update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: string
  --admin-contact: string
  --asn: int # 32-bit autonomous system number (nullable)
  --comments: string
  --custom-fields: record # default: {}
  name: string
  --noc-contact: string
  --portal-url: string # format: uri
  slug: string # format: slug
  --tags: list<string>
]: any -> record<account: string, admin_contact: string, asn: int, circuit_count: int, comments: string, created: string, custom_fields: record, id: int, last_updated: string, name: string, noc_contact: string, portal_url: string, slug: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/providers/{id}/"))
  let req_body = {"account": $account, "admin_contact": $admin_contact, "asn": $asn, "comments": $comments, "custom_fields": $custom_fields, "name": $name, "noc_contact": $noc_contact, "portal_url": $portal_url, "slug": $slug, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# A convenience method for rendering graphs for a particular provider.
#
# GET /circuits/providers/{id}/graphs/
# operationId: circuits_providers_graphs
export def "circuits-providers-graphs get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account: string, admin_contact: string, asn: int, circuit_count: int, comments: string, created: string, custom_fields: record, id: int, last_updated: string, name: string, noc_contact: string, portal_url: string, slug: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/circuits/providers/{id}/graphs/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/cables/
# operationId: dcim_cables_list
export def "dcim-cables list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --label: string
  --length: string
  --length-unit: string
  --q: string
  --type: string
  --status: string
  --color: string
  --device-id: string
  --device: string
  --rack-id: string
  --rack: string
  --site-id: string
  --site: string
  --tenant-id: string
  --tenant: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --label-n: string
  --label-ic: string
  --label-nic: string
  --label-iew: string
  --label-niew: string
  --label-isw: string
  --label-nisw: string
  --label-ie: string
  --label-nie: string
  --length-n: string
  --length-lte: string
  --length-lt: string
  --length-gte: string
  --length-gt: string
  --length-unit-n: string
  --type-n: string
  --status-n: string
  --color-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<color: string, id: int, label: string, length: int, length_unit: record, status: record, termination_a: record, termination_a_id: int, termination_a_type: string, termination_b: record, termination_b_id: int, termination_b_type: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "length" $length "scalar") (serialize-qp "length_unit" $length_unit "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "color" $color "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "rack_id" $rack_id "scalar") (serialize-qp "rack" $rack "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "tenant_id" $tenant_id "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "label__n" $label_n "scalar") (serialize-qp "label__ic" $label_ic "scalar") (serialize-qp "label__nic" $label_nic "scalar") (serialize-qp "label__iew" $label_iew "scalar") (serialize-qp "label__niew" $label_niew "scalar") (serialize-qp "label__isw" $label_isw "scalar") (serialize-qp "label__nisw" $label_nisw "scalar") (serialize-qp "label__ie" $label_ie "scalar") (serialize-qp "label__nie" $label_nie "scalar") (serialize-qp "length__n" $length_n "scalar") (serialize-qp "length__lte" $length_lte "scalar") (serialize-qp "length__lt" $length_lt "scalar") (serialize-qp "length__gte" $length_gte "scalar") (serialize-qp "length__gt" $length_gt "scalar") (serialize-qp "length_unit__n" $length_unit_n "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "status__n" $status_n "scalar") (serialize-qp "color__n" $color_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/cables/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/cables/
#
# operationId: dcim_cables_create
export def "dcim-cables create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: string
  --label: string
  --length: int # nullable
  --length-unit: string@length-unit-completer
  --status: string@status-completer-1
  termination_a_id: int
  termination_a_type: string
  termination_b_id: int
  termination_b_type: string
  --type: string@type-completer
]: any -> record<color: string, id: int, label: string, length: int, length_unit: record<label: string, value: string>, status: record<label: string, value: string>, termination_a: record, termination_a_id: int, termination_a_type: string, termination_b: record, termination_b_id: int, termination_b_type: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/cables/")
  let req_body = {"color": $color, "label": $label, "length": $length, "length_unit": $length_unit, "status": $status, "termination_a_id": $termination_a_id, "termination_a_type": $termination_a_type, "termination_b_id": $termination_b_id, "termination_b_type": $termination_b_type, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/cables/{id}/
#
# operationId: dcim_cables_delete
export def "dcim-cables delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/cables/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/cables/{id}/
# operationId: dcim_cables_read
export def "dcim-cables get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<color: string, id: int, label: string, length: int, length_unit: record<label: string, value: string>, status: record<label: string, value: string>, termination_a: record, termination_a_id: int, termination_a_type: string, termination_b: record, termination_b_id: int, termination_b_type: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/cables/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/cables/{id}/
#
# operationId: dcim_cables_partial_update
export def "dcim-cables update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: string
  --label: string
  --length: int # nullable
  --length-unit: string@length-unit-completer
  --status: string@status-completer-1
  termination_a_id: int
  termination_a_type: string
  termination_b_id: int
  termination_b_type: string
  --type: string@type-completer
]: any -> record<color: string, id: int, label: string, length: int, length_unit: record<label: string, value: string>, status: record<label: string, value: string>, termination_a: record, termination_a_id: int, termination_a_type: string, termination_b: record, termination_b_id: int, termination_b_type: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/cables/{id}/"))
  let req_body = {"color": $color, "label": $label, "length": $length, "length_unit": $length_unit, "status": $status, "termination_a_id": $termination_a_id, "termination_a_type": $termination_a_type, "termination_b_id": $termination_b_id, "termination_b_type": $termination_b_type, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/cables/{id}/
#
# operationId: dcim_cables_update
export def "dcim-cables update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: string
  --label: string
  --length: int # nullable
  --length-unit: string@length-unit-completer
  --status: string@status-completer-1
  termination_a_id: int
  termination_a_type: string
  termination_b_id: int
  termination_b_type: string
  --type: string@type-completer
]: any -> record<color: string, id: int, label: string, length: int, length_unit: record<label: string, value: string>, status: record<label: string, value: string>, termination_a: record, termination_a_id: int, termination_a_type: string, termination_b: record, termination_b_id: int, termination_b_type: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/cables/{id}/"))
  let req_body = {"color": $color, "label": $label, "length": $length, "length_unit": $length_unit, "status": $status, "termination_a_id": $termination_a_id, "termination_a_type": $termination_a_type, "termination_b_id": $termination_b_id, "termination_b_type": $termination_b_type, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This endpoint allows a user to determine what device (if any) is connected to a given peer device and peer interface. This is useful in a situation where a device boots with no configuration, but can detect its neighbors via a protocol such as LLDP. Two query parameters must be included in the request: * `peer_device`: The name of the peer device * `peer_interface`: The name of the peer interface
#
# GET /dcim/connected-device/
# operationId: dcim_connected-device_list
export def "dcim-connected-device list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --peer-device: string # The name of the peer device
  --peer-interface: string # The name of the peer interface
]: nothing -> record<asset_tag: string, cluster: record<id: int, name: string, url: string, virtualmachine_count: int>, comments: string, created: string, custom_fields: record, device_role: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, display_name: string, face: record<label: string, value: string>, id: int, last_updated: string, local_context_data: string, name: string, parent_device: record<display_name: string, id: int, name: string, url: string>, platform: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, position: int, primary_ip: record<address: string, family: string, id: int, url: string>, primary_ip4: record<address: string, family: string, id: int, url: string>, primary_ip6: record<address: string, family: string, id: int, url: string>, rack: record<device_count: int, display_name: string, id: int, name: string, url: string>, serial: string, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vc_position: int, vc_priority: int, virtual_chassis: record<id: int, master: record<display_name: string, id: int, name: string, url: string>, member_count: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "peer_device" $peer_device "scalar") (serialize-qp "peer_interface" $peer_interface "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/connected-device/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /dcim/console-connections/
#
# operationId: dcim_console-connections_list
export def "dcim-console-connections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --connection-status: string
  --site: string
  --device-id: string
  --device: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --connection-status-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<cable: record, connected_endpoint: record, connected_endpoint_type: string, connection_status: record, description: string, device: record, id: int, name: string, tags: list, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "connection_status" $connection_status "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "connection_status__n" $connection_status_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/console-connections/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/console-port-templates/
# operationId: dcim_console-port-templates_list
export def "dcim-console-port-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --type: string
  --q: string
  --devicetype-id: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --type-n: string
  --devicetype-id-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<device_type: record, id: int, name: string, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "devicetype_id" $devicetype_id "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "devicetype_id__n" $devicetype_id_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/console-port-templates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/console-port-templates/
#
# operationId: dcim_console-port-templates_create
export def "dcim-console-port-templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  name: string
  --type: string@type-completer-1
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/console-port-templates/")
  let req_body = {"device_type": $device_type, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/console-port-templates/{id}/
#
# operationId: dcim_console-port-templates_delete
export def "dcim-console-port-templates delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-port-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/console-port-templates/{id}/
# operationId: dcim_console-port-templates_read
export def "dcim-console-port-templates get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-port-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/console-port-templates/{id}/
#
# operationId: dcim_console-port-templates_partial_update
export def "dcim-console-port-templates update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  name: string
  --type: string@type-completer-1
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-port-templates/{id}/"))
  let req_body = {"device_type": $device_type, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/console-port-templates/{id}/
#
# operationId: dcim_console-port-templates_update
export def "dcim-console-port-templates update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  name: string
  --type: string@type-completer-1
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-port-templates/{id}/"))
  let req_body = {"device_type": $device_type, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/console-ports/
# operationId: dcim_console-ports_list
export def "dcim-console-ports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --description: string
  --connection-status: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --device-id: string
  --device: string
  --tag: string
  --type: string
  --cabled: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --connection-status-n: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --device-id-n: string
  --device-n: string
  --tag-n: string
  --type-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<cable: record, connected_endpoint: record, connected_endpoint_type: string, connection_status: record, description: string, device: record, id: int, name: string, tags: list, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "connection_status" $connection_status "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "cabled" $cabled "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "connection_status__n" $connection_status_n "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "device_id__n" $device_id_n "scalar") (serialize-qp "device__n" $device_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/console-ports/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/console-ports/
#
# operationId: dcim_console-ports_create
# --cable shape: {label?: string}
export def "dcim-console-ports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --connection-status: oneof<nothing, bool>
  --description: string
  device: int
  name: string
  --tags: list<string>
  --type: string@type-completer-1 # Physical port type
]: any -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/console-ports/")
  let req_body = {"cable": $cable, "connection_status": $connection_status, "description": $description, "device": $device, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/console-ports/{id}/
#
# operationId: dcim_console-ports_delete
export def "dcim-console-ports delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-ports/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/console-ports/{id}/
# operationId: dcim_console-ports_read
export def "dcim-console-ports get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, tags: list<string>, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-ports/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/console-ports/{id}/
#
# operationId: dcim_console-ports_partial_update
# --cable shape: {label?: string}
export def "dcim-console-ports update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --connection-status: oneof<nothing, bool>
  --description: string
  device: int
  name: string
  --tags: list<string>
  --type: string@type-completer-1 # Physical port type
]: any -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-ports/{id}/"))
  let req_body = {"cable": $cable, "connection_status": $connection_status, "description": $description, "device": $device, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/console-ports/{id}/
#
# operationId: dcim_console-ports_update
# --cable shape: {label?: string}
export def "dcim-console-ports update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --connection-status: oneof<nothing, bool>
  --description: string
  device: int
  name: string
  --tags: list<string>
  --type: string@type-completer-1 # Physical port type
]: any -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-ports/{id}/"))
  let req_body = {"cable": $cable, "connection_status": $connection_status, "description": $description, "device": $device, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Trace a complete cable path and return each segment as a three-tuple of (termination, cable, termination).
#
# GET /dcim/console-ports/{id}/trace/
# operationId: dcim_console-ports_trace
export def "dcim-console-ports-trace get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, tags: list<string>, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-ports/{id}/trace/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/console-server-port-templates/
# operationId: dcim_console-server-port-templates_list
export def "dcim-console-server-port-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --type: string
  --q: string
  --devicetype-id: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --type-n: string
  --devicetype-id-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<device_type: record, id: int, name: string, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "devicetype_id" $devicetype_id "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "devicetype_id__n" $devicetype_id_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/console-server-port-templates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/console-server-port-templates/
#
# operationId: dcim_console-server-port-templates_create
export def "dcim-console-server-port-templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  name: string
  --type: string@type-completer-1
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/console-server-port-templates/")
  let req_body = {"device_type": $device_type, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/console-server-port-templates/{id}/
#
# operationId: dcim_console-server-port-templates_delete
export def "dcim-console-server-port-templates delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-server-port-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/console-server-port-templates/{id}/
# operationId: dcim_console-server-port-templates_read
export def "dcim-console-server-port-templates get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-server-port-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/console-server-port-templates/{id}/
#
# operationId: dcim_console-server-port-templates_partial_update
export def "dcim-console-server-port-templates update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  name: string
  --type: string@type-completer-1
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-server-port-templates/{id}/"))
  let req_body = {"device_type": $device_type, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/console-server-port-templates/{id}/
#
# operationId: dcim_console-server-port-templates_update
export def "dcim-console-server-port-templates update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  name: string
  --type: string@type-completer-1
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-server-port-templates/{id}/"))
  let req_body = {"device_type": $device_type, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/console-server-ports/
# operationId: dcim_console-server-ports_list
export def "dcim-console-server-ports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --description: string
  --connection-status: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --device-id: string
  --device: string
  --tag: string
  --type: string
  --cabled: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --connection-status-n: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --device-id-n: string
  --device-n: string
  --tag-n: string
  --type-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<cable: record, connected_endpoint: record, connected_endpoint_type: string, connection_status: record, description: string, device: record, id: int, name: string, tags: list, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "connection_status" $connection_status "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "cabled" $cabled "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "connection_status__n" $connection_status_n "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "device_id__n" $device_id_n "scalar") (serialize-qp "device__n" $device_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/console-server-ports/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/console-server-ports/
#
# operationId: dcim_console-server-ports_create
# --cable shape: {label?: string}
export def "dcim-console-server-ports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --connection-status: oneof<nothing, bool>
  --description: string
  device: int
  name: string
  --tags: list<string>
  --type: string@type-completer-1 # Physical port type
]: any -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/console-server-ports/")
  let req_body = {"cable": $cable, "connection_status": $connection_status, "description": $description, "device": $device, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/console-server-ports/{id}/
#
# operationId: dcim_console-server-ports_delete
export def "dcim-console-server-ports delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-server-ports/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/console-server-ports/{id}/
# operationId: dcim_console-server-ports_read
export def "dcim-console-server-ports get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, tags: list<string>, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-server-ports/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/console-server-ports/{id}/
#
# operationId: dcim_console-server-ports_partial_update
# --cable shape: {label?: string}
export def "dcim-console-server-ports update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --connection-status: oneof<nothing, bool>
  --description: string
  device: int
  name: string
  --tags: list<string>
  --type: string@type-completer-1 # Physical port type
]: any -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-server-ports/{id}/"))
  let req_body = {"cable": $cable, "connection_status": $connection_status, "description": $description, "device": $device, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/console-server-ports/{id}/
#
# operationId: dcim_console-server-ports_update
# --cable shape: {label?: string}
export def "dcim-console-server-ports update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --connection-status: oneof<nothing, bool>
  --description: string
  device: int
  name: string
  --tags: list<string>
  --type: string@type-completer-1 # Physical port type
]: any -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-server-ports/{id}/"))
  let req_body = {"cable": $cable, "connection_status": $connection_status, "description": $description, "device": $device, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Trace a complete cable path and return each segment as a three-tuple of (termination, cable, termination).
#
# GET /dcim/console-server-ports/{id}/trace/
# operationId: dcim_console-server-ports_trace
export def "dcim-console-server-ports-trace get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, tags: list<string>, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/console-server-ports/{id}/trace/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/device-bay-templates/
# operationId: dcim_device-bay-templates_list
export def "dcim-device-bay-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --q: string
  --devicetype-id: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --devicetype-id-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<device_type: record, id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "devicetype_id" $devicetype_id "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "devicetype_id__n" $devicetype_id_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/device-bay-templates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/device-bay-templates/
#
# operationId: dcim_device-bay-templates_create
export def "dcim-device-bay-templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  name: string
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/device-bay-templates/")
  let req_body = {"device_type": $device_type, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/device-bay-templates/{id}/
#
# operationId: dcim_device-bay-templates_delete
export def "dcim-device-bay-templates delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-bay-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/device-bay-templates/{id}/
# operationId: dcim_device-bay-templates_read
export def "dcim-device-bay-templates get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-bay-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/device-bay-templates/{id}/
#
# operationId: dcim_device-bay-templates_partial_update
export def "dcim-device-bay-templates update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  name: string
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-bay-templates/{id}/"))
  let req_body = {"device_type": $device_type, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/device-bay-templates/{id}/
#
# operationId: dcim_device-bay-templates_update
export def "dcim-device-bay-templates update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  name: string
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-bay-templates/{id}/"))
  let req_body = {"device_type": $device_type, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/device-bays/
# operationId: dcim_device-bays_list
export def "dcim-device-bays list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --description: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --device-id: string
  --device: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --device-id-n: string
  --device-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<description: string, device: record, id: int, installed_device: record, name: string, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "device_id__n" $device_id_n "scalar") (serialize-qp "device__n" $device_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/device-bays/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/device-bays/
#
# operationId: dcim_device-bays_create
export def "dcim-device-bays create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  device: int
  --installed-device: int # nullable
  name: string
  --tags: list<string>
]: any -> record<description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, installed_device: record<display_name: string, id: int, name: string, url: string>, name: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/device-bays/")
  let req_body = {"description": $description, "device": $device, "installed_device": $installed_device, "name": $name, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/device-bays/{id}/
#
# operationId: dcim_device-bays_delete
export def "dcim-device-bays delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-bays/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/device-bays/{id}/
# operationId: dcim_device-bays_read
export def "dcim-device-bays get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, installed_device: record<display_name: string, id: int, name: string, url: string>, name: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-bays/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/device-bays/{id}/
#
# operationId: dcim_device-bays_partial_update
export def "dcim-device-bays update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  device: int
  --installed-device: int # nullable
  name: string
  --tags: list<string>
]: any -> record<description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, installed_device: record<display_name: string, id: int, name: string, url: string>, name: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-bays/{id}/"))
  let req_body = {"description": $description, "device": $device, "installed_device": $installed_device, "name": $name, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/device-bays/{id}/
#
# operationId: dcim_device-bays_update
export def "dcim-device-bays update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  device: int
  --installed-device: int # nullable
  name: string
  --tags: list<string>
]: any -> record<description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, installed_device: record<display_name: string, id: int, name: string, url: string>, name: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-bays/{id}/"))
  let req_body = {"description": $description, "device": $device, "installed_device": $installed_device, "name": $name, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/device-roles/
# operationId: dcim_device-roles_list
export def "dcim-device-roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --color: string
  --vm-role: string
  --q: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --color-n: string
  --color-ic: string
  --color-nic: string
  --color-iew: string
  --color-niew: string
  --color-isw: string
  --color-nisw: string
  --color-ie: string
  --color-nie: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<color: string, description: string, device_count: int, id: int, name: string, slug: string, virtualmachine_count: int, vm_role: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "color" $color "scalar") (serialize-qp "vm_role" $vm_role "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "color__n" $color_n "scalar") (serialize-qp "color__ic" $color_ic "scalar") (serialize-qp "color__nic" $color_nic "scalar") (serialize-qp "color__iew" $color_iew "scalar") (serialize-qp "color__niew" $color_niew "scalar") (serialize-qp "color__isw" $color_isw "scalar") (serialize-qp "color__nisw" $color_nisw "scalar") (serialize-qp "color__ie" $color_ie "scalar") (serialize-qp "color__nie" $color_nie "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/device-roles/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/device-roles/
#
# operationId: dcim_device-roles_create
export def "dcim-device-roles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: string
  --description: string
  name: string
  slug: string # format: slug
  --vm-role: oneof<nothing, bool> # Virtual machines may be assigned to this role
]: any -> record<color: string, description: string, device_count: int, id: int, name: string, slug: string, virtualmachine_count: int, vm_role: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/device-roles/")
  let req_body = {"color": $color, "description": $description, "name": $name, "slug": $slug, "vm_role": $vm_role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/device-roles/{id}/
#
# operationId: dcim_device-roles_delete
export def "dcim-device-roles delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-roles/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/device-roles/{id}/
# operationId: dcim_device-roles_read
export def "dcim-device-roles get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<color: string, description: string, device_count: int, id: int, name: string, slug: string, virtualmachine_count: int, vm_role: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-roles/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/device-roles/{id}/
#
# operationId: dcim_device-roles_partial_update
export def "dcim-device-roles update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: string
  --description: string
  name: string
  slug: string # format: slug
  --vm-role: oneof<nothing, bool> # Virtual machines may be assigned to this role
]: any -> record<color: string, description: string, device_count: int, id: int, name: string, slug: string, virtualmachine_count: int, vm_role: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-roles/{id}/"))
  let req_body = {"color": $color, "description": $description, "name": $name, "slug": $slug, "vm_role": $vm_role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/device-roles/{id}/
#
# operationId: dcim_device-roles_update
export def "dcim-device-roles update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: string
  --description: string
  name: string
  slug: string # format: slug
  --vm-role: oneof<nothing, bool> # Virtual machines may be assigned to this role
]: any -> record<color: string, description: string, device_count: int, id: int, name: string, slug: string, virtualmachine_count: int, vm_role: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-roles/{id}/"))
  let req_body = {"color": $color, "description": $description, "name": $name, "slug": $slug, "vm_role": $vm_role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/device-types/
# operationId: dcim_device-types_list
export def "dcim-device-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --model: string
  --slug: string
  --part-number: string
  --u-height: string
  --is-full-depth: string
  --subdevice-role: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --manufacturer-id: string
  --manufacturer: string
  --console-ports: string
  --console-server-ports: string
  --power-ports: string
  --power-outlets: string
  --interfaces: string
  --pass-through-ports: string
  --device-bays: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --model-n: string
  --model-ic: string
  --model-nic: string
  --model-iew: string
  --model-niew: string
  --model-isw: string
  --model-nisw: string
  --model-ie: string
  --model-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --part-number-n: string
  --part-number-ic: string
  --part-number-nic: string
  --part-number-iew: string
  --part-number-niew: string
  --part-number-isw: string
  --part-number-nisw: string
  --part-number-ie: string
  --part-number-nie: string
  --u-height-n: string
  --u-height-lte: string
  --u-height-lt: string
  --u-height-gte: string
  --u-height-gt: string
  --subdevice-role-n: string
  --manufacturer-id-n: string
  --manufacturer-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<comments: string, created: string, custom_fields: record, device_count: int, display_name: string, front_image: string, id: int, is_full_depth: bool, last_updated: string, manufacturer: record, model: string, part_number: string, rear_image: string, slug: string, subdevice_role: record, tags: list, u_height: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "part_number" $part_number "scalar") (serialize-qp "u_height" $u_height "scalar") (serialize-qp "is_full_depth" $is_full_depth "scalar") (serialize-qp "subdevice_role" $subdevice_role "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "manufacturer_id" $manufacturer_id "scalar") (serialize-qp "manufacturer" $manufacturer "scalar") (serialize-qp "console_ports" $console_ports "scalar") (serialize-qp "console_server_ports" $console_server_ports "scalar") (serialize-qp "power_ports" $power_ports "scalar") (serialize-qp "power_outlets" $power_outlets "scalar") (serialize-qp "interfaces" $interfaces "scalar") (serialize-qp "pass_through_ports" $pass_through_ports "scalar") (serialize-qp "device_bays" $device_bays "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "model__n" $model_n "scalar") (serialize-qp "model__ic" $model_ic "scalar") (serialize-qp "model__nic" $model_nic "scalar") (serialize-qp "model__iew" $model_iew "scalar") (serialize-qp "model__niew" $model_niew "scalar") (serialize-qp "model__isw" $model_isw "scalar") (serialize-qp "model__nisw" $model_nisw "scalar") (serialize-qp "model__ie" $model_ie "scalar") (serialize-qp "model__nie" $model_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "part_number__n" $part_number_n "scalar") (serialize-qp "part_number__ic" $part_number_ic "scalar") (serialize-qp "part_number__nic" $part_number_nic "scalar") (serialize-qp "part_number__iew" $part_number_iew "scalar") (serialize-qp "part_number__niew" $part_number_niew "scalar") (serialize-qp "part_number__isw" $part_number_isw "scalar") (serialize-qp "part_number__nisw" $part_number_nisw "scalar") (serialize-qp "part_number__ie" $part_number_ie "scalar") (serialize-qp "part_number__nie" $part_number_nie "scalar") (serialize-qp "u_height__n" $u_height_n "scalar") (serialize-qp "u_height__lte" $u_height_lte "scalar") (serialize-qp "u_height__lt" $u_height_lt "scalar") (serialize-qp "u_height__gte" $u_height_gte "scalar") (serialize-qp "u_height__gt" $u_height_gt "scalar") (serialize-qp "subdevice_role__n" $subdevice_role_n "scalar") (serialize-qp "manufacturer_id__n" $manufacturer_id_n "scalar") (serialize-qp "manufacturer__n" $manufacturer_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/device-types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/device-types/
#
# operationId: dcim_device-types_create
export def "dcim-device-types create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comments: string
  --custom-fields: record # default: {}
  --is-full-depth: oneof<nothing, bool> # Device consumes both front and rear rack faces
  manufacturer: int
  model: string
  --part-number: string # Discrete part number (optional)
  slug: string # format: slug
  --subdevice-role: string@subdevice-role-completer # Parent devices house child devices in device bays. Leave blank if this device type is neither a parent nor a child.
  --tags: list<string>
  --u-height: int
]: any -> record<comments: string, created: string, custom_fields: record, device_count: int, display_name: string, front_image: string, id: int, is_full_depth: bool, last_updated: string, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, part_number: string, rear_image: string, slug: string, subdevice_role: record<label: string, value: string>, tags: list<string>, u_height: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/device-types/")
  let req_body = {"comments": $comments, "custom_fields": $custom_fields, "is_full_depth": $is_full_depth, "manufacturer": $manufacturer, "model": $model, "part_number": $part_number, "slug": $slug, "subdevice_role": $subdevice_role, "tags": $tags, "u_height": $u_height} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/device-types/{id}/
#
# operationId: dcim_device-types_delete
export def "dcim-device-types delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-types/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/device-types/{id}/
# operationId: dcim_device-types_read
export def "dcim-device-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<comments: string, created: string, custom_fields: record, device_count: int, display_name: string, front_image: string, id: int, is_full_depth: bool, last_updated: string, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, part_number: string, rear_image: string, slug: string, subdevice_role: record<label: string, value: string>, tags: list<string>, u_height: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-types/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/device-types/{id}/
#
# operationId: dcim_device-types_partial_update
export def "dcim-device-types update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comments: string
  --custom-fields: record # default: {}
  --is-full-depth: oneof<nothing, bool> # Device consumes both front and rear rack faces
  manufacturer: int
  model: string
  --part-number: string # Discrete part number (optional)
  slug: string # format: slug
  --subdevice-role: string@subdevice-role-completer # Parent devices house child devices in device bays. Leave blank if this device type is neither a parent nor a child.
  --tags: list<string>
  --u-height: int
]: any -> record<comments: string, created: string, custom_fields: record, device_count: int, display_name: string, front_image: string, id: int, is_full_depth: bool, last_updated: string, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, part_number: string, rear_image: string, slug: string, subdevice_role: record<label: string, value: string>, tags: list<string>, u_height: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-types/{id}/"))
  let req_body = {"comments": $comments, "custom_fields": $custom_fields, "is_full_depth": $is_full_depth, "manufacturer": $manufacturer, "model": $model, "part_number": $part_number, "slug": $slug, "subdevice_role": $subdevice_role, "tags": $tags, "u_height": $u_height} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/device-types/{id}/
#
# operationId: dcim_device-types_update
export def "dcim-device-types update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comments: string
  --custom-fields: record # default: {}
  --is-full-depth: oneof<nothing, bool> # Device consumes both front and rear rack faces
  manufacturer: int
  model: string
  --part-number: string # Discrete part number (optional)
  slug: string # format: slug
  --subdevice-role: string@subdevice-role-completer # Parent devices house child devices in device bays. Leave blank if this device type is neither a parent nor a child.
  --tags: list<string>
  --u-height: int
]: any -> record<comments: string, created: string, custom_fields: record, device_count: int, display_name: string, front_image: string, id: int, is_full_depth: bool, last_updated: string, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, part_number: string, rear_image: string, slug: string, subdevice_role: record<label: string, value: string>, tags: list<string>, u_height: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/device-types/{id}/"))
  let req_body = {"comments": $comments, "custom_fields": $custom_fields, "is_full_depth": $is_full_depth, "manufacturer": $manufacturer, "model": $model, "part_number": $part_number, "slug": $slug, "subdevice_role": $subdevice_role, "tags": $tags, "u_height": $u_height} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/devices/
# operationId: dcim_devices_list
export def "dcim-devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --asset-tag: string
  --face: string
  --position: string
  --vc-position: string
  --vc-priority: string
  --tenant-group-id: string
  --tenant-group: string
  --tenant-id: string
  --tenant: string
  --local-context-data: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --manufacturer-id: string
  --manufacturer: string
  --device-type-id: string
  --role-id: string
  --role: string
  --platform-id: string
  --platform: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --rack-group-id: string
  --rack-id: string
  --cluster-id: string
  --model: string
  --status: string
  --is-full-depth: string
  --mac-address: string
  --serial: string
  --has-primary-ip: string
  --virtual-chassis-id: string
  --virtual-chassis-member: string
  --console-ports: string
  --console-server-ports: string
  --power-ports: string
  --power-outlets: string
  --interfaces: string
  --pass-through-ports: string
  --device-bays: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --asset-tag-n: string
  --asset-tag-ic: string
  --asset-tag-nic: string
  --asset-tag-iew: string
  --asset-tag-niew: string
  --asset-tag-isw: string
  --asset-tag-nisw: string
  --asset-tag-ie: string
  --asset-tag-nie: string
  --face-n: string
  --position-n: string
  --position-lte: string
  --position-lt: string
  --position-gte: string
  --position-gt: string
  --vc-position-n: string
  --vc-position-lte: string
  --vc-position-lt: string
  --vc-position-gte: string
  --vc-position-gt: string
  --vc-priority-n: string
  --vc-priority-lte: string
  --vc-priority-lt: string
  --vc-priority-gte: string
  --vc-priority-gt: string
  --tenant-group-id-n: string
  --tenant-group-n: string
  --tenant-id-n: string
  --tenant-n: string
  --manufacturer-id-n: string
  --manufacturer-n: string
  --device-type-id-n: string
  --role-id-n: string
  --role-n: string
  --platform-id-n: string
  --platform-n: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --rack-group-id-n: string
  --rack-id-n: string
  --cluster-id-n: string
  --model-n: string
  --status-n: string
  --mac-address-n: string
  --mac-address-ic: string
  --mac-address-nic: string
  --mac-address-iew: string
  --mac-address-niew: string
  --mac-address-isw: string
  --mac-address-nisw: string
  --mac-address-ie: string
  --mac-address-nie: string
  --virtual-chassis-id-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<asset_tag: string, cluster: record, comments: string, config_context: record, created: string, custom_fields: record, device_role: record, device_type: record, display_name: string, face: record, id: int, last_updated: string, local_context_data: string, name: string, parent_device: record, platform: record, position: int, primary_ip: record, primary_ip4: record, primary_ip6: record, rack: record, serial: string, site: record, status: record, tags: list, tenant: record, vc_position: int, vc_priority: int, virtual_chassis: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "asset_tag" $asset_tag "scalar") (serialize-qp "face" $face "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "vc_position" $vc_position "scalar") (serialize-qp "vc_priority" $vc_priority "scalar") (serialize-qp "tenant_group_id" $tenant_group_id "scalar") (serialize-qp "tenant_group" $tenant_group "scalar") (serialize-qp "tenant_id" $tenant_id "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "local_context_data" $local_context_data "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "manufacturer_id" $manufacturer_id "scalar") (serialize-qp "manufacturer" $manufacturer "scalar") (serialize-qp "device_type_id" $device_type_id "scalar") (serialize-qp "role_id" $role_id "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "platform_id" $platform_id "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "rack_group_id" $rack_group_id "scalar") (serialize-qp "rack_id" $rack_id "scalar") (serialize-qp "cluster_id" $cluster_id "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "is_full_depth" $is_full_depth "scalar") (serialize-qp "mac_address" $mac_address "scalar") (serialize-qp "serial" $serial "scalar") (serialize-qp "has_primary_ip" $has_primary_ip "scalar") (serialize-qp "virtual_chassis_id" $virtual_chassis_id "scalar") (serialize-qp "virtual_chassis_member" $virtual_chassis_member "scalar") (serialize-qp "console_ports" $console_ports "scalar") (serialize-qp "console_server_ports" $console_server_ports "scalar") (serialize-qp "power_ports" $power_ports "scalar") (serialize-qp "power_outlets" $power_outlets "scalar") (serialize-qp "interfaces" $interfaces "scalar") (serialize-qp "pass_through_ports" $pass_through_ports "scalar") (serialize-qp "device_bays" $device_bays "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "asset_tag__n" $asset_tag_n "scalar") (serialize-qp "asset_tag__ic" $asset_tag_ic "scalar") (serialize-qp "asset_tag__nic" $asset_tag_nic "scalar") (serialize-qp "asset_tag__iew" $asset_tag_iew "scalar") (serialize-qp "asset_tag__niew" $asset_tag_niew "scalar") (serialize-qp "asset_tag__isw" $asset_tag_isw "scalar") (serialize-qp "asset_tag__nisw" $asset_tag_nisw "scalar") (serialize-qp "asset_tag__ie" $asset_tag_ie "scalar") (serialize-qp "asset_tag__nie" $asset_tag_nie "scalar") (serialize-qp "face__n" $face_n "scalar") (serialize-qp "position__n" $position_n "scalar") (serialize-qp "position__lte" $position_lte "scalar") (serialize-qp "position__lt" $position_lt "scalar") (serialize-qp "position__gte" $position_gte "scalar") (serialize-qp "position__gt" $position_gt "scalar") (serialize-qp "vc_position__n" $vc_position_n "scalar") (serialize-qp "vc_position__lte" $vc_position_lte "scalar") (serialize-qp "vc_position__lt" $vc_position_lt "scalar") (serialize-qp "vc_position__gte" $vc_position_gte "scalar") (serialize-qp "vc_position__gt" $vc_position_gt "scalar") (serialize-qp "vc_priority__n" $vc_priority_n "scalar") (serialize-qp "vc_priority__lte" $vc_priority_lte "scalar") (serialize-qp "vc_priority__lt" $vc_priority_lt "scalar") (serialize-qp "vc_priority__gte" $vc_priority_gte "scalar") (serialize-qp "vc_priority__gt" $vc_priority_gt "scalar") (serialize-qp "tenant_group_id__n" $tenant_group_id_n "scalar") (serialize-qp "tenant_group__n" $tenant_group_n "scalar") (serialize-qp "tenant_id__n" $tenant_id_n "scalar") (serialize-qp "tenant__n" $tenant_n "scalar") (serialize-qp "manufacturer_id__n" $manufacturer_id_n "scalar") (serialize-qp "manufacturer__n" $manufacturer_n "scalar") (serialize-qp "device_type_id__n" $device_type_id_n "scalar") (serialize-qp "role_id__n" $role_id_n "scalar") (serialize-qp "role__n" $role_n "scalar") (serialize-qp "platform_id__n" $platform_id_n "scalar") (serialize-qp "platform__n" $platform_n "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "rack_group_id__n" $rack_group_id_n "scalar") (serialize-qp "rack_id__n" $rack_id_n "scalar") (serialize-qp "cluster_id__n" $cluster_id_n "scalar") (serialize-qp "model__n" $model_n "scalar") (serialize-qp "status__n" $status_n "scalar") (serialize-qp "mac_address__n" $mac_address_n "scalar") (serialize-qp "mac_address__ic" $mac_address_ic "scalar") (serialize-qp "mac_address__nic" $mac_address_nic "scalar") (serialize-qp "mac_address__iew" $mac_address_iew "scalar") (serialize-qp "mac_address__niew" $mac_address_niew "scalar") (serialize-qp "mac_address__isw" $mac_address_isw "scalar") (serialize-qp "mac_address__nisw" $mac_address_nisw "scalar") (serialize-qp "mac_address__ie" $mac_address_ie "scalar") (serialize-qp "mac_address__nie" $mac_address_nie "scalar") (serialize-qp "virtual_chassis_id__n" $virtual_chassis_id_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/devices/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/devices/
#
# operationId: dcim_devices_create
# --parent_device shape: {name?: string}
export def "dcim-devices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-tag: string # A unique tag used to identify this device (nullable)
  --cluster: int # nullable
  --comments: string
  --custom-fields: record # default: {}
  device_role: int
  device_type: int
  --face: string@face-completer
  --local-context-data: string # nullable
  --name: string # nullable
  --parent-device: record # shape: {name?: string}
  --platform: int # nullable
  --position: int # The lowest-numbered unit occupied by the device (nullable)
  --primary-ip4: int # nullable
  --primary-ip6: int # nullable
  --rack: int # nullable
  --serial: string
  site: int
  --status: string@status-completer-2
  --tags: list<string>
  --tenant: int # nullable
  --vc-position: int # nullable
  --vc-priority: int # nullable
  --virtual-chassis: int # nullable
]: any -> record<asset_tag: string, cluster: record<id: int, name: string, url: string, virtualmachine_count: int>, comments: string, config_context: record, created: string, custom_fields: record, device_role: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, display_name: string, face: record<label: string, value: string>, id: int, last_updated: string, local_context_data: string, name: string, parent_device: record<display_name: string, id: int, name: string, url: string>, platform: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, position: int, primary_ip: record<address: string, family: string, id: int, url: string>, primary_ip4: record<address: string, family: string, id: int, url: string>, primary_ip6: record<address: string, family: string, id: int, url: string>, rack: record<device_count: int, display_name: string, id: int, name: string, url: string>, serial: string, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vc_position: int, vc_priority: int, virtual_chassis: record<id: int, master: record<display_name: string, id: int, name: string, url: string>, member_count: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/devices/")
  let req_body = {"asset_tag": $asset_tag, "cluster": $cluster, "comments": $comments, "custom_fields": $custom_fields, "device_role": $device_role, "device_type": $device_type, "face": $face, "local_context_data": $local_context_data, "name": $name, "parent_device": $parent_device, "platform": $platform, "position": $position, "primary_ip4": $primary_ip4, "primary_ip6": $primary_ip6, "rack": $rack, "serial": $serial, "site": $site, "status": $status, "tags": $tags, "tenant": $tenant, "vc_position": $vc_position, "vc_priority": $vc_priority, "virtual_chassis": $virtual_chassis} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/devices/{id}/
#
# operationId: dcim_devices_delete
export def "dcim-devices delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/devices/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/devices/{id}/
# operationId: dcim_devices_read
export def "dcim-devices get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<asset_tag: string, cluster: record<id: int, name: string, url: string, virtualmachine_count: int>, comments: string, config_context: record, created: string, custom_fields: record, device_role: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, display_name: string, face: record<label: string, value: string>, id: int, last_updated: string, local_context_data: string, name: string, parent_device: record<display_name: string, id: int, name: string, url: string>, platform: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, position: int, primary_ip: record<address: string, family: string, id: int, url: string>, primary_ip4: record<address: string, family: string, id: int, url: string>, primary_ip6: record<address: string, family: string, id: int, url: string>, rack: record<device_count: int, display_name: string, id: int, name: string, url: string>, serial: string, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vc_position: int, vc_priority: int, virtual_chassis: record<id: int, master: record<display_name: string, id: int, name: string, url: string>, member_count: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/devices/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/devices/{id}/
#
# operationId: dcim_devices_partial_update
# --parent_device shape: {name?: string}
export def "dcim-devices update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-tag: string # A unique tag used to identify this device (nullable)
  --cluster: int # nullable
  --comments: string
  --custom-fields: record # default: {}
  device_role: int
  device_type: int
  --face: string@face-completer
  --local-context-data: string # nullable
  --name: string # nullable
  --parent-device: record # shape: {name?: string}
  --platform: int # nullable
  --position: int # The lowest-numbered unit occupied by the device (nullable)
  --primary-ip4: int # nullable
  --primary-ip6: int # nullable
  --rack: int # nullable
  --serial: string
  site: int
  --status: string@status-completer-2
  --tags: list<string>
  --tenant: int # nullable
  --vc-position: int # nullable
  --vc-priority: int # nullable
  --virtual-chassis: int # nullable
]: any -> record<asset_tag: string, cluster: record<id: int, name: string, url: string, virtualmachine_count: int>, comments: string, config_context: record, created: string, custom_fields: record, device_role: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, display_name: string, face: record<label: string, value: string>, id: int, last_updated: string, local_context_data: string, name: string, parent_device: record<display_name: string, id: int, name: string, url: string>, platform: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, position: int, primary_ip: record<address: string, family: string, id: int, url: string>, primary_ip4: record<address: string, family: string, id: int, url: string>, primary_ip6: record<address: string, family: string, id: int, url: string>, rack: record<device_count: int, display_name: string, id: int, name: string, url: string>, serial: string, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vc_position: int, vc_priority: int, virtual_chassis: record<id: int, master: record<display_name: string, id: int, name: string, url: string>, member_count: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/devices/{id}/"))
  let req_body = {"asset_tag": $asset_tag, "cluster": $cluster, "comments": $comments, "custom_fields": $custom_fields, "device_role": $device_role, "device_type": $device_type, "face": $face, "local_context_data": $local_context_data, "name": $name, "parent_device": $parent_device, "platform": $platform, "position": $position, "primary_ip4": $primary_ip4, "primary_ip6": $primary_ip6, "rack": $rack, "serial": $serial, "site": $site, "status": $status, "tags": $tags, "tenant": $tenant, "vc_position": $vc_position, "vc_priority": $vc_priority, "virtual_chassis": $virtual_chassis} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/devices/{id}/
#
# operationId: dcim_devices_update
# --parent_device shape: {name?: string}
export def "dcim-devices update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-tag: string # A unique tag used to identify this device (nullable)
  --cluster: int # nullable
  --comments: string
  --custom-fields: record # default: {}
  device_role: int
  device_type: int
  --face: string@face-completer
  --local-context-data: string # nullable
  --name: string # nullable
  --parent-device: record # shape: {name?: string}
  --platform: int # nullable
  --position: int # The lowest-numbered unit occupied by the device (nullable)
  --primary-ip4: int # nullable
  --primary-ip6: int # nullable
  --rack: int # nullable
  --serial: string
  site: int
  --status: string@status-completer-2
  --tags: list<string>
  --tenant: int # nullable
  --vc-position: int # nullable
  --vc-priority: int # nullable
  --virtual-chassis: int # nullable
]: any -> record<asset_tag: string, cluster: record<id: int, name: string, url: string, virtualmachine_count: int>, comments: string, config_context: record, created: string, custom_fields: record, device_role: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, display_name: string, face: record<label: string, value: string>, id: int, last_updated: string, local_context_data: string, name: string, parent_device: record<display_name: string, id: int, name: string, url: string>, platform: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, position: int, primary_ip: record<address: string, family: string, id: int, url: string>, primary_ip4: record<address: string, family: string, id: int, url: string>, primary_ip6: record<address: string, family: string, id: int, url: string>, rack: record<device_count: int, display_name: string, id: int, name: string, url: string>, serial: string, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vc_position: int, vc_priority: int, virtual_chassis: record<id: int, master: record<display_name: string, id: int, name: string, url: string>, member_count: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/devices/{id}/"))
  let req_body = {"asset_tag": $asset_tag, "cluster": $cluster, "comments": $comments, "custom_fields": $custom_fields, "device_role": $device_role, "device_type": $device_type, "face": $face, "local_context_data": $local_context_data, "name": $name, "parent_device": $parent_device, "platform": $platform, "position": $position, "primary_ip4": $primary_ip4, "primary_ip6": $primary_ip6, "rack": $rack, "serial": $serial, "site": $site, "status": $status, "tags": $tags, "tenant": $tenant, "vc_position": $vc_position, "vc_priority": $vc_priority, "virtual_chassis": $virtual_chassis} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# A convenience method for rendering graphs for a particular Device.
#
# GET /dcim/devices/{id}/graphs/
# operationId: dcim_devices_graphs
export def "dcim-devices-graphs get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<asset_tag: string, cluster: record<id: int, name: string, url: string, virtualmachine_count: int>, comments: string, config_context: record, created: string, custom_fields: record, device_role: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, display_name: string, face: record<label: string, value: string>, id: int, last_updated: string, local_context_data: string, name: string, parent_device: record<display_name: string, id: int, name: string, url: string>, platform: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, position: int, primary_ip: record<address: string, family: string, id: int, url: string>, primary_ip4: record<address: string, family: string, id: int, url: string>, primary_ip6: record<address: string, family: string, id: int, url: string>, rack: record<device_count: int, display_name: string, id: int, name: string, url: string>, serial: string, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vc_position: int, vc_priority: int, virtual_chassis: record<id: int, master: record<display_name: string, id: int, name: string, url: string>, member_count: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/devices/{id}/graphs/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Execute a NAPALM method on a Device
#
# GET /dcim/devices/{id}/napalm/
# operationId: dcim_devices_napalm
export def "dcim-devices-napalm get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --method: string
]: nothing -> record<method: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "method" $method "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/devices/{id}/napalm/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/front-port-templates/
# operationId: dcim_front-port-templates_list
export def "dcim-front-port-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --type: string
  --q: string
  --devicetype-id: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --type-n: string
  --devicetype-id-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<device_type: record, id: int, name: string, rear_port: record, rear_port_position: int, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "devicetype_id" $devicetype_id "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "devicetype_id__n" $devicetype_id_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/front-port-templates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/front-port-templates/
#
# operationId: dcim_front-port-templates_create
export def "dcim-front-port-templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  name: string
  rear_port: int
  --rear-port-position: int # default: 1
  type: string@type-completer-2
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, rear_port: record<id: int, name: string, url: string>, rear_port_position: int, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/front-port-templates/")
  let req_body = {"device_type": $device_type, "name": $name, "rear_port": $rear_port, "rear_port_position": $rear_port_position, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/front-port-templates/{id}/
#
# operationId: dcim_front-port-templates_delete
export def "dcim-front-port-templates delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/front-port-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/front-port-templates/{id}/
# operationId: dcim_front-port-templates_read
export def "dcim-front-port-templates get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, rear_port: record<id: int, name: string, url: string>, rear_port_position: int, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/front-port-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/front-port-templates/{id}/
#
# operationId: dcim_front-port-templates_partial_update
export def "dcim-front-port-templates update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  name: string
  rear_port: int
  --rear-port-position: int # default: 1
  type: string@type-completer-2
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, rear_port: record<id: int, name: string, url: string>, rear_port_position: int, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/front-port-templates/{id}/"))
  let req_body = {"device_type": $device_type, "name": $name, "rear_port": $rear_port, "rear_port_position": $rear_port_position, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/front-port-templates/{id}/
#
# operationId: dcim_front-port-templates_update
export def "dcim-front-port-templates update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  name: string
  rear_port: int
  --rear-port-position: int # default: 1
  type: string@type-completer-2
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, rear_port: record<id: int, name: string, url: string>, rear_port_position: int, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/front-port-templates/{id}/"))
  let req_body = {"device_type": $device_type, "name": $name, "rear_port": $rear_port, "rear_port_position": $rear_port_position, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/front-ports/
# operationId: dcim_front-ports_list
export def "dcim-front-ports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --type: string
  --description: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --device-id: string
  --device: string
  --tag: string
  --cabled: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --type-n: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --device-id-n: string
  --device-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<cable: record, description: string, device: record, id: int, name: string, rear_port: record, rear_port_position: int, tags: list, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "cabled" $cabled "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "device_id__n" $device_id_n "scalar") (serialize-qp "device__n" $device_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/front-ports/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/front-ports/
#
# operationId: dcim_front-ports_create
# --cable shape: {label?: string}
export def "dcim-front-ports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --description: string
  device: int
  name: string
  rear_port: int
  --rear-port-position: int # default: 1
  --tags: list<string>
  type: string@type-completer-2
]: any -> record<cable: record<id: int, label: string, url: string>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, rear_port: record<id: int, name: string, url: string>, rear_port_position: int, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/front-ports/")
  let req_body = {"cable": $cable, "description": $description, "device": $device, "name": $name, "rear_port": $rear_port, "rear_port_position": $rear_port_position, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/front-ports/{id}/
#
# operationId: dcim_front-ports_delete
export def "dcim-front-ports delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/front-ports/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/front-ports/{id}/
# operationId: dcim_front-ports_read
export def "dcim-front-ports get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cable: record<id: int, label: string, url: string>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, rear_port: record<id: int, name: string, url: string>, rear_port_position: int, tags: list<string>, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/front-ports/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/front-ports/{id}/
#
# operationId: dcim_front-ports_partial_update
# --cable shape: {label?: string}
export def "dcim-front-ports update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --description: string
  device: int
  name: string
  rear_port: int
  --rear-port-position: int # default: 1
  --tags: list<string>
  type: string@type-completer-2
]: any -> record<cable: record<id: int, label: string, url: string>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, rear_port: record<id: int, name: string, url: string>, rear_port_position: int, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/front-ports/{id}/"))
  let req_body = {"cable": $cable, "description": $description, "device": $device, "name": $name, "rear_port": $rear_port, "rear_port_position": $rear_port_position, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/front-ports/{id}/
#
# operationId: dcim_front-ports_update
# --cable shape: {label?: string}
export def "dcim-front-ports update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --description: string
  device: int
  name: string
  rear_port: int
  --rear-port-position: int # default: 1
  --tags: list<string>
  type: string@type-completer-2
]: any -> record<cable: record<id: int, label: string, url: string>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, rear_port: record<id: int, name: string, url: string>, rear_port_position: int, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/front-ports/{id}/"))
  let req_body = {"cable": $cable, "description": $description, "device": $device, "name": $name, "rear_port": $rear_port, "rear_port_position": $rear_port_position, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Trace a complete cable path and return each segment as a three-tuple of (termination, cable, termination).
#
# GET /dcim/front-ports/{id}/trace/
# operationId: dcim_front-ports_trace
export def "dcim-front-ports-trace get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cable: record<id: int, label: string, url: string>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, rear_port: record<id: int, name: string, url: string>, rear_port_position: int, tags: list<string>, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/front-ports/{id}/trace/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /dcim/interface-connections/
#
# operationId: dcim_interface-connections_list
export def "dcim-interface-connections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-status: string
  --site: string
  --device-id: string
  --device: string
  --connection-status-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<connection_status: record, interface_a: record, interface_b: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "connection_status" $connection_status "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "connection_status__n" $connection_status_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/interface-connections/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/interface-templates/
# operationId: dcim_interface-templates_list
export def "dcim-interface-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --type: string
  --mgmt-only: string
  --q: string
  --devicetype-id: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --type-n: string
  --devicetype-id-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<device_type: record, id: int, mgmt_only: bool, name: string, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "mgmt_only" $mgmt_only "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "devicetype_id" $devicetype_id "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "devicetype_id__n" $devicetype_id_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/interface-templates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/interface-templates/
#
# operationId: dcim_interface-templates_create
export def "dcim-interface-templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  --mgmt-only: oneof<nothing, bool>
  name: string
  type: string@type-completer-3
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, mgmt_only: bool, name: string, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/interface-templates/")
  let req_body = {"device_type": $device_type, "mgmt_only": $mgmt_only, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/interface-templates/{id}/
#
# operationId: dcim_interface-templates_delete
export def "dcim-interface-templates delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/interface-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/interface-templates/{id}/
# operationId: dcim_interface-templates_read
export def "dcim-interface-templates get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, mgmt_only: bool, name: string, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/interface-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/interface-templates/{id}/
#
# operationId: dcim_interface-templates_partial_update
export def "dcim-interface-templates update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  --mgmt-only: oneof<nothing, bool>
  name: string
  type: string@type-completer-3
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, mgmt_only: bool, name: string, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/interface-templates/{id}/"))
  let req_body = {"device_type": $device_type, "mgmt_only": $mgmt_only, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/interface-templates/{id}/
#
# operationId: dcim_interface-templates_update
export def "dcim-interface-templates update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  --mgmt-only: oneof<nothing, bool>
  name: string
  type: string@type-completer-3
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, mgmt_only: bool, name: string, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/interface-templates/{id}/"))
  let req_body = {"device_type": $device_type, "mgmt_only": $mgmt_only, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/interfaces/
# operationId: dcim_interfaces_list
export def "dcim-interfaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --connection-status: string
  --type: string
  --enabled: string
  --mtu: string
  --mgmt-only: string
  --mode: string
  --description: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --device-id: string
  --device: string
  --tag: string
  --cabled: string
  --kind: string
  --lag-id: string
  --mac-address: string
  --vlan-id: string
  --vlan: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --connection-status-n: string
  --type-n: string
  --mtu-n: string
  --mtu-lte: string
  --mtu-lt: string
  --mtu-gte: string
  --mtu-gt: string
  --mode-n: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --tag-n: string
  --lag-id-n: string
  --mac-address-n: string
  --mac-address-ic: string
  --mac-address-nic: string
  --mac-address-iew: string
  --mac-address-niew: string
  --mac-address-isw: string
  --mac-address-nisw: string
  --mac-address-ie: string
  --mac-address-nie: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<cable: record, connected_endpoint: record, connected_endpoint_type: string, connection_status: record, count_ipaddresses: int, description: string, device: record, enabled: bool, id: int, lag: record, mac_address: string, mgmt_only: bool, mode: record, mtu: int, name: string, tagged_vlans: list, tags: list, type: record, untagged_vlan: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "connection_status" $connection_status "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "mtu" $mtu "scalar") (serialize-qp "mgmt_only" $mgmt_only "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "cabled" $cabled "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "lag_id" $lag_id "scalar") (serialize-qp "mac_address" $mac_address "scalar") (serialize-qp "vlan_id" $vlan_id "scalar") (serialize-qp "vlan" $vlan "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "connection_status__n" $connection_status_n "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "mtu__n" $mtu_n "scalar") (serialize-qp "mtu__lte" $mtu_lte "scalar") (serialize-qp "mtu__lt" $mtu_lt "scalar") (serialize-qp "mtu__gte" $mtu_gte "scalar") (serialize-qp "mtu__gt" $mtu_gt "scalar") (serialize-qp "mode__n" $mode_n "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "lag_id__n" $lag_id_n "scalar") (serialize-qp "mac_address__n" $mac_address_n "scalar") (serialize-qp "mac_address__ic" $mac_address_ic "scalar") (serialize-qp "mac_address__nic" $mac_address_nic "scalar") (serialize-qp "mac_address__iew" $mac_address_iew "scalar") (serialize-qp "mac_address__niew" $mac_address_niew "scalar") (serialize-qp "mac_address__isw" $mac_address_isw "scalar") (serialize-qp "mac_address__nisw" $mac_address_nisw "scalar") (serialize-qp "mac_address__ie" $mac_address_ie "scalar") (serialize-qp "mac_address__nie" $mac_address_nie "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/interfaces/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/interfaces/
#
# operationId: dcim_interfaces_create
# --cable shape: {label?: string}
export def "dcim-interfaces create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --connection-status: oneof<nothing, bool>
  --description: string
  device: int
  --enabled: oneof<nothing, bool>
  --lag: int # nullable
  --mac-address: string # nullable
  --mgmt-only: oneof<nothing, bool> # This interface is used only for out-of-band management
  --mode: string@mode-completer
  --mtu: int # nullable
  name: string
  --tagged-vlans: list<int>
  --tags: list<string>
  type: string@type-completer-3
  --untagged-vlan: int # nullable
]: any -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, count_ipaddresses: int, description: string, device: record<display_name: string, id: int, name: string, url: string>, enabled: bool, id: int, lag: record<cable: int, connection_status: record<label: string, value: bool>, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, url: string>, mac_address: string, mgmt_only: bool, mode: record<label: string, value: string>, mtu: int, name: string, tagged_vlans: table<display_name: string, id: int, name: string, url: string, vid: int>, tags: list<string>, type: record<label: string, value: string>, untagged_vlan: record<display_name: string, id: int, name: string, url: string, vid: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/interfaces/")
  let req_body = {"cable": $cable, "connection_status": $connection_status, "description": $description, "device": $device, "enabled": $enabled, "lag": $lag, "mac_address": $mac_address, "mgmt_only": $mgmt_only, "mode": $mode, "mtu": $mtu, "name": $name, "tagged_vlans": $tagged_vlans, "tags": $tags, "type": $type, "untagged_vlan": $untagged_vlan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/interfaces/{id}/
#
# operationId: dcim_interfaces_delete
export def "dcim-interfaces delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/interfaces/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/interfaces/{id}/
# operationId: dcim_interfaces_read
export def "dcim-interfaces get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, count_ipaddresses: int, description: string, device: record<display_name: string, id: int, name: string, url: string>, enabled: bool, id: int, lag: record<cable: int, connection_status: record<label: string, value: bool>, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, url: string>, mac_address: string, mgmt_only: bool, mode: record<label: string, value: string>, mtu: int, name: string, tagged_vlans: table<display_name: string, id: int, name: string, url: string, vid: int>, tags: list<string>, type: record<label: string, value: string>, untagged_vlan: record<display_name: string, id: int, name: string, url: string, vid: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/interfaces/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/interfaces/{id}/
#
# operationId: dcim_interfaces_partial_update
# --cable shape: {label?: string}
export def "dcim-interfaces update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --connection-status: oneof<nothing, bool>
  --description: string
  device: int
  --enabled: oneof<nothing, bool>
  --lag: int # nullable
  --mac-address: string # nullable
  --mgmt-only: oneof<nothing, bool> # This interface is used only for out-of-band management
  --mode: string@mode-completer
  --mtu: int # nullable
  name: string
  --tagged-vlans: list<int>
  --tags: list<string>
  type: string@type-completer-3
  --untagged-vlan: int # nullable
]: any -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, count_ipaddresses: int, description: string, device: record<display_name: string, id: int, name: string, url: string>, enabled: bool, id: int, lag: record<cable: int, connection_status: record<label: string, value: bool>, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, url: string>, mac_address: string, mgmt_only: bool, mode: record<label: string, value: string>, mtu: int, name: string, tagged_vlans: table<display_name: string, id: int, name: string, url: string, vid: int>, tags: list<string>, type: record<label: string, value: string>, untagged_vlan: record<display_name: string, id: int, name: string, url: string, vid: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/interfaces/{id}/"))
  let req_body = {"cable": $cable, "connection_status": $connection_status, "description": $description, "device": $device, "enabled": $enabled, "lag": $lag, "mac_address": $mac_address, "mgmt_only": $mgmt_only, "mode": $mode, "mtu": $mtu, "name": $name, "tagged_vlans": $tagged_vlans, "tags": $tags, "type": $type, "untagged_vlan": $untagged_vlan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/interfaces/{id}/
#
# operationId: dcim_interfaces_update
# --cable shape: {label?: string}
export def "dcim-interfaces update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --connection-status: oneof<nothing, bool>
  --description: string
  device: int
  --enabled: oneof<nothing, bool>
  --lag: int # nullable
  --mac-address: string # nullable
  --mgmt-only: oneof<nothing, bool> # This interface is used only for out-of-band management
  --mode: string@mode-completer
  --mtu: int # nullable
  name: string
  --tagged-vlans: list<int>
  --tags: list<string>
  type: string@type-completer-3
  --untagged-vlan: int # nullable
]: any -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, count_ipaddresses: int, description: string, device: record<display_name: string, id: int, name: string, url: string>, enabled: bool, id: int, lag: record<cable: int, connection_status: record<label: string, value: bool>, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, url: string>, mac_address: string, mgmt_only: bool, mode: record<label: string, value: string>, mtu: int, name: string, tagged_vlans: table<display_name: string, id: int, name: string, url: string, vid: int>, tags: list<string>, type: record<label: string, value: string>, untagged_vlan: record<display_name: string, id: int, name: string, url: string, vid: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/interfaces/{id}/"))
  let req_body = {"cable": $cable, "connection_status": $connection_status, "description": $description, "device": $device, "enabled": $enabled, "lag": $lag, "mac_address": $mac_address, "mgmt_only": $mgmt_only, "mode": $mode, "mtu": $mtu, "name": $name, "tagged_vlans": $tagged_vlans, "tags": $tags, "type": $type, "untagged_vlan": $untagged_vlan} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# A convenience method for rendering graphs for a particular interface.
#
# GET /dcim/interfaces/{id}/graphs/
# operationId: dcim_interfaces_graphs
export def "dcim-interfaces-graphs get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, count_ipaddresses: int, description: string, device: record<display_name: string, id: int, name: string, url: string>, enabled: bool, id: int, lag: record<cable: int, connection_status: record<label: string, value: bool>, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, url: string>, mac_address: string, mgmt_only: bool, mode: record<label: string, value: string>, mtu: int, name: string, tagged_vlans: table<display_name: string, id: int, name: string, url: string, vid: int>, tags: list<string>, type: record<label: string, value: string>, untagged_vlan: record<display_name: string, id: int, name: string, url: string, vid: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/interfaces/{id}/graphs/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trace a complete cable path and return each segment as a three-tuple of (termination, cable, termination).
#
# GET /dcim/interfaces/{id}/trace/
# operationId: dcim_interfaces_trace
export def "dcim-interfaces-trace get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, count_ipaddresses: int, description: string, device: record<display_name: string, id: int, name: string, url: string>, enabled: bool, id: int, lag: record<cable: int, connection_status: record<label: string, value: bool>, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, url: string>, mac_address: string, mgmt_only: bool, mode: record<label: string, value: string>, mtu: int, name: string, tagged_vlans: table<display_name: string, id: int, name: string, url: string, vid: int>, tags: list<string>, type: record<label: string, value: string>, untagged_vlan: record<display_name: string, id: int, name: string, url: string, vid: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/interfaces/{id}/trace/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/inventory-items/
# operationId: dcim_inventory-items_list
export def "dcim-inventory-items list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --part-id: string
  --asset-tag: string
  --discovered: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --device-id: string
  --device: string
  --tag: string
  --parent-id: string
  --manufacturer-id: string
  --manufacturer: string
  --serial: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --part-id-n: string
  --part-id-ic: string
  --part-id-nic: string
  --part-id-iew: string
  --part-id-niew: string
  --part-id-isw: string
  --part-id-nisw: string
  --part-id-ie: string
  --part-id-nie: string
  --asset-tag-n: string
  --asset-tag-ic: string
  --asset-tag-nic: string
  --asset-tag-iew: string
  --asset-tag-niew: string
  --asset-tag-isw: string
  --asset-tag-nisw: string
  --asset-tag-ie: string
  --asset-tag-nie: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --device-id-n: string
  --device-n: string
  --tag-n: string
  --parent-id-n: string
  --manufacturer-id-n: string
  --manufacturer-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<asset_tag: string, description: string, device: record, discovered: bool, id: int, manufacturer: record, name: string, parent: int, part_id: string, serial: string, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "part_id" $part_id "scalar") (serialize-qp "asset_tag" $asset_tag "scalar") (serialize-qp "discovered" $discovered "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "manufacturer_id" $manufacturer_id "scalar") (serialize-qp "manufacturer" $manufacturer "scalar") (serialize-qp "serial" $serial "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "part_id__n" $part_id_n "scalar") (serialize-qp "part_id__ic" $part_id_ic "scalar") (serialize-qp "part_id__nic" $part_id_nic "scalar") (serialize-qp "part_id__iew" $part_id_iew "scalar") (serialize-qp "part_id__niew" $part_id_niew "scalar") (serialize-qp "part_id__isw" $part_id_isw "scalar") (serialize-qp "part_id__nisw" $part_id_nisw "scalar") (serialize-qp "part_id__ie" $part_id_ie "scalar") (serialize-qp "part_id__nie" $part_id_nie "scalar") (serialize-qp "asset_tag__n" $asset_tag_n "scalar") (serialize-qp "asset_tag__ic" $asset_tag_ic "scalar") (serialize-qp "asset_tag__nic" $asset_tag_nic "scalar") (serialize-qp "asset_tag__iew" $asset_tag_iew "scalar") (serialize-qp "asset_tag__niew" $asset_tag_niew "scalar") (serialize-qp "asset_tag__isw" $asset_tag_isw "scalar") (serialize-qp "asset_tag__nisw" $asset_tag_nisw "scalar") (serialize-qp "asset_tag__ie" $asset_tag_ie "scalar") (serialize-qp "asset_tag__nie" $asset_tag_nie "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "device_id__n" $device_id_n "scalar") (serialize-qp "device__n" $device_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "parent_id__n" $parent_id_n "scalar") (serialize-qp "manufacturer_id__n" $manufacturer_id_n "scalar") (serialize-qp "manufacturer__n" $manufacturer_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/inventory-items/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/inventory-items/
#
# operationId: dcim_inventory-items_create
export def "dcim-inventory-items create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-tag: string # A unique tag used to identify this item (nullable)
  --description: string
  device: int
  --discovered: oneof<nothing, bool> # This item was automatically discovered
  --manufacturer: int # nullable
  name: string
  --parent: int # nullable
  --part-id: string # Manufacturer-assigned part identifier
  --serial: string
  --tags: list<string>
]: any -> record<asset_tag: string, description: string, device: record<display_name: string, id: int, name: string, url: string>, discovered: bool, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, name: string, parent: int, part_id: string, serial: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/inventory-items/")
  let req_body = {"asset_tag": $asset_tag, "description": $description, "device": $device, "discovered": $discovered, "manufacturer": $manufacturer, "name": $name, "parent": $parent, "part_id": $part_id, "serial": $serial, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/inventory-items/{id}/
#
# operationId: dcim_inventory-items_delete
export def "dcim-inventory-items delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/inventory-items/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/inventory-items/{id}/
# operationId: dcim_inventory-items_read
export def "dcim-inventory-items get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<asset_tag: string, description: string, device: record<display_name: string, id: int, name: string, url: string>, discovered: bool, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, name: string, parent: int, part_id: string, serial: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/inventory-items/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/inventory-items/{id}/
#
# operationId: dcim_inventory-items_partial_update
export def "dcim-inventory-items update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-tag: string # A unique tag used to identify this item (nullable)
  --description: string
  device: int
  --discovered: oneof<nothing, bool> # This item was automatically discovered
  --manufacturer: int # nullable
  name: string
  --parent: int # nullable
  --part-id: string # Manufacturer-assigned part identifier
  --serial: string
  --tags: list<string>
]: any -> record<asset_tag: string, description: string, device: record<display_name: string, id: int, name: string, url: string>, discovered: bool, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, name: string, parent: int, part_id: string, serial: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/inventory-items/{id}/"))
  let req_body = {"asset_tag": $asset_tag, "description": $description, "device": $device, "discovered": $discovered, "manufacturer": $manufacturer, "name": $name, "parent": $parent, "part_id": $part_id, "serial": $serial, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/inventory-items/{id}/
#
# operationId: dcim_inventory-items_update
export def "dcim-inventory-items update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-tag: string # A unique tag used to identify this item (nullable)
  --description: string
  device: int
  --discovered: oneof<nothing, bool> # This item was automatically discovered
  --manufacturer: int # nullable
  name: string
  --parent: int # nullable
  --part-id: string # Manufacturer-assigned part identifier
  --serial: string
  --tags: list<string>
]: any -> record<asset_tag: string, description: string, device: record<display_name: string, id: int, name: string, url: string>, discovered: bool, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, name: string, parent: int, part_id: string, serial: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/inventory-items/{id}/"))
  let req_body = {"asset_tag": $asset_tag, "description": $description, "device": $device, "discovered": $discovered, "manufacturer": $manufacturer, "name": $name, "parent": $parent, "part_id": $part_id, "serial": $serial, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/manufacturers/
# operationId: dcim_manufacturers_list
export def "dcim-manufacturers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --description: string
  --q: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<description: string, devicetype_count: int, id: int, inventoryitem_count: int, name: string, platform_count: int, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/manufacturers/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/manufacturers/
#
# operationId: dcim_manufacturers_create
export def "dcim-manufacturers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<description: string, devicetype_count: int, id: int, inventoryitem_count: int, name: string, platform_count: int, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/manufacturers/")
  let req_body = {"description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/manufacturers/{id}/
#
# operationId: dcim_manufacturers_delete
export def "dcim-manufacturers delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/manufacturers/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/manufacturers/{id}/
# operationId: dcim_manufacturers_read
export def "dcim-manufacturers get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, devicetype_count: int, id: int, inventoryitem_count: int, name: string, platform_count: int, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/manufacturers/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/manufacturers/{id}/
#
# operationId: dcim_manufacturers_partial_update
export def "dcim-manufacturers update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<description: string, devicetype_count: int, id: int, inventoryitem_count: int, name: string, platform_count: int, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/manufacturers/{id}/"))
  let req_body = {"description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/manufacturers/{id}/
#
# operationId: dcim_manufacturers_update
export def "dcim-manufacturers update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<description: string, devicetype_count: int, id: int, inventoryitem_count: int, name: string, platform_count: int, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/manufacturers/{id}/"))
  let req_body = {"description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/platforms/
# operationId: dcim_platforms_list
export def "dcim-platforms list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --napalm-driver: string
  --description: string
  --q: string
  --manufacturer-id: string
  --manufacturer: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --napalm-driver-n: string
  --napalm-driver-ic: string
  --napalm-driver-nic: string
  --napalm-driver-iew: string
  --napalm-driver-niew: string
  --napalm-driver-isw: string
  --napalm-driver-nisw: string
  --napalm-driver-ie: string
  --napalm-driver-nie: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --manufacturer-id-n: string
  --manufacturer-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<description: string, device_count: int, id: int, manufacturer: record, name: string, napalm_args: string, napalm_driver: string, slug: string, virtualmachine_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "napalm_driver" $napalm_driver "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "manufacturer_id" $manufacturer_id "scalar") (serialize-qp "manufacturer" $manufacturer "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "napalm_driver__n" $napalm_driver_n "scalar") (serialize-qp "napalm_driver__ic" $napalm_driver_ic "scalar") (serialize-qp "napalm_driver__nic" $napalm_driver_nic "scalar") (serialize-qp "napalm_driver__iew" $napalm_driver_iew "scalar") (serialize-qp "napalm_driver__niew" $napalm_driver_niew "scalar") (serialize-qp "napalm_driver__isw" $napalm_driver_isw "scalar") (serialize-qp "napalm_driver__nisw" $napalm_driver_nisw "scalar") (serialize-qp "napalm_driver__ie" $napalm_driver_ie "scalar") (serialize-qp "napalm_driver__nie" $napalm_driver_nie "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "manufacturer_id__n" $manufacturer_id_n "scalar") (serialize-qp "manufacturer__n" $manufacturer_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/platforms/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/platforms/
#
# operationId: dcim_platforms_create
export def "dcim-platforms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --manufacturer: int # Optionally limit this platform to devices of a certain manufacturer (nullable)
  name: string
  --napalm-args: string # Additional arguments to pass when initiating the NAPALM driver (JSON format) (nullable)
  --napalm-driver: string # The name of the NAPALM driver to use when interacting with devices
  slug: string # format: slug
]: any -> record<description: string, device_count: int, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, name: string, napalm_args: string, napalm_driver: string, slug: string, virtualmachine_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/platforms/")
  let req_body = {"description": $description, "manufacturer": $manufacturer, "name": $name, "napalm_args": $napalm_args, "napalm_driver": $napalm_driver, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/platforms/{id}/
#
# operationId: dcim_platforms_delete
export def "dcim-platforms delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/platforms/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/platforms/{id}/
# operationId: dcim_platforms_read
export def "dcim-platforms get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, device_count: int, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, name: string, napalm_args: string, napalm_driver: string, slug: string, virtualmachine_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/platforms/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/platforms/{id}/
#
# operationId: dcim_platforms_partial_update
export def "dcim-platforms update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --manufacturer: int # Optionally limit this platform to devices of a certain manufacturer (nullable)
  name: string
  --napalm-args: string # Additional arguments to pass when initiating the NAPALM driver (JSON format) (nullable)
  --napalm-driver: string # The name of the NAPALM driver to use when interacting with devices
  slug: string # format: slug
]: any -> record<description: string, device_count: int, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, name: string, napalm_args: string, napalm_driver: string, slug: string, virtualmachine_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/platforms/{id}/"))
  let req_body = {"description": $description, "manufacturer": $manufacturer, "name": $name, "napalm_args": $napalm_args, "napalm_driver": $napalm_driver, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/platforms/{id}/
#
# operationId: dcim_platforms_update
export def "dcim-platforms update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --manufacturer: int # Optionally limit this platform to devices of a certain manufacturer (nullable)
  name: string
  --napalm-args: string # Additional arguments to pass when initiating the NAPALM driver (JSON format) (nullable)
  --napalm-driver: string # The name of the NAPALM driver to use when interacting with devices
  slug: string # format: slug
]: any -> record<description: string, device_count: int, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, name: string, napalm_args: string, napalm_driver: string, slug: string, virtualmachine_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/platforms/{id}/"))
  let req_body = {"description": $description, "manufacturer": $manufacturer, "name": $name, "napalm_args": $napalm_args, "napalm_driver": $napalm_driver, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# GET /dcim/power-connections/
#
# operationId: dcim_power-connections_list
export def "dcim-power-connections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --connection-status: string
  --site: string
  --device-id: string
  --device: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --connection-status-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<allocated_draw: int, cable: record, connected_endpoint: record, connected_endpoint_type: string, connection_status: record, description: string, device: record, id: int, maximum_draw: int, name: string, tags: list, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "connection_status" $connection_status "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "connection_status__n" $connection_status_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/power-connections/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/power-feeds/
# operationId: dcim_power-feeds_list
export def "dcim-power-feeds list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --status: string
  --type: string
  --supply: string
  --phase: string
  --voltage: string
  --amperage: string
  --max-utilization: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --power-panel-id: string
  --rack-id: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --status-n: string
  --type-n: string
  --supply-n: string
  --phase-n: string
  --voltage-n: string
  --voltage-lte: string
  --voltage-lt: string
  --voltage-gte: string
  --voltage-gt: string
  --amperage-n: string
  --amperage-lte: string
  --amperage-lt: string
  --amperage-gte: string
  --amperage-gt: string
  --max-utilization-n: string
  --max-utilization-lte: string
  --max-utilization-lt: string
  --max-utilization-gte: string
  --max-utilization-gt: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --power-panel-id-n: string
  --rack-id-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<amperage: int, comments: string, created: string, custom_fields: record, id: int, last_updated: string, max_utilization: int, name: string, phase: record, power_panel: record, rack: record, status: record, supply: record, tags: list, type: record, voltage: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "supply" $supply "scalar") (serialize-qp "phase" $phase "scalar") (serialize-qp "voltage" $voltage "scalar") (serialize-qp "amperage" $amperage "scalar") (serialize-qp "max_utilization" $max_utilization "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "power_panel_id" $power_panel_id "scalar") (serialize-qp "rack_id" $rack_id "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "status__n" $status_n "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "supply__n" $supply_n "scalar") (serialize-qp "phase__n" $phase_n "scalar") (serialize-qp "voltage__n" $voltage_n "scalar") (serialize-qp "voltage__lte" $voltage_lte "scalar") (serialize-qp "voltage__lt" $voltage_lt "scalar") (serialize-qp "voltage__gte" $voltage_gte "scalar") (serialize-qp "voltage__gt" $voltage_gt "scalar") (serialize-qp "amperage__n" $amperage_n "scalar") (serialize-qp "amperage__lte" $amperage_lte "scalar") (serialize-qp "amperage__lt" $amperage_lt "scalar") (serialize-qp "amperage__gte" $amperage_gte "scalar") (serialize-qp "amperage__gt" $amperage_gt "scalar") (serialize-qp "max_utilization__n" $max_utilization_n "scalar") (serialize-qp "max_utilization__lte" $max_utilization_lte "scalar") (serialize-qp "max_utilization__lt" $max_utilization_lt "scalar") (serialize-qp "max_utilization__gte" $max_utilization_gte "scalar") (serialize-qp "max_utilization__gt" $max_utilization_gt "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "power_panel_id__n" $power_panel_id_n "scalar") (serialize-qp "rack_id__n" $rack_id_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/power-feeds/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/power-feeds/
#
# operationId: dcim_power-feeds_create
export def "dcim-power-feeds create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amperage: int
  --comments: string
  --custom-fields: record # default: {}
  --max-utilization: int # Maximum permissible draw (percentage)
  name: string
  --phase: string@phase-completer
  power_panel: int
  --rack: int # nullable
  --status: string@status-completer-3
  --supply: string@supply-completer
  --tags: list<string>
  --type: string@type-completer-4
  --voltage: int
]: any -> record<amperage: int, comments: string, created: string, custom_fields: record, id: int, last_updated: string, max_utilization: int, name: string, phase: record<label: string, value: string>, power_panel: record<id: int, name: string, powerfeed_count: int, url: string>, rack: record<device_count: int, display_name: string, id: int, name: string, url: string>, status: record<label: string, value: string>, supply: record<label: string, value: string>, tags: list<string>, type: record<label: string, value: string>, voltage: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/power-feeds/")
  let req_body = {"amperage": $amperage, "comments": $comments, "custom_fields": $custom_fields, "max_utilization": $max_utilization, "name": $name, "phase": $phase, "power_panel": $power_panel, "rack": $rack, "status": $status, "supply": $supply, "tags": $tags, "type": $type, "voltage": $voltage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/power-feeds/{id}/
#
# operationId: dcim_power-feeds_delete
export def "dcim-power-feeds delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-feeds/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/power-feeds/{id}/
# operationId: dcim_power-feeds_read
export def "dcim-power-feeds get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<amperage: int, comments: string, created: string, custom_fields: record, id: int, last_updated: string, max_utilization: int, name: string, phase: record<label: string, value: string>, power_panel: record<id: int, name: string, powerfeed_count: int, url: string>, rack: record<device_count: int, display_name: string, id: int, name: string, url: string>, status: record<label: string, value: string>, supply: record<label: string, value: string>, tags: list<string>, type: record<label: string, value: string>, voltage: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-feeds/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/power-feeds/{id}/
#
# operationId: dcim_power-feeds_partial_update
export def "dcim-power-feeds update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amperage: int
  --comments: string
  --custom-fields: record # default: {}
  --max-utilization: int # Maximum permissible draw (percentage)
  name: string
  --phase: string@phase-completer
  power_panel: int
  --rack: int # nullable
  --status: string@status-completer-3
  --supply: string@supply-completer
  --tags: list<string>
  --type: string@type-completer-4
  --voltage: int
]: any -> record<amperage: int, comments: string, created: string, custom_fields: record, id: int, last_updated: string, max_utilization: int, name: string, phase: record<label: string, value: string>, power_panel: record<id: int, name: string, powerfeed_count: int, url: string>, rack: record<device_count: int, display_name: string, id: int, name: string, url: string>, status: record<label: string, value: string>, supply: record<label: string, value: string>, tags: list<string>, type: record<label: string, value: string>, voltage: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-feeds/{id}/"))
  let req_body = {"amperage": $amperage, "comments": $comments, "custom_fields": $custom_fields, "max_utilization": $max_utilization, "name": $name, "phase": $phase, "power_panel": $power_panel, "rack": $rack, "status": $status, "supply": $supply, "tags": $tags, "type": $type, "voltage": $voltage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/power-feeds/{id}/
#
# operationId: dcim_power-feeds_update
export def "dcim-power-feeds update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amperage: int
  --comments: string
  --custom-fields: record # default: {}
  --max-utilization: int # Maximum permissible draw (percentage)
  name: string
  --phase: string@phase-completer
  power_panel: int
  --rack: int # nullable
  --status: string@status-completer-3
  --supply: string@supply-completer
  --tags: list<string>
  --type: string@type-completer-4
  --voltage: int
]: any -> record<amperage: int, comments: string, created: string, custom_fields: record, id: int, last_updated: string, max_utilization: int, name: string, phase: record<label: string, value: string>, power_panel: record<id: int, name: string, powerfeed_count: int, url: string>, rack: record<device_count: int, display_name: string, id: int, name: string, url: string>, status: record<label: string, value: string>, supply: record<label: string, value: string>, tags: list<string>, type: record<label: string, value: string>, voltage: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-feeds/{id}/"))
  let req_body = {"amperage": $amperage, "comments": $comments, "custom_fields": $custom_fields, "max_utilization": $max_utilization, "name": $name, "phase": $phase, "power_panel": $power_panel, "rack": $rack, "status": $status, "supply": $supply, "tags": $tags, "type": $type, "voltage": $voltage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/power-outlet-templates/
# operationId: dcim_power-outlet-templates_list
export def "dcim-power-outlet-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --type: string
  --feed-leg: string
  --q: string
  --devicetype-id: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --type-n: string
  --feed-leg-n: string
  --devicetype-id-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<device_type: record, feed_leg: record, id: int, name: string, power_port: record, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "feed_leg" $feed_leg "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "devicetype_id" $devicetype_id "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "feed_leg__n" $feed_leg_n "scalar") (serialize-qp "devicetype_id__n" $devicetype_id_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/power-outlet-templates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/power-outlet-templates/
#
# operationId: dcim_power-outlet-templates_create
export def "dcim-power-outlet-templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  --feed-leg: string@feed-leg-completer # Phase (for three-phase feeds)
  name: string
  --power-port: int # nullable
  --type: string@type-completer-5
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, feed_leg: record<label: string, value: string>, id: int, name: string, power_port: record<id: int, name: string, url: string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/power-outlet-templates/")
  let req_body = {"device_type": $device_type, "feed_leg": $feed_leg, "name": $name, "power_port": $power_port, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/power-outlet-templates/{id}/
#
# operationId: dcim_power-outlet-templates_delete
export def "dcim-power-outlet-templates delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-outlet-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/power-outlet-templates/{id}/
# operationId: dcim_power-outlet-templates_read
export def "dcim-power-outlet-templates get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, feed_leg: record<label: string, value: string>, id: int, name: string, power_port: record<id: int, name: string, url: string>, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-outlet-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/power-outlet-templates/{id}/
#
# operationId: dcim_power-outlet-templates_partial_update
export def "dcim-power-outlet-templates update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  --feed-leg: string@feed-leg-completer # Phase (for three-phase feeds)
  name: string
  --power-port: int # nullable
  --type: string@type-completer-5
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, feed_leg: record<label: string, value: string>, id: int, name: string, power_port: record<id: int, name: string, url: string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-outlet-templates/{id}/"))
  let req_body = {"device_type": $device_type, "feed_leg": $feed_leg, "name": $name, "power_port": $power_port, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/power-outlet-templates/{id}/
#
# operationId: dcim_power-outlet-templates_update
export def "dcim-power-outlet-templates update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  --feed-leg: string@feed-leg-completer # Phase (for three-phase feeds)
  name: string
  --power-port: int # nullable
  --type: string@type-completer-5
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, feed_leg: record<label: string, value: string>, id: int, name: string, power_port: record<id: int, name: string, url: string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-outlet-templates/{id}/"))
  let req_body = {"device_type": $device_type, "feed_leg": $feed_leg, "name": $name, "power_port": $power_port, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/power-outlets/
# operationId: dcim_power-outlets_list
export def "dcim-power-outlets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --feed-leg: string
  --description: string
  --connection-status: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --device-id: string
  --device: string
  --tag: string
  --type: string
  --cabled: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --feed-leg-n: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --connection-status-n: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --device-id-n: string
  --device-n: string
  --tag-n: string
  --type-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<cable: record, connected_endpoint: record, connected_endpoint_type: string, connection_status: record, description: string, device: record, feed_leg: record, id: int, name: string, power_port: record, tags: list, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "feed_leg" $feed_leg "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "connection_status" $connection_status "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "cabled" $cabled "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "feed_leg__n" $feed_leg_n "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "connection_status__n" $connection_status_n "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "device_id__n" $device_id_n "scalar") (serialize-qp "device__n" $device_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/power-outlets/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/power-outlets/
#
# operationId: dcim_power-outlets_create
# --cable shape: {label?: string}
export def "dcim-power-outlets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --connection-status: oneof<nothing, bool>
  --description: string
  device: int
  --feed-leg: string@feed-leg-completer # Phase (for three-phase feeds)
  name: string
  --power-port: int # nullable
  --tags: list<string>
  --type: string@type-completer-5 # Physical port type
]: any -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, feed_leg: record<label: string, value: string>, id: int, name: string, power_port: record<cable: int, connection_status: record<label: string, value: bool>, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, url: string>, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/power-outlets/")
  let req_body = {"cable": $cable, "connection_status": $connection_status, "description": $description, "device": $device, "feed_leg": $feed_leg, "name": $name, "power_port": $power_port, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/power-outlets/{id}/
#
# operationId: dcim_power-outlets_delete
export def "dcim-power-outlets delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-outlets/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/power-outlets/{id}/
# operationId: dcim_power-outlets_read
export def "dcim-power-outlets get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, feed_leg: record<label: string, value: string>, id: int, name: string, power_port: record<cable: int, connection_status: record<label: string, value: bool>, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, url: string>, tags: list<string>, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-outlets/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/power-outlets/{id}/
#
# operationId: dcim_power-outlets_partial_update
# --cable shape: {label?: string}
export def "dcim-power-outlets update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --connection-status: oneof<nothing, bool>
  --description: string
  device: int
  --feed-leg: string@feed-leg-completer # Phase (for three-phase feeds)
  name: string
  --power-port: int # nullable
  --tags: list<string>
  --type: string@type-completer-5 # Physical port type
]: any -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, feed_leg: record<label: string, value: string>, id: int, name: string, power_port: record<cable: int, connection_status: record<label: string, value: bool>, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, url: string>, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-outlets/{id}/"))
  let req_body = {"cable": $cable, "connection_status": $connection_status, "description": $description, "device": $device, "feed_leg": $feed_leg, "name": $name, "power_port": $power_port, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/power-outlets/{id}/
#
# operationId: dcim_power-outlets_update
# --cable shape: {label?: string}
export def "dcim-power-outlets update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --connection-status: oneof<nothing, bool>
  --description: string
  device: int
  --feed-leg: string@feed-leg-completer # Phase (for three-phase feeds)
  name: string
  --power-port: int # nullable
  --tags: list<string>
  --type: string@type-completer-5 # Physical port type
]: any -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, feed_leg: record<label: string, value: string>, id: int, name: string, power_port: record<cable: int, connection_status: record<label: string, value: bool>, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, url: string>, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-outlets/{id}/"))
  let req_body = {"cable": $cable, "connection_status": $connection_status, "description": $description, "device": $device, "feed_leg": $feed_leg, "name": $name, "power_port": $power_port, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Trace a complete cable path and return each segment as a three-tuple of (termination, cable, termination).
#
# GET /dcim/power-outlets/{id}/trace/
# operationId: dcim_power-outlets_trace
export def "dcim-power-outlets-trace get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, feed_leg: record<label: string, value: string>, id: int, name: string, power_port: record<cable: int, connection_status: record<label: string, value: bool>, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, url: string>, tags: list<string>, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-outlets/{id}/trace/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/power-panels/
# operationId: dcim_power-panels_list
export def "dcim-power-panels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --rack-group-id: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --rack-group-id-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, powerfeed_count: int, rack_group: record, site: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "rack_group_id" $rack_group_id "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "rack_group_id__n" $rack_group_id_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/power-panels/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/power-panels/
#
# operationId: dcim_power-panels_create
export def "dcim-power-panels create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --rack-group: int # nullable
  site: int
]: any -> record<id: int, name: string, powerfeed_count: int, rack_group: record<id: int, name: string, rack_count: int, slug: string, url: string>, site: record<id: int, name: string, slug: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/power-panels/")
  let req_body = {"name": $name, "rack_group": $rack_group, "site": $site} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/power-panels/{id}/
#
# operationId: dcim_power-panels_delete
export def "dcim-power-panels delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-panels/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/power-panels/{id}/
# operationId: dcim_power-panels_read
export def "dcim-power-panels get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, powerfeed_count: int, rack_group: record<id: int, name: string, rack_count: int, slug: string, url: string>, site: record<id: int, name: string, slug: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-panels/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/power-panels/{id}/
#
# operationId: dcim_power-panels_partial_update
export def "dcim-power-panels update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --rack-group: int # nullable
  site: int
]: any -> record<id: int, name: string, powerfeed_count: int, rack_group: record<id: int, name: string, rack_count: int, slug: string, url: string>, site: record<id: int, name: string, slug: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-panels/{id}/"))
  let req_body = {"name": $name, "rack_group": $rack_group, "site": $site} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/power-panels/{id}/
#
# operationId: dcim_power-panels_update
export def "dcim-power-panels update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
  --rack-group: int # nullable
  site: int
]: any -> record<id: int, name: string, powerfeed_count: int, rack_group: record<id: int, name: string, rack_count: int, slug: string, url: string>, site: record<id: int, name: string, slug: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-panels/{id}/"))
  let req_body = {"name": $name, "rack_group": $rack_group, "site": $site} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/power-port-templates/
# operationId: dcim_power-port-templates_list
export def "dcim-power-port-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --type: string
  --maximum-draw: string
  --allocated-draw: string
  --q: string
  --devicetype-id: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --type-n: string
  --maximum-draw-n: string
  --maximum-draw-lte: string
  --maximum-draw-lt: string
  --maximum-draw-gte: string
  --maximum-draw-gt: string
  --allocated-draw-n: string
  --allocated-draw-lte: string
  --allocated-draw-lt: string
  --allocated-draw-gte: string
  --allocated-draw-gt: string
  --devicetype-id-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<allocated_draw: int, device_type: record, id: int, maximum_draw: int, name: string, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "maximum_draw" $maximum_draw "scalar") (serialize-qp "allocated_draw" $allocated_draw "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "devicetype_id" $devicetype_id "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "maximum_draw__n" $maximum_draw_n "scalar") (serialize-qp "maximum_draw__lte" $maximum_draw_lte "scalar") (serialize-qp "maximum_draw__lt" $maximum_draw_lt "scalar") (serialize-qp "maximum_draw__gte" $maximum_draw_gte "scalar") (serialize-qp "maximum_draw__gt" $maximum_draw_gt "scalar") (serialize-qp "allocated_draw__n" $allocated_draw_n "scalar") (serialize-qp "allocated_draw__lte" $allocated_draw_lte "scalar") (serialize-qp "allocated_draw__lt" $allocated_draw_lt "scalar") (serialize-qp "allocated_draw__gte" $allocated_draw_gte "scalar") (serialize-qp "allocated_draw__gt" $allocated_draw_gt "scalar") (serialize-qp "devicetype_id__n" $devicetype_id_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/power-port-templates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/power-port-templates/
#
# operationId: dcim_power-port-templates_create
export def "dcim-power-port-templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allocated-draw: int # Allocated power draw (watts) (nullable)
  device_type: int
  --maximum-draw: int # Maximum power draw (watts) (nullable)
  name: string
  --type: string@type-completer-6
]: any -> record<allocated_draw: int, device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, maximum_draw: int, name: string, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/power-port-templates/")
  let req_body = {"allocated_draw": $allocated_draw, "device_type": $device_type, "maximum_draw": $maximum_draw, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/power-port-templates/{id}/
#
# operationId: dcim_power-port-templates_delete
export def "dcim-power-port-templates delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-port-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/power-port-templates/{id}/
# operationId: dcim_power-port-templates_read
export def "dcim-power-port-templates get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allocated_draw: int, device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, maximum_draw: int, name: string, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-port-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/power-port-templates/{id}/
#
# operationId: dcim_power-port-templates_partial_update
export def "dcim-power-port-templates update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allocated-draw: int # Allocated power draw (watts) (nullable)
  device_type: int
  --maximum-draw: int # Maximum power draw (watts) (nullable)
  name: string
  --type: string@type-completer-6
]: any -> record<allocated_draw: int, device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, maximum_draw: int, name: string, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-port-templates/{id}/"))
  let req_body = {"allocated_draw": $allocated_draw, "device_type": $device_type, "maximum_draw": $maximum_draw, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/power-port-templates/{id}/
#
# operationId: dcim_power-port-templates_update
export def "dcim-power-port-templates update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allocated-draw: int # Allocated power draw (watts) (nullable)
  device_type: int
  --maximum-draw: int # Maximum power draw (watts) (nullable)
  name: string
  --type: string@type-completer-6
]: any -> record<allocated_draw: int, device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, maximum_draw: int, name: string, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-port-templates/{id}/"))
  let req_body = {"allocated_draw": $allocated_draw, "device_type": $device_type, "maximum_draw": $maximum_draw, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/power-ports/
# operationId: dcim_power-ports_list
export def "dcim-power-ports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --maximum-draw: string
  --allocated-draw: string
  --description: string
  --connection-status: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --device-id: string
  --device: string
  --tag: string
  --type: string
  --cabled: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --maximum-draw-n: string
  --maximum-draw-lte: string
  --maximum-draw-lt: string
  --maximum-draw-gte: string
  --maximum-draw-gt: string
  --allocated-draw-n: string
  --allocated-draw-lte: string
  --allocated-draw-lt: string
  --allocated-draw-gte: string
  --allocated-draw-gt: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --connection-status-n: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --device-id-n: string
  --device-n: string
  --tag-n: string
  --type-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<allocated_draw: int, cable: record, connected_endpoint: record, connected_endpoint_type: string, connection_status: record, description: string, device: record, id: int, maximum_draw: int, name: string, tags: list, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "maximum_draw" $maximum_draw "scalar") (serialize-qp "allocated_draw" $allocated_draw "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "connection_status" $connection_status "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "cabled" $cabled "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "maximum_draw__n" $maximum_draw_n "scalar") (serialize-qp "maximum_draw__lte" $maximum_draw_lte "scalar") (serialize-qp "maximum_draw__lt" $maximum_draw_lt "scalar") (serialize-qp "maximum_draw__gte" $maximum_draw_gte "scalar") (serialize-qp "maximum_draw__gt" $maximum_draw_gt "scalar") (serialize-qp "allocated_draw__n" $allocated_draw_n "scalar") (serialize-qp "allocated_draw__lte" $allocated_draw_lte "scalar") (serialize-qp "allocated_draw__lt" $allocated_draw_lt "scalar") (serialize-qp "allocated_draw__gte" $allocated_draw_gte "scalar") (serialize-qp "allocated_draw__gt" $allocated_draw_gt "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "connection_status__n" $connection_status_n "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "device_id__n" $device_id_n "scalar") (serialize-qp "device__n" $device_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/power-ports/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/power-ports/
#
# operationId: dcim_power-ports_create
# --cable shape: {label?: string}
export def "dcim-power-ports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allocated-draw: int # Allocated power draw (watts) (nullable)
  --cable: record # shape: {label?: string}
  --connection-status: oneof<nothing, bool>
  --description: string
  device: int
  --maximum-draw: int # Maximum power draw (watts) (nullable)
  name: string
  --tags: list<string>
  --type: string@type-completer-6 # Physical port type
]: any -> record<allocated_draw: int, cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, maximum_draw: int, name: string, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/power-ports/")
  let req_body = {"allocated_draw": $allocated_draw, "cable": $cable, "connection_status": $connection_status, "description": $description, "device": $device, "maximum_draw": $maximum_draw, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/power-ports/{id}/
#
# operationId: dcim_power-ports_delete
export def "dcim-power-ports delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-ports/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/power-ports/{id}/
# operationId: dcim_power-ports_read
export def "dcim-power-ports get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allocated_draw: int, cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, maximum_draw: int, name: string, tags: list<string>, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-ports/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/power-ports/{id}/
#
# operationId: dcim_power-ports_partial_update
# --cable shape: {label?: string}
export def "dcim-power-ports update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allocated-draw: int # Allocated power draw (watts) (nullable)
  --cable: record # shape: {label?: string}
  --connection-status: oneof<nothing, bool>
  --description: string
  device: int
  --maximum-draw: int # Maximum power draw (watts) (nullable)
  name: string
  --tags: list<string>
  --type: string@type-completer-6 # Physical port type
]: any -> record<allocated_draw: int, cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, maximum_draw: int, name: string, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-ports/{id}/"))
  let req_body = {"allocated_draw": $allocated_draw, "cable": $cable, "connection_status": $connection_status, "description": $description, "device": $device, "maximum_draw": $maximum_draw, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/power-ports/{id}/
#
# operationId: dcim_power-ports_update
# --cable shape: {label?: string}
export def "dcim-power-ports update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allocated-draw: int # Allocated power draw (watts) (nullable)
  --cable: record # shape: {label?: string}
  --connection-status: oneof<nothing, bool>
  --description: string
  device: int
  --maximum-draw: int # Maximum power draw (watts) (nullable)
  name: string
  --tags: list<string>
  --type: string@type-completer-6 # Physical port type
]: any -> record<allocated_draw: int, cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, maximum_draw: int, name: string, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-ports/{id}/"))
  let req_body = {"allocated_draw": $allocated_draw, "cable": $cable, "connection_status": $connection_status, "description": $description, "device": $device, "maximum_draw": $maximum_draw, "name": $name, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Trace a complete cable path and return each segment as a three-tuple of (termination, cable, termination).
#
# GET /dcim/power-ports/{id}/trace/
# operationId: dcim_power-ports_trace
export def "dcim-power-ports-trace get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allocated_draw: int, cable: record<id: int, label: string, url: string>, connected_endpoint: record, connected_endpoint_type: string, connection_status: record<label: string, value: bool>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, maximum_draw: int, name: string, tags: list<string>, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/power-ports/{id}/trace/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/rack-groups/
# operationId: dcim_rack-groups_list
export def "dcim-rack-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --description: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --parent-id: string
  --parent: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --parent-id-n: string
  --parent-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<description: string, id: int, name: string, parent: record, rack_count: int, site: record, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "parent" $parent "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "parent_id__n" $parent_id_n "scalar") (serialize-qp "parent__n" $parent_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/rack-groups/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/rack-groups/
#
# operationId: dcim_rack-groups_create
export def "dcim-rack-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  --parent: int # nullable
  site: int
  slug: string # format: slug
]: any -> record<description: string, id: int, name: string, parent: record<id: int, name: string, rack_count: int, slug: string, url: string>, rack_count: int, site: record<id: int, name: string, slug: string, url: string>, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/rack-groups/")
  let req_body = {"description": $description, "name": $name, "parent": $parent, "site": $site, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/rack-groups/{id}/
#
# operationId: dcim_rack-groups_delete
export def "dcim-rack-groups delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rack-groups/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/rack-groups/{id}/
# operationId: dcim_rack-groups_read
export def "dcim-rack-groups get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: int, name: string, parent: record<id: int, name: string, rack_count: int, slug: string, url: string>, rack_count: int, site: record<id: int, name: string, slug: string, url: string>, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rack-groups/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/rack-groups/{id}/
#
# operationId: dcim_rack-groups_partial_update
export def "dcim-rack-groups update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  --parent: int # nullable
  site: int
  slug: string # format: slug
]: any -> record<description: string, id: int, name: string, parent: record<id: int, name: string, rack_count: int, slug: string, url: string>, rack_count: int, site: record<id: int, name: string, slug: string, url: string>, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rack-groups/{id}/"))
  let req_body = {"description": $description, "name": $name, "parent": $parent, "site": $site, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/rack-groups/{id}/
#
# operationId: dcim_rack-groups_update
export def "dcim-rack-groups update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  --parent: int # nullable
  site: int
  slug: string # format: slug
]: any -> record<description: string, id: int, name: string, parent: record<id: int, name: string, rack_count: int, slug: string, url: string>, rack_count: int, site: record<id: int, name: string, slug: string, url: string>, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rack-groups/{id}/"))
  let req_body = {"description": $description, "name": $name, "parent": $parent, "site": $site, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/rack-reservations/
# operationId: dcim_rack-reservations_list
export def "dcim-rack-reservations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --created: string
  --tenant-group-id: string
  --tenant-group: string
  --tenant-id: string
  --tenant: string
  --q: string
  --rack-id: string
  --site-id: string
  --site: string
  --group-id: string
  --group: string
  --user-id: string
  --user: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --created-n: string
  --created-lte: string
  --created-lt: string
  --created-gte: string
  --created-gt: string
  --tenant-group-id-n: string
  --tenant-group-n: string
  --tenant-id-n: string
  --tenant-n: string
  --rack-id-n: string
  --site-id-n: string
  --site-n: string
  --group-id-n: string
  --group-n: string
  --user-id-n: string
  --user-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<created: string, description: string, id: int, rack: record, tenant: record, units: list, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "tenant_group_id" $tenant_group_id "scalar") (serialize-qp "tenant_group" $tenant_group "scalar") (serialize-qp "tenant_id" $tenant_id "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "rack_id" $rack_id "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "created__n" $created_n "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "created__lt" $created_lt "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__gt" $created_gt "scalar") (serialize-qp "tenant_group_id__n" $tenant_group_id_n "scalar") (serialize-qp "tenant_group__n" $tenant_group_n "scalar") (serialize-qp "tenant_id__n" $tenant_id_n "scalar") (serialize-qp "tenant__n" $tenant_n "scalar") (serialize-qp "rack_id__n" $rack_id_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "group_id__n" $group_id_n "scalar") (serialize-qp "group__n" $group_n "scalar") (serialize-qp "user_id__n" $user_id_n "scalar") (serialize-qp "user__n" $user_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/rack-reservations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/rack-reservations/
#
# operationId: dcim_rack-reservations_create
export def "dcim-rack-reservations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string
  rack: int
  --tenant: int # nullable
  units: list<int>
  user: int
]: any -> record<created: string, description: string, id: int, rack: record<device_count: int, display_name: string, id: int, name: string, url: string>, tenant: record<id: int, name: string, slug: string, url: string>, units: list<int>, user: record<id: int, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/rack-reservations/")
  let req_body = {"description": $description, "rack": $rack, "tenant": $tenant, "units": $units, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/rack-reservations/{id}/
#
# operationId: dcim_rack-reservations_delete
export def "dcim-rack-reservations delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rack-reservations/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/rack-reservations/{id}/
# operationId: dcim_rack-reservations_read
export def "dcim-rack-reservations get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, description: string, id: int, rack: record<device_count: int, display_name: string, id: int, name: string, url: string>, tenant: record<id: int, name: string, slug: string, url: string>, units: list<int>, user: record<id: int, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rack-reservations/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/rack-reservations/{id}/
#
# operationId: dcim_rack-reservations_partial_update
export def "dcim-rack-reservations update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string
  rack: int
  --tenant: int # nullable
  units: list<int>
  user: int
]: any -> record<created: string, description: string, id: int, rack: record<device_count: int, display_name: string, id: int, name: string, url: string>, tenant: record<id: int, name: string, slug: string, url: string>, units: list<int>, user: record<id: int, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rack-reservations/{id}/"))
  let req_body = {"description": $description, "rack": $rack, "tenant": $tenant, "units": $units, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/rack-reservations/{id}/
#
# operationId: dcim_rack-reservations_update
export def "dcim-rack-reservations update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string
  rack: int
  --tenant: int # nullable
  units: list<int>
  user: int
]: any -> record<created: string, description: string, id: int, rack: record<device_count: int, display_name: string, id: int, name: string, url: string>, tenant: record<id: int, name: string, slug: string, url: string>, units: list<int>, user: record<id: int, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rack-reservations/{id}/"))
  let req_body = {"description": $description, "rack": $rack, "tenant": $tenant, "units": $units, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/rack-roles/
# operationId: dcim_rack-roles_list
export def "dcim-rack-roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --color: string
  --q: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --color-n: string
  --color-ic: string
  --color-nic: string
  --color-iew: string
  --color-niew: string
  --color-isw: string
  --color-nisw: string
  --color-ie: string
  --color-nie: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<color: string, description: string, id: int, name: string, rack_count: int, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "color" $color "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "color__n" $color_n "scalar") (serialize-qp "color__ic" $color_ic "scalar") (serialize-qp "color__nic" $color_nic "scalar") (serialize-qp "color__iew" $color_iew "scalar") (serialize-qp "color__niew" $color_niew "scalar") (serialize-qp "color__isw" $color_isw "scalar") (serialize-qp "color__nisw" $color_nisw "scalar") (serialize-qp "color__ie" $color_ie "scalar") (serialize-qp "color__nie" $color_nie "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/rack-roles/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/rack-roles/
#
# operationId: dcim_rack-roles_create
export def "dcim-rack-roles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: string
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<color: string, description: string, id: int, name: string, rack_count: int, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/rack-roles/")
  let req_body = {"color": $color, "description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/rack-roles/{id}/
#
# operationId: dcim_rack-roles_delete
export def "dcim-rack-roles delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rack-roles/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/rack-roles/{id}/
# operationId: dcim_rack-roles_read
export def "dcim-rack-roles get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<color: string, description: string, id: int, name: string, rack_count: int, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rack-roles/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/rack-roles/{id}/
#
# operationId: dcim_rack-roles_partial_update
export def "dcim-rack-roles update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: string
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<color: string, description: string, id: int, name: string, rack_count: int, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rack-roles/{id}/"))
  let req_body = {"color": $color, "description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/rack-roles/{id}/
#
# operationId: dcim_rack-roles_update
export def "dcim-rack-roles update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: string
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<color: string, description: string, id: int, name: string, rack_count: int, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rack-roles/{id}/"))
  let req_body = {"color": $color, "description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/racks/
# operationId: dcim_racks_list
export def "dcim-racks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --facility-id: string
  --asset-tag: string
  --type: string
  --width: string
  --u-height: string
  --desc-units: string
  --outer-width: string
  --outer-depth: string
  --outer-unit: string
  --tenant-group-id: string
  --tenant-group: string
  --tenant-id: string
  --tenant: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --group-id: string
  --group: string
  --status: string
  --role-id: string
  --role: string
  --serial: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --facility-id-n: string
  --facility-id-ic: string
  --facility-id-nic: string
  --facility-id-iew: string
  --facility-id-niew: string
  --facility-id-isw: string
  --facility-id-nisw: string
  --facility-id-ie: string
  --facility-id-nie: string
  --asset-tag-n: string
  --asset-tag-ic: string
  --asset-tag-nic: string
  --asset-tag-iew: string
  --asset-tag-niew: string
  --asset-tag-isw: string
  --asset-tag-nisw: string
  --asset-tag-ie: string
  --asset-tag-nie: string
  --type-n: string
  --width-n: string
  --u-height-n: string
  --u-height-lte: string
  --u-height-lt: string
  --u-height-gte: string
  --u-height-gt: string
  --outer-width-n: string
  --outer-width-lte: string
  --outer-width-lt: string
  --outer-width-gte: string
  --outer-width-gt: string
  --outer-depth-n: string
  --outer-depth-lte: string
  --outer-depth-lt: string
  --outer-depth-gte: string
  --outer-depth-gt: string
  --outer-unit-n: string
  --tenant-group-id-n: string
  --tenant-group-n: string
  --tenant-id-n: string
  --tenant-n: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --group-id-n: string
  --group-n: string
  --status-n: string
  --role-id-n: string
  --role-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<asset_tag: string, comments: string, created: string, custom_fields: record, desc_units: bool, device_count: int, display_name: string, facility_id: string, group: record, id: int, last_updated: string, name: string, outer_depth: int, outer_unit: record, outer_width: int, powerfeed_count: int, role: record, serial: string, site: record, status: record, tags: list, tenant: record, type: record, u_height: int, width: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "facility_id" $facility_id "scalar") (serialize-qp "asset_tag" $asset_tag "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "u_height" $u_height "scalar") (serialize-qp "desc_units" $desc_units "scalar") (serialize-qp "outer_width" $outer_width "scalar") (serialize-qp "outer_depth" $outer_depth "scalar") (serialize-qp "outer_unit" $outer_unit "scalar") (serialize-qp "tenant_group_id" $tenant_group_id "scalar") (serialize-qp "tenant_group" $tenant_group "scalar") (serialize-qp "tenant_id" $tenant_id "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "role_id" $role_id "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "serial" $serial "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "facility_id__n" $facility_id_n "scalar") (serialize-qp "facility_id__ic" $facility_id_ic "scalar") (serialize-qp "facility_id__nic" $facility_id_nic "scalar") (serialize-qp "facility_id__iew" $facility_id_iew "scalar") (serialize-qp "facility_id__niew" $facility_id_niew "scalar") (serialize-qp "facility_id__isw" $facility_id_isw "scalar") (serialize-qp "facility_id__nisw" $facility_id_nisw "scalar") (serialize-qp "facility_id__ie" $facility_id_ie "scalar") (serialize-qp "facility_id__nie" $facility_id_nie "scalar") (serialize-qp "asset_tag__n" $asset_tag_n "scalar") (serialize-qp "asset_tag__ic" $asset_tag_ic "scalar") (serialize-qp "asset_tag__nic" $asset_tag_nic "scalar") (serialize-qp "asset_tag__iew" $asset_tag_iew "scalar") (serialize-qp "asset_tag__niew" $asset_tag_niew "scalar") (serialize-qp "asset_tag__isw" $asset_tag_isw "scalar") (serialize-qp "asset_tag__nisw" $asset_tag_nisw "scalar") (serialize-qp "asset_tag__ie" $asset_tag_ie "scalar") (serialize-qp "asset_tag__nie" $asset_tag_nie "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "width__n" $width_n "scalar") (serialize-qp "u_height__n" $u_height_n "scalar") (serialize-qp "u_height__lte" $u_height_lte "scalar") (serialize-qp "u_height__lt" $u_height_lt "scalar") (serialize-qp "u_height__gte" $u_height_gte "scalar") (serialize-qp "u_height__gt" $u_height_gt "scalar") (serialize-qp "outer_width__n" $outer_width_n "scalar") (serialize-qp "outer_width__lte" $outer_width_lte "scalar") (serialize-qp "outer_width__lt" $outer_width_lt "scalar") (serialize-qp "outer_width__gte" $outer_width_gte "scalar") (serialize-qp "outer_width__gt" $outer_width_gt "scalar") (serialize-qp "outer_depth__n" $outer_depth_n "scalar") (serialize-qp "outer_depth__lte" $outer_depth_lte "scalar") (serialize-qp "outer_depth__lt" $outer_depth_lt "scalar") (serialize-qp "outer_depth__gte" $outer_depth_gte "scalar") (serialize-qp "outer_depth__gt" $outer_depth_gt "scalar") (serialize-qp "outer_unit__n" $outer_unit_n "scalar") (serialize-qp "tenant_group_id__n" $tenant_group_id_n "scalar") (serialize-qp "tenant_group__n" $tenant_group_n "scalar") (serialize-qp "tenant_id__n" $tenant_id_n "scalar") (serialize-qp "tenant__n" $tenant_n "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "group_id__n" $group_id_n "scalar") (serialize-qp "group__n" $group_n "scalar") (serialize-qp "status__n" $status_n "scalar") (serialize-qp "role_id__n" $role_id_n "scalar") (serialize-qp "role__n" $role_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/racks/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/racks/
#
# operationId: dcim_racks_create
export def "dcim-racks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-tag: string # A unique tag used to identify this rack (nullable)
  --comments: string
  --custom-fields: record # default: {}
  --desc-units: oneof<nothing, bool> # Units are numbered top-to-bottom
  --facility-id: string # Locally-assigned identifier (nullable)
  --group: int # Assigned group (nullable)
  name: string
  --outer-depth: int # Outer dimension of rack (depth) (nullable)
  --outer-unit: string@outer-unit-completer
  --outer-width: int # Outer dimension of rack (width) (nullable)
  --role: int # Functional role (nullable)
  --serial: string
  site: int
  --status: string@status-completer-4
  --tags: list<string>
  --tenant: int # nullable
  --type: string@type-completer-7
  --u-height: int # Height in rack units
  --width: int@width-completer # Rail-to-rail width
]: any -> record<asset_tag: string, comments: string, created: string, custom_fields: record, desc_units: bool, device_count: int, display_name: string, facility_id: string, group: record<id: int, name: string, rack_count: int, slug: string, url: string>, id: int, last_updated: string, name: string, outer_depth: int, outer_unit: record<label: string, value: string>, outer_width: int, powerfeed_count: int, role: record<id: int, name: string, rack_count: int, slug: string, url: string>, serial: string, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, type: record<label: string, value: string>, u_height: int, width: record<label: string, value: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/racks/")
  let req_body = {"asset_tag": $asset_tag, "comments": $comments, "custom_fields": $custom_fields, "desc_units": $desc_units, "facility_id": $facility_id, "group": $group, "name": $name, "outer_depth": $outer_depth, "outer_unit": $outer_unit, "outer_width": $outer_width, "role": $role, "serial": $serial, "site": $site, "status": $status, "tags": $tags, "tenant": $tenant, "type": $type, "u_height": $u_height, "width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/racks/{id}/
#
# operationId: dcim_racks_delete
export def "dcim-racks delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/racks/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/racks/{id}/
# operationId: dcim_racks_read
export def "dcim-racks get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<asset_tag: string, comments: string, created: string, custom_fields: record, desc_units: bool, device_count: int, display_name: string, facility_id: string, group: record<id: int, name: string, rack_count: int, slug: string, url: string>, id: int, last_updated: string, name: string, outer_depth: int, outer_unit: record<label: string, value: string>, outer_width: int, powerfeed_count: int, role: record<id: int, name: string, rack_count: int, slug: string, url: string>, serial: string, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, type: record<label: string, value: string>, u_height: int, width: record<label: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/racks/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/racks/{id}/
#
# operationId: dcim_racks_partial_update
export def "dcim-racks update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-tag: string # A unique tag used to identify this rack (nullable)
  --comments: string
  --custom-fields: record # default: {}
  --desc-units: oneof<nothing, bool> # Units are numbered top-to-bottom
  --facility-id: string # Locally-assigned identifier (nullable)
  --group: int # Assigned group (nullable)
  name: string
  --outer-depth: int # Outer dimension of rack (depth) (nullable)
  --outer-unit: string@outer-unit-completer
  --outer-width: int # Outer dimension of rack (width) (nullable)
  --role: int # Functional role (nullable)
  --serial: string
  site: int
  --status: string@status-completer-4
  --tags: list<string>
  --tenant: int # nullable
  --type: string@type-completer-7
  --u-height: int # Height in rack units
  --width: int@width-completer # Rail-to-rail width
]: any -> record<asset_tag: string, comments: string, created: string, custom_fields: record, desc_units: bool, device_count: int, display_name: string, facility_id: string, group: record<id: int, name: string, rack_count: int, slug: string, url: string>, id: int, last_updated: string, name: string, outer_depth: int, outer_unit: record<label: string, value: string>, outer_width: int, powerfeed_count: int, role: record<id: int, name: string, rack_count: int, slug: string, url: string>, serial: string, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, type: record<label: string, value: string>, u_height: int, width: record<label: string, value: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/racks/{id}/"))
  let req_body = {"asset_tag": $asset_tag, "comments": $comments, "custom_fields": $custom_fields, "desc_units": $desc_units, "facility_id": $facility_id, "group": $group, "name": $name, "outer_depth": $outer_depth, "outer_unit": $outer_unit, "outer_width": $outer_width, "role": $role, "serial": $serial, "site": $site, "status": $status, "tags": $tags, "tenant": $tenant, "type": $type, "u_height": $u_height, "width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/racks/{id}/
#
# operationId: dcim_racks_update
export def "dcim-racks update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-tag: string # A unique tag used to identify this rack (nullable)
  --comments: string
  --custom-fields: record # default: {}
  --desc-units: oneof<nothing, bool> # Units are numbered top-to-bottom
  --facility-id: string # Locally-assigned identifier (nullable)
  --group: int # Assigned group (nullable)
  name: string
  --outer-depth: int # Outer dimension of rack (depth) (nullable)
  --outer-unit: string@outer-unit-completer
  --outer-width: int # Outer dimension of rack (width) (nullable)
  --role: int # Functional role (nullable)
  --serial: string
  site: int
  --status: string@status-completer-4
  --tags: list<string>
  --tenant: int # nullable
  --type: string@type-completer-7
  --u-height: int # Height in rack units
  --width: int@width-completer # Rail-to-rail width
]: any -> record<asset_tag: string, comments: string, created: string, custom_fields: record, desc_units: bool, device_count: int, display_name: string, facility_id: string, group: record<id: int, name: string, rack_count: int, slug: string, url: string>, id: int, last_updated: string, name: string, outer_depth: int, outer_unit: record<label: string, value: string>, outer_width: int, powerfeed_count: int, role: record<id: int, name: string, rack_count: int, slug: string, url: string>, serial: string, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, type: record<label: string, value: string>, u_height: int, width: record<label: string, value: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/racks/{id}/"))
  let req_body = {"asset_tag": $asset_tag, "comments": $comments, "custom_fields": $custom_fields, "desc_units": $desc_units, "facility_id": $facility_id, "group": $group, "name": $name, "outer_depth": $outer_depth, "outer_unit": $outer_unit, "outer_width": $outer_width, "role": $role, "serial": $serial, "site": $site, "status": $status, "tags": $tags, "tenant": $tenant, "type": $type, "u_height": $u_height, "width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Rack elevation representing the list of rack units. Also supports rendering the elevation as an SVG.
#
# GET /dcim/racks/{id}/elevation/
# operationId: dcim_racks_elevation
export def "dcim-racks-elevation get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
  --face: string@face-completer # default: front
  --render: string@render-completer # default: json
  --unit-width: int # default: 220
  --unit-height: int # default: 22
  --legend-width: int # default: 30
  --exclude: int
  --expand-devices: oneof<nothing, bool> # default: true
  --include-images: oneof<nothing, bool> # default: true
]: nothing -> table<device: record<display_name: string, id: int, name: string, url: string>, face: record<label: string, value: string>, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "face" $face "scalar") (serialize-qp "render" $render "scalar") (serialize-qp "unit_width" $unit_width "scalar") (serialize-qp "unit_height" $unit_height "scalar") (serialize-qp "legend_width" $legend_width "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "expand_devices" $expand_devices "scalar") (serialize-qp "include_images" $include_images "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/racks/{id}/elevation/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/rear-port-templates/
# operationId: dcim_rear-port-templates_list
export def "dcim-rear-port-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --type: string
  --positions: string
  --q: string
  --devicetype-id: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --type-n: string
  --positions-n: string
  --positions-lte: string
  --positions-lt: string
  --positions-gte: string
  --positions-gt: string
  --devicetype-id-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<device_type: record, id: int, name: string, positions: int, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "positions" $positions "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "devicetype_id" $devicetype_id "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "positions__n" $positions_n "scalar") (serialize-qp "positions__lte" $positions_lte "scalar") (serialize-qp "positions__lt" $positions_lt "scalar") (serialize-qp "positions__gte" $positions_gte "scalar") (serialize-qp "positions__gt" $positions_gt "scalar") (serialize-qp "devicetype_id__n" $devicetype_id_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/rear-port-templates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/rear-port-templates/
#
# operationId: dcim_rear-port-templates_create
export def "dcim-rear-port-templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  name: string
  --positions: int
  type: string@type-completer-2
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, positions: int, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/rear-port-templates/")
  let req_body = {"device_type": $device_type, "name": $name, "positions": $positions, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/rear-port-templates/{id}/
#
# operationId: dcim_rear-port-templates_delete
export def "dcim-rear-port-templates delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rear-port-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/rear-port-templates/{id}/
# operationId: dcim_rear-port-templates_read
export def "dcim-rear-port-templates get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, positions: int, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rear-port-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/rear-port-templates/{id}/
#
# operationId: dcim_rear-port-templates_partial_update
export def "dcim-rear-port-templates update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  name: string
  --positions: int
  type: string@type-completer-2
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, positions: int, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rear-port-templates/{id}/"))
  let req_body = {"device_type": $device_type, "name": $name, "positions": $positions, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/rear-port-templates/{id}/
#
# operationId: dcim_rear-port-templates_update
export def "dcim-rear-port-templates update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  device_type: int
  name: string
  --positions: int
  type: string@type-completer-2
]: any -> record<device_type: record<device_count: int, display_name: string, id: int, manufacturer: record<devicetype_count: int, id: int, name: string, slug: string, url: string>, model: string, slug: string, url: string>, id: int, name: string, positions: int, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rear-port-templates/{id}/"))
  let req_body = {"device_type": $device_type, "name": $name, "positions": $positions, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/rear-ports/
# operationId: dcim_rear-ports_list
export def "dcim-rear-ports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --type: string
  --positions: string
  --description: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --device-id: string
  --device: string
  --tag: string
  --cabled: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --type-n: string
  --positions-n: string
  --positions-lte: string
  --positions-lt: string
  --positions-gte: string
  --positions-gt: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --device-id-n: string
  --device-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<cable: record, description: string, device: record, id: int, name: string, positions: int, tags: list, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "positions" $positions "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "cabled" $cabled "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "positions__n" $positions_n "scalar") (serialize-qp "positions__lte" $positions_lte "scalar") (serialize-qp "positions__lt" $positions_lt "scalar") (serialize-qp "positions__gte" $positions_gte "scalar") (serialize-qp "positions__gt" $positions_gt "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "device_id__n" $device_id_n "scalar") (serialize-qp "device__n" $device_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/rear-ports/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/rear-ports/
#
# operationId: dcim_rear-ports_create
# --cable shape: {label?: string}
export def "dcim-rear-ports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --description: string
  device: int
  name: string
  --positions: int
  --tags: list<string>
  type: string@type-completer-2
]: any -> record<cable: record<id: int, label: string, url: string>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, positions: int, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/rear-ports/")
  let req_body = {"cable": $cable, "description": $description, "device": $device, "name": $name, "positions": $positions, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/rear-ports/{id}/
#
# operationId: dcim_rear-ports_delete
export def "dcim-rear-ports delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rear-ports/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/rear-ports/{id}/
# operationId: dcim_rear-ports_read
export def "dcim-rear-ports get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cable: record<id: int, label: string, url: string>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, positions: int, tags: list<string>, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rear-ports/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/rear-ports/{id}/
#
# operationId: dcim_rear-ports_partial_update
# --cable shape: {label?: string}
export def "dcim-rear-ports update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --description: string
  device: int
  name: string
  --positions: int
  --tags: list<string>
  type: string@type-completer-2
]: any -> record<cable: record<id: int, label: string, url: string>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, positions: int, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rear-ports/{id}/"))
  let req_body = {"cable": $cable, "description": $description, "device": $device, "name": $name, "positions": $positions, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/rear-ports/{id}/
#
# operationId: dcim_rear-ports_update
# --cable shape: {label?: string}
export def "dcim-rear-ports update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cable: record # shape: {label?: string}
  --description: string
  device: int
  name: string
  --positions: int
  --tags: list<string>
  type: string@type-completer-2
]: any -> record<cable: record<id: int, label: string, url: string>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, positions: int, tags: list<string>, type: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rear-ports/{id}/"))
  let req_body = {"cable": $cable, "description": $description, "device": $device, "name": $name, "positions": $positions, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Trace a complete cable path and return each segment as a three-tuple of (termination, cable, termination).
#
# GET /dcim/rear-ports/{id}/trace/
# operationId: dcim_rear-ports_trace
export def "dcim-rear-ports-trace get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cable: record<id: int, label: string, url: string>, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, positions: int, tags: list<string>, type: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/rear-ports/{id}/trace/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/regions/
# operationId: dcim_regions_list
export def "dcim-regions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --description: string
  --q: string
  --parent-id: string
  --parent: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --parent-id-n: string
  --parent-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<description: string, id: int, name: string, parent: record, site_count: int, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "parent" $parent "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "parent_id__n" $parent_id_n "scalar") (serialize-qp "parent__n" $parent_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/regions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/regions/
#
# operationId: dcim_regions_create
export def "dcim-regions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  --parent: int # nullable
  slug: string # format: slug
]: any -> record<description: string, id: int, name: string, parent: record<id: int, name: string, site_count: int, slug: string, url: string>, site_count: int, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/regions/")
  let req_body = {"description": $description, "name": $name, "parent": $parent, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/regions/{id}/
#
# operationId: dcim_regions_delete
export def "dcim-regions delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/regions/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/regions/{id}/
# operationId: dcim_regions_read
export def "dcim-regions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: int, name: string, parent: record<id: int, name: string, site_count: int, slug: string, url: string>, site_count: int, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/regions/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/regions/{id}/
#
# operationId: dcim_regions_partial_update
export def "dcim-regions update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  --parent: int # nullable
  slug: string # format: slug
]: any -> record<description: string, id: int, name: string, parent: record<id: int, name: string, site_count: int, slug: string, url: string>, site_count: int, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/regions/{id}/"))
  let req_body = {"description": $description, "name": $name, "parent": $parent, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/regions/{id}/
#
# operationId: dcim_regions_update
export def "dcim-regions update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  --parent: int # nullable
  slug: string # format: slug
]: any -> record<description: string, id: int, name: string, parent: record<id: int, name: string, site_count: int, slug: string, url: string>, site_count: int, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/regions/{id}/"))
  let req_body = {"description": $description, "name": $name, "parent": $parent, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /dcim/sites/
# operationId: dcim_sites_list
export def "dcim-sites list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --facility: string
  --asn: string
  --latitude: string
  --longitude: string
  --contact-name: string
  --contact-phone: string
  --contact-email: string
  --tenant-group-id: string
  --tenant-group: string
  --tenant-id: string
  --tenant: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --status: string
  --region-id: string
  --region: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --facility-n: string
  --facility-ic: string
  --facility-nic: string
  --facility-iew: string
  --facility-niew: string
  --facility-isw: string
  --facility-nisw: string
  --facility-ie: string
  --facility-nie: string
  --asn-n: string
  --asn-lte: string
  --asn-lt: string
  --asn-gte: string
  --asn-gt: string
  --latitude-n: string
  --latitude-lte: string
  --latitude-lt: string
  --latitude-gte: string
  --latitude-gt: string
  --longitude-n: string
  --longitude-lte: string
  --longitude-lt: string
  --longitude-gte: string
  --longitude-gt: string
  --contact-name-n: string
  --contact-name-ic: string
  --contact-name-nic: string
  --contact-name-iew: string
  --contact-name-niew: string
  --contact-name-isw: string
  --contact-name-nisw: string
  --contact-name-ie: string
  --contact-name-nie: string
  --contact-phone-n: string
  --contact-phone-ic: string
  --contact-phone-nic: string
  --contact-phone-iew: string
  --contact-phone-niew: string
  --contact-phone-isw: string
  --contact-phone-nisw: string
  --contact-phone-ie: string
  --contact-phone-nie: string
  --contact-email-n: string
  --contact-email-ic: string
  --contact-email-nic: string
  --contact-email-iew: string
  --contact-email-niew: string
  --contact-email-isw: string
  --contact-email-nisw: string
  --contact-email-ie: string
  --contact-email-nie: string
  --tenant-group-id-n: string
  --tenant-group-n: string
  --tenant-id-n: string
  --tenant-n: string
  --status-n: string
  --region-id-n: string
  --region-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<asn: int, circuit_count: int, comments: string, contact_email: string, contact_name: string, contact_phone: string, created: string, custom_fields: record, description: string, device_count: int, facility: string, id: int, last_updated: string, latitude: string, longitude: string, name: string, physical_address: string, prefix_count: int, rack_count: int, region: record, shipping_address: string, slug: string, status: record, tags: list, tenant: record, time_zone: string, virtualmachine_count: int, vlan_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "facility" $facility "scalar") (serialize-qp "asn" $asn "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "contact_name" $contact_name "scalar") (serialize-qp "contact_phone" $contact_phone "scalar") (serialize-qp "contact_email" $contact_email "scalar") (serialize-qp "tenant_group_id" $tenant_group_id "scalar") (serialize-qp "tenant_group" $tenant_group "scalar") (serialize-qp "tenant_id" $tenant_id "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "facility__n" $facility_n "scalar") (serialize-qp "facility__ic" $facility_ic "scalar") (serialize-qp "facility__nic" $facility_nic "scalar") (serialize-qp "facility__iew" $facility_iew "scalar") (serialize-qp "facility__niew" $facility_niew "scalar") (serialize-qp "facility__isw" $facility_isw "scalar") (serialize-qp "facility__nisw" $facility_nisw "scalar") (serialize-qp "facility__ie" $facility_ie "scalar") (serialize-qp "facility__nie" $facility_nie "scalar") (serialize-qp "asn__n" $asn_n "scalar") (serialize-qp "asn__lte" $asn_lte "scalar") (serialize-qp "asn__lt" $asn_lt "scalar") (serialize-qp "asn__gte" $asn_gte "scalar") (serialize-qp "asn__gt" $asn_gt "scalar") (serialize-qp "latitude__n" $latitude_n "scalar") (serialize-qp "latitude__lte" $latitude_lte "scalar") (serialize-qp "latitude__lt" $latitude_lt "scalar") (serialize-qp "latitude__gte" $latitude_gte "scalar") (serialize-qp "latitude__gt" $latitude_gt "scalar") (serialize-qp "longitude__n" $longitude_n "scalar") (serialize-qp "longitude__lte" $longitude_lte "scalar") (serialize-qp "longitude__lt" $longitude_lt "scalar") (serialize-qp "longitude__gte" $longitude_gte "scalar") (serialize-qp "longitude__gt" $longitude_gt "scalar") (serialize-qp "contact_name__n" $contact_name_n "scalar") (serialize-qp "contact_name__ic" $contact_name_ic "scalar") (serialize-qp "contact_name__nic" $contact_name_nic "scalar") (serialize-qp "contact_name__iew" $contact_name_iew "scalar") (serialize-qp "contact_name__niew" $contact_name_niew "scalar") (serialize-qp "contact_name__isw" $contact_name_isw "scalar") (serialize-qp "contact_name__nisw" $contact_name_nisw "scalar") (serialize-qp "contact_name__ie" $contact_name_ie "scalar") (serialize-qp "contact_name__nie" $contact_name_nie "scalar") (serialize-qp "contact_phone__n" $contact_phone_n "scalar") (serialize-qp "contact_phone__ic" $contact_phone_ic "scalar") (serialize-qp "contact_phone__nic" $contact_phone_nic "scalar") (serialize-qp "contact_phone__iew" $contact_phone_iew "scalar") (serialize-qp "contact_phone__niew" $contact_phone_niew "scalar") (serialize-qp "contact_phone__isw" $contact_phone_isw "scalar") (serialize-qp "contact_phone__nisw" $contact_phone_nisw "scalar") (serialize-qp "contact_phone__ie" $contact_phone_ie "scalar") (serialize-qp "contact_phone__nie" $contact_phone_nie "scalar") (serialize-qp "contact_email__n" $contact_email_n "scalar") (serialize-qp "contact_email__ic" $contact_email_ic "scalar") (serialize-qp "contact_email__nic" $contact_email_nic "scalar") (serialize-qp "contact_email__iew" $contact_email_iew "scalar") (serialize-qp "contact_email__niew" $contact_email_niew "scalar") (serialize-qp "contact_email__isw" $contact_email_isw "scalar") (serialize-qp "contact_email__nisw" $contact_email_nisw "scalar") (serialize-qp "contact_email__ie" $contact_email_ie "scalar") (serialize-qp "contact_email__nie" $contact_email_nie "scalar") (serialize-qp "tenant_group_id__n" $tenant_group_id_n "scalar") (serialize-qp "tenant_group__n" $tenant_group_n "scalar") (serialize-qp "tenant_id__n" $tenant_id_n "scalar") (serialize-qp "tenant__n" $tenant_n "scalar") (serialize-qp "status__n" $status_n "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/sites/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/sites/
#
# operationId: dcim_sites_create
export def "dcim-sites create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asn: int # 32-bit autonomous system number (nullable)
  --comments: string
  --contact-email: string # format: email
  --contact-name: string
  --contact-phone: string
  --custom-fields: record # default: {}
  --description: string
  --facility: string # Local facility ID or description
  --latitude: string # GPS coordinate (latitude) (nullable, format: decimal)
  --longitude: string # GPS coordinate (longitude) (nullable, format: decimal)
  name: string
  --physical-address: string
  --region: int # nullable
  --shipping-address: string
  slug: string # format: slug
  --status: string@status-completer-5
  --tags: list<string>
  --tenant: int # nullable
  --time-zone: string
]: any -> record<asn: int, circuit_count: int, comments: string, contact_email: string, contact_name: string, contact_phone: string, created: string, custom_fields: record, description: string, device_count: int, facility: string, id: int, last_updated: string, latitude: string, longitude: string, name: string, physical_address: string, prefix_count: int, rack_count: int, region: record<id: int, name: string, site_count: int, slug: string, url: string>, shipping_address: string, slug: string, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, time_zone: string, virtualmachine_count: int, vlan_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/sites/")
  let req_body = {"asn": $asn, "comments": $comments, "contact_email": $contact_email, "contact_name": $contact_name, "contact_phone": $contact_phone, "custom_fields": $custom_fields, "description": $description, "facility": $facility, "latitude": $latitude, "longitude": $longitude, "name": $name, "physical_address": $physical_address, "region": $region, "shipping_address": $shipping_address, "slug": $slug, "status": $status, "tags": $tags, "tenant": $tenant, "time_zone": $time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/sites/{id}/
#
# operationId: dcim_sites_delete
export def "dcim-sites delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/sites/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/sites/{id}/
# operationId: dcim_sites_read
export def "dcim-sites get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<asn: int, circuit_count: int, comments: string, contact_email: string, contact_name: string, contact_phone: string, created: string, custom_fields: record, description: string, device_count: int, facility: string, id: int, last_updated: string, latitude: string, longitude: string, name: string, physical_address: string, prefix_count: int, rack_count: int, region: record<id: int, name: string, site_count: int, slug: string, url: string>, shipping_address: string, slug: string, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, time_zone: string, virtualmachine_count: int, vlan_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/sites/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/sites/{id}/
#
# operationId: dcim_sites_partial_update
export def "dcim-sites update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asn: int # 32-bit autonomous system number (nullable)
  --comments: string
  --contact-email: string # format: email
  --contact-name: string
  --contact-phone: string
  --custom-fields: record # default: {}
  --description: string
  --facility: string # Local facility ID or description
  --latitude: string # GPS coordinate (latitude) (nullable, format: decimal)
  --longitude: string # GPS coordinate (longitude) (nullable, format: decimal)
  name: string
  --physical-address: string
  --region: int # nullable
  --shipping-address: string
  slug: string # format: slug
  --status: string@status-completer-5
  --tags: list<string>
  --tenant: int # nullable
  --time-zone: string
]: any -> record<asn: int, circuit_count: int, comments: string, contact_email: string, contact_name: string, contact_phone: string, created: string, custom_fields: record, description: string, device_count: int, facility: string, id: int, last_updated: string, latitude: string, longitude: string, name: string, physical_address: string, prefix_count: int, rack_count: int, region: record<id: int, name: string, site_count: int, slug: string, url: string>, shipping_address: string, slug: string, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, time_zone: string, virtualmachine_count: int, vlan_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/sites/{id}/"))
  let req_body = {"asn": $asn, "comments": $comments, "contact_email": $contact_email, "contact_name": $contact_name, "contact_phone": $contact_phone, "custom_fields": $custom_fields, "description": $description, "facility": $facility, "latitude": $latitude, "longitude": $longitude, "name": $name, "physical_address": $physical_address, "region": $region, "shipping_address": $shipping_address, "slug": $slug, "status": $status, "tags": $tags, "tenant": $tenant, "time_zone": $time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/sites/{id}/
#
# operationId: dcim_sites_update
export def "dcim-sites update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --asn: int # 32-bit autonomous system number (nullable)
  --comments: string
  --contact-email: string # format: email
  --contact-name: string
  --contact-phone: string
  --custom-fields: record # default: {}
  --description: string
  --facility: string # Local facility ID or description
  --latitude: string # GPS coordinate (latitude) (nullable, format: decimal)
  --longitude: string # GPS coordinate (longitude) (nullable, format: decimal)
  name: string
  --physical-address: string
  --region: int # nullable
  --shipping-address: string
  slug: string # format: slug
  --status: string@status-completer-5
  --tags: list<string>
  --tenant: int # nullable
  --time-zone: string
]: any -> record<asn: int, circuit_count: int, comments: string, contact_email: string, contact_name: string, contact_phone: string, created: string, custom_fields: record, description: string, device_count: int, facility: string, id: int, last_updated: string, latitude: string, longitude: string, name: string, physical_address: string, prefix_count: int, rack_count: int, region: record<id: int, name: string, site_count: int, slug: string, url: string>, shipping_address: string, slug: string, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, time_zone: string, virtualmachine_count: int, vlan_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/sites/{id}/"))
  let req_body = {"asn": $asn, "comments": $comments, "contact_email": $contact_email, "contact_name": $contact_name, "contact_phone": $contact_phone, "custom_fields": $custom_fields, "description": $description, "facility": $facility, "latitude": $latitude, "longitude": $longitude, "name": $name, "physical_address": $physical_address, "region": $region, "shipping_address": $shipping_address, "slug": $slug, "status": $status, "tags": $tags, "tenant": $tenant, "time_zone": $time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# A convenience method for rendering graphs for a particular site.
#
# GET /dcim/sites/{id}/graphs/
# operationId: dcim_sites_graphs
export def "dcim-sites-graphs get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<asn: int, circuit_count: int, comments: string, contact_email: string, contact_name: string, contact_phone: string, created: string, custom_fields: record, description: string, device_count: int, facility: string, id: int, last_updated: string, latitude: string, longitude: string, name: string, physical_address: string, prefix_count: int, rack_count: int, region: record<id: int, name: string, site_count: int, slug: string, url: string>, shipping_address: string, slug: string, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, time_zone: string, virtualmachine_count: int, vlan_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/sites/{id}/graphs/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/virtual-chassis/
# operationId: dcim_virtual-chassis_list
export def "dcim-virtual-chassis list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --domain: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --tenant-id: string
  --tenant: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --domain-n: string
  --domain-ic: string
  --domain-nic: string
  --domain-iew: string
  --domain-niew: string
  --domain-isw: string
  --domain-nisw: string
  --domain-ie: string
  --domain-nie: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --tenant-id-n: string
  --tenant-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<domain: string, id: int, master: record, member_count: int, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "tenant_id" $tenant_id "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "domain__n" $domain_n "scalar") (serialize-qp "domain__ic" $domain_ic "scalar") (serialize-qp "domain__nic" $domain_nic "scalar") (serialize-qp "domain__iew" $domain_iew "scalar") (serialize-qp "domain__niew" $domain_niew "scalar") (serialize-qp "domain__isw" $domain_isw "scalar") (serialize-qp "domain__nisw" $domain_nisw "scalar") (serialize-qp "domain__ie" $domain_ie "scalar") (serialize-qp "domain__nie" $domain_nie "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "tenant_id__n" $tenant_id_n "scalar") (serialize-qp "tenant__n" $tenant_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dcim/virtual-chassis/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /dcim/virtual-chassis/
#
# operationId: dcim_virtual-chassis_create
export def "dcim-virtual-chassis create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string
  master: int
  --tags: list<string>
]: any -> record<domain: string, id: int, master: record<display_name: string, id: int, name: string, url: string>, member_count: int, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dcim/virtual-chassis/")
  let req_body = {"domain": $domain, "master": $master, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /dcim/virtual-chassis/{id}/
#
# operationId: dcim_virtual-chassis_delete
export def "dcim-virtual-chassis delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/virtual-chassis/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /dcim/virtual-chassis/{id}/
# operationId: dcim_virtual-chassis_read
export def "dcim-virtual-chassis get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain: string, id: int, master: record<display_name: string, id: int, name: string, url: string>, member_count: int, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/virtual-chassis/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /dcim/virtual-chassis/{id}/
#
# operationId: dcim_virtual-chassis_partial_update
export def "dcim-virtual-chassis update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string
  master: int
  --tags: list<string>
]: any -> record<domain: string, id: int, master: record<display_name: string, id: int, name: string, url: string>, member_count: int, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/virtual-chassis/{id}/"))
  let req_body = {"domain": $domain, "master": $master, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /dcim/virtual-chassis/{id}/
#
# operationId: dcim_virtual-chassis_update
export def "dcim-virtual-chassis update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string
  master: int
  --tags: list<string>
]: any -> record<domain: string, id: int, master: record<display_name: string, id: int, name: string, url: string>, member_count: int, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/dcim/virtual-chassis/{id}/"))
  let req_body = {"domain": $domain, "master": $master, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# GET /extras/_custom_field_choices/
#
# operationId: extras__custom_field_choices_list
export def "extras-custom-field-choices list" [
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
  let full_url = (build-url $base "/extras/_custom_field_choices/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /extras/_custom_field_choices/{id}/
#
# operationId: extras__custom_field_choices_read
export def "extras-custom-field-choices get" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/_custom_field_choices/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /extras/config-contexts/
# operationId: extras_config-contexts_list
export def "extras-config-contexts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --is-active: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --role-id: string
  --role: string
  --platform-id: string
  --platform: string
  --cluster-group-id: string
  --cluster-group: string
  --cluster-id: string
  --tenant-group-id: string
  --tenant-group: string
  --tenant-id: string
  --tenant: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --role-id-n: string
  --role-n: string
  --platform-id-n: string
  --platform-n: string
  --cluster-group-id-n: string
  --cluster-group-n: string
  --cluster-id-n: string
  --tenant-group-id-n: string
  --tenant-group-n: string
  --tenant-id-n: string
  --tenant-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<cluster_groups: list, clusters: list, data: string, description: string, id: int, is_active: bool, name: string, platforms: list, regions: list, roles: list, sites: list, tags: list, tenant_groups: list, tenants: list, weight: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "is_active" $is_active "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "role_id" $role_id "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "platform_id" $platform_id "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "cluster_group_id" $cluster_group_id "scalar") (serialize-qp "cluster_group" $cluster_group "scalar") (serialize-qp "cluster_id" $cluster_id "scalar") (serialize-qp "tenant_group_id" $tenant_group_id "scalar") (serialize-qp "tenant_group" $tenant_group "scalar") (serialize-qp "tenant_id" $tenant_id "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "role_id__n" $role_id_n "scalar") (serialize-qp "role__n" $role_n "scalar") (serialize-qp "platform_id__n" $platform_id_n "scalar") (serialize-qp "platform__n" $platform_n "scalar") (serialize-qp "cluster_group_id__n" $cluster_group_id_n "scalar") (serialize-qp "cluster_group__n" $cluster_group_n "scalar") (serialize-qp "cluster_id__n" $cluster_id_n "scalar") (serialize-qp "tenant_group_id__n" $tenant_group_id_n "scalar") (serialize-qp "tenant_group__n" $tenant_group_n "scalar") (serialize-qp "tenant_id__n" $tenant_id_n "scalar") (serialize-qp "tenant__n" $tenant_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extras/config-contexts/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /extras/config-contexts/
#
# operationId: extras_config-contexts_create
export def "extras-config-contexts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-groups: list<int>
  --clusters: list<int>
  data: string
  --description: string
  --is-active: oneof<nothing, bool>
  name: string
  --platforms: list<int>
  --regions: list<int>
  --roles: list<int>
  --sites: list<int>
  --tags: list<string>
  --tenant-groups: list<int>
  --tenants: list<int>
  --weight: int
]: any -> record<cluster_groups: table<cluster_count: int, id: int, name: string, slug: string, url: string>, clusters: table<id: int, name: string, url: string, virtualmachine_count: int>, data: string, description: string, id: int, is_active: bool, name: string, platforms: table<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, regions: table<id: int, name: string, site_count: int, slug: string, url: string>, roles: table<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, sites: table<id: int, name: string, slug: string, url: string>, tags: list<string>, tenant_groups: table<id: int, name: string, slug: string, tenant_count: int, url: string>, tenants: table<id: int, name: string, slug: string, url: string>, weight: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/extras/config-contexts/")
  let req_body = {"cluster_groups": $cluster_groups, "clusters": $clusters, "data": $data, "description": $description, "is_active": $is_active, "name": $name, "platforms": $platforms, "regions": $regions, "roles": $roles, "sites": $sites, "tags": $tags, "tenant_groups": $tenant_groups, "tenants": $tenants, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /extras/config-contexts/{id}/
#
# operationId: extras_config-contexts_delete
export def "extras-config-contexts delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/config-contexts/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /extras/config-contexts/{id}/
# operationId: extras_config-contexts_read
export def "extras-config-contexts get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cluster_groups: table<cluster_count: int, id: int, name: string, slug: string, url: string>, clusters: table<id: int, name: string, url: string, virtualmachine_count: int>, data: string, description: string, id: int, is_active: bool, name: string, platforms: table<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, regions: table<id: int, name: string, site_count: int, slug: string, url: string>, roles: table<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, sites: table<id: int, name: string, slug: string, url: string>, tags: list<string>, tenant_groups: table<id: int, name: string, slug: string, tenant_count: int, url: string>, tenants: table<id: int, name: string, slug: string, url: string>, weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/config-contexts/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /extras/config-contexts/{id}/
#
# operationId: extras_config-contexts_partial_update
export def "extras-config-contexts update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-groups: list<int>
  --clusters: list<int>
  data: string
  --description: string
  --is-active: oneof<nothing, bool>
  name: string
  --platforms: list<int>
  --regions: list<int>
  --roles: list<int>
  --sites: list<int>
  --tags: list<string>
  --tenant-groups: list<int>
  --tenants: list<int>
  --weight: int
]: any -> record<cluster_groups: table<cluster_count: int, id: int, name: string, slug: string, url: string>, clusters: table<id: int, name: string, url: string, virtualmachine_count: int>, data: string, description: string, id: int, is_active: bool, name: string, platforms: table<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, regions: table<id: int, name: string, site_count: int, slug: string, url: string>, roles: table<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, sites: table<id: int, name: string, slug: string, url: string>, tags: list<string>, tenant_groups: table<id: int, name: string, slug: string, tenant_count: int, url: string>, tenants: table<id: int, name: string, slug: string, url: string>, weight: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/config-contexts/{id}/"))
  let req_body = {"cluster_groups": $cluster_groups, "clusters": $clusters, "data": $data, "description": $description, "is_active": $is_active, "name": $name, "platforms": $platforms, "regions": $regions, "roles": $roles, "sites": $sites, "tags": $tags, "tenant_groups": $tenant_groups, "tenants": $tenants, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /extras/config-contexts/{id}/
#
# operationId: extras_config-contexts_update
export def "extras-config-contexts update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-groups: list<int>
  --clusters: list<int>
  data: string
  --description: string
  --is-active: oneof<nothing, bool>
  name: string
  --platforms: list<int>
  --regions: list<int>
  --roles: list<int>
  --sites: list<int>
  --tags: list<string>
  --tenant-groups: list<int>
  --tenants: list<int>
  --weight: int
]: any -> record<cluster_groups: table<cluster_count: int, id: int, name: string, slug: string, url: string>, clusters: table<id: int, name: string, url: string, virtualmachine_count: int>, data: string, description: string, id: int, is_active: bool, name: string, platforms: table<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, regions: table<id: int, name: string, site_count: int, slug: string, url: string>, roles: table<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, sites: table<id: int, name: string, slug: string, url: string>, tags: list<string>, tenant_groups: table<id: int, name: string, slug: string, tenant_count: int, url: string>, tenants: table<id: int, name: string, slug: string, url: string>, weight: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/config-contexts/{id}/"))
  let req_body = {"cluster_groups": $cluster_groups, "clusters": $clusters, "data": $data, "description": $description, "is_active": $is_active, "name": $name, "platforms": $platforms, "regions": $regions, "roles": $roles, "sites": $sites, "tags": $tags, "tenant_groups": $tenant_groups, "tenants": $tenants, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /extras/export-templates/
# operationId: extras_export-templates_list
export def "extras-export-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --content-type: string
  --name: string
  --template-language: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --content-type-n: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --template-language-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<content_type: string, description: string, file_extension: string, id: int, mime_type: string, name: string, template_code: string, template_language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "content_type" $content_type "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "template_language" $template_language "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "content_type__n" $content_type_n "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "template_language__n" $template_language_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extras/export-templates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /extras/export-templates/
#
# operationId: extras_export-templates_create
export def "extras-export-templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  content_type: string
  --description: string
  --file-extension: string # Extension to append to the rendered filename
  --mime-type: string # Defaults to text/plain
  name: string
  template_code: string # The list of objects being exported is passed as a context variable named queryset.
  --template-language: string@template-language-completer
]: any -> record<content_type: string, description: string, file_extension: string, id: int, mime_type: string, name: string, template_code: string, template_language: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/extras/export-templates/")
  let req_body = {"content_type": $content_type, "description": $description, "file_extension": $file_extension, "mime_type": $mime_type, "name": $name, "template_code": $template_code, "template_language": $template_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /extras/export-templates/{id}/
#
# operationId: extras_export-templates_delete
export def "extras-export-templates delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/export-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /extras/export-templates/{id}/
# operationId: extras_export-templates_read
export def "extras-export-templates get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content_type: string, description: string, file_extension: string, id: int, mime_type: string, name: string, template_code: string, template_language: record<label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/export-templates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /extras/export-templates/{id}/
#
# operationId: extras_export-templates_partial_update
export def "extras-export-templates update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  content_type: string
  --description: string
  --file-extension: string # Extension to append to the rendered filename
  --mime-type: string # Defaults to text/plain
  name: string
  template_code: string # The list of objects being exported is passed as a context variable named queryset.
  --template-language: string@template-language-completer
]: any -> record<content_type: string, description: string, file_extension: string, id: int, mime_type: string, name: string, template_code: string, template_language: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/export-templates/{id}/"))
  let req_body = {"content_type": $content_type, "description": $description, "file_extension": $file_extension, "mime_type": $mime_type, "name": $name, "template_code": $template_code, "template_language": $template_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /extras/export-templates/{id}/
#
# operationId: extras_export-templates_update
export def "extras-export-templates update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  content_type: string
  --description: string
  --file-extension: string # Extension to append to the rendered filename
  --mime-type: string # Defaults to text/plain
  name: string
  template_code: string # The list of objects being exported is passed as a context variable named queryset.
  --template-language: string@template-language-completer
]: any -> record<content_type: string, description: string, file_extension: string, id: int, mime_type: string, name: string, template_code: string, template_language: record<label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/export-templates/{id}/"))
  let req_body = {"content_type": $content_type, "description": $description, "file_extension": $file_extension, "mime_type": $mime_type, "name": $name, "template_code": $template_code, "template_language": $template_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /extras/graphs/
# operationId: extras_graphs_list
export def "extras-graphs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --type: string
  --name: string
  --template-language: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --type-n: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --template-language-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, link: string, name: string, source: string, template_language: string, type: string, weight: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "template_language" $template_language "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "template_language__n" $template_language_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extras/graphs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /extras/graphs/
#
# operationId: extras_graphs_create
export def "extras-graphs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --link: string # format: uri
  name: string
  --body-source: string
  --template-language: string@template-language-completer
  type: string
  --weight: int
]: any -> record<id: int, link: string, name: string, source: string, template_language: string, type: string, weight: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/extras/graphs/")
  let req_body = {"link": $link, "name": $name, "source": $body_source, "template_language": $template_language, "type": $type, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /extras/graphs/{id}/
#
# operationId: extras_graphs_delete
export def "extras-graphs delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/graphs/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /extras/graphs/{id}/
# operationId: extras_graphs_read
export def "extras-graphs get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, link: string, name: string, source: string, template_language: string, type: string, weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/graphs/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /extras/graphs/{id}/
#
# operationId: extras_graphs_partial_update
export def "extras-graphs update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --link: string # format: uri
  name: string
  --body-source: string
  --template-language: string@template-language-completer
  type: string
  --weight: int
]: any -> record<id: int, link: string, name: string, source: string, template_language: string, type: string, weight: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/graphs/{id}/"))
  let req_body = {"link": $link, "name": $name, "source": $body_source, "template_language": $template_language, "type": $type, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /extras/graphs/{id}/
#
# operationId: extras_graphs_update
export def "extras-graphs update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --link: string # format: uri
  name: string
  --body-source: string
  --template-language: string@template-language-completer
  type: string
  --weight: int
]: any -> record<id: int, link: string, name: string, source: string, template_language: string, type: string, weight: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/graphs/{id}/"))
  let req_body = {"link": $link, "name": $name, "source": $body_source, "template_language": $template_language, "type": $type, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /extras/image-attachments/
# operationId: extras_image-attachments_list
export def "extras-image-attachments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<content_type: string, created: string, id: int, image: string, image_height: int, image_width: int, name: string, object_id: int, parent: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extras/image-attachments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /extras/image-attachments/
#
# operationId: extras_image-attachments_create
export def "extras-image-attachments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  content_type: string
  image_height: int
  image_width: int
  --name: string
  object_id: int
]: any -> record<content_type: string, created: string, id: int, image: string, image_height: int, image_width: int, name: string, object_id: int, parent: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/extras/image-attachments/")
  let req_body = {"content_type": $content_type, "image_height": $image_height, "image_width": $image_width, "name": $name, "object_id": $object_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /extras/image-attachments/{id}/
#
# operationId: extras_image-attachments_delete
export def "extras-image-attachments delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/image-attachments/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /extras/image-attachments/{id}/
# operationId: extras_image-attachments_read
export def "extras-image-attachments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content_type: string, created: string, id: int, image: string, image_height: int, image_width: int, name: string, object_id: int, parent: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/image-attachments/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /extras/image-attachments/{id}/
#
# operationId: extras_image-attachments_partial_update
export def "extras-image-attachments update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  content_type: string
  image_height: int
  image_width: int
  --name: string
  object_id: int
]: any -> record<content_type: string, created: string, id: int, image: string, image_height: int, image_width: int, name: string, object_id: int, parent: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/image-attachments/{id}/"))
  let req_body = {"content_type": $content_type, "image_height": $image_height, "image_width": $image_width, "name": $name, "object_id": $object_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /extras/image-attachments/{id}/
#
# operationId: extras_image-attachments_update
export def "extras-image-attachments update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  content_type: string
  image_height: int
  image_width: int
  --name: string
  object_id: int
]: any -> record<content_type: string, created: string, id: int, image: string, image_height: int, image_width: int, name: string, object_id: int, parent: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/image-attachments/{id}/"))
  let req_body = {"content_type": $content_type, "image_height": $image_height, "image_width": $image_width, "name": $name, "object_id": $object_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve a list of recent changes.
#
# GET /extras/object-changes/
# operationId: extras_object-changes_list
export def "extras-object-changes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --user: string
  --user-name: string
  --request-id: string
  --action: string
  --changed-object-type: string
  --changed-object-id: string
  --object-repr: string
  --q: string
  --time: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --user-n: string
  --user-name-n: string
  --user-name-ic: string
  --user-name-nic: string
  --user-name-iew: string
  --user-name-niew: string
  --user-name-isw: string
  --user-name-nisw: string
  --user-name-ie: string
  --user-name-nie: string
  --action-n: string
  --changed-object-type-n: string
  --changed-object-id-n: string
  --changed-object-id-lte: string
  --changed-object-id-lt: string
  --changed-object-id-gte: string
  --changed-object-id-gt: string
  --object-repr-n: string
  --object-repr-ic: string
  --object-repr-nic: string
  --object-repr-iew: string
  --object-repr-niew: string
  --object-repr-isw: string
  --object-repr-nisw: string
  --object-repr-ie: string
  --object-repr-nie: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<action: record, changed_object: record, changed_object_id: int, changed_object_type: string, id: int, object_data: string, request_id: string, time: string, user: record, user_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "user_name" $user_name "scalar") (serialize-qp "request_id" $request_id "scalar") (serialize-qp "action" $action "scalar") (serialize-qp "changed_object_type" $changed_object_type "scalar") (serialize-qp "changed_object_id" $changed_object_id "scalar") (serialize-qp "object_repr" $object_repr "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "time" $time "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "user__n" $user_n "scalar") (serialize-qp "user_name__n" $user_name_n "scalar") (serialize-qp "user_name__ic" $user_name_ic "scalar") (serialize-qp "user_name__nic" $user_name_nic "scalar") (serialize-qp "user_name__iew" $user_name_iew "scalar") (serialize-qp "user_name__niew" $user_name_niew "scalar") (serialize-qp "user_name__isw" $user_name_isw "scalar") (serialize-qp "user_name__nisw" $user_name_nisw "scalar") (serialize-qp "user_name__ie" $user_name_ie "scalar") (serialize-qp "user_name__nie" $user_name_nie "scalar") (serialize-qp "action__n" $action_n "scalar") (serialize-qp "changed_object_type__n" $changed_object_type_n "scalar") (serialize-qp "changed_object_id__n" $changed_object_id_n "scalar") (serialize-qp "changed_object_id__lte" $changed_object_id_lte "scalar") (serialize-qp "changed_object_id__lt" $changed_object_id_lt "scalar") (serialize-qp "changed_object_id__gte" $changed_object_id_gte "scalar") (serialize-qp "changed_object_id__gt" $changed_object_id_gt "scalar") (serialize-qp "object_repr__n" $object_repr_n "scalar") (serialize-qp "object_repr__ic" $object_repr_ic "scalar") (serialize-qp "object_repr__nic" $object_repr_nic "scalar") (serialize-qp "object_repr__iew" $object_repr_iew "scalar") (serialize-qp "object_repr__niew" $object_repr_niew "scalar") (serialize-qp "object_repr__isw" $object_repr_isw "scalar") (serialize-qp "object_repr__nisw" $object_repr_nisw "scalar") (serialize-qp "object_repr__ie" $object_repr_ie "scalar") (serialize-qp "object_repr__nie" $object_repr_nie "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extras/object-changes/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of recent changes.
#
# GET /extras/object-changes/{id}/
# operationId: extras_object-changes_read
export def "extras-object-changes get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: record<label: string, value: string>, changed_object: record, changed_object_id: int, changed_object_type: string, id: int, object_data: string, request_id: string, time: string, user: record<id: int, username: string>, user_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/object-changes/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compile all reports and their related results (if any). Result data is deferred in the list view.
#
# GET /extras/reports/
# operationId: extras_reports_list
export def "extras-reports list" [
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
  let full_url = (build-url $base "/extras/reports/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a single Report identified as ".".
#
# GET /extras/reports/{id}/
# operationId: extras_reports_read
export def "extras-reports get" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/reports/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run a Report and create a new ReportResult, overwriting any previous result for the Report.
#
# POST /extras/reports/{id}/run/
# operationId: extras_reports_run
export def "extras-reports-run create" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/reports/{id}/run/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /extras/scripts/
#
# operationId: extras_scripts_list
export def "extras-scripts list" [
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
  let full_url = (build-url $base "/extras/scripts/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /extras/scripts/{id}/
#
# operationId: extras_scripts_read
export def "extras-scripts get" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/scripts/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /extras/tags/
# operationId: extras_tags_list
export def "extras-tags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --color: string
  --q: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --color-n: string
  --color-ic: string
  --color-nic: string
  --color-iew: string
  --color-niew: string
  --color-isw: string
  --color-nisw: string
  --color-ie: string
  --color-nie: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<color: string, description: string, id: int, name: string, slug: string, tagged_items: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "color" $color "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "color__n" $color_n "scalar") (serialize-qp "color__ic" $color_ic "scalar") (serialize-qp "color__nic" $color_nic "scalar") (serialize-qp "color__iew" $color_iew "scalar") (serialize-qp "color__niew" $color_niew "scalar") (serialize-qp "color__isw" $color_isw "scalar") (serialize-qp "color__nisw" $color_nisw "scalar") (serialize-qp "color__ie" $color_ie "scalar") (serialize-qp "color__nie" $color_nie "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extras/tags/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /extras/tags/
#
# operationId: extras_tags_create
export def "extras-tags create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: string
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<color: string, description: string, id: int, name: string, slug: string, tagged_items: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/extras/tags/")
  let req_body = {"color": $color, "description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /extras/tags/{id}/
#
# operationId: extras_tags_delete
export def "extras-tags delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/tags/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /extras/tags/{id}/
# operationId: extras_tags_read
export def "extras-tags get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<color: string, description: string, id: int, name: string, slug: string, tagged_items: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/tags/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /extras/tags/{id}/
#
# operationId: extras_tags_partial_update
export def "extras-tags update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: string
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<color: string, description: string, id: int, name: string, slug: string, tagged_items: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/tags/{id}/"))
  let req_body = {"color": $color, "description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /extras/tags/{id}/
#
# operationId: extras_tags_update
export def "extras-tags update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --color: string
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<color: string, description: string, id: int, name: string, slug: string, tagged_items: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/extras/tags/{id}/"))
  let req_body = {"color": $color, "description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /ipam/aggregates/
# operationId: ipam_aggregates_list
export def "ipam-aggregates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --date-added: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --family: float
  --prefix: string
  --rir-id: string
  --rir: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --date-added-n: string
  --date-added-lte: string
  --date-added-lt: string
  --date-added-gte: string
  --date-added-gt: string
  --rir-id-n: string
  --rir-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<created: string, custom_fields: record, date_added: string, description: string, family: record, id: int, last_updated: string, prefix: string, rir: record, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "date_added" $date_added "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "family" $family "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "rir_id" $rir_id "scalar") (serialize-qp "rir" $rir "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "date_added__n" $date_added_n "scalar") (serialize-qp "date_added__lte" $date_added_lte "scalar") (serialize-qp "date_added__lt" $date_added_lt "scalar") (serialize-qp "date_added__gte" $date_added_gte "scalar") (serialize-qp "date_added__gt" $date_added_gt "scalar") (serialize-qp "rir_id__n" $rir_id_n "scalar") (serialize-qp "rir__n" $rir_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ipam/aggregates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /ipam/aggregates/
#
# operationId: ipam_aggregates_create
export def "ipam-aggregates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --date-added: string # nullable, format: date
  --description: string
  prefix: string
  rir: int
  --tags: list<string>
]: any -> record<created: string, custom_fields: record, date_added: string, description: string, family: record<label: string, value: int>, id: int, last_updated: string, prefix: string, rir: record<aggregate_count: int, id: int, name: string, slug: string, url: string>, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ipam/aggregates/")
  let req_body = {"custom_fields": $custom_fields, "date_added": $date_added, "description": $description, "prefix": $prefix, "rir": $rir, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /ipam/aggregates/{id}/
#
# operationId: ipam_aggregates_delete
export def "ipam-aggregates delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/aggregates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /ipam/aggregates/{id}/
# operationId: ipam_aggregates_read
export def "ipam-aggregates get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, custom_fields: record, date_added: string, description: string, family: record<label: string, value: int>, id: int, last_updated: string, prefix: string, rir: record<aggregate_count: int, id: int, name: string, slug: string, url: string>, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/aggregates/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /ipam/aggregates/{id}/
#
# operationId: ipam_aggregates_partial_update
export def "ipam-aggregates update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --date-added: string # nullable, format: date
  --description: string
  prefix: string
  rir: int
  --tags: list<string>
]: any -> record<created: string, custom_fields: record, date_added: string, description: string, family: record<label: string, value: int>, id: int, last_updated: string, prefix: string, rir: record<aggregate_count: int, id: int, name: string, slug: string, url: string>, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/aggregates/{id}/"))
  let req_body = {"custom_fields": $custom_fields, "date_added": $date_added, "description": $description, "prefix": $prefix, "rir": $rir, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /ipam/aggregates/{id}/
#
# operationId: ipam_aggregates_update
export def "ipam-aggregates update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --date-added: string # nullable, format: date
  --description: string
  prefix: string
  rir: int
  --tags: list<string>
]: any -> record<created: string, custom_fields: record, date_added: string, description: string, family: record<label: string, value: int>, id: int, last_updated: string, prefix: string, rir: record<aggregate_count: int, id: int, name: string, slug: string, url: string>, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/aggregates/{id}/"))
  let req_body = {"custom_fields": $custom_fields, "date_added": $date_added, "description": $description, "prefix": $prefix, "rir": $rir, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /ipam/ip-addresses/
# operationId: ipam_ip-addresses_list
export def "ipam-ip-addresses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --dns-name: string
  --tenant-group-id: string
  --tenant-group: string
  --tenant-id: string
  --tenant: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --family: float
  --parent: string
  --address: string
  --mask-length: float
  --vrf-id: string
  --vrf: string
  --device: string
  --device-id: string
  --virtual-machine-id: string
  --virtual-machine: string
  --interface: string
  --interface-id: string
  --assigned-to-interface: string
  --status: string
  --role: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --dns-name-n: string
  --dns-name-ic: string
  --dns-name-nic: string
  --dns-name-iew: string
  --dns-name-niew: string
  --dns-name-isw: string
  --dns-name-nisw: string
  --dns-name-ie: string
  --dns-name-nie: string
  --tenant-group-id-n: string
  --tenant-group-n: string
  --tenant-id-n: string
  --tenant-n: string
  --vrf-id-n: string
  --vrf-n: string
  --virtual-machine-id-n: string
  --virtual-machine-n: string
  --interface-n: string
  --interface-id-n: string
  --status-n: string
  --role-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<address: string, created: string, custom_fields: record, description: string, dns_name: string, family: record, id: int, interface: record, last_updated: string, nat_inside: record, nat_outside: record, role: record, status: record, tags: list, tenant: record, vrf: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "dns_name" $dns_name "scalar") (serialize-qp "tenant_group_id" $tenant_group_id "scalar") (serialize-qp "tenant_group" $tenant_group "scalar") (serialize-qp "tenant_id" $tenant_id "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "family" $family "scalar") (serialize-qp "parent" $parent "scalar") (serialize-qp "address" $address "scalar") (serialize-qp "mask_length" $mask_length "scalar") (serialize-qp "vrf_id" $vrf_id "scalar") (serialize-qp "vrf" $vrf "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "virtual_machine_id" $virtual_machine_id "scalar") (serialize-qp "virtual_machine" $virtual_machine "scalar") (serialize-qp "interface" $interface "scalar") (serialize-qp "interface_id" $interface_id "scalar") (serialize-qp "assigned_to_interface" $assigned_to_interface "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "dns_name__n" $dns_name_n "scalar") (serialize-qp "dns_name__ic" $dns_name_ic "scalar") (serialize-qp "dns_name__nic" $dns_name_nic "scalar") (serialize-qp "dns_name__iew" $dns_name_iew "scalar") (serialize-qp "dns_name__niew" $dns_name_niew "scalar") (serialize-qp "dns_name__isw" $dns_name_isw "scalar") (serialize-qp "dns_name__nisw" $dns_name_nisw "scalar") (serialize-qp "dns_name__ie" $dns_name_ie "scalar") (serialize-qp "dns_name__nie" $dns_name_nie "scalar") (serialize-qp "tenant_group_id__n" $tenant_group_id_n "scalar") (serialize-qp "tenant_group__n" $tenant_group_n "scalar") (serialize-qp "tenant_id__n" $tenant_id_n "scalar") (serialize-qp "tenant__n" $tenant_n "scalar") (serialize-qp "vrf_id__n" $vrf_id_n "scalar") (serialize-qp "vrf__n" $vrf_n "scalar") (serialize-qp "virtual_machine_id__n" $virtual_machine_id_n "scalar") (serialize-qp "virtual_machine__n" $virtual_machine_n "scalar") (serialize-qp "interface__n" $interface_n "scalar") (serialize-qp "interface_id__n" $interface_id_n "scalar") (serialize-qp "status__n" $status_n "scalar") (serialize-qp "role__n" $role_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ipam/ip-addresses/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /ipam/ip-addresses/
#
# operationId: ipam_ip-addresses_create
export def "ipam-ip-addresses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # IPv4 or IPv6 address (with mask)
  --custom-fields: record # default: {}
  --description: string
  --dns-name: string # Hostname or FQDN (not case-sensitive)
  --interface: int # nullable
  --nat-inside: int # The IP for which this address is the "outside" IP (nullable)
  nat_outside: int
  --role: string@role-completer # The functional role of this IP
  --status: string@status-completer-6 # The operational status of this IP
  --tags: list<string>
  --tenant: int # nullable
  --vrf: int # nullable
]: any -> record<address: string, created: string, custom_fields: record, description: string, dns_name: string, family: record<label: string, value: int>, id: int, interface: record<device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, url: string, virtual_machine: record<id: int, name: string, url: string>>, last_updated: string, nat_inside: record<address: string, family: string, id: int, url: string>, nat_outside: record<address: string, family: string, id: int, url: string>, role: record<label: string, value: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vrf: record<id: int, name: string, prefix_count: int, rd: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ipam/ip-addresses/")
  let req_body = {"address": $address, "custom_fields": $custom_fields, "description": $description, "dns_name": $dns_name, "interface": $interface, "nat_inside": $nat_inside, "nat_outside": $nat_outside, "role": $role, "status": $status, "tags": $tags, "tenant": $tenant, "vrf": $vrf} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /ipam/ip-addresses/{id}/
#
# operationId: ipam_ip-addresses_delete
export def "ipam-ip-addresses delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/ip-addresses/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /ipam/ip-addresses/{id}/
# operationId: ipam_ip-addresses_read
export def "ipam-ip-addresses get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: string, created: string, custom_fields: record, description: string, dns_name: string, family: record<label: string, value: int>, id: int, interface: record<device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, url: string, virtual_machine: record<id: int, name: string, url: string>>, last_updated: string, nat_inside: record<address: string, family: string, id: int, url: string>, nat_outside: record<address: string, family: string, id: int, url: string>, role: record<label: string, value: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vrf: record<id: int, name: string, prefix_count: int, rd: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/ip-addresses/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /ipam/ip-addresses/{id}/
#
# operationId: ipam_ip-addresses_partial_update
export def "ipam-ip-addresses update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # IPv4 or IPv6 address (with mask)
  --custom-fields: record # default: {}
  --description: string
  --dns-name: string # Hostname or FQDN (not case-sensitive)
  --interface: int # nullable
  --nat-inside: int # The IP for which this address is the "outside" IP (nullable)
  nat_outside: int
  --role: string@role-completer # The functional role of this IP
  --status: string@status-completer-6 # The operational status of this IP
  --tags: list<string>
  --tenant: int # nullable
  --vrf: int # nullable
]: any -> record<address: string, created: string, custom_fields: record, description: string, dns_name: string, family: record<label: string, value: int>, id: int, interface: record<device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, url: string, virtual_machine: record<id: int, name: string, url: string>>, last_updated: string, nat_inside: record<address: string, family: string, id: int, url: string>, nat_outside: record<address: string, family: string, id: int, url: string>, role: record<label: string, value: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vrf: record<id: int, name: string, prefix_count: int, rd: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/ip-addresses/{id}/"))
  let req_body = {"address": $address, "custom_fields": $custom_fields, "description": $description, "dns_name": $dns_name, "interface": $interface, "nat_inside": $nat_inside, "nat_outside": $nat_outside, "role": $role, "status": $status, "tags": $tags, "tenant": $tenant, "vrf": $vrf} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /ipam/ip-addresses/{id}/
#
# operationId: ipam_ip-addresses_update
export def "ipam-ip-addresses update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # IPv4 or IPv6 address (with mask)
  --custom-fields: record # default: {}
  --description: string
  --dns-name: string # Hostname or FQDN (not case-sensitive)
  --interface: int # nullable
  --nat-inside: int # The IP for which this address is the "outside" IP (nullable)
  nat_outside: int
  --role: string@role-completer # The functional role of this IP
  --status: string@status-completer-6 # The operational status of this IP
  --tags: list<string>
  --tenant: int # nullable
  --vrf: int # nullable
]: any -> record<address: string, created: string, custom_fields: record, description: string, dns_name: string, family: record<label: string, value: int>, id: int, interface: record<device: record<display_name: string, id: int, name: string, url: string>, id: int, name: string, url: string, virtual_machine: record<id: int, name: string, url: string>>, last_updated: string, nat_inside: record<address: string, family: string, id: int, url: string>, nat_outside: record<address: string, family: string, id: int, url: string>, role: record<label: string, value: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vrf: record<id: int, name: string, prefix_count: int, rd: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/ip-addresses/{id}/"))
  let req_body = {"address": $address, "custom_fields": $custom_fields, "description": $description, "dns_name": $dns_name, "interface": $interface, "nat_inside": $nat_inside, "nat_outside": $nat_outside, "role": $role, "status": $status, "tags": $tags, "tenant": $tenant, "vrf": $vrf} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /ipam/prefixes/
# operationId: ipam_prefixes_list
export def "ipam-prefixes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --is-pool: string
  --tenant-group-id: string
  --tenant-group: string
  --tenant-id: string
  --tenant: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --family: float
  --prefix: string
  --within: string
  --within-include: string
  --contains: string
  --mask-length: float
  --vrf-id: string
  --vrf: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --vlan-id: string
  --vlan-vid: float
  --role-id: string
  --role: string
  --status: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --tenant-group-id-n: string
  --tenant-group-n: string
  --tenant-id-n: string
  --tenant-n: string
  --vrf-id-n: string
  --vrf-n: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --vlan-id-n: string
  --role-id-n: string
  --role-n: string
  --status-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<created: string, custom_fields: record, description: string, family: record, id: int, is_pool: bool, last_updated: string, prefix: string, role: record, site: record, status: record, tags: list, tenant: record, vlan: record, vrf: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "is_pool" $is_pool "scalar") (serialize-qp "tenant_group_id" $tenant_group_id "scalar") (serialize-qp "tenant_group" $tenant_group "scalar") (serialize-qp "tenant_id" $tenant_id "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "family" $family "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "within" $within "scalar") (serialize-qp "within_include" $within_include "scalar") (serialize-qp "contains" $contains "scalar") (serialize-qp "mask_length" $mask_length "scalar") (serialize-qp "vrf_id" $vrf_id "scalar") (serialize-qp "vrf" $vrf "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "vlan_id" $vlan_id "scalar") (serialize-qp "vlan_vid" $vlan_vid "scalar") (serialize-qp "role_id" $role_id "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "tenant_group_id__n" $tenant_group_id_n "scalar") (serialize-qp "tenant_group__n" $tenant_group_n "scalar") (serialize-qp "tenant_id__n" $tenant_id_n "scalar") (serialize-qp "tenant__n" $tenant_n "scalar") (serialize-qp "vrf_id__n" $vrf_id_n "scalar") (serialize-qp "vrf__n" $vrf_n "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "vlan_id__n" $vlan_id_n "scalar") (serialize-qp "role_id__n" $role_id_n "scalar") (serialize-qp "role__n" $role_n "scalar") (serialize-qp "status__n" $status_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ipam/prefixes/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /ipam/prefixes/
#
# operationId: ipam_prefixes_create
export def "ipam-prefixes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --description: string
  --is-pool: oneof<nothing, bool> # All IP addresses within this prefix are considered usable
  prefix: string # IPv4 or IPv6 network with mask
  --role: int # The primary function of this prefix (nullable)
  --site: int # nullable
  --status: string@status-completer-7 # Operational status of this prefix
  --tags: list<string>
  --tenant: int # nullable
  --vlan: int # nullable
  --vrf: int # nullable
]: any -> record<created: string, custom_fields: record, description: string, family: record<label: string, value: int>, id: int, is_pool: bool, last_updated: string, prefix: string, role: record<id: int, name: string, prefix_count: int, slug: string, url: string, vlan_count: int>, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vlan: record<display_name: string, id: int, name: string, url: string, vid: int>, vrf: record<id: int, name: string, prefix_count: int, rd: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ipam/prefixes/")
  let req_body = {"custom_fields": $custom_fields, "description": $description, "is_pool": $is_pool, "prefix": $prefix, "role": $role, "site": $site, "status": $status, "tags": $tags, "tenant": $tenant, "vlan": $vlan, "vrf": $vrf} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /ipam/prefixes/{id}/
#
# operationId: ipam_prefixes_delete
export def "ipam-prefixes delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/prefixes/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /ipam/prefixes/{id}/
# operationId: ipam_prefixes_read
export def "ipam-prefixes get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, custom_fields: record, description: string, family: record<label: string, value: int>, id: int, is_pool: bool, last_updated: string, prefix: string, role: record<id: int, name: string, prefix_count: int, slug: string, url: string, vlan_count: int>, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vlan: record<display_name: string, id: int, name: string, url: string, vid: int>, vrf: record<id: int, name: string, prefix_count: int, rd: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/prefixes/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /ipam/prefixes/{id}/
#
# operationId: ipam_prefixes_partial_update
export def "ipam-prefixes update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --description: string
  --is-pool: oneof<nothing, bool> # All IP addresses within this prefix are considered usable
  prefix: string # IPv4 or IPv6 network with mask
  --role: int # The primary function of this prefix (nullable)
  --site: int # nullable
  --status: string@status-completer-7 # Operational status of this prefix
  --tags: list<string>
  --tenant: int # nullable
  --vlan: int # nullable
  --vrf: int # nullable
]: any -> record<created: string, custom_fields: record, description: string, family: record<label: string, value: int>, id: int, is_pool: bool, last_updated: string, prefix: string, role: record<id: int, name: string, prefix_count: int, slug: string, url: string, vlan_count: int>, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vlan: record<display_name: string, id: int, name: string, url: string, vid: int>, vrf: record<id: int, name: string, prefix_count: int, rd: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/prefixes/{id}/"))
  let req_body = {"custom_fields": $custom_fields, "description": $description, "is_pool": $is_pool, "prefix": $prefix, "role": $role, "site": $site, "status": $status, "tags": $tags, "tenant": $tenant, "vlan": $vlan, "vrf": $vrf} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /ipam/prefixes/{id}/
#
# operationId: ipam_prefixes_update
export def "ipam-prefixes update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --description: string
  --is-pool: oneof<nothing, bool> # All IP addresses within this prefix are considered usable
  prefix: string # IPv4 or IPv6 network with mask
  --role: int # The primary function of this prefix (nullable)
  --site: int # nullable
  --status: string@status-completer-7 # Operational status of this prefix
  --tags: list<string>
  --tenant: int # nullable
  --vlan: int # nullable
  --vrf: int # nullable
]: any -> record<created: string, custom_fields: record, description: string, family: record<label: string, value: int>, id: int, is_pool: bool, last_updated: string, prefix: string, role: record<id: int, name: string, prefix_count: int, slug: string, url: string, vlan_count: int>, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vlan: record<display_name: string, id: int, name: string, url: string, vid: int>, vrf: record<id: int, name: string, prefix_count: int, rd: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/prefixes/{id}/"))
  let req_body = {"custom_fields": $custom_fields, "description": $description, "is_pool": $is_pool, "prefix": $prefix, "role": $role, "site": $site, "status": $status, "tags": $tags, "tenant": $tenant, "vlan": $vlan, "vrf": $vrf} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# A convenience method for returning available IP addresses within a prefix. By default, the number of IPs returned will be equivalent to PAGINATE_COUNT. An arbitrary limit (up to MAX_PAGE_SIZE, if set) may be passed, however results will not be paginated. The advisory lock decorator uses a PostgreSQL advisory lock to prevent this API from being invoked in parallel, which results in a race condition where multiple insertions can occur.
#
# GET /ipam/prefixes/{id}/available-ips/
# operationId: ipam_prefixes_available-ips_read
export def "ipam-prefixes-available-ips get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<address: string, family: int, vrf: record<id: int, name: string, prefix_count: int, rd: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/prefixes/{id}/available-ips/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A convenience method for returning available IP addresses within a prefix. By default, the number of IPs returned will be equivalent to PAGINATE_COUNT. An arbitrary limit (up to MAX_PAGE_SIZE, if set) may be passed, however results will not be paginated. The advisory lock decorator uses a PostgreSQL advisory lock to prevent this API from being invoked in parallel, which results in a race condition where multiple insertions can occur.
#
# POST /ipam/prefixes/{id}/available-ips/
# operationId: ipam_prefixes_available-ips_create
export def "ipam-prefixes-available-ips create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<address: string, family: int, vrf: record<id: int, name: string, prefix_count: int, rd: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/prefixes/{id}/available-ips/"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# A convenience method for returning available child prefixes within a parent.
#
# GET /ipam/prefixes/{id}/available-prefixes/
# operationId: ipam_prefixes_available-prefixes_read
export def "ipam-prefixes-available-prefixes get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<family: int, prefix: string, vrf: record<id: int, name: string, prefix_count: int, rd: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/prefixes/{id}/available-prefixes/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A convenience method for returning available child prefixes within a parent.
#
# POST /ipam/prefixes/{id}/available-prefixes/
# operationId: ipam_prefixes_available-prefixes_create
export def "ipam-prefixes-available-prefixes create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --description: string
  --is-pool: oneof<nothing, bool> # All IP addresses within this prefix are considered usable
  prefix: string # IPv4 or IPv6 network with mask
  --role: int # The primary function of this prefix (nullable)
  --site: int # nullable
  --status: string@status-completer-7 # Operational status of this prefix
  --tags: list<string>
  --tenant: int # nullable
  --vlan: int # nullable
  --vrf: int # nullable
]: any -> table<family: int, prefix: string, vrf: record<id: int, name: string, prefix_count: int, rd: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/prefixes/{id}/available-prefixes/"))
  let req_body = {"custom_fields": $custom_fields, "description": $description, "is_pool": $is_pool, "prefix": $prefix, "role": $role, "site": $site, "status": $status, "tags": $tags, "tenant": $tenant, "vlan": $vlan, "vrf": $vrf} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /ipam/rirs/
# operationId: ipam_rirs_list
export def "ipam-rirs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --is-private: string
  --description: string
  --q: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<aggregate_count: int, description: string, id: int, is_private: bool, name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "is_private" $is_private "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ipam/rirs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /ipam/rirs/
#
# operationId: ipam_rirs_create
export def "ipam-rirs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --is-private: oneof<nothing, bool> # IP space managed by this RIR is considered private
  name: string
  slug: string # format: slug
]: any -> record<aggregate_count: int, description: string, id: int, is_private: bool, name: string, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ipam/rirs/")
  let req_body = {"description": $description, "is_private": $is_private, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /ipam/rirs/{id}/
#
# operationId: ipam_rirs_delete
export def "ipam-rirs delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/rirs/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /ipam/rirs/{id}/
# operationId: ipam_rirs_read
export def "ipam-rirs get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<aggregate_count: int, description: string, id: int, is_private: bool, name: string, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/rirs/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /ipam/rirs/{id}/
#
# operationId: ipam_rirs_partial_update
export def "ipam-rirs update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --is-private: oneof<nothing, bool> # IP space managed by this RIR is considered private
  name: string
  slug: string # format: slug
]: any -> record<aggregate_count: int, description: string, id: int, is_private: bool, name: string, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/rirs/{id}/"))
  let req_body = {"description": $description, "is_private": $is_private, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /ipam/rirs/{id}/
#
# operationId: ipam_rirs_update
export def "ipam-rirs update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --is-private: oneof<nothing, bool> # IP space managed by this RIR is considered private
  name: string
  slug: string # format: slug
]: any -> record<aggregate_count: int, description: string, id: int, is_private: bool, name: string, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/rirs/{id}/"))
  let req_body = {"description": $description, "is_private": $is_private, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /ipam/roles/
# operationId: ipam_roles_list
export def "ipam-roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --q: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<description: string, id: int, name: string, prefix_count: int, slug: string, vlan_count: int, weight: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ipam/roles/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /ipam/roles/
#
# operationId: ipam_roles_create
export def "ipam-roles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
  --weight: int
]: any -> record<description: string, id: int, name: string, prefix_count: int, slug: string, vlan_count: int, weight: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ipam/roles/")
  let req_body = {"description": $description, "name": $name, "slug": $slug, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /ipam/roles/{id}/
#
# operationId: ipam_roles_delete
export def "ipam-roles delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/roles/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /ipam/roles/{id}/
# operationId: ipam_roles_read
export def "ipam-roles get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: int, name: string, prefix_count: int, slug: string, vlan_count: int, weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/roles/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /ipam/roles/{id}/
#
# operationId: ipam_roles_partial_update
export def "ipam-roles update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
  --weight: int
]: any -> record<description: string, id: int, name: string, prefix_count: int, slug: string, vlan_count: int, weight: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/roles/{id}/"))
  let req_body = {"description": $description, "name": $name, "slug": $slug, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /ipam/roles/{id}/
#
# operationId: ipam_roles_update
export def "ipam-roles update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
  --weight: int
]: any -> record<description: string, id: int, name: string, prefix_count: int, slug: string, vlan_count: int, weight: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/roles/{id}/"))
  let req_body = {"description": $description, "name": $name, "slug": $slug, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /ipam/services/
# operationId: ipam_services_list
export def "ipam-services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --protocol: string
  --port: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --device-id: string
  --device: string
  --virtual-machine-id: string
  --virtual-machine: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --protocol-n: string
  --port-n: string
  --port-lte: string
  --port-lt: string
  --port-gte: string
  --port-gt: string
  --device-id-n: string
  --device-n: string
  --virtual-machine-id-n: string
  --virtual-machine-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<created: string, custom_fields: record, description: string, device: record, id: int, ipaddresses: list, last_updated: string, name: string, port: int, protocol: record, tags: list, virtual_machine: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "protocol" $protocol "scalar") (serialize-qp "port" $port "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "virtual_machine_id" $virtual_machine_id "scalar") (serialize-qp "virtual_machine" $virtual_machine "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "protocol__n" $protocol_n "scalar") (serialize-qp "port__n" $port_n "scalar") (serialize-qp "port__lte" $port_lte "scalar") (serialize-qp "port__lt" $port_lt "scalar") (serialize-qp "port__gte" $port_gte "scalar") (serialize-qp "port__gt" $port_gt "scalar") (serialize-qp "device_id__n" $device_id_n "scalar") (serialize-qp "device__n" $device_n "scalar") (serialize-qp "virtual_machine_id__n" $virtual_machine_id_n "scalar") (serialize-qp "virtual_machine__n" $virtual_machine_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ipam/services/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /ipam/services/
#
# operationId: ipam_services_create
export def "ipam-services create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --description: string
  --device: int # nullable
  --ipaddresses: list<int>
  name: string
  port: int
  protocol: string@protocol-completer
  --tags: list<string>
  --virtual-machine: int # nullable
]: any -> record<created: string, custom_fields: record, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, ipaddresses: table<address: string, family: string, id: int, url: string>, last_updated: string, name: string, port: int, protocol: record<label: string, value: string>, tags: list<string>, virtual_machine: record<id: int, name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ipam/services/")
  let req_body = {"custom_fields": $custom_fields, "description": $description, "device": $device, "ipaddresses": $ipaddresses, "name": $name, "port": $port, "protocol": $protocol, "tags": $tags, "virtual_machine": $virtual_machine} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /ipam/services/{id}/
#
# operationId: ipam_services_delete
export def "ipam-services delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/services/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /ipam/services/{id}/
# operationId: ipam_services_read
export def "ipam-services get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, custom_fields: record, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, ipaddresses: table<address: string, family: string, id: int, url: string>, last_updated: string, name: string, port: int, protocol: record<label: string, value: string>, tags: list<string>, virtual_machine: record<id: int, name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/services/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /ipam/services/{id}/
#
# operationId: ipam_services_partial_update
export def "ipam-services update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --description: string
  --device: int # nullable
  --ipaddresses: list<int>
  name: string
  port: int
  protocol: string@protocol-completer
  --tags: list<string>
  --virtual-machine: int # nullable
]: any -> record<created: string, custom_fields: record, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, ipaddresses: table<address: string, family: string, id: int, url: string>, last_updated: string, name: string, port: int, protocol: record<label: string, value: string>, tags: list<string>, virtual_machine: record<id: int, name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/services/{id}/"))
  let req_body = {"custom_fields": $custom_fields, "description": $description, "device": $device, "ipaddresses": $ipaddresses, "name": $name, "port": $port, "protocol": $protocol, "tags": $tags, "virtual_machine": $virtual_machine} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /ipam/services/{id}/
#
# operationId: ipam_services_update
export def "ipam-services update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --description: string
  --device: int # nullable
  --ipaddresses: list<int>
  name: string
  port: int
  protocol: string@protocol-completer
  --tags: list<string>
  --virtual-machine: int # nullable
]: any -> record<created: string, custom_fields: record, description: string, device: record<display_name: string, id: int, name: string, url: string>, id: int, ipaddresses: table<address: string, family: string, id: int, url: string>, last_updated: string, name: string, port: int, protocol: record<label: string, value: string>, tags: list<string>, virtual_machine: record<id: int, name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/services/{id}/"))
  let req_body = {"custom_fields": $custom_fields, "description": $description, "device": $device, "ipaddresses": $ipaddresses, "name": $name, "port": $port, "protocol": $protocol, "tags": $tags, "virtual_machine": $virtual_machine} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /ipam/vlan-groups/
# operationId: ipam_vlan-groups_list
export def "ipam-vlan-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --description: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<description: string, id: int, name: string, site: record, slug: string, vlan_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ipam/vlan-groups/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /ipam/vlan-groups/
#
# operationId: ipam_vlan-groups_create
export def "ipam-vlan-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  --site: int # nullable
  slug: string # format: slug
]: any -> record<description: string, id: int, name: string, site: record<id: int, name: string, slug: string, url: string>, slug: string, vlan_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ipam/vlan-groups/")
  let req_body = {"description": $description, "name": $name, "site": $site, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /ipam/vlan-groups/{id}/
#
# operationId: ipam_vlan-groups_delete
export def "ipam-vlan-groups delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/vlan-groups/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /ipam/vlan-groups/{id}/
# operationId: ipam_vlan-groups_read
export def "ipam-vlan-groups get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: int, name: string, site: record<id: int, name: string, slug: string, url: string>, slug: string, vlan_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/vlan-groups/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /ipam/vlan-groups/{id}/
#
# operationId: ipam_vlan-groups_partial_update
export def "ipam-vlan-groups update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  --site: int # nullable
  slug: string # format: slug
]: any -> record<description: string, id: int, name: string, site: record<id: int, name: string, slug: string, url: string>, slug: string, vlan_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/vlan-groups/{id}/"))
  let req_body = {"description": $description, "name": $name, "site": $site, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /ipam/vlan-groups/{id}/
#
# operationId: ipam_vlan-groups_update
export def "ipam-vlan-groups update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  --site: int # nullable
  slug: string # format: slug
]: any -> record<description: string, id: int, name: string, site: record<id: int, name: string, slug: string, url: string>, slug: string, vlan_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/vlan-groups/{id}/"))
  let req_body = {"description": $description, "name": $name, "site": $site, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /ipam/vlans/
# operationId: ipam_vlans_list
export def "ipam-vlans list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --vid: string
  --name: string
  --tenant-group-id: string
  --tenant-group: string
  --tenant-id: string
  --tenant: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --group-id: string
  --group: string
  --role-id: string
  --role: string
  --status: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --vid-n: string
  --vid-lte: string
  --vid-lt: string
  --vid-gte: string
  --vid-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --tenant-group-id-n: string
  --tenant-group-n: string
  --tenant-id-n: string
  --tenant-n: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --group-id-n: string
  --group-n: string
  --role-id-n: string
  --role-n: string
  --status-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<created: string, custom_fields: record, description: string, display_name: string, group: record, id: int, last_updated: string, name: string, prefix_count: int, role: record, site: record, status: record, tags: list, tenant: record, vid: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "vid" $vid "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "tenant_group_id" $tenant_group_id "scalar") (serialize-qp "tenant_group" $tenant_group "scalar") (serialize-qp "tenant_id" $tenant_id "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "role_id" $role_id "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "vid__n" $vid_n "scalar") (serialize-qp "vid__lte" $vid_lte "scalar") (serialize-qp "vid__lt" $vid_lt "scalar") (serialize-qp "vid__gte" $vid_gte "scalar") (serialize-qp "vid__gt" $vid_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "tenant_group_id__n" $tenant_group_id_n "scalar") (serialize-qp "tenant_group__n" $tenant_group_n "scalar") (serialize-qp "tenant_id__n" $tenant_id_n "scalar") (serialize-qp "tenant__n" $tenant_n "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "group_id__n" $group_id_n "scalar") (serialize-qp "group__n" $group_n "scalar") (serialize-qp "role_id__n" $role_id_n "scalar") (serialize-qp "role__n" $role_n "scalar") (serialize-qp "status__n" $status_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ipam/vlans/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /ipam/vlans/
#
# operationId: ipam_vlans_create
export def "ipam-vlans create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --description: string
  --group: int # nullable
  name: string
  --role: int # nullable
  --site: int # nullable
  --status: string@status-completer-8
  --tags: list<string>
  --tenant: int # nullable
  vid: int
]: any -> record<created: string, custom_fields: record, description: string, display_name: string, group: record<id: int, name: string, slug: string, url: string, vlan_count: int>, id: int, last_updated: string, name: string, prefix_count: int, role: record<id: int, name: string, prefix_count: int, slug: string, url: string, vlan_count: int>, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ipam/vlans/")
  let req_body = {"custom_fields": $custom_fields, "description": $description, "group": $group, "name": $name, "role": $role, "site": $site, "status": $status, "tags": $tags, "tenant": $tenant, "vid": $vid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /ipam/vlans/{id}/
#
# operationId: ipam_vlans_delete
export def "ipam-vlans delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/vlans/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /ipam/vlans/{id}/
# operationId: ipam_vlans_read
export def "ipam-vlans get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, custom_fields: record, description: string, display_name: string, group: record<id: int, name: string, slug: string, url: string, vlan_count: int>, id: int, last_updated: string, name: string, prefix_count: int, role: record<id: int, name: string, prefix_count: int, slug: string, url: string, vlan_count: int>, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vid: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/vlans/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /ipam/vlans/{id}/
#
# operationId: ipam_vlans_partial_update
export def "ipam-vlans update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --description: string
  --group: int # nullable
  name: string
  --role: int # nullable
  --site: int # nullable
  --status: string@status-completer-8
  --tags: list<string>
  --tenant: int # nullable
  vid: int
]: any -> record<created: string, custom_fields: record, description: string, display_name: string, group: record<id: int, name: string, slug: string, url: string, vlan_count: int>, id: int, last_updated: string, name: string, prefix_count: int, role: record<id: int, name: string, prefix_count: int, slug: string, url: string, vlan_count: int>, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/vlans/{id}/"))
  let req_body = {"custom_fields": $custom_fields, "description": $description, "group": $group, "name": $name, "role": $role, "site": $site, "status": $status, "tags": $tags, "tenant": $tenant, "vid": $vid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /ipam/vlans/{id}/
#
# operationId: ipam_vlans_update
export def "ipam-vlans update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --description: string
  --group: int # nullable
  name: string
  --role: int # nullable
  --site: int # nullable
  --status: string@status-completer-8
  --tags: list<string>
  --tenant: int # nullable
  vid: int
]: any -> record<created: string, custom_fields: record, description: string, display_name: string, group: record<id: int, name: string, slug: string, url: string, vlan_count: int>, id: int, last_updated: string, name: string, prefix_count: int, role: record<id: int, name: string, prefix_count: int, slug: string, url: string, vlan_count: int>, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/vlans/{id}/"))
  let req_body = {"custom_fields": $custom_fields, "description": $description, "group": $group, "name": $name, "role": $role, "site": $site, "status": $status, "tags": $tags, "tenant": $tenant, "vid": $vid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /ipam/vrfs/
# operationId: ipam_vrfs_list
export def "ipam-vrfs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --rd: string
  --enforce-unique: string
  --tenant-group-id: string
  --tenant-group: string
  --tenant-id: string
  --tenant: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --rd-n: string
  --rd-ic: string
  --rd-nic: string
  --rd-iew: string
  --rd-niew: string
  --rd-isw: string
  --rd-nisw: string
  --rd-ie: string
  --rd-nie: string
  --tenant-group-id-n: string
  --tenant-group-n: string
  --tenant-id-n: string
  --tenant-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<created: string, custom_fields: record, description: string, display_name: string, enforce_unique: bool, id: int, ipaddress_count: int, last_updated: string, name: string, prefix_count: int, rd: string, tags: list, tenant: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "rd" $rd "scalar") (serialize-qp "enforce_unique" $enforce_unique "scalar") (serialize-qp "tenant_group_id" $tenant_group_id "scalar") (serialize-qp "tenant_group" $tenant_group "scalar") (serialize-qp "tenant_id" $tenant_id "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "rd__n" $rd_n "scalar") (serialize-qp "rd__ic" $rd_ic "scalar") (serialize-qp "rd__nic" $rd_nic "scalar") (serialize-qp "rd__iew" $rd_iew "scalar") (serialize-qp "rd__niew" $rd_niew "scalar") (serialize-qp "rd__isw" $rd_isw "scalar") (serialize-qp "rd__nisw" $rd_nisw "scalar") (serialize-qp "rd__ie" $rd_ie "scalar") (serialize-qp "rd__nie" $rd_nie "scalar") (serialize-qp "tenant_group_id__n" $tenant_group_id_n "scalar") (serialize-qp "tenant_group__n" $tenant_group_n "scalar") (serialize-qp "tenant_id__n" $tenant_id_n "scalar") (serialize-qp "tenant__n" $tenant_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ipam/vrfs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /ipam/vrfs/
#
# operationId: ipam_vrfs_create
export def "ipam-vrfs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --description: string
  --enforce-unique: oneof<nothing, bool> # Prevent duplicate prefixes/IP addresses within this VRF
  name: string
  --rd: string # Unique route distinguisher (as defined in RFC 4364) (nullable)
  --tags: list<string>
  --tenant: int # nullable
]: any -> record<created: string, custom_fields: record, description: string, display_name: string, enforce_unique: bool, id: int, ipaddress_count: int, last_updated: string, name: string, prefix_count: int, rd: string, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ipam/vrfs/")
  let req_body = {"custom_fields": $custom_fields, "description": $description, "enforce_unique": $enforce_unique, "name": $name, "rd": $rd, "tags": $tags, "tenant": $tenant} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /ipam/vrfs/{id}/
#
# operationId: ipam_vrfs_delete
export def "ipam-vrfs delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/vrfs/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /ipam/vrfs/{id}/
# operationId: ipam_vrfs_read
export def "ipam-vrfs get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, custom_fields: record, description: string, display_name: string, enforce_unique: bool, id: int, ipaddress_count: int, last_updated: string, name: string, prefix_count: int, rd: string, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/vrfs/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /ipam/vrfs/{id}/
#
# operationId: ipam_vrfs_partial_update
export def "ipam-vrfs update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --description: string
  --enforce-unique: oneof<nothing, bool> # Prevent duplicate prefixes/IP addresses within this VRF
  name: string
  --rd: string # Unique route distinguisher (as defined in RFC 4364) (nullable)
  --tags: list<string>
  --tenant: int # nullable
]: any -> record<created: string, custom_fields: record, description: string, display_name: string, enforce_unique: bool, id: int, ipaddress_count: int, last_updated: string, name: string, prefix_count: int, rd: string, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/vrfs/{id}/"))
  let req_body = {"custom_fields": $custom_fields, "description": $description, "enforce_unique": $enforce_unique, "name": $name, "rd": $rd, "tags": $tags, "tenant": $tenant} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /ipam/vrfs/{id}/
#
# operationId: ipam_vrfs_update
export def "ipam-vrfs update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  --description: string
  --enforce-unique: oneof<nothing, bool> # Prevent duplicate prefixes/IP addresses within this VRF
  name: string
  --rd: string # Unique route distinguisher (as defined in RFC 4364) (nullable)
  --tags: list<string>
  --tenant: int # nullable
]: any -> record<created: string, custom_fields: record, description: string, display_name: string, enforce_unique: bool, id: int, ipaddress_count: int, last_updated: string, name: string, prefix_count: int, rd: string, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ipam/vrfs/{id}/"))
  let req_body = {"custom_fields": $custom_fields, "description": $description, "enforce_unique": $enforce_unique, "name": $name, "rd": $rd, "tags": $tags, "tenant": $tenant} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This endpoint can be used to generate a new RSA key pair. The keys are returned in PEM format.
#
# GET /secrets/generate-rsa-key-pair/
# operationId: secrets_generate-rsa-key-pair_list
export def "secrets-generate-rsa-key-pair list" [
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
  let full_url = (build-url $base "/secrets/generate-rsa-key-pair/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a temporary session key to use for encrypting and decrypting secrets via the API. The user's private RSA key is POSTed with the name `private_key`. An example: curl -v -X POST -H "Authorization: Token " -H "Accept: application/json; indent=4" \ --data-urlencode "private_key@" https://netbox/api/secrets/get-session-key/ This request will yield a base64-encoded session key to be included in an `X-Session-Key` header in future requests: { "session_key": "+8t4SI6XikgVmB5+/urhozx9O5qCQANyOk1MNe6taRf=" } This endpoint accepts one optional parameter: `preserve_key`. If True and a session key exists, the existing session key will be returned instead of a new one.
#
# POST /secrets/get-session-key/
# operationId: secrets_get-session-key_create
export def "secrets-get-session-key create" [
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
  let full_url = (build-url $base "/secrets/get-session-key/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /secrets/secret-roles/
# operationId: secrets_secret-roles_list
export def "secrets-secret-roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --q: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<description: string, id: int, name: string, secret_count: int, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/secrets/secret-roles/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /secrets/secret-roles/
#
# operationId: secrets_secret-roles_create
export def "secrets-secret-roles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<description: string, id: int, name: string, secret_count: int, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/secrets/secret-roles/")
  let req_body = {"description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /secrets/secret-roles/{id}/
#
# operationId: secrets_secret-roles_delete
export def "secrets-secret-roles delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/secrets/secret-roles/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /secrets/secret-roles/{id}/
# operationId: secrets_secret-roles_read
export def "secrets-secret-roles get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: int, name: string, secret_count: int, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/secrets/secret-roles/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /secrets/secret-roles/{id}/
#
# operationId: secrets_secret-roles_partial_update
export def "secrets-secret-roles update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<description: string, id: int, name: string, secret_count: int, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/secrets/secret-roles/{id}/"))
  let req_body = {"description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /secrets/secret-roles/{id}/
#
# operationId: secrets_secret-roles_update
export def "secrets-secret-roles update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<description: string, id: int, name: string, secret_count: int, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/secrets/secret-roles/{id}/"))
  let req_body = {"description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# GET /secrets/secrets/
#
# operationId: secrets_secrets_list
export def "secrets-secrets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --role-id: string
  --role: string
  --device-id: string
  --device: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --role-id-n: string
  --role-n: string
  --device-id-n: string
  --device-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<created: string, custom_fields: record, device: record, hash: string, id: int, last_updated: string, name: string, plaintext: string, role: record, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "role_id" $role_id "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "device_id" $device_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "role_id__n" $role_id_n "scalar") (serialize-qp "role__n" $role_n "scalar") (serialize-qp "device_id__n" $device_id_n "scalar") (serialize-qp "device__n" $device_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/secrets/secrets/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /secrets/secrets/
#
# operationId: secrets_secrets_create
export def "secrets-secrets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  device: int
  --name: string
  plaintext: string
  role: int
  --tags: list<string>
]: any -> record<created: string, custom_fields: record, device: record<display_name: string, id: int, name: string, url: string>, hash: string, id: int, last_updated: string, name: string, plaintext: string, role: record<id: int, name: string, secret_count: int, slug: string, url: string>, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/secrets/secrets/")
  let req_body = {"custom_fields": $custom_fields, "device": $device, "name": $name, "plaintext": $plaintext, "role": $role, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /secrets/secrets/{id}/
#
# operationId: secrets_secrets_delete
export def "secrets-secrets delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/secrets/secrets/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /secrets/secrets/{id}/
#
# operationId: secrets_secrets_read
export def "secrets-secrets get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, custom_fields: record, device: record<display_name: string, id: int, name: string, url: string>, hash: string, id: int, last_updated: string, name: string, plaintext: string, role: record<id: int, name: string, secret_count: int, slug: string, url: string>, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/secrets/secrets/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /secrets/secrets/{id}/
#
# operationId: secrets_secrets_partial_update
export def "secrets-secrets update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  device: int
  --name: string
  plaintext: string
  role: int
  --tags: list<string>
]: any -> record<created: string, custom_fields: record, device: record<display_name: string, id: int, name: string, url: string>, hash: string, id: int, last_updated: string, name: string, plaintext: string, role: record<id: int, name: string, secret_count: int, slug: string, url: string>, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/secrets/secrets/{id}/"))
  let req_body = {"custom_fields": $custom_fields, "device": $device, "name": $name, "plaintext": $plaintext, "role": $role, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /secrets/secrets/{id}/
#
# operationId: secrets_secrets_update
export def "secrets-secrets update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: record # default: {}
  device: int
  --name: string
  plaintext: string
  role: int
  --tags: list<string>
]: any -> record<created: string, custom_fields: record, device: record<display_name: string, id: int, name: string, url: string>, hash: string, id: int, last_updated: string, name: string, plaintext: string, role: record<id: int, name: string, secret_count: int, slug: string, url: string>, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/secrets/secrets/{id}/"))
  let req_body = {"custom_fields": $custom_fields, "device": $device, "name": $name, "plaintext": $plaintext, "role": $role, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /tenancy/tenant-groups/
# operationId: tenancy_tenant-groups_list
export def "tenancy-tenant-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --description: string
  --q: string
  --parent-id: string
  --parent: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --parent-id-n: string
  --parent-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<description: string, id: int, name: string, parent: record, slug: string, tenant_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "parent" $parent "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "parent_id__n" $parent_id_n "scalar") (serialize-qp "parent__n" $parent_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tenancy/tenant-groups/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /tenancy/tenant-groups/
#
# operationId: tenancy_tenant-groups_create
export def "tenancy-tenant-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  --parent: int # nullable
  slug: string # format: slug
]: any -> record<description: string, id: int, name: string, parent: record<id: int, name: string, slug: string, tenant_count: int, url: string>, slug: string, tenant_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tenancy/tenant-groups/")
  let req_body = {"description": $description, "name": $name, "parent": $parent, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /tenancy/tenant-groups/{id}/
#
# operationId: tenancy_tenant-groups_delete
export def "tenancy-tenant-groups delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/tenancy/tenant-groups/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /tenancy/tenant-groups/{id}/
# operationId: tenancy_tenant-groups_read
export def "tenancy-tenant-groups get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: int, name: string, parent: record<id: int, name: string, slug: string, tenant_count: int, url: string>, slug: string, tenant_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/tenancy/tenant-groups/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /tenancy/tenant-groups/{id}/
#
# operationId: tenancy_tenant-groups_partial_update
export def "tenancy-tenant-groups update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  --parent: int # nullable
  slug: string # format: slug
]: any -> record<description: string, id: int, name: string, parent: record<id: int, name: string, slug: string, tenant_count: int, url: string>, slug: string, tenant_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/tenancy/tenant-groups/{id}/"))
  let req_body = {"description": $description, "name": $name, "parent": $parent, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /tenancy/tenant-groups/{id}/
#
# operationId: tenancy_tenant-groups_update
export def "tenancy-tenant-groups update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  --parent: int # nullable
  slug: string # format: slug
]: any -> record<description: string, id: int, name: string, parent: record<id: int, name: string, slug: string, tenant_count: int, url: string>, slug: string, tenant_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/tenancy/tenant-groups/{id}/"))
  let req_body = {"description": $description, "name": $name, "parent": $parent, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /tenancy/tenants/
# operationId: tenancy_tenants_list
export def "tenancy-tenants list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --group-id: string
  --group: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --group-id-n: string
  --group-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<circuit_count: int, cluster_count: int, comments: string, created: string, custom_fields: record, description: string, device_count: int, group: record, id: int, ipaddress_count: int, last_updated: string, name: string, prefix_count: int, rack_count: int, site_count: int, slug: string, tags: list, virtualmachine_count: int, vlan_count: int, vrf_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "group_id__n" $group_id_n "scalar") (serialize-qp "group__n" $group_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tenancy/tenants/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /tenancy/tenants/
#
# operationId: tenancy_tenants_create
export def "tenancy-tenants create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comments: string
  --custom-fields: record # default: {}
  --description: string
  --group: int # nullable
  name: string
  slug: string # format: slug
  --tags: list<string>
]: any -> record<circuit_count: int, cluster_count: int, comments: string, created: string, custom_fields: record, description: string, device_count: int, group: record<id: int, name: string, slug: string, tenant_count: int, url: string>, id: int, ipaddress_count: int, last_updated: string, name: string, prefix_count: int, rack_count: int, site_count: int, slug: string, tags: list<string>, virtualmachine_count: int, vlan_count: int, vrf_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tenancy/tenants/")
  let req_body = {"comments": $comments, "custom_fields": $custom_fields, "description": $description, "group": $group, "name": $name, "slug": $slug, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /tenancy/tenants/{id}/
#
# operationId: tenancy_tenants_delete
export def "tenancy-tenants delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/tenancy/tenants/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /tenancy/tenants/{id}/
# operationId: tenancy_tenants_read
export def "tenancy-tenants get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<circuit_count: int, cluster_count: int, comments: string, created: string, custom_fields: record, description: string, device_count: int, group: record<id: int, name: string, slug: string, tenant_count: int, url: string>, id: int, ipaddress_count: int, last_updated: string, name: string, prefix_count: int, rack_count: int, site_count: int, slug: string, tags: list<string>, virtualmachine_count: int, vlan_count: int, vrf_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/tenancy/tenants/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /tenancy/tenants/{id}/
#
# operationId: tenancy_tenants_partial_update
export def "tenancy-tenants update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comments: string
  --custom-fields: record # default: {}
  --description: string
  --group: int # nullable
  name: string
  slug: string # format: slug
  --tags: list<string>
]: any -> record<circuit_count: int, cluster_count: int, comments: string, created: string, custom_fields: record, description: string, device_count: int, group: record<id: int, name: string, slug: string, tenant_count: int, url: string>, id: int, ipaddress_count: int, last_updated: string, name: string, prefix_count: int, rack_count: int, site_count: int, slug: string, tags: list<string>, virtualmachine_count: int, vlan_count: int, vrf_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/tenancy/tenants/{id}/"))
  let req_body = {"comments": $comments, "custom_fields": $custom_fields, "description": $description, "group": $group, "name": $name, "slug": $slug, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /tenancy/tenants/{id}/
#
# operationId: tenancy_tenants_update
export def "tenancy-tenants update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comments: string
  --custom-fields: record # default: {}
  --description: string
  --group: int # nullable
  name: string
  slug: string # format: slug
  --tags: list<string>
]: any -> record<circuit_count: int, cluster_count: int, comments: string, created: string, custom_fields: record, description: string, device_count: int, group: record<id: int, name: string, slug: string, tenant_count: int, url: string>, id: int, ipaddress_count: int, last_updated: string, name: string, prefix_count: int, rack_count: int, site_count: int, slug: string, tags: list<string>, virtualmachine_count: int, vlan_count: int, vrf_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/tenancy/tenants/{id}/"))
  let req_body = {"comments": $comments, "custom_fields": $custom_fields, "description": $description, "group": $group, "name": $name, "slug": $slug, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /virtualization/cluster-groups/
# operationId: virtualization_cluster-groups_list
export def "virtualization-cluster-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --description: string
  --q: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<cluster_count: int, description: string, id: int, name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/virtualization/cluster-groups/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /virtualization/cluster-groups/
#
# operationId: virtualization_cluster-groups_create
export def "virtualization-cluster-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<cluster_count: int, description: string, id: int, name: string, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/virtualization/cluster-groups/")
  let req_body = {"description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /virtualization/cluster-groups/{id}/
#
# operationId: virtualization_cluster-groups_delete
export def "virtualization-cluster-groups delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/cluster-groups/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /virtualization/cluster-groups/{id}/
# operationId: virtualization_cluster-groups_read
export def "virtualization-cluster-groups get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cluster_count: int, description: string, id: int, name: string, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/cluster-groups/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /virtualization/cluster-groups/{id}/
#
# operationId: virtualization_cluster-groups_partial_update
export def "virtualization-cluster-groups update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<cluster_count: int, description: string, id: int, name: string, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/cluster-groups/{id}/"))
  let req_body = {"description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /virtualization/cluster-groups/{id}/
#
# operationId: virtualization_cluster-groups_update
export def "virtualization-cluster-groups update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<cluster_count: int, description: string, id: int, name: string, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/cluster-groups/{id}/"))
  let req_body = {"description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /virtualization/cluster-types/
# operationId: virtualization_cluster-types_list
export def "virtualization-cluster-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --slug: string
  --description: string
  --q: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --slug-n: string
  --slug-ic: string
  --slug-nic: string
  --slug-iew: string
  --slug-niew: string
  --slug-isw: string
  --slug-nisw: string
  --slug-ie: string
  --slug-nie: string
  --description-n: string
  --description-ic: string
  --description-nic: string
  --description-iew: string
  --description-niew: string
  --description-isw: string
  --description-nisw: string
  --description-ie: string
  --description-nie: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<cluster_count: int, description: string, id: int, name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "slug__n" $slug_n "scalar") (serialize-qp "slug__ic" $slug_ic "scalar") (serialize-qp "slug__nic" $slug_nic "scalar") (serialize-qp "slug__iew" $slug_iew "scalar") (serialize-qp "slug__niew" $slug_niew "scalar") (serialize-qp "slug__isw" $slug_isw "scalar") (serialize-qp "slug__nisw" $slug_nisw "scalar") (serialize-qp "slug__ie" $slug_ie "scalar") (serialize-qp "slug__nie" $slug_nie "scalar") (serialize-qp "description__n" $description_n "scalar") (serialize-qp "description__ic" $description_ic "scalar") (serialize-qp "description__nic" $description_nic "scalar") (serialize-qp "description__iew" $description_iew "scalar") (serialize-qp "description__niew" $description_niew "scalar") (serialize-qp "description__isw" $description_isw "scalar") (serialize-qp "description__nisw" $description_nisw "scalar") (serialize-qp "description__ie" $description_ie "scalar") (serialize-qp "description__nie" $description_nie "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/virtualization/cluster-types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /virtualization/cluster-types/
#
# operationId: virtualization_cluster-types_create
export def "virtualization-cluster-types create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<cluster_count: int, description: string, id: int, name: string, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/virtualization/cluster-types/")
  let req_body = {"description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /virtualization/cluster-types/{id}/
#
# operationId: virtualization_cluster-types_delete
export def "virtualization-cluster-types delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/cluster-types/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /virtualization/cluster-types/{id}/
# operationId: virtualization_cluster-types_read
export def "virtualization-cluster-types get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cluster_count: int, description: string, id: int, name: string, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/cluster-types/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /virtualization/cluster-types/{id}/
#
# operationId: virtualization_cluster-types_partial_update
export def "virtualization-cluster-types update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<cluster_count: int, description: string, id: int, name: string, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/cluster-types/{id}/"))
  let req_body = {"description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /virtualization/cluster-types/{id}/
#
# operationId: virtualization_cluster-types_update
export def "virtualization-cluster-types update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  slug: string # format: slug
]: any -> record<cluster_count: int, description: string, id: int, name: string, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/cluster-types/{id}/"))
  let req_body = {"description": $description, "name": $name, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /virtualization/clusters/
# operationId: virtualization_clusters_list
export def "virtualization-clusters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --tenant-group-id: string
  --tenant-group: string
  --tenant-id: string
  --tenant: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --group-id: string
  --group: string
  --type-id: string
  --type: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --tenant-group-id-n: string
  --tenant-group-n: string
  --tenant-id-n: string
  --tenant-n: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --group-id-n: string
  --group-n: string
  --type-id-n: string
  --type-n: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<comments: string, created: string, custom_fields: record, device_count: int, group: record, id: int, last_updated: string, name: string, site: record, tags: list, tenant: record, type: record, virtualmachine_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "tenant_group_id" $tenant_group_id "scalar") (serialize-qp "tenant_group" $tenant_group "scalar") (serialize-qp "tenant_id" $tenant_id "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "type_id" $type_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "tenant_group_id__n" $tenant_group_id_n "scalar") (serialize-qp "tenant_group__n" $tenant_group_n "scalar") (serialize-qp "tenant_id__n" $tenant_id_n "scalar") (serialize-qp "tenant__n" $tenant_n "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "group_id__n" $group_id_n "scalar") (serialize-qp "group__n" $group_n "scalar") (serialize-qp "type_id__n" $type_id_n "scalar") (serialize-qp "type__n" $type_n "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/virtualization/clusters/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /virtualization/clusters/
#
# operationId: virtualization_clusters_create
export def "virtualization-clusters create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comments: string
  --custom-fields: record # default: {}
  --group: int # nullable
  name: string
  --site: int # nullable
  --tags: list<string>
  --tenant: int # nullable
  type: int
]: any -> record<comments: string, created: string, custom_fields: record, device_count: int, group: record<cluster_count: int, id: int, name: string, slug: string, url: string>, id: int, last_updated: string, name: string, site: record<id: int, name: string, slug: string, url: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, type: record<cluster_count: int, id: int, name: string, slug: string, url: string>, virtualmachine_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/virtualization/clusters/")
  let req_body = {"comments": $comments, "custom_fields": $custom_fields, "group": $group, "name": $name, "site": $site, "tags": $tags, "tenant": $tenant, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /virtualization/clusters/{id}/
#
# operationId: virtualization_clusters_delete
export def "virtualization-clusters delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/clusters/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /virtualization/clusters/{id}/
# operationId: virtualization_clusters_read
export def "virtualization-clusters get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<comments: string, created: string, custom_fields: record, device_count: int, group: record<cluster_count: int, id: int, name: string, slug: string, url: string>, id: int, last_updated: string, name: string, site: record<id: int, name: string, slug: string, url: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, type: record<cluster_count: int, id: int, name: string, slug: string, url: string>, virtualmachine_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/clusters/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /virtualization/clusters/{id}/
#
# operationId: virtualization_clusters_partial_update
export def "virtualization-clusters update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comments: string
  --custom-fields: record # default: {}
  --group: int # nullable
  name: string
  --site: int # nullable
  --tags: list<string>
  --tenant: int # nullable
  type: int
]: any -> record<comments: string, created: string, custom_fields: record, device_count: int, group: record<cluster_count: int, id: int, name: string, slug: string, url: string>, id: int, last_updated: string, name: string, site: record<id: int, name: string, slug: string, url: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, type: record<cluster_count: int, id: int, name: string, slug: string, url: string>, virtualmachine_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/clusters/{id}/"))
  let req_body = {"comments": $comments, "custom_fields": $custom_fields, "group": $group, "name": $name, "site": $site, "tags": $tags, "tenant": $tenant, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /virtualization/clusters/{id}/
#
# operationId: virtualization_clusters_update
export def "virtualization-clusters update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comments: string
  --custom-fields: record # default: {}
  --group: int # nullable
  name: string
  --site: int # nullable
  --tags: list<string>
  --tenant: int # nullable
  type: int
]: any -> record<comments: string, created: string, custom_fields: record, device_count: int, group: record<cluster_count: int, id: int, name: string, slug: string, url: string>, id: int, last_updated: string, name: string, site: record<id: int, name: string, slug: string, url: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, type: record<cluster_count: int, id: int, name: string, slug: string, url: string>, virtualmachine_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/clusters/{id}/"))
  let req_body = {"comments": $comments, "custom_fields": $custom_fields, "group": $group, "name": $name, "site": $site, "tags": $tags, "tenant": $tenant, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /virtualization/interfaces/
# operationId: virtualization_interfaces_list
export def "virtualization-interfaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --enabled: string
  --mtu: string
  --q: string
  --virtual-machine-id: string
  --virtual-machine: string
  --mac-address: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --mtu-n: string
  --mtu-lte: string
  --mtu-lt: string
  --mtu-gte: string
  --mtu-gt: string
  --virtual-machine-id-n: string
  --virtual-machine-n: string
  --mac-address-n: string
  --mac-address-ic: string
  --mac-address-nic: string
  --mac-address-iew: string
  --mac-address-niew: string
  --mac-address-isw: string
  --mac-address-nisw: string
  --mac-address-ie: string
  --mac-address-nie: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<description: string, enabled: bool, id: int, mac_address: string, mode: record, mtu: int, name: string, tagged_vlans: list, tags: list, type: record, untagged_vlan: record, virtual_machine: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "enabled" $enabled "scalar") (serialize-qp "mtu" $mtu "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "virtual_machine_id" $virtual_machine_id "scalar") (serialize-qp "virtual_machine" $virtual_machine "scalar") (serialize-qp "mac_address" $mac_address "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "mtu__n" $mtu_n "scalar") (serialize-qp "mtu__lte" $mtu_lte "scalar") (serialize-qp "mtu__lt" $mtu_lt "scalar") (serialize-qp "mtu__gte" $mtu_gte "scalar") (serialize-qp "mtu__gt" $mtu_gt "scalar") (serialize-qp "virtual_machine_id__n" $virtual_machine_id_n "scalar") (serialize-qp "virtual_machine__n" $virtual_machine_n "scalar") (serialize-qp "mac_address__n" $mac_address_n "scalar") (serialize-qp "mac_address__ic" $mac_address_ic "scalar") (serialize-qp "mac_address__nic" $mac_address_nic "scalar") (serialize-qp "mac_address__iew" $mac_address_iew "scalar") (serialize-qp "mac_address__niew" $mac_address_niew "scalar") (serialize-qp "mac_address__isw" $mac_address_isw "scalar") (serialize-qp "mac_address__nisw" $mac_address_nisw "scalar") (serialize-qp "mac_address__ie" $mac_address_ie "scalar") (serialize-qp "mac_address__nie" $mac_address_nie "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/virtualization/interfaces/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /virtualization/interfaces/
#
# operationId: virtualization_interfaces_create
export def "virtualization-interfaces create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --enabled: oneof<nothing, bool>
  --mac-address: string # nullable
  --mode: string@mode-completer
  --mtu: int # nullable
  name: string
  --tagged-vlans: list<int>
  --tags: list<string>
  type: string@type-completer-3
  --untagged-vlan: int # nullable
  --virtual-machine: int # nullable
]: any -> record<description: string, enabled: bool, id: int, mac_address: string, mode: record<label: string, value: string>, mtu: int, name: string, tagged_vlans: table<display_name: string, id: int, name: string, url: string, vid: int>, tags: list<string>, type: record<label: string, value: string>, untagged_vlan: record<display_name: string, id: int, name: string, url: string, vid: int>, virtual_machine: record<id: int, name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/virtualization/interfaces/")
  let req_body = {"description": $description, "enabled": $enabled, "mac_address": $mac_address, "mode": $mode, "mtu": $mtu, "name": $name, "tagged_vlans": $tagged_vlans, "tags": $tags, "type": $type, "untagged_vlan": $untagged_vlan, "virtual_machine": $virtual_machine} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /virtualization/interfaces/{id}/
#
# operationId: virtualization_interfaces_delete
export def "virtualization-interfaces delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/interfaces/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /virtualization/interfaces/{id}/
# operationId: virtualization_interfaces_read
export def "virtualization-interfaces get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, enabled: bool, id: int, mac_address: string, mode: record<label: string, value: string>, mtu: int, name: string, tagged_vlans: table<display_name: string, id: int, name: string, url: string, vid: int>, tags: list<string>, type: record<label: string, value: string>, untagged_vlan: record<display_name: string, id: int, name: string, url: string, vid: int>, virtual_machine: record<id: int, name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/interfaces/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /virtualization/interfaces/{id}/
#
# operationId: virtualization_interfaces_partial_update
export def "virtualization-interfaces update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --enabled: oneof<nothing, bool>
  --mac-address: string # nullable
  --mode: string@mode-completer
  --mtu: int # nullable
  name: string
  --tagged-vlans: list<int>
  --tags: list<string>
  type: string@type-completer-3
  --untagged-vlan: int # nullable
  --virtual-machine: int # nullable
]: any -> record<description: string, enabled: bool, id: int, mac_address: string, mode: record<label: string, value: string>, mtu: int, name: string, tagged_vlans: table<display_name: string, id: int, name: string, url: string, vid: int>, tags: list<string>, type: record<label: string, value: string>, untagged_vlan: record<display_name: string, id: int, name: string, url: string, vid: int>, virtual_machine: record<id: int, name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/interfaces/{id}/"))
  let req_body = {"description": $description, "enabled": $enabled, "mac_address": $mac_address, "mode": $mode, "mtu": $mtu, "name": $name, "tagged_vlans": $tagged_vlans, "tags": $tags, "type": $type, "untagged_vlan": $untagged_vlan, "virtual_machine": $virtual_machine} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /virtualization/interfaces/{id}/
#
# operationId: virtualization_interfaces_update
export def "virtualization-interfaces update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --enabled: oneof<nothing, bool>
  --mac-address: string # nullable
  --mode: string@mode-completer
  --mtu: int # nullable
  name: string
  --tagged-vlans: list<int>
  --tags: list<string>
  type: string@type-completer-3
  --untagged-vlan: int # nullable
  --virtual-machine: int # nullable
]: any -> record<description: string, enabled: bool, id: int, mac_address: string, mode: record<label: string, value: string>, mtu: int, name: string, tagged_vlans: table<display_name: string, id: int, name: string, url: string, vid: int>, tags: list<string>, type: record<label: string, value: string>, untagged_vlan: record<display_name: string, id: int, name: string, url: string, vid: int>, virtual_machine: record<id: int, name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/interfaces/{id}/"))
  let req_body = {"description": $description, "enabled": $enabled, "mac_address": $mac_address, "mode": $mode, "mtu": $mtu, "name": $name, "tagged_vlans": $tagged_vlans, "tags": $tags, "type": $type, "untagged_vlan": $untagged_vlan, "virtual_machine": $virtual_machine} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Call to super to allow for caching
#
# GET /virtualization/virtual-machines/
# operationId: virtualization_virtual-machines_list
export def "virtualization-virtual-machines list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --name: string
  --cluster: string
  --vcpus: string
  --memory: string
  --disk: string
  --local-context-data: string
  --tenant-group-id: string
  --tenant-group: string
  --tenant-id: string
  --tenant: string
  --created: string
  --created-gte: string
  --created-lte: string
  --last-updated: string
  --last-updated-gte: string
  --last-updated-lte: string
  --q: string
  --status: string
  --cluster-group-id: string
  --cluster-group: string
  --cluster-type-id: string
  --cluster-type: string
  --cluster-id: string
  --region-id: string
  --region: string
  --site-id: string
  --site: string
  --role-id: string
  --role: string
  --platform-id: string
  --platform: string
  --mac-address: string
  --tag: string
  --id-n: string
  --id-lte: string
  --id-lt: string
  --id-gte: string
  --id-gt: string
  --name-n: string
  --name-ic: string
  --name-nic: string
  --name-iew: string
  --name-niew: string
  --name-isw: string
  --name-nisw: string
  --name-ie: string
  --name-nie: string
  --cluster-n: string
  --vcpus-n: string
  --vcpus-lte: string
  --vcpus-lt: string
  --vcpus-gte: string
  --vcpus-gt: string
  --memory-n: string
  --memory-lte: string
  --memory-lt: string
  --memory-gte: string
  --memory-gt: string
  --disk-n: string
  --disk-lte: string
  --disk-lt: string
  --disk-gte: string
  --disk-gt: string
  --tenant-group-id-n: string
  --tenant-group-n: string
  --tenant-id-n: string
  --tenant-n: string
  --status-n: string
  --cluster-group-id-n: string
  --cluster-group-n: string
  --cluster-type-id-n: string
  --cluster-type-n: string
  --cluster-id-n: string
  --region-id-n: string
  --region-n: string
  --site-id-n: string
  --site-n: string
  --role-id-n: string
  --role-n: string
  --platform-id-n: string
  --platform-n: string
  --mac-address-n: string
  --mac-address-ic: string
  --mac-address-nic: string
  --mac-address-iew: string
  --mac-address-niew: string
  --mac-address-isw: string
  --mac-address-nisw: string
  --mac-address-ie: string
  --mac-address-nie: string
  --tag-n: string
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<cluster: record, comments: string, config_context: record, created: string, custom_fields: record, disk: int, id: int, last_updated: string, local_context_data: string, memory: int, name: string, platform: record, primary_ip: record, primary_ip4: record, primary_ip6: record, role: record, site: record, status: record, tags: list, tenant: record, vcpus: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "cluster" $cluster "scalar") (serialize-qp "vcpus" $vcpus "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "disk" $disk "scalar") (serialize-qp "local_context_data" $local_context_data "scalar") (serialize-qp "tenant_group_id" $tenant_group_id "scalar") (serialize-qp "tenant_group" $tenant_group "scalar") (serialize-qp "tenant_id" $tenant_id "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "created__gte" $created_gte "scalar") (serialize-qp "created__lte" $created_lte "scalar") (serialize-qp "last_updated" $last_updated "scalar") (serialize-qp "last_updated__gte" $last_updated_gte "scalar") (serialize-qp "last_updated__lte" $last_updated_lte "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "cluster_group_id" $cluster_group_id "scalar") (serialize-qp "cluster_group" $cluster_group "scalar") (serialize-qp "cluster_type_id" $cluster_type_id "scalar") (serialize-qp "cluster_type" $cluster_type "scalar") (serialize-qp "cluster_id" $cluster_id "scalar") (serialize-qp "region_id" $region_id "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "site_id" $site_id "scalar") (serialize-qp "site" $site "scalar") (serialize-qp "role_id" $role_id "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "platform_id" $platform_id "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "mac_address" $mac_address "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "id__n" $id_n "scalar") (serialize-qp "id__lte" $id_lte "scalar") (serialize-qp "id__lt" $id_lt "scalar") (serialize-qp "id__gte" $id_gte "scalar") (serialize-qp "id__gt" $id_gt "scalar") (serialize-qp "name__n" $name_n "scalar") (serialize-qp "name__ic" $name_ic "scalar") (serialize-qp "name__nic" $name_nic "scalar") (serialize-qp "name__iew" $name_iew "scalar") (serialize-qp "name__niew" $name_niew "scalar") (serialize-qp "name__isw" $name_isw "scalar") (serialize-qp "name__nisw" $name_nisw "scalar") (serialize-qp "name__ie" $name_ie "scalar") (serialize-qp "name__nie" $name_nie "scalar") (serialize-qp "cluster__n" $cluster_n "scalar") (serialize-qp "vcpus__n" $vcpus_n "scalar") (serialize-qp "vcpus__lte" $vcpus_lte "scalar") (serialize-qp "vcpus__lt" $vcpus_lt "scalar") (serialize-qp "vcpus__gte" $vcpus_gte "scalar") (serialize-qp "vcpus__gt" $vcpus_gt "scalar") (serialize-qp "memory__n" $memory_n "scalar") (serialize-qp "memory__lte" $memory_lte "scalar") (serialize-qp "memory__lt" $memory_lt "scalar") (serialize-qp "memory__gte" $memory_gte "scalar") (serialize-qp "memory__gt" $memory_gt "scalar") (serialize-qp "disk__n" $disk_n "scalar") (serialize-qp "disk__lte" $disk_lte "scalar") (serialize-qp "disk__lt" $disk_lt "scalar") (serialize-qp "disk__gte" $disk_gte "scalar") (serialize-qp "disk__gt" $disk_gt "scalar") (serialize-qp "tenant_group_id__n" $tenant_group_id_n "scalar") (serialize-qp "tenant_group__n" $tenant_group_n "scalar") (serialize-qp "tenant_id__n" $tenant_id_n "scalar") (serialize-qp "tenant__n" $tenant_n "scalar") (serialize-qp "status__n" $status_n "scalar") (serialize-qp "cluster_group_id__n" $cluster_group_id_n "scalar") (serialize-qp "cluster_group__n" $cluster_group_n "scalar") (serialize-qp "cluster_type_id__n" $cluster_type_id_n "scalar") (serialize-qp "cluster_type__n" $cluster_type_n "scalar") (serialize-qp "cluster_id__n" $cluster_id_n "scalar") (serialize-qp "region_id__n" $region_id_n "scalar") (serialize-qp "region__n" $region_n "scalar") (serialize-qp "site_id__n" $site_id_n "scalar") (serialize-qp "site__n" $site_n "scalar") (serialize-qp "role_id__n" $role_id_n "scalar") (serialize-qp "role__n" $role_n "scalar") (serialize-qp "platform_id__n" $platform_id_n "scalar") (serialize-qp "platform__n" $platform_n "scalar") (serialize-qp "mac_address__n" $mac_address_n "scalar") (serialize-qp "mac_address__ic" $mac_address_ic "scalar") (serialize-qp "mac_address__nic" $mac_address_nic "scalar") (serialize-qp "mac_address__iew" $mac_address_iew "scalar") (serialize-qp "mac_address__niew" $mac_address_niew "scalar") (serialize-qp "mac_address__isw" $mac_address_isw "scalar") (serialize-qp "mac_address__nisw" $mac_address_nisw "scalar") (serialize-qp "mac_address__ie" $mac_address_ie "scalar") (serialize-qp "mac_address__nie" $mac_address_nie "scalar") (serialize-qp "tag__n" $tag_n "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/virtualization/virtual-machines/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /virtualization/virtual-machines/
#
# operationId: virtualization_virtual-machines_create
export def "virtualization-virtual-machines create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cluster: int
  --comments: string
  --custom-fields: record # default: {}
  --disk: int # nullable
  --local-context-data: string # nullable
  --memory: int # nullable
  name: string
  --platform: int # nullable
  --primary-ip4: int # nullable
  --primary-ip6: int # nullable
  --role: int # nullable
  --status: string@status-completer-9
  --tags: list<string>
  --tenant: int # nullable
  --vcpus: int # nullable
]: any -> record<cluster: record<id: int, name: string, url: string, virtualmachine_count: int>, comments: string, config_context: record, created: string, custom_fields: record, disk: int, id: int, last_updated: string, local_context_data: string, memory: int, name: string, platform: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, primary_ip: record<address: string, family: string, id: int, url: string>, primary_ip4: record<address: string, family: string, id: int, url: string>, primary_ip6: record<address: string, family: string, id: int, url: string>, role: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vcpus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/virtualization/virtual-machines/")
  let req_body = {"cluster": $cluster, "comments": $comments, "custom_fields": $custom_fields, "disk": $disk, "local_context_data": $local_context_data, "memory": $memory, "name": $name, "platform": $platform, "primary_ip4": $primary_ip4, "primary_ip6": $primary_ip6, "role": $role, "status": $status, "tags": $tags, "tenant": $tenant, "vcpus": $vcpus} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /virtualization/virtual-machines/{id}/
#
# operationId: virtualization_virtual-machines_delete
export def "virtualization-virtual-machines delete" [
  id: int
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/virtual-machines/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Call to super to allow for caching
#
# GET /virtualization/virtual-machines/{id}/
# operationId: virtualization_virtual-machines_read
export def "virtualization-virtual-machines get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cluster: record<id: int, name: string, url: string, virtualmachine_count: int>, comments: string, config_context: record, created: string, custom_fields: record, disk: int, id: int, last_updated: string, local_context_data: string, memory: int, name: string, platform: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, primary_ip: record<address: string, family: string, id: int, url: string>, primary_ip4: record<address: string, family: string, id: int, url: string>, primary_ip6: record<address: string, family: string, id: int, url: string>, role: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vcpus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/virtual-machines/{id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /virtualization/virtual-machines/{id}/
#
# operationId: virtualization_virtual-machines_partial_update
export def "virtualization-virtual-machines update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cluster: int
  --comments: string
  --custom-fields: record # default: {}
  --disk: int # nullable
  --local-context-data: string # nullable
  --memory: int # nullable
  name: string
  --platform: int # nullable
  --primary-ip4: int # nullable
  --primary-ip6: int # nullable
  --role: int # nullable
  --status: string@status-completer-9
  --tags: list<string>
  --tenant: int # nullable
  --vcpus: int # nullable
]: any -> record<cluster: record<id: int, name: string, url: string, virtualmachine_count: int>, comments: string, config_context: record, created: string, custom_fields: record, disk: int, id: int, last_updated: string, local_context_data: string, memory: int, name: string, platform: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, primary_ip: record<address: string, family: string, id: int, url: string>, primary_ip4: record<address: string, family: string, id: int, url: string>, primary_ip6: record<address: string, family: string, id: int, url: string>, role: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vcpus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/virtual-machines/{id}/"))
  let req_body = {"cluster": $cluster, "comments": $comments, "custom_fields": $custom_fields, "disk": $disk, "local_context_data": $local_context_data, "memory": $memory, "name": $name, "platform": $platform, "primary_ip4": $primary_ip4, "primary_ip6": $primary_ip6, "role": $role, "status": $status, "tags": $tags, "tenant": $tenant, "vcpus": $vcpus} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /virtualization/virtual-machines/{id}/
#
# operationId: virtualization_virtual-machines_update
export def "virtualization-virtual-machines update-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cluster: int
  --comments: string
  --custom-fields: record # default: {}
  --disk: int # nullable
  --local-context-data: string # nullable
  --memory: int # nullable
  name: string
  --platform: int # nullable
  --primary-ip4: int # nullable
  --primary-ip6: int # nullable
  --role: int # nullable
  --status: string@status-completer-9
  --tags: list<string>
  --tenant: int # nullable
  --vcpus: int # nullable
]: any -> record<cluster: record<id: int, name: string, url: string, virtualmachine_count: int>, comments: string, config_context: record, created: string, custom_fields: record, disk: int, id: int, last_updated: string, local_context_data: string, memory: int, name: string, platform: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, primary_ip: record<address: string, family: string, id: int, url: string>, primary_ip4: record<address: string, family: string, id: int, url: string>, primary_ip6: record<address: string, family: string, id: int, url: string>, role: record<device_count: int, id: int, name: string, slug: string, url: string, virtualmachine_count: int>, site: record<id: int, name: string, slug: string, url: string>, status: record<label: string, value: string>, tags: list<string>, tenant: record<id: int, name: string, slug: string, url: string>, vcpus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/virtualization/virtual-machines/{id}/"))
  let req_body = {"cluster": $cluster, "comments": $comments, "custom_fields": $custom_fields, "disk": $disk, "local_context_data": $local_context_data, "memory": $memory, "name": $name, "platform": $platform, "primary_ip4": $primary_ip4, "primary_ip6": $primary_ip6, "role": $role, "status": $status, "tags": $tags, "tenant": $tenant, "vcpus": $vcpus} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
