# Auto-generated client for supports a RESTful API for the Libpod library v5.0.0
# Source: https://storage.googleapis.com/libpod-master-releases/swagger-latest.yaml
# Auth: --token flag or $env.SUPPORTS_A_RESTFUL_API_FOR_THE_LIBPOD_LIBRARY_TOKEN

const BASE_URL = "http://podman.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SUPPORTS_A_RESTFUL_API_FOR_THE_LIBPOD_LIBRARY_TOKEN | default "" }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def base-url-completer [] { ["http://podman.io" "https://podman.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def Content-Type-completer [] { ["application/x-tar"] }
def diffType-completer [] { ["all" "container" "image"] }
def accept-completer [] { ["application/json" "application/octet-stream" "text/plain"] }
def Content-Type-completer-1 [] { ["application/x-tar" "multipart/form-data"] }
def accept-completer-1 [] { ["application/json" "text/plain"] }
def restartPolicy-completer [] { ["always" "no" "on-abnormal" "on-abort" "on-failure" "on-success" "on-watchdog"] }
def accept-completer-2 [] { ["application/json" "text/vnd.yaml"] }
def Content-Type-completer-2 [] { ["application/x-tar" "plain/text"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "auth SystemAuth" } } | get name | first)
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
  --body-auth: string
  --email: string # Email is an optional value associated with the username. This field is deprecated and will be removed in a later version of docker.
  --identitytoken: string # IdentityToken is used to authenticate the user and get an access token for the registry.
  --password: string
  --registrytoken: string # RegistryToken is a bearer token to be sent to a registry
  --serveraddress: string
  --username: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth")
  let body = {auth: $body_auth, email: $email, identitytoken: $identitytoken, password: $password, registrytoken: $registrytoken, serveraddress: $serveraddress, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Build image
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
  --dockerfile: string # Path within the build context to the `Dockerfile`. This is ignored if remote is specified and points to an external `Dockerfile`.  (default: Dockerfile)
  --t: string # A name and optional tag to apply to the image in the `name:tag` format. If you omit the tag, the default latest value is assumed. You can provide several t parameters. (default: latest)
  --extrahosts: string # TBD Extra hosts to add to /etc/hosts (As of version 1.xx)
  --nohosts: oneof<nothing, bool> # Not to create /etc/hosts when building the image
  --remote: string # A Git repository URI or HTTP/HTTPS context URI. If the URI points to a single text file, the file’s contents are placed into a file called Dockerfile and the image is built from that file. If the URI points to a tarball, the file is downloaded by the daemon and the contents therein used as the context for the build. If the URI points to a tarball and the dockerfile parameter is also specified, there must be a file with the corresponding path inside the tarball. (As of version 1.xx)
  --retry: int # Number of times to retry in case of failure when performing push/pull.  (default: 3)
  --retry-delay: string # Delay between retries in case of push/pull failures.  (default: 2s)
  --q: oneof<nothing, bool> # Suppress verbose build output  (default: false)
  --nocache: oneof<nothing, bool> # Do not use the cache when building the image (As of version 1.xx)  (default: false)
  --cachefrom: string # JSON array of images used to build cache resolution (As of version 1.xx)
  --pull: oneof<nothing, bool> # Attempt to pull the image even if an older image exists locally (As of version 1.xx)  (default: false)
  --rm: oneof<nothing, bool> # Remove intermediate containers after a successful build (As of version 1.xx)  (default: true)
  --forcerm: oneof<nothing, bool> # Always remove intermediate containers, even upon failure (As of version 1.xx)  (default: false)
  --memory: int # Memory is the upper limit (in bytes) on how much memory running containers can use (As of version 1.xx)
  --memswap: int # MemorySwap limits the amount of memory and swap together (As of version 1.xx)
  --cpushares: int # CPUShares (relative weight (As of version 1.xx)
  --cpusetcpus: string # CPUSetCPUs in which to allow execution (0-3, 0,1) (As of version 1.xx)
  --cpuperiod: int # CPUPeriod limits the CPU CFS (Completely Fair Scheduler) period (As of version 1.xx)
  --cpuquota: int # CPUQuota limits the CPU CFS (Completely Fair Scheduler) quota (As of version 1.xx)
  --buildargs: string # JSON map of string pairs denoting build-time variables. For example, the build argument `Foo` with the value of `bar` would be encoded in JSON as `["Foo":"bar"]`.  For example, buildargs={"Foo":"bar"}.  Note(s): * This should not be used to pass secrets. * The value of buildargs should be URI component encoded before being passed to the API.  (As of version 1.xx)
  --shmsize: int # ShmSize is the "size" value to use when mounting an shmfs on the container's /dev/shm directory. Default is 64MB (As of version 1.xx)  (default: 67108864)
  --squash: oneof<nothing, bool> # Silently ignored. Squash the resulting images layers into a single layer (As of version 1.xx)  (default: false)
  --save-stages: oneof<nothing, bool> # Preserve intermediate stage images instead of removing them after the build completes. By default, they are removed to save space. However, they can be useful for debugging multi-stage builds or reusing stages in subsequent builds.  (default: false)
  --stage-labels: oneof<nothing, bool> # Add metadata labels to all intermediate stage images of a multistage build, including the final image. If set to true, save-stages must also be set to true. If enabled, the labels 'io.buildah.stage.name' and 'io.buildah.stage.base' will be added.  (default: false)
  --labels: string # JSON map of key, value pairs to set as labels on the new image (As of version 1.xx)
  --networkmode: string # Sets the networking mode for the run commands during build. Supported standard values are:   * `bridge` limited to containers within a single host, port mapping required for external access   * `host` no isolation between host and containers on this network   * `none` disable all networking for this container   * container:<nameOrID> share networking with given container   ---All other values are assumed to be a custom network's name (As of version 1.xx)  (default: bridge)
  --platform: string # Platform format os[/arch[/variant]] Can be comma separated list for multi arch builds. (As of version 1.xx)
  --target: string # Target build stage (As of version 1.xx)
  --outputs: string # output configuration TBD (As of version 1.xx)
  --Content-Type: string@Content-Type-completer
  --X-Registry-Config: string
  --body: record
]: any -> record<stream: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dockerfile" $dockerfile "scalar") (serialize-qp "t" $t "scalar") (serialize-qp "extrahosts" $extrahosts "scalar") (serialize-qp "nohosts" $nohosts "scalar") (serialize-qp "remote" $remote "scalar") (serialize-qp "retry" $retry "scalar") (serialize-qp "retry-delay" $retry_delay "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "nocache" $nocache "scalar") (serialize-qp "cachefrom" $cachefrom "scalar") (serialize-qp "pull" $pull "scalar") (serialize-qp "rm" $rm "scalar") (serialize-qp "forcerm" $forcerm "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "memswap" $memswap "scalar") (serialize-qp "cpushares" $cpushares "scalar") (serialize-qp "cpusetcpus" $cpusetcpus "scalar") (serialize-qp "cpuperiod" $cpuperiod "scalar") (serialize-qp "cpuquota" $cpuquota "scalar") (serialize-qp "buildargs" $buildargs "scalar") (serialize-qp "shmsize" $shmsize "scalar") (serialize-qp "squash" $squash "scalar") (serialize-qp "save-stages" $save_stages "scalar") (serialize-qp "stage-labels" $stage_labels "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "networkmode" $networkmode "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "target" $target "scalar") (serialize-qp "outputs" $outputs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/build" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "X-Registry-Config": $X_Registry_Config} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# New Image
#
# POST /commit
# operationId: ImageCommit
export def "commit ImageCommit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --container: string # the name or ID of a container
  --repo: string # the repository name for the created image
  --tag: string # tag name for the created image
  --comment: string # commit message
  --author: string # author of the image
  --pause: oneof<nothing, bool> # pause the container before committing it
  --changes: string # instructions to apply while committing in Dockerfile format
  --squash: oneof<nothing, bool> # squash newly built layers into a single new layer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "container" $container "scalar") (serialize-qp "repo" $repo "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "comment" $comment "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "pause" $pause "scalar") (serialize-qp "changes" $changes "scalar") (serialize-qp "squash" $squash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a container
#
# DELETE /containers/{name}
# operationId: ContainerDelete
export def "containers ContainerDelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # If the container is running, kill it before removing it. (default: false)
  --v: oneof<nothing, bool> # Remove the volumes associated with the container. (default: false)
  --link: oneof<nothing, bool> # not supported
  --ignore: oneof<nothing, bool> # Ignore if a specified container does not exist. (default: false)
  --depend: oneof<nothing, bool> # Remove container dependencies. (default: false)
  --timeout: int # Number of seconds to wait before forcibly stopping the container.
  --volumes: oneof<nothing, bool> # Remove anonymous volumes associated with the container. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "v" $v "scalar") (serialize-qp "link" $link "scalar") (serialize-qp "ignore" $ignore "scalar") (serialize-qp "depend" $depend "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "volumes" $volumes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get files from a container
#
# GET /containers/{name}/archive
# operationId: ContainerArchive
export def "containers-archive ContainerArchive" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string # Path to a directory in the container to extract
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)/archive" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Put files into a container
#
# PUT /containers/{name}/archive
# operationId: PutContainerArchive
export def "containers-archive PutContainerArchive" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string # Path to a directory in the container to extract
  --noOverwriteDirNonDir: string # if unpacking the given content would cause an existing directory to be replaced with a non-directory and vice versa (1 or true)
  --copyUIDGID: string # copy UID/GID maps to the dest file or di (1 or true)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "noOverwriteDirNonDir" $noOverwriteDirNonDir "scalar") (serialize-qp "copyUIDGID" $copyUIDGID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)/archive" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Attach to a container
#
# POST /containers/{name}/attach
# operationId: ContainerAttach
export def "containers-attach ContainerAttach" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --detachKeys: string # keys to use for detaching from the container
  --logs: oneof<nothing, bool> # Stream all logs from the container across the connection. Happens before streaming attach (if requested). At least one of logs or stream must be set
  --stream: oneof<nothing, bool> # Attach to the container. If unset, and logs is set, only the container's logs will be sent. At least one of stream or logs must be set (default: true)
  --stdout: oneof<nothing, bool> # Attach to container STDOUT
  --stderr: oneof<nothing, bool> # Attach to container STDERR
  --stdin: oneof<nothing, bool> # Attach to container STDIN
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detachKeys" $detachKeys "scalar") (serialize-qp "logs" $logs "scalar") (serialize-qp "stream" $stream "scalar") (serialize-qp "stdout" $stdout "scalar") (serialize-qp "stderr" $stderr "scalar") (serialize-qp "stdin" $stdin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)/attach" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Report on changes to container's filesystem; adds, deletes or modifications.
#
# GET /containers/{name}/changes
# operationId: ContainerChanges
export def "containers-changes ContainerChanges" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --parent: string # specify a second layer which is used to compare against it instead of the parent layer
  --diffType: string@diffType-completer # select what you want to match, default is all
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent" $parent "scalar") (serialize-qp "diffType" $diffType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)/changes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an exec instance
#
# POST /containers/{name}/exec
# operationId: ContainerExec
export def "containers-exec ContainerExec" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --AttachStderr: oneof<nothing, bool> # Attach to stderr of the exec command
  --AttachStdin: oneof<nothing, bool> # Attach to stdin of the exec command
  --AttachStdout: oneof<nothing, bool> # Attach to stdout of the exec command
  --Cmd: list # Command to run, as a string or array of strings.
  --DetachKeys: string # "Override the key sequence for detaching a container. Format is a single character [a-Z] or ctrl-<value> where <value> is one of: a-z, @, ^, [, , or _."
  --Env: list # A list of environment variables in the form ["VAR=value", ...]
  --Privileged: oneof<nothing, bool> # Runs the exec process with extended privileges (default: false)
  --Tty: oneof<nothing, bool> # Allocate a pseudo-TTY
  --User: string # "The user, and optionally, group to run the exec process inside the container. Format is one of: user, user:group, uid, or uid:gid."
  --WorkingDir: string # The working directory for the exec process inside the container.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($name)/exec")
  let body = {AttachStderr: $AttachStderr, AttachStdin: $AttachStdin, AttachStdout: $AttachStdout, Cmd: $Cmd, DetachKeys: $DetachKeys, Env: $Env, Privileged: $Privileged, Tty: $Tty, User: $User, WorkingDir: $WorkingDir} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export a container
#
# GET /containers/{name}/export
# operationId: ContainerExport
export def "containers-export ContainerExport" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($name)/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect container
#
# GET /containers/{name}/json
# operationId: ContainerInspect
export def "containers-json ContainerInspect" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --size: oneof<nothing, bool> # include the size of the container (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Kill container
#
# POST /containers/{name}/kill
# operationId: ContainerKill
export def "containers-kill ContainerKill" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --all: oneof<nothing, bool> # Send kill signal to all containers (default: false)
  --signal: string # signal to be sent to container (default: SIGKILL)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "signal" $signal "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)/kill" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get container logs
#
# GET /containers/{name}/logs
# operationId: ContainerLogs
export def "containers-logs ContainerLogs" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --follow: oneof<nothing, bool> # Keep connection after returning logs.
  --stdout: oneof<nothing, bool> # Return logs from stdout
  --stderr: oneof<nothing, bool> # Return logs from stderr
  --since: string # Only return logs since this time, as a UNIX timestamp
  --until: string # Only return logs before this time, as a UNIX timestamp
  --timestamps: oneof<nothing, bool> # Add timestamps to every log line (default: false)
  --tail: string # Only return this number of log lines from the end of the logs (default: all)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "follow" $follow "scalar") (serialize-qp "stdout" $stdout "scalar") (serialize-qp "stderr" $stderr "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "timestamps" $timestamps "scalar") (serialize-qp "tail" $tail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause container
#
# POST /containers/{name}/pause
# operationId: ContainerPause
export def "containers-pause ContainerPause" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($name)/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rename an existing container
#
# POST /containers/{name}/rename
# operationId: ContainerRename
export def "containers-rename ContainerRename" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # New name for the container
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)/rename" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resize a container's TTY
#
# POST /containers/{name}/resize
# operationId: ContainerResize
export def "containers-resize ContainerResize" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --h: int # Height to set for the terminal, in characters
  --w: int # Width to set for the terminal, in characters
  --running: oneof<nothing, bool> # Ignore containers not running errors
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "h" $h "scalar") (serialize-qp "w" $w "scalar") (serialize-qp "running" $running "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)/resize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restart container
#
# POST /containers/{name}/restart
# operationId: ContainerRestart
export def "containers-restart ContainerRestart" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --t: int # timeout before sending kill signal to container
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t" $t "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)/restart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a container
#
# POST /containers/{name}/start
# operationId: ContainerStart
export def "containers-start ContainerStart" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --detachKeys: string # Override the key sequence for detaching a container. Format is a single character [a-Z] or ctrl-<value> where <value> is one of: a-z, @, ^, [, , or _. (default: ctrl-p,ctrl-q)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detachKeys" $detachKeys "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get stats for a container
#
# GET /containers/{name}/stats
# operationId: ContainerStats
export def "containers-stats ContainerStats" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --stream: oneof<nothing, bool> # Stream the output (default: true)
  --one-shot: oneof<nothing, bool> # Provide a one-shot response in which preCPU stats are blank, resulting in a single cycle return. (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stream" $stream "scalar") (serialize-qp "one-shot" $one_shot "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop a container
#
# POST /containers/{name}/stop
# operationId: ContainerStop
export def "containers-stop ContainerStop" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --t: int # number of seconds to wait before killing container
  --timeout: int # Number of seconds to wait before killing the container (libpod alias for `t`).
  --ignore: oneof<nothing, bool> # Do not return an error if the container is already stopped. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t" $t "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "ignore" $ignore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List processes running inside a container
