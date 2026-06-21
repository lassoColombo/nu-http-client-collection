# Auto-generated client for IBM Containers API v3.0.0
# Source: https://api.apis.guru/v2/specs/bluemix.net/containers/3.0.0/openapi.json
# Auth: --token flag or $env.IBM_CONTAINERS_API_TOKEN

const BASE_URL = "https://containers-api.ng.bluemix.net/v3"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o IBM_CONTAINERS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://containers-api.ng.bluemix.net/v3"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "build create" } } | get name | first)
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

# Build a Docker image from a Dockerfile
#
# POST /build
export def "build create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t: string # Tag the image with the full path to your private Bluemix registry in the following format: `t=registry.ng.bluemix.net//<image_name>:`. This path is used to push the image to the private Bluemix registry after it is built.
  --q: oneof<nothing, bool> # You can choose whether or not to show the verbose build output to review every step during the container image build. If you set the query parameter to `q=false`, `q=False`, or `q=0`, the verbose build output is suppressed. To show the verbose build output, enter `q=true`, `q=True`, or `q=1`.
  --nocache: oneof<nothing, bool> # If you set the query parameter to `nocache=true`, `nocache=True`, or `nocache=1`, the cache will not be used to build your image. To use the cache, enter `nocache=false`, `nocache=False`, or `nocache=0`.
  --pull: oneof<nothing, bool> # If set to pull=true, pull=True, or pull=1, then a newer version of the image is always attempted to be pulled even though an older version of the image exists locally. If set to pull=false, pull=False, or pull=0, then the local image will be used if one exists.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t" $t "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "nocache" $nocache "scalar") (serialize-qp "pull" $pull "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/build" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/tar" $req_body {query: ({"t": $t, "q": $q, "nocache": $nocache, "pull": $pull} | compact), body: $req_body}
}

# Create and start a single container
#
# POST /containers/create
# --HostConfig shape: {Binds?: list<string>, ExtraHosts?: list<string>, Links?: list<string>, PortBindings?: list<string>}
export def "containers-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Choose a name for your container. The characters in the name can include uppercase letters, lowercase letters, numbers, periods (.), underscores (_), or hyphens (-), but the name must start with a letter.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
  --bluemix-app: string # The name of the Cloud Foundry app that you want to bind to your container. The Cloud Foundry app must be created in the same space where you want to create your container.
  --cmd: list<string> # The command and arguments in this list are passed to the container to be executed when the container is started. This command must be a long-running command. Do not use a short-lived command, for example, /bin/date, because it might cause the container to crash. Sample long-running commands:["ping","localhost"]["tail","-f","/dev/null"]["sh","-c","while true; do date; sleep 20; done"]
  --cpuset: string # Pins the container processes to a specific CPU core on the compute host. For example: 0 means that processes are executed on the first core only.
  --body-env: list<string> # A list of environment variables in the form of key=value pairs. All keys in this list have to be unique. List multiple keys separately and if you include quotation marks, include them around both the environment variable name and the value.
  --exposed-ports: list<string> # All public ports that need to be exposed for the container, so the container can be accessed from the Internet.
  --host-config: record # shape: {Binds?: list<string>, ExtraHosts?: list<string>, Links?: list<string>, PortBindings?: list<string>}
  image: string # Full path to the image in your private Bluemix registry in the format `registry.ng.bluemix.net/namespace/image`.
  --memory: int # The container memory that is set for the container in Megabyte. Choose one of the following sizes: Pico 64 MB, Nano 128 MB, Micro 256 MB, Tiny 512 MB, Small 1 GB (1024 MB), Medium 2 GB (2048 MB), Large 4 GB (4096 MB) XLarge 8GB (8192 MB) and 2XLarge 16 GB (16384 MB). (format: int32)
  --number-cpus: int # Number of virtual CPUs that are allocated to the container. (format: int32)
  --volumes: string # Mount a volume to a container by specifying the details in the following format: `VOLUME_NAME:/DIRECTORY_PATH[:ro]`. Example: testvolume:/volumedata/temp:rw. By default, all volumes will be set up with read-write access inside the container (rw). If you wish to set up your volume with read-only access, enter `ro`. Note: To mount a volume to a container, you must create the volume in your space first by using the `cf ic volume-create` command, or calling the `POST /volumes/create endpoint`.
]: any -> record<Id: string, flavor_id: int, mem: int, vcpu: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/containers/create" $qp)
  let req_body = {"BluemixApp": $bluemix_app, "Cmd": $cmd, "Cpuset": $cpuset, "Env": $body_env, "ExposedPorts": $exposed_ports, "HostConfig": $host_config, "Image": $image, "Memory": $memory, "NumberCpus": $number_cpus, "Volumes": $volumes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"name": $name} | compact), body: $req_body}
}

