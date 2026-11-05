# Auto-generated client for DigitalOcean API v2.0
# Source: https://api.apis.guru/v2/specs/digitalocean.com/2.0/openapi.json
# Auth: --token flag or $env.DIGITALOCEAN_API_TOKEN

const BASE_URL = "https://api.digitalocean.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o DIGITALOCEAN_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.digitalocean.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["droplet" "kubernetes"] }
def accept-completer [] { ["application/json" "application/yaml"] }
def content-type-completer [] { ["application/json" "application/yaml"] }
def type-completer-1 [] { ["BUILD" "DEPLOY" "RUN" "UNSPECIFIED"] }
def ttl-completer [] { ["3600" "60" "600" "604800" "86400"] }
def type-completer-2 [] { ["custom" "lets_encrypt"] }
def accept-completer-1 [] { ["application/json" "text/csv"] }
def accept-completer-2 [] { ["application/json" "application/pdf"] }
def engine-completer [] { ["mongodb" "mysql" "pg" "redis"] }
def eviction-policy-completer [] { ["allkeys_lru" "allkeys_random" "noeviction" "volatile_lru" "volatile_random" "volatile_ttl"] }
def type-completer-3 [] { ["A" "AAAA" "CAA" "CNAME" "MX" "NS" "SOA" "SRV" "TXT"] }
def type-completer-4 [] { ["disable_backups" "enable_backups" "enable_ipv6" "power_cycle" "power_off" "power_on" "shutdown" "snapshot"] }
def type-completer-5 [] { ["change_kernel" "disable_backups" "enable_backups" "enable_ipv6" "password_reset" "power_cycle" "power_off" "power_on" "reboot" "rebuild" "rename" "resize" "restore" "shutdown" "snapshot"] }
def type-completer-6 [] { ["assign" "unassign"] }
def type-completer-7 [] { ["application" "distribution"] }
def distribution-completer [] { ["Arch Linux" "CentOS" "CoreOS" "Debian" "Fedora" "Fedora Atomic" "FreeBSD" "Gentoo" "RancherOS" "Rocky Linux" "Ubuntu" "Unknown" "openSUSE"] }
def region-completer [] { ["ams1" "ams2" "ams3" "blr1" "fra1" "lon1" "nyc1" "nyc2" "nyc3" "sfo1" "sfo2" "sfo3" "sgp1" "tor1"] }
def type-completer-8 [] { ["convert" "transfer"] }
def algorithm-completer [] { ["least_connections" "round_robin"] }
def size-completer [] { ["lb-large" "lb-medium" "lb-small"] }
def compare-completer [] { ["GreaterThan" "LessThan"] }
def type-completer-9 [] { ["v1/dbaas/alerts/cpu_alerts" "v1/dbaas/alerts/disk_utilization_alerts" "v1/dbaas/alerts/load_15_alerts" "v1/dbaas/alerts/memory_utilization_alerts" "v1/insights/droplet/cpu" "v1/insights/droplet/disk_read" "v1/insights/droplet/disk_utilization_percent" "v1/insights/droplet/disk_write" "v1/insights/droplet/load_1" "v1/insights/droplet/load_15" "v1/insights/droplet/load_5" "v1/insights/droplet/memory_utilization_percent" "v1/insights/droplet/private_inbound_bandwidth" "v1/insights/droplet/private_outbound_bandwidth" "v1/insights/droplet/public_inbound_bandwidth" "v1/insights/droplet/public_outbound_bandwidth" "v1/insights/lbaas/avg_cpu_utilization_percent" "v1/insights/lbaas/connection_utilization_percent" "v1/insights/lbaas/droplet_health" "v1/insights/lbaas/high_http_request_response_time" "v1/insights/lbaas/high_http_request_response_time_50p" "v1/insights/lbaas/high_http_request_response_time_95p" "v1/insights/lbaas/high_http_request_response_time_99p" "v1/insights/lbaas/increase_in_http_error_rate_count_4xx" "v1/insights/lbaas/increase_in_http_error_rate_count_5xx" "v1/insights/lbaas/increase_in_http_error_rate_percentage_4xx" "v1/insights/lbaas/increase_in_http_error_rate_percentage_5xx" "v1/insights/lbaas/tls_connections_per_second_utilization_percent"] }
def window-completer [] { ["10m" "1h" "30m" "5m"] }
def interface-completer [] { ["private" "public"] }
def direction-completer [] { ["inbound" "outbound"] }
def environment-completer [] { ["Development" "Production" "Staging"] }
def region-completer-1 [] { ["ams3" "fra1" "nyc3" "sfo3" "sgp1"] }
def subscription-tier-slug-completer [] { ["basic" "professional" "starter"] }
def tier-slug-completer [] { ["basic" "professional" "starter"] }
def resource-type-completer [] { ["droplet" "volume"] }
def type-completer-10 [] { ["http" "https" "ping"] }
def comparison-completer [] { ["greater_than" "less_than"] }
def period-completer [] { ["10m" "15m" "1h" "2m" "30m" "3m" "5m"] }
def type-completer-11 [] { ["down" "down_global" "latency" "ssl_expiry"] }
def type-completer-12 [] { ["attach" "detach"] }
def type-completer-13 [] { ["attach" "detach" "resize"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["one-clicks-list" "one-clicks-install-kubernetes" "account-get" "ssh-keys-list" "ssh-keys-create" "ssh-keys-delete" "ssh-keys-get" "ssh-keys-update" "actions-list" "actions-get" "apps-list" "apps-create" "apps-list-metrics-bandwidth-daily" "apps-validate-app-spec" "apps-list-regions" "apps-list-tiers" "apps-list-instance-sizes" "apps-get-instance-size" "apps-get-tier" "apps-list-alerts" "apps-assign-alert-destinations" "apps-get-logs-active-deployment" "apps-list-deployments" "apps-create-deployment" "apps-get-deployment" "apps-cancel-deployment" "apps-get-logs" "apps-get-logs-aggregate" "apps-get-logs-active-deployment-aggregate" "apps-get-metrics-bandwidth-daily" "apps-create-rollback" "apps-commit-rollback" "apps-revert-rollback" "apps-validate-rollback" "apps-delete" "apps-get" "apps-update" "cdn-list-endpoints" "cdn-create-endpoint" "cdn-delete-endpoint" "cdn-get-endpoint" "cdn-update-endpoints" "cdn-purge-cache" "certificates-list" "certificates-create" "certificates-delete" "certificates-get" "balance-get" "billing-history-list" "invoices-list" "invoices-get-by-uuid" "invoices-get-csv-by-uuid" "invoices-get-pdf-by-uuid" "invoices-get-summary-by-uuid" "databases-list-clusters" "databases-create-cluster" "databases-list-options" "databases-destroy-cluster" "databases-get-cluster" "databases-list-backups" "databases-get-ca" "databases-get-config" "databases-patch-config" "databases-list" "databases-add" "databases-delete" "databases-get" "databases-get-eviction-policy" "databases-update-eviction-policy" "databases-list-firewall-rules" "databases-update-firewall-rules" "databases-update-maintenance-window" "databases-update-region" "databases-get-migration-status" "databases-update-online-migration" "databases-delete-online-migration" "databases-list-connection-pools" "databases-add-connection-pool" "databases-delete-connection-pool" "databases-get-connection-pool" "databases-update-connection-pool" "databases-list-replicas" "databases-create-replica" "databases-destroy-replica" "databases-get-replica" "databases-promote-replica" "databases-update-cluster-size" "databases-get-sql-mode" "databases-update-sql-mode" "databases-update-major-version" "databases-list-users" "databases-add-user" "databases-delete-user" "databases-get-user" "databases-reset-auth" "domains-list" "domains-create" "domains-delete" "domains-get" "domains-list-records" "domains-create-record" "domains-delete-record" "domains-get-record" "domains-patch-record" "domains-update-record" "droplets-destroy-by-tag" "droplets-list" "droplets-create" "droplet-actions-post-by-tag" "droplets-destroy" "droplets-get" "droplet-actions-list" "droplet-actions-post" "droplet-actions-get" "droplets-list-backups" "droplets-list-associated-resources" "droplets-destroy-with-associated-resources-dangerous" "droplets-destroy-retry-with-associated-resources" "droplets-destroy-with-associated-resources-selective" "droplets-get-destroy-associated-resources-status" "droplets-list-firewalls" "droplets-list-kernels" "droplets-list-neighbors" "droplets-list-snapshots" "firewalls-list" "firewalls-create" "firewalls-delete" "firewalls-get" "firewalls-update" "firewalls-delete-droplets" "firewalls-assign-droplets" "firewalls-delete-rules" "firewalls-add-rules" "firewalls-delete-tags" "firewalls-add-tags" "floating-i-ps-list" "floating-i-ps-create" "floating-i-ps-delete" "floating-i-ps-get" "floating-i-ps-action-list" "floating-i-ps-action-post" "floating-i-ps-action-get" "functions-list-namespaces" "functions-create-namespace" "functions-delete-namespace" "functions-get-namespace" "functions-list-triggers" "functions-create-trigger" "functions-delete-trigger" "functions-get-trigger" "functions-update-trigger" "images-list" "images-create-custom" "images-delete" "images-get" "images-update" "image-actions-list" "image-actions-post" "image-actions-get" "kubernetes-list-clusters" "kubernetes-create-cluster" "kubernetes-delete-cluster" "kubernetes-get-cluster" "kubernetes-update-cluster" "kubernetes-get-cluster-lint-results" "kubernetes-run-cluster-lint" "kubernetes-get-credentials" "kubernetes-list-associated-resources" "kubernetes-destroy-associated-resources-dangerous" "kubernetes-destroy-associated-resources-selective" "kubernetes-get-kubeconfig" "kubernetes-list-node-pools" "kubernetes-add-node-pool" "kubernetes-delete-node-pool" "kubernetes-get-node-pool" "kubernetes-update-node-pool" "kubernetes-delete-node" "kubernetes-recycle-node-pool" "kubernetes-upgrade-cluster" "kubernetes-get-available-upgrades" "kubernetes-get-cluster-user" "kubernetes-list-options" "kubernetes-remove-registry" "kubernetes-add-registry" "load-balancers-list" "load-balancers-create" "load-balancers-delete" "load-balancers-get" "load-balancers-update" "load-balancers-remove-droplets" "load-balancers-add-droplets" "load-balancers-remove-forwarding-rules" "load-balancers-add-forwarding-rules" "monitoring-list-alert-policy" "monitoring-create-alert-policy" "monitoring-delete-alert-policy" "monitoring-get-alert-policy" "monitoring-update-alert-policy" "monitoring-get-droplet-bandwidth-metrics" "monitoring-get-droplet-cpu-metrics" "monitoring-get-droplet-filesystem-free-metrics" "monitoring-get-droplet-filesystem-size-metrics" "monitoring-get-droplet-load1-metrics" "monitoring-get-droplet-load15-metrics" "monitoring-get-droplet-load5-metrics" "monitoring-get-droplet-memory-available-metrics" "monitoring-get-droplet-memory-cached-metrics" "monitoring-get-droplet-memory-free-metrics" "monitoring-get-droplet-memory-total-metrics" "projects-list" "projects-create" "projects-get-default" "projects-patch-default" "projects-update-default" "projects-list-resources-default" "projects-assign-resources-default" "projects-delete" "projects-get" "projects-patch" "projects-update" "projects-list-resources" "projects-assign-resources" "regions-list" "registry-delete" "registry-get" "registry-create" "registry-get-docker-credentials" "registry-get-options" "registry-get-subscription" "registry-update-subscription" "registry-validate-name" "registry-get-garbage-collection" "registry-run-garbage-collection" "registry-update-garbage-collection" "registry-list-garbage-collections" "registry-list-repositories" "registry-list-repositories-v2" "registry-list-repository-manifests" "registry-delete-repository-manifest" "registry-list-repository-tags" "registry-delete-repository-tag" "droplets-list-neighbors-ids" "reserved-i-ps-list" "reserved-i-ps-create" "reserved-i-ps-delete" "reserved-i-ps-get" "reserved-i-ps-actions-list" "reserved-i-ps-actions-post" "reserved-i-ps-actions-get" "sizes-list" "snapshots-list" "snapshots-delete" "snapshots-get" "tags-list" "tags-create" "tags-delete" "tags-get" "tags-unassign-resources" "tags-assign-resources" "uptime-checks-list" "uptime-check-create" "uptime-check-delete" "uptime-check-get" "uptime-check-update" "uptime-check-alerts-list" "uptime-alert-create" "uptime-alert-delete" "uptime-alert-get" "uptime-alert-update" "uptime-check-state-get" "volumes-delete-by-name" "volumes-list" "volumes-create" "volume-actions-post" "volume-snapshots-delete-by-id" "volume-snapshots-get-by-id" "volumes-delete" "volumes-get" "volume-actions-list" "volume-actions-post-by-id" "volume-actions-get" "volume-snapshots-list" "volume-snapshots-create" "vpcs-list" "vpcs-create" "vpcs-delete" "vpcs-get" "vpcs-patch" "vpcs-update" "vpcs-list-members" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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

# List 1-Click Applications
#
# GET /v2/1-clicks
# operationId: oneClicks_list
export def "one-clicks-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Restrict results to a certain type of 1-Click. (e.g. kubernetes)
]: nothing -> oneof<record<1_clicks: table<slug: string, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/1-clicks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Install Kubernetes 1-Click Applications
#
# POST /v2/1-clicks/kubernetes
# operationId: oneClicks_install_kubernetes
export def "one-clicks-install-kubernetes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  addon_slugs: list<string> # An array of 1-Click Application slugs to be installed to the Kubernetes cluster. (default: [], e.g. [kube-state-metrics, loki])
  cluster_uuid: string # A unique ID for the Kubernetes cluster to which the 1-Click Applications will be installed. (e.g. 50a994b6-c303-438f-9495-7e896cfe6b08)
]: any -> oneof<record<message: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/1-clicks/kubernetes" $auth.query)
  let req_body = {"addon_slugs": $addon_slugs, "cluster_uuid": $cluster_uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get User Information
#
# GET /v2/account
# operationId: account_get
export def "account-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<account: record<droplet_limit: int, email: string, email_verified: bool, floating_ip_limit: int, status: string, status_message: string, team: record<name: string, uuid: string>, uuid: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/account" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All SSH Keys
#
# GET /v2/account/keys
# operationId: sshKeys_list
export def "ssh-keys-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<ssh_keys: table<fingerprint: string, id: int, name: string, public_key: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/account/keys" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New SSH Key
#
# POST /v2/account/keys
# operationId: sshKeys_create
export def "ssh-keys-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # A human-readable display name for this key, used to easily identify the SSH keys when they are displayed. (e.g. My SSH Public Key)
  public_key: string # The entire public key string that was uploaded. Embedded into the root user's `authorized_keys` file if you include this key during Droplet creation. (e.g. ssh-rsa AEXAMPLEaC1yc2EAAAADAQABAAAAQQDDHr/jh2Jy4yALcK4JyWbVkPRaWmhck3IgCoeOO3z1e2dBowLh64QAM+Qb72pxekALga2oi4GvT+TlWNhzPH4V example)
]: any -> oneof<record<ssh_key: record<fingerprint: string, id: int, name: string, public_key: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/account/keys" $auth.query)
  let req_body = {"name": $name, "public_key": $public_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete an SSH Key
#
# DELETE /v2/account/keys/{ssh_key_identifier}
# operationId: sshKeys_delete
export def "ssh-keys-delete" [
  ssh_key_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ssh_key_identifier | is-empty) { error make --unspanned { msg: "path parameter 'ssh_key_identifier' must be non-empty" } }
  let full_url = (build-url $base ({ssh_key_identifier: (encode-path-segment $ssh_key_identifier)} | format pattern "/v2/account/keys/{ssh_key_identifier}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing SSH Key
#
# GET /v2/account/keys/{ssh_key_identifier}
# operationId: sshKeys_get
export def "ssh-keys-get" [
  ssh_key_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<ssh_key: record<fingerprint: string, id: int, name: string, public_key: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ssh_key_identifier | is-empty) { error make --unspanned { msg: "path parameter 'ssh_key_identifier' must be non-empty" } }
  let full_url = (build-url $base ({ssh_key_identifier: (encode-path-segment $ssh_key_identifier)} | format pattern "/v2/account/keys/{ssh_key_identifier}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update an SSH Key's Name
#
# PUT /v2/account/keys/{ssh_key_identifier}
# operationId: sshKeys_update
export def "ssh-keys-update" [
  ssh_key_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A human-readable display name for this key, used to easily identify the SSH keys when they are displayed. (e.g. My SSH Public Key)
]: any -> oneof<record<ssh_key: record<fingerprint: string, id: int, name: string, public_key: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ssh_key_identifier | is-empty) { error make --unspanned { msg: "path parameter 'ssh_key_identifier' must be non-empty" } }
  let full_url = (build-url $base ({ssh_key_identifier: (encode-path-segment $ssh_key_identifier)} | format pattern "/v2/account/keys/{ssh_key_identifier}") $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List All Actions
#
# GET /v2/actions
# operationId: actions_list
export def "actions-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<actions: table<completed_at: string, id: int, region: record, region_slug: string, resource_id: int, resource_type: string, started_at: string, status: string, type: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/actions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve an Existing Action
#
# GET /v2/actions/{action_id}
# operationId: actions_get
export def "actions-get" [
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<action: record<completed_at: string, id: int, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, region_slug: string, resource_id: int, resource_type: string, started_at: string, status: string, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($action_id | is-empty) { error make --unspanned { msg: "path parameter 'action_id' must be non-empty" } }
  let full_url = (build-url $base ({action_id: (encode-path-segment $action_id)} | format pattern "/v2/actions/{action_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Apps
#
# GET /v2/apps
# operationId: apps_list
export def "apps-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --with-projects: oneof<nothing, bool> # Whether the project_id of listed apps should be fetched and included. (e.g. true)
]: nothing -> oneof<record<apps: table<active_deployment: record, created_at: string, default_ingress: string, domains: list, id: string, in_progress_deployment: record, last_deployment_created_at: string, live_domain: string, live_url: string, live_url_base: string, owner_uuid: string, pending_deployment: record, pinned_deployment: record, project_id: string, region: record, spec: record, tier_slug: string, updated_at: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "with_projects" $with_projects "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/apps" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page, "with_projects": $with_projects} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New App
#
# POST /v2/apps
# operationId: apps_create
export def "apps-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string@accept-completer # The content-type that should be used by the response. By default, the response will be `application/json`. `application/yaml` is also supported. (e.g. application/json)
  --content-type: string@content-type-completer # The content-type used for the request. By default, the requests are assumed to use `application/json`. `application/yaml` is also supported. (e.g. application/json)
  --project-id: string # The ID of the project the app should be assigned to. If omitted, it will be assigned to your default project.
  spec: record # The desired configuration of an application. — shape: {databases?: list, domains?: list, functions?: list, jobs?: list, name: string, region?: "ams"|"nyc"|"fra"|"sfo"|"sgp"|"blr"|"tor"|"lon"|"syd", services?: list, static_sites?: list, workers?: list}
]: any -> oneof<record<app: record<active_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, created_at: string, default_ingress: string, domains: list<record>, id: string, in_progress_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, last_deployment_created_at: string, live_domain: string, live_url: string, live_url_base: string, owner_uuid: string, pending_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, pinned_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, project_id: string, region: record<continent: string, data_centers: list, default: bool, disabled: bool, flag: string, label: string, reason: string, slug: string>, spec: record<databases: list, domains: list, functions: list, jobs: list, name: string, region: string, services: list, static_sites: list, workers: list>, tier_slug: string, updated_at: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apps" $auth.query)
  let req_body = {"project_id": $project_id, "spec": $spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Retrieve Multiple Apps' Daily Bandwidth Metrics
#
# POST /v2/apps/metrics/bandwidth_daily
# operationId: apps_list_metrics_bandwidth_daily
export def "apps-list-metrics-bandwidth-daily" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  app_ids: list<string> # A list of app IDs to query bandwidth metrics for. (e.g. [4f6c71e2-1e90-4762-9fee-6cc4a0a9f2cf, c2a93513-8d9b-4223-9d61-5e7272c81cf5])
  --date: string # Optional day to query. Only the date component of the timestamp will be considered. Default: yesterday. (format: date-time, e.g. 2023-01-17T00:00:00Z)
]: any -> oneof<record<app_bandwidth_usage: table<app_id: string, bandwidth_bytes: string>, date: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apps/metrics/bandwidth_daily" $auth.query)
  let req_body = {"app_ids": $app_ids, "date": $date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Propose an App Spec
#
# POST /v2/apps/propose
# operationId: apps_validate_appSpec
export def "apps-validate-app-spec" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # An optional ID of an existing app. If set, the spec will be treated as a proposed update to the specified app. The existing app is not modified using this method. (e.g. b6bdf840-2854-4f87-a36c-5f231c617c84)
  spec: record # The desired configuration of an application. — shape: {databases?: list, domains?: list, functions?: list, jobs?: list, name: string, region?: "ams"|"nyc"|"fra"|"sfo"|"sgp"|"blr"|"tor"|"lon"|"syd", services?: list, static_sites?: list, workers?: list}
]: any -> oneof<record<app_cost: int, app_is_static: bool, app_name_available: bool, app_name_suggestion: string, app_tier_downgrade_cost: int, existing_static_apps: string, spec: record<databases: list<record>, domains: list<record>, functions: list<record>, jobs: list<record>, name: string, region: string, services: list<record>, static_sites: list<record>, workers: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apps/propose" $auth.query)
  let req_body = {"app_id": $app_id, "spec": $spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List App Regions
#
# GET /v2/apps/regions
# operationId: apps_list_regions
export def "apps-list-regions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<regions: table<continent: string, data_centers: list, default: bool, disabled: bool, flag: string, label: string, reason: string, slug: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apps/regions" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List App Tiers
#
# GET /v2/apps/tiers
# operationId: apps_list_tiers
export def "apps-list-tiers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<tiers: table<build_seconds: string, egress_bandwidth_bytes: string, name: string, slug: string, storage_bytes: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apps/tiers" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Instance Sizes
#
# GET /v2/apps/tiers/instance_sizes
# operationId: apps_list_instanceSizes
export def "apps-list-instance-sizes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<discount_percent: float, instance_sizes: table<cpu_type: string, cpus: string, memory_bytes: string, name: string, slug: string, tier_downgrade_to: string, tier_slug: string, tier_upgrade_to: string, usd_per_month: string, usd_per_second: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/apps/tiers/instance_sizes" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve an Instance Size
#
# GET /v2/apps/tiers/instance_sizes/{slug}
# operationId: apps_get_instanceSize
export def "apps-get-instance-size" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<instance_size: record<cpu_type: string, cpus: string, memory_bytes: string, name: string, slug: string, tier_downgrade_to: string, tier_slug: string, tier_upgrade_to: string, usd_per_month: string, usd_per_second: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($slug | is-empty) { error make --unspanned { msg: "path parameter 'slug' must be non-empty" } }
  let full_url = (build-url $base ({slug: (encode-path-segment $slug)} | format pattern "/v2/apps/tiers/instance_sizes/{slug}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve an App Tier
#
# GET /v2/apps/tiers/{slug}
# operationId: apps_get_tier
export def "apps-get-tier" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<tier: record<build_seconds: string, egress_bandwidth_bytes: string, name: string, slug: string, storage_bytes: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($slug | is-empty) { error make --unspanned { msg: "path parameter 'slug' must be non-empty" } }
  let full_url = (build-url $base ({slug: (encode-path-segment $slug)} | format pattern "/v2/apps/tiers/{slug}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all app alerts
#
# GET /v2/apps/{app_id}/alerts
# operationId: apps_list_alerts
export def "apps-list-alerts" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<alerts: table<component_name: string, emails: list, id: string, phase: string, progress: record, slack_webhooks: list, spec: record>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/alerts") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update destinations for alerts
#
# POST /v2/apps/{app_id}/alerts/{alert_id}/destinations
# operationId: apps_assign_alertDestinations
export def "apps-assign-alert-destinations" [
  app_id: string
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: list<string> # e.g. [sammy@digitalocean.com]
  --slack-webhooks: list # item shape: {channel?: string, url?: string}
]: any -> oneof<record<alert: record<component_name: string, emails: list<string>, id: string, phase: string, progress: record<steps: list>, slack_webhooks: list<record>, spec: record<disabled: bool, operator: string, rule: string, value: float, window: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($alert_id | is-empty) { error make --unspanned { msg: "path parameter 'alert_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), alert_id: (encode-path-segment $alert_id)} | format pattern "/v2/apps/{app_id}/alerts/{alert_id}/destinations") $auth.query)
  let req_body = {"emails": $emails, "slack_webhooks": $slack_webhooks} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve Active Deployment Logs
#
# GET /v2/apps/{app_id}/components/{component_name}/logs
# operationId: apps_get_logs_active_deployment
export def "apps-get-logs-active-deployment" [
  app_id: string
  component_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --follow: oneof<nothing, bool> # Whether the logs should follow live updates. (e.g. true)
  --type: string@type-completer-1 # The type of logs to retrieve - BUILD: Build-time logs - DEPLOY: Deploy-time logs - RUN: Live run-time logs (required, default: UNSPECIFIED, e.g. BUILD)
  --pod-connection-timeout: string # An optional time duration to wait if the underlying component instance is not immediately available. Default: `3m`. (e.g. 3m)
]: nothing -> oneof<record<historic_urls: list<string>, live_url: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($component_name | is-empty) { error make --unspanned { msg: "path parameter 'component_name' must be non-empty" } }
  let type = ($type | default "UNSPECIFIED")
  let qp = [(serialize-qp "follow" $follow "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "pod_connection_timeout" $pod_connection_timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), component_name: (encode-path-segment $component_name)} | format pattern "/v2/apps/{app_id}/components/{component_name}/logs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"follow": $follow, "type": $type, "pod_connection_timeout": $pod_connection_timeout} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List App Deployments
#
# GET /v2/apps/{app_id}/deployments
# operationId: apps_list_deployments
export def "apps-list-deployments" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
]: nothing -> oneof<record<deployments: table<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/deployments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an App Deployment
#
# POST /v2/apps/{app_id}/deployments
# operationId: apps_create_deployment
export def "apps-create-deployment" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force-build: oneof<nothing, bool> # e.g. true
]: any -> oneof<record<deployment: record<cause: string, cloned_from: string, created_at: string, functions: list<record>, id: string, jobs: list<record>, phase: string, phase_last_updated_at: string, progress: record<error_steps: int, pending_steps: int, running_steps: int, steps: list, success_steps: int, summary_steps: list, total_steps: int>, services: list<record>, spec: record<databases: list, domains: list, functions: list, jobs: list, name: string, region: string, services: list, static_sites: list, workers: list>, static_sites: list<record>, tier_slug: string, updated_at: string, workers: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/deployments") $auth.query)
  let req_body = {"force_build": $force_build} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve an App Deployment
#
# GET /v2/apps/{app_id}/deployments/{deployment_id}
# operationId: apps_get_deployment
export def "apps-get-deployment" [
  app_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<deployment: record<cause: string, cloned_from: string, created_at: string, functions: list<record>, id: string, jobs: list<record>, phase: string, phase_last_updated_at: string, progress: record<error_steps: int, pending_steps: int, running_steps: int, steps: list, success_steps: int, summary_steps: list, total_steps: int>, services: list<record>, spec: record<databases: list, domains: list, functions: list, jobs: list, name: string, region: string, services: list, static_sites: list, workers: list>, static_sites: list<record>, tier_slug: string, updated_at: string, workers: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deployment_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), deployment_id: (encode-path-segment $deployment_id)} | format pattern "/v2/apps/{app_id}/deployments/{deployment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Cancel a Deployment
#
# POST /v2/apps/{app_id}/deployments/{deployment_id}/cancel
# operationId: apps_cancel_deployment
export def "apps-cancel-deployment" [
  app_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<deployment: record<cause: string, cloned_from: string, created_at: string, functions: list<record>, id: string, jobs: list<record>, phase: string, phase_last_updated_at: string, progress: record<error_steps: int, pending_steps: int, running_steps: int, steps: list, success_steps: int, summary_steps: list, total_steps: int>, services: list<record>, spec: record<databases: list, domains: list, functions: list, jobs: list, name: string, region: string, services: list, static_sites: list, workers: list>, static_sites: list<record>, tier_slug: string, updated_at: string, workers: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deployment_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), deployment_id: (encode-path-segment $deployment_id)} | format pattern "/v2/apps/{app_id}/deployments/{deployment_id}/cancel") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve Deployment Logs
#
# GET /v2/apps/{app_id}/deployments/{deployment_id}/components/{component_name}/logs
# operationId: apps_get_logs
export def "apps-get-logs" [
  app_id: string
  deployment_id: string
  component_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --follow: oneof<nothing, bool> # Whether the logs should follow live updates. (e.g. true)
  --type: string@type-completer-1 # The type of logs to retrieve - BUILD: Build-time logs - DEPLOY: Deploy-time logs - RUN: Live run-time logs (required, default: UNSPECIFIED, e.g. BUILD)
  --pod-connection-timeout: string # An optional time duration to wait if the underlying component instance is not immediately available. Default: `3m`. (e.g. 3m)
]: nothing -> oneof<record<historic_urls: list<string>, live_url: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deployment_id' must be non-empty" } }
  if ($component_name | is-empty) { error make --unspanned { msg: "path parameter 'component_name' must be non-empty" } }
  let type = ($type | default "UNSPECIFIED")
  let qp = [(serialize-qp "follow" $follow "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "pod_connection_timeout" $pod_connection_timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), deployment_id: (encode-path-segment $deployment_id), component_name: (encode-path-segment $component_name)} | format pattern "/v2/apps/{app_id}/deployments/{deployment_id}/components/{component_name}/logs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"follow": $follow, "type": $type, "pod_connection_timeout": $pod_connection_timeout} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve Aggregate Deployment Logs
#
# GET /v2/apps/{app_id}/deployments/{deployment_id}/logs
# operationId: apps_get_logs_aggregate
export def "apps-get-logs-aggregate" [
  app_id: string
  deployment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --follow: oneof<nothing, bool> # Whether the logs should follow live updates. (e.g. true)
  --type: string@type-completer-1 # The type of logs to retrieve - BUILD: Build-time logs - DEPLOY: Deploy-time logs - RUN: Live run-time logs (required, default: UNSPECIFIED, e.g. BUILD)
  --pod-connection-timeout: string # An optional time duration to wait if the underlying component instance is not immediately available. Default: `3m`. (e.g. 3m)
]: nothing -> oneof<record<historic_urls: list<string>, live_url: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  if ($deployment_id | is-empty) { error make --unspanned { msg: "path parameter 'deployment_id' must be non-empty" } }
  let type = ($type | default "UNSPECIFIED")
  let qp = [(serialize-qp "follow" $follow "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "pod_connection_timeout" $pod_connection_timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), deployment_id: (encode-path-segment $deployment_id)} | format pattern "/v2/apps/{app_id}/deployments/{deployment_id}/logs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"follow": $follow, "type": $type, "pod_connection_timeout": $pod_connection_timeout} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve Active Deployment Aggregate Logs
#
# GET /v2/apps/{app_id}/logs
# operationId: apps_get_logs_active_deployment_aggregate
export def "apps-get-logs-active-deployment-aggregate" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --follow: oneof<nothing, bool> # Whether the logs should follow live updates. (e.g. true)
  --type: string@type-completer-1 # The type of logs to retrieve - BUILD: Build-time logs - DEPLOY: Deploy-time logs - RUN: Live run-time logs (required, default: UNSPECIFIED, e.g. BUILD)
  --pod-connection-timeout: string # An optional time duration to wait if the underlying component instance is not immediately available. Default: `3m`. (e.g. 3m)
]: nothing -> oneof<record<historic_urls: list<string>, live_url: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let type = ($type | default "UNSPECIFIED")
  let qp = [(serialize-qp "follow" $follow "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "pod_connection_timeout" $pod_connection_timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/logs") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"follow": $follow, "type": $type, "pod_connection_timeout": $pod_connection_timeout} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve App Daily Bandwidth Metrics
#
# GET /v2/apps/{app_id}/metrics/bandwidth_daily
# operationId: apps_get_metrics_bandwidth_daily
export def "apps-get-metrics-bandwidth-daily" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Optional day to query. Only the date component of the timestamp will be considered. Default: yesterday. (format: date-time, e.g. 2023-01-17T00:00:00Z)
]: nothing -> oneof<record<app_bandwidth_usage: table<app_id: string, bandwidth_bytes: string>, date: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/metrics/bandwidth_daily") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"date": $date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Rollback App
#
# POST /v2/apps/{app_id}/rollback
# operationId: apps_create_rollback
export def "apps-create-rollback" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-id: string # The ID of the deployment to rollback to. (e.g. 3aa4d20e-5527-4c00-b496-601fbd22520a)
  --skip-pin: oneof<nothing, bool> # Whether to skip pinning the rollback deployment. If false, the rollback deployment will be pinned and any new deployments including Auto Deploy on Push hooks will be disabled until the rollback is either manually committed or reverted via the CommitAppRollback or RevertAppRollback endpoints respectively. If true, the rollback will be immediately committed and the app will remain unpinned. (e.g. false)
]: any -> oneof<record<deployment: record<cause: string, cloned_from: string, created_at: string, functions: list<record>, id: string, jobs: list<record>, phase: string, phase_last_updated_at: string, progress: record<error_steps: int, pending_steps: int, running_steps: int, steps: list, success_steps: int, summary_steps: list, total_steps: int>, services: list<record>, spec: record<databases: list, domains: list, functions: list, jobs: list, name: string, region: string, services: list, static_sites: list, workers: list>, static_sites: list<record>, tier_slug: string, updated_at: string, workers: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/rollback") $auth.query)
  let req_body = {"deployment_id": $deployment_id, "skip_pin": $skip_pin} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Commit App Rollback
#
# POST /v2/apps/{app_id}/rollback/commit
# operationId: apps_commit_rollback
export def "apps-commit-rollback" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/rollback/commit") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Revert App Rollback
#
# POST /v2/apps/{app_id}/rollback/revert
# operationId: apps_revert_rollback
export def "apps-revert-rollback" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<deployment: record<cause: string, cloned_from: string, created_at: string, functions: list<record>, id: string, jobs: list<record>, phase: string, phase_last_updated_at: string, progress: record<error_steps: int, pending_steps: int, running_steps: int, steps: list, success_steps: int, summary_steps: list, total_steps: int>, services: list<record>, spec: record<databases: list, domains: list, functions: list, jobs: list, name: string, region: string, services: list, static_sites: list, workers: list>, static_sites: list<record>, tier_slug: string, updated_at: string, workers: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/rollback/revert") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Validate App Rollback
#
# POST /v2/apps/{app_id}/rollback/validate
# operationId: apps_validate_rollback
export def "apps-validate-rollback" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --deployment-id: string # The ID of the deployment to rollback to. (e.g. 3aa4d20e-5527-4c00-b496-601fbd22520a)
  --skip-pin: oneof<nothing, bool> # Whether to skip pinning the rollback deployment. If false, the rollback deployment will be pinned and any new deployments including Auto Deploy on Push hooks will be disabled until the rollback is either manually committed or reverted via the CommitAppRollback or RevertAppRollback endpoints respectively. If true, the rollback will be immediately committed and the app will remain unpinned. (e.g. false)
]: any -> oneof<record<error: record<code: string, components: list<string>, message: string>, valid: bool, warnings: table<code: string, components: list, message: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'app_id' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/v2/apps/{app_id}/rollback/validate") $auth.query)
  let req_body = {"deployment_id": $deployment_id, "skip_pin": $skip_pin} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete an App
#
# DELETE /v2/apps/{id}
# operationId: apps_delete
export def "apps-delete" [
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
]: nothing -> oneof<record<id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/apps/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve an Existing App
#
# GET /v2/apps/{id}
# operationId: apps_get
export def "apps-get" [
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
  --name: string # The name of the app to retrieve. (e.g. myApp)
]: nothing -> oneof<record<app: record<active_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, created_at: string, default_ingress: string, domains: list<record>, id: string, in_progress_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, last_deployment_created_at: string, live_domain: string, live_url: string, live_url_base: string, owner_uuid: string, pending_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, pinned_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, project_id: string, region: record<continent: string, data_centers: list, default: bool, disabled: bool, flag: string, label: string, reason: string, slug: string>, spec: record<databases: list, domains: list, functions: list, jobs: list, name: string, region: string, services: list, static_sites: list, workers: list>, tier_slug: string, updated_at: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/apps/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update an App
#
# PUT /v2/apps/{id}
# operationId: apps_update
export def "apps-update" [
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
  spec: record # The desired configuration of an application. — shape: {databases?: list, domains?: list, functions?: list, jobs?: list, name: string, region?: "ams"|"nyc"|"fra"|"sfo"|"sgp"|"blr"|"tor"|"lon"|"syd", services?: list, static_sites?: list, workers?: list}
]: any -> oneof<record<app: record<active_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, created_at: string, default_ingress: string, domains: list<record>, id: string, in_progress_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, last_deployment_created_at: string, live_domain: string, live_url: string, live_url_base: string, owner_uuid: string, pending_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, pinned_deployment: record<cause: string, cloned_from: string, created_at: string, functions: list, id: string, jobs: list, phase: string, phase_last_updated_at: string, progress: record, services: list, spec: record, static_sites: list, tier_slug: string, updated_at: string, workers: list>, project_id: string, region: record<continent: string, data_centers: list, default: bool, disabled: bool, flag: string, label: string, reason: string, slug: string>, spec: record<databases: list, domains: list, functions: list, jobs: list, name: string, region: string, services: list, static_sites: list, workers: list>, tier_slug: string, updated_at: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/apps/{id}") $auth.query)
  let req_body = {"spec": $spec} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List All CDN Endpoints
#
# GET /v2/cdn/endpoints
# operationId: cdn_list_endpoints
export def "cdn-list-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<endpoints: table<certificate_id: string, created_at: string, custom_domain: string, endpoint: string, id: string, origin: string, ttl: int>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/cdn/endpoints" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New CDN Endpoint
#
# POST /v2/cdn/endpoints
# operationId: cdn_create_endpoint
export def "cdn-create-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificate-id: string # The ID of a DigitalOcean managed TLS certificate used for SSL when a custom subdomain is provided. (format: uuid, e.g. 892071a0-bb95-49bc-8021-3afd67a210bf)
  --custom-domain: string # The fully qualified domain name (FQDN) of the custom subdomain used with the CDN endpoint. (format: hostname, e.g. static.example.com)
  origin: string # The fully qualified domain name (FQDN) for the origin server which provides the content for the CDN. This is currently restricted to a Space. (format: hostname, e.g. static-images.nyc3.digitaloceanspaces.com)
  --ttl: int@ttl-completer # The amount of time the content is cached by the CDN's edge servers in seconds. TTL must be one of 60, 600, 3600, 86400, or 604800. Defaults to 3600 (one hour) when excluded. (default: 3600, e.g. 3600)
]: any -> oneof<record<endpoint: record<certificate_id: string, created_at: string, custom_domain: string, endpoint: string, id: string, origin: string, ttl: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/cdn/endpoints" $auth.query)
  let req_body = {"certificate_id": $certificate_id, "custom_domain": $custom_domain, "origin": $origin, "ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a CDN Endpoint
#
# DELETE /v2/cdn/endpoints/{cdn_id}
# operationId: cdn_delete_endpoint
export def "cdn-delete-endpoint" [
  cdn_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cdn_id | is-empty) { error make --unspanned { msg: "path parameter 'cdn_id' must be non-empty" } }
  let full_url = (build-url $base ({cdn_id: (encode-path-segment $cdn_id)} | format pattern "/v2/cdn/endpoints/{cdn_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing CDN Endpoint
#
# GET /v2/cdn/endpoints/{cdn_id}
# operationId: cdn_get_endpoint
export def "cdn-get-endpoint" [
  cdn_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<endpoint: record<certificate_id: string, created_at: string, custom_domain: string, endpoint: string, id: string, origin: string, ttl: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cdn_id | is-empty) { error make --unspanned { msg: "path parameter 'cdn_id' must be non-empty" } }
  let full_url = (build-url $base ({cdn_id: (encode-path-segment $cdn_id)} | format pattern "/v2/cdn/endpoints/{cdn_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a CDN Endpoint
#
# PUT /v2/cdn/endpoints/{cdn_id}
# operationId: cdn_update_endpoints
export def "cdn-update-endpoints" [
  cdn_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --certificate-id: string # The ID of a DigitalOcean managed TLS certificate used for SSL when a custom subdomain is provided. (format: uuid, e.g. 892071a0-bb95-49bc-8021-3afd67a210bf)
  --custom-domain: string # The fully qualified domain name (FQDN) of the custom subdomain used with the CDN endpoint. (format: hostname, e.g. static.example.com)
  --ttl: int@ttl-completer # The amount of time the content is cached by the CDN's edge servers in seconds. TTL must be one of 60, 600, 3600, 86400, or 604800. Defaults to 3600 (one hour) when excluded. (default: 3600, e.g. 3600)
]: any -> oneof<record<endpoint: record<certificate_id: string, created_at: string, custom_domain: string, endpoint: string, id: string, origin: string, ttl: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cdn_id | is-empty) { error make --unspanned { msg: "path parameter 'cdn_id' must be non-empty" } }
  let full_url = (build-url $base ({cdn_id: (encode-path-segment $cdn_id)} | format pattern "/v2/cdn/endpoints/{cdn_id}") $auth.query)
  let req_body = {"certificate_id": $certificate_id, "custom_domain": $custom_domain, "ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Purge the Cache for an Existing CDN Endpoint
#
# DELETE /v2/cdn/endpoints/{cdn_id}/cache
# operationId: cdn_purge_cache
export def "cdn-purge-cache" [
  cdn_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  files: list<string> # An array of strings containing the path to the content to be purged from the CDN cache. (e.g. [path/to/image.png, path/to/css/*])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cdn_id | is-empty) { error make --unspanned { msg: "path parameter 'cdn_id' must be non-empty" } }
  let full_url = (build-url $base ({cdn_id: (encode-path-segment $cdn_id)} | format pattern "/v2/cdn/endpoints/{cdn_id}/cache") $auth.query)
  let req_body = {"files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [204]
}

# List All Certificates
#
# GET /v2/certificates
# operationId: certificates_list
export def "certificates-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<certificates: table<created_at: string, dns_names: list, id: string, name: string, not_after: string, sha1_fingerprint: string, state: string, type: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/certificates" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New Certificate
#
# POST /v2/certificates
# operationId: certificates_create
export def "certificates-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # A unique human-readable name referring to a certificate. (e.g. web-cert-01)
  --type: string@type-completer-2 # A string representing the type of the certificate. The value will be `custom` for a user-uploaded certificate or `lets_encrypt` for one automatically generated with Let's Encrypt. (e.g. lets_encrypt)
  --dns-names: list<string> # An array of fully qualified domain names (FQDNs) for which the certificate was issued. A certificate covering all subdomains can be issued using a wildcard (e.g. `*.example.com`). (e.g. [www.example.com, example.com])
  --certificate-chain: string # The full PEM-formatted trust chain between the certificate authority's certificate and your domain's SSL certificate. (e.g. -----BEGIN CERTIFICATE----- MIIFFjCCA/6gAwIBAgISA0AznUJmXhu08/89ZuSPC/kRMA0GCSqGSIb3DQEBCwUA MEoxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MSMwIQYDVQQD ExpMZXQncyBFbmNyeXB0IEF1dGhvcml0eSBYMzAeFw0xNjExMjQwMDIzMDBaFw0x NzAyMjIwMDIzMDBaMCQxIjAgBgNVBAMTGWNsb3VkLmFuZHJld3NvbWV0aGluZy5j b20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDBIZMz7tnK6V52SVf+ CYssOfCQHAx5f0Ou5rYbq3xNh8VHAIYJCQ1QxQIxKSP6+uODSYrb2KWyurP1DwGb 8OYm0J3syEDtCUQik1cpCzpeNlAZ2f8FzXyYQAqPopxdRpsFz8DtZnVvu86XwrE4 oFPl9MReICmZfBNWylpV5qgFPoXyJ70ZAsTm3cEe3n+LBXEnY4YrVDRWxA3wZ2mz Z03HZ1hHrxK9CMnS829U+8sK+UneZpCO7yLRPuxwhmps0wpK/YuZZfRAKF1FZRna k/SIQ28rnWufmdg16YqqHgl5JOgnb3aslKRvL4dI2Gwnkd2IHtpZnTR0gxFXfqqb QwuRAgMBAAGjggIaMIICFjAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYB BQUHAwEGCCsGAQUFBwMCMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFLsAFcxAhFX1 MbCnzr9hEO5rL4jqMB8GA1UdIwQYMBaAFKhKamMEfd265tE5t6ZFZe/zqOyhMHAG CCsGAQUFBwEBBGQwYjAvBggrBgEFBQcwAYYjaHR0cDovL29jc3AuaW50LXgzLmxl dHNlbmNyeXB0Lm9yZy8wLwYIKwYBBQUHMAKGI2h0dHA6Ly9jZXJ0LmludC14My5s ZXRzZW5jcnlwdC5vcmcvMCQGA1UdEQQdMBuCGWNsb3VkLmFuZHJld3NvbWV0aGlu Zy5jb20wgf4GA1UdIASB9jCB8zAIBgZngQwBAgEwgeWECysGAQQBgt8TAQEBMIHW MCYGCCsGAQUFBwIBFhpodHRwOi8vY3BzLmxldHNlbmNyeXB0Lm9yZzCBqwYIKwYB BQUHAgIwgZ4MgZtUaGlzIENlcnRpZmljYXRlIG1heSBvbmx5IGJlIHJlbGllZCB1 cG9uIGJ5IFJlbHlpbmcgUGFydGllcyBhbmQgb25seSQ2ziBhY2NvcmRhbmNlIHdp dGggdGhlIENlcnRpZmljYXRlIFBvbGljeSBmb3VuZCBhdCBsdHRwczovL2xldHNl bmNyeXB0Lm9yZy9yZXBvc2l0b3J5LzANBgkqhkiG9w0BAQsFAAOCAQEAOZVQvrjM PKXLARTjB5XsgfyDN3/qwLl7SmwGkPe+B+9FJpfScYG1JzVuCj/SoaPaK34G4x/e iXwlwOXtMOtqjQYzNu2Pr2C+I+rVmaxIrCUXFmC205IMuUBEeWXG9Y/HvXQLPabD D3Gdl5+Feink9SDRP7G0HaAwq13hI7ARxkL3o+UIY39X0dV3WOboW2Re8nrkFXJ7 q9Z6shK5QgpBfsLjtjNsQzaGV3ve1gOg25aTJGearBWOvEjJNA1wGMoKVXOtYwm/ WyWoVdCQ8HmconcbJB6xc0UZ1EjvzRr5ZIvSa5uHZD0L3m7/kpPWlAlFJ7hHASPu UlF1zblDmg2Iaw== -----END CERTIFICATE----- -----BEGIN CERTIFICATE----- MIIEkjCCA3qgAwIBAgIQCgFBQgAAAVOFc2oLheynCDANBgkqhkiG9w0BAQsFADA/ MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT DkRTVCBSb290IENBIFgzMB4XDTE2MDMxNzE2NDA0NloXDTIxMDMxNzE2NDA0Nlow SjELMAkGA1UEBhMCVVMxFjAUBgNVBAoTDUxldCdzIEVuY3J5cHQxIzAhBgNVBAMT GkxldCdzIEVuY3J5cHQgQXV0aG9yaXR5IFgzMIIBIjANBgkqhkiG9w0BAQEFAAOC AQ8AMIIBCgKCAQEAnNMM8FrlLsd3cl03g7NoYzDq1zUmGSXhvb418XCSL7e4S0EF q6meNQhY7LEqxGiHC6PjdeTm86dicbp5gWAf15Gan/PQeGdxyGkOlZHP/uaZ6WA8 SMx+yk13EiSdRxta67nsHjcAHJyse6cF6s5K671B5TaYucv9bTyWaN8jKkKQDIZ0 Z8h/pZq4UmEUEz9l6YKHy9v6Dlb2honzhT+Xhq+w3Brvaw2VFn3EK6BlspkENnWA a6xK8xuQSXgvopZPKiAlKQTGdMDQMc2PMTiVFrqoM7hD8bEfwzB/onkxEz0tNvjj /PIzark5McWvxI0NHWQWM6r6hCm21AvA2H3DkwIPOIUo4IBfTCCAXkwEgYDVR0T AQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwfwYIKwYBBQUHAQEEczBxMDIG CCsGAQUFBzABhiZodHRwOi8vaXNyZy50cnVzdGlkLm9jc3AuaWRlbnRydXN0LmNv bTA7BggrBgEFBQcwAoYvaHR0cDovL2FwcHMuaWRlbnRydXN0LmNvbS9yb290cy9k c3Ryb290Y2F4My5wN2MwHwYDVR0jBBgwFoAUxKexpHsscfrb4UuQdf/EFWCFiRAw VAYDVR0gBE0wSzAIBgZngQwBAgEwPwYLKwYBBAGC3xMBAQEwMDAuBggrBgEFBQcC ARYiaHR0cDovL2Nwcy5yb290LXgxLmxldHNlbmNyeXB0Lm9yZzA8BgNVHR8ENTAz MDGgL6AthitodHRwOi8vY3JsLmlkZW50cnVzdC5jb20vRFNUUk9PVENBWDNDUkwu Y3JsMB0GA1UdDgQWBBSoSmpjBH3duubRObemRWXv86jsoTANBgkqhkiG9w0BAQsF AAOCAQEA3TPXEfNjWDjdGBX7CVW+dla5cEilaUcne8IkCJLxWh9KEik3JHRRHGJo uM2VcGfl96S8TihRzZvoroed6ti6WqEBmtzw3Wodatg+VyOeph4EYpr/1wXKtx8/ wApIvJSwtmVi4MFU5aMqrSDE6ea73Mj2tcMyo5jMd6jmeWUHK8so/joWUoHOUgwu X4Po1QYz+3dszkDqMp4fklxBwXRsW10KXzPMTZ+sOPAveyxindmjkW8lGy+QsRlG PfZ+G6Z6h7mjem0Y+iWlkYcV4PIWL1iwBi8saCbGS5jN2p8M+X+Q7UNKEkROb3N6 KOqkqm57TH2H3eDJAkSnh6/DNFu0Qg== -----END CERTIFICATE-----)
  --leaf-certificate: string # The contents of a PEM-formatted public SSL certificate. (e.g. -----BEGIN CERTIFICATE----- MIIFFjCCA/6gAwIBAgISA0AznUJmXhu08/89ZuSPC/kRMA0GCSqGSIb3DQEBCwUA MEoxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MSMwIQYDVQQD ExpMZXQncyBFbmNyeXB0IEF1dGhvcml0eSBYMzAeFw0xNjExMjQwMDIzMDBaFw0x NzAyMjIwMDIzMDBaMCQxIjAgBgNVBAMTGWNsb3VkLmFuZHJld3NvbWV0aGluZy5j b20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDBIZMz8pnK6V52SVf+ CYssOfCQHAx5f0Ou5rYbq3xNh8VWHIYJCQ1QxQIxKSP6+uODSYrb2KWyurP1DwGb 8OYm0J3syEDtCUQik1cpCzpeNlAZ2f8FzXyYQAqPopxdRpsFz8DtZnVvu86XwrE4 oFPl9MReICmZfBNWylpV5qgFPoXyJ70ZAsTm3cEe3n+LBXEnY4YrVDRWxA3wZ2mz Z03HZ1hHrxK9CMnS829U+8sK+UneZpCO7yLRPuxwhmps0wpK/YuZZfRAKF1FZRna k/SIQ28rnWufmdg16YqqHgl5JOgnb3aslKRvL4dI2Gwnkd2IHtpZnTR0gxFXfqqb QwuRAgMBAAGjggIaMIICFjAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYB BQUHAwEGCCsGAQUFBwMCMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFLsAFcxAhFX1 MbCnzr9hEO5rL4jqMB8GA1UdIwQYMBaAFKhKamMEfd265tE5t6ZFZe/zqOyhMHAG CCsGAQUFBwEBBGQwYjAvBggrBgEFBQcwAYYjaHR0cDovL29jc3AuaW50LXgzLmxl dHNlbmNyeXB0Lm9yZy8wLwYIKwYBBQUHMAKGI2h0dHA6Ly9jZXJ0LmludC14My5s ZXRzZW5jcnlwdC5vcmcvMCQGA1UdEQQdMBuCGWNsb3VkLmFuZHJld3NvbWV0aGlu Zy5jb20wgf4GA1UdIASB9jCB8zAIBgZngQwBAgWrgeYGCysGAQQBgt8TAQEBMIHW MCYGCCsGAQUFBwIBFhpodHRwOi8vY3BzLmxldHNlbmNyeXB0Lm9yZzCBqwYIKwYB BQUHAgIwgZ4MgZtUaGlzIENlcnRpZmljYXRlIG1heSBvbmx5IGJlIHJlbGllZCB1 cG9uIGJ5IFJlbHlpbmcgUGFydGllcyBhbmQgb25seSQ2ziBhY2NvcmRhbmNlIHdp dGggdGhlIENlcnRpZmljYXRlIFBvbGljeSBmb3VuZCBhdCBodHRwczovL2xldHNl bmNyeXB0Lm9yZy9yZXBvc2l0b3J5LzANBgkqhkiG9w0BAQsFAAOCAQEAOZVQvrjM PKXLARTjB5XsgfyDN3/qwLl7SmwGkPe+B+9FJpfScYG1JzVuCj/SoaPaK34G4x/e iXwlwOXtMOtqjQYzNu2Pr2C+I+rVmaxIrCUXFmC205IMuUBEeWXG9Y/HvXQLPabD D3Gdl5+Feink9SDRP7G0HaAwq13hI7ARxkL9p+UIY39X0dV3WOboW2Re8nrkFXJ7 q9Z6shK5QgpBfsLjtjNsQzaGV3ve1gOg25aTJGearBWOvEjJNA1wGMoKVXOtYwm/ WyWoVdCQ8HmconcbJB6xc0UZ1EjvzRr5ZIvSa5uHZD0L3m7/kpPWlAlFJ7hHASPu UlF1zblDmg2Iaw== -----END CERTIFICATE-----)
  --private-key: string # The contents of a PEM-formatted private-key corresponding to the SSL certificate. (e.g. -----BEGIN PRIVATE KEY----- MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDBIZMz8pnK6V52 SVf+CYssOfCQHAx5f0Ou5rYbq3xNh8VHAIYJCQ1QxQIxKSP6+uODSYrb2KWyurP1 DwGb8OYm0J3syEDtCUQik1cpCzpeNlAZ2f8FzXyYQAqPopxdRpsFz8DtZnVvu86X wrE4oFPl9MReICmZfBNWylpV5qgFPoXyJ70ZAsTm3cEe3n+LBXEnY4YrVDRWxA3w Z2mzZ03HZ1hHrxK9CMnS829U+8sK+UneZpCO7yLRPuxwhmps0wpK/YuZZfRAKF1F ZRnak/SIQ28rnWufmdg16YqqHgl5JOgnb3aslKRvL4dI2Gwnkd2IHtpZnTR0gxFX fqqbQwuRAgMBAAECggEBAILLmkW0JzOkmLTDNzR0giyRkLoIROqDpfLtjKdwm95l 9NUBJcU4vCvXQITKt/NhtnNTexcowg8pInb0ksJpg3UGE+4oMNBXVi2UW5MQZ5cm cVkQqgXkBF2YAY8FMaB6EML+0En2+dGR/3gIAr221xsFiXe1kHbB8Nb2c/d5HpFt eRpLVJnK+TxSr78PcZA8DDGlSgwvgimdAaFUNO2OqB9/0E9UPyKk2ycdff/Z6ldF 0hkCLtdYTTl8Kf/OwjcuTgmA2O3Y8/CoQX/L+oP9Rvt9pWCEfuebiOmHJVPO6Y6x gtQVEXwmF1pDHH4Qtz/e6UZTdYeMl9G4aNO2CawwcaYECgYEA57imgSOG4XsJLRh GGncV9R/xhy4AbDWLtAMzQRX4ktvKCaHWyQV2XK2we/cu29NLv2Y89WmerTNPOU+ P8+pB31uty2ELySVn15QhKpQClVEAlxCnnNjXYrii5LOM80+lVmxvQwxVd8Yz8nj IntyioXNBEnYS7V2RxxFGgFun1cCgYEA1V3W+Uyamhq8JS5EY0FhyGcXdHd70K49 W1ou7McIpncf9tM9acLS1hkI98rd2T69Zo8mKoV1V2hjFaKUYfNys6tTkYWeZCcJ 3rW44j9DTD+FmmjcX6b8DzfybGLehfNbCw6n67/r45DXIV/fk6XZfkx6IEGO4ODt Nfnvx4TuI1cCgYBACDiKqwSUvmkUuweOo4IuCxyb5Ee8v98P5JIE/VRDxlCbKbpx pxEam6aBBQVcDi+n8o0H3WjjlKc6UqbW/01YMoMrvzotxNBLz8Y0QtQHZvR6KoCG RKCKstxTcWflzKuknbqN4RapAhNbKBDJ8PMSWfyDWNyaXzSmBdvaidbF1QKBgDI0 o4oD0Xkjg1QIYAUu9FBQmb9JAjRnW36saNBEQS/SZg4RRKknM683MtoDvVIKJk0E sAlfX+4SXQZRPDMUMtA+Jyrd0xhj6zmhbwClvDMr20crF3fWdgcqtft1BEFmsuyW JUMe5OWmRkjPI2+9ncDPRAllA7a8lnSV/Crph5N/AoGBAIK249temKrGe9pmsmAo QbNuYSmwpnMoAqdHTrl70HEmK7ob6SIVmsR8QFAkH7xkYZc4Bxbx4h1bdpozGB+/ AangbiaYJcAOD1QyfiFbflvI1RFeHgrk7VIafeSeQv6qu0LLMi2zUbpgVzxt78Wg eTuK2xNR0PIM8OI7pRpgyj1I -----END PRIVATE KEY-----)
]: any -> oneof<record<certificate: record<created_at: string, dns_names: list<string>, id: string, name: string, not_after: string, sha1_fingerprint: string, state: string, type: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/certificates" $auth.query)
  let req_body = {"name": $name, "type": $type, "dns_names": $dns_names, "certificate_chain": $certificate_chain, "leaf_certificate": $leaf_certificate, "private_key": $private_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a Certificate
#
# DELETE /v2/certificates/{certificate_id}
# operationId: certificates_delete
export def "certificates-delete" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificate_id' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v2/certificates/{certificate_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Certificate
#
# GET /v2/certificates/{certificate_id}
# operationId: certificates_get
export def "certificates-get" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<certificate: record<created_at: string, dns_names: list<string>, id: string, name: string, not_after: string, sha1_fingerprint: string, state: string, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificate_id' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v2/certificates/{certificate_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Customer Balance
#
# GET /v2/customers/my/balance
# operationId: balance_get
export def "balance-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<account_balance: string, generated_at: string, month_to_date_balance: string, month_to_date_usage: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers/my/balance" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Billing History
#
# GET /v2/customers/my/billing_history
# operationId: billingHistory_list
export def "billing-history-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<billing_history: table<amount: string, date: string, description: string, invoice_id: string, invoice_uuid: string, type: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/customers/my/billing_history" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Invoices
#
# GET /v2/customers/my/invoices
# operationId: invoices_list
export def "invoices-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<invoice_preview: record<amount: string, invoice_period: string, invoice_uuid: string, updated_at: string>, invoices: table<amount: string, invoice_period: string, invoice_uuid: string, updated_at: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/customers/my/invoices" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve an Invoice by UUID
#
# GET /v2/customers/my/invoices/{invoice_uuid}
# operationId: invoices_get_byUUID
export def "invoices-get-by-uuid" [
  invoice_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<invoice_items: table<amount: string, description: string, duration: string, duration_unit: string, end_time: string, group_description: string, product: string, project_name: string, resource_id: string, resource_uuid: string, start_time: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_uuid | is-empty) { error make --unspanned { msg: "path parameter 'invoice_uuid' must be non-empty" } }
  let full_url = (build-url $base ({invoice_uuid: (encode-path-segment $invoice_uuid)} | format pattern "/v2/customers/my/invoices/{invoice_uuid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve an Invoice CSV by UUID
#
# GET /v2/customers/my/invoices/{invoice_uuid}/csv
# operationId: invoices_get_csvByUUID
export def "invoices-get-csv-by-uuid" [
  invoice_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_uuid | is-empty) { error make --unspanned { msg: "path parameter 'invoice_uuid' must be non-empty" } }
  let full_url = (build-url $base ({invoice_uuid: (encode-path-segment $invoice_uuid)} | format pattern "/v2/customers/my/invoices/{invoice_uuid}/csv") $auth.query)
  let accept_val = ($accept | default "text/csv")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve an Invoice PDF by UUID
#
# GET /v2/customers/my/invoices/{invoice_uuid}/pdf
# operationId: invoices_get_pdfByUUID
export def "invoices-get-pdf-by-uuid" [
  invoice_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_uuid | is-empty) { error make --unspanned { msg: "path parameter 'invoice_uuid' must be non-empty" } }
  let full_url = (build-url $base ({invoice_uuid: (encode-path-segment $invoice_uuid)} | format pattern "/v2/customers/my/invoices/{invoice_uuid}/pdf") $auth.query)
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve an Invoice Summary by UUID
#
# GET /v2/customers/my/invoices/{invoice_uuid}/summary
# operationId: invoices_get_summaryByUUID
export def "invoices-get-summary-by-uuid" [
  invoice_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<amount: string, billing_period: string, credits_and_adjustments: record<amount: string, name: string>, invoice_uuid: string, overages: record<amount: string, name: string>, product_charges: record<amount: string, items: list<record>, name: string>, taxes: record<amount: string, name: string>, user_billing_address: record<address_line1: string, address_line2: string, city: string, country_iso2_code: string, created_at: string, postal_code: string, region: string, updated_at: string>, user_company: string, user_email: string, user_name: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_uuid | is-empty) { error make --unspanned { msg: "path parameter 'invoice_uuid' must be non-empty" } }
  let full_url = (build-url $base ({invoice_uuid: (encode-path-segment $invoice_uuid)} | format pattern "/v2/customers/my/invoices/{invoice_uuid}/summary") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Database Clusters
#
# GET /v2/databases
# operationId: databases_list_clusters
export def "databases-list-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-name: string # Limits the results to database clusters with a specific tag. (e.g. production)
]: nothing -> oneof<record<databases: table<connection: record, created_at: string, db_names: list, engine: string, id: string, maintenance_window: record, name: string, num_nodes: int, private_connection: record, private_network_uuid: string, project_id: string, region: string, rules: list, size: string, status: string, tags: list, users: list, version: string, version_end_of_availability: string, version_end_of_life: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag_name" $tag_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/databases" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"tag_name": $tag_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New Database Cluster
#
# POST /v2/databases
# operationId: databases_create_cluster
export def "databases-create-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection: record
  engine: string@engine-completer # A slug representing the database engine used for the cluster. The possible values are: "pg" for PostgreSQL, "mysql" for MySQL, "redis" for Redis, and "mongodb" for MongoDB. (e.g. pg)
  --maintenance-window: record # nullable — shape: {day: string, hour: string}
  name: string # A unique, human-readable name referring to a database cluster. (e.g. backend)
  num_nodes: int # The number of nodes in the database cluster. (e.g. 2)
  --private-connection: record
  --private-network-uuid: string # A string specifying the UUID of the VPC to which the database cluster will be assigned. If excluded, the cluster when creating a new database cluster, it will be assigned to your account's default VPC for the region. (e.g. d455e75d-4858-4eec-8c95-da2f0a5f93a7)
  --project-id: string # The ID of the project that the database cluster is assigned to. If excluded when creating a new database cluster, it will be assigned to your default project. (format: uuid, e.g. 9cc10173-e9ea-4176-9dbc-a4cee4c4ff30)
  region: string # The slug identifier for the region where the database cluster is located. (e.g. nyc3)
  --rules: list # item shape: {cluster_uuid?: string, type: "droplet"|"k8s"|"ip_addr"|"tag"|"app", uuid?: string, value: string}
  size: string # The slug identifier representing the size of the nodes in the database cluster. (e.g. db-s-2vcpu-4gb)
  --tags: list<string> # An array of tags that have been applied to the database cluster. (nullable, e.g. [production])
  --version: string # A string representing the version of the database engine in use for the cluster. (e.g. 10)
  --backup-restore: record # shape: {backup_created_at?: string, database_name: string}
]: any -> oneof<record<database: record<connection: record<database: string, host: string, password: string, port: int, ssl: bool, uri: string, user: string>, created_at: string, db_names: list<string>, engine: string, id: string, maintenance_window: record<day: string, description: list, hour: string, pending: bool>, name: string, num_nodes: int, private_connection: record<database: string, host: string, password: string, port: int, ssl: bool, uri: string, user: string>, private_network_uuid: string, project_id: string, region: string, rules: list<record>, size: string, status: string, tags: list<string>, users: list<record>, version: string, version_end_of_availability: string, version_end_of_life: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/databases" $auth.query)
  let req_body = {"connection": $connection, "engine": $engine, "maintenance_window": $maintenance_window, "name": $name, "num_nodes": $num_nodes, "private_connection": $private_connection, "private_network_uuid": $private_network_uuid, "project_id": $project_id, "region": $region, "rules": $rules, "size": $size, "tags": $tags, "version": $version, "backup_restore": $backup_restore} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List Database Options
#
# GET /v2/databases/options
# operationId: databases_list_options
export def "databases-list-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<options: record<mongodb: record<regions: list, versions: list, layouts: list>, mysql: record<regions: list, versions: list, layouts: list>, pg: record<regions: list, versions: list, layouts: list>, redis: record<regions: list, versions: list, layouts: list>>, version_availability: record<mongodb: list<record>, mysql: list<record>, pg: list<record>, redis: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/databases/options" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Destroy a Database Cluster
#
# DELETE /v2/databases/{database_cluster_uuid}
# operationId: databases_destroy_cluster
export def "databases-destroy-cluster" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Database Cluster
#
# GET /v2/databases/{database_cluster_uuid}
# operationId: databases_get_cluster
export def "databases-get-cluster" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<database: record<connection: record<database: string, host: string, password: string, port: int, ssl: bool, uri: string, user: string>, created_at: string, db_names: list<string>, engine: string, id: string, maintenance_window: record<day: string, description: list, hour: string, pending: bool>, name: string, num_nodes: int, private_connection: record<database: string, host: string, password: string, port: int, ssl: bool, uri: string, user: string>, private_network_uuid: string, project_id: string, region: string, rules: list<record>, size: string, status: string, tags: list<string>, users: list<record>, version: string, version_end_of_availability: string, version_end_of_life: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Backups for a Database Cluster
#
# GET /v2/databases/{database_cluster_uuid}/backups
# operationId: databases_list_backups
export def "databases-list-backups" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<backups: table<created_at: string, size_gigabytes: float>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/backups") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve the Public Certificate
#
# GET /v2/databases/{database_cluster_uuid}/ca
# operationId: databases_get_ca
export def "databases-get-ca" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<ca: record<certificate: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/ca") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve an Existing Database Cluster Configuration
#
# GET /v2/databases/{database_cluster_uuid}/config
# operationId: databases_get_config
export def "databases-get-config" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<config: any>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/config") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update the Database Configuration for an Existing Database
#
# PATCH /v2/databases/{database_cluster_uuid}/config
# operationId: databases_patch_config
export def "databases-patch-config" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/config") $auth.query)
  let req_body = {"config": $config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# List All Databases
#
# GET /v2/databases/{database_cluster_uuid}/dbs
# operationId: databases_list
export def "databases-list" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<dbs: table<name: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/dbs") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a New Database
#
# POST /v2/databases/{database_cluster_uuid}/dbs
# operationId: databases_add
export def "databases-add" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the database. (e.g. alpha)
]: any -> oneof<record<db: record<name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/dbs") $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a Database
#
# DELETE /v2/databases/{database_cluster_uuid}/dbs/{database_name}
# operationId: databases_delete
export def "databases-delete" [
  database_cluster_uuid: string
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  if ($database_name | is-empty) { error make --unspanned { msg: "path parameter 'database_name' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), database_name: (encode-path-segment $database_name)} | format pattern "/v2/databases/{database_cluster_uuid}/dbs/{database_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Database
#
# GET /v2/databases/{database_cluster_uuid}/dbs/{database_name}
# operationId: databases_get
export def "databases-get" [
  database_cluster_uuid: string
  database_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<db: record<name: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  if ($database_name | is-empty) { error make --unspanned { msg: "path parameter 'database_name' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), database_name: (encode-path-segment $database_name)} | format pattern "/v2/databases/{database_cluster_uuid}/dbs/{database_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve the Eviction Policy for a Redis Cluster
#
# GET /v2/databases/{database_cluster_uuid}/eviction_policy
# operationId: databases_get_evictionPolicy
export def "databases-get-eviction-policy" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<eviction_policy: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/eviction_policy") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Configure the Eviction Policy for a Redis Cluster
#
# PUT /v2/databases/{database_cluster_uuid}/eviction_policy
# operationId: databases_update_evictionPolicy
export def "databases-update-eviction-policy" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  eviction_policy: string@eviction-policy-completer # A string specifying the desired eviction policy for the Redis cluster. - `noeviction`: Don't evict any data, returns error when memory limit is reached. - `allkeys_lru:` Evict any key, least recently used (LRU) first. - `allkeys_random`: Evict keys in a random order. - `volatile_lru`: Evict keys with expiration only, least recently used (LRU) first. - `volatile_random`: Evict keys with expiration only in a random order. - `volatile_ttl`: Evict keys with expiration only, shortest time-to-live (TTL) first. (e.g. allkeys_lru)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/eviction_policy") $auth.query)
  let req_body = {"eviction_policy": $eviction_policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# List Firewall Rules (Trusted Sources) for a Database Cluster
#
# GET /v2/databases/{database_cluster_uuid}/firewall
# operationId: databases_list_firewall_rules
export def "databases-list-firewall-rules" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<rules: table<cluster_uuid: string, created_at: string, type: string, uuid: string, value: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/firewall") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Firewall Rules (Trusted Sources) for a Database
#
# PUT /v2/databases/{database_cluster_uuid}/firewall
# operationId: databases_update_firewall_rules
export def "databases-update-firewall-rules" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: list # item shape: {cluster_uuid?: string, type: "droplet"|"k8s"|"ip_addr"|"tag"|"app", uuid?: string, value: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/firewall") $auth.query)
  let req_body = {"rules": $rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Configure a Database Cluster's Maintenance Window
#
# PUT /v2/databases/{database_cluster_uuid}/maintenance
# operationId: databases_update_maintenanceWindow
export def "databases-update-maintenance-window" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  day: string # The day of the week on which to apply maintenance updates. (e.g. tuesday)
  hour: string # The hour in UTC at which maintenance updates will be applied in 24 hour format. (e.g. 14:00)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/maintenance") $auth.query)
  let req_body = {"day": $day, "hour": $hour} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Migrate a Database Cluster to a New Region
#
# PUT /v2/databases/{database_cluster_uuid}/migrate
# operationId: databases_update_region
export def "databases-update-region" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  region: string # A slug identifier for the region to which the database cluster will be migrated. (e.g. lon1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/migrate") $auth.query)
  let req_body = {"region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Retrieve the Status of an Online Migration
#
# GET /v2/databases/{database_cluster_uuid}/online-migration
# operationId: databases_get_migrationStatus
export def "databases-get-migration-status" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<created_at: string, id: string, status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/online-migration") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Start an Online Migration
#
# PUT /v2/databases/{database_cluster_uuid}/online-migration
# operationId: databases_update_onlineMigration
export def "databases-update-online-migration" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --disable-ssl: oneof<nothing, bool> # Enables SSL encryption when connecting to the source database. (e.g. false)
  --source: record
]: any -> oneof<record<created_at: string, id: string, status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/online-migration") $auth.query)
  let req_body = {"disable_ssl": $disable_ssl, "source": $source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Stop an Online Migration
#
# DELETE /v2/databases/{database_cluster_uuid}/online-migration/{migration_id}
# operationId: databases_delete_onlineMigration
export def "databases-delete-online-migration" [
  database_cluster_uuid: string
  migration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  if ($migration_id | is-empty) { error make --unspanned { msg: "path parameter 'migration_id' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), migration_id: (encode-path-segment $migration_id)} | format pattern "/v2/databases/{database_cluster_uuid}/online-migration/{migration_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List Connection Pools (PostgreSQL)
#
# GET /v2/databases/{database_cluster_uuid}/pools
# operationId: databases_list_connectionPools
export def "databases-list-connection-pools" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<pools: table<connection: record, db: string, mode: string, name: string, private_connection: record, size: int, user: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/pools") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a New Connection Pool (PostgreSQL)
#
# POST /v2/databases/{database_cluster_uuid}/pools
# operationId: databases_add_connectionPool
export def "databases-add-connection-pool" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection: record
  db: string # The database for use with the connection pool. (e.g. defaultdb)
  mode: string # The PGBouncer transaction mode for the connection pool. The allowed values are session, transaction, and statement. (e.g. transaction)
  name: string # A unique name for the connection pool. Must be between 3 and 60 characters. (e.g. backend-pool)
  --private-connection: record
  size: int # The desired size of the PGBouncer connection pool. The maximum allowed size is determined by the size of the cluster's primary node. 25 backend server connections are allowed for every 1GB of RAM. Three are reserved for maintenance. For example, a primary node with 1 GB of RAM allows for a maximum of 22 backend server connections while one with 4 GB would allow for 97. Note that these are shared across all connection pools in a cluster. (format: int32, e.g. 10)
  --user: string # The name of the user for use with the connection pool. When excluded, all sessions connect to the database as the inbound user. (e.g. doadmin)
]: any -> oneof<record<pool: record<connection: record<database: string, host: string, password: string, port: int, ssl: bool, uri: string, user: string>, db: string, mode: string, name: string, private_connection: record<database: string, host: string, password: string, port: int, ssl: bool, uri: string, user: string>, size: int, user: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/pools") $auth.query)
  let req_body = {"connection": $connection, "db": $db, "mode": $mode, "name": $name, "private_connection": $private_connection, "size": $size, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a Connection Pool (PostgreSQL)
#
# DELETE /v2/databases/{database_cluster_uuid}/pools/{pool_name}
# operationId: databases_delete_connectionPool
export def "databases-delete-connection-pool" [
  database_cluster_uuid: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  if ($pool_name | is-empty) { error make --unspanned { msg: "path parameter 'pool_name' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), pool_name: (encode-path-segment $pool_name)} | format pattern "/v2/databases/{database_cluster_uuid}/pools/{pool_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve Existing Connection Pool (PostgreSQL)
#
# GET /v2/databases/{database_cluster_uuid}/pools/{pool_name}
# operationId: databases_get_connectionPool
export def "databases-get-connection-pool" [
  database_cluster_uuid: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<pool: record<connection: record<database: string, host: string, password: string, port: int, ssl: bool, uri: string, user: string>, db: string, mode: string, name: string, private_connection: record<database: string, host: string, password: string, port: int, ssl: bool, uri: string, user: string>, size: int, user: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  if ($pool_name | is-empty) { error make --unspanned { msg: "path parameter 'pool_name' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), pool_name: (encode-path-segment $pool_name)} | format pattern "/v2/databases/{database_cluster_uuid}/pools/{pool_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Connection Pools (PostgreSQL)
#
# PUT /v2/databases/{database_cluster_uuid}/pools/{pool_name}
# operationId: databases_update_connectionPool
export def "databases-update-connection-pool" [
  database_cluster_uuid: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  db: string # The database for use with the connection pool. (e.g. defaultdb)
  mode: string # The PGBouncer transaction mode for the connection pool. The allowed values are session, transaction, and statement. (e.g. transaction)
  size: int # The desired size of the PGBouncer connection pool. The maximum allowed size is determined by the size of the cluster's primary node. 25 backend server connections are allowed for every 1GB of RAM. Three are reserved for maintenance. For example, a primary node with 1 GB of RAM allows for a maximum of 22 backend server connections while one with 4 GB would allow for 97. Note that these are shared across all connection pools in a cluster. (format: int32, e.g. 10)
  --user: string # The name of the user for use with the connection pool. When excluded, all sessions connect to the database as the inbound user. (e.g. doadmin)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  if ($pool_name | is-empty) { error make --unspanned { msg: "path parameter 'pool_name' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), pool_name: (encode-path-segment $pool_name)} | format pattern "/v2/databases/{database_cluster_uuid}/pools/{pool_name}") $auth.query)
  let req_body = {"db": $db, "mode": $mode, "size": $size, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# List All Read-only Replicas
#
# GET /v2/databases/{database_cluster_uuid}/replicas
# operationId: databases_list_replicas
export def "databases-list-replicas" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<replicas: table<connection: record, created_at: string, id: string, name: string, private_connection: record, private_network_uuid: string, region: string, size: string, status: string, tags: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/replicas") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Read-only Replica
#
# POST /v2/databases/{database_cluster_uuid}/replicas
# operationId: databases_create_replica
export def "databases-create-replica" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection: record
  name: string # The name to give the read-only replicating (e.g. read-nyc3-01)
  --private-connection: record
  --private-network-uuid: string # A string specifying the UUID of the VPC to which the read-only replica will be assigned. If excluded, the replica will be assigned to your account's default VPC for the region. (e.g. 9423cbad-9211-442f-820b-ef6915e99b5f)
  --region: string # A slug identifier for the region where the read-only replica will be located. If excluded, the replica will be placed in the same region as the cluster. (e.g. nyc3)
  size: string # A slug identifier representing the size of the node for the read-only replica. The size of the replica must be at least as large as the node size for the database cluster from which it is replicating. (e.g. db-s-2vcpu-4gb)
  --tags: list<string> # A flat array of tag names as strings to apply to the read-only replica after it is created. Tag names can either be existing or new tags. (e.g. [production])
]: any -> oneof<record<replica: record<connection: record<database: string, host: string, password: string, port: int, ssl: bool, uri: string, user: string>, created_at: string, id: string, name: string, private_connection: record<database: string, host: string, password: string, port: int, ssl: bool, uri: string, user: string>, private_network_uuid: string, region: string, size: string, status: string, tags: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/replicas") $auth.query)
  let req_body = {"connection": $connection, "name": $name, "private_connection": $private_connection, "private_network_uuid": $private_network_uuid, "region": $region, "size": $size, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Destroy a Read-only Replica
#
# DELETE /v2/databases/{database_cluster_uuid}/replicas/{replica_name}
# operationId: databases_destroy_replica
export def "databases-destroy-replica" [
  database_cluster_uuid: string
  replica_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  if ($replica_name | is-empty) { error make --unspanned { msg: "path parameter 'replica_name' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), replica_name: (encode-path-segment $replica_name)} | format pattern "/v2/databases/{database_cluster_uuid}/replicas/{replica_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Read-only Replica
#
# GET /v2/databases/{database_cluster_uuid}/replicas/{replica_name}
# operationId: databases_get_replica
export def "databases-get-replica" [
  database_cluster_uuid: string
  replica_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<replica: record<connection: record<database: string, host: string, password: string, port: int, ssl: bool, uri: string, user: string>, created_at: string, id: string, name: string, private_connection: record<database: string, host: string, password: string, port: int, ssl: bool, uri: string, user: string>, private_network_uuid: string, region: string, size: string, status: string, tags: list<string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  if ($replica_name | is-empty) { error make --unspanned { msg: "path parameter 'replica_name' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), replica_name: (encode-path-segment $replica_name)} | format pattern "/v2/databases/{database_cluster_uuid}/replicas/{replica_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Promote a Read-only Replica to become a Primary Cluster
#
# PUT /v2/databases/{database_cluster_uuid}/replicas/{replica_name}/promote
# operationId: databases_promote_replica
export def "databases-promote-replica" [
  database_cluster_uuid: string
  replica_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  if ($replica_name | is-empty) { error make --unspanned { msg: "path parameter 'replica_name' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), replica_name: (encode-path-segment $replica_name)} | format pattern "/v2/databases/{database_cluster_uuid}/replicas/{replica_name}/promote") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# Resize a Database Cluster
#
# PUT /v2/databases/{database_cluster_uuid}/resize
# operationId: databases_update_clusterSize
export def "databases-update-cluster-size" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  num_nodes: int # The number of nodes in the database cluster. Valid values are are 1-3. In addition to the primary node, up to two standby nodes may be added for highly available configurations. (format: int32, e.g. 3)
  size: string # A slug identifier representing desired the size of the nodes in the database cluster. (e.g. db-s-4vcpu-8gb)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/resize") $auth.query)
  let req_body = {"num_nodes": $num_nodes, "size": $size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Retrieve the SQL Modes for a MySQL Cluster
#
# GET /v2/databases/{database_cluster_uuid}/sql_mode
# operationId: databases_get_sql_mode
export def "databases-get-sql-mode" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<sql_mode: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/sql_mode") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update SQL Mode for a Cluster
#
# PUT /v2/databases/{database_cluster_uuid}/sql_mode
# operationId: databases_update_sql_mode
export def "databases-update-sql-mode" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  sql_mode: string # A string specifying the configured SQL modes for the MySQL cluster. (e.g. ANSI,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION,NO_ZERO_DATE,NO_ZERO_IN_DATE,STRICT_ALL_TABLES)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/sql_mode") $auth.query)
  let req_body = {"sql_mode": $sql_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Upgrade Major Version for a Database
#
# PUT /v2/databases/{database_cluster_uuid}/upgrade
# operationId: databases_update_major_version
export def "databases-update-major-version" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # A string representing the version of the database engine in use for the cluster. (e.g. 10)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/upgrade") $auth.query)
  let req_body = {"version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# List all Database Users
#
# GET /v2/databases/{database_cluster_uuid}/users
# operationId: databases_list_users
export def "databases-list-users" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<users: table<mysql_settings: record, name: string, password: string, role: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/users") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a Database User
#
# POST /v2/databases/{database_cluster_uuid}/users
# operationId: databases_add_user
export def "databases-add-user" [
  database_cluster_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mysql-settings: record # shape: {auth_plugin: "mysql_native_password"|"caching_sha2_password"}
  name: string # The name of a database user. (e.g. app-01)
]: any -> oneof<record<user: record<mysql_settings: record<auth_plugin: string>, name: string, password: string, role: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid)} | format pattern "/v2/databases/{database_cluster_uuid}/users") $auth.query)
  let req_body = {"mysql_settings": $mysql_settings, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Remove a Database User
#
# DELETE /v2/databases/{database_cluster_uuid}/users/{username}
# operationId: databases_delete_user
export def "databases-delete-user" [
  database_cluster_uuid: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), username: (encode-path-segment $username)} | format pattern "/v2/databases/{database_cluster_uuid}/users/{username}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Database User
#
# GET /v2/databases/{database_cluster_uuid}/users/{username}
# operationId: databases_get_user
export def "databases-get-user" [
  database_cluster_uuid: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<user: record<mysql_settings: record<auth_plugin: string>, name: string, password: string, role: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), username: (encode-path-segment $username)} | format pattern "/v2/databases/{database_cluster_uuid}/users/{username}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Reset a Database User's Password or Authentication Method
#
# POST /v2/databases/{database_cluster_uuid}/users/{username}/reset_auth
# operationId: databases_reset_auth
export def "databases-reset-auth" [
  database_cluster_uuid: string
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mysql-settings: record # shape: {auth_plugin: "mysql_native_password"|"caching_sha2_password"}
]: any -> oneof<record<user: record<mysql_settings: record<auth_plugin: string>, name: string, password: string, role: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($database_cluster_uuid | is-empty) { error make --unspanned { msg: "path parameter 'database_cluster_uuid' must be non-empty" } }
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let full_url = (build-url $base ({database_cluster_uuid: (encode-path-segment $database_cluster_uuid), username: (encode-path-segment $username)} | format pattern "/v2/databases/{database_cluster_uuid}/users/{username}/reset_auth") $auth.query)
  let req_body = {"mysql_settings": $mysql_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List All Domains
#
# GET /v2/domains
# operationId: domains_list
export def "domains-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<domains: table<ip_address: string, name: string, ttl: int, zone_file: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/domains" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New Domain
#
# POST /v2/domains
# operationId: domains_create
export def "domains-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip-address: string # This optional attribute may contain an IP address. When provided, an A record will be automatically created pointing to the apex domain. (e.g. 192.0.2.1)
  --name: string # The name of the domain itself. This should follow the standard domain format of domain.TLD. For instance, `example.com` is a valid domain name. (e.g. example.com)
]: any -> oneof<record<domain: record<ip_address: string, name: string, ttl: int, zone_file: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/domains" $auth.query)
  let req_body = {"ip_address": $ip_address, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a Domain
#
# DELETE /v2/domains/{domain_name}
# operationId: domains_delete
export def "domains-delete" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v2/domains/{domain_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Domain
#
# GET /v2/domains/{domain_name}
# operationId: domains_get
export def "domains-get" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<domain: record<ip_address: string, name: string, ttl: int, zone_file: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v2/domains/{domain_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Domain Records
#
# GET /v2/domains/{domain_name}/records
# operationId: domains_list_records
export def "domains-list-records" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A fully qualified record name. For example, to only include records matching sub.example.com, send a GET request to `/v2/domains/$DOMAIN_NAME/records?name=sub.example.com`. (e.g. sub.example.com)
  --type: string@type-completer-3 # The type of the DNS record. For example: A, CNAME, TXT, ... (e.g. A)
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<domain_records: table<data: string, flags: int, id: int, name: string, port: int, priority: int, tag: string, ttl: int, type: string, weight: int>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v2/domains/{domain_name}/records") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "type": $type, "per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New Domain Record
#
# POST /v2/domains/{domain_name}/records
# Discriminator (request): type = A, AAAA, CAA, CNAME, MX, NS, SOA, SRV, TXT
# operationId: domains_create_record
export def "domains-create-record" [
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Variable data depending on record type. For example, the "data" value for an A record would be the IPv4 address to which the domain will be mapped. For a CAA record, it would contain the domain name of the CA being granted permission to issue certificates. (e.g. ns1.digitalocean.com)
  --flags: int # An unsigned integer between 0-255 used for CAA records. (nullable)
  --name: string # The host name, alias, or service being defined by the record. (e.g. @)
  --port: int # The port for SRV records. (nullable)
  --priority: int # The priority for SRV and MX records. (nullable)
  --tag: string # The parameter tag for CAA records. Valid values are "issue", "issuewild", or "iodef" (nullable)
  --ttl: int # This value is the time to live for the record, in seconds. This defines the time frame that clients can cache queried information before a refresh should be requested. (e.g. 1800)
  type: string@type-completer-3 # The type of the DNS record. For example: A, CNAME, TXT, ... (e.g. NS)
  --weight: int # The weight for SRV records. (nullable)
]: any -> oneof<record<domain_record: record<data: string, flags: int, id: int, name: string, port: int, priority: int, tag: string, ttl: int, type: string, weight: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name)} | format pattern "/v2/domains/{domain_name}/records") $auth.query)
  let req_body = {"data": $data, "flags": $flags, "name": $name, "port": $port, "priority": $priority, "tag": $tag, "ttl": $ttl, "type": $type, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a Domain Record
#
# DELETE /v2/domains/{domain_name}/records/{domain_record_id}
# operationId: domains_delete_record
export def "domains-delete-record" [
  domain_name: string
  domain_record_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  if ($domain_record_id | is-empty) { error make --unspanned { msg: "path parameter 'domain_record_id' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), domain_record_id: (encode-path-segment $domain_record_id)} | format pattern "/v2/domains/{domain_name}/records/{domain_record_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Domain Record
#
# GET /v2/domains/{domain_name}/records/{domain_record_id}
# operationId: domains_get_record
export def "domains-get-record" [
  domain_name: string
  domain_record_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<domain_record: record<data: string, flags: int, id: int, name: string, port: int, priority: int, tag: string, ttl: int, type: string, weight: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  if ($domain_record_id | is-empty) { error make --unspanned { msg: "path parameter 'domain_record_id' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), domain_record_id: (encode-path-segment $domain_record_id)} | format pattern "/v2/domains/{domain_name}/records/{domain_record_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a Domain Record
#
# PATCH /v2/domains/{domain_name}/records/{domain_record_id}
# operationId: domains_patch_record
export def "domains-patch-record" [
  domain_name: string
  domain_record_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Variable data depending on record type. For example, the "data" value for an A record would be the IPv4 address to which the domain will be mapped. For a CAA record, it would contain the domain name of the CA being granted permission to issue certificates. (e.g. ns1.digitalocean.com)
  --flags: int # An unsigned integer between 0-255 used for CAA records. (nullable)
  --name: string # The host name, alias, or service being defined by the record. (e.g. @)
  --port: int # The port for SRV records. (nullable)
  --priority: int # The priority for SRV and MX records. (nullable)
  --tag: string # The parameter tag for CAA records. Valid values are "issue", "issuewild", or "iodef" (nullable)
  --ttl: int # This value is the time to live for the record, in seconds. This defines the time frame that clients can cache queried information before a refresh should be requested. (e.g. 1800)
  type: string # The type of the DNS record. For example: A, CNAME, TXT, ... (e.g. NS)
  --weight: int # The weight for SRV records. (nullable)
]: any -> oneof<record<domain_record: record<data: string, flags: int, id: int, name: string, port: int, priority: int, tag: string, ttl: int, type: string, weight: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  if ($domain_record_id | is-empty) { error make --unspanned { msg: "path parameter 'domain_record_id' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), domain_record_id: (encode-path-segment $domain_record_id)} | format pattern "/v2/domains/{domain_name}/records/{domain_record_id}") $auth.query)
  let req_body = {"data": $data, "flags": $flags, "name": $name, "port": $port, "priority": $priority, "tag": $tag, "ttl": $ttl, "type": $type, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update a Domain Record
#
# PUT /v2/domains/{domain_name}/records/{domain_record_id}
# operationId: domains_update_record
export def "domains-update-record" [
  domain_name: string
  domain_record_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # Variable data depending on record type. For example, the "data" value for an A record would be the IPv4 address to which the domain will be mapped. For a CAA record, it would contain the domain name of the CA being granted permission to issue certificates. (e.g. ns1.digitalocean.com)
  --flags: int # An unsigned integer between 0-255 used for CAA records. (nullable)
  --name: string # The host name, alias, or service being defined by the record. (e.g. @)
  --port: int # The port for SRV records. (nullable)
  --priority: int # The priority for SRV and MX records. (nullable)
  --tag: string # The parameter tag for CAA records. Valid values are "issue", "issuewild", or "iodef" (nullable)
  --ttl: int # This value is the time to live for the record, in seconds. This defines the time frame that clients can cache queried information before a refresh should be requested. (e.g. 1800)
  type: string # The type of the DNS record. For example: A, CNAME, TXT, ... (e.g. NS)
  --weight: int # The weight for SRV records. (nullable)
]: any -> oneof<record<domain_record: record<data: string, flags: int, id: int, name: string, port: int, priority: int, tag: string, ttl: int, type: string, weight: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domain_name' must be non-empty" } }
  if ($domain_record_id | is-empty) { error make --unspanned { msg: "path parameter 'domain_record_id' must be non-empty" } }
  let full_url = (build-url $base ({domain_name: (encode-path-segment $domain_name), domain_record_id: (encode-path-segment $domain_record_id)} | format pattern "/v2/domains/{domain_name}/records/{domain_record_id}") $auth.query)
  let req_body = {"data": $data, "flags": $flags, "name": $name, "port": $port, "priority": $priority, "tag": $tag, "ttl": $ttl, "type": $type, "weight": $weight} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deleting Droplets by Tag
#
# DELETE /v2/droplets
# operationId: droplets_destroy_byTag
export def "droplets-destroy-by-tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-name: string # Specifies Droplets to be deleted by tag. (required, e.g. env:test)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_name == null) { error make --unspanned { msg: "required query parameter 'tag_name' missing: pass --tag-name" } }
  let qp = [(serialize-qp "tag_name" $tag_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/droplets" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"tag_name": $tag_name} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List All Droplets
#
# GET /v2/droplets
# operationId: droplets_list
export def "droplets-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
  --tag-name: string # Used to filter Droplets by a specific tag. Can not be combined with `name`. (e.g. env:prod)
  --name: string # Used to filter list response by Droplet name returning only exact matches. It is case-insensitive and can not be combined with `tag_name`. (e.g. web-01)
]: nothing -> oneof<record<droplets: table<backup_ids: list, created_at: string, disk: int, features: list, id: int, image: record, kernel: record, locked: bool, memory: int, name: string, networks: record, next_backup_window: record, region: record, size: record, size_slug: string, snapshot_ids: list, status: string, tags: list, vcpus: int, volume_ids: list, vpc_uuid: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "tag_name" $tag_name "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/droplets" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page, "tag_name": $tag_name, "name": $name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New Droplet
#
# POST /v2/droplets
# operationId: droplets_create
@deprecated --flag private-networking
export def "droplets-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The human-readable string you wish to use when displaying the Droplet name. The name, if set to a domain name managed in the DigitalOcean DNS management system, will configure a PTR record for the Droplet. The name set during creation will also determine the hostname for the Droplet in its internal configuration. (e.g. example.com)
  --backups: oneof<nothing, bool> # A boolean indicating whether automated backups should be enabled for the Droplet. (default: false, e.g. true)
  image: any # The image ID of a public or private image or the slug identifier for a public image. This image will be the base image for your Droplet. (e.g. ubuntu-20-04-x64)
  --ipv6: oneof<nothing, bool> # A boolean indicating whether to enable IPv6 on the Droplet. (default: false, e.g. true)
  --monitoring: oneof<nothing, bool> # A boolean indicating whether to install the DigitalOcean agent for monitoring. (default: false, e.g. true)
  --private-networking: oneof<nothing, bool> # This parameter has been deprecated. Use `vpc_uuid` instead to specify a VPC network for the Droplet. If no `vpc_uuid` is provided, the Droplet will be placed in your account's default VPC for the region. (DEPRECATED, default: false, e.g. true)
  --region: string # The slug identifier for the region that you wish to deploy the Droplet in. If the specific datacenter is not not important, a slug prefix (e.g. `nyc`) can be used to deploy the Droplet in any of the that region's locations (`nyc1`, `nyc2`, or `nyc3`). If the region is omitted from the create request completely, the Droplet may deploy in any region. (e.g. nyc3)
  size: string # The slug identifier for the size that you wish to select for this Droplet. (e.g. s-1vcpu-1gb)
  --ssh-keys: list # An array containing the IDs or fingerprints of the SSH keys that you wish to embed in the Droplet's root account upon creation. (default: [], e.g. [289794, 3b:16:e4:bf:8b:00:8b:b8:59:8c:a9:d3:f0:19:fa:45])
  --tags: list<string> # A flat array of tag names as strings to apply to the Droplet after it is created. Tag names can either be existing or new tags. (nullable, default: [], e.g. [env:prod, web])
  --user-data: string # A string containing 'user data' which may be used to configure the Droplet on first boot, often a 'cloud-config' file or Bash script. It must be plain text and may not exceed 64 KiB in size. (e.g. #cloud-config runcmd:   - touch /test.txt )
  --volumes: list<string> # An array of IDs for block storage volumes that will be attached to the Droplet once created. The volumes must not already be attached to an existing Droplet. (default: [], e.g. [12e97116-7280-11ed-b3d0-0a58ac146812])
  --vpc-uuid: string # A string specifying the UUID of the VPC to which the Droplet will be assigned. If excluded, the Droplet will be assigned to your account's default VPC for the region. (e.g. 760e09ef-dc84-11e8-981e-3cfdfeaae000)
  --with-droplet-agent: oneof<nothing, bool> # A boolean indicating whether to install the DigitalOcean agent used for providing access to the Droplet web console in the control panel. By default, the agent is installed on new Droplets but installation errors (i.e. OS not supported) are ignored. To prevent it from being installed, set to `false`. To make installation errors fatal, explicitly set it to `true`. (e.g. true)
  --names: list<string> # An array of human human-readable strings you wish to use when displaying the Droplet name. Each name, if set to a domain name managed in the DigitalOcean DNS management system, will configure a PTR record for the Droplet. Each name set during creation will also determine the hostname for the Droplet in its internal configuration. (e.g. [sub-01.example.com, sub-02.example.com])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/droplets" $auth.query)
  let req_body = {"name": $name, "backups": $backups, "image": $image, "ipv6": $ipv6, "monitoring": $monitoring, "private_networking": $private_networking, "region": $region, "size": $size, "ssh_keys": $ssh_keys, "tags": $tags, "user_data": $user_data, "volumes": $volumes, "vpc_uuid": $vpc_uuid, "with_droplet_agent": $with_droplet_agent, "names": $names} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Acting on Tagged Droplets
#
# POST /v2/droplets/actions
# Discriminator (request): type = disable_backups, enable_backups, enable_ipv6, power_cycle, power_off, power_on, shutdown, snapshot
# operationId: dropletActions_post_byTag
export def "droplet-actions-post-by-tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag-name: string # Used to filter Droplets by a specific tag. Can not be combined with `name`. (e.g. env:prod)
  type: string@type-completer-4 # The type of action to initiate for the Droplet. (e.g. reboot)
  --name: string # The name to give the new snapshot of the Droplet. (e.g. Nifty New Snapshot)
]: any -> oneof<record<actions: table<completed_at: string, id: int, region: record, region_slug: string, resource_id: int, resource_type: string, started_at: string, status: string, type: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag_name" $tag_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/droplets/actions" $qp $auth.query)
  let req_body = {"type": $type, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"tag_name": $tag_name} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete an Existing Droplet
#
# DELETE /v2/droplets/{droplet_id}
# operationId: droplets_destroy
export def "droplets-destroy" [
  droplet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($droplet_id | is-empty) { error make --unspanned { msg: "path parameter 'droplet_id' must be non-empty" } }
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Droplet
#
# GET /v2/droplets/{droplet_id}
# operationId: droplets_get
export def "droplets-get" [
  droplet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<droplet: record<backup_ids: list<int>, created_at: string, disk: int, features: list<string>, id: int, image: record<created_at: string, description: string, distribution: string, error_message: string, id: int, min_disk_size: int, name: string, public: bool, regions: list, size_gigabytes: float, slug: string, status: string, tags: list, type: string>, kernel: record<id: int, name: string, version: string>, locked: bool, memory: int, name: string, networks: record<v4: list, v6: list>, next_backup_window: record<end: string, start: string>, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, size: record<available: bool, description: string, disk: int, memory: int, price_hourly: float, price_monthly: float, regions: list, slug: string, transfer: float, vcpus: int>, size_slug: string, snapshot_ids: list<int>, status: string, tags: list<string>, vcpus: int, volume_ids: list<string>, vpc_uuid: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($droplet_id | is-empty) { error make --unspanned { msg: "path parameter 'droplet_id' must be non-empty" } }
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Actions for a Droplet
#
# GET /v2/droplets/{droplet_id}/actions
# operationId: dropletActions_list
export def "droplet-actions-list" [
  droplet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<actions: table<completed_at: string, id: int, region: record, region_slug: string, resource_id: int, resource_type: string, started_at: string, status: string, type: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($droplet_id | is-empty) { error make --unspanned { msg: "path parameter 'droplet_id' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/actions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Initiate a Droplet Action
#
# POST /v2/droplets/{droplet_id}/actions
# Discriminator (request): type = change_kernel, disable_backups, enable_backups, enable_ipv6, password_reset, power_cycle, power_off, power_on, reboot, rebuild, rename, resize, restore, shutdown, snapshot
# operationId: dropletActions_post
export def "droplet-actions-post" [
  droplet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-5 # The type of action to initiate for the Droplet. (e.g. reboot)
  --image: int # The ID of a backup of the current Droplet instance to restore from. (e.g. 12389723)
  --disk: oneof<nothing, bool> # When `true`, the Droplet's disk will be resized in addition to its RAM and CPU. This is a permanent change and cannot be reversed as a Droplet's disk size cannot be decreased. (e.g. true)
  --size: string # The slug identifier for the size to which you wish to resize the Droplet. (e.g. s-2vcpu-2gb)
  --name: string # The new name for the Droplet. (e.g. nifty-new-name)
  --kernel: int # A unique number used to identify and reference a specific kernel. (e.g. 12389723)
]: any -> oneof<record<action: record<completed_at: string, id: int, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, region_slug: string, resource_id: int, resource_type: string, started_at: string, status: string, type: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($droplet_id | is-empty) { error make --unspanned { msg: "path parameter 'droplet_id' must be non-empty" } }
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/actions") $auth.query)
  let req_body = {"type": $type, "image": $image, "disk": $disk, "size": $size, "name": $name, "kernel": $kernel} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve a Droplet Action
#
# GET /v2/droplets/{droplet_id}/actions/{action_id}
# operationId: dropletActions_get
export def "droplet-actions-get" [
  droplet_id: int
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<action: record<completed_at: string, id: int, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, region_slug: string, resource_id: int, resource_type: string, started_at: string, status: string, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($droplet_id | is-empty) { error make --unspanned { msg: "path parameter 'droplet_id' must be non-empty" } }
  if ($action_id | is-empty) { error make --unspanned { msg: "path parameter 'action_id' must be non-empty" } }
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id), action_id: (encode-path-segment $action_id)} | format pattern "/v2/droplets/{droplet_id}/actions/{action_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Backups for a Droplet
#
# GET /v2/droplets/{droplet_id}/backups
# operationId: droplets_list_backups
export def "droplets-list-backups" [
  droplet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<backups: table<id: int, created_at: string, min_disk_size: int, name: string, regions: list, size_gigabytes: float, type: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($droplet_id | is-empty) { error make --unspanned { msg: "path parameter 'droplet_id' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/backups") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Associated Resources for a Droplet
#
# GET /v2/droplets/{droplet_id}/destroy_with_associated_resources
# operationId: droplets_list_associatedResources
export def "droplets-list-associated-resources" [
  droplet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<floating_ips: table<cost: string, id: string, name: string>, reserved_ips: table<cost: string, id: string, name: string>, snapshots: table<cost: string, id: string, name: string>, volume_snapshots: table<cost: string, id: string, name: string>, volumes: table<cost: string, id: string, name: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($droplet_id | is-empty) { error make --unspanned { msg: "path parameter 'droplet_id' must be non-empty" } }
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/destroy_with_associated_resources") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Destroy a Droplet and All of its Associated Resources (Dangerous)
#
# DELETE /v2/droplets/{droplet_id}/destroy_with_associated_resources/dangerous
# operationId: droplets_destroy_withAssociatedResourcesDangerous
export def "droplets-destroy-with-associated-resources-dangerous" [
  droplet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-dangerous: oneof<nothing, bool> # Acknowledge this action will destroy the Droplet and all associated resources and _can not_ be reversed. (required, e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($droplet_id | is-empty) { error make --unspanned { msg: "path parameter 'droplet_id' must be non-empty" } }
  if ($x_dangerous == null) { error make --unspanned { msg: "required header parameter 'X-Dangerous' missing: pass --x-dangerous" } }
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/destroy_with_associated_resources/dangerous") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Dangerous": $x_dangerous} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Retry a Droplet Destroy with Associated Resources Request
#
# POST /v2/droplets/{droplet_id}/destroy_with_associated_resources/retry
# operationId: droplets_destroy_retryWithAssociatedResources
export def "droplets-destroy-retry-with-associated-resources" [
  droplet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($droplet_id | is-empty) { error make --unspanned { msg: "path parameter 'droplet_id' must be non-empty" } }
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/destroy_with_associated_resources/retry") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [202]
}

# Selectively Destroy a Droplet and its Associated Resources
#
# DELETE /v2/droplets/{droplet_id}/destroy_with_associated_resources/selective
# operationId: droplets_destroy_withAssociatedResourcesSelective
@deprecated --flag floating-ips
export def "droplets-destroy-with-associated-resources-selective" [
  droplet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --floating-ips: list<string> # An array of unique identifiers for the floating IPs to be scheduled for deletion. (DEPRECATED, e.g. [6186916])
  --reserved-ips: list<string> # An array of unique identifiers for the reserved IPs to be scheduled for deletion. (e.g. [6186916])
  --snapshots: list<string> # An array of unique identifiers for the snapshots to be scheduled for deletion. (e.g. [61486916])
  --volume-snapshots: list<string> # An array of unique identifiers for the volume snapshots to be scheduled for deletion. (e.g. [edb0478d-7436-11ea-86e6-0a58ac144b91])
  --volumes: list<string> # An array of unique identifiers for the volumes to be scheduled for deletion. (e.g. [ba49449a-7435-11ea-b89e-0a58ac14480f])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($droplet_id | is-empty) { error make --unspanned { msg: "path parameter 'droplet_id' must be non-empty" } }
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/destroy_with_associated_resources/selective") $auth.query)
  let req_body = {"floating_ips": $floating_ips, "reserved_ips": $reserved_ips, "snapshots": $snapshots, "volume_snapshots": $volume_snapshots, "volumes": $volumes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [202]
}

# Check Status of a Droplet Destroy with Associated Resources Request
#
# GET /v2/droplets/{droplet_id}/destroy_with_associated_resources/status
# operationId: droplets_get_DestroyAssociatedResourcesStatus
export def "droplets-get-destroy-associated-resources-status" [
  droplet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<completed_at: string, droplet: record<destroyed_at: string, error_message: string, id: string, name: string>, failures: int, resources: record<floating_ips: list<record>, reserved_ips: list<record>, snapshots: list<record>, volume_snapshots: list<record>, volumes: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($droplet_id | is-empty) { error make --unspanned { msg: "path parameter 'droplet_id' must be non-empty" } }
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/destroy_with_associated_resources/status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all Firewalls Applied to a Droplet
#
# GET /v2/droplets/{droplet_id}/firewalls
# operationId: droplets_list_firewalls
export def "droplets-list-firewalls" [
  droplet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<firewalls: table<created_at: string, droplet_ids: list, id: string, name: string, pending_changes: list, status: string, tags: list, inbound_rules: list, outbound_rules: list>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($droplet_id | is-empty) { error make --unspanned { msg: "path parameter 'droplet_id' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/firewalls") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Available Kernels for a Droplet
#
# GET /v2/droplets/{droplet_id}/kernels
# operationId: droplets_list_kernels
export def "droplets-list-kernels" [
  droplet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<kernels: table<id: int, name: string, version: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($droplet_id | is-empty) { error make --unspanned { msg: "path parameter 'droplet_id' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/kernels") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Neighbors for a Droplet
#
# GET /v2/droplets/{droplet_id}/neighbors
# operationId: droplets_list_neighbors
export def "droplets-list-neighbors" [
  droplet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<droplets: table<backup_ids: list, created_at: string, disk: int, features: list, id: int, image: record, kernel: record, locked: bool, memory: int, name: string, networks: record, next_backup_window: record, region: record, size: record, size_slug: string, snapshot_ids: list, status: string, tags: list, vcpus: int, volume_ids: list, vpc_uuid: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($droplet_id | is-empty) { error make --unspanned { msg: "path parameter 'droplet_id' must be non-empty" } }
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/neighbors") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Snapshots for a Droplet
#
# GET /v2/droplets/{droplet_id}/snapshots
# operationId: droplets_list_snapshots
export def "droplets-list-snapshots" [
  droplet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<snapshots: table<id: int, created_at: string, min_disk_size: int, name: string, regions: list, size_gigabytes: float, type: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($droplet_id | is-empty) { error make --unspanned { msg: "path parameter 'droplet_id' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({droplet_id: (encode-path-segment $droplet_id)} | format pattern "/v2/droplets/{droplet_id}/snapshots") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Firewalls
#
# GET /v2/firewalls
# operationId: firewalls_list
export def "firewalls-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<firewalls: table<created_at: string, droplet_ids: list, id: string, name: string, pending_changes: list, status: string, tags: list, inbound_rules: list, outbound_rules: list>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/firewalls" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New Firewall
#
# POST /v2/firewalls
# operationId: firewalls_create
export def "firewalls-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --droplet-ids: list<int> # An array containing the IDs of the Droplets assigned to the firewall. (nullable, e.g. [8043964])
  name: string # A human-readable name for a firewall. The name must begin with an alphanumeric character. Subsequent characters must either be alphanumeric characters, a period (.), or a dash (-). (e.g. firewall)
  --tags: list<string> # A flat array of tag names as strings to be applied to the resource. Tag names may be for either existing or new tags. (nullable)
  --inbound-rules: list # nullable — item shape: {ports: string, protocol: "tcp"|"udp"|"icmp", sources: record}
  --outbound-rules: list # nullable — item shape: {ports: string, protocol: "tcp"|"udp"|"icmp", destinations: record}
]: any -> oneof<record<firewall: record<created_at: string, droplet_ids: list<int>, id: string, name: string, pending_changes: list<record>, status: string, tags: list<string>, inbound_rules: list<record>, outbound_rules: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/firewalls" $auth.query)
  let req_body = {"droplet_ids": $droplet_ids, "name": $name, "tags": $tags, "inbound_rules": $inbound_rules, "outbound_rules": $outbound_rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Delete a Firewall
#
# DELETE /v2/firewalls/{firewall_id}
# operationId: firewalls_delete
export def "firewalls-delete" [
  firewall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($firewall_id | is-empty) { error make --unspanned { msg: "path parameter 'firewall_id' must be non-empty" } }
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Firewall
#
# GET /v2/firewalls/{firewall_id}
# operationId: firewalls_get
export def "firewalls-get" [
  firewall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<firewall: record<created_at: string, droplet_ids: list<int>, id: string, name: string, pending_changes: list<record>, status: string, tags: list<string>, inbound_rules: list<record>, outbound_rules: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($firewall_id | is-empty) { error make --unspanned { msg: "path parameter 'firewall_id' must be non-empty" } }
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a Firewall
#
# PUT /v2/firewalls/{firewall_id}
# operationId: firewalls_update
export def "firewalls-update" [
  firewall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --droplet-ids: list<int> # An array containing the IDs of the Droplets assigned to the firewall. (nullable, e.g. [8043964])
  name: string # A human-readable name for a firewall. The name must begin with an alphanumeric character. Subsequent characters must either be alphanumeric characters, a period (.), or a dash (-). (e.g. firewall)
  --tags: list<string> # A flat array of tag names as strings to be applied to the resource. Tag names may be for either existing or new tags. (nullable)
  --inbound-rules: list # nullable — item shape: {ports: string, protocol: "tcp"|"udp"|"icmp", sources: record}
  --outbound-rules: list # nullable — item shape: {ports: string, protocol: "tcp"|"udp"|"icmp", destinations: record}
]: any -> oneof<record<firewall: record<created_at: string, droplet_ids: list<int>, id: string, name: string, pending_changes: list<record>, status: string, tags: list<string>, inbound_rules: list<record>, outbound_rules: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($firewall_id | is-empty) { error make --unspanned { msg: "path parameter 'firewall_id' must be non-empty" } }
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}") $auth.query)
  let req_body = {"droplet_ids": $droplet_ids, "name": $name, "tags": $tags, "inbound_rules": $inbound_rules, "outbound_rules": $outbound_rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Remove Droplets from a Firewall
#
# DELETE /v2/firewalls/{firewall_id}/droplets
# operationId: firewalls_delete_droplets
export def "firewalls-delete-droplets" [
  firewall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  droplet_ids: list<int> # An array containing the IDs of the Droplets to be removed from the firewall. (e.g. [49696269])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($firewall_id | is-empty) { error make --unspanned { msg: "path parameter 'firewall_id' must be non-empty" } }
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}/droplets") $auth.query)
  let req_body = {"droplet_ids": $droplet_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [204]
}

# Add Droplets to a Firewall
#
# POST /v2/firewalls/{firewall_id}/droplets
# operationId: firewalls_assign_droplets
export def "firewalls-assign-droplets" [
  firewall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  droplet_ids: list<int> # An array containing the IDs of the Droplets to be assigned to the firewall. (e.g. [49696269])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($firewall_id | is-empty) { error make --unspanned { msg: "path parameter 'firewall_id' must be non-empty" } }
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}/droplets") $auth.query)
  let req_body = {"droplet_ids": $droplet_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Remove Rules from a Firewall
#
# DELETE /v2/firewalls/{firewall_id}/rules
# operationId: firewalls_delete_rules
export def "firewalls-delete-rules" [
  firewall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --inbound-rules: list # nullable — item shape: {ports: string, protocol: "tcp"|"udp"|"icmp", sources: record}
  --outbound-rules: list # nullable — item shape: {ports: string, protocol: "tcp"|"udp"|"icmp", destinations: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($firewall_id | is-empty) { error make --unspanned { msg: "path parameter 'firewall_id' must be non-empty" } }
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}/rules") $auth.query)
  let req_body = {"inbound_rules": $inbound_rules, "outbound_rules": $outbound_rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [204]
}

# Add Rules to a Firewall
#
# POST /v2/firewalls/{firewall_id}/rules
# operationId: firewalls_add_rules
export def "firewalls-add-rules" [
  firewall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --inbound-rules: list # nullable — item shape: {ports: string, protocol: "tcp"|"udp"|"icmp", sources: record}
  --outbound-rules: list # nullable — item shape: {ports: string, protocol: "tcp"|"udp"|"icmp", destinations: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($firewall_id | is-empty) { error make --unspanned { msg: "path parameter 'firewall_id' must be non-empty" } }
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}/rules") $auth.query)
  let req_body = {"inbound_rules": $inbound_rules, "outbound_rules": $outbound_rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Remove Tags from a Firewall
#
# DELETE /v2/firewalls/{firewall_id}/tags
# operationId: firewalls_delete_tags
export def "firewalls-delete-tags" [
  firewall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: list<string> # A flat array of tag names as strings to be applied to the resource. Tag names may be for either existing or new tags. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($firewall_id | is-empty) { error make --unspanned { msg: "path parameter 'firewall_id' must be non-empty" } }
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}/tags") $auth.query)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [204]
}

# Add Tags to a Firewall
#
# POST /v2/firewalls/{firewall_id}/tags
# operationId: firewalls_add_tags
export def "firewalls-add-tags" [
  firewall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: list<string> # A flat array of tag names as strings to be applied to the resource. Tag names may be for either existing or new tags. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($firewall_id | is-empty) { error make --unspanned { msg: "path parameter 'firewall_id' must be non-empty" } }
  let full_url = (build-url $base ({firewall_id: (encode-path-segment $firewall_id)} | format pattern "/v2/firewalls/{firewall_id}/tags") $auth.query)
  let req_body = {"tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# List All Floating IPs
#
# GET /v2/floating_ips
# operationId: floatingIPs_list
export def "floating-i-ps-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<floating_ips: table<droplet: any, ip: string, locked: bool, project_id: string, region: record>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/floating_ips" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New Floating IP
#
# POST /v2/floating_ips
# operationId: floatingIPs_create
export def "floating-i-ps-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --droplet-id: int # The ID of the Droplet that the floating IP will be assigned to. (e.g. 2457247)
  --project-id: string # The UUID of the project to which the floating IP will be assigned. (format: uuid, e.g. 746c6152-2fa2-11ed-92d3-27aaa54e4988)
  --region: string # The slug identifier for the region the floating IP will be reserved to. (e.g. nyc3)
]: any -> oneof<record<floating_ip: record<droplet: any, ip: string, locked: bool, project_id: string, region: record<available: bool, features: list, name: string, sizes: list, slug: string>>, links: record<actions: list<record>, droplets: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/floating_ips" $auth.query)
  let req_body = {"droplet_id": $droplet_id, "project_id": $project_id, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Delete a Floating IP
#
# DELETE /v2/floating_ips/{floating_ip}
# operationId: floatingIPs_delete
export def "floating-i-ps-delete" [
  floating_ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($floating_ip | is-empty) { error make --unspanned { msg: "path parameter 'floating_ip' must be non-empty" } }
  let full_url = (build-url $base ({floating_ip: (encode-path-segment $floating_ip)} | format pattern "/v2/floating_ips/{floating_ip}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Floating IP
#
# GET /v2/floating_ips/{floating_ip}
# operationId: floatingIPs_get
export def "floating-i-ps-get" [
  floating_ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<floating_ip: record<droplet: any, ip: string, locked: bool, project_id: string, region: record<available: bool, features: list, name: string, sizes: list, slug: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($floating_ip | is-empty) { error make --unspanned { msg: "path parameter 'floating_ip' must be non-empty" } }
  let full_url = (build-url $base ({floating_ip: (encode-path-segment $floating_ip)} | format pattern "/v2/floating_ips/{floating_ip}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Actions for a Floating IP
#
# GET /v2/floating_ips/{floating_ip}/actions
# operationId: floatingIPsAction_list
export def "floating-i-ps-action-list" [
  floating_ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<actions: table<completed_at: string, id: int, region: record, region_slug: string, resource_id: int, resource_type: string, started_at: string, status: string, type: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($floating_ip | is-empty) { error make --unspanned { msg: "path parameter 'floating_ip' must be non-empty" } }
  let full_url = (build-url $base ({floating_ip: (encode-path-segment $floating_ip)} | format pattern "/v2/floating_ips/{floating_ip}/actions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Initiate a Floating IP Action
#
# POST /v2/floating_ips/{floating_ip}/actions
# Discriminator (request): type = assign, unassign
# operationId: floatingIPsAction_post
export def "floating-i-ps-action-post" [
  floating_ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-6 # The type of action to initiate for the floating IP.
  --droplet-id: int # The ID of the Droplet that the floating IP will be assigned to. (e.g. 758604968)
]: any -> oneof<record<action: record<completed_at: string, id: int, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, region_slug: string, resource_id: int, resource_type: string, started_at: string, status: string, type: string, project_id: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($floating_ip | is-empty) { error make --unspanned { msg: "path parameter 'floating_ip' must be non-empty" } }
  let full_url = (build-url $base ({floating_ip: (encode-path-segment $floating_ip)} | format pattern "/v2/floating_ips/{floating_ip}/actions") $auth.query)
  let req_body = {"type": $type, "droplet_id": $droplet_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve an Existing Floating IP Action
#
# GET /v2/floating_ips/{floating_ip}/actions/{action_id}
# operationId: floatingIPsAction_get
export def "floating-i-ps-action-get" [
  floating_ip: string
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<action: record<completed_at: string, id: int, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, region_slug: string, resource_id: int, resource_type: string, started_at: string, status: string, type: string, project_id: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($floating_ip | is-empty) { error make --unspanned { msg: "path parameter 'floating_ip' must be non-empty" } }
  if ($action_id | is-empty) { error make --unspanned { msg: "path parameter 'action_id' must be non-empty" } }
  let full_url = (build-url $base ({floating_ip: (encode-path-segment $floating_ip), action_id: (encode-path-segment $action_id)} | format pattern "/v2/floating_ips/{floating_ip}/actions/{action_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Namespaces
#
# GET /v2/functions/namespaces
# operationId: functions_list_namespaces
export def "functions-list-namespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<namespaces: table<api_host: string, created_at: string, key: string, label: string, namespace: string, region: string, updated_at: string, uuid: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/functions/namespaces" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create Namespace
#
# POST /v2/functions/namespaces
# operationId: functions_create_namespace
export def "functions-create-namespace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The namespace's unique name. (e.g. my namespace)
  region: string # The [datacenter region](https://docs.digitalocean.com/products/platform/availability-matrix/#available-datacenters) in which to create the namespace. (e.g. nyc1)
]: any -> oneof<record<namespace: record<api_host: string, created_at: string, key: string, label: string, namespace: string, region: string, updated_at: string, uuid: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/functions/namespaces" $auth.query)
  let req_body = {"label": $label, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete Namespace
#
# DELETE /v2/functions/namespaces/{namespace_id}
# operationId: functions_delete_namespace
export def "functions-delete-namespace" [
  namespace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace_id | is-empty) { error make --unspanned { msg: "path parameter 'namespace_id' must be non-empty" } }
  let full_url = (build-url $base ({namespace_id: (encode-path-segment $namespace_id)} | format pattern "/v2/functions/namespaces/{namespace_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get Namespace
#
# GET /v2/functions/namespaces/{namespace_id}
# operationId: functions_get_namespace
export def "functions-get-namespace" [
  namespace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<namespace: record<api_host: string, created_at: string, key: string, label: string, namespace: string, region: string, updated_at: string, uuid: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace_id | is-empty) { error make --unspanned { msg: "path parameter 'namespace_id' must be non-empty" } }
  let full_url = (build-url $base ({namespace_id: (encode-path-segment $namespace_id)} | format pattern "/v2/functions/namespaces/{namespace_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Triggers
#
# GET /v2/functions/namespaces/{namespace_id}/triggers
# operationId: functions_list_triggers
export def "functions-list-triggers" [
  namespace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<triggers: table<created_at: string, function: string, is_enabled: bool, name: string, namespace: string, scheduled_details: record, scheduled_runs: record, type: string, updated_at: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace_id | is-empty) { error make --unspanned { msg: "path parameter 'namespace_id' must be non-empty" } }
  let full_url = (build-url $base ({namespace_id: (encode-path-segment $namespace_id)} | format pattern "/v2/functions/namespaces/{namespace_id}/triggers") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create Trigger
#
# POST /v2/functions/namespaces/{namespace_id}/triggers
# operationId: functions_create_trigger
export def "functions-create-trigger" [
  namespace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  function: string # Name of function(action) that exists in the given namespace. (e.g. hello)
  --is-enabled: oneof<nothing, bool> # Indicates weather the trigger is paused or unpaused. (e.g. true)
  name: string # The trigger's unique name within the namespace. (e.g. my trigger)
  scheduled_details: record # Trigger details for SCHEDULED type, where body is optional. — shape: {body?: record, cron: string}
  type: string # One of different type of triggers. Currently only SCHEDULED is supported. (e.g. SCHEDULED)
]: any -> oneof<record<trigger: record<created_at: string, function: string, is_enabled: bool, name: string, namespace: string, scheduled_details: record<body: record, cron: string>, scheduled_runs: record<last_run_at: string, next_run_at: string>, type: string, updated_at: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace_id | is-empty) { error make --unspanned { msg: "path parameter 'namespace_id' must be non-empty" } }
  let full_url = (build-url $base ({namespace_id: (encode-path-segment $namespace_id)} | format pattern "/v2/functions/namespaces/{namespace_id}/triggers") $auth.query)
  let req_body = {"function": $function, "is_enabled": $is_enabled, "name": $name, "scheduled_details": $scheduled_details, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "is_enabled") == null) { error make --unspanned { msg: "required body field 'is_enabled' missing: pass --is-enabled or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete Trigger
#
# DELETE /v2/functions/namespaces/{namespace_id}/triggers/{trigger_name}
# operationId: functions_delete_trigger
export def "functions-delete-trigger" [
  namespace_id: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace_id | is-empty) { error make --unspanned { msg: "path parameter 'namespace_id' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'trigger_name' must be non-empty" } }
  let full_url = (build-url $base ({namespace_id: (encode-path-segment $namespace_id), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/v2/functions/namespaces/{namespace_id}/triggers/{trigger_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get Trigger
#
# GET /v2/functions/namespaces/{namespace_id}/triggers/{trigger_name}
# operationId: functions_get_trigger
export def "functions-get-trigger" [
  namespace_id: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<trigger: record<created_at: string, function: string, is_enabled: bool, name: string, namespace: string, scheduled_details: record<body: record, cron: string>, scheduled_runs: record<last_run_at: string, next_run_at: string>, type: string, updated_at: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace_id | is-empty) { error make --unspanned { msg: "path parameter 'namespace_id' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'trigger_name' must be non-empty" } }
  let full_url = (build-url $base ({namespace_id: (encode-path-segment $namespace_id), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/v2/functions/namespaces/{namespace_id}/triggers/{trigger_name}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Trigger
#
# PUT /v2/functions/namespaces/{namespace_id}/triggers/{trigger_name}
# operationId: functions_update_trigger
export def "functions-update-trigger" [
  namespace_id: string
  trigger_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-enabled: oneof<nothing, bool> # Indicates weather the trigger is paused or unpaused. (e.g. true)
  --scheduled-details: record # Trigger details for SCHEDULED type, where body is optional. — shape: {body?: record, cron: string}
]: any -> oneof<record<trigger: record<created_at: string, function: string, is_enabled: bool, name: string, namespace: string, scheduled_details: record<body: record, cron: string>, scheduled_runs: record<last_run_at: string, next_run_at: string>, type: string, updated_at: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace_id | is-empty) { error make --unspanned { msg: "path parameter 'namespace_id' must be non-empty" } }
  if ($trigger_name | is-empty) { error make --unspanned { msg: "path parameter 'trigger_name' must be non-empty" } }
  let full_url = (build-url $base ({namespace_id: (encode-path-segment $namespace_id), trigger_name: (encode-path-segment $trigger_name)} | format pattern "/v2/functions/namespaces/{namespace_id}/triggers/{trigger_name}") $auth.query)
  let req_body = {"is_enabled": $is_enabled, "scheduled_details": $scheduled_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List All Images
#
# GET /v2/images
# operationId: images_list
export def "images-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-7 # Filters results based on image type which can be either `application` or `distribution`. (e.g. distribution)
  --private: oneof<nothing, bool> # Used to filter only user images. (e.g. true)
  --tag-name: string # Used to filter images by a specific tag. (e.g. base-image)
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<images: table<created_at: string, description: string, distribution: string, error_message: string, id: int, min_disk_size: int, name: string, public: bool, regions: list, size_gigabytes: float, slug: string, status: string, tags: list, type: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "private" $private "scalar") (serialize-qp "tag_name" $tag_name "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/images" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "private": $private, "tag_name": $tag_name, "per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Custom Image
#
# POST /v2/images
# operationId: images_create_custom
export def "images-create-custom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # An optional free-form text field to describe an image. (e.g.  )
  --distribution: string@distribution-completer # The name of a custom image's distribution. Currently, the valid values are `Arch Linux`, `CentOS`, `CoreOS`, `Debian`, `Fedora`, `Fedora Atomic`, `FreeBSD`, `Gentoo`, `openSUSE`, `RancherOS`, `Rocky Linux`, `Ubuntu`, and `Unknown`. Any other value will be accepted but ignored, and `Unknown` will be used in its place. (e.g. Ubuntu)
  name: string # The display name that has been given to an image. This is what is shown in the control panel and is generally a descriptive title for the image in question. (e.g. Nifty New Snapshot)
  region: string@region-completer # The slug identifier for the region where the resource will initially be available. (e.g. nyc3)
  --tags: list<string> # A flat array of tag names as strings to be applied to the resource. Tag names may be for either existing or new tags. (nullable, e.g. [base-image, prod])
  url: string # A URL from which the custom Linux virtual machine image may be retrieved. The image it points to must be in the raw, qcow2, vhdx, vdi, or vmdk format. It may be compressed using gzip or bzip2 and must be smaller than 100 GB after being decompressed. (e.g. http://cloud-images.ubuntu.com/minimal/releases/bionic/release/ubuntu-18.04-minimal-cloudimg-amd64.img)
]: any -> oneof<record<image: record<created_at: string, description: string, distribution: string, error_message: string, id: int, min_disk_size: int, name: string, public: bool, regions: list<string>, size_gigabytes: float, slug: string, status: string, tags: list<string>, type: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/images" $auth.query)
  let req_body = {"description": $description, "distribution": $distribution, "name": $name, "region": $region, "tags": $tags, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Delete an Image
#
# DELETE /v2/images/{image_id}
# operationId: images_delete
export def "images-delete" [
  image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'image_id' must be non-empty" } }
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/v2/images/{image_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Image
#
# GET /v2/images/{image_id}
# operationId: images_get
export def "images-get" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<image: record<created_at: string, description: string, distribution: string, error_message: string, id: int, min_disk_size: int, name: string, public: bool, regions: list<string>, size_gigabytes: float, slug: string, status: string, tags: list<string>, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'image_id' must be non-empty" } }
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/v2/images/{image_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update an Image
#
# PUT /v2/images/{image_id}
# operationId: images_update
export def "images-update" [
  image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # An optional free-form text field to describe an image. (e.g.  )
  --distribution: string@distribution-completer # The name of a custom image's distribution. Currently, the valid values are `Arch Linux`, `CentOS`, `CoreOS`, `Debian`, `Fedora`, `Fedora Atomic`, `FreeBSD`, `Gentoo`, `openSUSE`, `RancherOS`, `Rocky Linux`, `Ubuntu`, and `Unknown`. Any other value will be accepted but ignored, and `Unknown` will be used in its place. (e.g. Ubuntu)
  --name: string # The display name that has been given to an image. This is what is shown in the control panel and is generally a descriptive title for the image in question. (e.g. Nifty New Snapshot)
]: any -> oneof<record<image: record<created_at: string, description: string, distribution: string, error_message: string, id: int, min_disk_size: int, name: string, public: bool, regions: list<string>, size_gigabytes: float, slug: string, status: string, tags: list<string>, type: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'image_id' must be non-empty" } }
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/v2/images/{image_id}") $auth.query)
  let req_body = {"description": $description, "distribution": $distribution, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List All Actions for an Image
#
# GET /v2/images/{image_id}/actions
# operationId: imageActions_list
export def "image-actions-list" [
  image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<actions: table<completed_at: string, id: int, region: record, region_slug: string, resource_id: int, resource_type: string, started_at: string, status: string, type: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'image_id' must be non-empty" } }
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/v2/images/{image_id}/actions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Initiate an Image Action
#
# POST /v2/images/{image_id}/actions
# Discriminator (request): type = convert, transfer
# operationId: imageActions_post
export def "image-actions-post" [
  image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-8 # The action to be taken on the image. Can be either `convert` or `transfer`. (e.g. convert)
  --region: string@region-completer # The slug identifier for the region where the resource will initially be available. (e.g. nyc3)
]: any -> oneof<record<completed_at: string, id: int, region: record<available: bool, features: list<string>, name: string, sizes: list<string>, slug: string>, region_slug: string, resource_id: int, resource_type: string, started_at: string, status: string, type: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'image_id' must be non-empty" } }
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id)} | format pattern "/v2/images/{image_id}/actions") $auth.query)
  let req_body = {"type": $type, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve an Existing Action
#
# GET /v2/images/{image_id}/actions/{action_id}
# operationId: imageActions_get
export def "image-actions-get" [
  image_id: int
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<completed_at: string, id: int, region: record<available: bool, features: list<string>, name: string, sizes: list<string>, slug: string>, region_slug: string, resource_id: int, resource_type: string, started_at: string, status: string, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'image_id' must be non-empty" } }
  if ($action_id | is-empty) { error make --unspanned { msg: "path parameter 'action_id' must be non-empty" } }
  let full_url = (build-url $base ({image_id: (encode-path-segment $image_id), action_id: (encode-path-segment $action_id)} | format pattern "/v2/images/{image_id}/actions/{action_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Kubernetes Clusters
#
# GET /v2/kubernetes/clusters
# operationId: kubernetes_list_clusters
export def "kubernetes-list-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<kubernetes_clusters: table<auto_upgrade: bool, cluster_subnet: string, created_at: string, endpoint: string, ha: bool, id: string, ipv4: string, maintenance_policy: record, name: string, node_pools: list, region: string, registry_enabled: bool, service_subnet: string, status: record, surge_upgrade: bool, tags: list, updated_at: string, version: string, vpc_uuid: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/kubernetes/clusters" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New Kubernetes Cluster
#
# POST /v2/kubernetes/clusters
# operationId: kubernetes_create_cluster
export def "kubernetes-create-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-upgrade: oneof<nothing, bool> # A boolean value indicating whether the cluster will be automatically upgraded to new patch releases during its maintenance window. (default: false, e.g. true)
  --ha: oneof<nothing, bool> # A boolean value indicating whether the control plane is run in a highly available configuration in the cluster. Highly available control planes incur less downtime. The property cannot be disabled. (default: false, e.g. true)
  --maintenance-policy: record # An object specifying the maintenance window policy for the Kubernetes cluster. (nullable) — shape: {day?: "any"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", start_time?: string}
  name: string # A human-readable name for a Kubernetes cluster. (e.g. prod-cluster-01)
  node_pools: list # An object specifying the details of the worker nodes available to the Kubernetes cluster. — item shape: {size: string, auto_scale?: bool, count: int, labels?: record, max_nodes?: int, min_nodes?: int, name: string, tags?: list<string>, taints?: list}
  region: string # The slug identifier for the region where the Kubernetes cluster is located. (e.g. nyc1)
  --surge-upgrade: oneof<nothing, bool> # A boolean value indicating whether surge upgrade is enabled/disabled for the cluster. Surge upgrade makes cluster upgrades fast and reliable by bringing up new nodes before destroying the outdated nodes. (default: false, e.g. true)
  --tags: list<string> # An array of tags applied to the Kubernetes cluster. All clusters are automatically tagged `k8s` and `k8s:$K8S_CLUSTER_ID`. (e.g. [k8s, k8s:bd5f5959-5e1e-4205-a714-a914373942af, production, web-team])
  version: string # The slug identifier for the version of Kubernetes used for the cluster. If set to a minor version (e.g. "1.14"), the latest version within it will be used (e.g. "1.14.6-do.1"); if set to "latest", the latest published version will be used. See the `/v2/kubernetes/options` endpoint to find all currently available versions. (e.g. 1.18.6-do.0)
  --vpc-uuid: string # A string specifying the UUID of the VPC to which the Kubernetes cluster is assigned. (format: uuid, e.g. c33931f2-a26a-4e61-b85c-4e95a2ec431b)
]: any -> oneof<record<kubernetes_cluster: record<auto_upgrade: bool, cluster_subnet: string, created_at: string, endpoint: string, ha: bool, id: string, ipv4: string, maintenance_policy: record<day: string, duration: string, start_time: string>, name: string, node_pools: list<record>, region: string, registry_enabled: bool, service_subnet: string, status: record<message: string, state: string>, surge_upgrade: bool, tags: list<string>, updated_at: string, version: string, vpc_uuid: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/kubernetes/clusters" $auth.query)
  let req_body = {"auto_upgrade": $auto_upgrade, "ha": $ha, "maintenance_policy": $maintenance_policy, "name": $name, "node_pools": $node_pools, "region": $region, "surge_upgrade": $surge_upgrade, "tags": $tags, "version": $version, "vpc_uuid": $vpc_uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a Kubernetes Cluster
#
# DELETE /v2/kubernetes/clusters/{cluster_id}
# operationId: kubernetes_delete_cluster
export def "kubernetes-delete-cluster" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Kubernetes Cluster
#
# GET /v2/kubernetes/clusters/{cluster_id}
# operationId: kubernetes_get_cluster
export def "kubernetes-get-cluster" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<kubernetes_cluster: record<auto_upgrade: bool, cluster_subnet: string, created_at: string, endpoint: string, ha: bool, id: string, ipv4: string, maintenance_policy: record<day: string, duration: string, start_time: string>, name: string, node_pools: list<record>, region: string, registry_enabled: bool, service_subnet: string, status: record<message: string, state: string>, surge_upgrade: bool, tags: list<string>, updated_at: string, version: string, vpc_uuid: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a Kubernetes Cluster
#
# PUT /v2/kubernetes/clusters/{cluster_id}
# operationId: kubernetes_update_cluster
export def "kubernetes-update-cluster" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-upgrade: oneof<nothing, bool> # A boolean value indicating whether the cluster will be automatically upgraded to new patch releases during its maintenance window. (default: false, e.g. true)
  --ha: oneof<nothing, bool> # A boolean value indicating whether the control plane is run in a highly available configuration in the cluster. Highly available control planes incur less downtime. The property cannot be disabled. (default: false, e.g. true)
  --maintenance-policy: record # An object specifying the maintenance window policy for the Kubernetes cluster. (nullable) — shape: {day?: "any"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday"|"sunday", start_time?: string}
  name: string # A human-readable name for a Kubernetes cluster. (e.g. prod-cluster-01)
  --surge-upgrade: oneof<nothing, bool> # A boolean value indicating whether surge upgrade is enabled/disabled for the cluster. Surge upgrade makes cluster upgrades fast and reliable by bringing up new nodes before destroying the outdated nodes. (default: false, e.g. true)
  --tags: list<string> # An array of tags applied to the Kubernetes cluster. All clusters are automatically tagged `k8s` and `k8s:$K8S_CLUSTER_ID`. (e.g. [k8s, k8s:bd5f5959-5e1e-4205-a714-a914373942af, production, web-team])
]: any -> oneof<record<kubernetes_cluster: record<auto_upgrade: bool, cluster_subnet: string, created_at: string, endpoint: string, ha: bool, id: string, ipv4: string, maintenance_policy: record<day: string, duration: string, start_time: string>, name: string, node_pools: list<record>, region: string, registry_enabled: bool, service_subnet: string, status: record<message: string, state: string>, surge_upgrade: bool, tags: list<string>, updated_at: string, version: string, vpc_uuid: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}") $auth.query)
  let req_body = {"auto_upgrade": $auto_upgrade, "ha": $ha, "maintenance_policy": $maintenance_policy, "name": $name, "surge_upgrade": $surge_upgrade, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Fetch Clusterlint Diagnostics for a Kubernetes Cluster
#
# GET /v2/kubernetes/clusters/{cluster_id}/clusterlint
# operationId: kubernetes_get_clusterLintResults
export def "kubernetes-get-cluster-lint-results" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --run-id: string # Specifies the clusterlint run whose results will be retrieved. (format: uuid, e.g. 50c2f44c-011d-493e-aee5-361a4a0d1844)
]: nothing -> oneof<record<completed_at: string, diagnostics: table<check_name: string, message: string, object: record, severity: string>, requested_at: string, run_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  let qp = [(serialize-qp "run_id" $run_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/clusterlint") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"run_id": $run_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Run Clusterlint Checks on a Kubernetes Cluster
#
# POST /v2/kubernetes/clusters/{cluster_id}/clusterlint
# operationId: kubernetes_run_clusterLint
export def "kubernetes-run-cluster-lint" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclude-checks: list<string> # An array of checks that will be run when clusterlint executes checks. (e.g. [default-namespace])
  --exclude-groups: list<string> # An array of check groups that will be omitted when clusterlint executes checks. (e.g. [workload-health])
  --include-checks: list<string> # An array of checks that will be run when clusterlint executes checks. (e.g. [bare-pods, resource-requirements])
  --include-groups: list<string> # An array of check groups that will be run when clusterlint executes checks. (e.g. [basic, doks, security])
]: any -> oneof<record<run_id: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/clusterlint") $auth.query)
  let req_body = {"exclude_checks": $exclude_checks, "exclude_groups": $exclude_groups, "include_checks": $include_checks, "include_groups": $include_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Retrieve Credentials for a Kubernetes Cluster
#
# GET /v2/kubernetes/clusters/{cluster_id}/credentials
# operationId: kubernetes_get_credentials
export def "kubernetes-get-credentials" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry-seconds: int # The duration in seconds that the returned Kubernetes credentials will be valid. If not set or 0, the credentials will have a 7 day expiry. (default: 0, e.g. 300)
]: nothing -> oneof<record<certificate_authority_data: string, client_certificate_data: string, client_key_data: string, expires_at: string, server: string, token: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  let qp = [(serialize-qp "expiry_seconds" $expiry_seconds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/credentials") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"expiry_seconds": $expiry_seconds} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Associated Resources for Cluster Deletion
#
# GET /v2/kubernetes/clusters/{cluster_id}/destroy_with_associated_resources
# operationId: kubernetes_list_associatedResources
export def "kubernetes-list-associated-resources" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<load_balancers: table<id: string, name: string>, volume_snapshots: table<id: string, name: string>, volumes: table<id: string, name: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/destroy_with_associated_resources") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a Cluster and All of its Associated Resources (Dangerous)
#
# DELETE /v2/kubernetes/clusters/{cluster_id}/destroy_with_associated_resources/dangerous
# operationId: kubernetes_destroy_associatedResourcesDangerous
export def "kubernetes-destroy-associated-resources-dangerous" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/destroy_with_associated_resources/dangerous") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Selectively Delete a Cluster and its Associated Resources
#
# DELETE /v2/kubernetes/clusters/{cluster_id}/destroy_with_associated_resources/selective
# operationId: kubernetes_destroy_associatedResourcesSelective
export def "kubernetes-destroy-associated-resources-selective" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --load-balancers: list<string> # A list of IDs for associated load balancers to destroy along with the cluster. (e.g. [4de7ac8b-495b-4884-9a69-1050c6793cd6])
  --volume-snapshots: list<string> # A list of IDs for associated volume snapshots to destroy along with the cluster. (e.g. [edb0478d-7436-11ea-86e6-0a58ac144b91])
  --volumes: list<string> # A list of IDs for associated volumes to destroy along with the cluster. (e.g. [ba49449a-7435-11ea-b89e-0a58ac14480f])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/destroy_with_associated_resources/selective") $auth.query)
  let req_body = {"load_balancers": $load_balancers, "volume_snapshots": $volume_snapshots, "volumes": $volumes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [204]
}

# Retrieve the kubeconfig for a Kubernetes Cluster
#
# GET /v2/kubernetes/clusters/{cluster_id}/kubeconfig
# operationId: kubernetes_get_kubeconfig
export def "kubernetes-get-kubeconfig" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expiry-seconds: int # The duration in seconds that the returned Kubernetes credentials will be valid. If not set or 0, the credentials will have a 7 day expiry. (default: 0, e.g. 300)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  let qp = [(serialize-qp "expiry_seconds" $expiry_seconds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/kubeconfig") $qp $auth.query)
  let accept_val = ($accept | default "application/yaml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"expiry_seconds": $expiry_seconds} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Node Pools in a Kubernetes Clusters
#
# GET /v2/kubernetes/clusters/{cluster_id}/node_pools
# operationId: kubernetes_list_nodePools
export def "kubernetes-list-node-pools" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<node_pools: table<size: string, auto_scale: bool, count: int, id: string, labels: record, max_nodes: int, min_nodes: int, name: string, nodes: list, tags: list, taints: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/node_pools") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a Node Pool to a Kubernetes Cluster
#
# POST /v2/kubernetes/clusters/{cluster_id}/node_pools
# operationId: kubernetes_add_nodePool
export def "kubernetes-add-node-pool" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  size: string # The slug identifier for the type of Droplet used as workers in the node pool. (e.g. s-1vcpu-2gb)
  --auto-scale: oneof<nothing, bool> # A boolean value indicating whether auto-scaling is enabled for this node pool. (e.g. true)
  count: int # The number of Droplet instances in the node pool. (e.g. 3)
  --labels: record # An object containing a set of Kubernetes labels. The keys and are values are both user-defined. (nullable)
  --max-nodes: int # The maximum number of nodes that this node pool can be auto-scaled to. The value will be `0` if `auto_scale` is set to `false`. (e.g. 6)
  --min-nodes: int # The minimum number of nodes that this node pool can be auto-scaled to. The value will be `0` if `auto_scale` is set to `false`. (e.g. 3)
  name: string # A human-readable name for the node pool. (e.g. frontend-pool)
  --tags: list<string> # An array containing the tags applied to the node pool. All node pools are automatically tagged `k8s`, `k8s-worker`, and `k8s:$K8S_CLUSTER_ID`. (e.g. [k8s, k8s:bd5f5959-5e1e-4205-a714-a914373942af, k8s-worker, production, web-team])
  --taints: list # An array of taints to apply to all nodes in a pool. Taints will automatically be applied to all existing nodes and any subsequent nodes added to the pool. When a taint is removed, it is removed from all nodes in the pool. — item shape: {effect?: "NoSchedule"|"PreferNoSchedule"|"NoExecute", key?: string, value?: string}
]: any -> oneof<record<node_pool: record<size: string, auto_scale: bool, count: int, id: string, labels: record, max_nodes: int, min_nodes: int, name: string, nodes: list<record>, tags: list<string>, taints: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/node_pools") $auth.query)
  let req_body = {"size": $size, "auto_scale": $auto_scale, "count": $count, "labels": $labels, "max_nodes": $max_nodes, "min_nodes": $min_nodes, "name": $name, "tags": $tags, "taints": $taints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a Node Pool in a Kubernetes Cluster
#
# DELETE /v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}
# operationId: kubernetes_delete_nodePool
export def "kubernetes-delete-node-pool" [
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  if ($node_pool_id | is-empty) { error make --unspanned { msg: "path parameter 'node_pool_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve a Node Pool for a Kubernetes Cluster
#
# GET /v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}
# operationId: kubernetes_get_nodePool
export def "kubernetes-get-node-pool" [
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<node_pool: record<size: string, auto_scale: bool, count: int, id: string, labels: record, max_nodes: int, min_nodes: int, name: string, nodes: list<record>, tags: list<string>, taints: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  if ($node_pool_id | is-empty) { error make --unspanned { msg: "path parameter 'node_pool_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a Node Pool in a Kubernetes Cluster
#
# PUT /v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}
# operationId: kubernetes_update_nodePool
export def "kubernetes-update-node-pool" [
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-scale: oneof<nothing, bool> # A boolean value indicating whether auto-scaling is enabled for this node pool. (e.g. true)
  count: int # The number of Droplet instances in the node pool. (e.g. 3)
  --labels: record # An object containing a set of Kubernetes labels. The keys and are values are both user-defined. (nullable)
  --max-nodes: int # The maximum number of nodes that this node pool can be auto-scaled to. The value will be `0` if `auto_scale` is set to `false`. (e.g. 6)
  --min-nodes: int # The minimum number of nodes that this node pool can be auto-scaled to. The value will be `0` if `auto_scale` is set to `false`. (e.g. 3)
  name: string # A human-readable name for the node pool. (e.g. frontend-pool)
  --tags: list<string> # An array containing the tags applied to the node pool. All node pools are automatically tagged `k8s`, `k8s-worker`, and `k8s:$K8S_CLUSTER_ID`. (e.g. [k8s, k8s:bd5f5959-5e1e-4205-a714-a914373942af, k8s-worker, production, web-team])
  --taints: list # An array of taints to apply to all nodes in a pool. Taints will automatically be applied to all existing nodes and any subsequent nodes added to the pool. When a taint is removed, it is removed from all nodes in the pool. — item shape: {effect?: "NoSchedule"|"PreferNoSchedule"|"NoExecute", key?: string, value?: string}
]: any -> oneof<record<node_pool: record<size: string, auto_scale: bool, count: int, id: string, labels: record, max_nodes: int, min_nodes: int, name: string, nodes: list<record>, tags: list<string>, taints: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  if ($node_pool_id | is-empty) { error make --unspanned { msg: "path parameter 'node_pool_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}") $auth.query)
  let req_body = {"auto_scale": $auto_scale, "count": $count, "labels": $labels, "max_nodes": $max_nodes, "min_nodes": $min_nodes, "name": $name, "tags": $tags, "taints": $taints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [202]
}

# Delete a Node in a Kubernetes Cluster
#
# DELETE /v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}/nodes/{node_id}
# operationId: kubernetes_delete_node
export def "kubernetes-delete-node" [
  cluster_id: string
  node_pool_id: string
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip-drain: int # Specifies whether or not to drain workloads from a node before it is deleted. Setting it to `1` causes node draining to be skipped. Omitting the query parameter or setting its value to `0` carries out draining prior to deletion. (default: 0, e.g. 1)
  --replace: int # Specifies whether or not to replace a node after it has been deleted. Setting it to `1` causes the node to be replaced by a new one after deletion. Omitting the query parameter or setting its value to `0` deletes without replacement. (default: 0, e.g. 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  if ($node_pool_id | is-empty) { error make --unspanned { msg: "path parameter 'node_pool_id' must be non-empty" } }
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let qp = [(serialize-qp "skip_drain" $skip_drain "scalar") (serialize-qp "replace" $replace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id), node_id: (encode-path-segment $node_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}/nodes/{node_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"skip_drain": $skip_drain, "replace": $replace} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Recycle a Kubernetes Node Pool
#
# POST /v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}/recycle
# DEPRECATED
# operationId: kubernetes_recycle_node_pool
@deprecated
export def "kubernetes-recycle-node-pool" [
  cluster_id: string
  node_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --nodes: list<string> # e.g. [d8db5e1a-6103-43b5-a7b3-8a948210a9fc]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  if ($node_pool_id | is-empty) { error make --unspanned { msg: "path parameter 'node_pool_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id), node_pool_id: (encode-path-segment $node_pool_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/node_pools/{node_pool_id}/recycle") $auth.query)
  let req_body = {"nodes": $nodes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Upgrade a Kubernetes Cluster
#
# POST /v2/kubernetes/clusters/{cluster_id}/upgrade
# operationId: kubernetes_upgrade_cluster
export def "kubernetes-upgrade-cluster" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The slug identifier for the version of Kubernetes that the cluster will be upgraded to. (e.g. 1.16.13-do.0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/upgrade") $auth.query)
  let req_body = {"version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Retrieve Available Upgrades for an Existing Kubernetes Cluster
#
# GET /v2/kubernetes/clusters/{cluster_id}/upgrades
# operationId: kubernetes_get_availableUpgrades
export def "kubernetes-get-available-upgrades" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<available_upgrade_versions: table<kubernetes_version: string, slug: string, supported_features: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/upgrades") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve User Information for a Kubernetes Cluster
#
# GET /v2/kubernetes/clusters/{cluster_id}/user
# operationId: kubernetes_get_clusterUser
export def "kubernetes-get-cluster-user" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<kubernetes_cluster_user: record<groups: list<string>, username: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cluster_id | is-empty) { error make --unspanned { msg: "path parameter 'cluster_id' must be non-empty" } }
  let full_url = (build-url $base ({cluster_id: (encode-path-segment $cluster_id)} | format pattern "/v2/kubernetes/clusters/{cluster_id}/user") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Available Regions, Node Sizes, and Versions of Kubernetes
#
# GET /v2/kubernetes/options
# operationId: kubernetes_list_options
export def "kubernetes-list-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<options: record<regions: list<record>, sizes: list<record>, versions: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/kubernetes/options" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove Container Registry from Kubernetes Clusters
#
# DELETE /v2/kubernetes/registry
# operationId: kubernetes_remove_registry
export def "kubernetes-remove-registry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-uuids: list<string> # An array containing the UUIDs of Kubernetes clusters. (e.g. [bd5f5959-5e1e-4205-a714-a914373942af, 50c2f44c-011d-493e-aee5-361a4a0d1844])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/kubernetes/registry" $auth.query)
  let req_body = {"cluster_uuids": $cluster_uuids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [204]
}

# Add Container Registry to Kubernetes Clusters
#
# POST /v2/kubernetes/registry
# operationId: kubernetes_add_registry
export def "kubernetes-add-registry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cluster-uuids: list<string> # An array containing the UUIDs of Kubernetes clusters. (e.g. [bd5f5959-5e1e-4205-a714-a914373942af, 50c2f44c-011d-493e-aee5-361a4a0d1844])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/kubernetes/registry" $auth.query)
  let req_body = {"cluster_uuids": $cluster_uuids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# List All Load Balancers
#
# GET /v2/load_balancers
# operationId: loadBalancers_list
export def "load-balancers-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<load_balancers: table<algorithm: string, created_at: string, disable_lets_encrypt_dns_records: bool, enable_backend_keepalive: bool, enable_proxy_protocol: bool, firewall: record, forwarding_rules: list, health_check: record, http_idle_timeout_seconds: int, id: string, ip: string, name: string, project_id: string, redirect_http_to_https: bool, size: string, size_unit: int, status: string, sticky_sessions: record, vpc_uuid: string, region: record, droplet_ids: list, tag: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/load_balancers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New Load Balancer
#
# POST /v2/load_balancers
# operationId: loadBalancers_create
@deprecated --flag algorithm
@deprecated --flag size
export def "load-balancers-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --droplet-ids: list<int> # An array containing the IDs of the Droplets assigned to the load balancer. (e.g. [3164444, 3164445])
  region: string@region-completer # The slug identifier for the region where the resource will initially be available. (e.g. nyc3)
  --algorithm: string@algorithm-completer # This field has been deprecated. You can no longer specify an algorithm for load balancers. (DEPRECATED, default: round_robin, e.g. round_robin)
  --disable-lets-encrypt-dns-records: oneof<nothing, bool> # A boolean value indicating whether to disable automatic DNS record creation for Let's Encrypt certificates that are added to the load balancer. (default: false, e.g. true)
  --enable-backend-keepalive: oneof<nothing, bool> # A boolean value indicating whether HTTP keepalive connections are maintained to target Droplets. (default: false, e.g. true)
  --enable-proxy-protocol: oneof<nothing, bool> # A boolean value indicating whether PROXY Protocol is in use. (default: false, e.g. true)
  --firewall: record # An object specifying allow and deny rules to control traffic to the load balancer. — shape: {allow?: list<string>, deny?: list<string>}
  forwarding_rules: list # An array of objects specifying the forwarding rules for a load balancer. — item shape: {certificate_id?: string, entry_port: int, entry_protocol: "http"|"https"|"http2"|"http3"|"tcp"|"udp", target_port: int, target_protocol: "http"|"https"|"http2"|"tcp"|"udp", tls_passthrough?: bool}
  --health-check: record # An object specifying health check settings for the load balancer. — shape: {check_interval_seconds?: int, healthy_threshold?: int, path?: string, port?: int, protocol?: "http"|"https"|"tcp", response_timeout_seconds?: int, unhealthy_threshold?: int}
  --http-idle-timeout-seconds: int # An integer value which configures the idle timeout for HTTP requests to the target droplets. (default: 60, e.g. 90)
  --name: string # A human-readable name for a load balancer instance. (e.g. example-lb-01)
  --project-id: string # The ID of the project that the load balancer is associated with. If no ID is provided at creation, the load balancer associates with the user's default project. If an invalid project ID is provided, the load balancer will not be created. (e.g. 4de7ac8b-495b-4884-9a69-1050c6793cd6)
  --redirect-http-to-https: oneof<nothing, bool> # A boolean value indicating whether HTTP requests to the load balancer on port 80 will be redirected to HTTPS on port 443. (default: false, e.g. true)
  --size: string@size-completer # This field has been replaced by the `size_unit` field for all regions except in AMS2, NYC2, and SFO1. Each available load balancer size now equates to the load balancer having a set number of nodes. * `lb-small` = 1 node * `lb-medium` = 3 nodes * `lb-large` = 6 nodes You can resize load balancers after creation up to once per hour. You cannot resize a load balancer within the first hour of its creation. (DEPRECATED, default: lb-small, e.g. lb-small)
  --size-unit: int # How many nodes the load balancer contains. Each additional node increases the load balancer's ability to manage more connections. Load balancers can be scaled up or down, and you can change the number of nodes after creation up to once per hour. This field is currently not available in the AMS2, NYC2, or SFO1 regions. Use the `size` field to scale load balancers that reside in these regions. (default: 1, e.g. 3)
  --sticky-sessions: record # An object specifying sticky sessions settings for the load balancer. — shape: {cookie_name?: string, cookie_ttl_seconds?: int, type?: "cookies"|"none"}
  --vpc-uuid: string # A string specifying the UUID of the VPC to which the load balancer is assigned. (format: uuid, e.g. c33931f2-a26a-4e61-b85c-4e95a2ec431b)
  --tag: string # The name of a Droplet tag corresponding to Droplets assigned to the load balancer. (e.g. prod:web)
]: any -> oneof<record<load_balancer: record<algorithm: string, created_at: string, disable_lets_encrypt_dns_records: bool, enable_backend_keepalive: bool, enable_proxy_protocol: bool, firewall: record<allow: list, deny: list>, forwarding_rules: list<record>, health_check: record<check_interval_seconds: int, healthy_threshold: int, path: string, port: int, protocol: string, response_timeout_seconds: int, unhealthy_threshold: int>, http_idle_timeout_seconds: int, id: string, ip: string, name: string, project_id: string, redirect_http_to_https: bool, size: string, size_unit: int, status: string, sticky_sessions: record<cookie_name: string, cookie_ttl_seconds: int, type: string>, vpc_uuid: string, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, droplet_ids: list<int>, tag: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/load_balancers" $auth.query)
  let req_body = {"droplet_ids": $droplet_ids, "region": $region, "algorithm": $algorithm, "disable_lets_encrypt_dns_records": $disable_lets_encrypt_dns_records, "enable_backend_keepalive": $enable_backend_keepalive, "enable_proxy_protocol": $enable_proxy_protocol, "firewall": $firewall, "forwarding_rules": $forwarding_rules, "health_check": $health_check, "http_idle_timeout_seconds": $http_idle_timeout_seconds, "name": $name, "project_id": $project_id, "redirect_http_to_https": $redirect_http_to_https, "size": $size, "size_unit": $size_unit, "sticky_sessions": $sticky_sessions, "vpc_uuid": $vpc_uuid, "tag": $tag} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Delete a Load Balancer
#
# DELETE /v2/load_balancers/{lb_id}
# operationId: loadBalancers_delete
export def "load-balancers-delete" [
  lb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lb_id | is-empty) { error make --unspanned { msg: "path parameter 'lb_id' must be non-empty" } }
  let full_url = (build-url $base ({lb_id: (encode-path-segment $lb_id)} | format pattern "/v2/load_balancers/{lb_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Load Balancer
#
# GET /v2/load_balancers/{lb_id}
# operationId: loadBalancers_get
export def "load-balancers-get" [
  lb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<load_balancer: record<algorithm: string, created_at: string, disable_lets_encrypt_dns_records: bool, enable_backend_keepalive: bool, enable_proxy_protocol: bool, firewall: record<allow: list, deny: list>, forwarding_rules: list<record>, health_check: record<check_interval_seconds: int, healthy_threshold: int, path: string, port: int, protocol: string, response_timeout_seconds: int, unhealthy_threshold: int>, http_idle_timeout_seconds: int, id: string, ip: string, name: string, project_id: string, redirect_http_to_https: bool, size: string, size_unit: int, status: string, sticky_sessions: record<cookie_name: string, cookie_ttl_seconds: int, type: string>, vpc_uuid: string, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, droplet_ids: list<int>, tag: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lb_id | is-empty) { error make --unspanned { msg: "path parameter 'lb_id' must be non-empty" } }
  let full_url = (build-url $base ({lb_id: (encode-path-segment $lb_id)} | format pattern "/v2/load_balancers/{lb_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a Load Balancer
#
# PUT /v2/load_balancers/{lb_id}
# operationId: loadBalancers_update
@deprecated --flag algorithm
@deprecated --flag size
export def "load-balancers-update" [
  lb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --droplet-ids: list<int> # An array containing the IDs of the Droplets assigned to the load balancer. (e.g. [3164444, 3164445])
  region: string@region-completer # The slug identifier for the region where the resource will initially be available. (e.g. nyc3)
  --algorithm: string@algorithm-completer # This field has been deprecated. You can no longer specify an algorithm for load balancers. (DEPRECATED, default: round_robin, e.g. round_robin)
  --disable-lets-encrypt-dns-records: oneof<nothing, bool> # A boolean value indicating whether to disable automatic DNS record creation for Let's Encrypt certificates that are added to the load balancer. (default: false, e.g. true)
  --enable-backend-keepalive: oneof<nothing, bool> # A boolean value indicating whether HTTP keepalive connections are maintained to target Droplets. (default: false, e.g. true)
  --enable-proxy-protocol: oneof<nothing, bool> # A boolean value indicating whether PROXY Protocol is in use. (default: false, e.g. true)
  --firewall: record # An object specifying allow and deny rules to control traffic to the load balancer. — shape: {allow?: list<string>, deny?: list<string>}
  forwarding_rules: list # An array of objects specifying the forwarding rules for a load balancer. — item shape: {certificate_id?: string, entry_port: int, entry_protocol: "http"|"https"|"http2"|"http3"|"tcp"|"udp", target_port: int, target_protocol: "http"|"https"|"http2"|"tcp"|"udp", tls_passthrough?: bool}
  --health-check: record # An object specifying health check settings for the load balancer. — shape: {check_interval_seconds?: int, healthy_threshold?: int, path?: string, port?: int, protocol?: "http"|"https"|"tcp", response_timeout_seconds?: int, unhealthy_threshold?: int}
  --http-idle-timeout-seconds: int # An integer value which configures the idle timeout for HTTP requests to the target droplets. (default: 60, e.g. 90)
  --name: string # A human-readable name for a load balancer instance. (e.g. example-lb-01)
  --project-id: string # The ID of the project that the load balancer is associated with. If no ID is provided at creation, the load balancer associates with the user's default project. If an invalid project ID is provided, the load balancer will not be created. (e.g. 4de7ac8b-495b-4884-9a69-1050c6793cd6)
  --redirect-http-to-https: oneof<nothing, bool> # A boolean value indicating whether HTTP requests to the load balancer on port 80 will be redirected to HTTPS on port 443. (default: false, e.g. true)
  --size: string@size-completer # This field has been replaced by the `size_unit` field for all regions except in AMS2, NYC2, and SFO1. Each available load balancer size now equates to the load balancer having a set number of nodes. * `lb-small` = 1 node * `lb-medium` = 3 nodes * `lb-large` = 6 nodes You can resize load balancers after creation up to once per hour. You cannot resize a load balancer within the first hour of its creation. (DEPRECATED, default: lb-small, e.g. lb-small)
  --size-unit: int # How many nodes the load balancer contains. Each additional node increases the load balancer's ability to manage more connections. Load balancers can be scaled up or down, and you can change the number of nodes after creation up to once per hour. This field is currently not available in the AMS2, NYC2, or SFO1 regions. Use the `size` field to scale load balancers that reside in these regions. (default: 1, e.g. 3)
  --sticky-sessions: record # An object specifying sticky sessions settings for the load balancer. — shape: {cookie_name?: string, cookie_ttl_seconds?: int, type?: "cookies"|"none"}
  --vpc-uuid: string # A string specifying the UUID of the VPC to which the load balancer is assigned. (format: uuid, e.g. c33931f2-a26a-4e61-b85c-4e95a2ec431b)
  --tag: string # The name of a Droplet tag corresponding to Droplets assigned to the load balancer. (e.g. prod:web)
]: any -> oneof<record<load_balancer: record<algorithm: string, created_at: string, disable_lets_encrypt_dns_records: bool, enable_backend_keepalive: bool, enable_proxy_protocol: bool, firewall: record<allow: list, deny: list>, forwarding_rules: list<record>, health_check: record<check_interval_seconds: int, healthy_threshold: int, path: string, port: int, protocol: string, response_timeout_seconds: int, unhealthy_threshold: int>, http_idle_timeout_seconds: int, id: string, ip: string, name: string, project_id: string, redirect_http_to_https: bool, size: string, size_unit: int, status: string, sticky_sessions: record<cookie_name: string, cookie_ttl_seconds: int, type: string>, vpc_uuid: string, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, droplet_ids: list<int>, tag: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lb_id | is-empty) { error make --unspanned { msg: "path parameter 'lb_id' must be non-empty" } }
  let full_url = (build-url $base ({lb_id: (encode-path-segment $lb_id)} | format pattern "/v2/load_balancers/{lb_id}") $auth.query)
  let req_body = {"droplet_ids": $droplet_ids, "region": $region, "algorithm": $algorithm, "disable_lets_encrypt_dns_records": $disable_lets_encrypt_dns_records, "enable_backend_keepalive": $enable_backend_keepalive, "enable_proxy_protocol": $enable_proxy_protocol, "firewall": $firewall, "forwarding_rules": $forwarding_rules, "health_check": $health_check, "http_idle_timeout_seconds": $http_idle_timeout_seconds, "name": $name, "project_id": $project_id, "redirect_http_to_https": $redirect_http_to_https, "size": $size, "size_unit": $size_unit, "sticky_sessions": $sticky_sessions, "vpc_uuid": $vpc_uuid, "tag": $tag} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Remove Droplets from a Load Balancer
#
# DELETE /v2/load_balancers/{lb_id}/droplets
# operationId: loadBalancers_remove_droplets
export def "load-balancers-remove-droplets" [
  lb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --droplet-ids: list<int> # An array containing the IDs of the Droplets assigned to the load balancer. (e.g. [3164444, 3164445])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lb_id | is-empty) { error make --unspanned { msg: "path parameter 'lb_id' must be non-empty" } }
  let full_url = (build-url $base ({lb_id: (encode-path-segment $lb_id)} | format pattern "/v2/load_balancers/{lb_id}/droplets") $auth.query)
  let req_body = {"droplet_ids": $droplet_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [204]
}

# Add Droplets to a Load Balancer
#
# POST /v2/load_balancers/{lb_id}/droplets
# operationId: loadBalancers_add_droplets
export def "load-balancers-add-droplets" [
  lb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --droplet-ids: list<int> # An array containing the IDs of the Droplets assigned to the load balancer. (e.g. [3164444, 3164445])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lb_id | is-empty) { error make --unspanned { msg: "path parameter 'lb_id' must be non-empty" } }
  let full_url = (build-url $base ({lb_id: (encode-path-segment $lb_id)} | format pattern "/v2/load_balancers/{lb_id}/droplets") $auth.query)
  let req_body = {"droplet_ids": $droplet_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Remove Forwarding Rules from a Load Balancer
#
# DELETE /v2/load_balancers/{lb_id}/forwarding_rules
# operationId: loadBalancers_remove_forwardingRules
export def "load-balancers-remove-forwarding-rules" [
  lb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  forwarding_rules: list # item shape: {certificate_id?: string, entry_port: int, entry_protocol: "http"|"https"|"http2"|"http3"|"tcp"|"udp", target_port: int, target_protocol: "http"|"https"|"http2"|"tcp"|"udp", tls_passthrough?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lb_id | is-empty) { error make --unspanned { msg: "path parameter 'lb_id' must be non-empty" } }
  let full_url = (build-url $base ({lb_id: (encode-path-segment $lb_id)} | format pattern "/v2/load_balancers/{lb_id}/forwarding_rules") $auth.query)
  let req_body = {"forwarding_rules": $forwarding_rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [204]
}

# Add Forwarding Rules to a Load Balancer
#
# POST /v2/load_balancers/{lb_id}/forwarding_rules
# operationId: loadBalancers_add_forwardingRules
export def "load-balancers-add-forwarding-rules" [
  lb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  forwarding_rules: list # item shape: {certificate_id?: string, entry_port: int, entry_protocol: "http"|"https"|"http2"|"http3"|"tcp"|"udp", target_port: int, target_protocol: "http"|"https"|"http2"|"tcp"|"udp", tls_passthrough?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lb_id | is-empty) { error make --unspanned { msg: "path parameter 'lb_id' must be non-empty" } }
  let full_url = (build-url $base ({lb_id: (encode-path-segment $lb_id)} | format pattern "/v2/load_balancers/{lb_id}/forwarding_rules") $auth.query)
  let req_body = {"forwarding_rules": $forwarding_rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# List Alert Policies
#
# GET /v2/monitoring/alerts
# operationId: monitoring_list_alertPolicy
export def "monitoring-list-alert-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<policies: table<alerts: record, compare: string, description: string, enabled: bool, entities: list, tags: list, type: string, uuid: string, value: float, window: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/alerts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create Alert Policy
#
# POST /v2/monitoring/alerts
# operationId: monitoring_create_alertPolicy
export def "monitoring-create-alert-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  alerts: record # shape: {email: list<string>, slack: list}
  compare: string@compare-completer # e.g. GreaterThan
  description: string # e.g. CPU Alert
  --enabled: oneof<nothing, bool> # e.g. true
  entities: list<string> # e.g. [192018292]
  tags: list<string> # e.g. [droplet_tag]
  type: string@type-completer-9 # e.g. v1/insights/droplet/cpu
  value: float # format: float, e.g. 80
  window: string@window-completer # e.g. 5m
]: any -> oneof<record<policy: record<alerts: record<email: list, slack: list>, compare: string, description: string, enabled: bool, entities: list<string>, tags: list<string>, type: string, uuid: string, value: float, window: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/monitoring/alerts" $auth.query)
  let req_body = {"alerts": $alerts, "compare": $compare, "description": $description, "enabled": $enabled, "entities": $entities, "tags": $tags, "type": $type, "value": $value, "window": $window} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "enabled") == null) { error make --unspanned { msg: "required body field 'enabled' missing: pass --enabled or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete an Alert Policy
#
# DELETE /v2/monitoring/alerts/{alert_uuid}
# operationId: monitoring_delete_alertPolicy
export def "monitoring-delete-alert-policy" [
  alert_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($alert_uuid | is-empty) { error make --unspanned { msg: "path parameter 'alert_uuid' must be non-empty" } }
  let full_url = (build-url $base ({alert_uuid: (encode-path-segment $alert_uuid)} | format pattern "/v2/monitoring/alerts/{alert_uuid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Alert Policy
#
# GET /v2/monitoring/alerts/{alert_uuid}
# operationId: monitoring_get_alertPolicy
export def "monitoring-get-alert-policy" [
  alert_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<policy: record<alerts: record<email: list, slack: list>, compare: string, description: string, enabled: bool, entities: list<string>, tags: list<string>, type: string, uuid: string, value: float, window: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($alert_uuid | is-empty) { error make --unspanned { msg: "path parameter 'alert_uuid' must be non-empty" } }
  let full_url = (build-url $base ({alert_uuid: (encode-path-segment $alert_uuid)} | format pattern "/v2/monitoring/alerts/{alert_uuid}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update an Alert Policy
#
# PUT /v2/monitoring/alerts/{alert_uuid}
# operationId: monitoring_update_alertPolicy
export def "monitoring-update-alert-policy" [
  alert_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  alerts: record # shape: {email: list<string>, slack: list}
  compare: string@compare-completer # e.g. GreaterThan
  description: string # e.g. CPU Alert
  --enabled: oneof<nothing, bool> # e.g. true
  entities: list<string> # e.g. [192018292]
  tags: list<string> # e.g. [droplet_tag]
  type: string@type-completer-9 # e.g. v1/insights/droplet/cpu
  value: float # format: float, e.g. 80
  window: string@window-completer # e.g. 5m
]: any -> oneof<record<policy: record<alerts: record<email: list, slack: list>, compare: string, description: string, enabled: bool, entities: list<string>, tags: list<string>, type: string, uuid: string, value: float, window: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($alert_uuid | is-empty) { error make --unspanned { msg: "path parameter 'alert_uuid' must be non-empty" } }
  let full_url = (build-url $base ({alert_uuid: (encode-path-segment $alert_uuid)} | format pattern "/v2/monitoring/alerts/{alert_uuid}") $auth.query)
  let req_body = {"alerts": $alerts, "compare": $compare, "description": $description, "enabled": $enabled, "entities": $entities, "tags": $tags, "type": $type, "value": $value, "window": $window} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "enabled") == null) { error make --unspanned { msg: "required body field 'enabled' missing: pass --enabled or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get Droplet Bandwidth Metrics
#
# GET /v2/monitoring/metrics/droplet/bandwidth
# operationId: monitoring_get_dropletBandwidthMetrics
export def "monitoring-get-droplet-bandwidth-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (required, e.g. 17209102)
  --interface: string@interface-completer # The network interface. (required, e.g. private)
  --direction: string@direction-completer # The traffic direction. (required, e.g. inbound)
  --start: string # Timestamp to start metric window. (required, e.g. 1620683817)
  --end: string # Timestamp to end metric window. (required, e.g. 1620705417)
]: nothing -> oneof<record<data: record<result: list<record>, resultType: string>, status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_id == null) { error make --unspanned { msg: "required query parameter 'host_id' missing: pass --host-id" } }
  if ($interface == null) { error make --unspanned { msg: "required query parameter 'interface' missing: pass --interface" } }
  if ($direction == null) { error make --unspanned { msg: "required query parameter 'direction' missing: pass --direction" } }
  if ($start == null) { error make --unspanned { msg: "required query parameter 'start' missing: pass --start" } }
  if ($end == null) { error make --unspanned { msg: "required query parameter 'end' missing: pass --end" } }
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "interface" $interface "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/bandwidth" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"host_id": $host_id, "interface": $interface, "direction": $direction, "start": $start, "end": $end} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Droplet CPU Metrics
#
# GET /v2/monitoring/metrics/droplet/cpu
# operationId: monitoring_get_DropletCpuMetrics
export def "monitoring-get-droplet-cpu-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (required, e.g. 17209102)
  --start: string # Timestamp to start metric window. (required, e.g. 1620683817)
  --end: string # Timestamp to end metric window. (required, e.g. 1620705417)
]: nothing -> oneof<record<data: record<result: list<record>, resultType: string>, status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_id == null) { error make --unspanned { msg: "required query parameter 'host_id' missing: pass --host-id" } }
  if ($start == null) { error make --unspanned { msg: "required query parameter 'start' missing: pass --start" } }
  if ($end == null) { error make --unspanned { msg: "required query parameter 'end' missing: pass --end" } }
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/cpu" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"host_id": $host_id, "start": $start, "end": $end} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Droplet Filesystem Free Metrics
#
# GET /v2/monitoring/metrics/droplet/filesystem_free
# operationId: monitoring_get_dropletFilesystemFreeMetrics
export def "monitoring-get-droplet-filesystem-free-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (required, e.g. 17209102)
  --start: string # Timestamp to start metric window. (required, e.g. 1620683817)
  --end: string # Timestamp to end metric window. (required, e.g. 1620705417)
]: nothing -> oneof<record<data: record<result: list<record>, resultType: string>, status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_id == null) { error make --unspanned { msg: "required query parameter 'host_id' missing: pass --host-id" } }
  if ($start == null) { error make --unspanned { msg: "required query parameter 'start' missing: pass --start" } }
  if ($end == null) { error make --unspanned { msg: "required query parameter 'end' missing: pass --end" } }
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/filesystem_free" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"host_id": $host_id, "start": $start, "end": $end} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Droplet Filesystem Size Metrics
#
# GET /v2/monitoring/metrics/droplet/filesystem_size
# operationId: monitoring_get_dropletFilesystemSizeMetrics
export def "monitoring-get-droplet-filesystem-size-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (required, e.g. 17209102)
  --start: string # Timestamp to start metric window. (required, e.g. 1620683817)
  --end: string # Timestamp to end metric window. (required, e.g. 1620705417)
]: nothing -> oneof<record<data: record<result: list<record>, resultType: string>, status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_id == null) { error make --unspanned { msg: "required query parameter 'host_id' missing: pass --host-id" } }
  if ($start == null) { error make --unspanned { msg: "required query parameter 'start' missing: pass --start" } }
  if ($end == null) { error make --unspanned { msg: "required query parameter 'end' missing: pass --end" } }
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/filesystem_size" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"host_id": $host_id, "start": $start, "end": $end} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Droplet Load1 Metrics
#
# GET /v2/monitoring/metrics/droplet/load_1
# operationId: monitoring_get_dropletLoad1Metrics
export def "monitoring-get-droplet-load1-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (required, e.g. 17209102)
  --start: string # Timestamp to start metric window. (required, e.g. 1620683817)
  --end: string # Timestamp to end metric window. (required, e.g. 1620705417)
]: nothing -> oneof<record<data: record<result: list<record>, resultType: string>, status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_id == null) { error make --unspanned { msg: "required query parameter 'host_id' missing: pass --host-id" } }
  if ($start == null) { error make --unspanned { msg: "required query parameter 'start' missing: pass --start" } }
  if ($end == null) { error make --unspanned { msg: "required query parameter 'end' missing: pass --end" } }
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/load_1" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"host_id": $host_id, "start": $start, "end": $end} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Droplet Load15 Metrics
#
# GET /v2/monitoring/metrics/droplet/load_15
# operationId: monitoring_get_dropletLoad15Metrics
export def "monitoring-get-droplet-load15-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (required, e.g. 17209102)
  --start: string # Timestamp to start metric window. (required, e.g. 1620683817)
  --end: string # Timestamp to end metric window. (required, e.g. 1620705417)
]: nothing -> oneof<record<data: record<result: list<record>, resultType: string>, status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_id == null) { error make --unspanned { msg: "required query parameter 'host_id' missing: pass --host-id" } }
  if ($start == null) { error make --unspanned { msg: "required query parameter 'start' missing: pass --start" } }
  if ($end == null) { error make --unspanned { msg: "required query parameter 'end' missing: pass --end" } }
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/load_15" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"host_id": $host_id, "start": $start, "end": $end} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Droplet Load5 Metrics
#
# GET /v2/monitoring/metrics/droplet/load_5
# operationId: monitoring_get_dropletLoad5Metrics
export def "monitoring-get-droplet-load5-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (required, e.g. 17209102)
  --start: string # Timestamp to start metric window. (required, e.g. 1620683817)
  --end: string # Timestamp to end metric window. (required, e.g. 1620705417)
]: nothing -> oneof<record<data: record<result: list<record>, resultType: string>, status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_id == null) { error make --unspanned { msg: "required query parameter 'host_id' missing: pass --host-id" } }
  if ($start == null) { error make --unspanned { msg: "required query parameter 'start' missing: pass --start" } }
  if ($end == null) { error make --unspanned { msg: "required query parameter 'end' missing: pass --end" } }
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/load_5" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"host_id": $host_id, "start": $start, "end": $end} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Droplet Available Memory Metrics
#
# GET /v2/monitoring/metrics/droplet/memory_available
# operationId: monitoring_get_dropletMemoryAvailableMetrics
export def "monitoring-get-droplet-memory-available-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (required, e.g. 17209102)
  --start: string # Timestamp to start metric window. (required, e.g. 1620683817)
  --end: string # Timestamp to end metric window. (required, e.g. 1620705417)
]: nothing -> oneof<record<data: record<result: list<record>, resultType: string>, status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_id == null) { error make --unspanned { msg: "required query parameter 'host_id' missing: pass --host-id" } }
  if ($start == null) { error make --unspanned { msg: "required query parameter 'start' missing: pass --start" } }
  if ($end == null) { error make --unspanned { msg: "required query parameter 'end' missing: pass --end" } }
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/memory_available" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"host_id": $host_id, "start": $start, "end": $end} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Droplet Cached Memory Metrics
#
# GET /v2/monitoring/metrics/droplet/memory_cached
# operationId: monitoring_get_dropletMemoryCachedMetrics
export def "monitoring-get-droplet-memory-cached-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (required, e.g. 17209102)
  --start: string # Timestamp to start metric window. (required, e.g. 1620683817)
  --end: string # Timestamp to end metric window. (required, e.g. 1620705417)
]: nothing -> oneof<record<data: record<result: list<record>, resultType: string>, status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_id == null) { error make --unspanned { msg: "required query parameter 'host_id' missing: pass --host-id" } }
  if ($start == null) { error make --unspanned { msg: "required query parameter 'start' missing: pass --start" } }
  if ($end == null) { error make --unspanned { msg: "required query parameter 'end' missing: pass --end" } }
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/memory_cached" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"host_id": $host_id, "start": $start, "end": $end} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Droplet Free Memory Metrics
#
# GET /v2/monitoring/metrics/droplet/memory_free
# operationId: monitoring_get_dropletMemoryFreeMetrics
export def "monitoring-get-droplet-memory-free-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (required, e.g. 17209102)
  --start: string # Timestamp to start metric window. (required, e.g. 1620683817)
  --end: string # Timestamp to end metric window. (required, e.g. 1620705417)
]: nothing -> oneof<record<data: record<result: list<record>, resultType: string>, status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_id == null) { error make --unspanned { msg: "required query parameter 'host_id' missing: pass --host-id" } }
  if ($start == null) { error make --unspanned { msg: "required query parameter 'start' missing: pass --start" } }
  if ($end == null) { error make --unspanned { msg: "required query parameter 'end' missing: pass --end" } }
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/memory_free" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"host_id": $host_id, "start": $start, "end": $end} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Droplet Total Memory Metrics
#
# GET /v2/monitoring/metrics/droplet/memory_total
# operationId: monitoring_get_dropletMemoryTotalMetrics
export def "monitoring-get-droplet-memory-total-metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --host-id: string # The droplet ID. (required, e.g. 17209102)
  --start: string # Timestamp to start metric window. (required, e.g. 1620683817)
  --end: string # Timestamp to end metric window. (required, e.g. 1620705417)
]: nothing -> oneof<record<data: record<result: list<record>, resultType: string>, status: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host_id == null) { error make --unspanned { msg: "required query parameter 'host_id' missing: pass --host-id" } }
  if ($start == null) { error make --unspanned { msg: "required query parameter 'start' missing: pass --start" } }
  if ($end == null) { error make --unspanned { msg: "required query parameter 'end' missing: pass --end" } }
  let qp = [(serialize-qp "host_id" $host_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/monitoring/metrics/droplet/memory_total" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"host_id": $host_id, "start": $start, "end": $end} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Projects
#
# GET /v2/projects
# operationId: projects_list
export def "projects-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<projects: table<created_at: string, description: string, environment: string, id: string, name: string, owner_id: int, owner_uuid: string, purpose: string, updated_at: string, is_default: bool>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/projects" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Project
#
# POST /v2/projects
# operationId: projects_create
export def "projects-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the project. The maximum length is 255 characters. (e.g. My website API)
  --environment: string@environment-completer # The environment of the project's resources. (e.g. Production)
  name: string # The human-readable name for the project. The maximum length is 175 characters and the name must be unique. (e.g. my-web-api)
  purpose: string # The purpose of the project. The maximum length is 255 characters. It can have one of the following values: - Just trying out DigitalOcean - Class project / Educational purposes - Website or blog - Web Application - Service or API - Mobile Application - Machine learning / AI / Data processing - IoT - Operational / Developer tooling If another value for purpose is specified, for example, "your custom purpose", your purpose will be stored as `Other: your custom purpose`. (e.g. Service or API)
]: any -> oneof<record<project: record<created_at: string, description: string, environment: string, id: string, name: string, owner_id: int, owner_uuid: string, purpose: string, updated_at: string, is_default: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects" $auth.query)
  let req_body = {"description": $description, "environment": $environment, "name": $name, "purpose": $purpose} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve the Default Project
#
# GET /v2/projects/default
# operationId: projects_get_default
export def "projects-get-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<project: record<created_at: string, description: string, environment: string, id: string, name: string, owner_id: int, owner_uuid: string, purpose: string, updated_at: string, is_default: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/default" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Patch the Default Project
#
# PATCH /v2/projects/default
# operationId: projects_patch_default
export def "projects-patch-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the project. The maximum length is 255 characters. (e.g. My website API)
  --environment: string@environment-completer # The environment of the project's resources. (e.g. Production)
  --name: string # The human-readable name for the project. The maximum length is 175 characters and the name must be unique. (e.g. my-web-api)
  --purpose: string # The purpose of the project. The maximum length is 255 characters. It can have one of the following values: - Just trying out DigitalOcean - Class project / Educational purposes - Website or blog - Web Application - Service or API - Mobile Application - Machine learning / AI / Data processing - IoT - Operational / Developer tooling If another value for purpose is specified, for example, "your custom purpose", your purpose will be stored as `Other: your custom purpose`. (e.g. Service or API)
  --is-default: oneof<nothing, bool> # If true, all resources will be added to this project if no project is specified. (e.g. false)
]: any -> oneof<record<project: record<created_at: string, description: string, environment: string, id: string, name: string, owner_id: int, owner_uuid: string, purpose: string, updated_at: string, is_default: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/default" $auth.query)
  let req_body = {"description": $description, "environment": $environment, "name": $name, "purpose": $purpose, "is_default": $is_default} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update the Default Project
#
# PUT /v2/projects/default
# operationId: projects_update_default
export def "projects-update-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # The description of the project. The maximum length is 255 characters. (e.g. My website API)
  environment: string@environment-completer # The environment of the project's resources. (e.g. Production)
  name: string # The human-readable name for the project. The maximum length is 175 characters and the name must be unique. (e.g. my-web-api)
  purpose: string # The purpose of the project. The maximum length is 255 characters. It can have one of the following values: - Just trying out DigitalOcean - Class project / Educational purposes - Website or blog - Web Application - Service or API - Mobile Application - Machine learning / AI / Data processing - IoT - Operational / Developer tooling If another value for purpose is specified, for example, "your custom purpose", your purpose will be stored as `Other: your custom purpose`. (e.g. Service or API)
  --is-default: oneof<nothing, bool> # If true, all resources will be added to this project if no project is specified. (e.g. false)
]: any -> oneof<record<project: record<created_at: string, description: string, environment: string, id: string, name: string, owner_id: int, owner_uuid: string, purpose: string, updated_at: string, is_default: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/default" $auth.query)
  let req_body = {"description": $description, "environment": $environment, "name": $name, "purpose": $purpose, "is_default": $is_default} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "is_default") == null) { error make --unspanned { msg: "required body field 'is_default' missing: pass --is-default or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List Default Project Resources
#
# GET /v2/projects/default/resources
# operationId: projects_list_resources_default
export def "projects-list-resources-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<resources: table<assigned_at: string, links: record, status: string, urn: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/default/resources" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Assign Resources to Default Project
#
# POST /v2/projects/default/resources
# operationId: projects_assign_resources_default
export def "projects-assign-resources-default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resources: list<string> # A list of uniform resource names (URNs) to be added to a project. (e.g. [do:droplet:13457723])
]: any -> oneof<record<resources: table<assigned_at: string, links: record, status: string, urn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/default/resources" $auth.query)
  let req_body = {"resources": $resources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete an Existing Project
#
# DELETE /v2/projects/{project_id}
# operationId: projects_delete
export def "projects-delete" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Project
#
# GET /v2/projects/{project_id}
# operationId: projects_get
export def "projects-get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<project: record<created_at: string, description: string, environment: string, id: string, name: string, owner_id: int, owner_uuid: string, purpose: string, updated_at: string, is_default: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Patch a Project
#
# PATCH /v2/projects/{project_id}
# operationId: projects_patch
export def "projects-patch" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the project. The maximum length is 255 characters. (e.g. My website API)
  --environment: string@environment-completer # The environment of the project's resources. (e.g. Production)
  --name: string # The human-readable name for the project. The maximum length is 175 characters and the name must be unique. (e.g. my-web-api)
  --purpose: string # The purpose of the project. The maximum length is 255 characters. It can have one of the following values: - Just trying out DigitalOcean - Class project / Educational purposes - Website or blog - Web Application - Service or API - Mobile Application - Machine learning / AI / Data processing - IoT - Operational / Developer tooling If another value for purpose is specified, for example, "your custom purpose", your purpose will be stored as `Other: your custom purpose`. (e.g. Service or API)
  --is-default: oneof<nothing, bool> # If true, all resources will be added to this project if no project is specified. (e.g. false)
]: any -> oneof<record<project: record<created_at: string, description: string, environment: string, id: string, name: string, owner_id: int, owner_uuid: string, purpose: string, updated_at: string, is_default: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}") $auth.query)
  let req_body = {"description": $description, "environment": $environment, "name": $name, "purpose": $purpose, "is_default": $is_default} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update a Project
#
# PUT /v2/projects/{project_id}
# operationId: projects_update
export def "projects-update" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # The description of the project. The maximum length is 255 characters. (e.g. My website API)
  environment: string@environment-completer # The environment of the project's resources. (e.g. Production)
  name: string # The human-readable name for the project. The maximum length is 175 characters and the name must be unique. (e.g. my-web-api)
  purpose: string # The purpose of the project. The maximum length is 255 characters. It can have one of the following values: - Just trying out DigitalOcean - Class project / Educational purposes - Website or blog - Web Application - Service or API - Mobile Application - Machine learning / AI / Data processing - IoT - Operational / Developer tooling If another value for purpose is specified, for example, "your custom purpose", your purpose will be stored as `Other: your custom purpose`. (e.g. Service or API)
  --is-default: oneof<nothing, bool> # If true, all resources will be added to this project if no project is specified. (e.g. false)
]: any -> oneof<record<project: record<created_at: string, description: string, environment: string, id: string, name: string, owner_id: int, owner_uuid: string, purpose: string, updated_at: string, is_default: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}") $auth.query)
  let req_body = {"description": $description, "environment": $environment, "name": $name, "purpose": $purpose, "is_default": $is_default} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "is_default") == null) { error make --unspanned { msg: "required body field 'is_default' missing: pass --is-default or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List Project Resources
#
# GET /v2/projects/{project_id}/resources
# operationId: projects_list_resources
export def "projects-list-resources" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<resources: table<assigned_at: string, links: record, status: string, urn: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/resources") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Assign Resources to a Project
#
# POST /v2/projects/{project_id}/resources
# operationId: projects_assign_resources
export def "projects-assign-resources" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resources: list<string> # A list of uniform resource names (URNs) to be added to a project. (e.g. [do:droplet:13457723])
]: any -> oneof<record<resources: table<assigned_at: string, links: record, status: string, urn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/resources") $auth.query)
  let req_body = {"resources": $resources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List All Data Center Regions
#
# GET /v2/regions
# operationId: regions_list
export def "regions-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<regions: table<available: bool, features: list, name: string, sizes: list, slug: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/regions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete Container Registry
#
# DELETE /v2/registry
# operationId: registry_delete
export def "registry-delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/registry" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get Container Registry Information
#
# GET /v2/registry
# operationId: registry_get
export def "registry-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<registry: record<created_at: string, name: string, region: string, storage_usage_bytes: int, storage_usage_bytes_updated_at: string, subscription: record<created_at: string, tier: record, updated_at: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/registry" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create Container Registry
#
# POST /v2/registry
# operationId: registry_create
export def "registry-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # A globally unique name for the container registry. Must be lowercase and be composed only of numbers, letters and `-`, up to a limit of 63 characters. (e.g. example)
  --region: string@region-completer-1 # Slug of the region where registry data is stored. When not provided, a region will be selected. (e.g. fra1)
  subscription_tier_slug: string@subscription-tier-slug-completer # The slug of the subscription tier to sign up for. Valid values can be retrieved using the options endpoint. (e.g. basic)
]: any -> oneof<record<registry: record<created_at: string, name: string, region: string, storage_usage_bytes: int, storage_usage_bytes_updated_at: string, subscription: record<created_at: string, tier: record, updated_at: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/registry" $auth.query)
  let req_body = {"name": $name, "region": $region, "subscription_tier_slug": $subscription_tier_slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get Docker Credentials for Container Registry
#
# GET /v2/registry/docker-credentials
# operationId: registry_get_dockerCredentials
export def "registry-get-docker-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry-seconds: int # The duration in seconds that the returned registry credentials will be valid. If not set or 0, the credentials will not expire. (default: 0, e.g. 3600)
  --read-write: oneof<nothing, bool> # By default, the registry credentials allow for read-only access. Set this query parameter to `true` to obtain read-write credentials. (default: false, e.g. true)
]: nothing -> oneof<record<auths: record<registry_digitalocean_com: record<auth: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiry_seconds" $expiry_seconds "scalar") (serialize-qp "read_write" $read_write "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/registry/docker-credentials" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"expiry_seconds": $expiry_seconds, "read_write": $read_write} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Registry Options (Subscription Tiers and Available Regions)
#
# GET /v2/registry/options
# operationId: registry_get_options
export def "registry-get-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<options: record<available_regions: list<string>, subscription_tiers: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/registry/options" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Subscription Information
#
# GET /v2/registry/subscription
# operationId: registry_get_subscription
export def "registry-get-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<subscription: record<created_at: string, tier: record<allow_storage_overage: bool, included_bandwidth_bytes: int, included_repositories: int, included_storage_bytes: int, monthly_price_in_cents: int, name: string, slug: string, storage_overage_price_in_cents: int>, updated_at: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/registry/subscription" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Subscription Tier
#
# POST /v2/registry/subscription
# operationId: registry_update_subscription
export def "registry-update-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tier-slug: string@tier-slug-completer # The slug of the subscription tier to sign up for. (e.g. basic)
]: any -> oneof<record<subscription: record<created_at: string, tier: record<allow_storage_overage: bool, included_bandwidth_bytes: int, included_repositories: int, included_storage_bytes: int, monthly_price_in_cents: int, name: string, slug: string, storage_overage_price_in_cents: int>, updated_at: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/registry/subscription" $auth.query)
  let req_body = {"tier_slug": $tier_slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Validate a Container Registry Name
#
# POST /v2/registry/validate-name
# operationId: registry_validate_name
export def "registry-validate-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # A globally unique name for the container registry. Must be lowercase and be composed only of numbers, letters and `-`, up to a limit of 63 characters. (e.g. example)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/registry/validate-name" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Active Garbage Collection
#
# GET /v2/registry/{registry_name}/garbage-collection
# operationId: registry_get_garbageCollection
export def "registry-get-garbage-collection" [
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<garbage_collection: record<blobs_deleted: int, created_at: string, freed_bytes: int, registry_name: string, status: string, updated_at: string, uuid: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registry_name' must be non-empty" } }
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name)} | format pattern "/v2/registry/{registry_name}/garbage-collection") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Start Garbage Collection
#
# POST /v2/registry/{registry_name}/garbage-collection
# operationId: registry_run_garbageCollection
export def "registry-run-garbage-collection" [
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<garbage_collection: record<blobs_deleted: int, created_at: string, freed_bytes: int, registry_name: string, status: string, updated_at: string, uuid: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registry_name' must be non-empty" } }
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name)} | format pattern "/v2/registry/{registry_name}/garbage-collection") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Update Garbage Collection
#
# PUT /v2/registry/{registry_name}/garbage-collection/{garbage_collection_uuid}
# operationId: registry_update_garbageCollection
export def "registry-update-garbage-collection" [
  registry_name: string
  garbage_collection_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cancel: oneof<nothing, bool> # A boolean value indicating that the garbage collection should be cancelled. (e.g. true)
]: any -> oneof<record<garbage_collection: record<blobs_deleted: int, created_at: string, freed_bytes: int, registry_name: string, status: string, updated_at: string, uuid: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registry_name' must be non-empty" } }
  if ($garbage_collection_uuid | is-empty) { error make --unspanned { msg: "path parameter 'garbage_collection_uuid' must be non-empty" } }
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name), garbage_collection_uuid: (encode-path-segment $garbage_collection_uuid)} | format pattern "/v2/registry/{registry_name}/garbage-collection/{garbage_collection_uuid}") $auth.query)
  let req_body = {"cancel": $cancel} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List Garbage Collections
#
# GET /v2/registry/{registry_name}/garbage-collections
# operationId: registry_list_garbageCollections
export def "registry-list-garbage-collections" [
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<garbage_collections: table<blobs_deleted: int, created_at: string, freed_bytes: int, registry_name: string, status: string, updated_at: string, uuid: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registry_name' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name)} | format pattern "/v2/registry/{registry_name}/garbage-collections") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Container Registry Repositories
#
# GET /v2/registry/{registry_name}/repositories
# DEPRECATED
# operationId: registry_list_repositories
@deprecated
export def "registry-list-repositories" [
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<repositories: table<latest_tag: record, name: string, registry_name: string, tag_count: int>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registry_name' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name)} | format pattern "/v2/registry/{registry_name}/repositories") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Container Registry Repositories (V2)
#
# GET /v2/registry/{registry_name}/repositoriesV2
# operationId: registry_list_repositoriesV2
export def "registry-list-repositories-v2" [
  registry_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. Ignored when 'page_token' is provided. (default: 1, e.g. 1)
  --page-token: string # Token to retrieve of the next or previous set of results more quickly than using 'page'. (e.g. eyJUb2tlbiI6IkNnZGpiMjlz)
]: nothing -> oneof<record<repositories: table<latest_manifest: record, manifest_count: int, name: string, registry_name: string, tag_count: int>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registry_name' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name)} | format pattern "/v2/registry/{registry_name}/repositoriesV2") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page, "page_token": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Container Registry Repository Manifests
#
# GET /v2/registry/{registry_name}/{repository_name}/digests
# operationId: registry_list_repositoryManifests
export def "registry-list-repository-manifests" [
  registry_name: string
  repository_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<manifests: table<blobs: list, compressed_size_bytes: int, digest: string, registry_name: string, repository: string, size_bytes: int, tags: list, updated_at: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registry_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name), repository_name: (encode-path-segment $repository_name)} | format pattern "/v2/registry/{registry_name}/{repository_name}/digests") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete Container Registry Repository Manifest
#
# DELETE /v2/registry/{registry_name}/{repository_name}/digests/{manifest_digest}
# operationId: registry_delete_repositoryManifest
export def "registry-delete-repository-manifest" [
  registry_name: string
  repository_name: string
  manifest_digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registry_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($manifest_digest | is-empty) { error make --unspanned { msg: "path parameter 'manifest_digest' must be non-empty" } }
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name), repository_name: (encode-path-segment $repository_name), manifest_digest: (encode-path-segment $manifest_digest)} | format pattern "/v2/registry/{registry_name}/{repository_name}/digests/{manifest_digest}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List All Container Registry Repository Tags
#
# GET /v2/registry/{registry_name}/{repository_name}/tags
# operationId: registry_list_repositoryTags
export def "registry-list-repository-tags" [
  registry_name: string
  repository_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<tags: table<compressed_size_bytes: int, manifest_digest: string, registry_name: string, repository: string, size_bytes: int, tag: string, updated_at: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registry_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name), repository_name: (encode-path-segment $repository_name)} | format pattern "/v2/registry/{registry_name}/{repository_name}/tags") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete Container Registry Repository Tag
#
# DELETE /v2/registry/{registry_name}/{repository_name}/tags/{repository_tag}
# operationId: registry_delete_repositoryTag
export def "registry-delete-repository-tag" [
  registry_name: string
  repository_name: string
  repository_tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registry_name | is-empty) { error make --unspanned { msg: "path parameter 'registry_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($repository_tag | is-empty) { error make --unspanned { msg: "path parameter 'repository_tag' must be non-empty" } }
  let full_url = (build-url $base ({registry_name: (encode-path-segment $registry_name), repository_name: (encode-path-segment $repository_name), repository_tag: (encode-path-segment $repository_tag)} | format pattern "/v2/registry/{registry_name}/{repository_name}/tags/{repository_tag}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List All Droplet Neighbors
#
# GET /v2/reports/droplet_neighbors_ids
# operationId: droplets_list_neighborsIds
export def "droplets-list-neighbors-ids" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<neighbor_ids: list<list<int>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/reports/droplet_neighbors_ids" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Reserved IPs
#
# GET /v2/reserved_ips
# operationId: reservedIPs_list
export def "reserved-i-ps-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<reserved_ips: table<droplet: any, ip: string, locked: bool, project_id: string, region: record>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/reserved_ips" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New Reserved IP
#
# POST /v2/reserved_ips
# operationId: reservedIPs_create
export def "reserved-i-ps-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --droplet-id: int # The ID of the Droplet that the reserved IP will be assigned to. (e.g. 2457247)
  --project-id: string # The UUID of the project to which the reserved IP will be assigned. (format: uuid, e.g. 746c6152-2fa2-11ed-92d3-27aaa54e4988)
  --region: string # The slug identifier for the region the reserved IP will be reserved to. (e.g. nyc3)
]: any -> oneof<record<links: record<actions: list<record>, droplets: list<record>>, reserved_ip: record<droplet: any, ip: string, locked: bool, project_id: string, region: record<available: bool, features: list, name: string, sizes: list, slug: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/reserved_ips" $auth.query)
  let req_body = {"droplet_id": $droplet_id, "project_id": $project_id, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Delete a Reserved IP
#
# DELETE /v2/reserved_ips/{reserved_ip}
# operationId: reservedIPs_delete
export def "reserved-i-ps-delete" [
  reserved_ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reserved_ip | is-empty) { error make --unspanned { msg: "path parameter 'reserved_ip' must be non-empty" } }
  let full_url = (build-url $base ({reserved_ip: (encode-path-segment $reserved_ip)} | format pattern "/v2/reserved_ips/{reserved_ip}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Reserved IP
#
# GET /v2/reserved_ips/{reserved_ip}
# operationId: reservedIPs_get
export def "reserved-i-ps-get" [
  reserved_ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<reserved_ip: record<droplet: any, ip: string, locked: bool, project_id: string, region: record<available: bool, features: list, name: string, sizes: list, slug: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reserved_ip | is-empty) { error make --unspanned { msg: "path parameter 'reserved_ip' must be non-empty" } }
  let full_url = (build-url $base ({reserved_ip: (encode-path-segment $reserved_ip)} | format pattern "/v2/reserved_ips/{reserved_ip}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Actions for a Reserved IP
#
# GET /v2/reserved_ips/{reserved_ip}/actions
# operationId: reservedIPsActions_list
export def "reserved-i-ps-actions-list" [
  reserved_ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<actions: table<completed_at: string, id: int, region: record, region_slug: string, resource_id: int, resource_type: string, started_at: string, status: string, type: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reserved_ip | is-empty) { error make --unspanned { msg: "path parameter 'reserved_ip' must be non-empty" } }
  let full_url = (build-url $base ({reserved_ip: (encode-path-segment $reserved_ip)} | format pattern "/v2/reserved_ips/{reserved_ip}/actions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Initiate a Reserved IP Action
#
# POST /v2/reserved_ips/{reserved_ip}/actions
# Discriminator (request): type = assign, unassign
# operationId: reservedIPsActions_post
export def "reserved-i-ps-actions-post" [
  reserved_ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string@type-completer-6 # The type of action to initiate for the reserved IP.
  --droplet-id: int # The ID of the Droplet that the reserved IP will be assigned to. (e.g. 758604968)
]: any -> oneof<record<action: record<completed_at: string, id: int, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, region_slug: string, resource_id: int, resource_type: string, started_at: string, status: string, type: string, project_id: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reserved_ip | is-empty) { error make --unspanned { msg: "path parameter 'reserved_ip' must be non-empty" } }
  let full_url = (build-url $base ({reserved_ip: (encode-path-segment $reserved_ip)} | format pattern "/v2/reserved_ips/{reserved_ip}/actions") $auth.query)
  let req_body = {"type": $type, "droplet_id": $droplet_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve an Existing Reserved IP Action
#
# GET /v2/reserved_ips/{reserved_ip}/actions/{action_id}
# operationId: reservedIPsActions_get
export def "reserved-i-ps-actions-get" [
  reserved_ip: string
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<action: record<completed_at: string, id: int, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, region_slug: string, resource_id: int, resource_type: string, started_at: string, status: string, type: string, project_id: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reserved_ip | is-empty) { error make --unspanned { msg: "path parameter 'reserved_ip' must be non-empty" } }
  if ($action_id | is-empty) { error make --unspanned { msg: "path parameter 'action_id' must be non-empty" } }
  let full_url = (build-url $base ({reserved_ip: (encode-path-segment $reserved_ip), action_id: (encode-path-segment $action_id)} | format pattern "/v2/reserved_ips/{reserved_ip}/actions/{action_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Droplet Sizes
#
# GET /v2/sizes
# operationId: sizes_list
export def "sizes-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<sizes: table<available: bool, description: string, disk: int, memory: int, price_hourly: float, price_monthly: float, regions: list, slug: string, transfer: float, vcpus: int>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sizes" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Snapshots
#
# GET /v2/snapshots
# operationId: snapshots_list
export def "snapshots-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
  --resource-type: string@resource-type-completer # Used to filter snapshots by a resource type. (e.g. droplet)
]: nothing -> oneof<record<snapshots: table<id: string, created_at: string, min_disk_size: int, name: string, regions: list, size_gigabytes: float, resource_id: string, resource_type: string, tags: list>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "resource_type" $resource_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/snapshots" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page, "resource_type": $resource_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a Snapshot
#
# DELETE /v2/snapshots/{snapshot_id}
# operationId: snapshots_delete
export def "snapshots-delete" [
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshot_id' must be non-empty" } }
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/v2/snapshots/{snapshot_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Snapshot
#
# GET /v2/snapshots/{snapshot_id}
# operationId: snapshots_get
export def "snapshots-get" [
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<snapshot: record<id: string, created_at: string, min_disk_size: int, name: string, regions: list<string>, size_gigabytes: float, resource_id: string, resource_type: string, tags: list<string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshot_id' must be non-empty" } }
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/v2/snapshots/{snapshot_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Tags
#
# GET /v2/tags
# operationId: tags_list
export def "tags-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<tags: table<name: string, resources: record>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/tags" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New Tag
#
# POST /v2/tags
# operationId: tags_create
export def "tags-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the tag. Tags may contain letters, numbers, colons, dashes, and underscores. There is a limit of 255 characters per tag. **Note:** Tag names are case stable, which means the capitalization you use when you first create a tag is canonical. When working with tags in the API, you must use the tag's canonical capitalization. For example, if you create a tag named "PROD", the URL to add that tag to a resource would be `https://api.digitalocean.com/v2/tags/PROD/resources` (not `/v2/tags/prod/resources`). Tagged resources in the control panel will always display the canonical capitalization. For example, if you create a tag named "PROD", you can tag resources in the control panel by entering "prod". The tag will still display with its canonical capitalization, "PROD". (e.g. extra-awesome)
]: any -> oneof<record<tag: record<name: string, resources: record<count: int, last_tagged_uri: string, databases: record, droplets: record, imgages: record, volume_snapshots: record, volumes: record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/tags" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a Tag
#
# DELETE /v2/tags/{tag_id}
# operationId: tags_delete
export def "tags-delete" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tag_id' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/v2/tags/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve a Tag
#
# GET /v2/tags/{tag_id}
# operationId: tags_get
export def "tags-get" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<tag: record<name: string, resources: record<count: int, last_tagged_uri: string, databases: record, droplets: record, imgages: record, volume_snapshots: record, volumes: record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tag_id' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/v2/tags/{tag_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Untag a Resource
#
# DELETE /v2/tags/{tag_id}/resources
# operationId: tags_unassign_resources
export def "tags-unassign-resources" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  resources: list # An array of objects containing resource_id and resource_type attributes. (e.g. [{resource_id: 9569411, resource_type: droplet}, {resource_id: 7555620, resource_type: image}, {resource_id: 3d80cb72-342b-4aaa-b92e-4e4abb24a933, resource_type: volume}]) — item shape: {resource_id?: string, resource_type?: "droplet"|"image"|"volume"|"volume_snapshot"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tag_id' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/v2/tags/{tag_id}/resources") $auth.query)
  let req_body = {"resources": $resources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [204]
}

# Tag a Resource
#
# POST /v2/tags/{tag_id}/resources
# operationId: tags_assign_resources
export def "tags-assign-resources" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  resources: list # An array of objects containing resource_id and resource_type attributes. (e.g. [{resource_id: 9569411, resource_type: droplet}, {resource_id: 7555620, resource_type: image}, {resource_id: 3d80cb72-342b-4aaa-b92e-4e4abb24a933, resource_type: volume}]) — item shape: {resource_id?: string, resource_type?: "droplet"|"image"|"volume"|"volume_snapshot"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tag_id' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/v2/tags/{tag_id}/resources") $auth.query)
  let req_body = {"resources": $resources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# List All Checks
#
# GET /v2/uptime/checks
# operationId: uptime_checks_list
export def "uptime-checks-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<checks: table<id: string, enabled: bool, name: string, regions: list, target: string, type: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/uptime/checks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New Check
#
# POST /v2/uptime/checks
# operationId: uptime_check_create
export def "uptime-check-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # A boolean value indicating whether the check is enabled/disabled. (default: true, e.g. true)
  name: string # A human-friendly display name. (e.g. Landing page check)
  regions: list<string> # An array containing the selected regions to perform healthchecks from. (e.g. [us_east, eu_west])
  target: string # The endpoint to perform healthchecks on. (format: url, e.g. https://www.landingpage.com)
  type: string@type-completer-10 # The type of health check to perform. (e.g. https)
]: any -> oneof<record<check: record<id: string, enabled: bool, name: string, regions: list<string>, target: string, type: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/uptime/checks" $auth.query)
  let req_body = {"enabled": $enabled, "name": $name, "regions": $regions, "target": $target, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "enabled") == null) { error make --unspanned { msg: "required body field 'enabled' missing: pass --enabled or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a Check
#
# DELETE /v2/uptime/checks/{check_id}
# operationId: uptime_check_delete
export def "uptime-check-delete" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'check_id' must be non-empty" } }
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v2/uptime/checks/{check_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Check
#
# GET /v2/uptime/checks/{check_id}
# operationId: uptime_check_get
export def "uptime-check-get" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<check: record<id: string, enabled: bool, name: string, regions: list<string>, target: string, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'check_id' must be non-empty" } }
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v2/uptime/checks/{check_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a Check
#
# PUT /v2/uptime/checks/{check_id}
# operationId: uptime_check_update
export def "uptime-check-update" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # A boolean value indicating whether the check is enabled/disabled. (default: true, e.g. true)
  --name: string # A human-friendly display name. (e.g. Landing page check)
  --regions: list<string> # An array containing the selected regions to perform healthchecks from. (e.g. [us_east, eu_west])
  --target: string # The endpoint to perform healthchecks on. (format: url, e.g. https://www.landingpage.com)
  --type: string@type-completer-10 # The type of health check to perform. (e.g. https)
]: any -> oneof<record<check: record<id: string, enabled: bool, name: string, regions: list<string>, target: string, type: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'check_id' must be non-empty" } }
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v2/uptime/checks/{check_id}") $auth.query)
  let req_body = {"enabled": $enabled, "name": $name, "regions": $regions, "target": $target, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List All Alerts
#
# GET /v2/uptime/checks/{check_id}/alerts
# operationId: uptime_check_alerts_list
export def "uptime-check-alerts-list" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<alerts: table<id: string, comparison: string, name: string, notifications: record, period: string, threshold: int, type: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'check_id' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v2/uptime/checks/{check_id}/alerts") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New Alert
#
# POST /v2/uptime/checks/{check_id}/alerts
# operationId: uptime_alert_create
export def "uptime-alert-create" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comparison: string@comparison-completer # The comparison operator used against the alert's threshold. (e.g. greater_than)
  name: string # A human-friendly display name. (e.g. Landing page degraded performance)
  notifications: record # The notification settings for a trigger alert. — shape: {email: list<string>, slack: list}
  --period: string@period-completer # Period of time the threshold must be exceeded to trigger the alert. (e.g. 2m)
  --threshold: int # The threshold at which the alert will enter a trigger state. The specific threshold is dependent on the alert type. (e.g. 300)
  type: string@type-completer-11 # The type of alert. (e.g. latency)
]: any -> oneof<record<alert: record<id: string, comparison: string, name: string, notifications: record<email: list, slack: list>, period: string, threshold: int, type: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'check_id' must be non-empty" } }
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v2/uptime/checks/{check_id}/alerts") $auth.query)
  let req_body = {"comparison": $comparison, "name": $name, "notifications": $notifications, "period": $period, "threshold": $threshold, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete an Alert
#
# DELETE /v2/uptime/checks/{check_id}/alerts/{alert_id}
# operationId: uptime_alert_delete
export def "uptime-alert-delete" [
  check_id: string
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'check_id' must be non-empty" } }
  if ($alert_id | is-empty) { error make --unspanned { msg: "path parameter 'alert_id' must be non-empty" } }
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id), alert_id: (encode-path-segment $alert_id)} | format pattern "/v2/uptime/checks/{check_id}/alerts/{alert_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Alert
#
# GET /v2/uptime/checks/{check_id}/alerts/{alert_id}
# operationId: uptime_alert_get
export def "uptime-alert-get" [
  check_id: string
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<alert: record<id: string, comparison: string, name: string, notifications: record<email: list, slack: list>, period: string, threshold: int, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'check_id' must be non-empty" } }
  if ($alert_id | is-empty) { error make --unspanned { msg: "path parameter 'alert_id' must be non-empty" } }
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id), alert_id: (encode-path-segment $alert_id)} | format pattern "/v2/uptime/checks/{check_id}/alerts/{alert_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update an Alert
#
# PUT /v2/uptime/checks/{check_id}/alerts/{alert_id}
# operationId: uptime_alert_update
export def "uptime-alert-update" [
  check_id: string
  alert_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comparison: string@comparison-completer # The comparison operator used against the alert's threshold. (e.g. greater_than)
  --name: string # A human-friendly display name. (e.g. Landing page degraded performance)
  --notifications: record # The notification settings for a trigger alert. — shape: {email: list<string>, slack: list}
  --period: string@period-completer # Period of time the threshold must be exceeded to trigger the alert. (e.g. 2m)
  --threshold: int # The threshold at which the alert will enter a trigger state. The specific threshold is dependent on the alert type. (e.g. 300)
  --type: string@type-completer-11 # The type of alert. (e.g. latency)
]: any -> oneof<record<alert: record<id: string, comparison: string, name: string, notifications: record<email: list, slack: list>, period: string, threshold: int, type: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'check_id' must be non-empty" } }
  if ($alert_id | is-empty) { error make --unspanned { msg: "path parameter 'alert_id' must be non-empty" } }
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id), alert_id: (encode-path-segment $alert_id)} | format pattern "/v2/uptime/checks/{check_id}/alerts/{alert_id}") $auth.query)
  let req_body = {"comparison": $comparison, "name": $name, "notifications": $notifications, "period": $period, "threshold": $threshold, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve Check State
#
# GET /v2/uptime/checks/{check_id}/state
# operationId: uptime_check_state_get
export def "uptime-check-state-get" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<state: record<previous_outage: record<duration_seconds: int, ended_at: string, region: string, started_at: string>, regions: record<eu_west: record, us_east: record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($check_id | is-empty) { error make --unspanned { msg: "path parameter 'check_id' must be non-empty" } }
  let full_url = (build-url $base ({check_id: (encode-path-segment $check_id)} | format pattern "/v2/uptime/checks/{check_id}/state") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a Block Storage Volume by Name
#
# DELETE /v2/volumes
# operationId: volumes_delete_byName
export def "volumes-delete-by-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The block storage volume's name. (e.g. example)
  --region: string@region-completer # The slug identifier for the region where the resource is available. (e.g. nyc3)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "region" $region "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/volumes" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"name": $name, "region": $region} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# List All Block Storage Volumes
#
# GET /v2/volumes
# operationId: volumes_list
export def "volumes-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The block storage volume's name. (e.g. example)
  --region: string@region-completer # The slug identifier for the region where the resource is available. (e.g. nyc3)
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<volumes: table<created_at: string, description: string, droplet_ids: list, id: string, name: string, size_gigabytes: int, tags: list, filesystem_label: string, filesystem_type: string, region: record>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/volumes" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "region": $region, "per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New Block Storage Volume
#
# POST /v2/volumes
# operationId: volumes_create
export def "volumes-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # An optional free-form text field to describe a block storage volume. (e.g. Block store for examples)
  name: string # A human-readable name for the block storage volume. Must be lowercase and be composed only of numbers, letters and "-", up to a limit of 64 characters. The name must begin with a letter. (e.g. example)
  size_gigabytes: int # The size of the block storage volume in GiB (1024^3). (e.g. 10)
  --tags: list<string> # A flat array of tag names as strings to be applied to the resource. Tag names may be for either existing or new tags. (nullable, e.g. [base-image, prod])
  --snapshot-id: string # The unique identifier for the volume snapshot from which to create the volume. (e.g. b0798135-fb76-11eb-946a-0a58ac146f33)
  --filesystem-type: string # The name of the filesystem type to be used on the volume. When provided, the volume will automatically be formatted to the specified filesystem type. Currently, the available options are `ext4` and `xfs`. Pre-formatted volumes are automatically mounted when attached to Ubuntu, Debian, Fedora, Fedora Atomic, and CentOS Droplets created on or after April 26, 2018. Attaching pre-formatted volumes to other Droplets is not recommended. (e.g. ext4)
  --filesystem-label: string # The label applied to the filesystem. Labels for ext4 type filesystems may contain 16 characters while labels for xfs type filesystems are limited to 12 characters. May only be used in conjunction with filesystem_type.
  region: string@region-completer # The slug identifier for the region where the resource will initially be available. (e.g. nyc3)
]: any -> oneof<record<volume: record<created_at: string, description: string, droplet_ids: list<int>, id: string, name: string, size_gigabytes: int, tags: list<string>, filesystem_label: string, filesystem_type: string, region: record<available: bool, features: list, name: string, sizes: list, slug: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/volumes" $auth.query)
  let req_body = {"description": $description, "name": $name, "size_gigabytes": $size_gigabytes, "tags": $tags, "snapshot_id": $snapshot_id, "filesystem_type": $filesystem_type, "filesystem_label": $filesystem_label, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Initiate A Block Storage Action By Volume Name
#
# POST /v2/volumes/actions
# Discriminator (request): type = attach, detach
# operationId: volumeActions_post
export def "volume-actions-post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
  --region: string@region-completer # The slug identifier for the region where the resource will initially be available. (e.g. nyc3)
  type: string@type-completer-12 # The volume action to initiate. (e.g. attach)
  droplet_id: int # The unique identifier for the Droplet the volume will be attached or detached from. (e.g. 11612190)
  --tags: list<string> # A flat array of tag names as strings to be applied to the resource. Tag names may be for either existing or new tags. (nullable, e.g. [base-image, prod])
]: any -> oneof<record<action: record<resource_id: int, type: string, completed_at: string, id: int, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, region_slug: string, resource_type: string, started_at: string, status: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/volumes/actions" $qp $auth.query)
  let req_body = {"region": $region, "type": $type, "droplet_id": $droplet_id, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Delete a Volume Snapshot
#
# DELETE /v2/volumes/snapshots/{snapshot_id}
# operationId: volumeSnapshots_delete_byId
export def "volume-snapshots-delete-by-id" [
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshot_id' must be non-empty" } }
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/v2/volumes/snapshots/{snapshot_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Volume Snapshot
#
# GET /v2/volumes/snapshots/{snapshot_id}
# operationId: volumeSnapshots_get_byId
export def "volume-snapshots-get-by-id" [
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<snapshot: record<id: string, created_at: string, min_disk_size: int, name: string, regions: list<string>, size_gigabytes: float, resource_id: string, resource_type: string, tags: list<string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshot_id' must be non-empty" } }
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/v2/volumes/snapshots/{snapshot_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a Block Storage Volume
#
# DELETE /v2/volumes/{volume_id}
# operationId: volumes_delete
export def "volumes-delete" [
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($volume_id | is-empty) { error make --unspanned { msg: "path parameter 'volume_id' must be non-empty" } }
  let full_url = (build-url $base ({volume_id: (encode-path-segment $volume_id)} | format pattern "/v2/volumes/{volume_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing Block Storage Volume
#
# GET /v2/volumes/{volume_id}
# operationId: volumes_get
export def "volumes-get" [
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<volume: record<created_at: string, description: string, droplet_ids: list<int>, id: string, name: string, size_gigabytes: int, tags: list<string>, filesystem_label: string, filesystem_type: string, region: record<available: bool, features: list, name: string, sizes: list, slug: string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($volume_id | is-empty) { error make --unspanned { msg: "path parameter 'volume_id' must be non-empty" } }
  let full_url = (build-url $base ({volume_id: (encode-path-segment $volume_id)} | format pattern "/v2/volumes/{volume_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List All Actions for a Volume
#
# GET /v2/volumes/{volume_id}/actions
# operationId: volumeActions_list
export def "volume-actions-list" [
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<actions: table<resource_id: int, type: string, completed_at: string, id: int, region: record, region_slug: string, resource_type: string, started_at: string, status: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($volume_id | is-empty) { error make --unspanned { msg: "path parameter 'volume_id' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({volume_id: (encode-path-segment $volume_id)} | format pattern "/v2/volumes/{volume_id}/actions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Initiate A Block Storage Action By Volume Id
#
# POST /v2/volumes/{volume_id}/actions
# Discriminator (request): type = attach, detach, resize
# operationId: volumeActions_post_byId
export def "volume-actions-post-by-id" [
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
  --region: string@region-completer # The slug identifier for the region where the resource will initially be available. (e.g. nyc3)
  type: string@type-completer-13 # The volume action to initiate. (e.g. attach)
  --droplet-id: int # The unique identifier for the Droplet the volume will be attached or detached from. (e.g. 11612190)
  --tags: list<string> # A flat array of tag names as strings to be applied to the resource. Tag names may be for either existing or new tags. (nullable, e.g. [base-image, prod])
  --size-gigabytes: int # The new size of the block storage volume in GiB (1024^3).
]: any -> oneof<record<action: record<resource_id: int, type: string, completed_at: string, id: int, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, region_slug: string, resource_type: string, started_at: string, status: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($volume_id | is-empty) { error make --unspanned { msg: "path parameter 'volume_id' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({volume_id: (encode-path-segment $volume_id)} | format pattern "/v2/volumes/{volume_id}/actions") $qp $auth.query)
  let req_body = {"region": $region, "type": $type, "droplet_id": $droplet_id, "tags": $tags, "size_gigabytes": $size_gigabytes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Retrieve an Existing Volume Action
#
# GET /v2/volumes/{volume_id}/actions/{action_id}
# operationId: volumeActions_get
export def "volume-actions-get" [
  volume_id: string
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<action: record<resource_id: int, type: string, completed_at: string, id: int, region: record<available: bool, features: list, name: string, sizes: list, slug: string>, region_slug: string, resource_type: string, started_at: string, status: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($volume_id | is-empty) { error make --unspanned { msg: "path parameter 'volume_id' must be non-empty" } }
  if ($action_id | is-empty) { error make --unspanned { msg: "path parameter 'action_id' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({volume_id: (encode-path-segment $volume_id), action_id: (encode-path-segment $action_id)} | format pattern "/v2/volumes/{volume_id}/actions/{action_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Snapshots for a Volume
#
# GET /v2/volumes/{volume_id}/snapshots
# operationId: volumeSnapshots_list
export def "volume-snapshots-list" [
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<snapshots: table<id: string, created_at: string, min_disk_size: int, name: string, regions: list, size_gigabytes: float, resource_id: string, resource_type: string, tags: list>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($volume_id | is-empty) { error make --unspanned { msg: "path parameter 'volume_id' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({volume_id: (encode-path-segment $volume_id)} | format pattern "/v2/volumes/{volume_id}/snapshots") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create Snapshot from a Volume
#
# POST /v2/volumes/{volume_id}/snapshots
# operationId: volumeSnapshots_create
export def "volume-snapshots-create" [
  volume_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # A human-readable name for the volume snapshot. (e.g. big-data-snapshot1475261774)
  --tags: list<string> # A flat array of tag names as strings to be applied to the resource. Tag names may be for either existing or new tags. (nullable, e.g. [base-image, prod])
]: any -> oneof<record<snapshot: record<id: string, created_at: string, min_disk_size: int, name: string, regions: list<string>, size_gigabytes: float, resource_id: string, resource_type: string, tags: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($volume_id | is-empty) { error make --unspanned { msg: "path parameter 'volume_id' must be non-empty" } }
  let full_url = (build-url $base ({volume_id: (encode-path-segment $volume_id)} | format pattern "/v2/volumes/{volume_id}/snapshots") $auth.query)
  let req_body = {"name": $name, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List All VPCs
#
# GET /v2/vpcs
# operationId: vpcs_list
export def "vpcs-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<vpcs: table<description: string, name: string, ip_range: string, region: string, default: bool, created_at: string, id: string, urn: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/vpcs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a New VPC
#
# POST /v2/vpcs
# operationId: vpcs_create
export def "vpcs-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A free-form text field for describing the VPC's purpose. It may be a maximum of 255 characters. (e.g. VPC for production environment)
  name: string # The name of the VPC. Must be unique and may only contain alphanumeric characters, dashes, and periods. (e.g. env.prod-vpc)
  --ip-range: string # The range of IP addresses in the VPC in CIDR notation. Network ranges cannot overlap with other networks in the same account and must be in range of private addresses as defined in RFC1918. It may not be smaller than `/28` nor larger than `/16`. If no IP range is specified, a `/20` network range is generated that won't conflict with other VPC networks in your account. (e.g. 10.10.10.0/24)
  region: string # The slug identifier for the region where the VPC will be created. (e.g. nyc1)
]: any -> oneof<record<vpc: record<description: string, name: string, ip_range: string, region: string, default: bool, created_at: string, id: string, urn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/vpcs" $auth.query)
  let req_body = {"description": $description, "name": $name, "ip_range": $ip_range, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a VPC
#
# DELETE /v2/vpcs/{vpc_id}
# operationId: vpcs_delete
export def "vpcs-delete" [
  vpc_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vpc_id | is-empty) { error make --unspanned { msg: "path parameter 'vpc_id' must be non-empty" } }
  let full_url = (build-url $base ({vpc_id: (encode-path-segment $vpc_id)} | format pattern "/v2/vpcs/{vpc_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Retrieve an Existing VPC
#
# GET /v2/vpcs/{vpc_id}
# operationId: vpcs_get
export def "vpcs-get" [
  vpc_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<vpc: record<description: string, name: string, ip_range: string, region: string, default: bool, created_at: string, id: string, urn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vpc_id | is-empty) { error make --unspanned { msg: "path parameter 'vpc_id' must be non-empty" } }
  let full_url = (build-url $base ({vpc_id: (encode-path-segment $vpc_id)} | format pattern "/v2/vpcs/{vpc_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Partially Update a VPC
#
# PATCH /v2/vpcs/{vpc_id}
# operationId: vpcs_patch
export def "vpcs-patch" [
  vpc_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A free-form text field for describing the VPC's purpose. It may be a maximum of 255 characters. (e.g. VPC for production environment)
  --name: string # The name of the VPC. Must be unique and may only contain alphanumeric characters, dashes, and periods. (e.g. env.prod-vpc)
  --default: oneof<nothing, bool> # A boolean value indicating whether or not the VPC is the default network for the region. All applicable resources are placed into the default VPC network unless otherwise specified during their creation. The `default` field cannot be unset from `true`. If you want to set a new default VPC network, update the `default` field of another VPC network in the same region. The previous network's `default` field will be set to `false` when a new default VPC has been defined. (e.g. true)
]: any -> oneof<record<vpc: record<description: string, name: string, ip_range: string, region: string, default: bool, created_at: string, id: string, urn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vpc_id | is-empty) { error make --unspanned { msg: "path parameter 'vpc_id' must be non-empty" } }
  let full_url = (build-url $base ({vpc_id: (encode-path-segment $vpc_id)} | format pattern "/v2/vpcs/{vpc_id}") $auth.query)
  let req_body = {"description": $description, "name": $name, "default": $default} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update a VPC
#
# PUT /v2/vpcs/{vpc_id}
# operationId: vpcs_update
export def "vpcs-update" [
  vpc_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A free-form text field for describing the VPC's purpose. It may be a maximum of 255 characters. (e.g. VPC for production environment)
  name: string # The name of the VPC. Must be unique and may only contain alphanumeric characters, dashes, and periods. (e.g. env.prod-vpc)
  --default: oneof<nothing, bool> # A boolean value indicating whether or not the VPC is the default network for the region. All applicable resources are placed into the default VPC network unless otherwise specified during their creation. The `default` field cannot be unset from `true`. If you want to set a new default VPC network, update the `default` field of another VPC network in the same region. The previous network's `default` field will be set to `false` when a new default VPC has been defined. (e.g. true)
]: any -> oneof<record<vpc: record<description: string, name: string, ip_range: string, region: string, default: bool, created_at: string, id: string, urn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vpc_id | is-empty) { error make --unspanned { msg: "path parameter 'vpc_id' must be non-empty" } }
  let full_url = (build-url $base ({vpc_id: (encode-path-segment $vpc_id)} | format pattern "/v2/vpcs/{vpc_id}") $auth.query)
  let req_body = {"description": $description, "name": $name, "default": $default} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List the Member Resources of a VPC
#
# GET /v2/vpcs/{vpc_id}/members
# operationId: vpcs_list_members
export def "vpcs-list-members" [
  vpc_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-type: string # Used to filter VPC members by a resource type. (e.g. droplet)
  --per-page: int # Number of items returned per page (default: 20, e.g. 2)
  --page: int # Which 'page' of paginated results to return. (default: 1, e.g. 1)
]: nothing -> oneof<record<members: table<created_at: string, name: string, urn: string>, links: record<pages: any>, meta: record<total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vpc_id | is-empty) { error make --unspanned { msg: "path parameter 'vpc_id' must be non-empty" } }
  let qp = [(serialize-qp "resource_type" $resource_type "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vpc_id: (encode-path-segment $vpc_id)} | format pattern "/v2/vpcs/{vpc_id}/members") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"resource_type": $resource_type, "per_page": $per_page, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