#
# GET /containers/{name}/top
# operationId: ContainerTop
export def "containers-top ContainerTop" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ps-args: string # arguments to pass to ps such as aux. (default: -ef)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ps_args" $ps_args "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)/top" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpause container
#
# POST /containers/{name}/unpause
# operationId: ContainerUnpause
export def "containers-unpause ContainerUnpause" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($name)/unpause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update configuration of an existing container, allowing changes to resource limits
#
# POST /containers/{name}/update
# operationId: ContainerUpdate
# --BlkioDeviceReadBps item shape: {Path?: string, Rate?: int}
# --BlkioDeviceReadIOps item shape: {Path?: string, Rate?: int}
# --BlkioDeviceWriteBps item shape: {Path?: string, Rate?: int}
# --BlkioDeviceWriteIOps item shape: {Path?: string, Rate?: int}
# --BlkioWeightDevice item shape: {Path?: string, Weight?: int}
# --DeviceRequests item shape: {Capabilities?: list, Count?: int, DeviceIDs?: list, Driver?: string, Options?: record}
# --Devices item shape: {CgroupPermissions?: string, PathInContainer?: string, PathOnHost?: string}
# --RestartPolicy shape: {MaximumRetryCount?: int, Name?: string}
export def "containers-update ContainerUpdate" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --BlkioDeviceReadBps: list # item shape: {Path?: string, Rate?: int}
  --BlkioDeviceReadIOps: list # item shape: {Path?: string, Rate?: int}
  --BlkioDeviceWriteBps: list # item shape: {Path?: string, Rate?: int}
  --BlkioDeviceWriteIOps: list # item shape: {Path?: string, Rate?: int}
  --BlkioWeight: int # format: uint16
  --BlkioWeightDevice: list # item shape: {Path?: string, Weight?: int}
  --CgroupParent: string # Applicable to UNIX platforms
  --CpuCount: int # Applicable to Windows (format: int64)
  --CpuPercent: int # format: int64
  --CpuPeriod: int # format: int64
  --CpuQuota: int # format: int64
  --CpuRealtimePeriod: int # format: int64
  --CpuRealtimeRuntime: int # format: int64
  --CpuShares: int # Applicable to all platforms (format: int64)
  --CpusetCpus: string
  --CpusetMems: string
  --DeviceCgroupRules: list
  --DeviceRequests: list # item shape: {Capabilities?: list, Count?: int, DeviceIDs?: list, Driver?: string, Options?: record}
  --Devices: list # item shape: {CgroupPermissions?: string, PathInContainer?: string, PathOnHost?: string}
  --IOMaximumBandwidth: int # format: uint64
  --IOMaximumIOps: int # format: uint64
  --Memory: int # format: int64
  --MemoryReservation: int # format: int64
  --MemorySwap: int # format: int64
  --MemorySwappiness: int # format: int64
  --NanoCpus: int # format: int64
  --OomKillDisable: oneof<nothing, bool>
  --PidsLimit: int # format: int64
  --RestartPolicy: record # shape: {MaximumRetryCount?: int, Name?: string}
  --Ulimits: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containers/($name)/update")
  let body = {BlkioDeviceReadBps: $BlkioDeviceReadBps, BlkioDeviceReadIOps: $BlkioDeviceReadIOps, BlkioDeviceWriteBps: $BlkioDeviceWriteBps, BlkioDeviceWriteIOps: $BlkioDeviceWriteIOps, BlkioWeight: $BlkioWeight, BlkioWeightDevice: $BlkioWeightDevice, CgroupParent: $CgroupParent, CpuCount: $CpuCount, CpuPercent: $CpuPercent, CpuPeriod: $CpuPeriod, CpuQuota: $CpuQuota, CpuRealtimePeriod: $CpuRealtimePeriod, CpuRealtimeRuntime: $CpuRealtimeRuntime, CpuShares: $CpuShares, CpusetCpus: $CpusetCpus, CpusetMems: $CpusetMems, DeviceCgroupRules: $DeviceCgroupRules, DeviceRequests: $DeviceRequests, Devices: $Devices, IOMaximumBandwidth: $IOMaximumBandwidth, IOMaximumIOps: $IOMaximumIOps, Memory: $Memory, MemoryReservation: $MemoryReservation, MemorySwap: $MemorySwap, MemorySwappiness: $MemorySwappiness, NanoCpus: $NanoCpus, OomKillDisable: $OomKillDisable, PidsLimit: $PidsLimit, RestartPolicy: $RestartPolicy, Ulimits: $Ulimits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Wait on a container
#
# POST /containers/{name}/wait
# operationId: ContainerWait
export def "containers-wait ContainerWait" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --condition: string # Wait condition.  Valid values are:   - not-running (default) - return when the container is not running     (stopped, exited, or was never started).   - next-exit - wait for the next time the container stops.     If the container is running, block until it exits.     If the container is already stopped, block until     the next start-and-exit cycle.   - removed - wait until the container is removed.  (default: not-running)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "condition" $condition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/containers/($name)/wait" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a container
#
# POST /containers/create
# operationId: ContainerCreate
# --HostConfig shape: {Annotations?: record, AutoRemove?: bool, Binds?: list, BlkioDeviceReadBps?: list, BlkioDeviceReadIOps?: list, BlkioDeviceWriteBps?: list, BlkioDeviceWriteIOps?: list, BlkioWeight?: int, BlkioWeightDevice?: list, CapAdd?: list, CapDrop?: list, Cgroup?: string, CgroupParent?: string, CgroupnsMode?: string, ConsoleSize?: list, ContainerIDFile?: string, CpuCount?: int, CpuPercent?: int, CpuPeriod?: int, CpuQuota?: int, CpuRealtimePeriod?: int, CpuRealtimeRuntime?: int, CpuShares?: int, CpusetCpus?: string, CpusetMems?: string, DeviceCgroupRules?: list, DeviceRequests?: list, Devices?: list, Dns?: list, DnsOptions?: list, DnsSearch?: list, ExtraHosts?: list, GroupAdd?: list, IOMaximumBandwidth?: int, IOMaximumIOps?: int, Init?: bool, IpcMode?: string, Isolation?: string, Links?: list, LogConfig?: record, MaskedPaths?: list, Memory?: int, MemoryReservation?: int, MemorySwap?: int, MemorySwappiness?: int, Mounts?: list, NanoCpus?: int, NetworkMode?: string, OomKillDisable?: bool, OomScoreAdj?: int, PidMode?: string, PidsLimit?: int, PortBindings?: record, Privileged?: bool, PublishAllPorts?: bool, ReadonlyPaths?: list, ReadonlyRootfs?: bool, RestartPolicy?: record, Runtime?: string, SecurityOpt?: list, ShmSize?: int, StorageOpt?: record, Sysctls?: record, Tmpfs?: record, UTSMode?: string, Ulimits?: list, UsernsMode?: string, VolumeDriver?: string, VolumesFrom?: list}
# --NetworkingConfig shape: {EndpointsConfig?: record}
export def "containers-create ContainerCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # container name
  --ArgsEscaped: oneof<nothing, bool>
  --AttachStderr: oneof<nothing, bool>
  --AttachStdin: oneof<nothing, bool>
  --AttachStdout: oneof<nothing, bool>
  --Cmd: list
  --Domainname: string
  --Entrypoint: list
  --Env: list
  --EnvMerge: list
  --ExposedPorts: record
  --Healthcheck: record
  --HostConfig: record # Here, "non-portable" means "dependent of the host we are running on". Portable information *should* appear in Config. — shape: {Annotations?: record, AutoRemove?: bool, Binds?: list, BlkioDeviceReadBps?: list, BlkioDeviceReadIOps?: list, BlkioDeviceWriteBps?: list, BlkioDeviceWriteIOps?: list, BlkioWeight?: int, BlkioWeightDevice?: list, CapAdd?: list, CapDrop?: list, Cgroup?: string, CgroupParent?: string, CgroupnsMode?: string, ConsoleSize?: list, ContainerIDFile?: string, CpuCount?: int, CpuPercent?: int, CpuPeriod?: int, CpuQuota?: int, CpuRealtimePeriod?: int, CpuRealtimeRuntime?: int, CpuShares?: int, CpusetCpus?: string, CpusetMems?: string, DeviceCgroupRules?: list, DeviceRequests?: list, Devices?: list, Dns?: list, DnsOptions?: list, DnsSearch?: list, ExtraHosts?: list, GroupAdd?: list, IOMaximumBandwidth?: int, IOMaximumIOps?: int, Init?: bool, IpcMode?: string, Isolation?: string, Links?: list, LogConfig?: record, MaskedPaths?: list, Memory?: int, MemoryReservation?: int, MemorySwap?: int, MemorySwappiness?: int, Mounts?: list, NanoCpus?: int, NetworkMode?: string, OomKillDisable?: bool, OomScoreAdj?: int, PidMode?: string, PidsLimit?: int, PortBindings?: record, Privileged?: bool, PublishAllPorts?: bool, ReadonlyPaths?: list, ReadonlyRootfs?: bool, RestartPolicy?: record, Runtime?: string, SecurityOpt?: list, ShmSize?: int, StorageOpt?: record, Sysctls?: record, Tmpfs?: record, UTSMode?: string, Ulimits?: list, UsernsMode?: string, VolumeDriver?: string, VolumesFrom?: list}
  --Hostname: string
  --Image: string
  --Labels: record
  --MacAddress: string
  --Name: string
  --NetworkDisabled: oneof<nothing, bool>
  --NetworkingConfig: record # NetworkingConfig represents the container's networking configuration for each of its interfaces Carries the networking configs specified in the `docker run` and `docker network connect` commands — shape: {EndpointsConfig?: record}
  --OnBuild: list
  --OpenStdin: oneof<nothing, bool>
  --Shell: list
  --StdinOnce: oneof<nothing, bool>
  --StopSignal: string
  --StopTimeout: int # format: int64
  --Tty: oneof<nothing, bool>
  --UnsetEnv: list
  --UnsetEnvAll: oneof<nothing, bool>
  --User: string
  --Volumes: record
  --WorkingDir: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/containers/create" $qp)
  let body = {ArgsEscaped: $ArgsEscaped, AttachStderr: $AttachStderr, AttachStdin: $AttachStdin, AttachStdout: $AttachStdout, Cmd: $Cmd, Domainname: $Domainname, Entrypoint: $Entrypoint, Env: $Env, EnvMerge: $EnvMerge, ExposedPorts: $ExposedPorts, Healthcheck: $Healthcheck, HostConfig: $HostConfig, Hostname: $Hostname, Image: $Image, Labels: $Labels, MacAddress: $MacAddress, Name: $Name, NetworkDisabled: $NetworkDisabled, NetworkingConfig: $NetworkingConfig, OnBuild: $OnBuild, OpenStdin: $OpenStdin, Shell: $Shell, StdinOnce: $StdinOnce, StopSignal: $StopSignal, StopTimeout: $StopTimeout, Tty: $Tty, UnsetEnv: $UnsetEnv, UnsetEnvAll: $UnsetEnvAll, User: $User, Volumes: $Volumes, WorkingDir: $WorkingDir} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --all: oneof<nothing, bool> # Return all containers. By default, only running containers are shown (default: false)
  --external: oneof<nothing, bool> # Return containers in storage not controlled by Podman (default: false)
  --limit: int # Return this number of most recently created containers, including non-running ones.
  --size: oneof<nothing, bool> # Return the size of container as fields SizeRw and SizeRootFs. (default: false)
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the containers list. Available filters: - `ancestor`=(`<image-name>[:<tag>]`, `<image id>`, or `<image@digest>`) - `annotation`=(`key` or `"key=value"`) of a container annotation - `before`=(`<container id>` or `<container name>`) - `exited=<int>` containers with exit code of `<int>` - `expose`=(`<port>[/<proto>]` or `<startport-endport>/[<proto>]`) - `health`=(`starting`, `healthy`, `unhealthy` or `none`) - `id=<ID>` a container's ID - `is-task`=(`true` or `false`) - `label`=(`key` or `"key=value"`) of a container label - `name=<name>` a container's name - `network`=(`<network id>` or `<network name>`) - `publish`=(`<port>[/<proto>]` or `<startport-endport>/[<proto>]`) - `since`=(`<container id>` or `<container name>`) - `status`=(`created`, `restarting`, `running`, `removing`, `paused`, `exited` or `dead`) - `volume`=(`<volume name>` or `<mount point destination>`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "external" $external "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/containers/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --filters: string # Filters to process on the prune list, encoded as JSON (a `map[string][]string`).  Available filters:  - `annotation` (`annotation=<key>`, `annotation=<key>=<value>`, `annotation!=<key>`, or `annotation!=<key>=<value>`) Prune containers with (or without, in case `annotation!=...` is used) the specified annotations.  - `label` (`label=<key>`, `label=<key>=<value>`, `label!=<key>`, or `label!=<key>=<value>`) Prune containers with (or without, in case `label!=...` is used) the specified labels.  - `until=<timestamp>` Prune containers created before this timestamp. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/containers/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get events
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
  --since: string # start streaming events from this time
  --until: string # stop streaming events later than this
  --filters: string # JSON encoded map[string][]string of constraints
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/exec/($id)/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --h: int # Height of the TTY session in characters
  --w: int # Width of the TTY session in characters
  --running: oneof<nothing, bool> # Ignore containers not running errors
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "h" $h "scalar") (serialize-qp "w" $w "scalar") (serialize-qp "running" $running "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/exec/($id)/resize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --Detach: oneof<nothing, bool> # Detach from the command. Not presently supported.
  --Tty: oneof<nothing, bool> # Allocate a pseudo-TTY. Presently ignored.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/exec/($id)/start")
  let body = {Detach: $Detach, Tty: $Tty} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Image
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
  --force: oneof<nothing, bool> # Remove the image even if it is being used by stopped containers or has other tags
  --noprune: oneof<nothing, bool> # do not remove dangling parent images
  --ignore: oneof<nothing, bool> # Ignore if a specified image does not exist and do not throw an error. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "noprune" $noprune "scalar") (serialize-qp "ignore" $ignore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($name)/get")
  let accept_val = "application/x-tar"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# History of an image
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($name)/history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/images/($name)/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Push Image
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
  --tag: string # The tag to associate with the image on the registry.
  --all: oneof<nothing, bool> # All indicates whether to push all images related to the image list
  --compress: oneof<nothing, bool> # Use compression on image.
  --compressionFormat: string # The type of compression to apply to layer blobs pushed to build caches in registries.
  --compressionLevel: int # The level of compression to apply to layer blobs pushed to build caches in registries. The range of acceptable values varies based on the compression format.
  --forceCompressionFormat: oneof<nothing, bool> # Use the specified compression format for layer blobs, even when pushing to a location where an equivalent blob which differs only in how it's compressed could be reused.
  --destination: string # Allows for pushing the image to a different destination than the image refers to.
  --format: string # Manifest type (oci, v2s1, or v2s2) to use when pushing an image. Default is manifest type of source, with fallbacks.
  --tlsVerify: oneof<nothing, bool> # Require TLS verification. (default: true)
  --X-Registry-Auth: string # A base64-encoded auth configuration.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "all" $all "scalar") (serialize-qp "compress" $compress "scalar") (serialize-qp "compressionFormat" $compressionFormat "scalar") (serialize-qp "compressionLevel" $compressionLevel "scalar") (serialize-qp "forceCompressionFormat" $forceCompressionFormat "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "tlsVerify" $tlsVerify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($name)/push" $qp)
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --repo: string # the repository to tag in
  --tag: string # the name of the new tag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "repo" $repo "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/images/($name)/tag" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --fromImage: string # Name of the image to pull. The name may include a tag or digest. This parameter may only be used when pulling an image. The pull is cancelled if the HTTP connection is closed.
  --fromSrc: string # Source to import. The value may be a URL from which the image can be retrieved or - to read the image from the request body. This parameter may only be used when importing an image
  --repo: string # Repository name given to an image when it is imported. The repo may include a tag. This parameter may only be used when importing an image.
  --tag: string # Tag or digest. If empty when pulling an image, this causes all tags for the given image to be pulled.
  --message: string # Set commit message for imported image.
  --platform: string # Platform in the format os[/arch[/variant]]
  --retry: int # Number of times to retry in case of failure when performing pull.
  --retryDelay: string # Delay between retries in case of pull failures.
  --X-Registry-Auth: string # A base64-encoded auth configuration.
  --body: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromImage" $fromImage "scalar") (serialize-qp "fromSrc" $fromSrc "scalar") (serialize-qp "repo" $repo "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "message" $message "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "retry" $retry "scalar") (serialize-qp "retryDelay" $retryDelay "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images/create" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --names: string # one or more image names or IDs comma separated
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "names" $names "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --all: oneof<nothing, bool> # Show all images. Only images from a final layer (no children) are shown by default. (default: false)
  --filters: string # JSON-encoded string containing filters as a `map[string][]string` to process on the images list. Available filters: - `before`=(`<image-name>[:<tag>]`,  `<image id>` or `<image@digest>`) - `dangling=true` - `label=key` or `label="key=value"` of an image label - `reference`=(`<image-name>[:<tag>]`) - `since`=(`<image-name>[:<tag>]`,  `<image id>` or `<image@digest>`)
  --digests: oneof<nothing, bool> # Not supported (default: false)
  --shared-size: oneof<nothing, bool> # Compute and show shared size as a SharedSize field on each image. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "digests" $digests "scalar") (serialize-qp "shared-size" $shared_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import image
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
  --quiet: oneof<nothing, bool> # not supported
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
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Prune unused images
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
  --filters: string # filters to apply to image pruning, encoded as JSON (map[string][]string). Available filters:   - `dangling=<boolean>` When set to `true` (or `1`), prune only      unused *and* untagged images. When set to `false`      (or `0`), all unused images are pruned.   - `until=<string>` Prune images created before this timestamp. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time.   - `label` (`label=<key>`, `label=<key>=<value>`, `label!=<key>`, or `label!=<key>=<value>`) Prune images with (or without, in case `label!=...` is used) the specified labels.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --term: string # term to search
  --limit: int # maximum number of results (default: 25)
  --filters: string # JSON-encoded string containing filters as a `map[string][]string` to process on the images list. Available filters: - `is-automated=(true|false)` - `is-official=(true|false)` - `stars=<number>` Matches images that have at least 'number' stars.
  --tlsVerify: oneof<nothing, bool> # Require HTTPS and verify signatures when contacting registries. (default: true)
  --listTags: oneof<nothing, bool> # list the available tags in the repository
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "tlsVerify" $tlsVerify "scalar") (serialize-qp "listTags" $listTags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get info
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ping service
#
# GET /libpod/_ping
# operationId: SystemPing
export def "libpod-ping SystemPing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/libpod/_ping")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an artifact
#
# DELETE /libpod/artifacts/{name}
# operationId: ArtifactDeleteLibpod
export def "libpod-artifacts ArtifactDeleteLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/artifacts/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Extract an artifacts contents
#
# GET /libpod/artifacts/{name}/extract
# operationId: ArtifactExtractLibpod
export def "libpod-artifacts-extract ArtifactExtractLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Only extract the file with the given title
  --digest: string # Only extract the file with the given digest
  --excludeTitle: oneof<nothing, bool> # When extracting a single file from an artifact, don't use the files title as the file name in the tar archive
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "digest" $digest "scalar") (serialize-qp "excludeTitle" $excludeTitle "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/artifacts/($name)/extract" $qp)
  let accept_val = "application/x-tar"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect an artifact
#
# GET /libpod/artifacts/{name}/json
# operationId: ArtifactInspectLibpod
export def "libpod-artifacts-json ArtifactInspectLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/artifacts/($name)/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Push an artifact
#
# POST /libpod/artifacts/{name}/push
# operationId: ArtifactPushLibpod
export def "libpod-artifacts-push ArtifactPushLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --retry: int # Number of times to retry in case of failure when performing pull (default: 3)
  --retryDelay: string # Delay between retries in case of pull failures (e.g., 10s) (default: 1s)
  --tlsVerify: oneof<nothing, bool> # Require TLS verification (default: true)
  --X-Registry-Auth: string # base-64 encoded auth config. Must include the following four values: username, password, email and server address OR simply just an identity token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "retry" $retry "scalar") (serialize-qp "retryDelay" $retryDelay "scalar") (serialize-qp "tlsVerify" $tlsVerify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/artifacts/($name)/push" $qp)
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a file as an artifact
#
# POST /libpod/artifacts/add
# operationId: ArtifactAddLibpod
export def "libpod-artifacts-add ArtifactAddLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Mandatory reference to the artifact (e.g., quay.io/image/artifact:tag)
  --fileName: string # Path of the file to be added
  --fileMIMEType: string # Optionally set the type of file
  --annotations: list # Array of annotation strings e.g "test=true"
  --artifactMIMEType: string # Use type to describe an artifact
  --append: oneof<nothing, bool> # Append files to an existing artifact (default: false)
  --replace: oneof<nothing, bool> # Replace an existing artifact with the same name (default: false)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "fileName" $fileName "scalar") (serialize-qp "fileMIMEType" $fileMIMEType "scalar") (serialize-qp "annotations" $annotations "csv") (serialize-qp "artifactMIMEType" $artifactMIMEType "scalar") (serialize-qp "append" $append "scalar") (serialize-qp "replace" $replace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/artifacts/add" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List artifacts
#
# GET /libpod/artifacts/json
# operationId: ArtifactListLibpod
export def "libpod-artifacts-json ArtifactListLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/libpod/artifacts/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a local file as an artifact
#
# POST /libpod/artifacts/local/add
# operationId: ArtifactLocalLibpod
export def "libpod-artifacts-local-add ArtifactLocalLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Mandatory reference to the artifact (e.g., quay.io/image/artifact:tag)
  --path: string # Absolute path to the local file on the server filesystem to be added
  --fileName: string # Name/title of the file within the artifact
  --fileMIMEType: string # Optionally set the MIME type of the file
  --annotations: list # Array of annotation strings e.g "test=true"
  --artifactMIMEType: string # Use type to describe an artifact
  --append: oneof<nothing, bool> # Append files to an existing artifact (default: false)
  --replace: oneof<nothing, bool> # Replace an existing artifact with the same name (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "fileName" $fileName "scalar") (serialize-qp "fileMIMEType" $fileMIMEType "scalar") (serialize-qp "annotations" $annotations "csv") (serialize-qp "artifactMIMEType" $artifactMIMEType "scalar") (serialize-qp "append" $append "scalar") (serialize-qp "replace" $replace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/artifacts/local/add" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pull an artifact
