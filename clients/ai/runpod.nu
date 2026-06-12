# Auto-generated client for Runpod API v0.1.0
# Source: https://rest.runpod.io/v1/openapi.json
# Auth: --token flag or $env.RUNPOD_API_TOKEN

const BASE_URL = "https://rest.runpod.io/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RUNPOD_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://rest.runpod.io/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def cloudType-completer [] { ["COMMUNITY" "SECURE"] }
def computeType-completer [] { ["CPU" "GPU"] }
def cpuFlavorPriority-completer [] { ["availability" "custom"] }
def dataCenterPriority-completer [] { ["availability" "custom"] }
def gpuTypePriority-completer [] { ["availability" "custom"] }
def desiredStatus-completer [] { ["EXITED" "RUNNING" "TERMINATED"] }
def minCudaVersion-completer [] { ["11.8" "12.0" "12.1" "12.2" "12.3" "12.4" "12.5" "12.6" "12.7" "12.8" "12.9" "13.0"] }
def scalerType-completer [] { ["QUEUE_DELAY" "REQUEST_COUNT"] }
def category-completer [] { ["AMD" "CPU" "NVIDIA"] }
def bucketSize-completer [] { ["day" "hour" "month" "week" "year"] }
def gpuTypeId-completer [] { ["AMD Instinct MI300X OAM" "NVIDIA  A30" "NVIDIA  RTX A4500" "NVIDIA A100 80GB PCIe" "NVIDIA A100-SXM4-80GB" "NVIDIA A30" "NVIDIA A40" "NVIDIA A5000 Ada" "NVIDIA B200" "NVIDIA GeForce RTX 3070" "NVIDIA GeForce RTX 3080" "NVIDIA GeForce RTX 3080 Ti" "NVIDIA GeForce RTX 3080TI" "NVIDIA GeForce RTX 3090" "NVIDIA GeForce RTX 3090 Ti" "NVIDIA GeForce RTX 4070 Ti" "NVIDIA GeForce RTX 4080" "NVIDIA GeForce RTX 4080 SUPER" "NVIDIA GeForce RTX 4090" "NVIDIA GeForce RTX 5080" "NVIDIA GeForce RTX 5090" "NVIDIA H100 80GB HBM3" "NVIDIA H100 NVL" "NVIDIA H100 PCIe" "NVIDIA H200" "NVIDIA H200 NVL" "NVIDIA L4" "NVIDIA L40" "NVIDIA L40S" "NVIDIA RTX 2000 Ada Generation" "NVIDIA RTX 4000 Ada Generation" "NVIDIA RTX 4000 SFF Ada Generation" "NVIDIA RTX 5000 Ada Generation" "NVIDIA RTX 6000 Ada Generation" "NVIDIA RTX A2000" "NVIDIA RTX A30" "NVIDIA RTX A4000" "NVIDIA RTX A4500" "NVIDIA RTX A5000" "NVIDIA RTX A6000" "NVIDIA RTX PRO 6000 Blackwell Max-Q Workstation Edition" "NVIDIA RTX PRO 6000 Blackwell Server Edition" "NVIDIA RTX PRO 6000 Blackwell Workstation Edition" "Tesla T4" "Tesla V100-FHHL-16GB" "Tesla V100-PCIE-16GB" "Tesla V100-PCIE-32GB" "Tesla V100-SXM2-16GB" "Tesla V100-SXM2-32GB"] }
def grouping-completer [] { ["gpuTypeId" "podId"] }
def grouping-completer-1 [] { ["endpointId" "gpuTypeId" "podId"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "openapijson GetOpenAPI" } } | get name | first)
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

