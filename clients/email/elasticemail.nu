# Auto-generated client for Elastic Email REST API v4.0.0
# Source: https://raw.githubusercontent.com/elasticemail/elasticemail-go/master/api/openapi.yaml
# Auth: --token flag or $env.ELASTIC_EMAIL_REST_API_TOKEN

const BASE_URL = "https://api.elasticemail.com/v4"
const DEFAULT_AUTH = "x-elasticemail-apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ELASTIC_EMAIL_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-elasticemail-apikey" => { {headers: {X-ElasticEmail-ApiKey: $token_val}, query: ""} }
    "x-auth-token" => { {headers: {X-Auth-Token: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.elasticemail.com/v4"] }
def auth-scheme-completer [] { ["x-elasticemail-apikey" "x-auth-token"] }

# Completers for enum parameters
def Status-completer [] { ["Active" "Cancelled" "Completed" "Deleted" "Draft" "Paused" "Processing" "Sending"] }
def CertificateStatus-completer [] { ["CertNotSet" "ErrorOccured" "NotValid" "Valid"] }
def FilterType-completer [] { ["EmailAddress" "Subject"] }
def ActionType-completer [] { ["ForwardToEmail" "NotifyViaHttp" "Stop"] }
def TemplateScope-completer [] { ["Global" "Personal"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "campaigns campaignsGet" } } | get name | first)
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

# Load Campaigns
#
# GET /campaigns
# operationId: campaignsGet
export def "campaigns campaignsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Text fragment used for searching in Campaign name (using the 'contains' rule) (format: string)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
]: nothing -> table<Content: list<record>, Name: string, Status: string, Recipients: record<ListNames: list, SegmentNames: list>, ExcludedRecipients: record<ListNames: list, SegmentNames: list>, Options: record<DeliveryOptimization: string, TrackOpens: bool, TrackClicks: bool, ScheduleFor: string, TriggerFrequency: float, TriggerCount: int, SplitOptions: record, SendAtLocalTime: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/campaigns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Campaign
#
# POST /campaigns
# operationId: campaignsPost
# --Content item shape: {Poolname?: string, From: string, ReplyTo?: string, Subject?: string, TemplateName?: string, AttachFiles?: list, Utm?: record}
# --Recipients shape: {ListNames?: list, SegmentNames?: list}
# --ExcludedRecipients shape: {ListNames?: list, SegmentNames?: list}
# --Options shape: {DeliveryOptimization?: "None"|"ToEngagedFirst"|"ByOpenTime", TrackOpens?: bool, TrackClicks?: bool, ScheduleFor?: string, TriggerFrequency?: float, TriggerCount?: int, SplitOptions?: record, SendAtLocalTime?: bool}
export def "campaigns campaignsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content: list # Campaign's email content. Provide multiple items to send an A/X Split Campaign — item shape: {Poolname?: string, From: string, ReplyTo?: string, Subject?: string, TemplateName?: string, AttachFiles?: list, Utm?: record}
  Name: string # Campaign name (format: string)
  --Status: string@Status-completer # default: Deleted
  Recipients: record # A set of lists and segments names to read recipients from (e.g. {SegmentNames: [SegmentNames, SegmentNames], ListNames: [ListNames, ListNames]}) — shape: {ListNames?: list, SegmentNames?: list}
  --ExcludedRecipients: record # A set of lists and segments names to read recipients from (e.g. {SegmentNames: [SegmentNames, SegmentNames], ListNames: [ListNames, ListNames]}) — shape: {ListNames?: list, SegmentNames?: list}
  --Options: record # Different send options for a Campaign (e.g. {TrackClicks: true, TriggerCount: 6, ScheduleFor: 2000-01-23T04:56:07.000+00:00, SendAtLocalTime: true, TriggerFrequency: 0.8008281904610115, DeliveryOptimization: None, TrackOpens: true, SplitOptions: {OptimizeFor: Opens, OptimizePeriodMinutes: 30}}) — shape: {DeliveryOptimization?: "None"|"ToEngagedFirst"|"ByOpenTime", TrackOpens?: bool, TrackClicks?: bool, ScheduleFor?: string, TriggerFrequency?: float, TriggerCount?: int, SplitOptions?: record, SendAtLocalTime?: bool}
]: any -> record<Content: table<Poolname: string, From: string, ReplyTo: string, Subject: string, TemplateName: string, AttachFiles: list, Utm: record>, Name: string, Status: string, Recipients: record<ListNames: list<string>, SegmentNames: list<string>>, ExcludedRecipients: record<ListNames: list<string>, SegmentNames: list<string>>, Options: record<DeliveryOptimization: string, TrackOpens: bool, TrackClicks: bool, ScheduleFor: string, TriggerFrequency: float, TriggerCount: int, SplitOptions: record<OptimizeFor: string, OptimizePeriodMinutes: int>, SendAtLocalTime: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/campaigns")
  let body = {Content: $Content, Name: $Name, Status: $Status, Recipients: $Recipients, ExcludedRecipients: $ExcludedRecipients, Options: $Options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Campaign
#
# DELETE /campaigns/{name}
# operationId: campaignsByNameDelete
export def "campaigns campaignsByNameDelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load Campaign
#
# GET /campaigns/{name}
# operationId: campaignsByNameGet
export def "campaigns campaignsByNameGet" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Content: table<Poolname: string, From: string, ReplyTo: string, Subject: string, TemplateName: string, AttachFiles: list, Utm: record>, Name: string, Status: string, Recipients: record<ListNames: list<string>, SegmentNames: list<string>>, ExcludedRecipients: record<ListNames: list<string>, SegmentNames: list<string>>, Options: record<DeliveryOptimization: string, TrackOpens: bool, TrackClicks: bool, ScheduleFor: string, TriggerFrequency: float, TriggerCount: int, SplitOptions: record<OptimizeFor: string, OptimizePeriodMinutes: int>, SendAtLocalTime: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Campaign
#
# PUT /campaigns/{name}
# operationId: campaignsByNamePut
# --Content item shape: {Poolname?: string, From: string, ReplyTo?: string, Subject?: string, TemplateName?: string, AttachFiles?: list, Utm?: record}
# --Recipients shape: {ListNames?: list, SegmentNames?: list}
# --ExcludedRecipients shape: {ListNames?: list, SegmentNames?: list}
# --Options shape: {DeliveryOptimization?: "None"|"ToEngagedFirst"|"ByOpenTime", TrackOpens?: bool, TrackClicks?: bool, ScheduleFor?: string, TriggerFrequency?: float, TriggerCount?: int, SplitOptions?: record, SendAtLocalTime?: bool}
export def "campaigns campaignsByNamePut" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content: list # Campaign's email content. Provide multiple items to send an A/X Split Campaign — item shape: {Poolname?: string, From: string, ReplyTo?: string, Subject?: string, TemplateName?: string, AttachFiles?: list, Utm?: record}
  Name: string # Campaign name (format: string)
  --Status: string@Status-completer # default: Deleted
  Recipients: record # A set of lists and segments names to read recipients from (e.g. {SegmentNames: [SegmentNames, SegmentNames], ListNames: [ListNames, ListNames]}) — shape: {ListNames?: list, SegmentNames?: list}
  --ExcludedRecipients: record # A set of lists and segments names to read recipients from (e.g. {SegmentNames: [SegmentNames, SegmentNames], ListNames: [ListNames, ListNames]}) — shape: {ListNames?: list, SegmentNames?: list}
  --Options: record # Different send options for a Campaign (e.g. {TrackClicks: true, TriggerCount: 6, ScheduleFor: 2000-01-23T04:56:07.000+00:00, SendAtLocalTime: true, TriggerFrequency: 0.8008281904610115, DeliveryOptimization: None, TrackOpens: true, SplitOptions: {OptimizeFor: Opens, OptimizePeriodMinutes: 30}}) — shape: {DeliveryOptimization?: "None"|"ToEngagedFirst"|"ByOpenTime", TrackOpens?: bool, TrackClicks?: bool, ScheduleFor?: string, TriggerFrequency?: float, TriggerCount?: int, SplitOptions?: record, SendAtLocalTime?: bool}
]: any -> record<Content: table<Poolname: string, From: string, ReplyTo: string, Subject: string, TemplateName: string, AttachFiles: list, Utm: record>, Name: string, Status: string, Recipients: record<ListNames: list<string>, SegmentNames: list<string>>, ExcludedRecipients: record<ListNames: list<string>, SegmentNames: list<string>>, Options: record<DeliveryOptimization: string, TrackOpens: bool, TrackClicks: bool, ScheduleFor: string, TriggerFrequency: float, TriggerCount: int, SplitOptions: record<OptimizeFor: string, OptimizePeriodMinutes: int>, SendAtLocalTime: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($name)")
  let body = {Content: $Content, Name: $Name, Status: $Status, Recipients: $Recipients, ExcludedRecipients: $ExcludedRecipients, Options: $Options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Pause Campaign
#
# PUT /campaigns/{name}/pause
# operationId: campaignsByNamePausePut
export def "campaigns-pause campaignsByNamePausePut" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/campaigns/($name)/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load Contacts
#
# GET /contacts
# operationId: contactsGet
export def "contacts contactsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<Email: string, Status: string, FirstName: string, LastName: string, CustomFields: record, Consent: record<ConsentIP: string, ConsentDate: string, ConsentTracking: string>, Source: string, SourceInfo: string, DateAdded: string, DateUpdated: string, StatusChangeDate: string, Activity: record<TotalSent: int, TotalOpened: int, TotalClicked: int, TotalFailed: int, LastSent: string, LastOpened: string, LastClicked: string, LastFailed: string, LastIP: string, ErrorCode: int, FriendlyErrorMessage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Contact
#
# POST /contacts
# operationId: contactsPost
export def "contacts contactsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listnames: list # Names of lists to which the uploaded contacts should be added to
  --body: record
]: any -> table<Email: string, Status: string, FirstName: string, LastName: string, CustomFields: record, Consent: record<ConsentIP: string, ConsentDate: string, ConsentTracking: string>, Source: string, SourceInfo: string, DateAdded: string, DateUpdated: string, StatusChangeDate: string, Activity: record<TotalSent: int, TotalOpened: int, TotalClicked: int, TotalFailed: int, LastSent: string, LastOpened: string, LastClicked: string, LastFailed: string, LastIP: string, ErrorCode: int, FriendlyErrorMessage: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listnames" $listnames "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Contact
#
# DELETE /contacts/{email}
# operationId: contactsByEmailDelete
export def "contacts contactsByEmailDelete" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load Contact
#
# GET /contacts/{email}
# operationId: contactsByEmailGet
export def "contacts contactsByEmailGet" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Email: string, Status: string, FirstName: string, LastName: string, CustomFields: record, Consent: record<ConsentIP: string, ConsentDate: string, ConsentTracking: string>, Source: string, SourceInfo: string, DateAdded: string, DateUpdated: string, StatusChangeDate: string, Activity: record<TotalSent: int, TotalOpened: int, TotalClicked: int, TotalFailed: int, LastSent: string, LastOpened: string, LastClicked: string, LastFailed: string, LastIP: string, ErrorCode: int, FriendlyErrorMessage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Contact
#
# PUT /contacts/{email}
# operationId: contactsByEmailPut
export def "contacts contactsByEmailPut" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FirstName: string # First name. (format: string, e.g. Fred)
  --LastName: string # Last name. (format: string, e.g. Flintstone)
  --CustomFields: record # A key-value collection of custom contact fields which can be used in the system. (e.g. {city: New York, age: 34})
]: any -> record<Email: string, Status: string, FirstName: string, LastName: string, CustomFields: record, Consent: record<ConsentIP: string, ConsentDate: string, ConsentTracking: string>, Source: string, SourceInfo: string, DateAdded: string, DateUpdated: string, StatusChangeDate: string, Activity: record<TotalSent: int, TotalOpened: int, TotalClicked: int, TotalFailed: int, LastSent: string, LastOpened: string, LastClicked: string, LastFailed: string, LastIP: string, ErrorCode: int, FriendlyErrorMessage: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/($email)")
  let body = {FirstName: $FirstName, LastName: $LastName, CustomFields: $CustomFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Contacts Bulk
#
# POST /contacts/delete
# operationId: contactsDeletePost
export def "contacts-delete contactsDeletePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Rule: string # SQL-like rule. Sending 'All' as a value loads all resources of the given type. Help for building a segment rule can be found here: https://help.elasticemail.com/en/articles/5162182-segment-rules (format: string)
  --Emails: list # Comma delimited list of contact emails (e.g. [john.doe@sample.com])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts/delete")
  let body = {Rule: $Rule, Emails: $Emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export Contacts
#
# POST /contacts/export
# operationId: contactsExportPost
export def "contacts-export contactsExportPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fileFormat: string # Format of the exported file
  --rule: string # Query used for filtering. (format: string, e.g. Status%20=%20Engaged)
  --emails: list # Comma delimited list of contact emails (e.g. [mail@contact.com,mail1@contact.com,mail2@contact.com])
  --compressionFormat: string # FileResponse compression format. None or Zip.
  --fileName: string # Name of your file including extension. (format: string, e.g. filename.txt)
]: nothing -> record<Link: string, PublicExportID: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fileFormat" $fileFormat "scalar") (serialize-qp "rule" $rule "scalar") (serialize-qp "emails" $emails "multi") (serialize-qp "compressionFormat" $compressionFormat "scalar") (serialize-qp "fileName" $fileName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check Export Status
#
# GET /contacts/export/{id}/status
# operationId: contactsExportByIdStatusGet
export def "contacts-export-status contactsExportByIdStatusGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/export/($id)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload Contacts
#
# POST /contacts/import
# operationId: contactsImportPost
export def "contacts-import contactsImportPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listName: string # Name of an existing list to add these contacts to (format: string)
  --encodingName: string # In what encoding the file is uploaded (format: string)
  --fileUrl: string # Optional url of csv to import (format: string)
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listName" $listName "scalar") (serialize-qp "encodingName" $encodingName "scalar") (serialize-qp "fileUrl" $fileUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts/import" $qp)
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Load Domains
#
# GET /domains
# operationId: domainsGet
export def "domains domainsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<Domain: string, DefaultDomain: bool, Spf: bool, Dkim: bool, MX: bool, DMARC: bool, IsRewriteDomainValid: bool, Verify: bool, Type: string, TrackingStatus: string, CertificateStatus: string, CertificateValidationError: string, TrackingTypeUserRequest: string, VERP: bool, CustomBouncesDomain: string, IsCustomBouncesDomainDefault: bool, IsMarkedForDeletion: bool, Ownership: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Domain
#
# POST /domains
# operationId: domainsPost
export def "domains domainsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Domain: string # Name of selected domain. (format: string, e.g. example.com)
  --SetAsDefault: string@bool-completer # format: boolean
]: any -> record<Domain: string, DefaultDomain: bool, Spf: bool, Dkim: bool, MX: bool, DMARC: bool, IsRewriteDomainValid: bool, Verify: bool, Type: string, TrackingStatus: string, CertificateStatus: string, CertificateValidationError: string, TrackingTypeUserRequest: string, VERP: bool, CustomBouncesDomain: string, IsCustomBouncesDomainDefault: bool, IsMarkedForDeletion: bool, Ownership: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains")
  let body = {Domain: $Domain, SetAsDefault: $SetAsDefault} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Domain