# List available public IP addresses in a space
#
# GET /containers/floating-ips
export def "containers-floating-ips get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # If this option is set to `all=1`, `all=True`, or `all=true`, all public IP addresses that are allocated to a space are returned. If this option is set to `all=0`, `all=False`, or `all=false`, only available public IP addresses that are allocated but not bound to a container are returned. By default, only available public IP addresses are returned.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> table<Bindings: record<ContainerId: string>, IpAddress: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/containers/floating-ips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"all": $all} | compact), body: null}
}

# Request a public IP address for a space
#
# POST /containers/floating-ips/request
export def "containers-floating-ips-request create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/containers/floating-ips/request")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Release public IP address
#
# POST /containers/floating-ips/{ip}/release
export def "containers-floating-ips-release create" [
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ip | is-empty) { error make --unspanned { msg: "path parameter 'ip' must be non-empty" } }
  let full_url = (build-url $base ({ip: (encode-path-segment $ip)} | format pattern "/containers/floating-ips/{ip}/release"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all container groups in a space
#
# GET /containers/groups
export def "containers-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> table<Creation_time: string, Id: string, Name: string, Port: int, Routes: list<string>, Status: string, Updated_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/containers/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create and start a container group.
#
# POST /containers/groups
# --NumberInstances shape: {Desired?: int, Max?: int, Min?: int}
# --Route shape: {domain?: string, host?: string}
export def "containers-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
  --autorecovery: string # (Optional) Enable the Auto-recovery mode for your container group. If set to true, IBM Containers checks the health of each instance with an HTTP request to the port that is assigned. If the health check does not receive a TCP response from a container instance in two subsequent 90-second intervals, the instance is removed and replaced with a new instance. If set to false and container instances crash, they are not recovered by IBM Containers.
  --bluemix-app: string # (Optional) The name of the Cloud Foundry app that you created in your organization space.
  --cmd: list<string> # (Optional) Docker command that is passed to the container group to be run when the container instances are started. This command must be a long-running command. Do not use a short-lived command, for example, /bin/date, because it might cause the container to crash.
  --body-env: list<string> # (Optional) List of environmental variables. Every environment variable that is listed here needs to be a key=value pair. Every key that you use needs to be unique for this container group. Multiple environment variables are separated with comma (,).
  image: string # (Required) The full path to your private Bluemix repository. If you want to use an image in your private Bluemix repository, specify the image in the following format: registry.ng.bluemix.net/NAMESPACE/IMAGE. If you want to use an IBM Containers provided image, do not include your organization's namespace. Specify the image in the following format: registry.ng.bluemix.net/IMAGE
  --memory: int # (Optional) The size of each container instance in the container group. The size of each container instance in the group. Choose one of the following sizes and enter the size in MegaBytes: Pico 64 MB, Nano 128 MB, Micro 256 MB, Tiny 512 MB, Small 1 GB (1024 MB), Medium 2 GB (2048 MB), Large 4 GB (4096 MB) XLarge 8GB (8192 MB) and 2XLarge 16 GB (16384 MB). If you do not specify a size, all container instances in this group are created with 256 MB. (format: int32)
  name: string # (Required) Name of the container group that you want to create. The name needs to be unique in your organization space and must start with a letter. Then, you can include uppercase letters, lowercase letters, numbers, periods (.), underscores (_), or hyphens (-).
  --number-instances: record # shape: {Desired?: int, Max?: int, Min?: int}
  --port: int # (Optional) Expose a port for HTTP traffic to make your container group available from the Internet. Every container instance that is started for this group, listens on this port. Container groups cannot expose multiple ports. Note: You need to expose a port, when "Autorecovery" is set to true. (format: int32)
  --route: record # shape: {domain?: string, host?: string}
  --volumes: list<string> # (Optional) List of volumes to be mounted to the container instances of your container group. You need to create the volume first by using the cf ic volume-create command before you can mount a volume to a container group. When you specify a volume, use the following format: NAME:PATH:MODE. For NAME, use either the name or ID of the volume. For the PATH, enter the absolute path to the volume directory in the container. For MODE, enter either ro (read-only) or rw (read-write).
]: any -> record<Id: string, Warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/containers/groups")
  let req_body = {"Autorecovery": $autorecovery, "BluemixApp": $bluemix_app, "Cmd": $cmd, "Env": $body_env, "Image": $image, "Memory": $memory, "Name": $name, "NumberInstances": $number_instances, "Port": $port, "Route": $route, "Volumes": $volumes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Stop and delete all container instances in a container group.
#
# DELETE /containers/groups/{name_or_id}
export def "containers-groups delete" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: string # If you want to force the deletion of a container group that has running container instances, use the force option. This parameter needs to be set to either true or false. If set to `force=true`, `force=True`, or `force=1`, running container instances are deleted. If set to `force=false`, `force=False`, or `force=0`, running container instances are not deleted. If you do not specify this paramater, running container instances are not deleted by default.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id)} | format pattern "/containers/groups/{name_or_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"force": $force} | compact), body: null}
}

# Inspect a container group.
#
# GET /containers/groups/{name_or_id}
export def "containers-groups get" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> record<Anti_affinity: string, Autorecovery: string, AvailabilityZone: string, Cmd: list<string>, Creation_time: string, Env: list<string>, Id: string, Image: string, ImageName: string, Memory: int, Name: string, NumberInstances: record<CurrentSize: int, Desired: int, Max: int, Min: int>, Port: int, Route_Status: record<in_progress: bool, message: string, successful: bool>, Routes: list<string>, Status: string, UpdatedTime: string, Volumes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id)} | format pattern "/containers/groups/{name_or_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a container group.
#
# PATCH /containers/groups/{name_or_id}
# --NumberInstances shape: {Desired?: int, Max?: int, Min?: int}
export def "containers-groups update" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
  --autorecovery: string # Enable or disable the Autorecovery mode for your container group. To enable it, enter true. If you want to disable it, enter false. Note: You can only enable/ disable Autorecovery mode if your container group was initially created with Autorecovery mode enabled.
  --environment: list<string> # A list of environment variables that you want to add to your container group. Every environment variable needs to be a key=value pair. Every key that you use needs to be unique for this container group. Multiple environment variables are separated with comma (,)
  --number-instances: record # shape: {Desired?: int, Max?: int, Min?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id)} | format pattern "/containers/groups/{name_or_id}"))
  let req_body = {"Autorecovery": $autorecovery, "Environment": $environment, "NumberInstances": $number_instances} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Map a public route to a container group.
