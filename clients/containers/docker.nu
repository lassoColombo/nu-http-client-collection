# Auto-generated client for Docker Engine API v1.55
# Source: https://raw.githubusercontent.com/moby/moby/master/api/swagger.yaml
# Auth: --token flag or $env.DOCKER_ENGINE_API_TOKEN

const BASE_URL = "http://localhost/v1.55"
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

def base-url-completer [] { ["http://localhost/v1.55" "https://localhost/v1.55"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/plain"] }
def accept-completer-1 [] { ["application/vnd.docker.multiplexed-stream" "application/vnd.docker.raw-stream"] }
def condition-completer [] { ["next-exit" "not-running" "removed"] }
def version-completer [] { ["1" "2"] }
def Content-type-completer [] { ["application/x-tar"] }
def accept-completer-2 [] { ["application/json-seq" "application/jsonl" "application/x-ndjson"] }
def Role-completer [] { ["manager" "worker"] }
def Availability-completer [] { ["active" "drain" "pause"] }
def registryAuthFrom-completer [] { ["previous-spec" "spec"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "containers-json ContainerList" } } | get name | first)
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
  --all: oneof<nothing, bool> # Return all containers. By default, only running containers are shown.  (default: false)
  --limit: int # Return this number of most recently created containers, including non-running ones.
  --size: oneof<nothing, bool> # Return the size of container as fields `SizeRw` and `SizeRootFs`.  (default: false)
  --filters: string # Filters to process on the container list, encoded as JSON (a `map[string][]string`). For example, `{"status": ["paused"]}` will only return paused containers.  Available filters:  - `ancestor`=(`<image-name>[:<tag>]`, `<image id>`, or `<image@digest>`) - `before`=(`<container id>` or `<container name>`) - `expose`=(`<port>[/<proto>]`|`<startport-endport>/[<proto>]`) - `exited=<int>` containers with exit code of `<int>` - `health`=(`starting`|`healthy`|`unhealthy`|`none`) - `id=<ID>` a container's ID - `isolation=`(`default`|`process`|`hyperv`) (Windows daemon only) - `is-task=`(`true`|`false`) - `label=key` or `label="key=value"` of a container label - `name=<name>` a container's name - `network`=(`<network id>` or `<network name>`) - `publish`=(`<port>[/<proto>]`|`<startport-endport>/[<proto>]`) - `since`=(`<container id>` or `<container name>`) - `status=`(`created`|`restarting`|`running`|`removing`|`paused`|`exited`|`dead`) - `volume`=(`<volume name>` or `<mount point destination>`)
]: nothing -> table<Id: string, Names: list<string>, Image: string, ImageID: string, ImageManifestDescriptor: record<mediaType: string, digest: string, size: int, urls: list, annotations: record, data: string, platform: record, artifactType: string>, Command: string, Created: int, Ports: list<record>, SizeRw: int, SizeRootFs: int, Labels: record, State: string, Status: string, HostConfig: record<NetworkMode: string, Annotations: record>, NetworkSettings: record<Networks: record>, Mounts: list<record>, Health: record<Status: string, FailingStreak: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/containers/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a container
#
# POST /containers/create
# operationId: ContainerCreate
# --Healthcheck shape: {Test?: list, Interval?: int, Timeout?: int, Retries?: int, StartPeriod?: int, StartInterval?: int}
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
  --name: string # Assign the specified name to the container. Must match `/?[a-zA-Z0-9][a-zA-Z0-9_.-]+`.
  --platform: string # Platform in the format `os[/arch[/variant]]` used for image lookup.  When specified, the daemon checks if the requested image is present in the local image cache with the given OS and Architecture, and otherwise returns a `404` status.  If the option is not set, the host's native OS and Architecture are used to look up the image in the image cache. However, if no platform is passed and the given image does exist in the local image cache, but its OS or architecture does not match, the container is created with the available image, and a warning is added to the `Warnings` field in the response, for example;      WARNING: The requested image's platform (linux/arm64/v8) does not              match the detected host platform (linux/amd64) and no              specific platform was requested  (default: )
  --Hostname: string # The hostname to use for the container, as a valid RFC 1123 hostname.  (e.g. 439f4e91bd1d)
  --Domainname: string # The domain name to use for the container.
  --User: string # Commands run as this user inside the container. If omitted, commands run as the user specified in the image the container was started from.  Can be either user-name or UID, and optional group-name or GID, separated by a colon (`<user-name|UID>[<:group-name|GID>]`). (e.g. 123:456)
  --AttachStdin: oneof<nothing, bool> # Whether to attach to `stdin`. (default: false)
  --AttachStdout: oneof<nothing, bool> # Whether to attach to `stdout`. (default: true)
  --AttachStderr: oneof<nothing, bool> # Whether to attach to `stderr`. (default: true)
  --ExposedPorts: record # An object mapping ports to an empty object in the form:  `{"<port>/<tcp|udp|sctp>": {}}`  (e.g. {80/tcp: {}, 443/tcp: {}})
  --Tty: oneof<nothing, bool> # Attach standard streams to a TTY, including `stdin` if it is not closed.  (default: false)
  --OpenStdin: oneof<nothing, bool> # Open `stdin` (default: false)
  --StdinOnce: oneof<nothing, bool> # Close `stdin` after one attached client disconnects (default: false)
  --Env: list # A list of environment variables to set inside the container in the form `["VAR=value", ...]`. A variable without `=` is removed from the environment, rather than to have an empty value.  (e.g. [PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin])
  --Cmd: list # Command to run specified as a string or an array of strings.  (e.g. [/bin/sh])
  --Healthcheck: record # A test to perform to check that the container is healthy. Healthcheck commands should be side-effect free. — shape: {Test?: list, Interval?: int, Timeout?: int, Retries?: int, StartPeriod?: int, StartInterval?: int}
  --ArgsEscaped: oneof<nothing, bool> # Command is already escaped (Windows only) (default: false, e.g. false)
  --Image: string # The name (or reference) of the image to use when creating the container, or which was used when the container was created.  (e.g. example-image:1.0)
  --Volumes: record # An object mapping mount point paths inside the container to empty objects.
  --WorkingDir: string # The working directory for commands to run in. (e.g. /public/)
  --Entrypoint: list # The entry point for the container as a string or an array of strings.  If the array consists of exactly one empty string (`[""]`) then the entry point is reset to system default (i.e., the entry point used by docker when there is no `ENTRYPOINT` instruction in the `Dockerfile`).  (e.g. [])
  --NetworkDisabled: oneof<nothing, bool> # Disable networking for the container.
  --OnBuild: list # `ONBUILD` metadata that were defined in the image's `Dockerfile`.  (e.g. [])
  --Labels: record # User-defined key/value metadata. (e.g. {com.example.some-label: some-value, com.example.some-other-label: some-other-value})
  --StopSignal: string # Signal to stop a container as a string or unsigned integer.  (e.g. SIGTERM)
  --StopTimeout: int # Timeout to stop a container in seconds. (default: 10)
  --Shell: list # Shell for when `RUN`, `CMD`, and `ENTRYPOINT` uses a shell.  (e.g. [/bin/sh, -c])
  --HostConfig: any # Container configuration that depends on the host we are running on
  --NetworkingConfig: record # NetworkingConfig represents the container's networking configuration for each of its interfaces. It is used for the networking configs specified in the `docker create` and `docker network connect` commands.  (e.g. {EndpointsConfig: {isolated_nw: {IPAMConfig: {IPv4Address: 172.20.30.33, IPv6Address: 2001:db8:abcd::3033, LinkLocalIPs: [169.254.34.68, fe80::3468]}, MacAddress: 02:42:ac:12:05:02, Links: [container_1, container_2], Aliases: [server_x, server_y]}, database_nw: {}}}) — shape: {EndpointsConfig?: record}
]: any -> record<Id: string, Warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/containers/create" $qp)
  let body = {Hostname: $Hostname, Domainname: $Domainname, User: $User, AttachStdin: $AttachStdin, AttachStdout: $AttachStdout, AttachStderr: $AttachStderr, ExposedPorts: $ExposedPorts, Tty: $Tty, OpenStdin: $OpenStdin, StdinOnce: $StdinOnce, Env: $Env, Cmd: $Cmd, Healthcheck: $Healthcheck, ArgsEscaped: $ArgsEscaped, Image: $Image, Volumes: $Volumes, WorkingDir: $WorkingDir, Entrypoint: $Entrypoint, NetworkDisabled: $NetworkDisabled, OnBuild: $OnBuild, Labels: $Labels, StopSignal: $StopSignal, StopTimeout: $StopTimeout, Shell: $Shell, HostConfig: $HostConfig, NetworkingConfig: $NetworkingConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
]: nothing -> record<Id: string, Created: string, Path: string, Args: list<string>, State: record<Status: string, Running: bool, Paused: bool, Restarting: bool, OOMKilled: bool, Dead: bool, Pid: int, ExitCode: int, Error: string, StartedAt: string, FinishedAt: string, Health: record<Status: string, FailingStreak: int, Log: list>>, Image: string, ResolvConfPath: string, HostnamePath: string, HostsPath: string, LogPath: string, Name: string, RestartCount: int, Driver: string, Platform: string, ImageManifestDescriptor: record<mediaType: string, digest: string, size: int, urls: list<string>, annotations: record, data: string, platform: record<architecture: string, os: string, os_version: string, os_features: list, variant: string>, artifactType: string>, MountLabel: string, ProcessLabel: string, AppArmorProfile: string, ExecIDs: list<string>, HostConfig: record<CpuShares: int, Memory: int, CgroupParent: string, BlkioWeight: int, BlkioWeightDevice: list<record>, BlkioDeviceReadBps: list<record>, BlkioDeviceWriteBps: list<record>, BlkioDeviceReadIOps: list<record>, BlkioDeviceWriteIOps: list<record>, CpuPeriod: int, CpuQuota: int, CpuRealtimePeriod: int, CpuRealtimeRuntime: int, CpusetCpus: string, CpusetMems: string, Devices: list<record>, DeviceCgroupRules: list<string>, DeviceRequests: list<record>, MemoryReservation: int, MemorySwap: int, MemorySwappiness: int, NanoCpus: int, OomKillDisable: bool, Init: bool, PidsLimit: int, Ulimits: list<record>, CpuCount: int, CpuPercent: int, IOMaximumIOps: int, IOMaximumBandwidth: int, Binds: list<string>, ContainerIDFile: string, LogConfig: record<Type: string, Config: record>, NetworkMode: string, PortBindings: record, RestartPolicy: record<Name: string, MaximumRetryCount: int>, AutoRemove: bool, VolumeDriver: string, VolumesFrom: list<string>, Mounts: list<record>, ConsoleSize: list<int>, Annotations: record, CapAdd: list<string>, CapDrop: list<string>, CgroupnsMode: string, Dns: list<string>, DnsOptions: list<string>, DnsSearch: list<string>, ExtraHosts: list<string>, GroupAdd: list<string>, IpcMode: string, Cgroup: string, Links: list<string>, OomScoreAdj: int, PidMode: string, Privileged: bool, PublishAllPorts: bool, ReadonlyRootfs: bool, SecurityOpt: list<string>, StorageOpt: record, Tmpfs: record, UTSMode: string, UsernsMode: string, ShmSize: int, Sysctls: record, Runtime: string, Isolation: string, MaskedPaths: list<string>, ReadonlyPaths: list<string>>, GraphDriver: record<Name: string, Data: record>, Storage: record<RootFS: record<Snapshot: record>>, SizeRw: int, SizeRootFs: int, Mounts: table<Type: record, Name: string, Source: string, Destination: string, Driver: string, Mode: string, RW: bool, Propagation: string>, Config: record<Hostname: string, Domainname: string, User: string, AttachStdin: bool, AttachStdout: bool, AttachStderr: bool, ExposedPorts: record, Tty: bool, OpenStdin: bool, StdinOnce: bool, Env: list<string>, Cmd: list<string>, Healthcheck: record<Test: list, Interval: int, Timeout: int, Retries: int, StartPeriod: int, StartInterval: int>, ArgsEscaped: bool, Image: string, Volumes: record, WorkingDir: string, Entrypoint: list<string>, NetworkDisabled: bool, OnBuild: list<string>, Labels: record, StopSignal: string, StopTimeout: int, Shell: list<string>>, NetworkSettings: record<SandboxID: string, SandboxKey: string, Ports: record, Networks: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
]: nothing -> record<Titles: list<string>, Processes: list<list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ps_args" $ps_args "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/top" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --accept: string@accept-completer-1 # Response content type
  --follow: oneof<nothing, bool> # Keep connection after returning logs. (default: false)
  --stdout: oneof<nothing, bool> # Return logs from `stdout` (default: false)
  --stderr: oneof<nothing, bool> # Return logs from `stderr` (default: false)
  --since: int # Only return logs since this time, as a UNIX timestamp (default: 0)
  --until: int # Only return logs before this time, as a UNIX timestamp (default: 0)
  --timestamps: oneof<nothing, bool> # Add timestamps to every log line (default: false)
  --tail: string # Only return this number of log lines from the end of the logs. Specify as an integer or `all` to output all log lines.  (default: all)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "follow" $follow "scalar") (serialize-qp "stdout" $stdout "scalar") (serialize-qp "stderr" $stderr "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "timestamps" $timestamps "scalar") (serialize-qp "tail" $tail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/logs" $qp)
  let accept_val = ($accept | default "application/vnd.docker.raw-stream")
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
]: nothing -> table<Path: string, Kind: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($id)/changes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --stream: oneof<nothing, bool> # Stream the output. If false, the stats will be output once and then it will disconnect.  (default: true)
  --one-shot: oneof<nothing, bool> # Only get a single stat instead of waiting for 2 cycles. Must be used with `stream=false`.  (default: false)
]: nothing -> record<id: string, name: string, os_type: string, read: string, cpu_stats: record<cpu_usage: record<total_usage: int, percpu_usage: list, usage_in_kernelmode: int, usage_in_usermode: int>, system_cpu_usage: int, online_cpus: int, throttling_data: record<periods: int, throttled_periods: int, throttled_time: int>>, memory_stats: record<usage: int, max_usage: int, stats: record, failcnt: int, limit: int, commitbytes: int, commitpeakbytes: int, privateworkingset: int>, networks: any, pids_stats: record<current: int, limit: int>, blkio_stats: record<io_service_bytes_recursive: list<record>, io_serviced_recursive: list<record>, io_queue_recursive: list<record>, io_service_time_recursive: list<record>, io_wait_time_recursive: list<record>, io_merged_recursive: list<record>, io_time_recursive: list<record>, sectors_recursive: list<record>>, num_procs: int, storage_stats: record<read_count_normalized: int, read_size_bytes: int, write_count_normalized: int, write_size_bytes: int>, preread: string, precpu_stats: record<cpu_usage: record<total_usage: int, percpu_usage: list, usage_in_kernelmode: int, usage_in_usermode: int>, system_cpu_usage: int, online_cpus: int, throttling_data: record<periods: int, throttled_periods: int, throttled_time: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stream" $stream "scalar") (serialize-qp "one-shot" $one_shot "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --h: int # Height of the TTY session in characters
  --w: int # Width of the TTY session in characters
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "h" $h "scalar") (serialize-qp "w" $w "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/resize" $qp)
  let accept_val = "text/plain"
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
  --accept: string@accept-completer # Response content type
  --detachKeys: string # Override the key sequence for detaching a container. Format is a single character `[a-Z]` or `ctrl-<value>` where `<value>` is one of: `a-z`, `@`, `^`, `[`, `,` or `_`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detachKeys" $detachKeys "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/start" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --accept: string@accept-completer # Response content type
  --signal: string # Signal to send to the container as an integer or string (e.g. `SIGINT`).
  --t: int # Number of seconds to wait before killing the container
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signal" $signal "scalar") (serialize-qp "t" $t "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/stop" $qp)
  let accept_val = ($accept | default "application/json")
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
  --accept: string@accept-completer # Response content type
  --signal: string # Signal to send to the container as an integer or string (e.g. `SIGINT`).
  --t: int # Number of seconds to wait before killing the container
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signal" $signal "scalar") (serialize-qp "t" $t "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/restart" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --accept: string@accept-completer # Response content type
  --signal: string # Signal to send to the container as an integer or string (e.g. `SIGINT`).  (default: SIGKILL)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signal" $signal "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/kill" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a container