#
# DELETE /domains/{domain}
# operationId: domainsByDomainDelete
export def "domains domainsByDomainDelete" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($domain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load Domain
#
# GET /domains/{domain}
# operationId: domainsByDomainGet
export def "domains domainsByDomainGet" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ValidationLog: string, Domain: string, DefaultDomain: bool, Spf: bool, Dkim: bool, MX: bool, DMARC: bool, IsRewriteDomainValid: bool, Verify: bool, Type: string, TrackingStatus: string, CertificateStatus: string, CertificateValidationError: string, TrackingTypeUserRequest: string, VERP: bool, CustomBouncesDomain: string, IsCustomBouncesDomainDefault: bool, IsMarkedForDeletion: bool, Ownership: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($domain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Domain
#
# PUT /domains/{domain}
# operationId: domainsByDomainPut
export def "domains domainsByDomainPut" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --CertificateStatus: string@CertificateStatus-completer # default: ErrorOccured
  --VERP: string@bool-completer # format: boolean
  --CustomBouncesDomain: string # format: string
  --IsCustomBouncesDomainDefault: string@bool-completer # format: boolean
]: any -> record<Domain: string, DefaultDomain: bool, Spf: bool, Dkim: bool, MX: bool, DMARC: bool, IsRewriteDomainValid: bool, Verify: bool, Type: string, TrackingStatus: string, CertificateStatus: string, CertificateValidationError: string, TrackingTypeUserRequest: string, VERP: bool, CustomBouncesDomain: string, IsCustomBouncesDomainDefault: bool, IsMarkedForDeletion: bool, Ownership: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($domain)")
  let body = {CertificateStatus: $CertificateStatus, VERP: $VERP, CustomBouncesDomain: $CustomBouncesDomain, IsCustomBouncesDomainDefault: $IsCustomBouncesDomainDefault} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check for domain restriction
#
# GET /domains/{domain}/restricted
# operationId: domainsByDomainRestrictedGet
export def "domains-restricted domainsByDomainRestrictedGet" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($domain)/restricted")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify Domain
#
# PUT /domains/{domain}/verification
# operationId: domainsByDomainVerificationPut
export def "domains-verification domainsByDomainVerificationPut" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<ValidationLog: string, Domain: string, DefaultDomain: bool, Spf: bool, Dkim: bool, MX: bool, DMARC: bool, IsRewriteDomainValid: bool, Verify: bool, Type: string, TrackingStatus: string, CertificateStatus: string, CertificateValidationError: string, TrackingTypeUserRequest: string, VERP: bool, CustomBouncesDomain: string, IsCustomBouncesDomainDefault: bool, IsMarkedForDeletion: bool, Ownership: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($domain)/verification")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Default
#
# PATCH /domains/{email}/default
# operationId: domainsByEmailDefaultPatch
export def "domains-default domainsByEmailDefaultPatch" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Domain: string, DefaultDomain: bool, Spf: bool, Dkim: bool, MX: bool, DMARC: bool, IsRewriteDomainValid: bool, Verify: bool, Type: string, TrackingStatus: string, CertificateStatus: string, CertificateValidationError: string, TrackingTypeUserRequest: string, VERP: bool, CustomBouncesDomain: string, IsCustomBouncesDomainDefault: bool, IsMarkedForDeletion: bool, Ownership: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($email)/default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send Bulk Emails
#
# POST /emails
# operationId: emailsPost
# --Recipients item shape: {Email: string, Fields?: record}
# --Content shape: {Body?: list, Merge?: record, Attachments?: list, Headers?: record, Postback?: string, EnvelopeFrom?: string, From: string, ReplyTo?: string, Subject?: string, TemplateName?: string, AttachFiles?: list, Utm?: record}
# --Options shape: {TimeOffset?: int, PoolName?: string, ChannelName?: string, Encoding?: "UserProvided"|"None"|"Raw7bit"|"Raw8bit"|"QuotedPrintable"|"Base64"|"Uue", TrackOpens?: bool, TrackClicks?: bool}
export def "emails emailsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Recipients: list # List of recipients — item shape: {Email: string, Fields?: record}
  Content: record # Proper e-mail content (e.g. {ReplyTo: John Doe <email@domain.com>,John Doe2 <email2@domain.com>, Merge: {city: New York, age: 34}, Headers: {city: New York, age: 34}, Postback: Postback, EnvelopeFrom: John Doe <email@domain.com>, TemplateName: Template01, From: John Doe <email@domain.com>, AttachFiles: [preuploaded.jpg], Body: [{ContentType: HTML, Content: Content, Charset: Charset}, {ContentType: HTML, Content: Content, Charset: Charset}], Attachments: [{ContentType: ContentType, Size: 0, BinaryContent: BinaryContent, Name: Name}, {ContentType: ContentType, Size: 0, BinaryContent: BinaryContent, Name: Name}], Subject: Hello!, Utm: {Campaign: Campaign, Medium: Medium, Content: Content, Source: Source}}) — shape: {Body?: list, Merge?: record, Attachments?: list, Headers?: record, Postback?: string, EnvelopeFrom?: string, From: string, ReplyTo?: string, Subject?: string, TemplateName?: string, AttachFiles?: list, Utm?: record}
  --Options: record # E-mail configuration (e.g. {TrackClicks: true, ChannelName: Channel01, PoolName: My Custom Pool, Encoding: UserProvided, TimeOffset: 6, TrackOpens: true}) — shape: {TimeOffset?: int, PoolName?: string, ChannelName?: string, Encoding?: "UserProvided"|"None"|"Raw7bit"|"Raw8bit"|"QuotedPrintable"|"Base64"|"Uue", TrackOpens?: bool, TrackClicks?: bool}
]: any -> record<TransactionID: string, MessageID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/emails")
  let body = {Recipients: $Recipients, Content: $Content, Options: $Options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# View Email
#
# GET /emails/{msgid}/view
# operationId: emailsByMsgidViewGet
export def "emails-view emailsByMsgidViewGet" [
  msgid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Preview: record<Body: string, Subject: string, From: string>, Attachments: table<FileName: string, Size: int, DateAdded: string, ExpirationDate: string, ContentType: string>, Status: record<From: string, To: string, Date: string, Status: string, StatusName: string, StatusChangeDate: string, DateSent: string, DateOpened: string, DateClicked: string, ErrorMessage: string, TransactionID: string, EnvelopeFrom: string, ErrorCategory: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/emails/($msgid)/view")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Status
#
# GET /emails/{transactionid}/status
# operationId: emailsByTransactionidStatusGet
export def "emails-status emailsByTransactionidStatusGet" [
  transactionid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --showFailed: string@bool-completer # Include Bounced email addresses. (format: boolean, default: false)
  --showSent: string@bool-completer # Include Sent email addresses. (format: boolean, default: false)
  --showDelivered: string@bool-completer # Include all delivered email addresses. (format: boolean, default: false)
  --showPending: string@bool-completer # Include Ready to send email addresses. (format: boolean, default: false)
  --showOpened: string@bool-completer # Include Opened email addresses. (format: boolean, default: false)
  --showClicked: string@bool-completer # Include Clicked email addresses. (format: boolean, default: false)
  --showAbuse: string@bool-completer # Include Reported as abuse email addresses. (format: boolean, default: false)
  --showUnsubscribed: string@bool-completer # Include Unsubscribed email addresses. (format: boolean, default: false)
  --showErrors: string@bool-completer # Include error messages for bounced emails. (format: boolean, default: false)
  --showMessageIDs: string@bool-completer # Include all MessageIDs for this transaction (format: boolean, default: false)
]: nothing -> record<ID: string, Status: string, RecipientsCount: int, Failed: table<Address: string, Error: string, ErrorCode: int, Category: string>, FailedCount: int, Sent: list<string>, SentCount: int, Delivered: list<string>, DeliveredCount: int, Pending: list<string>, PendingCount: int, Opened: list<string>, OpenedCount: int, Clicked: list<string>, ClickedCount: int, Unsubscribed: list<string>, UnsubscribedCount: int, AbuseReports: list<string>, AbuseReportsCount: int, MessageIDs: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showFailed" $showFailed "scalar") (serialize-qp "showSent" $showSent "scalar") (serialize-qp "showDelivered" $showDelivered "scalar") (serialize-qp "showPending" $showPending "scalar") (serialize-qp "showOpened" $showOpened "scalar") (serialize-qp "showClicked" $showClicked "scalar") (serialize-qp "showAbuse" $showAbuse "scalar") (serialize-qp "showUnsubscribed" $showUnsubscribed "scalar") (serialize-qp "showErrors" $showErrors "scalar") (serialize-qp "showMessageIDs" $showMessageIDs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/emails/($transactionid)/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send Bulk Emails CSV
#
# POST /emails/mergefile
# operationId: emailsMergefilePost
# --MergeFile shape: {BinaryContent: string, Name: string, ContentType?: string, Size?: int}
# --Content shape: {Body?: list, Merge?: record, Attachments?: list, Headers?: record, Postback?: string, EnvelopeFrom?: string, From: string, ReplyTo?: string, Subject?: string, TemplateName?: string, AttachFiles?: list, Utm?: record}
# --Options shape: {TimeOffset?: int, PoolName?: string, ChannelName?: string, Encoding?: "UserProvided"|"None"|"Raw7bit"|"Raw8bit"|"QuotedPrintable"|"Base64"|"Uue", TrackOpens?: bool, TrackClicks?: bool}
export def "emails-mergefile emailsMergefilePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  MergeFile: record # e.g. {ContentType: ContentType, Size: 0, BinaryContent: BinaryContent, Name: Name} — shape: {BinaryContent: string, Name: string, ContentType?: string, Size?: int}
  Content: record # Proper e-mail content (e.g. {ReplyTo: John Doe <email@domain.com>,John Doe2 <email2@domain.com>, Merge: {city: New York, age: 34}, Headers: {city: New York, age: 34}, Postback: Postback, EnvelopeFrom: John Doe <email@domain.com>, TemplateName: Template01, From: John Doe <email@domain.com>, AttachFiles: [preuploaded.jpg], Body: [{ContentType: HTML, Content: Content, Charset: Charset}, {ContentType: HTML, Content: Content, Charset: Charset}], Attachments: [{ContentType: ContentType, Size: 0, BinaryContent: BinaryContent, Name: Name}, {ContentType: ContentType, Size: 0, BinaryContent: BinaryContent, Name: Name}], Subject: Hello!, Utm: {Campaign: Campaign, Medium: Medium, Content: Content, Source: Source}}) — shape: {Body?: list, Merge?: record, Attachments?: list, Headers?: record, Postback?: string, EnvelopeFrom?: string, From: string, ReplyTo?: string, Subject?: string, TemplateName?: string, AttachFiles?: list, Utm?: record}
  --Options: record # E-mail configuration (e.g. {TrackClicks: true, ChannelName: Channel01, PoolName: My Custom Pool, Encoding: UserProvided, TimeOffset: 6, TrackOpens: true}) — shape: {TimeOffset?: int, PoolName?: string, ChannelName?: string, Encoding?: "UserProvided"|"None"|"Raw7bit"|"Raw8bit"|"QuotedPrintable"|"Base64"|"Uue", TrackOpens?: bool, TrackClicks?: bool}
]: any -> record<TransactionID: string, MessageID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/emails/mergefile")
  let body = {MergeFile: $MergeFile, Content: $Content, Options: $Options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send Transactional Email
#
# POST /emails/transactional
# operationId: emailsTransactionalPost
# --Recipients shape: {To: list, CC?: list, BCC?: list}
# --Content shape: {Body?: list, Merge?: record, Attachments?: list, Headers?: record, Postback?: string, EnvelopeFrom?: string, From: string, ReplyTo?: string, Subject?: string, TemplateName?: string, AttachFiles?: list, Utm?: record}
# --Options shape: {TimeOffset?: int, PoolName?: string, ChannelName?: string, Encoding?: "UserProvided"|"None"|"Raw7bit"|"Raw8bit"|"QuotedPrintable"|"Base64"|"Uue", TrackOpens?: bool, TrackClicks?: bool}
export def "emails-transactional emailsTransactionalPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Recipients: record # List of transactional recipients (e.g. {CC: [CC, CC], BCC: [BCC, BCC], To: [To, To]}) — shape: {To: list, CC?: list, BCC?: list}
  Content: record # Proper e-mail content (e.g. {ReplyTo: John Doe <email@domain.com>,John Doe2 <email2@domain.com>, Merge: {city: New York, age: 34}, Headers: {city: New York, age: 34}, Postback: Postback, EnvelopeFrom: John Doe <email@domain.com>, TemplateName: Template01, From: John Doe <email@domain.com>, AttachFiles: [preuploaded.jpg], Body: [{ContentType: HTML, Content: Content, Charset: Charset}, {ContentType: HTML, Content: Content, Charset: Charset}], Attachments: [{ContentType: ContentType, Size: 0, BinaryContent: BinaryContent, Name: Name}, {ContentType: ContentType, Size: 0, BinaryContent: BinaryContent, Name: Name}], Subject: Hello!, Utm: {Campaign: Campaign, Medium: Medium, Content: Content, Source: Source}}) — shape: {Body?: list, Merge?: record, Attachments?: list, Headers?: record, Postback?: string, EnvelopeFrom?: string, From: string, ReplyTo?: string, Subject?: string, TemplateName?: string, AttachFiles?: list, Utm?: record}
  --Options: record # E-mail configuration (e.g. {TrackClicks: true, ChannelName: Channel01, PoolName: My Custom Pool, Encoding: UserProvided, TimeOffset: 6, TrackOpens: true}) — shape: {TimeOffset?: int, PoolName?: string, ChannelName?: string, Encoding?: "UserProvided"|"None"|"Raw7bit"|"Raw8bit"|"QuotedPrintable"|"Base64"|"Uue", TrackOpens?: bool, TrackClicks?: bool}
]: any -> record<TransactionID: string, MessageID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/emails/transactional")
  let body = {Recipients: $Recipients, Content: $Content, Options: $Options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Load Events
#
# GET /events
# operationId: eventsGet
export def "events eventsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --eventTypes: list # Types of Events to return
  --qp-from: string # Starting date for search in YYYY-MM-DDThh:mm:ss format. (nullable, format: date-time)
  --qp-to: string # Ending date for search in YYYY-MM-DDThh:mm:ss format. (nullable, format: date-time)
  --orderBy: string
  --limit: int # How many items to load. Maximum for this request is 1000 items (format: int32)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<TransactionID: string, MsgID: string, FromEmail: string, To: string, Subject: string, EventType: string, EventDate: string, ChannelName: string, MessageCategory: string, NextTryOn: string, Message: string, IPAddress: string, PoolName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "eventTypes" $eventTypes "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load Email Events
#
# GET /events/{transactionid}
# operationId: eventsByTransactionidGet
export def "events eventsByTransactionidGet" [
  transactionid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Starting date for search in YYYY-MM-DDThh:mm:ss format. (nullable, format: date-time)
  --qp-to: string # Ending date for search in YYYY-MM-DDThh:mm:ss format. (nullable, format: date-time)
  --orderBy: string
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<TransactionID: string, MsgID: string, FromEmail: string, To: string, Subject: string, EventType: string, EventDate: string, ChannelName: string, MessageCategory: string, NextTryOn: string, Message: string, IPAddress: string, PoolName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/events/($transactionid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load Channel Events
#
# GET /events/channels/{name}
# operationId: eventsChannelsByNameGet
export def "events-channels eventsChannelsByNameGet" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --eventTypes: list # Types of Events to return
  --qp-from: string # Starting date for search in YYYY-MM-DDThh:mm:ss format. (nullable, format: date-time)
  --qp-to: string # Ending date for search in YYYY-MM-DDThh:mm:ss format. (nullable, format: date-time)
  --orderBy: string
  --limit: int # How many items to load. Maximum for this request is 1000 items (format: int32)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<TransactionID: string, MsgID: string, FromEmail: string, To: string, Subject: string, EventType: string, EventDate: string, ChannelName: string, MessageCategory: string, NextTryOn: string, Message: string, IPAddress: string, PoolName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "eventTypes" $eventTypes "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/events/channels/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export Channel Events
#
# POST /events/channels/{name}/export
# operationId: eventsChannelsByNameExportPost
export def "events-channels-export eventsChannelsByNameExportPost" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --eventTypes: list # Types of Events to return
  --qp-from: string # Starting date for search in YYYY-MM-DDThh:mm:ss format. (nullable, format: date-time)
  --qp-to: string # Ending date for search in YYYY-MM-DDThh:mm:ss format. (nullable, format: date-time)
  --fileFormat: string # Format of the exported file
  --compressionFormat: string # FileResponse compression format. None or Zip.
  --fileName: string # Name of your file including extension. (format: string, e.g. filename.txt)
]: nothing -> record<Link: string, PublicExportID: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "eventTypes" $eventTypes "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "fileFormat" $fileFormat "scalar") (serialize-qp "compressionFormat" $compressionFormat "scalar") (serialize-qp "fileName" $fileName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/events/channels/($name)/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check Channel Export Status
#
# GET /events/channels/export/{id}/status
# operationId: eventsChannelsExportByIdStatusGet
export def "events-channels-export-status eventsChannelsExportByIdStatusGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/events/channels/export/($id)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export Events
#
# POST /events/export
# operationId: eventsExportPost
export def "events-export eventsExportPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --eventTypes: list # Types of Events to return
  --qp-from: string # Starting date for search in YYYY-MM-DDThh:mm:ss format. (nullable, format: date-time)
  --qp-to: string # Ending date for search in YYYY-MM-DDThh:mm:ss format. (nullable, format: date-time)
  --fileFormat: string # Format of the exported file
  --compressionFormat: string # FileResponse compression format. None or Zip.
  --fileName: string # Name of your file including extension. (format: string, e.g. filename.txt)
]: nothing -> record<Link: string, PublicExportID: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "eventTypes" $eventTypes "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "fileFormat" $fileFormat "scalar") (serialize-qp "compressionFormat" $compressionFormat "scalar") (serialize-qp "fileName" $fileName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check Export Status
#
# GET /events/export/{id}/status
# operationId: eventsExportByIdStatusGet
export def "events-export-status eventsExportByIdStatusGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/events/export/($id)/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Files
#
# GET /files
# operationId: filesGet
export def "files filesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<FileName: string, Size: int, DateAdded: string, ExpirationDate: string, ContentType: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload File
#
# POST /files
# operationId: filesPost
export def "files filesPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expiresAfterDays: int # After how many days should the file be deleted. (nullable, format: int32)
  BinaryContent: string # Content of the file sent as binary data (format: byte)
  --Name: string # Filename (format: string, e.g. attachment.txt)
  --ContentType: string # Type of file's content (e.g. image/jpeg) (format: string)
]: any -> record<FileName: string, Size: int, DateAdded: string, ExpirationDate: string, ContentType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiresAfterDays" $expiresAfterDays "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files" $qp)
  let body = {BinaryContent: $BinaryContent, Name: $Name, ContentType: $ContentType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete File
#
# DELETE /files/{name}
# operationId: filesByNameDelete
export def "files filesByNameDelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download File
#
# GET /files/{name}
# operationId: filesByNameGet
export def "files filesByNameGet" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($name)")
  let accept_val = "application/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load File Details
#
# GET /files/{name}/info
# operationId: filesByNameInfoGet
export def "files-info filesByNameInfoGet" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<FileName: string, Size: int, DateAdded: string, ExpirationDate: string, ContentType: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($name)/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Routes
#
# GET /inboundroute
# operationId: inboundrouteGet
export def "inboundroute inboundrouteGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<PublicId: string, Name: string, FilterType: string, Filter: string, ActionType: string, ActionParameter: string, SortOrder: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/inboundroute")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Route
#
# POST /inboundroute
# operationId: inboundroutePost
export def "inboundroute inboundroutePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Filter: string # Filter of the inbound data (format: string)
  Name: string # Name of this route (format: string)
  FilterType: string@FilterType-completer # default: EmailAddress
  ActionType: string@ActionType-completer # default: ForwardToEmail
  --EmailAddress: string # Email to forward the inbound to (format: string)
  --HttpAddress: string # Address to notify about the inbound (format: string)
]: any -> record<PublicId: string, Name: string, FilterType: string, Filter: string, ActionType: string, ActionParameter: string, SortOrder: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/inboundroute")
  let body = {Filter: $Filter, Name: $Name, FilterType: $FilterType, ActionType: $ActionType, EmailAddress: $EmailAddress, HttpAddress: $HttpAddress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Route
#
# DELETE /inboundroute/{id}
# operationId: inboundrouteByIdDelete
export def "inboundroute inboundrouteByIdDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/inboundroute/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Route
#
# GET /inboundroute/{id}
# operationId: inboundrouteByIdGet
export def "inboundroute inboundrouteByIdGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<PublicId: string, Name: string, FilterType: string, Filter: string, ActionType: string, ActionParameter: string, SortOrder: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/inboundroute/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Route
#
# PUT /inboundroute/{id}
# operationId: inboundrouteByIdPut
export def "inboundroute inboundrouteByIdPut" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Filter: string # Filter of the inbound data (format: string)
  Name: string # Name of this route (format: string)
  FilterType: string@FilterType-completer # default: EmailAddress
  ActionType: string@ActionType-completer # default: ForwardToEmail
  --EmailAddress: string # Email to forward the inbound to (format: string)
  --HttpAddress: string # Address to notify about the inbound (format: string)
]: any -> record<PublicId: string, Name: string, FilterType: string, Filter: string, ActionType: string, ActionParameter: string, SortOrder: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/inboundroute/($id)")
  let body = {Filter: $Filter, Name: $Name, FilterType: $FilterType, ActionType: $ActionType, EmailAddress: $EmailAddress, HttpAddress: $HttpAddress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Sorting
#
# PUT /inboundroute/order
# operationId: inboundrouteOrderPut
export def "inboundroute-order inboundrouteOrderPut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<PublicId: string, Name: string, FilterType: string, Filter: string, ActionType: string, ActionParameter: string, SortOrder: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/inboundroute/order")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Load Lists
#
# GET /lists
# operationId: listsGet
export def "lists listsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<ListName: string, PublicListID: string, DateAdded: string, AllowUnsubscribe: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add List
#
# POST /lists
# operationId: listsPost
export def "lists listsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ListName: string # Name of your list. (format: string, e.g. My List 1)
  --AllowUnsubscribe: string@bool-completer # True: Allow unsubscribing from this list. Otherwise, false (format: boolean, e.g. false)
  --Emails: list # Comma delimited list of existing contact emails that should be added to this list. Leave empty for all contacts (e.g. [john.doe@sample.com])
]: any -> record<ListName: string, PublicListID: string, DateAdded: string, AllowUnsubscribe: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lists")
  let body = {ListName: $ListName, AllowUnsubscribe: $AllowUnsubscribe, Emails: $Emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Load Contacts in List
#
# GET /lists/{listname}/contacts
# operationId: listsByListnameContactsGet
export def "lists-contacts listsByListnameContactsGet" [
  listname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<Email: string, Status: string, FirstName: string, LastName: string, CustomFields: record, Consent: record<ConsentIP: string, ConsentDate: string, ConsentTracking: string>, Source: string, SourceInfo: string, DateAdded: string, DateUpdated: string, StatusChangeDate: string, Activity: record<TotalSent: int, TotalOpened: int, TotalClicked: int, TotalFailed: int, LastSent: string, LastOpened: string, LastClicked: string, LastFailed: string, LastIP: string, ErrorCode: int, FriendlyErrorMessage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($listname)/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete List
#
# DELETE /lists/{name}
# operationId: listsByNameDelete
export def "lists listsByNameDelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load List
#
# GET /lists/{name}
# operationId: listsByNameGet
export def "lists listsByNameGet" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ListName: string, PublicListID: string, DateAdded: string, AllowUnsubscribe: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update List
#
# PUT /lists/{name}
# operationId: listsByNamePut
export def "lists listsByNamePut" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --NewListName: string # Name of your list if you want to change it. (format: string, e.g. My List 2)
  --AllowUnsubscribe: string@bool-completer # True: Allow unsubscribing from this list. Otherwise, false (format: boolean, e.g. false)
]: any -> record<ListName: string, PublicListID: string, DateAdded: string, AllowUnsubscribe: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($name)")
  let body = {NewListName: $NewListName, AllowUnsubscribe: $AllowUnsubscribe} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Contacts to List
#
# POST /lists/{name}/contacts
# operationId: listsByNameContactsPost
export def "lists-contacts listsByNameContactsPost" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Rule: string # SQL-like rule. Sending 'All' as a value loads all resources of the given type. Help for building a segment rule can be found here: https://help.elasticemail.com/en/articles/5162182-segment-rules (format: string)
  --Emails: list # Comma delimited list of contact emails (e.g. [john.doe@sample.com])
]: any -> record<ListName: string, PublicListID: string, DateAdded: string, AllowUnsubscribe: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($name)/contacts")
  let body = {Rule: $Rule, Emails: $Emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Contacts from List
#
# POST /lists/{name}/contacts/remove
# operationId: listsByNameContactsRemovePost
export def "lists-contacts-remove listsByNameContactsRemovePost" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Rule: string # SQL-like rule. Sending 'All' as a value loads all resources of the given type. Help for building a segment rule can be found here: https://help.elasticemail.com/en/articles/5162182-segment-rules (format: string)
  --Emails: list # Comma delimited list of contact emails (e.g. [john.doe@sample.com])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($name)/contacts/remove")
  let body = {Rule: $Rule, Emails: $Emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List ApiKeys
#
# GET /security/apikeys
# operationId: securityApikeysGet
export def "security-apikeys securityApikeysGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subaccount: string # Email of the subaccount of which ApiKeys should be loaded (format: string)
]: nothing -> table<AccessLevel: list<string>, Name: string, DateCreated: string, LastUse: string, Expires: string, RestrictAccessToIPRange: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subaccount" $subaccount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/security/apikeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add ApiKey
#
# POST /security/apikeys
# operationId: securityApikeysPost
export def "security-apikeys securityApikeysPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Name: string # Name of the ApiKey for ease of reference. (format: string)
  AccessLevel: list # Access level or permission to be assigned to this ApiKey.
  --Expires: string # Date this ApiKey expires. (nullable, format: date-time)
  --RestrictAccessToIPRange: list # Which IPs can use this ApiKey
  --Subaccount: string # Email of the subaccount for which this ApiKey should be created (format: string)
]: any -> record<Token: string, AccessLevel: list<string>, Name: string, DateCreated: string, LastUse: string, Expires: string, RestrictAccessToIPRange: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/security/apikeys")
  let body = {Name: $Name, AccessLevel: $AccessLevel, Expires: $Expires, RestrictAccessToIPRange: $RestrictAccessToIPRange, Subaccount: $Subaccount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete ApiKey
#
# DELETE /security/apikeys/{name}
# operationId: securityApikeysByNameDelete
export def "security-apikeys securityApikeysByNameDelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subaccount: string # Email of the subaccount of which ApiKey should be deleted (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subaccount" $subaccount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/security/apikeys/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load ApiKey
#
# GET /security/apikeys/{name}
# operationId: securityApikeysByNameGet
export def "security-apikeys securityApikeysByNameGet" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subaccount: string # Email of the subaccount of which ApiKey should be loaded (format: string)
]: nothing -> record<AccessLevel: list<string>, Name: string, DateCreated: string, LastUse: string, Expires: string, RestrictAccessToIPRange: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subaccount" $subaccount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/security/apikeys/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update ApiKey
#
# PUT /security/apikeys/{name}
# operationId: securityApikeysByNamePut
export def "security-apikeys securityApikeysByNamePut" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Name: string # Name of the ApiKey for ease of reference. (format: string)
  AccessLevel: list # Access level or permission to be assigned to this ApiKey.
  --Expires: string # Date this ApiKey expires. (nullable, format: date-time)
  --RestrictAccessToIPRange: list # Which IPs can use this ApiKey
  --Subaccount: string # Email of the subaccount for which this ApiKey should be created (format: string)
]: any -> record<AccessLevel: list<string>, Name: string, DateCreated: string, LastUse: string, Expires: string, RestrictAccessToIPRange: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/security/apikeys/($name)")
  let body = {Name: $Name, AccessLevel: $AccessLevel, Expires: $Expires, RestrictAccessToIPRange: $RestrictAccessToIPRange, Subaccount: $Subaccount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List SMTP Credentials
#
# GET /security/smtp
# operationId: securitySmtpGet
export def "security-smtp securitySmtpGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subaccount: string # Email of the subaccount of which credentials should be listed (format: string)
]: nothing -> table<AccessLevel: string, Name: string, DateCreated: string, LastUse: string, Expires: string, RestrictAccessToIPRange: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subaccount" $subaccount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/security/smtp" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add SMTP Credential
#
# POST /security/smtp
# operationId: securitySmtpPost
export def "security-smtp securitySmtpPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Name: string # Name of the Credential for ease of reference. It must be a valid email address. (format: string)
  --Expires: string # Date this SmtpCredential expires. (nullable, format: date-time)
  --RestrictAccessToIPRange: list # Which IPs can use this SmtpCredential
  --Subaccount: string # Email of the subaccount for which this SmtpCredential should be created (format: string)
]: any -> record<Token: string, AccessLevel: string, Name: string, DateCreated: string, LastUse: string, Expires: string, RestrictAccessToIPRange: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/security/smtp")
  let body = {Name: $Name, Expires: $Expires, RestrictAccessToIPRange: $RestrictAccessToIPRange, Subaccount: $Subaccount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete SMTP Credential
#
# DELETE /security/smtp/{name}
# operationId: securitySmtpByNameDelete
export def "security-smtp securitySmtpByNameDelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subaccount: string # Email of the subaccount of which credential should be deleted (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subaccount" $subaccount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/security/smtp/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load SMTP Credential
#
# GET /security/smtp/{name}
# operationId: securitySmtpByNameGet
export def "security-smtp securitySmtpByNameGet" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subaccount: string # Email of the subaccount of which credential should be loaded (format: string)
]: nothing -> record<AccessLevel: string, Name: string, DateCreated: string, LastUse: string, Expires: string, RestrictAccessToIPRange: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subaccount" $subaccount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/security/smtp/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update SMTP Credential
#
# PUT /security/smtp/{name}
# operationId: securitySmtpByNamePut
export def "security-smtp securitySmtpByNamePut" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Name: string # Name of the Credential for ease of reference. It must be a valid email address. (format: string)
  --Expires: string # Date this SmtpCredential expires. (nullable, format: date-time)
  --RestrictAccessToIPRange: list # Which IPs can use this SmtpCredential
  --Subaccount: string # Email of the subaccount for which this SmtpCredential should be created (format: string)
]: any -> record<AccessLevel: string, Name: string, DateCreated: string, LastUse: string, Expires: string, RestrictAccessToIPRange: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/security/smtp/($name)")
  let body = {Name: $Name, Expires: $Expires, RestrictAccessToIPRange: $RestrictAccessToIPRange, Subaccount: $Subaccount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Load Segments
#
# GET /segments
# operationId: segmentsGet
export def "segments segmentsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<Name: string, Rule: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/segments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Segment
#
# POST /segments
# operationId: segmentsPost
export def "segments segmentsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Name: string # Segment name (format: string)
  Rule: string # SQL-like rule to determine which Contacts belong to this Segment. Help for building a segment rule can be found here: https://help.elasticemail.com/en/articles/5162182-segment-rules (format: string)
]: any -> record<Name: string, Rule: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/segments")
  let body = {Name: $Name, Rule: $Rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Segment
#
# DELETE /segments/{name}
# operationId: segmentsByNameDelete
export def "segments segmentsByNameDelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/segments/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load Segment
#
# GET /segments/{name}
# operationId: segmentsByNameGet
export def "segments segmentsByNameGet" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Name: string, Rule: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/segments/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Segment
#
# PUT /segments/{name}
# operationId: segmentsByNamePut
export def "segments segmentsByNamePut" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Name: string # Segment name (format: string)
  Rule: string # SQL-like rule to determine which Contacts belong to this Segment. Help for building a segment rule can be found here: https://help.elasticemail.com/en/articles/5162182-segment-rules (format: string)
]: any -> record<Name: string, Rule: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/segments/($name)")
  let body = {Name: $Name, Rule: $Rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Load Statistics
#
# GET /statistics
# operationId: statisticsGet
export def "statistics statisticsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Starting date for search in YYYY-MM-DDThh:mm:ss format. (format: date-time)
  --qp-to: string # Ending date for search in YYYY-MM-DDThh:mm:ss format. (nullable, format: date-time)
]: nothing -> record<Recipients: int, EmailTotal: int, SmsTotal: int, Delivered: int, Bounced: int, InProgress: int, Opened: int, Clicked: int, Unsubscribed: int, Complaints: int, Inbound: int, ManualCancel: int, NotDelivered: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load Campaigns Stats
#
# GET /statistics/campaigns
# operationId: statisticsCampaignsGet
export def "statistics-campaigns statisticsCampaignsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<ChannelName: string, Recipients: int, EmailTotal: int, SmsTotal: int, Delivered: int, Bounced: int, InProgress: int, Opened: int, Clicked: int, Unsubscribed: int, Complaints: int, Inbound: int, ManualCancel: int, NotDelivered: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/campaigns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load Campaign Stats
#
# GET /statistics/campaigns/{name}
# operationId: statisticsCampaignsByNameGet
export def "statistics-campaigns statisticsCampaignsByNameGet" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ChannelName: string, Recipients: int, EmailTotal: int, SmsTotal: int, Delivered: int, Bounced: int, InProgress: int, Opened: int, Clicked: int, Unsubscribed: int, Complaints: int, Inbound: int, ManualCancel: int, NotDelivered: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/statistics/campaigns/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load Channels Stats
#
# GET /statistics/channels
# operationId: statisticsChannelsGet
export def "statistics-channels statisticsChannelsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<ChannelName: string, Recipients: int, EmailTotal: int, SmsTotal: int, Delivered: int, Bounced: int, InProgress: int, Opened: int, Clicked: int, Unsubscribed: int, Complaints: int, Inbound: int, ManualCancel: int, NotDelivered: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statistics/channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load Channel Stats
#
# GET /statistics/channels/{name}
# operationId: statisticsChannelsByNameGet
export def "statistics-channels statisticsChannelsByNameGet" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ChannelName: string, Recipients: int, EmailTotal: int, SmsTotal: int, Delivered: int, Bounced: int, InProgress: int, Opened: int, Clicked: int, Unsubscribed: int, Complaints: int, Inbound: int, ManualCancel: int, NotDelivered: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/statistics/channels/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load SubAccounts
#
# GET /subaccounts
# operationId: subaccountsGet
export def "subaccounts subaccountsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<PublicAccountID: string, Email: string, Settings: record<Email: record>, LastActivity: string, EmailCredits: int, TotalEmailsSent: int, Reputation: float, Status: string, ContactsCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subaccounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add SubAccount
#
# POST /subaccounts
# operationId: subaccountsPost
# --Settings shape: {Email?: record}
export def "subaccounts subaccountsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Email: string # Proper email address. (format: string, e.g. mail@example.com)
  Password: string # Current password. (format: string, e.g. ********)
  --SendActivation: string@bool-completer # True, if you want to send activation email to this Account to confirm the creation of a new SubAccount. Otherwise, false (SubAccount will immediately be Active). (format: boolean)
  --Settings: record # SubAccount settings (e.g. {Email: {PoolName: My Custom Pool, RequiresEmailCredits: true, ValidSenderDomainOnly: true, EmailSizeLimit: 10, DailySendLimit: 100000, MaxContacts: 0, EnablePrivateIPPurchase: true}}) — shape: {Email?: record}
]: any -> record<PublicAccountID: string, Email: string, Settings: record<Email: record<MonthlyRefillCredits: int, RequiresEmailCredits: bool, EmailSizeLimit: int, DailySendLimit: int, MaxContacts: int, EnablePrivateIPPurchase: bool, PoolName: string, ValidSenderDomainOnly: bool>>, LastActivity: string, EmailCredits: int, TotalEmailsSent: int, Reputation: float, Status: string, ContactsCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subaccounts")
  let body = {Email: $Email, Password: $Password, SendActivation: $SendActivation, Settings: $Settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete SubAccount
#
# DELETE /subaccounts/{email}
# operationId: subaccountsByEmailDelete
export def "subaccounts subaccountsByEmailDelete" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subaccounts/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load SubAccount
#
# GET /subaccounts/{email}
# operationId: subaccountsByEmailGet
export def "subaccounts subaccountsByEmailGet" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<PublicAccountID: string, Email: string, Settings: record<Email: record<MonthlyRefillCredits: int, RequiresEmailCredits: bool, EmailSizeLimit: int, DailySendLimit: int, MaxContacts: int, EnablePrivateIPPurchase: bool, PoolName: string, ValidSenderDomainOnly: bool>>, LastActivity: string, EmailCredits: int, TotalEmailsSent: int, Reputation: float, Status: string, ContactsCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subaccounts/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add, Subtract Email Credits
#
# PATCH /subaccounts/{email}/credits
# operationId: subaccountsByEmailCreditsPatch
export def "subaccounts-credits subaccountsByEmailCreditsPatch" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Credits: int # Positive or negative value; this will be added or subtracted from Subaccount's current email Credits pool. (format: int32)
  --Notes: string # Note to append to this credits change, for history. (format: string)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subaccounts/($email)/credits")
  let body = {Credits: $Credits, Notes: $Notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update SubAccount Email Settings
#
# PUT /subaccounts/{email}/settings/email
# operationId: subaccountsByEmailSettingsEmailPut
export def "subaccounts-settings-email subaccountsByEmailSettingsEmailPut" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --MonthlyRefillCredits: int # Amount of credits added to Account automatically (format: int32, e.g. 1000)
  --RequiresEmailCredits: string@bool-completer # True, if Account needs credits to send emails. Otherwise, false (format: boolean, e.g. true)
  --EmailSizeLimit: int # Maximum size of email including attachments in MB's (format: int32, e.g. 10)
  --DailySendLimit: int # Amount of emails Account can send daily (format: int32, e.g. 100000)
  --MaxContacts: int # Maximum number of contacts the Account can have. 0 means that parent account's limit is used. (format: int32)
  --EnablePrivateIPPurchase: string@bool-completer # Can the SubAccount purchase Private IP for themselves (format: boolean)
  --PoolName: string # Name of your custom IP Pool to be used in the sending process (format: string, e.g. My Custom Pool)
  --ValidSenderDomainOnly: string@bool-completer # nullable, format: boolean
]: any -> record<MonthlyRefillCredits: int, RequiresEmailCredits: bool, EmailSizeLimit: int, DailySendLimit: int, MaxContacts: int, EnablePrivateIPPurchase: bool, PoolName: string, ValidSenderDomainOnly: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subaccounts/($email)/settings/email")
  let body = {MonthlyRefillCredits: $MonthlyRefillCredits, RequiresEmailCredits: $RequiresEmailCredits, EmailSizeLimit: $EmailSizeLimit, DailySendLimit: $DailySendLimit, MaxContacts: $MaxContacts, EnablePrivateIPPurchase: $EnablePrivateIPPurchase, PoolName: $PoolName, ValidSenderDomainOnly: $ValidSenderDomainOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Suppressions
#
# GET /suppressions
# operationId: suppressionsGet
export def "suppressions suppressionsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<Email: string, FriendlyErrorMessage: string, ErrorCode: int, DateUpdated: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/suppressions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Suppression
#
# DELETE /suppressions/{email}
# operationId: suppressionsByEmailDelete
export def "suppressions suppressionsByEmailDelete" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/suppressions/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Suppression
#
# GET /suppressions/{email}
# operationId: suppressionsByEmailGet
export def "suppressions suppressionsByEmailGet" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Email: string, FriendlyErrorMessage: string, ErrorCode: int, DateUpdated: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/suppressions/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Bounce List
#
# GET /suppressions/bounces
# operationId: suppressionsBouncesGet
export def "suppressions-bounces suppressionsBouncesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Text fragment used for searching. (format: string, e.g. text)
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<Email: string, FriendlyErrorMessage: string, ErrorCode: int, DateUpdated: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/suppressions/bounces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Bounces
#
# POST /suppressions/bounces
# operationId: suppressionsBouncesPost
export def "suppressions-bounces suppressionsBouncesPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<Email: string, FriendlyErrorMessage: string, ErrorCode: int, DateUpdated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/suppressions/bounces")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Bounces Async
#
# POST /suppressions/bounces/import
# operationId: suppressionsBouncesImportPost
export def "suppressions-bounces-import suppressionsBouncesImportPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/suppressions/bounces/import")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Complaints List
#
# GET /suppressions/complaints
# operationId: suppressionsComplaintsGet
export def "suppressions-complaints suppressionsComplaintsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Text fragment used for searching. (format: string, e.g. text)
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<Email: string, FriendlyErrorMessage: string, ErrorCode: int, DateUpdated: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/suppressions/complaints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Complaints
#
# POST /suppressions/complaints
# operationId: suppressionsComplaintsPost
export def "suppressions-complaints suppressionsComplaintsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<Email: string, FriendlyErrorMessage: string, ErrorCode: int, DateUpdated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/suppressions/complaints")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Complaints Async
#
# POST /suppressions/complaints/import
# operationId: suppressionsComplaintsImportPost
export def "suppressions-complaints-import suppressionsComplaintsImportPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/suppressions/complaints/import")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Unsubscribes List
#
# GET /suppressions/unsubscribes
# operationId: suppressionsUnsubscribesGet
export def "suppressions-unsubscribes suppressionsUnsubscribesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Text fragment used for searching. (format: string, e.g. text)
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<Email: string, FriendlyErrorMessage: string, ErrorCode: int, DateUpdated: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/suppressions/unsubscribes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Unsubscribes
#
# POST /suppressions/unsubscribes
# operationId: suppressionsUnsubscribesPost
export def "suppressions-unsubscribes suppressionsUnsubscribesPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<Email: string, FriendlyErrorMessage: string, ErrorCode: int, DateUpdated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/suppressions/unsubscribes")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Unsubscribes Async
#
# POST /suppressions/unsubscribes/import
# operationId: suppressionsUnsubscribesImportPost
export def "suppressions-unsubscribes-import suppressionsUnsubscribesImportPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/suppressions/unsubscribes/import")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Load Templates
#
# GET /templates
# operationId: templatesGet
export def "templates templatesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scopeType: list # Return templates with specified scope only
  --templateTypes: list # Return templates with specified type only
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<TemplateType: string, Name: string, DateAdded: string, Subject: string, Body: list<record>, TemplateScope: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scopeType" $scopeType "multi") (serialize-qp "templateTypes" $templateTypes "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Template
#
# POST /templates
# operationId: templatesPost
# --Body item shape: {ContentType: "HTML"|"PlainText"|"AMP"|"CSS", Content?: string, Charset?: string}
export def "templates templatesPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Name: string # Template name (format: string)
  --Subject: string # Default subject of email. (format: string, e.g. Hello!)
  --Body: list # Email content of this template — item shape: {ContentType: "HTML"|"PlainText"|"AMP"|"CSS", Content?: string, Charset?: string}
  --TemplateScope: string@TemplateScope-completer # Visibility of a template (default: Personal)
]: any -> record<TemplateType: string, Name: string, DateAdded: string, Subject: string, Body: table<ContentType: string, Content: string, Charset: string>, TemplateScope: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates")
  let body = {Name: $Name, Subject: $Subject, Body: $Body, TemplateScope: $TemplateScope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Template
#
# DELETE /templates/{name}
# operationId: templatesByNameDelete
export def "templates templatesByNameDelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load Template
#
# GET /templates/{name}
# operationId: templatesByNameGet
export def "templates templatesByNameGet" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<TemplateType: string, Name: string, DateAdded: string, Subject: string, Body: table<ContentType: string, Content: string, Charset: string>, TemplateScope: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Template
#
# PUT /templates/{name}
# operationId: templatesByNamePut
# --Body item shape: {ContentType: "HTML"|"PlainText"|"AMP"|"CSS", Content?: string, Charset?: string}
export def "templates templatesByNamePut" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Name: string # Template name (format: string)
  --Subject: string # Default subject of email. (format: string, e.g. Hello!)
  --Body: list # Email content of this template — item shape: {ContentType: "HTML"|"PlainText"|"AMP"|"CSS", Content?: string, Charset?: string}
  --TemplateScope: string@TemplateScope-completer # Visibility of a template (default: Personal)
]: any -> record<TemplateType: string, Name: string, DateAdded: string, Subject: string, Body: table<ContentType: string, Content: string, Charset: string>, TemplateScope: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($name)")
  let body = {Name: $Name, Subject: $Subject, Body: $Body, TemplateScope: $TemplateScope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Emails Verification Results
#
# GET /verifications
# operationId: verificationsGet
export def "verifications verificationsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<Account: string, Domain: string, Email: string, SuggestedSpelling: string, Disposable: bool, Role: bool, Reason: string, DateAdded: string, Result: string, PredictedScore: float, PredictedStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/verifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Email Verification Result
#
# DELETE /verifications/{email}
# operationId: verificationsByEmailDelete
export def "verifications verificationsByEmailDelete" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/verifications/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Email Verification Result
#
# GET /verifications/{email}
# operationId: verificationsByEmailGet
export def "verifications verificationsByEmailGet" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Account: string, Domain: string, Email: string, SuggestedSpelling: string, Disposable: bool, Role: bool, Reason: string, DateAdded: string, Result: string, PredictedScore: float, PredictedStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/verifications/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify Email
#
# POST /verifications/{email}
# operationId: verificationsByEmailPost
export def "verifications verificationsByEmailPost" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Account: string, Domain: string, Email: string, SuggestedSpelling: string, Disposable: bool, Role: bool, Reason: string, DateAdded: string, Result: string, PredictedScore: float, PredictedStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/verifications/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload File with Emails
#
# POST /verifications/files
# operationId: verificationsFilesPost
export def "verifications-files verificationsFilesPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file: string # format: binary
]: any -> record<VerificationID: string, Filename: string, VerificationStatus: string, FileUploadResult: record<EmailsCount: int, DuplicatedEmailsCount: int>, DateAdded: string, Source: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verifications/files")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete File Verification Result
#
# DELETE /verifications/files/{id}
# operationId: verificationsFilesByIdDelete
export def "verifications-files verificationsFilesByIdDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/verifications/files/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Detailed File Verification Result
#
# GET /verifications/files/{id}/result
# operationId: verificationsFilesByIdResultGet
export def "verifications-files-result verificationsFilesByIdResultGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of returned email verification results (format: int32)
  --offset: int # How many result items should be returned ahead (format: int32)
]: nothing -> record<VerificationResult: table<Account: string, Domain: string, Email: string, SuggestedSpelling: string, Disposable: bool, Role: bool, Reason: string, DateAdded: string, Result: string, PredictedScore: float, PredictedStatus: string>, VerificationID: string, Filename: string, VerificationStatus: string, FileUploadResult: record<EmailsCount: int, DuplicatedEmailsCount: int>, DateAdded: string, Source: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/verifications/files/($id)/result" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download File Verification Result
#
# GET /verifications/files/{id}/result/download
# operationId: verificationsFilesByIdResultDownloadGet
export def "verifications-files-result-download verificationsFilesByIdResultDownloadGet" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/verifications/files/($id)/result/download")
  let accept_val = "application/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start verification
