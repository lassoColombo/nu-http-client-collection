# Auto-generated client for AWS OpsWorks CM v2016-11-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/opsworkscm/2016-11-01/openapi.json
# Auth: --token flag or $env.AWS_OPSWORKS_CM_TOKEN

const BASE_URL = "http://opsworks-cm.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_OPSWORKS_CM_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://opsworks-cm.us-east-1.amazonaws.com" "http://opsworks-cm.us-east-2.amazonaws.com" "http://opsworks-cm.us-west-1.amazonaws.com" "http://opsworks-cm.us-west-2.amazonaws.com" "http://opsworks-cm.us-gov-west-1.amazonaws.com" "http://opsworks-cm.us-gov-east-1.amazonaws.com" "http://opsworks-cm.ca-central-1.amazonaws.com" "http://opsworks-cm.eu-north-1.amazonaws.com" "http://opsworks-cm.eu-west-1.amazonaws.com" "http://opsworks-cm.eu-west-2.amazonaws.com" "http://opsworks-cm.eu-west-3.amazonaws.com" "http://opsworks-cm.eu-central-1.amazonaws.com" "http://opsworks-cm.eu-south-1.amazonaws.com" "http://opsworks-cm.af-south-1.amazonaws.com" "http://opsworks-cm.ap-northeast-1.amazonaws.com" "http://opsworks-cm.ap-northeast-2.amazonaws.com" "http://opsworks-cm.ap-northeast-3.amazonaws.com" "http://opsworks-cm.ap-southeast-1.amazonaws.com" "http://opsworks-cm.ap-southeast-2.amazonaws.com" "http://opsworks-cm.ap-east-1.amazonaws.com" "http://opsworks-cm.ap-south-1.amazonaws.com" "http://opsworks-cm.sa-east-1.amazonaws.com" "http://opsworks-cm.me-south-1.amazonaws.com" "https://opsworks-cm.us-east-1.amazonaws.com" "https://opsworks-cm.us-east-2.amazonaws.com" "https://opsworks-cm.us-west-1.amazonaws.com" "https://opsworks-cm.us-west-2.amazonaws.com" "https://opsworks-cm.us-gov-west-1.amazonaws.com" "https://opsworks-cm.us-gov-east-1.amazonaws.com" "https://opsworks-cm.ca-central-1.amazonaws.com" "https://opsworks-cm.eu-north-1.amazonaws.com" "https://opsworks-cm.eu-west-1.amazonaws.com" "https://opsworks-cm.eu-west-2.amazonaws.com" "https://opsworks-cm.eu-west-3.amazonaws.com" "https://opsworks-cm.eu-central-1.amazonaws.com" "https://opsworks-cm.eu-south-1.amazonaws.com" "https://opsworks-cm.af-south-1.amazonaws.com" "https://opsworks-cm.ap-northeast-1.amazonaws.com" "https://opsworks-cm.ap-northeast-2.amazonaws.com" "https://opsworks-cm.ap-northeast-3.amazonaws.com" "https://opsworks-cm.ap-southeast-1.amazonaws.com" "https://opsworks-cm.ap-southeast-2.amazonaws.com" "https://opsworks-cm.ap-east-1.amazonaws.com" "https://opsworks-cm.ap-south-1.amazonaws.com" "https://opsworks-cm.sa-east-1.amazonaws.com" "https://opsworks-cm.me-south-1.amazonaws.com" "http://opsworks-cm.cn-north-1.amazonaws.com.cn" "http://opsworks-cm.cn-northwest-1.amazonaws.com.cn" "https://opsworks-cm.cn-north-1.amazonaws.com.cn" "https://opsworks-cm.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["OpsWorksCM_V2016_11_01.AssociateNode"] }
def x-amz-target-completer-1 [] { ["OpsWorksCM_V2016_11_01.CreateBackup"] }
def x-amz-target-completer-2 [] { ["OpsWorksCM_V2016_11_01.CreateServer"] }
def x-amz-target-completer-3 [] { ["OpsWorksCM_V2016_11_01.DeleteBackup"] }
def x-amz-target-completer-4 [] { ["OpsWorksCM_V2016_11_01.DeleteServer"] }
def x-amz-target-completer-5 [] { ["OpsWorksCM_V2016_11_01.DescribeAccountAttributes"] }
def x-amz-target-completer-6 [] { ["OpsWorksCM_V2016_11_01.DescribeBackups"] }
def x-amz-target-completer-7 [] { ["OpsWorksCM_V2016_11_01.DescribeEvents"] }
def x-amz-target-completer-8 [] { ["OpsWorksCM_V2016_11_01.DescribeNodeAssociationStatus"] }
def x-amz-target-completer-9 [] { ["OpsWorksCM_V2016_11_01.DescribeServers"] }
def x-amz-target-completer-10 [] { ["OpsWorksCM_V2016_11_01.DisassociateNode"] }
def x-amz-target-completer-11 [] { ["OpsWorksCM_V2016_11_01.ExportServerEngineAttribute"] }
def x-amz-target-completer-12 [] { ["OpsWorksCM_V2016_11_01.ListTagsForResource"] }
def x-amz-target-completer-13 [] { ["OpsWorksCM_V2016_11_01.RestoreServer"] }
def x-amz-target-completer-14 [] { ["OpsWorksCM_V2016_11_01.StartMaintenance"] }
def x-amz-target-completer-15 [] { ["OpsWorksCM_V2016_11_01.TagResource"] }
def x-amz-target-completer-16 [] { ["OpsWorksCM_V2016_11_01.UntagResource"] }
def x-amz-target-completer-17 [] { ["OpsWorksCM_V2016_11_01.UpdateServer"] }
def x-amz-target-completer-18 [] { ["OpsWorksCM_V2016_11_01.UpdateServerEngineAttributes"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "associate-node" } } | get name | first)
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