# OpenAPI 3.0 schema
#
# GET /openapi.json
# operationId: GetOpenAPI
export def "openapijson GetOpenAPI" [
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
  let full_url = (build-url $base "/openapi.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Documentation Page
#
# GET /docs
# operationId: GetDocs
export def "docs GetDocs" [
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
  let full_url = (build-url $base "/docs")
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Pod
#
# POST /pods
# operationId: CreatePod
export def "pods CreatePod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowedCudaVersions: list # If the created Pod is a GPU Pod, a list of acceptable CUDA versions on the [Pod](#/components/schemas/Pod). If not set, any CUDA version is acceptable.
  --cloudType: string@cloudType-completer # Set to SECURE to create the Pod in Secure Cloud. Set to COMMUNITY to create the Pod in Community Cloud. To determine which one suits your needs, see https://docs.runpod.io/pods/overview#pod-types. (default: SECURE)
  --computeType: string@computeType-completer # Set to GPU to create a GPU Pod. Set to CPU to create a CPU Pod. If set to CPU, the Pod will not have a GPU attached and properties related to GPUs such as gpuTypeIds will be ignored. If set to GPU, the Pod will have a GPU attached and properties related to CPUs such as cpuFlavorIds will be ignored. (default: GPU)
  --containerDiskInGb: int # The amount of disk space, in gigabytes (GB), to allocate on the container disk for the created Pod. The data on the container disk is wiped when the Pod restarts. To persist data across Pod restarts, set volumeInGb to configure the Pod network volume. (nullable, default: 50)
  --containerRegistryAuthId: string # Registry credentials ID. (e.g. clzdaifot0001l90809257ynb)
  --countryCodes: list # A list of country codes where the created Pod can be located. If not set, the Pod can be located in any country.
  --cpuFlavorIds: list # If the created Pod is a CPU Pod, a list of Runpod CPU flavors which can be attached to the Pod. The order of the list determines the order to rent CPU flavors. See cpuFlavorPriority for how the order of the list affects Pod creation.
  --cpuFlavorPriority: string@cpuFlavorPriority-completer # If the created Pod is a CPU Pod, set to availability to respond to current CPU flavor availability. Set to custom to always try to rent CPU flavors in the order specified in cpuFlavorIds. (default: availability)
  --dataCenterIds: list # A list of Runpod data center IDs where the created Pod can be located. See `dataCenterPriority` for information on how the order of the list affects Pod creation. (default: [EU-RO-1, CA-MTL-1, EU-SE-1, US-IL-1, EUR-IS-1, EU-CZ-1, US-TX-3, EUR-IS-2, US-KS-2, US-GA-2, US-WA-1, US-TX-1, CA-MTL-3, EU-NL-1, US-TX-4, US-CA-2, US-NC-1, OC-AU-1, US-DE-1, EUR-IS-3, CA-MTL-2, AP-JP-1, EUR-NO-1, EU-FR-1, US-KS-3, US-GA-1, AP-IN-1, US-MD-1], e.g. [EU-RO-1, CA-MTL-1])
  --dataCenterPriority: string@dataCenterPriority-completer # Set to availability to respond to current machine availability. Set to custom to always try to rent machines from data centers in the order specified in dataCenterIds. (default: availability)
  --dockerEntrypoint: list # If specified, overrides the ENTRYPOINT for the Docker image run on the created Pod. If [], uses the ENTRYPOINT defined in the image. (default: [])
  --dockerStartCmd: list # If specified, overrides the start CMD for the Docker image run on the created Pod. If [], uses the start CMD defined in the image. (default: [])
  --env: record # default: {}, e.g. {ENV_VAR: value}
  --globalNetworking: oneof<nothing, bool> # Set to true to enable global networking for the created Pod. Currently only available for On-Demand GPU Pods on some Secure Cloud data centers. (default: false, e.g. true)
  --gpuCount: int # If the created Pod is a GPU Pod, the number of GPUs attached to the created Pod. (default: 1)
  --gpuTypeIds: list # If the created Pod is a GPU Pod, a list of Runpod GPU types which can be attached to the created Pod. The order of the list determines the order to rent GPU types. See `gpuTypePriority` for information on how the order of the list affects Pod creation.
  --gpuTypePriority: string@gpuTypePriority-completer # If the created Pod is a GPU Pod, set to availability to respond to current GPU type availability. Set to custom to always try to rent GPU types in the order specified in gpuTypeIds. (default: availability)
  --imageName: string # The image tag for the container run on the created Pod. (e.g. runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04)
  --interruptible: oneof<nothing, bool> # Set to true to create an interruptible or spot Pod. An interruptible Pod can be rented at a lower cost but can be stopped at any time to free up resources for another Pod. A reserved Pod is rented at a higher cost but runs until it exits or is manually stopped. (default: false)
  --locked: oneof<nothing, bool> # Set to true to lock a Pod. Locking a Pod disables stopping or resetting the Pod. (default: false)
  --minDiskBandwidthMBps: float # The minimum disk bandwidth, in megabytes per second (MBps), for the created Pod.
  --minDownloadMbps: float # The minimum download speed, in megabits per second (Mbps), for the created Pod.
  --minRAMPerGPU: int # If the created Pod is a GPU Pod, the minimum amount of RAM, in gigabytes (GB), allocated to the created Pod for each GPU attached to the Pod. (default: 8)
  --minUploadMbps: float # The minimum upload speed, in megabits per second (Mbps), for the created Pod.
  --minVCPUPerGPU: int # If the created Pod is a GPU Pod, the minimum number of virtual CPUs allocated to the created Pod for each GPU attached to the Pod. (default: 2)
  --name: string # A user-defined name for the created Pod. The name does not need to be unique. (default: my pod)
  --networkVolumeId: string # The unique string identifying the network volume to attach to the created Pod. If attached, a network volume replaces the Pod network volume.
  --ports: list # A list of ports exposed on the created Pod. Each port is formatted as [port number]/[protocol]. Protocol can be either http or tcp. (default: 8888/http,22/tcp, e.g. [8888/http, 22/tcp])
  --supportPublicIp: oneof<nothing, bool> # If the created Pod is on Community Cloud, set to true if you need the Pod to expose a public IP address. If null, the Pod might not have a public IP address. On Secure Cloud, the Pod will always have a public IP address. (e.g. true)
  --templateId: string # If the Pod is created with a template, the unique string identifying that template.
  --vcpuCount: int # If the created Pod is a CPU Pod, the number of vCPUs allocated to the Pod. (default: 2)
  --volumeInGb: int # The amount of disk space, in gigabytes (GB), to allocate on the Pod volume for the created Pod. The data on the Pod volume is persisted across Pod restarts. To persist data so that future Pods can access it, create a network volume and set networkVolumeId to attach it to the Pod. (nullable, default: 20)
  --volumeMountPath: string # If either a Pod volume or a network volume is attached to a Pod, the absolute path where the network volume will be mounted in the filesystem. (default: /workspace)
]: any -> record<adjustedCostPerHr: float, aiApiId: string, consumerUserId: string, containerDiskInGb: int, containerRegistryAuthId: string, costPerHr: float, cpuFlavorId: string, desiredStatus: string, dockerEntrypoint: list<string>, dockerStartCmd: list<string>, endpointId: string, env: record, gpu: record<id: string, count: int, displayName: string, securePrice: float, communityPrice: float, oneMonthPrice: float, threeMonthPrice: float, sixMonthPrice: float, oneWeekPrice: float, communitySpotPrice: float, secureSpotPrice: float>, id: string, image: string, interruptible: bool, lastStartedAt: string, lastStatusChange: string, locked: bool, machine: record<minPodGpuCount: int, gpuTypeId: string, gpuType: record<id: string, count: int, displayName: string, securePrice: float, communityPrice: float, oneMonthPrice: float, threeMonthPrice: float, sixMonthPrice: float, oneWeekPrice: float, communitySpotPrice: float, secureSpotPrice: float>, cpuCount: int, cpuTypeId: string, cpuType: record<id: string, displayName: string, cores: float, threadsPerCore: float, groupId: string>, location: string, dataCenterId: string, diskThroughputMBps: int, maxDownloadSpeedMbps: int, maxUploadSpeedMbps: int, supportPublicIp: bool, secureCloud: bool, maintenanceStart: string, maintenanceEnd: string, maintenanceNote: string, note: string, costPerHr: float, currentPricePerGpu: float, gpuAvailable: int, gpuDisplayName: string>, machineId: string, memoryInGb: float, name: string, networkVolume: record<id: string, name: string, size: int, dataCenterId: string>, portMappings: record, ports: list<string>, publicIp: string, savingsPlans: table<costPerHr: float, endTime: string, gpuTypeId: string, id: string, podId: string, startTime: string>, slsVersion: int, templateId: string, vcpuCount: float, volumeEncrypted: bool, volumeInGb: int, volumeMountPath: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pods")
  let body = {allowedCudaVersions: $allowedCudaVersions, cloudType: $cloudType, computeType: $computeType, containerDiskInGb: $containerDiskInGb, containerRegistryAuthId: $containerRegistryAuthId, countryCodes: $countryCodes, cpuFlavorIds: $cpuFlavorIds, cpuFlavorPriority: $cpuFlavorPriority, dataCenterIds: $dataCenterIds, dataCenterPriority: $dataCenterPriority, dockerEntrypoint: $dockerEntrypoint, dockerStartCmd: $dockerStartCmd, env: $env, globalNetworking: $globalNetworking, gpuCount: $gpuCount, gpuTypeIds: $gpuTypeIds, gpuTypePriority: $gpuTypePriority, imageName: $imageName, interruptible: $interruptible, locked: $locked, minDiskBandwidthMBps: $minDiskBandwidthMBps, minDownloadMbps: $minDownloadMbps, minRAMPerGPU: $minRAMPerGPU, minUploadMbps: $minUploadMbps, minVCPUPerGPU: $minVCPUPerGPU, name: $name, networkVolumeId: $networkVolumeId, ports: $ports, supportPublicIp: $supportPublicIp, templateId: $templateId, vcpuCount: $vcpuCount, volumeInGb: $volumeInGb, volumeMountPath: $volumeMountPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Pods
#
# GET /pods
# operationId: ListPods
export def "pods ListPods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --computeType: string@computeType-completer # e.g. CPU
  --cpuFlavorId: list # e.g. [cpu3c, cpu5g]
  --dataCenterId: list # e.g. [EU-RO-1]
  --desiredStatus: string@desiredStatus-completer # e.g. RUNNING
  --endpointId: string
  --gpuTypeId: list # e.g. [NVIDIA GeForce RTX 4090, NVIDIA RTX A5000]
  --id: string # e.g. xedezhzb9la3ye
  --imageName: string # e.g. runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04
  --includeMachine: oneof<nothing, bool> # default: false, e.g. true
  --includeNetworkVolume: oneof<nothing, bool> # default: false, e.g. true
  --includeSavingsPlans: oneof<nothing, bool> # default: false, e.g. true
  --includeTemplate: oneof<nothing, bool> # default: false, e.g. true
  --includeWorkers: oneof<nothing, bool> # default: false, e.g. true
  --name: string
  --networkVolumeId: string # e.g. agv6w2qcg7
  --templateId: string # e.g. 30zmvf89kd
]: nothing -> table<adjustedCostPerHr: float, aiApiId: string, consumerUserId: string, containerDiskInGb: int, containerRegistryAuthId: string, costPerHr: float, cpuFlavorId: string, desiredStatus: string, dockerEntrypoint: list<string>, dockerStartCmd: list<string>, endpointId: string, env: record, gpu: record<id: string, count: int, displayName: string, securePrice: float, communityPrice: float, oneMonthPrice: float, threeMonthPrice: float, sixMonthPrice: float, oneWeekPrice: float, communitySpotPrice: float, secureSpotPrice: float>, id: string, image: string, interruptible: bool, lastStartedAt: string, lastStatusChange: string, locked: bool, machine: record<minPodGpuCount: int, gpuTypeId: string, gpuType: record, cpuCount: int, cpuTypeId: string, cpuType: record, location: string, dataCenterId: string, diskThroughputMBps: int, maxDownloadSpeedMbps: int, maxUploadSpeedMbps: int, supportPublicIp: bool, secureCloud: bool, maintenanceStart: string, maintenanceEnd: string, maintenanceNote: string, note: string, costPerHr: float, currentPricePerGpu: float, gpuAvailable: int, gpuDisplayName: string>, machineId: string, memoryInGb: float, name: string, networkVolume: record<id: string, name: string, size: int, dataCenterId: string>, portMappings: record, ports: list<string>, publicIp: string, savingsPlans: list<record>, slsVersion: int, templateId: string, vcpuCount: float, volumeEncrypted: bool, volumeInGb: int, volumeMountPath: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "computeType" $computeType "scalar") (serialize-qp "cpuFlavorId" $cpuFlavorId "multi") (serialize-qp "dataCenterId" $dataCenterId "multi") (serialize-qp "desiredStatus" $desiredStatus "scalar") (serialize-qp "endpointId" $endpointId "scalar") (serialize-qp "gpuTypeId" $gpuTypeId "multi") (serialize-qp "id" $id "scalar") (serialize-qp "imageName" $imageName "scalar") (serialize-qp "includeMachine" $includeMachine "scalar") (serialize-qp "includeNetworkVolume" $includeNetworkVolume "scalar") (serialize-qp "includeSavingsPlans" $includeSavingsPlans "scalar") (serialize-qp "includeTemplate" $includeTemplate "scalar") (serialize-qp "includeWorkers" $includeWorkers "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "networkVolumeId" $networkVolumeId "scalar") (serialize-qp "templateId" $templateId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find a Pod by ID
#
# GET /pods/{podId}
# operationId: GetPod
export def "pods GetPod" [
  podId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeMachine: oneof<nothing, bool> # default: false, e.g. true
  --includeNetworkVolume: oneof<nothing, bool> # default: false, e.g. true
  --includeSavingsPlans: oneof<nothing, bool> # default: false, e.g. true
  --includeTemplate: oneof<nothing, bool> # default: false, e.g. true
  --includeWorkers: oneof<nothing, bool> # default: false, e.g. true
]: nothing -> record<adjustedCostPerHr: float, aiApiId: string, consumerUserId: string, containerDiskInGb: int, containerRegistryAuthId: string, costPerHr: float, cpuFlavorId: string, desiredStatus: string, dockerEntrypoint: list<string>, dockerStartCmd: list<string>, endpointId: string, env: record, gpu: record<id: string, count: int, displayName: string, securePrice: float, communityPrice: float, oneMonthPrice: float, threeMonthPrice: float, sixMonthPrice: float, oneWeekPrice: float, communitySpotPrice: float, secureSpotPrice: float>, id: string, image: string, interruptible: bool, lastStartedAt: string, lastStatusChange: string, locked: bool, machine: record<minPodGpuCount: int, gpuTypeId: string, gpuType: record<id: string, count: int, displayName: string, securePrice: float, communityPrice: float, oneMonthPrice: float, threeMonthPrice: float, sixMonthPrice: float, oneWeekPrice: float, communitySpotPrice: float, secureSpotPrice: float>, cpuCount: int, cpuTypeId: string, cpuType: record<id: string, displayName: string, cores: float, threadsPerCore: float, groupId: string>, location: string, dataCenterId: string, diskThroughputMBps: int, maxDownloadSpeedMbps: int, maxUploadSpeedMbps: int, supportPublicIp: bool, secureCloud: bool, maintenanceStart: string, maintenanceEnd: string, maintenanceNote: string, note: string, costPerHr: float, currentPricePerGpu: float, gpuAvailable: int, gpuDisplayName: string>, machineId: string, memoryInGb: float, name: string, networkVolume: record<id: string, name: string, size: int, dataCenterId: string>, portMappings: record, ports: list<string>, publicIp: string, savingsPlans: table<costPerHr: float, endTime: string, gpuTypeId: string, id: string, podId: string, startTime: string>, slsVersion: int, templateId: string, vcpuCount: float, volumeEncrypted: bool, volumeInGb: int, volumeMountPath: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeMachine" $includeMachine "scalar") (serialize-qp "includeNetworkVolume" $includeNetworkVolume "scalar") (serialize-qp "includeSavingsPlans" $includeSavingsPlans "scalar") (serialize-qp "includeTemplate" $includeTemplate "scalar") (serialize-qp "includeWorkers" $includeWorkers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/pods/($podId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Pod
#
# PATCH /pods/{podId}
# operationId: UpdatePod
export def "pods UpdatePod" [
  podId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --containerDiskInGb: int # The amount of disk space, in gigabytes (GB), to allocate on the container disk for the created Pod. The data on the container disk is wiped when the Pod restarts. To persist data across Pod restarts, set volumeInGb to configure the Pod network volume. (nullable, default: 50)
  --containerRegistryAuthId: string # Registry credentials ID. (e.g. clzdaifot0001l90809257ynb)
  --dockerEntrypoint: list # If specified, overrides the ENTRYPOINT for the Docker image run on the created Pod. If [], uses the ENTRYPOINT defined in the image. (default: [])
  --dockerStartCmd: list # If specified, overrides the start CMD for the Docker image run on the created Pod. If [], uses the start CMD defined in the image. (default: [])
  --env: record # default: {}, e.g. {ENV_VAR: value}
  --globalNetworking: oneof<nothing, bool> # Set to true to enable global networking for the created Pod. Currently only available for On-Demand GPU Pods on some Secure Cloud data centers. (default: false, e.g. true)
  --imageName: string # The image tag for the container run on the created Pod. (e.g. runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04)
  --locked: oneof<nothing, bool> # Set to true to lock a Pod. Locking a Pod disables stopping or resetting the Pod. (default: false)
  --name: string # A user-defined name for the created Pod. The name does not need to be unique. (default: my pod)
  --ports: list # A list of ports exposed on the created Pod. Each port is formatted as [port number]/[protocol]. Protocol can be either http or tcp. (default: 8888/http,22/tcp, e.g. [8888/http, 22/tcp])
  --volumeInGb: int # The amount of disk space, in gigabytes (GB), to allocate on the Pod volume for the created Pod. The data on the Pod volume is persisted across Pod restarts. To persist data so that future Pods can access it, create a network volume and set networkVolumeId to attach it to the Pod. (nullable, default: 20)
  --volumeMountPath: string # If either a Pod volume or a network volume is attached to a Pod, the absolute path where the network volume will be mounted in the filesystem. (default: /workspace)
]: any -> record<adjustedCostPerHr: float, aiApiId: string, consumerUserId: string, containerDiskInGb: int, containerRegistryAuthId: string, costPerHr: float, cpuFlavorId: string, desiredStatus: string, dockerEntrypoint: list<string>, dockerStartCmd: list<string>, endpointId: string, env: record, gpu: record<id: string, count: int, displayName: string, securePrice: float, communityPrice: float, oneMonthPrice: float, threeMonthPrice: float, sixMonthPrice: float, oneWeekPrice: float, communitySpotPrice: float, secureSpotPrice: float>, id: string, image: string, interruptible: bool, lastStartedAt: string, lastStatusChange: string, locked: bool, machine: record<minPodGpuCount: int, gpuTypeId: string, gpuType: record<id: string, count: int, displayName: string, securePrice: float, communityPrice: float, oneMonthPrice: float, threeMonthPrice: float, sixMonthPrice: float, oneWeekPrice: float, communitySpotPrice: float, secureSpotPrice: float>, cpuCount: int, cpuTypeId: string, cpuType: record<id: string, displayName: string, cores: float, threadsPerCore: float, groupId: string>, location: string, dataCenterId: string, diskThroughputMBps: int, maxDownloadSpeedMbps: int, maxUploadSpeedMbps: int, supportPublicIp: bool, secureCloud: bool, maintenanceStart: string, maintenanceEnd: string, maintenanceNote: string, note: string, costPerHr: float, currentPricePerGpu: float, gpuAvailable: int, gpuDisplayName: string>, machineId: string, memoryInGb: float, name: string, networkVolume: record<id: string, name: string, size: int, dataCenterId: string>, portMappings: record, ports: list<string>, publicIp: string, savingsPlans: table<costPerHr: float, endTime: string, gpuTypeId: string, id: string, podId: string, startTime: string>, slsVersion: int, templateId: string, vcpuCount: float, volumeEncrypted: bool, volumeInGb: int, volumeMountPath: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pods/($podId)")
  let body = {containerDiskInGb: $containerDiskInGb, containerRegistryAuthId: $containerRegistryAuthId, dockerEntrypoint: $dockerEntrypoint, dockerStartCmd: $dockerStartCmd, env: $env, globalNetworking: $globalNetworking, imageName: $imageName, locked: $locked, name: $name, ports: $ports, volumeInGb: $volumeInGb, volumeMountPath: $volumeMountPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Pod
#
# DELETE /pods/{podId}
# operationId: DeletePod
export def "pods DeletePod" [
  podId: string
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
  let full_url = (build-url $base $"/pods/($podId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Pod
#
# POST /pods/{podId}/update
# operationId: UpdatePod
export def "pods-update UpdatePod" [
  podId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --containerDiskInGb: int # The amount of disk space, in gigabytes (GB), to allocate on the container disk for the created Pod. The data on the container disk is wiped when the Pod restarts. To persist data across Pod restarts, set volumeInGb to configure the Pod network volume. (nullable, default: 50)
  --containerRegistryAuthId: string # Registry credentials ID. (e.g. clzdaifot0001l90809257ynb)
  --dockerEntrypoint: list # If specified, overrides the ENTRYPOINT for the Docker image run on the created Pod. If [], uses the ENTRYPOINT defined in the image. (default: [])
  --dockerStartCmd: list # If specified, overrides the start CMD for the Docker image run on the created Pod. If [], uses the start CMD defined in the image. (default: [])
  --env: record # default: {}, e.g. {ENV_VAR: value}
  --globalNetworking: oneof<nothing, bool> # Set to true to enable global networking for the created Pod. Currently only available for On-Demand GPU Pods on some Secure Cloud data centers. (default: false, e.g. true)
  --imageName: string # The image tag for the container run on the created Pod. (e.g. runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04)
  --locked: oneof<nothing, bool> # Set to true to lock a Pod. Locking a Pod disables stopping or resetting the Pod. (default: false)
  --name: string # A user-defined name for the created Pod. The name does not need to be unique. (default: my pod)
  --ports: list # A list of ports exposed on the created Pod. Each port is formatted as [port number]/[protocol]. Protocol can be either http or tcp. (default: 8888/http,22/tcp, e.g. [8888/http, 22/tcp])
  --volumeInGb: int # The amount of disk space, in gigabytes (GB), to allocate on the Pod volume for the created Pod. The data on the Pod volume is persisted across Pod restarts. To persist data so that future Pods can access it, create a network volume and set networkVolumeId to attach it to the Pod. (nullable, default: 20)
  --volumeMountPath: string # If either a Pod volume or a network volume is attached to a Pod, the absolute path where the network volume will be mounted in the filesystem. (default: /workspace)
]: any -> record<adjustedCostPerHr: float, aiApiId: string, consumerUserId: string, containerDiskInGb: int, containerRegistryAuthId: string, costPerHr: float, cpuFlavorId: string, desiredStatus: string, dockerEntrypoint: list<string>, dockerStartCmd: list<string>, endpointId: string, env: record, gpu: record<id: string, count: int, displayName: string, securePrice: float, communityPrice: float, oneMonthPrice: float, threeMonthPrice: float, sixMonthPrice: float, oneWeekPrice: float, communitySpotPrice: float, secureSpotPrice: float>, id: string, image: string, interruptible: bool, lastStartedAt: string, lastStatusChange: string, locked: bool, machine: record<minPodGpuCount: int, gpuTypeId: string, gpuType: record<id: string, count: int, displayName: string, securePrice: float, communityPrice: float, oneMonthPrice: float, threeMonthPrice: float, sixMonthPrice: float, oneWeekPrice: float, communitySpotPrice: float, secureSpotPrice: float>, cpuCount: int, cpuTypeId: string, cpuType: record<id: string, displayName: string, cores: float, threadsPerCore: float, groupId: string>, location: string, dataCenterId: string, diskThroughputMBps: int, maxDownloadSpeedMbps: int, maxUploadSpeedMbps: int, supportPublicIp: bool, secureCloud: bool, maintenanceStart: string, maintenanceEnd: string, maintenanceNote: string, note: string, costPerHr: float, currentPricePerGpu: float, gpuAvailable: int, gpuDisplayName: string>, machineId: string, memoryInGb: float, name: string, networkVolume: record<id: string, name: string, size: int, dataCenterId: string>, portMappings: record, ports: list<string>, publicIp: string, savingsPlans: table<costPerHr: float, endTime: string, gpuTypeId: string, id: string, podId: string, startTime: string>, slsVersion: int, templateId: string, vcpuCount: float, volumeEncrypted: bool, volumeInGb: int, volumeMountPath: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pods/($podId)/update")
  let body = {containerDiskInGb: $containerDiskInGb, containerRegistryAuthId: $containerRegistryAuthId, dockerEntrypoint: $dockerEntrypoint, dockerStartCmd: $dockerStartCmd, env: $env, globalNetworking: $globalNetworking, imageName: $imageName, locked: $locked, name: $name, ports: $ports, volumeInGb: $volumeInGb, volumeMountPath: $volumeMountPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Start or resume a Pod
#
# POST /pods/{podId}/start
# operationId: StartPod
export def "pods-start StartPod" [
  podId: string
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
  let full_url = (build-url $base $"/pods/($podId)/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop a Pod
#
# POST /pods/{podId}/stop
# operationId: StopPod
export def "pods-stop StopPod" [
  podId: string
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
  let full_url = (build-url $base $"/pods/($podId)/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset a Pod
#
# POST /pods/{podId}/reset
# operationId: ResetPod
export def "pods-reset ResetPod" [
  podId: string
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
  let full_url = (build-url $base $"/pods/($podId)/reset")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restart a Pod
#
# POST /pods/{podId}/restart
# operationId: RestartPod
export def "pods-restart RestartPod" [
  podId: string
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
  let full_url = (build-url $base $"/pods/($podId)/restart")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new endpoint
#
# POST /endpoints
# operationId: CreateEndpoint
export def "endpoints CreateEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowedCudaVersions: list # If the created Serverless endpoint is a GPU endpoint, a list of acceptable CUDA versions on the created workers. If not set, any CUDA version is acceptable.
  --computeType: string@computeType-completer # Set to GPU to create a Serverless endpoint with GPU workers. Set to CPU to create a Serverless endpoint with CPU workers. If set to CPU, properties related to GPUs such as gpuTypeIds will be ignored. If set to GPU, properties related to CPUs such as cpuFlavorIds will be ignored. (default: GPU)
  --cpuFlavorIds: list # If the created Serverless endpoint is a CPU endpoint, a list of Runpod CPU flavors which can be attached to the created workers. The order of the list determines the order to rent CPU flavors.
  --dataCenterIds: list # A list of Runpod data center IDs where workers on the created Serverless endpoint can be located. (default: [EU-RO-1, CA-MTL-1, EU-SE-1, US-IL-1, EUR-IS-1, EU-CZ-1, US-TX-3, EUR-IS-2, US-KS-2, US-GA-2, US-WA-1, US-TX-1, CA-MTL-3, EU-NL-1, US-TX-4, US-CA-2, US-NC-1, OC-AU-1, US-DE-1, EUR-IS-3, CA-MTL-2, AP-JP-1, EUR-NO-1, EU-FR-1, US-KS-3, US-GA-1, AP-IN-1, US-MD-1], e.g. [EU-RO-1, CA-MTL-1])
  --executionTimeoutMs: int # The maximum number of milliseconds an individual request can run on a Serverless endpoint before the worker is stopped and the request is marked as failed. (e.g. 600000)
  --flashboot: oneof<nothing, bool> # Whether to use flash boot for the created Serverless endpoint. (e.g. true)
  --gpuCount: int # If the created Serverless endpoint is a GPU endpoint, the number of GPUs attached to each worker on the endpoint. (default: 1)
  --gpuTypeIds: list # If the created Serverless endpoint is a GPU endpoint, a list of Runpod GPU types which can be attached to the created workers. The order of the list determines the order to rent GPU types.
  --idleTimeout: int # The number of seconds a worker on the created Serverless endpoint can run without taking a job before the worker is scaled down. (default: 5)
  --minCudaVersion: string@minCudaVersion-completer # If the created Serverless endpoint is a GPU endpoint, the minimum acceptable CUDA version on the created workers.
  --name: string # A user-defined name for the created Serverless endpoint. The name does not need to be unique.
  --networkVolumeId: string # The unique string identifying the network volume to attach to the created Serverless endpoint.
  --networkVolumeIds: list # A list of network volume IDs to attach to the created Serverless endpoint. Allows multiple network volumes to be used with multi-region endpoints.
  --scalerType: string@scalerType-completer # The method used to scale up workers on the created Serverless endpoint. If QUEUE_DELAY, workers are scaled based on a periodic check to see if any requests have been in queue for too long. If REQUEST_COUNT, the desired number of workers is periodically calculated based on the number of requests in the endpoint's queue. Use QUEUE_DELAY if you need to ensure requests take no longer than a maximum latency, and use REQUEST_COUNT if you need to scale based on the number of requests. (default: QUEUE_DELAY)
  --scalerValue: int # If the endpoint scalerType is QUEUE_DELAY, the number of seconds a request can remain in queue before a new worker is scaled up. If the endpoint scalerType is REQUEST_COUNT, the number of workers is increased as needed to meet the number of requests in the endpoint's queue divided by scalerValue. (default: 4)
  templateId: string # The unique string identifying the template used to create the Serverless endpoint. (e.g. 30zmvf89kd)
  --vcpuCount: int # If the created Serverless endpoint is a CPU endpoint, the number of vCPUs allocated to each created worker. (default: 2)
  --workersMax: int # The maximum number of workers that can be running at the same time on a Serverless endpoint. (e.g. 3)
  --workersMin: int # The minimum number of workers that will run at the same time on a Serverless endpoint. This number of workers will always stay running for the endpoint, and will be charged even if no requests are being processed, but they are charged at a lower rate than running autoscaling workers. (e.g. 0)
]: any -> record<allowedCudaVersions: list<string>, computeType: string, createdAt: string, dataCenterIds: list<string>, env: record, executionTimeoutMs: int, gpuCount: int, gpuTypeIds: list<string>, id: string, idleTimeout: int, instanceIds: list<string>, minCudaVersion: string, name: string, networkVolumeId: string, networkVolumeIds: list<string>, scalerType: string, scalerValue: int, template: record<category: string, containerDiskInGb: int, containerRegistryAuthId: string, dockerEntrypoint: list<string>, dockerStartCmd: list<string>, earned: float, env: record, id: string, imageName: string, isPublic: bool, isRunpod: bool, isServerless: bool, name: string, ports: list<string>, readme: string, runtimeInMin: int, volumeInGb: int, volumeMountPath: string>, templateId: string, userId: string, version: int, workers: table<adjustedCostPerHr: float, aiApiId: string, consumerUserId: string, containerDiskInGb: int, containerRegistryAuthId: string, costPerHr: float, cpuFlavorId: string, desiredStatus: string, dockerEntrypoint: list, dockerStartCmd: list, endpointId: string, env: record, gpu: record, id: string, image: string, interruptible: bool, lastStartedAt: string, lastStatusChange: string, locked: bool, machine: record, machineId: string, memoryInGb: float, name: string, networkVolume: record, portMappings: record, ports: list, publicIp: string, savingsPlans: list, slsVersion: int, templateId: string, vcpuCount: float, volumeEncrypted: bool, volumeInGb: int, volumeMountPath: string>, workersMax: int, workersMin: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/endpoints")
  let body = {allowedCudaVersions: $allowedCudaVersions, computeType: $computeType, cpuFlavorIds: $cpuFlavorIds, dataCenterIds: $dataCenterIds, executionTimeoutMs: $executionTimeoutMs, flashboot: $flashboot, gpuCount: $gpuCount, gpuTypeIds: $gpuTypeIds, idleTimeout: $idleTimeout, minCudaVersion: $minCudaVersion, name: $name, networkVolumeId: $networkVolumeId, networkVolumeIds: $networkVolumeIds, scalerType: $scalerType, scalerValue: $scalerValue, templateId: $templateId, vcpuCount: $vcpuCount, workersMax: $workersMax, workersMin: $workersMin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List endpoints
#
# GET /endpoints
# operationId: ListEndpoints
export def "endpoints ListEndpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeTemplate: oneof<nothing, bool> # default: false, e.g. true
  --includeWorkers: oneof<nothing, bool> # default: false, e.g. true
]: nothing -> table<allowedCudaVersions: list<string>, computeType: string, createdAt: string, dataCenterIds: list<string>, env: record, executionTimeoutMs: int, gpuCount: int, gpuTypeIds: list<string>, id: string, idleTimeout: int, instanceIds: list<string>, minCudaVersion: string, name: string, networkVolumeId: string, networkVolumeIds: list<string>, scalerType: string, scalerValue: int, template: record<category: string, containerDiskInGb: int, containerRegistryAuthId: string, dockerEntrypoint: list, dockerStartCmd: list, earned: float, env: record, id: string, imageName: string, isPublic: bool, isRunpod: bool, isServerless: bool, name: string, ports: list, readme: string, runtimeInMin: int, volumeInGb: int, volumeMountPath: string>, templateId: string, userId: string, version: int, workers: list<record>, workersMax: int, workersMin: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeTemplate" $includeTemplate "scalar") (serialize-qp "includeWorkers" $includeWorkers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/endpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find an endpoint by ID
#
# GET /endpoints/{endpointId}
# operationId: GetEndpoint
export def "endpoints GetEndpoint" [
  endpointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeTemplate: oneof<nothing, bool> # default: false, e.g. true
  --includeWorkers: oneof<nothing, bool> # default: false, e.g. true
]: nothing -> record<allowedCudaVersions: list<string>, computeType: string, createdAt: string, dataCenterIds: list<string>, env: record, executionTimeoutMs: int, gpuCount: int, gpuTypeIds: list<string>, id: string, idleTimeout: int, instanceIds: list<string>, minCudaVersion: string, name: string, networkVolumeId: string, networkVolumeIds: list<string>, scalerType: string, scalerValue: int, template: record<category: string, containerDiskInGb: int, containerRegistryAuthId: string, dockerEntrypoint: list<string>, dockerStartCmd: list<string>, earned: float, env: record, id: string, imageName: string, isPublic: bool, isRunpod: bool, isServerless: bool, name: string, ports: list<string>, readme: string, runtimeInMin: int, volumeInGb: int, volumeMountPath: string>, templateId: string, userId: string, version: int, workers: table<adjustedCostPerHr: float, aiApiId: string, consumerUserId: string, containerDiskInGb: int, containerRegistryAuthId: string, costPerHr: float, cpuFlavorId: string, desiredStatus: string, dockerEntrypoint: list, dockerStartCmd: list, endpointId: string, env: record, gpu: record, id: string, image: string, interruptible: bool, lastStartedAt: string, lastStatusChange: string, locked: bool, machine: record, machineId: string, memoryInGb: float, name: string, networkVolume: record, portMappings: record, ports: list, publicIp: string, savingsPlans: list, slsVersion: int, templateId: string, vcpuCount: float, volumeEncrypted: bool, volumeInGb: int, volumeMountPath: string>, workersMax: int, workersMin: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeTemplate" $includeTemplate "scalar") (serialize-qp "includeWorkers" $includeWorkers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/endpoints/($endpointId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an endpoint
#
# PATCH /endpoints/{endpointId}
# operationId: UpdateEndpoint
export def "endpoints UpdateEndpoint" [
  endpointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowedCudaVersions: list # If the created Serverless endpoint is a GPU endpoint, a list of acceptable CUDA versions on the created workers. If not set, any CUDA version is acceptable.
  --cpuFlavorIds: list # If the created Serverless endpoint is a CPU endpoint, a list of Runpod CPU flavors which can be attached to the created workers. The order of the list determines the order to rent CPU flavors.
  --dataCenterIds: list # A list of Runpod data center IDs where workers on the created Serverless endpoint can be located. (default: [EU-RO-1, CA-MTL-1, EU-SE-1, US-IL-1, EUR-IS-1, EU-CZ-1, US-TX-3, EUR-IS-2, US-KS-2, US-GA-2, US-WA-1, US-TX-1, CA-MTL-3, EU-NL-1, US-TX-4, US-CA-2, US-NC-1, OC-AU-1, US-DE-1, EUR-IS-3, CA-MTL-2, AP-JP-1, EUR-NO-1, EU-FR-1, US-KS-3, US-GA-1, AP-IN-1, US-MD-1], e.g. [EU-RO-1, CA-MTL-1])
  --executionTimeoutMs: int # The maximum number of milliseconds an individual request can run on a Serverless endpoint before the worker is stopped and the request is marked as failed. (e.g. 600000)
  --flashboot: oneof<nothing, bool> # Whether to use flash boot for the created Serverless endpoint. (e.g. true)
  --gpuCount: int # If the created Serverless endpoint is a GPU endpoint, the number of GPUs attached to each worker on the endpoint. (default: 1)
  --gpuTypeIds: list # If the created Serverless endpoint is a GPU endpoint, a list of Runpod GPU types which can be attached to the created workers. The order of the list determines the order to rent GPU types.
  --idleTimeout: int # The number of seconds a worker on the created Serverless endpoint can run without taking a job before the worker is scaled down. (default: 5)
  --minCudaVersion: string@minCudaVersion-completer # If the created Serverless endpoint is a GPU endpoint, the minimum acceptable CUDA version on the created workers.
  --name: string # A user-defined name for the created Serverless endpoint. The name does not need to be unique.
  --networkVolumeId: string # The unique string identifying the network volume to attach to the created Serverless endpoint.
  --networkVolumeIds: list # A list of network volume IDs to attach to the created Serverless endpoint. Allows multiple network volumes to be used with multi-region endpoints.
  --scalerType: string@scalerType-completer # The method used to scale up workers on the created Serverless endpoint. If QUEUE_DELAY, workers are scaled based on a periodic check to see if any requests have been in queue for too long. If REQUEST_COUNT, the desired number of workers is periodically calculated based on the number of requests in the endpoint's queue. Use QUEUE_DELAY if you need to ensure requests take no longer than a maximum latency, and use REQUEST_COUNT if you need to scale based on the number of requests. (default: QUEUE_DELAY)
  --scalerValue: int # If the endpoint scalerType is QUEUE_DELAY, the number of seconds a request can remain in queue before a new worker is scaled up. If the endpoint scalerType is REQUEST_COUNT, the number of workers is increased as needed to meet the number of requests in the endpoint's queue divided by scalerValue. (default: 4)
  --templateId: string # The unique string identifying the template used to create the Serverless endpoint. (e.g. 30zmvf89kd)
  --vcpuCount: int # If the created Serverless endpoint is a CPU endpoint, the number of vCPUs allocated to each created worker. (default: 2)
  --workersMax: int # The maximum number of workers that can be running at the same time on a Serverless endpoint. (e.g. 3)
  --workersMin: int # The minimum number of workers that will run at the same time on a Serverless endpoint. This number of workers will always stay running for the endpoint, and will be charged even if no requests are being processed, but they are charged at a lower rate than running autoscaling workers. (e.g. 0)
]: any -> record<allowedCudaVersions: list<string>, computeType: string, createdAt: string, dataCenterIds: list<string>, env: record, executionTimeoutMs: int, gpuCount: int, gpuTypeIds: list<string>, id: string, idleTimeout: int, instanceIds: list<string>, minCudaVersion: string, name: string, networkVolumeId: string, networkVolumeIds: list<string>, scalerType: string, scalerValue: int, template: record<category: string, containerDiskInGb: int, containerRegistryAuthId: string, dockerEntrypoint: list<string>, dockerStartCmd: list<string>, earned: float, env: record, id: string, imageName: string, isPublic: bool, isRunpod: bool, isServerless: bool, name: string, ports: list<string>, readme: string, runtimeInMin: int, volumeInGb: int, volumeMountPath: string>, templateId: string, userId: string, version: int, workers: table<adjustedCostPerHr: float, aiApiId: string, consumerUserId: string, containerDiskInGb: int, containerRegistryAuthId: string, costPerHr: float, cpuFlavorId: string, desiredStatus: string, dockerEntrypoint: list, dockerStartCmd: list, endpointId: string, env: record, gpu: record, id: string, image: string, interruptible: bool, lastStartedAt: string, lastStatusChange: string, locked: bool, machine: record, machineId: string, memoryInGb: float, name: string, networkVolume: record, portMappings: record, ports: list, publicIp: string, savingsPlans: list, slsVersion: int, templateId: string, vcpuCount: float, volumeEncrypted: bool, volumeInGb: int, volumeMountPath: string>, workersMax: int, workersMin: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($endpointId)")
  let body = {allowedCudaVersions: $allowedCudaVersions, cpuFlavorIds: $cpuFlavorIds, dataCenterIds: $dataCenterIds, executionTimeoutMs: $executionTimeoutMs, flashboot: $flashboot, gpuCount: $gpuCount, gpuTypeIds: $gpuTypeIds, idleTimeout: $idleTimeout, minCudaVersion: $minCudaVersion, name: $name, networkVolumeId: $networkVolumeId, networkVolumeIds: $networkVolumeIds, scalerType: $scalerType, scalerValue: $scalerValue, templateId: $templateId, vcpuCount: $vcpuCount, workersMax: $workersMax, workersMin: $workersMin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an endpoint
#
# DELETE /endpoints/{endpointId}
# operationId: DeleteEndpoint
export def "endpoints DeleteEndpoint" [
  endpointId: string
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
  let full_url = (build-url $base $"/endpoints/($endpointId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an endpoint
#
# POST /endpoints/{endpointId}/update
# operationId: UpdateEndpoint
export def "endpoints-update UpdateEndpoint" [
  endpointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowedCudaVersions: list # If the created Serverless endpoint is a GPU endpoint, a list of acceptable CUDA versions on the created workers. If not set, any CUDA version is acceptable.
  --cpuFlavorIds: list # If the created Serverless endpoint is a CPU endpoint, a list of Runpod CPU flavors which can be attached to the created workers. The order of the list determines the order to rent CPU flavors.
  --dataCenterIds: list # A list of Runpod data center IDs where workers on the created Serverless endpoint can be located. (default: [EU-RO-1, CA-MTL-1, EU-SE-1, US-IL-1, EUR-IS-1, EU-CZ-1, US-TX-3, EUR-IS-2, US-KS-2, US-GA-2, US-WA-1, US-TX-1, CA-MTL-3, EU-NL-1, US-TX-4, US-CA-2, US-NC-1, OC-AU-1, US-DE-1, EUR-IS-3, CA-MTL-2, AP-JP-1, EUR-NO-1, EU-FR-1, US-KS-3, US-GA-1, AP-IN-1, US-MD-1], e.g. [EU-RO-1, CA-MTL-1])
  --executionTimeoutMs: int # The maximum number of milliseconds an individual request can run on a Serverless endpoint before the worker is stopped and the request is marked as failed. (e.g. 600000)
  --flashboot: oneof<nothing, bool> # Whether to use flash boot for the created Serverless endpoint. (e.g. true)
  --gpuCount: int # If the created Serverless endpoint is a GPU endpoint, the number of GPUs attached to each worker on the endpoint. (default: 1)
  --gpuTypeIds: list # If the created Serverless endpoint is a GPU endpoint, a list of Runpod GPU types which can be attached to the created workers. The order of the list determines the order to rent GPU types.
  --idleTimeout: int # The number of seconds a worker on the created Serverless endpoint can run without taking a job before the worker is scaled down. (default: 5)
  --minCudaVersion: string@minCudaVersion-completer # If the created Serverless endpoint is a GPU endpoint, the minimum acceptable CUDA version on the created workers.
  --name: string # A user-defined name for the created Serverless endpoint. The name does not need to be unique.
  --networkVolumeId: string # The unique string identifying the network volume to attach to the created Serverless endpoint.
  --networkVolumeIds: list # A list of network volume IDs to attach to the created Serverless endpoint. Allows multiple network volumes to be used with multi-region endpoints.
  --scalerType: string@scalerType-completer # The method used to scale up workers on the created Serverless endpoint. If QUEUE_DELAY, workers are scaled based on a periodic check to see if any requests have been in queue for too long. If REQUEST_COUNT, the desired number of workers is periodically calculated based on the number of requests in the endpoint's queue. Use QUEUE_DELAY if you need to ensure requests take no longer than a maximum latency, and use REQUEST_COUNT if you need to scale based on the number of requests. (default: QUEUE_DELAY)
  --scalerValue: int # If the endpoint scalerType is QUEUE_DELAY, the number of seconds a request can remain in queue before a new worker is scaled up. If the endpoint scalerType is REQUEST_COUNT, the number of workers is increased as needed to meet the number of requests in the endpoint's queue divided by scalerValue. (default: 4)
  --templateId: string # The unique string identifying the template used to create the Serverless endpoint. (e.g. 30zmvf89kd)
  --vcpuCount: int # If the created Serverless endpoint is a CPU endpoint, the number of vCPUs allocated to each created worker. (default: 2)
  --workersMax: int # The maximum number of workers that can be running at the same time on a Serverless endpoint. (e.g. 3)
  --workersMin: int # The minimum number of workers that will run at the same time on a Serverless endpoint. This number of workers will always stay running for the endpoint, and will be charged even if no requests are being processed, but they are charged at a lower rate than running autoscaling workers. (e.g. 0)
]: any -> record<allowedCudaVersions: list<string>, computeType: string, createdAt: string, dataCenterIds: list<string>, env: record, executionTimeoutMs: int, gpuCount: int, gpuTypeIds: list<string>, id: string, idleTimeout: int, instanceIds: list<string>, minCudaVersion: string, name: string, networkVolumeId: string, networkVolumeIds: list<string>, scalerType: string, scalerValue: int, template: record<category: string, containerDiskInGb: int, containerRegistryAuthId: string, dockerEntrypoint: list<string>, dockerStartCmd: list<string>, earned: float, env: record, id: string, imageName: string, isPublic: bool, isRunpod: bool, isServerless: bool, name: string, ports: list<string>, readme: string, runtimeInMin: int, volumeInGb: int, volumeMountPath: string>, templateId: string, userId: string, version: int, workers: table<adjustedCostPerHr: float, aiApiId: string, consumerUserId: string, containerDiskInGb: int, containerRegistryAuthId: string, costPerHr: float, cpuFlavorId: string, desiredStatus: string, dockerEntrypoint: list, dockerStartCmd: list, endpointId: string, env: record, gpu: record, id: string, image: string, interruptible: bool, lastStartedAt: string, lastStatusChange: string, locked: bool, machine: record, machineId: string, memoryInGb: float, name: string, networkVolume: record, portMappings: record, ports: list, publicIp: string, savingsPlans: list, slsVersion: int, templateId: string, vcpuCount: float, volumeEncrypted: bool, volumeInGb: int, volumeMountPath: string>, workersMax: int, workersMin: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/endpoints/($endpointId)/update")
  let body = {allowedCudaVersions: $allowedCudaVersions, cpuFlavorIds: $cpuFlavorIds, dataCenterIds: $dataCenterIds, executionTimeoutMs: $executionTimeoutMs, flashboot: $flashboot, gpuCount: $gpuCount, gpuTypeIds: $gpuTypeIds, idleTimeout: $idleTimeout, minCudaVersion: $minCudaVersion, name: $name, networkVolumeId: $networkVolumeId, networkVolumeIds: $networkVolumeIds, scalerType: $scalerType, scalerValue: $scalerValue, templateId: $templateId, vcpuCount: $vcpuCount, workersMax: $workersMax, workersMin: $workersMin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new template
#
# POST /templates
# operationId: CreateTemplate
export def "templates CreateTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The compute category of the resource defined by this template. (default: NVIDIA)
  --containerDiskInGb: int # The amount of disk space in GB to allocate for the container. (default: 50)
  --containerRegistryAuthId: string # The unique string representing the container auth object needed for a private image.
  --dockerEntrypoint: list # If specified, overrides the ENTRYPOINT for the Docker image run on the Pods using this template. If [], uses the ENTRYPOINT defined in the DockerFile. (default: [])
  --dockerStartCmd: list # If specified, overrides the start CMD for the Docker image run on the Pods using this template. If [], uses the start CMD defined in the DockerFile. (default: [])
  --env: record # default: {}, e.g. {ENV_VAR: value}
  imageName: string # Docker image name.
  --isPublic: oneof<nothing, bool> # If this is a Pod template, specifies whether the template is visible to other Runpod users. (default: false)
  --isServerless: oneof<nothing, bool> # Whether the template specifies a Serverless worker or a Pod. (default: false)
  name: string # Template name.
  --ports: list # A list of ports exposed on the created Pod. Each port is formatted as [port number]/[protocol]. Protocol can be either http or tcp. (default: 8888/http,22/tcp, e.g. [8888/http, 22/tcp])
  --readme: string # README content in markdown format. (default: )
  --volumeInGb: int # The amount of disk space, in gigabytes (GB), to allocate on the Pods deployed with this template. (default: 20)
  --volumeMountPath: string # If a volume is attached to a Pod deployed with this template, the absolute path where the volume will be mounted in the filesystem. (default: /workspace)
]: any -> record<category: string, containerDiskInGb: int, containerRegistryAuthId: string, dockerEntrypoint: list<string>, dockerStartCmd: list<string>, earned: float, env: record, id: string, imageName: string, isPublic: bool, isRunpod: bool, isServerless: bool, name: string, ports: list<string>, readme: string, runtimeInMin: int, volumeInGb: int, volumeMountPath: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates")
  let body = {category: $category, containerDiskInGb: $containerDiskInGb, containerRegistryAuthId: $containerRegistryAuthId, dockerEntrypoint: $dockerEntrypoint, dockerStartCmd: $dockerStartCmd, env: $env, imageName: $imageName, isPublic: $isPublic, isServerless: $isServerless, name: $name, ports: $ports, readme: $readme, volumeInGb: $volumeInGb, volumeMountPath: $volumeMountPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List templates
#
# GET /templates
# operationId: ListTemplates
export def "templates ListTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeEndpointBoundTemplates: oneof<nothing, bool> # default: false, e.g. true
  --includePublicTemplates: oneof<nothing, bool> # default: false, e.g. true
  --includeRunpodTemplates: oneof<nothing, bool> # default: false, e.g. true
]: nothing -> table<category: string, containerDiskInGb: int, containerRegistryAuthId: string, dockerEntrypoint: list<string>, dockerStartCmd: list<string>, earned: float, env: record, id: string, imageName: string, isPublic: bool, isRunpod: bool, isServerless: bool, name: string, ports: list<string>, readme: string, runtimeInMin: int, volumeInGb: int, volumeMountPath: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeEndpointBoundTemplates" $includeEndpointBoundTemplates "scalar") (serialize-qp "includePublicTemplates" $includePublicTemplates "scalar") (serialize-qp "includeRunpodTemplates" $includeRunpodTemplates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find a template by ID
#
# GET /templates/{templateId}
# operationId: GetTemplate
export def "templates GetTemplate" [
  templateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeEndpointBoundTemplates: oneof<nothing, bool> # default: false, e.g. true
  --includePublicTemplates: oneof<nothing, bool> # default: false, e.g. true
  --includeRunpodTemplates: oneof<nothing, bool> # default: false, e.g. true
]: nothing -> record<category: string, containerDiskInGb: int, containerRegistryAuthId: string, dockerEntrypoint: list<string>, dockerStartCmd: list<string>, earned: float, env: record, id: string, imageName: string, isPublic: bool, isRunpod: bool, isServerless: bool, name: string, ports: list<string>, readme: string, runtimeInMin: int, volumeInGb: int, volumeMountPath: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeEndpointBoundTemplates" $includeEndpointBoundTemplates "scalar") (serialize-qp "includePublicTemplates" $includePublicTemplates "scalar") (serialize-qp "includeRunpodTemplates" $includeRunpodTemplates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/templates/($templateId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a template
#
# PATCH /templates/{templateId}
# operationId: UpdateTemplate
export def "templates UpdateTemplate" [
  templateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --containerDiskInGb: int # The amount of disk space in GB to allocate for the container. (default: 50)
  --containerRegistryAuthId: string # The unique string representing the container auth object needed for a private image.
  --dockerEntrypoint: list # If specified, overrides the ENTRYPOINT for the Docker image run on the Pods using this template. If [], uses the ENTRYPOINT defined in the DockerFile. (default: [])
  --dockerStartCmd: list # If specified, overrides the start CMD for the Docker image run on the Pods using this template. If [], uses the start CMD defined in the DockerFile. (default: [])
  --env: record # default: {}, e.g. {ENV_VAR: value}
  --imageName: string # Docker image name.
  --isPublic: oneof<nothing, bool> # If this is a Pod template, specifies whether the template is visible to other Runpod users. (default: false)
  --name: string # Template name.
  --ports: list # A list of ports exposed on the created Pod. Each port is formatted as [port number]/[protocol]. Protocol can be either http or tcp. (default: 8888/http,22/tcp, e.g. [8888/http, 22/tcp])
  --readme: string # README content in markdown format. (default: )
  --volumeInGb: int # The amount of disk space, in gigabytes (GB), to allocate on the Pods deployed with this template. (default: 20)
  --volumeMountPath: string # If a volume is attached to a Pod deployed with this template, the absolute path where the volume will be mounted in the filesystem. (default: /workspace)
]: any -> record<category: string, containerDiskInGb: int, containerRegistryAuthId: string, dockerEntrypoint: list<string>, dockerStartCmd: list<string>, earned: float, env: record, id: string, imageName: string, isPublic: bool, isRunpod: bool, isServerless: bool, name: string, ports: list<string>, readme: string, runtimeInMin: int, volumeInGb: int, volumeMountPath: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($templateId)")
  let body = {containerDiskInGb: $containerDiskInGb, containerRegistryAuthId: $containerRegistryAuthId, dockerEntrypoint: $dockerEntrypoint, dockerStartCmd: $dockerStartCmd, env: $env, imageName: $imageName, isPublic: $isPublic, name: $name, ports: $ports, readme: $readme, volumeInGb: $volumeInGb, volumeMountPath: $volumeMountPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a template
#
# DELETE /templates/{templateId}
# operationId: DeleteTemplate
export def "templates DeleteTemplate" [
  templateId: string
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
  let full_url = (build-url $base $"/templates/($templateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a template
#
# POST /templates/{templateId}/update
# operationId: UpdateTemplate
export def "templates-update UpdateTemplate" [
  templateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --containerDiskInGb: int # The amount of disk space in GB to allocate for the container. (default: 50)
  --containerRegistryAuthId: string # The unique string representing the container auth object needed for a private image.
  --dockerEntrypoint: list # If specified, overrides the ENTRYPOINT for the Docker image run on the Pods using this template. If [], uses the ENTRYPOINT defined in the DockerFile. (default: [])
  --dockerStartCmd: list # If specified, overrides the start CMD for the Docker image run on the Pods using this template. If [], uses the start CMD defined in the DockerFile. (default: [])
  --env: record # default: {}, e.g. {ENV_VAR: value}
  --imageName: string # Docker image name.
  --isPublic: oneof<nothing, bool> # If this is a Pod template, specifies whether the template is visible to other Runpod users. (default: false)
  --name: string # Template name.
  --ports: list # A list of ports exposed on the created Pod. Each port is formatted as [port number]/[protocol]. Protocol can be either http or tcp. (default: 8888/http,22/tcp, e.g. [8888/http, 22/tcp])
  --readme: string # README content in markdown format. (default: )
  --volumeInGb: int # The amount of disk space, in gigabytes (GB), to allocate on the Pods deployed with this template. (default: 20)
  --volumeMountPath: string # If a volume is attached to a Pod deployed with this template, the absolute path where the volume will be mounted in the filesystem. (default: /workspace)
]: any -> record<category: string, containerDiskInGb: int, containerRegistryAuthId: string, dockerEntrypoint: list<string>, dockerStartCmd: list<string>, earned: float, env: record, id: string, imageName: string, isPublic: bool, isRunpod: bool, isServerless: bool, name: string, ports: list<string>, readme: string, runtimeInMin: int, volumeInGb: int, volumeMountPath: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($templateId)/update")
  let body = {containerDiskInGb: $containerDiskInGb, containerRegistryAuthId: $containerRegistryAuthId, dockerEntrypoint: $dockerEntrypoint, dockerStartCmd: $dockerStartCmd, env: $env, imageName: $imageName, isPublic: $isPublic, name: $name, ports: $ports, readme: $readme, volumeInGb: $volumeInGb, volumeMountPath: $volumeMountPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new network volume
#
# POST /networkvolumes
# operationId: CreateNetworkVolume
export def "networkvolumes CreateNetworkVolume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  dataCenterId: string # The Runpod data center ID where the created network volume is located. (e.g. EU-RO-1)
  name: string # A user-defined name for the created network volume. The name does not need to be unique. (e.g. my network volume)
  size: int # The amount of disk space, in gigabytes (GB), allocated to the created network volume. (e.g. 50)
]: any -> record<dataCenterId: string, id: string, name: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/networkvolumes")
  let body = {dataCenterId: $dataCenterId, name: $name, size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List network volumes
#
# GET /networkvolumes
# operationId: ListNetworkVolumes
export def "networkvolumes ListNetworkVolumes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, size: int, dataCenterId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/networkvolumes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find a network volume by ID
#
# GET /networkvolumes/{networkVolumeId}
# operationId: GetNetworkVolume
export def "networkvolumes GetNetworkVolume" [
  networkVolumeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dataCenterId: string, id: string, name: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networkvolumes/($networkVolumeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a network volume
#
# PATCH /networkvolumes/{networkVolumeId}
# operationId: UpdateNetworkVolume
export def "networkvolumes UpdateNetworkVolume" [
  networkVolumeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A user-defined name for the network volume. The name does not need to be unique. (e.g. my network volume)
  --size: int # The amount of disk space, in gigabytes (GB), which will be allocated to the network volume after the update. Must be greater than the current size of the network volume. (e.g. 50)
]: any -> record<dataCenterId: string, id: string, name: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networkvolumes/($networkVolumeId)")
  let body = {name: $name, size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a network volume
#
# DELETE /networkvolumes/{networkVolumeId}
# operationId: DeleteNetworkVolume
export def "networkvolumes DeleteNetworkVolume" [
  networkVolumeId: string
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
  let full_url = (build-url $base $"/networkvolumes/($networkVolumeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a network volume
#
# POST /networkvolumes/{networkVolumeId}/update
# operationId: UpdateNetworkVolume
export def "networkvolumes-update UpdateNetworkVolume" [
  networkVolumeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A user-defined name for the network volume. The name does not need to be unique. (e.g. my network volume)
  --size: int # The amount of disk space, in gigabytes (GB), which will be allocated to the network volume after the update. Must be greater than the current size of the network volume. (e.g. 50)
]: any -> record<dataCenterId: string, id: string, name: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/networkvolumes/($networkVolumeId)/update")
  let body = {name: $name, size: $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new container registry auth
#
# POST /containerregistryauth
# operationId: CreateContainerRegistryAuth
export def "containerregistryauth CreateContainerRegistryAuth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # A user-defined name for a container registry authentication. The name must be unique. (e.g. my creds)
  password: string # The password for the container registry. (e.g. my-password)
  username: string # The username for the container registry. (e.g. my-username)
]: any -> record<id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/containerregistryauth")
  let body = {name: $name, password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List container registry auths
#
# GET /containerregistryauth
# operationId: ListContainerRegistryAuths
export def "containerregistryauth ListContainerRegistryAuths" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/containerregistryauth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find a container registry auth by ID
#
# GET /containerregistryauth/{containerRegistryAuthId}
# operationId: GetContainerRegistryAuth
export def "containerregistryauth GetContainerRegistryAuth" [
  containerRegistryAuthId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/containerregistryauth/($containerRegistryAuthId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a container registry auth
#
# DELETE /containerregistryauth/{containerRegistryAuthId}
# operationId: DeleteContainerRegistryAuth
export def "containerregistryauth DeleteContainerRegistryAuth" [
  containerRegistryAuthId: string
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
  let full_url = (build-url $base $"/containerregistryauth/($containerRegistryAuthId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pod billing history
#
# GET /billing/pods
# operationId: PodBilling
export def "billing-pods PodBilling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bucketSize: string@bucketSize-completer # default: day
  --endTime: string # format: date-time, e.g. 2023-01-31T23:59:59Z
  --gpuTypeId: string@gpuTypeId-completer # e.g. NVIDIA GeForce RTX 4090
  --grouping: string@grouping-completer # default: gpuTypeId
  --podId: string # e.g. xedezhzb9la3ye
  --startTime: string # format: date-time, e.g. 2023-01-01T00:00:00Z
]: nothing -> table<amount: float, diskSpaceBilledGb: int, endpointId: string, gpuTypeId: string, podId: string, time: string, timeBilledMs: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bucketSize" $bucketSize "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "gpuTypeId" $gpuTypeId "scalar") (serialize-qp "grouping" $grouping "scalar") (serialize-qp "podId" $podId "scalar") (serialize-qp "startTime" $startTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/billing/pods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Serverless billing history
#
# GET /billing/endpoints
# operationId: EndpointBilling
export def "billing-endpoints EndpointBilling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bucketSize: string@bucketSize-completer # default: day
  --dataCenterId: list # default: [EU-RO-1, CA-MTL-1, EU-SE-1, US-IL-1, EUR-IS-1, EU-CZ-1, US-TX-3, EUR-IS-2, US-KS-2, US-GA-2, US-WA-1, US-TX-1, CA-MTL-3, EU-NL-1, US-TX-4, US-CA-2, US-NC-1, OC-AU-1, US-DE-1, EUR-IS-3, CA-MTL-2, AP-JP-1, EUR-NO-1, EU-FR-1, US-KS-3, US-GA-1, AP-IN-1, US-MD-1], e.g. [EU-RO-1, CA-MTL-1]
  --endpointId: string # e.g. jpnw0v75y3qoql
  --endTime: string # format: date-time, e.g. 2023-01-31T23:59:59Z
  --gpuTypeId: list # e.g. NVIDIA GeForce RTX 4090
  --grouping: string@grouping-completer-1 # default: endpointId
  --imageName: string # e.g. runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04
  --startTime: string # format: date-time, e.g. 2023-01-01T00:00:00Z
  --templateId: string # e.g. 30zmvf89kd
]: nothing -> table<amount: float, diskSpaceBilledGb: int, endpointId: string, gpuTypeId: string, podId: string, time: string, timeBilledMs: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bucketSize" $bucketSize "scalar") (serialize-qp "dataCenterId" $dataCenterId "multi") (serialize-qp "endpointId" $endpointId "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "gpuTypeId" $gpuTypeId "multi") (serialize-qp "grouping" $grouping "scalar") (serialize-qp "imageName" $imageName "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "templateId" $templateId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/billing/endpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Network volume billing history
#
# GET /billing/networkvolumes
# operationId: NetworkVolumeBilling
export def "billing-networkvolumes NetworkVolumeBilling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bucketSize: string@bucketSize-completer # default: day
  --endTime: string # format: date-time, e.g. 2023-01-31T23:59:59Z
  --startTime: string # format: date-time, e.g. 2023-01-01T00:00:00Z
]: nothing -> table<amount: float, diskSpaceBilledGb: int, highPerformanceStorageAmount: float, highPerformanceStorageDiskSpaceBilledGb: int, time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bucketSize" $bucketSize "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "startTime" $startTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/billing/networkvolumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