#
# POST /verifications/files/{id}/verification
# operationId: verificationsFilesByIdVerificationPost
export def "verifications-files-verification verificationsFilesByIdVerificationPost" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/verifications/files/($id)/verification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Files Verification Results
#
# GET /verifications/files/result
# operationId: verificationsFilesResultGet
export def "verifications-files-result verificationsFilesResultGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<VerificationID: string, Filename: string, VerificationStatus: string, FileUploadResult: record<EmailsCount: int, DuplicatedEmailsCount: int>, DateAdded: string, Source: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verifications/files/result")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load Webhooks
#
# GET /webhook
# operationId: webhookGet
export def "webhook webhookGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of returned items. (format: int32, e.g. 100)
  --offset: int # How many items should be returned ahead. (format: int32, e.g. 20)
]: nothing -> table<WebhookID: string, Name: string, DateCreated: string, DateUpdated: string, URL: string, NotifyOncePerEmail: bool, NotificationForSent: bool, NotificationForOpened: bool, NotificationForClicked: bool, NotificationForUnsubscribed: bool, NotificationForAbuseReport: bool, NotificationForError: bool, IsEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhook" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Webhook
#
# POST /webhook
# operationId: webhookPost
export def "webhook webhookPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Name: string # Filename (format: string, e.g. attachment.txt)
  URL: string # URL of notification. (format: string, e.g. http://address.for.notification.com)
  --NotifyOncePerEmail: string@bool-completer # format: boolean
  --NotificationForSent: string@bool-completer # format: boolean
  --NotificationForOpened: string@bool-completer # format: boolean
  --NotificationForClicked: string@bool-completer # format: boolean
  --NotificationForUnsubscribed: string@bool-completer # format: boolean
  --NotificationForAbuseReport: string@bool-completer # format: boolean
  --NotificationForError: string@bool-completer # format: boolean
]: any -> record<WebhookID: string, Name: string, DateCreated: string, DateUpdated: string, URL: string, NotifyOncePerEmail: bool, NotificationForSent: bool, NotificationForOpened: bool, NotificationForClicked: bool, NotificationForUnsubscribed: bool, NotificationForAbuseReport: bool, NotificationForError: bool, IsEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhook")
  let body = {Name: $Name, URL: $URL, NotifyOncePerEmail: $NotifyOncePerEmail, NotificationForSent: $NotificationForSent, NotificationForOpened: $NotificationForOpened, NotificationForClicked: $NotificationForClicked, NotificationForUnsubscribed: $NotificationForUnsubscribed, NotificationForAbuseReport: $NotificationForAbuseReport, NotificationForError: $NotificationForError} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Webhook