# Associates a new node with the server. For more information about how to disassociate a node, see DisassociateNode. On a Chef server: This command is an alternative to knife bootstrap. Example (Chef): aws opsworks-cm associate-node --server-name MyServer --node-name MyManagedNode --engine-attributes "Name=CHEF_ORGANIZATION,Value=default" "Name=CHEF_NODE_PUBLIC_KEY,Value=public-key-pem" On a Puppet server, this command is an alternative to the puppet cert sign command that signs a Puppet node CSR. Example (Puppet): aws opsworks-cm associate-node --server-name MyServer --node-name MyManagedNode --engine-attributes "Name=PUPPET_NODE_CSR,Value=csr-pem" A node can can only be associated with servers that are in a HEALTHY state. Otherwise, an InvalidStateException is thrown. A ResourceNotFoundException is thrown when the server does not exist. A ValidationException is raised when parameters of the request are not valid. The AssociateNode API call can be integrated into Auto Scaling configurations, AWS Cloudformation templates, or the user data of a server's instance.
#
# POST /
# operationId: AssociateNode
# --EngineAttributes item shape: {Name?: string, Value?: string}
export def "associate-node" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer # required
  server_name: string # The name of the server with which to associate the node.
  node_name: string # The node name that is used by chef-client or puppet-agentfor a new node. We recommend to use a unique FQDN as hostname. For more information, see the Chef (https://docs.aws.amazon.com/https:/docs.chef.io/nodes.html#about-node-names) or Puppet (https://docs.aws.amazon.com/https:/docs.puppet.com/puppet/4.10/man/agent.html) documentation.
  engine_attributes: list # Engine attributes used for associating the node. Attributes accepted in a AssociateNode request for Chef CHEF_ORGANIZATION: The Chef organization with which the node is associated. By default only one organization named default can exist. CHEF_NODE_PUBLIC_KEY: A PEM-formatted public key. This key is required for the chef-client agent to access the Chef API. Attributes accepted in a AssociateNode request for Puppet PUPPET_NODE_CSR: A PEM-formatted certificate-signing request (CSR) that is created by the node. — item shape: {Name?: string, Value?: string}
]: any -> record<NodeAssociationStatusToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.AssociateNode")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ServerName": $server_name, "NodeName": $node_name, "EngineAttributes": $engine_attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates an application-level backup of a server. While the server is in the BACKING_UP state, the server cannot be changed, and no additional backup can be created. Backups can be created for servers in RUNNING, HEALTHY, and UNHEALTHY states. By default, you can create a maximum of 50 manual backups. This operation is asynchronous. A LimitExceededException is thrown when the maximum number of manual backups is reached. An InvalidStateException is thrown when the server is not in any of the following states: RUNNING, HEALTHY, or UNHEALTHY. A ResourceNotFoundException is thrown when the server is not found. A ValidationException is thrown when parameters of the request are not valid.
#
# POST /
# operationId: CreateBackup
# --Tags item shape: {Key: string, Value: string}
export def "create-backup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-1 # required
  server_name: string # The name of the server that you want to back up.
  --description: string # A user-defined description of the backup.
  --tags: list # A map that contains tag keys and tag values to attach to an AWS OpsWorks-CM server backup. The key cannot be empty. The key can be a maximum of 127 characters, and can contain only Unicode letters, numbers, or separators, or the following special characters: + - = . _ : / The value can be a maximum 255 characters, and contain only Unicode letters, numbers, or separators, or the following special characters: + - = . _ : / Leading and trailing white spaces are trimmed from both the key and value. A maximum of 50 user-applied tags is allowed for tag-supported AWS OpsWorks-CM resources. — item shape: {Key: string, Value: string}
]: any -> record<Backup: record<BackupArn: string, BackupId: string, BackupType: string, CreatedAt: string, Description: string, Engine: string, EngineModel: string, EngineVersion: string, InstanceProfileArn: string, InstanceType: string, KeyPair: string, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, S3DataSize: int, S3DataUrl: string, S3LogUrl: string, SecurityGroupIds: list<string>, ServerName: string, ServiceRoleArn: string, Status: string, StatusDescription: string, SubnetIds: list<string>, ToolsVersion: string, UserArn: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.CreateBackup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ServerName": $server_name, "Description": $description, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Creates and immedately starts a new server. The server is ready to use when it is in the HEALTHY state. By default, you can create a maximum of 10 servers. This operation is asynchronous. A LimitExceededException is thrown when you have created the maximum number of servers (10). A ResourceAlreadyExistsException is thrown when a server with the same name already exists in the account. A ResourceNotFoundException is thrown when you specify a backup ID that is not valid or is for a backup that does not exist. A ValidationException is thrown when parameters of the request are not valid. If you do not specify a security group by adding the SecurityGroupIds parameter, AWS OpsWorks creates a new security group. Chef Automate: The default security group opens the Chef server to the world on TCP port 443. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. Puppet Enterprise: The default security group opens TCP ports 22, 443, 4433, 8140, 8142, 8143, and 8170. If a KeyName is present, AWS OpsWorks enables SSH access. SSH is also open to the world on TCP port 22. By default, your server is accessible from any IP address. We recommend that you update your security group rules to allow access from known IP addresses and address ranges only. To edit security group rules, open Security Groups in the navigation pane of the EC2 management console. To specify your own domain for a server, and provide your own self-signed or CA-signed certificate and private key, specify values for CustomDomain, CustomCertificate, and CustomPrivateKey.
#
# POST /
# operationId: CreateServer
# --EngineAttributes item shape: {Name?: string, Value?: string}
# --Tags item shape: {Key: string, Value: string}
export def "create-server" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-2 # required
  --associate-public-ip-address: oneof<nothing, bool> # Associate a public IP address with a server that you are launching. Valid values are true or false. The default value is true.
  --custom-domain: string # An optional public endpoint of a server, such as https://aws.my-company.com. To access the server, create a CNAME DNS record in your preferred DNS service that points the custom domain to the endpoint that is generated when the server is created (the value of the CreateServer Endpoint attribute). You cannot access the server by using the generated Endpoint value if the server is using a custom domain. If you specify a custom domain, you must also specify values for CustomCertificate and CustomPrivateKey.
  --custom-certificate: string # A PEM-formatted HTTPS certificate. The value can be be a single, self-signed certificate, or a certificate chain. If you specify a custom certificate, you must also specify values for CustomDomain and CustomPrivateKey. The following are requirements for the CustomCertificate value: You can provide either a self-signed, custom certificate, or the full certificate chain. The certificate must be a valid X509 certificate, or a certificate chain in PEM format. The certificate must be valid at the time of upload. A certificate can't be used before its validity period begins (the certificate's NotBefore date), or after it expires (the certificate's NotAfter date). The certificate’s common name or subject alternative names (SANs), if present, must match the value of CustomDomain. The certificate must match the value of CustomPrivateKey.
  --custom-private-key: string # A private key in PEM format for connecting to the server by using HTTPS. The private key must not be encrypted; it cannot be protected by a password or passphrase. If you specify a custom private key, you must also specify values for CustomDomain and CustomCertificate. (format: password)
  --disable-automated-backup: oneof<nothing, bool> # Enable or disable scheduled backups. Valid values are true or false. The default value is true.
  engine: string # The configuration management engine to use. Valid values include ChefAutomate and Puppet.
  --engine-model: string # The engine model of the server. Valid values in this release include Monolithic for Puppet and Single for Chef.
  --engine-version: string # The major release version of the engine that you want to use. For a Chef server, the valid value for EngineVersion is currently 2. For a Puppet server, valid values are 2019 or 2017.
  --engine-attributes: list # Optional engine attributes on a specified server. Attributes accepted in a Chef createServer request: CHEF_AUTOMATE_PIVOTAL_KEY: A base64-encoded RSA public key. The corresponding private key is required to access the Chef API. When no CHEF_AUTOMATE_PIVOTAL_KEY is set, a private key is generated and returned in the response. CHEF_AUTOMATE_ADMIN_PASSWORD: The password for the administrative user in the Chef Automate web-based dashboard. The password length is a minimum of eight characters, and a maximum of 32. The password can contain letters, numbers, and special characters (!/@#$%^&+=_). The password must contain at least one lower case letter, one upper case letter, one number, and one special character. When no CHEF_AUTOMATE_ADMIN_PASSWORD is set, one is generated and returned in the response. Attributes accepted in a Puppet createServer request: PUPPET_ADMIN_PASSWORD: To work with the Puppet Enterprise console, a password must use ASCII characters. PUPPET_R10K_REMOTE: The r10k remote is the URL of your control repository (for example, ssh://git@your.git-repo.com:user/control-repo.git). Specifying an r10k remote opens TCP port 8170. PUPPET_R10K_PRIVATE_KEY: If you are using a private Git repository, add PUPPET_R10K_PRIVATE_KEY to specify a PEM-encoded private SSH key. — item shape: {Name?: string, Value?: string}
  --backup-retention-count: int # The number of automated backups that you want to keep. Whenever a new backup is created, AWS OpsWorks CM deletes the oldest backups if this number is exceeded. The default value is 1.
  server_name: string # The name of the server. The server name must be unique within your AWS account, within each region. Server names must start with a letter; then letters, numbers, or hyphens (-) are allowed, up to a maximum of 40 characters.
  instance_profile_arn: string # The ARN of the instance profile that your Amazon EC2 instances use. Although the AWS OpsWorks console typically creates the instance profile for you, if you are using API commands instead, run the service-role-creation.yaml AWS CloudFormation template, located at https://s3.amazonaws.com/opsworks-cm-us-east-1-prod-default-assets/misc/opsworks-cm-roles.yaml. This template creates a CloudFormation stack that includes the instance profile you need.
  instance_type: string # The Amazon EC2 instance type to use. For example, m5.large.
  --key-pair: string # The Amazon EC2 key pair to set for the instance. This parameter is optional; if desired, you may specify this parameter to connect to your instances by using SSH.
  --preferred-maintenance-window: string # DDD:HH:MM (weekly start time) or HH:MM (daily start time). Time windows always use coordinated universal time (UTC). Valid strings for day of week (DDD) are: Mon, Tue, Wed, Thr, Fri, Sat, or Sun.
  --preferred-backup-window: string # DDD:HH:MM (weekly start time) or HH:MM (daily start time). Time windows always use coordinated universal time (UTC). Valid strings for day of week (DDD) are: Mon, Tue, Wed, Thr, Fri, Sat, or Sun.
  --security-group-ids: list<string> # A list of security group IDs to attach to the Amazon EC2 instance. If you add this parameter, the specified security groups must be within the VPC that is specified by SubnetIds. If you do not specify this parameter, AWS OpsWorks CM creates one new security group that uses TCP ports 22 and 443, open to 0.0.0.0/0 (everyone).
  service_role_arn: string # The service role that the AWS OpsWorks CM service backend uses to work with your account. Although the AWS OpsWorks management console typically creates the service role for you, if you are using the AWS CLI or API commands, run the service-role-creation.yaml AWS CloudFormation template, located at https://s3.amazonaws.com/opsworks-cm-us-east-1-prod-default-assets/misc/opsworks-cm-roles.yaml. This template creates a CloudFormation stack that includes the service role and instance profile that you need.
  --subnet-ids: list<string> # The IDs of subnets in which to launch the server EC2 instance. Amazon EC2-Classic customers: This field is required. All servers must run within a VPC. The VPC must have "Auto Assign Public IP" enabled. EC2-VPC customers: This field is optional. If you do not specify subnet IDs, your EC2 instances are created in a default subnet that is selected by Amazon EC2. If you specify subnet IDs, the VPC must have "Auto Assign Public IP" enabled. For more information about supported Amazon EC2 platforms, see Supported Platforms (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-supported-platforms.html).
  --tags: list # A map that contains tag keys and tag values to attach to an AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise server. The key cannot be empty. The key can be a maximum of 127 characters, and can contain only Unicode letters, numbers, or separators, or the following special characters: + - = . _ : / @ The value can be a maximum 255 characters, and contain only Unicode letters, numbers, or separators, or the following special characters: + - = . _ : / @ Leading and trailing white spaces are trimmed from both the key and value. A maximum of 50 user-applied tags is allowed for any AWS OpsWorks-CM server. — item shape: {Key: string, Value: string}
  --backup-id: string # If you specify this field, AWS OpsWorks CM creates the server by using the backup represented by BackupId.
]: any -> record<Server: record<AssociatePublicIpAddress: bool, BackupRetentionCount: int, ServerName: string, CreatedAt: string, CloudFormationStackArn: string, CustomDomain: string, DisableAutomatedBackup: bool, Endpoint: string, Engine: string, EngineModel: string, EngineAttributes: list<record>, EngineVersion: string, InstanceProfileArn: string, InstanceType: string, KeyPair: string, MaintenanceStatus: string, PreferredMaintenanceWindow: string, PreferredBackupWindow: string, SecurityGroupIds: list<string>, ServiceRoleArn: string, Status: string, StatusReason: string, SubnetIds: list<string>, ServerArn: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.CreateServer")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AssociatePublicIpAddress": $associate_public_ip_address, "CustomDomain": $custom_domain, "CustomCertificate": $custom_certificate, "CustomPrivateKey": $custom_private_key, "DisableAutomatedBackup": $disable_automated_backup, "Engine": $engine, "EngineModel": $engine_model, "EngineVersion": $engine_version, "EngineAttributes": $engine_attributes, "BackupRetentionCount": $backup_retention_count, "ServerName": $server_name, "InstanceProfileArn": $instance_profile_arn, "InstanceType": $instance_type, "KeyPair": $key_pair, "PreferredMaintenanceWindow": $preferred_maintenance_window, "PreferredBackupWindow": $preferred_backup_window, "SecurityGroupIds": $security_group_ids, "ServiceRoleArn": $service_role_arn, "SubnetIds": $subnet_ids, "Tags": $tags, "BackupId": $backup_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes a backup. You can delete both manual and automated backups. This operation is asynchronous. An InvalidStateException is thrown when a backup deletion is already in progress. A ResourceNotFoundException is thrown when the backup does not exist. A ValidationException is thrown when parameters of the request are not valid.
#
# POST /
# operationId: DeleteBackup
export def "delete-backup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-3 # required
  backup_id: string # The ID of the backup to delete. Run the DescribeBackups command to get a list of backup IDs. Backup IDs are in the format ServerName-yyyyMMddHHmmssSSS.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.DeleteBackup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BackupId": $backup_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Deletes the server and the underlying AWS CloudFormation stacks (including the server's EC2 instance). When you run this command, the server state is updated to DELETING. After the server is deleted, it is no longer returned by DescribeServer requests. If the AWS CloudFormation stack cannot be deleted, the server cannot be deleted. This operation is asynchronous. An InvalidStateException is thrown when a server deletion is already in progress. A ResourceNotFoundException is thrown when the server does not exist. A ValidationException is raised when parameters of the request are not valid.