#
# POST /containers/groups/{name_or_id}/maproute
export def "containers-groups-maproute create" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
  --domain: string # The default system domain is mybluemix.net and already provides a SSL certificate, so you can access your container groups with HTTPS without any additional configuration.
  --host: string # The host name of your container group, such as mycontainerhost. Do not include underscores (_) in the host name. The host and the domain combined form the full public route URL, such as http://mycontainerhost.mybluemix.net.
]: any -> record<Id: string, Warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id)} | format pattern "/containers/groups/{name_or_id}/maproute"))
  let req_body = {"domain": $domain, "host": $host} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Unmap a public route from a container group
#
# POST /containers/groups/{name_or_id}/unmaproute
export def "containers-groups-unmaproute create" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
  --domain: string # The default system domain is mybluemix.net and already provides a SSL certificate, so you can access your container groups with HTTPS without any additional configuration.
  --host: string # The host name of your container group, such as mycontainerhost. Do not include underscores (_) in the host name. The host and the domain combined form the full public route URL, such as http://mycontainerhost.mybluemix.net.
]: any -> record<Id: string, Warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id)} | format pattern "/containers/groups/{name_or_id}/unmaproute"))
  let req_body = {"domain": $domain, "host": $host} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List single containers in a space.
#
# GET /containers/json
export def "containers-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: string # By default, the `GET /containers/json` endpoint returns a list of all single containers in a space that are in a running state. To request a list of all containers independent of their current state, set the `all` query parameter to true. Allowed values are: `all=true`, `all=True`, and `all=1`.
  --filters: string # You can filter your containers by any environment variable key or value that is listed in the `Env` section of your CLI/ API response when you run the `cf ic inspect ` command, or call the `GET /containers/{id}/json` endpoint. Your search criteria does not need to be an exact match. It can also be a part of the key or value you are looking for. For example, to filter all containers with an environment variable that contains `id` in one of their environment variables, use `filter=id`.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> table<Command: string, ContainerState: string, Created: float, Env: list<string>, Group: record<Id: string, Name: string>, Id: string, Image: string, ImageId: string, Labels: record, Memory: int, Name: string, Names: list<string>, NetworkSettings: record<Bridge: string, Gateway: string, IpAddress: string, IpPrefixLen: int, MacAddress: string, Network: record, PortMapping: string, Ports: list, PublicIpAddress: string>, Ports: record<IP: string, PrivatePort: string, PublicPort: string, Type: string>, SizeRootFs: int, SizeRw: int, Started: float, Status: string, VCPU: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/containers/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"all": $all, "filters": $filters} | compact), body: null}
}