#
# POST /containers/{id}/update
# operationId: ContainerUpdate
# --BlkioWeightDevice item shape: {Path?: string, Weight?: int}
# --BlkioDeviceReadBps item shape: {Path?: string, Rate?: int}
# --BlkioDeviceWriteBps item shape: {Path?: string, Rate?: int}
# --BlkioDeviceReadIOps item shape: {Path?: string, Rate?: int}
# --BlkioDeviceWriteIOps item shape: {Path?: string, Rate?: int}
# --Devices item shape: {PathOnHost?: string, PathInContainer?: string, CgroupPermissions?: string}
# --DeviceRequests item shape: {Driver?: string, Count?: int, DeviceIDs?: list, Capabilities?: list, Options?: record}
# --Ulimits item shape: {Name?: string, Soft?: int, Hard?: int}
# --RestartPolicy shape: {Name?: ""|"no"|"always"|"unless-stopped"|"on-failure", MaximumRetryCount?: int}
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
  --CpuShares: int # An integer value representing this container's relative CPU weight versus other containers.
  --Memory: int # Memory limit in bytes. (format: int64, default: 0)
  --CgroupParent: string # Path to `cgroups` under which the container's `cgroup` is created. If the path is not absolute, the path is considered to be relative to the `cgroups` path of the init process. Cgroups are created if they do not already exist.
  --BlkioWeight: int # Block IO weight (relative weight).
  --BlkioWeightDevice: list # Block IO weight (relative device weight) in the form:  ``` [{"Path": "device_path", "Weight": weight}] ``` — item shape: {Path?: string, Weight?: int}
  --BlkioDeviceReadBps: list # Limit read rate (bytes per second) from a device, in the form:  ``` [{"Path": "device_path", "Rate": rate}] ``` — item shape: {Path?: string, Rate?: int}
  --BlkioDeviceWriteBps: list # Limit write rate (bytes per second) to a device, in the form:  ``` [{"Path": "device_path", "Rate": rate}] ``` — item shape: {Path?: string, Rate?: int}
  --BlkioDeviceReadIOps: list # Limit read rate (IO per second) from a device, in the form:  ``` [{"Path": "device_path", "Rate": rate}] ``` — item shape: {Path?: string, Rate?: int}
  --BlkioDeviceWriteIOps: list # Limit write rate (IO per second) to a device, in the form:  ``` [{"Path": "device_path", "Rate": rate}] ``` — item shape: {Path?: string, Rate?: int}
  --CpuPeriod: int # The length of a CPU period in microseconds. (format: int64)
  --CpuQuota: int # Microseconds of CPU time that the container can get in a CPU period.  (format: int64)
  --CpuRealtimePeriod: int # The length of a CPU real-time period in microseconds. Set to 0 to allocate no time allocated to real-time tasks.  (format: int64)
  --CpuRealtimeRuntime: int # The length of a CPU real-time runtime in microseconds. Set to 0 to allocate no time allocated to real-time tasks.  (format: int64)
  --CpusetCpus: string # CPUs in which to allow execution (e.g., `0-3`, `0,1`).  (e.g. 0-3)
  --CpusetMems: string # Memory nodes (MEMs) in which to allow execution (0-3, 0,1). Only effective on NUMA systems.
  --Devices: list # A list of devices to add to the container. — item shape: {PathOnHost?: string, PathInContainer?: string, CgroupPermissions?: string}
  --DeviceCgroupRules: list # a list of cgroup rules to apply to the container
  --DeviceRequests: list # A list of requests for devices to be sent to device drivers. — item shape: {Driver?: string, Count?: int, DeviceIDs?: list, Capabilities?: list, Options?: record}
  --MemoryReservation: int # Memory soft limit in bytes. (format: int64)
  --MemorySwap: int # Total memory limit (memory + swap). Set as `-1` to enable unlimited swap.  (format: int64)
  --MemorySwappiness: int # Tune a container's memory swappiness behavior. Accepts an integer between 0 and 100.  (format: int64)
  --NanoCpus: int # CPU quota in units of 10<sup>-9</sup> CPUs. (format: int64)
  --OomKillDisable: oneof<nothing, bool> # Disable OOM Killer for the container.
  --Init: oneof<nothing, bool> # Run an init inside the container that forwards signals and reaps processes. This field is omitted if empty, and the default (as configured on the daemon) is used.
  --PidsLimit: int # Tune a container's PIDs limit. Set `0` or `-1` for unlimited, or `null` to not change.  (format: int64)
  --Ulimits: list # A list of resource limits to set in the container. For example:  ``` {"Name": "nofile", "Soft": 1024, "Hard": 2048} ``` — item shape: {Name?: string, Soft?: int, Hard?: int}
  --CpuCount: int # The number of usable CPUs (Windows only).  On Windows Server containers, the processor resource controls are mutually exclusive. The order of precedence is `CPUCount` first, then `CPUShares`, and `CPUPercent` last.  (format: int64)
  --CpuPercent: int # The usable percentage of the available CPUs (Windows only).  On Windows Server containers, the processor resource controls are mutually exclusive. The order of precedence is `CPUCount` first, then `CPUShares`, and `CPUPercent` last.  (format: int64)
  --IOMaximumIOps: int # Maximum IOps for the container system drive (Windows only) (format: int64)
  --IOMaximumBandwidth: int # Maximum IO in bytes per second for the container system drive (Windows only).  (format: int64)
  --RestartPolicy: record # The behavior to apply when the container exits. The default is not to restart.  An ever increasing delay (double the previous delay, starting at 100ms) is added before each restart to prevent flooding the server. — shape: {Name?: ""|"no"|"always"|"unless-stopped"|"on-failure", MaximumRetryCount?: int}
]: any -> record<Warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($id)/update")
  let body = {CpuShares: $CpuShares, Memory: $Memory, CgroupParent: $CgroupParent, BlkioWeight: $BlkioWeight, BlkioWeightDevice: $BlkioWeightDevice, BlkioDeviceReadBps: $BlkioDeviceReadBps, BlkioDeviceWriteBps: $BlkioDeviceWriteBps, BlkioDeviceReadIOps: $BlkioDeviceReadIOps, BlkioDeviceWriteIOps: $BlkioDeviceWriteIOps, CpuPeriod: $CpuPeriod, CpuQuota: $CpuQuota, CpuRealtimePeriod: $CpuRealtimePeriod, CpuRealtimeRuntime: $CpuRealtimeRuntime, CpusetCpus: $CpusetCpus, CpusetMems: $CpusetMems, Devices: $Devices, DeviceCgroupRules: $DeviceCgroupRules, DeviceRequests: $DeviceRequests, MemoryReservation: $MemoryReservation, MemorySwap: $MemorySwap, MemorySwappiness: $MemorySwappiness, NanoCpus: $NanoCpus, OomKillDisable: $OomKillDisable, Init: $Init, PidsLimit: $PidsLimit, Ulimits: $Ulimits, CpuCount: $CpuCount, CpuPercent: $CpuPercent, IOMaximumIOps: $IOMaximumIOps, IOMaximumBandwidth: $IOMaximumBandwidth, RestartPolicy: $RestartPolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --accept: string@accept-completer # Response content type
  --name: string # New name for the container
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/rename" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($id)/pause")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($id)/unpause")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --accept: string@accept-completer-1 # Response content type
  --detachKeys: string # Override the key sequence for detaching a container.Format is a single character `[a-Z]` or `ctrl-<value>` where `<value>` is one of: `a-z`, `@`, `^`, `[`, `,` or `_`.
  --logs: oneof<nothing, bool> # Replay previous logs from the container.  This is useful for attaching to a container that has started and you want to output everything since the container started.  If `stream` is also enabled, once all the previous output has been returned, it will seamlessly transition into streaming current output.  (default: false)
  --stream: oneof<nothing, bool> # Stream attached streams from the time the request was made onwards.  (default: false)
  --stdin: oneof<nothing, bool> # Attach to `stdin` (default: false)
  --stdout: oneof<nothing, bool> # Attach to `stdout` (default: false)
  --stderr: oneof<nothing, bool> # Attach to `stderr` (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detachKeys" $detachKeys "scalar") (serialize-qp "logs" $logs "scalar") (serialize-qp "stream" $stream "scalar") (serialize-qp "stdin" $stdin "scalar") (serialize-qp "stdout" $stdout "scalar") (serialize-qp "stderr" $stderr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/attach" $qp)
  let accept_val = ($accept | default "application/vnd.docker.raw-stream")
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
  --accept: string@accept-completer # Response content type
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
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --condition: string@condition-completer # Wait until a container state reaches the given condition.  Defaults to `not-running` if omitted or empty.  (default: not-running)
]: nothing -> record<StatusCode: int, Error: record<Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "condition" $condition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/wait" $qp)
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
  --accept: string@accept-completer # Response content type
  --v: oneof<nothing, bool> # Remove anonymous volumes associated with the container. (default: false)
  --force: oneof<nothing, bool> # If the container is running, kill it before removing it. (default: false)
  --link: oneof<nothing, bool> # Remove the specified link associated with the container. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "v" $v "scalar") (serialize-qp "force" $force "scalar") (serialize-qp "link" $link "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --accept: string@accept-completer # Response content type
  --path: string # Resource in the container’s filesystem to archive.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/archive" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let accept_val = "application/x-tar"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --accept: string@accept-completer # Response content type
  --path: string # Path to a directory in the container to extract the archive’s contents into. 
  --noOverwriteDirNonDir: string # If `1`, `true`, or `True` then it will be an error if unpacking the given content would cause an existing directory to be replaced with a non-directory and vice versa.
  --copyUIDGID: string # If `1`, `true`, then it will copy UID/GID maps to the dest file or dir
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "noOverwriteDirNonDir" $noOverwriteDirNonDir "scalar") (serialize-qp "copyUIDGID" $copyUIDGID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($id)/archive" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the images list.  Available filters:  - `before`=(`<image-name>[:<tag>]`,  `<image id>` or `<image@digest>`) - `dangling=true` - `label=key` or `label="key=value"` of an image label - `reference`=(`<image-name>[:<tag>]`) - `since`=(`<image-name>[:<tag>]`,  `<image id>` or `<image@digest>`) - `until=<timestamp>`
  --shared-size: oneof<nothing, bool> # Compute and show shared size as a `SharedSize` field on each image. (default: false)
  --digests: oneof<nothing, bool> # Show digest information as a `RepoDigests` field on each image. (default: false)
  --manifests: oneof<nothing, bool> # Include `Manifests` in the image summary. (default: false)
  --identity: oneof<nothing, bool> # Include `Identity` in each manifest summary. Requires `manifests=1`. (default: false)
]: nothing -> table<Id: string, ParentId: string, RepoTags: list<string>, RepoDigests: list<string>, Created: int, Size: int, SharedSize: int, Labels: record, Containers: int, Manifests: list<record>, Descriptor: record<mediaType: string, digest: string, size: int, urls: list, annotations: record, data: string, platform: record, artifactType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "shared-size" $shared_size "scalar") (serialize-qp "digests" $digests "scalar") (serialize-qp "manifests" $manifests "scalar") (serialize-qp "identity" $identity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --buildargs: string # JSON map of string pairs for build-time variables. Users pass these values at build-time. Docker uses the buildargs as the environment context for commands run via the `Dockerfile` RUN instruction, or for variable expansion in other `Dockerfile` instructions. This is not meant for passing secret values.  For example, the build arg `FOO=bar` would become `{"FOO":"bar"}` in JSON. This would result in the query parameter `buildargs={"FOO":"bar"}`. Note that `{"FOO":"bar"}` should be URI component encoded.  [Read more about the buildargs instruction.](https://docs.docker.com/engine/reference/builder/#arg)
  --shmsize: int # Size of `/dev/shm` in bytes. The size must be greater than 0. If omitted the system uses 64MB.
  --squash: oneof<nothing, bool> # Squash the resulting images layers into a single layer. *(Experimental release only.)*
  --labels: string # Arbitrary key/value labels to set on the image, as a JSON map of string pairs.
  --networkmode: string # Sets the networking mode for the run commands during build. Supported standard values are: `bridge`, `host`, `none`, and `container:<name|id>`. Any other value is taken as a custom network's name or ID to which this container should connect to.
  --platform: string # Platform in the format os[/arch[/variant]] (default: )
  --target: string # Target build stage (default: )
  --outputs: string # BuildKit output configuration in the format of a stringified JSON array of objects. Each object must have two top-level properties: `Type` and `Attrs`. The `Type` property must be set to 'moby'. The `Attrs` property is a map of attributes for the BuildKit output configuration. See https://docs.docker.com/build/exporters/oci-docker/ for more information.  Example:  ``` [{"Type":"moby","Attrs":{"type":"image","force-compression":"true","compression":"zstd"}}] ```  (default: )
  --version: string@version-completer # Version of the builder backend to use.  - `1` is the first generation classic (deprecated) builder in the Docker daemon (default) - `2` is [BuildKit](https://github.com/moby/buildkit)  (default: 1)
  --Content-type: string@Content-type-completer
  --X-Registry-Config: string # This is a base64-encoded JSON object with auth configurations for multiple registries that a build may refer to.  The key is a registry URL, and the value is an auth configuration object, [as described in the authentication section](#section/Authentication). For example:  ``` {   "docker.example.com": {     "username": "janedoe",     "password": "hunter2"   },   "https://index.docker.io/v1/": {     "username": "mobydock",     "password": "conta1n3rize14"   } } ```  Only the registry domain name (and port if not the default 443) are required. However, for legacy reasons, the Docker Hub registry must be specified with both a `https://` prefix and a `/v1/` suffix even though Docker will prefer to use the v2 registry API.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dockerfile" $dockerfile "scalar") (serialize-qp "t" $t "scalar") (serialize-qp "extrahosts" $extrahosts "scalar") (serialize-qp "remote" $remote "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "nocache" $nocache "scalar") (serialize-qp "cachefrom" $cachefrom "scalar") (serialize-qp "pull" $pull "scalar") (serialize-qp "rm" $rm "scalar") (serialize-qp "forcerm" $forcerm "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "memswap" $memswap "scalar") (serialize-qp "cpushares" $cpushares "scalar") (serialize-qp "cpusetcpus" $cpusetcpus "scalar") (serialize-qp "cpuperiod" $cpuperiod "scalar") (serialize-qp "cpuquota" $cpuquota "scalar") (serialize-qp "buildargs" $buildargs "scalar") (serialize-qp "shmsize" $shmsize "scalar") (serialize-qp "squash" $squash "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "networkmode" $networkmode "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "target" $target "scalar") (serialize-qp "outputs" $outputs "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/build" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-type": $Content_type, "X-Registry-Config": $X_Registry_Config} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --reserved-space: int # Amount of disk space in bytes to keep for cache (format: int64)
  --max-used-space: int # Maximum amount of disk space allowed to keep for cache (format: int64)
  --min-free-space: int # Target amount of free disk space after pruning (format: int64)
  --all: oneof<nothing, bool> # Remove all types of build cache
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the list of build cache objects.  Available filters:  - `until=<timestamp>` remove cache older than `<timestamp>`. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon's local time. - `id=<id>` - `parent=<id>` - `type=<string>` - `description=<string>` - `inuse` - `shared` - `private`
]: nothing -> record<CachesDeleted: list<string>, SpaceReclaimed: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reserved-space" $reserved_space "scalar") (serialize-qp "max-used-space" $max_used_space "scalar") (serialize-qp "min-free-space" $min_free_space "scalar") (serialize-qp "all" $all "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/build/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --fromImage: string # Name of the image to pull. If the name includes a tag or digest, specific behavior applies:  - If only `fromImage` includes a tag, that tag is used. - If both `fromImage` and `tag` are provided, `tag` takes precedence. - If `fromImage` includes a digest, the image is pulled by digest, and `tag` is ignored. - If neither a tag nor digest is specified, all tags are pulled.
  --fromSrc: string # Source to import. The value may be a URL from which the image can be retrieved or `-` to read the image from the request body. This parameter may only be used when importing an image.
  --repo: string # Repository name given to an image when it is imported. The repo may include a tag. This parameter may only be used when importing an image.
  --tag: string # Tag or digest. If empty when pulling an image, this causes all tags for the given image to be pulled.
  --message: string # Set commit message for imported image.
  --changes: list # Apply `Dockerfile` instructions to the image that is created, for example: `changes=ENV DEBUG=true`. Note that `ENV DEBUG=true` should be URI component encoded.  Supported `Dockerfile` instructions: `CMD`|`ENTRYPOINT`|`ENV`|`EXPOSE`|`ONBUILD`|`USER`|`VOLUME`|`WORKDIR`
  --platform: string # Platform in the format os[/arch[/variant]].  When used in combination with the `fromImage` option, the daemon checks if the given image is present in the local image cache with the given OS and Architecture, and otherwise attempts to pull the image. If the option is not set, the host's native OS and Architecture are used. If the given image does not exist in the local image cache, the daemon attempts to pull the image with the host's native OS and Architecture. If the given image does exists in the local image cache, but its OS or architecture does not match, a warning is produced.  When used with the `fromSrc` option to import an image from an archive, this option sets the platform information for the imported image. If the option is not set, the host's native OS and Architecture are used for the imported image.  (default: )
  --X-Registry-Auth: string # A base64url-encoded auth configuration.  Refer to the [authentication section](#section/Authentication) for details.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromImage" $fromImage "scalar") (serialize-qp "fromSrc" $fromSrc "scalar") (serialize-qp "repo" $repo "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "message" $message "scalar") (serialize-qp "changes" $changes "csv") (serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images/create" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --manifests: oneof<nothing, bool> # Include Manifests in the image summary.  The `manifests` and `platform` options are mutually exclusive, and an error is produced if both are set. (default: false)
  --platform: string # JSON-encoded OCI platform to select the platform-variant. If omitted, it defaults to any locally available platform, prioritizing the daemon's host platform.  If the daemon provides a multi-platform image store, this selects the platform-variant to show inspect. If the image is a single-platform image, or if the multi-platform image does not provide a variant matching the given platform, an error is returned.  The `platform` and `manifests` options are mutually exclusive, and an error is produced if both are set.  Example: `{"os": "linux", "architecture": "arm", "variant": "v5"}`
]: nothing -> record<Id: string, Descriptor: record<mediaType: string, digest: string, size: int, urls: list<string>, annotations: record, data: string, platform: record<architecture: string, os: string, os_version: string, os_features: list, variant: string>, artifactType: string>, Manifests: table<ID: string, Descriptor: record, Available: bool, Size: record, Kind: string, ImageData: record, AttestationData: record>, Identity: record<Signature: list<record>, Pull: list<record>, Build: list<record>>, RepoTags: list<string>, RepoDigests: list<string>, Comment: string, Created: string, Author: string, Config: record<User: string, ExposedPorts: record, Env: list<string>, Cmd: list<string>, Healthcheck: record<Test: list, Interval: int, Timeout: int, Retries: int, StartPeriod: int, StartInterval: int>, ArgsEscaped: bool, Volumes: record, WorkingDir: string, Entrypoint: list<string>, OnBuild: list<string>, Labels: record, StopSignal: string, Shell: list<string>>, Architecture: string, Variant: string, Os: string, OsVersion: string, Size: int, GraphDriver: record<Name: string, Data: record>, RootFS: record<Type: string, Layers: list<string>>, Metadata: record<LastTagTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "manifests" $manifests "scalar") (serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($name)/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attestation statements for an image
#
# GET /images/{name}/attestations
# operationId: ImageAttestations
export def "images-attestations ImageAttestations" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: list # JSON-encoded OCI platform to select the image variant whose attestations to return. If omitted, the daemon's default (host) platform is used.  Only one platform value is currently accepted; passing more than one returns an error. The parameter is declared as an array so the wire shape can accept multiple values in the future without an API version bump.  Example: `{"os": "linux", "architecture": "amd64"}`
  --type: list # In-toto predicate type URI to filter returned statements. May be repeated to accept any of several predicate types. If omitted, all statements are returned.  Example: `type=https://slsa.dev/provenance/v0.2&type=https://spdx.dev/Document`
  --statement: oneof<nothing, bool> # Include the verbatim in-toto statement body in each returned entry. Defaults to false; when omitted or false, only the descriptor and predicate type are returned and statement blobs are not read. (default: false)
]: nothing -> table<Descriptor: record<mediaType: string, digest: string, size: int, urls: list, annotations: record, data: string, platform: record, artifactType: string>, PredicateType: string, Statement: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "multi") (serialize-qp "type" $type "multi") (serialize-qp "statement" $statement "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($name)/attestations" $qp)
  let accept_val = "application/json"
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
  --platform: string # JSON-encoded OCI platform to select the platform-variant. If omitted, it defaults to any locally available platform, prioritizing the daemon's host platform.  If the daemon provides a multi-platform image store, this selects the platform-variant to show the history for. If the image is a single-platform image, or if the multi-platform image does not provide a variant matching the given platform, an error is returned.  Example: `{"os": "linux", "architecture": "arm", "variant": "v5"}`
]: nothing -> table<Id: string, Created: int, CreatedBy: string, Tags: list<string>, Size: int, Comment: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($name)/history" $qp)
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
  --accept: string@accept-completer # Response content type
  --tag: string # Tag of the image to push. For example, `latest`. If no tag is provided, all tags of the given image that are present in the local image store are pushed.
  --platform: string # JSON-encoded OCI platform to select the platform-variant to push. If not provided, all available variants will attempt to be pushed.  If the daemon provides a multi-platform image store, this selects the platform-variant to push to the registry. If the image is a single-platform image, or if the multi-platform image does not provide a variant matching the given platform, an error is returned.  Example: `{"os": "linux", "architecture": "arm", "variant": "v5"}`
  --X-Registry-Auth: string # A base64url-encoded auth configuration.  Refer to the [authentication section](#section/Authentication) for details.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($name)/push" $qp)
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
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
  --accept: string@accept-completer # Response content type
  --repo: string # The repository to tag in. For example, `someuser/someimage`.
  --tag: string # The name of the new tag.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "repo" $repo "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($name)/tag" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --platforms: list # Select platform-specific content to delete. Multiple values are accepted. Each platform is a OCI platform encoded as a JSON string.
]: nothing -> table<Untagged: string, Deleted: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "noprune" $noprune "scalar") (serialize-qp "platforms" $platforms "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the images list. Available filters:  - `is-official=(true|false)` - `stars=<number>` Matches images that has at least 'number' stars.
]: nothing -> table<description: string, is_official: bool, is_automated: bool, name: string, star_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
]: nothing -> record<ImagesDeleted: table<Untagged: string, Deleted: string>, SpaceReclaimed: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --username: string
  --password: string
  --serveraddress: string
]: any -> record<Status: string, IdentityToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth")
  let body = {username: $username, password: $password, serveraddress: $serveraddress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
]: nothing -> record<ID: string, Containers: int, ContainersRunning: int, ContainersPaused: int, ContainersStopped: int, Images: int, Driver: string, DriverStatus: list<list<string>>, DockerRootDir: string, Plugins: record<Volume: list<string>, Network: list<string>, Authorization: list<string>, Log: list<string>>, MemoryLimit: bool, SwapLimit: bool, CpuCfsPeriod: bool, CpuCfsQuota: bool, CPUShares: bool, CPUSet: bool, PidsLimit: bool, OomKillDisable: bool, IPv4Forwarding: bool, Debug: bool, NFd: int, NGoroutines: int, SystemTime: string, LoggingDriver: string, CgroupDriver: string, CgroupVersion: string, NEventsListener: int, KernelVersion: string, OperatingSystem: string, OSVersion: string, OSType: string, Architecture: string, NCPU: int, MemTotal: int, IndexServerAddress: string, RegistryConfig: record<InsecureRegistryCIDRs: list<string>, IndexConfigs: record, Mirrors: list<string>>, GenericResources: table<NamedResourceSpec: record, DiscreteResourceSpec: record>, HttpProxy: string, HttpsProxy: string, NoProxy: string, Name: string, Labels: list<string>, ExperimentalBuild: bool, ServerVersion: string, Runtimes: record, DefaultRuntime: string, Swarm: record<NodeID: string, NodeAddr: string, LocalNodeState: string, ControlAvailable: bool, Error: string, RemoteManagers: list<record>, Nodes: int, Managers: int, Cluster: record<ID: string, Version: record, CreatedAt: string, UpdatedAt: string, Spec: record, TLSInfo: record, RootRotationInProgress: bool, DataPathPort: int, DefaultAddrPool: list, SubnetSize: int>>, LiveRestoreEnabled: bool, Isolation: string, InitBinary: string, ContainerdCommit: record<ID: string>, RuncCommit: record<ID: string>, InitCommit: record<ID: string>, SecurityOptions: list<string>, ProductLicense: string, DefaultAddressPools: table<Base: string, Size: int>, FirewallBackend: record<Driver: string, Info: list<list>>, DiscoveredDevices: table<Source: string, ID: string>, NRI: record<Info: list<list>>, Warnings: list<string>, CDISpecDirs: list<string>, Containerd: record<Address: string, Namespaces: record<Containers: string, Plugins: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/info")
  let accept_val = "application/json"
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
]: nothing -> record<Platform: record<Name: string>, Components: table<Name: string, Version: string, Details: record>, Version: string, ApiVersion: string, MinAPIVersion: string, GitCommit: string, GoVersion: string, Os: string, Arch: string, KernelVersion: string, Experimental: bool, BuildTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/_ping")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ping
#
# HEAD /_ping
# operationId: SystemPingHead
export def "ping SystemPingHead" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/_ping")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new image from a container
#
# POST /commit
# operationId: ImageCommit
# --Healthcheck shape: {Test?: list, Interval?: int, Timeout?: int, Retries?: int, StartPeriod?: int, StartInterval?: int}
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
  --Hostname: string # The hostname to use for the container, as a valid RFC 1123 hostname.  (e.g. 439f4e91bd1d)
  --Domainname: string # The domain name to use for the container.
  --User: string # Commands run as this user inside the container. If omitted, commands run as the user specified in the image the container was started from.  Can be either user-name or UID, and optional group-name or GID, separated by a colon (`<user-name|UID>[<:group-name|GID>]`). (e.g. 123:456)
  --AttachStdin: oneof<nothing, bool> # Whether to attach to `stdin`. (default: false)
  --AttachStdout: oneof<nothing, bool> # Whether to attach to `stdout`. (default: true)
  --AttachStderr: oneof<nothing, bool> # Whether to attach to `stderr`. (default: true)
  --ExposedPorts: record # An object mapping ports to an empty object in the form:  `{"<port>/<tcp|udp|sctp>": {}}`  (e.g. {80/tcp: {}, 443/tcp: {}})
  --Tty: oneof<nothing, bool> # Attach standard streams to a TTY, including `stdin` if it is not closed.  (default: false)
  --OpenStdin: oneof<nothing, bool> # Open `stdin` (default: false)
  --StdinOnce: oneof<nothing, bool> # Close `stdin` after one attached client disconnects (default: false)
  --Env: list # A list of environment variables to set inside the container in the form `["VAR=value", ...]`. A variable without `=` is removed from the environment, rather than to have an empty value.  (e.g. [PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin])
  --Cmd: list # Command to run specified as a string or an array of strings.  (e.g. [/bin/sh])
  --Healthcheck: record # A test to perform to check that the container is healthy. Healthcheck commands should be side-effect free. — shape: {Test?: list, Interval?: int, Timeout?: int, Retries?: int, StartPeriod?: int, StartInterval?: int}
  --ArgsEscaped: oneof<nothing, bool> # Command is already escaped (Windows only) (default: false, e.g. false)
  --Image: string # The name (or reference) of the image to use when creating the container, or which was used when the container was created.  (e.g. example-image:1.0)
  --Volumes: record # An object mapping mount point paths inside the container to empty objects.
  --WorkingDir: string # The working directory for commands to run in. (e.g. /public/)
  --Entrypoint: list # The entry point for the container as a string or an array of strings.  If the array consists of exactly one empty string (`[""]`) then the entry point is reset to system default (i.e., the entry point used by docker when there is no `ENTRYPOINT` instruction in the `Dockerfile`).  (e.g. [])
  --NetworkDisabled: oneof<nothing, bool> # Disable networking for the container.
  --OnBuild: list # `ONBUILD` metadata that were defined in the image's `Dockerfile`.  (e.g. [])
  --Labels: record # User-defined key/value metadata. (e.g. {com.example.some-label: some-value, com.example.some-other-label: some-other-value})
  --StopSignal: string # Signal to stop a container as a string or unsigned integer.  (e.g. SIGTERM)
  --StopTimeout: int # Timeout to stop a container in seconds. (default: 10)
  --Shell: list # Shell for when `RUN`, `CMD`, and `ENTRYPOINT` uses a shell.  (e.g. [/bin/sh, -c])
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "container" $container "scalar") (serialize-qp "repo" $repo "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "comment" $comment "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "pause" $pause "scalar") (serialize-qp "changes" $changes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commit" $qp)
  let body = {Hostname: $Hostname, Domainname: $Domainname, User: $User, AttachStdin: $AttachStdin, AttachStdout: $AttachStdout, AttachStderr: $AttachStderr, ExposedPorts: $ExposedPorts, Tty: $Tty, OpenStdin: $OpenStdin, StdinOnce: $StdinOnce, Env: $Env, Cmd: $Cmd, Healthcheck: $Healthcheck, ArgsEscaped: $ArgsEscaped, Image: $Image, Volumes: $Volumes, WorkingDir: $WorkingDir, Entrypoint: $Entrypoint, NetworkDisabled: $NetworkDisabled, OnBuild: $OnBuild, Labels: $Labels, StopSignal: $StopSignal, StopTimeout: $StopTimeout, Shell: $Shell} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --accept: string@accept-completer-2 # Response content type
  --since: string # Show events created since this timestamp then stream new events.
  --until: string # Show events created until this timestamp then stop streaming.
  --filters: string # A JSON encoded value of filters (a `map[string][]string`) to process on the event list. Available filters:  - `config=<string>` config name or ID - `container=<string>` container name or ID - `daemon=<string>` daemon name or ID - `event=<string>` event type - `image=<string>` image name or ID - `label=<string>` image or container label - `network=<string>` network name or ID - `node=<string>` node ID - `plugin`=<string> plugin name or ID - `scope`=<string> local or swarm - `secret=<string>` secret name or ID - `service=<string>` service name or ID - `type=<string>` object to filter by, one of `container`, `image`, `volume`, `network`, `daemon`, `plugin`, `node`, `service`, `secret` or `config` - `volume=<string>` volume name
]: nothing -> record<Type: string, Action: string, Actor: record<ID: string, Attributes: record>, scope: string, time: int, timeNano: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = ($accept | default "application/jsonl")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --type: list # Object types, for which to compute and return data.
  --verbose: oneof<nothing, bool> # Show detailed information on space usage.  (default: false)
]: nothing -> record<ImageUsage: record<ActiveCount: int, TotalCount: int, Reclaimable: int, TotalSize: int, Items: list<any>>, ContainerUsage: record<ActiveCount: int, TotalCount: int, Reclaimable: int, TotalSize: int, Items: list<any>>, VolumeUsage: record<ActiveCount: int, TotalCount: int, Reclaimable: int, TotalSize: int, Items: list<any>>, BuildCacheUsage: record<ActiveCount: int, TotalCount: int, Reclaimable: int, TotalSize: int, Items: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "multi") (serialize-qp "verbose" $verbose "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/system/df" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --platform: list # JSON encoded OCI platform describing a platform which will be used to select a platform-specific image to be saved if the image is multi-platform. If not provided, the full multi-platform image will be saved.  Example: `{"os": "linux", "architecture": "arm", "variant": "v5"}`
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($name)/get" $qp)
  let accept_val = "application/x-tar"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --platform: list # JSON encoded OCI platform(s) which will be used to select the platform-specific image(s) to be saved if the image is multi-platform. If not provided, the full multi-platform image will be saved.  Example: `{"os": "linux", "architecture": "arm", "variant": "v5"}`
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "names" $names "csv") (serialize-qp "platform" $platform "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/images/get" $qp)
  let accept_val = "application/x-tar"
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
  --platform: list # JSON encoded OCI platform(s) which will be used to select the platform-specific image(s) to load if the image is multi-platform. If not provided, the full multi-platform image will be loaded.  Example: `{"os": "linux", "architecture": "arm", "variant": "v5"}`
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quiet" $quiet "scalar") (serialize-qp "platform" $platform "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/images/load" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --AttachStdin: oneof<nothing, bool> # Attach to `stdin` of the exec command.
  --AttachStdout: oneof<nothing, bool> # Attach to `stdout` of the exec command.
  --AttachStderr: oneof<nothing, bool> # Attach to `stderr` of the exec command.
  --ConsoleSize: list # Initial console size, as an `[height, width]` array. (e.g. [80, 64])
  --DetachKeys: string # Override the key sequence for detaching a container. Format is a single character `[a-Z]` or `ctrl-<value>` where `<value>` is one of: `a-z`, `@`, `^`, `[`, `,` or `_`.
  --Tty: oneof<nothing, bool> # Allocate a pseudo-TTY.
  --Env: list # A list of environment variables in the form `["VAR=value", ...]`.
  --Cmd: list # Command to run, as a string or array of strings.
  --Privileged: oneof<nothing, bool> # Runs the exec process with extended privileges. (default: false)
  --User: string # The user, and optionally, group to run the exec process inside the container. Format is one of: `user`, `user:group`, `uid`, or `uid:gid`.
  --WorkingDir: string # The working directory for the exec process inside the container.
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($id)/exec")
  let body = {AttachStdin: $AttachStdin, AttachStdout: $AttachStdout, AttachStderr: $AttachStderr, ConsoleSize: $ConsoleSize, DetachKeys: $DetachKeys, Tty: $Tty, Env: $Env, Cmd: $Cmd, Privileged: $Privileged, User: $User, WorkingDir: $WorkingDir} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --accept: string@accept-completer-1 # Response content type
  --Detach: oneof<nothing, bool> # Detach from the command. (e.g. false)
  --Tty: oneof<nothing, bool> # Allocate a pseudo-TTY. (e.g. true)
  --ConsoleSize: list # Initial console size, as an `[height, width]` array. (e.g. [80, 64])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/exec/($id)/start")
  let body = {Detach: $Detach, Tty: $Tty, ConsoleSize: $ConsoleSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/vnd.docker.raw-stream")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --accept: string@accept-completer # Response content type
  --h: int # Height of the TTY session in characters
  --w: int # Width of the TTY session in characters
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "h" $h "scalar") (serialize-qp "w" $w "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/exec/($id)/resize" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
]: nothing -> record<CanRemove: bool, DetachKeys: string, ID: string, Running: bool, ExitCode: int, ProcessConfig: record<privileged: bool, user: string, tty: bool, entrypoint: string, arguments: list<string>>, OpenStdin: bool, OpenStderr: bool, OpenStdout: bool, ContainerID: string, Pid: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/exec/($id)/json")
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
]: nothing -> record<Volumes: table<Name: string, Driver: string, Mountpoint: string, CreatedAt: string, Status: record, Labels: record, Scope: string, ClusterVolume: record, Options: record, UsageData: record>, Warnings: list<string>> {
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
# --ClusterVolumeSpec shape: {Group?: string, AccessMode?: record}
export def "volumes-create VolumeCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # The new volume's name. If not specified, Docker generates a name.  (e.g. tardis)
  --Driver: string # Name of the volume driver to use. (default: local, e.g. custom)
  --DriverOpts: record # A mapping of driver options and values. These options are passed directly to the driver and are driver specific.  (e.g. {device: tmpfs, o: size=100m,uid=1000, type: tmpfs})
  --Labels: record # User-defined key/value metadata. (e.g. {com.example.some-label: some-value, com.example.some-other-label: some-other-value})
  --ClusterVolumeSpec: record # Cluster-specific options used to create the volume. — shape: {Group?: string, AccessMode?: record}
]: any -> record<Name: string, Driver: string, Mountpoint: string, CreatedAt: string, Status: record, Labels: record, Scope: string, ClusterVolume: record<ID: string, Version: record<Index: int>, CreatedAt: string, UpdatedAt: string, Spec: record<Group: string, AccessMode: record>, Info: record<CapacityBytes: int, VolumeContext: record, VolumeID: string, AccessibleTopology: list>, PublishStatus: list<record>>, Options: record, UsageData: record<Size: int, RefCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/volumes/create")
  let body = {Name: $Name, Driver: $Driver, DriverOpts: $DriverOpts, Labels: $Labels, ClusterVolumeSpec: $ClusterVolumeSpec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
]: nothing -> record<Name: string, Driver: string, Mountpoint: string, CreatedAt: string, Status: record, Labels: record, Scope: string, ClusterVolume: record<ID: string, Version: record<Index: int>, CreatedAt: string, UpdatedAt: string, Spec: record<Group: string, AccessMode: record>, Info: record<CapacityBytes: int, VolumeContext: record, VolumeID: string, AccessibleTopology: list>, PublishStatus: list<record>>, Options: record, UsageData: record<Size: int, RefCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/volumes/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# "Update a volume. Valid only for Swarm cluster volumes"
#
# PUT /volumes/{name}
# operationId: VolumeUpdate
# --Spec shape: {Group?: string, AccessMode?: record}
export def "volumes VolumeUpdate" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # The version number of the volume being updated. This is required to avoid conflicting writes. Found in the volume's `ClusterVolume` field.  (format: int64)
  --Spec: record # Cluster-specific options used to create the volume. — shape: {Group?: string, AccessMode?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/volumes/($name)" $qp)
  let body = {Spec: $Spec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --accept: string@accept-completer # Response content type
  --force: oneof<nothing, bool> # Force the removal of the volume (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/volumes/($name)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --filters: string # Filters to process on the prune list, encoded as JSON (a `map[string][]string`).  Available filters: - `label` (`label=<key>`, `label=<key>=<value>`, `label!=<key>`, or `label!=<key>=<value>`) Prune volumes with (or without, in case `label!=...` is used) the specified labels. - `all` (`all=true`) - Consider all (local) volumes for pruning and not just anonymous volumes.
]: nothing -> record<VolumesDeleted: list<string>, SpaceReclaimed: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/volumes/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --filters: string # JSON encoded value of the filters (a `map[string][]string`) to process on the networks list.  Available filters:  - `dangling=<boolean>` When set to `true` (or `1`), returns all    networks that are not in use by a container. When set to `false`    (or `0`), only networks that are in use by one or more    containers are returned. - `driver=<driver-name>` Matches a network's driver. - `id=<network-id>` Matches all or part of a network ID. - `label=<key>` or `label=<key>=<value>` of a network label. - `name=<network-name>` Matches all or part of a network name. - `scope=["swarm"|"global"|"local"]` Filters networks by scope (`swarm`, `global`, or `local`). - `type=["custom"|"builtin"]` Filters networks by type. The `custom` keyword returns all user-defined networks.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/networks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
]: nothing -> record<Containers: record, Services: record, Status: record<IPAM: record<Subnets: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "verbose" $verbose "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a network
#
# POST /networks/create
# operationId: NetworkCreate
# --ConfigFrom shape: {Network?: string}
# --IPAM shape: {Driver?: string, Config?: list, Options?: record}
export def "networks-create NetworkCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Name: string # The network's name. (e.g. my_network)
  --Driver: string # Name of the network driver plugin to use. (default: bridge, e.g. bridge)
  --Scope: string # The level at which the network exists (e.g. `swarm` for cluster-wide or `local` for machine level).
  --Internal: oneof<nothing, bool> # Restrict external access to the network.
  --Attachable: oneof<nothing, bool> # Globally scoped network is manually attachable by regular containers from workers in swarm mode.  (e.g. true)
  --Ingress: oneof<nothing, bool> # Ingress network is the network which provides the routing-mesh in swarm mode.  (e.g. false)
  --ConfigOnly: oneof<nothing, bool> # Creates a config-only network. Config-only networks are placeholder networks for network configurations to be used by other networks. Config-only networks cannot be used directly to run containers or services.  (default: false, e.g. false)
  --ConfigFrom: record # The config-only network source to provide the configuration for this network. — shape: {Network?: string}
  --IPAM: record # shape: {Driver?: string, Config?: list, Options?: record}
  --EnableIPv4: oneof<nothing, bool> # Enable IPv4 on the network. (e.g. true)
  --EnableIPv6: oneof<nothing, bool> # Enable IPv6 on the network. (e.g. true)
  --Options: record # Network specific options to be used by the drivers. (e.g. {com.docker.network.bridge.default_bridge: true, com.docker.network.bridge.enable_icc: true, com.docker.network.bridge.enable_ip_masquerade: true, com.docker.network.bridge.host_binding_ipv4: 0.0.0.0, com.docker.network.bridge.name: docker0, com.docker.network.driver.mtu: 1500})
  --Labels: record # User-defined key/value metadata. (e.g. {com.example.some-label: some-value, com.example.some-other-label: some-other-value})
]: any -> record<Id: string, Warning: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/networks/create")
  let body = {Name: $Name, Driver: $Driver, Scope: $Scope, Internal: $Internal, Attachable: $Attachable, Ingress: $Ingress, ConfigOnly: $ConfigOnly, ConfigFrom: $ConfigFrom, IPAM: $IPAM, EnableIPv4: $EnableIPv4, EnableIPv6: $EnableIPv6, Options: $Options, Labels: $Labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Connect a container to a network
#
# POST /networks/{id}/connect
# operationId: NetworkConnect
# --EndpointConfig shape: {IPAMConfig?: record, Links?: list, MacAddress?: string, Aliases?: list, DriverOpts?: record, GwPriority?: int, NetworkID?: string, EndpointID?: string, Gateway?: string, IPAddress?: string, IPPrefixLen?: int, IPv6Gateway?: string, GlobalIPv6Address?: string, GlobalIPv6PrefixLen?: int, DNSNames?: list}
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
  --accept: string@accept-completer # Response content type
  Container: string # The ID or name of the container to connect to the network. (e.g. 3613f73ba0e4)
  --EndpointConfig: record # Configuration for a network endpoint. — shape: {IPAMConfig?: record, Links?: list, MacAddress?: string, Aliases?: list, DriverOpts?: record, GwPriority?: int, NetworkID?: string, EndpointID?: string, Gateway?: string, IPAddress?: string, IPPrefixLen?: int, IPv6Gateway?: string, GlobalIPv6Address?: string, GlobalIPv6PrefixLen?: int, DNSNames?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($id)/connect")
  let body = {Container: $Container, EndpointConfig: $EndpointConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --accept: string@accept-completer # Response content type
  Container: string # The ID or name of the container to disconnect from the network. (e.g. 3613f73ba0e4)
  --Force: oneof<nothing, bool> # Force the container to disconnect from the network. (default: false, e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($id)/disconnect")
  let body = {Container: $Container, Force: $Force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
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
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the plugin list.  Available filters:  - `capability=<capability name>` - `enable=<true>|<false>`
]: nothing -> table<Id: string, Name: string, Enabled: bool, Settings: record<Mounts: list, Env: list, Args: list, Devices: list>, PluginReference: string, Config: record<Description: string, Documentation: string, Interface: record, Entrypoint: list, WorkDir: string, User: record, Network: record, Linux: record, PropagatedMount: string, IpcHost: bool, PidHost: bool, Mounts: list, Env: list, Args: record, rootfs: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/plugins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
]: nothing -> table<Name: string, Description: string, Value: list<string>> {
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
  --X-Registry-Auth: string # A base64url-encoded auth configuration to use when pulling a plugin from a registry.  Refer to the [authentication section](#section/Authentication) for details.
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
]: nothing -> record<Id: string, Name: string, Enabled: bool, Settings: record<Mounts: list<record>, Env: list<string>, Args: list<string>, Devices: list<record>>, PluginReference: string, Config: record<Description: string, Documentation: string, Interface: record<Types: list, Socket: string, ProtocolScheme: string>, Entrypoint: list<string>, WorkDir: string, User: record<UID: int, GID: int>, Network: record<Type: string>, Linux: record<Capabilities: list, AllowAllDevices: bool, Devices: list>, PropagatedMount: string, IpcHost: bool, PidHost: bool, Mounts: list<record>, Env: list<record>, Args: record<Name: string, Description: string, Settable: list, Value: list>, rootfs: record<type: string, diff_ids: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plugins/($name)/json")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --force: oneof<nothing, bool> # Disable the plugin before removing. This may result in issues if the plugin is in use by a container.  (default: false)
]: nothing -> record<Id: string, Name: string, Enabled: bool, Settings: record<Mounts: list<record>, Env: list<string>, Args: list<string>, Devices: list<record>>, PluginReference: string, Config: record<Description: string, Documentation: string, Interface: record<Types: list, Socket: string, ProtocolScheme: string>, Entrypoint: list<string>, WorkDir: string, User: record<UID: int, GID: int>, Network: record<Type: string>, Linux: record<Capabilities: list, AllowAllDevices: bool, Devices: list>, PropagatedMount: string, IpcHost: bool, PidHost: bool, Mounts: list<record>, Env: list<record>, Args: record<Name: string, Description: string, Settable: list, Value: list>, rootfs: record<type: string, diff_ids: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/plugins/($name)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --accept: string@accept-completer # Response content type
  --timeout: int # Set the HTTP client timeout (in seconds) (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/plugins/($name)/enable" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --accept: string@accept-completer # Response content type
  --force: oneof<nothing, bool> # Force disable a plugin even if still in use.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/plugins/($name)/disable" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --accept: string@accept-completer # Response content type
  --remote: string # Remote reference to upgrade to.  The `:latest` tag is optional, and is used as the default if omitted.
  --X-Registry-Auth: string # A base64url-encoded auth configuration to use when pulling a plugin from a registry.  Refer to the [authentication section](#section/Authentication) for details.
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
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --accept: string@accept-completer # Response content type
  --name: string # The name of the plugin. The `:latest` tag is optional, and is the default if omitted.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/plugins/create" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plugins/($name)/push")
  let accept_val = ($accept | default "application/json")
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
  --accept: string@accept-completer # Response content type
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plugins/($name)/set")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
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
  --filters: string # Filters to process on the nodes list, encoded as JSON (a `map[string][]string`).  Available filters: - `id=<node id>` - `label=<engine label>` - `membership=`(`accepted`|`pending`)` - `name=<node name>` - `node.label=<node label>` - `role=`(`manager`|`worker`)`
]: nothing -> table<ID: string, Version: record<Index: int>, CreatedAt: string, UpdatedAt: string, Spec: record<Name: string, Labels: record, Role: string, Availability: string>, Description: record<Hostname: string, Platform: record, Resources: record, Engine: record, TLSInfo: record>, Status: record<State: string, Message: string, Addr: string>, ManagerStatus: record<Leader: bool, Reachability: string, Addr: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nodes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
]: nothing -> record<ID: string, Version: record<Index: int>, CreatedAt: string, UpdatedAt: string, Spec: record<Name: string, Labels: record, Role: string, Availability: string>, Description: record<Hostname: string, Platform: record<Architecture: string, OS: string>, Resources: record<NanoCPUs: int, MemoryBytes: int, GenericResources: list>, Engine: record<EngineVersion: string, Labels: record, Plugins: list>, TLSInfo: record<TrustRoot: string, CertIssuerSubject: string, CertIssuerPublicKey: string>>, Status: record<State: string, Message: string, Addr: string>, ManagerStatus: record<Leader: bool, Reachability: string, Addr: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/nodes/($id)")
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
  --accept: string@accept-completer # Response content type
  --force: oneof<nothing, bool> # Force remove a node from the swarm (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nodes/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --accept: string@accept-completer # Response content type
  --version: int # The version number of the node object being updated. This is required to avoid conflicting writes.  (format: int64)
  --Name: string # Name for the node. (e.g. my-node)
  --Labels: record # User-defined key/value metadata.
  --Role: string@Role-completer # Role of the node. (e.g. manager)
  --Availability: string@Availability-completer # Availability of the node. (e.g. active)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nodes/($id)/update" $qp)
  let body = {Name: $Name, Labels: $Labels, Role: $Role, Availability: $Availability} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