#
# POST /
# operationId: DeleteServer
export def "delete-server" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-4 # required
  server_name: string # The ID of the server to delete.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.DeleteServer")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ServerName": $server_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Describes your OpsWorks-CM account attributes. This operation is synchronous.
#
# POST /
# operationId: DescribeAccountAttributes
export def "describe-account-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-5 # required
  --body: record
]: any -> record<Attributes: table<Name: string, Maximum: int, Used: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.DescribeAccountAttributes")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Describes backups. The results are ordered by time, with newest backups first. If you do not specify a BackupId or ServerName, the command returns all backups. This operation is synchronous. A ResourceNotFoundException is thrown when the backup does not exist. A ValidationException is raised when parameters of the request are not valid.
#
# POST /
# operationId: DescribeBackups
export def "describe-backups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-6 # required
  --backup-id: string # Describes a single backup.
  --server-name: string # Returns backups for the server with the specified ServerName.
  --next-token-body: string # This is not currently implemented for DescribeBackups requests. (body field)
  --max-results-body: int # This is not currently implemented for DescribeBackups requests. (body field)
]: any -> record<Backups: table<BackupArn: string, BackupId: string, BackupType: string, CreatedAt: string, Description: string, Engine: string, EngineModel: string, EngineVersion: string, InstanceProfileArn: string, InstanceType: string, KeyPair: string, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, S3DataSize: int, S3DataUrl: string, S3LogUrl: string, SecurityGroupIds: list, ServerName: string, ServiceRoleArn: string, Status: string, StatusDescription: string, SubnetIds: list, ToolsVersion: string, UserArn: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.DescribeBackups")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"BackupId": $backup_id, "ServerName": $server_name, "NextToken": $next_token_body, "MaxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes events for a specified server. Results are ordered by time, with newest events first. This operation is synchronous. A ResourceNotFoundException is thrown when the server does not exist. A ValidationException is raised when parameters of the request are not valid.
#
# POST /
# operationId: DescribeEvents
export def "describe-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-7 # required
  server_name: string # The name of the server for which you want to view events.
  --next-token-body: string # NextToken is a string that is returned in some command responses. It indicates that not all entries have been returned, and that you must run at least one more request to get remaining items. To get remaining results, call DescribeEvents again, and assign the token from the previous results as the value of the nextToken parameter. If there are no more results, the response object's nextToken parameter value is null. Setting a nextToken value that was not returned in your previous results causes an InvalidNextTokenException to occur. (body field)
  --max-results-body: int # To receive a paginated response, use this parameter to specify the maximum number of results to be returned with a single call. If the number of available results exceeds this maximum, the response includes a NextToken value that you can assign to the NextToken request parameter to get the next set of results. (body field)
]: any -> record<ServerEvents: table<CreatedAt: string, ServerName: string, Message: string, LogUrl: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.DescribeEvents")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ServerName": $server_name, "NextToken": $next_token_body, "MaxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the current status of an existing association or disassociation request. A ResourceNotFoundException is thrown when no recent association or disassociation request with the specified token is found, or when the server does not exist. A ValidationException is raised when parameters of the request are not valid.
#
# POST /
# operationId: DescribeNodeAssociationStatus
export def "describe-node-association-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-8 # required
  node_association_status_token: string # The token returned in either the AssociateNodeResponse or the DisassociateNodeResponse.
  server_name: string # The name of the server from which to disassociate the node.
]: any -> record<NodeAssociationStatus: string, EngineAttributes: table<Name: string, Value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.DescribeNodeAssociationStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NodeAssociationStatusToken": $node_association_status_token, "ServerName": $server_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Lists all configuration management servers that are identified with your account. Only the stored results from Amazon DynamoDB are returned. AWS OpsWorks CM does not query other services. This operation is synchronous. A ResourceNotFoundException is thrown when the server does not exist. A ValidationException is raised when parameters of the request are not valid.
#
# POST /
# operationId: DescribeServers
export def "describe-servers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-9 # required
  --server-name: string # Describes the server with the specified ServerName.
  --next-token-body: string # This is not currently implemented for DescribeServers requests. (body field)
  --max-results-body: int # This is not currently implemented for DescribeServers requests. (body field)
]: any -> record<Servers: table<AssociatePublicIpAddress: bool, BackupRetentionCount: int, ServerName: string, CreatedAt: string, CloudFormationStackArn: string, CustomDomain: string, DisableAutomatedBackup: bool, Endpoint: string, Engine: string, EngineModel: string, EngineAttributes: list, EngineVersion: string, InstanceProfileArn: string, InstanceType: string, KeyPair: string, MaintenanceStatus: string, PreferredMaintenanceWindow: string, PreferredBackupWindow: string, SecurityGroupIds: list, ServiceRoleArn: string, Status: string, StatusReason: string, SubnetIds: list, ServerArn: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.DescribeServers")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ServerName": $server_name, "NextToken": $next_token_body, "MaxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Disassociates a node from an AWS OpsWorks CM server, and removes the node from the server's managed nodes. After a node is disassociated, the node key pair is no longer valid for accessing the configuration manager's API. For more information about how to associate a node, see AssociateNode. A node can can only be disassociated from a server that is in a HEALTHY state. Otherwise, an InvalidStateException is thrown. A ResourceNotFoundException is thrown when the server does not exist. A ValidationException is raised when parameters of the request are not valid.
#
# POST /
# operationId: DisassociateNode
# --EngineAttributes item shape: {Name?: string, Value?: string}
export def "disassociate-node" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-10 # required
  server_name: string # The name of the server from which to disassociate the node.
  node_name: string # The node name that is used by chef-client or puppet-agentfor a new node. We recommend to use a unique FQDN as hostname. For more information, see the Chef (https://docs.aws.amazon.com/https:/docs.chef.io/nodes.html#about-node-names) or Puppet (https://docs.aws.amazon.com/https:/docs.puppet.com/puppet/4.10/man/agent.html) documentation.
  --engine-attributes: list # Engine attributes that are used for disassociating the node. No attributes are required for Puppet. Attributes required in a DisassociateNode request for Chef CHEF_ORGANIZATION: The Chef organization with which the node was associated. By default only one organization named default can exist. — item shape: {Name?: string, Value?: string}
]: any -> record<NodeAssociationStatusToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.DisassociateNode")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ServerName": $server_name, "NodeName": $node_name, "EngineAttributes": $engine_attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Exports a specified server engine attribute as a base64-encoded string. For example, you can export user data that you can use in EC2 to associate nodes with a server. This operation is synchronous. A ValidationException is raised when parameters of the request are not valid. A ResourceNotFoundException is thrown when the server does not exist. An InvalidStateException is thrown when the server is in any of the following states: CREATING, TERMINATED, FAILED or DELETING.
#
# POST /
# operationId: ExportServerEngineAttribute
# --InputAttributes item shape: {Name?: string, Value?: string}
export def "export-server-engine-attribute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-11 # required
  export_attribute_name: string # The name of the export attribute. Currently, the supported export attribute is Userdata. This exports a user data script that includes parameters and values provided in the InputAttributes list.
  server_name: string # The name of the server from which you are exporting the attribute.
  --input-attributes: list # The list of engine attributes. The list type is EngineAttribute. An EngineAttribute list item is a pair that includes an attribute name and its value. For the Userdata ExportAttributeName, the following are supported engine attribute names. RunList In Chef, a list of roles or recipes that are run in the specified order. In Puppet, this parameter is ignored. OrganizationName In Chef, an organization name. AWS OpsWorks for Chef Automate always creates the organization default. In Puppet, this parameter is ignored. NodeEnvironment In Chef, a node environment (for example, development, staging, or one-box). In Puppet, this parameter is ignored. NodeClientVersion In Chef, the version of the Chef engine (three numbers separated by dots, such as 13.8.5). If this attribute is empty, OpsWorks for Chef Automate uses the most current version. In Puppet, this parameter is ignored. — item shape: {Name?: string, Value?: string}
]: any -> record<EngineAttribute: record<Name: string, Value: string>, ServerName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.ExportServerEngineAttribute")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ExportAttributeName": $export_attribute_name, "ServerName": $server_name, "InputAttributes": $input_attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Returns a list of tags that are applied to the specified AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise servers or backups.
#
# POST /
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-12 # required
  resource_arn: string # The Amazon Resource Number (ARN) of an AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise server for which you want to show applied tags. For example, arn:aws:opsworks-cm:us-west-2:123456789012:server/test-owcm-server/EXAMPLE-66b0-4196-8274-d1a2bEXAMPLE.
  --next-token-body: string # NextToken is a string that is returned in some command responses. It indicates that not all entries have been returned, and that you must run at least one more request to get remaining items. To get remaining results, call ListTagsForResource again, and assign the token from the previous results as the value of the nextToken parameter. If there are no more results, the response object's nextToken parameter value is null. Setting a nextToken value that was not returned in your previous results causes an InvalidNextTokenException to occur. (body field)
  --max-results-body: int # To receive a paginated response, use this parameter to specify the maximum number of results to be returned with a single call. If the number of available results exceeds this maximum, the response includes a NextToken value that you can assign to the NextToken request parameter to get the next set of results. (body field)
]: any -> record<Tags: table<Key: string, Value: string>, NextToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.ListTagsForResource")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "NextToken": $next_token_body, "MaxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Restores a backup to a server that is in a CONNECTION_LOST, HEALTHY, RUNNING, UNHEALTHY, or TERMINATED state. When you run RestoreServer, the server's EC2 instance is deleted, and a new EC2 instance is configured. RestoreServer maintains the existing server endpoint, so configuration management of the server's client devices (nodes) should continue to work. Restoring from a backup is performed by creating a new EC2 instance. If restoration is successful, and the server is in a HEALTHY state, AWS OpsWorks CM switches traffic over to the new instance. After restoration is finished, the old EC2 instance is maintained in a Running or Stopped state, but is eventually terminated. This operation is asynchronous. An InvalidStateException is thrown when the server is not in a valid state. A ResourceNotFoundException is thrown when the server does not exist. A ValidationException is raised when parameters of the request are not valid.
#
# POST /
# operationId: RestoreServer
export def "restore-server" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-13 # required
  backup_id: string # The ID of the backup that you want to use to restore a server.
  server_name: string # The name of the server that you want to restore.
  --instance-type: string # The type of instance to restore. Valid values must be specified in the following format: ^([cm][34]|t2).* For example, m5.large. Valid values are m5.large, r5.xlarge, and r5.2xlarge. If you do not specify this parameter, RestoreServer uses the instance type from the specified backup.
  --key-pair: string # The name of the key pair to set on the new EC2 instance. This can be helpful if the administrator no longer has the SSH key.
]: any -> record<Server: record<AssociatePublicIpAddress: bool, BackupRetentionCount: int, ServerName: string, CreatedAt: string, CloudFormationStackArn: string, CustomDomain: string, DisableAutomatedBackup: bool, Endpoint: string, Engine: string, EngineModel: string, EngineAttributes: list<record>, EngineVersion: string, InstanceProfileArn: string, InstanceType: string, KeyPair: string, MaintenanceStatus: string, PreferredMaintenanceWindow: string, PreferredBackupWindow: string, SecurityGroupIds: list<string>, ServiceRoleArn: string, Status: string, StatusReason: string, SubnetIds: list<string>, ServerArn: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.RestoreServer")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BackupId": $backup_id, "ServerName": $server_name, "InstanceType": $instance_type, "KeyPair": $key_pair} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Manually starts server maintenance. This command can be useful if an earlier maintenance attempt failed, and the underlying cause of maintenance failure has been resolved. The server is in an UNDER_MAINTENANCE state while maintenance is in progress. Maintenance can only be started on servers in HEALTHY and UNHEALTHY states. Otherwise, an InvalidStateException is thrown. A ResourceNotFoundException is thrown when the server does not exist. A ValidationException is raised when parameters of the request are not valid.
#
# POST /
# operationId: StartMaintenance
# --EngineAttributes item shape: {Name?: string, Value?: string}
export def "start-maintenance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-14 # required
  server_name: string # The name of the server on which to run maintenance.
  --engine-attributes: list # Engine attributes that are specific to the server on which you want to run maintenance. Attributes accepted in a StartMaintenance request for Chef CHEF_MAJOR_UPGRADE: If a Chef Automate server is eligible for upgrade to Chef Automate 2, add this engine attribute to a StartMaintenance request and set the value to true to upgrade the server to Chef Automate 2. For more information, see Upgrade an AWS OpsWorks for Chef Automate Server to Chef Automate 2 (https://docs.aws.amazon.com/opsworks/latest/userguide/opscm-a2upgrade.html). — item shape: {Name?: string, Value?: string}
]: any -> record<Server: record<AssociatePublicIpAddress: bool, BackupRetentionCount: int, ServerName: string, CreatedAt: string, CloudFormationStackArn: string, CustomDomain: string, DisableAutomatedBackup: bool, Endpoint: string, Engine: string, EngineModel: string, EngineAttributes: list<record>, EngineVersion: string, InstanceProfileArn: string, InstanceType: string, KeyPair: string, MaintenanceStatus: string, PreferredMaintenanceWindow: string, PreferredBackupWindow: string, SecurityGroupIds: list<string>, ServiceRoleArn: string, Status: string, StatusReason: string, SubnetIds: list<string>, ServerArn: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.StartMaintenance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ServerName": $server_name, "EngineAttributes": $engine_attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Applies tags to an AWS OpsWorks for Chef Automate or AWS OpsWorks for Puppet Enterprise server, or to server backups.
#
# POST /
# operationId: TagResource
# --Tags item shape: {Key: string, Value: string}
export def "tag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-15 # required
  resource_arn: string # The Amazon Resource Number (ARN) of a resource to which you want to apply tags. For example, arn:aws:opsworks-cm:us-west-2:123456789012:server/test-owcm-server/EXAMPLE-66b0-4196-8274-d1a2bEXAMPLE.
  tags: list # A map that contains tag keys and tag values to attach to AWS OpsWorks-CM servers or backups. The key cannot be empty. The key can be a maximum of 127 characters, and can contain only Unicode letters, numbers, or separators, or the following special characters: + - = . _ : / The value can be a maximum 255 characters, and contain only Unicode letters, numbers, or separators, or the following special characters: + - = . _ : / Leading and trailing white spaces are trimmed from both the key and value. A maximum of 50 user-applied tags is allowed for any AWS OpsWorks-CM server or backup. — item shape: {Key: string, Value: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.TagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Removes specified tags from an AWS OpsWorks-CM server or backup.