# List messages for the user
#
# GET /containers/messages
export def "containers-messages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. To retrieve your space ID, run `cf space <space_name> --guid` and replace `<space_name>` with the name of the space where you want to create or work with your container.
]: nothing -> record<created_date: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/containers/messages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve organization and space specific quota
#
# GET /containers/quota
export def "containers-quota get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> record<account_type: string, country_code: string, org_quota: record<floating_ips_max: string, floating_ips_space_default: string, floating_ips_usage: int, ram_max: int, ram_space_default: int, ram_usage: int, subnet_usage: int, subnets_default: int, subnets_max: int>, space_quota: record<floating_ips_max: string, ram_max: int, subnets_max: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/containers/quota")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update space quota
#
# PUT /containers/quota
export def "containers-quota update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
  --floating-ips: int # The new number of public IP addresses that you want to assign to your space. (format: int32)
  --ram: int # The amount of container memory that you want to assign to your space. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/containers/quota")
  let req_body = {"floating_ips": $floating_ips, "ram": $ram} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List container sizes and quota limits
#
# GET /containers/usage
export def "containers-usage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> record<AvailableSizes: table<disk: int, id: string, memory_MB: int, name: string, vcpus: int>, Environment: string, Limits: record<containers: int, floating_ips: int, memory_MB: int, vcpu: int>, Usage: record<containers: int, floating_ips: int, floating_ips_bound: int, images: int, memory_MB: int, running: int, vcpu: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/containers/usage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List latest API version
#
# GET /containers/version
export def "containers-version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ApiVersion: string, Arch: string, BuildDetail: record<api: string, automount: string, grupdater: string, harmony: string, health_monitor: string, hijack: string, ldap: string, logmet: string, lumberjack: string, redis_cluster: string, sgwatcher: string, volmgr: string>, BuildID: string, BuildNumber: string, BuildTime: string, GitCommit: string, GoVersion: string, KernelVersion: string, Os: string, Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/containers/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List the current state of a container.
#
# GET /containers/{id}/status
export def "containers-status get" [
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
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> record<NameOrId: string, Status: string, Transient: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/containers/{id}/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Remove a single container
#
# DELETE /containers/{name_or_id}
export def "containers delete" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Use the `force` query parameter if you want to delete the container independent of their current state. The container does not need to be stopped first. To force the deletion of a container, enter `force=true`, `force=True`, or `force=1`. If you want to delete containers that are in a non-running state only, do either not set this query parameter, or enter `force=false`, `force=False`, or `force=0`.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id)} | format pattern "/containers/{name_or_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"force": $force} | compact), body: null}
}