#
# DELETE /webhook/{publicid}
# operationId: webhookByPublicidDelete
export def "webhook webhookByPublicidDelete" [
  publicid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook/($publicid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load Webhook
#
# GET /webhook/{publicid}
# operationId: webhookByPublicidGet
export def "webhook webhookByPublicidGet" [
  publicid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<WebhookID: string, Name: string, DateCreated: string, DateUpdated: string, URL: string, NotifyOncePerEmail: bool, NotificationForSent: bool, NotificationForOpened: bool, NotificationForClicked: bool, NotificationForUnsubscribed: bool, NotificationForAbuseReport: bool, NotificationForError: bool, IsEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook/($publicid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Webhook
#
# PUT /webhook/{publicid}
# operationId: webhookByPublicidPut
export def "webhook webhookByPublicidPut" [
  publicid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Name: string # Filename (format: string, e.g. attachment.txt)
  --URL: string # URL of notification. (format: string, e.g. http://address.for.notification.com)
  --NotifyOncePerEmail: string@bool-completer # nullable, format: boolean
  --NotificationForSent: string@bool-completer # nullable, format: boolean
  --NotificationForOpened: string@bool-completer # nullable, format: boolean
  --NotificationForClicked: string@bool-completer # nullable, format: boolean
  --NotificationForUnsubscribed: string@bool-completer # nullable, format: boolean
  --NotificationForAbuseReport: string@bool-completer # nullable, format: boolean
  --NotificationForError: string@bool-completer # nullable, format: boolean
  --IsEnabled: string@bool-completer # nullable, format: boolean
]: any -> record<WebhookID: string, Name: string, DateCreated: string, DateUpdated: string, URL: string, NotifyOncePerEmail: bool, NotificationForSent: bool, NotificationForOpened: bool, NotificationForClicked: bool, NotificationForUnsubscribed: bool, NotificationForAbuseReport: bool, NotificationForError: bool, IsEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-elasticemail-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook/($publicid)")
  let body = {Name: $Name, URL: $URL, NotifyOncePerEmail: $NotifyOncePerEmail, NotificationForSent: $NotificationForSent, NotificationForOpened: $NotificationForOpened, NotificationForClicked: $NotificationForClicked, NotificationForUnsubscribed: $NotificationForUnsubscribed, NotificationForAbuseReport: $NotificationForAbuseReport, NotificationForError: $NotificationForError, IsEnabled: $IsEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