#
# POST /
# operationId: UntagResource
export def "untag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-16 # required
  resource_arn: string # The Amazon Resource Number (ARN) of a resource from which you want to remove tags. For example, arn:aws:opsworks-cm:us-west-2:123456789012:server/test-owcm-server/EXAMPLE-66b0-4196-8274-d1a2bEXAMPLE.
  tag_keys: list<string> # The keys of tags that you want to remove.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.UntagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates settings for a server. This operation is synchronous.
#
# POST /
# operationId: UpdateServer
export def "update-server" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-17 # required
  --disable-automated-backup: oneof<nothing, bool> # Setting DisableAutomatedBackup to true disables automated or scheduled backups. Automated backups are enabled by default.
  --backup-retention-count: int # Sets the number of automated backups that you want to keep.
  server_name: string # The name of the server to update.
  --preferred-maintenance-window: string # DDD:HH:MM (weekly start time) or HH:MM (daily start time). Time windows always use coordinated universal time (UTC). Valid strings for day of week (DDD) are: Mon, Tue, Wed, Thr, Fri, Sat, or Sun.
  --preferred-backup-window: string # DDD:HH:MM (weekly start time) or HH:MM (daily start time). Time windows always use coordinated universal time (UTC). Valid strings for day of week (DDD) are: Mon, Tue, Wed, Thr, Fri, Sat, or Sun.
]: any -> record<Server: record<AssociatePublicIpAddress: bool, BackupRetentionCount: int, ServerName: string, CreatedAt: string, CloudFormationStackArn: string, CustomDomain: string, DisableAutomatedBackup: bool, Endpoint: string, Engine: string, EngineModel: string, EngineAttributes: list<record>, EngineVersion: string, InstanceProfileArn: string, InstanceType: string, KeyPair: string, MaintenanceStatus: string, PreferredMaintenanceWindow: string, PreferredBackupWindow: string, SecurityGroupIds: list<string>, ServiceRoleArn: string, Status: string, StatusReason: string, SubnetIds: list<string>, ServerArn: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.UpdateServer")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DisableAutomatedBackup": $disable_automated_backup, "BackupRetentionCount": $backup_retention_count, "ServerName": $server_name, "PreferredMaintenanceWindow": $preferred_maintenance_window, "PreferredBackupWindow": $preferred_backup_window} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Updates engine-specific attributes on a specified server. The server enters the MODIFYING state when this operation is in progress. Only one update can occur at a time. You can use this command to reset a Chef server's public key (CHEF_PIVOTAL_KEY) or a Puppet server's admin password (PUPPET_ADMIN_PASSWORD). This operation is asynchronous. This operation can only be called for servers in HEALTHY or UNHEALTHY states. Otherwise, an InvalidStateException is raised. A ResourceNotFoundException is thrown when the server does not exist. A ValidationException is raised when parameters of the request are not valid.
#
# POST /
# operationId: UpdateServerEngineAttributes
export def "update-server-engine-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-18 # required
  server_name: string # The name of the server to update.
  attribute_name: string # The name of the engine attribute to update.
  --attribute-value: string # The value to set for the attribute.
]: any -> record<Server: record<AssociatePublicIpAddress: bool, BackupRetentionCount: int, ServerName: string, CreatedAt: string, CloudFormationStackArn: string, CustomDomain: string, DisableAutomatedBackup: bool, Endpoint: string, Engine: string, EngineModel: string, EngineAttributes: list<record>, EngineVersion: string, InstanceProfileArn: string, InstanceType: string, KeyPair: string, MaintenanceStatus: string, PreferredMaintenanceWindow: string, PreferredBackupWindow: string, SecurityGroupIds: list<string>, ServiceRoleArn: string, Status: string, StatusReason: string, SubnetIds: list<string>, ServerArn: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "OpsWorksCM_V2016_11_01.UpdateServerEngineAttributes")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ServerName": $server_name, "AttributeName": $attribute_name, "AttributeValue": $attribute_value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