# Bind a public IP address to a single container
#
# POST /containers/{name_or_id}/floating-ips/{ip}/bind
export def "containers-floating-ips-bind create" [
  name_or_id: string
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  if ($ip | is-empty) { error make --unspanned { msg: "path parameter 'ip' must be non-empty" } }
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id), ip: (encode-path-segment $ip)} | format pattern "/containers/{name_or_id}/floating-ips/{ip}/bind"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Unbind a public IP address from a container
#
# POST /containers/{name_or_id}/floating-ips/{ip}/unbind
export def "containers-floating-ips-unbind create" [
  name_or_id: string
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  if ($ip | is-empty) { error make --unspanned { msg: "path parameter 'ip' must be non-empty" } }
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id), ip: (encode-path-segment $ip)} | format pattern "/containers/{name_or_id}/floating-ips/{ip}/unbind"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Inspect a single container
#
# GET /containers/{name_or_id}/json
export def "containers-json get" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> record<BluemixApp: string, BluemixServices: string, Config: record<ArgsEscaped: bool, AttachStderr: string, AttachStdin: string, AttachStdout: string, Cmd: list<string>, Domainname: string, Env: list<string>, ExposedPorts: list<string>, Hostname: string, Image: string, ImageArchitecture: string, Labels: list<string>, Memory: int, MemorySwap: string, OpenStdin: string, PortSpecs: string, StdinOnce: string, Tty: string, User: string, VCPU: int, VolumesFrom: string, WorkingDir: string>, ContainerState: string, Created: string, Group: record<Id: string, Name: string>, HostConfig: record<Binds: list<string>, ExtraHosts: list<string>, Links: list<string>, PortBindings: list<string>>, HostId: string, Human_Id: string, Id: string, Image: string, Mounts: list<string>, Name: string, NetworkSettings: record<Bridge: string, Gateway: string, IpAddress: string, IpPrefixLen: int, MacAddress: string, Network: record<Aliases: string, EndpointID: string, Gateway: string, GlobalIPv6Address: string, GlobalIPv6PrefixLen: int, IPAMConfig: string, IPPrefixLen: string, IPv6Gateway: string, Links: string, MacAddress: string, NetworkID: string>, PortMapping: string, Ports: list<string>, PublicIpAddress: string>, Path: string, ResolveConfPath: string, State: record<ExitCode: string, FinishedAt: string, Ghost: string, Pid: int, Running: bool, StartedAt: string, Status: string>, Volumes: record<fsID: string, hostPath: string, otherSpaceVisibility: list<string>, spaceGuid: string, volName: string>, VolumesRW: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id)} | format pattern "/containers/{name_or_id}/json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Pause a single container
#
# POST /containers/{name_or_id}/pause
export def "containers-pause create" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id)} | format pattern "/containers/{name_or_id}/pause"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Rename a single container
#
# POST /containers/{name_or_id}/rename
export def "containers-rename create" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name for the container. The characters in the name can include uppercase letters, lowercase letters, numbers, periods (.), underscores (_), or hyphens (-), but the name must start with a letter.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id)} | format pattern "/containers/{name_or_id}/rename") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name} | compact), body: null}
}