# --Spec shape: {Name?: string, Labels?: record, Orchestration?: record, Raft?: record, Dispatcher?: record, CAConfig?: record, EncryptionConfig?: record, TaskDefaults?: record}
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
  --ListenAddr: string # Listen address used for inter-manager communication, as well as determining the networking interface used for the VXLAN Tunnel Endpoint (VTEP). This can either be an address/port combination in the form `192.168.1.1:4567`, or an interface followed by a port number, like `eth0:4567`. If the port number is omitted, the default swarm listening port is used.
  --AdvertiseAddr: string # Externally reachable address advertised to other nodes. This can either be an address/port combination in the form `192.168.1.1:4567`, or an interface followed by a port number, like `eth0:4567`. If the port number is omitted, the port number from the listen address is used. If `AdvertiseAddr` is not specified, it will be automatically detected when possible.
  --DataPathAddr: string # Address or interface to use for data path traffic (format: `<ip|interface>`), for example,  `192.168.1.1`, or an interface, like `eth0`. If `DataPathAddr` is unspecified, the same address as `AdvertiseAddr` is used.  The `DataPathAddr` specifies the address that global scope network drivers will publish towards other  nodes in order to reach the containers running on this node. Using this parameter it is possible to separate the container data traffic from the management traffic of the cluster.
  --DataPathPort: int # DataPathPort specifies the data path port number for data traffic. Acceptable port range is 1024 to 49151. if no port is set or is set to 0, default port 4789 will be used.  (format: uint32)
  --DefaultAddrPool: list # Default Address Pool specifies default subnet pools for global scope networks.
  --ForceNewCluster: oneof<nothing, bool> # Force creation of a new swarm.
  --SubnetSize: int # SubnetSize specifies the subnet size of the networks created from the default subnet pool.  (format: uint32)
  --Spec: record # User modifiable swarm configuration. — shape: {Name?: string, Labels?: record, Orchestration?: record, Raft?: record, Dispatcher?: record, CAConfig?: record, EncryptionConfig?: record, TaskDefaults?: record}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/swarm/init")
  let body = {ListenAddr: $ListenAddr, AdvertiseAddr: $AdvertiseAddr, DataPathAddr: $DataPathAddr, DataPathPort: $DataPathPort, DefaultAddrPool: $DefaultAddrPool, ForceNewCluster: $ForceNewCluster, SubnetSize: $SubnetSize, Spec: $Spec} | compact
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
  --accept: string@accept-completer # Response content type
  ListenAddr: string # Listen address used for inter-manager communication if the node gets promoted to manager, as well as determining the networking interface used for the VXLAN Tunnel Endpoint (VTEP). This is required for joining a swarm. If the port number is omitted, the default swarm listening port is used.
  --AdvertiseAddr: string # Externally reachable address advertised to other nodes. This can either be an address/port combination in the form `192.168.1.1:4567`, or an interface followed by a port number, like `eth0:4567`. If the port number is omitted, the port number from the listen address is used. If `AdvertiseAddr` is not specified, it will be automatically detected when possible.
  --DataPathAddr: string # Address or interface to use for data path traffic (format: `<ip|interface>`), for example,  `192.168.1.1`, or an interface, like `eth0`. If `DataPathAddr` is unspecified, the same address as `AdvertiseAddr` is used.  The `DataPathAddr` specifies the address that global scope network drivers will publish towards other nodes in order to reach the containers running on this node. Using this parameter it is possible to separate the container data traffic from the management traffic of the cluster.
  RemoteAddrs: list # Addresses of manager nodes already participating in the swarm.
  JoinToken: string # Secret token for joining this swarm.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/swarm/join")
  let body = {ListenAddr: $ListenAddr, AdvertiseAddr: $AdvertiseAddr, DataPathAddr: $DataPathAddr, RemoteAddrs: $RemoteAddrs, JoinToken: $JoinToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
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
  --accept: string@accept-completer # Response content type
  --force: oneof<nothing, bool> # Force leave swarm, even if this is the last manager or that it will break the cluster.  (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/swarm/leave" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a swarm
#
# POST /swarm/update
# operationId: SwarmUpdate
# --Orchestration shape: {TaskHistoryRetentionLimit?: int}
# --Raft shape: {SnapshotInterval?: int, KeepOldSnapshots?: int, LogEntriesForSlowFollowers?: int, ElectionTick?: int, HeartbeatTick?: int}
# --Dispatcher shape: {HeartbeatPeriod?: int}
# --CAConfig shape: {NodeCertExpiry?: int, ExternalCAs?: list, SigningCACert?: string, SigningCAKey?: string, ForceRotate?: int}
# --EncryptionConfig shape: {AutoLockManagers?: bool}
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
  --accept: string@accept-completer # Response content type
  --version: int # The version number of the swarm object being updated. This is required to avoid conflicting writes.  (format: int64)
  --rotateWorkerToken: oneof<nothing, bool> # Rotate the worker join token. (default: false)
  --rotateManagerToken: oneof<nothing, bool> # Rotate the manager join token. (default: false)
  --rotateManagerUnlockKey: oneof<nothing, bool> # Rotate the manager unlock key. (default: false)
  --Name: string # Name of the swarm. (e.g. default)
  --Labels: record # User-defined key/value metadata. (e.g. {com.example.corp.type: production, com.example.corp.department: engineering})
  --Orchestration: record # Orchestration configuration. — shape: {TaskHistoryRetentionLimit?: int}
  --Raft: record # Raft configuration. — shape: {SnapshotInterval?: int, KeepOldSnapshots?: int, LogEntriesForSlowFollowers?: int, ElectionTick?: int, HeartbeatTick?: int}
  --Dispatcher: record # Dispatcher configuration. — shape: {HeartbeatPeriod?: int}
  --CAConfig: record # CA configuration. — shape: {NodeCertExpiry?: int, ExternalCAs?: list, SigningCACert?: string, SigningCAKey?: string, ForceRotate?: int}
  --EncryptionConfig: record # Parameters related to encryption-at-rest. — shape: {AutoLockManagers?: bool}
  --TaskDefaults: record # Defaults for creating tasks in this cluster. — shape: {LogDriver?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "rotateWorkerToken" $rotateWorkerToken "scalar") (serialize-qp "rotateManagerToken" $rotateManagerToken "scalar") (serialize-qp "rotateManagerUnlockKey" $rotateManagerUnlockKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/swarm/update" $qp)
  let body = {Name: $Name, Labels: $Labels, Orchestration: $Orchestration, Raft: $Raft, Dispatcher: $Dispatcher, CAConfig: $CAConfig, EncryptionConfig: $EncryptionConfig, TaskDefaults: $TaskDefaults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
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
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the services list.  Available filters:  - `id=<service id>` - `label=<service label>` - `mode=["replicated"|"global"]` - `name=<service name>`
  --status: oneof<nothing, bool> # Include service status, with count of running and desired tasks.
]: nothing -> table<ID: string, Version: record<Index: int>, CreatedAt: string, UpdatedAt: string, Spec: record<Name: string, Labels: record, TaskTemplate: record, Mode: record, UpdateConfig: record, RollbackConfig: record, Networks: list, EndpointSpec: record>, Endpoint: record<Spec: record, Ports: list, VirtualIPs: list>, UpdateStatus: record<State: string, StartedAt: string, CompletedAt: string, Message: string>, ServiceStatus: record<RunningTasks: int, DesiredTasks: int, CompletedTasks: int>, JobStatus: record<JobIteration: record, LastExecution: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a service
#
# POST /services/create
# operationId: ServiceCreate
# --TaskTemplate shape: {PluginSpec?: record, ContainerSpec?: record, NetworkAttachmentSpec?: record, Resources?: record, RestartPolicy?: record, Placement?: record, ForceUpdate?: int, Runtime?: string, Networks?: list, LogDriver?: record}
# --Mode shape: {Replicated?: record, Global?: record, ReplicatedJob?: record, GlobalJob?: record}
# --UpdateConfig shape: {Parallelism?: int, Delay?: int, FailureAction?: "continue"|"pause"|"rollback", Monitor?: int, MaxFailureRatio?: float, Order?: "stop-first"|"start-first"}
# --RollbackConfig shape: {Parallelism?: int, Delay?: int, FailureAction?: "continue"|"pause", Monitor?: int, MaxFailureRatio?: float, Order?: "stop-first"|"start-first"}
# --Networks item shape: {Target?: string, Aliases?: list, DriverOpts?: record}
# --EndpointSpec shape: {Mode?: "vip"|"dnsrr", Ports?: list}
export def "services-create ServiceCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Registry-Auth: string # A base64url-encoded auth configuration for pulling from private registries.  Refer to the [authentication section](#section/Authentication) for details.
  --Name: string # Name of the service.
  --Labels: record # User-defined key/value metadata.
  --TaskTemplate: record # User modifiable task configuration. — shape: {PluginSpec?: record, ContainerSpec?: record, NetworkAttachmentSpec?: record, Resources?: record, RestartPolicy?: record, Placement?: record, ForceUpdate?: int, Runtime?: string, Networks?: list, LogDriver?: record}
  --Mode: record # Scheduling mode for the service. — shape: {Replicated?: record, Global?: record, ReplicatedJob?: record, GlobalJob?: record}
  --UpdateConfig: record # Specification for the update strategy of the service. — shape: {Parallelism?: int, Delay?: int, FailureAction?: "continue"|"pause"|"rollback", Monitor?: int, MaxFailureRatio?: float, Order?: "stop-first"|"start-first"}
  --RollbackConfig: record # Specification for the rollback strategy of the service. — shape: {Parallelism?: int, Delay?: int, FailureAction?: "continue"|"pause", Monitor?: int, MaxFailureRatio?: float, Order?: "stop-first"|"start-first"}
  --Networks: list # Specifies which networks the service should attach to.  Deprecated: This field is deprecated since v1.44. The Networks field in TaskSpec should be used instead. — item shape: {Target?: string, Aliases?: list, DriverOpts?: record}
  --EndpointSpec: record # Properties that can be configured to access and load balance a service. — shape: {Mode?: "vip"|"dnsrr", Ports?: list}
]: any -> record<ID: string, Warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/services/create")
  let body = {Name: $Name, Labels: $Labels, TaskTemplate: $TaskTemplate, Mode: $Mode, UpdateConfig: $UpdateConfig, RollbackConfig: $RollbackConfig, Networks: $Networks, EndpointSpec: $EndpointSpec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
]: nothing -> record<ID: string, Version: record<Index: int>, CreatedAt: string, UpdatedAt: string, Spec: record<Name: string, Labels: record, TaskTemplate: record<PluginSpec: record, ContainerSpec: record, NetworkAttachmentSpec: record, Resources: record, RestartPolicy: record, Placement: record, ForceUpdate: int, Runtime: string, Networks: list, LogDriver: record>, Mode: record<Replicated: record, Global: record, ReplicatedJob: record, GlobalJob: record>, UpdateConfig: record<Parallelism: int, Delay: int, FailureAction: string, Monitor: int, MaxFailureRatio: float, Order: string>, RollbackConfig: record<Parallelism: int, Delay: int, FailureAction: string, Monitor: int, MaxFailureRatio: float, Order: string>, Networks: list<record>, EndpointSpec: record<Mode: string, Ports: list>>, Endpoint: record<Spec: record<Mode: string, Ports: list>, Ports: list<record>, VirtualIPs: list<record>>, UpdateStatus: record<State: string, StartedAt: string, CompletedAt: string, Message: string>, ServiceStatus: record<RunningTasks: int, DesiredTasks: int, CompletedTasks: int>, JobStatus: record<JobIteration: record<Index: int>, LastExecution: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "insertDefaults" $insertDefaults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/services/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a service
#
# POST /services/{id}/update
# operationId: ServiceUpdate
# --TaskTemplate shape: {PluginSpec?: record, ContainerSpec?: record, NetworkAttachmentSpec?: record, Resources?: record, RestartPolicy?: record, Placement?: record, ForceUpdate?: int, Runtime?: string, Networks?: list, LogDriver?: record}
# --Mode shape: {Replicated?: record, Global?: record, ReplicatedJob?: record, GlobalJob?: record}
# --UpdateConfig shape: {Parallelism?: int, Delay?: int, FailureAction?: "continue"|"pause"|"rollback", Monitor?: int, MaxFailureRatio?: float, Order?: "stop-first"|"start-first"}
# --RollbackConfig shape: {Parallelism?: int, Delay?: int, FailureAction?: "continue"|"pause", Monitor?: int, MaxFailureRatio?: float, Order?: "stop-first"|"start-first"}
# --Networks item shape: {Target?: string, Aliases?: list, DriverOpts?: record}
# --EndpointSpec shape: {Mode?: "vip"|"dnsrr", Ports?: list}
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
  --version: int # The version number of the service object being updated. This is required to avoid conflicting writes. This version number should be the value as currently set on the service *before* the update. You can find the current version by calling `GET /services/{id}`
  --registryAuthFrom: string@registryAuthFrom-completer # If the `X-Registry-Auth` header is not specified, this parameter indicates where to find registry authorization credentials.  (default: spec)
  --rollback: string # Set to this parameter to `previous` to cause a server-side rollback to the previous service spec. The supplied spec will be ignored in this case.
  --X-Registry-Auth: string # A base64url-encoded auth configuration for pulling from private registries.  Refer to the [authentication section](#section/Authentication) for details.
  --Name: string # Name of the service.
  --Labels: record # User-defined key/value metadata.
  --TaskTemplate: record # User modifiable task configuration. — shape: {PluginSpec?: record, ContainerSpec?: record, NetworkAttachmentSpec?: record, Resources?: record, RestartPolicy?: record, Placement?: record, ForceUpdate?: int, Runtime?: string, Networks?: list, LogDriver?: record}
  --Mode: record # Scheduling mode for the service. — shape: {Replicated?: record, Global?: record, ReplicatedJob?: record, GlobalJob?: record}
  --UpdateConfig: record # Specification for the update strategy of the service. — shape: {Parallelism?: int, Delay?: int, FailureAction?: "continue"|"pause"|"rollback", Monitor?: int, MaxFailureRatio?: float, Order?: "stop-first"|"start-first"}
  --RollbackConfig: record # Specification for the rollback strategy of the service. — shape: {Parallelism?: int, Delay?: int, FailureAction?: "continue"|"pause", Monitor?: int, MaxFailureRatio?: float, Order?: "stop-first"|"start-first"}
  --Networks: list # Specifies which networks the service should attach to.  Deprecated: This field is deprecated since v1.44. The Networks field in TaskSpec should be used instead. — item shape: {Target?: string, Aliases?: list, DriverOpts?: record}
  --EndpointSpec: record # Properties that can be configured to access and load balance a service. — shape: {Mode?: "vip"|"dnsrr", Ports?: list}
]: any -> record<Warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "registryAuthFrom" $registryAuthFrom "scalar") (serialize-qp "rollback" $rollback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($id)/update" $qp)
  let body = {Name: $Name, Labels: $Labels, TaskTemplate: $TaskTemplate, Mode: $Mode, UpdateConfig: $UpdateConfig, RollbackConfig: $RollbackConfig, Networks: $Networks, EndpointSpec: $EndpointSpec} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --follow: oneof<nothing, bool> # Keep connection after returning logs. (default: false)
  --stdout: oneof<nothing, bool> # Return logs from `stdout` (default: false)
  --stderr: oneof<nothing, bool> # Return logs from `stderr` (default: false)
  --since: int # Only return logs since this time, as a UNIX timestamp (default: 0)
  --timestamps: oneof<nothing, bool> # Add timestamps to every log line (default: false)
  --tail: string # Only return this number of log lines from the end of the logs. Specify as an integer or `all` to output all log lines.  (default: all)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar") (serialize-qp "follow" $follow "scalar") (serialize-qp "stdout" $stdout "scalar") (serialize-qp "stderr" $stderr "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "timestamps" $timestamps "scalar") (serialize-qp "tail" $tail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/services/($id)/logs" $qp)
  let accept_val = ($accept | default "application/vnd.docker.raw-stream")
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
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the tasks list.  Available filters:  - `desired-state=(running | shutdown | accepted)` - `id=<task id>` - `label=key` or `label="key=value"` - `name=<task name>` - `node=<node id or name>` - `service=<service name>`
]: nothing -> table<ID: string, Version: record<Index: int>, CreatedAt: string, UpdatedAt: string, Name: string, Labels: record, Spec: record<PluginSpec: record, ContainerSpec: record, NetworkAttachmentSpec: record, Resources: record, RestartPolicy: record, Placement: record, ForceUpdate: int, Runtime: string, Networks: list, LogDriver: record>, ServiceID: string, Slot: int, NodeID: string, AssignedGenericResources: list<record>, Status: record<Timestamp: string, State: string, Message: string, Err: string, ContainerStatus: record, PortStatus: record>, DesiredState: string, JobIteration: record<Index: int>> {
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
]: nothing -> record<ID: string, Version: record<Index: int>, CreatedAt: string, UpdatedAt: string, Name: string, Labels: record, Spec: record<PluginSpec: record<Name: string, Remote: string, Disabled: bool, PluginPrivilege: list>, ContainerSpec: record<Image: string, Labels: record, Command: list, Args: list, Hostname: string, Env: list, Dir: string, User: string, Groups: list, Privileges: record, TTY: bool, OpenStdin: bool, ReadOnly: bool, Mounts: list, StopSignal: string, StopGracePeriod: int, HealthCheck: record, Hosts: list, DNSConfig: record, Secrets: list, OomScoreAdj: int, Configs: list, Isolation: string, Init: bool, Sysctls: record, CapabilityAdd: list, CapabilityDrop: list, Ulimits: list>, NetworkAttachmentSpec: record<ContainerID: string>, Resources: record<Limits: record, Reservations: record, SwapBytes: int, MemorySwappiness: int>, RestartPolicy: record<Condition: string, Delay: int, MaxAttempts: int, Window: int>, Placement: record<Constraints: list, Preferences: list, MaxReplicas: int, Platforms: list>, ForceUpdate: int, Runtime: string, Networks: list<record>, LogDriver: record<Name: string, Options: record>>, ServiceID: string, Slot: int, NodeID: string, AssignedGenericResources: table<NamedResourceSpec: record, DiscreteResourceSpec: record>, Status: record<Timestamp: string, State: string, Message: string, Err: string, ContainerStatus: record<ContainerID: string, PID: int, ExitCode: int>, PortStatus: record<Ports: list>>, DesiredState: string, JobIteration: record<Index: int>> {
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
  --follow: oneof<nothing, bool> # Keep connection after returning logs. (default: false)
  --stdout: oneof<nothing, bool> # Return logs from `stdout` (default: false)
  --stderr: oneof<nothing, bool> # Return logs from `stderr` (default: false)
  --since: int # Only return logs since this time, as a UNIX timestamp (default: 0)
  --timestamps: oneof<nothing, bool> # Add timestamps to every log line (default: false)
  --tail: string # Only return this number of log lines from the end of the logs. Specify as an integer or `all` to output all log lines.  (default: all)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "details" $details "scalar") (serialize-qp "follow" $follow "scalar") (serialize-qp "stdout" $stdout "scalar") (serialize-qp "stderr" $stderr "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "timestamps" $timestamps "scalar") (serialize-qp "tail" $tail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($id)/logs" $qp)
  let accept_val = ($accept | default "application/vnd.docker.raw-stream")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the secrets list.  Available filters:  - `id=<secret id>` - `label=<key> or label=<key>=value` - `name=<secret name>` - `names=<secret name>`
]: nothing -> table<ID: string, Version: record<Index: int>, CreatedAt: string, UpdatedAt: string, Spec: record<Name: string, Labels: record, Data: string, Driver: record, Templating: record>> {
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
# --Templating shape: {Name: string, Options?: record}
export def "secrets-create SecretCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # User-defined name of the secret.
  --Labels: record # User-defined key/value metadata. (e.g. {com.example.some-label: some-value, com.example.some-other-label: some-other-value})
  --Data: string # Data is the data to store as a secret, formatted as a standard base64-encoded ([RFC 4648](https://tools.ietf.org/html/rfc4648#section-4)) string. It must be empty if the Driver field is set, in which case the data is loaded from an external secret store. The maximum allowed size is 500KB, as defined in [MaxSecretSize](https://pkg.go.dev/github.com/moby/swarmkit/v2@v2.0.0/api/validation#MaxSecretSize).  This field is only used to _create_ a secret, and is not returned by other endpoints.  (e.g. )
  --Driver: record # Driver represents a driver (network, logging, secrets). — shape: {Name: string, Options?: record}
  --Templating: record # Driver represents a driver (network, logging, secrets). — shape: {Name: string, Options?: record}
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/secrets/create")
  let body = {Name: $Name, Labels: $Labels, Data: $Data, Driver: $Driver, Templating: $Templating} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
]: nothing -> record<ID: string, Version: record<Index: int>, CreatedAt: string, UpdatedAt: string, Spec: record<Name: string, Labels: record, Data: string, Driver: record<Name: string, Options: record>, Templating: record<Name: string, Options: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/secrets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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

