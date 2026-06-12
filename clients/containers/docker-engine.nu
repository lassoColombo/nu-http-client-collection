# Auto-generated client for Docker Engine API v1.33
# Source: https://api.apis.guru/v2/specs/docker.com/engine/1.33/openapi.json
# Auth: --token flag or $env.DOCKER_ENGINE_API_TOKEN

const BASE_URL = "http://localhost/v1.33"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DOCKER_ENGINE_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost/v1.33" "https://docker.com/1.33"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def Content-type-completer [] { ["application/x-tar"] }
def accept-completer [] { ["application/json" "text/plain"] }
def Availability-completer [] { ["active" "drain" "pause"] }
def Role-completer [] { ["manager" "worker"] }
def accept-completer-1 [] { ["application/json" "application/vnd.docker.raw-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "ping SystemPing" } } | get name | first)
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

# Ping
#
# GET /_ping
# operationId: SystemPing
export def "ping SystemPing" [
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
  let full_url = (build-url $base "/_ping")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check auth configuration
#
# POST /auth
# operationId: SystemAuth
export def "auth SystemAuth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --password: string
  --serveraddress: string
  --username: string
]: any -> record<IdentityToken: string, Status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth")
  let body = {email: $email, password: $password, serveraddress: $serveraddress, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Build an image
#
# POST /build
# operationId: ImageBuild
export def "build ImageBuild" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dockerfile: string # Path within the build context to the `Dockerfile`. This is ignored if `remote` is specified and points to an external `Dockerfile`. (default: Dockerfile)
  --t: string # A name and optional tag to apply to the image in the `name:tag` format. If you omit the tag the default `latest` value is assumed. You can provide several `t` parameters.
  --extrahosts: string # Extra hosts to add to /etc/hosts
  --remote: string # A Git repository URI or HTTP/HTTPS context URI. If the URI points to a single text file, the file’s contents are placed into a file called `Dockerfile` and the image is built from that file. If the URI points to a tarball, the file is downloaded by the daemon and the contents therein used as the context for the build. If the URI points to a tarball and the `dockerfile` parameter is also specified, there must be a file with the corresponding path inside the tarball.
  --q: oneof<nothing, bool> # Suppress verbose build output. (default: false)
  --nocache: oneof<nothing, bool> # Do not use the cache when building the image. (default: false)
  --cachefrom: string # JSON array of images used for build cache resolution.
  --pull: string # Attempt to pull the image even if an older image exists locally.
  --rm: oneof<nothing, bool> # Remove intermediate containers after a successful build. (default: true)
  --forcerm: oneof<nothing, bool> # Always remove intermediate containers, even upon failure. (default: false)
  --memory: int # Set memory limit for build.
  --memswap: int # Total memory (memory + swap). Set as `-1` to disable swap.
  --cpushares: int # CPU shares (relative weight).
  --cpusetcpus: string # CPUs in which to allow execution (e.g., `0-3`, `0,1`).
  --cpuperiod: int # The length of a CPU period in microseconds.
  --cpuquota: int # Microseconds of CPU time that the container can get in a CPU period.
  --buildargs: int # JSON map of string pairs for build-time variables. Users pass these values at build-time. Docker uses the buildargs as the environment context for commands run via the `Dockerfile` RUN instruction, or for variable expansion in other `Dockerfile` instructions. This is not meant for passing secret values. [Read more about the buildargs instruction.](https://docs.docker.com/engine/reference/builder/#arg)
  --shmsize: int # Size of `/dev/shm` in bytes. The size must be greater than 0. If omitted the system uses 64MB.
  --squash: oneof<nothing, bool> # Squash the resulting images layers into a single layer. *(Experimental release only.)*
  --labels: string # Arbitrary key/value labels to set on the image, as a JSON map of string pairs.
  --networkmode: string # Sets the networking mode for the run commands during build. Supported standard values are: `bridge`, `host`, `none`, and `container:<name|id>`. Any other value is taken as a custom network's name to which this container should connect to.
  --Content-type: string@Content-type-completer
  --X-Registry-Config: string # This is a base64-encoded JSON object with auth configurations for multiple registries that a build may refer to.  The key is a registry URL, and the value is an auth configuration object, [as described in the authentication section](#section/Authentication). For example:  ``` {   "docker.example.com": {     "username": "janedoe",     "password": "hunter2"   },   "https://index.docker.io/v1/": {     "username": "mobydock",     "password": "conta1n3rize14"   } } ```  Only the registry domain name (and port if not the default 443) are required. However, for legacy reasons, the Docker Hub registry must be specified with both a `https://` prefix and a `/v1/` suffix even though Docker will prefer to use the v2 registry API.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dockerfile" $dockerfile "scalar") (serialize-qp "t" $t "scalar") (serialize-qp "extrahosts" $extrahosts "scalar") (serialize-qp "remote" $remote "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "nocache" $nocache "scalar") (serialize-qp "cachefrom" $cachefrom "scalar") (serialize-qp "pull" $pull "scalar") (serialize-qp "rm" $rm "scalar") (serialize-qp "forcerm" $forcerm "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "memswap" $memswap "scalar") (serialize-qp "cpushares" $cpushares "scalar") (serialize-qp "cpusetcpus" $cpusetcpus "scalar") (serialize-qp "cpuperiod" $cpuperiod "scalar") (serialize-qp "cpuquota" $cpuquota "scalar") (serialize-qp "buildargs" $buildargs "scalar") (serialize-qp "shmsize" $shmsize "scalar") (serialize-qp "squash" $squash "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "networkmode" $networkmode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/build" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-type": $Content_type, "X-Registry-Config": $X_Registry_Config} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Delete builder cache
#
# POST /build/prune
# operationId: BuildPrune
export def "build-prune BuildPrune" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<SpaceReclaimed: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/build/prune")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new image from a container
#
# POST /commit
# operationId: ImageCommit
# --Healthcheck shape: {Interval?: int, Retries?: int, StartPeriod?: int, Test?: list, Timeout?: int}
# --Volumes shape: {additionalProperties?: "{}"}
export def "commit ImageCommit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --container: string # The ID or name of the container to commit
  --repo: string # Repository name for the created image
  --tag: string # Tag name for the create image
  --comment: string # Commit message
  --author: string # Author of the image (e.g., `John Hannibal Smith <hannibal@a-team.com>`)
  --pause: oneof<nothing, bool> # Whether to pause the container before committing (default: true)
  --changes: string # `Dockerfile` instructions to apply while committing
  --ArgsEscaped: oneof<nothing, bool> # Command is already escaped (Windows only)
  --AttachStderr: oneof<nothing, bool> # Whether to attach to `stderr`. (default: true)
  --AttachStdin: oneof<nothing, bool> # Whether to attach to `stdin`. (default: false)
  --AttachStdout: oneof<nothing, bool> # Whether to attach to `stdout`. (default: true)
  --Cmd: any # Command to run specified as a string or an array of strings.
  --Domainname: string # The domain name to use for the container.
  --Entrypoint: any # The entry point for the container as a string or an array of strings.  If the array consists of exactly one empty string (`[""]`) then the entry point is reset to system default (i.e., the entry point used by docker when there is no `ENTRYPOINT` instruction in the `Dockerfile`).
  --Env: list # A list of environment variables to set inside the container in the form `["VAR=value", ...]`. A variable without `=` is removed from the environment, rather than to have an empty value.
  --ExposedPorts: record # An object mapping ports to an empty object in the form:  `{"<port>/<tcp|udp>": {}}`
  --Healthcheck: record # A test to perform to check that the container is healthy. — shape: {Interval?: int, Retries?: int, StartPeriod?: int, Test?: list, Timeout?: int}
  --Hostname: string # The hostname to use for the container, as a valid RFC 1123 hostname.
  --Image: string # The name of the image to use when creating the container
  --Labels: record # User-defined key/value metadata.
  --MacAddress: string # MAC address of the container.
  --NetworkDisabled: oneof<nothing, bool> # Disable networking for the container.
  --OnBuild: list # `ONBUILD` metadata that were defined in the image's `Dockerfile`.
  --OpenStdin: oneof<nothing, bool> # Open `stdin` (default: false)
  --Shell: list # Shell for when `RUN`, `CMD`, and `ENTRYPOINT` uses a shell.
  --StdinOnce: oneof<nothing, bool> # Close `stdin` after one attached client disconnects (default: false)
  --StopSignal: string # Signal to stop a container as a string or unsigned integer. (default: SIGTERM)
  --StopTimeout: int # Timeout to stop a container in seconds. (default: 10)
  --Tty: oneof<nothing, bool> # Attach standard streams to a TTY, including `stdin` if it is not closed. (default: false)
  --User: string # The user that commands are run as inside the container.
  --Volumes: record # An object mapping mount point paths inside the container to empty objects. — shape: {additionalProperties?: "{}"}
  --WorkingDir: string # The working directory for commands to run in.
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "container" $container "scalar") (serialize-qp "repo" $repo "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "comment" $comment "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "pause" $pause "scalar") (serialize-qp "changes" $changes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commit" $qp)
  let body = {ArgsEscaped: $ArgsEscaped, AttachStderr: $AttachStderr, AttachStdin: $AttachStdin, AttachStdout: $AttachStdout, Cmd: $Cmd, Domainname: $Domainname, Entrypoint: $Entrypoint, Env: $Env, ExposedPorts: $ExposedPorts, Healthcheck: $Healthcheck, Hostname: $Hostname, Image: $Image, Labels: $Labels, MacAddress: $MacAddress, NetworkDisabled: $NetworkDisabled, OnBuild: $OnBuild, OpenStdin: $OpenStdin, Shell: $Shell, StdinOnce: $StdinOnce, StopSignal: $StopSignal, StopTimeout: $StopTimeout, Tty: $Tty, User: $User, Volumes: $Volumes, WorkingDir: $WorkingDir} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List configs
#
# GET /configs
# operationId: ConfigList
export def "configs ConfigList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the configs list. Available filters:  - `id=<config id>` - `label=<key> or label=<key>=value` - `name=<config name>` - `names=<config name>`
]: nothing -> table<CreatedAt: string, ID: string, Spec: record<Data: string, Labels: record, Name: string>, UpdatedAt: string, Version: record<Index: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/configs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a config
#
# POST /configs/create
# operationId: ConfigCreate
export def "configs-create ConfigCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Data: string # Base64-url-safe-encoded ([RFC 4648](https://tools.ietf.org/html/rfc4648#section-3.2)) config data.
  --Labels: record # User-defined key/value metadata.
  --Name: string # User-defined name of the config.
]: any -> record<ID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configs/create")
  let body = {Data: $Data, Labels: $Labels, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a config
#
# DELETE /configs/{id}
# operationId: ConfigDelete
export def "configs ConfigDelete" [
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
  let full_url = (build-url $base $"/configs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inspect a config
#
# GET /configs/{id}
# operationId: ConfigInspect
export def "configs ConfigInspect" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<CreatedAt: string, ID: string, Spec: record<Data: string, Labels: record, Name: string>, UpdatedAt: string, Version: record<Index: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/configs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Config
#
# POST /configs/{id}/update
# operationId: ConfigUpdate
export def "configs-update ConfigUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # The version number of the config object being updated. This is required to avoid conflicting writes. (format: int64)
  --Data: string # Base64-url-safe-encoded ([RFC 4648](https://tools.ietf.org/html/rfc4648#section-3.2)) config data.
  --Labels: record # User-defined key/value metadata.
  --Name: string # User-defined name of the config.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($id)/update" $qp)
  let body = {Data: $Data, Labels: $Labels, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a container
#
# POST /containers/create
# operationId: ContainerCreate
# --Healthcheck shape: {Interval?: int, Retries?: int, StartPeriod?: int, Test?: list, Timeout?: int}
# --Volumes shape: {additionalProperties?: "{}"}
# --NetworkingConfig shape: {EndpointsConfig?: record}
export def "containers-create ContainerCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Assign the specified name to the container. Must match `/?[a-zA-Z0-9_-]+`.
  --ArgsEscaped: oneof<nothing, bool> # Command is already escaped (Windows only)
  --AttachStderr: oneof<nothing, bool> # Whether to attach to `stderr`. (default: true)
  --AttachStdin: oneof<nothing, bool> # Whether to attach to `stdin`. (default: false)
  --AttachStdout: oneof<nothing, bool> # Whether to attach to `stdout`. (default: true)
  --Cmd: any # Command to run specified as a string or an array of strings.
  --Domainname: string # The domain name to use for the container.
  --Entrypoint: any # The entry point for the container as a string or an array of strings.  If the array consists of exactly one empty string (`[""]`) then the entry point is reset to system default (i.e., the entry point used by docker when there is no `ENTRYPOINT` instruction in the `Dockerfile`).
  --Env: list # A list of environment variables to set inside the container in the form `["VAR=value", ...]`. A variable without `=` is removed from the environment, rather than to have an empty value.
  --ExposedPorts: record # An object mapping ports to an empty object in the form:  `{"<port>/<tcp|udp>": {}}`
  --Healthcheck: record # A test to perform to check that the container is healthy. — shape: {Interval?: int, Retries?: int, StartPeriod?: int, Test?: list, Timeout?: int}
  --Hostname: string # The hostname to use for the container, as a valid RFC 1123 hostname.
  --Image: string # The name of the image to use when creating the container
  --Labels: record # User-defined key/value metadata.
  --MacAddress: string # MAC address of the container.
  --NetworkDisabled: oneof<nothing, bool> # Disable networking for the container.
  --OnBuild: list # `ONBUILD` metadata that were defined in the image's `Dockerfile`.
  --OpenStdin: oneof<nothing, bool> # Open `stdin` (default: false)
  --Shell: list # Shell for when `RUN`, `CMD`, and `ENTRYPOINT` uses a shell.
  --StdinOnce: oneof<nothing, bool> # Close `stdin` after one attached client disconnects (default: false)
  --StopSignal: string # Signal to stop a container as a string or unsigned integer. (default: SIGTERM)
  --StopTimeout: int # Timeout to stop a container in seconds. (default: 10)
  --Tty: oneof<nothing, bool> # Attach standard streams to a TTY, including `stdin` if it is not closed. (default: false)
  --User: string # The user that commands are run as inside the container.
  --Volumes: record # An object mapping mount point paths inside the container to empty objects. — shape: {additionalProperties?: "{}"}
  --WorkingDir: string # The working directory for commands to run in.
  --HostConfig: any # Container configuration that depends on the host we are running on
  --NetworkingConfig: record # This container's networking configuration. — shape: {EndpointsConfig?: record}
]: any -> record<Id: string, Warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/containers/create" $qp)
  let body = {ArgsEscaped: $ArgsEscaped, AttachStderr: $AttachStderr, AttachStdin: $AttachStdin, AttachStdout: $AttachStdout, Cmd: $Cmd, Domainname: $Domainname, Entrypoint: $Entrypoint, Env: $Env, ExposedPorts: $ExposedPorts, Healthcheck: $Healthcheck, Hostname: $Hostname, Image: $Image, Labels: $Labels, MacAddress: $MacAddress, NetworkDisabled: $NetworkDisabled, OnBuild: $OnBuild, OpenStdin: $OpenStdin, Shell: $Shell, StdinOnce: $StdinOnce, StopSignal: $StopSignal, StopTimeout: $StopTimeout, Tty: $Tty, User: $User, Volumes: $Volumes, WorkingDir: $WorkingDir, HostConfig: $HostConfig, NetworkingConfig: $NetworkingConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List containers
#
# GET /containers/json
# operationId: ContainerList
export def "containers-json ContainerList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Return all containers. By default, only running containers are shown (default: false)
  --limit: int # Return this number of most recently created containers, including non-running ones.
  --size: oneof<nothing, bool> # Return the size of container as fields `SizeRw` and `SizeRootFs`. (default: false)
  --filters: string # Filters to process on the container list, encoded as JSON (a `map[string][]string`). For example, `{"status": ["paused"]}` will only return paused containers. Available filters:  - `ancestor`=(`<image-name>[:<tag>]`, `<image id>`, or `<image@digest>`) - `before`=(`<container id>` or `<container name>`) - `expose`=(`<port>[/<proto>]`|`<startport-endport>/[<proto>]`) - `exited=<int>` containers with exit code of `<int>` - `health`=(`starting`|`healthy`|`unhealthy`|`none`) - `id=<ID>` a container's ID - `isolation=`(`default`|`process`|`hyperv`) (Windows daemon only) - `is-task=`(`true`|`false`) - `label=key` or `label="key=value"` of a container label - `name=<name>` a container's name - `network`=(`<network id>` or `<network name>`) - `publish`=(`<port>[/<proto>]`|`<startport-endport>/[<proto>]`) - `since`=(`<container id>` or `<container name>`) - `status=`(`created`|`restarting`|`running`|`removing`|`paused`|`exited`|`dead`) - `volume`=(`<volume name>` or `<mount point destination>`)
]: nothing -> table<Command: string, Created: int, HostConfig: record<NetworkMode: string>, Id: string, Image: string, ImageID: string, Labels: record, Mounts: list<record>, Names: list<string>, NetworkSettings: record<Networks: record>, Ports: list<record>, SizeRootFs: int, SizeRw: int, State: string, Status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/containers/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete stopped containers
#
# POST /containers/prune
# operationId: ContainerPrune
export def "containers-prune ContainerPrune" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # Filters to process on the prune list, encoded as JSON (a `map[string][]string`).  Available filters: - `until=<timestamp>` Prune containers created before this timestamp. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time. - `label` (`label=<key>`, `label=<key>=<value>`, `label!=<key>`, or `label!=<key>=<value>`) Prune containers with (or without, in case `label!=...` is used) the specified labels.
]: nothing -> record<ContainersDeleted: list<string>, SpaceReclaimed: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/containers/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a container
#
# DELETE /containers/{id}
# operationId: ContainerDelete
export def "containers ContainerDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --v: oneof<nothing, bool> # Remove the volumes associated with the container. (default: false)
  --force: oneof<nothing, bool> # If the container is running, kill it before removing it. (default: false)
  --link: oneof<nothing, bool> # Remove the specified link associated with the container. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "v" $v "scalar") (serialize-qp "force" $force "scalar") (serialize-qp "link" $link "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an archive of a filesystem resource in a container
#
# GET /containers/{id}/archive
# operationId: ContainerArchive
export def "containers-archive ContainerArchive" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # Resource in the container’s filesystem to archive.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/archive" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about files in a container
#
# HEAD /containers/{id}/archive
# operationId: ContainerArchiveInfo
export def "containers-archive ContainerArchiveInfo" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # Resource in the container’s filesystem to archive.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/archive" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Extract an archive of files or folders to a directory in a container
#
# PUT /containers/{id}/archive
# operationId: PutContainerArchive
export def "containers-archive PutContainerArchive" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # Path to a directory in the container to extract the archive’s contents into. 
  --noOverwriteDirNonDir: string # If “1”, “true”, or “True” then it will be an error if unpacking the given content would cause an existing directory to be replaced with a non-directory and vice versa.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "noOverwriteDirNonDir" $noOverwriteDirNonDir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/archive" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Attach to a container
#
# POST /containers/{id}/attach
# operationId: ContainerAttach
export def "containers-attach ContainerAttach" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --detachKeys: string # Override the key sequence for detaching a container.Format is a single character `[a-Z]` or `ctrl-<value>` where `<value>` is one of: `a-z`, `@`, `^`, `[`, `,` or `_`.
  --logs: oneof<nothing, bool> # Replay previous logs from the container.  This is useful for attaching to a container that has started and you want to output everything since the container started.  If `stream` is also enabled, once all the previous output has been returned, it will seamlessly transition into streaming current output.  (default: false)
  --stream: oneof<nothing, bool> # Stream attached streams from the time the request was made onwards (default: false)
  --stdin: oneof<nothing, bool> # Attach to `stdin` (default: false)
  --stdout: oneof<nothing, bool> # Attach to `stdout` (default: false)
  --stderr: oneof<nothing, bool> # Attach to `stderr` (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detachKeys" $detachKeys "scalar") (serialize-qp "logs" $logs "scalar") (serialize-qp "stream" $stream "scalar") (serialize-qp "stdin" $stdin "scalar") (serialize-qp "stdout" $stdout "scalar") (serialize-qp "stderr" $stderr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/attach" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attach to a container via a websocket
#
# GET /containers/{id}/attach/ws
# operationId: ContainerAttachWebsocket
export def "containers-attach-ws ContainerAttachWebsocket" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --detachKeys: string # Override the key sequence for detaching a container.Format is a single character `[a-Z]` or `ctrl-<value>` where `<value>` is one of: `a-z`, `@`, `^`, `[`, `,`, or `_`.
  --logs: oneof<nothing, bool> # Return logs (default: false)
  --stream: oneof<nothing, bool> # Return stream (default: false)
  --stdin: oneof<nothing, bool> # Attach to `stdin` (default: false)
  --stdout: oneof<nothing, bool> # Attach to `stdout` (default: false)
  --stderr: oneof<nothing, bool> # Attach to `stderr` (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detachKeys" $detachKeys "scalar") (serialize-qp "logs" $logs "scalar") (serialize-qp "stream" $stream "scalar") (serialize-qp "stdin" $stdin "scalar") (serialize-qp "stdout" $stdout "scalar") (serialize-qp "stderr" $stderr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/attach/ws" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get changes on a container’s filesystem
#
# GET /containers/{id}/changes
# operationId: ContainerChanges
export def "containers-changes ContainerChanges" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Kind: int, Path: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($id)/changes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an exec instance
#
# POST /containers/{id}/exec
# operationId: ContainerExec
export def "containers-exec ContainerExec" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AttachStderr: oneof<nothing, bool> # Attach to `stderr` of the exec command.
  --AttachStdin: oneof<nothing, bool> # Attach to `stdin` of the exec command.
  --AttachStdout: oneof<nothing, bool> # Attach to `stdout` of the exec command.
  --Cmd: list # Command to run, as a string or array of strings.
  --DetachKeys: string # Override the key sequence for detaching a container. Format is a single character `[a-Z]` or `ctrl-<value>` where `<value>` is one of: `a-z`, `@`, `^`, `[`, `,` or `_`.
  --Env: list # A list of environment variables in the form `["VAR=value", ...]`.
  --Privileged: oneof<nothing, bool> # Runs the exec process with extended privileges. (default: false)
  --Tty: oneof<nothing, bool> # Allocate a pseudo-TTY.
  --User: string # The user, and optionally, group to run the exec process inside the container. Format is one of: `user`, `user:group`, `uid`, or `uid:gid`.
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($id)/exec")
  let body = {AttachStderr: $AttachStderr, AttachStdin: $AttachStdin, AttachStdout: $AttachStdout, Cmd: $Cmd, DetachKeys: $DetachKeys, Env: $Env, Privileged: $Privileged, Tty: $Tty, User: $User} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Export a container
#
# GET /containers/{id}/export
# operationId: ContainerExport
export def "containers-export ContainerExport" [
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
  let full_url = (build-url $base $"/containers/($id)/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inspect a container
#
# GET /containers/{id}/json
# operationId: ContainerInspect
export def "containers-json ContainerInspect" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --size: oneof<nothing, bool> # Return the size of container as fields `SizeRw` and `SizeRootFs` (default: false)
]: nothing -> record<AppArmorProfile: string, Args: list<string>, Config: record<ArgsEscaped: bool, AttachStderr: bool, AttachStdin: bool, AttachStdout: bool, Cmd: list<string>, Domainname: string, Entrypoint: list<string>, Env: list<string>, ExposedPorts: record, Healthcheck: record<Interval: int, Retries: int, StartPeriod: int, Test: list, Timeout: int>, Hostname: string, Image: string, Labels: record, MacAddress: string, NetworkDisabled: bool, OnBuild: list<string>, OpenStdin: bool, Shell: list<string>, StdinOnce: bool, StopSignal: string, StopTimeout: int, Tty: bool, User: string, Volumes: record<additionalProperties: record>, WorkingDir: string>, Created: string, Driver: string, ExecIDs: string, GraphDriver: record<Data: record, Name: string>, HostConfig: record<BlkioDeviceReadBps: list<record>, BlkioDeviceReadIOps: list<record>, BlkioDeviceWriteBps: list<record>, BlkioDeviceWriteIOps: list<record>, BlkioWeight: int, BlkioWeightDevice: list<record>, CgroupParent: string, CpuCount: int, CpuPercent: int, CpuPeriod: int, CpuQuota: int, CpuRealtimePeriod: int, CpuRealtimeRuntime: int, CpuShares: int, CpusetCpus: string, CpusetMems: string, DeviceCgroupRules: list<string>, Devices: list<record>, DiskQuota: int, IOMaximumBandwidth: int, IOMaximumIOps: int, KernelMemory: int, Memory: int, MemoryReservation: int, MemorySwap: int, MemorySwappiness: int, NanoCPUs: int, OomKillDisable: bool, PidsLimit: int, Ulimits: list<record>, AutoRemove: bool, Binds: list<string>, CapAdd: list<string>, CapDrop: list<string>, Cgroup: string, ConsoleSize: list<int>, ContainerIDFile: string, Dns: list<string>, DnsOptions: list<string>, DnsSearch: list<string>, ExtraHosts: list<string>, GroupAdd: list<string>, IpcMode: string, Isolation: string, Links: list<string>, LogConfig: record<Config: record, Type: string>, Mounts: list<record>, NetworkMode: string, OomScoreAdj: int, PidMode: string, PortBindings: record, Privileged: bool, PublishAllPorts: bool, ReadonlyRootfs: bool, RestartPolicy: record<MaximumRetryCount: int, Name: string>, Runtime: string, SecurityOpt: list<string>, ShmSize: int, StorageOpt: record, Sysctls: record, Tmpfs: record, UTSMode: string, UsernsMode: string, VolumeDriver: string, VolumesFrom: list<string>>, HostnamePath: string, HostsPath: string, Id: string, Image: string, LogPath: string, MountLabel: string, Mounts: table<Destination: string, Driver: string, Mode: string, Name: string, Propagation: string, RW: bool, Source: string, Type: string>, Name: string, NetworkSettings: record<Bridge: string, EndpointID: string, Gateway: string, GlobalIPv6Address: string, GlobalIPv6PrefixLen: int, HairpinMode: bool, IPAddress: string, IPPrefixLen: int, IPv6Gateway: string, LinkLocalIPv6Address: string, LinkLocalIPv6PrefixLen: int, MacAddress: string, Networks: record, Ports: record, SandboxID: string, SandboxKey: string, SecondaryIPAddresses: list<record>, SecondaryIPv6Addresses: list<record>>, Node: record, Path: string, ProcessLabel: string, ResolvConfPath: string, RestartCount: int, SizeRootFs: int, SizeRw: int, State: record<Dead: bool, Error: string, ExitCode: int, FinishedAt: string, OOMKilled: bool, Paused: bool, Pid: int, Restarting: bool, Running: bool, StartedAt: string, Status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Kill a container
#
# POST /containers/{id}/kill
# operationId: ContainerKill
export def "containers-kill ContainerKill" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --signal: string # Signal to send to the container as an integer or string (e.g. `SIGINT`) (default: SIGKILL)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signal" $signal "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/kill" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get container logs
#
# GET /containers/{id}/logs
# operationId: ContainerLogs
export def "containers-logs ContainerLogs" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --follow: oneof<nothing, bool> # Return the logs as a stream.  This will return a `101` HTTP response with a `Connection: upgrade` header, then hijack the HTTP connection to send raw output. For more information about hijacking and the stream format, [see the documentation for the attach endpoint](#operation/ContainerAttach).  (default: false)
  --stdout: oneof<nothing, bool> # Return logs from `stdout` (default: false)
  --stderr: oneof<nothing, bool> # Return logs from `stderr` (default: false)
  --since: int # Only return logs since this time, as a UNIX timestamp (default: 0)
  --timestamps: oneof<nothing, bool> # Add timestamps to every log line (default: false)
  --tail: string # Only return this number of log lines from the end of the logs. Specify as an integer or `all` to output all log lines. (default: all)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "follow" $follow "scalar") (serialize-qp "stdout" $stdout "scalar") (serialize-qp "stderr" $stderr "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "timestamps" $timestamps "scalar") (serialize-qp "tail" $tail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/logs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pause a container
#
# POST /containers/{id}/pause
# operationId: ContainerPause
export def "containers-pause ContainerPause" [
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
  let full_url = (build-url $base $"/containers/($id)/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rename a container
#
# POST /containers/{id}/rename
# operationId: ContainerRename
export def "containers-rename ContainerRename" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # New name for the container
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/rename" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resize a container TTY
#
# POST /containers/{id}/resize
# operationId: ContainerResize
export def "containers-resize ContainerResize" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --h: int # Height of the tty session in characters
  --w: int # Width of the tty session in characters
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "h" $h "scalar") (serialize-qp "w" $w "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/resize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restart a container
#
# POST /containers/{id}/restart
# operationId: ContainerRestart
export def "containers-restart ContainerRestart" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t: int # Number of seconds to wait before killing the container
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t" $t "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/restart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start a container
#
# POST /containers/{id}/start
# operationId: ContainerStart
export def "containers-start ContainerStart" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --detachKeys: string # Override the key sequence for detaching a container. Format is a single character `[a-Z]` or `ctrl-<value>` where `<value>` is one of: `a-z`, `@`, `^`, `[`, `,` or `_`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detachKeys" $detachKeys "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get container stats based on resource usage
#
# GET /containers/{id}/stats
# operationId: ContainerStats
export def "containers-stats ContainerStats" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stream: oneof<nothing, bool> # Stream the output. If false, the stats will be output once and then it will disconnect. (default: true)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stream" $stream "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop a container
#
# POST /containers/{id}/stop
# operationId: ContainerStop
export def "containers-stop ContainerStop" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --t: int # Number of seconds to wait before killing the container
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t" $t "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List processes running inside a container
#
# GET /containers/{id}/top
# operationId: ContainerTop
export def "containers-top ContainerTop" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ps-args: string # The arguments to pass to `ps`. For example, `aux` (default: -ef)
]: nothing -> record<Processes: list<list<string>>, Titles: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ps_args" $ps_args "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/top" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unpause a container
#
# POST /containers/{id}/unpause
# operationId: ContainerUnpause
export def "containers-unpause ContainerUnpause" [
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
  let full_url = (build-url $base $"/containers/($id)/unpause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a container
#
# POST /containers/{id}/update
# operationId: ContainerUpdate
# --BlkioDeviceReadBps item shape: {Path?: string, Rate?: int}
# --BlkioDeviceReadIOps item shape: {Path?: string, Rate?: int}
# --BlkioDeviceWriteBps item shape: {Path?: string, Rate?: int}
# --BlkioDeviceWriteIOps item shape: {Path?: string, Rate?: int}
# --BlkioWeightDevice item shape: {Path?: string, Weight?: int}
# --Devices item shape: {CgroupPermissions?: string, PathInContainer?: string, PathOnHost?: string}
# --Ulimits item shape: {Hard?: int, Name?: string, Soft?: int}
# --RestartPolicy shape: {MaximumRetryCount?: int, Name?: ""|"always"|"unless-stopped"|"on-failure"}
export def "containers-update ContainerUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --BlkioDeviceReadBps: list # Limit read rate (bytes per second) from a device, in the form `[{"Path": "device_path", "Rate": rate}]`. — item shape: {Path?: string, Rate?: int}
  --BlkioDeviceReadIOps: list # Limit read rate (IO per second) from a device, in the form `[{"Path": "device_path", "Rate": rate}]`. — item shape: {Path?: string, Rate?: int}
  --BlkioDeviceWriteBps: list # Limit write rate (bytes per second) to a device, in the form `[{"Path": "device_path", "Rate": rate}]`. — item shape: {Path?: string, Rate?: int}
  --BlkioDeviceWriteIOps: list # Limit write rate (IO per second) to a device, in the form `[{"Path": "device_path", "Rate": rate}]`. — item shape: {Path?: string, Rate?: int}
  --BlkioWeight: int # Block IO weight (relative weight).
  --BlkioWeightDevice: list # Block IO weight (relative device weight) in the form `[{"Path": "device_path", "Weight": weight}]`. — item shape: {Path?: string, Weight?: int}
  --CgroupParent: string # Path to `cgroups` under which the container's `cgroup` is created. If the path is not absolute, the path is considered to be relative to the `cgroups` path of the init process. Cgroups are created if they do not already exist.
  --CpuCount: int # The number of usable CPUs (Windows only).  On Windows Server containers, the processor resource controls are mutually exclusive. The order of precedence is `CPUCount` first, then `CPUShares`, and `CPUPercent` last.  (format: int64)
  --CpuPercent: int # The usable percentage of the available CPUs (Windows only).  On Windows Server containers, the processor resource controls are mutually exclusive. The order of precedence is `CPUCount` first, then `CPUShares`, and `CPUPercent` last.  (format: int64)
  --CpuPeriod: int # The length of a CPU period in microseconds. (format: int64)
  --CpuQuota: int # Microseconds of CPU time that the container can get in a CPU period. (format: int64)
  --CpuRealtimePeriod: int # The length of a CPU real-time period in microseconds. Set to 0 to allocate no time allocated to real-time tasks. (format: int64)
  --CpuRealtimeRuntime: int # The length of a CPU real-time runtime in microseconds. Set to 0 to allocate no time allocated to real-time tasks. (format: int64)
  --CpuShares: int # An integer value representing this container's relative CPU weight versus other containers.
  --CpusetCpus: string # CPUs in which to allow execution (e.g., `0-3`, `0,1`) (e.g. 0-3)
  --CpusetMems: string # Memory nodes (MEMs) in which to allow execution (0-3, 0,1). Only effective on NUMA systems.
  --DeviceCgroupRules: list # a list of cgroup rules to apply to the container
  --Devices: list # A list of devices to add to the container. — item shape: {CgroupPermissions?: string, PathInContainer?: string, PathOnHost?: string}
  --DiskQuota: int # Disk limit (in bytes). (format: int64)
  --IOMaximumBandwidth: int # Maximum IO in bytes per second for the container system drive (Windows only) (format: int64)
  --IOMaximumIOps: int # Maximum IOps for the container system drive (Windows only) (format: int64)
  --KernelMemory: int # Kernel memory limit in bytes. (format: int64)
  --Memory: int # Memory limit in bytes. (default: 0)
  --MemoryReservation: int # Memory soft limit in bytes. (format: int64)
  --MemorySwap: int # Total memory limit (memory + swap). Set as `-1` to enable unlimited swap. (format: int64)
  --MemorySwappiness: int # Tune a container's memory swappiness behavior. Accepts an integer between 0 and 100. (format: int64)
  --NanoCPUs: int # CPU quota in units of 10<sup>-9</sup> CPUs. (format: int64)
  --OomKillDisable: oneof<nothing, bool> # Disable OOM Killer for the container.
  --PidsLimit: int # Tune a container's pids limit. Set -1 for unlimited. (format: int64)
  --Ulimits: list # A list of resource limits to set in the container. For example: `{"Name": "nofile", "Soft": 1024, "Hard": 2048}`" — item shape: {Hard?: int, Name?: string, Soft?: int}
  --RestartPolicy: record # The behavior to apply when the container exits. The default is not to restart.  An ever increasing delay (double the previous delay, starting at 100ms) is added before each restart to prevent flooding the server. — shape: {MaximumRetryCount?: int, Name?: ""|"always"|"unless-stopped"|"on-failure"}
]: any -> record<Warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($id)/update")
  let body = {BlkioDeviceReadBps: $BlkioDeviceReadBps, BlkioDeviceReadIOps: $BlkioDeviceReadIOps, BlkioDeviceWriteBps: $BlkioDeviceWriteBps, BlkioDeviceWriteIOps: $BlkioDeviceWriteIOps, BlkioWeight: $BlkioWeight, BlkioWeightDevice: $BlkioWeightDevice, CgroupParent: $CgroupParent, CpuCount: $CpuCount, CpuPercent: $CpuPercent, CpuPeriod: $CpuPeriod, CpuQuota: $CpuQuota, CpuRealtimePeriod: $CpuRealtimePeriod, CpuRealtimeRuntime: $CpuRealtimeRuntime, CpuShares: $CpuShares, CpusetCpus: $CpusetCpus, CpusetMems: $CpusetMems, DeviceCgroupRules: $DeviceCgroupRules, Devices: $Devices, DiskQuota: $DiskQuota, IOMaximumBandwidth: $IOMaximumBandwidth, IOMaximumIOps: $IOMaximumIOps, KernelMemory: $KernelMemory, Memory: $Memory, MemoryReservation: $MemoryReservation, MemorySwap: $MemorySwap, MemorySwappiness: $MemorySwappiness, NanoCPUs: $NanoCPUs, OomKillDisable: $OomKillDisable, PidsLimit: $PidsLimit, Ulimits: $Ulimits, RestartPolicy: $RestartPolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Wait for a container
#
# POST /containers/{id}/wait
# operationId: ContainerWait
export def "containers-wait ContainerWait" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --condition: string # Wait until a container state reaches the given condition, either 'not-running' (default), 'next-exit', or 'removed'. (default: not-running)
]: nothing -> record<StatusCode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "condition" $condition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/wait" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get image information from the registry
#
# GET /distribution/{name}/json
# operationId: DistributionInspect
export def "distribution-json DistributionInspect" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Descriptor: record<Digest: string, MediaType: string, Size: int, URLs: list<string>>, Platforms: table<Architecture: string, Features: list, OS: string, OSFeatures: list, OSVersion: string, Variant: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/distribution/($name)/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Monitor events
#
# GET /events
# operationId: SystemEvents
export def "events SystemEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # Show events created since this timestamp then stream new events.
  --until: string # Show events created until this timestamp then stop streaming.
  --filters: string # A JSON encoded value of filters (a `map[string][]string`) to process on the event list. Available filters:  - `config=<string>` config name or ID - `container=<string>` container name or ID - `daemon=<string>` daemon name or ID - `event=<string>` event type - `image=<string>` image name or ID - `label=<string>` image or container label - `network=<string>` network name or ID - `node=<string>` node ID - `plugin`=<string> plugin name or ID - `scope`＝<string> local or swarm - `secret=<string>` secret name or ID - `service=<string>` service name or ID - `type=<string>` object to filter by, one of `container`, `image`, `volume`, `network`, `daemon`, `plugin`, `node`, `service`, `secret` or `config` - `volume=<string>` volume name
]: nothing -> record<Action: string, Actor: record<Attributes: record, ID: string>, Type: string, time: int, timeNano: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inspect an exec instance
#
# GET /exec/{id}/json
# operationId: ExecInspect
export def "exec-json ExecInspect" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ContainerID: string, ExitCode: int, ID: string, OpenStderr: bool, OpenStdin: bool, OpenStdout: bool, Pid: int, ProcessConfig: record<arguments: list<string>, entrypoint: string, privileged: bool, tty: bool, user: string>, Running: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/exec/($id)/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resize an exec instance
#
# POST /exec/{id}/resize
# operationId: ExecResize
export def "exec-resize ExecResize" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --h: int # Height of the TTY session in characters
  --w: int # Width of the TTY session in characters
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "h" $h "scalar") (serialize-qp "w" $w "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/exec/($id)/resize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start an exec instance
#
# POST /exec/{id}/start
# operationId: ExecStart
export def "exec-start ExecStart" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Detach: oneof<nothing, bool> # Detach from the command.
  --Tty: oneof<nothing, bool> # Allocate a pseudo-TTY.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/exec/($id)/start")
  let body = {Detach: $Detach, Tty: $Tty} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an image
#
# POST /images/create
# operationId: ImageCreate
export def "images-create ImageCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromImage: string # Name of the image to pull. The name may include a tag or digest. This parameter may only be used when pulling an image. The pull is cancelled if the HTTP connection is closed.
  --fromSrc: string # Source to import. The value may be a URL from which the image can be retrieved or `-` to read the image from the request body. This parameter may only be used when importing an image.
  --repo: string # Repository name given to an image when it is imported. The repo may include a tag. This parameter may only be used when importing an image.
  --tag: string # Tag or digest. If empty when pulling an image, this causes all tags for the given image to be pulled.
  --X-Registry-Auth: string # A base64-encoded auth configuration. [See the authentication section for details.](#section/Authentication)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromImage" $fromImage "scalar") (serialize-qp "fromSrc" $fromSrc "scalar") (serialize-qp "repo" $repo "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images/create" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Export several images
#
# GET /images/get
# operationId: ImageGetAll
export def "images-get ImageGetAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --names: list # Image names to filter by
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "names" $names "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/images/get" $qp)
  let accept_val = "application/x-tar"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Images
#
# GET /images/json
# operationId: ImageList
export def "images-json ImageList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: oneof<nothing, bool> # Show all images. Only images from a final layer (no children) are shown by default. (default: false)
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the images list. Available filters:  - `before`=(`<image-name>[:<tag>]`,  `<image id>` or `<image@digest>`) - `dangling=true` - `label=key` or `label="key=value"` of an image label - `reference`=(`<image-name>[:<tag>]`) - `since`=(`<image-name>[:<tag>]`,  `<image id>` or `<image@digest>`)
  --digests: oneof<nothing, bool> # Show digest information as a `RepoDigests` field on each image. (default: false)
]: nothing -> table<Containers: int, Created: int, Id: string, Labels: record, ParentId: string, RepoDigests: list<string>, RepoTags: list<string>, SharedSize: int, Size: int, VirtualSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "digests" $digests "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Import images
#
# POST /images/load
# operationId: ImageLoad
export def "images-load ImageLoad" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --quiet: oneof<nothing, bool> # Suppress progress details during load. (default: false)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quiet" $quiet "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images/load" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-tar" $body
}

# Delete unused images
#
# POST /images/prune
# operationId: ImagePrune
export def "images-prune ImagePrune" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # Filters to process on the prune list, encoded as JSON (a `map[string][]string`). Available filters:  - `dangling=<boolean>` When set to `true` (or `1`), prune only    unused *and* untagged images. When set to `false`    (or `0`), all unused images are pruned. - `until=<string>` Prune images created before this timestamp. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time. - `label` (`label=<key>`, `label=<key>=<value>`, `label!=<key>`, or `label!=<key>=<value>`) Prune images with (or without, in case `label!=...` is used) the specified labels.
]: nothing -> record<ImagesDeleted: table<Deleted: string, Untagged: string>, SpaceReclaimed: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search images
#
# GET /images/search
# operationId: ImageSearch
export def "images-search ImageSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --term: string # Term to search
  --limit: int # Maximum number of results to return
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the images list. Available filters:  - `is-automated=(true|false)` - `is-official=(true|false)` - `stars=<number>` Matches images that has at least 'number' stars.
]: nothing -> table<description: string, is_automated: bool, is_official: bool, name: string, star_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove an image
#
# DELETE /images/{name}
# operationId: ImageDelete
export def "images ImageDelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Remove the image even if it is being used by stopped containers or has other tags (default: false)
  --noprune: oneof<nothing, bool> # Do not delete untagged parent images (default: false)
]: nothing -> table<Deleted: string, Untagged: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "noprune" $noprune "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export an image
#
# GET /images/{name}/get
# operationId: ImageGet
export def "images-get ImageGet" [
  name: string
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
  let full_url = (build-url $base $"/images/($name)/get")
  let accept_val = "application/x-tar"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the history of an image
#
# GET /images/{name}/history
# operationId: ImageHistory
export def "images-history ImageHistory" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Comment: string, Created: int, CreatedBy: string, Id: string, Size: int, Tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($name)/history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inspect an image
#
# GET /images/{name}/json
# operationId: ImageInspect
export def "images-json ImageInspect" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Architecture: string, Author: string, Comment: string, Config: record<ArgsEscaped: bool, AttachStderr: bool, AttachStdin: bool, AttachStdout: bool, Cmd: list<string>, Domainname: string, Entrypoint: list<string>, Env: list<string>, ExposedPorts: record, Healthcheck: record<Interval: int, Retries: int, StartPeriod: int, Test: list, Timeout: int>, Hostname: string, Image: string, Labels: record, MacAddress: string, NetworkDisabled: bool, OnBuild: list<string>, OpenStdin: bool, Shell: list<string>, StdinOnce: bool, StopSignal: string, StopTimeout: int, Tty: bool, User: string, Volumes: record<additionalProperties: record>, WorkingDir: string>, Container: string, ContainerConfig: record<ArgsEscaped: bool, AttachStderr: bool, AttachStdin: bool, AttachStdout: bool, Cmd: list<string>, Domainname: string, Entrypoint: list<string>, Env: list<string>, ExposedPorts: record, Healthcheck: record<Interval: int, Retries: int, StartPeriod: int, Test: list, Timeout: int>, Hostname: string, Image: string, Labels: record, MacAddress: string, NetworkDisabled: bool, OnBuild: list<string>, OpenStdin: bool, Shell: list<string>, StdinOnce: bool, StopSignal: string, StopTimeout: int, Tty: bool, User: string, Volumes: record<additionalProperties: record>, WorkingDir: string>, Created: string, DockerVersion: string, GraphDriver: record<Data: record, Name: string>, Id: string, Metadata: record<LastTagTime: string>, Os: string, OsVersion: string, Parent: string, RepoDigests: list<string>, RepoTags: list<string>, RootFS: record<BaseLayer: string, Layers: list<string>, Type: string>, Size: int, VirtualSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($name)/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Push an image
#
# POST /images/{name}/push
# operationId: ImagePush
export def "images-push ImagePush" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # The tag to associate with the image on the registry.
  --X-Registry-Auth: string # A base64-encoded auth configuration. [See the authentication section for details.](#section/Authentication)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($name)/push" $qp)
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Tag an image
#
# POST /images/{name}/tag
# operationId: ImageTag
export def "images-tag ImageTag" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --repo: string # The repository to tag in. For example, `someuser/someimage`.
  --tag: string # The name of the new tag.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "repo" $repo "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($name)/tag" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get system information
#
# GET /info
# operationId: SystemInfo
export def "info SystemInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Architecture: string, BridgeNfIp6tables: bool, BridgeNfIptables: bool, CPUSet: bool, CPUShares: bool, CgroupDriver: string, ClusterAdvertise: string, ClusterStore: string, ContainerdCommit: record<Expected: string, ID: string>, Containers: int, ContainersPaused: int, ContainersRunning: int, ContainersStopped: int, CpuCfsPeriod: bool, CpuCfsQuota: bool, Debug: bool, DefaultRuntime: string, DockerRootDir: string, Driver: string, DriverStatus: list<list<string>>, ExperimentalBuild: bool, GenericResources: table<DiscreteResourceSpec: record, NamedResourceSpec: record>, HttpProxy: string, HttpsProxy: string, ID: string, IPv4Forwarding: bool, Images: int, IndexServerAddress: string, InitBinary: string, InitCommit: record<Expected: string, ID: string>, Isolation: string, KernelMemory: bool, KernelVersion: string, Labels: list<string>, LiveRestoreEnabled: bool, LoggingDriver: string, MemTotal: int, MemoryLimit: bool, NCPU: int, NEventsListener: int, NFd: int, NGoroutines: int, Name: string, NoProxy: string, OSType: string, OomKillDisable: bool, OperatingSystem: string, Plugins: record<Authorization: list<string>, Log: list<string>, Network: list<string>, Volume: list<string>>, RegistryConfig: record<AllowNondistributableArtifactsCIDRs: list<string>, AllowNondistributableArtifactsHostnames: list<string>, IndexConfigs: record, InsecureRegistryCIDRs: list<string>, Mirrors: list<string>>, RuncCommit: record<Expected: string, ID: string>, Runtimes: record, SecurityOptions: list<string>, ServerVersion: string, SwapLimit: bool, Swarm: record<Cluster: record<CreatedAt: string, ID: string, RootRotationInProgress: bool, Spec: record, TLSInfo: record, UpdatedAt: string, Version: record>, ControlAvailable: bool, Error: string, LocalNodeState: string, Managers: int, NodeAddr: string, NodeID: string, Nodes: int, RemoteManagers: list<record>>, SystemStatus: list<list<string>>, SystemTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List networks
#
# GET /networks
# operationId: NetworkList
export def "networks NetworkList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON encoded value of the filters (a `map[string][]string`) to process on the networks list. Available filters:  - `driver=<driver-name>` Matches a network's driver. - `id=<network-id>` Matches all or part of a network ID. - `label=<key>` or `label=<key>=<value>` of a network label. - `name=<network-name>` Matches all or part of a network name. - `scope=["swarm"|"global"|"local"]` Filters networks by scope (`swarm`, `global`, or `local`). - `type=["custom"|"builtin"]` Filters networks by type. The `custom` keyword returns all user-defined networks.
]: nothing -> table<Attachable: bool, Containers: record, Created: string, Driver: string, EnableIPv6: bool, IPAM: record<Config: list, Driver: string, Options: list>, Id: string, Ingress: bool, Internal: bool, Labels: record, Name: string, Options: record, Scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/networks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a network
#
# POST /networks/create
# operationId: NetworkCreate
# --IPAM shape: {Config?: list, Driver?: string, Options?: list}
export def "networks-create NetworkCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attachable: oneof<nothing, bool> # Globally scoped network is manually attachable by regular containers from workers in swarm mode.
  --CheckDuplicate: oneof<nothing, bool> # Check for networks with duplicate names. Since Network is primarily keyed based on a random ID and not on the name, and network name is strictly a user-friendly alias to the network which is uniquely identified using ID, there is no guaranteed way to check for duplicates. CheckDuplicate is there to provide a best effort checking of any networks which has the same name but it is not guaranteed to catch all name collisions.
  --Driver: string # Name of the network driver plugin to use. (default: bridge)
  --EnableIPv6: oneof<nothing, bool> # Enable IPv6 on the network.
  --IPAM: record # shape: {Config?: list, Driver?: string, Options?: list}
  --Ingress: oneof<nothing, bool> # Ingress network is the network which provides the routing-mesh in swarm mode.
  --Internal: oneof<nothing, bool> # Restrict external access to the network.
  --Labels: record # User-defined key/value metadata.
  Name: string # The network's name.
  --Options: record # Network specific options to be used by the drivers.
]: any -> record<Id: string, Warning: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/networks/create")
  let body = {Attachable: $Attachable, CheckDuplicate: $CheckDuplicate, Driver: $Driver, EnableIPv6: $EnableIPv6, IPAM: $IPAM, Ingress: $Ingress, Internal: $Internal, Labels: $Labels, Name: $Name, Options: $Options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete unused networks
#
# POST /networks/prune
# operationId: NetworkPrune
export def "networks-prune NetworkPrune" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # Filters to process on the prune list, encoded as JSON (a `map[string][]string`).  Available filters: - `until=<timestamp>` Prune networks created before this timestamp. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time. - `label` (`label=<key>`, `label=<key>=<value>`, `label!=<key>`, or `label!=<key>=<value>`) Prune networks with (or without, in case `label!=...` is used) the specified labels.
]: nothing -> record<NetworksDeleted: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/networks/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a network
#
# DELETE /networks/{id}
# operationId: NetworkDelete
export def "networks NetworkDelete" [
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
  let full_url = (build-url $base $"/networks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inspect a network
#
# GET /networks/{id}
# operationId: NetworkInspect
export def "networks NetworkInspect" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --verbose: oneof<nothing, bool> # Detailed inspect output for troubleshooting (default: false)
  --scope: string # Filter the network by scope (swarm, global, or local)
]: nothing -> record<Attachable: bool, Containers: record, Created: string, Driver: string, EnableIPv6: bool, IPAM: record<Config: list<record>, Driver: string, Options: list<record>>, Id: string, Ingress: bool, Internal: bool, Labels: record, Name: string, Options: record, Scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "verbose" $verbose "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Connect a container to a network
#
# POST /networks/{id}/connect
# operationId: NetworkConnect
export def "networks-connect NetworkConnect" [
  id: string
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
  let full_url = (build-url $base $"/networks/($id)/connect")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Disconnect a container from a network
#
# POST /networks/{id}/disconnect
# operationId: NetworkDisconnect
export def "networks-disconnect NetworkDisconnect" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Container: string # The ID or name of the container to disconnect from the network.
  --Force: oneof<nothing, bool> # Force the container to disconnect from the network.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($id)/disconnect")
  let body = {Container: $Container, Force: $Force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List nodes
#
# GET /nodes
# operationId: NodeList
export def "nodes NodeList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filters: string # Filters to process on the nodes list, encoded as JSON (a `map[string][]string`).  Available filters: - `id=<node id>` - `label=<engine label>` - `membership=`(`accepted`|`pending`)` - `name=<node name>` - `role=`(`manager`|`worker`)`
]: nothing -> table<CreatedAt: string, Description: record<Engine: record, Hostname: string, Platform: record, Resources: record, TLSInfo: record>, ID: string, ManagerStatus: record<Addr: string, Leader: bool, Reachability: string>, Spec: record<Availability: string, Labels: record, Name: string, Role: string>, Status: record<Addr: string, Message: string, State: string>, UpdatedAt: string, Version: record<Index: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nodes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a node
#
# DELETE /nodes/{id}
# operationId: NodeDelete
export def "nodes NodeDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Force remove a node from the swarm (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nodes/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inspect a node
#
# GET /nodes/{id}
# operationId: NodeInspect
export def "nodes NodeInspect" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<CreatedAt: string, Description: record<Engine: record<EngineVersion: string, Labels: record, Plugins: list>, Hostname: string, Platform: record<Architecture: string, OS: string>, Resources: record<GenericResources: list, MemoryBytes: int, NanoCPUs: int>, TLSInfo: record<CertIssuerPublicKey: string, CertIssuerSubject: string, TrustRoot: string>>, ID: string, ManagerStatus: record<Addr: string, Leader: bool, Reachability: string>, Spec: record<Availability: string, Labels: record, Name: string, Role: string>, Status: record<Addr: string, Message: string, State: string>, UpdatedAt: string, Version: record<Index: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/nodes/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a node
#
# POST /nodes/{id}/update
# operationId: NodeUpdate
export def "nodes-update NodeUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # The version number of the node object being updated. This is required to avoid conflicting writes. (format: int64)
  --Availability: string@Availability-completer # Availability of the node. (e.g. active)
  --Labels: record # User-defined key/value metadata.
  --Name: string # Name for the node. (e.g. my-node)
  --Role: string@Role-completer # Role of the node. (e.g. manager)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nodes/($id)/update" $qp)
  let body = {Availability: $Availability, Labels: $Labels, Name: $Name, Role: $Role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List plugins
#
# GET /plugins
# operationId: PluginList
export def "plugins PluginList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the plugin list. Available filters:  - `capability=<capability name>` - `enable=<true>|<false>`
]: nothing -> table<Config: record<Args: record, Description: string, DockerVersion: string, Documentation: string, Entrypoint: list, Env: list, Interface: record, IpcHost: bool, Linux: record, Mounts: list, Network: record, PidHost: bool, PropagatedMount: string, User: record, WorkDir: string, rootfs: record>, Enabled: bool, Id: string, Name: string, PluginReference: string, Settings: record<Args: list, Devices: list, Env: list, Mounts: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/plugins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a plugin
#
# POST /plugins/create
# operationId: PluginCreate
export def "plugins-create PluginCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the plugin. The `:latest` tag is optional, and is the default if omitted.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/plugins/create" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-tar" $body
}

# Get plugin privileges
#
# GET /plugins/privileges
# operationId: GetPluginPrivileges
export def "plugins-privileges GetPluginPrivileges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --remote: string # The name of the plugin. The `:latest` tag is optional, and is the default if omitted.
]: nothing -> table<Description: string, Name: string, Value: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "remote" $remote "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/plugins/privileges" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Install a plugin
#
# POST /plugins/pull
# operationId: PluginPull
export def "plugins-pull PluginPull" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --remote: string # Remote reference for plugin to install.  The `:latest` tag is optional, and is used as the default if omitted.
  --name: string # Local name for the pulled plugin.  The `:latest` tag is optional, and is used as the default if omitted.
  --X-Registry-Auth: string # A base64-encoded auth configuration to use when pulling a plugin from a registry. [See the authentication section for details.](#section/Authentication)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "remote" $remote "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/plugins/pull" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a plugin