# Restart a single container
#
# POST /containers/{name_or_id}/restart
export def "containers-restart create" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t: int # The number of seconds to wait before the container is restarted. For example, if you want a container to restart after 10 seconds, enter `t=10`.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  let qp = [(serialize-qp "t" $t "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id)} | format pattern "/containers/{name_or_id}/restart") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"t": $t} | compact), body: null}
}

# Start a single container
#
# POST /containers/{name_or_id}/start
export def "containers-start create" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id)} | format pattern "/containers/{name_or_id}/start"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Stop a single container
#
# POST /containers/{name_or_id}/stop
export def "containers-stop create" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --t: int # The number of seconds to wait before the container is stopped. For example, if you want a container to stop after 10 seconds, enter `t=10`.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  let qp = [(serialize-qp "t" $t "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id)} | format pattern "/containers/{name_or_id}/stop") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"t": $t} | compact), body: null}
}

# Unpause a single container
#
# POST /containers/{name_or_id}/unpause
export def "containers-unpause create" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id)} | format pattern "/containers/{name_or_id}/unpause"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all Docker images that are available in your private Bluemix registry.
#
# GET /images/json
export def "images-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> record<Created: float, Id: string, Image: string, RepoTags: list<string>, Size: int, VirtualSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/images/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Remove a Docker image.
#
# DELETE /images/{id}
export def "images delete" [
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
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/images/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Inspect a Docker image in private Bluemix registry
#
# GET /images/{name_or_id}/json
export def "images-json get" [
  name_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> record<Architecture: string, Config: record<ArgsEscaped: bool, AttachStderr: bool, AttachStdin: bool, AttachStdout: bool, Cmd: list<string>, Domainmame: string, Entrypoint: string, Env: list<string>, ExposedPorts: list<string>, Hostname: string, Image: string, Labels: list<string>, OnBuild: list<string>, OpenStdin: bool, StdinOnce: bool, Tty: bool, User: string, Volumes: string, WorkingDir: string>, Container: string, ContainerConfig: record<ArgsEscaped: bool, AttachStderr: string, AttachStdin: string, AttachStdout: string, Cmd: list<string>, Domainname: string, Env: list<string>, ExposedPorts: list<string>, Hostname: string, Image: string, ImageArchitecture: string, Labels: list<string>, Memory: int, MemorySwap: string, OpenStdin: string, PortSpecs: string, StdinOnce: string, Tty: string, User: string, VCPU: int, VolumesFrom: string, WorkingDir: string>, Created: string, DockerVersion: string, Id: string, Os: string, Parent: string, Size: int, Tag: string, Throwaway: string, VirtualSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name_or_id | is-empty) { error make --unspanned { msg: "path parameter 'name_or_id' must be non-empty" } }
  let full_url = (build-url $base ({name_or_id: (encode-path-segment $name_or_id)} | format pattern "/images/{name_or_id}/json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve the namespace of an organization.
#
# GET /registry/namespaces
export def "registry-namespaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> record<namespace: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/registry/namespaces")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check the availability of a namespace
#
# GET /registry/namespaces/{namespace}
export def "registry-namespaces get" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> record<namespace: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/registry/namespaces/{namespace}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Set a namespace for your private Bluemix registry.
#
# PUT /registry/namespaces/{namespace}
export def "registry-namespaces update" [
  namespace: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> record<namespace: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/registry/namespaces/{namespace}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve the TLS Certificate
#
# GET /tlskey
export def "tlskey get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> record<ca_cert: string, server_cert: string, user_cert: string, user_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tlskey")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Refresh the TLS Certificate
#
# PUT /tlskey/refresh
export def "tlskey-refresh update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> record<ca_cert: string, reg_host: string, server_cert: string, user_cert: string, user_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tlskey/refresh")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a volume in a space
#
# POST /volumes/create
export def "volumes-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the volume. The name must be unique for a space and can contain uppercase letters, lowercase letters, numbers, underscores (_), and hyphens (-).
  --fs-name: string # The name of the file share that the volume is hosted on. File shares can have different storage sizes and IOPS based on the required workload. If this field is left blank, the volume is hosted on the default file share.
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> record<fsID: string, hostPath: string, otherSpaceVisibility: list<string>, spaceGuid: string, volName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "fsName" $fs_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/volumes/create" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "fsName": $fs_name} | compact), body: null}
}

