# Auto-generated client for RingCentral API v1.0.58-20240529-47eda8bd
# Source: https://netstorage.ringcentral.com/dpw/api-reference/specs/rc-platform.yml
# Auth: --token flag or $env.RINGCENTRAL_API_TOKEN

const BASE_URL = "https://platform.ringcentral.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RINGCENTRAL_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://platform.ringcentral.com" "https://media.ringcentral.com" "https://platform.devtest.ringcentral.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def recordingMediaType-completer [] { ["Audio" "Video"] }
def registrationStatus-completer [] { ["Closed" "Open"] }
def status-completer [] { ["Active" "Finished" "Scheduled"] }
def role-completer [] { ["Attendee" "CoHost" "Host" "Panelist"] }
def type-completer [] { ["Room" "User"] }
def contentDisposition-completer [] { ["Attachment" "Inline"] }
def accept-completer [] { ["audio/mpeg" "audio/wav"] }
def accept-completer-1 [] { ["application/pdf" "audio/*" "image/*" "video/*"] }
def type-completer-1 [] { ["Instant" "PMI" "Scheduled"] }
def type-completer-2 [] { ["All" "Deleted" "My" "Shared"] }
def client-assertion-type-completer [] { ["urn:ietf:params:oauth:client-assertion-type:jwt-bearer"] }
def grant-type-completer [] { ["authorization_code" "client_credentials" "device_certificate" "guest" "ivr_pin" "otp" "partner_jwt" "password" "personal_jwt" "refresh_token" "urn:ietf:params:oauth:grant-type:device_code" "urn:ietf:params:oauth:grant-type:jwt-bearer"] }
def response-type-completer [] { ["code"] }
def display-completer [] { ["mobile" "page" "popup" "touch"] }
def code-challenge-method-completer [] { ["S256" "plain"] }
def type-completer-3 [] { ["OtherPhone"] }
def type-completer-4 [] { ["FaxOnly" "VoiceFax" "VoiceOnly"] }
def usageType-completer [] { ["CompanyNumber" "DirectNumber" "MainCompanyNumber" "PhoneLine"] }
def category-completer [] { ["User"] }
def type-completer-5 [] { ["AutomaticRecording" "StartRecording" "StopRecording"] }
def mode-completer [] { ["Listen"] }
def mediaSDP-completer [] { ["sendOnly" "sendRecv"] }
def proto-completer [] { ["Auto" "BroadWorks" "DisconnectHolder" "RC"] }
def view-completer [] { ["Detailed" "Simple"] }
def recordingType-completer [] { ["All" "Automatic" "OnDemand"] }
def type-completer-6 [] { ["CallHandling" "UserSettings"] }
def direction-completer [] { ["Inbound" "Outbound"] }
def status-completer-1 [] { ["all" "optin" "optout"] }
def accept-completer-2 [] { ["application/json" "text/csv"] }
def type-completer-7 [] { ["AfterHours" "BusinessHours" "Custom"] }
def callHandlingAction-completer [] { ["Bypass" "Disconnect" "Operator"] }
def status-completer-2 [] { ["Disabled" "Enabled" "NotActivated"] }
def subType-completer [] { ["Emergency"] }
def alertTimer-completer [] { ["10" "120" "15" "180" "20" "240" "30" "300" "360" "420" "45" "480" "5" "540" "60" "600"] }
def orderBy-completer [] { ["+address" "+addressStatus" "+name" "+siteName" "+usageStatus" "-address" "-addressStatus" "-name" "-siteName" "-usageStatus"] }
def addressStatus-completer [] { ["Invalid" "Valid"] }
def usageStatus-completer [] { ["Active" "Inactive"] }
def visibility-completer [] { ["Public"] }
def type-completer-8 [] { ["Announcement" "Department" "External" "IvrMenu" "Limited" "PagingOnly" "ParkLocation" "SharedLinesGroup" "User" "Voicemail"] }
def typeGroup-completer [] { ["NonUser" "User"] }
def extensionType-completer [] { ["Announcement" "ApplicationExtension" "Bot" "DelegatedLinesGroup" "Department" "External" "GroupCallPickup" "IvrMenu" "Limited" "PagingOnly" "ParkLocation" "Room" "SharedLinesGroup" "Site" "User" "Voicemail"] }
def type-completer-9 [] { ["AutomaticRecording" "Company" "StartRecording" "StopRecording" "TemplateGreeting"] }
def scope-completer [] { ["Account" "AllExtensions" "Federation" "Group" "NonUserExtensions" "RoleBased" "Self" "UserExtensions"] }
def setupWizardState-completer [] { ["Completed" "Incomplete" "NotStarted"] }
def status-completer-3 [] { ["Disabled" "Enabled" "Frozen" "NotActivated" "Unassigned"] }
def type-completer-10 [] { ["Announcement" "Department" "DigitalUser" "FlexibleUser" "Limited" "PagingOnly" "ParkLocation" "SharedLinesGroup" "User" "VirtualUser" "Voicemail"] }
def status-completer-4 [] { ["Disabled" "Enabled" "Frozen" "NotActivated"] }
def type-completer-11 [] { ["Announcement" "ApplicationExtension" "DelegatedLinesGroup" "Department" "DigitalUser" "FaxUser" "FlexibleUser" "GroupCallPickup" "IvrMenu" "PagingOnly" "ParkLocation" "SharedLinesGroup" "User" "VirtualUser" "Voicemail"] }
def subType-completer-1 [] { ["DigitalSignageOnlyRooms" "Emergency" "Unknown" "VideoPro" "VideoProPlus"] }
def linePooling-completer [] { ["Guest" "Host" "None"] }
def type-completer-12 [] { ["BLA" "HardPhone" "MobileDevice" "OtherPhone" "Paging" "Room" "SoftPhone" "WebPhone" "WebRTC"] }
def extensionType-completer-1 [] { ["Announcement" "ApplicationExtension" "Bot" "DelegatedLinesGroup" "Department" "DigitalUser" "FaxUser" "IvrMenu" "Limited" "PagingOnly" "ParkLocation" "Room" "SharedLinesGroup" "User" "VirtualUser" "Voicemail"] }
def accept-completer-3 [] { ["image/gif" "image/jpeg" "image/png"] }
def type-completer-13 [] { ["Custom"] }
def callHandlingAction-completer-1 [] { ["AgentQueue" "ForwardCalls" "PlayAnnouncementOnly" "SharedLines" "TakeMessagesOnly" "TransferToExtension" "UnconditionalForwarding"] }
def screening-completer [] { ["Always" "NoCallerId" "Off" "UnknownCallerId"] }
def orderBy-completer-1 [] { ["+address" "+addressStatus" "+name" "+siteName" "+usageStatus" "+visibility" "-address" "-addressStatus" "-name" "-siteName" "-usageStatus" "-visibility"] }
def type-completer-14 [] { ["Home" "Mobile" "Other" "PhoneLine" "Work"] }
def type-completer-15 [] { ["BusinessMobilePhone" "ExternalCarrier" "Home" "Mobile" "Other" "Outage" "PhoneLine" "Work"] }
def meetingType-completer [] { ["Instant" "Recurring" "Scheduled" "ScheduledRecurring"] }
def autoRecordType-completer [] { ["cloud" "local" "none"] }
def userStatus-completer [] { ["Available" "Busy" "Offline"] }
def dndStatus-completer [] { ["DoNotAcceptAnyCalls" "DoNotAcceptDepartmentCalls" "TakeAllCalls" "TakeDepartmentCallsOnly" "Unknown"] }
def callerIdVisibility-completer [] { ["All" "None" "PermittedUsers"] }
def faxResolution-completer [] { ["High" "Low"] }
def type-completer-16 [] { ["All" "Fax" "Pager" "SMS" "Text" "VoiceMail"] }
def accept-completer-4 [] { ["application/json" "application/vnd.ringcentral.multipart+json" "multipart/mixed"] }
def readStatus-completer [] { ["Read" "Unread"] }
def availability-completer [] { ["Alive" "Deleted" "Purged"] }
def type-completer-17 [] { ["Announcement" "ConnectingAudio" "ConnectingMessage" "HoldMusic" "Introductory" "TemplateGreeting" "Unavailable" "Voicemail"] }
def mode-completer-1 [] { ["All" "Specific"] }
def noCallerId-completer [] { ["Allow" "BlockCallsAndFaxes" "BlockFaxes"] }
def payPhones-completer [] { ["Allow" "Block"] }
def status-completer-5 [] { ["Allowed" "Blocked"] }
def syncType-completer [] { ["FSync" "ISync"] }
def status-completer-6 [] { ["Normal" "Pending" "PortedIn" "Temporary"] }
def orderBy-completer-2 [] { ["City" "Npa"] }
def type-completer-18 [] { ["Announcement" "Company" "ConnectingAudio" "ConnectingMessage" "HoldMusic" "Introductory" "Unavailable" "Voicemail"] }
def usageType-completer-1 [] { ["AnnouncementExtensionAnsweringRule" "CompanyAfterHoursAnsweringRule" "CompanyAnsweringRule" "DepartmentExtensionAnsweringRule" "ExtensionAnsweringRule" "SharedLinesGroupAnsweringRule" "UserExtensionAnsweringRule" "VoicemailExtensionAnsweringRule"] }
def softPhoneLineReassignment-completer [] { ["Initialize" "None" "Reassign"] }
def summaryType-completer [] { ["AbstractiveAll" "AbstractiveLong" "AbstractiveShort" "All" "Extractive"] }
def encoding-completer [] { ["Aac" "Avi" "Mp4" "Mpeg" "Ogg" "Wav" "Webm" "Webp"] }
def orderBy-completer-3 [] { ["+creationTime" "-creationTime" "creationTime"] }
def accept-completer-5 [] { ["application/json" "application/scim+json"] }
def completenessCondition-completer [] { ["AllAssignees" "Percentage" "Simple"] }
def color-completer [] { ["Black" "Blue" "Green" "Magenta" "Orange" "Purple" "Red" "Yellow"] }
def status-completer-7 [] { ["Complete" "Incomplete"] }
def accept-completer-6 [] { ["application/json" "multipart/mixed"] }
def assignmentStatus-completer [] { ["Assigned" "Unassigned"] }
def assigneeStatus-completer [] { ["Completed" "Pending"] }
def type-completer-19 [] { ["AdaptiveCard"] }
def lang-completer [] { ["en" "es" "fr"] }
def status-completer-8 [] { ["Active" "Draft"] }
def status-completer-9 [] { ["Accepted" "Completed" "Expired" "Failed" "InProgress"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "webinar-notifications-subscriptions rcwN11sListSubscriptions" } } | get name | first)
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

# List Webinar Subscriptions
#
# GET /webinar/notifications/v1/subscriptions
# operationId: rcwN11sListSubscriptions
export def "webinar-notifications-subscriptions rcwN11sListSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, records: table<uri: string, id: string, eventFilters: list, disabledFilters: list, expirationTime: string, expiresIn: int, status: string, creationTime: string, deliveryMode: any, blacklistedData: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webinar/notifications/v1/subscriptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Webinar Subscription
#
# POST /webinar/notifications/v1/subscriptions
# operationId: rcwN11sCreateSubscription
# --deliveryMode shape: {transportType: "WebHook", address: string, verificationToken?: string}
export def "webinar-notifications-subscriptions rcwN11sCreateSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  eventFilters: list # The list of event filters corresponding to events the user is subscribed to
  --expiresIn: int # Subscription lifetime in seconds. The maximum subscription lifetime depends upon the specified `transportType`:  | Transport type      | Maximum permitted lifetime     | | ------------------- | ------------------------------ | | `WebHook`           | 315360000 seconds (10 years)   | | `RC/APNS`, `RC/GSM` | 7776000 seconds (90 days)      | | `PubNub`            | 900 seconds (15 minutes)       | | `WebSocket`         | n/a (the parameter is ignored) |  (format: int32, e.g. 1200)
  deliveryMode: record # shape: {transportType: "WebHook", address: string, verificationToken?: string}
]: any -> record<uri: string, id: string, eventFilters: list<string>, disabledFilters: table<filter: string, reason: string, message: string>, expirationTime: string, expiresIn: int, status: string, creationTime: string, deliveryMode: any, blacklistedData: record<blacklistedAt: string, reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webinar/notifications/v1/subscriptions")
  let body = {eventFilters: $eventFilters, expiresIn: $expiresIn, deliveryMode: $deliveryMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Webinar Subscription
#
# GET /webinar/notifications/v1/subscriptions/{subscriptionId}
# operationId: rcwN11sGetSubscription
export def "webinar-notifications-subscriptions rcwN11sGetSubscription" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, eventFilters: list<string>, disabledFilters: table<filter: string, reason: string, message: string>, expirationTime: string, expiresIn: int, status: string, creationTime: string, deliveryMode: any, blacklistedData: record<blacklistedAt: string, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/notifications/v1/subscriptions/($subscriptionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Webinar Subscription
#
# PUT /webinar/notifications/v1/subscriptions/{subscriptionId}
# operationId: rcwN11sUpdateSubscription
export def "webinar-notifications-subscriptions rcwN11sUpdateSubscription" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  eventFilters: list # The list of event filters corresponding to events the user is subscribed to
  --expiresIn: int # Subscription lifetime in seconds. The maximum subscription lifetime depends upon the specified `transportType`:  | Transport type      | Maximum permitted lifetime     | | ------------------- | ------------------------------ | | `WebHook`           | 315360000 seconds (10 years)   | | `RC/APNS`, `RC/GSM` | 7776000 seconds (90 days)      | | `PubNub`            | 900 seconds (15 minutes)       | | `WebSocket`         | n/a (the parameter is ignored) |  (format: int32, e.g. 1200)
]: any -> record<uri: string, id: string, eventFilters: list<string>, disabledFilters: table<filter: string, reason: string, message: string>, expirationTime: string, expiresIn: int, status: string, creationTime: string, deliveryMode: any, blacklistedData: record<blacklistedAt: string, reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/notifications/v1/subscriptions/($subscriptionId)")
  let body = {eventFilters: $eventFilters, expiresIn: $expiresIn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel Webinar Subscription
#
# DELETE /webinar/notifications/v1/subscriptions/{subscriptionId}
# operationId: rcwN11sDeleteSubscription
export def "webinar-notifications-subscriptions rcwN11sDeleteSubscription" [
  subscriptionId: string
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
  let full_url = (build-url $base $"/webinar/notifications/v1/subscriptions/($subscriptionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Renew Webinar Subscription
#
# POST /webinar/notifications/v1/subscriptions/{subscriptionId}/renew
# operationId: rcwN11sRenewSubscription
export def "webinar-notifications-subscriptions-renew rcwN11sRenewSubscription" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, eventFilters: list<string>, disabledFilters: table<filter: string, reason: string, message: string>, expirationTime: string, expiresIn: int, status: string, creationTime: string, deliveryMode: any, blacklistedData: record<blacklistedAt: string, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/notifications/v1/subscriptions/($subscriptionId)/renew")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Historical Webinar
#
# GET /webinar/history/v1/webinars/{webinarId}
# operationId: rcwHistoryGetWebinar
export def "webinar-history-webinars rcwHistoryGetWebinar" [
  webinarId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<title: string, description: string, settings: record<recordingEnabled: bool, autoRecord: bool, recordingSharingEnabled: bool, recordingDownloadEnabled: bool, recordingDeletionEnabled: bool, pastSessionDeletionEnabled: bool, panelistWaitingRoom: bool, panelistVideoEnabled: bool, panelistScreenSharingEnabled: bool, panelistMuteControlEnabled: bool, panelistAuthentication: string, attendeeAuthentication: string, artifactsAccessAuthentication: string, pstnEnabled: bool, password: string, qnaEnabled: bool, qnaAnonymousEnabled: bool, moderatedQnaEnabled: bool, pollsEnabled: bool, pollsAnonymousEnabled: bool, registrationEnabled: bool, postWebinarRedirectUri: string, externalLivestreamEnabled: bool>, host: record<firstName: string, lastName: string, linkedUser: record<userId: string, accountId: string, domain: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/history/v1/webinars/($webinarId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Historical Webinar Session
#
# GET /webinar/history/v1/webinars/{webinarId}/sessions/{sessionId}
# operationId: rcwHistoryGetSession
export def "webinar-history-webinars-sessions rcwHistoryGetSession" [
  webinarId: string
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<videoBridgeId: string, recording: record<status: string, failureReason: record<errorCode: string, message: string>, duration: int, shared: bool, sharedUriExpirationTime: string, recordingSharedUri: string>, livestreams: table<livestreamId: string, serviceProvider: string, livestreamStatus: string, previousLivestreamStatus: string, livestreamStartTime: string, error: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/history/v1/webinars/($webinarId)/sessions/($sessionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Session Participants
#
# GET /webinar/history/v1/webinars/{webinarId}/sessions/{sessionId}/participants
# operationId: rcwHistoryListParticipants
export def "webinar-history-webinars-sessions-participants rcwHistoryListParticipants" [
  webinarId: string
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: list # The role of the invitee/participant.
  --originalRole: list # The original role of the invitee/participant.
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --pageToken: string # The token indicating the particular page of the result set to be retrieved. If omitted the first page will be returned.
]: nothing -> record<records: table<joinTime: string, leaveTime: string, wasEjected: bool, inviteeId: string, registrantId: string, uniqueUserHash: string>, paging: record<perPage: int, pageToken: string, nextPageToken: string, previousPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "multi") (serialize-qp "originalRole" $originalRole "multi") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webinar/history/v1/webinars/($webinarId)/sessions/($sessionId)/participants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Participant Information
#
# GET /webinar/history/v1/webinars/{webinarId}/sessions/{sessionId}/participants/self
# operationId: rcwHistoryGetParticipantInfo
export def "webinar-history-webinars-sessions-participants-self rcwHistoryGetParticipantInfo" [
  webinarId: string
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, firstName: string, lastName: string, role: string, originalRole: string, linkedUser: record<userId: string, accountId: string, domain: string>, avatarToken: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/history/v1/webinars/($webinarId)/sessions/($sessionId)/participants/self")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Session Invitees
#
# GET /webinar/history/v1/webinars/{webinarId}/sessions/{sessionId}/invitees
# operationId: rcwHistoryListInvitees
export def "webinar-history-webinars-sessions-invitees rcwHistoryListInvitees" [
  webinarId: string
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: list # The role of the invitee/participant.
  --originalRole: list # The original role of the invitee/participant.
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --pageToken: string # The token indicating the particular page of the result set to be retrieved. If omitted the first page will be returned.
]: nothing -> record<records: table<sendInvite: bool, joined: bool>, paging: record<perPage: int, pageToken: string, nextPageToken: string, previousPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "multi") (serialize-qp "originalRole" $originalRole "multi") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webinar/history/v1/webinars/($webinarId)/sessions/($sessionId)/invitees" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Session Invitee
#
# GET /webinar/history/v1/webinars/{webinarId}/sessions/{sessionId}/invitees/{inviteeId}
# operationId: rcwHistoryGetInvitee
export def "webinar-history-webinars-sessions-invitees rcwHistoryGetInvitee" [
  webinarId: string
  sessionId: string
  inviteeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sendInvite: bool, joined: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/history/v1/webinars/($webinarId)/sessions/($sessionId)/invitees/($inviteeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Webinar Recordings (Admin)
#
# GET /webinar/history/v1/company/recordings
# operationId: rcwHistoryAdminListRecordings
export def "webinar-history-company-recordings rcwHistoryAdminListRecordings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nameFragment: string # Filter to return only webinar recordings containing particular substring within their names (e.g. All-hands)
  --creationTimeFrom: string # The beginning of the time window by 'creationTime' . (format: date-time)
  --creationTimeTo: string # The end of the time window by 'creationTime' . (format: date-time)
  --status: list # The status of the recording.
  --hostUserId: list # Identifier of the user who hosts a webinar (if omitted, webinars hosted by all company users will be returned) (e.g. [77777777])
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --pageToken: string # The token indicating the particular page of the result set to be retrieved. If omitted the first page will be returned.
]: nothing -> record<records: table<session: record>, paging: record<perPage: int, pageToken: string, nextPageToken: string, previousPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nameFragment" $nameFragment "scalar") (serialize-qp "creationTimeFrom" $creationTimeFrom "scalar") (serialize-qp "creationTimeTo" $creationTimeTo "scalar") (serialize-qp "status" $status "multi") (serialize-qp "hostUserId" $hostUserId "csv") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webinar/history/v1/company/recordings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Webinar Recording (Admin)
#
# GET /webinar/history/v1/company/recordings/{recordingId}
# operationId: rcwHistoryAdminGetRecording
export def "webinar-history-company-recordings rcwHistoryAdminGetRecording" [
  recordingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<session: record<id: string, startTime: string, endTime: string, duration: int, title: string, description: string, webinar: record<id: string, title: string, description: string, host: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/history/v1/company/recordings/($recordingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Historical Webinar Sessions across Multiple Webinars / Hosts
#
# GET /webinar/history/v1/company/sessions
# operationId: rcwHistoryListAllCompanySessions
export def "webinar-history-company-sessions rcwHistoryListAllCompanySessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hostUserId: list # Identifier of the user who hosts a webinar (if omitted, webinars hosted by all company users will be returned) (e.g. [77777777])
  --status: list # Filter to return only webinar sessions in certain status. Multiple values are supported. (e.g. [Active, Finished])
  --endTimeFrom: string # The beginning of the time window by 'endTime' . (format: date-time)
  --endTimeTo: string # The end of the time window by 'endTime' . (format: date-time)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --pageToken: string # The token indicating the particular page of the result set to be retrieved. If omitted the first page will be returned.
]: nothing -> record<records: table<webinar: record, videoBridgeId: string, recording: record, livestreams: list>, paging: record<perPage: int, pageToken: string, nextPageToken: string, previousPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hostUserId" $hostUserId "csv") (serialize-qp "status" $status "multi") (serialize-qp "endTimeFrom" $endTimeFrom "scalar") (serialize-qp "endTimeTo" $endTimeTo "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webinar/history/v1/company/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Webinar Recordings
#
# GET /webinar/history/v1/recordings
# operationId: rcwHistoryListRecordings
export def "webinar-history-recordings rcwHistoryListRecordings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --creationTimeFrom: string # The beginning of the time window by 'creationTime' . (format: date-time)
  --creationTimeTo: string # The end of the time window by 'creationTime' . (format: date-time)
  --status: list # The status of the recording.
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --pageToken: string # The token indicating the particular page of the result set to be retrieved. If omitted the first page will be returned.
]: nothing -> record<records: table<session: record>, paging: record<perPage: int, pageToken: string, nextPageToken: string, previousPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "creationTimeFrom" $creationTimeFrom "scalar") (serialize-qp "creationTimeTo" $creationTimeTo "scalar") (serialize-qp "status" $status "multi") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webinar/history/v1/recordings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Webinar Recording
#
# GET /webinar/history/v1/recordings/{recordingId}
# operationId: rcwHistoryGetRecording
export def "webinar-history-recordings rcwHistoryGetRecording" [
  recordingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<session: record<id: string, startTime: string, endTime: string, duration: int, title: string, description: string, webinar: record<id: string, title: string, description: string, host: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/history/v1/recordings/($recordingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Webinar Recording Download Resource
#
# GET /webinar/history/v1/recordings/{recordingId}/download
# operationId: rcwHistoryGetRecordingDownload
export def "webinar-history-recordings-download rcwHistoryGetRecordingDownload" [
  recordingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recordingMediaType: string@recordingMediaType-completer # Download file media type. - Type 'Video' refers to a multiplexed audio and video file. - Type 'Audio' refers to an audio only file. - Unless specified by this query parameter, a video file is returned by default when a recording is downloaded.  (default: Video, e.g. Video)
]: nothing -> record<downloadUri: string, downloadContentType: string, downloadSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recordingMediaType" $recordingMediaType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webinar/history/v1/recordings/($recordingId)/download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Historical Webinar Sessions across Multiple Webinars
#
# GET /webinar/history/v1/sessions
# operationId: rcwHistoryListAllSessions
export def "webinar-history-sessions rcwHistoryListAllSessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nameFragment: string # Filter to return only webinar sessions containing particular substring within their names (e.g. All-hands)
  --status: list # Filter to return only webinar sessions in certain status. Multiple values are supported. (e.g. [Active, Finished])
  --endTimeFrom: string # The beginning of the time window by 'endTime' . (format: date-time)
  --endTimeTo: string # The end of the time window by 'endTime' . (format: date-time)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --pageToken: string # The token indicating the particular page of the result set to be retrieved. If omitted the first page will be returned.
]: nothing -> record<records: table<webinar: record, videoBridgeId: string, recording: record, livestreams: list>, paging: record<perPage: int, pageToken: string, nextPageToken: string, previousPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nameFragment" $nameFragment "scalar") (serialize-qp "status" $status "multi") (serialize-qp "endTimeFrom" $endTimeFrom "scalar") (serialize-qp "endTimeTo" $endTimeTo "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webinar/history/v1/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Registration Session Info
#
# GET /webinar/registration/v1/sessions/{sessionId}
# operationId: rcwRegGetSession
export def "webinar-registration-sessions rcwRegGetSession" [
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, registrationStatus: string, registrationPageUri: string, brandingDescriptorUri: string, registrantCount: int, hasRealRegistrants: bool, icalendarSequence: int, settings: record<autoCloseLimit: int, suppressEmails: bool, registrationDigestEnabled: bool, preventMultipleDeviceJoins: bool, workEmailRequired: bool, viewRecording: bool, onDemandDuration: string, recordingExist: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/registration/v1/sessions/($sessionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Registration Session
#
# PATCH /webinar/registration/v1/sessions/{sessionId}
# operationId: rcwRegUpdateSession
# --settings shape: {autoCloseLimit?: int, suppressEmails?: bool, registrationDigestEnabled?: bool, preventMultipleDeviceJoins?: bool, workEmailRequired?: bool, viewRecording?: bool, onDemandDuration?: "OneMonth"|"TwoMonths"|"ThreeMonths"|"SixMonths"|"OneYear"}
export def "webinar-registration-sessions rcwRegUpdateSession" [
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  registrationStatus: string@registrationStatus-completer # Status of the registration (e.g. Open)
  --settings: record # shape: {autoCloseLimit?: int, suppressEmails?: bool, registrationDigestEnabled?: bool, preventMultipleDeviceJoins?: bool, workEmailRequired?: bool, viewRecording?: bool, onDemandDuration?: "OneMonth"|"TwoMonths"|"ThreeMonths"|"SixMonths"|"OneYear"}
]: any -> record<id: string, registrationStatus: string, registrationPageUri: string, brandingDescriptorUri: string, registrantCount: int, hasRealRegistrants: bool, icalendarSequence: int, settings: record<autoCloseLimit: int, suppressEmails: bool, registrationDigestEnabled: bool, preventMultipleDeviceJoins: bool, workEmailRequired: bool, viewRecording: bool, onDemandDuration: string, recordingExist: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/registration/v1/sessions/($sessionId)")
  let body = {registrationStatus: $registrationStatus, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Session Registrants
#
# GET /webinar/registration/v1/sessions/{sessionId}/registrants
# operationId: rcwRegListRegistrants
export def "webinar-registration-sessions-registrants rcwRegListRegistrants" [
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --pageToken: string # The token indicating the particular page of the result set to be retrieved. If omitted the first page will be returned.
  --includeQuestionnaire: string@bool-completer # Indicates if registrant's "questionnaire" should be returned (default: false)
]: nothing -> record<records: list<record>, paging: record<perPage: int, pageToken: string, nextPageToken: string, previousPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "includeQuestionnaire" $includeQuestionnaire "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webinar/registration/v1/sessions/($sessionId)/registrants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Registrant
#
# POST /webinar/registration/v1/sessions/{sessionId}/registrants
# operationId: rcwRegCreateRegistrant
export def "webinar-registration-sessions-registrants rcwRegCreateRegistrant" [
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --questionnaire: list # Answers on custom registration questions
]: any -> record<icalendarSequence: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/registration/v1/sessions/($sessionId)/registrants")
  let body = {questionnaire: $questionnaire} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Registrant
#
# GET /webinar/registration/v1/sessions/{sessionId}/registrants/{registrantId}
# operationId: rcwRegGetRegistrant
export def "webinar-registration-sessions-registrants rcwRegGetRegistrant" [
  sessionId: string
  registrantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeQuestionnaire: string@bool-completer # Indicates if registrant's "questionnaire" should be returned (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeQuestionnaire" $includeQuestionnaire "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webinar/registration/v1/sessions/($sessionId)/registrants/($registrantId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Registrant
#
# DELETE /webinar/registration/v1/sessions/{sessionId}/registrants/{registrantId}
# operationId: rcwRegDeleteRegistrant
export def "webinar-registration-sessions-registrants rcwRegDeleteRegistrant" [
  sessionId: string
  registrantId: string
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
  let full_url = (build-url $base $"/webinar/registration/v1/sessions/($sessionId)/registrants/($registrantId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Webinar
#
# POST /webinar/configuration/v1/webinars
# operationId: rcwConfigCreateWebinar
# --host shape: {linkedUser?: any}
export def "webinar-configuration-webinars rcwConfigCreateWebinar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --host: record # The internal IDs of RC-authenticated users. — shape: {linkedUser?: any}
]: any -> record<host: record<entitled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webinar/configuration/v1/webinars")
  let body = {host: $host} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List User's Webinars
#
# GET /webinar/configuration/v1/webinars
# operationId: rcwConfigListWebinars
export def "webinar-configuration-webinars rcwConfigListWebinars" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --creationTimeFrom: string # The beginning of the time window by 'creationTime' . (format: date-time)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --pageToken: string # The token indicating the particular page of the result set to be retrieved. If omitted the first page will be returned.
]: nothing -> record<records: table<host: record>, paging: record<perPage: int, pageToken: string, nextPageToken: string, previousPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "creationTimeFrom" $creationTimeFrom "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webinar/configuration/v1/webinars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Webinar
#
# GET /webinar/configuration/v1/webinars/{webinarId}
# operationId: rcwConfigGetWebinar
export def "webinar-configuration-webinars rcwConfigGetWebinar" [
  webinarId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<host: record<entitled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/configuration/v1/webinars/($webinarId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Webinar
#
# PATCH /webinar/configuration/v1/webinars/{webinarId}
# operationId: rcwConfigUpdateWebinar
# --settings shape: {autoRecord?: bool, panelistWaitingRoom?: bool, panelistVideoEnabled?: bool, panelistScreenSharingEnabled?: bool, panelistMuteControlEnabled?: bool, panelistAuthentication?: "Guest"|"AuthenticatedUser"|"AuthenticatedCoworker", attendeeAuthentication?: "Guest"|"AuthenticatedUser"|"AuthenticatedCoworker", artifactsAccessAuthentication?: "Guest"|"AuthenticatedUser"|"AuthenticatedCoworker", pstnEnabled?: bool, password?: string, qnaEnabled?: bool, qnaAnonymousEnabled?: bool, registrationEnabled?: bool, postWebinarRedirectUri?: string, moderatedQnaEnabled?: bool}
export def "webinar-configuration-webinars rcwConfigUpdateWebinar" [
  webinarId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Webinar title (e.g. All-Hands Webinar)
  --description: string # User-friendly description of the Webinar (e.g. Quarterly All-hands event to present recent news about our company to employees)
  --settings: record # Various settings which define behavior of this Webinar's Sessions — shape: {autoRecord?: bool, panelistWaitingRoom?: bool, panelistVideoEnabled?: bool, panelistScreenSharingEnabled?: bool, panelistMuteControlEnabled?: bool, panelistAuthentication?: "Guest"|"AuthenticatedUser"|"AuthenticatedCoworker", attendeeAuthentication?: "Guest"|"AuthenticatedUser"|"AuthenticatedCoworker", artifactsAccessAuthentication?: "Guest"|"AuthenticatedUser"|"AuthenticatedCoworker", pstnEnabled?: bool, password?: string, qnaEnabled?: bool, qnaAnonymousEnabled?: bool, registrationEnabled?: bool, postWebinarRedirectUri?: string, moderatedQnaEnabled?: bool}
]: any -> record<host: record<entitled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/configuration/v1/webinars/($webinarId)")
  let body = {title: $title, description: $description, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Webinar
#
# DELETE /webinar/configuration/v1/webinars/{webinarId}
# operationId: rcwConfigDeleteWebinar
export def "webinar-configuration-webinars rcwConfigDeleteWebinar" [
  webinarId: string
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
  let full_url = (build-url $base $"/webinar/configuration/v1/webinars/($webinarId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Webinar Session
#
# POST /webinar/configuration/v1/webinars/{webinarId}/sessions
# operationId: rcwConfigCreateSession
export def "webinar-configuration-webinars-sessions rcwConfigCreateSession" [
  webinarId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scheduledStartTime: string # Session scheduled start time. (format: date-time)
  scheduledDuration: int # The duration of the Session in seconds. (format: int32, e.g. 1800)
  timeZone: string # IANA-compatible time zone name (see https://www.iana.org/time-zones). (e.g. America/New_York)
  --localizedTimeZoneDescription: string # Localized time zone description. (e.g. Eastern Time (America/New_York))
  --panelJoinTimeOffset: int # The time offset (positive, in seconds) indicating how much in advance (comparing to "scheduledStartTime") panel members should join for the pre-webinar team sync  (format: int32, default: 0, e.g. 900)
  --title: string # Session title. Can be left blank - then Webinar title should be used for presentation. (e.g. Live Broadcasting US)
  --description: string # User-friendly description of the Session. Can be left blank - then Webinar title should be used for presentation. (e.g. Live session for US-based participants)
  --status: string@status-completer # Session status (for the purposes of Configuration service) (e.g. Scheduled)
  --localeCode: string # Session locale code. Can't be blank or null (e.g. en-US)
]: any -> record<videoBridgeId: string, videoBridgePassword: string, videoBridgePstnPassword: string, attendeeJoinUri: string, hasUnsentInvites: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/configuration/v1/webinars/($webinarId)/sessions")
  let body = {scheduledStartTime: $scheduledStartTime, scheduledDuration: $scheduledDuration, timeZone: $timeZone, localizedTimeZoneDescription: $localizedTimeZoneDescription, panelJoinTimeOffset: $panelJoinTimeOffset, title: $title, description: $description, status: $status, localeCode: $localeCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Webinar Session
#
# PATCH /webinar/configuration/v1/webinars/{webinarId}/sessions/{sessionId}
# operationId: rcwConfigUpdateSession
export def "webinar-configuration-webinars-sessions rcwConfigUpdateSession" [
  webinarId: string
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scheduledStartTime: string # Session scheduled start time. (format: date-time)
  scheduledDuration: int # The duration of the Session in seconds. (format: int32, e.g. 1800)
  timeZone: string # IANA-compatible time zone name (see https://www.iana.org/time-zones). (e.g. America/New_York)
  --localizedTimeZoneDescription: string # Localized time zone description. (e.g. Eastern Time (America/New_York))
  --panelJoinTimeOffset: int # The time offset (positive, in seconds) indicating how much in advance (comparing to "scheduledStartTime") panel members should join for the pre-webinar team sync  (format: int32, default: 0, e.g. 900)
  --title: string # Session title. Can be left blank - then Webinar title should be used for presentation. (e.g. Live Broadcasting US)
  --description: string # User-friendly description of the Session. Can be left blank - then Webinar title should be used for presentation. (e.g. Live session for US-based participants)
  --status: string@status-completer # Session status (for the purposes of Configuration service) (e.g. Scheduled)
  --localeCode: string # Session locale code. Can't be blank or null (e.g. en-US)
]: any -> record<videoBridgeId: string, videoBridgePassword: string, videoBridgePstnPassword: string, attendeeJoinUri: string, hasUnsentInvites: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/configuration/v1/webinars/($webinarId)/sessions/($sessionId)")
  let body = {scheduledStartTime: $scheduledStartTime, scheduledDuration: $scheduledDuration, timeZone: $timeZone, localizedTimeZoneDescription: $localizedTimeZoneDescription, panelJoinTimeOffset: $panelJoinTimeOffset, title: $title, description: $description, status: $status, localeCode: $localeCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Webinar Session
#
# GET /webinar/configuration/v1/webinars/{webinarId}/sessions/{sessionId}
# operationId: rcwConfigGetSession
export def "webinar-configuration-webinars-sessions rcwConfigGetSession" [
  webinarId: string
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<videoBridgeId: string, videoBridgePassword: string, videoBridgePstnPassword: string, attendeeJoinUri: string, hasUnsentInvites: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/configuration/v1/webinars/($webinarId)/sessions/($sessionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Webinar Session
#
# DELETE /webinar/configuration/v1/webinars/{webinarId}/sessions/{sessionId}
# operationId: rcwConfigDeleteSession
export def "webinar-configuration-webinars-sessions rcwConfigDeleteSession" [
  webinarId: string
  sessionId: string
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
  let full_url = (build-url $base $"/webinar/configuration/v1/webinars/($webinarId)/sessions/($sessionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Add/Delete Session Invitees
#
# PATCH /webinar/configuration/v1/webinars/{webinarId}/sessions/{sessionId}/invitees
# operationId: rcwConfigUpdateInvitees
# --addedInvitees item shape: {linkedUser?: any, role: "Panelist"|"CoHost"|"Host"|"Attendee", type?: "User"|"Room", sendInvite?: bool}
# --updatedInvitees item shape: {id?: string}
# --deletedInvitees item shape: {id?: string}
export def "webinar-configuration-webinars-sessions-invitees rcwConfigUpdateInvitees" [
  webinarId: string
  sessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --addedInvitees: list # item shape: {linkedUser?: any, role: "Panelist"|"CoHost"|"Host"|"Attendee", type?: "User"|"Room", sendInvite?: bool}
  --updatedInvitees: list # item shape: {id?: string}
  --deletedInvitees: list # item shape: {id?: string}
]: any -> record<addedInvitees: table<joinUri: string, phoneParticipantCode: string>, updatedInvitees: table<joinUri: string, phoneParticipantCode: string>, deletedInvitees: table<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/configuration/v1/webinars/($webinarId)/sessions/($sessionId)/invitees")
  let body = {addedInvitees: $addedInvitees, updatedInvitees: $updatedInvitees, deletedInvitees: $deletedInvitees} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Session Invitees
#
# GET /webinar/configuration/v1/webinars/{webinarId}/sessions/{sessionId}/invitees
# operationId: rcwConfigListInvitees
export def "webinar-configuration-webinars-sessions-invitees rcwConfigListInvitees" [
  webinarId: any
  sessionId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --pageToken: string # The token indicating the particular page of the result set to be retrieved. If omitted the first page will be returned.
]: nothing -> record<records: table<joinUri: string, phoneParticipantCode: string>, paging: record<perPage: int, pageToken: string, nextPageToken: string, previousPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webinar/configuration/v1/webinars/($webinarId)/sessions/($sessionId)/invitees" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Session Invitee
#
# GET /webinar/configuration/v1/webinars/{webinarId}/sessions/{sessionId}/invitees/{inviteeId}
# operationId: rcwConfigGetInvitee
export def "webinar-configuration-webinars-sessions-invitees rcwConfigGetInvitee" [
  webinarId: string
  sessionId: string
  inviteeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<joinUri: string, phoneParticipantCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/configuration/v1/webinars/($webinarId)/sessions/($sessionId)/invitees/($inviteeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Session Invitee
#
# PUT /webinar/configuration/v1/webinars/{webinarId}/sessions/{sessionId}/invitees/{inviteeId}
# operationId: rcwConfigUpdateInvitee
export def "webinar-configuration-webinars-sessions-invitees rcwConfigUpdateInvitee" [
  webinarId: string
  sessionId: string
  inviteeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role: string@role-completer # The role of the webinar session participant/invitee. See also: [Understanding Webinar Roles](https://support.ringcentral.com/webinar/getting-started/understanding-ringcentral-webinar-roles.html)  (e.g. Panelist)
  --type: string@type-completer # The type of the webinar invitee (default: User)
  --sendInvite: string@bool-completer # Indicates if invite/cancellation emails have to be sent to this invitee. For "Host" it cannot be set to false. If it is true it can't be changed back to false.  (default: true)
]: any -> record<joinUri: string, phoneParticipantCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webinar/configuration/v1/webinars/($webinarId)/sessions/($sessionId)/invitees/($inviteeId)")
  let body = {role: $role, type: $type, sendInvite: $sendInvite} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Session Invitee
#
# DELETE /webinar/configuration/v1/webinars/{webinarId}/sessions/{sessionId}/invitees/{inviteeId}
# operationId: rcwConfigDeleteInvitee
export def "webinar-configuration-webinars-sessions-invitees rcwConfigDeleteInvitee" [
  webinarId: string
  sessionId: string
  inviteeId: string
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
  let full_url = (build-url $base $"/webinar/configuration/v1/webinars/($webinarId)/sessions/($sessionId)/invitees/($inviteeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Sessions across Multiple Webinars/Hosts
#
# GET /webinar/configuration/v1/company/sessions
# operationId: rcwConfigListAllCompanySessions
export def "webinar-configuration-company-sessions rcwConfigListAllCompanySessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # Filter to return only webinar sessions in certain status. Multiple values are supported. (e.g. Scheduled)
  --endTimeFrom: string # The beginning of the time window by 'endTime' (it is calculated as scheduledStartTime+scheduledDuration) (format: date-time)
  --hostUserId: list # Identifier of the user who hosts a webinar (if omitted, webinars hosted by all company users will be returned) (e.g. [77777777])
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --pageToken: string # The token indicating the particular page of the result set to be retrieved. If omitted the first page will be returned.
]: nothing -> record<records: table<webinar: record>, paging: record<perPage: int, pageToken: string, nextPageToken: string, previousPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "endTimeFrom" $endTimeFrom "scalar") (serialize-qp "hostUserId" $hostUserId "csv") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webinar/configuration/v1/company/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Sessions across Multiple Webinars
#
# GET /webinar/configuration/v1/sessions
# operationId: rcwConfigListAllSessions
export def "webinar-configuration-sessions rcwConfigListAllSessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nameFragment: string # Filter to return only webinar sessions containing particular substring within their names (e.g. All-hands)
  --status: string # Filter to return only webinar sessions in certain status. Multiple values are supported. (e.g. Scheduled)
  --endTimeFrom: string # The beginning of the time window by 'endTime' (it is calculated as scheduledStartTime+scheduledDuration) (format: date-time)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --pageToken: string # The token indicating the particular page of the result set to be retrieved. If omitted the first page will be returned.
]: nothing -> record<records: table<webinar: record>, paging: record<perPage: int, pageToken: string, nextPageToken: string, previousPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nameFragment" $nameFragment "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "endTimeFrom" $endTimeFrom "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webinar/configuration/v1/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Call Recording Content
#
# GET /restapi/v1.0/account/{accountId}/recording/{recordingId}/content
# operationId: readCallRecordingContent
export def "restapi-v10-account-recording-content readCallRecordingContent" [
  accountId: string
  recordingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --contentDisposition: string@contentDisposition-completer # Whether the content is expected to be displayed in the browser, or downloaded and saved locally
  --contentDispositionFilename: string # The default filename of the file to be downloaded
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contentDisposition" $contentDisposition "scalar") (serialize-qp "contentDispositionFilename" $contentDispositionFilename "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/recording/($recordingId)/content" $qp)
  let accept_val = ($accept | default "audio/mpeg")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Account Greeting Media Content
#
# GET /restapi/v1.0/account/{accountId}/greeting/{greetingId}/content
# operationId: readAccountGreetingContent
export def "restapi-v10-account-greeting-content readAccountGreetingContent" [
  accountId: string
  greetingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contentDisposition: string@contentDisposition-completer # Whether the content is expected to be displayed in the browser, or downloaded and saved locally
  --contentDispositionFilename: string # The default filename of the file to be downloaded
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contentDisposition" $contentDisposition "scalar") (serialize-qp "contentDispositionFilename" $contentDispositionFilename "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/greeting/($greetingId)/content" $qp)
  let accept_val = "audio/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Extension Greeting Media Content
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/greeting/{greetingId}/content
# operationId: readGreetingContent
export def "restapi-v10-account-extension-greeting-content readGreetingContent" [
  accountId: string
  extensionId: string
  greetingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contentDisposition: string@contentDisposition-completer # Whether the content is expected to be displayed in the browser, or downloaded and saved locally
  --contentDispositionFilename: string # The default filename of the file to be downloaded
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contentDisposition" $contentDisposition "scalar") (serialize-qp "contentDispositionFilename" $contentDispositionFilename "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/greeting/($greetingId)/content" $qp)
  let accept_val = "audio/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Scaled Profile Image
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/profile-image/{scaleSize}
# operationId: readScaledProfileImage
export def "restapi-v10-account-extension-profile-image readScaledProfileImage" [
  accountId: string
  extensionId: string
  scaleSize: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contentDisposition: string@contentDisposition-completer # Whether the content is expected to be displayed in the browser, or downloaded and saved locally
  --contentDispositionFilename: string # The default filename of the file to be downloaded
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contentDisposition" $contentDisposition "scalar") (serialize-qp "contentDispositionFilename" $contentDispositionFilename "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/profile-image/($scaleSize)" $qp)
  let accept_val = "image/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Message Attachment Content
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/message-store/{messageId}/content/{attachmentId}
# operationId: readMessageContent
export def "restapi-v10-account-extension-message-store-content readMessageContent" [
  accountId: string
  extensionId: string
  messageId: string
  attachmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --contentDisposition: string@contentDisposition-completer # Whether the content is expected to be displayed in the browser, or downloaded and saved locally
  --contentDispositionFilename: string # The default filename of the file to be downloaded
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contentDisposition" $contentDisposition "scalar") (serialize-qp "contentDispositionFilename" $contentDispositionFilename "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/message-store/($messageId)/content/($attachmentId)" $qp)
  let accept_val = ($accept | default "audio/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get IVR Prompt Content
#
# GET /restapi/v1.0/account/{accountId}/ivr-prompts/{promptId}/content
# operationId: readIVRPromptContent
export def "restapi-v10-account-ivr-prompts-content readIVRPromptContent" [
  accountId: string
  promptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contentDisposition: string@contentDisposition-completer # Whether the content is expected to be displayed in the browser, or downloaded and saved locally
  --contentDispositionFilename: string # The default filename of the file to be downloaded
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contentDisposition" $contentDisposition "scalar") (serialize-qp "contentDispositionFilename" $contentDispositionFilename "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/ivr-prompts/($promptId)/content" $qp)
  let accept_val = "audio/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Bridge
#
# POST /rcvideo/v2/account/{accountId}/extension/{extensionId}/bridges
# operationId: createBridge
# --pins shape: {pstn?: record, web?: string}
# --security shape: {passwordProtected?: bool, password?: string, noGuests?: bool, sameAccount?: bool, e2ee?: bool}
# --preferences shape: {join?: record, playTones?: "On"|"Off"|"ExitOnly"|"EnterOnly", musicOnHold?: bool, joinBeforeHost?: bool, screenSharing?: bool, recordingsMode?: "Auto"|"ForceAuto"|"User", transcriptionsMode?: "Auto"|"ForceAuto"|"User", recordings?: record, allowEveryoneTranscribeMeetings?: bool}
export def "rcvideo-account-extension-bridges createBridge" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Custom name of a bridge (e.g. Weekly Meeting with Joseph)
  --type: string@type-completer-1 # Type of bridge. It specifies bridge life cycle. 1) Instant - The bridge will be used for a meeting only once immediately after creation. Then it will be deleted. 2) Scheduled - The bridge will be used for scheduled one or more meetings. If the bridge is not used for a long time after the last meeting, then it will be deleted. 3) PMI - The bridge will contain Personal Meeting Identifier owned by a user. It is the default user bridge. Each user may have only one default (PMI) bridge. Such bridge will be deleted only in case the user is deleted from the system.  (default: Instant)
  --pins: record # shape: {pstn?: record, web?: string}
  --security: record # shape: {passwordProtected?: bool, password?: string, noGuests?: bool, sameAccount?: bool, e2ee?: bool}
  --preferences: record # shape: {join?: record, playTones?: "On"|"Off"|"ExitOnly"|"EnterOnly", musicOnHold?: bool, joinBeforeHost?: bool, screenSharing?: bool, recordingsMode?: "Auto"|"ForceAuto"|"User", transcriptionsMode?: "Auto"|"ForceAuto"|"User", recordings?: record, allowEveryoneTranscribeMeetings?: bool}
]: any -> record<id: string, name: string, type: string, host: record<accountId: string, extensionId: string>, pins: record<pstn: record<host: string, participant: string>, web: string, aliases: list<string>>, security: record<passwordProtected: bool, password: record<plainText: string, pstn: string, joinQuery: string>, noGuests: bool, sameAccount: bool, e2ee: bool>, preferences: record<join: record<audioMuted: bool, videoMuted: bool, waitingRoomRequired: string, pstn: record>, playTones: string, musicOnHold: bool, joinBeforeHost: bool, screenSharing: bool, recordingsMode: string, transcriptionsMode: string, recordings: record<everyoneCanControl: record, autoShared: record>, allowEveryoneTranscribeMeetings: bool>, discovery: record<web: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rcvideo/v2/account/($accountId)/extension/($extensionId)/bridges")
  let body = {name: $name, type: $type, pins: $pins, security: $security, preferences: $preferences} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get User's Default Bridge
#
# GET /rcvideo/v2/account/{accountId}/extension/{extensionId}/bridges/default
# operationId: getDefaultBridge
export def "rcvideo-account-extension-bridges-default get" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, type: string, host: record<accountId: string, extensionId: string>, pins: record<pstn: record<host: string, participant: string>, web: string, aliases: list<string>>, security: record<passwordProtected: bool, password: record<plainText: string, pstn: string, joinQuery: string>, noGuests: bool, sameAccount: bool, e2ee: bool>, preferences: record<join: record<audioMuted: bool, videoMuted: bool, waitingRoomRequired: string, pstn: record>, playTones: string, musicOnHold: bool, joinBeforeHost: bool, screenSharing: bool, recordingsMode: string, transcriptionsMode: string, recordings: record<everyoneCanControl: record, autoShared: record>, allowEveryoneTranscribeMeetings: bool>, discovery: record<web: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rcvideo/v2/account/($accountId)/extension/($extensionId)/bridges/default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Bridge by PSTN PIN
#
# GET /rcvideo/v2/bridges/pin/pstn/{pin}
# operationId: getBridgeByPstnPin
export def "rcvideo-bridges-pin-pstn get" [
  pin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --phoneNumber: string # Phone number to find a phone group for PSTN PIN. If it is not specified, then the default phone group will be used.
  --pw: string # Bridge hash password
]: nothing -> record<id: string, name: string, type: string, host: record<accountId: string, extensionId: string>, pins: record<pstn: record<host: string, participant: string>, web: string, aliases: list<string>>, security: record<passwordProtected: bool, password: record<plainText: string, pstn: string, joinQuery: string>, noGuests: bool, sameAccount: bool, e2ee: bool>, preferences: record<join: record<audioMuted: bool, videoMuted: bool, waitingRoomRequired: string, pstn: record>, playTones: string, musicOnHold: bool, joinBeforeHost: bool, screenSharing: bool, recordingsMode: string, transcriptionsMode: string, recordings: record<everyoneCanControl: record, autoShared: record>, allowEveryoneTranscribeMeetings: bool>, discovery: record<web: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "phoneNumber" $phoneNumber "scalar") (serialize-qp "pw" $pw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rcvideo/v2/bridges/pin/pstn/($pin)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Bridge by Web PIN
#
# GET /rcvideo/v2/bridges/pin/web/{pin}
# operationId: getBridgeByWebPin
export def "rcvideo-bridges-pin-web get" [
  pin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pw: string # Bridge hash password
]: nothing -> record<id: string, name: string, type: string, host: record<accountId: string, extensionId: string>, pins: record<pstn: record<host: string, participant: string>, web: string, aliases: list<string>>, security: record<passwordProtected: bool, password: record<plainText: string, pstn: string, joinQuery: string>, noGuests: bool, sameAccount: bool, e2ee: bool>, preferences: record<join: record<audioMuted: bool, videoMuted: bool, waitingRoomRequired: string, pstn: record>, playTones: string, musicOnHold: bool, joinBeforeHost: bool, screenSharing: bool, recordingsMode: string, transcriptionsMode: string, recordings: record<everyoneCanControl: record, autoShared: record>, allowEveryoneTranscribeMeetings: bool>, discovery: record<web: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pw" $pw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rcvideo/v2/bridges/pin/web/($pin)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Bridge
#
# GET /rcvideo/v2/bridges/{bridgeId}
# operationId: getBridge
export def "rcvideo-bridges get" [
  bridgeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pw: string # Bridge hash password
]: nothing -> record<id: string, name: string, type: string, host: record<accountId: string, extensionId: string>, pins: record<pstn: record<host: string, participant: string>, web: string, aliases: list<string>>, security: record<passwordProtected: bool, password: record<plainText: string, pstn: string, joinQuery: string>, noGuests: bool, sameAccount: bool, e2ee: bool>, preferences: record<join: record<audioMuted: bool, videoMuted: bool, waitingRoomRequired: string, pstn: record>, playTones: string, musicOnHold: bool, joinBeforeHost: bool, screenSharing: bool, recordingsMode: string, transcriptionsMode: string, recordings: record<everyoneCanControl: record, autoShared: record>, allowEveryoneTranscribeMeetings: bool>, discovery: record<web: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pw" $pw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rcvideo/v2/bridges/($bridgeId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Bridge
#
# PATCH /rcvideo/v2/bridges/{bridgeId}
# operationId: updateBridge
# --pins shape: {web?: string}
# --security shape: {passwordProtected?: bool, password?: string, noGuests?: bool, sameAccount?: bool, e2ee?: bool}
# --preferences shape: {join?: record, playTones?: "On"|"Off"|"ExitOnly"|"EnterOnly", musicOnHold?: bool, joinBeforeHost?: bool, screenSharing?: bool, recordingsMode?: "Auto"|"ForceAuto"|"User", transcriptionsMode?: "Auto"|"ForceAuto"|"User", recordings?: record, allowEveryoneTranscribeMeetings?: bool}
export def "rcvideo-bridges updateBridge" [
  bridgeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Custom name of a bridge (e.g. Weekly Meeting with Joseph)
  --pins: record # shape: {web?: string}
  --security: record # shape: {passwordProtected?: bool, password?: string, noGuests?: bool, sameAccount?: bool, e2ee?: bool}
  --preferences: record # shape: {join?: record, playTones?: "On"|"Off"|"ExitOnly"|"EnterOnly", musicOnHold?: bool, joinBeforeHost?: bool, screenSharing?: bool, recordingsMode?: "Auto"|"ForceAuto"|"User", transcriptionsMode?: "Auto"|"ForceAuto"|"User", recordings?: record, allowEveryoneTranscribeMeetings?: bool}
]: any -> record<id: string, name: string, type: string, host: record<accountId: string, extensionId: string>, pins: record<pstn: record<host: string, participant: string>, web: string, aliases: list<string>>, security: record<passwordProtected: bool, password: record<plainText: string, pstn: string, joinQuery: string>, noGuests: bool, sameAccount: bool, e2ee: bool>, preferences: record<join: record<audioMuted: bool, videoMuted: bool, waitingRoomRequired: string, pstn: record>, playTones: string, musicOnHold: bool, joinBeforeHost: bool, screenSharing: bool, recordingsMode: string, transcriptionsMode: string, recordings: record<everyoneCanControl: record, autoShared: record>, allowEveryoneTranscribeMeetings: bool>, discovery: record<web: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rcvideo/v2/bridges/($bridgeId)")
  let body = {name: $name, pins: $pins, security: $security, preferences: $preferences} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Bridge
#
# DELETE /rcvideo/v2/bridges/{bridgeId}
# operationId: deleteBridge
export def "rcvideo-bridges delete" [
  bridgeId: string
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
  let full_url = (build-url $base $"/rcvideo/v2/bridges/($bridgeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Account Recordings
#
# GET /rcvideo/v1/account/{accountId}/recordings
# operationId: getAccountRecordings
export def "rcvideo-account-recordings get" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageToken: string # Token to get the next page
  --perPage: int # Number of records returned (format: int32)
]: nothing -> record<recordings: table<id: string, shortId: string, startTime: string, duration: int, displayName: string, hostInfo: record, mediaLink: string, url: string, expiresIn: string>, paging: record<currentPageToken: string, nextPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rcvideo/v1/account/($accountId)/recordings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Recordings
#
# GET /rcvideo/v1/account/{accountId}/extension/{extensionId}/recordings
# operationId: getExtensionRecordings
export def "rcvideo-account-extension-recordings get" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageToken: string # Token to get the next page
  --perPage: int # Number of records returned (format: int32)
]: nothing -> record<recordings: table<id: string, shortId: string, startTime: string, duration: int, displayName: string, hostInfo: record, mediaLink: string, url: string, expiresIn: string>, paging: record<currentPageToken: string, nextPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/rcvideo/v1/account/($accountId)/extension/($extensionId)/recordings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Delegators
#
# GET /rcvideo/v1/accounts/{accountId}/extensions/{extensionId}/delegators
# operationId: rcvListDelegators
export def "rcvideo-accounts-extensions-delegators rcvListDelegators" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<id: string, name: string, accountId: string, extensionId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rcvideo/v1/accounts/($accountId)/extensions/($extensionId)/delegators")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Video Meetings
#
# GET /rcvideo/v1/history/meetings
# operationId: listVideoMeetings
export def "rcvideo-history-meetings listVideoMeetings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # Search text
  --pageToken: string # Token to get the next page
  --perPage: int # Number of records returned (format: int32)
  --type: string@type-completer-2 # Specify what kind of meeting should be returned. Possible values: All, My, Deleted, Shared Request type meaning in meeting search: `None` (not passed) - take meetings only where requested acc/ext is participant OR host OR deputy OR watcher. `ALL`- access rights of meeting is equal to Alive AND requested acc/ext  is in watchers list OR host OR deputy `My`- access rights of meeting is equal to Alive AND requested acc/ext is host OR deputy `Shared` - access rights of meeting is equal to Alive AND requested acc/ext is in watcher list AND not HOST `Deleted` - access rights of meeting is equal to Delete and requested acc/ext is host OR deputy
  --startTime: int # Unix timestamp in milliseconds (inclusive) indicates the start time of meetings which should be included in response (format: int64)
  --endTime: int # Unix timestamp in milliseconds (inclusive) indicates the end time of meetings which should be included in response (format: int64)
]: nothing -> record<meetings: table<id: string, bridgeId: string, shortId: string, startTime: string, duration: int, displayName: string, type: string, status: string, hostInfo: record, rights: list, longSummary: string, shortSummary: string, keywords: list, participants: list, recordings: list, chatUrl: string>, paging: record<currentPageToken: string, nextPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rcvideo/v1/history/meetings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Video Meeting
#
# GET /rcvideo/v1/history/meetings/{meetingId}
# operationId: getVideoMeeting
export def "rcvideo-history-meetings get" [
  meetingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, bridgeId: string, shortId: string, startTime: string, duration: int, displayName: string, type: string, status: string, hostInfo: record<accountId: string, extensionId: string, displayName: string>, rights: list<string>, longSummary: string, shortSummary: string, keywords: list<string>, participants: table<type: string, id: string, accountId: string, extensionId: string, displayName: string, callerId: string, correlationId: string>, recordings: table<id: string, startTime: int, url: string, metadata: record, status: string, availabilityStatus: string, longSummary: string, shortSummary: string, keywords: list>, chatUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rcvideo/v1/history/meetings/($meetingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get API Versions
#
# GET /restapi
# operationId: readAPIVersions
export def "restapi readAPIVersions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, apiVersions: table<uri: string, versionString: string, releaseDate: string, uriString: string>, serverVersion: string, serverRevision: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restapi")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OAuth 2.0 Token Endpoint
#
# POST /restapi/oauth/token
# operationId: getToken
export def "restapi-oauth-token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-assertion-type: string@client-assertion-type-completer # Client assertion type for the `client_secret_jwt` or `private_key_jwt` client authentication types, as defined by [RFC-7523](https://datatracker.ietf.org/doc/html/rfc7523#section-2.2). This parameter is mandatory if the client authentication is required and a client decided to use one of these authentication types
  --client-assertion: string # Client assertion (JWT) for the `client_secret_jwt` or `private_key_jwt` client authentication types, as defined by [RFC-7523](https://datatracker.ietf.org/doc/html/rfc7523#section-2.2). This parameter is mandatory if the client authentication is required and a client decided to use one of these authentication types
  grant_type: string@grant-type-completer # Grant type
  --scope: string # The list of application permissions (OAuth scopes) requested. By default, it includes all permissions configured on the client application registration
  --client-id: string # The registered identifier of a client application. Used to identify a client ONLY if the client authentication is not required and corresponding credentials are not provided with this request  (e.g. AZwEVwGEcfGet2PCouA7K6)
  --endpoint-id: string # The unique identifier of a client application instance. If not specified, the derived or auto-generated value will be used
  --access-token-ttl: int # Access token lifetime in seconds (format: int32, default: 3600)
  --refresh-token-ttl: int # Refresh token lifetime in seconds (format: int32, default: 604800)
]: any -> record<access_token: string, expires_in: int, refresh_token: string, refresh_token_expires_in: int, scope: string, token_type: string, owner_id: string, endpoint_id: string, id_token: string, session_expires_in: int, session_expiration_time: string, session_id: string, session_idle_timeout: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restapi/oauth/token")
  let body = {client_assertion_type: $client_assertion_type, client_assertion: $client_assertion, grant_type: $grant_type, scope: $scope, client_id: $client_id, endpoint_id: $endpoint_id, access_token_ttl: $access_token_ttl, refresh_token_ttl: $refresh_token_ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# OAuth 2.0 Authorization Endpoint
#
# GET /restapi/oauth/authorize
# operationId: authorize
@deprecated --flag localeId
export def "restapi-oauth-authorize authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # The registered identifier of a client application (e.g. AZwEVwGEcfGet2PCouA7K6)
  --response-type: string@response-type-completer # Determines authorization flow type. The only supported value is `code` which corresponds to OAuth 2.0 "Authorization Code Flow"
  --redirect-uri: string # This is the URI where the Authorization Server redirects the User Agent to at the end of the authorization flow. The value of this parameter must exactly match one of the URIs registered for this client application. This parameter is required if there are more than one redirect URIs registered for the app.  (format: uri)
  --state: string # An opaque value used by the client to maintain state between the request and callback. The authorization server includes this value when redirecting the User Agent back to the client. The parameter SHOULD be used for preventing cross-site request forgery attacks.
  --scope: string # The list of space separated application permissions (OAuth scopes)
  --display: string # Specifies how the Authorization Server displays the authentication and consent user interface pages to the End-User.
  --prompt: string # Space-delimited, case-sensitive list of ASCII string values that specifies whether the Authorization Server prompts the End-User for re-authentication and consent. The defined values are:  - `login` - RingCentral native login form, - `sso` - Single Sign-On login form, - `consent` - form to show the requested scope and prompt user for consent.  Either `login` or `sso` (or both) must be specified. The default value is `login sso`  (default: login sso)
  --ui-locales: string # End-User's preferred languages and scripts for the user interface, represented as a space-separated list of [RFC-5646](https://datatracker.ietf.org/doc/html/rfc5646) language tag values, ordered by preference.  If this parameter is provided, its value overrides 'Accept-Language' header value and 'localeId' parameter value (if any)  (e.g. en-US)
  --localeId: string # DEPRECATED: `ui_locales` parameter should be used instead (DEPRECATED, e.g. en-US)
  --code-challenge: string # The code challenge value as defined by the PKCE specification - [RFC-7636 "Proof Key for Code Exchange by OAuth Public Clients"](https://datatracker.ietf.org/doc/html/rfc7636)
  --code-challenge-method: string # The code challenge method as defined by by the PKCE specification - [RFC-7636 "Proof Key for Code Exchange by OAuth Public Clients"](https://datatracker.ietf.org/doc/html/rfc7636)
  --nonce: string # String value used to associate a Client session with an ID Token, and to mitigate replay attacks. The value is passed through unmodified from the Authentication Request to the ID Token.
  --ui-options: string # Login form user interface options (space-separated). By default, the UI options that are registered for this client application will be used
  --login-hint: string # Hint to the Authorization Server about the login identifier the End-User might use to log in.
  --brand-id: string # RingCentral Brand identifier. If it is not provided in the request, server will try to determine brand from the client application profile.  (e.g. 1210)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "response_type" $response_type "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "display" $display "scalar") (serialize-qp "prompt" $prompt "scalar") (serialize-qp "ui_locales" $ui_locales "scalar") (serialize-qp "localeId" $localeId "scalar") (serialize-qp "code_challenge" $code_challenge "scalar") (serialize-qp "code_challenge_method" $code_challenge_method "scalar") (serialize-qp "nonce" $nonce "scalar") (serialize-qp "ui_options" $ui_options "scalar") (serialize-qp "login_hint" $login_hint "scalar") (serialize-qp "brand_id" $brand_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapi/oauth/authorize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OAuth 2.0 Authorization Endpoint (POST)
#
# POST /restapi/oauth/authorize
# operationId: authorize2
@deprecated --flag accept-language
export def "restapi-oauth-authorize authorize2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  response_type: string@response-type-completer # Determines authorization flow type. The only supported value is `code` which corresponds to OAuth 2.0 "Authorization Code Flow"
  --redirect-uri: string # This is the URI where the Authorization Server redirects the User Agent to at the end of the authorization flow. The value of this parameter must exactly match one of the URIs registered for this client application. This parameter is required if there are more than one redirect URIs registered for the app.  (format: uri)
  client_id: string # The registered identifier of a client application (e.g. AZwEVwGEcfGet2PCouA7K6)
  --state: string # An opaque value used by the client to maintain state between the request and callback. The authorization server includes this value when redirecting the User Agent back to the client. The parameter SHOULD be used for preventing cross-site request forgery attacks.
  --scope: string # The list of requested OAuth scopes (space separated)
  --display: string@display-completer # Specifies how the Authorization Server displays the authentication and consent user interface pages to the End-User.  (default: page)
  --prompt: string # Space-delimited, case-sensitive list of ASCII string values that specifies whether the Authorization Server prompts the End-User for re-authentication and consent. The defined values are:  - `login` - RingCentral native login form, - `sso` - Single Sign-On login form, - `consent` - form to show the requested scope and prompt user for consent.  Either `login` or `sso` (or both) must be specified. The default value is `login sso`  (default: login sso)
  --ui-locales: string # End-User's preferred languages and scripts for the user interface, represented as a space-separated list of [RFC-5646](https://datatracker.ietf.org/doc/html/rfc5646) language tag values, ordered by preference.  If this parameter is provided, its value overrides 'Accept-Language' header value and 'localeId' parameter value (if any)  (e.g. en-US)
  --code-challenge: string # The code challenge value as defined by the PKCE specification - [RFC-7636 "Proof Key for Code Exchange by OAuth Public Clients"](https://datatracker.ietf.org/doc/html/rfc7636)
  --code-challenge-method: string@code-challenge-method-completer # The code challenge method as defined by the PKCE specification - [RFC-7636 "Proof Key for Code Exchange by OAuth Public Clients"](https://datatracker.ietf.org/doc/html/rfc7636)  (default: plain)
  --nonce: string # String value used to associate a Client session with an ID Token, and to mitigate replay attacks. The value is passed through unmodified from the Authentication Request to the ID Token.
  --ui-options: string # Login form user interface options (space-separated). By default, the UI options that are registered for this client application will be used
  --login-hint: string # Hint to the Authorization Server about the login identifier the End-User might use to log in.
  --brand-id: string # RingCentral Brand identifier. If it is not provided in the request, server will try to determine brand from the client application profile.  (e.g. 1210)
  --accept-language: string # DEPRECATED
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restapi/oauth/authorize")
  let body = {response_type: $response_type, redirect_uri: $redirect_uri, client_id: $client_id, state: $state, scope: $scope, display: $display, prompt: $prompt, ui_locales: $ui_locales, code_challenge: $code_challenge, code_challenge_method: $code_challenge_method, nonce: $nonce, ui_options: $ui_options, login_hint: $login_hint, brand_id: $brand_id, accept_language: $accept_language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# OAuth 2.0 Token Revocation Endpoint
#
# POST /restapi/oauth/revoke
# operationId: revokeToken
export def "restapi-oauth-revoke revokeToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # Access or refresh token to be revoked (along with the entire OAuth session)
  --body-token: string # Access or refresh token to be revoked (along with the entire OAuth session)
  --client-assertion-type: string@client-assertion-type-completer # Client assertion type for the `client_secret_jwt` or `private_key_jwt` client authentication types, as defined by [RFC-7523](https://datatracker.ietf.org/doc/html/rfc7523#section-2.2). This parameter is mandatory if the client authentication is required and a client decided to use one of these authentication types
  --client-assertion: string # Client assertion (JWT) for the `client_secret_jwt` or `private_key_jwt` client authentication types, as defined by [RFC-7523](https://datatracker.ietf.org/doc/html/rfc7523#section-2.2). This parameter is mandatory if the client authentication is required and a client decided to use one of these authentication types
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapi/oauth/revoke" $qp)
  let body = {token: $body_token, client_assertion_type: $client_assertion_type, client_assertion: $client_assertion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get Account Info
#
# GET /restapi/v2/accounts/{accountId}
# operationId: getAccountInfoV2
export def "restapi-accounts get" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, externalAccountId: string, mainNumber: string, status: string, statusInfo: record<reason: string, comment: string, till: string>, companyName: string, companyAddress: record<street: string, street2: string, city: string, state: string, zip: string, country: string>, serviceInfo: record<package: record<id: string, version: string>, brand: record<id: string, name: string>, contractedCountry: record<isoCode: string, callingCode: string>, uBrand: record<id: string, name: string>, servicePlan: record<id: string, name: string, edition: string, freemiumProductType: string>>, contactInfo: record<id: string, extensionNumber: string>, opportunityId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Phone to Inventory
#
# POST /restapi/v2/accounts/{accountId}/device-inventory
# operationId: addDeviceToInventory
# --site shape: {id?: string}
export def "restapi-accounts-device-inventory addDeviceToInventory" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-3 # Device type. Use `OtherPhone` to indicate BYOD (customer provided) device
  quantity: int # Quantity of devices (total quantity should not exceed 50) (format: int32)
  --site: record # shape: {id?: string}
]: any -> record<devices: table<id: string>, site: record<id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)/device-inventory")
  let body = {type: $type, quantity: $quantity, site: $site} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Device from Inventory
#
# DELETE /restapi/v2/accounts/{accountId}/device-inventory
# operationId: deleteDeviceFromInventory
# --records item shape: {deviceId?: string}
export def "restapi-accounts-device-inventory delete" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  records: list # List of internal identifiers of the devices that should be deleted — item shape: {deviceId?: string}
]: any -> record<records: table<bulkItemSuccessful: bool, deviceId: string, bulkItemErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)/device-inventory")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send/Resend Welcome Email
#
# POST /restapi/v2/accounts/{accountId}/send-welcome-email
# operationId: sendWelcomeEmailV2
export def "restapi-accounts-send-welcome-email sendWelcomeEmailV2" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # format: email, e.g. user@email.com
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)/send-welcome-email")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Account Phone Numbers
#
# GET /restapi/v2/accounts/{accountId}/phone-numbers
# operationId: listAccountPhoneNumbersV2
export def "restapi-accounts-phone-numbers listAccountPhoneNumbersV2" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The result set page number (1-indexed) to return (format: int32, default: 1, e.g. 1)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --type: list # Types of phone numbers to be returned
  --usageType: list # Usage type(s) of phone numbers to be returned
  --status: string # Status of the phone number(s) to be returned
  --tollType: string # Toll type of phone numbers to return
  --extensionStatus: string # Statuses of extensions to return phone numbers for
  --byocNumber: string@bool-completer # The parameter reflects whether this number is BYOC or not
  --phoneNumber: string # Phone number in e.164 format to be searched for. Parameter value can include wildcards (e.g. "+165012345**") or be an exact number "+16501234500" - single number is searched in that case. Make sure you escape the "+" in the URL as "%2B"
]: nothing -> record<records: table<id: string, phoneNumber: string, type: string, tollType: string, usageType: string, byocNumber: bool, status: string, extension: record>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "type" $type "multi") (serialize-qp "usageType" $usageType "multi") (serialize-qp "status" $status "scalar") (serialize-qp "tollType" $tollType "scalar") (serialize-qp "extensionStatus" $extensionStatus "scalar") (serialize-qp "byocNumber" $byocNumber "scalar") (serialize-qp "phoneNumber" $phoneNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)/phone-numbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Numbers from Inventory
#
# DELETE /restapi/v2/accounts/{accountId}/phone-numbers
# operationId: deleteNumbersFromInventoryV2
# --records item shape: {id?: string, phoneNumber?: string}
export def "restapi-accounts-phone-numbers delete" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  records: list # List of phone numbers or phone IDs to be deleted — item shape: {id?: string, phoneNumber?: string}
]: any -> record<records: table<bulkItemSuccessful: bool, bulkItemErrors: list, id: string, phoneNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)/phone-numbers")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign Phone Number
#
# PATCH /restapi/v2/accounts/{accountId}/phone-numbers/{phoneNumberId}
# operationId: assignPhoneNumberV2
# --extension shape: {id: string}
export def "restapi-accounts-phone-numbers assignPhoneNumberV2" [
  accountId: string
  phoneNumberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # Type of phone number (nullable)
  usageType: string@usageType-completer # Target usage type of phone number (only listed values are supported)
  --extension: record # shape: {id: string}
  --costCenterId: string
]: any -> record<id: string, phoneNumber: string, type: string, tollType: string, usageType: string, byocNumber: bool, status: string, extension: record<id: string, extensionNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)/phone-numbers/($phoneNumberId)")
  let body = {type: $type, usageType: $usageType, extension: $extension, costCenterId: $costCenterId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace Phone Number
#
# POST /restapi/v2/accounts/{accountId}/phone-numbers/{phoneNumberId}/replace
# operationId: replacePhoneNumberV2
export def "restapi-accounts-phone-numbers-replace replacePhoneNumberV2" [
  accountId: string
  phoneNumberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --targetPhoneNumberId: string # Internal unique identifier of a phone number (e.g. 1162820004)
]: any -> record<id: string, phoneNumber: string, type: string, tollType: string, usageType: string, byocNumber: bool, status: string, extension: record<id: string, extensionNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)/phone-numbers/($phoneNumberId)/replace")
  let body = {targetPhoneNumberId: $targetPhoneNumberId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Numbers to Inventory
#
# POST /restapi/v2/accounts/{accountId}/phone-numbers/bulk-add
# operationId: addNumbersToInventoryV2
# --records item shape: {phoneNumber: string, usageType: "Inventory"|"InventoryPartnerBusinessMobileNumber"|"PartnerBusinessMobileNumber"}
export def "restapi-accounts-phone-numbers-bulk-add addNumbersToInventoryV2" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  records: list # List of account phone numbers — item shape: {phoneNumber: string, usageType: "Inventory"|"InventoryPartnerBusinessMobileNumber"|"PartnerBusinessMobileNumber"}
]: any -> record<records: table<bulkItemSuccessful: bool, bulkItemErrors: list, id: string, phoneNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)/phone-numbers/bulk-add")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Add Numbers Task Results
#
# GET /restapi/v2/accounts/{accountId}/phone-numbers/bulk-add/{taskId}
# operationId: getBulkAddTaskResultsV2
export def "restapi-accounts-phone-numbers-bulk-add get" [
  accountId: string
  taskId: string
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
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)/phone-numbers/bulk-add/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove phone line
#
# DELETE /restapi/v2/accounts/{accountId}/devices/{deviceId}
# operationId: removeLineJWSPublic
export def "restapi-accounts-devices removeLineJWSPublic" [
  accountId: string
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keepAssetsInInventory: string@bool-completer # The flag that controls what to do with the number and device:  - if the value of `keepAssetsInInventory` is `true`, the given device is moved to unassigned devices and the number is moved to the number inventory; - if the value of `keepAssetsInInventory` is `false`, the given device and number is removed from the account; - if the parameter `keepAssetsInInventory` is not set (empty body) or the value of the parameter is empty, default value `true` is set.  (default: true)
]: any -> record<id: string, type: string, name: string, serial: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)/devices/($deviceId)")
  let body = {keepAssetsInInventory: $keepAssetsInInventory} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add BYOD Devices
#
# POST /restapi/v2/accounts/{accountId}/devices/bulk-add
# operationId: bulkAddDevicesV2
# --records item shape: {costCenterId?: string, extension: record, type: "OtherPhone"|"WebRTC", emergency: any, phoneInfo: any}
export def "restapi-accounts-devices-bulk-add bulkAddDevicesV2" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  records: list # item shape: {costCenterId?: string, extension: record, type: "OtherPhone"|"WebRTC", emergency: any, phoneInfo: any}
]: any -> record<results: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)/devices/bulk-add")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send/Resend Activation Email
#
# POST /restapi/v2/accounts/{accountId}/send-activation-email
# operationId: sendActivationEmailV2
export def "restapi-accounts-send-activation-email sendActivationEmailV2" [
  accountId: string
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
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)/send-activation-email")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Multiple User Extensions
#
# POST /restapi/v2/accounts/{accountId}/batch-provisioning/users
# operationId: postBatchProvisionUsers
# --records item shape: {extensionNumber?: string, status: "Enabled", contact: any, costCenter?: record, roles?: list, devices?: list, sendWelcomeEmail?: bool}
export def "restapi-accounts-batch-provisioning-users post" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  records: list # item shape: {extensionNumber?: string, status: "Enabled", contact: any, costCenter?: record, roles?: list, devices?: list, sendWelcomeEmail?: bool}
]: any -> record<results: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)/batch-provisioning/users")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete User Extensions
#
# DELETE /restapi/v2/accounts/{accountId}/extensions
# operationId: bulkDeleteUsersV2
# --records item shape: {id: string}
export def "restapi-accounts-extensions bulkDeleteUsersV2" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keepAssetsInInventory: string@bool-completer # Indicates that the freed users' assets (phone numbers and devices) should be moved to account inventory rather than deleted. If set to `true`, the phone numbers and devices assigned to deleted extensions will be kept in the account's inventory. If set to `false`, these assets will be deleted from the account and returned to either the partner's phone numbers or RingCentral's phone number pool  (default: true)
  records: list # item shape: {id: string}
]: any -> record<records: table<id: string, bulkItemSuccessful: bool, bulkItemErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)/extensions")
  let body = {keepAssetsInInventory: $keepAssetsInInventory, records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Swap Devices
#
# POST /restapi/v2/accounts/{accountId}/extensions/{extensionId}/devices/{deviceId}/replace
# operationId: replaceDevicesJWSPublic
export def "restapi-accounts-extensions-devices-replace replaceDevicesJWSPublic" [
  accountId: string
  extensionId: string
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --targetDeviceId: string # Internal identifier of a target device, to which the current one will be swapped (e.g. 8459879873)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v2/accounts/($accountId)/extensions/($extensionId)/devices/($deviceId)/replace")
  let body = {targetDeviceId: $targetDeviceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Account Info
#
# GET /restapi/v1.0/account/{accountId}
# operationId: readAccountInfo
export def "restapi-v10-account readAccountInfo" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, uri: string, bsid: string, mainNumber: string, operator: record<uri: string, id: int, extensionNumber: string, partnerId: string>, partnerId: string, serviceInfo: record<uri: string, billingPlan: record<id: string, name: string, durationUnit: string, duration: int, type: string, includedPhoneLines: int>, brand: record<id: string, name: string, homeCountry: record>, servicePlan: record<id: string, name: string, edition: string, freemiumProductType: string>, targetServicePlan: record<id: string, name: string, edition: string, freemiumProductType: string>, contractedCountry: record<isoCode: string, callingCode: string>, uBrand: record<id: string, name: string>>, setupWizardState: string, signupInfo: record<tosAccepted: bool, signupState: list<string>, verificationReason: string, marketingAccepted: bool, creationTime: string>, status: string, statusInfo: record<reason: string, comment: string, till: string>, regionalSettings: record<homeCountry: record<isoCode: string, callingCode: string>, timezone: record<id: string, uri: string, name: string, description: string, bias: string>, language: record<id: string, localeCode: string, name: string>, greetingLanguage: record<id: string, localeCode: string, name: string>, formattingLocale: record<id: string, localeCode: string, name: string>, timeFormat: string, currency: record<id: int, code: string, name: string, symbol: string, minorSymbol: string>>, federated: bool, outboundCallPrefix: int, cfid: string, limits: record<freeSoftPhoneLinesPerExtension: int, meetingSize: int, cloudRecordingStorage: int, maxMonitoredExtensionsPerUser: int, maxExtensionNumberLength: int, siteCodeLength: int, shortExtensionNumberLength: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Company Business Hours
#
# GET /restapi/v1.0/account/{accountId}/business-hours
# operationId: readCompanyBusinessHours
export def "restapi-v10-account-business-hours readCompanyBusinessHours" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, schedule: record<weeklyRanges: record<monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, sunday: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/business-hours")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Company Business Hours
#
# PUT /restapi/v1.0/account/{accountId}/business-hours
# operationId: updateCompanyBusinessHours
# --schedule shape: {weeklyRanges?: record}
export def "restapi-v10-account-business-hours updateCompanyBusinessHours" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --schedule: record # Schedule when an answering rule is applied — shape: {weeklyRanges?: record}
]: any -> record<uri: string, schedule: record<weeklyRanges: record<monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, sunday: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/business-hours")
  let body = {schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Device
#
# GET /restapi/v1.0/account/{accountId}/device/{deviceId}
# operationId: readDevice
export def "restapi-v10-account-device readDevice" [
  accountId: string
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --syncEmergencyAddress: string@bool-completer # Specifies if an emergency address should be synchronized or not (default: false)
]: nothing -> record<id: string, uri: string, sku: string, type: string, name: string, serial: string, status: string, computerName: string, model: record<id: string, name: string, addons: list<record>, deviceClass: string, features: list<string>, lineCount: int>, extension: record<id: int, uri: string, extensionNumber: string, partnerId: string>, emergency: record<address: record<country: string, countryId: string, countryIsoCode: string, countryName: string, state: string, stateId: string, stateIsoCode: string, stateName: string, city: string, street: string, street2: string, zip: string, customerName: string>, location: record<id: string, name: string, addressFormatId: string>, outOfCountry: bool, addressStatus: string, visibility: string, syncStatus: string, addressEditableStatus: string>, emergencyServiceAddress: record<street: string, street2: string, city: string, zip: string, customerName: string, state: string, stateId: string, stateIsoCode: string, stateName: string, countryId: string, countryIsoCode: string, country: string, countryName: string, outOfCountry: bool, syncStatus: string, additionalCustomerName: string, customerEmail: string, additionalCustomerEmail: string, customerPhone: string, additionalCustomerPhone: string, lineProvisioningStatus: string, taxId: string>, phoneLines: table<id: string, lineType: string, phoneInfo: record, emergencyAddress: record>, shipping: record<status: string, carrier: string, trackingNumber: string, method: record<id: string, name: string>, address: record<customerName: string, additionalCustomerName: string, customerEmail: string, additionalCustomerEmail: string, customerPhone: string, additionalCustomerPhone: string, street: string, street2: string, city: string, state: string, stateId: string, stateIsoCode: string, stateName: string, countryId: string, countryIsoCode: string, country: string, countryName: string, zip: string, taxId: string>>, boxBillingId: int, useAsCommonPhone: bool, hotDeskDevice: bool, inCompanyNet: bool, site: record<id: string, name: string>, lastLocationReportTime: string, linePooling: string, billingStatement: record<currency: string, charges: list<record>, fees: list<record>, totalCharged: float, totalCharges: float, totalFees: float, subtotal: float, totalFreeServiceCredit: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "syncEmergencyAddress" $syncEmergencyAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/device/($deviceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Device
#
# PUT /restapi/v1.0/account/{accountId}/device/{deviceId}
# operationId: updateDevice
# --emergencyServiceAddress shape: {street?: string, street2?: string, city?: string, zip?: string, customerName?: string, state?: string, stateId?: string, country?: string, countryId?: string}
# --emergency shape: {address?: record, location?: record, outOfCountry?: bool, addressStatus?: "Valid"|"Invalid"|"Provisioning", visibility?: "Private"|"Public", syncStatus?: "Verified"|"Updated"|"Deleted"|"NotRequired"|"Unsupported"|"Failed", addressEditableStatus?: "MainDevice"|"AnyDevice"}
# --extension shape: {id?: string}
# --phoneLines shape: {phoneLines?: list}
export def "restapi-v10-account-device updateDevice" [
  accountId: string
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --prestatement: string@bool-completer
  --emergencyServiceAddress: record # Address for emergency cases. The same emergency address is assigned to all numbers of a single device. If the emergency address is also specified in `emergency` resource, then this value is ignored — shape: {street?: string, street2?: string, city?: string, zip?: string, customerName?: string, state?: string, stateId?: string, country?: string, countryId?: string}
  --emergency: record # Device emergency settings — shape: {address?: record, location?: record, outOfCountry?: bool, addressStatus?: "Valid"|"Invalid"|"Provisioning", visibility?: "Private"|"Public", syncStatus?: "Verified"|"Updated"|"Deleted"|"NotRequired"|"Unsupported"|"Failed", addressEditableStatus?: "MainDevice"|"AnyDevice"}
  --extension: record # Information on extension that the device is assigned to — shape: {id?: string}
  --phoneLines: record # Information on phone lines added to a device — shape: {phoneLines?: list}
  --useAsCommonPhone: string@bool-completer # Supported only for devices assigned to Limited extensions. If true, enables users to log in to this phone as a common phone
  --name: string # Device label, maximum number of symbols is 64
]: any -> record<id: string, uri: string, sku: string, type: string, name: string, serial: string, status: string, computerName: string, model: record<id: string, name: string, addons: list<record>, deviceClass: string, features: list<string>, lineCount: int>, extension: record<id: int, uri: string, extensionNumber: string, partnerId: string>, emergency: record<address: record<country: string, countryId: string, countryIsoCode: string, countryName: string, state: string, stateId: string, stateIsoCode: string, stateName: string, city: string, street: string, street2: string, zip: string, customerName: string>, location: record<id: string, name: string, addressFormatId: string>, outOfCountry: bool, addressStatus: string, visibility: string, syncStatus: string, addressEditableStatus: string>, emergencyServiceAddress: record<street: string, street2: string, city: string, zip: string, customerName: string, state: string, stateId: string, stateIsoCode: string, stateName: string, countryId: string, countryIsoCode: string, country: string, countryName: string, outOfCountry: bool, syncStatus: string, additionalCustomerName: string, customerEmail: string, additionalCustomerEmail: string, customerPhone: string, additionalCustomerPhone: string, lineProvisioningStatus: string, taxId: string>, phoneLines: table<id: string, lineType: string, phoneInfo: record, emergencyAddress: record>, shipping: record<status: string, carrier: string, trackingNumber: string, method: record<id: string, name: string>, address: record<customerName: string, additionalCustomerName: string, customerEmail: string, additionalCustomerEmail: string, customerPhone: string, additionalCustomerPhone: string, street: string, street2: string, city: string, state: string, stateId: string, stateIsoCode: string, stateName: string, countryId: string, countryIsoCode: string, country: string, countryName: string, zip: string, taxId: string>>, boxBillingId: int, useAsCommonPhone: bool, hotDeskDevice: bool, inCompanyNet: bool, site: record<id: string, name: string>, lastLocationReportTime: string, linePooling: string, billingStatement: record<currency: string, charges: list<record>, fees: list<record>, totalCharged: float, totalCharges: float, totalFees: float, subtotal: float, totalFreeServiceCredit: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prestatement" $prestatement "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/device/($deviceId)" $qp)
  let body = {emergencyServiceAddress: $emergencyServiceAddress, emergency: $emergency, extension: $extension, phoneLines: $phoneLines, useAsCommonPhone: $useAsCommonPhone, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Device SIP Info
#
# GET /restapi/v1.0/account/{accountId}/device/{deviceId}/sip-info
# operationId: readDeviceSipInfo
export def "restapi-v10-account-device-sip-info readDeviceSipInfo" [
  accountId: string
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<domain: string, outboundProxies: table<region: string, proxy: string, proxyTLS: string>, userName: string, password: string, authorizationId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/device/($deviceId)/sip-info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Device Emergency Info
#
# PUT /restapi/v1.0/account/{accountId}/device/{deviceId}/emergency
# operationId: updateDeviceEmergency
# --emergencyServiceAddress shape: {street?: string, street2?: string, city?: string, zip?: string, customerName?: string, state?: string, stateId?: string, country?: string, countryId?: string}
# --emergency shape: {address?: record, location?: record, outOfCountry?: bool, addressStatus?: "Valid"|"Invalid"|"Provisioning", visibility?: "Private"|"Public", syncStatus?: "Verified"|"Updated"|"Deleted"|"NotRequired"|"Unsupported"|"Failed", addressEditableStatus?: "MainDevice"|"AnyDevice"}
# --extension shape: {id?: string}
# --phoneLines shape: {phoneLines?: list}
export def "restapi-v10-account-device-emergency updateDeviceEmergency" [
  accountId: string
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --emergencyServiceAddress: record # Address for emergency cases. The same emergency address is assigned to all numbers of a single device. If the emergency address is also specified in `emergency` resource, then this value is ignored — shape: {street?: string, street2?: string, city?: string, zip?: string, customerName?: string, state?: string, stateId?: string, country?: string, countryId?: string}
  --emergency: record # Device emergency settings — shape: {address?: record, location?: record, outOfCountry?: bool, addressStatus?: "Valid"|"Invalid"|"Provisioning", visibility?: "Private"|"Public", syncStatus?: "Verified"|"Updated"|"Deleted"|"NotRequired"|"Unsupported"|"Failed", addressEditableStatus?: "MainDevice"|"AnyDevice"}
  --extension: record # Information on extension that the device is assigned to — shape: {id?: string}
  --phoneLines: record # Information on phone lines added to a device — shape: {phoneLines?: list}
  --useAsCommonPhone: string@bool-completer # Supported only for devices assigned to Limited extensions. If true, enables users to log in to this phone as a common phone
  --name: string # Device label, maximum number of symbols is 64
]: any -> record<id: string, uri: string, sku: string, type: string, name: string, serial: string, status: string, computerName: string, model: record<id: string, name: string, addons: list<record>, deviceClass: string, features: list<string>, lineCount: int>, extension: record<id: int, uri: string, extensionNumber: string, partnerId: string>, emergency: record<address: record<country: string, countryId: string, countryIsoCode: string, countryName: string, state: string, stateId: string, stateIsoCode: string, stateName: string, city: string, street: string, street2: string, zip: string, customerName: string>, location: record<id: string, name: string, addressFormatId: string>, outOfCountry: bool, addressStatus: string, visibility: string, syncStatus: string, addressEditableStatus: string>, emergencyServiceAddress: record<street: string, street2: string, city: string, zip: string, customerName: string, state: string, stateId: string, stateIsoCode: string, stateName: string, countryId: string, countryIsoCode: string, country: string, countryName: string, outOfCountry: bool, syncStatus: string, additionalCustomerName: string, customerEmail: string, additionalCustomerEmail: string, customerPhone: string, additionalCustomerPhone: string, lineProvisioningStatus: string, taxId: string>, phoneLines: table<id: string, lineType: string, phoneInfo: record, emergencyAddress: record>, shipping: record<status: string, carrier: string, trackingNumber: string, method: record<id: string, name: string>, address: record<customerName: string, additionalCustomerName: string, customerEmail: string, additionalCustomerEmail: string, customerPhone: string, additionalCustomerPhone: string, street: string, street2: string, city: string, state: string, stateId: string, stateIsoCode: string, stateName: string, countryId: string, countryIsoCode: string, country: string, countryName: string, zip: string, taxId: string>>, boxBillingId: int, useAsCommonPhone: bool, hotDeskDevice: bool, inCompanyNet: bool, site: record<id: string, name: string>, lastLocationReportTime: string, linePooling: string, billingStatement: record<currency: string, charges: list<record>, fees: list<record>, totalCharged: float, totalCharges: float, totalFees: float, subtotal: float, totalFreeServiceCredit: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/device/($deviceId)/emergency")
  let body = {emergencyServiceAddress: $emergencyServiceAddress, emergency: $emergency, extension: $extension, phoneLines: $phoneLines, useAsCommonPhone: $useAsCommonPhone, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Custom Field List
#
# GET /restapi/v1.0/account/{accountId}/custom-fields
# operationId: listCustomFields
export def "restapi-v10-account-custom-fields listCustomFields" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<records: table<id: string, category: string, displayName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/custom-fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Custom Field
#
# POST /restapi/v1.0/account/{accountId}/custom-fields
# operationId: createCustomField
export def "restapi-v10-account-custom-fields createCustomField" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --category: string@category-completer # Object category to attach custom fields
  --displayName: string # Custom field display name
]: any -> record<id: string, category: string, displayName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/custom-fields")
  let body = {category: $category, displayName: $displayName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Custom Field
#
# PUT /restapi/v1.0/account/{accountId}/custom-fields/{fieldId}
# operationId: updateCustomField
export def "restapi-v10-account-custom-fields updateCustomField" [
  accountId: string
  fieldId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --displayName: string # Custom field display name
]: any -> record<id: string, category: string, displayName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/custom-fields/($fieldId)")
  let body = {displayName: $displayName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Custom Field
#
# DELETE /restapi/v1.0/account/{accountId}/custom-fields/{fieldId}
# operationId: deleteCustomField
export def "restapi-v10-account-custom-fields delete" [
  accountId: string
  fieldId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/custom-fields/($fieldId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Call Recording Settings
#
# GET /restapi/v1.0/account/{accountId}/call-recording
# operationId: readCallRecordingSettings
export def "restapi-v10-account-call-recording readCallRecordingSettings" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<onDemand: record<enabled: bool, retentionPeriod: int>, automatic: record<enabled: bool, outboundCallTones: bool, outboundCallAnnouncement: bool, allowMute: bool, extensionCount: int, retentionPeriod: int, maxNumberLimit: int>, greetings: table<type: string, mode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-recording")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Call Recording Settings
#
# PUT /restapi/v1.0/account/{accountId}/call-recording
# operationId: updateCallRecordingSettings
# --onDemand shape: {enabled?: bool, retentionPeriod?: int}
# --automatic shape: {enabled?: bool, outboundCallTones?: bool, outboundCallAnnouncement?: bool, allowMute?: bool, extensionCount?: int, retentionPeriod?: int, maxNumberLimit?: int}
# --greetings item shape: {type?: "StartRecording"|"StopRecording"|"AutomaticRecording", mode?: "Default"|"Custom"}
export def "restapi-v10-account-call-recording updateCallRecordingSettings" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --onDemand: record # shape: {enabled?: bool, retentionPeriod?: int}
  --automatic: record # shape: {enabled?: bool, outboundCallTones?: bool, outboundCallAnnouncement?: bool, allowMute?: bool, extensionCount?: int, retentionPeriod?: int, maxNumberLimit?: int}
  --greetings: list # Collection of Greeting Info — item shape: {type?: "StartRecording"|"StopRecording"|"AutomaticRecording", mode?: "Default"|"Custom"}
]: any -> record<onDemand: record<enabled: bool, retentionPeriod: int>, automatic: record<enabled: bool, outboundCallTones: bool, outboundCallAnnouncement: bool, allowMute: bool, extensionCount: int, retentionPeriod: int, maxNumberLimit: int>, greetings: table<type: string, mode: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-recording")
  let body = {onDemand: $onDemand, automatic: $automatic, greetings: $greetings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Call Recording Custom Greeting List
#
# GET /restapi/v1.0/account/{accountId}/call-recording/custom-greetings
# operationId: listCallRecordingCustomGreetings
export def "restapi-v10-account-call-recording-custom-greetings listCallRecordingCustomGreetings" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-5
]: nothing -> record<records: table<type: string, custom: record, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-recording/custom-greetings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Call Recording Custom Greeting List
#
# DELETE /restapi/v1.0/account/{accountId}/call-recording/custom-greetings
# operationId: deleteCallRecordingCustomGreetingList
export def "restapi-v10-account-call-recording-custom-greetings delete-by-accountId" [
  accountId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-recording/custom-greetings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Call Recording Custom Greeting
#
# DELETE /restapi/v1.0/account/{accountId}/call-recording/custom-greetings/{greetingId}
# operationId: deleteCallRecordingCustomGreeting
export def "restapi-v10-account-call-recording-custom-greetings delete-by-accountId-greetingId" [
  accountId: string
  greetingId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-recording/custom-greetings/($greetingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Call Recording Extension List
#
# POST /restapi/v1.0/account/{accountId}/call-recording/bulk-assign
# operationId: updateCallRecordingExtensionList
# --addedExtensions item shape: {id?: string, uri?: string, extensionNumber?: string, type?: string, callDirection?: "Outbound"|"Inbound"|"All"}
# --updatedExtensions item shape: {id?: string, uri?: string, extensionNumber?: string, type?: string, callDirection?: "Outbound"|"Inbound"|"All"}
# --removedExtensions item shape: {id?: string, uri?: string, extensionNumber?: string, type?: string, callDirection?: "Outbound"|"Inbound"|"All"}
export def "restapi-v10-account-call-recording-bulk-assign updateCallRecordingExtensionList" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --addedExtensions: list # item shape: {id?: string, uri?: string, extensionNumber?: string, type?: string, callDirection?: "Outbound"|"Inbound"|"All"}
  --updatedExtensions: list # item shape: {id?: string, uri?: string, extensionNumber?: string, type?: string, callDirection?: "Outbound"|"Inbound"|"All"}
  --removedExtensions: list # item shape: {id?: string, uri?: string, extensionNumber?: string, type?: string, callDirection?: "Outbound"|"Inbound"|"All"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-recording/bulk-assign")
  let body = {addedExtensions: $addedExtensions, updatedExtensions: $updatedExtensions, removedExtensions: $removedExtensions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Call Recording Extension List
#
# GET /restapi/v1.0/account/{accountId}/call-recording/extensions
# operationId: listCallRecordingExtensions
export def "restapi-v10-account-call-recording-extensions listCallRecordingExtensions" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, records: table<id: string, uri: string, extensionNumber: string, name: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-recording/extensions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Make CallOut
#
# POST /restapi/v1.0/account/{accountId}/telephony/call-out
# operationId: createCallOutCallSession
# --from shape: {deviceId?: string}
# --to shape: {phoneNumber?: string, extensionNumber?: string}
export def "restapi-v10-account-telephony-call-out createCallOutCallSession" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-from: record # Instance id of the caller. It corresponds to the 1st leg of the CallOut call. — shape: {deviceId?: string}
  --body-to: record # Phone number of the called party. This number corresponds to the 2nd leg of a CallOut call — shape: {phoneNumber?: string, extensionNumber?: string}
  --countryId: int # Optional. Dialing plan country data. If not specified, then extension home country is applied by default. (format: int64)
]: any -> record<session: record<id: string, origin: record<type: string>, voiceCallToken: string, parties: list<record>, creationTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/call-out")
  let body = {from: $body_from, to: $body_to, countryId: $countryId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start Conference Call Session
#
# POST /restapi/v1.0/account/{accountId}/telephony/conference
# operationId: createConferenceCallSession
export def "restapi-v10-account-telephony-conference createConferenceCallSession" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<session: record<id: string, origin: record<type: string>, voiceCallToken: string, parties: list<record>, creationTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/conference")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Call Session Status
#
# GET /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}
# operationId: readCallSessionStatus
export def "restapi-v10-account-telephony-sessions readCallSessionStatus" [
  accountId: string
  telephonySessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timestamp: string # The date and time of a call session latest change
  --timeout: string # The time frame of awaiting for a status change before sending the resulting one in response
]: nothing -> record<id: string, origin: record<type: string>, voiceCallToken: string, parties: table<id: string, status: record, muted: bool, standAlone: bool, park: record, from: record, to: record, owner: record, direction: string, conferenceRole: string, ringOutRole: string, ringMeRole: string, recordings: list>, creationTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Drop Call Session
#
# DELETE /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}
# operationId: deleteCallSession
export def "restapi-v10-account-telephony-sessions delete" [
  accountId: string
  telephonySessionId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bring-In Call Party
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/bring-in
# operationId: createCallPartyWithBringIn
export def "restapi-v10-account-telephony-sessions-parties-bring-in createCallPartyWithBringIn" [
  accountId: string
  telephonySessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sessionId: string # Internal identifier of a call session
  partyId: string # Internal identifier of a party that should be added to the call session
]: any -> record<id: string, status: record<code: string, peerId: record<sessionId: string, telephonySessionId: string, partyId: string>, reason: string, description: string>, muted: bool, standAlone: bool, park: record<id: string>, from: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, to: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, owner: record<accountId: string, extensionId: string>, direction: string, conferenceRole: string, ringOutRole: string, ringMeRole: string, recordings: table<id: string, active: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/bring-in")
  let body = {sessionId: $sessionId, partyId: $partyId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Call Party Status
#
# GET /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}
# operationId: readCallPartyStatus
export def "restapi-v10-account-telephony-sessions-parties readCallPartyStatus" [
  accountId: string
  telephonySessionId: string
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: record<code: string, peerId: record<sessionId: string, telephonySessionId: string, partyId: string>, reason: string, description: string>, muted: bool, standAlone: bool, park: record<id: string>, from: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, to: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, owner: record<accountId: string, extensionId: string>, direction: string, conferenceRole: string, ringOutRole: string, ringMeRole: string, recordings: table<id: string, active: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Call Party
#
# DELETE /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}
# operationId: deleteCallParty
export def "restapi-v10-account-telephony-sessions-parties delete" [
  accountId: string
  telephonySessionId: string
  partyId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Call Party
#
# PATCH /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}
# operationId: updateCallParty
# --party shape: {muted?: bool, standAlone?: bool}
export def "restapi-v10-account-telephony-sessions-parties updateCallParty" [
  accountId: string
  telephonySessionId: string
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --party: record # Party update data — shape: {muted?: bool, standAlone?: bool}
]: any -> record<id: string, status: record<code: string, peerId: record<sessionId: string, telephonySessionId: string, partyId: string>, reason: string, description: string>, muted: bool, standAlone: bool, park: record<id: string>, from: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, to: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, owner: record<accountId: string, extensionId: string>, direction: string, conferenceRole: string, ringOutRole: string, ringMeRole: string, recordings: table<id: string, active: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)")
  let body = {party: $party} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Un-hold Call Party
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}/unhold
# operationId: unholdCallParty
export def "restapi-v10-account-telephony-sessions-parties-unhold unholdCallParty" [
  accountId: string
  telephonySessionId: string
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: record<code: string, peerId: record<sessionId: string, telephonySessionId: string, partyId: string>, reason: string, description: string>, muted: bool, standAlone: bool, park: record<id: string>, from: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, to: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, owner: record<accountId: string, extensionId: string>, direction: string, conferenceRole: string, ringOutRole: string, ringMeRole: string, recordings: table<id: string, active: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)/unhold")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Call Park
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}/park
# operationId: callParkParty
export def "restapi-v10-account-telephony-sessions-parties-park callParkParty" [
  accountId: string
  telephonySessionId: string
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: record<code: string, peerId: record<sessionId: string, telephonySessionId: string, partyId: string>, reason: string, description: string>, muted: bool, standAlone: bool, park: record<id: string>, from: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, to: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, owner: record<accountId: string, extensionId: string>, direction: string, conferenceRole: string, ringOutRole: string, ringMeRole: string, recordings: table<id: string, active: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)/park")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Call Flip on Party
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}/flip
# operationId: callFlipParty
export def "restapi-v10-account-telephony-sessions-parties-flip callFlipParty" [
  accountId: string
  telephonySessionId: string
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --callFlipId: string # Call flip id
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)/flip")
  let body = {callFlipId: $callFlipId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reply with Text
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}/reply
# operationId: replyParty
# --replyWithPattern shape: {pattern?: "WillCallYouBack"|"CallMeBack"|"OnMyWay"|"OnTheOtherLine"|"WillCallYouBackLater"|"CallMeBackLater"|"InAMeeting"|"OnTheOtherLineNoCall", time?: int, timeUnit?: "Minute"|"Hour"|"Day"}
export def "restapi-v10-account-telephony-sessions-parties-reply replyParty" [
  accountId: string
  telephonySessionId: string
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --replyWithText: string # Text to reply
  --replyWithPattern: record # shape: {pattern?: "WillCallYouBack"|"CallMeBack"|"OnMyWay"|"OnTheOtherLine"|"WillCallYouBackLater"|"CallMeBackLater"|"InAMeeting"|"OnTheOtherLineNoCall", time?: int, timeUnit?: "Minute"|"Hour"|"Day"}
]: any -> record<id: string, status: record<code: string, peerId: record<sessionId: string, telephonySessionId: string, partyId: string>, reason: string, description: string>, muted: bool, standAlone: bool, park: record<id: string>, from: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, to: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, owner: record<accountId: string, extensionId: string>, direction: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)/reply")
  let body = {replyWithText: $replyWithText, replyWithPattern: $replyWithPattern} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bridge Call Party
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}/bridge
# operationId: bridgeCallParty
export def "restapi-v10-account-telephony-sessions-parties-bridge bridgeCallParty" [
  accountId: string
  telephonySessionId: string
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-telephonySessionId: string # Internal identifier of a call session to be connected to (bridged)
  --body-partyId: string # Internal identifier of a call party to be connected to (bridged)
]: any -> record<id: string, status: record<code: string, peerId: record<sessionId: string, telephonySessionId: string, partyId: string>, reason: string, description: string>, muted: bool, standAlone: bool, park: record<id: string>, from: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, to: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, owner: record<accountId: string, extensionId: string>, direction: string, conferenceRole: string, ringOutRole: string, ringMeRole: string, recordings: table<id: string, active: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)/bridge")
  let body = {telephonySessionId: $body_telephonySessionId, partyId: $body_partyId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Ignore Call in Queue
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}/ignore
# operationId: ignoreCallInQueue
export def "restapi-v10-account-telephony-sessions-parties-ignore ignoreCallInQueue" [
  accountId: string
  telephonySessionId: string
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  deviceId: string # Internal device identifier (e.g. 400020454008)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)/ignore")
  let body = {deviceId: $deviceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Supervise Call Party
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}/supervise
# operationId: superviseCallParty
export def "restapi-v10-account-telephony-sessions-parties-supervise superviseCallParty" [
  accountId: string
  telephonySessionId: string
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  mode: string@mode-completer # Supervising mode (e.g. Listen)
  supervisorDeviceId: string # Internal identifier of a supervisor's device (e.g. 191888004)
  agentExtensionId: string # Mailbox ID of a user that will be monitored (e.g. 400378008008)
  --autoAnswer: string@bool-completer # Specifies if auto-answer SIP header should be sent. If auto-answer is set to `true`, the call is automatically answered by the supervising party, if set to `false` - then the supervising party has to accept or decline the monitored call (default: true)
  --mediaSDP: string@mediaSDP-completer # Specifies session description protocol (SDP) setting. The possible values are 'sendOnly' (only sending) meaning one-way audio streaming; and 'sendRecv' (sending/receiving) meaning two-way audio streaming
]: any -> record<from: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, to: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, direction: string, id: string, accountId: string, extensionId: string, muted: bool, owner: record<accountId: string, extensionId: string>, standAlone: bool, status: record<code: string, peerId: record<sessionId: string, telephonySessionId: string, partyId: string>, reason: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)/supervise")
  let body = {mode: $mode, supervisorDeviceId: $supervisorDeviceId, agentExtensionId: $agentExtensionId, autoAnswer: $autoAnswer, mediaSDP: $mediaSDP} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reject Call Party
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}/reject
# operationId: rejectParty
export def "restapi-v10-account-telephony-sessions-parties-reject rejectParty" [
  accountId: string
  telephonySessionId: string
  partyId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)/reject")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Recording
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}/recordings
# operationId: startCallRecording
export def "restapi-v10-account-telephony-sessions-parties-recordings startCallRecording" [
  accountId: string
  telephonySessionId: string
  partyId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)/recordings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause/Resume Recording
#
# PATCH /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}/recordings/{recordingId}
# operationId: pauseResumeCallRecording
export def "restapi-v10-account-telephony-sessions-parties-recordings pauseResumeCallRecording" [
  accountId: string
  telephonySessionId: string
  partyId: string
  recordingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --brandId: string # Identifies a brand of a logged-in user or a brand of a sign-up session (default: ~)
  --active: string@bool-completer # Recording status
]: any -> record<id: string, active: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "brandId" $brandId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)/recordings/($recordingId)" $qp)
  let body = {active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Answer Call Party
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}/answer
# operationId: answerCallParty
export def "restapi-v10-account-telephony-sessions-parties-answer answerCallParty" [
  accountId: string
  telephonySessionId: string
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deviceId: string # Device ID that is used to answer to incoming call. (e.g. 400018633008)
]: any -> record<id: string, status: record<code: string, peerId: record<sessionId: string, telephonySessionId: string, partyId: string>, reason: string, description: string>, muted: bool, standAlone: bool, park: record<id: string>, from: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, to: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, owner: record<accountId: string, extensionId: string>, direction: string, conferenceRole: string, ringOutRole: string, ringMeRole: string, recordings: table<id: string, active: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)/answer")
  let body = {deviceId: $deviceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Transfer Call Party
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}/transfer
# operationId: transferCallParty
export def "restapi-v10-account-telephony-sessions-parties-transfer transferCallParty" [
  accountId: string
  telephonySessionId: string
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --phoneNumber: string # Phone number
  --voicemail: string # Voicemail owner extension identifier
  --parkOrbit: string # Park orbit identifier
  --extensionNumber: string # Extension short number
]: any -> record<id: string, status: record<code: string, peerId: record<sessionId: string, telephonySessionId: string, partyId: string>, reason: string, description: string>, muted: bool, standAlone: bool, park: record<id: string>, from: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, to: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, owner: record<accountId: string, extensionId: string>, direction: string, conferenceRole: string, ringOutRole: string, ringMeRole: string, recordings: table<id: string, active: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)/transfer")
  let body = {phoneNumber: $phoneNumber, voicemail: $voicemail, parkOrbit: $parkOrbit, extensionNumber: $extensionNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Hold Call Party
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}/hold
# operationId: holdCallParty
export def "restapi-v10-account-telephony-sessions-parties-hold holdCallParty" [
  accountId: string
  telephonySessionId: string
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --proto: string@proto-completer # Protocol for hold mode initiation (default: Auto)
]: any -> record<id: string, status: record<code: string, peerId: record<sessionId: string, telephonySessionId: string, partyId: string>, reason: string, description: string>, muted: bool, standAlone: bool, park: record<id: string>, from: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, to: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, owner: record<accountId: string, extensionId: string>, direction: string, conferenceRole: string, ringOutRole: string, ringMeRole: string, recordings: table<id: string, active: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)/hold")
  let body = {proto: $proto} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Pickup Call
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}/pickup
# operationId: pickupCallParty
export def "restapi-v10-account-telephony-sessions-parties-pickup pickupCallParty" [
  accountId: string
  telephonySessionId: string
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  deviceId: string # Device identifier that is used to pick up the parked call. (e.g. 400018633008)
]: any -> record<id: string, status: record<code: string, peerId: record<sessionId: string, telephonySessionId: string, partyId: string>, reason: string, description: string>, muted: bool, standAlone: bool, park: record<id: string>, from: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, to: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, owner: record<accountId: string, extensionId: string>, direction: string, conferenceRole: string, ringOutRole: string, ringMeRole: string, recordings: table<id: string, active: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)/pickup")
  let body = {deviceId: $deviceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Forward Call Party
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/parties/{partyId}/forward
# operationId: forwardCallParty
export def "restapi-v10-account-telephony-sessions-parties-forward forwardCallParty" [
  accountId: string
  telephonySessionId: string
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --phoneNumber: string # Phone number
  --voicemail: string # Voicemail owner extension identifier
  --extensionNumber: string # Extension short number
]: any -> record<id: string, status: record<code: string, peerId: record<sessionId: string, telephonySessionId: string, partyId: string>, reason: string, description: string>, muted: bool, standAlone: bool, park: record<id: string>, from: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, to: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, owner: record<accountId: string, extensionId: string>, direction: string, conferenceRole: string, ringOutRole: string, ringMeRole: string, recordings: table<id: string, active: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/parties/($partyId)/forward")
  let body = {phoneNumber: $phoneNumber, voicemail: $voicemail, extensionNumber: $extensionNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Supervise Call Session
#
# POST /restapi/v1.0/account/{accountId}/telephony/sessions/{telephonySessionId}/supervise
# operationId: superviseCallSession
export def "restapi-v10-account-telephony-sessions-supervise superviseCallSession" [
  accountId: string
  telephonySessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  mode: string@mode-completer # Supervising mode (e.g. Listen)
  supervisorDeviceId: string # Internal identifier of a supervisor's device which will be used for call session monitoring (e.g. 191888004)
  --agentExtensionId: string # Extension identifier of the user that will be monitored (e.g. 400378008008)
  --autoAnswer: string@bool-completer # Specifies if auto-answer SIP header should be sent. If auto-answer is set to `true`, the call is automatically answered by the supervising party, if set to `false` - then the supervising party has to accept or decline the monitored call (default: true)
  --mediaSDP: string@mediaSDP-completer # Specifies session description protocol setting
]: any -> record<from: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, to: record<phoneNumber: string, name: string, deviceId: string, extensionId: string>, direction: string, id: string, accountId: string, extensionId: string, muted: bool, owner: record<accountId: string, extensionId: string>, standAlone: bool, status: record<code: string, peerId: record<sessionId: string, telephonySessionId: string, partyId: string>, reason: string, description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/telephony/sessions/($telephonySessionId)/supervise")
  let body = {mode: $mode, supervisorDeviceId: $supervisorDeviceId, agentExtensionId: $agentExtensionId, autoAnswer: $autoAnswer, mediaSDP: $mediaSDP} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Account Service Info
#
# GET /restapi/v1.0/account/{accountId}/service-info
# operationId: readAccountServiceInfo
export def "restapi-v10-account-service-info readAccountServiceInfo" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, servicePlanName: string, brand: record<id: string, name: string, homeCountry: record<isoCode: string, callingCode: string>>, contractedCountry: record<isoCode: string, callingCode: string>, servicePlan: record<id: string, name: string, edition: string, freemiumProductType: string>, targetServicePlan: record<id: string, name: string, edition: string, freemiumProductType: string>, billingPlan: record<id: string, name: string, durationUnit: string, duration: int, type: string, includedPhoneLines: int>, serviceFeatures: table<featureName: string, enabled: bool>, limits: record<freeSoftPhoneLinesPerExtension: int, meetingSize: int, cloudRecordingStorage: int, maxMonitoredExtensionsPerUser: int, maxExtensionNumberLength: int, siteCodeLength: int, shortExtensionNumberLength: int>, package: record<version: string, id: string>, uBrand: record<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/service-info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Company Message Template
#
# POST /restapi/v1.0/account/{accountId}/message-store-templates
# operationId: createCompanyMessageTemplate
# --body shape: {text: string}
# --site shape: {id?: string, name?: string}
export def "restapi-v10-account-message-store-templates createCompanyMessageTemplate" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  displayName: string # Name of a template
  --body-body: record # Text message template information — shape: {text: string}
  --site: record # Specifies a site that message template is associated with. Supported only if the Sites feature is enabled.  The default is `main-site` value. — shape: {id?: string, name?: string}
]: any -> record<id: string, displayName: string, body: record<text: string>, scope: string, site: record<id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/message-store-templates")
  let body = {displayName: $displayName, body: $body_body, site: $site} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Company Message Templates
#
# GET /restapi/v1.0/account/{accountId}/message-store-templates
# operationId: listCompanyMessageTemplates
export def "restapi-v10-account-message-store-templates listCompanyMessageTemplates" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --siteIds: list # Site ID(s) to filter company message templates, associated with particular sites By default the value is all - templates with all sites will be returned
]: nothing -> record<records: table<id: string, displayName: string, body: record, scope: string, site: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "siteIds" $siteIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/message-store-templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Company Message Template
#
# PUT /restapi/v1.0/account/{accountId}/message-store-templates/{templateId}
# operationId: updateCompanyMessageTemplate
# --body shape: {text: string}
# --site shape: {id?: string, name?: string}
export def "restapi-v10-account-message-store-templates updateCompanyMessageTemplate" [
  accountId: string
  templateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  displayName: string # Name of a template
  --body-body: record # Text message template information — shape: {text: string}
  --site: record # Specifies a site that message template is associated with. Supported only if the Sites feature is enabled.  The default is `main-site` value. — shape: {id?: string, name?: string}
]: any -> record<id: string, displayName: string, body: record<text: string>, scope: string, site: record<id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/message-store-templates/($templateId)")
  let body = {displayName: $displayName, body: $body_body, site: $site} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Company Message Template
#
# GET /restapi/v1.0/account/{accountId}/message-store-templates/{templateId}
# operationId: readCompanyMessageTemplate
export def "restapi-v10-account-message-store-templates readCompanyMessageTemplate" [
  accountId: string
  templateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, displayName: string, body: record<text: string>, scope: string, site: record<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/message-store-templates/($templateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Company Message Template
#
# DELETE /restapi/v1.0/account/{accountId}/message-store-templates/{templateId}
# operationId: deleteCompanyMessageTemplate
export def "restapi-v10-account-message-store-templates delete" [
  accountId: string
  templateId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/message-store-templates/($templateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Company Call Records
#
# GET /restapi/v1.0/account/{accountId}/call-log
# operationId: readCompanyCallLog
@deprecated --flag withRecording
export def "restapi-v10-account-call-log readCompanyCallLog" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extensionNumber: string # Short extension number of a user. If specified, returns call log for this particular extension only. Cannot be combined with `phoneNumber` filter  (e.g. 101)
  --phoneNumber: string # Phone number of a caller/callee in e.164 format without a '+' sign. If specified, all incoming/outgoing calls from/to this phone number are returned.  (e.g. 12053320032)
  --direction: list # The direction of call records to be included in the result. If omitted, both inbound and outbound calls are returned. Multiple values are supported
  --type: list # The type of call records to be included in the result. If omitted, all call types are returned. Multiple values are supported
  --view: string@view-completer # Defines the level of details for returned call records  (default: Simple)
  --withRecording: string@bool-completer # Deprecated, replaced with `recordingType` filter, still supported for compatibility reasons. Indicates if only recorded calls should be returned.  If both `withRecording` and `recordingType` parameters are specified, then `withRecording` is ignored  (DEPRECATED, default: false)
  --recordingType: string@recordingType-completer # Indicates that call records with recordings of particular type should be returned. If omitted, then calls with and without recordings are returned
  --dateFrom: string # The beginning of the time range to return call records in ISO 8601 format including timezone, for example 2016-03-10T18:07:52.534Z. The default value is `dateTo` minus 24 hours  (format: date-time)
  --dateTo: string # The end of the time range to return call records in ISO 8601 format including timezone, for example 2016-03-10T18:07:52.534Z. The default value is current time  (format: date-time)
  --sessionId: string # Internal identifier of a call session
  --telephonySessionId: string # Internal identifier of a telephony session
  --page: int # Indicates the page number to retrieve. Only positive number values are accepted (format: int32, default: 1)
  --perPage: int # Indicates the page size (number of items) (format: int32, default: 100)
]: nothing -> record<uri: string, records: table<extension: record, telephonySessionId: string, sipUuidInfo: string, transferTarget: record, transferee: record, partyId: string, transport: string, from: record, to: record, type: string, direction: string, message: record, delegate: record, delegationType: string, action: string, result: string, reason: string, reasonDescription: string, startTime: string, duration: int, durationMs: int, recording: record, shortRecording: bool, billing: record, internalType: string, id: string, uri: string, sessionId: string, deleted: bool, legs: list, lastModifiedTime: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extensionNumber" $extensionNumber "scalar") (serialize-qp "phoneNumber" $phoneNumber "scalar") (serialize-qp "direction" $direction "multi") (serialize-qp "type" $type "multi") (serialize-qp "view" $view "scalar") (serialize-qp "withRecording" $withRecording "scalar") (serialize-qp "recordingType" $recordingType "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "sessionId" $sessionId "scalar") (serialize-qp "telephonySessionId" $telephonySessionId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Company Call Record(s)
#
# GET /restapi/v1.0/account/{accountId}/call-log/{callRecordId}
# operationId: readCompanyCallRecord
export def "restapi-v10-account-call-log readCompanyCallRecord" [
  accountId: string
  callRecordId: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --view: string@view-completer # Defines the level of details for returned call records  (default: Simple)
]: nothing -> record<extension: record<id: int, uri: string>, telephonySessionId: string, sipUuidInfo: string, transferTarget: record<telephonySessionId: string>, transferee: record<telephonySessionId: string>, partyId: string, transport: string, from: record<dialerPhoneNumber: string>, to: record<dialedPhoneNumber: string>, type: string, direction: string, message: record<id: string, type: string, uri: string>, delegate: record<id: string, name: string>, delegationType: string, action: string, result: string, reason: string, reasonDescription: string, startTime: string, duration: int, durationMs: int, recording: record<id: string, uri: string, type: string, contentUri: string>, shortRecording: bool, billing: record<costIncluded: float, costPurchased: float>, internalType: string, id: string, uri: string, sessionId: string, deleted: bool, legs: table<extension: record, telephonySessionId: string, sipUuidInfo: string, transferTarget: record, transferee: record, partyId: string, transport: string, from: record, to: record, type: string, direction: string, message: record, delegate: record, delegationType: string, action: string, result: string, reason: string, reasonDescription: string, startTime: string, duration: int, durationMs: int, recording: record, shortRecording: bool, billing: record, internalType: string, legType: string, master: bool>, lastModifiedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-log/($callRecordId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sync Company Call Log
#
# GET /restapi/v1.0/account/{accountId}/call-log-sync
# operationId: syncAccountCallLog
@deprecated --flag withRecording
export def "restapi-v10-account-call-log-sync syncAccountCallLog" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --syncType: string # Type of call log synchronization request
  --syncToken: string # Value of syncToken property of last sync request response. Mandatory parameter for 'ISync' sync type
  --dateFrom: string # The start datetime for resulting records in ISO 8601 format including timezone, for example 2016-03-10T18:07:52.534Z. The default value is the current moment (format: date-time)
  --recordCount: int # For `FSync` mode this parameter is mandatory, it limits the number of records to be returned in response.  For `ISync` mode this parameter specifies the number of records to extend the sync frame with to the past (the maximum number of records is 250)  (format: int32)
  --statusGroup: list # Type of calls to be returned
  --view: string@view-completer # Defines the level of details for returned call records  (default: Simple)
  --showDeleted: string@bool-completer # Supported for `ISync` mode. Indicates that deleted call records should be returned (default: false)
  --withRecording: string@bool-completer # Deprecated, replaced with `recordingType` filter, still supported for compatibility reasons. Indicates if only recorded calls should be returned.  If both `withRecording` and `recordingType` parameters are specified, then `withRecording` is ignored  (DEPRECATED, default: false)
  --recordingType: string@recordingType-completer # Indicates that call records with recordings of particular type should be returned. If omitted, then calls with and without recordings are returned
]: nothing -> record<uri: string, records: table<extension: record, telephonySessionId: string, sipUuidInfo: string, transferTarget: record, transferee: record, partyId: string, transport: string, from: record, to: record, type: string, direction: string, message: record, delegate: record, delegationType: string, action: string, result: string, reason: string, reasonDescription: string, startTime: string, duration: int, durationMs: int, recording: record, shortRecording: bool, billing: record, internalType: string, id: string, uri: string, sessionId: string, deleted: bool, legs: list, lastModifiedTime: string>, syncInfo: record<syncType: string, syncToken: string, syncTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "syncType" $syncType "scalar") (serialize-qp "syncToken" $syncToken "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "recordCount" $recordCount "scalar") (serialize-qp "statusGroup" $statusGroup "multi") (serialize-qp "view" $view "scalar") (serialize-qp "showDeleted" $showDeleted "scalar") (serialize-qp "withRecording" $withRecording "scalar") (serialize-qp "recordingType" $recordingType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-log-sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Company Active Calls
#
# GET /restapi/v1.0/account/{accountId}/active-calls
# operationId: listCompanyActiveCalls
export def "restapi-v10-account-active-calls listCompanyActiveCalls" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --direction: list # The direction of call records to be included in the result. If omitted, both inbound and outbound calls are returned. Multiple values are supported
  --view: string@view-completer # Defines the level of details for returned call records  (default: Simple)
  --type: list # The type of call records to be included in the result. If omitted, all call types are returned. Multiple values are supported
  --transport: list # The type of call transport. Multiple values are supported. By default, this filter is disabled
  --conferenceType: list # Conference call type: RCC or RC Meetings. If not specified, no conference call filter applied
  --page: int # Indicates the page number to retrieve. Only positive number values are accepted (format: int32, default: 1)
  --perPage: int # Indicates the page size (number of items) (format: int32, default: 100)
]: nothing -> record<uri: string, records: table<extension: record, telephonySessionId: string, sipUuidInfo: string, transferTarget: record, transferee: record, partyId: string, transport: string, from: record, to: record, type: string, direction: string, message: record, delegate: record, delegationType: string, action: string, result: string, reason: string, reasonDescription: string, startTime: string, duration: int, durationMs: int, recording: record, shortRecording: bool, billing: record, internalType: string, id: string, uri: string, sessionId: string, deleted: bool, legs: list, lastModifiedTime: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "multi") (serialize-qp "view" $view "scalar") (serialize-qp "type" $type "multi") (serialize-qp "transport" $transport "multi") (serialize-qp "conferenceType" $conferenceType "multi") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/active-calls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Multiple Extensions
#
# POST /restapi/v1.0/account/{accountId}/extension-bulk-update
# operationId: extensionBulkUpdate
# --records item shape: {id?: string, status?: "Disabled"|"Enabled"|"NotActivated"|"Frozen", statusInfo?: record, reason?: string, comment?: string, extensionNumber?: string, contact?: record, regionalSettings?: record, setupWizardState?: "NotStarted"|"Incomplete"|"Completed", partnerId?: string, ivrPin?: string, password?: string, callQueueInfo?: record, transition?: record, costCenter?: record, customFields?: list, hidden?: bool, site?: record, type?: "User"|"FaxUser"|"VirtualUser"|"DigitalUser"|"Department"|"Announcement"|"Voicemail"|"SharedLinesGroup"|"PagingOnly"|"IvrMenu"|"ApplicationExtension"|"ParkLocation"|"DelegatedLinesGroup", references?: list}
export def "restapi-v10-account-extension-bulk-update extensionBulkUpdate" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  records: list # item shape: {id?: string, status?: "Disabled"|"Enabled"|"NotActivated"|"Frozen", statusInfo?: record, reason?: string, comment?: string, extensionNumber?: string, contact?: record, regionalSettings?: record, setupWizardState?: "NotStarted"|"Incomplete"|"Completed", partnerId?: string, ivrPin?: string, password?: string, callQueueInfo?: record, transition?: record, costCenter?: record, customFields?: list, hidden?: bool, site?: record, type?: "User"|"FaxUser"|"VirtualUser"|"DigitalUser"|"Department"|"Announcement"|"Voicemail"|"SharedLinesGroup"|"PagingOnly"|"IvrMenu"|"ApplicationExtension"|"ParkLocation"|"DelegatedLinesGroup", references?: list}
]: any -> record<uri: string, id: string, status: string, creationTime: string, lastModifiedTime: string, result: record<affectedItems: list<record>, errors: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension-bulk-update")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Extension Update Task Status
#
# GET /restapi/v1.0/account/{accountId}/extension-bulk-update/tasks/{taskId}
# operationId: getExtensionBulkUpdateTask
export def "restapi-v10-account-extension-bulk-update-tasks get" [
  accountId: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, status: string, creationTime: string, lastModifiedTime: string, result: record<affectedItems: list<record>, errors: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension-bulk-update/tasks/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Templates
#
# GET /restapi/v1.0/account/{accountId}/templates
# operationId: listUserTemplates
export def "restapi-v10-account-templates listUserTemplates" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-6 # Type of template
  --page: int # Indicates a page number to retrieve. Only positive number values are allowed. Default value is '1'  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items). If not specified, the value is '100' by default (format: int32, default: 100)
]: nothing -> record<uri: string, records: table<text: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User Template
#
# GET /restapi/v1.0/account/{accountId}/templates/{templateId}
# operationId: readUserTemplate
export def "restapi-v10-account-templates readUserTemplate" [
  accountId: string
  templateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/templates/($templateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List A2P SMS Statuses
#
# GET /restapi/v1.0/account/{accountId}/a2p-sms/statuses
# operationId: aggregateA2PSMSStatuses
export def "restapi-v10-account-a2p-sms-statuses aggregateA2PSMSStatuses" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --batchId: string # Internal identifier of a message batch to filter the response (e.g. 55577)
  --direction: string@direction-completer # Direction of a message to filter the message list result. By default, there is no filter applied - both Inbound and Outbound messages are returned  (e.g. Inbound)
  --dateFrom: string # The end of the time range to filter the results in ISO 8601 format including timezone. Default is the 'dateTo' minus 24 hours (format: date-time, e.g. 2020-11-09T16:07:52.597Z)
  --dateTo: string # The end of the time range to filter the results in ISO 8601 format including timezone. Default is the current time (format: date-time, e.g. 2020-11-25T16:07:52.597Z)
  --phoneNumber: list # List of phone numbers (specified in 'to' or 'from' fields of a message) to filter the results. Maximum number of phone numbers allowed to be specified as filters is 15 (e.g. [15551234455, 15551235577])
]: nothing -> record<queued: record<cost: float, count: int, errorCodeCounts: record>, delivered: record<cost: float, count: int, errorCodeCounts: record>, deliveryFailed: record<cost: float, count: int, errorCodeCounts: record>, sent: record<cost: float, count: int, errorCodeCounts: record>, sendingFailed: record<cost: float, count: int, errorCodeCounts: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "batchId" $batchId "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "phoneNumber" $phoneNumber "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/a2p-sms/statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List A2P SMS Messages
#
# GET /restapi/v1.0/account/{accountId}/a2p-sms/messages
# operationId: listA2PSMS
export def "restapi-v10-account-a2p-sms-messages listA2PSMS" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --batchId: string # Internal identifier of a message batch to filter the response (e.g. 55577)
  --direction: string@direction-completer # Direction of a message to filter the message list result. By default, there is no filter applied - both Inbound and Outbound messages are returned  (e.g. Inbound)
  --dateFrom: string # The end of the time range to filter the results in ISO 8601 format including timezone. Default is the 'dateTo' minus 24 hours (format: date-time, e.g. 2020-11-09T16:07:52.597Z)
  --dateTo: string # The end of the time range to filter the results in ISO 8601 format including timezone. Default is the current time (format: date-time, e.g. 2020-11-25T16:07:52.597Z)
  --view: string@view-completer # Indicates if the response has to be detailed, includes text in the response if detailed (default: Simple)
  --phoneNumber: list # List of phone numbers (specified in 'to' or 'from' fields of a message) to filter the results. Maximum number of phone numbers allowed to be specified as filters is 15 (e.g. [15551234455, 15551235577])
  --pageToken: string # The page token of the page to be retrieved. (e.g. pgt1)
  --perPage: int # The number of messages to be returned per request (format: int32, default: 1000, e.g. 1)
]: nothing -> record<records: table<id: int, batchId: string, from: string, to: list, creationTime: string, lastModifiedTime: string, messageStatus: string, segmentCount: int, text: string, cost: float, direction: string, errorCode: string>, paging: record<pageToken: string, perPage: int, firstPageToken: string, previousPageToken: string, nextPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "batchId" $batchId "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "phoneNumber" $phoneNumber "multi") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/a2p-sms/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get A2P SMS
#
# GET /restapi/v1.0/account/{accountId}/a2p-sms/messages/{messageId}
# operationId: readA2PSMS
export def "restapi-v10-account-a2p-sms-messages readA2PSMS" [
  accountId: string
  messageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, from: string, to: list<string>, text: string, creationTime: string, lastModifiedTime: string, messageStatus: string, segmentCount: int, cost: float, batchId: string, direction: string, errorCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/a2p-sms/messages/($messageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Opted Out Numbers
#
# GET /restapi/v1.0/account/{accountId}/a2p-sms/opt-outs
# operationId: readA2PSMSOptOuts
export def "restapi-v10-account-a2p-sms-opt-outs readA2PSMSOptOuts" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
  --qp-from: string # The sender's phone number in [E.164](https://www.itu.int/rec/T-REC-E.164-201011-I) format for filtering messages. The asterisk value "*" means any number in `from` field  (e.g. 15551234455)
  --qp-to: string # The receiver's phone number (`to` field) in [E.164](https://www.itu.int/rec/T-REC-E.164-201011-I) format for filtering messages  (e.g. 15551237755)
  --status: string@status-completer-1 # The status (opted out, opted in, or both) to be used as the filter (default: optout, e.g. optout)
  --pageToken: string # The page token of the page to be retrieved (e.g. pgt1)
  --perPage: int # The number of records to be returned for the page (format: int32, default: 1000, e.g. 5)
]: nothing -> record<records: table<from: string, to: string, status: string, source: string>, paging: record<pageToken: string, perPage: int, firstPageToken: string, previousPageToken: string, nextPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/a2p-sms/opt-outs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Opt-In/Out Numbers
#
# POST /restapi/v1.0/account/{accountId}/a2p-sms/opt-outs/bulk-assign
# operationId: addA2PSMSOptOuts
export def "restapi-v10-account-a2p-sms-opt-outs-bulk-assign addA2PSMSOptOuts" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-from: string # The phone number of a sender which the recipients should be opted out from or opted in to (e.g. +15551234455)
  --optOuts: list # The list of phone numbers to be opted out (e.g. [+15551237755, +15551237756])
  --optIns: list # The list of phone numbers to be opted in (e.g. [+15551237799, +15551237798])
]: any -> record<optIns: record<successful: list<string>, failed: list<record>>, optOuts: record<successful: list<string>, failed: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/a2p-sms/opt-outs/bulk-assign")
  let body = {from: $body_from, optOuts: $optOuts, optIns: $optIns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send A2P SMS
#
# POST /restapi/v1.0/account/{accountId}/a2p-sms/batches
# operationId: createA2PSMS
# --messages item shape: {to: list, text?: string}
export def "restapi-v10-account-a2p-sms-batches createA2PSMS" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-from: string # Sender's phone number in [E.164](https://www.itu.int/rec/T-REC-E.164-201011-I) format. (e.g. +15551234567)
  --text: string # Text to send to `messages.to` phone numbers. Can be overridden on a per-message basis (e.g. Hello, World!)
  messages: list # Individual messages — item shape: {to: list, text?: string}
]: any -> record<id: string, from: string, batchSize: int, processedCount: int, lastModifiedTime: string, status: string, creationTime: string, rejected: table<index: int, to: list, errorCode: string, description: string>, cost: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/a2p-sms/batches")
  let body = {from: $body_from, text: $text, messages: $messages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List A2P SMS Batches
#
# GET /restapi/v1.0/account/{accountId}/a2p-sms/batches
# operationId: listA2PBatches
export def "restapi-v10-account-a2p-sms-batches listA2PBatches" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateFrom: string # The end of the time range to filter the results in ISO 8601 format including timezone. Default is the 'dateTo' minus 24 hours (format: date-time, e.g. 2020-11-09T16:07:52.597Z)
  --dateTo: string # The end of the time range to filter the results in ISO 8601 format including timezone. Default is the current time (format: date-time, e.g. 2020-11-25T16:07:52.597Z)
  --qp-from: string # Phone number in E.164 format from which the messages are going to be sent (e.g. 15551234455)
  --status: list # A list of batch statuses to filter the results (e.g. [Queued, Processing])
  --pageToken: string # The page token of the page to be retrieved (e.g. pgt1)
  --perPage: int # The number of records to be returned per page (format: int64, e.g. 1)
]: nothing -> record<records: table<id: string, from: string, batchSize: int, processedCount: int, lastModifiedTime: string, status: string, creationTime: string, rejected: list, cost: float>, paging: record<pageToken: string, perPage: int, firstPageToken: string, previousPageToken: string, nextPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "status" $status "multi") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/a2p-sms/batches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get A2P SMS Batch
#
# GET /restapi/v1.0/account/{accountId}/a2p-sms/batches/{batchId}
# operationId: readA2PBatch
export def "restapi-v10-account-a2p-sms-batches readA2PBatch" [
  accountId: string
  batchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, from: string, batchSize: int, processedCount: int, lastModifiedTime: string, status: string, creationTime: string, rejected: table<index: int, to: list, errorCode: string, description: string>, cost: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/a2p-sms/batches/($batchId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Company Call Handling Rules
#
# GET /restapi/v1.0/account/{accountId}/answering-rule
# operationId: listCompanyAnsweringRules
export def "restapi-v10-account-answering-rule listCompanyAnsweringRules" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The result set page number (1-indexed) to return (format: int32, default: 1, e.g. 1)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
]: nothing -> record<uri: string, records: table<id: string, uri: string, enabled: bool, type: string, name: string, calledNumbers: list, extension: record>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/answering-rule" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Company Call Handling Rule
#
# POST /restapi/v1.0/account/{accountId}/answering-rule
# operationId: createCompanyAnsweringRule
# --callers item shape: {callerId?: string, name?: string}
# --calledNumbers item shape: {id?: string, phoneNumber?: string}
# --schedule shape: {weeklyRanges?: record, ranges?: list, ref?: "BusinessHours"|"AfterHours"}
# --extension shape: {id?: string}
# --greetings item shape: {type?: "Introductory"|"Announcement"|"AutomaticRecording"|"BlockedCallersAll"|"BlockedCallersSpecific"|"BlockedNoCallerId"|"BlockedPayPhones"|"ConnectingMessage"|"ConnectingAudio"|"StartRecording"|"StopRecording"|"Voicemail"|"Unavailable"|"InterruptPrompt"|"HoldMusic"|"Company", preset?: record, custom?: record}
export def "restapi-v10-account-answering-rule createCompanyAnsweringRule" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of an answering rule specified by user. Max number of symbols is 30. The default value is 'My Rule N' where 'N' is the first free number
  --enabled: string@bool-completer # Specifies if the rule is active or inactive. The default value is `true` (default: true)
  --type: string@type-completer-7 # Type of an answering rule, the default value is 'Custom' = ['BusinessHours', 'AfterHours', 'Custom']
  --callers: list # Answering rule will be applied when calls are received from the specified caller(s) — item shape: {callerId?: string, name?: string}
  --calledNumbers: list # Answering rule will be applied when calling the specified number(s) — item shape: {id?: string, phoneNumber?: string}
  --schedule: record # Schedule when an answering rule should be applied — shape: {weeklyRanges?: record, ranges?: list, ref?: "BusinessHours"|"AfterHours"}
  --callHandlingAction: string@callHandlingAction-completer # Specifies how incoming calls are forwarded. The default value is 'Operator' 'Operator' - play company greeting and forward to operator extension 'Disconnect' - play company greeting and disconnect 'Bypass' - bypass greeting to go to selected extension = ['Operator', 'Disconnect', 'Bypass']
  --extension: record # Extension to which the call is forwarded in 'Bypass' mode — shape: {id?: string}
  --greetings: list # Greetings applied for an answering rule; only predefined greetings can be applied, see Dictionary Greeting List — item shape: {type?: "Introductory"|"Announcement"|"AutomaticRecording"|"BlockedCallersAll"|"BlockedCallersSpecific"|"BlockedNoCallerId"|"BlockedPayPhones"|"ConnectingMessage"|"ConnectingAudio"|"StartRecording"|"StopRecording"|"Voicemail"|"Unavailable"|"InterruptPrompt"|"HoldMusic"|"Company", preset?: record, custom?: record}
]: any -> record<id: string, uri: string, enabled: bool, type: string, name: string, callers: table<callerId: string, name: string>, calledNumbers: table<id: string, phoneNumber: string>, schedule: record<weeklyRanges: record<monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, sunday: list>, ranges: list<record>, ref: string>, callHandlingAction: string, extension: record<id: string>, greetings: table<type: string, preset: record, custom: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/answering-rule")
  let body = {name: $name, enabled: $enabled, type: $type, callers: $callers, calledNumbers: $calledNumbers, schedule: $schedule, callHandlingAction: $callHandlingAction, extension: $extension, greetings: $greetings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Company Call Handling Rule
#
# GET /restapi/v1.0/account/{accountId}/answering-rule/{ruleId}
# operationId: readCompanyAnsweringRule
export def "restapi-v10-account-answering-rule readCompanyAnsweringRule" [
  accountId: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uri: string, enabled: bool, type: string, name: string, callers: table<callerId: string, name: string>, calledNumbers: table<id: string, phoneNumber: string>, schedule: record<weeklyRanges: record<monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, sunday: list>, ranges: list<record>, ref: string>, callHandlingAction: string, extension: record<id: string>, greetings: table<type: string, preset: record, custom: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/answering-rule/($ruleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Company Call Handling Rule
#
# PUT /restapi/v1.0/account/{accountId}/answering-rule/{ruleId}
# operationId: updateCompanyAnsweringRule
# --callers item shape: {callerId?: string, name?: string}
# --calledNumbers item shape: {id?: string, phoneNumber?: string}
# --schedule shape: {weeklyRanges?: record, ranges?: list, ref?: "BusinessHours"|"AfterHours"}
# --extension shape: {callerId?: string, name?: string}
# --greetings item shape: {type?: "Introductory"|"Announcement"|"AutomaticRecording"|"BlockedCallersAll"|"BlockedCallersSpecific"|"BlockedNoCallerId"|"BlockedPayPhones"|"ConnectingMessage"|"ConnectingAudio"|"StartRecording"|"StopRecording"|"Voicemail"|"Unavailable"|"InterruptPrompt"|"HoldMusic"|"Company", preset?: record, custom?: record}
export def "restapi-v10-account-answering-rule updateCompanyAnsweringRule" [
  accountId: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Specifies if a rule is active or inactive. The default value is `true` (default: true)
  --name: string # Name of an answering rule specified by user. Max number of symbols is 30. The default value is 'My Rule N' where 'N' is the first free number
  --callers: list # Answering rule will be applied when calls are received from the specified caller(s) — item shape: {callerId?: string, name?: string}
  --calledNumbers: list # Answering rule will be applied when calling the specified number(s) — item shape: {id?: string, phoneNumber?: string}
  --schedule: record # Schedule when an answering rule should be applied — shape: {weeklyRanges?: record, ranges?: list, ref?: "BusinessHours"|"AfterHours"}
  --callHandlingAction: string@callHandlingAction-completer # Specifies how incoming calls are forwarded. The default value is 'Operator' 'Operator' - play company greeting and forward to operator extension 'Disconnect' - play company greeting and disconnect 'Bypass' - bypass greeting to go to selected extension = ['Operator', 'Disconnect','Bypass']
  --type: string@type-completer-7 # Type of an answering rule (default: Custom)
  --extension: record # shape: {callerId?: string, name?: string}
  --greetings: list # Greetings applied for an answering rule; only predefined greetings can be applied, see Dictionary Greeting List — item shape: {type?: "Introductory"|"Announcement"|"AutomaticRecording"|"BlockedCallersAll"|"BlockedCallersSpecific"|"BlockedNoCallerId"|"BlockedPayPhones"|"ConnectingMessage"|"ConnectingAudio"|"StartRecording"|"StopRecording"|"Voicemail"|"Unavailable"|"InterruptPrompt"|"HoldMusic"|"Company", preset?: record, custom?: record}
]: any -> record<id: string, uri: string, enabled: bool, type: string, name: string, callers: table<callerId: string, name: string>, calledNumbers: table<id: string, phoneNumber: string>, schedule: record<weeklyRanges: record<monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, sunday: list>, ranges: list<record>, ref: string>, callHandlingAction: string, extension: record<id: string>, greetings: table<type: string, preset: record, custom: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/answering-rule/($ruleId)")
  let body = {enabled: $enabled, name: $name, callers: $callers, calledNumbers: $calledNumbers, schedule: $schedule, callHandlingAction: $callHandlingAction, type: $type, extension: $extension, greetings: $greetings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Company Call Handling Rule
#
# DELETE /restapi/v1.0/account/{accountId}/answering-rule/{ruleId}
# operationId: deleteCompanyAnsweringRule
export def "restapi-v10-account-answering-rule delete" [
  accountId: string
  ruleId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/answering-rule/($ruleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List IVR Prompts
#
# GET /restapi/v1.0/account/{accountId}/ivr-prompts
# operationId: listIvrPrompts
export def "restapi-v10-account-ivr-prompts listIvrPrompts" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, records: table<uri: string, id: string, contentType: string, contentUri: string, filename: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/ivr-prompts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create IVR Prompts
#
# POST /restapi/v1.0/account/{accountId}/ivr-prompts
# operationId: createIVRPrompt
export def "restapi-v10-account-ivr-prompts createIVRPrompt" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  attachment: string # Audio file that will be used as a prompt. Attachment cannot be empty, only audio files are supported (format: binary)
  --name: string # Description of file contents.
]: any -> record<uri: string, id: string, contentType: string, contentUri: string, filename: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/ivr-prompts")
  let body = {attachment: $attachment, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get IVR Prompt
#
# GET /restapi/v1.0/account/{accountId}/ivr-prompts/{promptId}
# operationId: readIVRPrompt
export def "restapi-v10-account-ivr-prompts readIVRPrompt" [
  accountId: string
  promptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, contentType: string, contentUri: string, filename: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/ivr-prompts/($promptId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update IVR Prompt
#
# PUT /restapi/v1.0/account/{accountId}/ivr-prompts/{promptId}
# operationId: updateIVRPrompt
export def "restapi-v10-account-ivr-prompts updateIVRPrompt" [
  accountId: string
  promptId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filename: string # Name of a file to be uploaded as a prompt
]: any -> record<uri: string, id: string, contentType: string, contentUri: string, filename: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/ivr-prompts/($promptId)")
  let body = {filename: $filename} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete IVR Prompt
#
# DELETE /restapi/v1.0/account/{accountId}/ivr-prompts/{promptId}
# operationId: deleteIVRPrompt
export def "restapi-v10-account-ivr-prompts delete" [
  accountId: string
  promptId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/ivr-prompts/($promptId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload Multiple User Contacts
#
# POST /restapi/v1.0/account/{accountId}/address-book-bulk-upload
# operationId: addressBookBulkUpload
# --records item shape: {extensionId: string, contacts: list}
export def "restapi-v10-account-address-book-bulk-upload addressBookBulkUpload" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  records: list # item shape: {extensionId: string, contacts: list}
]: any -> record<id: string, uri: string, status: string, creationTime: string, lastModifiedTime: string, results: record<affectedItems: list<record>, errors: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/address-book-bulk-upload")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Contacts Upload Task
#
# GET /restapi/v1.0/account/{accountId}/address-book-bulk-upload/tasks/{taskId}
# operationId: getAddressBookBulkUploadTask
export def "restapi-v10-account-address-book-bulk-upload-tasks get" [
  accountId: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uri: string, status: string, creationTime: string, lastModifiedTime: string, results: record<affectedItems: list<record>, errors: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/address-book-bulk-upload/tasks/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Call Queues
#
# GET /restapi/v1.0/account/{accountId}/call-queues
# operationId: listCallQueues
export def "restapi-v10-account-call-queues listCallQueues" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Indicates a page number to retrieve. Only positive number values are accepted (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items) (format: int32, default: 100)
  --memberExtensionId: string # Internal identifier of an extension that is a member of every group within the result
]: nothing -> record<uri: string, records: table<uri: string, id: string, extensionNumber: string, name: string, status: string, subType: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "memberExtensionId" $memberExtensionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-queues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Call Queue
#
# GET /restapi/v1.0/account/{accountId}/call-queues/{groupId}
# operationId: readCallQueueInfo
export def "restapi-v10-account-call-queues readCallQueueInfo" [
  accountId: string
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, extensionNumber: string, name: string, status: string, subType: string, serviceLevelSettings: record<slaGoal: int, slaThresholdSeconds: int, includeAbandonedCalls: bool, abandonedThresholdSeconds: int>, editableMemberStatus: bool, alertTimer: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-queues/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Call Queue
#
# PUT /restapi/v1.0/account/{accountId}/call-queues/{groupId}
# operationId: updateCallQueueInfo
# --serviceLevelSettings shape: {slaGoal?: int, slaThresholdSeconds?: int, includeAbandonedCalls?: bool, abandonedThresholdSeconds?: int}
export def "restapi-v10-account-call-queues updateCallQueueInfo" [
  accountId: string
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uri: string # Link to a call queue (format: uri)
  --id: string # Internal identifier of a call queue
  --extensionNumber: string # Extension number of a call queue
  --name: string # Name of a call queue
  --status: string@status-completer-2 # Call queue status
  --subType: string@subType-completer # Indicates whether it is an emergency call queue extension or not
  --serviceLevelSettings: record # Call queue service level settings — shape: {slaGoal?: int, slaThresholdSeconds?: int, includeAbandonedCalls?: bool, abandonedThresholdSeconds?: int}
  --editableMemberStatus: string@bool-completer # Allows members to change their queue status
  --alertTimer: int@alertTimer-completer # Alert timer or pickup setting. Delay time in seconds before call queue group members are notified when calls are queued  (format: int32)
]: any -> record<uri: string, id: string, extensionNumber: string, name: string, status: string, subType: string, serviceLevelSettings: record<slaGoal: int, slaThresholdSeconds: int, includeAbandonedCalls: bool, abandonedThresholdSeconds: int>, editableMemberStatus: bool, alertTimer: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-queues/($groupId)")
  let body = {uri: $uri, id: $id, extensionNumber: $extensionNumber, name: $name, status: $status, subType: $subType, serviceLevelSettings: $serviceLevelSettings, editableMemberStatus: $editableMemberStatus, alertTimer: $alertTimer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Call Queue Presence
#
# GET /restapi/v1.0/account/{accountId}/call-queues/{groupId}/presence
# operationId: readCallQueuePresence
export def "restapi-v10-account-call-queues-presence readCallQueuePresence" [
  accountId: string
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<records: table<member: record, acceptQueueCalls: bool, acceptCurrentQueueCalls: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-queues/($groupId)/presence")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Call Queue Presence
#
# PUT /restapi/v1.0/account/{accountId}/call-queues/{groupId}/presence
# operationId: updateCallQueuePresence
# --records item shape: {member?: record, acceptCurrentQueueCalls?: bool}
export def "restapi-v10-account-call-queues-presence updateCallQueuePresence" [
  accountId: string
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --records: list # item shape: {member?: record, acceptCurrentQueueCalls?: bool}
]: any -> record<records: table<member: record, acceptQueueCalls: bool, acceptCurrentQueueCalls: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-queues/($groupId)/presence")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign Multiple Call Queue Members
#
# POST /restapi/v1.0/account/{accountId}/call-queues/{groupId}/bulk-assign
# operationId: assignMultipleCallQueueMembers
export def "restapi-v10-account-call-queues-bulk-assign assignMultipleCallQueueMembers" [
  accountId: string
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --addedExtensionIds: list
  --removedExtensionIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-queues/($groupId)/bulk-assign")
  let body = {addedExtensionIds: $addedExtensionIds, removedExtensionIds: $removedExtensionIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Call Queue Members
#
# GET /restapi/v1.0/account/{accountId}/call-queues/{groupId}/members
# operationId: listCallQueueMembers
export def "restapi-v10-account-call-queues-members listCallQueueMembers" [
  accountId: string
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Indicates a page number to retrieve. Only positive number values are allowed  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items) (format: int32, default: 100)
]: nothing -> record<uri: string, records: table<uri: string, id: int, extensionNumber: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-queues/($groupId)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Emergency Locations
#
# GET /restapi/v1.0/account/{accountId}/emergency-locations
# operationId: listEmergencyLocations
export def "restapi-v10-account-emergency-locations listEmergencyLocations" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --siteId: list # Internal identifier of a site for filtering. To indicate company main site `main-site` value should be specified. Supported only if multi-site feature is enabled for the account. Multiple values are supported.
  --searchString: string # Filters entries containing the specified substring in 'address' and 'name' fields. The character range is 0-64; not case-sensitive. If empty then the filter is ignored
  --addressStatus: string
  --usageStatus: string
  --domesticCountryId: string
  --orderBy: string@orderBy-completer # Comma-separated list of fields to order results, prefixed by plus sign '+' (ascending order) or minus sign '-' (descending order)  (default: +address)
  --perPage: int # Indicates a page size (number of items). The values supported: `Max` or numeric value. If not specified, 100 records are returned per one page  (format: int32, default: 100)
  --page: int # Indicates the page number to retrieve. Only positive number values are supported  (format: int32, default: 1)
]: nothing -> record<records: table<id: string, address: any, name: string, site: record, addressStatus: string, usageStatus: string, syncStatus: string, addressType: string, visibility: string, owners: list, addressFormatId: string>, paging: record<page: int, totalPages: int, perPage: int, totalElements: int, pageStart: int, pageEnd: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "siteId" $siteId "multi") (serialize-qp "searchString" $searchString "scalar") (serialize-qp "addressStatus" $addressStatus "scalar") (serialize-qp "usageStatus" $usageStatus "scalar") (serialize-qp "domesticCountryId" $domesticCountryId "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-locations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Emergency Location
#
# POST /restapi/v1.0/account/{accountId}/emergency-locations
# operationId: createEmergencyLocation
# --site shape: {id?: string, name?: string}
export def "restapi-v10-account-emergency-locations createEmergencyLocation" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Internal identifier of an emergency response location
  --address: any
  --name: string # Emergency response location name
  --site: record # shape: {id?: string, name?: string}
  --addressStatus: string@addressStatus-completer # Emergency address status
  --usageStatus: string@usageStatus-completer # Status of an emergency response location usage.
  --addressFormatId: string # Address format ID
  --visibility: string@visibility-completer # Visibility of an emergency response location. If `Private` is set, then a location is visible only for restricted number of users, specified in `owners` array  (default: Public)
  --trusted: string@bool-completer # If 'true' address validation for non-us addresses is skipped
]: any -> record<id: string, address: any, name: string, site: record<id: string, name: string>, addressStatus: string, usageStatus: string, syncStatus: string, addressType: string, visibility: string, owners: table<id: string, extensionNumber: string, name: string>, addressFormatId: string, trusted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-locations")
  let body = {id: $id, address: $address, name: $name, site: $site, addressStatus: $addressStatus, usageStatus: $usageStatus, addressFormatId: $addressFormatId, visibility: $visibility, trusted: $trusted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Emergency Location
#
# GET /restapi/v1.0/account/{accountId}/emergency-locations/{locationId}
# operationId: readEmergencyLocation
export def "restapi-v10-account-emergency-locations readEmergencyLocation" [
  accountId: string
  locationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --syncEmergencyAddress: string@bool-completer
]: nothing -> record<id: string, address: any, name: string, site: record<id: string, name: string>, addressStatus: string, usageStatus: string, syncStatus: string, addressType: string, visibility: string, owners: table<id: string, extensionNumber: string, name: string>, addressFormatId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "syncEmergencyAddress" $syncEmergencyAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-locations/($locationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Emergency Location
#
# PUT /restapi/v1.0/account/{accountId}/emergency-locations/{locationId}
# operationId: updateEmergencyLocation
# --site shape: {id?: string, name?: string}
export def "restapi-v10-account-emergency-locations updateEmergencyLocation" [
  accountId: string
  locationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Internal identifier of an emergency response location
  --address: any
  --name: string # Emergency response location name
  --site: record # shape: {id?: string, name?: string}
  --addressStatus: string@addressStatus-completer # Emergency address status
  --usageStatus: string@usageStatus-completer # Status of an emergency response location usage.
  --addressFormatId: string # Address format ID
  --visibility: string@visibility-completer # Visibility of an emergency response location. If `Private` is set, then a location is visible only for restricted number of users, specified in `owners` array  (default: Public)
  --trusted: string@bool-completer # If 'true' address validation for non-us addresses is skipped
]: any -> record<id: string, address: any, name: string, site: record<id: string, name: string>, addressStatus: string, usageStatus: string, syncStatus: string, addressType: string, visibility: string, owners: table<id: string, extensionNumber: string, name: string>, addressFormatId: string, trusted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-locations/($locationId)")
  let body = {id: $id, address: $address, name: $name, site: $site, addressStatus: $addressStatus, usageStatus: $usageStatus, addressFormatId: $addressFormatId, visibility: $visibility, trusted: $trusted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Emergency Location
#
# DELETE /restapi/v1.0/account/{accountId}/emergency-locations/{locationId}
# operationId: deleteEmergencyLocation
export def "restapi-v10-account-emergency-locations delete" [
  accountId: string
  locationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --validateOnly: string@bool-completer # Flag indicating that validation of emergency location(s) is required before deletion
  --newLocationId: string # Internal identifier of an emergency response location that should be used instead of a deleted one.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validateOnly" $validateOnly "scalar") (serialize-qp "newLocationId" $newLocationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-locations/($locationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Locked Meeting Settings
#
# GET /restapi/v1.0/account/{accountId}/meeting/locked-settings
# DEPRECATED
# operationId: getAccountLockedSetting
@deprecated
export def "restapi-v10-account-meeting-locked-settings get" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<scheduleMeeting: record<startHostVideo: bool, startParticipantVideo: bool, audioOptions: bool, allowJoinBeforeHost: bool, requirePasswordForSchedulingNewMeetings: bool, requirePasswordForInstantMeetings: bool, requirePasswordForPmiMeetings: bool, enforceLogin: bool>, recording: record<localRecording: bool, cloudRecording: bool, autoRecording: bool, cloudRecordingDownload: bool, hostDeleteCloudRecording: bool, accountUserAccessRecording: bool, autoDeleteCmr: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/meeting/locked-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Account-level Meeting Info
#
# GET /restapi/v1.0/account/{accountId}/meeting/{meetingId}
# DEPRECATED
# operationId: readAccountMeeting
@deprecated
export def "restapi-v10-account-meeting readAccountMeeting" [
  accountId: string
  meetingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, uuid: string, id: string, topic: string, meetingType: string, password: string, h323Password: string, status: string, links: record<startUri: string, joinUri: string>, schedule: record<startTime: string, durationInMinutes: int, timeZone: record<uri: string, id: string, name: string, description: string>>, host: record<uri: string, id: string>, allowJoinBeforeHost: bool, startHostVideo: bool, startParticipantsVideo: bool, audioOptions: list<string>, recurrence: record<frequency: string, interval: int, weeklyByDays: list<string>, monthlyByDay: int, monthlyByWeek: string, monthlyByWeekDay: string, count: int, until: string>, autoRecordType: string, enforceLogin: bool, muteParticipantsOnEntry: bool, occurrences: table<id: string, startTime: string, durationInMinutes: int, status: string>, enableWaitingRoom: bool, globalDialInCountries: list<string>, alternativeHosts: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/meeting/($meetingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Department Member List
#
# GET /restapi/v1.0/account/{accountId}/department/{departmentId}/members
# DEPRECATED
# operationId: listDepartmentMembers
@deprecated
export def "restapi-v10-account-department-members listDepartmentMembers" [
  accountId: string
  departmentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Indicates a page number to retrieve. Only positive number values are accepted  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items) (format: int32, default: 100)
]: nothing -> record<uri: string, records: table<id: int, uri: string, name: string, extensionNumber: string, partnerId: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/department/($departmentId)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign Multiple Department Members
#
# POST /restapi/v1.0/account/{accountId}/department/bulk-assign
# DEPRECATED
# operationId: assignMultipleDepartmentMembers
# --items item shape: {departmentId?: string, addedExtensionIds?: list, removedExtensionIds?: list}
@deprecated
export def "restapi-v10-account-department-bulk-assign assignMultipleDepartmentMembers" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --items: list # item shape: {departmentId?: string, addedExtensionIds?: list, removedExtensionIds?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/department/bulk-assign")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get User Presence Status List
#
# GET /restapi/v1.0/account/{accountId}/presence
# operationId: readAccountPresence
export def "restapi-v10-account-presence readAccountPresence" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --detailedTelephonyState: string@bool-completer # Whether to return detailed telephony state
  --sipData: string@bool-completer # Whether to return SIP data
  --page: int # Page number for account presence information (format: int32)
  --perPage: int # Number for account presence information items per page (format: int32)
]: nothing -> record<uri: string, records: table<uri: string, allowSeeMyPresence: bool, callerIdVisibility: string, dndStatus: string, extension: record, message: string, pickUpCallsOnHold: bool, presenceStatus: string, ringOnMonitoredCall: bool, telephonyStatus: string, userStatus: string, meetingStatus: string, activeCalls: list>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<page: int, perPage: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detailedTelephonyState" $detailedTelephonyState "scalar") (serialize-qp "sipData" $sipData "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/presence" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Company Call Recordings
#
# DELETE /restapi/v1.0/account/{accountId}/call-recordings
# operationId: deleteCompanyCallRecordings
export def "restapi-v10-account-call-recordings delete" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  records: list # Call recordings ID(s) to delete
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-recordings")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Company Assigned Roles
#
# GET /restapi/v1.0/account/{accountId}/assigned-role
# operationId: listAssignedRoles
export def "restapi-v10-account-assigned-role listAssignedRoles" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --showHidden: string@bool-completer # Specifies if hidden roles are shown or not
]: nothing -> record<uri: string, records: table<uri: string, extensionId: string, roles: list>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showHidden" $showHidden "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/assigned-role" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Account Meeting Recordings
#
# GET /restapi/v1.0/account/{accountId}/meeting-recordings
# DEPRECATED
# operationId: listAccountMeetingRecordings
@deprecated
export def "restapi-v10-account-meeting-recordings listAccountMeetingRecordings" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --meetingId: string # Internal identifier of a meeting. Either `meetingId` or `meetingStartTime`/`meetingEndTime` can be specified
  --meetingStartTimeFrom: string # Recordings of meetings started after the time specified will be returned. Either `meetingId` or `meetingStartTime`/`meetingEndTime` can be specified  (format: date-time)
  --meetingStartTimeTo: string # Recordings of meetings started before the time specified will be returned. The default value is current time. Either `meetingId` or `meetingStartTime`/`meetingEndTime` can be specified  (format: date-time)
  --page: int # Page number (format: int32)
  --perPage: int # Number of items per page. The `max` value is supported to indicate the maximum size - 300 (format: int32, default: 100)
]: nothing -> record<records: table<meeting: record, recordings: list>, paging: record<page: int, perPage: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meetingId" $meetingId "scalar") (serialize-qp "meetingStartTimeFrom" $meetingStartTimeFrom "scalar") (serialize-qp "meetingStartTimeTo" $meetingStartTimeTo "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/meeting-recordings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Forward All Company Calls
#
# GET /restapi/v1.0/account/{accountId}/forward-all-calls
# operationId: getForwardAllCompanyCalls
export def "restapi-v10-account-forward-all-calls get" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool, ranges: table<from: string, to: string>, callHandlingAction: string, extension: record<id: string, name: string, extensionNumber: string>, reason: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/forward-all-calls")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Forward All Company Calls
#
# PATCH /restapi/v1.0/account/{accountId}/forward-all-calls
# operationId: updateForwardAllCompanyCalls
export def "restapi-v10-account-forward-all-calls updateForwardAllCompanyCalls" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Indicates whether the *Forward All Company Calls* feature is enabled or disabled for an account
]: any -> record<enabled: bool, ranges: table<from: string, to: string>, callHandlingAction: string, extension: record<id: string, name: string, extensionNumber: string>, reason: record<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/forward-all-calls")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Call Monitoring Groups
#
# GET /restapi/v1.0/account/{accountId}/call-monitoring-groups
# operationId: listCallMonitoringGroups
export def "restapi-v10-account-call-monitoring-groups listCallMonitoringGroups" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Indicates a page number to retrieve. Only positive number values are allowed  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items) (format: int32, default: 100)
  --memberExtensionId: string # Internal identifier of an extension that is a member of every group within the result
]: nothing -> record<uri: string, records: table<uri: string, id: string, name: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "memberExtensionId" $memberExtensionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-monitoring-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Call Monitoring Group
#
# POST /restapi/v1.0/account/{accountId}/call-monitoring-groups
# operationId: createCallMonitoringGroup
export def "restapi-v10-account-call-monitoring-groups createCallMonitoringGroup" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of a group
]: any -> record<uri: string, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-monitoring-groups")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Call Monitoring Group
#
# PUT /restapi/v1.0/account/{accountId}/call-monitoring-groups/{groupId}
# operationId: updateCallMonitoringGroup
export def "restapi-v10-account-call-monitoring-groups updateCallMonitoringGroup" [
  accountId: string
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of a group
]: any -> record<uri: string, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-monitoring-groups/($groupId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Call Monitoring Group
#
# DELETE /restapi/v1.0/account/{accountId}/call-monitoring-groups/{groupId}
# operationId: deleteCallMonitoringGroup
export def "restapi-v10-account-call-monitoring-groups delete" [
  accountId: string
  groupId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-monitoring-groups/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Call Monitoring Group List
#
# POST /restapi/v1.0/account/{accountId}/call-monitoring-groups/{groupId}/bulk-assign
# operationId: updateCallMonitoringGroupList
# --addedExtensions item shape: {id?: string, permissions?: list}
# --updatedExtensions item shape: {id?: string, permissions?: list}
# --removedExtensions item shape: {id?: string, permissions?: list}
export def "restapi-v10-account-call-monitoring-groups-bulk-assign updateCallMonitoringGroupList" [
  accountId: string
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --addedExtensions: list # item shape: {id?: string, permissions?: list}
  --updatedExtensions: list # item shape: {id?: string, permissions?: list}
  --removedExtensions: list # item shape: {id?: string, permissions?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-monitoring-groups/($groupId)/bulk-assign")
  let body = {addedExtensions: $addedExtensions, updatedExtensions: $updatedExtensions, removedExtensions: $removedExtensions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Call Monitoring Group Members
#
# GET /restapi/v1.0/account/{accountId}/call-monitoring-groups/{groupId}/members
# operationId: listCallMonitoringGroupMembers
export def "restapi-v10-account-call-monitoring-groups-members listCallMonitoringGroupMembers" [
  accountId: string
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Indicates a page number to retrieve. Only positive number values are allowed  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items) (format: int32, default: 100)
]: nothing -> record<uri: string, records: table<uri: string, id: string, extensionNumber: string, permissions: list>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/call-monitoring-groups/($groupId)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Account Business Address
#
# GET /restapi/v1.0/account/{accountId}/business-address
# operationId: readAccountBusinessAddress
export def "restapi-v10-account-business-address readAccountBusinessAddress" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, businessAddress: record<country: string, state: string, city: string, street: string, zip: string>, company: string, email: string, mainSiteName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/business-address")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Company Business Address
#
# PUT /restapi/v1.0/account/{accountId}/business-address
# operationId: updateAccountBusinessAddress
# --businessAddress shape: {country?: string, state?: string, city?: string, street?: string, zip?: string}
export def "restapi-v10-account-business-address updateAccountBusinessAddress" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --company: string # Company business name
  --email: string # Company business email address (format: email)
  --businessAddress: record # Company business address — shape: {country?: string, state?: string, city?: string, street?: string, zip?: string}
  --mainSiteName: string # Custom site name
]: any -> record<uri: string, businessAddress: record<country: string, state: string, city: string, street: string, zip: string>, company: string, email: string, mainSiteName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/business-address")
  let body = {company: $company, email: $email, businessAddress: $businessAddress, mainSiteName: $mainSiteName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search Audit Trail Data
#
# POST /restapi/v1.0/account/{accountId}/audit-trail/search
# operationId: auditTrailSearch
export def "restapi-v10-account-audit-trail-search auditTrailSearch" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --eventTimeFrom: string # The beginning of the time range to return records in ISO 8601 format in UTC timezone, default is "eventTimeFrom"-24 hours  (format: date-time)
  --eventTimeTo: string # The end of the time range to return records in ISO 8601 format in UTC timezone, default is the current time (format: date-time)
  --initiatorIds: list # List of extension IDs of change initiators.
  --page: int # Page number in the result set (format: int32, e.g. 1)
  --perPage: int # Number of records to be returned per page. (format: int32, e.g. 25)
  --targetIds: list # List of extension (user) IDs affected by this action. (e.g. [404611540004])
  --siteId: string # Site ID to apply as a filter (e.g. 871836004)
  --actionIds: list # List of action IDs (exact keys) to search for (alternatively "excludeActionIds" option can be used). (e.g. [CHANGE_SECRET_INFO, CHANGE_USER_INFO])
  --searchString: string # The (sub)string to search, applied to the following fields:  - initiator.name - initiator.role - initiator.extensionNumber - target.name - target.extensionNumber - details.parameters.value (e.g. 542617)
  --excludeActionIds: list # List of action IDs (exact keys) to exclude from your search (alternatively "actionIds" option can be used). (e.g. [CHANGE_SECRET_INFO, CHANGE_USER_INFO])
]: any -> record<records: table<id: string, eventTime: string, initiator: record, actionId: string, eventType: string, accountId: string, accountName: string, target: record, clientIp: string, comment: string, details: record>, paging: record<page: int, perPage: int, total: int, totalFound: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/audit-trail/search")
  let body = {eventTimeFrom: $eventTimeFrom, eventTimeTo: $eventTimeTo, initiatorIds: $initiatorIds, page: $page, perPage: $perPage, targetIds: $targetIds, siteId: $siteId, actionIds: $actionIds, searchString: $searchString, excludeActionIds: $excludeActionIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get IVR Menu list
#
# GET /restapi/v1.0/account/{accountId}/ivr-menus
# operationId: readIVRMenuList
export def "restapi-v10-account-ivr-menus readIVRMenuList" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, records: table<id: string, uri: string, name: string, extensionNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/ivr-menus")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create IVR Menu
#
# POST /restapi/v1.0/account/{accountId}/ivr-menus
# operationId: createIVRMenu
# --site shape: {id?: string, name?: string}
# --prompt shape: {mode?: "Audio"|"TextToSpeech", audio?: record, text?: string, language?: record}
# --actions item shape: {input?: string, action?: "Connect"|"Voicemail"|"DialByName"|"Transfer"|"Repeat"|"ReturnToRoot"|"ReturnToPrevious"|"Disconnect"|"ReturnToTopLevelMenu"|"DoNothing"|"ConnectToOperator", extension?: record, phoneNumber?: string}
export def "restapi-v10-account-ivr-menus createIVRMenu" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Internal identifier of an IVR Menu extension
  --uri: string # Link to an IVR Menu extension resource (format: uri)
  --name: string # First name of an IVR Menu user
  --extensionNumber: string # Number of an IVR Menu extension
  --site: record # Site data — shape: {id?: string, name?: string}
  --prompt: record # Prompt metadata — shape: {mode?: "Audio"|"TextToSpeech", audio?: record, text?: string, language?: record}
  --actions: list # Keys handling settings — item shape: {input?: string, action?: "Connect"|"Voicemail"|"DialByName"|"Transfer"|"Repeat"|"ReturnToRoot"|"ReturnToPrevious"|"Disconnect"|"ReturnToTopLevelMenu"|"DoNothing"|"ConnectToOperator", extension?: record, phoneNumber?: string}
]: any -> record<id: string, uri: string, name: string, extensionNumber: string, site: record<id: string, name: string>, prompt: record<mode: string, audio: record<uri: string, id: string>, text: string, language: record<uri: string, id: string, name: string, localeCode: string>>, actions: table<input: string, action: string, extension: record, phoneNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/ivr-menus")
  let body = {id: $id, uri: $uri, name: $name, extensionNumber: $extensionNumber, site: $site, prompt: $prompt, actions: $actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get IVR Menu
#
# GET /restapi/v1.0/account/{accountId}/ivr-menus/{ivrMenuId}
# operationId: readIVRMenu
export def "restapi-v10-account-ivr-menus readIVRMenu" [
  accountId: string
  ivrMenuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uri: string, name: string, extensionNumber: string, site: record<id: string, name: string>, prompt: record<mode: string, audio: record<uri: string, id: string>, text: string, language: record<uri: string, id: string, name: string, localeCode: string>>, actions: table<input: string, action: string, extension: record, phoneNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/ivr-menus/($ivrMenuId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update IVR Menu
#
# PUT /restapi/v1.0/account/{accountId}/ivr-menus/{ivrMenuId}
# operationId: updateIVRMenu
# --site shape: {id?: string, name?: string}
# --prompt shape: {mode?: "Audio"|"TextToSpeech", audio?: record, text?: string, language?: record}
# --actions item shape: {input?: string, action?: "Connect"|"Voicemail"|"DialByName"|"Transfer"|"Repeat"|"ReturnToRoot"|"ReturnToPrevious"|"Disconnect"|"ReturnToTopLevelMenu"|"DoNothing"|"ConnectToOperator", extension?: record, phoneNumber?: string}
export def "restapi-v10-account-ivr-menus updateIVRMenu" [
  accountId: string
  ivrMenuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Internal identifier of an IVR Menu extension
  --uri: string # Link to an IVR Menu extension resource (format: uri)
  --name: string # First name of an IVR Menu user
  --extensionNumber: string # Number of an IVR Menu extension
  --site: record # Site data — shape: {id?: string, name?: string}
  --prompt: record # Prompt metadata — shape: {mode?: "Audio"|"TextToSpeech", audio?: record, text?: string, language?: record}
  --actions: list # Keys handling settings — item shape: {input?: string, action?: "Connect"|"Voicemail"|"DialByName"|"Transfer"|"Repeat"|"ReturnToRoot"|"ReturnToPrevious"|"Disconnect"|"ReturnToTopLevelMenu"|"DoNothing"|"ConnectToOperator", extension?: record, phoneNumber?: string}
]: any -> record<id: string, uri: string, name: string, extensionNumber: string, site: record<id: string, name: string>, prompt: record<mode: string, audio: record<uri: string, id: string>, text: string, language: record<uri: string, id: string, name: string, localeCode: string>>, actions: table<input: string, action: string, extension: record, phoneNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/ivr-menus/($ivrMenuId)")
  let body = {id: $id, uri: $uri, name: $name, extensionNumber: $extensionNumber, site: $site, prompt: $prompt, actions: $actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Message Store Report
#
# POST /restapi/v1.0/account/{accountId}/message-store-report
# operationId: createMessageStoreReport
export def "restapi-v10-account-message-store-report createMessageStoreReport" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateTo: string # The end of the time range to collect message records in ISO 8601 format including timezone. Default is the current time  (format: date-time)
  --dateFrom: string # The beginning of the time range to collect call log records in ISO 8601 format including timezone. Default is the current time minus 24 hours  (format: date-time)
  --messageTypes: list # Types of messages to be collected. If not specified, all messages without message type filtering will be returned. Multiple values are accepted (e.g. [Fax, VoiceMail])
]: any -> record<id: string, uri: string, status: string, accountId: string, extensionId: string, dateTo: string, dateFrom: string, startTime: string, finishTime: string, messageTypes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/message-store-report")
  let body = {dateTo: $dateTo, dateFrom: $dateFrom, messageTypes: $messageTypes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Message Store Report Task
#
# GET /restapi/v1.0/account/{accountId}/message-store-report/{taskId}
# operationId: readMessageStoreReportTask
export def "restapi-v10-account-message-store-report readMessageStoreReportTask" [
  accountId: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uri: string, status: string, accountId: string, extensionId: string, dateTo: string, dateFrom: string, startTime: string, finishTime: string, messageTypes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/message-store-report/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Message Store Report Archive
#
# GET /restapi/v1.0/account/{accountId}/message-store-report/{taskId}/archive
# operationId: readMessageStoreReportArchive
export def "restapi-v10-account-message-store-report-archive readMessageStoreReportArchive" [
  accountId: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<records: table<size: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/message-store-report/($taskId)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Company Directory Entries
#
# GET /restapi/v1.0/account/{accountId}/directory/entries
# operationId: listDirectoryEntries
export def "restapi-v10-account-directory-entries listDirectoryEntries" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --showFederated: string@bool-completer # If `true` then contacts of all accounts in federation are returned. If `false` then only contacts of the current account are returned, and account section is eliminated in this case (default: true)
  --type: string@type-completer-8 # Type of an extension. Please note that legacy 'Department' extension type corresponds to 'Call Queue' extensions in modern RingCentral product terminology
  --typeGroup: string@typeGroup-completer # Type of extension group
  --page: int # Page number (format: int32, default: 1)
  --perPage: string # Records count to be returned per one page. It can be either integer or string with the specific keyword values: - `all` - all records are returned in one page - `max` - maximum count of records that can be returned in one page
  --siteId: string # Internal identifier of the business site to which extensions belong
  --If-None-Match: string # User in GET requests to skip retrieving the data if the provided value matches current `ETag` associated with this resource. The server checks the current resource ETag and returns the data only if mismatches the `If-None-Match` value, otherwise `HTTP 304 Not Modified` status is returned.
]: nothing -> record<paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>, records: table<id: string, type: string, status: string, account: record, department: string, email: string, extensionNumber: string, firstName: string, lastName: string, name: string, jobTitle: string, phoneNumbers: list, profileImage: record, site: record, hidden: bool, role: record, callQueues: list, customFields: list, groups: list, costCenter: record, integration: record, subType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showFederated" $showFederated "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "typeGroup" $typeGroup "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "siteId" $siteId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/directory/entries" $qp)
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Corporate Directory Entry
#
# GET /restapi/v1.0/account/{accountId}/directory/entries/{entryId}
# operationId: readDirectoryEntry
export def "restapi-v10-account-directory-entries readDirectoryEntry" [
  accountId: string
  entryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, status: string, account: record<companyName: string, federatedName: string, id: string, mainNumber: record<formattedPhoneNumber: string, phoneNumber: string, type: string, label: string, usageType: string, hidden: bool, primary: bool>>, department: string, email: string, extensionNumber: string, firstName: string, lastName: string, name: string, jobTitle: string, phoneNumbers: table<formattedPhoneNumber: string, phoneNumber: string, type: string, label: string, usageType: string, hidden: bool, primary: bool>, profileImage: record<etag: string, uri: string>, site: record<id: string, name: string, code: string>, hidden: bool, role: record<id: string, name: string, domain: string, displayName: string>, callQueues: table<id: string, name: string>, customFields: table<id: string, name: string, value: string>, groups: table<id: string, name: string>, costCenter: record<id: string, code: string, name: string>, integration: record<id: string, typeId: string, type: string, displayName: string, routingType: string, outboundEdgeId: string>, subType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/directory/entries/($entryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Company Directory Entries
#
# POST /restapi/v1.0/account/{accountId}/directory/entries/search
# operationId: searchDirectoryEntries
# --orderBy item shape: {index?: int, fieldName?: "firstName"|"lastName"|"extensionNumber"|"phoneNumber"|"email"|"jobTitle"|"department", direction?: "Asc"|"Desc"}
export def "restapi-v10-account-directory-entries-search searchDirectoryEntries" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountId: string # A list of Account IDs (e.g. 400131426008)
  --department: string # A list of department names (e.g. North office)
  --siteId: string # A list of Site IDs (e.g. 872781797006)
  --extensionStatus: string # Extension current state (e.g. Enabled)
  --extensionType: string # Extension types
  --searchString: string # String value to filter the contacts. The value specified is searched through the following fields: `firstName`, `lastName`, `extensionNumber`, `phoneNumber`, `email`, `jobTitle`, `department`, `customFieldValue`
  --searchFields: list # The list of field to be searched for
  --showFederated: string@bool-completer # If `true` then contacts of all accounts in federation are returned, if it is in federation, account section will be returned. If `false` then only contacts of the current account are returned, and account section is eliminated in this case
  --showAdminOnlyContacts: string@bool-completer # Should show AdminOnly Contacts (default: false)
  --extensionType: string@extensionType-completer # Type of directory contact to filter (e.g. User)
  --siteId: string # Internal identifier of the business site to which extensions belong (e.g. 872781797006)
  --showExternalContacts: string@bool-completer # Allows to control whether External (Hybrid) contacts should be returned in the response or not (default: false, e.g. true)
  --accountIds: list # The list of Internal identifiers of an accounts (e.g. [854874047006, 422456828004, 854874151006])
  --department: string # Department
  --siteIds: list # The list of Internal identifiers of the business sites to which extensions belong
  --extensionStatuses: list # Extension current state.
  --extensionTypes: list # Types of extension to filter the contacts
  --orderBy: list # Sorting settings — item shape: {index?: int, fieldName?: "firstName"|"lastName"|"extensionNumber"|"phoneNumber"|"email"|"jobTitle"|"department", direction?: "Asc"|"Desc"}
  --page: int # format: int32
  --perPage: int # format: int32
]: any -> record<paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>, records: table<id: string, type: string, status: string, account: record, department: string, email: string, extensionNumber: string, firstName: string, lastName: string, name: string, jobTitle: string, phoneNumbers: list, profileImage: record, site: record, hidden: bool, role: record, callQueues: list, customFields: list, groups: list, costCenter: record, integration: record, subType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $accountId "scalar") (serialize-qp "department" $department "scalar") (serialize-qp "siteId" $siteId "scalar") (serialize-qp "extensionStatus" $extensionStatus "scalar") (serialize-qp "extensionType" $extensionType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/directory/entries/search" $qp)
  let body = {searchString: $searchString, searchFields: $searchFields, showFederated: $showFederated, showAdminOnlyContacts: $showAdminOnlyContacts, extensionType: $extensionType, siteId: $siteId, showExternalContacts: $showExternalContacts, accountIds: $accountIds, department: $department, siteIds: $siteIds, extensionStatuses: $extensionStatuses, extensionTypes: $extensionTypes, orderBy: $orderBy, page: $page, perPage: $perPage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Account Federation
#
# GET /restapi/v1.0/account/{accountId}/directory/federation
# operationId: readDirectoryFederation
export def "restapi-v10-account-directory-federation readDirectoryFederation" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --types: string # Filter by federation types. Default is Regular
  --RCExtensionId: string # RingCentral extension id
]: nothing -> record<accounts: table<companyName: string, conflictCount: int, federatedName: string, id: string, linkCreationTime: string, mainNumber: record>, creationTime: string, displayName: string, id: string, lastModifiedTime: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "types" $types "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/directory/federation" $qp)
  let extra_headers = {"RCExtensionId": $RCExtensionId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Paging Group Users
#
# GET /restapi/v1.0/account/{accountId}/paging-only-groups/{pagingOnlyGroupId}/users
# operationId: listPagingGroupUsers
export def "restapi-v10-account-paging-only-groups-users listPagingGroupUsers" [
  accountId: string
  pagingOnlyGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Indicates a page number to retrieve. Only positive number values are accepted  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items) (format: int32, default: 100)
]: nothing -> record<uri: string, records: table<id: string, uri: string, extensionNumber: string, name: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/paging-only-groups/($pagingOnlyGroupId)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign Paging Group Users and Devices
#
# POST /restapi/v1.0/account/{accountId}/paging-only-groups/{pagingOnlyGroupId}/bulk-assign
# operationId: assignMultiplePagingGroupUsersDevices
export def "restapi-v10-account-paging-only-groups-bulk-assign assignMultiplePagingGroupUsersDevices" [
  accountId: string
  pagingOnlyGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --addedUserIds: list # List of users that will be allowed to page a group specified
  --removedUserIds: list # List of users that will be disallowed to page a group specified
  --addedDeviceIds: list # List of account devices that will be assigned to a paging group specified
  --removedDeviceIds: list # List of account devices that will be unassigned from a paging group specified
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/paging-only-groups/($pagingOnlyGroupId)/bulk-assign")
  let body = {addedUserIds: $addedUserIds, removedUserIds: $removedUserIds, addedDeviceIds: $addedDeviceIds, removedDeviceIds: $removedDeviceIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Paging Group Devices
#
# GET /restapi/v1.0/account/{accountId}/paging-only-groups/{pagingOnlyGroupId}/devices
# operationId: listPagingGroupDevices
export def "restapi-v10-account-paging-only-groups-devices listPagingGroupDevices" [
  accountId: string
  pagingOnlyGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Indicates a page number to retrieve. Only positive number values are accepted  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items)  (format: int32, default: 100)
]: nothing -> record<uri: string, records: table<id: string, uri: string, name: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/paging-only-groups/($pagingOnlyGroupId)/devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Sites
#
# GET /restapi/v1.0/account/{accountId}/sites
# operationId: listSites
export def "restapi-v10-account-sites listSites" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, records: table<id: string, uri: string, name: string, extensionNumber: string, callerIdName: string, email: string, businessAddress: record, regionalSettings: record, operator: record, code: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/sites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Site
#
# POST /restapi/v1.0/account/{accountId}/sites
# operationId: createSite
# --businessAddress shape: {country?: string, state?: string, city?: string, street?: string, zip?: string}
# --regionalSettings shape: {homeCountry?: any, timezone?: record, language?: record, greetingLanguage?: record, formattingLocale?: record, timeFormat?: "12h"|"24h"}
# --operator shape: {id?: string}
export def "restapi-v10-account-sites createSite" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Extension user first name
  --extensionNumber: string # Extension number
  --callerIdName: string # Custom name of a caller. Max number of characters is 15 (only alphabetical symbols, numbers and commas are supported)
  --email: string # Extension user email (format: email)
  --businessAddress: record # User's business address. The default is Company (Auto-Receptionist) settings — shape: {country?: string, state?: string, city?: string, street?: string, zip?: string}
  --regionalSettings: record # Regional data (timezone, home country, language) of an extension/account. The default is Company (Auto-Receptionist) settings — shape: {homeCountry?: any, timezone?: record, language?: record, greetingLanguage?: record, formattingLocale?: record, timeFormat?: "12h"|"24h"}
  --operator: record # Site Fax/SMS recipient (operator) reference. Multi-level IVR should be enabled — shape: {id?: string}
  --code: string # Site code value
]: any -> record<id: string, uri: string, name: string, extensionNumber: string, callerIdName: string, email: string, businessAddress: record<country: string, state: string, city: string, street: string, zip: string>, regionalSettings: record<homeCountry: record<isoCode: string, callingCode: string>, timezone: record<id: string, uri: string, name: string, description: string, bias: string>, language: record<id: string, localeCode: string, name: string>, greetingLanguage: record<id: string, localeCode: string, name: string>, formattingLocale: record<id: string, localeCode: string, name: string>, timeFormat: string>, operator: record<id: string, uri: string, extensionNumber: string, name: string>, code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/sites")
  let body = {name: $name, extensionNumber: $extensionNumber, callerIdName: $callerIdName, email: $email, businessAddress: $businessAddress, regionalSettings: $regionalSettings, operator: $operator, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Site
#
# GET /restapi/v1.0/account/{accountId}/sites/{siteId}
# operationId: readSite
export def "restapi-v10-account-sites readSite" [
  accountId: string
  siteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uri: string, name: string, extensionNumber: string, callerIdName: string, email: string, businessAddress: record<country: string, state: string, city: string, street: string, zip: string>, regionalSettings: record<homeCountry: record<isoCode: string, callingCode: string>, timezone: record<id: string, uri: string, name: string, description: string, bias: string>, language: record<id: string, localeCode: string, name: string>, greetingLanguage: record<id: string, localeCode: string, name: string>, formattingLocale: record<id: string, localeCode: string, name: string>, timeFormat: string>, operator: record<id: string, uri: string, extensionNumber: string, name: string>, code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/sites/($siteId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Site
#
# PUT /restapi/v1.0/account/{accountId}/sites/{siteId}
# operationId: updateSite
# --businessAddress shape: {country?: string, state?: string, city?: string, street?: string, zip?: string}
# --regionalSettings shape: {homeCountry?: any, timezone?: record, language?: record, greetingLanguage?: record, formattingLocale?: record, timeFormat?: "12h"|"24h"}
# --operator shape: {id?: string, uri?: string, extensionNumber?: string, name?: string}
export def "restapi-v10-account-sites updateSite" [
  accountId: string
  siteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Extension user first name
  --extensionNumber: string # Extension number
  --callerIdName: string # Custom name of a caller. Max number of characters is 15 (only alphabetical symbols, numbers and commas are supported)
  --email: string # Site extension contact email (format: email)
  --businessAddress: record # User's business address. The default is Company (Auto-Receptionist) settings — shape: {country?: string, state?: string, city?: string, street?: string, zip?: string}
  --regionalSettings: record # Regional data (timezone, home country, language) of an extension/account. The default is Company (Auto-Receptionist) settings — shape: {homeCountry?: any, timezone?: record, language?: record, greetingLanguage?: record, formattingLocale?: record, timeFormat?: "12h"|"24h"}
  --operator: record # Site Fax/SMS recipient (operator) reference. Multi-level IVR should be enabled — shape: {id?: string, uri?: string, extensionNumber?: string, name?: string}
]: any -> record<id: string, uri: string, name: string, extensionNumber: string, callerIdName: string, email: string, businessAddress: record<country: string, state: string, city: string, street: string, zip: string>, regionalSettings: record<homeCountry: record<isoCode: string, callingCode: string>, timezone: record<id: string, uri: string, name: string, description: string, bias: string>, language: record<id: string, localeCode: string, name: string>, greetingLanguage: record<id: string, localeCode: string, name: string>, formattingLocale: record<id: string, localeCode: string, name: string>, timeFormat: string>, operator: record<id: string, uri: string, extensionNumber: string, name: string>, code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/sites/($siteId)")
  let body = {name: $name, extensionNumber: $extensionNumber, callerIdName: $callerIdName, email: $email, businessAddress: $businessAddress, regionalSettings: $regionalSettings, operator: $operator} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Site
#
# DELETE /restapi/v1.0/account/{accountId}/sites/{siteId}
# operationId: deleteSite
export def "restapi-v10-account-sites delete" [
  accountId: string
  siteId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/sites/($siteId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit Sites
#
# POST /restapi/v1.0/account/{accountId}/sites/{siteId}/bulk-assign
# operationId: assignMultipleSites
export def "restapi-v10-account-sites-bulk-assign assignMultipleSites" [
  accountId: string
  siteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --removedExtensionIds: list # List of removed extensions
  --addedExtensionIds: list # List of added extensions
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/sites/($siteId)/bulk-assign")
  let body = {removedExtensionIds: $removedExtensionIds, addedExtensionIds: $addedExtensionIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Site Members
#
# GET /restapi/v1.0/account/{accountId}/sites/{siteId}/members
# operationId: listSiteMembers
export def "restapi-v10-account-sites-members listSiteMembers" [
  accountId: string
  siteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, records: table<id: int, uri: string, extensionNumber: string, type: string, name: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/sites/($siteId)/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Site IVR Settings
#
# GET /restapi/v1.0/account/{accountId}/sites/{siteId}/ivr
# operationId: readSiteIvrSettings
export def "restapi-v10-account-sites-ivr readSiteIvrSettings" [
  accountId: string
  siteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<topMenu: record<id: string, uri: string, name: string>, actions: table<input: string, action: string, extension: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/sites/($siteId)/ivr")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Site IVR Settings
#
# PUT /restapi/v1.0/account/{accountId}/sites/{siteId}/ivr
# operationId: updateSiteIvrSettings
# --topMenu shape: {id?: string}
# --actions item shape: {input?: "Star"|"Hash"|"NoInput"|"0", action?: "Repeat"|"ReturnToRoot"|"ReturnToPrevious"|"ReturnToTopLevelMenu"|"Connect"|"ConnectToOperator"|"Disconnect"|"DoNothing", extension?: record}
export def "restapi-v10-account-sites-ivr updateSiteIvrSettings" [
  accountId: string
  siteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --topMenu: record # Top IVR Menu extension — shape: {id?: string}
  --actions: list # item shape: {input?: "Star"|"Hash"|"NoInput"|"0", action?: "Repeat"|"ReturnToRoot"|"ReturnToPrevious"|"ReturnToTopLevelMenu"|"Connect"|"ConnectToOperator"|"Disconnect"|"DoNothing", extension?: record}
]: any -> record<topMenu: record<id: string, uri: string, name: string>, actions: table<input: string, action: string, extension: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/sites/($siteId)/ivr")
  let body = {topMenu: $topMenu, actions: $actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Call Recording
#
# GET /restapi/v1.0/account/{accountId}/recording/{recordingId}
# operationId: readCallRecording
export def "restapi-v10-account-recording readCallRecording" [
  accountId: string
  recordingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, contentUri: string, contentType: string, duration: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/recording/($recordingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Message Store Configuration
#
# GET /restapi/v1.0/account/{accountId}/message-store-configuration
# operationId: readMessageStoreConfiguration
export def "restapi-v10-account-message-store-configuration readMessageStoreConfiguration" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<retentionPeriod: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/message-store-configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Message Store Configuration
#
# PUT /restapi/v1.0/account/{accountId}/message-store-configuration
# operationId: updateMessageStoreConfiguration
export def "restapi-v10-account-message-store-configuration updateMessageStoreConfiguration" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --retentionPeriod: int # Retention policy setting, specifying how long to keep messages; the supported value range is 7-90 days. Currently, the retention period is supported for `Fax` and `Voicemail` messages only. SMS messages are stored with no time limits  (format: int32)
]: any -> record<retentionPeriod: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/message-store-configuration")
  let body = {retentionPeriod: $retentionPeriod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Company Greeting
#
# POST /restapi/v1.0/account/{accountId}/greeting
# operationId: createCompanyGreeting
export def "restapi-v10-account-greeting createCompanyGreeting" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-9 # Type of greeting, specifying the case when the greeting is played.
  --answeringRuleId: string # Internal identifier of an answering rule
  --languageId: string # Internal identifier of a language. See Get Language List
  binary: string # Media file to upload (format: binary)
]: any -> record<uri: string, id: string, type: string, contentType: string, contentUri: string, answeringRule: record<uri: string, id: string>, language: record<id: string, uri: string, name: string, localeCode: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/greeting")
  let body = {type: $type, answeringRuleId: $answeringRuleId, languageId: $languageId, binary: $binary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List Company User Roles
#
# GET /restapi/v1.0/account/{accountId}/user-role
# operationId: listUserRoles
export def "restapi-v10-account-user-role listUserRoles" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --custom: string@bool-completer # Specifies whether to return custom roles or predefined roles only. If not specified, all roles are returned
  --page: int # The result set page number (1-indexed) to return (format: int32, default: 1, e.g. 1)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
]: nothing -> record<uri: string, records: table<uri: string, id: string, displayName: string, description: string, siteCompatible: bool, custom: bool, scope: string, hidden: bool, lastUpdated: string, permissions: list>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "custom" $custom "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/user-role" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Custom Role
#
# POST /restapi/v1.0/account/{accountId}/user-role
# operationId: createCustomRole
# --permissions item shape: {uri?: string, id?: string, siteCompatible?: "Compatible"|"Incompatible"|"Independent", readOnly?: bool, assignable?: bool, permissionsCapabilities?: record}
export def "restapi-v10-account-user-role createCustomRole" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Internal identifier of a role
  --displayName: string # Dispayed name of a role (e.g. Super Admin)
  --description: string # Role description (e.g. Primary company administrator role)
  --siteCompatible: string@bool-completer # Site compatibility of a user role
  --custom: string@bool-completer # Specifies if a user role is custom (default: false)
  --scope: string@scope-completer # Specifies resource for permission
  --hidden: string@bool-completer # default: false
  --lastUpdated: string # format: date-time
  --permissions: list # item shape: {uri?: string, id?: string, siteCompatible?: "Compatible"|"Incompatible"|"Independent", readOnly?: bool, assignable?: bool, permissionsCapabilities?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/user-role")
  let body = {id: $id, displayName: $displayName, description: $description, siteCompatible: $siteCompatible, custom: $custom, scope: $scope, hidden: $hidden, lastUpdated: $lastUpdated, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Default User Role
#
# GET /restapi/v1.0/account/{accountId}/user-role/default
# operationId: readDefaultRole
export def "restapi-v10-account-user-role-default readDefaultRole" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, displayName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/user-role/default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Default User Role
#
# PUT /restapi/v1.0/account/{accountId}/user-role/default
# operationId: updateDefaultUserRole
export def "restapi-v10-account-user-role-default updateDefaultUserRole" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Internal identifier of a user role to be set as default
]: any -> record<uri: string, id: string, displayName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/user-role/default")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get User Role
#
# GET /restapi/v1.0/account/{accountId}/user-role/{roleId}
# operationId: readUserRole
export def "restapi-v10-account-user-role readUserRole" [
  roleId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --advancedPermissions: string@bool-completer # Specifies whether to return advanced permissions capabilities within `permissionsCapabilities` resource. The default value is false.
]: nothing -> record<uri: string, id: string, displayName: string, description: string, siteCompatible: bool, custom: bool, scope: string, hidden: bool, lastUpdated: string, permissions: table<uri: string, id: string, siteCompatible: string, readOnly: bool, assignable: bool, permissionsCapabilities: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "advancedPermissions" $advancedPermissions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/user-role/($roleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User Role
#
# PUT /restapi/v1.0/account/{accountId}/user-role/{roleId}
# operationId: updateUserRole
# --permissions item shape: {uri?: string, id?: string, siteCompatible?: "Compatible"|"Incompatible"|"Independent", readOnly?: bool, assignable?: bool, permissionsCapabilities?: record}
export def "restapi-v10-account-user-role updateUserRole" [
  roleId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Internal identifier of a role
  --displayName: string # Dispayed name of a role (e.g. Super Admin)
  --description: string # Role description (e.g. Primary company administrator role)
  --siteCompatible: string@bool-completer # Site compatibility of a user role
  --custom: string@bool-completer # Specifies if a user role is custom (default: false)
  --scope: string@scope-completer # Specifies resource for permission
  --hidden: string@bool-completer # default: false
  --lastUpdated: string # format: date-time
  --permissions: list # item shape: {uri?: string, id?: string, siteCompatible?: "Compatible"|"Incompatible"|"Independent", readOnly?: bool, assignable?: bool, permissionsCapabilities?: record}
]: any -> record<uri: string, id: string, displayName: string, description: string, siteCompatible: bool, custom: bool, scope: string, hidden: bool, lastUpdated: string, permissions: table<uri: string, id: string, siteCompatible: string, readOnly: bool, assignable: bool, permissionsCapabilities: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/user-role/($roleId)")
  let body = {id: $id, displayName: $displayName, description: $description, siteCompatible: $siteCompatible, custom: $custom, scope: $scope, hidden: $hidden, lastUpdated: $lastUpdated, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Custom Role
#
# DELETE /restapi/v1.0/account/{accountId}/user-role/{roleId}
# operationId: deleteCustomRole
export def "restapi-v10-account-user-role delete" [
  roleId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --validateOnly: string@bool-completer # Specifies that role should be validated prior to deletion, whether it can be deleted or not
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validateOnly" $validateOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/user-role/($roleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign Multiple User Roles
#
# POST /restapi/v1.0/account/{accountId}/user-role/{roleId}/bulk-assign
# operationId: assignMultipleUserRoles
export def "restapi-v10-account-user-role-bulk-assign assignMultipleUserRoles" [
  accountId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --siteRestricted: string@bool-completer # e.g. true
  --siteCompatible: string@bool-completer
  --uri: string # format: uri
  --addedExtensionIds: list
  --removedExtensionIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/user-role/($roleId)/bulk-assign")
  let body = {siteRestricted: $siteRestricted, siteCompatible: $siteCompatible, uri: $uri, addedExtensionIds: $addedExtensionIds, removedExtensionIds: $removedExtensionIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Extensions
#
# GET /restapi/v1.0/account/{accountId}/extension
# operationId: listExtensions
export def "restapi-v10-account-extension listExtensions" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extensionNumber: string # Extension short number to filter records
  --email: string # Extension email address. Multiple values are accepted  (e.g. alice.smith@example.com&email=bob.johnson@example.com)
  --page: int # Indicates a page number to retrieve. Only positive number values are allowed  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items) (format: int32, default: 100)
  --status: list # Extension current state. Multiple values are supported. If 'Unassigned' is specified, then extensions without `extensionNumber` attribute are returned. If not specified, then all extensions are returned  (allows empty value)
  --type: list # Extension type. Multiple values are supported. Please note that legacy 'Department' extension type corresponds to 'Call Queue' extensions in modern RingCentral product terminology  (allows empty value)
]: nothing -> record<uri: string, records: table<id: int, uri: string, contact: record, extensionNumber: string, name: string, permissions: record, profileImage: record, status: string, type: string, subType: string, callQueueInfo: record, hidden: bool, site: record, assignedCountry: record, costCenter: record>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extensionNumber" $extensionNumber "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "status" $status "multi") (serialize-qp "type" $type "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Extension
#
# POST /restapi/v1.0/account/{accountId}/extension
# operationId: createExtension
# --contact shape: {firstName?: string, lastName?: string, company?: string, jobTitle?: string, email?: string, businessPhone?: string, mobilePhone?: string, businessAddress?: record, emailAsLoginName?: bool, pronouncedName?: record, department?: string}
# --costCenter shape: {id?: string, name?: string}
# --customFields item shape: {id?: string, value?: string, displayName?: string}
# --references item shape: {ref?: string, type?: "PartnerId"|"CustomerDirectoryId", refAccId?: string}
# --regionalSettings shape: {homeCountry?: any, timezone?: record, language?: record, greetingLanguage?: record, formattingLocale?: record, timeFormat?: "12h"|"24h"}
# --site shape: {id?: string, uri?: string, name?: string, extensionNumber?: string, callerIdName?: string, email?: string, businessAddress?: record, regionalSettings?: record, operator?: record, code?: string}
# --statusInfo shape: {comment?: string, reason?: "SuspendedVoluntarily"|"SuspendedInvoluntarily"|"CancelledVoluntarily"|"CancelledInvoluntarily", till?: string}
export def "restapi-v10-account-extension createExtension" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contact: record # Contact Information — shape: {firstName?: string, lastName?: string, company?: string, jobTitle?: string, email?: string, businessPhone?: string, mobilePhone?: string, businessAddress?: record, emailAsLoginName?: bool, pronouncedName?: record, department?: string}
  --extensionNumber: string # Extension short number
  --costCenter: record # Cost center information. Applicable if Cost Center feature is enabled. The default is `root` cost center value — shape: {id?: string, name?: string}
  --customFields: list # item shape: {id?: string, value?: string, displayName?: string}
  --password: string # Password for extension. If not specified, the password is auto-generated
  --references: list # List of non-RC internal identifiers assigned to an extension — item shape: {ref?: string, type?: "PartnerId"|"CustomerDirectoryId", refAccId?: string}
  --regionalSettings: record # Regional data (timezone, home country, language) of an extension/account. The default is Company (Auto-Receptionist) settings — shape: {homeCountry?: any, timezone?: record, language?: record, greetingLanguage?: record, formattingLocale?: record, timeFormat?: "12h"|"24h"}
  --partnerId: string # Additional extension identifier, created by partner application and applied on client side
  --ivrPin: string # IVR PIN
  --setupWizardState: string@setupWizardState-completer # Initial configuration wizard state (default: NotStarted)
  --site: record # shape: {id?: string, uri?: string, name?: string, extensionNumber?: string, callerIdName?: string, email?: string, businessAddress?: record, regionalSettings?: record, operator?: record, code?: string}
  --status: string@status-completer-3 # Extension current state
  --statusInfo: record # Status information (reason, comment). Returned for 'Disabled' status only — shape: {comment?: string, reason?: "SuspendedVoluntarily"|"SuspendedInvoluntarily"|"CancelledVoluntarily"|"CancelledInvoluntarily", till?: string}
  --type: string@type-completer-10 # Extension type. Please note that legacy 'Department' extension type corresponds to 'Call Queue' extensions in modern RingCentral product terminology
  --hidden: string@bool-completer # Hides extension from showing in company directory. Supported for extensions of 'User' type only. For unassigned extensions the value is set to `true` by default. For assigned extensions the value is set to `false` by default
]: any -> record<id: int, uri: string, contact: record<firstName: string, lastName: string, name: string, company: string, jobTitle: string, email: string, businessPhone: string, mobilePhone: string, businessAddress: record<country: string, state: string, city: string, street: string, zip: string>, emailAsLoginName: bool, pronouncedName: record<type: string, text: string, prompt: record>, department: string>, costCenter: record<id: string, name: string>, customFields: table<id: string, value: string, displayName: string>, extensionNumber: string, name: string, partnerId: string, permissions: record<admin: record<enabled: bool>, internationalCalling: record<enabled: bool>>, profileImage: record<uri: string, etag: string, lastModified: string, contentType: string, scales: list<record>>, references: table<ref: string, type: string, refAccId: string>, regionalSettings: record<homeCountry: record<isoCode: string, callingCode: string>, timezone: record<id: string, uri: string, name: string, description: string, bias: string>, language: record<id: string, localeCode: string, name: string>, greetingLanguage: record<id: string, localeCode: string, name: string>, formattingLocale: record<id: string, localeCode: string, name: string>, timeFormat: string>, serviceFeatures: table<enabled: bool, featureName: string, reason: string>, setupWizardState: string, site: record<id: string, uri: string, name: string, code: string>, status: string, statusInfo: record<comment: string, reason: string, till: string>, type: string, hidden: bool, assignedCountry: record<id: string, uri: string, isoCode: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension")
  let body = {contact: $contact, extensionNumber: $extensionNumber, costCenter: $costCenter, customFields: $customFields, password: $password, references: $references, regionalSettings: $regionalSettings, partnerId: $partnerId, ivrPin: $ivrPin, setupWizardState: $setupWizardState, site: $site, status: $status, statusInfo: $statusInfo, type: $type, hidden: $hidden} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Extension
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}
# operationId: readExtension
export def "restapi-v10-account-extension readExtension" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, uri: string, account: record<id: string, uri: string>, contact: record<firstName: string, lastName: string, name: string, company: string, jobTitle: string, email: string, businessPhone: string, mobilePhone: string, businessAddress: record<country: string, state: string, city: string, street: string, zip: string>, emailAsLoginName: bool, pronouncedName: record<type: string, text: string, prompt: record>, department: string>, costCenter: record<id: string, name: string>, customFields: table<id: string, value: string, displayName: string>, departments: table<id: string, uri: string, extensionNumber: string>, extensionNumber: string, extensionNumbers: list<string>, name: string, partnerId: string, permissions: record<admin: record<enabled: bool>, internationalCalling: record<enabled: bool>>, profileImage: record<uri: string, etag: string, lastModified: string, contentType: string, scales: list<record>>, references: table<ref: string, type: string, refAccId: string>, roles: table<uri: string, id: string, autoAssigned: bool, displayName: string, siteCompatible: bool, siteRestricted: bool>, regionalSettings: record<homeCountry: record<isoCode: string, callingCode: string>, timezone: record<id: string, uri: string, name: string, description: string, bias: string>, language: record<id: string, localeCode: string, name: string>, greetingLanguage: record<id: string, localeCode: string, name: string>, formattingLocale: record<id: string, localeCode: string, name: string>, timeFormat: string>, serviceFeatures: table<enabled: bool, featureName: string, reason: string>, setupWizardState: string, status: string, statusInfo: record<comment: string, reason: string, till: string>, type: string, subType: string, callQueueInfo: record<slaGoal: int, slaThresholdSeconds: int, includeAbandonedCalls: bool, abandonedThresholdSeconds: int>, hidden: bool, site: record<id: string, uri: string, name: string, code: string>, assignedCountry: record<id: string, uri: string, isoCode: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Extension
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}
# operationId: updateExtension
# --statusInfo shape: {comment?: string, reason?: "SuspendedVoluntarily"|"SuspendedInvoluntarily"|"CancelledVoluntarily"|"CancelledInvoluntarily", till?: string}
# --contact shape: {firstName?: string, lastName?: string, company?: string, jobTitle?: string, email?: string, businessPhone?: string, mobilePhone?: string, businessAddress?: record, emailAsLoginName?: bool, pronouncedName?: record, department?: string}
# --regionalSettings shape: {homeCountry?: record, timezone?: record, language?: record, greetingLanguage?: record, formattingLocale?: record, currency?: record, timeFormat?: "12h"|"24h"}
# --callQueueInfo shape: {slaGoal?: int, slaThresholdSeconds?: int, includeAbandonedCalls?: bool, abandonedThresholdSeconds?: int}
# --transition shape: {sendWelcomeEmailsToUsers?: bool, sendWelcomeEmail?: bool}
# --customFields item shape: {id?: string, value?: string, displayName?: string}
# --site shape: {id?: string}
# --references item shape: {ref?: string, type?: "PartnerId"|"CustomerDirectoryId", refAccId?: string}
export def "restapi-v10-account-extension updateExtension" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-4
  --statusInfo: record # Status information (reason, comment). Returned for 'Disabled' status only — shape: {comment?: string, reason?: "SuspendedVoluntarily"|"SuspendedInvoluntarily"|"CancelledVoluntarily"|"CancelledInvoluntarily", till?: string}
  --extensionNumber: string # Extension number available
  --contact: record # shape: {firstName?: string, lastName?: string, company?: string, jobTitle?: string, email?: string, businessPhone?: string, mobilePhone?: string, businessAddress?: record, emailAsLoginName?: bool, pronouncedName?: record, department?: string}
  --regionalSettings: record # shape: {homeCountry?: record, timezone?: record, language?: record, greetingLanguage?: record, formattingLocale?: record, currency?: record, timeFormat?: "12h"|"24h"}
  --setupWizardState: string@setupWizardState-completer # Initial configuration wizard state (default: NotStarted)
  --partnerId: string # Additional extension identifier, created by partner application and applied on client side
  --ivrPin: string # IVR PIN
  --password: string # Password for extension
  --callQueueInfo: record # For Call Queue extension type only. Please note that legacy 'Department' extension type corresponds to 'Call Queue' extensions in modern RingCentral product terminology — shape: {slaGoal?: int, slaThresholdSeconds?: int, includeAbandonedCalls?: bool, abandonedThresholdSeconds?: int}
  --transition: record # For NotActivated extensions only. Welcome email settings — shape: {sendWelcomeEmailsToUsers?: bool, sendWelcomeEmail?: bool}
  --customFields: list # item shape: {id?: string, value?: string, displayName?: string}
  --site: record # shape: {id?: string}
  --type: string@type-completer-11 # Extension type. Please note that legacy 'Department' extension type corresponds to 'Call Queue' extensions in modern RingCentral product terminology
  --subType: string@subType-completer-1 # Extension subtype, if applicable. For any unsupported subtypes the 'Unknown' value will be returned
  --references: list # List of non-RC internal identifiers assigned to an extension — item shape: {ref?: string, type?: "PartnerId"|"CustomerDirectoryId", refAccId?: string}
]: any -> record<id: int, uri: string, account: record<id: string, uri: string>, contact: record<firstName: string, lastName: string, name: string, company: string, jobTitle: string, email: string, businessPhone: string, mobilePhone: string, businessAddress: record<country: string, state: string, city: string, street: string, zip: string>, emailAsLoginName: bool, pronouncedName: record<type: string, text: string, prompt: record>, department: string>, costCenter: record<id: string, name: string>, customFields: table<id: string, value: string, displayName: string>, departments: table<id: string, uri: string, extensionNumber: string>, extensionNumber: string, extensionNumbers: list<string>, name: string, partnerId: string, permissions: record<admin: record<enabled: bool>, internationalCalling: record<enabled: bool>>, profileImage: record<uri: string, etag: string, lastModified: string, contentType: string, scales: list<record>>, references: table<ref: string, type: string, refAccId: string>, roles: table<uri: string, id: string, autoAssigned: bool, displayName: string, siteCompatible: bool, siteRestricted: bool>, regionalSettings: record<homeCountry: record<isoCode: string, callingCode: string>, timezone: record<id: string, uri: string, name: string, description: string, bias: string>, language: record<id: string, localeCode: string, name: string>, greetingLanguage: record<id: string, localeCode: string, name: string>, formattingLocale: record<id: string, localeCode: string, name: string>, timeFormat: string>, serviceFeatures: table<enabled: bool, featureName: string, reason: string>, setupWizardState: string, status: string, statusInfo: record<comment: string, reason: string, till: string>, type: string, subType: string, callQueueInfo: record<slaGoal: int, slaThresholdSeconds: int, includeAbandonedCalls: bool, abandonedThresholdSeconds: int>, hidden: bool, site: record<id: string, uri: string, name: string, code: string>, assignedCountry: record<id: string, uri: string, isoCode: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)")
  let body = {status: $status, statusInfo: $statusInfo, extensionNumber: $extensionNumber, contact: $contact, regionalSettings: $regionalSettings, setupWizardState: $setupWizardState, partnerId: $partnerId, ivrPin: $ivrPin, password: $password, callQueueInfo: $callQueueInfo, transition: $transition, customFields: $customFields, site: $site, type: $type, subType: $subType, references: $references} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Extension
#
# DELETE /restapi/v1.0/account/{accountId}/extension/{extensionId}
# DEPRECATED
# operationId: deleteExtension
@deprecated
export def "restapi-v10-account-extension delete" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --savePhoneLines: string@bool-completer # default: false
  --savePhoneNumbers: string@bool-completer # default: true
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "savePhoneLines" $savePhoneLines "scalar") (serialize-qp "savePhoneNumbers" $savePhoneNumbers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User Business Hours
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/business-hours
# operationId: readUserBusinessHours
export def "restapi-v10-account-extension-business-hours readUserBusinessHours" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, schedule: record<weeklyRanges: record<monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, sunday: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/business-hours")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User Business Hours
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/business-hours
# operationId: updateUserBusinessHours
# --schedule shape: {weeklyRanges?: record}
export def "restapi-v10-account-extension-business-hours updateUserBusinessHours" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  schedule: record # Schedule when an answering rule is applied — shape: {weeklyRanges?: record}
]: any -> record<uri: string, schedule: record<weeklyRanges: record<monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, sunday: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/business-hours")
  let body = {schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get User Video Configuration
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/video-configuration
# operationId: readUserVideoConfiguration
export def "restapi-v10-account-extension-video-configuration readUserVideoConfiguration" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<provider: string, userLicenseType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/video-configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Favorite Contacts
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/favorite
# operationId: listFavoriteContacts
export def "restapi-v10-account-extension-favorite listFavoriteContacts" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, records: table<id: int, extensionId: string, accountId: string, contactId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/favorite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Favorite Contact List
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/favorite
# operationId: updateFavoriteContactList
# --records item shape: {id?: int, extensionId?: string, accountId?: string, contactId?: string}
export def "restapi-v10-account-extension-favorite updateFavoriteContactList" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --records: list # item shape: {id?: int, extensionId?: string, accountId?: string, contactId?: string}
]: any -> record<uri: string, records: table<id: int, extensionId: string, accountId: string, contactId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/favorite")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Extension Devices
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/device
# operationId: listExtensionDevices
export def "restapi-v10-account-extension-device listExtensionDevices" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The result set page number (1-indexed) to return (format: int32, default: 1, e.g. 1)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --linePooling: string@linePooling-completer # Pooling type of device - Host - a device with standalone paid phone line which can be linked to a soft client instance - Guest - a device with a linked phone line - None - a device without a phone line or with specific line (free, BLA, etc.)
  --feature: string # Device feature or multiple features supported
  --type: string@type-completer-12 # Device type (default: HardPhone)
  --lineType: string # Phone line type
]: nothing -> record<uri: string, records: table<id: string, uri: string, sku: string, type: string, name: string, serial: string, status: string, computerName: string, model: record, extension: record, emergency: record, emergencyServiceAddress: record, phoneLines: list, shipping: record, boxBillingId: int, useAsCommonPhone: bool, hotDeskDevice: bool, inCompanyNet: bool, site: record, lastLocationReportTime: string, linePooling: string, billingStatement: record>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "linePooling" $linePooling "scalar") (serialize-qp "feature" $feature "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "lineType" $lineType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/device" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Extension Grants
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/grant
# operationId: listExtensionGrants
export def "restapi-v10-account-extension-grant listExtensionGrants" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extensionType: string@extensionType-completer-1 # Type of extension to be returned. Multiple values are supported. Please note that legacy 'Department' extension type corresponds to 'Call Queue' extensions in modern RingCentral product terminology
  --page: int # Indicates a page number to retrieve. Only positive number values are allowed  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items) (format: int32, default: 100)
]: nothing -> record<uri: string, records: table<uri: string, extension: record, callPickup: bool, callMonitoring: bool, callOnBehalfOf: bool, callDelegation: bool, groupPaging: bool, callQueueSetup: bool, callQueueMembersSetup: bool, callQueueMessages: bool, callQueueFacSetup: bool, sharedVoicemails: bool>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extensionType" $extensionType "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/grant" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User Conferencing Settings
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/conferencing
# operationId: readConferencingSettings
export def "restapi-v10-account-extension-conferencing readConferencingSettings" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --countryId: string # Internal identifier of a country. If not specified, the response is returned for the brand country
]: nothing -> record<uri: string, allowJoinBeforeHost: bool, hostCode: string, mode: string, participantCode: string, phoneNumber: string, supportUri: string, tapToJoinUri: string, phoneNumbers: table<country: record, default: bool, hasGreeting: bool, location: string, phoneNumber: string, premium: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryId" $countryId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/conferencing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User Conferencing Settings
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/conferencing
# operationId: updateConferencingSettings
# --phoneNumbers item shape: {phoneNumber?: string, default?: bool}
export def "restapi-v10-account-extension-conferencing updateConferencingSettings" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --phoneNumbers: list # Multiple dial-in phone numbers to connect to audio conference service, relevant for user's brand. Each number is given with the country and location information, in order to let the user choose the less expensive way to connect to a conference. The first number in the list is the primary conference number, that is default and domestic — item shape: {phoneNumber?: string, default?: bool}
  --allowJoinBeforeHost: string@bool-completer # Determines if host user allows conference participants to join before the host
]: any -> record<uri: string, allowJoinBeforeHost: bool, hostCode: string, mode: string, participantCode: string, phoneNumber: string, supportUri: string, tapToJoinUri: string, phoneNumbers: table<country: record, default: bool, hasGreeting: bool, location: string, phoneNumber: string, premium: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/conferencing")
  let body = {phoneNumbers: $phoneNumbers, allowJoinBeforeHost: $allowJoinBeforeHost} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload User Meeting Profile Image
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/meeting-configuration/profile-image
# DEPRECATED
# operationId: createUserMeetingProfileImage
@deprecated
export def "restapi-v10-account-extension-meeting-configuration-profile-image createUserMeetingProfileImage" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  profilePic: string # Profile image file size cannot exceed 2Mb. Supported formats are: JPG/JPEG, GIF and PNG (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/meeting-configuration/profile-image")
  let body = {profilePic: $profilePic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Agent’s Call Queue Presence
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/call-queue-presence
# operationId: readExtensionCallQueuePresence
export def "restapi-v10-account-extension-call-queue-presence readExtensionCallQueuePresence" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --editableMemberStatus: string@bool-completer # Filtering by the flag 'Allow members to change their Queue Status'. If 'true' only queues where user can change his availability status are returned
]: nothing -> record<records: table<callQueue: record, acceptCalls: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "editableMemberStatus" $editableMemberStatus "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/call-queue-presence" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Call Queue Presence
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/call-queue-presence
# operationId: updateExtensionCallQueuePresence
# --records item shape: {callQueue?: record, acceptCalls?: bool}
export def "restapi-v10-account-extension-call-queue-presence updateExtensionCallQueuePresence" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --records: list # item shape: {callQueue?: record, acceptCalls?: bool}
]: any -> record<records: table<callQueue: record, acceptCalls: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/call-queue-presence")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create User Message Template
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/message-store-templates
# operationId: createUserMessageTemplate
# --body shape: {text: string}
# --site shape: {id?: string, name?: string}
export def "restapi-v10-account-extension-message-store-templates createUserMessageTemplate" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  displayName: string # Name of a template
  --body-body: record # Text message template information — shape: {text: string}
  --site: record # Specifies a site that message template is associated with. Supported only if the Sites feature is enabled.  The default is `main-site` value. — shape: {id?: string, name?: string}
]: any -> record<id: string, displayName: string, body: record<text: string>, scope: string, site: record<id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/message-store-templates")
  let body = {displayName: $displayName, body: $body_body, site: $site} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List User Message Templates
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/message-store-templates
# operationId: listUserMessageTemplates
export def "restapi-v10-account-extension-message-store-templates listUserMessageTemplates" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --siteIds: list # Site ID(s) to filter user message templates, associated with particular sites. By default the value is all - templates with all sites will be returned
  --scope: string # Message templates scope. By default the value is all - both Personal and Company templates will be returned
]: nothing -> record<records: table<id: string, displayName: string, body: record, scope: string, site: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "siteIds" $siteIds "multi") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/message-store-templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User Message Template
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/message-store-templates/{templateId}
# operationId: updateUserMessageTemplate
# --body shape: {text: string}
# --site shape: {id?: string, name?: string}
export def "restapi-v10-account-extension-message-store-templates updateUserMessageTemplate" [
  accountId: string
  extensionId: string
  templateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  displayName: string # Name of a template
  --body-body: record # Text message template information — shape: {text: string}
  --site: record # Specifies a site that message template is associated with. Supported only if the Sites feature is enabled.  The default is `main-site` value. — shape: {id?: string, name?: string}
]: any -> record<id: string, displayName: string, body: record<text: string>, scope: string, site: record<id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/message-store-templates/($templateId)")
  let body = {displayName: $displayName, body: $body_body, site: $site} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get User Message Template
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/message-store-templates/{templateId}
# operationId: readUserMessageTemplate
export def "restapi-v10-account-extension-message-store-templates readUserMessageTemplate" [
  accountId: string
  extensionId: string
  templateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, displayName: string, body: record<text: string>, scope: string, site: record<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/message-store-templates/($templateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete User Message Template
#
# DELETE /restapi/v1.0/account/{accountId}/extension/{extensionId}/message-store-templates/{templateId}
# operationId: deleteUserMessageTemplate
export def "restapi-v10-account-extension-message-store-templates delete" [
  accountId: string
  extensionId: string
  templateId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/message-store-templates/($templateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sync Messages
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/message-sync
# operationId: syncMessages
export def "restapi-v10-account-extension-message-sync syncMessages" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --conversationId: int # Conversation identifier for the resulting messages. Meaningful for SMS and Pager messages only.  (format: int64)
  --dateFrom: string # The start date/time for resulting messages in ISO 8601 format including timezone, for example 2016-03-10T18:07:52.534Z. The default value is dateTo minus 24 hours  (format: date-time)
  --dateTo: string # The end date/time for resulting messages in ISO 8601 format including timezone, for example 2016-03-10T18:07:52.534Z. The default value is current time  (format: date-time)
  --direction: list # Direction for the resulting messages. If not specified, both inbound and outbound messages are returned. Multiple values are accepted
  --distinctConversations: string@bool-completer # If `true`, then the latest messages per every conversation ID are returned
  --messageType: list # Type for the resulting messages. If not specified, all types of messages are returned. Multiple values are accepted
  --recordCount: int # Limits the number of records to be returned (works in combination with dateFrom and dateTo if specified)  (format: int32)
  --syncToken: string # A `syncToken` value from the previous sync response (for `ISync` mode only, mandatory)
  --syncType: string # Type of message synchronization
  --voicemailOwner: list # This query parameter will filter voicemail messages based on its owner. This parameter should be controlled by the 'SharedVoicemail' feature. If the feature is disabled this filter shouldn't be applied.
]: nothing -> record<uri: string, records: table<id: int, uri: string, extensionId: string, attachments: list, availability: string, conversationId: int, conversation: record, creationTime: string, deliveryErrorCode: string, direction: string, faxPageCount: int, faxResolution: string, from: record, lastModifiedTime: string, messageStatus: string, pgToDepartment: bool, priority: string, readStatus: string, smsDeliveryTime: string, smsSendingAttemptsCount: int, subject: string, to: list, type: string, vmTranscriptionStatus: string, coverIndex: int, coverPageText: string>, syncInfo: record<syncType: string, syncToken: string, syncTime: string, olderRecordsExist: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "conversationId" $conversationId "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "direction" $direction "multi") (serialize-qp "distinctConversations" $distinctConversations "scalar") (serialize-qp "messageType" $messageType "multi") (serialize-qp "recordCount" $recordCount "scalar") (serialize-qp "syncToken" $syncToken "scalar") (serialize-qp "syncType" $syncType "scalar") (serialize-qp "voicemailOwner" $voicemailOwner "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/message-sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User Profile Image
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/profile-image
# operationId: readUserProfileImageLegacy
export def "restapi-v10-account-extension-profile-image readUserProfileImageLegacy" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-3 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/profile-image")
  let accept_val = ($accept | default "image/png")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User Profile Image
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/profile-image
# operationId: updateUserProfileImage
export def "restapi-v10-account-extension-profile-image updateUserProfileImage" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --image: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/profile-image")
  let body = {image: $image} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Upload User Profile Image
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/profile-image
# operationId: createUserProfileImage
export def "restapi-v10-account-extension-profile-image createUserProfileImage" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  image: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/profile-image")
  let body = {image: $image} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Delete User Profile Image
#
# DELETE /restapi/v1.0/account/{accountId}/extension/{extensionId}/profile-image
# operationId: deleteUserProfileImage
export def "restapi-v10-account-extension-profile-image delete" [
  accountId: string
  extensionId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/profile-image")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Call Records
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/call-log
# operationId: readUserCallLog
@deprecated --flag withRecording
export def "restapi-v10-account-extension-call-log readUserCallLog" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extensionNumber: string # Short extension number of a user. If specified, returns call log for this particular extension only. Cannot be combined with `phoneNumber` filter  (e.g. 101)
  --phoneNumber: string # Phone number of a caller/callee in e.164 format without a '+' sign. If specified, all incoming/outgoing calls from/to this phone number are returned.  (e.g. 12053320032)
  --showBlocked: string@bool-completer # Indicates then calls from/to blocked numbers are returned (default: true)
  --direction: list # The direction of call records to be included in the result. If omitted, both inbound and outbound calls are returned. Multiple values are supported
  --sessionId: string # Internal identifier of a call session
  --type: list # The type of call records to be included in the result. If omitted, all call types are returned. Multiple values are supported
  --transport: list # The type of call transport. Multiple values are supported. By default, this filter is disabled
  --view: string@view-completer # Defines the level of details for returned call records  (default: Simple)
  --withRecording: string@bool-completer # Deprecated, replaced with `recordingType` filter, still supported for compatibility reasons. Indicates if only recorded calls should be returned.  If both `withRecording` and `recordingType` parameters are specified, then `withRecording` is ignored  (DEPRECATED, default: false)
  --recordingType: string@recordingType-completer # Indicates that call records with recordings of particular type should be returned. If omitted, then calls with and without recordings are returned
  --dateTo: string # The end of the time range to return call records in ISO 8601 format including timezone, for example 2016-03-10T18:07:52.534Z. The default value is current time  (format: date-time)
  --dateFrom: string # The beginning of the time range to return call records in ISO 8601 format including timezone, for example 2016-03-10T18:07:52.534Z. The default value is `dateTo` minus 24 hours  (format: date-time)
  --telephonySessionId: string # Internal identifier of a telephony session
  --page: int # Indicates the page number to retrieve. Only positive number values are allowed (format: int32, default: 1)
  --perPage: int # Indicates the page size (number of items). The default value is 100. The maximum value for `Simple` view is 1000, for `Detailed` view - 250  (format: int32, default: 100)
  --showDeleted: string@bool-completer # Indicates that deleted calls records should be returned (default: false)
]: nothing -> record<uri: string, records: table<extension: record, telephonySessionId: string, sipUuidInfo: string, transferTarget: record, transferee: record, partyId: string, transport: string, from: record, to: record, type: string, direction: string, message: record, delegate: record, delegationType: string, action: string, result: string, reason: string, reasonDescription: string, startTime: string, duration: int, durationMs: int, recording: record, shortRecording: bool, billing: record, internalType: string, id: string, uri: string, sessionId: string, deleted: bool, legs: list, lastModifiedTime: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extensionNumber" $extensionNumber "scalar") (serialize-qp "phoneNumber" $phoneNumber "scalar") (serialize-qp "showBlocked" $showBlocked "scalar") (serialize-qp "direction" $direction "multi") (serialize-qp "sessionId" $sessionId "scalar") (serialize-qp "type" $type "multi") (serialize-qp "transport" $transport "multi") (serialize-qp "view" $view "scalar") (serialize-qp "withRecording" $withRecording "scalar") (serialize-qp "recordingType" $recordingType "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "telephonySessionId" $telephonySessionId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "showDeleted" $showDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/call-log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete User Call Records
#
# DELETE /restapi/v1.0/account/{accountId}/extension/{extensionId}/call-log
# operationId: deleteUserCallLog
export def "restapi-v10-account-extension-call-log delete" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dateTo: string # The time boundary to delete all older records in ISO 8601 format including timezone, for example *2016-03-10T18:07:52.534Z*. The default value is current time  (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateTo" $dateTo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/call-log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User Call Record(s)
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/call-log/{callRecordId}
# operationId: readUserCallRecord
export def "restapi-v10-account-extension-call-log readUserCallRecord" [
  accountId: string
  extensionId: string
  callRecordId: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --view: string@view-completer # Defines the level of details for returned call records  (default: Simple)
]: nothing -> record<extension: record<id: int, uri: string>, telephonySessionId: string, sipUuidInfo: string, transferTarget: record<telephonySessionId: string>, transferee: record<telephonySessionId: string>, partyId: string, transport: string, from: record<dialerPhoneNumber: string>, to: record<dialedPhoneNumber: string>, type: string, direction: string, message: record<id: string, type: string, uri: string>, delegate: record<id: string, name: string>, delegationType: string, action: string, result: string, reason: string, reasonDescription: string, startTime: string, duration: int, durationMs: int, recording: record<id: string, uri: string, type: string, contentUri: string>, shortRecording: bool, billing: record<costIncluded: float, costPurchased: float>, internalType: string, id: string, uri: string, sessionId: string, deleted: bool, legs: table<extension: record, telephonySessionId: string, sipUuidInfo: string, transferTarget: record, transferee: record, partyId: string, transport: string, from: record, to: record, type: string, direction: string, message: record, delegate: record, delegationType: string, action: string, result: string, reason: string, reasonDescription: string, startTime: string, duration: int, durationMs: int, recording: record, shortRecording: bool, billing: record, internalType: string, legType: string, master: bool>, lastModifiedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/call-log/($callRecordId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sync User Call Log
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/call-log-sync
# operationId: syncUserCallLog
@deprecated --flag withRecording
export def "restapi-v10-account-extension-call-log-sync syncUserCallLog" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --syncType: string # Type of call log synchronization request
  --syncToken: string # A `syncToken` value from the previous sync response (for `ISync` mode only, mandatory)
  --dateFrom: string # The start datetime for resulting records in ISO 8601 format including timezone, for example 2016-03-10T18:07:52.534Z. The default value is the current moment  (format: date-time)
  --recordCount: int # For `FSync` mode this parameter is mandatory, it limits the number of records to be returned in response.  For `ISync` mode this parameter specifies the number of records to extend the sync frame with to the past (the maximum number of records is 250)  (format: int32)
  --statusGroup: list # Type of calls to be returned
  --view: string@view-completer # Defines the level of details for returned call records  (default: Simple)
  --showDeleted: string@bool-completer # Supported for `ISync` mode. Indicates that deleted call records should be returned (default: false)
  --withRecording: string@bool-completer # Deprecated, replaced with `recordingType` filter, still supported for compatibility reasons. Indicates if only recorded calls should be returned.  If both `withRecording` and `recordingType` parameters are specified, then `withRecording` is ignored  (DEPRECATED, default: false)
  --recordingType: string@recordingType-completer # Indicates that call records with recordings of particular type should be returned. If omitted, then calls with and without recordings are returned
]: nothing -> record<uri: string, records: table<extension: record, telephonySessionId: string, sipUuidInfo: string, transferTarget: record, transferee: record, partyId: string, transport: string, from: record, to: record, type: string, direction: string, message: record, delegate: record, delegationType: string, action: string, result: string, reason: string, reasonDescription: string, startTime: string, duration: int, durationMs: int, recording: record, shortRecording: bool, billing: record, internalType: string, id: string, uri: string, sessionId: string, deleted: bool, legs: list, lastModifiedTime: string>, syncInfo: record<syncType: string, syncToken: string, syncTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "syncType" $syncType "scalar") (serialize-qp "syncToken" $syncToken "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "recordCount" $recordCount "scalar") (serialize-qp "statusGroup" $statusGroup "multi") (serialize-qp "view" $view "scalar") (serialize-qp "showDeleted" $showDeleted "scalar") (serialize-qp "withRecording" $withRecording "scalar") (serialize-qp "recordingType" $recordingType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/call-log-sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Assignable Roles
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/assignable-roles
# operationId: listOfAvailableForAssigningRoles
export def "restapi-v10-account-extension-assignable-roles listOfAvailableForAssigningRoles" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The result set page number (1-indexed) to return (format: int32, default: 1, e.g. 1)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
]: nothing -> record<uri: string, records: table<uri: string, id: string, displayName: string, description: string, siteCompatible: bool, custom: bool, scope: string, hidden: bool, lastUpdated: string, permissions: list>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/assignable-roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Active Calls
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/active-calls
# operationId: listExtensionActiveCalls
export def "restapi-v10-account-extension-active-calls listExtensionActiveCalls" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --direction: list # The direction of call records to be included in the result. If omitted, both inbound and outbound calls are returned. Multiple values are supported
  --view: string@view-completer # Defines the level of details for returned call records  (default: Simple)
  --type: list # The type of call records to be included in the result. If omitted, all call types are returned. Multiple values are supported
  --transport: list # The type of call transport. Multiple values are supported. By default, this filter is disabled
  --conferenceType: list # Conference call type: RCC or RC Meetings. If not specified, no conference call filter applied
  --page: int # Indicates the page number to retrieve. Only positive number values are allowed (format: int32, default: 1)
  --perPage: int # Indicates the page size (number of items) (format: int32, default: 100)
]: nothing -> record<uri: string, records: table<extension: record, telephonySessionId: string, sipUuidInfo: string, transferTarget: record, transferee: record, partyId: string, transport: string, from: record, to: record, type: string, direction: string, message: record, delegate: record, delegationType: string, action: string, result: string, reason: string, reasonDescription: string, startTime: string, duration: int, durationMs: int, recording: record, shortRecording: bool, billing: record, internalType: string, id: string, uri: string, sessionId: string, deleted: bool, legs: list, lastModifiedTime: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "multi") (serialize-qp "view" $view "scalar") (serialize-qp "type" $type "multi") (serialize-qp "transport" $transport "multi") (serialize-qp "conferenceType" $conferenceType "multi") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/active-calls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Extension Caller ID
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/caller-id
# operationId: readExtensionCallerId
export def "restapi-v10-account-extension-caller-id readExtensionCallerId" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, byDevice: table<device: record, callerId: record>, byFeature: table<feature: string, callerId: record>, extensionNameForOutboundCalls: bool, extensionNumberForInternalCalls: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/caller-id")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Extension Caller ID
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/caller-id
# operationId: updateExtensionCallerId
# --byDevice item shape: {device?: record, callerId?: record}
# --byFeature item shape: {feature?: "RingOut"|"RingMe"|"CallFlip"|"FaxNumber"|"AdditionalSoftphone"|"Alternate"|"CommonPhone"|"MobileApp"|"Delegated", callerId?: record}
export def "restapi-v10-account-extension-caller-id updateExtensionCallerId" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uri: string # Canonical URL of a caller ID resource (format: uri)
  --byDevice: list # item shape: {device?: record, callerId?: record}
  --byFeature: list # item shape: {feature?: "RingOut"|"RingMe"|"CallFlip"|"FaxNumber"|"AdditionalSoftphone"|"Alternate"|"CommonPhone"|"MobileApp"|"Delegated", callerId?: record}
  --extensionNameForOutboundCalls: string@bool-completer # If `true`, then the user first name and last name will be used as caller ID when making outbound calls from extension
  --extensionNumberForInternalCalls: string@bool-completer # If `true`, then extension number will be used as caller ID when making internal calls
]: any -> record<uri: string, byDevice: table<device: record, callerId: record>, byFeature: table<feature: string, callerId: record>, extensionNameForOutboundCalls: bool, extensionNumberForInternalCalls: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/caller-id")
  let body = {uri: $uri, byDevice: $byDevice, byFeature: $byFeature, extensionNameForOutboundCalls: $extensionNameForOutboundCalls, extensionNumberForInternalCalls: $extensionNumberForInternalCalls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Call Handling Rules
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/answering-rule
# operationId: listAnsweringRules
export def "restapi-v10-account-extension-answering-rule listAnsweringRules" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-13 # Filters custom call handling rules of the extension
  --view: string@view-completer # default: Simple
  --enabledOnly: string@bool-completer # If true, then only active call handling rules are returned (default: false)
  --page: int # The result set page number (1-indexed) to return (format: int32, default: 1, e.g. 1)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
]: nothing -> record<uri: string, records: table<uri: string, id: string, type: string, name: string, enabled: bool, schedule: record, calledNumbers: list, callers: list, callHandlingAction: string, forwarding: record, unconditionalForwarding: record, queue: record, transfer: record, voicemail: record, greetings: list, screening: string, sharedLines: record, missedCall: record>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "enabledOnly" $enabledOnly "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/answering-rule" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Call Handling Rule
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/answering-rule
# operationId: createAnsweringRule
# --callers item shape: {callerId?: string, name?: string}
# --calledNumbers item shape: {phoneNumber?: string}
# --schedule shape: {weeklyRanges?: record, ranges?: list, ref?: "BusinessHours"|"AfterHours"}
# --forwarding shape: {notifyMySoftPhones?: bool, notifyAdminSoftPhones?: bool, softPhonesRingCount?: int, softPhonesAlwaysRing?: bool, ringingMode?: "Sequentially"|"Simultaneously", rules?: list, softPhonesPositionTop?: bool, mobileTimeout?: bool}
# --unconditionalForwarding shape: {phoneNumber?: string, action?: "HoldTimeExpiration"|"MaxCallers"|"NoAnswer"}
# --queue shape: {transferMode?: "Rotating"|"Simultaneous"|"FixedOrder", transfer?: list, noAnswerAction?: "WaitPrimaryMembers"|"WaitPrimaryAndOverflowMembers"|"Voicemail"|"TransferToExtension"|"UnconditionalForwarding", fixedOrderAgents?: list, holdAudioInterruptionMode?: "Never"|"WhenMusicEnds"|"Periodically", holdAudioInterruptionPeriod?: int, holdTimeExpirationAction?: "TransferToExtension"|"UnconditionalForwarding"|"Voicemail", agentTimeout?: int, wrapUpTime?: int, holdTime?: int, maxCallers?: int, maxCallersAction?: "Voicemail"|"Announcement"|"TransferToExtension"|"UnconditionalForwarding", unconditionalForwarding?: list}
# --transfer shape: {extension?: record}
# --voicemail shape: {enabled?: bool, recipient?: record}
# --missedCall shape: {actionType?: "PlayGreetingAndDisconnect"|"ConnectToExtension"|"ConnectToExternalNumber", extension?: record}
# --greetings item shape: {type?: "Introductory"|"Announcement"|"AutomaticRecording"|"BlockedCallersAll"|"BlockedCallersSpecific"|"BlockedNoCallerId"|"BlockedPayPhones"|"ConnectingMessage"|"ConnectingAudio"|"StartRecording"|"StopRecording"|"Voicemail"|"Unavailable"|"InterruptPrompt"|"HoldMusic"|"Company", preset?: record, custom?: record}
export def "restapi-v10-account-extension-answering-rule createAnsweringRule" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Specifies if the rule is active or inactive. The default value is `true`
  type: string # Type of an answering rule. The 'Custom' value should be specified
  name: string # Name of an answering rule specified by user
  --callers: list # Answering rule will be applied when calls are received from the specified caller(s) — item shape: {callerId?: string, name?: string}
  --calledNumbers: list # Answering rules are applied when calling to selected number(s) — item shape: {phoneNumber?: string}
  --schedule: record # Schedule when an answering rule should be applied — shape: {weeklyRanges?: record, ranges?: list, ref?: "BusinessHours"|"AfterHours"}
  --callHandlingAction: string@callHandlingAction-completer-1 # Specifies how incoming calls are forwarded
  --forwarding: record # Forwarding parameters. Returned if 'ForwardCalls' is specified in 'callHandlingAction'. These settings determine the forwarding numbers to which the call will be forwarded — shape: {notifyMySoftPhones?: bool, notifyAdminSoftPhones?: bool, softPhonesRingCount?: int, softPhonesAlwaysRing?: bool, ringingMode?: "Sequentially"|"Simultaneously", rules?: list, softPhonesPositionTop?: bool, mobileTimeout?: bool}
  --unconditionalForwarding: record # Unconditional forwarding parameters. Returned if 'UnconditionalForwarding' value is specified for the `callHandlingAction` parameter — shape: {phoneNumber?: string, action?: "HoldTimeExpiration"|"MaxCallers"|"NoAnswer"}
  --queue: record # Queue settings applied for department (call queue) extension type, with the 'AgentQueue' value specified as a call handling action — shape: {transferMode?: "Rotating"|"Simultaneous"|"FixedOrder", transfer?: list, noAnswerAction?: "WaitPrimaryMembers"|"WaitPrimaryAndOverflowMembers"|"Voicemail"|"TransferToExtension"|"UnconditionalForwarding", fixedOrderAgents?: list, holdAudioInterruptionMode?: "Never"|"WhenMusicEnds"|"Periodically", holdAudioInterruptionPeriod?: int, holdTimeExpirationAction?: "TransferToExtension"|"UnconditionalForwarding"|"Voicemail", agentTimeout?: int, wrapUpTime?: int, holdTime?: int, maxCallers?: int, maxCallersAction?: "Voicemail"|"Announcement"|"TransferToExtension"|"UnconditionalForwarding", unconditionalForwarding?: list}
  --transfer: record # shape: {extension?: record}
  --voicemail: record # Specifies whether to take a voicemail and who should do it — shape: {enabled?: bool, recipient?: record}
  --missedCall: record # Specifies behavior for the missed call scenario. Returned only if `enabled` parameter of a voicemail is set to 'false' — shape: {actionType?: "PlayGreetingAndDisconnect"|"ConnectToExtension"|"ConnectToExternalNumber", extension?: record}
  --greetings: list # Greetings applied for an answering rule; only predefined greetings can be applied, see Dictionary Greeting List — item shape: {type?: "Introductory"|"Announcement"|"AutomaticRecording"|"BlockedCallersAll"|"BlockedCallersSpecific"|"BlockedNoCallerId"|"BlockedPayPhones"|"ConnectingMessage"|"ConnectingAudio"|"StartRecording"|"StopRecording"|"Voicemail"|"Unavailable"|"InterruptPrompt"|"HoldMusic"|"Company", preset?: record, custom?: record}
  --screening: string@screening-completer # Call screening status. 'Off' - no call screening; 'NoCallerId' - if caller ID is missing, then callers are asked to say their name before connecting; 'UnknownCallerId' - if caller ID is not in contact list, then callers are asked to say their name before connecting; 'Always' - the callers are always asked to say their name before connecting. The default value is 'Off'  (default: Off)
]: any -> record<uri: string, id: string, type: string, name: string, enabled: bool, schedule: record<weeklyRanges: record<monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, sunday: list>, ranges: list<record>, ref: string>, calledNumbers: table<phoneNumber: string>, callers: table<callerId: string, name: string>, callHandlingAction: string, forwarding: record<notifyMySoftPhones: bool, notifyAdminSoftPhones: bool, softPhonesRingCount: int, softPhonesAlwaysRing: bool, ringingMode: string, rules: list<record>, softPhonesPositionTop: bool, mobileTimeout: bool>, unconditionalForwarding: record<phoneNumber: string, action: string>, queue: record<transferMode: string, transfer: list<record>, noAnswerAction: string, fixedOrderAgents: list<record>, holdAudioInterruptionMode: string, holdAudioInterruptionPeriod: int, holdTimeExpirationAction: string, agentTimeout: int, wrapUpTime: int, holdTime: int, maxCallers: int, maxCallersAction: string, unconditionalForwarding: list<record>>, transfer: record<extension: record<id: string, uri: string>>, voicemail: record<enabled: bool, recipient: record<uri: string, id: string>>, greetings: table<type: string, preset: record, custom: record>, screening: string, sharedLines: record<timeout: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/answering-rule")
  let body = {enabled: $enabled, type: $type, name: $name, callers: $callers, calledNumbers: $calledNumbers, schedule: $schedule, callHandlingAction: $callHandlingAction, forwarding: $forwarding, unconditionalForwarding: $unconditionalForwarding, queue: $queue, transfer: $transfer, voicemail: $voicemail, missedCall: $missedCall, greetings: $greetings, screening: $screening} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Call Handling Rule
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/answering-rule/{ruleId}
# operationId: readAnsweringRule
export def "restapi-v10-account-extension-answering-rule readAnsweringRule" [
  accountId: string
  extensionId: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --showInactiveNumbers: string@bool-completer # Indicates whether inactive numbers should be returned or not (default: false)
]: nothing -> record<uri: string, id: string, type: string, name: string, enabled: bool, schedule: record<weeklyRanges: record<monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, sunday: list>, ranges: list<record>, ref: string>, calledNumbers: table<phoneNumber: string>, callers: table<callerId: string, name: string>, callHandlingAction: string, forwarding: record<notifyMySoftPhones: bool, notifyAdminSoftPhones: bool, softPhonesRingCount: int, softPhonesAlwaysRing: bool, ringingMode: string, rules: list<record>, softPhonesPositionTop: bool, mobileTimeout: bool>, unconditionalForwarding: record<phoneNumber: string, action: string>, queue: record<transferMode: string, transfer: list<record>, noAnswerAction: string, fixedOrderAgents: list<record>, holdAudioInterruptionMode: string, holdAudioInterruptionPeriod: int, holdTimeExpirationAction: string, agentTimeout: int, wrapUpTime: int, holdTime: int, maxCallers: int, maxCallersAction: string, unconditionalForwarding: list<record>>, transfer: record<extension: record<id: string, uri: string>>, voicemail: record<enabled: bool, recipient: record<uri: string, id: string>>, greetings: table<type: string, preset: record, custom: record>, screening: string, sharedLines: record<timeout: int>, missedCall: record<actionType: string, extension: record<id: string, externalNumber: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showInactiveNumbers" $showInactiveNumbers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/answering-rule/($ruleId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Call Handling Rule
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/answering-rule/{ruleId}
# operationId: updateAnsweringRule
# --forwarding shape: {notifyMySoftPhones?: bool, notifyAdminSoftPhones?: bool, softPhonesRingCount?: int, softPhonesAlwaysRing?: bool, ringingMode?: "Sequentially"|"Simultaneously", rules?: list, mobileTimeout?: bool}
# --callers item shape: {callerId?: string, name?: string}
# --calledNumbers item shape: {phoneNumber?: string}
# --schedule shape: {weeklyRanges?: record, ranges?: list, ref?: "BusinessHours"|"AfterHours"}
# --unconditionalForwarding shape: {phoneNumber?: string, action?: "HoldTimeExpiration"|"MaxCallers"|"NoAnswer"}
# --queue shape: {transferMode?: "Rotating"|"Simultaneous"|"FixedOrder", transfer?: list, noAnswerAction?: "WaitPrimaryMembers"|"WaitPrimaryAndOverflowMembers"|"Voicemail"|"TransferToExtension"|"UnconditionalForwarding", fixedOrderAgents?: list, holdAudioInterruptionMode?: "Never"|"WhenMusicEnds"|"Periodically", holdAudioInterruptionPeriod?: int, holdTimeExpirationAction?: "TransferToExtension"|"UnconditionalForwarding"|"Voicemail", agentTimeout?: int, wrapUpTime?: int, holdTime?: int, maxCallers?: int, maxCallersAction?: "Voicemail"|"Announcement"|"TransferToExtension"|"UnconditionalForwarding", unconditionalForwarding?: list}
# --voicemail shape: {enabled?: bool, recipient?: record}
# --missedCall shape: {actionType?: "PlayGreetingAndDisconnect"|"ConnectToExtension"|"ConnectToExternalNumber", extension?: record}
# --greetings item shape: {type?: "Introductory"|"Announcement"|"AutomaticRecording"|"BlockedCallersAll"|"BlockedCallersSpecific"|"BlockedNoCallerId"|"BlockedPayPhones"|"ConnectingMessage"|"ConnectingAudio"|"StartRecording"|"StopRecording"|"Voicemail"|"Unavailable"|"InterruptPrompt"|"HoldMusic"|"Company", preset?: record, custom?: record}
# --transfer shape: {extension?: record}
export def "restapi-v10-account-extension-answering-rule updateAnsweringRule" [
  accountId: string
  extensionId: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Identifier of an answering rule
  --forwarding: record # Forwarding parameters. Returned if 'ForwardCalls' is specified in 'callHandlingAction'. These settings determine the forwarding numbers to which the call will be forwarded — shape: {notifyMySoftPhones?: bool, notifyAdminSoftPhones?: bool, softPhonesRingCount?: int, softPhonesAlwaysRing?: bool, ringingMode?: "Sequentially"|"Simultaneously", rules?: list, mobileTimeout?: bool}
  --enabled: string@bool-completer # Specifies if the rule is active or inactive. The default value is `true`
  --name: string # Name of an answering rule specified by user
  --callers: list # Answering rule will be applied when calls are received from the specified caller(s) — item shape: {callerId?: string, name?: string}
  --calledNumbers: list # Answering rules are applied when calling to selected number(s) — item shape: {phoneNumber?: string}
  --schedule: record # Schedule when an answering rule should be applied — shape: {weeklyRanges?: record, ranges?: list, ref?: "BusinessHours"|"AfterHours"}
  --callHandlingAction: string@callHandlingAction-completer-1 # Specifies how incoming calls are forwarded
  --type: string@type-completer-7 # Type of an answering rule
  --unconditionalForwarding: record # Unconditional forwarding parameters. Returned if 'UnconditionalForwarding' value is specified for the `callHandlingAction` parameter — shape: {phoneNumber?: string, action?: "HoldTimeExpiration"|"MaxCallers"|"NoAnswer"}
  --queue: record # Queue settings applied for department (call queue) extension type, with the 'AgentQueue' value specified as a call handling action — shape: {transferMode?: "Rotating"|"Simultaneous"|"FixedOrder", transfer?: list, noAnswerAction?: "WaitPrimaryMembers"|"WaitPrimaryAndOverflowMembers"|"Voicemail"|"TransferToExtension"|"UnconditionalForwarding", fixedOrderAgents?: list, holdAudioInterruptionMode?: "Never"|"WhenMusicEnds"|"Periodically", holdAudioInterruptionPeriod?: int, holdTimeExpirationAction?: "TransferToExtension"|"UnconditionalForwarding"|"Voicemail", agentTimeout?: int, wrapUpTime?: int, holdTime?: int, maxCallers?: int, maxCallersAction?: "Voicemail"|"Announcement"|"TransferToExtension"|"UnconditionalForwarding", unconditionalForwarding?: list}
  --voicemail: record # Specifies whether to take a voicemail and who should do it — shape: {enabled?: bool, recipient?: record}
  --missedCall: record # Specifies behavior for the missed call scenario. Returned only if `enabled` parameter of a voicemail is set to 'false' — shape: {actionType?: "PlayGreetingAndDisconnect"|"ConnectToExtension"|"ConnectToExternalNumber", extension?: record}
  --greetings: list # Greetings applied for an answering rule; only predefined greetings can be applied, see Dictionary Greeting List — item shape: {type?: "Introductory"|"Announcement"|"AutomaticRecording"|"BlockedCallersAll"|"BlockedCallersSpecific"|"BlockedNoCallerId"|"BlockedPayPhones"|"ConnectingMessage"|"ConnectingAudio"|"StartRecording"|"StopRecording"|"Voicemail"|"Unavailable"|"InterruptPrompt"|"HoldMusic"|"Company", preset?: record, custom?: record}
  --screening: string@screening-completer # Call screening status. 'Off' - no call screening; 'NoCallerId' - if caller ID is missing, then callers are asked to say their name before connecting; 'UnknownCallerId' - if caller ID is not in contact list, then callers are asked to say their name before connecting; 'Always' - the callers are always asked to say their name before connecting. The default value is 'Off'  (default: Off)
  --showInactiveNumbers: string@bool-completer # Indicates whether inactive numbers should be returned or not
  --transfer: record # shape: {extension?: record}
]: any -> record<uri: string, id: string, type: string, name: string, enabled: bool, schedule: record<weeklyRanges: record<monday: list, tuesday: list, wednesday: list, thursday: list, friday: list, saturday: list, sunday: list>, ranges: list<record>, ref: string>, calledNumbers: table<phoneNumber: string>, callers: table<callerId: string, name: string>, callHandlingAction: string, forwarding: record<notifyMySoftPhones: bool, notifyAdminSoftPhones: bool, softPhonesRingCount: int, softPhonesAlwaysRing: bool, ringingMode: string, rules: list<record>, softPhonesPositionTop: bool, mobileTimeout: bool>, unconditionalForwarding: record<phoneNumber: string, action: string>, queue: record<transferMode: string, transfer: list<record>, noAnswerAction: string, fixedOrderAgents: list<record>, holdAudioInterruptionMode: string, holdAudioInterruptionPeriod: int, holdTimeExpirationAction: string, agentTimeout: int, wrapUpTime: int, holdTime: int, maxCallers: int, maxCallersAction: string, unconditionalForwarding: list<record>>, transfer: record<extension: record<id: string, uri: string>>, voicemail: record<enabled: bool, recipient: record<uri: string, id: string>>, greetings: table<type: string, preset: record, custom: record>, screening: string, sharedLines: record<timeout: int>, missedCall: record<actionType: string, extension: record<id: string, externalNumber: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/answering-rule/($ruleId)")
  let body = {id: $id, forwarding: $forwarding, enabled: $enabled, name: $name, callers: $callers, calledNumbers: $calledNumbers, schedule: $schedule, callHandlingAction: $callHandlingAction, type: $type, unconditionalForwarding: $unconditionalForwarding, queue: $queue, voicemail: $voicemail, missedCall: $missedCall, greetings: $greetings, screening: $screening, showInactiveNumbers: $showInactiveNumbers, transfer: $transfer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Call Handling Rule
#
# DELETE /restapi/v1.0/account/{accountId}/extension/{extensionId}/answering-rule/{ruleId}
# operationId: deleteAnsweringRule
export def "restapi-v10-account-extension-answering-rule delete" [
  accountId: string
  extensionId: string
  ruleId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/answering-rule/($ruleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Internal Text Message
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/company-pager
# operationId: createInternalTextMessage
# --from shape: {extensionId?: string, extensionNumber?: string}
# --to item shape: {extensionId?: string, extensionNumber?: string}
export def "restapi-v10-account-extension-company-pager createInternalTextMessage" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-from: record # Sender of a pager message. — shape: {extensionId?: string, extensionNumber?: string}
  --replyOn: int # Internal identifier of a message this message replies to (format: int32)
  text: string # Text of a pager message. Max length is 1024 symbols (2-byte UTF-16 encoded). If a character is encoded in 4 bytes in UTF-16 it is treated as 2 characters, thus restricting the maximum message length to 512 symbols  (e.g. hello world)
  --body-to: list # Optional if `replyOn` parameter is specified. Receiver of a pager message. — item shape: {extensionId?: string, extensionNumber?: string}
]: any -> record<id: int, uri: string, attachments: table<id: int, uri: string, type: string, contentType: string, vmDuration: int, fileName: string, size: int, height: int, width: int>, availability: string, conversationId: int, conversation: record<id: string, uri: string>, creationTime: string, direction: string, from: record<extensionNumber: string, extensionId: string, location: string, name: string, phoneNumber: string>, lastModifiedTime: string, messageStatus: string, pgToDepartment: bool, priority: string, readStatus: string, subject: string, to: table<extensionNumber: string, extensionId: string, location: string, target: bool, messageStatus: string, faxErrorCode: string, name: string, phoneNumber: string, recipientId: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/company-pager")
  let body = {from: $body_from, replyOn: $replyOn, text: $text, to: $body_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Authorization Profile
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/authz-profile
# operationId: readAuthorizationProfile
export def "restapi-v10-account-extension-authz-profile readAuthorizationProfile" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --targetExtensionId: string
]: nothing -> record<uri: string, permissions: table<permission: record, effectiveRole: record, scopes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "targetExtensionId" $targetExtensionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/authz-profile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check User Permission
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/authz-profile/check
# operationId: checkUserPermission
export def "restapi-v10-account-extension-authz-profile-check checkUserPermission" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permissionId: string
  --targetExtensionId: string
]: nothing -> record<uri: string, successful: bool, details: record<permission: record<uri: string, id: string, siteCompatible: string, readOnly: bool, assignable: bool, permissionsCapabilities: record>, effectiveRole: record<uri: string, id: string>, scopes: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permissionId" $permissionId "scalar") (serialize-qp "targetExtensionId" $targetExtensionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/authz-profile/check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User Call Queues
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/call-queues
# operationId: updateUserCallQueues
# --records item shape: {id?: string, name?: string}
export def "restapi-v10-account-extension-call-queues updateUserCallQueues" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --records: list # List of queues where an extension is an agent — item shape: {id?: string, name?: string}
]: any -> record<records: table<id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/call-queues")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List User Emergency Locations
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/emergency-locations
# operationId: getExtensionEmergencyLocations
export def "restapi-v10-account-extension-emergency-locations list" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --siteId: list # Internal identifier of a site for filtering. To indicate company main site `main-site` value should be specified. Supported only if multi-site feature is enabled for the account. Multiple values are supported.
  --searchString: string # Filters entries by the specified substring (search by chassis ID, switch name or address) The characters range is 0-64 (if empty the filter is ignored)
  --domesticCountryId: string
  --orderBy: string@orderBy-completer-1 # Comma-separated list of fields to order results prefixed by '+' sign (ascending order) or '-' sign (descending order). The default sorting is by `name`  (default: +visibility)
  --perPage: int # Indicates a page size (number of items). The values supported: `Max` or numeric value. If not specified, 100 records are returned per one page  (format: int32)
  --page: int # Indicates a page number to retrieve. Only positive number values are supported  (format: int32, default: 1)
  --visibility: string
]: nothing -> record<records: table<id: string, address: any, name: string, site: record, addressStatus: string, usageStatus: string, syncStatus: string, addressType: string, visibility: string, owners: list, addressFormatId: string>, paging: record<page: int, totalPages: int, perPage: int, totalElements: int, pageStart: int, pageEnd: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "siteId" $siteId "multi") (serialize-qp "searchString" $searchString "scalar") (serialize-qp "domesticCountryId" $domesticCountryId "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "visibility" $visibility "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/emergency-locations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create User Emergency Location
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/emergency-locations
# operationId: createExtensionEmergencyLocation
export def "restapi-v10-account-extension-emergency-locations createExtensionEmergencyLocation" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of a new personal emergency response location
  --addressFormatId: string # Address format ID
  --trusted: string@bool-completer # If 'true' address validation for non-us addresses is skipped
  --address: any
]: any -> record<id: string, address: any, name: string, site: record<id: string, name: string>, addressStatus: string, usageStatus: string, syncStatus: string, addressType: string, visibility: string, owners: table<id: string, extensionNumber: string, name: string>, addressFormatId: string, trusted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/emergency-locations")
  let body = {name: $name, addressFormatId: $addressFormatId, trusted: $trusted, address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update User Emergency Location
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/emergency-locations/{locationId}
# operationId: updateExtensionEmergencyLocation
# --site shape: {id?: string, name?: string}
export def "restapi-v10-account-extension-emergency-locations updateExtensionEmergencyLocation" [
  accountId: string
  extensionId: string
  locationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Internal identifier of an emergency response location
  --address: any
  --name: string # Emergency response location name
  --site: record # shape: {id?: string, name?: string}
  --addressStatus: string@addressStatus-completer # Emergency address status
  --usageStatus: string@usageStatus-completer # Status of an emergency response location usage.
  --addressFormatId: string # Address format ID
  --visibility: string@visibility-completer # Visibility of an emergency response location. If `Private` is set, then a location is visible only for restricted number of users, specified in `owners` array  (default: Public)
  --trusted: string@bool-completer # If 'true' address validation for non-us addresses is skipped
]: any -> record<id: string, address: any, name: string, site: record<id: string, name: string>, addressStatus: string, usageStatus: string, syncStatus: string, addressType: string, visibility: string, owners: table<id: string, extensionNumber: string, name: string>, addressFormatId: string, trusted: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/emergency-locations/($locationId)")
  let body = {id: $id, address: $address, name: $name, site: $site, addressStatus: $addressStatus, usageStatus: $usageStatus, addressFormatId: $addressFormatId, visibility: $visibility, trusted: $trusted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete User Emergency Location
#
# DELETE /restapi/v1.0/account/{accountId}/extension/{extensionId}/emergency-locations/{locationId}
# operationId: deleteExtensionEmergencyLocation
export def "restapi-v10-account-extension-emergency-locations delete" [
  accountId: string
  extensionId: string
  locationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --validateOnly: string@bool-completer # Flag indicating that only validation of Emergency Response Locations to be deleted is required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "validateOnly" $validateOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/emergency-locations/($locationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User Emergency Location
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/emergency-locations/{locationId}
# operationId: getExtensionEmergencyLocation
export def "restapi-v10-account-extension-emergency-locations get" [
  accountId: string
  extensionId: string
  locationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, address: any, name: string, site: record<id: string, name: string>, addressStatus: string, usageStatus: string, syncStatus: string, addressType: string, visibility: string, owners: table<id: string, extensionNumber: string, name: string>, addressFormatId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/emergency-locations/($locationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Forwarding Numbers
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/forwarding-number
# operationId: listForwardingNumbers
export def "restapi-v10-account-extension-forwarding-number listForwardingNumbers" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The result set page number (1-indexed) to return (format: int32, default: 1, e.g. 1)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
]: nothing -> record<uri: string, records: table<id: string, uri: string, phoneNumber: string, label: string, features: list, flipNumber: string, device: record, type: string, extension: record>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/forwarding-number" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Forwarding Number
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/forwarding-number
# operationId: createForwardingNumber
# --device shape: {id?: string}
export def "restapi-v10-account-extension-forwarding-number createForwardingNumber" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --flipNumber: int # Number assigned to the call flip phone number, corresponds to the shortcut dial number (format: int32)
  --phoneNumber: string # Forwarding/Call flip phone number
  --label: string # Forwarding/Call flip number title
  --type: string@type-completer-14 # Forwarding/Call flip phone type. If specified, 'label' attribute value is ignored. The default value is 'Other'
  --device: record # Forwarding device information. Applicable for 'PhoneLine' type only. Cannot be specified together with 'phoneNumber' parameter — shape: {id?: string}
]: any -> record<id: string, uri: string, phoneNumber: string, label: string, features: list<string>, flipNumber: string, device: record<id: string>, type: string, extension: record<id: string, extensionNumber: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/forwarding-number")
  let body = {flipNumber: $flipNumber, phoneNumber: $phoneNumber, label: $label, type: $type, device: $device} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Forwarding Numbers
#
# DELETE /restapi/v1.0/account/{accountId}/extension/{extensionId}/forwarding-number
# operationId: deleteForwardingNumbers
# --records item shape: {forwardingNumberId?: string}
export def "restapi-v10-account-extension-forwarding-number delete-by-accountId-extensionId" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --records: list # List of forwarding number IDs — item shape: {forwardingNumberId?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/forwarding-number")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Forwarding Number
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/forwarding-number/{forwardingNumberId}
# operationId: readForwardingNumber
export def "restapi-v10-account-extension-forwarding-number readForwardingNumber" [
  accountId: string
  extensionId: string
  forwardingNumberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, phoneNumber: string, label: string, features: list<string>, flipNumber: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/forwarding-number/($forwardingNumberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Forwarding Number
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/forwarding-number/{forwardingNumberId}
# operationId: updateForwardingNumber
export def "restapi-v10-account-extension-forwarding-number updateForwardingNumber" [
  accountId: string
  extensionId: string
  forwardingNumberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --phoneNumber: string # Forwarding/Call flip phone number
  --label: string # Forwarding/Call flip number title
  --flipNumber: string # Number assigned to the call flip phone number, corresponds to the shortcut dial number
  --type: string@type-completer-15 # Forwarding phone number type
]: any -> record<id: string, uri: string, phoneNumber: string, label: string, features: list<string>, flipNumber: string, device: record<id: string>, type: string, extension: record<id: string, extensionNumber: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/forwarding-number/($forwardingNumberId)")
  let body = {phoneNumber: $phoneNumber, label: $label, flipNumber: $flipNumber, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Forwarding Number
#
# DELETE /restapi/v1.0/account/{accountId}/extension/{extensionId}/forwarding-number/{forwardingNumberId}
# operationId: deleteForwardingNumber
export def "restapi-v10-account-extension-forwarding-number delete-by-accountId-extensionId-forwardingNumberId" [
  accountId: string
  extensionId: string
  forwardingNumberId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/forwarding-number/($forwardingNumberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Scheduled Meetings
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/meeting
# DEPRECATED
# operationId: listMeetings
@deprecated
export def "restapi-v10-account-extension-meeting listMeetings" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, records: table<uri: string, uuid: string, id: string, topic: string, meetingType: string, password: string, h323Password: string, status: string, links: record, schedule: record, host: record, allowJoinBeforeHost: bool, startHostVideo: bool, startParticipantsVideo: bool, audioOptions: list, recurrence: record, autoRecordType: string, enforceLogin: bool, muteParticipantsOnEntry: bool, occurrences: list, enableWaitingRoom: bool, globalDialInCountries: list, alternativeHosts: string>, paging: record<page: int, totalPages: int, perPage: int, totalElements: int, pageStart: int, pageEnd: int>, navigation: record<nextPage: record<uri: string>, previousPage: record<uri: string>, firstPage: record<uri: string>, lastPage: record<uri: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/meeting")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Meeting
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/meeting
# DEPRECATED
# operationId: createMeeting
# --schedule shape: {startTime?: string, durationInMinutes?: int, timeZone?: record}
# --host shape: {uri?: string, id?: string}
# --recurrence shape: {frequency?: "Daily"|"Weekly"|"Monthly", interval?: int, weeklyByDays?: list, monthlyByDay?: int, monthlyByWeek?: "Last"|"First"|"Second"|"Third"|"Fourth", monthlyByWeekDay?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", count?: int, until?: string}
@deprecated
export def "restapi-v10-account-extension-meeting createMeeting" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --topic: string # Custom topic of a meeting
  --meetingType: string@meetingType-completer
  --schedule: record # Timing of a meeting — shape: {startTime?: string, durationInMinutes?: int, timeZone?: record}
  --password: string # Meeting password (format: password)
  --host: record # Meeting host information — shape: {uri?: string, id?: string}
  --allowJoinBeforeHost: string@bool-completer # default: false
  --startHostVideo: string@bool-completer # default: false
  --startParticipantsVideo: string@bool-completer # Starting meetings with participant video on/off (true/false) (default: false)
  --usePersonalMeetingId: string@bool-completer # If true, then personal user's meeting ID is applied for creation of this meeting
  --audioOptions: list
  --recurrence: record # shape: {frequency?: "Daily"|"Weekly"|"Monthly", interval?: int, weeklyByDays?: list, monthlyByDay?: int, monthlyByWeek?: "Last"|"First"|"Second"|"Third"|"Fourth", monthlyByWeekDay?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", count?: int, until?: string}
  --autoRecordType: string@autoRecordType-completer # Automatic record type (default: none)
  --enforceLogin: string@bool-completer # If true, then only signed-in users can join this meeting
  --muteParticipantsOnEntry: string@bool-completer # If true, then participants are muted on entry
  --enableWaitingRoom: string@bool-completer # If true, then the waiting room for participants is enabled
  --globalDialInCountries: list # List of global dial-in countries (eg. US, UK, AU, etc.)
  --alternativeHosts: string
]: any -> record<uri: string, uuid: string, id: string, topic: string, meetingType: string, password: string, h323Password: string, status: string, links: record<startUri: string, joinUri: string>, schedule: record<startTime: string, durationInMinutes: int, timeZone: record<uri: string, id: string, name: string, description: string>>, host: record<uri: string, id: string>, allowJoinBeforeHost: bool, startHostVideo: bool, startParticipantsVideo: bool, audioOptions: list<string>, recurrence: record<frequency: string, interval: int, weeklyByDays: list<string>, monthlyByDay: int, monthlyByWeek: string, monthlyByWeekDay: string, count: int, until: string>, autoRecordType: string, enforceLogin: bool, muteParticipantsOnEntry: bool, occurrences: table<id: string, startTime: string, durationInMinutes: int, status: string>, enableWaitingRoom: bool, globalDialInCountries: list<string>, alternativeHosts: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/meeting")
  let body = {topic: $topic, meetingType: $meetingType, schedule: $schedule, password: $password, host: $host, allowJoinBeforeHost: $allowJoinBeforeHost, startHostVideo: $startHostVideo, startParticipantsVideo: $startParticipantsVideo, usePersonalMeetingId: $usePersonalMeetingId, audioOptions: $audioOptions, recurrence: $recurrence, autoRecordType: $autoRecordType, enforceLogin: $enforceLogin, muteParticipantsOnEntry: $muteParticipantsOnEntry, enableWaitingRoom: $enableWaitingRoom, globalDialInCountries: $globalDialInCountries, alternativeHosts: $alternativeHosts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Meeting User Settings
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/meeting/user-settings
# DEPRECATED
# operationId: getUserSetting
@deprecated
export def "restapi-v10-account-extension-meeting-user-settings get" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<recording: record<localRecording: bool, cloudRecording: bool, recordSpeakerView: bool, recordGalleryView: bool, recordAudioFile: bool, saveChatText: bool, showTimestamp: bool, autoRecording: string, autoDeleteCmr: string, autoDeleteCmrDays: int>, scheduleMeeting: record<enforceLogin: bool, startHostVideo: bool, startParticipantsVideo: bool, audioOptions: list<string>, allowJoinBeforeHost: bool, usePmiForScheduledMeetings: bool, usePmiForInstantMeetings: bool, requirePasswordForSchedulingNewMeetings: bool, requirePasswordForScheduledMeetings: bool, defaultPasswordForScheduledMeetings: string, requirePasswordForInstantMeetings: bool, requirePasswordForPmiMeetings: string, pmiPassword: string, pstnPasswordProtected: bool, muteParticipantsOnEntry: bool>, telephony: record<thirdPartyAudio: bool, audioConferenceInfo: bool, globalDialCountries: list<record>>, inMeetings: record<enableWaitingRoom: bool, breakoutRoom: bool, chat: bool, polling: bool, annotation: bool, virtualBackground: bool, screenSharing: bool, requestPermissionToUnmute: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/meeting/user-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Meeting Info
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/meeting/{meetingId}
# DEPRECATED
# operationId: readMeeting
@deprecated
export def "restapi-v10-account-extension-meeting readMeeting" [
  accountId: string
  extensionId: string
  meetingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, uuid: string, id: string, topic: string, meetingType: string, password: string, h323Password: string, status: string, links: record<startUri: string, joinUri: string>, schedule: record<startTime: string, durationInMinutes: int, timeZone: record<uri: string, id: string, name: string, description: string>>, host: record<uri: string, id: string>, allowJoinBeforeHost: bool, startHostVideo: bool, startParticipantsVideo: bool, audioOptions: list<string>, recurrence: record<frequency: string, interval: int, weeklyByDays: list<string>, monthlyByDay: int, monthlyByWeek: string, monthlyByWeekDay: string, count: int, until: string>, autoRecordType: string, enforceLogin: bool, muteParticipantsOnEntry: bool, occurrences: table<id: string, startTime: string, durationInMinutes: int, status: string>, enableWaitingRoom: bool, globalDialInCountries: list<string>, alternativeHosts: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/meeting/($meetingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Meeting
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/meeting/{meetingId}
# DEPRECATED
# operationId: updateMeeting
# --schedule shape: {startTime?: string, durationInMinutes?: int, timeZone?: record}
# --host shape: {uri?: string, id?: string}
# --recurrence shape: {frequency?: "Daily"|"Weekly"|"Monthly", interval?: int, weeklyByDays?: list, monthlyByDay?: int, monthlyByWeek?: "Last"|"First"|"Second"|"Third"|"Fourth", monthlyByWeekDay?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", count?: int, until?: string}
@deprecated
export def "restapi-v10-account-extension-meeting updateMeeting" [
  accountId: string
  extensionId: string
  meetingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --topic: string # Custom topic of a meeting
  --meetingType: string@meetingType-completer
  --schedule: record # Timing of a meeting — shape: {startTime?: string, durationInMinutes?: int, timeZone?: record}
  --password: string # Meeting password (format: password)
  --host: record # Meeting host information — shape: {uri?: string, id?: string}
  --allowJoinBeforeHost: string@bool-completer # default: false
  --startHostVideo: string@bool-completer # default: false
  --startParticipantsVideo: string@bool-completer # Starting meetings with participant video on/off (true/false) (default: false)
  --usePersonalMeetingId: string@bool-completer # If true, then personal user's meeting ID is applied for creation of this meeting
  --audioOptions: list
  --recurrence: record # shape: {frequency?: "Daily"|"Weekly"|"Monthly", interval?: int, weeklyByDays?: list, monthlyByDay?: int, monthlyByWeek?: "Last"|"First"|"Second"|"Third"|"Fourth", monthlyByWeekDay?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", count?: int, until?: string}
  --autoRecordType: string@autoRecordType-completer # Automatic record type (default: none)
  --enforceLogin: string@bool-completer # If true, then only signed-in users can join this meeting
  --muteParticipantsOnEntry: string@bool-completer # If true, then participants are muted on entry
  --enableWaitingRoom: string@bool-completer # If true, then the waiting room for participants is enabled
  --globalDialInCountries: list # List of global dial-in countries (eg. US, UK, AU, etc.)
  --alternativeHosts: string
]: any -> record<uri: string, uuid: string, id: string, topic: string, meetingType: string, password: string, h323Password: string, status: string, links: record<startUri: string, joinUri: string>, schedule: record<startTime: string, durationInMinutes: int, timeZone: record<uri: string, id: string, name: string, description: string>>, host: record<uri: string, id: string>, allowJoinBeforeHost: bool, startHostVideo: bool, startParticipantsVideo: bool, audioOptions: list<string>, recurrence: record<frequency: string, interval: int, weeklyByDays: list<string>, monthlyByDay: int, monthlyByWeek: string, monthlyByWeekDay: string, count: int, until: string>, autoRecordType: string, enforceLogin: bool, muteParticipantsOnEntry: bool, occurrences: table<id: string, startTime: string, durationInMinutes: int, status: string>, enableWaitingRoom: bool, globalDialInCountries: list<string>, alternativeHosts: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/meeting/($meetingId)")
  let body = {topic: $topic, meetingType: $meetingType, schedule: $schedule, password: $password, host: $host, allowJoinBeforeHost: $allowJoinBeforeHost, startHostVideo: $startHostVideo, startParticipantsVideo: $startParticipantsVideo, usePersonalMeetingId: $usePersonalMeetingId, audioOptions: $audioOptions, recurrence: $recurrence, autoRecordType: $autoRecordType, enforceLogin: $enforceLogin, muteParticipantsOnEntry: $muteParticipantsOnEntry, enableWaitingRoom: $enableWaitingRoom, globalDialInCountries: $globalDialInCountries, alternativeHosts: $alternativeHosts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Meeting
#
# DELETE /restapi/v1.0/account/{accountId}/extension/{extensionId}/meeting/{meetingId}
# DEPRECATED
# operationId: deleteMeeting
@deprecated
export def "restapi-v10-account-extension-meeting delete" [
  accountId: string
  extensionId: string
  meetingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --occurrenceId: string # Internal identifier of a recurrent meeting occurrence
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "occurrenceId" $occurrenceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/meeting/($meetingId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Meeting
#
# PATCH /restapi/v1.0/account/{accountId}/extension/{extensionId}/meeting/{meetingId}
# DEPRECATED
# operationId: patchMeeting
# --schedule shape: {startTime?: string, durationInMinutes?: int, timeZone?: record}
# --host shape: {uri?: string, id?: string}
# --recurrence shape: {frequency?: "Daily"|"Weekly"|"Monthly", interval?: int, weeklyByDays?: list, monthlyByDay?: int, monthlyByWeek?: "Last"|"First"|"Second"|"Third"|"Fourth", monthlyByWeekDay?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", count?: int, until?: string}
@deprecated
export def "restapi-v10-account-extension-meeting patch" [
  accountId: string
  extensionId: string
  meetingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --topic: string # Custom topic of a meeting
  --meetingType: string@meetingType-completer
  --schedule: record # Timing of a meeting — shape: {startTime?: string, durationInMinutes?: int, timeZone?: record}
  --password: string # Meeting password (format: password)
  --host: record # Meeting host information — shape: {uri?: string, id?: string}
  --allowJoinBeforeHost: string@bool-completer # default: false
  --startHostVideo: string@bool-completer # default: false
  --startParticipantsVideo: string@bool-completer # Starting meetings with participant video on/off (true/false) (default: false)
  --usePersonalMeetingId: string@bool-completer # If true, then personal user's meeting ID is applied for creation of this meeting
  --audioOptions: list
  --recurrence: record # shape: {frequency?: "Daily"|"Weekly"|"Monthly", interval?: int, weeklyByDays?: list, monthlyByDay?: int, monthlyByWeek?: "Last"|"First"|"Second"|"Third"|"Fourth", monthlyByWeekDay?: "Sunday"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"Saturday", count?: int, until?: string}
  --autoRecordType: string@autoRecordType-completer # Automatic record type (default: none)
  --enforceLogin: string@bool-completer # If true, then only signed-in users can join this meeting
  --muteParticipantsOnEntry: string@bool-completer # If true, then participants are muted on entry
  --enableWaitingRoom: string@bool-completer # If true, then the waiting room for participants is enabled
  --globalDialInCountries: list # List of global dial-in countries (eg. US, UK, AU, etc.)
  --alternativeHosts: string
]: any -> record<uri: string, uuid: string, id: string, topic: string, meetingType: string, password: string, h323Password: string, status: string, links: record<startUri: string, joinUri: string>, schedule: record<startTime: string, durationInMinutes: int, timeZone: record<uri: string, id: string, name: string, description: string>>, host: record<uri: string, id: string>, allowJoinBeforeHost: bool, startHostVideo: bool, startParticipantsVideo: bool, audioOptions: list<string>, recurrence: record<frequency: string, interval: int, weeklyByDays: list<string>, monthlyByDay: int, monthlyByWeek: string, monthlyByWeekDay: string, count: int, until: string>, autoRecordType: string, enforceLogin: bool, muteParticipantsOnEntry: bool, occurrences: table<id: string, startTime: string, durationInMinutes: int, status: string>, enableWaitingRoom: bool, globalDialInCountries: list<string>, alternativeHosts: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/meeting/($meetingId)")
  let body = {topic: $topic, meetingType: $meetingType, schedule: $schedule, password: $password, host: $host, allowJoinBeforeHost: $allowJoinBeforeHost, startHostVideo: $startHostVideo, startParticipantsVideo: $startParticipantsVideo, usePersonalMeetingId: $usePersonalMeetingId, audioOptions: $audioOptions, recurrence: $recurrence, autoRecordType: $autoRecordType, enforceLogin: $enforceLogin, muteParticipantsOnEntry: $muteParticipantsOnEntry, enableWaitingRoom: $enableWaitingRoom, globalDialInCountries: $globalDialInCountries, alternativeHosts: $alternativeHosts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# End Meeting
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/meeting/{meetingId}/end
# DEPRECATED
# operationId: endMeeting
@deprecated
export def "restapi-v10-account-extension-meeting-end endMeeting" [
  accountId: string
  extensionId: string
  meetingId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/meeting/($meetingId)/end")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Meeting Invitation
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/meeting/{meetingId}/invitation
# DEPRECATED
# operationId: readMeetingInvitation
@deprecated
export def "restapi-v10-account-extension-meeting-invitation readMeetingInvitation" [
  accountId: string
  extensionId: string
  meetingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<invitation: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/meeting/($meetingId)/invitation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Meeting Service Info
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/meeting/service-info
# DEPRECATED
# operationId: readMeetingServiceInfo
@deprecated
export def "restapi-v10-account-extension-meeting-service-info readMeetingServiceInfo" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, supportUri: string, intlDialInNumbersUri: string, externalUserInfo: record<uri: string, userId: string, accountId: string, userType: int, userToken: string, hostKey: string, personalMeetingId: string, personalLink: string, personalLinkName: string, usePmiForInstantMeetings: bool>, dialInNumbers: table<phoneNumber: string, formattedNumber: string, location: string, country: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/meeting/service-info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Meeting Service Info
#
# PATCH /restapi/v1.0/account/{accountId}/extension/{extensionId}/meeting/service-info
# DEPRECATED
# operationId: updateMeetingServiceInfo
# --externalUserInfo shape: {uri?: string, userId?: string, accountId?: string, userType?: int, userToken?: string, hostKey?: string, personalMeetingId?: string, personalLink?: string, personalLinkName?: string, usePmiForInstantMeetings?: bool}
@deprecated
export def "restapi-v10-account-extension-meeting-service-info updateMeetingServiceInfo" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --externalUserInfo: record # shape: {uri?: string, userId?: string, accountId?: string, userType?: int, userToken?: string, hostKey?: string, personalMeetingId?: string, personalLink?: string, personalLinkName?: string, usePmiForInstantMeetings?: bool}
]: any -> record<uri: string, supportUri: string, intlDialInNumbersUri: string, externalUserInfo: record<uri: string, userId: string, accountId: string, userType: int, userToken: string, hostKey: string, personalMeetingId: string, personalLink: string, personalLinkName: string, usePmiForInstantMeetings: bool>, dialInNumbers: table<phoneNumber: string, formattedNumber: string, location: string, country: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/meeting/service-info")
  let body = {externalUserInfo: $externalUserInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get User Presence Status
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/presence
# operationId: readUserPresenceStatus
export def "restapi-v10-account-extension-presence readUserPresenceStatus" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --detailedTelephonyState: string@bool-completer # Specifies whether to return a detailed telephony state or not
  --sipData: string@bool-completer # Specifies whether to return SIP data or not
]: nothing -> record<uri: string, allowSeeMyPresence: bool, callerIdVisibility: string, dndStatus: string, extension: record<id: int, uri: string, extensionNumber: string>, message: string, pickUpCallsOnHold: bool, presenceStatus: string, ringOnMonitoredCall: bool, telephonyStatus: string, userStatus: string, meetingStatus: string, activeCalls: table<id: string, direction: string, queueCall: bool, from: string, fromName: string, to: string, toName: string, startTime: string, telephonyStatus: string, sipData: record, sessionId: string, telephonySessionId: string, onBehalfOf: string, partyId: string, terminationType: string, callInfo: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detailedTelephonyState" $detailedTelephonyState "scalar") (serialize-qp "sipData" $sipData "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/presence" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User Presence Status
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/presence
# operationId: updateUserPresenceStatus
export def "restapi-v10-account-extension-presence updateUserPresenceStatus" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userStatus: string@userStatus-completer
  --dndStatus: string@dndStatus-completer
  --message: string
  --allowSeeMyPresence: string@bool-completer # default: false
  --ringOnMonitoredCall: string@bool-completer # default: false
  --pickUpCallsOnHold: string@bool-completer # default: false
  --callerIdVisibility: string@callerIdVisibility-completer # Configures the user presence visibility. When the `allowSeeMyPresence` parameter is set to `true`,  the following visibility options are supported via this parameter - All, None, PermittedUsers
]: any -> record<uri: string, userStatus: string, dndStatus: string, message: string, allowSeeMyPresence: bool, callerIdVisibility: string, ringOnMonitoredCall: bool, pickUpCallsOnHold: bool, activeCalls: table<id: string, direction: string, queueCall: bool, from: string, fromName: string, to: string, toName: string, startTime: string, telephonyStatus: string, sipData: record, sessionId: string, telephonySessionId: string, onBehalfOf: string, partyId: string, terminationType: string, callInfo: record>, extension: record<id: int, uri: string, extensionNumber: string>, meetingStatus: string, telephonyStatus: string, presenceStatus: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/presence")
  let body = {userStatus: $userStatus, dndStatus: $dndStatus, message: $message, allowSeeMyPresence: $allowSeeMyPresence, ringOnMonitoredCall: $ringOnMonitoredCall, pickUpCallsOnHold: $pickUpCallsOnHold, callerIdVisibility: $callerIdVisibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Fax Message
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/fax
# operationId: createFaxMessage
# --to item shape: {phoneNumber?: string, name?: string}
export def "restapi-v10-account-extension-fax createFaxMessage" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  attachment: string # File to upload (format: binary)
  --faxResolution: string@faxResolution-completer # Fax only. Resolution of a fax message. 'High' for black and white image scanned at 200 dpi, 'Low' for black and white image scanned at 100 dpi
  --body-to: list # Recipient's phone number(s) — item shape: {phoneNumber?: string, name?: string}
  --sendTime: string # Timestamp to send a fax at. If not specified, current or the past a fax message is sent immediately  (format: date-time)
  --isoCode: string # Alpha-2 ISO Code of a country (e.g. US)
  --coverIndex: int # Cover page identifier. If `coverIndex` is set to '0' (zero) a cover page is not attached. For a list of available cover page identifiers (1-13) please call the Fax Cover Pages method. If not specified, the default cover page is attached (which is configured in 'Outbound Fax Settings')  (format: int32)
  --coverPageText: string # Cover page text, entered by a fax sender and printed on a cover page. Maximum length is limited to 1024 symbols
]: any -> record<id: int, uri: string, type: string, from: record<extensionNumber: string, extensionId: string, location: string, name: string, phoneNumber: string>, to: table<recipientId: string, phoneNumber: string, name: string, messageStatus: string, location: string>, creationTime: string, readStatus: string, priority: string, attachments: table<id: int, uri: string, type: string, contentType: string, filename: string, size: int>, direction: string, availability: string, messageStatus: string, faxResolution: string, faxPageCount: int, lastModifiedTime: string, coverIndex: int, coverPageText: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/fax")
  let body = {attachment: $attachment, faxResolution: $faxResolution, to: $body_to, sendTime: $sendTime, isoCode: $isoCode, coverIndex: $coverIndex, coverPageText: $coverPageText} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Make RingOut Call
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/ring-out
# operationId: createRingOutCall
# --from shape: {phoneNumber?: string, forwardingNumberId?: string}
# --to shape: {phoneNumber?: string}
# --callerId shape: {phoneNumber?: string}
# --country shape: {id?: string}
export def "restapi-v10-account-extension-ring-out createRingOutCall" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-from: record # Phone number of a caller. This number corresponds to the 1st leg of a RingOut call. This number can be one of the user's configured forwarding numbers or an arbitrary number — shape: {phoneNumber?: string, forwardingNumberId?: string}
  --body-to: record # Phone number of a called party. This number corresponds to the 2nd leg of a RingOut call — shape: {phoneNumber?: string}
  --callerId: record # Phone number which will be displayed to the called party — shape: {phoneNumber?: string}
  --playPrompt: string@bool-completer # Audio prompt that a calling party hears when a call is connected
  --country: record # Optional. Dialing plan country data. If not specified, then an extension home country is applied by default — shape: {id?: string}
]: any -> record<id: string, uri: string, status: record<callStatus: string, callerStatus: string, calleeStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/ring-out")
  let body = {from: $body_from, to: $body_to, callerId: $callerId, playPrompt: $playPrompt, country: $country} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get RingOut Call Status
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/ring-out/{ringoutId}
# operationId: readRingOutCallStatus
export def "restapi-v10-account-extension-ring-out readRingOutCallStatus" [
  accountId: string
  extensionId: string
  ringoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uri: string, status: record<callStatus: string, callerStatus: string, calleeStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/ring-out/($ringoutId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel RingOut Call
#
# DELETE /restapi/v1.0/account/{accountId}/extension/{extensionId}/ring-out/{ringoutId}
# operationId: deleteRingOutCall
export def "restapi-v10-account-extension-ring-out delete" [
  accountId: string
  extensionId: string
  ringoutId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/ring-out/($ringoutId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Administered Sites
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/administered-sites
# operationId: listAdministeredSites
export def "restapi-v10-account-extension-administered-sites listAdministeredSites" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, records: table<uri: string, id: string, email: string, code: string, name: string, extensionNumber: string, callerIdName: string, operator: record, regionalSettings: record, businessAddress: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/administered-sites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User Administered Sites
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/administered-sites
# operationId: updateUserAdministeredSites
# --records item shape: {uri?: string, id: string, email?: string, code?: string, name?: string, extensionNumber?: string, callerIdName?: string, operator?: record, regionalSettings?: record, businessAddress?: record}
export def "restapi-v10-account-extension-administered-sites updateUserAdministeredSites" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --records: list # item shape: {uri?: string, id: string, email?: string, code?: string, name?: string, extensionNumber?: string, callerIdName?: string, operator?: record, regionalSettings?: record, businessAddress?: record}
]: any -> record<uri: string, records: table<uri: string, id: string, email: string, code: string, name: string, extensionNumber: string, callerIdName: string, operator: record, regionalSettings: record, businessAddress: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/administered-sites")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Contacts
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/address-book/contact
# operationId: listContacts
export def "restapi-v10-account-extension-address-book-contact listContacts" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startsWith: string # If specified, only contacts which 'First name' or 'Last name' start with the mentioned substring will be returned. Case-insensitive
  --sortBy: list # Sorts results by the specified property
  --page: int # The result set page number (1-indexed) to return (format: int32, default: 1, e.g. 1)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --phoneNumber: list # Phone number in e.164 format
]: nothing -> record<uri: string, records: table<uri: string, availability: string, email: string, id: int, notes: string, company: string, firstName: string, lastName: string, jobTitle: string, birthday: string, webPage: string, middleName: string, nickName: string, email2: string, email3: string, homePhone: string, homePhone2: string, businessPhone: string, businessPhone2: string, mobilePhone: string, businessFax: string, companyPhone: string, assistantPhone: string, carPhone: string, otherPhone: string, otherFax: string, callbackPhone: string, businessAddress: record, homeAddress: record, otherAddress: record, ringtoneIndex: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<page: int, perPage: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>, groups: record<uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startsWith" $startsWith "scalar") (serialize-qp "sortBy" $sortBy "multi") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "phoneNumber" $phoneNumber "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/address-book/contact" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create User Contact
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/address-book/contact
# operationId: createContact
# --homeAddress shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
# --businessAddress shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
# --otherAddress shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
export def "restapi-v10-account-extension-address-book-contact createContact" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dialingPlan: string # Country code value complying with the [ISO 3166-1 alpha-2](https://ru.wikipedia.org/wiki/ISO_3166-1_alpha-2) format. The default value is home country of the current extension
  --firstName: string # First name of a contact (e.g. Charlie)
  --lastName: string # Last name of a contact (e.g. Williams)
  --middleName: string # Middle name of a contact (e.g. J)
  --nickName: string # Nick name of a contact (e.g. The Boss)
  --company: string # Company name of a contact (e.g. Example, Inc.)
  --jobTitle: string # Job title of a contact (e.g. CEO)
  --email: string # Email of a contact (format: email, e.g. charlie.williams@example.com)
  --email2: string # Second email of a contact (format: email, e.g. charlie-example@gmail.com)
  --email3: string # Third email of a contact (format: email, e.g. theboss-example@hotmail.com)
  --birthday: string # Date of birth of a contact (format: date-time)
  --webPage: string # Contact home page URL (format: uri, e.g. http://www.example.com)
  --notes: string # Notes for a contact (e.g. #1 Customer)
  --homePhone: string # Home phone number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --homePhone2: string # Second home phone number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --businessPhone: string # Business phone of a contact in e.164 (with "+") format (e.g. +15551234567)
  --businessPhone2: string # Second business phone of a contact in e.164 (with "+") format (e.g. +15551234567)
  --mobilePhone: string # Mobile phone of a contact in e.164 (with "+") format (e.g. +15551234567)
  --businessFax: string # Business fax number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --companyPhone: string # Company number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --assistantPhone: string # Phone number of a contact assistant in e.164 (with "+") format (e.g. +15551234567)
  --carPhone: string # Car phone number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --otherPhone: string # Other phone number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --otherFax: string # Other fax number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --callbackPhone: string # Callback phone number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --homeAddress: record # shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
  --businessAddress: record # shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
  --otherAddress: record # shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
  --ringtoneIndex: string # Contact ringtone. Max number of symbols is 64
]: any -> record<uri: string, availability: string, email: string, id: int, notes: string, company: string, firstName: string, lastName: string, jobTitle: string, birthday: string, webPage: string, middleName: string, nickName: string, email2: string, email3: string, homePhone: string, homePhone2: string, businessPhone: string, businessPhone2: string, mobilePhone: string, businessFax: string, companyPhone: string, assistantPhone: string, carPhone: string, otherPhone: string, otherFax: string, callbackPhone: string, businessAddress: record<street: string, city: string, country: string, state: string, zip: string>, homeAddress: record<street: string, city: string, country: string, state: string, zip: string>, otherAddress: record<street: string, city: string, country: string, state: string, zip: string>, ringtoneIndex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dialingPlan" $dialingPlan "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/address-book/contact" $qp)
  let body = {firstName: $firstName, lastName: $lastName, middleName: $middleName, nickName: $nickName, company: $company, jobTitle: $jobTitle, email: $email, email2: $email2, email3: $email3, birthday: $birthday, webPage: $webPage, notes: $notes, homePhone: $homePhone, homePhone2: $homePhone2, businessPhone: $businessPhone, businessPhone2: $businessPhone2, mobilePhone: $mobilePhone, businessFax: $businessFax, companyPhone: $companyPhone, assistantPhone: $assistantPhone, carPhone: $carPhone, otherPhone: $otherPhone, otherFax: $otherFax, callbackPhone: $callbackPhone, homeAddress: $homeAddress, businessAddress: $businessAddress, otherAddress: $otherAddress, ringtoneIndex: $ringtoneIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get User Contact(s)
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/address-book/contact/{contactId}
# operationId: readContact
export def "restapi-v10-account-extension-address-book-contact readContact" [
  accountId: string
  extensionId: string
  contactId: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, availability: string, email: string, id: int, notes: string, company: string, firstName: string, lastName: string, jobTitle: string, birthday: string, webPage: string, middleName: string, nickName: string, email2: string, email3: string, homePhone: string, homePhone2: string, businessPhone: string, businessPhone2: string, mobilePhone: string, businessFax: string, companyPhone: string, assistantPhone: string, carPhone: string, otherPhone: string, otherFax: string, callbackPhone: string, businessAddress: record<street: string, city: string, country: string, state: string, zip: string>, homeAddress: record<street: string, city: string, country: string, state: string, zip: string>, otherAddress: record<street: string, city: string, country: string, state: string, zip: string>, ringtoneIndex: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/address-book/contact/($contactId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User Contact(s)
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/address-book/contact/{contactId}
# operationId: updateContact
# --homeAddress shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
# --businessAddress shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
# --otherAddress shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
export def "restapi-v10-account-extension-address-book-contact updateContact" [
  accountId: string
  extensionId: string
  contactId: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dialingPlan: string # Country code value complying with the [ISO 3166-1 alpha-2](https://ru.wikipedia.org/wiki/ISO_3166-1_alpha-2) format.  The default value is home country of the current extension
  --firstName: string # First name of a contact (e.g. Charlie)
  --lastName: string # Last name of a contact (e.g. Williams)
  --middleName: string # Middle name of a contact (e.g. J)
  --nickName: string # Nick name of a contact (e.g. The Boss)
  --company: string # Company name of a contact (e.g. Example, Inc.)
  --jobTitle: string # Job title of a contact (e.g. CEO)
  --email: string # Email of a contact (format: email, e.g. charlie.williams@example.com)
  --email2: string # Second email of a contact (format: email, e.g. charlie-example@gmail.com)
  --email3: string # Third email of a contact (format: email, e.g. theboss-example@hotmail.com)
  --birthday: string # Date of birth of a contact (format: date-time)
  --webPage: string # Contact home page URL (format: uri, e.g. http://www.example.com)
  --notes: string # Notes for a contact (e.g. #1 Customer)
  --homePhone: string # Home phone number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --homePhone2: string # Second home phone number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --businessPhone: string # Business phone of a contact in e.164 (with "+") format (e.g. +15551234567)
  --businessPhone2: string # Second business phone of a contact in e.164 (with "+") format (e.g. +15551234567)
  --mobilePhone: string # Mobile phone of a contact in e.164 (with "+") format (e.g. +15551234567)
  --businessFax: string # Business fax number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --companyPhone: string # Company number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --assistantPhone: string # Phone number of a contact assistant in e.164 (with "+") format (e.g. +15551234567)
  --carPhone: string # Car phone number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --otherPhone: string # Other phone number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --otherFax: string # Other fax number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --callbackPhone: string # Callback phone number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --homeAddress: record # shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
  --businessAddress: record # shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
  --otherAddress: record # shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
  --ringtoneIndex: string # Contact ringtone. Max number of symbols is 64
]: any -> record<uri: string, availability: string, email: string, id: int, notes: string, company: string, firstName: string, lastName: string, jobTitle: string, birthday: string, webPage: string, middleName: string, nickName: string, email2: string, email3: string, homePhone: string, homePhone2: string, businessPhone: string, businessPhone2: string, mobilePhone: string, businessFax: string, companyPhone: string, assistantPhone: string, carPhone: string, otherPhone: string, otherFax: string, callbackPhone: string, businessAddress: record<street: string, city: string, country: string, state: string, zip: string>, homeAddress: record<street: string, city: string, country: string, state: string, zip: string>, otherAddress: record<street: string, city: string, country: string, state: string, zip: string>, ringtoneIndex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dialingPlan" $dialingPlan "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/address-book/contact/($contactId)" $qp)
  let body = {firstName: $firstName, lastName: $lastName, middleName: $middleName, nickName: $nickName, company: $company, jobTitle: $jobTitle, email: $email, email2: $email2, email3: $email3, birthday: $birthday, webPage: $webPage, notes: $notes, homePhone: $homePhone, homePhone2: $homePhone2, businessPhone: $businessPhone, businessPhone2: $businessPhone2, mobilePhone: $mobilePhone, businessFax: $businessFax, companyPhone: $companyPhone, assistantPhone: $assistantPhone, carPhone: $carPhone, otherPhone: $otherPhone, otherFax: $otherFax, callbackPhone: $callbackPhone, homeAddress: $homeAddress, businessAddress: $businessAddress, otherAddress: $otherAddress, ringtoneIndex: $ringtoneIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Contact Attributes
#
# PATCH /restapi/v1.0/account/{accountId}/extension/{extensionId}/address-book/contact/{contactId}
# operationId: patchContact
# --homeAddress shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
# --businessAddress shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
# --otherAddress shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
export def "restapi-v10-account-extension-address-book-contact patch" [
  accountId: string
  extensionId: string
  contactId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dialingPlan: string # Country code value complying with the [ISO 3166-1 alpha-2](https://ru.wikipedia.org/wiki/ISO_3166-1_alpha-2) format. The default value is home country of the current extension
  --firstName: string # First name of a contact (e.g. Charlie)
  --lastName: string # Last name of a contact (e.g. Williams)
  --middleName: string # Middle name of a contact (e.g. J)
  --nickName: string # Nick name of a contact (e.g. The Boss)
  --company: string # Company name of a contact (e.g. Example, Inc.)
  --jobTitle: string # Job title of a contact (e.g. CEO)
  --email: string # Email of a contact (format: email, e.g. charlie.williams@example.com)
  --email2: string # Second email of a contact (format: email, e.g. charlie-example@gmail.com)
  --email3: string # Third email of a contact (format: email, e.g. theboss-example@hotmail.com)
  --birthday: string # Date of birth of a contact (format: date-time)
  --webPage: string # Contact home page URL (format: uri, e.g. http://www.example.com)
  --notes: string # Notes for a contact (e.g. #1 Customer)
  --homePhone: string # Home phone number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --homePhone2: string # Second home phone number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --businessPhone: string # Business phone of a contact in e.164 (with "+") format (e.g. +15551234567)
  --businessPhone2: string # Second business phone of a contact in e.164 (with "+") format (e.g. +15551234567)
  --mobilePhone: string # Mobile phone of a contact in e.164 (with "+") format (e.g. +15551234567)
  --businessFax: string # Business fax number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --companyPhone: string # Company number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --assistantPhone: string # Phone number of a contact assistant in e.164 (with "+") format (e.g. +15551234567)
  --carPhone: string # Car phone number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --otherPhone: string # Other phone number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --otherFax: string # Other fax number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --callbackPhone: string # Callback phone number of a contact in e.164 (with "+") format (e.g. +15551234567)
  --homeAddress: record # shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
  --businessAddress: record # shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
  --otherAddress: record # shape: {street?: string, city?: string, country?: string, state?: string, zip?: string}
  --ringtoneIndex: string # Contact ringtone. Max number of symbols is 64
]: any -> record<uri: string, availability: string, email: string, id: int, notes: string, company: string, firstName: string, lastName: string, jobTitle: string, birthday: string, webPage: string, middleName: string, nickName: string, email2: string, email3: string, homePhone: string, homePhone2: string, businessPhone: string, businessPhone2: string, mobilePhone: string, businessFax: string, companyPhone: string, assistantPhone: string, carPhone: string, otherPhone: string, otherFax: string, callbackPhone: string, businessAddress: record<street: string, city: string, country: string, state: string, zip: string>, homeAddress: record<street: string, city: string, country: string, state: string, zip: string>, otherAddress: record<street: string, city: string, country: string, state: string, zip: string>, ringtoneIndex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dialingPlan" $dialingPlan "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/address-book/contact/($contactId)" $qp)
  let body = {firstName: $firstName, lastName: $lastName, middleName: $middleName, nickName: $nickName, company: $company, jobTitle: $jobTitle, email: $email, email2: $email2, email3: $email3, birthday: $birthday, webPage: $webPage, notes: $notes, homePhone: $homePhone, homePhone2: $homePhone2, businessPhone: $businessPhone, businessPhone2: $businessPhone2, mobilePhone: $mobilePhone, businessFax: $businessFax, companyPhone: $companyPhone, assistantPhone: $assistantPhone, carPhone: $carPhone, otherPhone: $otherPhone, otherFax: $otherFax, callbackPhone: $callbackPhone, homeAddress: $homeAddress, businessAddress: $businessAddress, otherAddress: $otherAddress, ringtoneIndex: $ringtoneIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete User Contact(s)
#
# DELETE /restapi/v1.0/account/{accountId}/extension/{extensionId}/address-book/contact/{contactId}
# operationId: deleteContact
export def "restapi-v10-account-extension-address-book-contact delete" [
  accountId: string
  extensionId: string
  contactId: list
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/address-book/contact/($contactId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Assisted Users
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/meetings-configuration/assisted
# DEPRECATED
# operationId: readAssistedUsers
@deprecated
export def "restapi-v10-account-extension-meetings-configuration-assisted readAssistedUsers" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<records: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/meetings-configuration/assisted")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Assistants
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/meetings-configuration/assistants
# DEPRECATED
# operationId: readAssistants
@deprecated
export def "restapi-v10-account-extension-meetings-configuration-assistants readAssistants" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<records: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/meetings-configuration/assistants")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send SMS
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/sms
# operationId: createSMSMessage
# --from shape: {phoneNumber: string}
# --to item shape: {phoneNumber: string}
# --country shape: {id?: string, isoCode?: string}
export def "restapi-v10-account-extension-sms createSMSMessage" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-from: record # Message sender information. The `phoneNumber` value should be one the account phone numbers allowed to send the current type of messages — shape: {phoneNumber: string}
  --body-to: list # Message receiver(s) information. The `phoneNumber` value is required — item shape: {phoneNumber: string}
  text: string # Text of a message. Max length is 1000 symbols (2-byte UTF-16 encoded). If a character is encoded in 4 bytes in UTF-16 it is treated as 2 characters, thus restricting the maximum message length to 500 symbols
  --country: record # Target number country information. Either `id` or `isoCode` can be specified. — shape: {id?: string, isoCode?: string}
]: any -> record<id: int, uri: string, attachments: table<id: int, uri: string, type: string, contentType: string, vmDuration: int, fileName: string, size: int, height: int, width: int>, availability: string, conversationId: int, conversation: record<id: string, uri: string>, creationTime: string, deliveryErrorCode: string, direction: string, from: record<extensionNumber: string, extensionId: string, location: string, name: string, phoneNumber: string>, lastModifiedTime: string, messageStatus: string, priority: string, readStatus: string, smsDeliveryTime: string, smsSendingAttemptsCount: int, subject: string, to: table<extensionNumber: string, extensionId: string, location: string, target: bool, messageStatus: string, faxErrorCode: string, name: string, phoneNumber: string, recipientId: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/sms")
  let body = {from: $body_from, to: $body_to, text: $text, country: $country} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List User Assigned Roles
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/assigned-role
# operationId: listUserAssignedRoles
export def "restapi-v10-account-extension-assigned-role listUserAssignedRoles" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --showHidden: string@bool-completer # Specifies if hidden roles are shown or not
]: nothing -> record<uri: string, records: table<uri: string, id: string, autoAssigned: bool, displayName: string, siteCompatible: bool, siteRestricted: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showHidden" $showHidden "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/assigned-role" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update User Assigned Roles
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/assigned-role
# operationId: updateUserAssignedRoles
# --records item shape: {id?: string, autoAssigned?: bool, displayName?: string, siteCompatible?: bool, siteRestricted?: bool}
export def "restapi-v10-account-extension-assigned-role updateUserAssignedRoles" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --uri: string # format: uri
  --records: list # item shape: {id?: string, autoAssigned?: bool, displayName?: string, siteCompatible?: bool, siteRestricted?: bool}
]: any -> record<uri: string, records: table<uri: string, id: string, autoAssigned: bool, displayName: string, siteCompatible: bool, siteRestricted: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/assigned-role")
  let body = {uri: $uri, records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign Default Role
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/assigned-role/default
# operationId: assignDefaultRole
export def "restapi-v10-account-extension-assigned-role-default assignDefaultRole" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, records: table<uri: string, id: string, autoAssigned: bool, displayName: string, siteCompatible: bool, siteRestricted: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/assigned-role/default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List User Meeting Recordings
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/meeting-recordings
# DEPRECATED
# operationId: listUserMeetingRecordings
@deprecated
export def "restapi-v10-account-extension-meeting-recordings listUserMeetingRecordings" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --meetingId: string # Internal identifier of a meeting. Either `meetingId` or `meetingStartTime`/`meetingEndTime` can be specified
  --meetingStartTimeFrom: string # Recordings of meetings started after the time specified will be returned. Either `meetingId` or `meetingStartTime`/`meetingEndTime` can be specified (format: date-time)
  --meetingStartTimeTo: string # Recordings of meetings started before the time specified will be returned. The default value is current time. Either `meetingId` or `meetingStartTime`/`meetingEndTime` can be specified (format: date-time)
  --page: int # Page number (format: int32)
  --perPage: int # Number of items per page. The `max` value is supported to indicate the maximum size - 300 (format: int32, default: 100)
]: nothing -> record<records: table<meeting: record, recordings: list>, paging: record<page: int, perPage: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "meetingId" $meetingId "scalar") (serialize-qp "meetingStartTimeFrom" $meetingStartTimeFrom "scalar") (serialize-qp "meetingStartTimeTo" $meetingStartTimeTo "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/meeting-recordings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Notification Settings
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/notification-settings
# operationId: readNotificationSettings
export def "restapi-v10-account-extension-notification-settings readNotificationSettings" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, emailRecipients: table<extensionId: string, fullName: string, extensionNumber: string, status: string, emailAddresses: list, permission: string>, emailAddresses: list<string>, includeManagers: bool, smsEmailAddresses: list<string>, advancedMode: bool, voicemails: record<notifyByEmail: bool, notifyBySms: bool, advancedEmailAddresses: list<string>, advancedSmsEmailAddresses: list<string>, includeAttachment: bool, includeTranscription: bool, markAsRead: bool>, inboundFaxes: record<notifyByEmail: bool, notifyBySms: bool, advancedEmailAddresses: list<string>, advancedSmsEmailAddresses: list<string>, includeAttachment: bool, markAsRead: bool>, outboundFaxes: record<notifyByEmail: bool, notifyBySms: bool, advancedEmailAddresses: list<string>, advancedSmsEmailAddresses: list<string>>, inboundTexts: record<notifyByEmail: bool, notifyBySms: bool, advancedEmailAddresses: list<string>, advancedSmsEmailAddresses: list<string>>, missedCalls: record<notifyByEmail: bool, notifyBySms: bool, advancedEmailAddresses: list<string>, advancedSmsEmailAddresses: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/notification-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Notification Settings
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/notification-settings
# operationId: updateNotificationSettings
# --voicemails shape: {notifyByEmail?: bool, notifyBySms?: bool, advancedEmailAddresses?: list, advancedSmsEmailAddresses?: list, includeAttachment?: bool, includeTranscription?: bool, markAsRead?: bool}
# --inboundFaxes shape: {notifyByEmail?: bool, notifyBySms?: bool, advancedEmailAddresses?: list, advancedSmsEmailAddresses?: list, includeAttachment?: bool, markAsRead?: bool}
# --outboundFaxes shape: {notifyByEmail?: bool, notifyBySms?: bool, advancedEmailAddresses?: list, advancedSmsEmailAddresses?: list}
# --inboundTexts shape: {notifyByEmail?: bool, notifyBySms?: bool, advancedEmailAddresses?: list, advancedSmsEmailAddresses?: list}
# --missedCalls shape: {notifyByEmail?: bool, notifyBySms?: bool, advancedEmailAddresses?: list, advancedSmsEmailAddresses?: list}
export def "restapi-v10-account-extension-notification-settings updateNotificationSettings" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --emailAddresses: list # List of notification recipient email addresses. Should not be empty if 'includeManagers' parameter is set to false
  --smsEmailAddresses: list # List of notification recipient email addresses
  --advancedMode: string@bool-completer # Specifies notifications settings mode. If `true` then advanced mode is on, it allows using different emails and/or phone numbers for each notification type. If `false` then basic mode is on. Advanced mode settings are returned in both modes, if specified once, but if basic mode is switched on, they are not applied
  --voicemails: record # shape: {notifyByEmail?: bool, notifyBySms?: bool, advancedEmailAddresses?: list, advancedSmsEmailAddresses?: list, includeAttachment?: bool, includeTranscription?: bool, markAsRead?: bool}
  --inboundFaxes: record # shape: {notifyByEmail?: bool, notifyBySms?: bool, advancedEmailAddresses?: list, advancedSmsEmailAddresses?: list, includeAttachment?: bool, markAsRead?: bool}
  --outboundFaxes: record # shape: {notifyByEmail?: bool, notifyBySms?: bool, advancedEmailAddresses?: list, advancedSmsEmailAddresses?: list}
  --inboundTexts: record # shape: {notifyByEmail?: bool, notifyBySms?: bool, advancedEmailAddresses?: list, advancedSmsEmailAddresses?: list}
  --missedCalls: record # shape: {notifyByEmail?: bool, notifyBySms?: bool, advancedEmailAddresses?: list, advancedSmsEmailAddresses?: list}
  --includeManagers: string@bool-completer # Specifies if managers' emails are included in the list of emails to which notifications are sent. If not specified, then the value is `true`  (default: true)
]: any -> record<uri: string, emailRecipients: table<extensionId: string, fullName: string, extensionNumber: string, status: string, emailAddresses: list, permission: string>, emailAddresses: list<string>, includeManagers: bool, smsEmailAddresses: list<string>, advancedMode: bool, voicemails: record<notifyByEmail: bool, notifyBySms: bool, advancedEmailAddresses: list<string>, advancedSmsEmailAddresses: list<string>, includeAttachment: bool, includeTranscription: bool, markAsRead: bool>, inboundFaxes: record<notifyByEmail: bool, notifyBySms: bool, advancedEmailAddresses: list<string>, advancedSmsEmailAddresses: list<string>, includeAttachment: bool, markAsRead: bool>, outboundFaxes: record<notifyByEmail: bool, notifyBySms: bool, advancedEmailAddresses: list<string>, advancedSmsEmailAddresses: list<string>>, inboundTexts: record<notifyByEmail: bool, notifyBySms: bool, advancedEmailAddresses: list<string>, advancedSmsEmailAddresses: list<string>>, missedCalls: record<notifyByEmail: bool, notifyBySms: bool, advancedEmailAddresses: list<string>, advancedSmsEmailAddresses: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/notification-settings")
  let body = {emailAddresses: $emailAddresses, smsEmailAddresses: $smsEmailAddresses, advancedMode: $advancedMode, voicemails: $voicemails, inboundFaxes: $inboundFaxes, outboundFaxes: $outboundFaxes, inboundTexts: $inboundTexts, missedCalls: $missedCalls, includeManagers: $includeManagers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send MMS
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/mms
# operationId: createMMS
# --from shape: {phoneNumber: string}
# --to item shape: {phoneNumber: string}
# --country shape: {id?: string, isoCode?: string}
export def "restapi-v10-account-extension-mms createMMS" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-from: record # Message sender information. The `phoneNumber` value should be one the account phone numbers allowed to send the current type of messages — shape: {phoneNumber: string}
  --body-to: list # Message receiver(s) information. The `phoneNumber` value is required — item shape: {phoneNumber: string}
  --text: string # Text of a message. Max length is 1000 symbols (2-byte UTF-16 encoded). If a character is encoded in 4 bytes in UTF-16 it is treated as 2 characters, thus restricting the maximum message length to 500 symbols
  --country: record # Target number country information. Either `id` or `isoCode` can be specified. — shape: {id?: string, isoCode?: string}
  attachments: list # Media file(s) to upload
]: any -> record<id: int, uri: string, attachments: table<id: int, uri: string, type: string, contentType: string, vmDuration: int, fileName: string, size: int, height: int, width: int>, availability: string, conversationId: int, conversation: record<id: string, uri: string>, creationTime: string, deliveryErrorCode: string, direction: string, from: record<extensionNumber: string, extensionId: string, location: string, name: string, phoneNumber: string>, lastModifiedTime: string, messageStatus: string, priority: string, readStatus: string, smsDeliveryTime: string, smsSendingAttemptsCount: int, subject: string, to: table<extensionNumber: string, extensionId: string, location: string, target: bool, messageStatus: string, faxErrorCode: string, name: string, phoneNumber: string, recipientId: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/mms")
  let body = {from: $body_from, to: $body_to, text: $text, country: $country, attachments: $attachments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get User Features
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/features
# operationId: readExtensionFeatures
export def "restapi-v10-account-extension-features readExtensionFeatures" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --availableOnly: string@bool-completer # Allows to filter features by availability for an extension  (default: false)
  --featureId: list # Internal identifier(s) of the feature(s)
]: nothing -> record<records: table<id: string, available: bool, params: list, reason: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "availableOnly" $availableOnly "scalar") (serialize-qp "featureId" $featureId "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/features" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Messages
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/message-store
# operationId: listMessages
export def "restapi-v10-account-extension-message-store listMessages" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --availability: list # Specifies the availability status for resulting messages. Multiple values are accepted
  --conversationId: string # Specifies a conversation identifier for the resulting messages
  --dateFrom: string # Start date/time for resulting messages in ISO 8601 format including timezone, for example 2016-03-10T18:07:52.534Z. The default value is dateTo minus 24 hours  (format: date-time)
  --dateTo: string # End date/time for resulting messages in ISO 8601 format including timezone, for example 2016-03-10T18:07:52.534Z. The default value is current time  (format: date-time)
  --direction: list # Direction for resulting messages. If not specified, both inbound and outbound messages are returned. Multiple values are accepted
  --distinctConversations: string@bool-completer # If `true`, then the latest messages per every conversation ID are returned
  --messageType: list # Type of resulting messages. If not specified, all messages without message type filtering are returned. Multiple values are accepted
  --readStatus: list # Read status for resulting messages. Multiple values are accepted
  --page: int # Indicates a page number to retrieve. Only positive number values are accepted  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items) (format: int32, default: 100)
  --phoneNumber: string # Phone number. If specified, messages are returned for this particular phone number only
]: nothing -> record<uri: string, records: table<id: int, uri: string, extensionId: string, attachments: list, availability: string, conversationId: int, conversation: record, creationTime: string, deliveryErrorCode: string, direction: string, faxPageCount: int, faxResolution: string, from: record, lastModifiedTime: string, messageStatus: string, pgToDepartment: bool, priority: string, readStatus: string, smsDeliveryTime: string, smsSendingAttemptsCount: int, subject: string, to: list, type: string, vmTranscriptionStatus: string, coverIndex: int, coverPageText: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<page: int, perPage: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "availability" $availability "multi") (serialize-qp "conversationId" $conversationId "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "direction" $direction "multi") (serialize-qp "distinctConversations" $distinctConversations "scalar") (serialize-qp "messageType" $messageType "multi") (serialize-qp "readStatus" $readStatus "multi") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "phoneNumber" $phoneNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/message-store" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Conversation
#
# DELETE /restapi/v1.0/account/{accountId}/extension/{extensionId}/message-store
# operationId: deleteMessageByFilter
export def "restapi-v10-account-extension-message-store delete-by-accountId-extensionId" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --conversationId: list
  --dateTo: string # Messages received earlier then the date specified will be deleted. The default value is current date/time  (format: date-time)
  --type: string@type-completer-16 # Type of messages to be deleted (default: All)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "conversationId" $conversationId "multi") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/message-store" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Message(s)
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/message-store/{messageId}
# operationId: readMessage
export def "restapi-v10-account-extension-message-store readMessage" [
  accountId: string
  extensionId: string
  messageId: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-4 # Response content type
]: nothing -> record<id: int, uri: string, extensionId: string, attachments: table<id: int, uri: string, type: string, contentType: string, vmDuration: int, fileName: string, size: int, height: int, width: int>, availability: string, conversationId: int, conversation: record<id: string, uri: string>, creationTime: string, deliveryErrorCode: string, direction: string, faxPageCount: int, faxResolution: string, from: record<extensionNumber: string, extensionId: string, location: string, name: string, phoneNumber: string>, lastModifiedTime: string, messageStatus: string, pgToDepartment: bool, priority: string, readStatus: string, smsDeliveryTime: string, smsSendingAttemptsCount: int, subject: string, to: table<extensionNumber: string, extensionId: string, location: string, target: bool, messageStatus: string, faxErrorCode: string, name: string, phoneNumber: string, recipientId: string>, type: string, vmTranscriptionStatus: string, coverIndex: int, coverPageText: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/message-store/($messageId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Message(s)
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/message-store/{messageId}
# operationId: updateMessage
export def "restapi-v10-account-extension-message-store updateMessage" [
  accountId: string
  extensionId: string
  messageId: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-4 # Response content type
  readStatus: string@readStatus-completer # Message read status
]: any -> record<id: int, uri: string, extensionId: string, attachments: table<id: int, uri: string, type: string, contentType: string, vmDuration: int, fileName: string, size: int, height: int, width: int>, availability: string, conversationId: int, conversation: record<id: string, uri: string>, creationTime: string, deliveryErrorCode: string, direction: string, faxPageCount: int, faxResolution: string, from: record<extensionNumber: string, extensionId: string, location: string, name: string, phoneNumber: string>, lastModifiedTime: string, messageStatus: string, pgToDepartment: bool, priority: string, readStatus: string, smsDeliveryTime: string, smsSendingAttemptsCount: int, subject: string, to: table<extensionNumber: string, extensionId: string, location: string, target: bool, messageStatus: string, faxErrorCode: string, name: string, phoneNumber: string, recipientId: string>, type: string, vmTranscriptionStatus: string, coverIndex: int, coverPageText: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/message-store/($messageId)")
  let body = {readStatus: $readStatus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Patch Message(s)
#
# PATCH /restapi/v1.0/account/{accountId}/extension/{extensionId}/message-store/{messageId}
# operationId: patchMessage
export def "restapi-v10-account-extension-message-store patch" [
  accountId: string
  extensionId: string
  messageId: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-4 # Response content type
  --readStatus: string@readStatus-completer # Message read status
  --availability: string@availability-completer # Message availability status. Message in 'Deleted' state is still preserved with all its attachments and can be restored. 'Purged' means that all attachments are already deleted and the message itself is about to be physically deleted shortly
]: any -> record<id: int, uri: string, extensionId: string, attachments: table<id: int, uri: string, type: string, contentType: string, vmDuration: int, fileName: string, size: int, height: int, width: int>, availability: string, conversationId: int, conversation: record<id: string, uri: string>, creationTime: string, deliveryErrorCode: string, direction: string, faxPageCount: int, faxResolution: string, from: record<extensionNumber: string, extensionId: string, location: string, name: string, phoneNumber: string>, lastModifiedTime: string, messageStatus: string, pgToDepartment: bool, priority: string, readStatus: string, smsDeliveryTime: string, smsSendingAttemptsCount: int, subject: string, to: table<extensionNumber: string, extensionId: string, location: string, target: bool, messageStatus: string, faxErrorCode: string, name: string, phoneNumber: string, recipientId: string>, type: string, vmTranscriptionStatus: string, coverIndex: int, coverPageText: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/message-store/($messageId)")
  let body = {readStatus: $readStatus, availability: $availability} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Message
#
# DELETE /restapi/v1.0/account/{accountId}/extension/{extensionId}/message-store/{messageId}
# operationId: deleteMessage
export def "restapi-v10-account-extension-message-store delete-by-accountId-extensionId-messageId" [
  accountId: string
  extensionId: string
  messageId: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --purge: string@bool-completer # If the value is `true`, then the message is purged immediately with all the attachments  (default: false)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "purge" $purge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/message-store/($messageId)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Custom User Greeting
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/greeting
# operationId: createCustomUserGreeting
export def "restapi-v10-account-extension-greeting createCustomUserGreeting" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apply: string@bool-completer # Specifies whether to apply an answering rule or not. If set to true then `answeringRule` parameter is mandatory. If set to false, then the answering rule is not applied even if specified  (default: true)
  type: string@type-completer-17 # Type of greeting, specifying the case when the greeting is played.
  answeringRuleId: string # Internal identifier of an answering rule
  binary: string # Media file to upload (format: binary)
]: any -> record<uri: string, id: string, type: string, contentType: string, contentUri: string, answeringRule: record<uri: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apply" $apply "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/greeting" $qp)
  let body = {type: $type, answeringRuleId: $answeringRuleId, binary: $binary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get Custom Greeting
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/greeting/{greetingId}
# operationId: readCustomGreeting
export def "restapi-v10-account-extension-greeting readCustomGreeting" [
  accountId: string
  extensionId: string
  greetingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, type: string, contentType: string, contentUri: string, answeringRule: record<uri: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/greeting/($greetingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Unified Presence
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/unified-presence
# operationId: readUnifiedPresence
export def "restapi-v10-account-extension-unified-presence readUnifiedPresence" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, glip: record<status: string, visibility: string, availability: string>, telephony: record<status: string, visibility: string, availability: string>, meeting: record<status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/unified-presence")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Unified Presence
#
# PATCH /restapi/v1.0/account/{accountId}/extension/{extensionId}/unified-presence
# operationId: updateUnifiedPresence
# --glip shape: {visibility?: "Visible"|"Invisible", availability?: "Available"|"DND"}
# --telephony shape: {availability?: "TakeAllCalls"|"DoNotAcceptAnyCalls"|"DoNotAcceptQueueCalls"}
export def "restapi-v10-account-extension-unified-presence updateUnifiedPresence" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --glip: record # shape: {visibility?: "Visible"|"Invisible", availability?: "Available"|"DND"}
  --telephony: record # shape: {availability?: "TakeAllCalls"|"DoNotAcceptAnyCalls"|"DoNotAcceptQueueCalls"}
]: any -> record<status: string, glip: record<status: string, visibility: string, availability: string>, telephony: record<status: string, visibility: string, availability: string>, meeting: record<status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/unified-presence")
  let body = {glip: $glip, telephony: $telephony} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Caller Blocking Settings
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/caller-blocking
# operationId: readCallerBlockingSettings
export def "restapi-v10-account-extension-caller-blocking readCallerBlockingSettings" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<mode: string, noCallerId: string, payPhones: string, greetings: table<type: string, preset: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/caller-blocking")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Caller Blocking Settings
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/caller-blocking
# operationId: updateCallerBlockingSettings
# --greetings item shape: {type?: string, preset?: record}
export def "restapi-v10-account-extension-caller-blocking updateCallerBlockingSettings" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --mode: string@mode-completer-1 # Call blocking options: either specific or all calls and faxes
  --noCallerId: string@noCallerId-completer # Determines how to handle calls with no caller ID in 'Specific' mode
  --payPhones: string@payPhones-completer # Blocking settings for pay phones
  --greetings: list # List of greetings played for blocked callers — item shape: {type?: string, preset?: record}
]: any -> record<mode: string, noCallerId: string, payPhones: string, greetings: table<type: string, preset: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/caller-blocking")
  let body = {mode: $mode, noCallerId: $noCallerId, payPhones: $payPhones, greetings: $greetings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Blocked/Allowed Phone Numbers
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/caller-blocking/phone-numbers
# operationId: listBlockedAllowedNumbers
export def "restapi-v10-account-extension-caller-blocking-phone-numbers listBlockedAllowedNumbers" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The result set page number (1-indexed) to return (format: int32, default: 1, e.g. 1)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --status: string
]: nothing -> record<uri: string, records: table<uri: string, id: string, phoneNumber: string, label: string, status: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/caller-blocking/phone-numbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Blocked/Allowed Number
#
# POST /restapi/v1.0/account/{accountId}/extension/{extensionId}/caller-blocking/phone-numbers
# operationId: createBlockedAllowedNumber
export def "restapi-v10-account-extension-caller-blocking-phone-numbers createBlockedAllowedNumber" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --phoneNumber: string # A blocked/allowed phone number in [E.164](https://www.itu.int/rec/T-REC-E.164-201011-I) format
  --label: string # Custom name of a blocked/allowed phone number
  --status: string@status-completer-5 # Status of a phone number (default: Blocked)
]: any -> record<uri: string, id: string, phoneNumber: string, label: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/caller-blocking/phone-numbers")
  let body = {phoneNumber: $phoneNumber, label: $label, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Blocked/Allowed Number
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/caller-blocking/phone-numbers/{blockedNumberId}
# operationId: readBlockedAllowedNumber
export def "restapi-v10-account-extension-caller-blocking-phone-numbers readBlockedAllowedNumber" [
  accountId: string
  extensionId: string
  blockedNumberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, phoneNumber: string, label: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/caller-blocking/phone-numbers/($blockedNumberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Blocked/Allowed Number
#
# PUT /restapi/v1.0/account/{accountId}/extension/{extensionId}/caller-blocking/phone-numbers/{blockedNumberId}
# operationId: updateBlockedAllowedNumber
export def "restapi-v10-account-extension-caller-blocking-phone-numbers updateBlockedAllowedNumber" [
  accountId: string
  extensionId: string
  blockedNumberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --phoneNumber: string # A blocked/allowed phone number in [E.164](https://www.itu.int/rec/T-REC-E.164-201011-I) format
  --label: string # Custom name of a blocked/allowed phone number
  --status: string@status-completer-5 # Status of a phone number (default: Blocked)
]: any -> record<uri: string, id: string, phoneNumber: string, label: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/caller-blocking/phone-numbers/($blockedNumberId)")
  let body = {phoneNumber: $phoneNumber, label: $label, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Blocked/Allowed Number
#
# DELETE /restapi/v1.0/account/{accountId}/extension/{extensionId}/caller-blocking/phone-numbers/{blockedNumberId}
# operationId: deleteBlockedAllowedNumber
export def "restapi-v10-account-extension-caller-blocking-phone-numbers delete" [
  accountId: string
  extensionId: string
  blockedNumberId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/caller-blocking/phone-numbers/($blockedNumberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Address Book Synchronization
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/address-book-sync
# operationId: syncAddressBook
export def "restapi-v10-account-extension-address-book-sync syncAddressBook" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --syncType: string@syncType-completer # Type of synchronization
  --syncToken: string # Value of syncToken property of the last sync request response
  --perPage: int # Number of records per page to be returned. Max number of records is 250, which is also the default. For 'FSync' - if the number of records exceeds the parameter value (either specified or default), all of the pages can be retrieved in several requests. For 'ISync' - if the number of records exceeds page size, then the number of incoming changes to this number is limited  (format: int32)
  --pageId: int # Internal identifier of a page. It can be obtained from the 'nextPageId' parameter passed in response body  (format: int64)
]: nothing -> record<uri: string, records: table<uri: string, availability: string, email: string, id: int, notes: string, company: string, firstName: string, lastName: string, jobTitle: string, birthday: string, webPage: string, middleName: string, nickName: string, email2: string, email3: string, homePhone: string, homePhone2: string, businessPhone: string, businessPhone2: string, mobilePhone: string, businessFax: string, companyPhone: string, assistantPhone: string, carPhone: string, otherPhone: string, otherFax: string, callbackPhone: string, businessAddress: record, homeAddress: record, otherAddress: record, ringtoneIndex: string>, syncInfo: record<syncType: string, syncToken: string, syncTime: string, olderRecordsExist: bool>, nextPageId: int, nextPageUri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "syncType" $syncType "scalar") (serialize-qp "syncToken" $syncToken "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "pageId" $pageId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/address-book-sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Extension Phone Number List
#
# GET /restapi/v1.0/account/{accountId}/extension/{extensionId}/phone-number
# operationId: listExtensionPhoneNumbers
export def "restapi-v10-account-extension-phone-number listExtensionPhoneNumbers" [
  accountId: string
  extensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-6 # Status of a phone number
  --usageType: list # Usage type of phone number
  --page: int # Indicates a page number to retrieve. Only positive number values are allowed. Default value is '1'  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items). If not specified, the value is '100' by default (format: int32, default: 100)
]: nothing -> record<uri: string, records: table<uri: string, id: int, country: record, contactCenterProvider: record, extension: record, label: string, location: string, paymentType: string, phoneNumber: string, primary: bool, status: string, type: string, subType: string, usageType: string, features: list>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "usageType" $usageType "multi") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($extensionId)/phone-number" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Call Queue Overflow Settings
#
# GET /restapi/v1.0/account/{accountId}/extension/{callQueueId}/overflow-settings
# operationId: getCallQueueOverflowSettings
export def "restapi-v10-account-extension-overflow-settings get" [
  accountId: string
  callQueueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool, items: table<uri: string, id: string, extensionNumber: string, name: string, status: string, subType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($callQueueId)/overflow-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Call Queue Overflow Settings
#
# PUT /restapi/v1.0/account/{accountId}/extension/{callQueueId}/overflow-settings
# operationId: updateCallQueueOverflowSettings
# --items item shape: {id?: string}
export def "restapi-v10-account-extension-overflow-settings updateCallQueueOverflowSettings" [
  accountId: string
  callQueueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # Call queue overflow status
  --items: list # item shape: {id?: string}
]: any -> record<enabled: bool, items: table<uri: string, id: string, extensionNumber: string, name: string, status: string, subType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/extension/($callQueueId)/overflow-settings")
  let body = {enabled: $enabled, items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Emergency Map Configuration Task
#
# GET /restapi/v1.0/account/{accountId}/emergency-address-auto-update/tasks/{taskId}
# operationId: readAutomaticLocationUpdatesTask
export def "restapi-v10-account-emergency-address-auto-update-tasks readAutomaticLocationUpdatesTask" [
  accountId: string
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, creationTime: string, lastModifiedTime: string, type: string, result: record<records: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/tasks/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Users
#
# GET /restapi/v1.0/account/{accountId}/emergency-address-auto-update/users
# operationId: listAutomaticLocationUpdatesUsers
export def "restapi-v10-account-emergency-address-auto-update-users listAutomaticLocationUpdatesUsers" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: list # Extension type. Multiple values are supported
  --searchString: string # Filters entries containing the specified substring in user name, extension or department. The characters range is 0-64; not case-sensitive. If empty then the filter is ignored
  --department: list # Department name to filter the users. The value range is 0-64; not case-sensitive. If not specified then the parameter is ignored. Multiple values are supported
  --siteId: list # Internal identifier of a site for filtering. To indicate company main site `main-site` value should be specified. Supported only if multi-site feature is enabled for the account. Multiple values are supported.
  --featureEnabled: string@bool-completer # Filters entries by their status of Automatic Location Updates feature
  --orderBy: string # Comma-separated list of fields to order results prefixed by plus sign '+' (ascending order) or minus sign '-' (descending order). Supported values: 'name', 'modelName', 'siteName', 'featureEnabled'. The default sorting is by `name`
  --perPage: int # Indicates a page size (number of items). The values supported: `Max` or numeric value. If not specified, 100 records are returned per one page  (format: int32)
  --page: int # Indicates a page number to retrieve. Only positive number values are supported  (format: int32, default: 1)
]: nothing -> record<uri: string, records: table<id: string, fullName: string, extensionNumber: string, featureEnabled: bool, type: string, site: record, department: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "multi") (serialize-qp "searchString" $searchString "scalar") (serialize-qp "department" $department "multi") (serialize-qp "siteId" $siteId "multi") (serialize-qp "featureEnabled" $featureEnabled "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Automatic Location Updates for Users
#
# POST /restapi/v1.0/account/{accountId}/emergency-address-auto-update/users/bulk-assign
# operationId: assignMultipleAutomaticLocationUpdatesUsers
export def "restapi-v10-account-emergency-address-auto-update-users-bulk-assign assignMultipleAutomaticLocationUpdatesUsers" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabledUserIds: list
  --disabledUserIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/users/bulk-assign")
  let body = {enabledUserIds: $enabledUserIds, disabledUserIds: $disabledUserIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Multiple Wireless Points
#
# POST /restapi/v1.0/account/{accountId}/emergency-address-auto-update/wireless-points-bulk-create
# operationId: createMultipleWirelessPoints
# --records item shape: {bssid: string, name: string, site?: record, emergencyAddress?: any, emergencyLocation?: record}
export def "restapi-v10-account-emergency-address-auto-update-wireless-points-bulk-create createMultipleWirelessPoints" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --records: list # item shape: {bssid: string, name: string, site?: record, emergencyAddress?: any, emergencyLocation?: record}
]: any -> record<task: record<id: string, status: string, creationTime: string, lastModifiedTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/wireless-points-bulk-create")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Network Map
#
# GET /restapi/v1.0/account/{accountId}/emergency-address-auto-update/networks
# operationId: listNetworks
export def "restapi-v10-account-emergency-address-auto-update-networks listNetworks" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --siteId: list # Internal identifier of a site for filtering. To indicate company main site `main-site` value should be specified. Supported only if multi-site feature is enabled for the account. Multiple values are supported.
  --searchString: string # Filters entries by the specified substring (search by chassis ID, switch name or address) The characters range is 0-64 (if empty the filter is ignored)
  --orderBy: string # Comma-separated list of fields to order results prefixed by '+' sign (ascending order) or '-' sign (descending order). The default sorting is by `name`
  --perPage: int # Indicates a page size (number of items). The values supported: `Max` or numeric value. If not specified, 100 records are returned per one page'  (format: int32)
  --page: int # Indicates a page number to retrieve. Only positive number values are supported  (format: int32, default: 1)
]: nothing -> record<uri: string, records: table<id: string, uri: string, name: string, site: record, publicIpRanges: list, privateIpRanges: list>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "siteId" $siteId "multi") (serialize-qp "searchString" $searchString "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/networks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Network
#
# POST /restapi/v1.0/account/{accountId}/emergency-address-auto-update/networks
# operationId: createNetwork
# --site shape: {id?: string, uri?: string, name?: string, code?: string}
# --publicIpRanges item shape: {id?: string, startIp?: string, endIp?: string, matched?: bool}
# --privateIpRanges item shape: {id?: string, startIp?: string, endIp?: string, name?: string, emergencyAddress?: record, emergencyLocationId?: string, emergencyLocation?: record}
export def "restapi-v10-account-emergency-address-auto-update-networks createNetwork" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --site: record # Site data. If multi-site feature is turned on for the account, then ID of a site must be specified. In order to assign a wireless point to the main site (company) site ID should be set to `main-site` — shape: {id?: string, uri?: string, name?: string, code?: string}
  publicIpRanges: list # item shape: {id?: string, startIp?: string, endIp?: string, matched?: bool}
  privateIpRanges: list # item shape: {id?: string, startIp?: string, endIp?: string, name?: string, emergencyAddress?: record, emergencyLocationId?: string, emergencyLocation?: record}
]: any -> record<id: string, uri: string, name: string, site: record<id: string, uri: string, name: string, code: string>, publicIpRanges: table<id: string, startIp: string, endIp: string, matched: bool>, privateIpRanges: table<id: string, startIp: string, endIp: string, name: string, emergencyAddress: any, emergencyLocationId: string, matched: bool, emergencyLocation: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/networks")
  let body = {name: $name, site: $site, publicIpRanges: $publicIpRanges, privateIpRanges: $privateIpRanges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Network
#
# GET /restapi/v1.0/account/{accountId}/emergency-address-auto-update/networks/{networkId}
# operationId: readNetwork
export def "restapi-v10-account-emergency-address-auto-update-networks readNetwork" [
  accountId: string
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uri: string, name: string, site: record<id: string, uri: string, name: string, code: string>, publicIpRanges: table<id: string, startIp: string, endIp: string, matched: bool>, privateIpRanges: table<id: string, startIp: string, endIp: string, name: string, emergencyAddress: any, emergencyLocationId: string, matched: bool, emergencyLocation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/networks/($networkId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Network
#
# PUT /restapi/v1.0/account/{accountId}/emergency-address-auto-update/networks/{networkId}
# operationId: updateNetwork
# --site shape: {id?: string, uri?: string, name?: string, code?: string}
# --publicIpRanges item shape: {id?: string, startIp?: string, endIp?: string, matched?: bool}
# --privateIpRanges item shape: {id?: string, startIp?: string, endIp?: string, name?: string, emergencyAddress?: record, emergencyLocationId?: string, emergencyLocation?: record}
export def "restapi-v10-account-emergency-address-auto-update-networks updateNetwork" [
  accountId: string
  networkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Internal identifier of a network (e.g. 2874044)
  name: string
  --site: record # Site data. If multi-site feature is turned on for the account, then ID of a site must be specified. In order to assign a wireless point to the main site (company) site ID should be set to `main-site` — shape: {id?: string, uri?: string, name?: string, code?: string}
  publicIpRanges: list # item shape: {id?: string, startIp?: string, endIp?: string, matched?: bool}
  privateIpRanges: list # item shape: {id?: string, startIp?: string, endIp?: string, name?: string, emergencyAddress?: record, emergencyLocationId?: string, emergencyLocation?: record}
]: any -> record<id: string, uri: string, name: string, site: record<id: string, uri: string, name: string, code: string>, publicIpRanges: table<id: string, startIp: string, endIp: string, matched: bool>, privateIpRanges: table<id: string, startIp: string, endIp: string, name: string, emergencyAddress: any, emergencyLocationId: string, matched: bool, emergencyLocation: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/networks/($networkId)")
  let body = {id: $id, name: $name, site: $site, publicIpRanges: $publicIpRanges, privateIpRanges: $privateIpRanges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Network
#
# DELETE /restapi/v1.0/account/{accountId}/emergency-address-auto-update/networks/{networkId}
# operationId: deleteNetwork
export def "restapi-v10-account-emergency-address-auto-update-networks delete" [
  accountId: string
  networkId: list
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/networks/($networkId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate Multiple Switches
#
# POST /restapi/v1.0/account/{accountId}/emergency-address-auto-update/switches-bulk-validate
# operationId: validateMultipleSwitches
# --records item shape: {uri?: string, id?: string, chassisId?: string, port?: string, name?: string, site?: record, emergencyAddress?: any, emergencyLocation?: record}
export def "restapi-v10-account-emergency-address-auto-update-switches-bulk-validate validateMultipleSwitches" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --records: list # item shape: {uri?: string, id?: string, chassisId?: string, port?: string, name?: string, site?: record, emergencyAddress?: any, emergencyLocation?: record}
]: any -> record<records: table<id: string, chassisId: string, port: string, status: string, errors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/switches-bulk-validate")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Account Switches
#
# GET /restapi/v1.0/account/{accountId}/emergency-address-auto-update/switches
# operationId: listAccountSwitches
export def "restapi-v10-account-emergency-address-auto-update-switches listAccountSwitches" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --siteId: list # Internal identifier of a site for filtering. To indicate company main site `main-site` value should be specified. Supported only if multi-site feature is enabled for the account. Multiple values are supported.
  --searchString: string # Filters entries by the specified substring (search by chassis ID, switch name or address) The characters range is 0-64 (if empty the filter is ignored)
  --orderBy: string # Comma-separated list of fields to order results prefixed by '+' sign (ascending order) or '-' sign (descending order). The default sorting is by `name`
  --perPage: int # Indicates a page size (number of items). The values supported: `Max` or numeric value. If not specified, 100 records are returned per one page'  (format: int32)
  --page: int # Indicates a page number to retrieve. Only positive number values are supported  (format: int32, default: 1)
]: nothing -> record<records: table<uri: string, id: string, chassisId: string, port: string, name: string, site: record, emergencyAddress: record, emergencyLocation: record>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "siteId" $siteId "multi") (serialize-qp "searchString" $searchString "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/switches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Switch
#
# POST /restapi/v1.0/account/{accountId}/emergency-address-auto-update/switches
# operationId: createSwitch
# --site shape: {id?: string, name?: string}
# --emergencyLocation shape: {id: string, name?: string, addressFormatId?: string}
export def "restapi-v10-account-emergency-address-auto-update-switches createSwitch" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  chassisId: string # Unique identifier of a network switch. The supported formats are: XX:XX:XX:XX:XX:XX (symbols 0-9 and A-F) for MAC address and X.X.X.X for IP address (symbols 0-255)
  --port: string # Switch entity extension for better diversity. Should be used together with chassisId.
  --name: string # Name of a network switch
  --site: record # shape: {id?: string, name?: string}
  --emergencyAddress: any
  --emergencyLocation: record # Emergency response location information — shape: {id: string, name?: string, addressFormatId?: string}
]: any -> record<uri: string, id: string, chassisId: string, port: string, name: string, site: record<id: string, name: string>, emergencyAddress: record<syncStatus: string>, emergencyLocation: record<id: string, name: string, addressFormatId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/switches")
  let body = {chassisId: $chassisId, port: $port, name: $name, site: $site, emergencyAddress: $emergencyAddress, emergencyLocation: $emergencyLocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Switch
#
# GET /restapi/v1.0/account/{accountId}/emergency-address-auto-update/switches/{switchId}
# operationId: readSwitch
export def "restapi-v10-account-emergency-address-auto-update-switches readSwitch" [
  accountId: string
  switchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, chassisId: string, port: string, name: string, site: record<id: string, name: string>, emergencyAddress: record<syncStatus: string>, emergencyLocation: record<id: string, name: string, addressFormatId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/switches/($switchId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Switch
#
# PUT /restapi/v1.0/account/{accountId}/emergency-address-auto-update/switches/{switchId}
# operationId: updateSwitch
# --site shape: {id?: string, name?: string}
export def "restapi-v10-account-emergency-address-auto-update-switches updateSwitch" [
  accountId: string
  switchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Internal identifier of a switch
  --chassisId: string # Unique identifier of a network switch. The supported formats are: XX:XX:XX:XX:XX:XX (symbols 0-9 and A-F) for MAC address and X.X.X.X for IP address (symbols 0-255)
  --port: string # Switch entity extension for better diversity. Should be used together with chassisId.
  --name: string # Name of a network switch
  --site: record # shape: {id?: string, name?: string}
  --emergencyAddress: any
]: any -> record<uri: string, id: string, chassisId: string, port: string, name: string, site: record<id: string, name: string>, emergencyAddress: record<syncStatus: string>, emergencyLocation: record<id: string, name: string, addressFormatId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/switches/($switchId)")
  let body = {id: $id, chassisId: $chassisId, port: $port, name: $name, site: $site, emergencyAddress: $emergencyAddress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Switch
#
# DELETE /restapi/v1.0/account/{accountId}/emergency-address-auto-update/switches/{switchId}
# operationId: deleteSwitch
export def "restapi-v10-account-emergency-address-auto-update-switches delete" [
  accountId: string
  switchId: list
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/switches/($switchId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate Multiple Wireless Points
#
# POST /restapi/v1.0/account/{accountId}/emergency-address-auto-update/wireless-points-bulk-validate
# operationId: validateMultipleWirelessPoints
# --records item shape: {uri?: string, id?: string, bssid: string, name: string, site?: record, emergencyAddress: any, emergencyLocation?: record, emergencyLocationId?: string}
export def "restapi-v10-account-emergency-address-auto-update-wireless-points-bulk-validate validateMultipleWirelessPoints" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --records: list # item shape: {uri?: string, id?: string, bssid: string, name: string, site?: record, emergencyAddress: any, emergencyLocation?: record, emergencyLocationId?: string}
]: any -> record<records: table<id: string, bssid: string, status: string, errors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/wireless-points-bulk-validate")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Wireless Points
#
# GET /restapi/v1.0/account/{accountId}/emergency-address-auto-update/wireless-points
# operationId: listWirelessPoints
export def "restapi-v10-account-emergency-address-auto-update-wireless-points listWirelessPoints" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --siteId: list # Internal identifier of a site for filtering. To indicate company main site `main-site` value should be specified. Supported only if multi-site feature is enabled for the account. Multiple values are supported.
  --searchString: string # Filters entries by the specified substring (search by chassis ID, switch name or address) The characters range is 0-64 (if empty the filter is ignored)
  --orderBy: string # Comma-separated list of fields to order results prefixed by '+' sign (ascending order) or '-' sign (descending order).The default sorting is by `name`
  --perPage: int # Indicates a page size (number of items). The values supported: `Max` or numeric value. If not specified, 100 records are returned per one page  (format: int32)
  --page: int # Indicates the page number to retrieve. Only positive number values are supported  (format: int32, default: 1)
]: nothing -> record<uri: string, records: table<uri: string, id: string, bssid: string, name: string, site: record, emergencyAddress: record, emergencyLocation: record, emergencyLocationId: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "siteId" $siteId "multi") (serialize-qp "searchString" $searchString "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/wireless-points" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Wireless Point
#
# POST /restapi/v1.0/account/{accountId}/emergency-address-auto-update/wireless-points
# operationId: createWirelessPoint
# --site shape: {id?: string, name?: string}
# --emergencyLocation shape: {id: string, name?: string, addressFormatId?: string}
export def "restapi-v10-account-emergency-address-auto-update-wireless-points createWirelessPoint" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  bssid: string # Unique 48-bit identifier of wireless access point that follows MAC address conventions.  Mask: XX:XX:XX:XX:XX:XX, where X can be a symbol in the range of 0-9 or A-F
  name: string # Wireless access point name
  --site: record # shape: {id?: string, name?: string}
  --emergencyAddress: any
  --emergencyLocation: record # Emergency response location information — shape: {id: string, name?: string, addressFormatId?: string}
]: any -> record<uri: string, id: string, bssid: string, name: string, site: record<id: string, name: string>, emergencyAddress: record<syncStatus: string>, emergencyLocation: record<id: string, name: string, addressFormatId: string>, emergencyLocationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/wireless-points")
  let body = {bssid: $bssid, name: $name, site: $site, emergencyAddress: $emergencyAddress, emergencyLocation: $emergencyLocation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Wireless Point
#
# GET /restapi/v1.0/account/{accountId}/emergency-address-auto-update/wireless-points/{pointId}
# operationId: readWirelessPoint
export def "restapi-v10-account-emergency-address-auto-update-wireless-points readWirelessPoint" [
  accountId: string
  pointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, bssid: string, name: string, site: record<id: string, name: string>, emergencyAddress: record<syncStatus: string>, emergencyLocation: record<id: string, name: string, addressFormatId: string>, emergencyLocationId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/wireless-points/($pointId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Wireless Point
#
# PUT /restapi/v1.0/account/{accountId}/emergency-address-auto-update/wireless-points/{pointId}
# operationId: updateWirelessPoint
# --site shape: {id?: string, name?: string}
export def "restapi-v10-account-emergency-address-auto-update-wireless-points updateWirelessPoint" [
  accountId: string
  pointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Internal identifier of a wireless point
  --bssid: string # Unique 48-bit identifier of wireless access point that follows MAC address conventions. Mask: XX:XX:XX:XX:XX:XX, where X can be a symbol in the range of 0-9 or A-F
  --name: string # Name of a wireless access point
  --site: record # shape: {id?: string, name?: string}
  --emergencyAddress: any
]: any -> record<uri: string, id: string, bssid: string, name: string, site: record<id: string, name: string>, emergencyAddress: record<syncStatus: string>, emergencyLocation: record<id: string, name: string, addressFormatId: string>, emergencyLocationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/wireless-points/($pointId)")
  let body = {id: $id, bssid: $bssid, name: $name, site: $site, emergencyAddress: $emergencyAddress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Wireless Point
#
# DELETE /restapi/v1.0/account/{accountId}/emergency-address-auto-update/wireless-points/{pointId}
# operationId: deleteWirelessPoint
export def "restapi-v10-account-emergency-address-auto-update-wireless-points delete" [
  accountId: string
  pointId: list
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
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/wireless-points/($pointId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Devices
#
# GET /restapi/v1.0/account/{accountId}/emergency-address-auto-update/devices
# operationId: listDevicesAutomaticLocationUpdates
export def "restapi-v10-account-emergency-address-auto-update-devices listDevicesAutomaticLocationUpdates" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --siteId: list # Internal identifier of a site for filtering. To indicate company main site `main-site` value should be specified. Supported only if multi-site feature is enabled for the account. Multiple values are supported.
  --featureEnabled: string@bool-completer # Filters entries by their status of Automatic Location Updates feature
  --modelId: string # Internal identifier of a device model for filtering. Multiple values are supported
  --compatibleOnly: string@bool-completer # Filters devices which support HELD protocol
  --searchString: string # Filters entries which have device name or model name containing the mentioned substring. The value should be split by spaces; the range is 0 - 64 characters, not case-sensitive. If empty the filter is ignored
  --orderBy: string # Comma-separated list of fields to order results prefixed by plus sign '+' (ascending order) or minus sign '-' (descending order). Supported values: 'name', 'modelName', 'siteName', 'featureEnabled'. The default sorting is by `name`
  --perPage: int # Indicates a page size (number of items). The values supported: `Max` or numeric value. If not specified, 100 records are returned per one page  (format: int32)
  --page: int # Indicates a page number to retrieve. Only positive number values are supported  (format: int32, default: 1)
]: nothing -> record<uri: string, records: table<id: string, type: string, serial: string, featureEnabled: bool, name: string, model: record, site: record, phoneLines: list>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "siteId" $siteId "multi") (serialize-qp "featureEnabled" $featureEnabled "scalar") (serialize-qp "modelId" $modelId "scalar") (serialize-qp "compatibleOnly" $compatibleOnly "scalar") (serialize-qp "searchString" $searchString "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Automatic Location Updates Feature
#
# POST /restapi/v1.0/account/{accountId}/emergency-address-auto-update/devices/bulk-assign
# operationId: assignMultipleDevicesAutomaticLocationUpdates
export def "restapi-v10-account-emergency-address-auto-update-devices-bulk-assign assignMultipleDevicesAutomaticLocationUpdates" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabledDeviceIds: list
  --disabledDeviceIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/devices/bulk-assign")
  let body = {enabledDeviceIds: $enabledDeviceIds, disabledDeviceIds: $disabledDeviceIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Multiple Switches
#
# POST /restapi/v1.0/account/{accountId}/emergency-address-auto-update/switches-bulk-create
# operationId: createMultipleSwitches
# --records item shape: {chassisId: string, port?: string, name?: string, site?: record, emergencyAddress?: any, emergencyLocation?: record}
export def "restapi-v10-account-emergency-address-auto-update-switches-bulk-create createMultipleSwitches" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --records: list # item shape: {chassisId: string, port?: string, name?: string, site?: record, emergencyAddress?: any, emergencyLocation?: record}
]: any -> record<task: table<id: string, status: string, creationTime: string, lastModifiedTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/switches-bulk-create")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Multiple Wireless Points
#
# POST /restapi/v1.0/account/{accountId}/emergency-address-auto-update/wireless-points-bulk-update
# operationId: updateMultipleWirelessPoints
# --records item shape: {id?: string, bssid?: string, name?: string, site?: record, emergencyAddress?: any}
export def "restapi-v10-account-emergency-address-auto-update-wireless-points-bulk-update updateMultipleWirelessPoints" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --records: list # item shape: {id?: string, bssid?: string, name?: string, site?: record, emergencyAddress?: any}
]: any -> record<task: record<id: string, status: string, creationTime: string, lastModifiedTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/wireless-points-bulk-update")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Multiple Switches
#
# POST /restapi/v1.0/account/{accountId}/emergency-address-auto-update/switches-bulk-update
# operationId: updateMultipleSwitches
# --records item shape: {id?: string, chassisId?: string, port?: string, name?: string, site?: record, emergencyAddress?: any}
export def "restapi-v10-account-emergency-address-auto-update-switches-bulk-update updateMultipleSwitches" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --records: list # item shape: {id?: string, chassisId?: string, port?: string, name?: string, site?: record, emergencyAddress?: any}
]: any -> record<task: record<id: string, status: string, creationTime: string, lastModifiedTime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/emergency-address-auto-update/switches-bulk-update")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Company Phone Numbers
#
# GET /restapi/v1.0/account/{accountId}/phone-number
# operationId: listAccountPhoneNumbers
export def "restapi-v10-account-phone-number listAccountPhoneNumbers" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Indicates a page number to retrieve. Only positive number values are accepted  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items) (format: int32, default: 100)
  --usageType: list # Usage type of phone number
  --paymentType: string # Payment Type of the number
  --status: string@status-completer-6 # Status of a phone number
]: nothing -> record<uri: string, records: table<uri: string, id: int, country: record, extension: record, label: string, location: string, paymentType: string, phoneNumber: string, status: string, type: string, usageType: string, temporaryNumber: record, contactCenterProvider: record, vanityPattern: string, primary: bool>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "usageType" $usageType "multi") (serialize-qp "paymentType" $paymentType "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/phone-number" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Phone Number
#
# GET /restapi/v1.0/account/{accountId}/phone-number/{phoneNumberId}
# operationId: readAccountPhoneNumber
export def "restapi-v10-account-phone-number readAccountPhoneNumber" [
  accountId: string
  phoneNumberId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: int, country: record<id: string, uri: string, name: string>, extension: record<id: int, uri: string, name: string, extensionNumber: string, partnerId: string>, label: string, location: string, paymentType: string, phoneNumber: string, status: string, type: string, usageType: string, temporaryNumber: record<id: string, phoneNumber: string>, contactCenterProvider: record<id: string, name: string>, vanityPattern: string, primary: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/account/($accountId)/phone-number/($phoneNumberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Subscriptions
#
# GET /restapi/v1.0/subscription
# operationId: listSubscriptions
export def "restapi-v10-subscription listSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, records: table<uri: string, id: string, eventFilters: list, disabledFilters: list, expirationTime: string, expiresIn: int, status: string, creationTime: string, deliveryMode: any, blacklistedData: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restapi/v1.0/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Subscription
#
# POST /restapi/v1.0/subscription
# operationId: createSubscription
export def "restapi-v10-subscription createSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  eventFilters: list # The list of event filters corresponding to events the user is subscribed to
  --expiresIn: int # Subscription lifetime in seconds. The maximum subscription lifetime depends upon the specified `transportType`:  | Transport type      | Maximum permitted lifetime     | | ------------------- | ------------------------------ | | `WebHook`           | 315360000 seconds (10 years)   | | `RC/APNS`, `RC/GSM` | 7776000 seconds (90 days)      | | `PubNub`            | 900 seconds (15 minutes)       | | `WebSocket`         | n/a (the parameter is ignored) |  (format: int32, e.g. 1200)
  deliveryMode: any # Notification delivery transport information
]: any -> record<uri: string, id: string, eventFilters: list<string>, disabledFilters: table<filter: string, reason: string, message: string>, expirationTime: string, expiresIn: int, status: string, creationTime: string, deliveryMode: any, blacklistedData: record<blacklistedAt: string, reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restapi/v1.0/subscription")
  let body = {eventFilters: $eventFilters, expiresIn: $expiresIn, deliveryMode: $deliveryMode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Subscription
#
# GET /restapi/v1.0/subscription/{subscriptionId}
# operationId: readSubscription
export def "restapi-v10-subscription readSubscription" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, eventFilters: list<string>, disabledFilters: table<filter: string, reason: string, message: string>, expirationTime: string, expiresIn: int, status: string, creationTime: string, deliveryMode: any, blacklistedData: record<blacklistedAt: string, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/subscription/($subscriptionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Subscription
#
# PUT /restapi/v1.0/subscription/{subscriptionId}
# operationId: updateSubscription
export def "restapi-v10-subscription updateSubscription" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  eventFilters: list # The list of event filters corresponding to events the user is subscribed to
  --expiresIn: int # Subscription lifetime in seconds. The maximum subscription lifetime depends upon the specified `transportType`:  | Transport type      | Maximum permitted lifetime     | | ------------------- | ------------------------------ | | `WebHook`           | 315360000 seconds (10 years)   | | `RC/APNS`, `RC/GSM` | 7776000 seconds (90 days)      | | `PubNub`            | 900 seconds (15 minutes)       | | `WebSocket`         | n/a (the parameter is ignored) |  (format: int32, e.g. 1200)
]: any -> record<uri: string, id: string, eventFilters: list<string>, disabledFilters: table<filter: string, reason: string, message: string>, expirationTime: string, expiresIn: int, status: string, creationTime: string, deliveryMode: any, blacklistedData: record<blacklistedAt: string, reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/subscription/($subscriptionId)")
  let body = {eventFilters: $eventFilters, expiresIn: $expiresIn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel Subscription
#
# DELETE /restapi/v1.0/subscription/{subscriptionId}
# operationId: deleteSubscription
export def "restapi-v10-subscription delete" [
  subscriptionId: string
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
  let full_url = (build-url $base $"/restapi/v1.0/subscription/($subscriptionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Renew Subscription
#
# POST /restapi/v1.0/subscription/{subscriptionId}/renew
# operationId: renewSubscription
export def "restapi-v10-subscription-renew renewSubscription" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, eventFilters: list<string>, disabledFilters: table<filter: string, reason: string, message: string>, expirationTime: string, expiresIn: int, status: string, creationTime: string, deliveryMode: any, blacklistedData: record<blacklistedAt: string, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/subscription/($subscriptionId)/renew")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Parse Phone Number(s)
#
# POST /restapi/v1.0/number-parser/parse
# operationId: parsePhoneNumber
export def "restapi-v10-number-parser-parse parsePhoneNumber" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --homeCountry: string # ISO 3166 alpha2 code of the home country to be used if it is impossible to determine country from the number itself. By default, this parameter is preset to the current user's home country or brand country if the user is undefined  (e.g. US)
  --nationalAsPriority: string@bool-completer # The default value is `false`. If `true`, the numbers that are closer to the home country are given higher priority  (default: false)
  --originalStrings: list # The list of phone numbers passed as an array of strings (not more than 64 items). The maximum size of each string is 64 characters
]: any -> record<uri: string, homeCountry: record<id: string, uri: string, callingCode: string, isoCode: string, name: string>, phoneNumbers: table<originalString: string, country: record, areaCode: string, dialable: string, e164: string, formattedInternational: string, formattedNational: string, special: bool, normalized: string, tollFree: bool, subAddress: string, subscriberNumber: string, dtmfPostfix: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "homeCountry" $homeCountry "scalar") (serialize-qp "nationalAsPriority" $nationalAsPriority "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapi/v1.0/number-parser/parse" $qp)
  let body = {originalStrings: $originalStrings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Contracted Countries
#
# GET /restapi/v1.0/dictionary/brand/{brandId}/contracted-country
# operationId: listContractedCountries
export def "restapi-v10-dictionary-brand-contracted-country listContractedCountries" [
  brandId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<records: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/dictionary/brand/($brandId)/contracted-country")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Domestic Countries
#
# GET /restapi/v1.0/dictionary/brand/{brandId}/contracted-country/{contractedCountryId}
# operationId: listDomesticCountries
export def "restapi-v10-dictionary-brand-contracted-country listDomesticCountries" [
  brandId: string
  contractedCountryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Indicates a page number to retrieve. Only positive number values are accepted  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items) (format: int32, default: 100)
]: nothing -> record<uri: string, records: table<emergencyCalling: bool, isoCode: string, name: string, numberSelling: bool, loginAllowed: bool, signupAllowed: bool, freeSoftphoneLine: bool, localDialing: bool>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restapi/v1.0/dictionary/brand/($brandId)/contracted-country/($contractedCountryId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List States
#
# GET /restapi/v1.0/dictionary/state
# operationId: listStates
export def "restapi-v10-dictionary-state listStates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allCountries: string@bool-completer # If set to `true` then states of all countries are returned and `countryId` is ignored, even if specified. If the value is empty then the parameter is ignored
  --countryId: int # Internal identifier of a country (format: int64)
  --page: int # Indicates a page number to retrieve. Only positive number values are accepted  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items) (format: int32, default: 100)
  --withPhoneNumbers: string@bool-completer # If `true` the list of states with phone numbers available for buying is returned  (default: false)
]: nothing -> record<uri: string, records: table<id: string, uri: string, country: record, isoCode: string, name: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allCountries" $allCountries "scalar") (serialize-qp "countryId" $countryId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "withPhoneNumbers" $withPhoneNumbers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapi/v1.0/dictionary/state" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get State
#
# GET /restapi/v1.0/dictionary/state/{stateId}
# operationId: readState
export def "restapi-v10-dictionary-state readState" [
  stateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uri: string, country: record<id: string, uri: string>, isoCode: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/dictionary/state/($stateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Locations
#
# GET /restapi/v1.0/dictionary/location
# operationId: listLocations
export def "restapi-v10-dictionary-location listLocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderBy: string@orderBy-completer-2 # Sorts results by the property specified (default: City)
  --page: int # Indicates a page number to retrieve. Only positive number values are accepted  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items) (format: int32, default: 100)
  --stateId: string # Internal identifier of a state
  --withNxx: string@bool-completer # Specifies if `nxx` codes are returned
]: nothing -> record<uri: string, records: table<uri: string, areaCode: string, city: string, npa: string, nxx: string, state: record>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "stateId" $stateId "scalar") (serialize-qp "withNxx" $withNxx "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapi/v1.0/dictionary/location" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Permissions
#
# GET /restapi/v1.0/dictionary/permission
# operationId: listPermissions
export def "restapi-v10-dictionary-permission listPermissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The result set page number (1-indexed) to return (format: int32, default: 1, e.g. 1)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --assignable: string@bool-completer # Specifies whether to return only assignable permissions
  --servicePlanId: string # Internal identifier of a service plan
]: nothing -> record<uri: string, records: table<uri: string, id: string, displayName: string, description: string, assignable: bool, readOnly: bool, siteCompatible: string, category: record, includedPermissions: list>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "assignable" $assignable "scalar") (serialize-qp "servicePlanId" $servicePlanId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapi/v1.0/dictionary/permission" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Permission
#
# GET /restapi/v1.0/dictionary/permission/{permissionId}
# operationId: readPermission
export def "restapi-v10-dictionary-permission readPermission" [
  permissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, displayName: string, description: string, assignable: bool, readOnly: bool, siteCompatible: string, category: record<uri: string, id: string>, includedPermissions: table<uri: string, id: string, siteCompatible: string, readOnly: bool, assignable: bool, permissionsCapabilities: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/dictionary/permission/($permissionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Languages
#
# GET /restapi/v1.0/dictionary/language
# operationId: listLanguages
export def "restapi-v10-dictionary-language listLanguages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, records: table<id: string, uri: string, greeting: bool, formattingLocale: bool, localeCode: string, isoCode: string, name: string, ui: bool, timeFormat: string, dateFormat: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restapi/v1.0/dictionary/language")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Language
#
# GET /restapi/v1.0/dictionary/language/{languageId}
# operationId: readLanguage
export def "restapi-v10-dictionary-language readLanguage" [
  languageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uri: string, greeting: bool, formattingLocale: bool, localeCode: string, isoCode: string, name: string, ui: bool, timeFormat: string, dateFormat: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/dictionary/language/($languageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Permission Categories
#
# GET /restapi/v1.0/dictionary/permission-category
# operationId: listPermissionCategories
export def "restapi-v10-dictionary-permission-category listPermissionCategories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The result set page number (1-indexed) to return (format: int32, default: 1, e.g. 1)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --servicePlanId: string # Internal identifier of a service plan
]: nothing -> record<uri: string, records: table<uri: string, id: string, displayName: string, description: string>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "servicePlanId" $servicePlanId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapi/v1.0/dictionary/permission-category" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Permission Category
#
# GET /restapi/v1.0/dictionary/permission-category/{permissionCategoryId}
# operationId: readPermissionCategory
export def "restapi-v10-dictionary-permission-category readPermissionCategory" [
  permissionCategoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, displayName: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/dictionary/permission-category/($permissionCategoryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Standard Greetings
#
# GET /restapi/v1.0/dictionary/greeting
# operationId: listStandardGreetings
export def "restapi-v10-dictionary-greeting listStandardGreetings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The result set page number (1-indexed) to return (format: int32, default: 1, e.g. 1)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --type: string@type-completer-18 # Type of greeting, specifying the case when the greeting is played
  --usageType: string@usageType-completer-1 # Usage type of greeting, specifying if the greeting is applied for user extension or department (call queue) extension
]: nothing -> record<uri: string, records: table<id: string, uri: string, name: string, usageType: string, text: string, contentUri: string, type: string, category: string, navigation: record, paging: record>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "usageType" $usageType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapi/v1.0/dictionary/greeting" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Standard Greeting
#
# GET /restapi/v1.0/dictionary/greeting/{greetingId}
# operationId: readStandardGreeting
export def "restapi-v10-dictionary-greeting readStandardGreeting" [
  greetingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uri: string, name: string, usageType: string, text: string, contentUri: string, type: string, category: string, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/dictionary/greeting/($greetingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Timezones
#
# GET /restapi/v1.0/dictionary/timezone
# operationId: listTimezones
export def "restapi-v10-dictionary-timezone listTimezones" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Indicates a page number to retrieve. Only positive number values are allowed. Default value is '1'  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items). If not specified, the value is '100' by default (format: int32, default: 100)
]: nothing -> record<uri: string, records: table<id: string, uri: string, name: string, description: string, bias: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapi/v1.0/dictionary/timezone" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Timezone
#
# GET /restapi/v1.0/dictionary/timezone/{timezoneId}
# operationId: readTimezone
export def "restapi-v10-dictionary-timezone readTimezone" [
  timezoneId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uri: string, name: string, description: string, bias: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/dictionary/timezone/($timezoneId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Fax Cover Pages
#
# GET /restapi/v1.0/dictionary/fax-cover-page
# operationId: listFaxCoverPages
export def "restapi-v10-dictionary-fax-cover-page listFaxCoverPages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Indicates a page number to retrieve. Only positive number values are accepted  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items) (format: int32, default: 100)
]: nothing -> record<uri: string, records: table<id: string, name: string>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapi/v1.0/dictionary/fax-cover-page" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Standard User Roles
#
# GET /restapi/v1.0/dictionary/user-role
# operationId: listStandardUserRole
export def "restapi-v10-dictionary-user-role listStandardUserRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --servicePlanId: string # Internal identifier of a service plan.
  --page: int # The result set page number (1-indexed) to return (format: int32, default: 1, e.g. 1)
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
  --advancedPermissions: string@bool-completer # Specifies whether to return advanced permissions capabilities within `permissionsCapabilities` resource. The default value is false.
]: nothing -> record<uri: string, records: table<uri: string, id: string, displayName: string, description: string, siteCompatible: bool, custom: bool, scope: string, hidden: bool, lastUpdated: string, permissions: list>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "servicePlanId" $servicePlanId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "advancedPermissions" $advancedPermissions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapi/v1.0/dictionary/user-role" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Standard User Role
#
# GET /restapi/v1.0/dictionary/user-role/{roleId}
# operationId: readStandardUserRole
export def "restapi-v10-dictionary-user-role readStandardUserRole" [
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, displayName: string, description: string, siteCompatible: bool, custom: bool, scope: string, hidden: bool, lastUpdated: string, permissions: table<uri: string, id: string, siteCompatible: string, readOnly: bool, assignable: bool, permissionsCapabilities: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/dictionary/user-role/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Countries
#
# GET /restapi/v1.0/dictionary/country
# operationId: listCountries
export def "restapi-v10-dictionary-country listCountries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loginAllowed: string@bool-completer # Specifies whether the logging-in with the phone numbers of this country is enabled or not
  --signupAllowed: string@bool-completer # Indicates whether a signup/billing is allowed for a country. If not specified all countries are returned (according to other specified filters if any)
  --numberSelling: string@bool-completer # Specifies if RingCentral sells phone numbers of this country
  --page: int # Indicates a page number to retrieve. Only positive number values are accepted  (format: int32, default: 1)
  --perPage: int # Indicates a page size (number of items)  (format: int32, default: 100)
  --freeSoftphoneLine: string@bool-completer # Specifies if free phone line for softphone is available for a country or not
]: nothing -> record<uri: string, records: table<emergencyCalling: bool, isoCode: string, name: string, numberSelling: bool, loginAllowed: bool, signupAllowed: bool, freeSoftphoneLine: bool, localDialing: bool>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<perPage: int, page: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loginAllowed" $loginAllowed "scalar") (serialize-qp "signupAllowed" $signupAllowed "scalar") (serialize-qp "numberSelling" $numberSelling "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "freeSoftphoneLine" $freeSoftphoneLine "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restapi/v1.0/dictionary/country" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Country
#
# GET /restapi/v1.0/dictionary/country/{countryId}
# operationId: readCountry
export def "restapi-v10-dictionary-country readCountry" [
  countryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<emergencyCalling: bool, isoCode: string, name: string, numberSelling: bool, loginAllowed: bool, signupAllowed: bool, freeSoftphoneLine: bool, localDialing: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/v1.0/dictionary/country/($countryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register Device
#
# POST /restapi/v1.0/client-info/sip-provision
# operationId: createSIPRegistration
# --device shape: {id?: string, appExternalId?: string, computerName?: string, serial?: string}
# --sipInfo item shape: {transport?: "UDP"|"TCP"|"TLS"|"WSS"}
export def "restapi-v10-client-info-sip-provision createSIPRegistration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --device: record # Device information — shape: {id?: string, appExternalId?: string, computerName?: string, serial?: string}
  --sipInfo: list # SIP settings for device — item shape: {transport?: "UDP"|"TCP"|"TLS"|"WSS"}
  --softPhoneLineReassignment: string@softPhoneLineReassignment-completer # Supported for Softphone clients only. If 'SoftphoneLineReassignment' feature is enabled the reassignment process can be initialized, however if there is no DL for the given user's device then SPR-131 error code will be returned.  (default: None)
]: any -> record<device: record<uri: string, id: string, type: string, sku: string, status: string, name: string, serial: string, computerName: string, model: record<id: string, name: string, addons: list, features: list>, extension: record<id: int, uri: string, extensionNumber: string>, emergencyServiceAddress: record<street: string, street2: string, city: string, zip: string, customerName: string, state: string, stateId: string, stateIsoCode: string, stateName: string, countryId: string, countryIsoCode: string, country: string, countryName: string, outOfCountry: bool>, emergency: record<address: any, location: record, outOfCountry: bool, addressStatus: string, visibility: string, syncStatus: string, addressEditableStatus: string, addressRequired: bool, addressLocationOnly: bool>, shipping: record<status: string, carrier: string, trackingNumber: string, method: record, address: record>, phoneLines: list<record>, boxBillingId: int, useAsCommonPhone: bool, linePooling: string, inCompanyNet: bool, site: record<id: string, name: string>, lastLocationReportTime: string>, sipInfo: table<username: string, password: string, authorizationTypes: list, authorizationId: string, domain: string, outboundProxy: string, outboundProxyIPv6: string, outboundProxyBackup: string, outboundProxyIPv6Backup: string, transport: string, certificate: string, switchBackInterval: int, stunServers: list>, sipInfoPstn: table<username: string, password: string, authorizationTypes: list, authorizationId: string, domain: string, outboundProxy: string, outboundProxyIPv6: string, outboundProxyBackup: string, outboundProxyIPv6Backup: string, transport: string, certificate: string, switchBackInterval: int, stunServers: list>, sipFlags: record<voipFeatureEnabled: bool, voipCountryBlocked: bool, outboundCallsEnabled: bool, dscpEnabled: bool, dscpSignaling: int, dscpVoice: int, dscpVideo: int>, sipErrorCodes: list<string>, pollingInterval: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restapi/v1.0/client-info/sip-provision")
  let body = {device: $device, sipInfo: $sipInfo, softPhoneLineReassignment: $softPhoneLineReassignment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Version Info
#
# GET /restapi/{apiVersion}
# operationId: readAPIVersion
export def "restapi readAPIVersion" [
  apiVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, versionString: string, releaseDate: string, uriString: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restapi/($apiVersion)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Async Task Status
#
# GET /ai/status/v1/jobs/{jobId}
# operationId: caiJobStatusGet
export def "ai-status-jobs caiJobStatusGet" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<jobId: string, creationTime: string, completionTime: string, expirationTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ai/status/v1/jobs/($jobId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Conversational Summarization
#
# POST /ai/text/v1/async/summarize
# operationId: caiSummarize
# --utterances item shape: {speakerId: string, text: string, start: float, end: float}
export def "ai-text-async-summarize caiSummarize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook: string # The webhook URI to which the job response will be returned (format: uri)
  summaryType: string@summaryType-completer # Type of summary to be computed (e.g. AbstractiveShort)
  utterances: list # item shape: {speakerId: string, text: string, start: float, end: float}
]: any -> record<jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "webhook" $webhook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai/text/v1/async/summarize" $qp)
  let body = {summaryType: $summaryType, utterances: $utterances} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Smart Punctuation
#
# POST /ai/text/v1/async/punctuate
# operationId: caiPunctuate
export def "ai-text-async-punctuate caiPunctuate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook: string # The webhook URI to which the job response will be returned (format: uri)
  texts: list
]: any -> record<jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "webhook" $webhook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai/text/v1/async/punctuate" $qp)
  let body = {texts: $texts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Enrolled Speakers
#
# GET /ai/audio/v1/enrollments
# operationId: caiEnrollmentsList
export def "ai-audio-enrollments caiEnrollmentsList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --partial: string@bool-completer # Indicates if partially enrolled speakers should be returned
  --perPage: int # Number of enrollments to be returned per page (format: int32)
  --page: int # Page number to be returned (format: int32)
]: nothing -> record<paging: record<page: int, totalPages: int, perPage: int>, records: table<enrollmentQuality: string, enrollmentComplete: bool, speakerId: string, totalEnrollDuration: float, totalSpeechDuration: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "partial" $partial "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai/audio/v1/enrollments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Speaker Enrollment
#
# POST /ai/audio/v1/enrollments
# operationId: caiEnrollmentsCreate
export def "ai-audio-enrollments caiEnrollmentsCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  encoding: string@encoding-completer # The encoding of the original audio (e.g. Wav)
  --languageCode: string # Language spoken in the audio file. (e.g. en-US)
  content: string # Base64-encoded audio file data. (e.g. base64EncodedAudioInput)
  speakerId: string # The enrollment ID to be registered. Acceptable format [a-zA-Z0-9_]+ (e.g. JohnDoe)
]: any -> record<enrollmentQuality: string, enrollmentComplete: bool, speakerId: string, totalEnrollDuration: float, totalSpeechDuration: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ai/audio/v1/enrollments")
  let body = {encoding: $encoding, languageCode: $languageCode, content: $content, speakerId: $speakerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Speaker Enrollment Status
#
# GET /ai/audio/v1/enrollments/{speakerId}
# operationId: caiEnrollmentsGet
export def "ai-audio-enrollments caiEnrollmentsGet" [
  speakerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enrollmentQuality: string, enrollmentComplete: bool, speakerId: string, totalEnrollDuration: float, totalSpeechDuration: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ai/audio/v1/enrollments/($speakerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Speaker Enrollment
#
# DELETE /ai/audio/v1/enrollments/{speakerId}
# operationId: caiEnrollmentsDelete
export def "ai-audio-enrollments caiEnrollmentsDelete" [
  speakerId: string
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
  let full_url = (build-url $base $"/ai/audio/v1/enrollments/($speakerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Speaker Enrollment
#
# PATCH /ai/audio/v1/enrollments/{speakerId}
# operationId: caiEnrollmentsUpdate
export def "ai-audio-enrollments caiEnrollmentsUpdate" [
  speakerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  encoding: string@encoding-completer # The encoding of the original audio (e.g. Wav)
  --languageCode: string # Language spoken in the audio file. (e.g. en-US)
  content: string # Base64-encoded audio file data. (e.g. base64EncodedAudioInput)
]: any -> record<enrollmentQuality: string, enrollmentComplete: bool, speakerId: string, totalEnrollDuration: float, totalSpeechDuration: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ai/audio/v1/enrollments/($speakerId)")
  let body = {encoding: $encoding, languageCode: $languageCode, content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Speech to Text Conversion
#
# POST /ai/audio/v1/async/speech-to-text
# operationId: caiSpeechToText
# --speechContexts item shape: {phrases: list}
export def "ai-audio-async-speech-to-text caiSpeechToText" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook: string # The webhook URI to which the job response will be returned (format: uri)
  --enablePunctuation: string@bool-completer # Enables Smart Punctuation API.
  --enableSpeakerDiarization: string@bool-completer # Tags each word corresponding to the speaker. (default: false)
  --separateSpeakerPerChannel: string@bool-completer # Indicates that the input audio is multi-channel and each channel has a separate speaker. (default: false)
  --speechContexts: list # Indicates the words/phrases that will be used for boosting the transcript. This can help to boost accuracy for cases like Person Names, Company names etc. — item shape: {phrases: list}
]: any -> record<jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "webhook" $webhook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai/audio/v1/async/speech-to-text" $qp)
  let body = {enablePunctuation: $enablePunctuation, enableSpeakerDiarization: $enableSpeakerDiarization, separateSpeakerPerChannel: $separateSpeakerPerChannel, speechContexts: $speechContexts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Speaker Diarization
#
# POST /ai/audio/v1/async/speaker-diarize
# operationId: caiSpeakerDiarize
export def "ai-audio-async-speaker-diarize caiSpeakerDiarize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook: string # The webhook URI to which the job response will be returned (format: uri)
  --separateSpeakerPerChannel: string@bool-completer # Set to True if the input audio is multi-channel and each channel has a separate speaker. (e.g. false)
  --speakerCount: int # Number of speakers in the file, omit parameter if unknown (format: int32, e.g. 2)
  --speakerIds: list # Optional set of speakers to be identified from the call. (e.g. [speakerId1, speakerId2])
  --enableVoiceActivityDetection: string@bool-completer # Apply voice activity detection.
]: any -> record<jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "webhook" $webhook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai/audio/v1/async/speaker-diarize" $qp)
  let body = {separateSpeakerPerChannel: $separateSpeakerPerChannel, speakerCount: $speakerCount, speakerIds: $speakerIds, enableVoiceActivityDetection: $enableVoiceActivityDetection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Speaker Identification
#
# POST /ai/audio/v1/async/speaker-identify
# operationId: caiSpeakerIdentify
export def "ai-audio-async-speaker-identify caiSpeakerIdentify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook: string # The webhook URI to which the job response will be returned (format: uri)
  speakerIds: list # Set of enrolled speakers to be identified from the media. (e.g. [speakerId1, speakerId2])
  --enableVoiceActivityDetection: string@bool-completer # Apply voice activity detection.
]: any -> record<jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "webhook" $webhook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai/audio/v1/async/speaker-identify" $qp)
  let body = {speakerIds: $speakerIds, enableVoiceActivityDetection: $enableVoiceActivityDetection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Interaction Analytics
#
# POST /ai/insights/v1/async/analyze-interaction
# operationId: caiAnalyzeInteraction
# --speechContexts item shape: {phrases: list}
export def "ai-insights-async-analyze-interaction caiAnalyzeInteraction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook: string # The webhook URI to which the job response will be returned (format: uri)
  --insights: list
  --speechContexts: list # Indicates the words/phrases that will be used for boosting the transcript. This can help to boost accuracy for cases like Person Names, Company names etc. — item shape: {phrases: list}
]: any -> record<jobId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "webhook" $webhook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ai/insights/v1/async/analyze-interaction" $qp)
  let body = {insights: $insights, speechContexts: $speechContexts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List All Contents
#
# GET /cx/social-messaging/v1/contents
# operationId: socMsgListContents
export def "cx-social-messaging-contents socMsgListContents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --intervention: list # Filter based on the specified intervention identifiers. (e.g. [7f946431b6eebffafae642cc, re946431b6eebffafae642cc])
  --identity: list # Filter based on the specified identity identifiers. (e.g. [7f946431b6eebffafae642cc, re946431b6eebffafae642cc])
  --identityGroup: list # Filter based on the specified identity group identifiers. (e.g. [7f946431b6eebffafae642cc, re946431b6eebffafae642cc])
  --qp-source: list # Filter based on the specified channel identifiers. (e.g. [7f946431b6eebffafae642cc])
  --thread: list # Filter based on the specified thread identifiers. (e.g. [7f946431b6eebffafae642cc])
  --text: list # Filter based on the specified text(s). Provided multiple times, the values are ANDed.
  --status: list # Filter for specified status.
  --orderBy: string@orderBy-completer-3 # Order results by specified field. (default: -creationTime, e.g. +creationTime)
  --pageToken: string # The token indicating the particular page of the result set to be retrieved. If omitted the first page will be returned.
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "intervention" $intervention "multi") (serialize-qp "identity" $identity "multi") (serialize-qp "identityGroup" $identityGroup "multi") (serialize-qp "source" $qp_source "multi") (serialize-qp "thread" $thread "multi") (serialize-qp "text" $text "multi") (serialize-qp "status" $status "multi") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cx/social-messaging/v1/contents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Content
#
# POST /cx/social-messaging/v1/contents
# operationId: socMsgCreateContent
# --components item shape: {type?: string, parameters?: list}
export def "cx-social-messaging-contents socMsgCreateContent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --authorIdentityId: string # Identity identifier of the author of content.  Not mandatory on creation, by default it uses the token's user first identity on channel.  (e.g. 541014e17aa58d8ccf000023)
  --body-body: string # The content's body.  On creation this field is mandatory except for WhatsApp content using templates.  The following are the max length restrictions for the different channels supported. Channel and max length   * Apple Messages For Business (max length 10000)   * Email (max length 262144)   * RingCX Digital Messaging (max length 1024)   * Facebook (max length 8000)   * GoogleBusinessMessages (max length 3000)   * Google My Business (max length 4000)   * Instagram (max length 950)   * Instagram Messaging (max length 1000)   * LinkedIn (max length 3000)   * Messenger (max length 2000)   * Twitter (max length 280)   * Viber (max length 7000)   * WhatsApp (max length 3800)   * Youtube (max length 8000)  (e.g. Body of the content)
  --inReplyToContentId: string # The content identifier to which this content is a reply to.  On creation, if omitted, a new discussion will be created. If the channel does not support to initiate discussion this parameter is mandatory.  (e.g. 123414e17asdd8ccf000023)
  --public: string@bool-completer # True if the content is publicly visible on the remote channel (default).  Private content is NOT supported on every channel.  (default: true)
  --sourceId: string # Identifier of the channel.  On creation if `inReplyToContentId` is specified, the channel will be determined from it. Otherwise, this parameter is mandatory.  (e.g. fff415437asdd8ccf000023)
  --attachmentIds: list # An array containing the attachment identifiers that need to be attached to the content.  (e.g. [541014e17aa58d8ccf000023, 541014e17aa58d8ccf000023])
  --title: string # Applicable to Email channels only.  The subject of the email.  This field is mandatory when initiating a discussion.  (e.g. An email title)
  --body-to: any
  --cc: list # Applicable on Email channels only.  An array containing the email addresses used in sections of the email.  This parameter is mandatory when initiating a discussion.
  --bcc: list # Applicable on Email channels only.  An array containing the email addresses used in sections of the email.  This parameter is mandatory when initiating a discussion.
  --templateName: string # Applicable to WhatsApp channels only.  Name of the Whatsapp template to use for the content.  All available template names are visible on the Whatsapp Business Manager interface.  (e.g. customer_order_shipment_template)
  --templateLanguage: string # Applicable to WhatsApp channels only.  Language of the Whatsapp template to use for the content. All available template languages are visible on the Whatsapp Business Manager interface.  Language specified must conform to the ISO 639-1 alpha-2 codes for representing the names of languages.  (e.g. fr)
  --components: list # Applicable to WhatsApp channels only.  Component configuration of the Whatsapp template to use for the content.  All available components are visible on the Whatsapp Business Manager interface.  (e.g. [{Message1: [{param11: {type: Name, text: John}}, {param12: {type: Message, text: Product rocks!}}]}, {Message2: [{param21: {type: Agent Name, text: Alice}}, {param22: {type: Message, text: Thank you}}]}]) — item shape: {type?: string, parameters?: list}
  --contextData: record # Additional data of the content.  The contextData hash keys are the custom fields keys.  (e.g. {test1: value1, test2: value2})
  --autoSubmitted: string@bool-completer # Auto submitted content:   - won't reopen tasks or interventions   - can be used to send automatic messages like asking an user to follow on twitter, sending a survey, etc,   - doesn't get included in statistics
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cx/social-messaging/v1/contents")
  let body = {authorIdentityId: $authorIdentityId, body: $body_body, inReplyToContentId: $inReplyToContentId, public: $public, sourceId: $sourceId, attachmentIds: $attachmentIds, title: $title, to: $body_to, cc: $cc, bcc: $bcc, templateName: $templateName, templateLanguage: $templateLanguage, components: $components, contextData: $contextData, autoSubmitted: $autoSubmitted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Content
#
# GET /cx/social-messaging/v1/contents/{contentId}
# operationId: socMsgGetContent
export def "cx-social-messaging-contents socMsgGetContent" [
  contentId: string
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
  let full_url = (build-url $base $"/cx/social-messaging/v1/contents/($contentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List All Identities
#
# GET /cx/social-messaging/v1/identities
# operationId: socMsgListIdentities
export def "cx-social-messaging-identities socMsgListIdentities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourceId: string # Filter based on the specified sourceId.
  --identityGroupIds: list # Filter based on the specified identityGroupIds (separated by commas).
  --userId: string # Filter based on the specified userId.
  --uuid: string # Filter based on the specified uuid.
  --orderBy: string@orderBy-completer-3 # Order results by specified field. (default: -creationTime, e.g. +creationTime)
  --pageToken: string # The token indicating the particular page of the result set to be retrieved. If omitted the first page will be returned.
  --perPage: int # The number of items per page. If provided value in the request is greater than a maximum, the maximum value is applied  (format: int32, default: 100, e.g. 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sourceId" $sourceId "scalar") (serialize-qp "identityGroupIds" $identityGroupIds "csv") (serialize-qp "userId" $userId "scalar") (serialize-qp "uuid" $uuid "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cx/social-messaging/v1/identities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Identity
#
# GET /cx/social-messaging/v1/identities/{identityId}
# operationId: socMsgGetIdentity
export def "cx-social-messaging-identities socMsgGetIdentity" [
  identityId: string
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
  let full_url = (build-url $base $"/cx/social-messaging/v1/identities/($identityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Schemas
#
# GET /scim/v2/Schemas
# operationId: scimListSchemas2
export def "scim-schemas scimListSchemas2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-5 # Response content type
]: nothing -> record<Resources: table<id: string, name: string, description: string, attributes: list, meta: record>, itemsPerPage: int, schemas: list<string>, startIndex: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scim/v2/Schemas")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Schema
#
# GET /scim/v2/Schemas/{uri}
# operationId: scimGetSchema2
export def "scim-schemas scimGetSchema2" [
  uri: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-5 # Response content type
]: nothing -> record<id: string, name: string, description: string, attributes: table<name: string, type: string, subAttributes: list, multiValued: bool, description: string, required: bool, canonicalValues: list, caseExact: bool, mutability: string, returned: string, uniqueness: string, referenceTypes: list>, meta: record<created: string, lastModified: string, location: string, resourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scim/v2/Schemas/($uri)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search/List Users
#
# GET /scim/v2/Users
# operationId: scimSearchViaGet2
export def "scim-users scimSearchViaGet2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-5 # Response content type
  --filter: string # Only support 'userName' or 'email' filter expressions for now
  --startIndex: int # Start index (1-based) (format: int32, default: 1)
  --count: int # Page size (format: int32, default: 100)
]: nothing -> record<Resources: table<active: bool, addresses: list, emails: list, externalId: string, id: string, name: record, phoneNumbers: list, photos: list, schemas: list, title: string, urn_ietf_params_scim_schemas_extension_enterprise_2_0_User: record, userName: string, meta: record>, itemsPerPage: int, schemas: list<string>, startIndex: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scim/v2/Users" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create User
#
# POST /scim/v2/Users
# operationId: scimCreateUser2
# --addresses item shape: {country?: string, locality?: string, postalCode?: string, region?: string, streetAddress?: string, type: "work"}
# --emails item shape: {type: "work", value: string}
# --name shape: {familyName: string, givenName: string}
# --phoneNumbers item shape: {type: "work"|"mobile"|"other", value: string}
# --photos item shape: {type: "photo", value: string}
# --urn:ietf:params:scim:schemas:extension:enterprise:2.0:User shape: {department?: string}
export def "scim-users scimCreateUser2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-5 # Response content type
  --active: string@bool-completer # User status (default: false)
  --addresses: list # item shape: {country?: string, locality?: string, postalCode?: string, region?: string, streetAddress?: string, type: "work"}
  emails: list # item shape: {type: "work", value: string}
  --externalId: string # External unique resource ID defined by provisioning client
  --id: string # Unique resource ID defined by RingCentral
  name: record # shape: {familyName: string, givenName: string}
  --phoneNumbers: list # item shape: {type: "work"|"mobile"|"other", value: string}
  --photos: list # item shape: {type: "photo", value: string}
  schemas: list
  --title: string # User title
  --urn:ietf:params:scim:schemas:extension:enterprise:20:User: record # shape: {department?: string}
  userName: string # MUST be same as work type email address
]: any -> record<active: bool, addresses: table<country: string, locality: string, postalCode: string, region: string, streetAddress: string, type: string>, emails: table<type: string, value: string>, externalId: string, id: string, name: record<familyName: string, givenName: string>, phoneNumbers: table<type: string, value: string>, photos: table<type: string, value: string>, schemas: list<string>, title: string, urn_ietf_params_scim_schemas_extension_enterprise_2_0_User: record<department: string>, userName: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scim/v2/Users")
  let body = {active: $active, addresses: $addresses, emails: $emails, externalId: $externalId, id: $id, name: $name, phoneNumbers: $phoneNumbers, photos: $photos, schemas: $schemas, title: $title, urn:ietf:params:scim:schemas:extension:enterprise:2.0:User: $urn:ietf:params:scim:schemas:extension:enterprise:20:User, userName: $userName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search/List Users
#
# POST /scim/v2/Users/.search
# operationId: scimSearchViaPost2
export def "scim-users-search scimSearchViaPost2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-5 # Response content type
  --count: int # Page size (format: int32)
  --filter: string # Only support 'userName' or 'email' filter expressions for now
  --schemas: list
  --startIndex: int # Start index (1-based) (format: int32)
]: any -> record<Resources: table<active: bool, addresses: list, emails: list, externalId: string, id: string, name: record, phoneNumbers: list, photos: list, schemas: list, title: string, urn_ietf_params_scim_schemas_extension_enterprise_2_0_User: record, userName: string, meta: record>, itemsPerPage: int, schemas: list<string>, startIndex: int, totalResults: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scim/v2/Users/.search")
  let body = {count: $count, filter: $filter, schemas: $schemas, startIndex: $startIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get User
#
# GET /scim/v2/Users/{scimUserId}
# operationId: scimGetUser2
export def "scim-users scimGetUser2" [
  scimUserId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-5 # Response content type
]: nothing -> record<active: bool, addresses: table<country: string, locality: string, postalCode: string, region: string, streetAddress: string, type: string>, emails: table<type: string, value: string>, externalId: string, id: string, name: record<familyName: string, givenName: string>, phoneNumbers: table<type: string, value: string>, photos: table<type: string, value: string>, schemas: list<string>, title: string, urn_ietf_params_scim_schemas_extension_enterprise_2_0_User: record<department: string>, userName: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scim/v2/Users/($scimUserId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update/Replace User
#
# PUT /scim/v2/Users/{scimUserId}
# operationId: scimUpdateUser2
# --addresses item shape: {country?: string, locality?: string, postalCode?: string, region?: string, streetAddress?: string, type: "work"}
# --emails item shape: {type: "work", value: string}
# --name shape: {familyName: string, givenName: string}
# --phoneNumbers item shape: {type: "work"|"mobile"|"other", value: string}
# --photos item shape: {type: "photo", value: string}
# --urn:ietf:params:scim:schemas:extension:enterprise:2.0:User shape: {department?: string}
export def "scim-users scimUpdateUser2" [
  scimUserId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-5 # Response content type
  --active: string@bool-completer # User status (default: false)
  --addresses: list # item shape: {country?: string, locality?: string, postalCode?: string, region?: string, streetAddress?: string, type: "work"}
  emails: list # item shape: {type: "work", value: string}
  --externalId: string # External unique resource ID defined by provisioning client
  --id: string # Unique resource ID defined by RingCentral
  name: record # shape: {familyName: string, givenName: string}
  --phoneNumbers: list # item shape: {type: "work"|"mobile"|"other", value: string}
  --photos: list # item shape: {type: "photo", value: string}
  schemas: list
  --title: string # User title
  --urn:ietf:params:scim:schemas:extension:enterprise:20:User: record # shape: {department?: string}
  userName: string # MUST be same as work type email address
]: any -> record<active: bool, addresses: table<country: string, locality: string, postalCode: string, region: string, streetAddress: string, type: string>, emails: table<type: string, value: string>, externalId: string, id: string, name: record<familyName: string, givenName: string>, phoneNumbers: table<type: string, value: string>, photos: table<type: string, value: string>, schemas: list<string>, title: string, urn_ietf_params_scim_schemas_extension_enterprise_2_0_User: record<department: string>, userName: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scim/v2/Users/($scimUserId)")
  let body = {active: $active, addresses: $addresses, emails: $emails, externalId: $externalId, id: $id, name: $name, phoneNumbers: $phoneNumbers, photos: $photos, schemas: $schemas, title: $title, urn:ietf:params:scim:schemas:extension:enterprise:2.0:User: $urn:ietf:params:scim:schemas:extension:enterprise:20:User, userName: $userName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete User
#
# DELETE /scim/v2/Users/{scimUserId}
# operationId: scimDeleteUser2
export def "scim-users scimDeleteUser2" [
  scimUserId: string
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
  let full_url = (build-url $base $"/scim/v2/Users/($scimUserId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update/Patch User
#
# PATCH /scim/v2/Users/{scimUserId}
# operationId: scimPatchUser2
# --Operations item shape: {op: "add"|"replace"|"remove", path?: string, value?: string}
export def "scim-users scimPatchUser2" [
  scimUserId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-5 # Response content type
  Operations: list # Patch operations list — item shape: {op: "add"|"replace"|"remove", path?: string, value?: string}
  schemas: list
]: any -> record<active: bool, addresses: table<country: string, locality: string, postalCode: string, region: string, streetAddress: string, type: string>, emails: table<type: string, value: string>, externalId: string, id: string, name: record<familyName: string, givenName: string>, phoneNumbers: table<type: string, value: string>, photos: table<type: string, value: string>, schemas: list<string>, title: string, urn_ietf_params_scim_schemas_extension_enterprise_2_0_User: record<department: string>, userName: string, meta: record<created: string, lastModified: string, location: string, resourceType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scim/v2/Users/($scimUserId)")
  let body = {Operations: $Operations, schemas: $schemas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Provider Config
#
# GET /scim/v2/ServiceProviderConfig
# operationId: scimGetProviderConfig2
export def "scim-service-provider-config scimGetProviderConfig2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-5 # Response content type
]: nothing -> record<authenticationSchemes: table<description: string, documentationUri: string, name: string, specUri: string, primary: bool>, bulk: record<maxOperations: int, maxPayloadSize: int, supported: bool>, changePassword: record<supported: bool>, etag: record<supported: bool>, filter: record<maxResults: int, supported: bool>, patch: record<supported: bool>, schemas: list<string>, sort: record<supported: bool>, xmlDataFormat: record<supported: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scim/v2/ServiceProviderConfig")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Resource Types
#
# GET /scim/v2/ResourceTypes
# operationId: scimListResourceTypes2
export def "scim-resource-types scimListResourceTypes2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-5 # Response content type
]: nothing -> record<Resources: table<id: string, name: string, endpoint: string, description: string, schema: string, schemaExtensions: list, meta: record>, itemsPerPage: int, schemas: list<string>, startIndex: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scim/v2/ResourceTypes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Resource Type
#
# GET /scim/v2/ResourceTypes/{type}
# operationId: scimGetResourceType2
export def "scim-resource-types scimGetResourceType2" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-5 # Response content type
]: nothing -> record<id: string, name: string, endpoint: string, description: string, schema: string, schemaExtensions: table<schema: string, required: bool>, meta: record<created: string, lastModified: string, location: string, resourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/scim/v2/ResourceTypes/($type)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Calls Aggregation Data
#
# POST /analytics/calls/v1/accounts/{accountId}/aggregation/fetch
# operationId: analyticsCallsAggregationFetch
# --timeSettings shape: {timeZone: string, timeRange: record, advancedTimeSettings?: record}
# --callFilters shape: {extensionFilters?: record, queues?: list, calledNumbers?: list, directions?: list, origins?: list, callResponses?: list, callResults?: list, callSegments?: list, callActions?: list, companyHours?: list, callDuration?: record, timeSpent?: record, queueSla?: list, callTypes?: list}
# --responseOptions shape: {counters?: record, timers?: record}
export def "analytics-calls-accounts-aggregation-fetch analyticsCallsAggregationFetch" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The current page number (positive numbers only) (format: int32)
  --perPage: int # Number of records displayed on a page (positive numbers only, max value of 200) (format: int32)
  grouping: any # This field specifies the dimensions by which the response should be grouped and specific keys to narrow the response. See also [Call Aggregate reports](https://developers.ringcentral.com/guide/analytics/aggregate) or [Call Timeline reports](https://developers.ringcentral.com/guide/analytics/timeline) pages in the developer guide for more information
  timeSettings: record # Date-time range for the calls. The call is considered to be within time range if it started within time range. Both borders are inclusive — shape: {timeZone: string, timeRange: record, advancedTimeSettings?: record}
  --callFilters: record # Optional filters that limit the scope of calls (joined via AND) — shape: {extensionFilters?: record, queues?: list, calledNumbers?: list, directions?: list, origins?: list, callResponses?: list, callResults?: list, callSegments?: list, callActions?: list, companyHours?: list, callDuration?: record, timeSpent?: record, queueSla?: list, callTypes?: list}
  responseOptions: record # This field provides mapping of possible breakdown options for call aggregation and aggregation formula — shape: {counters?: record, timers?: record}
]: any -> record<paging: record<page: int, perPage: int, totalPages: int, totalElements: int>, data: record<groupedBy: string, records: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analytics/calls/v1/accounts/($accountId)/aggregation/fetch" $qp)
  let body = {grouping: $grouping, timeSettings: $timeSettings, callFilters: $callFilters, responseOptions: $responseOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Calls Timeline Data
#
# POST /analytics/calls/v1/accounts/{accountId}/timeline/fetch
# operationId: analyticsCallsTimelineFetch
# --timeSettings shape: {timeZone: string, timeRange: record, advancedTimeSettings?: record}
# --callFilters shape: {extensionFilters?: record, queues?: list, calledNumbers?: list, directions?: list, origins?: list, callResponses?: list, callResults?: list, callSegments?: list, callActions?: list, companyHours?: list, callDuration?: record, timeSpent?: record, queueSla?: list, callTypes?: list}
# --responseOptions shape: {counters?: record, timers?: record}
export def "analytics-calls-accounts-timeline-fetch analyticsCallsTimelineFetch" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --interval: string # Aggregation interval
  --page: int # The current page number (positive numbers only) (format: int32)
  --perPage: int # Number of records displayed on a page (positive numbers only, max value of 20) (format: int32)
  grouping: any # This field specifies the dimensions by which the response should be grouped and specific keys to narrow the response. See also [Call Aggregate reports](https://developers.ringcentral.com/guide/analytics/aggregate) or [Call Timeline reports](https://developers.ringcentral.com/guide/analytics/timeline) pages in the developer guide for more information
  timeSettings: record # Date-time range for the calls. The call is considered to be within time range if it started within time range. Both borders are inclusive — shape: {timeZone: string, timeRange: record, advancedTimeSettings?: record}
  --callFilters: record # Optional filters that limit the scope of calls (joined via AND) — shape: {extensionFilters?: record, queues?: list, calledNumbers?: list, directions?: list, origins?: list, callResponses?: list, callResults?: list, callSegments?: list, callActions?: list, companyHours?: list, callDuration?: record, timeSpent?: record, queueSla?: list, callTypes?: list}
  responseOptions: record # Counters and timers options for calls breakdown — shape: {counters?: record, timers?: record}
]: any -> record<paging: record<page: int, perPage: int, totalPages: int, totalElements: int>, data: record<groupedBy: string, records: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "interval" $interval "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/analytics/calls/v1/accounts/($accountId)/timeline/fetch" $qp)
  let body = {grouping: $grouping, timeSettings: $timeSettings, callFilters: $callFilters, responseOptions: $responseOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Task
#
# GET /team-messaging/v1/tasks/{taskId}
# operationId: readTaskNew
export def "team-messaging-tasks readTaskNew" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, creationTime: string, lastModifiedTime: string, type: string, creator: record<id: string>, chatIds: list<string>, status: string, subject: string, assignees: table<id: string, status: string>, completenessCondition: string, completenessPercentage: int, startDate: string, dueDate: string, color: string, section: string, description: string, recurrence: record<schedule: string, endingCondition: string, endingAfter: int, endingOn: string>, attachments: table<id: string, type: string, name: string, contentUri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/tasks/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Task
#
# DELETE /team-messaging/v1/tasks/{taskId}
# operationId: deleteTaskNew
export def "team-messaging-tasks delete" [
  taskId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/tasks/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Task
#
# PATCH /team-messaging/v1/tasks/{taskId}
# operationId: patchTaskNew
# --assignees item shape: {id?: string}
# --recurrence shape: {schedule?: "None"|"Daily"|"Weekdays"|"Weekly"|"Monthly"|"Yearly", endingCondition?: "None"|"Count"|"Date", endingAfter?: int, endingOn?: string}
# --attachments item shape: {id?: string, type?: "File"|"Note"|"Event"|"Card"}
export def "team-messaging-tasks patch" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subject: string # Task name/subject. Max allowed length is 250 characters.
  --assignees: list # item shape: {id?: string}
  --completenessCondition: string@completenessCondition-completer
  --startDate: string # Task start date in UTC time zone (format: date-time)
  --dueDate: string # Task due date/time in UTC time zone (format: date-time)
  --color: string@color-completer
  --section: string # Task section to group / search by. Max allowed length is 100 characters.
  --description: string # Task details. Max allowed length is 102400 characters (100kB)
  --recurrence: record # Task information — shape: {schedule?: "None"|"Daily"|"Weekdays"|"Weekly"|"Monthly"|"Yearly", endingCondition?: "None"|"Count"|"Date", endingAfter?: int, endingOn?: string}
  --attachments: list # item shape: {id?: string, type?: "File"|"Note"|"Event"|"Card"}
]: any -> record<records: table<id: string, creationTime: string, lastModifiedTime: string, type: string, creator: record, chatIds: list, status: string, subject: string, assignees: list, completenessCondition: string, completenessPercentage: int, startDate: string, dueDate: string, color: string, section: string, description: string, recurrence: record, attachments: list>, navigation: record<prevPageToken: string, nextPageToken: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/tasks/($taskId)")
  let body = {subject: $subject, assignees: $assignees, completenessCondition: $completenessCondition, startDate: $startDate, dueDate: $dueDate, color: $color, section: $section, description: $description, recurrence: $recurrence, attachments: $attachments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Complete Task
#
# POST /team-messaging/v1/tasks/{taskId}/complete
# operationId: completeTaskNew
# --assignees item shape: {id?: string}
export def "team-messaging-tasks-complete completeTaskNew" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-7 # Completeness status
  --assignees: list # item shape: {id?: string}
  --completenessPercentage: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/tasks/($taskId)/complete")
  let body = {status: $status, assignees: $assignees, completenessPercentage: $completenessPercentage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List User Events
#
# GET /team-messaging/v1/events
# operationId: readGlipEventsNew
export def "team-messaging-events readGlipEventsNew" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-6 # Response content type
  --recordCount: int # Number of groups to be fetched by one request. The maximum value is 250, by default - 30. (format: int32, default: 30)
  --pageToken: string # Token of a page to be returned
]: nothing -> record<records: table<id: string, creatorId: string, title: string, startTime: string, endTime: string, allDay: bool, recurrence: record, color: string, location: string, description: string>, navigation: record<prevPageToken: string, nextPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recordCount" $recordCount "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team-messaging/v1/events" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Event
#
# POST /team-messaging/v1/events
# operationId: createEventNew
# --recurrence shape: {schedule?: "None"|"Day"|"Weekday"|"Week"|"Month"|"Year", endingCondition?: "None"|"Count"|"Date", endingAfter?: int, endingOn?: string}
export def "team-messaging-events createEventNew" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Internal identifier of an event
  --creatorId: string # Internal identifier of a person created an event
  title: string # Event title
  startTime: string # Datetime of starting an event (format: date-time)
  endTime: string # Datetime of ending an event (format: date-time)
  --allDay: string@bool-completer # Indicates whether event has some specific time slot or lasts for whole day(s) (default: false)
  --recurrence: record # shape: {schedule?: "None"|"Day"|"Weekday"|"Week"|"Month"|"Year", endingCondition?: "None"|"Count"|"Date", endingAfter?: int, endingOn?: string}
  --color: string@color-completer # Color of Event title (including its presentation in Calendar) (default: Black)
  --location: string # Event location
  --description: string # Event details
]: any -> record<id: string, creatorId: string, title: string, startTime: string, endTime: string, allDay: bool, recurrence: record<schedule: string, endingCondition: string, endingAfter: int, endingOn: string>, color: string, location: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team-messaging/v1/events")
  let body = {id: $id, creatorId: $creatorId, title: $title, startTime: $startTime, endTime: $endTime, allDay: $allDay, recurrence: $recurrence, color: $color, location: $location, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Event
#
# GET /team-messaging/v1/events/{eventId}
# operationId: readEventNew
export def "team-messaging-events readEventNew" [
  eventId: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-6 # Response content type
]: nothing -> record<id: string, creatorId: string, title: string, startTime: string, endTime: string, allDay: bool, recurrence: record<schedule: string, endingCondition: string, endingAfter: int, endingOn: string>, color: string, location: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/events/($eventId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Event
#
# PUT /team-messaging/v1/events/{eventId}
# operationId: updateEventNew
# --recurrence shape: {schedule?: "None"|"Day"|"Weekday"|"Week"|"Month"|"Year", endingCondition?: "None"|"Count"|"Date", endingAfter?: int, endingOn?: string}
export def "team-messaging-events updateEventNew" [
  eventId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Internal identifier of an event
  --creatorId: string # Internal identifier of a person created an event
  title: string # Event title
  startTime: string # Datetime of starting an event (format: date-time)
  endTime: string # Datetime of ending an event (format: date-time)
  --allDay: string@bool-completer # Indicates whether event has some specific time slot or lasts for whole day(s) (default: false)
  --recurrence: record # shape: {schedule?: "None"|"Day"|"Weekday"|"Week"|"Month"|"Year", endingCondition?: "None"|"Count"|"Date", endingAfter?: int, endingOn?: string}
  --color: string@color-completer # Color of Event title (including its presentation in Calendar) (default: Black)
  --location: string # Event location
  --description: string # Event details
]: any -> record<id: string, creatorId: string, title: string, startTime: string, endTime: string, allDay: bool, recurrence: record<schedule: string, endingCondition: string, endingAfter: int, endingOn: string>, color: string, location: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/events/($eventId)")
  let body = {id: $id, creatorId: $creatorId, title: $title, startTime: $startTime, endTime: $endTime, allDay: $allDay, recurrence: $recurrence, color: $color, location: $location, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Event
#
# DELETE /team-messaging/v1/events/{eventId}
# operationId: deleteEventNew
export def "team-messaging-events delete" [
  eventId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/events/($eventId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Recent Chats
#
# GET /team-messaging/v1/recent/chats
# operationId: listRecentChatsNew
export def "team-messaging-recent-chats listRecentChatsNew" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: list # Type of chats to be fetched. By default, all chat types are returned
  --recordCount: int # Max number of chats to be fetched by one request (Not more than 250). (format: int32, default: 30)
]: nothing -> record<records: table<id: string, type: string, public: bool, name: string, description: string, status: string, creationTime: string, lastModifiedTime: string, members: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "multi") (serialize-qp "recordCount" $recordCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team-messaging/v1/recent/chats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload File
#
# POST /team-messaging/v1/files
# operationId: createGlipFileNew
export def "team-messaging-files createGlipFileNew" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --groupId: int # Internal identifier of a group to which the post with attachment will be added to (format: int64)
  --name: string # Name of a file attached
  --body-body: string # The file (binary or multipart/form-data) to upload (format: binary)
]: any -> record<id: string, contentUri: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupId" $groupId "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team-messaging/v1/files" $qp)
  let body = {body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List Chats
#
# GET /team-messaging/v1/chats
# operationId: listGlipChatsNew
export def "team-messaging-chats listGlipChatsNew" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: list # Type of chats to be fetched. By default, all type of chats will be fetched
  --recordCount: int # Number of chats to be fetched by one request. The maximum value is 250, by default - 30. (format: int32, default: 30)
  --pageToken: string # Pagination token.
]: nothing -> record<records: table<id: string, type: string, public: bool, name: string, description: string, status: string, creationTime: string, lastModifiedTime: string, members: list>, navigation: record<prevPageToken: string, nextPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "multi") (serialize-qp "recordCount" $recordCount "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team-messaging/v1/chats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Chat
#
# GET /team-messaging/v1/chats/{chatId}
# operationId: readGlipChatNew
export def "team-messaging-chats readGlipChatNew" [
  chatId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, public: bool, name: string, description: string, status: string, creationTime: string, lastModifiedTime: string, members: table<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/chats/($chatId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove Chat from Favorites
#
# POST /team-messaging/v1/chats/{chatId}/unfavorite
# operationId: unfavoriteGlipChatNew
export def "team-messaging-chats-unfavorite unfavoriteGlipChatNew" [
  chatId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/chats/($chatId)/unfavorite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Chat Tasks
#
# GET /team-messaging/v1/chats/{chatId}/tasks
# operationId: listChatTasksNew
export def "team-messaging-chats-tasks listChatTasksNew" [
  chatId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --creationTimeTo: string # The end datetime for resulting records in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format including timezone, e.g. 2019-03-10T18:23:45Z  (default: now)
  --creationTimeFrom: string # The start datetime for resulting records in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format including timezone, e.g. 2016-02-23T00:00:00
  --creatorId: list # Internal identifier of a task creator
  --status: list # Task execution status
  --assignmentStatus: string@assignmentStatus-completer # Task assignment status
  --assigneeId: list # Internal identifier of a task assignee
  --assigneeStatus: string@assigneeStatus-completer # Task execution status by assignee(-s) specified in assigneeId
  --pageToken: string # Token of the current page. If token is omitted then the first page should be returned
  --recordCount: int # Number of records to be returned per screen (format: int32, default: 30)
]: nothing -> record<records: table<id: string, creationTime: string, lastModifiedTime: string, type: string, creator: record, chatIds: list, status: string, subject: string, assignees: list, completenessCondition: string, completenessPercentage: int, startDate: string, dueDate: string, color: string, section: string, description: string, recurrence: record, attachments: list>, navigation: record<prevPageToken: string, nextPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "creationTimeTo" $creationTimeTo "scalar") (serialize-qp "creationTimeFrom" $creationTimeFrom "scalar") (serialize-qp "creatorId" $creatorId "csv") (serialize-qp "status" $status "csv") (serialize-qp "assignmentStatus" $assignmentStatus "scalar") (serialize-qp "assigneeId" $assigneeId "csv") (serialize-qp "assigneeStatus" $assigneeStatus "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "recordCount" $recordCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/team-messaging/v1/chats/($chatId)/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Task
#
# POST /team-messaging/v1/chats/{chatId}/tasks
# operationId: createTaskNew
# --assignees item shape: {id?: string}
# --recurrence shape: {schedule?: "None"|"Daily"|"Weekdays"|"Weekly"|"Monthly"|"Yearly", endingCondition?: "None"|"Count"|"Date", endingAfter?: int, endingOn?: string}
# --attachments item shape: {id?: string, type?: "File"|"Note"|"Event"|"Card"}
export def "team-messaging-chats-tasks createTaskNew" [
  chatId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subject: string # Task name/subject. Max allowed length is 250 characters
  assignees: list # item shape: {id?: string}
  --completenessCondition: string@completenessCondition-completer # default: Simple
  --startDate: string # Task start date in UTC time zone. (format: date-time)
  --dueDate: string # Task due date/time in UTC time zone. (format: date-time)
  --color: string@color-completer # default: Black
  --section: string # Task section to group / search by. Max allowed length is 100 characters.
  --description: string # Task details. Max allowed length is 102400 characters (100kB).
  --recurrence: record # Task information — shape: {schedule?: "None"|"Daily"|"Weekdays"|"Weekly"|"Monthly"|"Yearly", endingCondition?: "None"|"Count"|"Date", endingAfter?: int, endingOn?: string}
  --attachments: list # item shape: {id?: string, type?: "File"|"Note"|"Event"|"Card"}
]: any -> record<id: string, creationTime: string, lastModifiedTime: string, type: string, creator: record<id: string>, chatIds: list<string>, status: string, subject: string, assignees: table<id: string, status: string>, completenessCondition: string, completenessPercentage: int, startDate: string, dueDate: string, color: string, section: string, description: string, recurrence: record<schedule: string, endingCondition: string, endingAfter: int, endingOn: string>, attachments: table<id: string, type: string, name: string, contentUri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/chats/($chatId)/tasks")
  let body = {subject: $subject, assignees: $assignees, completenessCondition: $completenessCondition, startDate: $startDate, dueDate: $dueDate, color: $color, section: $section, description: $description, recurrence: $recurrence, attachments: $attachments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Posts
#
# GET /team-messaging/v1/chats/{chatId}/posts
# operationId: readGlipPostsNew
export def "team-messaging-chats-posts readGlipPostsNew" [
  chatId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recordCount: int # Max number of posts to be fetched by one request (not more than 250) (format: int32, default: 30)
  --pageToken: string # Pagination token.
]: nothing -> record<records: table<id: string, groupId: string, type: string, text: string, creatorId: string, addedPersonIds: list, creationTime: string, lastModifiedTime: string, attachments: list, mentions: list, activity: string, title: string, iconUri: string, iconEmoji: string>, navigation: record<prevPageToken: string, nextPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recordCount" $recordCount "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/team-messaging/v1/chats/($chatId)/posts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Post
#
# POST /team-messaging/v1/chats/{chatId}/posts
# operationId: createGlipPostNew
# --attachments item shape: {id?: string, type?: "File"|"Note"|"Event"|"Card"}
export def "team-messaging-chats-posts createGlipPostNew" [
  chatId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # Text of a post. Maximum length is 10000 symbols. Mentions can be added in .md format `![:Type](id)`
  --attachments: list # Identifier(s) of attachments. Maximum number of attachments is 25 — item shape: {id?: string, type?: "File"|"Note"|"Event"|"Card"}
]: any -> record<id: string, groupId: string, type: string, text: string, creatorId: string, addedPersonIds: list<string>, creationTime: string, lastModifiedTime: string, attachments: table<id: string, type: string, fallback: string, intro: string, author: record, title: string, text: string, imageUri: string, thumbnailUri: string, fields: list, footnote: record, creatorId: string, startTime: string, endTime: string, allDay: bool, recurrence: record, color: string, location: string, description: string>, mentions: table<id: string, type: string, name: string>, activity: string, title: string, iconUri: string, iconEmoji: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/chats/($chatId)/posts")
  let body = {text: $text, attachments: $attachments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Post
#
# GET /team-messaging/v1/chats/{chatId}/posts/{postId}
# operationId: readGlipPostNew
export def "team-messaging-chats-posts readGlipPostNew" [
  chatId: string
  postId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, groupId: string, type: string, text: string, creatorId: string, addedPersonIds: list<string>, creationTime: string, lastModifiedTime: string, attachments: table<id: string, type: string, fallback: string, intro: string, author: record, title: string, text: string, imageUri: string, thumbnailUri: string, fields: list, footnote: record, creatorId: string, startTime: string, endTime: string, allDay: bool, recurrence: record, color: string, location: string, description: string>, mentions: table<id: string, type: string, name: string>, activity: string, title: string, iconUri: string, iconEmoji: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/chats/($chatId)/posts/($postId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Post
#
# DELETE /team-messaging/v1/chats/{chatId}/posts/{postId}
# operationId: deleteGlipPostNew
export def "team-messaging-chats-posts delete" [
  chatId: string
  postId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/chats/($chatId)/posts/($postId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Post
#
# PATCH /team-messaging/v1/chats/{chatId}/posts/{postId}
# operationId: patchGlipPostNew
export def "team-messaging-chats-posts patch" [
  chatId: string
  postId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # Post text.
]: any -> record<id: string, groupId: string, type: string, text: string, creatorId: string, addedPersonIds: list<string>, creationTime: string, lastModifiedTime: string, attachments: table<id: string, type: string, fallback: string, intro: string, author: record, title: string, text: string, imageUri: string, thumbnailUri: string, fields: list, footnote: record, creatorId: string, startTime: string, endTime: string, allDay: bool, recurrence: record, color: string, location: string, description: string>, mentions: table<id: string, type: string, name: string>, activity: string, title: string, iconUri: string, iconEmoji: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/chats/($chatId)/posts/($postId)")
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Chat to Favorites
#
# POST /team-messaging/v1/chats/{chatId}/favorite
# operationId: favoriteGlipChatNew
export def "team-messaging-chats-favorite favoriteGlipChatNew" [
  chatId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/chats/($chatId)/favorite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Adaptive Card
#
# POST /team-messaging/v1/chats/{chatId}/adaptive-cards
# operationId: createGlipAdaptiveCardNew
# --body item shape: {type?: "Container", items?: list}
# --actions item shape: {type?: "Action.ShowCard"|"Action.Submit"|"Action.OpenUrl"|"Action.ToggleVisibility", title?: string, card?: record, url?: string}
# --selectAction shape: {type: "Action.Submit"|"Action.OpenUrl"|"Action.ToggleVisibility"}
export def "team-messaging-chats-adaptive-cards createGlipAdaptiveCardNew" [
  chatId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-19 # Type of attachment. This field is mandatory and filled on server side - will be ignored if set in request body
  version: string # Version. This field is mandatory and filled on server side - will be ignored if set in request body
  --body-body: list # List of adaptive cards with the detailed information — item shape: {type?: "Container", items?: list}
  --actions: list # item shape: {type?: "Action.ShowCard"|"Action.Submit"|"Action.OpenUrl"|"Action.ToggleVisibility", title?: string, card?: record, url?: string}
  --selectAction: record # An action that will be invoked when the card is tapped or selected. `Action.ShowCard` is not supported — shape: {type: "Action.Submit"|"Action.OpenUrl"|"Action.ToggleVisibility"}
  --fallbackText: string
  --backgroundImage: any # Specifies the background image of a card
  --minHeight: string # Specifies the minimum height of the card in pixels (e.g. 50px)
  --speak: string # Specifies what should be spoken for this entire card. This is simple text or SSML fragment
  --lang: string@lang-completer # The 2-letter ISO-639-1 language used in the card. Used to localize any date/time functions
  --verticalContentAlignment: any # Defines how the content should be aligned vertically within the container. Only relevant for fixed-height cards, or cards with a `minHeight` specified
]: any -> record<id: string, creationTime: string, lastModifiedTime: string, _schema: string, type: string, version: string, creator: record<id: string>, chatIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/chats/($chatId)/adaptive-cards")
  let body = {type: $type, version: $version, body: $body_body, actions: $actions, selectAction: $selectAction, fallbackText: $fallbackText, backgroundImage: $backgroundImage, minHeight: $minHeight, speak: $speak, lang: $lang, verticalContentAlignment: $verticalContentAlignment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Notes
#
# GET /team-messaging/v1/chats/{chatId}/notes
# operationId: listChatNotesNew
export def "team-messaging-chats-notes listChatNotesNew" [
  chatId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --creationTimeTo: string # The end datetime for resulting records in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format including timezone, e.g. 2019-03-10T18:23:45. The default value is Now.
  --creationTimeFrom: string # The start datetime for resulting records in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format including timezone
  --creatorId: string # Internal identifier of the user that created the note. Multiple values are supported
  --status: string@status-completer-8 # Status of notes to be fetched; if not specified all notes are fetched by default.
  --pageToken: string # Pagination token
  --recordCount: int # Max number of notes to be fetched by one request; the value range is 1-250. (format: int32, default: 30)
]: nothing -> record<records: table<id: string, title: string, chatIds: list, preview: string, creator: record, lastModifiedBy: record, lockedBy: record, status: string, creationTime: string, lastModifiedTime: string, type: string>, navigation: record<prevPageToken: string, nextPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "creationTimeTo" $creationTimeTo "scalar") (serialize-qp "creationTimeFrom" $creationTimeFrom "scalar") (serialize-qp "creatorId" $creatorId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "recordCount" $recordCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/team-messaging/v1/chats/($chatId)/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Note
#
# POST /team-messaging/v1/chats/{chatId}/notes
# operationId: createChatNoteNew
export def "team-messaging-chats-notes createChatNoteNew" [
  chatId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # Title of a note. Max allowed length is 250 characters
  --body-body: string # Contents of a note; HTML markup text. Max allowed length is 1048576 characters (1 Mb).
]: any -> record<id: string, title: string, chatIds: list<string>, preview: string, creator: record<id: string>, lastModifiedBy: record<id: string>, lockedBy: record<id: string>, status: string, creationTime: string, lastModifiedTime: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/chats/($chatId)/notes")
  let body = {title: $title, body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Adaptive Card
#
# GET /team-messaging/v1/adaptive-cards/{cardId}
# operationId: getGlipAdaptiveCardNew
export def "team-messaging-adaptive-cards get" [
  cardId: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, creationTime: string, lastModifiedTime: string, _schema: string, type: string, version: string, creator: record<id: string>, chatIds: list<string>, body: table<type: string, items: list>, actions: table<type: string, title: string, card: record, url: string>, selectAction: record<type: string>, fallbackText: string, backgroundImage: any, minHeight: string, speak: string, lang: string, verticalContentAlignment: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/adaptive-cards/($cardId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Adaptive Card
#
# PUT /team-messaging/v1/adaptive-cards/{cardId}
# operationId: updateGlipAdaptiveCardNew
# --body item shape: {type?: "Container", items?: list}
# --actions item shape: {type?: "Action.ShowCard"|"Action.Submit"|"Action.OpenUrl"|"Action.ToggleVisibility", title?: string, card?: record, url?: string}
# --selectAction shape: {type: "Action.Submit"|"Action.OpenUrl"|"Action.ToggleVisibility"}
export def "team-messaging-adaptive-cards updateGlipAdaptiveCardNew" [
  cardId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-19 # Type of attachment. This field is mandatory and filled on server side - will be ignored if set in request body
  version: string # Version. This field is mandatory and filled on server side - will be ignored if set in request body
  --body-body: list # List of adaptive cards with the detailed information — item shape: {type?: "Container", items?: list}
  --actions: list # item shape: {type?: "Action.ShowCard"|"Action.Submit"|"Action.OpenUrl"|"Action.ToggleVisibility", title?: string, card?: record, url?: string}
  --selectAction: record # An action that will be invoked when the card is tapped or selected. `Action.ShowCard` is not supported — shape: {type: "Action.Submit"|"Action.OpenUrl"|"Action.ToggleVisibility"}
  --fallbackText: string
  --backgroundImage: any # Specifies the background image of a card
  --minHeight: string # Specifies the minimum height of the card in pixels (e.g. 50px)
  --speak: string # Specifies what should be spoken for this entire card. This is simple text or SSML fragment
  --lang: string@lang-completer # The 2-letter ISO-639-1 language used in the card. Used to localize any date/time functions
  --verticalContentAlignment: any # Defines how the content should be aligned vertically within the container. Only relevant for fixed-height cards, or cards with a `minHeight` specified
]: any -> record<id: string, creationTime: string, lastModifiedTime: string, _schema: string, type: string, version: string, creator: record<id: string>, chatIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/adaptive-cards/($cardId)")
  let body = {type: $type, version: $version, body: $body_body, actions: $actions, selectAction: $selectAction, fallbackText: $fallbackText, backgroundImage: $backgroundImage, minHeight: $minHeight, speak: $speak, lang: $lang, verticalContentAlignment: $verticalContentAlignment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Adaptive Card
#
# DELETE /team-messaging/v1/adaptive-cards/{cardId}
# operationId: deleteGlipAdaptiveCardNew
export def "team-messaging-adaptive-cards delete" [
  cardId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/adaptive-cards/($cardId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Webhooks
#
# GET /team-messaging/v1/webhooks
# operationId: listGlipWebhooksNew
export def "team-messaging-webhooks listGlipWebhooksNew" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-6 # Response content type
]: nothing -> record<records: table<id: string, creatorId: string, groupIds: list, creationTime: string, lastModifiedTime: string, uri: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team-messaging/v1/webhooks")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Webhook
#
# GET /team-messaging/v1/webhooks/{webhookId}
# operationId: readGlipWebhookNew
export def "team-messaging-webhooks readGlipWebhookNew" [
  webhookId: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-6 # Response content type
]: nothing -> record<records: table<id: string, creatorId: string, groupIds: list, creationTime: string, lastModifiedTime: string, uri: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/webhooks/($webhookId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Webhook
#
# DELETE /team-messaging/v1/webhooks/{webhookId}
# operationId: deleteGlipWebhookNew
export def "team-messaging-webhooks delete" [
  webhookId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Activate Webhook
#
# POST /team-messaging/v1/webhooks/{webhookId}/activate
# operationId: activateGlipWebhookNew
export def "team-messaging-webhooks-activate activateGlipWebhookNew" [
  webhookId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/webhooks/($webhookId)/activate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suspend Webhook
#
# POST /team-messaging/v1/webhooks/{webhookId}/suspend
# operationId: suspendGlipWebhookNew
export def "team-messaging-webhooks-suspend suspendGlipWebhookNew" [
  webhookId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/webhooks/($webhookId)/suspend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Company Info
#
# GET /team-messaging/v1/companies/{companyId}
# operationId: readTMCompanyInfoNew
export def "team-messaging-companies readTMCompanyInfoNew" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-6 # Response content type
]: nothing -> record<id: string, name: string, domain: string, creationTime: string, lastModifiedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/companies/($companyId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Person
#
# GET /team-messaging/v1/persons/{personId}
# operationId: readGlipPersonNew
export def "team-messaging-persons readGlipPersonNew" [
  personId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, firstName: string, lastName: string, email: string, avatar: string, companyId: string, creationTime: string, lastModifiedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/persons/($personId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Conversations
#
# GET /team-messaging/v1/conversations
# operationId: listGlipConversationsNew
export def "team-messaging-conversations listGlipConversationsNew" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recordCount: int # Number of conversations to be fetched by one request. The maximum value is 250, by default - 30 (format: int32, default: 30)
  --pageToken: string # Pagination token.
]: nothing -> record<records: table<id: string, type: string, creationTime: string, lastModifiedTime: string, members: list>, navigation: record<prevPageToken: string, nextPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recordCount" $recordCount "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team-messaging/v1/conversations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create/Open Conversation
#
# POST /team-messaging/v1/conversations
# operationId: createGlipConversationNew
# --members item shape: {id?: string, email?: string}
export def "team-messaging-conversations createGlipConversationNew" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  members: list # Identifier(s) of chat member(s). The maximum supported number of IDs is 15. User's own ID is optional. If `members` section is omitted then "Personal" chat will be returned — item shape: {id?: string, email?: string}
]: any -> record<id: string, type: string, creationTime: string, lastModifiedTime: string, members: table<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team-messaging/v1/conversations")
  let body = {members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Conversation
#
# GET /team-messaging/v1/conversations/{chatId}
# operationId: readGlipConversationNew
export def "team-messaging-conversations readGlipConversationNew" [
  chatId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, creationTime: string, lastModifiedTime: string, members: table<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/conversations/($chatId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Group Events
#
# GET /team-messaging/v1/groups/{groupId}/events
# operationId: listGroupEventsNew
export def "team-messaging-groups-events listGroupEventsNew" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, creatorId: string, title: string, startTime: string, endTime: string, allDay: bool, recurrence: record<schedule: string, endingCondition: string, endingAfter: int, endingOn: string>, color: string, location: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/groups/($groupId)/events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Event by Group ID
#
# POST /team-messaging/v1/groups/{groupId}/events
# operationId: createEventByGroupIdNew
# --recurrence shape: {schedule?: "None"|"Day"|"Weekday"|"Week"|"Month"|"Year", endingCondition?: "None"|"Count"|"Date", endingAfter?: int, endingOn?: string}
export def "team-messaging-groups-events createEventByGroupIdNew" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Internal identifier of an event
  --creatorId: string # Internal identifier of a person created an event
  title: string # Event title
  startTime: string # Datetime of starting an event (format: date-time)
  endTime: string # Datetime of ending an event (format: date-time)
  --allDay: string@bool-completer # Indicates whether event has some specific time slot or lasts for whole day(s) (default: false)
  --recurrence: record # shape: {schedule?: "None"|"Day"|"Weekday"|"Week"|"Month"|"Year", endingCondition?: "None"|"Count"|"Date", endingAfter?: int, endingOn?: string}
  --color: string@color-completer # Color of Event title (including its presentation in Calendar) (default: Black)
  --location: string # Event location
  --description: string # Event details
]: any -> record<id: string, creatorId: string, title: string, startTime: string, endTime: string, allDay: bool, recurrence: record<schedule: string, endingCondition: string, endingAfter: int, endingOn: string>, color: string, location: string, description: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/groups/($groupId)/events")
  let body = {id: $id, creatorId: $creatorId, title: $title, startTime: $startTime, endTime: $endTime, allDay: $allDay, recurrence: $recurrence, color: $color, location: $location, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Webhooks in Group
#
# GET /team-messaging/v1/groups/{groupId}/webhooks
# operationId: listGlipGroupWebhooksNew
export def "team-messaging-groups-webhooks listGlipGroupWebhooksNew" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<records: table<id: string, creatorId: string, groupIds: list, creationTime: string, lastModifiedTime: string, uri: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/groups/($groupId)/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Webhook in Group
#
# POST /team-messaging/v1/groups/{groupId}/webhooks
# operationId: createGlipGroupWebhookNew
export def "team-messaging-groups-webhooks createGlipGroupWebhookNew" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, creatorId: string, groupIds: list<string>, creationTime: string, lastModifiedTime: string, uri: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/groups/($groupId)/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Data Export Tasks
#
# GET /team-messaging/v1/data-export
# operationId: listDataExportTasksNew
export def "team-messaging-data-export listDataExportTasksNew" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-9 # Status of the task(s) to be returned. Multiple values are supported
  --page: int # Page number to be retrieved; value range is > 0 (format: int32, default: 1)
  --perPage: int # Number of records to be returned per page; value range is 1 - 250 (format: int32, default: 30)
]: nothing -> record<tasks: table<uri: string, id: string, creationTime: string, lastModifiedTime: string, status: string, creator: record, specific: record, datasets: list>, navigation: record<firstPage: record<uri: string>, nextPage: record<uri: string>, previousPage: record<uri: string>, lastPage: record<uri: string>>, paging: record<page: int, perPage: int, pageStart: int, pageEnd: int, totalPages: int, totalElements: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "perPage" $perPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team-messaging/v1/data-export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Data Export Task
#
# POST /team-messaging/v1/data-export
# operationId: createDataExportTaskNew
# --contacts item shape: {id?: string, email?: string}
export def "team-messaging-data-export createDataExportTaskNew" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timeFrom: string # Starting time for data collection. The default value is `timeTo` minus 24 hours. Max allowed time frame between `timeFrom` and `timeTo` is 6 months (format: date-time)
  --timeTo: string # Ending time for data collection. The default value is current time. Max allowed time frame between `timeFrom` and `timeTo` is 6 months (format: date-time)
  --contacts: list # List of contacts which data is collected. The following data will be exported: posts, tasks, events, etc. posted by the user(s); posts addressing the user(s) via direct and @Mentions; tasks assigned to the listed user(s). The list of 30 users per request is supported. — item shape: {id?: string, email?: string}
  --chatIds: list # List of chats from which the data (posts, files, tasks, events, notes, etc.) will be collected. Maximum number of chats supported is 10
]: any -> record<uri: string, id: string, creationTime: string, lastModifiedTime: string, status: string, creator: record<id: string, firstName: string, lastName: string>, specific: record<timeFrom: string, timeTo: string, contacts: list<record>, chatIds: list<string>>, datasets: table<id: string, uri: string, size: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team-messaging/v1/data-export")
  let body = {timeFrom: $timeFrom, timeTo: $timeTo, contacts: $contacts, chatIds: $chatIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Data Export Task
#
# GET /team-messaging/v1/data-export/{taskId}
# operationId: readDataExportTaskNew
export def "team-messaging-data-export readDataExportTaskNew" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uri: string, id: string, creationTime: string, lastModifiedTime: string, status: string, creator: record<id: string, firstName: string, lastName: string>, specific: record<timeFrom: string, timeTo: string, contacts: list<record>, chatIds: list<string>>, datasets: table<id: string, uri: string, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/data-export/($taskId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Everyone Chat
#
# GET /team-messaging/v1/everyone
# operationId: readGlipEveryoneNew
export def "team-messaging-everyone readGlipEveryoneNew" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, name: string, description: string, creationTime: string, lastModifiedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team-messaging/v1/everyone")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Everyone Chat
#
# PATCH /team-messaging/v1/everyone
# operationId: patchGlipEveryoneNew
export def "team-messaging-everyone patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Everyone chat name. Maximum number of characters supported is 250
  --description: string # Everyone chat description. Maximum number of characters supported is 1000
]: any -> record<id: string, type: string, name: string, description: string, creationTime: string, lastModifiedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team-messaging/v1/everyone")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Teams
#
# GET /team-messaging/v1/teams
# operationId: listGlipTeamsNew
export def "team-messaging-teams listGlipTeamsNew" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recordCount: int # Number of teams to be fetched by one request. The maximum value is 250, by default - 30 (format: int32, default: 30)
  --pageToken: string # Pagination token.
]: nothing -> record<records: table<id: string, type: string, public: bool, name: string, description: string, status: string, creationTime: string, lastModifiedTime: string>, navigation: record<prevPageToken: string, nextPageToken: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recordCount" $recordCount "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team-messaging/v1/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Team
#
# POST /team-messaging/v1/teams
# operationId: createGlipTeamNew
# --members item shape: {id?: string, email?: string}
export def "team-messaging-teams createGlipTeamNew" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --public: string@bool-completer # Team access level.
  name: string # Team name.
  --description: string # Team description.
  --members: list # Identifier(s) of team members. — item shape: {id?: string, email?: string}
]: any -> record<id: string, type: string, public: bool, name: string, description: string, status: string, creationTime: string, lastModifiedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team-messaging/v1/teams")
  let body = {public: $public, name: $name, description: $description, members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Team
#
# GET /team-messaging/v1/teams/{chatId}
# operationId: readGlipTeamNew
export def "team-messaging-teams readGlipTeamNew" [
  chatId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, type: string, public: bool, name: string, description: string, status: string, creationTime: string, lastModifiedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/teams/($chatId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Team
#
# DELETE /team-messaging/v1/teams/{chatId}
# operationId: deleteGlipTeamNew
export def "team-messaging-teams delete" [
  chatId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/teams/($chatId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Team
#
# PATCH /team-messaging/v1/teams/{chatId}
# operationId: patchGlipTeamNew
export def "team-messaging-teams patch" [
  chatId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --public: string@bool-completer # Team access level
  --name: string # Team name. Maximum number of characters supported is 250
  --description: string # Team description. Maximum number of characters supported is 1000
]: any -> record<id: string, type: string, public: bool, name: string, description: string, status: string, creationTime: string, lastModifiedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/teams/($chatId)")
  let body = {public: $public, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Team Members
#
# POST /team-messaging/v1/teams/{chatId}/remove
# operationId: removeGlipTeamMembersNew
# --members item shape: {id?: string}
export def "team-messaging-teams-remove removeGlipTeamMembersNew" [
  chatId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  members: list # Identifier(s) of chat members. — item shape: {id?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/teams/($chatId)/remove")
  let body = {members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Join Team
#
# POST /team-messaging/v1/teams/{chatId}/join
# operationId: joinGlipTeamNew
export def "team-messaging-teams-join joinGlipTeamNew" [
  chatId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/teams/($chatId)/join")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive Team
#
# POST /team-messaging/v1/teams/{chatId}/archive
# operationId: archiveGlipTeamNew
export def "team-messaging-teams-archive archiveGlipTeamNew" [
  chatId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/teams/($chatId)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unarchive Team
#
# POST /team-messaging/v1/teams/{chatId}/unarchive
# operationId: unarchiveGlipTeamNew
export def "team-messaging-teams-unarchive unarchiveGlipTeamNew" [
  chatId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/teams/($chatId)/unarchive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Leave Team
#
# POST /team-messaging/v1/teams/{chatId}/leave
# operationId: leaveGlipTeamNew
export def "team-messaging-teams-leave leaveGlipTeamNew" [
  chatId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/teams/($chatId)/leave")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Team Members
#
# POST /team-messaging/v1/teams/{chatId}/add
# operationId: addGlipTeamMembersNew
# --members item shape: {id?: string, email?: string}
export def "team-messaging-teams-add addGlipTeamMembersNew" [
  chatId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  members: list # Identifier(s) of chat member(s) — item shape: {id?: string, email?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/teams/($chatId)/add")
  let body = {members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Note
#
# GET /team-messaging/v1/notes/{noteId}
# operationId: readUserNoteNew
export def "team-messaging-notes readUserNoteNew" [
  noteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, title: string, chatIds: list<string>, preview: string, creator: record<id: string>, lastModifiedBy: record<id: string>, lockedBy: record<id: string>, status: string, creationTime: string, lastModifiedTime: string, type: string, body: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/notes/($noteId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Note
#
# DELETE /team-messaging/v1/notes/{noteId}
# operationId: deleteNoteNew
export def "team-messaging-notes delete" [
  noteId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/notes/($noteId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Note
#
# PATCH /team-messaging/v1/notes/{noteId}
# operationId: patchNoteNew
export def "team-messaging-notes patch" [
  noteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --releaseLock: string@bool-completer # If true then note lock (if any) will be released upon request (default: false)
  title: string # Title of a note. Max allowed length is 250 characters
  --body-body: string # Contents of a note; HTML markup text. Max allowed length is 1048576 characters (1 Mb).
]: any -> record<id: string, title: string, chatIds: list<string>, preview: string, creator: record<id: string>, lastModifiedBy: record<id: string>, lockedBy: record<id: string>, status: string, creationTime: string, lastModifiedTime: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "releaseLock" $releaseLock "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/team-messaging/v1/notes/($noteId)" $qp)
  let body = {title: $title, body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lock Note
#
# POST /team-messaging/v1/notes/{noteId}/lock
# operationId: lockNoteNew
export def "team-messaging-notes-lock lockNoteNew" [
  noteId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/notes/($noteId)/lock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Publish Note
#
# POST /team-messaging/v1/notes/{noteId}/publish
# operationId: publishNoteNew
export def "team-messaging-notes-publish publishNoteNew" [
  noteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, title: string, chatIds: list<string>, preview: string, creator: record<id: string>, lastModifiedBy: record<id: string>, lockedBy: record<id: string>, status: string, creationTime: string, lastModifiedTime: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/team-messaging/v1/notes/($noteId)/publish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unlock Note
#
# POST /team-messaging/v1/notes/{noteId}/unlock
# operationId: unlockNoteNew
export def "team-messaging-notes-unlock unlockNoteNew" [
  noteId: string
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
  let full_url = (build-url $base $"/team-messaging/v1/notes/($noteId)/unlock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Favorite Chats
#
# GET /team-messaging/v1/favorites
# operationId: listFavoriteChatsNew
export def "team-messaging-favorites listFavoriteChatsNew" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recordCount: int # Max number of chats to be fetched by one request (Not more than 250). (format: int32, default: 30)
]: nothing -> record<records: table<id: string, type: string, public: bool, name: string, description: string, status: string, creationTime: string, lastModifiedTime: string, members: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recordCount" $recordCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team-messaging/v1/favorites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