#
# DELETE /plugins/{name}
# operationId: PluginDelete
export def "plugins PluginDelete" [
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
  --force: oneof<nothing, bool> # Disable the plugin before removing. This may result in issues if the plugin is in use by a container. (default: false)
]: nothing -> record<Config: record<Args: record<Description: string, Name: string, Settable: list, Value: list>, Description: string, DockerVersion: string, Documentation: string, Entrypoint: list<string>, Env: list<record>, Interface: record<Socket: string, Types: list>, IpcHost: bool, Linux: record<AllowAllDevices: bool, Capabilities: list, Devices: list>, Mounts: list<record>, Network: record<Type: string>, PidHost: bool, PropagatedMount: string, User: record<GID: int, UID: int>, WorkDir: string, rootfs: record<diff_ids: list, type: string>>, Enabled: bool, Id: string, Name: string, PluginReference: string, Settings: record<Args: list<string>, Devices: list<record>, Env: list<string>, Mounts: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/plugins/($name)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable a plugin
#
# POST /plugins/{name}/disable
# operationId: PluginDisable
export def "plugins-disable PluginDisable" [
  name: string
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
  let full_url = (build-url $base $"/plugins/($name)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a plugin
#
# POST /plugins/{name}/enable
# operationId: PluginEnable
export def "plugins-enable PluginEnable" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout: int # Set the HTTP client timeout (in seconds) (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/plugins/($name)/enable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inspect a plugin
#
# GET /plugins/{name}/json
# operationId: PluginInspect
export def "plugins-json PluginInspect" [
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
]: nothing -> record<Config: record<Args: record<Description: string, Name: string, Settable: list, Value: list>, Description: string, DockerVersion: string, Documentation: string, Entrypoint: list<string>, Env: list<record>, Interface: record<Socket: string, Types: list>, IpcHost: bool, Linux: record<AllowAllDevices: bool, Capabilities: list, Devices: list>, Mounts: list<record>, Network: record<Type: string>, PidHost: bool, PropagatedMount: string, User: record<GID: int, UID: int>, WorkDir: string, rootfs: record<diff_ids: list, type: string>>, Enabled: bool, Id: string, Name: string, PluginReference: string, Settings: record<Args: list<string>, Devices: list<record>, Env: list<string>, Mounts: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plugins/($name)/json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Push a plugin
#
# POST /plugins/{name}/push
# operationId: PluginPush
export def "plugins-push PluginPush" [
  name: string
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
  let full_url = (build-url $base $"/plugins/($name)/push")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure a plugin
#
# POST /plugins/{name}/set
# operationId: PluginSet
export def "plugins-set PluginSet" [
  name: string
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
  let full_url = (build-url $base $"/plugins/($name)/set")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upgrade a plugin
#
# POST /plugins/{name}/upgrade
# operationId: PluginUpgrade
export def "plugins-upgrade PluginUpgrade" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --remote: string # Remote reference to upgrade to.  The `:latest` tag is optional, and is used as the default if omitted.
  --X-Registry-Auth: string # A base64-encoded auth configuration to use when pulling a plugin from a registry. [See the authentication section for details.](#section/Authentication)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "remote" $remote "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/plugins/($name)/upgrade" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List secrets
#
# GET /secrets
# operationId: SecretList
export def "secrets SecretList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the secrets list. Available filters:  - `id=<secret id>` - `label=<key> or label=<key>=value` - `name=<secret name>` - `names=<secret name>`
]: nothing -> table<CreatedAt: string, ID: string, Spec: record<Data: string, Driver: record, Labels: record, Name: string>, UpdatedAt: string, Version: record<Index: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a secret
#
# POST /secrets/create
# operationId: SecretCreate
# --Driver shape: {Name: string, Options?: record}
export def "secrets-create SecretCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Data: string # Base64-url-safe-encoded ([RFC 4648](https://tools.ietf.org/html/rfc4648#section-3.2)) data to store as secret.  This field is only used to _create_ a secret, and is not returned by other endpoints.  (e.g. )
  --Driver: record # Driver represents a driver (network, logging, secrets). — shape: {Name: string, Options?: record}
  --Labels: record # User-defined key/value metadata. (e.g. {com.example.some-label: some-value, com.example.some-other-label: some-other-value})
  --Name: string # User-defined name of the secret.
]: any -> record<ID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/secrets/create")
  let body = {Data: $Data, Driver: $Driver, Labels: $Labels, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a secret
#
# DELETE /secrets/{id}
# operationId: SecretDelete
export def "secrets SecretDelete" [
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
  let full_url = (build-url $base $"/secrets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inspect a secret
#
# GET /secrets/{id}
# operationId: SecretInspect
export def "secrets SecretInspect" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<CreatedAt: string, ID: string, Spec: record<Data: string, Driver: record<Name: string, Options: record>, Labels: record, Name: string>, UpdatedAt: string, Version: record<Index: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/secrets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Secret
#
# POST /secrets/{id}/update
# operationId: SecretUpdate
# --Driver shape: {Name: string, Options?: record}
export def "secrets-update SecretUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # The version number of the secret object being updated. This is required to avoid conflicting writes. (format: int64)
  --Data: string # Base64-url-safe-encoded ([RFC 4648](https://tools.ietf.org/html/rfc4648#section-3.2)) data to store as secret.  This field is only used to _create_ a secret, and is not returned by other endpoints.  (e.g. )
  --Driver: record # Driver represents a driver (network, logging, secrets). — shape: {Name: string, Options?: record}
  --Labels: record # User-defined key/value metadata. (e.g. {com.example.some-label: some-value, com.example.some-other-label: some-other-value})
  --Name: string # User-defined name of the secret.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/secrets/($id)/update" $qp)
  let body = {Data: $Data, Driver: $Driver, Labels: $Labels, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List services
#
# GET /services
# operationId: ServiceList
export def "services ServiceList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the services list. Available filters:  - `id=<service id>` - `label=<service label>` - `mode=["replicated"|"global"]` - `name=<service name>`
]: nothing -> table<CreatedAt: string, Endpoint: record<Ports: list, Spec: record, VirtualIPs: list>, ID: string, Spec: record<EndpointSpec: record, Labels: record, Mode: record, Name: string, Networks: list, RollbackConfig: record, TaskTemplate: record, UpdateConfig: record>, UpdateStatus: record<CompletedAt: string, Message: string, StartedAt: string, State: string>, UpdatedAt: string, Version: record<Index: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a service
#
# POST /services/create
# operationId: ServiceCreate
# --EndpointSpec shape: {Mode?: "vip"|"dnsrr", Ports?: list}
# --Mode shape: {Global?: record, Replicated?: record}
# --Networks item shape: {Aliases?: list, Target?: string}
# --RollbackConfig shape: {Delay?: int, FailureAction?: "continue"|"pause", MaxFailureRatio?: float, Monitor?: int, Order?: "stop-first"|"start-first", Parallelism?: int}
# --TaskTemplate shape: {ContainerSpec?: record, ForceUpdate?: int, LogDriver?: record, Networks?: list, Placement?: record, PluginSpec?: record, Resources?: record, RestartPolicy?: record, Runtime?: string}
# --UpdateConfig shape: {Delay?: int, FailureAction?: "continue"|"pause"|"rollback", MaxFailureRatio?: float, Monitor?: int, Order?: "stop-first"|"start-first", Parallelism?: int}
export def "services-create ServiceCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Registry-Auth: string # A base64-encoded auth configuration for pulling from private registries. [See the authentication section for details.](#section/Authentication)
  --EndpointSpec: record # Properties that can be configured to access and load balance a service. — shape: {Mode?: "vip"|"dnsrr", Ports?: list}
  --Labels: record # User-defined key/value metadata.
  --Mode: record # Scheduling mode for the service. — shape: {Global?: record, Replicated?: record}
  --Name: string # Name of the service.
  --Networks: list # Array of network names or IDs to attach the service to. — item shape: {Aliases?: list, Target?: string}
  --RollbackConfig: record # Specification for the rollback strategy of the service. — shape: {Delay?: int, FailureAction?: "continue"|"pause", MaxFailureRatio?: float, Monitor?: int, Order?: "stop-first"|"start-first", Parallelism?: int}
  --TaskTemplate: record # User modifiable task configuration. — shape: {ContainerSpec?: record, ForceUpdate?: int, LogDriver?: record, Networks?: list, Placement?: record, PluginSpec?: record, Resources?: record, RestartPolicy?: record, Runtime?: string}
  --UpdateConfig: record # Specification for the update strategy of the service. — shape: {Delay?: int, FailureAction?: "continue"|"pause"|"rollback", MaxFailureRatio?: float, Monitor?: int, Order?: "stop-first"|"start-first", Parallelism?: int}
]: any -> record<ID: string, Warning: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/services/create")
  let body = {EndpointSpec: $EndpointSpec, Labels: $Labels, Mode: $Mode, Name: $Name, Networks: $Networks, RollbackConfig: $RollbackConfig, TaskTemplate: $TaskTemplate, UpdateConfig: $UpdateConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a service
#
# DELETE /services/{id}
# operationId: ServiceDelete
export def "services ServiceDelete" [
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
  let full_url = (build-url $base $"/services/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inspect a service
#
# GET /services/{id}
# operationId: ServiceInspect
export def "services ServiceInspect" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --insertDefaults: oneof<nothing, bool> # Fill empty fields with default values. (default: false)
]: nothing -> record<CreatedAt: string, Endpoint: record<Ports: list<record>, Spec: record<Mode: string, Ports: list>, VirtualIPs: list<record>>, ID: string, Spec: record<EndpointSpec: record<Mode: string, Ports: list>, Labels: record, Mode: record<Global: record, Replicated: record>, Name: string, Networks: list<record>, RollbackConfig: record<Delay: int, FailureAction: string, MaxFailureRatio: float, Monitor: int, Order: string, Parallelism: int>, TaskTemplate: record<ContainerSpec: record, ForceUpdate: int, LogDriver: record, Networks: list, Placement: record, PluginSpec: record, Resources: record, RestartPolicy: record, Runtime: string>, UpdateConfig: record<Delay: int, FailureAction: string, MaxFailureRatio: float, Monitor: int, Order: string, Parallelism: int>>, UpdateStatus: record<CompletedAt: string, Message: string, StartedAt: string, State: string>, UpdatedAt: string, Version: record<Index: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "insertDefaults" $insertDefaults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get service logs
#
# GET /services/{id}/logs
# operationId: ServiceLogs
export def "services-logs ServiceLogs" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --details: oneof<nothing, bool> # Show service context and extra details provided to logs. (default: false)
  --follow: oneof<nothing, bool> # Return the logs as a stream.  This will return a `101` HTTP response with a `Connection: upgrade` header, then hijack the HTTP connection to send raw output. For more information about hijacking and the stream format, [see the documentation for the attach endpoint](#operation/ContainerAttach).  (default: false)
  --stdout: oneof<nothing, bool> # Return logs from `stdout` (default: false)
  --stderr: oneof<nothing, bool> # Return logs from `stderr` (default: false)
  --since: int # Only return logs since this time, as a UNIX timestamp (default: 0)
  --timestamps: oneof<nothing, bool> # Add timestamps to every log line (default: false)
  --tail: string # Only return this number of log lines from the end of the logs. Specify as an integer or `all` to output all log lines. (default: all)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar") (serialize-qp "follow" $follow "scalar") (serialize-qp "stdout" $stdout "scalar") (serialize-qp "stderr" $stderr "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "timestamps" $timestamps "scalar") (serialize-qp "tail" $tail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($id)/logs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a service
#
# POST /services/{id}/update
# operationId: ServiceUpdate
# --EndpointSpec shape: {Mode?: "vip"|"dnsrr", Ports?: list}
# --Mode shape: {Global?: record, Replicated?: record}
# --Networks item shape: {Aliases?: list, Target?: string}
# --RollbackConfig shape: {Delay?: int, FailureAction?: "continue"|"pause", MaxFailureRatio?: float, Monitor?: int, Order?: "stop-first"|"start-first", Parallelism?: int}
# --TaskTemplate shape: {ContainerSpec?: record, ForceUpdate?: int, LogDriver?: record, Networks?: list, Placement?: record, PluginSpec?: record, Resources?: record, RestartPolicy?: record, Runtime?: string}
# --UpdateConfig shape: {Delay?: int, FailureAction?: "continue"|"pause"|"rollback", MaxFailureRatio?: float, Monitor?: int, Order?: "stop-first"|"start-first", Parallelism?: int}
export def "services-update ServiceUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # The version number of the service object being updated. This is required to avoid conflicting writes.
  --registryAuthFrom: string # If the X-Registry-Auth header is not specified, this parameter indicates where to find registry authorization credentials. The valid values are `spec` and `previous-spec`. (default: spec)
  --rollback: string # Set to this parameter to `previous` to cause a server-side rollback to the previous service spec. The supplied spec will be ignored in this case.
  --X-Registry-Auth: string # A base64-encoded auth configuration for pulling from private registries. [See the authentication section for details.](#section/Authentication)
  --EndpointSpec: record # Properties that can be configured to access and load balance a service. — shape: {Mode?: "vip"|"dnsrr", Ports?: list}
  --Labels: record # User-defined key/value metadata.
  --Mode: record # Scheduling mode for the service. — shape: {Global?: record, Replicated?: record}
  --Name: string # Name of the service.
  --Networks: list # Array of network names or IDs to attach the service to. — item shape: {Aliases?: list, Target?: string}
  --RollbackConfig: record # Specification for the rollback strategy of the service. — shape: {Delay?: int, FailureAction?: "continue"|"pause", MaxFailureRatio?: float, Monitor?: int, Order?: "stop-first"|"start-first", Parallelism?: int}
  --TaskTemplate: record # User modifiable task configuration. — shape: {ContainerSpec?: record, ForceUpdate?: int, LogDriver?: record, Networks?: list, Placement?: record, PluginSpec?: record, Resources?: record, RestartPolicy?: record, Runtime?: string}
  --UpdateConfig: record # Specification for the update strategy of the service. — shape: {Delay?: int, FailureAction?: "continue"|"pause"|"rollback", MaxFailureRatio?: float, Monitor?: int, Order?: "stop-first"|"start-first", Parallelism?: int}
]: any -> record<Warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "registryAuthFrom" $registryAuthFrom "scalar") (serialize-qp "rollback" $rollback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($id)/update" $qp)
  let body = {EndpointSpec: $EndpointSpec, Labels: $Labels, Mode: $Mode, Name: $Name, Networks: $Networks, RollbackConfig: $RollbackConfig, TaskTemplate: $TaskTemplate, UpdateConfig: $UpdateConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Initialize interactive session
#
# POST /session
# operationId: Session
export def "session Session" [
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
  let full_url = (build-url $base "/session")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inspect swarm
#
# GET /swarm
# operationId: SwarmInspect
export def "swarm SwarmInspect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/swarm")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initialize a new swarm
#
# POST /swarm/init
# operationId: SwarmInit
# --Spec shape: {CAConfig?: record, Dispatcher?: record, EncryptionConfig?: record, Labels?: record, Name?: string, Orchestration?: record, Raft?: record, TaskDefaults?: record}
export def "swarm-init SwarmInit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --AdvertiseAddr: string # Externally reachable address advertised to other nodes. This can either be an address/port combination in the form `192.168.1.1:4567`, or an interface followed by a port number, like `eth0:4567`. If the port number is omitted, the port number from the listen address is used. If `AdvertiseAddr` is not specified, it will be automatically detected when possible.
  --DataPathAddr: string # Address or interface to use for data path traffic (format: `<ip|interface>`), for example,  `192.168.1.1`, or an interface, like `eth0`. If `DataPathAddr` is unspecified, the same address as `AdvertiseAddr` is used.  The `DataPathAddr` specifies the address that global scope network drivers will publish towards other nodes in order to reach the containers running on this node. Using this parameter it is possible to separate the container data traffic from the management traffic of the cluster.
  --ForceNewCluster: oneof<nothing, bool> # Force creation of a new swarm.
  --ListenAddr: string # Listen address used for inter-manager communication, as well as determining the networking interface used for the VXLAN Tunnel Endpoint (VTEP). This can either be an address/port combination in the form `192.168.1.1:4567`, or an interface followed by a port number, like `eth0:4567`. If the port number is omitted, the default swarm listening port is used.
  --Spec: record # User modifiable swarm configuration. — shape: {CAConfig?: record, Dispatcher?: record, EncryptionConfig?: record, Labels?: record, Name?: string, Orchestration?: record, Raft?: record, TaskDefaults?: record}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/swarm/init")
  let body = {AdvertiseAddr: $AdvertiseAddr, DataPathAddr: $DataPathAddr, ForceNewCluster: $ForceNewCluster, ListenAddr: $ListenAddr, Spec: $Spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Join an existing swarm
#
# POST /swarm/join
# operationId: SwarmJoin
export def "swarm-join SwarmJoin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AdvertiseAddr: string # Externally reachable address advertised to other nodes. This can either be an address/port combination in the form `192.168.1.1:4567`, or an interface followed by a port number, like `eth0:4567`. If the port number is omitted, the port number from the listen address is used. If `AdvertiseAddr` is not specified, it will be automatically detected when possible.
  --DataPathAddr: string # Address or interface to use for data path traffic (format: `<ip|interface>`), for example,  `192.168.1.1`, or an interface, like `eth0`. If `DataPathAddr` is unspecified, the same address as `AdvertiseAddr` is used.  The `DataPathAddr` specifies the address that global scope network drivers will publish towards other nodes in order to reach the containers running on this node. Using this parameter it is possible to separate the container data traffic from the management traffic of the cluster.
  --JoinToken: string # Secret token for joining this swarm.
  --ListenAddr: string # Listen address used for inter-manager communication if the node gets promoted to manager, as well as determining the networking interface used for the VXLAN Tunnel Endpoint (VTEP).
  --RemoteAddrs: string # Addresses of manager nodes already participating in the swarm.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/swarm/join")
  let body = {AdvertiseAddr: $AdvertiseAddr, DataPathAddr: $DataPathAddr, JoinToken: $JoinToken, ListenAddr: $ListenAddr, RemoteAddrs: $RemoteAddrs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Leave a swarm
#
# POST /swarm/leave
# operationId: SwarmLeave
export def "swarm-leave SwarmLeave" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Force leave swarm, even if this is the last manager or that it will break the cluster. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/swarm/leave" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unlock a locked manager
#
# POST /swarm/unlock
# operationId: SwarmUnlock
export def "swarm-unlock SwarmUnlock" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --UnlockKey: string # The swarm's unlock key.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/swarm/unlock")
  let body = {UnlockKey: $UnlockKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the unlock key
#
# GET /swarm/unlockkey
# operationId: SwarmUnlockkey
export def "swarm-unlockkey SwarmUnlockkey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<UnlockKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/swarm/unlockkey")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a swarm
#
# POST /swarm/update
# operationId: SwarmUpdate
# --CAConfig shape: {ExternalCAs?: list, ForceRotate?: int, NodeCertExpiry?: int, SigningCACert?: string, SigningCAKey?: string}
# --Dispatcher shape: {HeartbeatPeriod?: int}
# --EncryptionConfig shape: {AutoLockManagers?: bool}
# --Orchestration shape: {TaskHistoryRetentionLimit?: int}
# --Raft shape: {ElectionTick?: int, HeartbeatTick?: int, KeepOldSnapshots?: int, LogEntriesForSlowFollowers?: int, SnapshotInterval?: int}
# --TaskDefaults shape: {LogDriver?: record}
export def "swarm-update SwarmUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # The version number of the swarm object being updated. This is required to avoid conflicting writes. (format: int64)
  --rotateWorkerToken: oneof<nothing, bool> # Rotate the worker join token. (default: false)
  --rotateManagerToken: oneof<nothing, bool> # Rotate the manager join token. (default: false)
  --rotateManagerUnlockKey: oneof<nothing, bool> # Rotate the manager unlock key. (default: false)
  --CAConfig: record # CA configuration. (nullable) — shape: {ExternalCAs?: list, ForceRotate?: int, NodeCertExpiry?: int, SigningCACert?: string, SigningCAKey?: string}
  --Dispatcher: record # Dispatcher configuration. (nullable) — shape: {HeartbeatPeriod?: int}
  --EncryptionConfig: record # Parameters related to encryption-at-rest. — shape: {AutoLockManagers?: bool}
  --Labels: record # User-defined key/value metadata. (e.g. {com.example.corp.department: engineering, com.example.corp.type: production})
  --Name: string # Name of the swarm. (e.g. default)
  --Orchestration: record # Orchestration configuration. (nullable) — shape: {TaskHistoryRetentionLimit?: int}
  --Raft: record # Raft configuration. — shape: {ElectionTick?: int, HeartbeatTick?: int, KeepOldSnapshots?: int, LogEntriesForSlowFollowers?: int, SnapshotInterval?: int}
  --TaskDefaults: record # Defaults for creating tasks in this cluster. — shape: {LogDriver?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "rotateWorkerToken" $rotateWorkerToken "scalar") (serialize-qp "rotateManagerToken" $rotateManagerToken "scalar") (serialize-qp "rotateManagerUnlockKey" $rotateManagerUnlockKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/swarm/update" $qp)
  let body = {CAConfig: $CAConfig, Dispatcher: $Dispatcher, EncryptionConfig: $EncryptionConfig, Labels: $Labels, Name: $Name, Orchestration: $Orchestration, Raft: $Raft, TaskDefaults: $TaskDefaults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get data usage information
#
# GET /system/df
# operationId: SystemDataUsage
export def "system-df SystemDataUsage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Containers: list<list<record>>, Images: table<Containers: int, Created: int, Id: string, Labels: record, ParentId: string, RepoDigests: list, RepoTags: list, SharedSize: int, Size: int, VirtualSize: int>, LayersSize: int, Volumes: table<CreatedAt: string, Driver: string, Labels: record, Mountpoint: string, Name: string, Options: record, Scope: string, Status: record, UsageData: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/df")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List tasks
#
# GET /tasks
# operationId: TaskList
export def "tasks TaskList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the tasks list. Available filters:  - `desired-state=(running | shutdown | accepted)` - `id=<task id>` - `label=key` or `label="key=value"` - `name=<task name>` - `node=<node id or name>` - `service=<service name>`
]: nothing -> table<AssignedGenericResources: list<record>, CreatedAt: string, DesiredState: string, ID: string, Labels: record, Name: string, NodeID: string, ServiceID: string, Slot: int, Spec: record<ContainerSpec: record, ForceUpdate: int, LogDriver: record, Networks: list, Placement: record, PluginSpec: record, Resources: record, RestartPolicy: record, Runtime: string>, Status: record<ContainerStatus: record, Err: string, Message: string, State: string, Timestamp: string>, UpdatedAt: string, Version: record<Index: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inspect a task
#
# GET /tasks/{id}
# operationId: TaskInspect
export def "tasks TaskInspect" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<AssignedGenericResources: table<DiscreteResourceSpec: record, NamedResourceSpec: record>, CreatedAt: string, DesiredState: string, ID: string, Labels: record, Name: string, NodeID: string, ServiceID: string, Slot: int, Spec: record<ContainerSpec: record<Args: list, Command: list, Configs: list, DNSConfig: record, Dir: string, Env: list, Groups: list, HealthCheck: record, Hostname: string, Hosts: list, Image: string, Labels: record, Mounts: list, OpenStdin: bool, Privileges: record, ReadOnly: bool, Secrets: list, StopGracePeriod: int, StopSignal: string, TTY: bool, User: string>, ForceUpdate: int, LogDriver: record<Name: string, Options: record>, Networks: list<record>, Placement: record<Constraints: list, Platforms: list, Preferences: list>, PluginSpec: record<Disabled: bool, Name: string, PluginPrivilege: list, Remote: string>, Resources: record<Limits: record, Reservation: record>, RestartPolicy: record<Condition: string, Delay: int, MaxAttempts: int, Window: int>, Runtime: string>, Status: record<ContainerStatus: record<ContainerID: string, ExitCode: int, PID: int>, Err: string, Message: string, State: string, Timestamp: string>, UpdatedAt: string, Version: record<Index: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get task logs
#
# GET /tasks/{id}/logs
# operationId: TaskLogs
export def "tasks-logs TaskLogs" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --details: oneof<nothing, bool> # Show task context and extra details provided to logs. (default: false)
  --follow: oneof<nothing, bool> # Return the logs as a stream.  This will return a `101` HTTP response with a `Connection: upgrade` header, then hijack the HTTP connection to send raw output. For more information about hijacking and the stream format, [see the documentation for the attach endpoint](#operation/ContainerAttach).  (default: false)
  --stdout: oneof<nothing, bool> # Return logs from `stdout` (default: false)
  --stderr: oneof<nothing, bool> # Return logs from `stderr` (default: false)
  --since: int # Only return logs since this time, as a UNIX timestamp (default: 0)
  --timestamps: oneof<nothing, bool> # Add timestamps to every log line (default: false)
  --tail: string # Only return this number of log lines from the end of the logs. Specify as an integer or `all` to output all log lines. (default: all)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar") (serialize-qp "follow" $follow "scalar") (serialize-qp "stdout" $stdout "scalar") (serialize-qp "stderr" $stderr "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "timestamps" $timestamps "scalar") (serialize-qp "tail" $tail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($id)/logs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get version
#
# GET /version
# operationId: SystemVersion
export def "version SystemVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ApiVersion: string, Arch: string, BuildTime: string, Experimental: bool, GitCommit: string, GoVersion: string, KernelVersion: string, MinAPIVersion: string, Os: string, Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List volumes
#
# GET /volumes
# operationId: VolumeList
export def "volumes VolumeList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # JSON encoded value of the filters (a `map[string][]string`) to process on the volumes list. Available filters:  - `dangling=<boolean>` When set to `true` (or `1`), returns all    volumes that are not in use by a container. When set to `false`    (or `0`), only volumes that are in use by one or more    containers are returned. - `driver=<volume-driver-name>` Matches volumes based on their driver. - `label=<key>` or `label=<key>:<value>` Matches volumes based on    the presence of a `label` alone or a `label` and a value. - `name=<volume-name>` Matches all or part of a volume name.  (format: json)
]: nothing -> record<Volumes: table<CreatedAt: string, Driver: string, Labels: record, Mountpoint: string, Name: string, Options: record, Scope: string, Status: record, UsageData: record>, Warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/volumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a volume
#
# POST /volumes/create
# operationId: VolumeCreate
export def "volumes-create VolumeCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Driver: string # Name of the volume driver to use. (default: local)
  --DriverOpts: record # A mapping of driver options and values. These options are passed directly to the driver and are driver specific.
  --Labels: record # User-defined key/value metadata.
  --Name: string # The new volume's name. If not specified, Docker generates a name.
]: any -> record<CreatedAt: string, Driver: string, Labels: record, Mountpoint: string, Name: string, Options: record, Scope: string, Status: record, UsageData: record<RefCount: int, Size: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/volumes/create")
  let body = {Driver: $Driver, DriverOpts: $DriverOpts, Labels: $Labels, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete unused volumes
#
# POST /volumes/prune
# operationId: VolumePrune
export def "volumes-prune VolumePrune" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # Filters to process on the prune list, encoded as JSON (a `map[string][]string`).  Available filters: - `label` (`label=<key>`, `label=<key>=<value>`, `label!=<key>`, or `label!=<key>=<value>`) Prune volumes with (or without, in case `label!=...` is used) the specified labels.
]: nothing -> record<SpaceReclaimed: int, VolumesDeleted: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/volumes/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a volume
#
# DELETE /volumes/{name}
# operationId: VolumeDelete
export def "volumes VolumeDelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Force the removal of the volume (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/volumes/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inspect a volume
#
# GET /volumes/{name}
# operationId: VolumeInspect
export def "volumes VolumeInspect" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<CreatedAt: string, Driver: string, Labels: record, Mountpoint: string, Name: string, Options: record, Scope: string, Status: record, UsageData: record<RefCount: int, Size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/volumes/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