#
# POST /libpod/artifacts/pull
# operationId: ArtifactPullLibpod
export def "libpod-artifacts-pull ArtifactPullLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Mandatory reference to the artifact (e.g., quay.io/image/artifact:tag)
  --retry: int # Number of times to retry in case of failure when performing pull (default: 3)
  --retryDelay: string # Delay between retries in case of pull failures (e.g., 10s) (default: 1s)
  --tlsVerify: oneof<nothing, bool> # Require TLS verification (default: true)
  --X-Registry-Auth: string # base-64 encoded auth config. Must include the following four values: username, password, email and server address OR simply just an identity token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "retry" $retry "scalar") (serialize-qp "retryDelay" $retryDelay "scalar") (serialize-qp "tlsVerify" $tlsVerify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/artifacts/pull" $qp)
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove one or more artifacts
#
# DELETE /libpod/artifacts/remove
# operationId: ArtifactDeleteAllLibpod
export def "libpod-artifacts-remove ArtifactDeleteAllLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --artifacts: list # List of artifact names/IDs to remove
  --all: oneof<nothing, bool> # Remove all artifacts
  --ignore: oneof<nothing, bool> # Ignore errors if artifact does not exist
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "artifacts" $artifacts "csv") (serialize-qp "all" $all "scalar") (serialize-qp "ignore" $ignore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/artifacts/remove" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Build image
#
# POST /libpod/build
# operationId: ImageBuildLibpod
export def "libpod-build ImageBuildLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dockerfile: string # Path within the build context to the `Dockerfile`. This is ignored if remote is specified and points to an external `Dockerfile`.  (default: Dockerfile)
  --t: string # A name and optional tag to apply to the image in the `name:tag` format.  If you omit the tag, the default latest value is assumed. You can provide several t parameters. (default: latest)
  --allplatforms: oneof<nothing, bool> # Instead of building for a set of platforms specified using the platform option, inspect the build's base images, and build for all of the platforms that are available.  Stages that use *scratch* as a starting point can not be inspected, so at least one non-*scratch* stage must be present for detection to work usefully.  (default: false)
  --additionalbuildcontexts: list # Additional build contexts for builds that require more than one context. Each additional context must be specified as a key-value pair in the format "name=value".  The value can be specified in two formats: - URL context: Use the prefix "url:" followed by a URL to a tar archive   Example: "mycontext=url:https://example.com/context.tar" - Image context: Use the prefix "image:" followed by an image reference   Example: "mycontext=image:alpine:latest" or "mycontext=image:docker.io/library/ubuntu:22.04"  Local contexts are provided via multipart/form-data upload. When using multipart/form-data, include additional build contexts as separate form fields with names prefixed by "build-context-". For example, a local context named "mycontext" should be uploaded as a tar file in a field named "build-context-mycontext".  (As of version 5.6.0)  (default: [])
  --extrahosts: string # TBD Extra hosts to add to /etc/hosts (As of version 1.xx)
  --nohosts: oneof<nothing, bool> # Not to create /etc/hosts when building the image
  --remote: string # A Git repository URI or HTTP/HTTPS context URI. If the URI points to a single text file, the file’s contents are placed into a file called Dockerfile and the image is built from that file. If the URI points to a tarball, the file is downloaded by the daemon and the contents therein used as the context for the build. If the URI points to a tarball and the dockerfile parameter is also specified, there must be a file with the corresponding path inside the tarball. (As of version 1.xx)
  --q: oneof<nothing, bool> # Suppress verbose build output  (default: false)
  --compatvolumes: oneof<nothing, bool> # Contents of volume locations to be modified on ADD or COPY only (As of Podman version v5.2)  (default: false)
  --createdannotation: oneof<nothing, bool> # Add an "org.opencontainers.image.created" annotation to the image. (As of Podman version v5.6)  (default: true)
  --sourcedateepoch: float # Timestamp to use for newly-added history entries and the image's creation date. (As of Podman version v5.6)
  --rewritetimestamp: oneof<nothing, bool> # If sourcedateepoch is set, force new content added in layers to have timestamps no later than the sourcedateepoch date. (As of Podman version v5.6)  (default: false)
  --timestamp: float # Timestamp to use for newly-added history entries, the image's creation date, and for new content added in layers.
  --inheritlabels: oneof<nothing, bool> # Inherit the labels from the base image or base stages (As of Podman version v5.5)  (default: true)
  --inheritannotations: oneof<nothing, bool> # Inherit the annotations from the base image or base stages (As of Podman version v5.6)  (default: true)
  --nocache: oneof<nothing, bool> # Do not use the cache when building the image (As of version 1.xx)  (default: false)
  --cachefrom: string # JSON array of images used to build cache resolution (As of version 1.xx)
  --pull: oneof<nothing, bool> # Attempt to pull the image even if an older image exists locally (As of version 1.xx)  (default: false)
  --rm: oneof<nothing, bool> # Remove intermediate containers after a successful build (As of version 1.xx)  (default: true)
  --forcerm: oneof<nothing, bool> # Always remove intermediate containers, even upon failure (As of version 1.xx)  (default: false)
  --memory: int # Memory is the upper limit (in bytes) on how much memory running containers can use (As of version 1.xx)
  --memswap: int # MemorySwap limits the amount of memory and swap together (As of version 1.xx)
  --cpushares: int # CPUShares (relative weight (As of version 1.xx)
  --cpusetcpus: string # CPUSetCPUs in which to allow execution (0-3, 0,1) (As of version 1.xx)
  --cpuperiod: int # CPUPeriod limits the CPU CFS (Completely Fair Scheduler) period (As of version 1.xx)
  --cpuquota: int # CPUQuota limits the CPU CFS (Completely Fair Scheduler) quota (As of version 1.xx)
  --buildargs: string # JSON map of string pairs denoting build-time variables. For example, the build argument `Foo` with the value of `bar` would be encoded in JSON as `["Foo":"bar"]`.  For example, buildargs={"Foo":"bar"}.  Note(s): * This should not be used to pass secrets. * The value of buildargs should be URI component encoded before being passed to the API.  (As of version 1.xx)
  --shmsize: int # ShmSize is the "size" value to use when mounting an shmfs on the container's /dev/shm directory. Default is 64MB (As of version 1.xx)  (default: 67108864)
  --squash: oneof<nothing, bool> # Silently ignored. Squash the resulting images layers into a single layer (As of version 1.xx)  (default: false)
  --labels: string # JSON map of key, value pairs to set as labels on the new image (As of version 1.xx)
  --layerLabel: list # Add an intermediate image *label* (e.g. label=*value*) to the intermediate image metadata.
  --layers: oneof<nothing, bool> # Cache intermediate layers during build. (As of version 1.xx)  (default: true)
  --networkmode: string # Sets the networking mode for the run commands during build. Supported standard values are:   * `bridge` limited to containers within a single host, port mapping required for external access   * `host` no isolation between host and containers on this network   * `none` disable all networking for this container   * container:<nameOrID> share networking with given container   ---All other values are assumed to be a custom network's name (As of version 1.xx)  (default: bridge)
  --platform: string # Platform format os[/arch[/variant]] (As of version 1.xx)
  --target: string # Target build stage (As of version 1.xx)
  --outputs: string # output configuration TBD (As of version 1.xx)
  --httpproxy: oneof<nothing, bool> # Inject http proxy environment variables into container (As of version 2.0.0)
  --unsetenv: list # Unset environment variables from the final image.
  --unsetlabel: list # Unset the image label, causing the label not to be inherited from the base image.
  --unsetannotation: list # Unset the image annotation, causing the annotation not to be inherited from the base image. (As of Podman version v5.6)
  --volume: list # Extra volumes that should be mounted in the build container.
  --manifest: string # Add the image to the specified manifest list. Creates a manifest list if it does not exist.
  --Content-Type: string@Content-Type-completer-1
  --X-Registry-Config: string
]: nothing -> record<stream: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dockerfile" $dockerfile "scalar") (serialize-qp "t" $t "scalar") (serialize-qp "allplatforms" $allplatforms "scalar") (serialize-qp "additionalbuildcontexts" $additionalbuildcontexts "csv") (serialize-qp "extrahosts" $extrahosts "scalar") (serialize-qp "nohosts" $nohosts "scalar") (serialize-qp "remote" $remote "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "compatvolumes" $compatvolumes "scalar") (serialize-qp "createdannotation" $createdannotation "scalar") (serialize-qp "sourcedateepoch" $sourcedateepoch "scalar") (serialize-qp "rewritetimestamp" $rewritetimestamp "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "inheritlabels" $inheritlabels "scalar") (serialize-qp "inheritannotations" $inheritannotations "scalar") (serialize-qp "nocache" $nocache "scalar") (serialize-qp "cachefrom" $cachefrom "scalar") (serialize-qp "pull" $pull "scalar") (serialize-qp "rm" $rm "scalar") (serialize-qp "forcerm" $forcerm "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "memswap" $memswap "scalar") (serialize-qp "cpushares" $cpushares "scalar") (serialize-qp "cpusetcpus" $cpusetcpus "scalar") (serialize-qp "cpuperiod" $cpuperiod "scalar") (serialize-qp "cpuquota" $cpuquota "scalar") (serialize-qp "buildargs" $buildargs "scalar") (serialize-qp "shmsize" $shmsize "scalar") (serialize-qp "squash" $squash "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "layerLabel" $layerLabel "csv") (serialize-qp "layers" $layers "scalar") (serialize-qp "networkmode" $networkmode "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "target" $target "scalar") (serialize-qp "outputs" $outputs "scalar") (serialize-qp "httpproxy" $httpproxy "scalar") (serialize-qp "unsetenv" $unsetenv "csv") (serialize-qp "unsetlabel" $unsetlabel "csv") (serialize-qp "unsetannotation" $unsetannotation "csv") (serialize-qp "volume" $volume "csv") (serialize-qp "manifest" $manifest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/build" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "X-Registry-Config": $X_Registry_Config} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Commit
#
# POST /libpod/commit
# operationId: ImageCommitLibpod
export def "libpod-commit ImageCommitLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --container: string # the name or ID of a container
  --author: string # author of the image
  --changes: list # instructions to apply while committing in Dockerfile format (i.e. "CMD=/bin/foo")
  --comment: string # commit message
  --format: string # format of the image manifest and metadata (default "oci")
  --pause: oneof<nothing, bool> # pause the container before committing it
  --squash: oneof<nothing, bool> # squash the container before committing it
  --repo: string # the repository name for the created image
  --stream: oneof<nothing, bool> # output from commit process
  --tag: string # tag name for the created image
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "container" $container "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "changes" $changes "csv") (serialize-qp "comment" $comment "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "pause" $pause "scalar") (serialize-qp "squash" $squash "scalar") (serialize-qp "repo" $repo "scalar") (serialize-qp "stream" $stream "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/commit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete container
#
# DELETE /libpod/containers/{name}
# operationId: ContainerDeleteLibpod
export def "libpod-containers ContainerDeleteLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --depend: oneof<nothing, bool> # additionally remove containers that depend on the container to be removed
  --force: oneof<nothing, bool> # force stop container if running
  --ignore: oneof<nothing, bool> # ignore errors when the container to be removed does not existxo
  --timeout: int # number of seconds to wait before killing container when force removing (default: 10)
  --v: oneof<nothing, bool> # delete volumes
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "depend" $depend "scalar") (serialize-qp "force" $force "scalar") (serialize-qp "ignore" $ignore "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "v" $v "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy files from a container
#
# GET /libpod/containers/{name}/archive
# operationId: ContainerArchiveLibpod
export def "libpod-containers-archive ContainerArchiveLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string # Path to a directory in the container to extract
  --rename: string # JSON encoded map[string]string to translate paths
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "rename" $rename "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/archive" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy files into a container
#
# PUT /libpod/containers/{name}/archive
# operationId: PutContainerArchiveLibpod
export def "libpod-containers-archive PutContainerArchiveLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string # Path to a directory in the container to extract
  --pause: oneof<nothing, bool> # pause the container while copying (defaults to true) (default: true)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "pause" $pause "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/archive" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Attach to a container
#
# POST /libpod/containers/{name}/attach
# operationId: ContainerAttachLibpod
export def "libpod-containers-attach ContainerAttachLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --detachKeys: string # keys to use for detaching from the container
  --logs: oneof<nothing, bool> # Stream all logs from the container across the connection. Happens before streaming attach (if requested). At least one of logs or stream must be set
  --stream: oneof<nothing, bool> # Attach to the container. If unset, and logs is set, only the container's logs will be sent. At least one of stream or logs must be set (default: true)
  --stdout: oneof<nothing, bool> # Attach to container STDOUT
  --stderr: oneof<nothing, bool> # Attach to container STDERR
  --stdin: oneof<nothing, bool> # Attach to container STDIN
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detachKeys" $detachKeys "scalar") (serialize-qp "logs" $logs "scalar") (serialize-qp "stream" $stream "scalar") (serialize-qp "stdout" $stdout "scalar") (serialize-qp "stderr" $stderr "scalar") (serialize-qp "stdin" $stdin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/attach" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Report on changes to container's filesystem; adds, deletes or modifications.
#
# GET /libpod/containers/{name}/changes
# operationId: ContainerChangesLibpod
export def "libpod-containers-changes ContainerChangesLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --parent: string # specify a second layer which is used to compare against it instead of the parent layer
  --diffType: string@diffType-completer # select what you want to match, default is all
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent" $parent "scalar") (serialize-qp "diffType" $diffType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/changes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Checkpoint a container
#
# POST /libpod/containers/{name}/checkpoint
# operationId: ContainerCheckpointLibpod
export def "libpod-containers-checkpoint ContainerCheckpointLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keep: oneof<nothing, bool> # keep all temporary checkpoint files
  --leaveRunning: oneof<nothing, bool> # leave the container running after writing checkpoint to disk
  --tcpEstablished: oneof<nothing, bool> # checkpoint a container with established TCP connections
  --qp-export: oneof<nothing, bool> # export the checkpoint image to a tar.gz
  --ignoreRootFS: oneof<nothing, bool> # do not include root file-system changes when exporting. can only be used with export
  --ignoreVolumes: oneof<nothing, bool> # do not include associated volumes. can only be used with export
  --preCheckpoint: oneof<nothing, bool> # dump the container's memory information only, leaving the container running. only works on runc 1.0-rc or higher
  --withPrevious: oneof<nothing, bool> # check out the container with previous criu image files in pre-dump. only works on runc 1.0-rc or higher
  --fileLocks: oneof<nothing, bool> # checkpoint a container with filelocks
  --printStats: oneof<nothing, bool> # add checkpoint statistics to the returned CheckpointReport
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keep" $keep "scalar") (serialize-qp "leaveRunning" $leaveRunning "scalar") (serialize-qp "tcpEstablished" $tcpEstablished "scalar") (serialize-qp "export" $qp_export "scalar") (serialize-qp "ignoreRootFS" $ignoreRootFS "scalar") (serialize-qp "ignoreVolumes" $ignoreVolumes "scalar") (serialize-qp "preCheckpoint" $preCheckpoint "scalar") (serialize-qp "withPrevious" $withPrevious "scalar") (serialize-qp "fileLocks" $fileLocks "scalar") (serialize-qp "printStats" $printStats "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/checkpoint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an exec instance
#
# POST /libpod/containers/{name}/exec
# operationId: ContainerExecLibpod
export def "libpod-containers-exec ContainerExecLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --AttachStderr: oneof<nothing, bool> # Attach to stderr of the exec command
  --AttachStdin: oneof<nothing, bool> # Attach to stdin of the exec command
  --AttachStdout: oneof<nothing, bool> # Attach to stdout of the exec command
  --Cmd: list # Command to run, as a string or array of strings.
  --DetachKeys: string # "Override the key sequence for detaching a container. Format is a single character [a-Z] or ctrl-<value> where <value> is one of: a-z, @, ^, [, , or _."
  --Env: list # A list of environment variables in the form ["VAR=value", ...]
  --Privileged: oneof<nothing, bool> # Runs the exec process with extended privileges (default: false)
  --Tty: oneof<nothing, bool> # Allocate a pseudo-TTY
  --User: string # "The user, and optionally, group to run the exec process inside the container. Format is one of: user, user:group, uid, or uid:gid."
  --WorkingDir: string # The working directory for the exec process inside the container.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/containers/($name)/exec")
  let body = {AttachStderr: $AttachStderr, AttachStdin: $AttachStdin, AttachStdout: $AttachStdout, Cmd: $Cmd, DetachKeys: $DetachKeys, Env: $Env, Privileged: $Privileged, Tty: $Tty, User: $User, WorkingDir: $WorkingDir} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check if container exists
#
# GET /libpod/containers/{name}/exists
# operationId: ContainerExistsLibpod
export def "libpod-containers-exists ContainerExistsLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/containers/($name)/exists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export a container
#
# GET /libpod/containers/{name}/export
# operationId: ContainerExportLibpod
export def "libpod-containers-export ContainerExportLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/containers/($name)/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Run a container's healthcheck
#
# GET /libpod/containers/{name}/healthcheck
# operationId: ContainerHealthcheckLibpod
export def "libpod-containers-healthcheck ContainerHealthcheckLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/containers/($name)/healthcheck")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initialize a container
#
# POST /libpod/containers/{name}/init
# operationId: ContainerInitLibpod
export def "libpod-containers-init ContainerInitLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/containers/($name)/init")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect container
#
# GET /libpod/containers/{name}/json
# operationId: ContainerInspectLibpod
export def "libpod-containers-json ContainerInspectLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --size: oneof<nothing, bool> # display filesystem usage
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Kill container
#
# POST /libpod/containers/{name}/kill
# operationId: ContainerKillLibpod
export def "libpod-containers-kill ContainerKillLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --signal: string # signal to be sent to container, either by integer or SIG_ name (default: SIGKILL)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signal" $signal "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/kill" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get container logs
#
# GET /libpod/containers/{name}/logs
# operationId: ContainerLogsLibpod
export def "libpod-containers-logs ContainerLogsLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --follow: oneof<nothing, bool> # Keep connection after returning logs.
  --stdout: oneof<nothing, bool> # Return logs from stdout
  --stderr: oneof<nothing, bool> # Return logs from stderr
  --since: string # Only return logs since this time, as a UNIX timestamp
  --until: string # Only return logs before this time, as a UNIX timestamp
  --timestamps: oneof<nothing, bool> # Add timestamps to every log line (default: false)
  --tail: string # Only return this number of log lines from the end of the logs (default: all)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "follow" $follow "scalar") (serialize-qp "stdout" $stdout "scalar") (serialize-qp "stderr" $stderr "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "timestamps" $timestamps "scalar") (serialize-qp "tail" $tail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mount a container
#
# POST /libpod/containers/{name}/mount
# operationId: ContainerMountLibpod
export def "libpod-containers-mount ContainerMountLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --external: oneof<nothing, bool> # Include external containers that are not managed by Podman. (default: false)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "external" $external "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/mount" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause a container
#
# POST /libpod/containers/{name}/pause
# operationId: ContainerPauseLibpod
export def "libpod-containers-pause ContainerPauseLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/containers/($name)/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rename an existing container
#
# POST /libpod/containers/{name}/rename
# operationId: ContainerRenameLibpod
export def "libpod-containers-rename ContainerRenameLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # New name for the container
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/rename" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resize a container's TTY
#
# POST /libpod/containers/{name}/resize
# operationId: ContainerResizeLibpod
export def "libpod-containers-resize ContainerResizeLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --h: int # Height to set for the terminal, in characters
  --w: int # Width to set for the terminal, in characters
  --running: oneof<nothing, bool> # Ignore containers not running errors
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "h" $h "scalar") (serialize-qp "w" $w "scalar") (serialize-qp "running" $running "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/resize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restart a container
#
# POST /libpod/containers/{name}/restart
# operationId: ContainerRestartLibpod
export def "libpod-containers-restart ContainerRestartLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --t: int # number of seconds to wait before killing container (Docker compatibility)
  --timeout: int # number of seconds to wait before killing container
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t" $t "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/restart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restore a container
#
# POST /libpod/containers/{name}/restore
# operationId: ContainerRestoreLibpod
export def "libpod-containers-restore ContainerRestoreLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # the name of the container when restored from a tar. can only be used with import
  --keep: oneof<nothing, bool> # keep all temporary checkpoint files
  --tcpEstablished: oneof<nothing, bool> # restore a container with established TCP connections
  --tcpClose: oneof<nothing, bool> # restore a container but close the TCP connections
  --import: oneof<nothing, bool> # import the restore from a checkpoint tar.gz
  --ignoreRootFS: oneof<nothing, bool> # do not include root file-system changes when exporting. can only be used with import
  --ignoreVolumes: oneof<nothing, bool> # do not restore associated volumes. can only be used with import
  --ignoreStaticIP: oneof<nothing, bool> # ignore IP address if set statically
  --ignoreStaticMAC: oneof<nothing, bool> # ignore MAC address if set statically
  --fileLocks: oneof<nothing, bool> # restore a container with file locks
  --printStats: oneof<nothing, bool> # add restore statistics to the returned RestoreReport
  --pod: string # pod to restore into
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "keep" $keep "scalar") (serialize-qp "tcpEstablished" $tcpEstablished "scalar") (serialize-qp "tcpClose" $tcpClose "scalar") (serialize-qp "import" $import "scalar") (serialize-qp "ignoreRootFS" $ignoreRootFS "scalar") (serialize-qp "ignoreVolumes" $ignoreVolumes "scalar") (serialize-qp "ignoreStaticIP" $ignoreStaticIP "scalar") (serialize-qp "ignoreStaticMAC" $ignoreStaticMAC "scalar") (serialize-qp "fileLocks" $fileLocks "scalar") (serialize-qp "printStats" $printStats "scalar") (serialize-qp "pod" $pod "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/restore" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a container
#
# POST /libpod/containers/{name}/start
# operationId: ContainerStartLibpod
export def "libpod-containers-start ContainerStartLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --detachKeys: string # Override the key sequence for detaching a container. Format is a single character [a-Z] or ctrl-<value> where <value> is one of: a-z, @, ^, [, , or _. (default: ctrl-p,ctrl-q)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detachKeys" $detachKeys "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get stats for a container
#
# GET /libpod/containers/{name}/stats
# operationId: ContainerStatsLibpod
export def "libpod-containers-stats ContainerStatsLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --stream: oneof<nothing, bool> # Stream the output (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stream" $stream "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop a container
#
# POST /libpod/containers/{name}/stop
# operationId: ContainerStopLibpod
export def "libpod-containers-stop ContainerStopLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeout: int # number of seconds to wait before killing container (default: 10)
  --ignore: oneof<nothing, bool> # do not return error if container is already stopped (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeout" $timeout "scalar") (serialize-qp "ignore" $ignore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List processes
#
# GET /libpod/containers/{name}/top
# operationId: ContainerTopLibpod
export def "libpod-containers-top ContainerTopLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --stream: oneof<nothing, bool> # when true, repeatedly stream the latest output (As of version 4.0)
  --delay: int # if streaming, delay in seconds between updates. Must be >1. (As of version 4.0) (default: 5)
  --ps-args: list # arguments to pass to ps such as aux.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stream" $stream "scalar") (serialize-qp "delay" $delay "scalar") (serialize-qp "ps_args" $ps_args "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/top" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unmount a container
#
# POST /libpod/containers/{name}/unmount
# operationId: ContainerUnmountLibpod
export def "libpod-containers-unmount ContainerUnmountLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/containers/($name)/unmount")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpause Container
#
# POST /libpod/containers/{name}/unpause
# operationId: ContainerUnpauseLibpod
export def "libpod-containers-unpause ContainerUnpauseLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/containers/($name)/unpause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the configuration of an existing container, allowing changes to resource limits and healthchecks
#
# POST /libpod/containers/{name}/update
# operationId: ContainerUpdateLibpod
# --BlkIOWeightDevice item shape: {Path?: string, Weight?: int}
# --DeviceReadBPs item shape: {Path?: string, Rate?: int}
# --DeviceReadIOPs item shape: {Path?: string, Rate?: int}
# --DeviceWriteBPs item shape: {Path?: string, Rate?: int}
# --DeviceWriteIOPs item shape: {Path?: string, Rate?: int}
# --blockIO shape: {leafWeight?: int, throttleReadBpsDevice?: list, throttleReadIOPSDevice?: list, throttleWriteBpsDevice?: list, throttleWriteIOPSDevice?: list, weight?: int, weightDevice?: list}
# --cpu shape: {burst?: int, cpus?: string, idle?: int, mems?: string, period?: int, quota?: int, realtimePeriod?: int, realtimeRuntime?: int, shares?: int}
# --devices item shape: {access?: string, allow?: bool, major?: int, minor?: int, type?: string}
# --hugepageLimits item shape: {limit?: int, pageSize?: string}
# --memory shape: {checkBeforeUpdate?: bool, disableOOMKiller?: bool, kernel?: int, kernelTCP?: int, limit?: int, reservation?: int, swap?: int, swappiness?: int, useHierarchy?: bool}
# --network shape: {classID?: int, priorities?: list}
# --pids shape: {limit?: int}
# --r_limits item shape: {hard?: int, soft?: int, type?: string}
export def "libpod-containers-update ContainerUpdateLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --restartPolicy: string # New restart policy for the container.
  --restartRetries: int # New amount of retries for the container's restart policy. Only allowed if restartPolicy is set to on-failure
  --BlkIOWeightDevice: list # Block IO weight (relative device weight) in the form: ```[{"Path": "device_path", "Weight": weight}]``` — item shape: {Path?: string, Weight?: int}
  --DeviceReadBPs: list # Limit read rate (bytes per second) from a device, in the form: ```[{"Path": "device_path", "Rate": rate}]``` — item shape: {Path?: string, Rate?: int}
  --DeviceReadIOPs: list # Limit read rate (IO per second) from a device, in the form: ```[{"Path": "device_path", "Rate": rate}]``` — item shape: {Path?: string, Rate?: int}
  --DeviceWriteBPs: list # Limit write rate (bytes per second) to a device, in the form: ```[{"Path": "device_path", "Rate": rate}]``` — item shape: {Path?: string, Rate?: int}
  --DeviceWriteIOPs: list # Limit write rate (IO per second) to a device, in the form: ```[{"Path": "device_path", "Rate": rate}]``` — item shape: {Path?: string, Rate?: int}
  --Env: list
  --UnsetEnv: list
  --blockIO: record # LinuxBlockIO for Linux cgroup 'blkio' resource management — shape: {leafWeight?: int, throttleReadBpsDevice?: list, throttleReadIOPSDevice?: list, throttleWriteBpsDevice?: list, throttleWriteIOPSDevice?: list, weight?: int, weightDevice?: list}
  --cpu: record # LinuxCPU for Linux cgroup 'cpu' resource management — shape: {burst?: int, cpus?: string, idle?: int, mems?: string, period?: int, quota?: int, realtimePeriod?: int, realtimeRuntime?: int, shares?: int}
  --devices: list # Devices configures the device allowlist. — item shape: {access?: string, allow?: bool, major?: int, minor?: int, type?: string}
  --health-cmd: string # HealthCmd set a healthcheck command for the container. ('none' disables the existing healthcheck)
  --health-interval: string # HealthInterval set an interval for the healthcheck. (a value of disable results in no automatic timer setup) Changing this setting resets timer.
  --health-log-destination: string # HealthLogDestination set the destination of the HealthCheck log. Directory path, local or events_logger (local use container state file) Warning: Changing this setting may cause the loss of previous logs!
  --health-max-log-count: int # HealthMaxLogCount set maximum number of attempts in the HealthCheck log file. ('0' value means an infinite number of attempts in the log file) (format: uint64)
  --health-max-log-size: int # HealthMaxLogSize set maximum length in characters of stored HealthCheck log. ('0' value means an infinite log length) (format: uint64)
  --health-on-failure: string # HealthOnFailure set the action to take once the container turns unhealthy.
  --health-retries: int # HealthRetries set the number of retries allowed before a healthcheck is considered to be unhealthy. (format: uint64)
  --health-start-period: string # HealthStartPeriod set the initialization time needed for a container to bootstrap.
  --health-startup-cmd: string # HealthStartupCmd set a startup healthcheck command for the container.
  --health-startup-interval: string # HealthStartupInterval set an interval for the startup healthcheck. Changing this setting resets the timer, depending on the state of the container.
  --health-startup-retries: int # HealthStartupRetries set the maximum number of retries before the startup healthcheck will restart the container. (format: uint64)
  --health-startup-success: int # HealthStartupSuccess set the number of consecutive successes before the startup healthcheck is marked as successful and the normal healthcheck begins (0 indicates any success will start the regular healthcheck) (format: uint64)
  --health-startup-timeout: string # HealthStartupTimeout set the maximum amount of time that the startup healthcheck may take before it is considered failed.
  --health-timeout: string # HealthTimeout set the maximum time allowed to complete the healthcheck before an interval is considered failed.
  --hugepageLimits: list # Hugetlb limits (in bytes). Default to reservation limits if supported. — item shape: {limit?: int, pageSize?: string}
  --memory: record # LinuxMemory for Linux cgroup 'memory' resource management — shape: {checkBeforeUpdate?: bool, disableOOMKiller?: bool, kernel?: int, kernelTCP?: int, limit?: int, reservation?: int, swap?: int, swappiness?: int, useHierarchy?: bool}
  --network: record # LinuxNetwork identification and priority configuration — shape: {classID?: int, priorities?: list}
  --no-healthcheck: oneof<nothing, bool> # Disable healthchecks on container.
  --pids: record # LinuxPids for Linux cgroup 'pids' resource management (Linux 4.3) — shape: {limit?: int}
  --r-limits: list # item shape: {hard?: int, soft?: int, type?: string}
  --rdma: record # Rdma resource restriction configuration. Limits are a set of key value pairs that define RDMA resource limits, where the key is device name and value is resource limits.
  --unified: record # Unified resources.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "restartPolicy" $restartPolicy "scalar") (serialize-qp "restartRetries" $restartRetries "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/update" $qp)
  let body = {BlkIOWeightDevice: $BlkIOWeightDevice, DeviceReadBPs: $DeviceReadBPs, DeviceReadIOPs: $DeviceReadIOPs, DeviceWriteBPs: $DeviceWriteBPs, DeviceWriteIOPs: $DeviceWriteIOPs, Env: $Env, UnsetEnv: $UnsetEnv, blockIO: $blockIO, cpu: $cpu, devices: $devices, health_cmd: $health_cmd, health_interval: $health_interval, health_log_destination: $health_log_destination, health_max_log_count: $health_max_log_count, health_max_log_size: $health_max_log_size, health_on_failure: $health_on_failure, health_retries: $health_retries, health_start_period: $health_start_period, health_startup_cmd: $health_startup_cmd, health_startup_interval: $health_startup_interval, health_startup_retries: $health_startup_retries, health_startup_success: $health_startup_success, health_startup_timeout: $health_startup_timeout, health_timeout: $health_timeout, hugepageLimits: $hugepageLimits, memory: $memory, network: $network, no_healthcheck: $no_healthcheck, pids: $pids, r_limits: $r_limits, rdma: $rdma, unified: $unified} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Wait on a container