# Update a Secret
#
# POST /secrets/{id}/update
# operationId: SecretUpdate
# --Driver shape: {Name: string, Options?: record}
# --Templating shape: {Name: string, Options?: record}
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
  --accept: string@accept-completer # Response content type
  --version: int # The version number of the secret object being updated. This is required to avoid conflicting writes.  (format: int64)
  --Name: string # User-defined name of the secret.
  --Labels: record # User-defined key/value metadata. (e.g. {com.example.some-label: some-value, com.example.some-other-label: some-other-value})
  --Data: string # Data is the data to store as a secret, formatted as a standard base64-encoded ([RFC 4648](https://tools.ietf.org/html/rfc4648#section-4)) string. It must be empty if the Driver field is set, in which case the data is loaded from an external secret store. The maximum allowed size is 500KB, as defined in [MaxSecretSize](https://pkg.go.dev/github.com/moby/swarmkit/v2@v2.0.0/api/validation#MaxSecretSize).  This field is only used to _create_ a secret, and is not returned by other endpoints.  (e.g. )
  --Driver: record # Driver represents a driver (network, logging, secrets). — shape: {Name: string, Options?: record}
  --Templating: record # Driver represents a driver (network, logging, secrets). — shape: {Name: string, Options?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/secrets/($id)/update" $qp)
  let body = {Name: $Name, Labels: $Labels, Data: $Data, Driver: $Driver, Templating: $Templating} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
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
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the configs list.  Available filters:  - `id=<config id>` - `label=<key> or label=<key>=value` - `name=<config name>` - `names=<config name>`
]: nothing -> table<ID: string, Version: record<Index: int>, CreatedAt: string, UpdatedAt: string, Spec: record<Name: string, Labels: record, Data: string, Templating: record>> {
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
# --Templating shape: {Name: string, Options?: record}
export def "configs-create ConfigCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Name: string # User-defined name of the config.
  --Labels: record # User-defined key/value metadata.
  --Data: string # Data is the data to store as a config, formatted as a standard base64-encoded ([RFC 4648](https://tools.ietf.org/html/rfc4648#section-4)) string. The maximum allowed size is 1000KB, as defined in [MaxConfigSize](https://pkg.go.dev/github.com/moby/swarmkit/v2@v2.0.0-20250103191802-8c1959736554/manager/controlapi#MaxConfigSize).
  --Templating: record # Driver represents a driver (network, logging, secrets). — shape: {Name: string, Options?: record}
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configs/create")
  let body = {Name: $Name, Labels: $Labels, Data: $Data, Templating: $Templating} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
]: nothing -> record<ID: string, Version: record<Index: int>, CreatedAt: string, UpdatedAt: string, Spec: record<Name: string, Labels: record, Data: string, Templating: record<Name: string, Options: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/configs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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