# Create a file share in a space
#
# POST /volumes/fs/create
export def "volumes-fs-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
  fs_iops: float # The number of input/output transactions per second. Available values are 0.25, 2 or 4. (format: double)
  fs_name: string # The name of the new file share that you want to create. The name can contain uppercase letters, lowercase letters, numbers, underscores (_), and hyphens (-).
  fs_size: int # The size of the file share in gigabyte. Run `cf ic volume fs-flavor-list` or call the GET /volumes/fs/flavors/json API endpoint to retrieve a list of available file share sizes.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/volumes/fs/create")
  let req_body = {"fsIOPS": $fs_iops, "fsName": $fs_name, "fsSize": $fs_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List available file share sizes
#
# GET /volumes/fs/flavors/json
export def "volumes-fs-flavors-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/volumes/fs/flavors/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List available file shares in a space
#
# GET /volumes/fs/json
export def "volumes-fs-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> table<capacity: int, created_date: string, fsName: string, hostPath: string, iops: float, iopsTotal: int, orderId: string, provider: string, spaceGuid: string, state: string, updated_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/volumes/fs/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a file share
#
# DELETE /volumes/fs/{name}
export def "volumes-fs delete" [
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
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/volumes/fs/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Inspect a file share
#
# GET /volumes/fs/{name}/json
export def "volumes-fs-json get" [
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
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> table<fs: list<record>, fsUsage: list<record>, volnames: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/volumes/fs/{name}/json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all volumes for a space
#
# GET /volumes/json
export def "volumes-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> table<fsID: string, hostPath: string, otherSpaceVisibility: list<string>, spaceGuid: string, volName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/volumes/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a volume
#
# DELETE /volumes/{name}
export def "volumes delete" [
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
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/volumes/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Share a volume with another space
#
# POST /volumes/{name}
export def "volumes create" [
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
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
  --add-spaces: list<string> # The name or ID of the space where you want to provision your existing volume. Run `cf spaces` to retrieve the name, or `cf space <space_name> --guid` to retrieve the space ID.
  --remove-spaces: list<string> # The name or ID of the space from which you want to unprovision your existing volume. Run `cf spaces` to retrieve the name, or `cf space <space_name> --guid` to retrieve the space ID.
]: any -> record<fsID: string, hostPath: string, otherSpaceVisibility: list<string>, spaceGuid: string, volName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/volumes/{name}"))
  let req_body = {"addSpaces": $add_spaces, "removeSpaces": $remove_spaces} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve detailed information about a volume.
#
# GET /volumes/{name}/json
export def "volumes-json get" [
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
  --x-auth-token: string # The Bluemix JSON web token that you receive when logging into Bluemix. Run `cf oauth-token` to retrieve your access token.
  --x-auth-project-id: string # The unique ID of your organization space where you want to create or work with your containers. Run `cf space <space_name> --guid`, where `<space_name>` is the name of your space, to retrieve your space ID.
]: nothing -> record<fsID: string, hostPath: string, otherSpaceVisibility: list<string>, spaceGuid: string, volName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/volumes/{name}/json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Auth-Token": $x_auth_token, "X-Auth-Project-Id": $x_auth_project_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