#
# POST /libpod/containers/{name}/wait
# operationId: ContainerWaitLibpod
export def "libpod-containers-wait ContainerWaitLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --condition: list # Conditions to wait for. If no condition provided the 'exited' condition is assumed.
  --interval: string # Time Interval to wait before polling for completion. (default: 250ms)
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "condition" $condition "csv") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/containers/($name)/wait" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a container
#
# POST /libpod/containers/create
# operationId: ContainerCreateLibpod
# --artifact_volumes item shape: {destination?: string, digest?: string, name?: string, source?: string, title?: string}
# --cgroupns shape: {nsmode?: string, value?: string}
# --device_cgroup_rule item shape: {access?: string, allow?: bool, major?: int, minor?: int, type?: string}
# --devices item shape: {fileMode?: int, gid?: int, major?: int, minor?: int, path?: string, type?: string, uid?: int}
# --healthconfig shape: {Interval?: int, Retries?: int, StartInterval?: int, StartPeriod?: int, Test?: list, Timeout?: int}
# --host_device_list item shape: {fileMode?: int, gid?: int, major?: int, minor?: int, path?: string, type?: string, uid?: int}
# --idmappings shape: {AutoUserNs?: bool, AutoUserNsOpts?: record, GIDMap?: list, HostGIDMapping?: bool, HostUIDMapping?: bool, UIDMap?: list}
# --image_volumes item shape: {Destination?: string, ReadWrite?: bool, Source?: string, subPath?: string}
# --intelRdt shape: {closID?: string, enableMonitoring?: bool, l3CacheSchema?: string, memBwSchema?: string, schemata?: list}
# --ipcns shape: {nsmode?: string, value?: string}
# --log_configuration shape: {driver?: string, labels?: record, options?: record, path?: string, size?: int}
# --mounts item shape: {BindOptions?: record, ClusterOptions?: record, Consistency?: string, ImageOptions?: record, ReadOnly?: bool, Source?: string, Target?: string, TmpfsOptions?: record, Type?: string, VolumeOptions?: record}
# --netns shape: {nsmode?: string, value?: string}
# --overlay_volumes item shape: {destination?: string, options?: list, source?: string}
# --personality shape: {domain?: string, flags?: list}
# --pidns shape: {nsmode?: string, value?: string}
# --portmappings item shape: {container_port?: int, host_ip?: string, host_port?: int, protocol?: string, range?: int}
# --r_limits item shape: {hard?: int, soft?: int, type?: string}
# --resource_limits shape: {blockIO?: record, cpu?: record, devices?: list, hugepageLimits?: list, memory?: record, network?: record, pids?: record, rdma?: record, unified?: record}
# --secrets item shape: {GID?: int, Mode?: int, Source?: string, Target?: string, UID?: int}
# --startupHealthConfig shape: {Interval?: int, Retries?: int, StartInterval?: int, StartPeriod?: int, Successes?: int, Test?: list, Timeout?: int}
# --userns shape: {nsmode?: string, value?: string}
# --utsns shape: {nsmode?: string, value?: string}
# --volumes item shape: {Dest?: string, IsAnonymous?: bool, Name?: string, Options?: list, SubPath?: string}
export def "libpod-containers-create ContainerCreateLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Networks: record # Map of networks names or ids that the container should join. You can request additional settings for each network, you can set network aliases, static ips, static mac address  and the network interface name for this container on the specific network. If the map is empty and the bridge network mode is set the container will be joined to the default network. Optional.
  --annotations: record # Annotations are key-value options passed into the container runtime that can be used to trigger special behavior. Optional.
  --apparmor-profile: string # ApparmorProfile is the name of the Apparmor profile the container will use. Optional.
  --artifact-volumes: list # ArtifactVolumes volumes based on an existing artifact. — item shape: {destination?: string, digest?: string, name?: string, source?: string, title?: string}
  --base-hosts-file: string # BaseHostsFile is the base file to create the `/etc/hosts` file inside the container. This must either be an absolute path to a file on the host system, or one of the special flags `image` or `none`. If it is empty it defaults to the base_hosts_file configuration in containers.conf. Optional.
  --cap-add: list # CapAdd are capabilities which will be added to the container. Conflicts with Privileged. Optional.
  --cap-drop: list # CapDrop are capabilities which will be removed from the container. Conflicts with Privileged. Optional.
  --cgroup-parent: string # CgroupParent is the container's Cgroup parent. If not set, the default for the current cgroup driver will be used. Optional.
  --cgroupns: record # Namespace describes the namespace — shape: {nsmode?: string, value?: string}
  --cgroups-mode: string # CgroupsMode sets a policy for how cgroups will be created for the container, including the ability to disable creation entirely. Optional.
  --chroot-directories: list # ChrootDirs is an additional set of directories that need to be treated as root directories. Standard bind mounts will be mounted into paths relative to these directories. Optional.
  --command: list # Command is the container's command. If not given and Image is specified, this will be populated by the image's configuration. Optional.
  --conmon-pid-file: string # ConmonPidFile is a path at which a PID file for Conmon will be placed. If not given, a default location will be used. Optional.
  --containerCreateCommand: list # ContainerCreateCommand is the command that was used to create this container. This will be shown in the output of Inspect() on the container, and may also be used by some tools that wish to recreate the container (e.g. `podman generate systemd --new`). Optional.
  --create-working-dir: oneof<nothing, bool> # Create the working directory if it doesn't exist. If unset, it doesn't create it. Optional.
  --dependencyContainers: list # DependencyContainers is an array of containers this container depends on. Dependency containers must be started before this container. Dependencies can be specified by name or full/partial ID. Optional.
  --device-cgroup-rule: list # DeviceCgroupRule are device cgroup rules that allow containers to use additional types of devices. — item shape: {access?: string, allow?: bool, major?: int, minor?: int, type?: string}
  --devices: list # Devices are devices that will be added to the container. Optional. — item shape: {fileMode?: int, gid?: int, major?: int, minor?: int, path?: string, type?: string, uid?: int}
  --devices-from: list # DevicesFrom specifies that this container will mount the device(s) from other container(s). Optional.
  --dns-option: list # DNSOptions is a set of DNS options that will be used in the container's resolv.conf, replacing the host's DNS options which are used by default. Conflicts with UseImageResolvConf. Optional.
  --dns-search: list # DNSSearch is a set of DNS search domains that will be used in the container's resolv.conf, replacing the host's DNS search domains which are used by default. Conflicts with UseImageResolvConf. Optional.
  --dns-server: list # DNSServers is a set of DNS servers that will be used in the container's resolv.conf, replacing the host's DNS Servers which are used by default. Conflicts with UseImageResolvConf. Optional.
  --entrypoint: list # Entrypoint is the container's entrypoint. If not given and Image is specified, this will be populated by the image's configuration. Optional.
  --env: record # Env is a set of environment variables that will be set in the container. Optional.
  --env-host: oneof<nothing, bool> # EnvHost indicates that the host environment should be added to container Optional.
  --envmerge: list # EnvMerge takes the specified environment variables from image and preprocess them before injecting them into the container. Optional.
  --expose: any # Expose is a number of ports that will be forwarded to the container if PublishExposedPorts is set. Expose is a map of uint16 (port number) to a string representing protocol i.e map[uint16]string. Allowed protocols are "tcp", "udp", and "sctp", or some combination of the three separated by commas. If protocol is set to "" we will assume TCP. Only available if NetNS is set to Bridge or Pasta, and PublishExposedPorts is set. Optional.
  --gpus: list # GPUs contains GPU device identifiers for CDI resolution. These will be resolved to full CDI device paths on the server side. Optional.
  --group-entry: string # GroupEntry specifies an arbitrary string to append to the container's /etc/group file. Optional.
  --groups: list # Groups are a list of supplemental groups the container's user will be granted access to. Optional.
  --health-check-on-failure-action: int # HealthCheckOnFailureAction defines how Podman reacts when a container's health status turns unhealthy. (format: int64)
  --healthLogDestination: string # HealthLogDestination defines the destination where the log is stored. TODO (6.0): In next major release convert it to pointer and use omitempty
  --healthMaxLogCount: int # HealthMaxLogCount is maximum number of attempts in the HealthCheck log file. ('0' value means an infinite number of attempts in the log file). TODO (6.0): In next major release convert it to pointer and use omitempty (format: uint64)
  --healthMaxLogSize: int # HealthMaxLogSize is the maximum length in characters of stored HealthCheck log ("0" value means an infinite log length). TODO (6.0): In next major release convert it to pointer and use omitempty (format: uint64)
  --healthconfig: record # Schema2HealthConfig is a HealthConfig, which holds configuration settings for the HEALTHCHECK feature, from docker/docker/api/types/container. — shape: {Interval?: int, Retries?: int, StartInterval?: int, StartPeriod?: int, Test?: list, Timeout?: int}
  --host-device-list: list # HostDeviceList is used to recreate the mounted device on inherited containers — item shape: {fileMode?: int, gid?: int, major?: int, minor?: int, path?: string, type?: string, uid?: int}
  --hostadd: list # HostAdd is a set of hosts which will be added to the container's etc/hosts file. Conflicts with UseImageHosts. Optional.
  --hostname: string # Hostname is the container's hostname. If not set, the hostname will not be modified (if UtsNS is not private) or will be set to the container ID (if UtsNS is private). Conflicts with UtsNS if UtsNS is not set to private. Optional.
  --hostusers: list # HostUsers is a list of host usernames or UIDs to add to the container etc/passwd file
  --httpproxy: oneof<nothing, bool> # EnvHTTPProxy indicates that the http host proxy environment variables should be added to container Optional.
  --idmappings: record # IDMappingOptions are used for specifying how ID mapping should be set up for a layer or container. — shape: {AutoUserNs?: bool, AutoUserNsOpts?: record, GIDMap?: list, HostGIDMapping?: bool, HostUIDMapping?: bool, UIDMap?: list}
  --image: string # Image is the image the container will be based on. The image will be used as the container's root filesystem, and its environment vars, volumes, and other configuration will be applied to the container. Conflicts with Rootfs. At least one of Image or Rootfs must be specified.
  --image-arch: string # ImageArch is the user-specified image architecture. Used to select a different variant from a manifest list. Optional.
  --image-os: string # ImageOS is the user-specified OS of the image. Used to select a different variant from a manifest list. Optional.
  --image-variant: string # ImageVariant is the user-specified image variant. Used to select a different variant from a manifest list. Optional.
  --image-volume-mode: string # ImageVolumeMode indicates how image volumes will be created. Supported modes are "ignore" (do not create), "tmpfs" (create as tmpfs), and "anonymous" (create as anonymous volumes). The default if unset is anonymous. Optional.
  --image-volumes: list # Image volumes bind-mount a container-image mount into the container. Optional. — item shape: {Destination?: string, ReadWrite?: bool, Source?: string, subPath?: string}
  --init: oneof<nothing, bool> # Init specifies that an init binary will be mounted into the container, and will be used as PID1. Optional.
  --init-container-type: string # InitContainerType describes if this container is an init container and if so, what type: always or once. Optional.
  --init-path: string # InitPath specifies the path to the init binary that will be added if Init is specified above. If not specified, the default set in the Libpod config will be used. Ignored if Init above is not set. Optional.
  --intelRdt: record # LinuxIntelRdt has container runtime resource constraints for Intel RDT CAT and MBA features and flags enabling Intel RDT CMT and MBM features. Intel RDT features are available in Linux 4.14 and newer kernel versions. — shape: {closID?: string, enableMonitoring?: bool, l3CacheSchema?: string, memBwSchema?: string, schemata?: list}
  --ipcns: record # Namespace describes the namespace — shape: {nsmode?: string, value?: string}
  --label-nested: oneof<nothing, bool> # LabelNested indicates whether or not the container is allowed to run fully nested containers including SELinux labelling. Optional.
  --labels: record # Labels are key-value pairs that are used to add metadata to containers. Optional.
  --log-configuration: record # LogConfig describes the logging characteristics for a container — shape: {driver?: string, labels?: record, options?: record, path?: string, size?: int}
  --manage-password: oneof<nothing, bool> # Passwd is a container run option that determines if we are validating users/groups before running the container
  --mask: list # Mask is the path we want to mask in the container. This masks the paths given in addition to the default list. Optional
  --mounts: list # Mounts are mounts that will be added to the container. These will supersede Image Volumes and VolumesFrom volumes where there are conflicts. Optional. — item shape: {BindOptions?: record, ClusterOptions?: record, Consistency?: string, ImageOptions?: record, ReadOnly?: bool, Source?: string, Target?: string, TmpfsOptions?: record, Type?: string, VolumeOptions?: record}
  --name: string # Name is the name the container will be given. If no name is provided, one will be randomly generated. Optional.
  --netns: record # Namespace describes the namespace — shape: {nsmode?: string, value?: string}
  --network-options: record # NetworkOptions are additional options for each network Optional.
  --networkOrder: list # The order that networks will be configured in. If not set, alphabetical order based on network name will be used. If set: Must be the same length as Networks and its contents must be every key in the Networks map. Optional.
  --no-new-privileges: oneof<nothing, bool> # NoNewPrivileges is whether the container will set the no new privileges flag on create, which disables gaining additional privileges (e.g. via setuid) in the container. Optional.
  --oci-runtime: string # OCIRuntime is the name of the OCI runtime that will be used to create the container. If not specified, the default will be used. Optional.
  --oom-score-adj: int # OOMScoreAdj adjusts the score used by the OOM killer to determine processes to kill for the container's process. Optional. (format: int64)
  --overlay-volumes: list # Overlay volumes are named volumes that will be added to the container. Optional. — item shape: {destination?: string, options?: list, source?: string}
  --passwd-entry: string # PasswdEntry specifies an arbitrary string to append to the container's /etc/passwd file. Optional.
  --personality: record # LinuxPersonality represents the Linux personality syscall input — shape: {domain?: string, flags?: list}
  --pidns: record # Namespace describes the namespace — shape: {nsmode?: string, value?: string}
  --pod: string # Pod is the ID of the pod the container will join. Optional.
  --portmappings: list # PortBindings is a set of ports to map into the container. Only available if NetNS is set to bridge or pasta. Optional. — item shape: {container_port?: int, host_ip?: string, host_port?: int, protocol?: string, range?: int}
  --privileged: oneof<nothing, bool> # Privileged is whether the container is privileged. Privileged does the following: Adds all devices on the system to the container. Adds all capabilities to the container. Disables Seccomp, SELinux, and Apparmor confinement. (Though SELinux can be manually re-enabled). TODO: this conflicts with things. TODO: this does more. Optional.
  --procfs-opts: list # ProcOpts are the options used for the proc mount.
  --publish-image-ports: oneof<nothing, bool> # PublishExposedPorts will publish ports specified in the image to random unused ports (guaranteed to be above 1024) on the host. This is based on ports set in Expose below, and any ports specified by the Image (if one is given). Only available if NetNS is set to Bridge or Pasta. Optional.
  --r-limits: list # Rlimits are POSIX rlimits to apply to the container. Optional. — item shape: {hard?: int, soft?: int, type?: string}
  --raw-image-name: string # RawImageName is the user-specified and unprocessed input referring to a local or a remote image. Optional, but strongly encouraged to be set if Image is set.
  --read-only-filesystem: oneof<nothing, bool> # ReadOnlyFilesystem indicates that everything will be mounted as read-only. Optional.
  --read-write-tmpfs: oneof<nothing, bool> # ReadWriteTmpfs indicates that when running with a ReadOnlyFilesystem mount temporary file systems. Optional.
  --remove: oneof<nothing, bool> # Remove indicates if the container should be removed once it has been started and exits. Optional.
  --removeImage: oneof<nothing, bool> # RemoveImage indicates that the container should remove the image it was created from after it exits. Only allowed if Remove is set to true and Image, not Rootfs, is in use. Optional.
  --resource-limits: record # LinuxResources has container runtime resource constraints — shape: {blockIO?: record, cpu?: record, devices?: list, hugepageLimits?: list, memory?: record, network?: record, pids?: record, rdma?: record, unified?: record}
  --restart-policy: string # RestartPolicy is the container's restart policy - an action which will be taken when the container exits. If not given, the default policy, which does nothing, will be used. Optional.
  --restart-tries: int # RestartRetries is the number of attempts that will be made to restart the container. Only available when RestartPolicy is set to "on-failure". Optional. (format: uint64)
  --rootfs: string # Rootfs is the path to a directory that will be used as the container's root filesystem. No modification will be made to the directory, it will be directly mounted into the container as root. Conflicts with Image. At least one of Image or Rootfs must be specified.
  --rootfs-mapping: string # RootfsMapping specifies if there are UID/GID mappings to apply to the rootfs. Optional.
  --rootfs-overlay: oneof<nothing, bool> # RootfsOverlay tells if rootfs is actually an overlay on top of base path. Optional.
  --rootfs-propagation: string # RootfsPropagation is the rootfs propagation mode for the container. If not set, the default of rslave will be used. Optional.
  --sdnotifyMode: string # Determine how to handle the NOTIFY_SOCKET - do we participate or pass it through "container" - let the OCI runtime deal with it, advertise conmon's MAINPID "conmon-only" - advertise conmon's MAINPID, send READY when started, don't pass to OCI "ignore" - unset NOTIFY_SOCKET Optional.
  --seccomp-policy: string # SeccompPolicy determines which seccomp profile gets applied the container. valid values: empty,default,image
  --seccomp-profile-path: string # SeccompProfilePath is the path to a JSON file containing the container's Seccomp profile. If not specified, no Seccomp profile will be used. Optional.
  --secret-env: record # EnvSecrets are secrets that will be set as environment variables Optional.
  --secrets: list # Secrets are the secrets that will be added to the container Optional. — item shape: {GID?: int, Mode?: int, Source?: string, Target?: string, UID?: int}
  --selinux-opts: list # SelinuxProcessLabel is the process label the container will use. If SELinux is enabled and this is not specified, a label will be automatically generated if not specified. Optional.
  --shm-size: int # ShmSize is the size of the tmpfs to mount in at /dev/shm, in bytes. Conflicts with ShmSize if IpcNS is not private. Optional. (format: int64)
  --shm-size-systemd: int # ShmSizeSystemd is the size of systemd-specific tmpfs mounts specifically /run, /run/lock, /var/log/journal and /tmp. Optional (format: int64)
  --startupHealthConfig: record # shape: {Interval?: int, Retries?: int, StartInterval?: int, StartPeriod?: int, Successes?: int, Test?: list, Timeout?: int}
  --stdin: oneof<nothing, bool> # Stdin is whether the container will keep its STDIN open. Optional.
  --stop-signal: int # It implements the [os.Signal] interface. (format: int64)
  --stop-timeout: int # StopTimeout is a timeout between the container's stop signal being sent and SIGKILL being sent. If not provided, the default will be used. If 0 is used, stop signal will not be sent, and SIGKILL will be sent instead. Optional. (format: uint64)
  --storage-opts: record # StorageOpts is the container's storage options Optional.
  --sysctl: record # Sysctl sets kernel parameters for the container
  --systemd: string # Systemd is whether the container will be started in systemd mode. Valid options are "true", "false", and "always". "true" enables this mode only if the binary run in the container is sbin/init or systemd. "always" unconditionally enables systemd mode. "false" unconditionally disables systemd mode. If enabled, mounts and stop signal will be modified. If set to "always" or set to "true" and conditionally triggered, conflicts with StopSignal. If not specified, "false" will be assumed. Optional.
  --terminal: oneof<nothing, bool> # Terminal is whether the container will create a PTY. Optional.
  --throttleReadBpsDevice: record # IO read rate limit per cgroup per device, bytes per second
  --throttleReadIOPSDevice: record # IO read rate limit per cgroup per device, IO per second
  --throttleWriteBpsDevice: record # IO write rate limit per cgroup per device, bytes per second
  --throttleWriteIOPSDevice: record # IO write rate limit per cgroup per device, IO per second
  --timeout: int # Timeout is a maximum time in seconds the container will run before main process is sent SIGKILL. If 0 is used, signal will not be sent. Container can run indefinitely if they do not stop after the default termination signal. Optional. (format: uint64)
  --timezone: string # Timezone is the timezone inside the container. Local means it has the same timezone as the host machine Optional.
  --umask: string # Umask is the umask the init process of the container will be run with.
  --unified: record # CgroupConf are key-value options passed into the container runtime that are used to configure cgroup v2. Optional.
  --unmask: list # Unmask a path in the container. Some paths are masked by default, preventing them from being accessed within the container; this undoes that masking. If ALL is passed, all paths will be unmasked. Optional.
  --unsetenv: list # UnsetEnv unsets the specified default environment variables from the image or from built-in or containers.conf Optional.
  --unsetenvall: oneof<nothing, bool> # UnsetEnvAll unsetall default environment variables from the image or from built-in or containers.conf UnsetEnvAll unsets all default environment variables from the image or from built-in Optional.
  --use-image-hostname: oneof<nothing, bool> # UseImageHostname indicates that /etc/hostname should not be managed by Podman, and instead sourced from the image. Optional.
  --use-image-hosts: oneof<nothing, bool> # UseImageHosts indicates that /etc/hosts should not be managed by Podman, and instead sourced from the image. Conflicts with HostAdd. Optional.
  --use-image-resolve-conf: oneof<nothing, bool> # UseImageResolvConf indicates that resolv.conf should not be managed by Podman, but instead sourced from the image. Conflicts with DNSServer, DNSSearch, DNSOption. Optional.
  --user: string # User is the user the container will be run as. Can be given as a UID or a username; if a username, it will be resolved within the container, using the container's /etc/passwd. If unset, the container will be run as root. Optional.
  --userns: record # Namespace describes the namespace — shape: {nsmode?: string, value?: string}
  --utsns: record # Namespace describes the namespace — shape: {nsmode?: string, value?: string}
  --volatile: oneof<nothing, bool> # Volatile specifies whether the container storage can be optimized at the cost of not syncing all the dirty files in memory. Optional.
  --volumes: list # Volumes are named volumes that will be added to the container. These will supersede Image Volumes and VolumesFrom volumes where there are conflicts. Optional. — item shape: {Dest?: string, IsAnonymous?: bool, Name?: string, Options?: list, SubPath?: string}
  --volumes-from: list # VolumesFrom is a set of containers whose volumes will be added to this container. The name or ID of the container must be provided, and may optionally be followed by a : and then one or more comma-separated options. Valid options are 'ro', 'rw', and 'z'. Options will be used for all volumes sourced from the container. Optional.
  --weightDevice: record # Weight per cgroup per device, can override BlkioWeight
  --work-dir: string # WorkDir is the container's working directory. If unset, the default, /, will be used. Optional.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/libpod/containers/create")
  let body = {Networks: $Networks, annotations: $annotations, apparmor_profile: $apparmor_profile, artifact_volumes: $artifact_volumes, base_hosts_file: $base_hosts_file, cap_add: $cap_add, cap_drop: $cap_drop, cgroup_parent: $cgroup_parent, cgroupns: $cgroupns, cgroups_mode: $cgroups_mode, chroot_directories: $chroot_directories, command: $command, conmon_pid_file: $conmon_pid_file, containerCreateCommand: $containerCreateCommand, create_working_dir: $create_working_dir, dependencyContainers: $dependencyContainers, device_cgroup_rule: $device_cgroup_rule, devices: $devices, devices_from: $devices_from, dns_option: $dns_option, dns_search: $dns_search, dns_server: $dns_server, entrypoint: $entrypoint, env: $env, env_host: $env_host, envmerge: $envmerge, expose: $expose, gpus: $gpus, group_entry: $group_entry, groups: $groups, health_check_on_failure_action: $health_check_on_failure_action, healthLogDestination: $healthLogDestination, healthMaxLogCount: $healthMaxLogCount, healthMaxLogSize: $healthMaxLogSize, healthconfig: $healthconfig, host_device_list: $host_device_list, hostadd: $hostadd, hostname: $hostname, hostusers: $hostusers, httpproxy: $httpproxy, idmappings: $idmappings, image: $image, image_arch: $image_arch, image_os: $image_os, image_variant: $image_variant, image_volume_mode: $image_volume_mode, image_volumes: $image_volumes, init: $init, init_container_type: $init_container_type, init_path: $init_path, intelRdt: $intelRdt, ipcns: $ipcns, label_nested: $label_nested, labels: $labels, log_configuration: $log_configuration, manage_password: $manage_password, mask: $mask, mounts: $mounts, name: $name, netns: $netns, network_options: $network_options, networkOrder: $networkOrder, no_new_privileges: $no_new_privileges, oci_runtime: $oci_runtime, oom_score_adj: $oom_score_adj, overlay_volumes: $overlay_volumes, passwd_entry: $passwd_entry, personality: $personality, pidns: $pidns, pod: $pod, portmappings: $portmappings, privileged: $privileged, procfs_opts: $procfs_opts, publish_image_ports: $publish_image_ports, r_limits: $r_limits, raw_image_name: $raw_image_name, read_only_filesystem: $read_only_filesystem, read_write_tmpfs: $read_write_tmpfs, remove: $remove, removeImage: $removeImage, resource_limits: $resource_limits, restart_policy: $restart_policy, restart_tries: $restart_tries, rootfs: $rootfs, rootfs_mapping: $rootfs_mapping, rootfs_overlay: $rootfs_overlay, rootfs_propagation: $rootfs_propagation, sdnotifyMode: $sdnotifyMode, seccomp_policy: $seccomp_policy, seccomp_profile_path: $seccomp_profile_path, secret_env: $secret_env, secrets: $secrets, selinux_opts: $selinux_opts, shm_size: $shm_size, shm_size_systemd: $shm_size_systemd, startupHealthConfig: $startupHealthConfig, stdin: $stdin, stop_signal: $stop_signal, stop_timeout: $stop_timeout, storage_opts: $storage_opts, sysctl: $sysctl, systemd: $systemd, terminal: $terminal, throttleReadBpsDevice: $throttleReadBpsDevice, throttleReadIOPSDevice: $throttleReadIOPSDevice, throttleWriteBpsDevice: $throttleWriteBpsDevice, throttleWriteIOPSDevice: $throttleWriteIOPSDevice, timeout: $timeout, timezone: $timezone, umask: $umask, unified: $unified, unmask: $unmask, unsetenv: $unsetenv, unsetenvall: $unsetenvall, use_image_hostname: $use_image_hostname, use_image_hosts: $use_image_hosts, use_image_resolve_conf: $use_image_resolve_conf, user: $user, userns: $userns, utsns: $utsns, volatile: $volatile, volumes: $volumes, volumes_from: $volumes_from, weightDevice: $weightDevice, work_dir: $work_dir} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List containers