# Update a Config
#
# POST /configs/{id}/update
# operationId: ConfigUpdate
# --Templating shape: {Name: string, Options?: record}
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
  --accept: string@accept-completer # Response content type
  --version: int # The version number of the config object being updated. This is required to avoid conflicting writes.  (format: int64)
  --Name: string # User-defined name of the config.
  --Labels: record # User-defined key/value metadata.
  --Data: string # Data is the data to store as a config, formatted as a standard base64-encoded ([RFC 4648](https://tools.ietf.org/html/rfc4648#section-4)) string. The maximum allowed size is 1000KB, as defined in [MaxConfigSize](https://pkg.go.dev/github.com/moby/swarmkit/v2@v2.0.0-20250103191802-8c1959736554/manager/controlapi#MaxConfigSize).
  --Templating: record # Driver represents a driver (network, logging, secrets). — shape: {Name: string, Options?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/configs/($id)/update" $qp)
  let body = {Name: $Name, Labels: $Labels, Data: $Data, Templating: $Templating} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
]: nothing -> record<Descriptor: record<mediaType: string, digest: string, size: int, urls: list<string>, annotations: record, data: string, platform: record<architecture: string, os: string, os_version: string, os_features: list, variant: string>, artifactType: string>, Platforms: table<architecture: string, os: string, os_version: string, os_features: list, variant: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/distribution/($name)/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let accept_val = "application/vnd.docker.raw-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
