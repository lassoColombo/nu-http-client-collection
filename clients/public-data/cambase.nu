# Auto-generated client for Cambase.io v1.0
# Source: https://api.apis.guru/v2/specs/cambase.io/1.0/swagger.json
# Auth: --token flag or $env.CAMBASE_IO_TOKEN

const BASE_URL = "http://api.cambase.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CAMBASE_IO_TOKEN | default "" }
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

def base-url-completer [] { ["http://api.cambase.io"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "modelsjson Api::V1::Modelsindex" } } | get name | first)
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

# Fetches all Models
#
# GET /api/v1/models.json
# operationId: Api::V1::Models#index
export def "modelsjson Api::V1::Modelsindex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number
  --order: string # Sort order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/models.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Model
#
# POST /api/v1/models.json
# operationId: Api::V1::Models#create
export def "modelsjson Api::V1::Modelscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  vendor_id: string # Vendor ID
  modelmodel: string # Model
  --modelshape: string # Shape
  --modelresolution: string # Resolution
  --modelonvif: string # ONVIF
  --modelpsia: string # PSIA
  --modelptz: string # PTZ
  --modelinfrared: string # Infrared
  --modelvarifocal: string # Varifocal
  --modelsd-card: string # SD Card
  --modelupnp: string # UPnP
  --modelaudio-in: string # UPnP
  --modelaudio-out: string # UPnP
  --modeldefault-username: string # Default Username
  --modeldefault-password: string # Default Password
  --modeljpeg-url: string # JPEG URL
  --modelh264-url: string # H264 URL
  --modelmjpeg-url: string # MJPEG URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/models.json")
  let body = {vendor_id: $vendor_id, model[model]: $modelmodel, model[shape]: $modelshape, model[resolution]: $modelresolution, model[onvif]: $modelonvif, model[psia]: $modelpsia, model[ptz]: $modelptz, model[infrared]: $modelinfrared, model[varifocal]: $modelvarifocal, model[sd_card]: $modelsd_card, model[upnp]: $modelupnp, model[audio_in]: $modelaudio_in, model[audio_out]: $modelaudio_out, model[default_username]: $modeldefault_username, model[default_password]: $modeldefault_password, model[jpeg_url]: $modeljpeg_url, model[h264_url]: $modelh264_url, model[mjpeg_url]: $modelmjpeg_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Searches all Models
#
# GET /api/v1/models/search.json
# operationId: Api::V1::Models#search
export def "models-searchjson Api::V1::Modelssearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number
  --qmodel-cont: string # Model
  --qmanufacturer-name-cont: string # Vendor
  --qshape-eq: string # Shape
  --qresolution-eq: string # Resolution
  --qonvif-true: string # ONVIF
  --qpsia-true: string # PSIA
  --qptz-true: string # PTZ
  --qinfrared-true: string # Infrared
  --qvarifocal-true: string # Varifocal
  --qsd-card-true: string # SD Card
  --qupnp-true: string # UPnP
  --qaudio-in-true: string # Audio In
  --qaudio-out-true: string # Audio Out
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "q[model_cont]" $qmodel_cont "scalar") (serialize-qp "q[manufacturer_name_cont]" $qmanufacturer_name_cont "scalar") (serialize-qp "q[shape_eq]" $qshape_eq "scalar") (serialize-qp "q[resolution_eq]" $qresolution_eq "scalar") (serialize-qp "q[onvif_true]" $qonvif_true "scalar") (serialize-qp "q[psia_true]" $qpsia_true "scalar") (serialize-qp "q[ptz_true]" $qptz_true "scalar") (serialize-qp "q[infrared_true]" $qinfrared_true "scalar") (serialize-qp "q[varifocal_true]" $qvarifocal_true "scalar") (serialize-qp "q[sd_card_true]" $qsd_card_true "scalar") (serialize-qp "q[upnp_true]" $qupnp_true "scalar") (serialize-qp "q[audio_in_true]" $qaudio_in_true "scalar") (serialize-qp "q[audio_out_true]" $qaudio_out_true "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/models/search.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches a single Model
#
# GET /api/v1/models/{id}.json
# operationId: Api::V1::Models#show
export def "models Api::V1::Modelsshow" [
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
  let full_url = (build-url $base $"/api/v1/models/($id).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Model
#
# PATCH /api/v1/models/{id}.json
export def "models patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  vendor_id: string # Vendor ID
  --modelmodel: string # Model
  --modelshape: string # Shape
  --modelresolution: string # Resolution
  --modelonvif: string # ONVIF
  --modelpsia: string # PSIA
  --modelptz: string # PTZ
  --modelinfrared: string # Infrared
  --modelvarifocal: string # Varifocal
  --modelsd-card: string # SD Card
  --modelupnp: string # UPnP
  --modelaudio-in: string # Audio In
  --modelaudio-out: string # Audio Out
  --modeldefault-username: string # Default Username
  --modeldefault-password: string # Default Password
  --modeljpeg-url: string # JPEG URL
  --modelh264-url: string # H264 URL
  --modelmjpeg-url: string # MJPEG URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/models/($id).json")
  let body = {vendor_id: $vendor_id, model[model]: $modelmodel, model[shape]: $modelshape, model[resolution]: $modelresolution, model[onvif]: $modelonvif, model[psia]: $modelpsia, model[ptz]: $modelptz, model[infrared]: $modelinfrared, model[varifocal]: $modelvarifocal, model[sd_card]: $modelsd_card, model[upnp]: $modelupnp, model[audio_in]: $modelaudio_in, model[audio_out]: $modelaudio_out, model[default_username]: $modeldefault_username, model[default_password]: $modeldefault_password, model[jpeg_url]: $modeljpeg_url, model[h264_url]: $modelh264_url, model[mjpeg_url]: $modelmjpeg_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Updates an existing Model
#
# PUT /api/v1/models/{id}.json
export def "models put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  vendor_id: string # Vendor ID
  --modelmodel: string # Model
  --modelshape: string # Shape
  --modelresolution: string # Resolution
  --modelonvif: string # ONVIF
  --modelpsia: string # PSIA
  --modelptz: string # PTZ
  --modelinfrared: string # Infrared
  --modelvarifocal: string # Varifocal
  --modelsd-card: string # SD Card
  --modelupnp: string # UPnP
  --modelaudio-in: string # Audio In
  --modelaudio-out: string # Audio Out
  --modeldefault-username: string # Default Username
  --modeldefault-password: string # Default Password
  --modeljpeg-url: string # JPEG URL
  --modelh264-url: string # H264 URL
  --modelmjpeg-url: string # MJPEG URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/models/($id).json")
  let body = {vendor_id: $vendor_id, model[model]: $modelmodel, model[shape]: $modelshape, model[resolution]: $modelresolution, model[onvif]: $modelonvif, model[psia]: $modelpsia, model[ptz]: $modelptz, model[infrared]: $modelinfrared, model[varifocal]: $modelvarifocal, model[sd_card]: $modelsd_card, model[upnp]: $modelupnp, model[audio_in]: $modelaudio_in, model[audio_out]: $modelaudio_out, model[default_username]: $modeldefault_username, model[default_password]: $modeldefault_password, model[jpeg_url]: $modeljpeg_url, model[h264_url]: $modelh264_url, model[mjpeg_url]: $modelmjpeg_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetches all Recorders
#
# GET /api/v1/recorders.json
# operationId: Api::V1::Recorders#index
export def "recordersjson Api::V1::Recordersindex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number
  --order: string # Sort order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/recorders.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Recorder
#
# POST /api/v1/recorders.json
# operationId: Api::V1::Recorders#create
export def "recordersjson Api::V1::Recorderscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  vendor_id: string # Vendor ID
  recordermodel: string # Model
  recordername: string # Name
  recorderrecorder_type: string # Type
  --recorderresolution: string # Resolution
  --recorderonvif: string # ONVIF
  --recorderpsia: string # PSIA
  --recorderptz: string # PTZ
  --recorderdiscontinued: string # Discontinued
  --recordersupport-3rdparty: string # 3rd pparty Camera Support
  --recordersd-card: string # SD Card
  --recorderupnp: string # UPnP
  --recorderhot-swap: string # Hot Swap
  --recorderhdmi: string # HDMI Support
  --recorderdigital-io: string # Digital I/O
  --recorderaudio-in: string # Audio In
  --recorderaudio-out: string # Audio Out
  --recorderinput-channels: string # Input Channels
  --recorderplayback-channels: string # Playback Channels
  --recorderusb: string # USB Ports
  --recordersdhc: string # SD Card (GB)
  --recordermobile-access: string # Mobile Access
  --recorderalarms: string # Alarms
  --recorderraid-support: string # Raid Support
  --recorderstorage: string # Internal Storage
  --recorderadditional-information: string # Additional Information
  --recorderdefault-username: string # Default Username
  --recorderdefault-password: string # Default Password
  --recorderjpeg-url: string # JPEG URL
  --recorderh264-url: string # H264 URL
  --recordermjpeg-url: string # MJPEG URL
  --recorderofficial-url: string # Official URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/recorders.json")
  let body = {vendor_id: $vendor_id, recorder[model]: $recordermodel, recorder[name]: $recordername, recorder[recorder_type]: $recorderrecorder_type, recorder[resolution]: $recorderresolution, recorder[onvif]: $recorderonvif, recorder[psia]: $recorderpsia, recorder[ptz]: $recorderptz, recorder[discontinued]: $recorderdiscontinued, recorder[support_3rdparty]: $recordersupport_3rdparty, recorder[sd_card]: $recordersd_card, recorder[upnp]: $recorderupnp, recorder[hot_swap]: $recorderhot_swap, recorder[hdmi]: $recorderhdmi, recorder[digital_io]: $recorderdigital_io, recorder[audio_in]: $recorderaudio_in, recorder[audio_out]: $recorderaudio_out, recorder[input_channels]: $recorderinput_channels, recorder[playback_channels]: $recorderplayback_channels, recorder[usb]: $recorderusb, recorder[sdhc]: $recordersdhc, recorder[mobile_access]: $recordermobile_access, recorder[alarms]: $recorderalarms, recorder[raid_support]: $recorderraid_support, recorder[storage]: $recorderstorage, recorder[additional_information]: $recorderadditional_information, recorder[default_username]: $recorderdefault_username, recorder[default_password]: $recorderdefault_password, recorder[jpeg_url]: $recorderjpeg_url, recorder[h264_url]: $recorderh264_url, recorder[mjpeg_url]: $recordermjpeg_url, recorder[official_url]: $recorderofficial_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Searches all Recorders
#
# GET /api/v1/recorders/search.json
# operationId: Api::V1::Recorders#search
export def "recorders-searchjson Api::V1::Recorderssearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number
  --qmodel-cont: string # Model
  --qvendor-name-cont: string # Vendor
  --qsdhc-eq: string # SD Card (GB)
  --qtype-eq: string # Type
  --qresolution-eq: string # Resolution
  --qinput-channels-eq: string # Input Channels
  --qplayback-channels-eq: string # Playback Channels
  --qonvif-true: string # ONVIF
  --qpsia-true: string # PSIA
  --qptz-true: string # PTZ
  --qsd-card-true: string # SD Card
  --qupnp-true: string # UPnP
  --qaudio-in-true: string # Audio In
  --qaudio-out-true: string # Audio Out
  --qhdmi-true: string # HDMI Support
  --qhot-swap-true: string # Hot Swap
  --qsupport-3rdparty-true: string # 3rd pparty Camera Support
  --qdigital-io-true: string # Digital I/O
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "q[model_cont]" $qmodel_cont "scalar") (serialize-qp "q[vendor_name_cont]" $qvendor_name_cont "scalar") (serialize-qp "q[sdhc_eq]" $qsdhc_eq "scalar") (serialize-qp "q[type_eq]" $qtype_eq "scalar") (serialize-qp "q[resolution_eq]" $qresolution_eq "scalar") (serialize-qp "q[input_channels_eq]" $qinput_channels_eq "scalar") (serialize-qp "q[playback_channels_eq]" $qplayback_channels_eq "scalar") (serialize-qp "q[onvif_true]" $qonvif_true "scalar") (serialize-qp "q[psia_true]" $qpsia_true "scalar") (serialize-qp "q[ptz_true]" $qptz_true "scalar") (serialize-qp "q[sd_card_true]" $qsd_card_true "scalar") (serialize-qp "q[upnp_true]" $qupnp_true "scalar") (serialize-qp "q[audio_in_true]" $qaudio_in_true "scalar") (serialize-qp "q[audio_out_true]" $qaudio_out_true "scalar") (serialize-qp "q[hdmi_true]" $qhdmi_true "scalar") (serialize-qp "q[hot_swap_true]" $qhot_swap_true "scalar") (serialize-qp "q[support_3rdparty_true]" $qsupport_3rdparty_true "scalar") (serialize-qp "q[digital_io_true]" $qdigital_io_true "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/recorders/search.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches a single Recorder
#
# GET /api/v1/recorders/{id}.json
# operationId: Api::V1::Recorders#show
export def "recorders Api::V1::Recordersshow" [
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
  let full_url = (build-url $base $"/api/v1/recorders/($id).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Recorder
#
# PATCH /api/v1/recorders/{id}.json
export def "recorders patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  vendor_id: string # Vendor ID
  recordermodel: string # Model
  recordername: string # Name
  recorderrecorder_type: string # Type
  --recorderresolution: string # Resolution
  --recorderonvif: string # ONVIF
  --recorderpsia: string # PSIA
  --recorderptz: string # PTZ
  --recorderdiscontinued: string # Discontinued
  --recordersupport-3rdparty: string # 3rd pparty Camera Support
  --recordersd-card: string # SD Card
  --recorderupnp: string # UPnP
  --recorderhot-swap: string # Hot Swap
  --recorderhdmi: string # HDMI Support
  --recorderdigital-io: string # Digital I/O
  --recorderaudio-in: string # Audio In
  --recorderaudio-out: string # Audio Out
  --recorderinput-channels: string # Input Channels
  --recorderplayback-channels: string # Playback Channels
  --recorderusb: string # USB Ports
  --recordersdhc: string # SD Card (GB)
  --recordermobile-access: string # Mobile Access
  --recorderalarms: string # Alarms
  --recorderraid-support: string # Raid Support
  --recorderstorage: string # Internal Storage
  --recorderadditional-information: string # Additional Information
  --recorderdefault-username: string # Default Username
  --recorderdefault-password: string # Default Password
  --recorderjpeg-url: string # JPEG URL
  --recorderh264-url: string # H264 URL
  --recordermjpeg-url: string # MJPEG URL
  --recorderofficial-url: string # Official URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/recorders/($id).json")
  let body = {vendor_id: $vendor_id, recorder[model]: $recordermodel, recorder[name]: $recordername, recorder[recorder_type]: $recorderrecorder_type, recorder[resolution]: $recorderresolution, recorder[onvif]: $recorderonvif, recorder[psia]: $recorderpsia, recorder[ptz]: $recorderptz, recorder[discontinued]: $recorderdiscontinued, recorder[support_3rdparty]: $recordersupport_3rdparty, recorder[sd_card]: $recordersd_card, recorder[upnp]: $recorderupnp, recorder[hot_swap]: $recorderhot_swap, recorder[hdmi]: $recorderhdmi, recorder[digital_io]: $recorderdigital_io, recorder[audio_in]: $recorderaudio_in, recorder[audio_out]: $recorderaudio_out, recorder[input_channels]: $recorderinput_channels, recorder[playback_channels]: $recorderplayback_channels, recorder[usb]: $recorderusb, recorder[sdhc]: $recordersdhc, recorder[mobile_access]: $recordermobile_access, recorder[alarms]: $recorderalarms, recorder[raid_support]: $recorderraid_support, recorder[storage]: $recorderstorage, recorder[additional_information]: $recorderadditional_information, recorder[default_username]: $recorderdefault_username, recorder[default_password]: $recorderdefault_password, recorder[jpeg_url]: $recorderjpeg_url, recorder[h264_url]: $recorderh264_url, recorder[mjpeg_url]: $recordermjpeg_url, recorder[official_url]: $recorderofficial_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Updates an existing Recorder
#
# PUT /api/v1/recorders/{id}.json
export def "recorders put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  vendor_id: string # Vendor ID
  recordermodel: string # Model
  recordername: string # Name
  recorderrecorder_type: string # Type
  --recorderresolution: string # Resolution
  --recorderonvif: string # ONVIF
  --recorderpsia: string # PSIA
  --recorderptz: string # PTZ
  --recorderdiscontinued: string # Discontinued
  --recordersupport-3rdparty: string # 3rd pparty Camera Support
  --recordersd-card: string # SD Card
  --recorderupnp: string # UPnP
  --recorderhot-swap: string # Hot Swap
  --recorderhdmi: string # HDMI Support
  --recorderdigital-io: string # Digital I/O
  --recorderaudio-in: string # Audio In
  --recorderaudio-out: string # Audio Out
  --recorderinput-channels: string # Input Channels
  --recorderplayback-channels: string # Playback Channels
  --recorderusb: string # USB Ports
  --recordersdhc: string # SD Card (GB)
  --recordermobile-access: string # Mobile Access
  --recorderalarms: string # Alarms
  --recorderraid-support: string # Raid Support
  --recorderstorage: string # Internal Storage
  --recorderadditional-information: string # Additional Information
  --recorderdefault-username: string # Default Username
  --recorderdefault-password: string # Default Password
  --recorderjpeg-url: string # JPEG URL
  --recorderh264-url: string # H264 URL
  --recordermjpeg-url: string # MJPEG URL
  --recorderofficial-url: string # Official URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/recorders/($id).json")
  let body = {vendor_id: $vendor_id, recorder[model]: $recordermodel, recorder[name]: $recordername, recorder[recorder_type]: $recorderrecorder_type, recorder[resolution]: $recorderresolution, recorder[onvif]: $recorderonvif, recorder[psia]: $recorderpsia, recorder[ptz]: $recorderptz, recorder[discontinued]: $recorderdiscontinued, recorder[support_3rdparty]: $recordersupport_3rdparty, recorder[sd_card]: $recordersd_card, recorder[upnp]: $recorderupnp, recorder[hot_swap]: $recorderhot_swap, recorder[hdmi]: $recorderhdmi, recorder[digital_io]: $recorderdigital_io, recorder[audio_in]: $recorderaudio_in, recorder[audio_out]: $recorderaudio_out, recorder[input_channels]: $recorderinput_channels, recorder[playback_channels]: $recorderplayback_channels, recorder[usb]: $recorderusb, recorder[sdhc]: $recordersdhc, recorder[mobile_access]: $recordermobile_access, recorder[alarms]: $recorderalarms, recorder[raid_support]: $recorderraid_support, recorder[storage]: $recorderstorage, recorder[additional_information]: $recorderadditional_information, recorder[default_username]: $recorderdefault_username, recorder[default_password]: $recorderdefault_password, recorder[jpeg_url]: $recorderjpeg_url, recorder[h264_url]: $recorderh264_url, recorder[mjpeg_url]: $recordermjpeg_url, recorder[official_url]: $recorderofficial_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetches all Vendors
#
# GET /api/v1/vendors.json
# operationId: Api::V1::Vendors#index
export def "vendorsjson Api::V1::Vendorsindex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number
  --order: string # Sort order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/vendors.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Vendor
#
# POST /api/v1/vendors.json
# operationId: Api::V1::Vendors#create
export def "vendorsjson Api::V1::Vendorscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  vendorname: string # Name
  --vendorinfo: string # Info.
  --vendorurl: string # Website
  --vendormac: string # MAC
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/vendors.json")
  let body = {vendor[name]: $vendorname, vendor[info]: $vendorinfo, vendor[url]: $vendorurl, vendor[mac]: $vendormac} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetches a single Vendor
#
# GET /api/v1/vendors/{id}.json
# operationId: Api::V1::Vendors#show
export def "vendors Api::V1::Vendorsshow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string # Sort order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/vendors/($id).json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Vendor
#
# PATCH /api/v1/vendors/{id}.json
export def "vendors patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --vendorname: string # Name
  --vendorinfo: string # Info.
  --vendorurl: string # Website
  --vendormac: string # MAC
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/vendors/($id).json")
  let body = {vendor[name]: $vendorname, vendor[info]: $vendorinfo, vendor[url]: $vendorurl, vendor[mac]: $vendormac} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Updates an existing Vendor
#
# PUT /api/v1/vendors/{id}.json
export def "vendors put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --vendorname: string # Name
  --vendorinfo: string # Info.
  --vendorurl: string # Website
  --vendormac: string # MAC
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/vendors/($id).json")
  let body = {vendor[name]: $vendorname, vendor[info]: $vendorinfo, vendor[url]: $vendorurl, vendor[mac]: $vendormac} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