#
# GET /libpod/containers/json
# operationId: ContainerListLibpod
export def "libpod-containers-json ContainerListLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --all: oneof<nothing, bool> # Return all containers. By default, only running containers are shown (default: false)
  --limit: int # Return this number of most recently created containers, including non-running ones.
  --last: int # Alias for `limit`. Return this number of most recently created containers.
  --external: oneof<nothing, bool> # Return containers created by external tools that use container storage. (default: false)
  --namespace: oneof<nothing, bool> # Include namespace information (default: false)
  --pod: oneof<nothing, bool> # Ignored. Previously included details on pod name and ID that are currently included by default. (default: false)
  --size: oneof<nothing, bool> # Return the size of container as fields SizeRw and SizeRootFs. (default: false)
  --sync: oneof<nothing, bool> # Sync container state with OCI runtime (default: false)
  --filters: string # A JSON encoded value of the filters (a `map[string][]string`) to process on the containers list. Available filters: - `ancestor`=(`<image-name>[:<tag>]`, `<image id>`, or `<image@digest>`) - `annotation`=(`key` or `"key=value"`) of a container annotation - `before`=(`<container id>` or `<container name>`) - `exited=<int>` containers with exit code of `<int>` - `expose`=(`<port>[/<proto>]` or `<startport-endport>/[<proto>]`) - `health`=(`starting`, `healthy`, `unhealthy` or `none`) - `id=<ID>` a container's ID - `is-task`=(`true` or `false`) - `label`=(`key` or `"key=value"`) of a container label - `name=<name>` a container's name - `network`=(`<network id>` or `<network name>`) - `pod`=(`<pod id>` or `<pod name>`) - `publish`=(`<port>[/<proto>]` or `<startport-endport>/[<proto>]`) - `since`=(`<container id>` or `<container name>`) - `status`=(`created`, `restarting`, `running`, `removing`, `paused`, `exited` or `dead`) - `volume`=(`<volume name>` or `<mount point destination>`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "last" $last "scalar") (serialize-qp "external" $external "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "pod" $pod "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "sync" $sync "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/containers/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete stopped containers
#
# POST /libpod/containers/prune
# operationId: ContainerPruneLibpod
export def "libpod-containers-prune ContainerPruneLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: string # Filters to process on the prune list, encoded as JSON (a `map[string][]string`).  Available filters:  - `annotation` (`annotation=<key>`, `annotation=<key>=<value>`, `annotation!=<key>`, or `annotation!=<key>=<value>`) Prune containers with (or without, in case `annotation!=...` is used) the specified annotations.  - `label` (`label=<key>`, `label=<key>=<value>`, `label!=<key>`, or `label!=<key>=<value>`) Prune containers with (or without, in case `label!=...` is used) the specified labels.  - `until=<timestamp>` Prune containers created before this timestamp. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/containers/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show mounted containers
#
# GET /libpod/containers/showmounted
# operationId: ContainerShowMountedLibpod
export def "libpod-containers-showmounted ContainerShowMountedLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/libpod/containers/showmounted")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get stats for one or more containers
#
# GET /libpod/containers/stats
# operationId: ContainersStatsAllLibpod
export def "libpod-containers-stats ContainersStatsAllLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --containers: list # names or IDs of containers
  --stream: oneof<nothing, bool> # Stream the output (default: true)
  --interval: int # Time in seconds between stats reports (default: 5)
  --all: oneof<nothing, bool> # Provide statistics for all running containers (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "containers" $containers "csv") (serialize-qp "stream" $stream "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/containers/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get events
#
# GET /libpod/events
# operationId: SystemEventsLibpod
export def "libpod-events SystemEventsLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # start streaming events from this time
  --until: string # stop streaming events later than this
  --filters: string # JSON encoded map[string][]string of constraints
  --stream: oneof<nothing, bool> # when false, do not follow events (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "stream" $stream "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect an exec instance
#
# GET /libpod/exec/{id}/json
# operationId: ExecInspectLibpod
export def "libpod-exec-json ExecInspectLibpod" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/exec/($id)/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resize an exec instance
#
# POST /libpod/exec/{id}/resize
# operationId: ExecResizeLibpod
export def "libpod-exec-resize ExecResizeLibpod" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --h: int # Height of the TTY session in characters
  --w: int # Width of the TTY session in characters
  --running: oneof<nothing, bool> # Ignore containers not running errors
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "h" $h "scalar") (serialize-qp "w" $w "scalar") (serialize-qp "running" $running "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/exec/($id)/resize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start an exec instance
#
# POST /libpod/exec/{id}/start
# operationId: ExecStartLibpod
export def "libpod-exec-start ExecStartLibpod" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Detach: oneof<nothing, bool> # Detach from the command.
  --Tty: oneof<nothing, bool> # Allocate a pseudo-TTY.
  --h: int # Height of the TTY session in characters. Tty must be set to true to use it.
  --w: int # Width of the TTY session in characters. Tty must be set to true to use it.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/exec/($id)/start")
  let body = {Detach: $Detach, Tty: $Tty, h: $h, w: $w} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate Systemd Units
#
# GET /libpod/generate/{name}/systemd
# operationId: GenerateSystemdLibpod
export def "libpod-generate-systemd GenerateSystemdLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --useName: oneof<nothing, bool> # Use container/pod names instead of IDs. (default: false)
  --new: oneof<nothing, bool> # Create a new container instead of starting an existing one. (default: false)
  --noHeader: oneof<nothing, bool> # Do not generate the header including the Podman version and the timestamp. (default: false)
  --startTimeout: int # Start timeout in seconds. (default: 0)
  --stopTimeout: int # Stop timeout in seconds. (default: 10)
  --restartPolicy: string@restartPolicy-completer # Systemd restart-policy. (default: on-failure)
  --containerPrefix: string # Systemd unit name prefix for containers. (default: container)
  --podPrefix: string # Systemd unit name prefix for pods. (default: pod)
  --separator: string # Systemd unit name separator between name/id and prefix. (default: -)
  --restartSec: int # Configures the time to sleep before restarting a service. (default: 0)
  --wants: list # Systemd Wants list for the container or pods. (default: [])
  --after: list # Systemd After list for the container or pods. (default: [])
  --requires: list # Systemd Requires list for the container or pods. (default: [])
  --additionalEnvVariables: list # Set environment variables to the systemd unit files. (default: [])
  --templateUnitFile: oneof<nothing, bool> # Add template specifier for the systemd unit file names. (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "useName" $useName "scalar") (serialize-qp "new" $new "scalar") (serialize-qp "noHeader" $noHeader "scalar") (serialize-qp "startTimeout" $startTimeout "scalar") (serialize-qp "stopTimeout" $stopTimeout "scalar") (serialize-qp "restartPolicy" $restartPolicy "scalar") (serialize-qp "containerPrefix" $containerPrefix "scalar") (serialize-qp "podPrefix" $podPrefix "scalar") (serialize-qp "separator" $separator "scalar") (serialize-qp "restartSec" $restartSec "scalar") (serialize-qp "wants" $wants "csv") (serialize-qp "after" $after "csv") (serialize-qp "requires" $requires "csv") (serialize-qp "additionalEnvVariables" $additionalEnvVariables "csv") (serialize-qp "templateUnitFile" $templateUnitFile "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/generate/($name)/systemd" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a Kubernetes YAML file.
#
# GET /libpod/generate/kube
# operationId: GenerateKubeLibpod
export def "libpod-generate-kube GenerateKubeLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --names: list # Name or ID of the container or pod.
  --service: oneof<nothing, bool> # Generate YAML for a Kubernetes service object. (default: false)
  --type: string # Generate YAML for the given Kubernetes kind. (default: pod)
  --replicas: int # Set the replica number for Deployment kind. (format: int32, default: 0)
  --noTrunc: oneof<nothing, bool> # don't truncate annotations to the Kubernetes maximum length of 63 characters (default: false)
  --podmanOnly: oneof<nothing, bool> # add podman-only reserved annotations in generated YAML file (cannot be used by Kubernetes) (default: false)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "names" $names "csv") (serialize-qp "service" $service "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "replicas" $replicas "scalar") (serialize-qp "noTrunc" $noTrunc "scalar") (serialize-qp "podmanOnly" $podmanOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/generate/kube" $qp)
  let accept_val = ($accept | default "text/vnd.yaml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an image from the local storage.
#
# DELETE /libpod/images/{name}
# operationId: ImageDeleteLibpod
export def "libpod-images ImageDeleteLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # remove the image even if used by containers or has other tags
  --ignore: oneof<nothing, bool> # Ignore if a specified image does not exist and do not throw an error. (default: false)
  --lookupManifest: oneof<nothing, bool> # Resolve to a manifest list instead of an image.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "ignore" $ignore "scalar") (serialize-qp "lookupManifest" $lookupManifest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/images/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Report on changes to images's filesystem; adds, deletes or modifications.
#
# GET /libpod/images/{name}/changes
# operationId: ImageChangesLibpod
export def "libpod-images-changes ImageChangesLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --parent: string # specify a second layer which is used to compare against it instead of the parent layer
  --diffType: string@diffType-completer # select what you want to match, default is all
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent" $parent "scalar") (serialize-qp "diffType" $diffType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/images/($name)/changes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Image exists
#
# GET /libpod/images/{name}/exists
# operationId: ImageExistsLibpod
export def "libpod-images-exists ImageExistsLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/images/($name)/exists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export an image
#
# GET /libpod/images/{name}/get
# operationId: ImageGetLibpod
export def "libpod-images-get ImageGetLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string # format for exported image
  --compress: oneof<nothing, bool> # use compression on image
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "compress" $compress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/images/($name)/get" $qp)
  let accept_val = "application/x-tar"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# History of an image
#
# GET /libpod/images/{name}/history
# operationId: ImageHistoryLibpod
export def "libpod-images-history ImageHistoryLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/images/($name)/history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect an image
#
# GET /libpod/images/{name}/json
# operationId: ImageInspectLibpod
export def "libpod-images-json ImageInspectLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/images/($name)/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Push Image
#
# POST /libpod/images/{name}/push
# operationId: ImagePushLibpod
export def "libpod-images-push ImagePushLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --destination: string # Allows for pushing the image to a different destination than the image refers to.
  --forceCompressionFormat: oneof<nothing, bool> # Enforce compressing the layers with the specified --compression and do not reuse differently compressed blobs on the registry. (default: false)
  --compressionFormat: string # Compression format used to compress image layers.
  --compressionLevel: int # Compression level used to compress image layers.
  --tlsVerify: oneof<nothing, bool> # Require TLS verification. (default: true)
  --quiet: oneof<nothing, bool> # Silences extra stream data on push. (default: true)
  --format: string # Manifest type (oci, v2s1, or v2s2) to use when pushing an image. Default is manifest type of source, with fallbacks.
  --all: oneof<nothing, bool> # All indicates whether to push all images related to the image list.
  --removeSignatures: oneof<nothing, bool> # Discard any pre-existing signatures in the image.
  --retry: int # Number of times to retry push in case of failure.
  --retryDelay: string # Delay between retries in case of push failures. Duration format such as "412ms", or "3.5h".
  --X-Registry-Auth: string # A base64-encoded auth configuration.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "destination" $destination "scalar") (serialize-qp "forceCompressionFormat" $forceCompressionFormat "scalar") (serialize-qp "compressionFormat" $compressionFormat "scalar") (serialize-qp "compressionLevel" $compressionLevel "scalar") (serialize-qp "tlsVerify" $tlsVerify "scalar") (serialize-qp "quiet" $quiet "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "all" $all "scalar") (serialize-qp "removeSignatures" $removeSignatures "scalar") (serialize-qp "retry" $retry "scalar") (serialize-qp "retryDelay" $retryDelay "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/images/($name)/push" $qp)
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve an image (short) name
#
# GET /libpod/images/{name}/resolve
# operationId: ImageResolveLibpod
export def "libpod-images-resolve ImageResolveLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/images/($name)/resolve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tag an image
#
# POST /libpod/images/{name}/tag
# operationId: ImageTagLibpod
export def "libpod-images-tag ImageTagLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --repo: string # the repository to tag in
  --tag: string # the name of the new tag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "repo" $repo "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/images/($name)/tag" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Image tree
#
# GET /libpod/images/{name}/tree
# operationId: ImageTreeLibpod
export def "libpod-images-tree ImageTreeLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --whatrequires: oneof<nothing, bool> # show all child images and layers of the specified image
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "whatrequires" $whatrequires "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/images/($name)/tree" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Untag an image
#
# POST /libpod/images/{name}/untag
# operationId: ImageUntagLibpod
export def "libpod-images-untag ImageUntagLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --repo: string # the repository to untag
  --tag: string # the name of the tag to untag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "repo" $repo "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/images/($name)/untag" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export multiple images
#
# GET /libpod/images/export
# operationId: ImageExportLibpod
export def "libpod-images-export ImageExportLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string # format for exported image (only docker-archive is supported)
  --references: list # references to images to export
  --compress: oneof<nothing, bool> # use compression on image
  --ociAcceptUncompressedLayers: oneof<nothing, bool> # accept uncompressed layers when copying OCI images
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "references" $references "csv") (serialize-qp "compress" $compress "scalar") (serialize-qp "ociAcceptUncompressedLayers" $ociAcceptUncompressedLayers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/images/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import image
#
# POST /libpod/images/import
# operationId: ImageImportLibpod
export def "libpod-images-import ImageImportLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --changes: list # Apply the following possible instructions to the created image: CMD | ENTRYPOINT | ENV | EXPOSE | LABEL | STOPSIGNAL | USER | VOLUME | WORKDIR.  JSON encoded string
  --message: string # Set commit message for imported image
  --reference: string # Optional Name[:TAG] for the image
  --qp-url: string # Load image from the specified URL
  --Content-Type: string@Content-Type-completer
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "changes" $changes "csv") (serialize-qp "message" $message "scalar") (serialize-qp "reference" $reference "scalar") (serialize-qp "url" $qp_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/images/import" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Images
#
# GET /libpod/images/json
# operationId: ImageListLibpod
export def "libpod-images-json ImageListLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --all: oneof<nothing, bool> # Show all images. Only images from a final layer (no children) are shown by default. (default: false)
  --filters: string # JSON-encoded string containing filters as a `map[string][]string` to process on the images list. Available filters: - `before`=(`<image-name>[:<tag>]`,  `<image id>` or `<image@digest>`) - `dangling=true` - `label=key` or `label="key=value"` of an image label - `reference`=(`<image-name>[:<tag>]`) - `id`=(`<image-id>`) - `since`=(`<image-name>[:<tag>]`,  `<image id>` or `<image@digest>`)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/images/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load image
#
# POST /libpod/images/load
# operationId: ImageLoadLibpod
export def "libpod-images-load ImageLoadLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/libpod/images/load")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Prune unused images
#
# POST /libpod/images/prune
# operationId: ImagePruneLibpod
export def "libpod-images-prune ImagePruneLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --all: oneof<nothing, bool> # Remove all images not in use by containers, not just dangling ones  (default: false)
  --external: oneof<nothing, bool> # Remove images even when they are used by external containers (e.g, by build containers)  (default: false)
  --buildcache: oneof<nothing, bool> # Remove persistent build cache created by build instructions such as `--mount=type=cache`.  (default: false)
  --filters: string # filters to apply to image pruning, encoded as JSON (map[string][]string). Available filters:   - `dangling=<boolean>` When set to `true` (or `1`), prune only      unused *and* untagged images. When set to `false`      (or `0`), all unused images are pruned.   - `until=<string>` Prune images created before this timestamp. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time.   - `label` (`label=<key>`, `label=<key>=<value>`, `label!=<key>`, or `label!=<key>=<value>`) Prune images with (or without, in case `label!=...` is used) the specified labels.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "external" $external "scalar") (serialize-qp "buildcache" $buildcache "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/images/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pull images
#
# POST /libpod/images/pull
# operationId: ImagePullLibpod
export def "libpod-images-pull ImagePullLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reference: string # Mandatory reference to the image (e.g., quay.io/image/name:tag)
  --quiet: oneof<nothing, bool> # Silence extra stream data on pull. Cannot be used with 'compatMode' or 'pullProgress'. (default: false)
  --compatMode: oneof<nothing, bool> # Return the same JSON payload as the Docker-compat endpoint. Cannot be used with 'pullProgress' or 'quiet'. (default: false)
  --pullProgress: oneof<nothing, bool> # Send reports about the progress of the pull. Cannot be used with 'compatMode' or 'quiet'. (default: false)
  --Arch: string # Pull image for the specified architecture.
  --OS: string # Pull image for the specified operating system.
  --Variant: string # Pull image for the specified variant.
  --policy: string # Pull policy, "always" (default), "missing", "newer", "never".
  --tlsVerify: oneof<nothing, bool> # Require TLS verification. (default: true)
  --allTags: oneof<nothing, bool> # Pull all tagged images in the repository.
  --X-Registry-Auth: string # base-64 encoded auth config. Must include the following four values: username, password, email and server address OR simply just an identity token.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reference" $reference "scalar") (serialize-qp "quiet" $quiet "scalar") (serialize-qp "compatMode" $compatMode "scalar") (serialize-qp "pullProgress" $pullProgress "scalar") (serialize-qp "Arch" $Arch "scalar") (serialize-qp "OS" $OS "scalar") (serialize-qp "Variant" $Variant "scalar") (serialize-qp "policy" $policy "scalar") (serialize-qp "tlsVerify" $tlsVerify "scalar") (serialize-qp "allTags" $allTags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/images/pull" $qp)
  let extra_headers = {"X-Registry-Auth": $X_Registry_Auth} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove one or more images from the storage.
#
# DELETE /libpod/images/remove
# operationId: ImageDeleteAllLibpod
export def "libpod-images-remove ImageDeleteAllLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --images: list # Images IDs or names to remove.
  --all: oneof<nothing, bool> # Remove all images. (default: true)
  --force: oneof<nothing, bool> # Force image removal (including containers using the images).
  --ignore: oneof<nothing, bool> # Ignore if a specified image does not exist and do not throw an error.
  --lookupManifest: oneof<nothing, bool> # Resolves to manifest list instead of image.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "images" $images "csv") (serialize-qp "all" $all "scalar") (serialize-qp "force" $force "scalar") (serialize-qp "ignore" $ignore "scalar") (serialize-qp "lookupManifest" $lookupManifest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/images/remove" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copy an image from one host to another
#
# POST /libpod/images/scp/{name}
# operationId: ImageScpLibpod
export def "libpod-images-scp ImageScpLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --destination: string # dest connection/image
  --quiet: oneof<nothing, bool> # quiet output (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "destination" $destination "scalar") (serialize-qp "quiet" $quiet "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/images/scp/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search images
#
# GET /libpod/images/search
# operationId: ImageSearchLibpod
export def "libpod-images-search ImageSearchLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --term: string # term to search
  --limit: int # maximum number of results (default: 25)
  --filters: string # JSON-encoded string containing filters as a `map[string][]string` to process on the images list. Available filters: - `is-automated=(true|false)` - `is-official=(true|false)` - `stars=<number>` Matches images that have at least 'number' stars.
  --tlsVerify: oneof<nothing, bool> # Require HTTPS and verify signatures when contacting registries. (default: true)
  --listTags: oneof<nothing, bool> # list the available tags in the repository (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "tlsVerify" $tlsVerify "scalar") (serialize-qp "listTags" $listTags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/images/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get info
#
# GET /libpod/info
# operationId: SystemInfoLibpod
export def "libpod-info SystemInfoLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/libpod/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply a podman workload or Kubernetes YAML file.
#
# POST /libpod/kube/apply
# operationId: KubeApplyLibpod
export def "libpod-kube-apply KubeApplyLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --caCertFile: string # Path to the CA cert file for the Kubernetes cluster.
  --kubeConfig: string # Path to the kubeconfig file for the Kubernetes cluster.
  --namespace: string # The namespace to deploy the workload to on the Kubernetes cluster.
  --service: oneof<nothing, bool> # Create a service object for the container being deployed.
  --file: string # Path to the Kubernetes yaml file to deploy.
  --body: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "caCertFile" $caCertFile "scalar") (serialize-qp "kubeConfig" $kubeConfig "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "service" $service "scalar") (serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/kube/apply" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create image from local build context
#
# POST /libpod/local/build
# operationId: LocalBuildLibpod
export def "libpod-local-build LocalBuildLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --localcontextdir: string # Absolute path to the build context directory on the server filesystem. This directory must contain all files needed for the build.
  --dockerfile: string # Absolute path within the build context to the `Dockerfile`. This is ignored if remote is specified and points to an external `Dockerfile`.  (default: Dockerfile)
  --t: string # A name and optional tag to apply to the image in the `name:tag` format.  If you omit the tag, the default latest value is assumed. You can provide several t parameters. (default: latest)
  --allplatforms: oneof<nothing, bool> # Instead of building for a set of platforms specified using the platform option, inspect the build's base images, and build for all of the platforms that are available.  Stages that use *scratch* as a starting point can not be inspected, so at least one non-*scratch* stage must be present for detection to work usefully.  (default: false)
  --additionalbuildcontexts: list # Additional build contexts for builds that require more than one context. Each additional context must be specified as a key-value pair in the format "name=value".  The value can be specified in three formats: - URL context: Use the prefix "url:" followed by a URL to a tar archive   Example: "mycontext=url:https://example.com/context.tar" - Image context: Use the prefix "image:" followed by an image reference   Example: "mycontext=image:alpine:latest" or "mycontext=image:docker.io/library/ubuntu:22.04" - Local path context: Use the prefix "localpath:" followed by an absolute path on the server filesystem   Example: "mycontext=localpath:/path/to/context/dir"  (As of version 5.6.0)  (default: [])
  --extrahosts: string # TBD Extra hosts to add to /etc/hosts (As of version 1.xx)
  --nohosts: oneof<nothing, bool> # Not to create /etc/hosts when building the image
  --remote: string # A Git repository URI or HTTP/HTTPS context URI. If the URI points to a single text file, the file's contents are placed into a file called Dockerfile and the image is built from that file. If the URI points to a tarball, the file is downloaded by the daemon and the contents therein used as the context for the build. If the URI points to a tarball and the dockerfile parameter is also specified, there must be a file with the corresponding path inside the tarball. (As of version 1.xx)
  --q: oneof<nothing, bool> # Suppress verbose build output  (default: false)
  --compatvolumes: oneof<nothing, bool> # Contents of volume locations to be modified on ADD or COPY only (As of Podman version v5.2)  (default: false)
  --createdannotation: oneof<nothing, bool> # Add an "org.opencontainers.image.created" annotation to the image. (As of Podman version v5.6)  (default: true)
  --sourcedateepoch: float # Timestamp to use for newly-added history entries and the image's creation date. (As of Podman version v5.6)
  --rewritetimestamp: oneof<nothing, bool> # If sourcedateepoch is set, force new content added in layers to have timestamps no later than the sourcedateepoch date. (As of Podman version v5.6)  (default: false)
  --timestamp: float # Timestamp to use for newly-added history entries, the image's creation date, and for new content added in layers.
  --inheritlabels: oneof<nothing, bool> # Inherit the labels from the base image or base stages (As of Podman version v5.5)  (default: true)
  --inheritannotations: oneof<nothing, bool> # Inherit the annotations from the base image or base stages (As of Podman version v5.6)  (default: true)
  --nocache: oneof<nothing, bool> # Do not use the cache when building the image (As of version 1.xx)  (default: false)
  --cachefrom: string # JSON array of images used to build cache resolution (As of version 1.xx)
  --pull: oneof<nothing, bool> # Attempt to pull the image even if an older image exists locally (As of version 1.xx)  (default: false)
  --rm: oneof<nothing, bool> # Remove intermediate containers after a successful build (As of version 1.xx)  (default: true)
  --forcerm: oneof<nothing, bool> # Always remove intermediate containers, even upon failure (As of version 1.xx)  (default: false)
  --memory: int # Memory is the upper limit (in bytes) on how much memory running containers can use (As of version 1.xx)
  --memswap: int # MemorySwap limits the amount of memory and swap together (As of version 1.xx)
  --cpushares: int # CPUShares (relative weight (As of version 1.xx)
  --cpusetcpus: string # CPUSetCPUs in which to allow execution (0-3, 0,1) (As of version 1.xx)
  --cpuperiod: int # CPUPeriod limits the CPU CFS (Completely Fair Scheduler) period (As of version 1.xx)
  --cpuquota: int # CPUQuota limits the CPU CFS (Completely Fair Scheduler) quota (As of version 1.xx)
  --buildargs: string # JSON map of string pairs denoting build-time variables. For example, the build argument `Foo` with the value of `bar` would be encoded in JSON as `["Foo":"bar"]`.  For example, buildargs={"Foo":"bar"}.  Note(s): * This should not be used to pass secrets. * The value of buildargs should be URI component encoded before being passed to the API.  (As of version 1.xx)
  --shmsize: int # ShmSize is the "size" value to use when mounting an shmfs on the container's /dev/shm directory. Default is 64MB (As of version 1.xx)  (default: 67108864)
  --squash: oneof<nothing, bool> # Silently ignored. Squash the resulting images layers into a single layer (As of version 1.xx)  (default: false)
  --labels: string # JSON map of key, value pairs to set as labels on the new image (As of version 1.xx)
  --layerLabel: list # Add an intermediate image *label* (e.g. label=*value*) to the intermediate image metadata.
  --layers: oneof<nothing, bool> # Cache intermediate layers during build. (As of version 1.xx)  (default: true)
  --networkmode: string # Sets the networking mode for the run commands during build. Supported standard values are:   * `bridge` limited to containers within a single host, port mapping required for external access   * `host` no isolation between host and containers on this network   * `none` disable all networking for this container   * container:<nameOrID> share networking with given container   ---All other values are assumed to be a custom network's name (As of version 1.xx)  (default: bridge)
  --platform: string # Platform format os[/arch[/variant]] (As of version 1.xx)
  --target: string # Target build stage (As of version 1.xx)
  --outputs: string # output configuration TBD (As of version 1.xx)
  --httpproxy: oneof<nothing, bool> # Inject http proxy environment variables into container (As of version 2.0.0)
  --unsetenv: list # Unset environment variables from the final image.
  --unsetlabel: list # Unset the image label, causing the label not to be inherited from the base image.
  --unsetannotation: list # Unset the image annotation, causing the annotation not to be inherited from the base image. (As of Podman version v5.6)
  --volume: list # Extra volumes that should be mounted in the build container.
  --manifest: string # Add the image to the specified manifest list. Creates a manifest list if it does not exist.
  --X-Registry-Config: string
]: nothing -> record<stream: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "localcontextdir" $localcontextdir "scalar") (serialize-qp "dockerfile" $dockerfile "scalar") (serialize-qp "t" $t "scalar") (serialize-qp "allplatforms" $allplatforms "scalar") (serialize-qp "additionalbuildcontexts" $additionalbuildcontexts "csv") (serialize-qp "extrahosts" $extrahosts "scalar") (serialize-qp "nohosts" $nohosts "scalar") (serialize-qp "remote" $remote "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "compatvolumes" $compatvolumes "scalar") (serialize-qp "createdannotation" $createdannotation "scalar") (serialize-qp "sourcedateepoch" $sourcedateepoch "scalar") (serialize-qp "rewritetimestamp" $rewritetimestamp "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "inheritlabels" $inheritlabels "scalar") (serialize-qp "inheritannotations" $inheritannotations "scalar") (serialize-qp "nocache" $nocache "scalar") (serialize-qp "cachefrom" $cachefrom "scalar") (serialize-qp "pull" $pull "scalar") (serialize-qp "rm" $rm "scalar") (serialize-qp "forcerm" $forcerm "scalar") (serialize-qp "memory" $memory "scalar") (serialize-qp "memswap" $memswap "scalar") (serialize-qp "cpushares" $cpushares "scalar") (serialize-qp "cpusetcpus" $cpusetcpus "scalar") (serialize-qp "cpuperiod" $cpuperiod "scalar") (serialize-qp "cpuquota" $cpuquota "scalar") (serialize-qp "buildargs" $buildargs "scalar") (serialize-qp "shmsize" $shmsize "scalar") (serialize-qp "squash" $squash "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "layerLabel" $layerLabel "csv") (serialize-qp "layers" $layers "scalar") (serialize-qp "networkmode" $networkmode "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "target" $target "scalar") (serialize-qp "outputs" $outputs "scalar") (serialize-qp "httpproxy" $httpproxy "scalar") (serialize-qp "unsetenv" $unsetenv "csv") (serialize-qp "unsetlabel" $unsetlabel "csv") (serialize-qp "unsetannotation" $unsetannotation "csv") (serialize-qp "volume" $volume "csv") (serialize-qp "manifest" $manifest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/local/build" $qp)
  let extra_headers = {"X-Registry-Config": $X_Registry_Config} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load image from local path
#
# POST /libpod/local/images/load
# operationId: LocalImagesLibpod
export def "libpod-local-images-load LocalImagesLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string # Absolute path to the image archive file on the server filesystem
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/local/images/load" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete manifest list
#
# DELETE /libpod/manifests/{name}
# operationId: ManifestDeleteLibpod
export def "libpod-manifests ManifestDeleteLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ignore: oneof<nothing, bool> # Ignore if a specified manifest does not exist and do not throw an error.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignore" $ignore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/manifests/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create
#
# POST /libpod/manifests/{name}
# operationId: ManifestCreateLibpod
export def "libpod-manifests ManifestCreateLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --images: string # One or more names of an image or a manifest list. Repeat parameter as needed.  Support for multiple images, as of version 4.0.0 Alias of `image` is support for compatibility with < 4.0.0 Response status code is 200 with < 4.0.0 for compatibility
  --all: oneof<nothing, bool> # add all contents if given list
  --amend: oneof<nothing, bool> # modify an existing list if one with the desired name already exists
  --all: oneof<nothing, bool> # True when operating on a list to include all images
  --annotation: list # Annotation to add to the item in the manifest list
  --annotations: record # Annotations to add to the item in the manifest list by a map which is preferred over Annotation
  --arch: string # Arch overrides the architecture for the item in the manifest list
  --artifact-annotations: record
  --artifact-config: string
  --artifact-config-type: string
  --artifact-exclude-titles: oneof<nothing, bool>
  --artifact-files: list
  --artifact-layer-type: string
  --artifact-subject: string
  --artifact-type: string # The following are all of the fields from ManifestAddArtifactOptions. We can't just embed the whole structure because it embeds a ManifestAnnotateOptions, which would conflict with the one that ManifestAddOptions embeds.
  --features: list # Feature list for the item in the manifest list
  --images: list # Images is an optional list of image references to add to manifest list
  --index-annotation: list # IndexAnnotation is a slice of key=value annotations to add to the manifest list itself
  --index-annotations: record # IndexAnnotations is a map of key:value annotations to add to the manifest list itself, by a map which is preferred over IndexAnnotation
  --operation: string
  --os: string # OS overrides the operating system for the item in the manifest list
  --os-features: list # OS features for the item in the manifest list
  --os-version: string # OSVersion overrides the operating system for the item in the manifest list
  --subject: string # IndexSubject is a subject value to set in the manifest list itself
  --variant: string # Variant for the item in the manifest list
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "images" $images "scalar") (serialize-qp "all" $all "scalar") (serialize-qp "amend" $amend "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/manifests/($name)" $qp)
  let body = {all: $all, annotation: $annotation, annotations: $annotations, arch: $arch, artifact_annotations: $artifact_annotations, artifact_config: $artifact_config, artifact_config_type: $artifact_config_type, artifact_exclude_titles: $artifact_exclude_titles, artifact_files: $artifact_files, artifact_layer_type: $artifact_layer_type, artifact_subject: $artifact_subject, artifact_type: $artifact_type, features: $features, images: $images, index_annotation: $index_annotation, index_annotations: $index_annotations, operation: $operation, os: $os, os_features: $os_features, os_version: $os_version, subject: $subject, variant: $variant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Modify manifest list
#
# PUT /libpod/manifests/{name}
# operationId: ManifestModifyLibpod
export def "libpod-manifests ManifestModifyLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tlsVerify: oneof<nothing, bool> # Require HTTPS and verify signatures when contacting registries. (default: true)
  --all: oneof<nothing, bool> # True when operating on a list to include all images
  --annotation: list # Annotation to add to the item in the manifest list
  --annotations: record # Annotations to add to the item in the manifest list by a map which is preferred over Annotation
  --arch: string # Arch overrides the architecture for the item in the manifest list
  --artifact-annotations: record
  --artifact-config: string
  --artifact-config-type: string
  --artifact-exclude-titles: oneof<nothing, bool>
  --artifact-files: list
  --artifact-layer-type: string
  --artifact-subject: string
  --artifact-type: string # The following are all of the fields from ManifestAddArtifactOptions. We can't just embed the whole structure because it embeds a ManifestAnnotateOptions, which would conflict with the one that ManifestAddOptions embeds.
  --features: list # Feature list for the item in the manifest list
  --images: list # Images is an optional list of image references to add to manifest list
  --index-annotation: list # IndexAnnotation is a slice of key=value annotations to add to the manifest list itself
  --index-annotations: record # IndexAnnotations is a map of key:value annotations to add to the manifest list itself, by a map which is preferred over IndexAnnotation
  --operation: string
  --os: string # OS overrides the operating system for the item in the manifest list
  --os-features: list # OS features for the item in the manifest list
  --os-version: string # OSVersion overrides the operating system for the item in the manifest list
  --subject: string # IndexSubject is a subject value to set in the manifest list itself
  --variant: string # Variant for the item in the manifest list
]: any -> record<Id: string, errors: list<string>, files: list<string>, images: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tlsVerify" $tlsVerify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/manifests/($name)" $qp)
  let body = {all: $all, annotation: $annotation, annotations: $annotations, arch: $arch, artifact_annotations: $artifact_annotations, artifact_config: $artifact_config, artifact_config_type: $artifact_config_type, artifact_exclude_titles: $artifact_exclude_titles, artifact_files: $artifact_files, artifact_layer_type: $artifact_layer_type, artifact_subject: $artifact_subject, artifact_type: $artifact_type, features: $features, images: $images, index_annotation: $index_annotation, index_annotations: $index_annotations, operation: $operation, os: $os, os_features: $os_features, os_version: $os_version, subject: $subject, variant: $variant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add image
#
# POST /libpod/manifests/{name}/add
# operationId: ManifestAddLibpod
export def "libpod-manifests-add ManifestAddLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --all: oneof<nothing, bool> # True when operating on a list to include all images
  --annotation: list # Annotation to add to the item in the manifest list
  --annotations: record # Annotations to add to the item in the manifest list by a map which is preferred over Annotation
  --arch: string # Arch overrides the architecture for the item in the manifest list
  --features: list # Feature list for the item in the manifest list
  --images: list # Images is an optional list of image references to add to manifest list
  --index-annotation: list # IndexAnnotation is a slice of key=value annotations to add to the manifest list itself
  --index-annotations: record # IndexAnnotations is a map of key:value annotations to add to the manifest list itself, by a map which is preferred over IndexAnnotation
  --os: string # OS overrides the operating system for the item in the manifest list
  --os-features: list # OS features for the item in the manifest list
  --os-version: string # OSVersion overrides the operating system for the item in the manifest list
  --subject: string # IndexSubject is a subject value to set in the manifest list itself
  --variant: string # Variant for the item in the manifest list
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/manifests/($name)/add")
  let body = {all: $all, annotation: $annotation, annotations: $annotations, arch: $arch, features: $features, images: $images, index_annotation: $index_annotation, index_annotations: $index_annotations, os: $os, os_features: $os_features, os_version: $os_version, subject: $subject, variant: $variant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Exists
#
# GET /libpod/manifests/{name}/exists
# operationId: ManifestExistsLibpod
export def "libpod-manifests-exists ManifestExistsLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/manifests/($name)/exists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect
#
# GET /libpod/manifests/{name}/json
# operationId: ManifestInspectLibpod
export def "libpod-manifests-json ManifestInspectLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tlsVerify: oneof<nothing, bool> # Require HTTPS and verify signatures when contacting registries. (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tlsVerify" $tlsVerify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/manifests/($name)/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Push manifest to registry
#
# POST /libpod/manifests/{name}/push
# operationId: ManifestPushV3Libpod
export def "libpod-manifests-push ManifestPushV3Libpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --destination: string # the destination for the manifest
  --all: oneof<nothing, bool> # push all images
]: nothing -> record<Id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "destination" $destination "scalar") (serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/manifests/($name)/push" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Push manifest list to registry
#
# POST /libpod/manifests/{name}/registry/{destination}
# operationId: ManifestPushLibpod
export def "libpod-manifests-registry ManifestPushLibpod" [
  name: string
  destination: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --addCompression: list # add existing instances with requested compression algorithms to manifest list
  --forceCompressionFormat: oneof<nothing, bool> # Enforce compressing the layers with the specified --compression and do not reuse differently compressed blobs on the registry. (default: false)
  --all: oneof<nothing, bool> # push all images (default: true)
  --tlsVerify: oneof<nothing, bool> # Require HTTPS and verify signatures when contacting registries. (default: true)
  --quiet: oneof<nothing, bool> # silences extra stream data on push (default: true)
]: nothing -> record<Id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "addCompression" $addCompression "csv") (serialize-qp "forceCompressionFormat" $forceCompressionFormat "scalar") (serialize-qp "all" $all "scalar") (serialize-qp "tlsVerify" $tlsVerify "scalar") (serialize-qp "quiet" $quiet "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/manifests/($name)/registry/($destination)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a network
#
# DELETE /libpod/networks/{name}
# operationId: NetworkDeleteLibpod
export def "libpod-networks NetworkDeleteLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # remove containers associated with network
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/networks/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Connect container to network
#
# POST /libpod/networks/{name}/connect
# operationId: NetworkConnectLibpod
export def "libpod-networks-connect NetworkConnectLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/networks/($name)/connect")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disconnect container from network
#
# POST /libpod/networks/{name}/disconnect
# operationId: NetworkDisconnectLibpod
export def "libpod-networks-disconnect NetworkDisconnectLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Container: string # The ID or name of the container to disconnect from the network. (e.g. 3613f73ba0e4)
  --Force: oneof<nothing, bool> # Force the container to disconnect from the network. (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/networks/($name)/disconnect")
  let body = {Container: $Container, Force: $Force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Network exists
#
# GET /libpod/networks/{name}/exists
# operationId: NetworkExistsLibpod
export def "libpod-networks-exists NetworkExistsLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/networks/($name)/exists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect a network
#
# GET /libpod/networks/{name}/json
# operationId: NetworkInspectLibpod
export def "libpod-networks-json NetworkInspectLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/networks/($name)/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update existing podman network
#
# POST /libpod/networks/{name}/update
# operationId: NetworkUpdateLibpod
export def "libpod-networks-update NetworkUpdateLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --adddnsservers: list
  --removednsservers: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/networks/($name)/update")
  let body = {adddnsservers: $adddnsservers, removednsservers: $removednsservers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create network
#
# POST /libpod/networks/create
# operationId: NetworkCreateLibpod
# --routes item shape: {destination?: string, gateway?: string, metric?: int, route_type?: string}
# --subnets item shape: {gateway?: string, lease_range?: record, subnet?: string}
export def "libpod-networks-create NetworkCreateLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ignoreIfExists: oneof<nothing, bool> # Ignore the request if a network with the same name already exists. (default: false)
  --created: string # Created contains the timestamp when this network was created. (format: date-time)
  --dns-enabled: oneof<nothing, bool> # DNSEnabled is whether name resolution is active for container on this Network. Only supported with the bridge driver.
  --driver: string # Driver for this Network, e.g. bridge, macvlan...
  --id: string # ID of the Network.
  --internal: oneof<nothing, bool> # Internal is whether the Network should not have external routes to public or other Networks.
  --ipam-options: record # IPAMOptions contains options used for the ip assignment.
  --ipv6-enabled: oneof<nothing, bool> # IPv6Enabled if set to true an ipv6 subnet should be created for this net.
  --labels: record # Labels is a set of key-value labels that have been applied to the Network.
  --name: string # Name of the Network.
  --network-dns-servers: list # List of custom DNS server for podman's DNS resolver at network level, all the containers attached to this network will consider resolvers configured at network level.
  --network-interface: string # NetworkInterface is the network interface name on the host.
  --options: record # Options is a set of key-value options that have been applied to the Network.
  --routes: list # Routes to use for this network. — item shape: {destination?: string, gateway?: string, metric?: int, route_type?: string}
  --subnets: list # Subnets to use for this network. — item shape: {gateway?: string, lease_range?: record, subnet?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignoreIfExists" $ignoreIfExists "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/networks/create" $qp)
  let body = {created: $created, dns_enabled: $dns_enabled, driver: $driver, id: $id, internal: $internal, ipam_options: $ipam_options, ipv6_enabled: $ipv6_enabled, labels: $labels, name: $name, network_dns_servers: $network_dns_servers, network_interface: $network_interface, options: $options, routes: $routes, subnets: $subnets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List networks
#
# GET /libpod/networks/json
# operationId: NetworkListLibpod
export def "libpod-networks-json NetworkListLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: string # JSON encoded value of the filters (a `map[string][]string`) to process on the network list. Available filters:   - `name=[name]` Matches network name (accepts regex).   - `id=[id]` Matches for full or partial ID.   - `driver=[driver]` Only bridge is supported.   - `label=[key]` or `label=[key=value]` Matches networks based on the presence of a label alone or a label and a value.   - `until=[timestamp]` Matches all networks that were created before the given timestamp.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/networks/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete unused networks
#
# POST /libpod/networks/prune
# operationId: NetworkPruneLibpod
export def "libpod-networks-prune NetworkPruneLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: string # Filters to process on the prune list, encoded as JSON (a `map[string][]string`). Available filters:   - `until=<timestamp>` Prune networks created before this timestamp. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time.   - `label` (`label=<key>`, `label=<key>=<value>`, `label!=<key>`, or `label!=<key>=<value>`) Prune networks with (or without, in case `label!=...` is used) the specified labels.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/networks/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove resources created from kube play
#
# DELETE /libpod/play/kube
# operationId: PlayKubeDownLibpod
export def "libpod-play-kube PlayKubeDownLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # Remove volumes. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/play/kube" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Play a Kubernetes YAML file.
#
# POST /libpod/play/kube
# operationId: PlayKubeLibpod
export def "libpod-play-kube PlayKubeLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --annotations: string # JSON encoded value of annotations (a map[string]string).
  --logDriver: string # Logging driver for the containers in the pod.
  --logOptions: list # logging driver options
  --network: list # USe the network mode or specify an array of networks.
  --noHosts: oneof<nothing, bool> # do not setup /etc/hosts file in container (default: false)
  --noTrunc: oneof<nothing, bool> # use annotations that are not truncated to the Kubernetes maximum length of 63 characters (default: false)
  --publishPorts: list # publish a container's port, or a range of ports, to the host
  --publishAllPorts: oneof<nothing, bool> # Whether to publish all ports defined in the K8S YAML file (containerPort, hostPort), if false only hostPort will be published
  --replace: oneof<nothing, bool> # replace existing pods and containers (default: false)
  --serviceContainer: oneof<nothing, bool> # Starts a service container before all pods. (default: false)
  --start: oneof<nothing, bool> # Start the pod after creating it. (default: true)
  --staticIPs: list # Static IPs used for the pods.
  --staticMACs: list # Static MACs used for the pods.
  --tlsVerify: oneof<nothing, bool> # Require HTTPS and verify signatures when contacting registries. (default: true)
  --userns: string # Set the user namespace mode for the pods.
  --wait: oneof<nothing, bool> # Clean up all objects created when a SIGTERM is received or pods exit. (default: false)
  --build: oneof<nothing, bool> # Build the images with corresponding context.
  --Content-Type: string@Content-Type-completer-2
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "annotations" $annotations "scalar") (serialize-qp "logDriver" $logDriver "scalar") (serialize-qp "logOptions" $logOptions "csv") (serialize-qp "network" $network "csv") (serialize-qp "noHosts" $noHosts "scalar") (serialize-qp "noTrunc" $noTrunc "scalar") (serialize-qp "publishPorts" $publishPorts "csv") (serialize-qp "publishAllPorts" $publishAllPorts "scalar") (serialize-qp "replace" $replace "scalar") (serialize-qp "serviceContainer" $serviceContainer "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "staticIPs" $staticIPs "csv") (serialize-qp "staticMACs" $staticMACs "csv") (serialize-qp "tlsVerify" $tlsVerify "scalar") (serialize-qp "userns" $userns "scalar") (serialize-qp "wait" $wait "scalar") (serialize-qp "build" $build "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/play/kube" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove pod
#
# DELETE /libpod/pods/{name}
# operationId: PodDeleteLibpod
export def "libpod-pods PodDeleteLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # force removal of a running pod by first stopping all containers, then removing all containers in the pod
  --timeout: int # number of seconds to wait before killing containers in pod
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/pods/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pod exists
#
# GET /libpod/pods/{name}/exists
# operationId: PodExistsLibpod
export def "libpod-pods-exists PodExistsLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/pods/($name)/exists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect pod
#
# GET /libpod/pods/{name}/json
# operationId: PodInspectLibpod
export def "libpod-pods-json PodInspectLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/pods/($name)/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Kill a pod
#
# POST /libpod/pods/{name}/kill
# operationId: PodKillLibpod
export def "libpod-pods-kill PodKillLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --signal: string # signal to be sent to pod (default: SIGKILL)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signal" $signal "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/pods/($name)/kill" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause a pod
#
# POST /libpod/pods/{name}/pause
# operationId: PodPauseLibpod
export def "libpod-pods-pause PodPauseLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/pods/($name)/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restart a pod
#
# POST /libpod/pods/{name}/restart
# operationId: PodRestartLibpod
export def "libpod-pods-restart PodRestartLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/pods/($name)/restart")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start a pod
#
# POST /libpod/pods/{name}/start
# operationId: PodStartLibpod
export def "libpod-pods-start PodStartLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/pods/($name)/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stop a pod
#
# POST /libpod/pods/{name}/stop
# operationId: PodStopLibpod
export def "libpod-pods-stop PodStopLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --t: int # timeout
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t" $t "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/pods/($name)/stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List processes
#
# GET /libpod/pods/{name}/top
# operationId: PodTopLibpod
export def "libpod-pods-top PodTopLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --stream: oneof<nothing, bool> # when true, repeatedly stream the latest output (As of version 4.0)
  --delay: int # if streaming, delay in seconds between updates. Must be >1. (As of version 4.0) (default: 5)
  --ps-args: string # arguments to pass to ps such as aux.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stream" $stream "scalar") (serialize-qp "delay" $delay "scalar") (serialize-qp "ps_args" $ps_args "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/pods/($name)/top" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpause a pod
#
# POST /libpod/pods/{name}/unpause
# operationId: PodUnpauseLibpod
export def "libpod-pods-unpause PodUnpauseLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/pods/($name)/unpause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a pod
#
# POST /libpod/pods/create
# operationId: PodCreateLibpod
# --idmappings shape: {AutoUserNs?: bool, AutoUserNsOpts?: record, GIDMap?: list, HostGIDMapping?: bool, HostUIDMapping?: bool, UIDMap?: list}
# --image_volumes item shape: {Destination?: string, ReadWrite?: bool, Source?: string, subPath?: string}
# --ipcns shape: {nsmode?: string, value?: string}
# --mounts item shape: {BindOptions?: record, ClusterOptions?: record, Consistency?: string, ImageOptions?: record, ReadOnly?: bool, Source?: string, Target?: string, TmpfsOptions?: record, Type?: string, VolumeOptions?: record}
# --netns shape: {nsmode?: string, value?: string}
# --overlay_volumes item shape: {destination?: string, options?: list, source?: string}
# --pidns shape: {nsmode?: string, value?: string}
# --portmappings item shape: {container_port?: int, host_ip?: string, host_port?: int, protocol?: string, range?: int}
# --resource_limits shape: {blockIO?: record, cpu?: record, devices?: list, hugepageLimits?: list, memory?: record, network?: record, pids?: record, rdma?: record, unified?: record}
# --userns shape: {nsmode?: string, value?: string}
# --utsns shape: {nsmode?: string, value?: string}
# --volumes item shape: {Dest?: string, IsAnonymous?: bool, Name?: string, Options?: list, SubPath?: string}
export def "libpod-pods-create PodCreateLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Networks: record # Map of networks names to ids the container should join to. You can request additional settings for each network, you can set network aliases, static ips, static mac address  and the network interface name for this container on the specific network. If the map is empty and the bridge network mode is set the container will be joined to the default network.
  --cgroup-parent: string # CgroupParent is the parent for the Cgroup that the pod will create. This pod cgroup will, in turn, be the default cgroup parent for all containers in the pod. Optional.
  --dns-option: list # DNSOption is a set of DNS options that will be used in the infra container's resolv.conf, which will, by default, be shared with all containers in the pod. Conflicts with NoInfra=true. Optional.
  --dns-search: list # DNSSearch is a set of DNS search domains that will be used in the infra container's resolv.conf, which will, by default, be shared with all containers in the pod. If not provided, DNS search domains from the host's resolv.conf will be used. Conflicts with NoInfra=true. Optional.
  --dns-server: list # DNSServer is a set of DNS servers that will be used in the infra container's resolv.conf, which will, by default, be shared with all containers in the pod. If not provided, the host's DNS servers will be used, unless the only server set is a localhost address. As the container cannot connect to the host's localhost, a default server will instead be set. Conflicts with NoInfra=true. Optional.
  --exit-policy: string # ExitPolicy determines the pod's exit and stop behaviour.
  --hostadd: list # HostAdd is a set of hosts that will be added to the infra container's etc/hosts that will, by default, be shared with all containers in the pod. Conflicts with NoInfra=true and NoManageHosts. Optional.
  --hostname: string # Hostname is the pod's hostname. If not set, the name of the pod will be used (if a name was not provided here, the name auto-generated for the pod will be used). This will be used by the infra container and all containers in the pod as long as the UTS namespace is shared. Optional.
  --hostsFile: string # HostsFile is the base file to create the `/etc/hosts` file inside the infra container. This must either be an absolute path to a file on the host system, or one of the special flags `image` or `none`. If it is empty it defaults to the base_hosts_file configuration in containers.conf. Conflicts with NoInfra=true and NoManageHosts. Optional.
  --idmappings: record # IDMappingOptions are used for specifying how ID mapping should be set up for a layer or container. — shape: {AutoUserNs?: bool, AutoUserNsOpts?: record, GIDMap?: list, HostGIDMapping?: bool, HostUIDMapping?: bool, UIDMap?: list}
  --image-volumes: list # Image volumes bind-mount a container-image mount into the pod's infra container. Optional. — item shape: {Destination?: string, ReadWrite?: bool, Source?: string, subPath?: string}
  --infra-command: list # InfraCommand sets the command that will be used to start the infra container. If not set, the default set in the Libpod configuration file will be used. Conflicts with NoInfra=true. Optional.
  --infra-conmon-pid-file: string # InfraConmonPidFile is a custom path to store the infra container's conmon PID.
  --infra-image: string # InfraImage is the image that will be used for the infra container. If not set, the default set in the Libpod configuration file will be used. Conflicts with NoInfra=true. Optional.
  --infra-name: string # InfraName is the name that will be used for the infra container. If not set, the default set in the Libpod configuration file will be used. Conflicts with NoInfra=true. Optional.
  --ipcns: record # Namespace describes the namespace — shape: {nsmode?: string, value?: string}
  --labels: record # Labels are key-value pairs that are used to add metadata to pods. Optional.
  --mounts: list # Mounts are mounts that will be added to the pod. These will supersede Image Volumes and VolumesFrom volumes where there are conflicts. Optional. — item shape: {BindOptions?: record, ClusterOptions?: record, Consistency?: string, ImageOptions?: record, ReadOnly?: bool, Source?: string, Target?: string, TmpfsOptions?: record, Type?: string, VolumeOptions?: record}
  --name: string # Name is the name of the pod. If not provided, a name will be generated when the pod is created. Optional.
  --netns: record # Namespace describes the namespace — shape: {nsmode?: string, value?: string}
  --network-options: record # NetworkOptions are additional options for each network Optional.
  --no-infra: oneof<nothing, bool> # NoInfra tells the pod not to create an infra container. If this is done, many networking-related options will become unavailable. Conflicts with setting any options in PodNetworkConfig, and the InfraCommand and InfraImages in this struct. Optional.
  --no-manage-hostname: oneof<nothing, bool> # NoManageHostname indicates that /etc/hostname should not be managed by the pod. Instead, each container will create a separate etc/hostname as they would if not in a pod.
  --no-manage-hosts: oneof<nothing, bool> # NoManageHosts indicates that /etc/hosts should not be managed by the pod. Instead, each container will create a separate /etc/hosts as they would if not in a pod. Conflicts with HostAdd.
  --no-manage-resolv-conf: oneof<nothing, bool> # NoManageResolvConf indicates that /etc/resolv.conf should not be managed by the pod. Instead, each container will create and manage a separate resolv.conf as if they had not joined a pod. Conflicts with NoInfra=true and DNSServer, DNSSearch, DNSOption. Optional.
  --overlay-volumes: list # Overlay volumes are named volumes that will be added to the pod. Optional. — item shape: {destination?: string, options?: list, source?: string}
  --pidns: record # Namespace describes the namespace — shape: {nsmode?: string, value?: string}
  --pod-create-command: list
  --pod-devices: list # Devices contains user specified Devices to be added to the Pod
  --portmappings: list # PortMappings is a set of ports to map into the infra container. As, by default, containers share their network with the infra container, this will forward the ports to the entire pod. Only available if NetNS is set to Bridge or Pasta. Optional. — item shape: {container_port?: int, host_ip?: string, host_port?: int, protocol?: string, range?: int}
  --resource-limits: record # LinuxResources has container runtime resource constraints — shape: {blockIO?: record, cpu?: record, devices?: list, hugepageLimits?: list, memory?: record, network?: record, pids?: record, rdma?: record, unified?: record}
  --restart-policy: string # RestartPolicy is the pod's restart policy - an action which will be taken when one or all the containers in the pod exits. If not given, the default policy will be set to Always, which restarts the containers in the pod when they exit indefinitely. Optional.
  --restart-tries: int # RestartRetries is the number of attempts that will be made to restart the container. Only available when RestartPolicy is set to "on-failure". Optional. (format: uint64)
  --security-opt: list
  --serviceContainerID: string # The ID of the pod's service container.
  --share-parent: oneof<nothing, bool> # PodCreateCommand is the command used to create this pod. This will be shown in the output of Inspect() on the pod, and may also be used by some tools that wish to recreate the pod (e.g. `podman generate systemd --new`). Optional. ShareParent determines if all containers in the pod will share the pod's cgroup as the cgroup parent
  --shared-namespaces: list # SharedNamespaces instructs the pod to share a set of namespaces. Shared namespaces will be joined (by default) by every container which joins the pod. If not set and NoInfra is false, the pod will set a default set of namespaces to share. Conflicts with NoInfra=true. Optional.
  --shm-size: int # ShmSize is the size of the tmpfs to mount in at /dev/shm, in bytes. Conflicts with ShmSize if IpcNS is not private. Optional. (format: int64)
  --shm-size-systemd: int # ShmSizeSystemd is the size of systemd-specific tmpfs mounts specifically /run, /run/lock, /var/log/journal and /tmp. Optional (format: int64)
  --sysctl: record # Sysctl sets kernel parameters for the pod
  --userns: record # Namespace describes the namespace — shape: {nsmode?: string, value?: string}
  --utsns: record # Namespace describes the namespace — shape: {nsmode?: string, value?: string}
  --volumes: list # Volumes are named volumes that will be added to the pod. These will supersede Image Volumes and VolumesFrom  volumes where there are conflicts. Optional. — item shape: {Dest?: string, IsAnonymous?: bool, Name?: string, Options?: list, SubPath?: string}
  --volumes-from: list # VolumesFrom is a set of containers whose volumes will be added to this pod. The name or ID of the container must be provided, and may optionally be followed by a : and then one or more comma-separated options. Valid options are 'ro', 'rw', and 'z'. Options will be used for all volumes sourced from the container.
]: any -> record<Id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/libpod/pods/create")
  let body = {Networks: $Networks, cgroup_parent: $cgroup_parent, dns_option: $dns_option, dns_search: $dns_search, dns_server: $dns_server, exit_policy: $exit_policy, hostadd: $hostadd, hostname: $hostname, hostsFile: $hostsFile, idmappings: $idmappings, image_volumes: $image_volumes, infra_command: $infra_command, infra_conmon_pid_file: $infra_conmon_pid_file, infra_image: $infra_image, infra_name: $infra_name, ipcns: $ipcns, labels: $labels, mounts: $mounts, name: $name, netns: $netns, network_options: $network_options, no_infra: $no_infra, no_manage_hostname: $no_manage_hostname, no_manage_hosts: $no_manage_hosts, no_manage_resolv_conf: $no_manage_resolv_conf, overlay_volumes: $overlay_volumes, pidns: $pidns, pod_create_command: $pod_create_command, pod_devices: $pod_devices, portmappings: $portmappings, resource_limits: $resource_limits, restart_policy: $restart_policy, restart_tries: $restart_tries, security_opt: $security_opt, serviceContainerID: $serviceContainerID, share_parent: $share_parent, shared_namespaces: $shared_namespaces, shm_size: $shm_size, shm_size_systemd: $shm_size_systemd, sysctl: $sysctl, userns: $userns, utsns: $utsns, volumes: $volumes, volumes_from: $volumes_from} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List pods
#
# GET /libpod/pods/json
# operationId: PodListLibpod
export def "libpod-pods-json PodListLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: string # JSON encoded value of the filters (a map[string][]string) to process on the pods list. Available filters:   - `id=<pod-id>` Matches all of pod id.   - `label=<key>` or `label=<key>:<value>` Matches pods based on the presence of a label alone or a label and a value.   - `name=<pod-name>` Matches all of pod name.   - `until=<timestamp>` List pods created before this timestamp. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time.   - `status=<pod-status>` Pod's status: `stopped`, `running`, `paused`, `exited`, `dead`, `created`, `degraded`.   - `network=<pod-network>` Name or full ID of network.   - `ctr-names=<pod-ctr-names>` Container name within the pod.   - `ctr-ids=<pod-ctr-ids>` Container ID within the pod.   - `ctr-status=<pod-ctr-status>` Container status within the pod.   - `ctr-number=<pod-ctr-number>` Number of containers in the pod.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/pods/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Prune unused pods
#
# POST /libpod/pods/prune
# operationId: PodPruneLibpod
export def "libpod-pods-prune PodPruneLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/libpod/pods/prune")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Statistics for one or more pods
#
# GET /libpod/pods/stats
# operationId: PodStatsAllLibpod
export def "libpod-pods-stats PodStatsAllLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --all: oneof<nothing, bool> # Provide statistics for all running pods.
  --namesOrIDs: list # Names or IDs of pods.
  --stream: oneof<nothing, bool> # Stream the output (default: false)
  --delay: int # Time in seconds between stats reports (default: 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "namesOrIDs" $namesOrIDs "csv") (serialize-qp "stream" $stream "scalar") (serialize-qp "delay" $delay "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/pods/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove quadlet files (batch operation)
#
# DELETE /libpod/quadlets
# operationId: QuadletDeleteAllLibpod
export def "libpod-quadlets QuadletDeleteAllLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --quadlets: list # Names of quadlets to remove (e.g., "myapp.container"). Required unless all=true
  --all: oneof<nothing, bool> # Remove all quadlets for the current user (default: false)
  --force: oneof<nothing, bool> # Remove running quadlets by stopping them first (default: false)
  --ignore: oneof<nothing, bool> # Do not error for quadlets that do not exist (default: false)
  --reload-systemd: oneof<nothing, bool> # Reload systemd after removing quadlets (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quadlets" $quadlets "csv") (serialize-qp "all" $all "scalar") (serialize-qp "force" $force "scalar") (serialize-qp "ignore" $ignore "scalar") (serialize-qp "reload-systemd" $reload_systemd "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/quadlets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Install quadlet files
#
# POST /libpod/quadlets
# operationId: QuadletInstallLibpod
export def "libpod-quadlets QuadletInstallLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --replace: oneof<nothing, bool> # Replace the installation files even if the files already exists (default: false)
  --reload-systemd: oneof<nothing, bool> # Reload systemd after installing quadlets (default: true)
  --body: record
]: any -> record<InstalledQuadlets: record, QuadletErrors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "replace" $replace "scalar") (serialize-qp "reload-systemd" $reload_systemd "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/quadlets" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a quadlet file
#
# DELETE /libpod/quadlets/{name}
# operationId: QuadletDeleteLibpod
export def "libpod-quadlets QuadletDeleteLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # Remove running quadlet by stopping it first (default: false)
  --ignore: oneof<nothing, bool> # Do not error if the quadlet does not exist (default: false)
  --reload-systemd: oneof<nothing, bool> # Reload systemd after removing the quadlet (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "ignore" $ignore "scalar") (serialize-qp "reload-systemd" $reload_systemd "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/quadlets/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if quadlet exists
#
# GET /libpod/quadlets/{name}/exists
# operationId: QuadletExistsLibpod
export def "libpod-quadlets-exists QuadletExistsLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/quadlets/($name)/exists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get quadlet file
#
# GET /libpod/quadlets/{name}/file
# operationId: QuadletFileLibpod
export def "libpod-quadlets-file QuadletFileLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/quadlets/($name)/file")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List quadlets
#
# GET /libpod/quadlets/json
# operationId: QuadletListLibpod
export def "libpod-quadlets-json QuadletListLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: string # JSON encoded value of the filters (a map[string][]string). Supported filters:   - name=<quadlet-name> Filter by quadlet name   - pod=<pod-quadlet> Filter by Pod= value (container quadlets only)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/quadlets/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove secret
#
# DELETE /libpod/secrets/{name}
# operationId: SecretDeleteLibpod
export def "libpod-secrets SecretDeleteLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --all: oneof<nothing, bool> # Remove all secrets (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/secrets/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Secret exists
#
# GET /libpod/secrets/{name}/exists
# operationId: SecretExistsLibpod
export def "libpod-secrets-exists SecretExistsLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/secrets/($name)/exists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect secret
#
# GET /libpod/secrets/{name}/json
# operationId: SecretInspectLibpod
export def "libpod-secrets-json SecretInspectLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --showsecret: oneof<nothing, bool> # Display Secret (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showsecret" $showsecret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/secrets/($name)/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a secret
#
# POST /libpod/secrets/create
# operationId: SecretCreateLibpod
export def "libpod-secrets-create SecretCreateLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # User-defined name of the secret.
  --driver: string # Secret driver (default: file)
  --driveropts: string # JSON-encoded string containing secret driver options as a `map[string]string`.
  --labels: string # JSON-encoded string containing labels as a `map[string]string`.
  --replace: oneof<nothing, bool> # Replace an existing secret with the same name. (default: false)
  --ignore: oneof<nothing, bool> # Ignore the request if a secret with the same name already exists. (default: false)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "driver" $driver "scalar") (serialize-qp "driveropts" $driveropts "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "replace" $replace "scalar") (serialize-qp "ignore" $ignore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/secrets/create" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List secrets
#
# GET /libpod/secrets/json
# operationId: SecretListLibpod
export def "libpod-secrets-json SecretListLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: string # JSON encoded value of the filters (a `map[string][]string`) to process on the secrets list. Currently available filters:   - `name=[name]` Matches secrets name (accepts regex).   - `id=[id]` Matches for full or partial ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/secrets/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Performs consistency checks on storage, optionally removing items which fail checks
#
# POST /libpod/system/check
# operationId: SystemCheckLibpod
export def "libpod-system-check SystemCheckLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --quick: oneof<nothing, bool> # Skip time-consuming checks
  --repair: oneof<nothing, bool> # Remove inconsistent images
  --repair-lossy: oneof<nothing, bool> # Remove inconsistent containers and images
  --unreferenced-layer-max-age: string # Maximum allowed age of unreferenced layers (default: 24h0m0s)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quick" $quick "scalar") (serialize-qp "repair" $repair "scalar") (serialize-qp "repair_lossy" $repair_lossy "scalar") (serialize-qp "unreferenced_layer_max_age" $unreferenced_layer_max_age "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/system/check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show disk usage
#
# GET /libpod/system/df
# operationId: SystemDataUsageLibpod
export def "libpod-system-df SystemDataUsageLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/libpod/system/df")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Prune unused data
#
# POST /libpod/system/prune
# operationId: SystemPruneLibpod
export def "libpod-system-prune SystemPruneLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --all: oneof<nothing, bool> # Remove all unused data, not just dangling data
  --volumes: oneof<nothing, bool> # Prune volumes
  --external: oneof<nothing, bool> # Remove images used by external containers (e.g., build containers)
  --build: oneof<nothing, bool> # Remove build cache
  --filters: string # JSON encoded value of filters (a map[string][]string) to match data against before pruning. Available filters:   - `until=<timestamp>` Prune data created before this timestamp. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine's time.   - `label` (`label=<key>`, `label=<key>=<value>`, `label!=<key>`, or `label!=<key>=<value>`) Prune data with (or without, in case `label!=...` is used) the specified labels.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "volumes" $volumes "scalar") (serialize-qp "external" $external "scalar") (serialize-qp "build" $build "scalar") (serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/system/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Component Version information
#
# GET /libpod/version
# operationId: SystemVersionLibpod
export def "libpod-version SystemVersionLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/libpod/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove volume
#
# DELETE /libpod/volumes/{name}
# operationId: VolumeDeleteLibpod
export def "libpod-volumes VolumeDeleteLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # force removal
  --timeout: int # timeout before forcibly killing any containers using the volume
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/libpod/volumes/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Volume exists
#
# GET /libpod/volumes/{name}/exists
# operationId: VolumeExistsLibpod
export def "libpod-volumes-exists VolumeExistsLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/volumes/($name)/exists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export a volume
#
# GET /libpod/volumes/{name}/export
# operationId: VolumeExportLibpod
export def "libpod-volumes-export VolumeExportLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/volumes/($name)/export")
  let accept_val = "application/x-tar"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Populate a volume by importing provided tar
#
# POST /libpod/volumes/{name}/import
# operationId: VolumeImportLibpod
export def "libpod-volumes-import VolumeImportLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/volumes/($name)/import")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Inspect volume
#
# GET /libpod/volumes/{name}/json
# operationId: VolumeInspectLibpod
export def "libpod-volumes-json VolumeInspectLibpod" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/libpod/volumes/($name)/json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a volume
#
# POST /libpod/volumes/create
# operationId: VolumeCreateLibpod
export def "libpod-volumes-create VolumeCreateLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Driver: string # Volume driver to use
  --GID: int # GID that the volume will be created as (format: int64)
  --IgnoreIfExists: oneof<nothing, bool> # Ignore existing volumes
  --Label: record # User-defined key/value metadata. Provided for compatibility
  --Labels: record # User-defined key/value metadata. Preferred field, will override Label
  --Name: string # New volume's name. Can be left blank
  --Options: record # Mapping of driver options and values.
  --UID: int # UID that the volume will be created as (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/libpod/volumes/create")
  let body = {Driver: $Driver, GID: $GID, IgnoreIfExists: $IgnoreIfExists, Label: $Label, Labels: $Labels, Name: $Name, Options: $Options, UID: $UID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List volumes
#
# GET /libpod/volumes/json
# operationId: VolumeListLibpod
export def "libpod-volumes-json VolumeListLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: string # JSON encoded value of the filters (a map[string][]string) to process on the volumes list. Available filters:   - driver=<volume-driver-name> Matches volumes based on their driver.   - label=<key> or label=<key>:<value> Matches volumes based on the presence of a label alone or a label and a value.   - name=<volume-name> Matches all of volume name.   - opt=<driver-option> Matches a storage driver options   - `until=<timestamp>` List volumes created before this timestamp. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/volumes/json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Prune volumes
#
# POST /libpod/volumes/prune
# operationId: VolumePruneLibpod
export def "libpod-volumes-prune VolumePruneLibpod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: string # JSON encoded value of filters (a map[string][]string) to match volumes against before pruning. Available filters:   - `all` When true, prune all unused volumes; when false or unset, only anonymous unused volumes.   - `anonymous` When true/false, restrict to anonymous or named volumes only.   - `until=<timestamp>` Prune volumes created before this timestamp. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time.   - `label` (`label=<key>`, `label=<key>=<value>`, `label!=<key>`, or `label!=<key>=<value>`) Prune volumes with (or without, in case `label!=...` is used) the specified labels.
  --dryrun: oneof<nothing, bool> # Show which volumes would be pruned without removing them. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "dryrun" $dryrun "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libpod/volumes/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --filters: string # JSON encoded value of the filters (a `map[string][]string`) to process on the network list. Currently available filters:   - `name=[name]` Matches network name (accepts regex).   - `id=[id]` Matches for full or partial ID.   - `driver=[driver]` Only bridge is supported.   - `label=[key]` or `label=[key=value]` Matches networks based on the presence of a label alone or a label and a value.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/networks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a network
#
# DELETE /networks/{name}
# operationId: NetworkDelete
export def "networks NetworkDelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force: oneof<nothing, bool> # Remove containers associated with the network. (default: false)
  --timeout: int # Seconds to wait for container removal when force is set.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect a network
#
# GET /networks/{name}
# operationId: NetworkInspect
export def "networks NetworkInspect" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --verbose: oneof<nothing, bool> # Detailed inspect output for troubleshooting
  --scope: string # Filter the network by scope (swarm, global, or local)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "verbose" $verbose "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/networks/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Connect container to network
#
# POST /networks/{name}/connect
# operationId: NetworkConnect
# --EndpointConfig shape: {Aliases?: list, DNSNames?: list, DriverOpts?: record, EndpointID?: string, Gateway?: string, GlobalIPv6Address?: string, GlobalIPv6PrefixLen?: int, GwPriority?: int, IPAMConfig?: record, IPAddress?: string, IPPrefixLen?: int, IPv6Gateway?: string, Links?: list, MacAddress?: string, NetworkID?: string}
export def "networks-connect NetworkConnect" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Container: string # The ID or name of the container to connect to the network. (e.g. 3613f73ba0e4)
  --EndpointConfig: record # EndpointSettings stores the network endpoint details — shape: {Aliases?: list, DNSNames?: list, DriverOpts?: record, EndpointID?: string, Gateway?: string, GlobalIPv6Address?: string, GlobalIPv6PrefixLen?: int, GwPriority?: int, IPAMConfig?: record, IPAddress?: string, IPPrefixLen?: int, IPv6Gateway?: string, Links?: list, MacAddress?: string, NetworkID?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($name)/connect")
  let body = {Container: $Container, EndpointConfig: $EndpointConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disconnect container from network
#
# POST /networks/{name}/disconnect
# operationId: NetworkDisconnect
export def "networks-disconnect NetworkDisconnect" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Container: string # The ID or name of the container to disconnect from the network. (e.g. 3613f73ba0e4)
  --Force: oneof<nothing, bool> # Force the container to disconnect from the network. (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networks/($name)/disconnect")
  let body = {Container: $Container, Force: $Force} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create network
#
# POST /networks/create
# operationId: NetworkCreate
# --ConfigFrom shape: {Network?: string}
# --IPAM shape: {Config?: list, Driver?: string, Options?: record}
export def "networks-create NetworkCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Attachable: oneof<nothing, bool>
  --ConfigFrom: record # ConfigReference The config-only network source to provide the configuration for this network. — shape: {Network?: string}
  --ConfigOnly: oneof<nothing, bool>
  --Driver: string
  --EnableIPv4: oneof<nothing, bool>
  --EnableIPv6: oneof<nothing, bool>
  --IPAM: record # IPAM represents IP Address Management — shape: {Config?: list, Driver?: string, Options?: record}
  --Ingress: oneof<nothing, bool>
  --Internal: oneof<nothing, bool>
  --Labels: record
  --Name: string
  --Options: record
  --Scope: string
]: any -> record<Id: string, Warning: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/networks/create")
  let body = {Attachable: $Attachable, ConfigFrom: $ConfigFrom, ConfigOnly: $ConfigOnly, Driver: $Driver, EnableIPv4: $EnableIPv4, EnableIPv6: $EnableIPv6, IPAM: $IPAM, Ingress: $Ingress, Internal: $Internal, Labels: $Labels, Name: $Name, Options: $Options, Scope: $Scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --filters: string # Filters to process on the prune list, encoded as JSON (a map[string][]string). Available filters:   - `until=<timestamp>` Prune networks created before this timestamp. The <timestamp> can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time.   - `label` (`label=<key>`, `label=<key>=<value>`, `label!=<key>`, or `label!=<key>=<value>`) Prune networks with (or without, in case `label!=...` is used) the specified labels.
]: nothing -> record<NetworksDeleted: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/networks/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --filters: string # JSON encoded value of the filters (a `map[string][]string`) to process on the secrets list. Currently available filters:   - `name=[name]` Matches secrets name (accepts regex).   - `id=[id]` Matches for full or partial ID.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove secret
#
# DELETE /secrets/{name}
# operationId: SecretDelete
export def "secrets SecretDelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/secrets/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect secret
#
# GET /secrets/{name}
# operationId: SecretInspect
export def "secrets SecretInspect" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/secrets/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a secret
#
# POST /secrets/create
# operationId: SecretCreate
export def "secrets-create SecretCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Data: string # Base64-url-safe-encoded (RFC 4648) data to store as secret.
  --Driver: record
  --Labels: record # Labels are labels on the secret
  --Name: string # User-defined name of the secret.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/secrets/create")
  let body = {Data: $Data, Driver: $Driver, Labels: $Labels, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show disk usage
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/df")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Component Version information
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --filters: string # JSON encoded value of the filters (a map[string][]string) to process on the volumes list. Available filters:   - driver=<volume-driver-name> Matches volumes based on their driver.   - label=<key> or label=<key>:<value> Matches volumes based on the presence of a label alone or a label and a value.   - name=<volume-name> Matches all of volume name.   - `until=<timestamp>` List volumes created before this timestamp. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time.  Note:   The boolean `dangling` filter is not yet implemented for this endpoint.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/volumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove volume
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
  --force: oneof<nothing, bool> # Force removal of the volume. This actually only causes errors due to the names volume not being found to be suppressed, which is the behaviour Docker implements.
  --timeout: int # timeout before forcibly killing any containers using the volume
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/volumes/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect volume
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/volumes/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  Driver: string # Name of the volume driver to use.
  DriverOpts: record # A mapping of driver options and values. These options are passed directly to the driver and are driver specific.
  Labels: record # User-defined key/value metadata.
  Name: string # The new volume's name. If not specified, Docker generates a name.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/volumes/create")
  let body = {Driver: $Driver, DriverOpts: $DriverOpts, Labels: $Labels, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Prune volumes
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
  --filters: string # JSON encoded value of filters (a map[string][]string). Docker API 1.42+ - by default only anonymous (unnamed) unused volumes are pruned; use filter all=true to prune all unused volumes. Available filters:   - `all` When true, prune all unused volumes (anonymous and named). When false or unset, only anonymous unused volumes are pruned.   - `until=<timestamp>` Prune volumes created before this timestamp. The `<timestamp>` can be Unix timestamps, date formatted timestamps, or Go duration strings (e.g. `10m`, `1h30m`) computed relative to the daemon machine’s time.   - `label` (`label=<key>`, `label=<key>=<value>`, `label!=<key>`, or `label!=<key>=<value>`) Prune volumes with (or without, in case `label!=...` is used) the specified labels.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/volumes/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
