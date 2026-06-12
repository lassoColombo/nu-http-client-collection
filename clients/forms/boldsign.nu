# Auto-generated client for BoldSign API v1
# Source: https://api.boldsign.com/swagger/v1/swagger.json
# Auth: --token flag or $env.BOLDSIGN_API_TOKEN

const BASE_URL = "https://api.boldsign.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BOLDSIGN_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "x-api-key" => { {headers: {X-API-KEY: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.boldsign.com"] }
def auth-scheme-completer [] { ["bearer" "x-api-key"] }

# Completers for enum parameters
def EmailSignedDocument-completer [] { ["Attachment" "DocumentLink"] }
def DocumentExpirySettingsExpiryDateType-completer [] { ["Days" "Hours" "SpecificDateTime"] }
def accept-completer [] { ["application/json" "application/json;IEEE754Compatible=false" "application/json;IEEE754Compatible=true" "application/json;odata.metadata=full" "application/json;odata.metadata=full;IEEE754Compatible=false" "application/json;odata.metadata=full;IEEE754Compatible=true" "application/json;odata.metadata=full;odata.streaming=false" "application/json;odata.metadata=full;odata.streaming=false;IEEE754Compatible=false" "application/json;odata.metadata=full;odata.streaming=false;IEEE754Compatible=true" "application/json;odata.metadata=full;odata.streaming=true" "application/json;odata.metadata=full;odata.streaming=true;IEEE754Compatible=false" "application/json;odata.metadata=full;odata.streaming=true;IEEE754Compatible=true" "application/json;odata.metadata=minimal" "application/json;odata.metadata=minimal;IEEE754Compatible=false" "application/json;odata.metadata=minimal;IEEE754Compatible=true" "application/json;odata.metadata=minimal;odata.streaming=false" "application/json;odata.metadata=minimal;odata.streaming=false;IEEE754Compatible=false" "application/json;odata.metadata=minimal;odata.streaming=false;IEEE754Compatible=true" "application/json;odata.metadata=minimal;odata.streaming=true" "application/json;odata.metadata=minimal;odata.streaming=true;IEEE754Compatible=false" "application/json;odata.metadata=minimal;odata.streaming=true;IEEE754Compatible=true" "application/json;odata.metadata=none" "application/json;odata.metadata=none;IEEE754Compatible=false" "application/json;odata.metadata=none;IEEE754Compatible=true" "application/json;odata.metadata=none;odata.streaming=false" "application/json;odata.metadata=none;odata.streaming=false;IEEE754Compatible=false" "application/json;odata.metadata=none;odata.streaming=false;IEEE754Compatible=true" "application/json;odata.metadata=none;odata.streaming=true" "application/json;odata.metadata=none;odata.streaming=true;IEEE754Compatible=false" "application/json;odata.metadata=none;odata.streaming=true;IEEE754Compatible=true" "application/json;odata.streaming=false" "application/json;odata.streaming=false;IEEE754Compatible=false" "application/json;odata.streaming=false;IEEE754Compatible=true" "application/json;odata.streaming=true" "application/json;odata.streaming=true;IEEE754Compatible=false" "application/json;odata.streaming=true;IEEE754Compatible=true" "application/octet-stream" "application/xml" "text/json" "text/plain"] }
def ContactType-completer [] { ["AllContacts" "MyContacts"] }
def expiryDateType-completer [] { ["Days" "Hours" "SpecificDateTime"] }
def documentDownloadOption-completer [] { ["Combined" "Individually"] }
def sendViewOption-completer [] { ["FillingPage" "PreparePage"] }
def locale-completer [] { ["BG" "CS" "DA" "DE" "Default" "EN" "ES" "FR" "IT" "JA" "KO" "NL" "NO" "PL" "PT" "RO" "RU" "SV" "TH" "ZH_CN" "ZH_TW"] }
def TransmitType-completer [] { ["Both" "Received" "Sent"] }
def DateFilterType-completer [] { ["Expiring" "SentBetween"] }
def PageType-completer [] { ["BehalfOfMe" "BehalfOfOthers"] }
def authenticationType-completer [] { ["AccessCode" "EmailOTP" "IdVerification" "None" "SMSOTP"] }
def TemplateType-completer [] { ["all" "mytemplates" "sharedtemplate"] }
def viewOption-completer [] { ["FillingPage" "PreparePage"] }
def userRole-completer [] { ["Admin" "Member" "TeamAdmin"] }
def userStatus-completer [] { ["Activate" "Deactivate"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "brand-create CreateBrand" } } | get name | first)
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

# Create the brand.
#
# POST /v1/brand/create
# operationId: CreateBrand
export def "brand-create CreateBrand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  BrandName: string
  BrandLogo: string # format: binary
  --BackgroundColor: string
  --ButtonColor: string
  --ButtonTextColor: string
  --EmailDisplayName: string
  --DisclaimerDescription: string
  --DisclaimerTitle: string
  --RedirectUrl: string
  --IsDefault: oneof<nothing, bool> # default: false
  --CanHideTagLine: oneof<nothing, bool> # default: false
  --CombineAuditTrail: oneof<nothing, bool> # default: false
  --CombineAttachments: oneof<nothing, bool> # default: false
  --ExcludeAuditTrailFromEmail: oneof<nothing, bool> # default: false
  --EmailSignedDocument: string@EmailSignedDocument-completer # default: Attachment
  --DocumentTimeZone: string
  --ShowBuiltInFormFields: oneof<nothing, bool> # default: true
  --AllowCustomFieldCreation: oneof<nothing, bool> # default: false
  --ShowSharedCustomFields: oneof<nothing, bool> # default: false
  --HideDecline: oneof<nothing, bool> # This option prevents signers to decline the document during the signing process.
  --HideSave: oneof<nothing, bool> # This option prevents signers to save their changes during the signing process and continue signing later.
  --DocumentExpirySettingsExpiryDateType: string@DocumentExpirySettingsExpiryDateType-completer # This property represents the type for the expiry date (format: Enumeration)
  --DocumentExpirySettingsExpiryValue: int # This property is used to set the expiry value based on the expiry type (format: int32)
  --DocumentExpirySettingsEnableDefaultExpiryAlert: oneof<nothing, bool> # This property will send the expiry alert email before the day of expiry for the pending signers.
  --DocumentExpirySettingsEnableAutoReminder: oneof<nothing, bool> # When auto reminder is enabled, you can select how often to remind in terms of days and select the maximum number of reminders.
  --DocumentExpirySettingsReminderDays: int # Remind in terms of days. (format: int32)
  --DocumentExpirySettingsReminderCount: int # Number of reminder count. (format: int32)
  --CustomDomainSettingsDomainName: string
  --CustomDomainSettingsFromName: string
  --SignatureFrameSettingsEnableSignatureFrame: oneof<nothing, bool> # default: false
  --SignatureFrameSettingsShowRecipientName: oneof<nothing, bool> # default: false
  --SignatureFrameSettingsShowRecipientEmail: oneof<nothing, bool> # default: false
  --SignatureFrameSettingsShowTimeStamp: oneof<nothing, bool> # default: false
]: any -> record<brandId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/brand/create")
  let body = {BrandName: $BrandName, BrandLogo: $BrandLogo, BackgroundColor: $BackgroundColor, ButtonColor: $ButtonColor, ButtonTextColor: $ButtonTextColor, EmailDisplayName: $EmailDisplayName, DisclaimerDescription: $DisclaimerDescription, DisclaimerTitle: $DisclaimerTitle, RedirectUrl: $RedirectUrl, IsDefault: $IsDefault, CanHideTagLine: $CanHideTagLine, CombineAuditTrail: $CombineAuditTrail, CombineAttachments: $CombineAttachments, ExcludeAuditTrailFromEmail: $ExcludeAuditTrailFromEmail, EmailSignedDocument: $EmailSignedDocument, DocumentTimeZone: $DocumentTimeZone, ShowBuiltInFormFields: $ShowBuiltInFormFields, AllowCustomFieldCreation: $AllowCustomFieldCreation, ShowSharedCustomFields: $ShowSharedCustomFields, HideDecline: $HideDecline, HideSave: $HideSave, DocumentExpirySettings.ExpiryDateType: $DocumentExpirySettingsExpiryDateType, DocumentExpirySettings.ExpiryValue: $DocumentExpirySettingsExpiryValue, DocumentExpirySettings.EnableDefaultExpiryAlert: $DocumentExpirySettingsEnableDefaultExpiryAlert, DocumentExpirySettings.EnableAutoReminder: $DocumentExpirySettingsEnableAutoReminder, DocumentExpirySettings.ReminderDays: $DocumentExpirySettingsReminderDays, DocumentExpirySettings.ReminderCount: $DocumentExpirySettingsReminderCount, CustomDomainSettings.DomainName: $CustomDomainSettingsDomainName, CustomDomainSettings.FromName: $CustomDomainSettingsFromName, SignatureFrameSettings.EnableSignatureFrame: $SignatureFrameSettingsEnableSignatureFrame, SignatureFrameSettings.ShowRecipientName: $SignatureFrameSettingsShowRecipientName, SignatureFrameSettings.ShowRecipientEmail: $SignatureFrameSettingsShowRecipientEmail, SignatureFrameSettings.ShowTimeStamp: $SignatureFrameSettingsShowTimeStamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json;odata.metadata=minimal;odata.streaming=true")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Edit the brand.
#
# POST /v1/brand/edit
# operationId: EditBrand
export def "brand-edit EditBrand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --brandId: string
  --BrandName: string
  --BrandLogo: string # format: binary
  --BackgroundColor: string
  --ButtonColor: string
  --ButtonTextColor: string
  --EmailDisplayName: string
  --DisclaimerDescription: string
  --DisclaimerTitle: string
  --RedirectUrl: string
  --IsDefault: oneof<nothing, bool> # default: false
  --CanHideTagLine: oneof<nothing, bool> # default: false
  --CombineAuditTrail: oneof<nothing, bool> # default: false
  --CombineAttachments: oneof<nothing, bool> # default: false
  --ExcludeAuditTrailFromEmail: oneof<nothing, bool> # default: false
  --EmailSignedDocument: string@EmailSignedDocument-completer # default: Attachment
  --DocumentTimeZone: string
  --ShowBuiltInFormFields: oneof<nothing, bool> # default: true
  --AllowCustomFieldCreation: oneof<nothing, bool> # default: false
  --ShowSharedCustomFields: oneof<nothing, bool> # default: false
  --HideDecline: oneof<nothing, bool> # This option prevents signers to decline the document during the signing process.
  --HideSave: oneof<nothing, bool> # This option prevents signers to save their changes during the signing process and continue signing later.
  --DocumentExpirySettingsExpiryDateType: string@DocumentExpirySettingsExpiryDateType-completer # This property represents the type for the expiry date (format: Enumeration)
  --DocumentExpirySettingsExpiryValue: int # This property is used to set the expiry value based on the expiry type (format: int32)
  --DocumentExpirySettingsEnableDefaultExpiryAlert: oneof<nothing, bool> # This property will send the expiry alert email before the day of expiry for the pending signers.
  --DocumentExpirySettingsEnableAutoReminder: oneof<nothing, bool> # When auto reminder is enabled, you can select how often to remind in terms of days and select the maximum number of reminders.
  --DocumentExpirySettingsReminderDays: int # Remind in terms of days. (format: int32)
  --DocumentExpirySettingsReminderCount: int # Number of reminder count. (format: int32)
  --CustomDomainSettingsDomainName: string
  --CustomDomainSettingsFromName: string
  --SignatureFrameSettingsEnableSignatureFrame: oneof<nothing, bool> # default: false
  --SignatureFrameSettingsShowRecipientName: oneof<nothing, bool> # default: false
  --SignatureFrameSettingsShowRecipientEmail: oneof<nothing, bool> # default: false
  --SignatureFrameSettingsShowTimeStamp: oneof<nothing, bool> # default: false
]: any -> record<brandId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "brandId" $brandId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/brand/edit" $qp)
  let body = {BrandName: $BrandName, BrandLogo: $BrandLogo, BackgroundColor: $BackgroundColor, ButtonColor: $ButtonColor, ButtonTextColor: $ButtonTextColor, EmailDisplayName: $EmailDisplayName, DisclaimerDescription: $DisclaimerDescription, DisclaimerTitle: $DisclaimerTitle, RedirectUrl: $RedirectUrl, IsDefault: $IsDefault, CanHideTagLine: $CanHideTagLine, CombineAuditTrail: $CombineAuditTrail, CombineAttachments: $CombineAttachments, ExcludeAuditTrailFromEmail: $ExcludeAuditTrailFromEmail, EmailSignedDocument: $EmailSignedDocument, DocumentTimeZone: $DocumentTimeZone, ShowBuiltInFormFields: $ShowBuiltInFormFields, AllowCustomFieldCreation: $AllowCustomFieldCreation, ShowSharedCustomFields: $ShowSharedCustomFields, HideDecline: $HideDecline, HideSave: $HideSave, DocumentExpirySettings.ExpiryDateType: $DocumentExpirySettingsExpiryDateType, DocumentExpirySettings.ExpiryValue: $DocumentExpirySettingsExpiryValue, DocumentExpirySettings.EnableDefaultExpiryAlert: $DocumentExpirySettingsEnableDefaultExpiryAlert, DocumentExpirySettings.EnableAutoReminder: $DocumentExpirySettingsEnableAutoReminder, DocumentExpirySettings.ReminderDays: $DocumentExpirySettingsReminderDays, DocumentExpirySettings.ReminderCount: $DocumentExpirySettingsReminderCount, CustomDomainSettings.DomainName: $CustomDomainSettingsDomainName, CustomDomainSettings.FromName: $CustomDomainSettingsFromName, SignatureFrameSettings.EnableSignatureFrame: $SignatureFrameSettingsEnableSignatureFrame, SignatureFrameSettings.ShowRecipientName: $SignatureFrameSettingsShowRecipientName, SignatureFrameSettings.ShowRecipientEmail: $SignatureFrameSettingsShowRecipientEmail, SignatureFrameSettings.ShowTimeStamp: $SignatureFrameSettingsShowTimeStamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json;odata.metadata=minimal;odata.streaming=true")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get the specific brand details.
#
# GET /v1/brand/get
# operationId: GetBrand
export def "brand-get GetBrand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --brandId: string
]: nothing -> record<brandId: string, brandLogo: string, brandName: string, backgroundColor: string, buttonColor: string, buttonTextColor: string, emailDisplayName: string, disclaimerTitle: string, disclaimerDescription: string, redirectUrl: string, isDefault: bool, canHideTagLine: bool, combineAuditTrail: bool, combineAttachments: bool, excludeAuditTrailFromEmail: bool, emailSignedDocument: string, documentTimeZone: string, showBuiltInFormFields: bool, allowCustomFieldCreation: bool, showSharedCustomFields: bool, hideDecline: bool, hideSave: bool, documentExpirySettings: record<expiryDateType: string, expiryValue: int, enableDefaultExpiryAlert: bool, enableAutoReminder: bool, reminderDays: int, reminderCount: int>, customDomainSettings: record<domainName: string, fromName: string>, isDomainVerified: bool, signatureFrameSettings: record<enableSignatureFrame: bool, showRecipientName: bool, showRecipientEmail: bool, showTimeStamp: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "brandId" $brandId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/brand/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the brand.
#
# DELETE /v1/brand/delete
# operationId: DeleteBrand
export def "brand-delete DeleteBrand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --brandId: string
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "brandId" $brandId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/brand/delete" $qp)
  let accept_val = ($accept | default "application/json;odata.metadata=minimal;odata.streaming=true")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset default brand.
#
# POST /v1/brand/resetdefault
# operationId: ResetDefaultBrand
export def "brand-resetdefault ResetDefaultBrand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --brandId: string
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "brandId" $brandId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/brand/resetdefault" $qp)
  let accept_val = ($accept | default "application/json;odata.metadata=minimal;odata.streaming=true")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the brands.
#
# GET /v1/brand/list
# operationId: BrandList
export def "brand-list BrandList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: table<brandId: string, brandLogo: string, brandName: string, backgroundColor: string, buttonColor: string, buttonTextColor: string, emailDisplayName: string, disclaimerTitle: string, disclaimerDescription: string, redirectUrl: string, isDefault: bool, canHideTagLine: bool, combineAuditTrail: bool, combineAttachments: bool, excludeAuditTrailFromEmail: bool, emailSignedDocument: string, documentTimeZone: string, showBuiltInFormFields: bool, allowCustomFieldCreation: bool, showSharedCustomFields: bool, hideDecline: bool, hideSave: bool, documentExpirySettings: record, customDomainSettings: record, isDomainVerified: bool, signatureFrameSettings: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/brand/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Contact document.
#
# GET /v1/contacts/list
# operationId: ContactUserList
export def "contacts-list ContactUserList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # Page size specified in get user contact list request. Default value is 10. (format: int32, default: 10)
  --Page: int # Page index specified in get user contact list request. Default value is 1. (format: int32, default: 1)
  --SearchKey: string # Contacts can be listed by the search  based on the Name or Email
  --ContactType: string@ContactType-completer # Contact type whether the contact is My Contacts or All Contacts. Default value is AllContacts.
]: nothing -> record<pageDetails: record<pageSize: int, page: int, totalRecordsCount: int>, result: table<id: string, name: string, email: string, companyName: string, jobTitle: string, phoneNumber: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "SearchKey" $SearchKey "scalar") (serialize-qp "ContactType" $ContactType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contacts/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a contact.
#
# DELETE /v1/contacts/delete
# operationId: DeleteContacts
export def "contacts-delete DeleteContacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contacts/delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the new Contact.
#
# POST /v1/contacts/create
# operationId: CreateContact
export def "contacts-create CreateContact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<createdContacts: table<id: string, email: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contacts/create")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the contact.
#
# PUT /v1/contacts/update
# operationId: UpdateContact
# --phoneNumber shape: {countryCode?: string, number?: string}
export def "contacts-update UpdateContact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  email: string
  name: string
  --phoneNumber: record # shape: {countryCode?: string, number?: string}
  --jobTitle: string # nullable
  --companyName: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contacts/update" $qp)
  let body = {email: $email, name: $name, phoneNumber: $phoneNumber, jobTitle: $jobTitle, companyName: $companyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get summary of the contact.
#
# GET /v1/contacts/get
# operationId: GetContact
export def "contacts-get GetContact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
]: nothing -> record<id: string, name: string, email: string, companyName: string, jobTitle: string, phoneNumber: record<countryCode: string, number: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contacts/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create the custom field.
#
# POST /v1/customField/create
# operationId: CreateCustomField
# --formField shape: {fieldType: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", width?: float, height?: float, isRequired?: bool, isReadOnly?: bool, value?: string, fontSize?: float, font?: "Helvetica"|"Courier"|"TimesRoman"|"NotoSans"|"Carlito", fontHexColor?: string, isBoldFont?: bool, isItalicFont?: bool, isUnderLineFont?: bool, lineHeight?: int, characterLimit?: int, placeHolder?: string, validationType?: "None"|"NumbersOnly"|"EmailAddress"|"Currency"|"CustomRegex", validationCustomRegex?: string, validationCustomRegexMessage?: string, dateFormat?: string, timeFormat?: string, imageInfo?: record, attachmentInfo?: record, editableDateFieldSettings?: record, hyperlinkText?: string, dataSyncTag?: string, dropdownOptions?: list, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, idPrefix?: string, restrictIdPrefixChange?: bool, backgroundHexColor?: string, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", isMasked?: bool}
export def "custom-field-create CreateCustomField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fieldName: string # nullable
  --fieldDescription: string # nullable
  --fieldOrder: int # format: int32, default: 1
  --brandId: string # nullable
  --sharedField: oneof<nothing, bool>
  --formField: record # shape: {fieldType: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", width?: float, height?: float, isRequired?: bool, isReadOnly?: bool, value?: string, fontSize?: float, font?: "Helvetica"|"Courier"|"TimesRoman"|"NotoSans"|"Carlito", fontHexColor?: string, isBoldFont?: bool, isItalicFont?: bool, isUnderLineFont?: bool, lineHeight?: int, characterLimit?: int, placeHolder?: string, validationType?: "None"|"NumbersOnly"|"EmailAddress"|"Currency"|"CustomRegex", validationCustomRegex?: string, validationCustomRegexMessage?: string, dateFormat?: string, timeFormat?: string, imageInfo?: record, attachmentInfo?: record, editableDateFieldSettings?: record, hyperlinkText?: string, dataSyncTag?: string, dropdownOptions?: list, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, idPrefix?: string, restrictIdPrefixChange?: bool, backgroundHexColor?: string, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", isMasked?: bool}
]: any -> record<customFieldId: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customField/create")
  let body = {fieldName: $fieldName, fieldDescription: $fieldDescription, fieldOrder: $fieldOrder, brandId: $brandId, sharedField: $sharedField, formField: $formField} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json;odata.metadata=minimal;odata.streaming=true")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Edit the custom field.
#
# POST /v1/customField/edit
# operationId: EditCustomField
# --formField shape: {fieldType: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", width?: float, height?: float, isRequired?: bool, isReadOnly?: bool, value?: string, fontSize?: float, font?: "Helvetica"|"Courier"|"TimesRoman"|"NotoSans"|"Carlito", fontHexColor?: string, isBoldFont?: bool, isItalicFont?: bool, isUnderLineFont?: bool, lineHeight?: int, characterLimit?: int, placeHolder?: string, validationType?: "None"|"NumbersOnly"|"EmailAddress"|"Currency"|"CustomRegex", validationCustomRegex?: string, validationCustomRegexMessage?: string, dateFormat?: string, timeFormat?: string, imageInfo?: record, attachmentInfo?: record, editableDateFieldSettings?: record, hyperlinkText?: string, dataSyncTag?: string, dropdownOptions?: list, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, idPrefix?: string, restrictIdPrefixChange?: bool, backgroundHexColor?: string, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", isMasked?: bool}
export def "custom-field-edit EditCustomField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --customFieldId: string
  --fieldName: string # nullable
  --fieldDescription: string # nullable
  --fieldOrder: int # format: int32, default: 1
  --brandId: string # nullable
  --sharedField: oneof<nothing, bool>
  --formField: record # shape: {fieldType: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", width?: float, height?: float, isRequired?: bool, isReadOnly?: bool, value?: string, fontSize?: float, font?: "Helvetica"|"Courier"|"TimesRoman"|"NotoSans"|"Carlito", fontHexColor?: string, isBoldFont?: bool, isItalicFont?: bool, isUnderLineFont?: bool, lineHeight?: int, characterLimit?: int, placeHolder?: string, validationType?: "None"|"NumbersOnly"|"EmailAddress"|"Currency"|"CustomRegex", validationCustomRegex?: string, validationCustomRegexMessage?: string, dateFormat?: string, timeFormat?: string, imageInfo?: record, attachmentInfo?: record, editableDateFieldSettings?: record, hyperlinkText?: string, dataSyncTag?: string, dropdownOptions?: list, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, idPrefix?: string, restrictIdPrefixChange?: bool, backgroundHexColor?: string, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", isMasked?: bool}
]: any -> record<customFieldId: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customFieldId" $customFieldId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/customField/edit" $qp)
  let body = {fieldName: $fieldName, fieldDescription: $fieldDescription, fieldOrder: $fieldOrder, brandId: $brandId, sharedField: $sharedField, formField: $formField} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json;odata.metadata=minimal;odata.streaming=true")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the custom field.
#
# DELETE /v1/customField/delete
# operationId: DeleteCustomField
export def "custom-field-delete DeleteCustomField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --customFieldId: string
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customFieldId" $customFieldId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/customField/delete" $qp)
  let accept_val = ($accept | default "application/json;odata.metadata=minimal;odata.streaming=true")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the custom fields respective to the brand id.
#
# GET /v1/customField/list
# operationId: CustomFieldsList
export def "custom-field-list CustomFieldsList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --brandId: string
]: nothing -> record<result: table<customFieldId: string, fieldName: string, fieldDescription: string, fieldOrder: int, brandId: string, sharedField: bool, formField: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "brandId" $brandId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/customField/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates a URL for creating or modifying custom fields within your application's embedded Designer.
#
# POST /v1/customField/createEmbeddedCustomFieldUrl
# operationId: EmbedCustomField
export def "custom-field-create-embedded-custom-field-url EmbedCustomField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --BrandId: string # The Brand ID for custom fields must be configured
  --LinkValidTill: string # This property is used to set the validity of the generated URL. Its maximum validity is 30 days (format: date-time)
]: nothing -> record<createUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "BrandId" $BrandId "scalar") (serialize-qp "LinkValidTill" $LinkValidTill "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/customField/createEmbeddedCustomFieldUrl" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends the document for sign.
#
# POST /v1/document/send
# operationId: SendDocument
# --signers item shape: {id?: string, name?: string, emailAddress?: string, privateMessage?: string, authenticationType?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", authenticationCode?: string, identityVerificationSettings?: record, signerOrder?: int, enableEmailOTP?: bool, signerType?: "Signer"|"Reviewer"|"InPersonSigner", hostEmail?: string, signerRole?: string, allowFieldConfiguration?: bool, formFields?: list, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", groupId?: string, recipientNotificationSettings?: record, authenticationRetryCount?: int, enableQes?: bool, authenticationSettings?: record}
# --cc item shape: {emailAddress: string}
# --reminderSettings shape: {enableAutoReminder?: bool, reminderDays?: int, reminderCount?: int}
# --textTagDefinitions item shape: {definitionId: string, type: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", signerIndex: int, isRequired?: bool, placeholder?: string, fieldId?: string, font?: record, validation?: record, size?: record, dateFormat?: string, timeFormat?: string, radioGroupName?: string, groupName?: string, value?: string, dropdownOptions?: list, imageInfo?: record, hyperlinkText?: string, attachmentInfo?: record, backgroundHexColor?: string, isReadOnly?: bool, offset?: record, label?: string, tabIndex?: int, dataSyncTag?: string, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, characterLimit?: int, formulaFieldSettings?: record, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", collaborationSettings?: record, isMasked?: bool, conditionalRules?: list}
# --documentInfo item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
# --formGroups item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
# --recipientNotificationSettings shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
# --groupSignerSettings shape: {enabled?: bool, allowedDirectories?: list}
@deprecated --flag expiryDays
@deprecated --flag enableEmbeddedSigning
export def "document-send SendDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list # nullable
  --title: string # nullable
  --message: string # nullable
  --signers: list # nullable — item shape: {id?: string, name?: string, emailAddress?: string, privateMessage?: string, authenticationType?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", authenticationCode?: string, identityVerificationSettings?: record, signerOrder?: int, enableEmailOTP?: bool, signerType?: "Signer"|"Reviewer"|"InPersonSigner", hostEmail?: string, signerRole?: string, allowFieldConfiguration?: bool, formFields?: list, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", groupId?: string, recipientNotificationSettings?: record, authenticationRetryCount?: int, enableQes?: bool, authenticationSettings?: record}
  --cc: list # nullable — item shape: {emailAddress: string}
  --enableSigningOrder: oneof<nothing, bool> # default: false
  --expiryDays: int # DEPRECATED, format: int32
  --expiryDateType: string@expiryDateType-completer # nullable
  --expiryValue: int # format: int64, default: 60
  --reminderSettings: record # shape: {enableAutoReminder?: bool, reminderDays?: int, reminderCount?: int}
  --enableEmbeddedSigning: oneof<nothing, bool> # DEPRECATED, default: false
  --disableEmails: oneof<nothing, bool> # default: false
  --disableSMS: oneof<nothing, bool> # default: false
  --brandId: string # nullable
  --hideDocumentId: oneof<nothing, bool> # nullable, default: false
  --labels: list # nullable
  --fileUrls: list # nullable
  --sendLinkValidTill: string # nullable, format: date-time
  --useTextTags: oneof<nothing, bool> # default: false
  --textTagDefinitions: list # nullable — item shape: {definitionId: string, type: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", signerIndex: int, isRequired?: bool, placeholder?: string, fieldId?: string, font?: record, validation?: record, size?: record, dateFormat?: string, timeFormat?: string, radioGroupName?: string, groupName?: string, value?: string, dropdownOptions?: list, imageInfo?: record, hyperlinkText?: string, attachmentInfo?: record, backgroundHexColor?: string, isReadOnly?: bool, offset?: record, label?: string, tabIndex?: int, dataSyncTag?: string, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, characterLimit?: int, formulaFieldSettings?: record, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", collaborationSettings?: record, isMasked?: bool, conditionalRules?: list}
  --enablePrintAndSign: oneof<nothing, bool> # default: false
  --enableReassign: oneof<nothing, bool> # default: true
  --disableExpiryAlert: oneof<nothing, bool> # nullable
  --documentInfo: list # nullable — item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
  --onBehalfOf: string # nullable
  --AutoDetectFields: oneof<nothing, bool> # default: false
  --documentDownloadOption: string@documentDownloadOption-completer # nullable
  --isSandbox: oneof<nothing, bool> # nullable
  --metaData: record # nullable
  --formGroups: list # nullable — item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
  --recipientNotificationSettings: record # shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
  --enableAuditTrailLocalization: oneof<nothing, bool> # nullable
  --downloadFileName: string # nullable
  --scheduledSendTime: int # nullable, format: int64
  --allowScheduledSend: oneof<nothing, bool> # default: false
  --allowedSignatureTypes: list # nullable
  --groupSignerSettings: record # shape: {enabled?: bool, allowedDirectories?: list}
  --enableAllowSignEverywhere: oneof<nothing, bool> # nullable
  --documentTimeZone: string # nullable
]: any -> record<documentId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/document/send")
  let body = {files: $files, title: $title, message: $message, signers: $signers, cc: $cc, enableSigningOrder: $enableSigningOrder, expiryDays: $expiryDays, expiryDateType: $expiryDateType, expiryValue: $expiryValue, reminderSettings: $reminderSettings, enableEmbeddedSigning: $enableEmbeddedSigning, disableEmails: $disableEmails, disableSMS: $disableSMS, brandId: $brandId, hideDocumentId: $hideDocumentId, labels: $labels, fileUrls: $fileUrls, sendLinkValidTill: $sendLinkValidTill, useTextTags: $useTextTags, textTagDefinitions: $textTagDefinitions, enablePrintAndSign: $enablePrintAndSign, enableReassign: $enableReassign, disableExpiryAlert: $disableExpiryAlert, documentInfo: $documentInfo, onBehalfOf: $onBehalfOf, AutoDetectFields: $AutoDetectFields, documentDownloadOption: $documentDownloadOption, isSandbox: $isSandbox, metaData: $metaData, formGroups: $formGroups, recipientNotificationSettings: $recipientNotificationSettings, enableAuditTrailLocalization: $enableAuditTrailLocalization, downloadFileName: $downloadFileName, scheduledSendTime: $scheduledSendTime, allowScheduledSend: $allowScheduledSend, allowedSignatureTypes: $allowedSignatureTypes, groupSignerSettings: $groupSignerSettings, enableAllowSignEverywhere: $enableAllowSignEverywhere, documentTimeZone: $documentTimeZone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Extends the expiration date of the document.
#
# PATCH /v1/document/extendExpiry
# operationId: ExtendExpiry
@deprecated --flag newExpiryDate
export def "document-extend-expiry ExtendExpiry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentId: string
  --newExpiryValue: string # nullable
  --newExpiryDate: string # DEPRECATED, nullable
  --warnPrior: oneof<nothing, bool> # nullable
  --onBehalfOf: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/extendExpiry" $qp)
  let body = {newExpiryValue: $newExpiryValue, newExpiryDate: $newExpiryDate, warnPrior: $warnPrior, onBehalfOf: $onBehalfOf} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generates a send URL which embeds document sending process into your application.
#
# POST /v1/document/createEmbeddedRequestUrl
# operationId: CreateEmbeddedRequestUrlDocument
# --signers item shape: {id?: string, name?: string, emailAddress?: string, privateMessage?: string, authenticationType?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", authenticationCode?: string, identityVerificationSettings?: record, signerOrder?: int, enableEmailOTP?: bool, signerType?: "Signer"|"Reviewer"|"InPersonSigner", hostEmail?: string, signerRole?: string, allowFieldConfiguration?: bool, formFields?: list, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", groupId?: string, recipientNotificationSettings?: record, authenticationRetryCount?: int, enableQes?: bool, authenticationSettings?: record}
# --cc item shape: {emailAddress: string}
# --reminderSettings shape: {enableAutoReminder?: bool, reminderDays?: int, reminderCount?: int}
# --textTagDefinitions item shape: {definitionId: string, type: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", signerIndex: int, isRequired?: bool, placeholder?: string, fieldId?: string, font?: record, validation?: record, size?: record, dateFormat?: string, timeFormat?: string, radioGroupName?: string, groupName?: string, value?: string, dropdownOptions?: list, imageInfo?: record, hyperlinkText?: string, attachmentInfo?: record, backgroundHexColor?: string, isReadOnly?: bool, offset?: record, label?: string, tabIndex?: int, dataSyncTag?: string, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, characterLimit?: int, formulaFieldSettings?: record, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", collaborationSettings?: record, isMasked?: bool, conditionalRules?: list}
# --documentInfo item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
# --formGroups item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
# --recipientNotificationSettings shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
# --groupSignerSettings shape: {enabled?: bool, allowedDirectories?: list}
@deprecated --flag expiryDays
@deprecated --flag enableEmbeddedSigning
export def "document-create-embedded-request-url CreateEmbeddedRequestUrlDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirectUrl: string # nullable, format: uri
  --showToolbar: oneof<nothing, bool> # default: false
  --sendViewOption: string@sendViewOption-completer # default: PreparePage
  --showSaveButton: oneof<nothing, bool> # default: true
  --locale: string@locale-completer # default: EN
  --showSendButton: oneof<nothing, bool> # default: true
  --showPreviewButton: oneof<nothing, bool> # default: true
  --showNavigationButtons: oneof<nothing, bool> # default: true
  --showTooltip: oneof<nothing, bool> # default: false
  --embeddedSendLinkValidTill: string # nullable, format: date-time
  --files: list # nullable
  --title: string # nullable
  --message: string # nullable
  --signers: list # nullable — item shape: {id?: string, name?: string, emailAddress?: string, privateMessage?: string, authenticationType?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", authenticationCode?: string, identityVerificationSettings?: record, signerOrder?: int, enableEmailOTP?: bool, signerType?: "Signer"|"Reviewer"|"InPersonSigner", hostEmail?: string, signerRole?: string, allowFieldConfiguration?: bool, formFields?: list, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", groupId?: string, recipientNotificationSettings?: record, authenticationRetryCount?: int, enableQes?: bool, authenticationSettings?: record}
  --cc: list # nullable — item shape: {emailAddress: string}
  --enableSigningOrder: oneof<nothing, bool> # default: false
  --expiryDays: int # DEPRECATED, format: int32
  --expiryDateType: string@expiryDateType-completer # nullable
  --expiryValue: int # format: int64, default: 60
  --reminderSettings: record # shape: {enableAutoReminder?: bool, reminderDays?: int, reminderCount?: int}
  --enableEmbeddedSigning: oneof<nothing, bool> # DEPRECATED, default: false
  --disableEmails: oneof<nothing, bool> # default: false
  --disableSMS: oneof<nothing, bool> # default: false
  --brandId: string # nullable
  --hideDocumentId: oneof<nothing, bool> # nullable, default: false
  --labels: list # nullable
  --fileUrls: list # nullable
  --sendLinkValidTill: string # nullable, format: date-time
  --useTextTags: oneof<nothing, bool> # default: false
  --textTagDefinitions: list # nullable — item shape: {definitionId: string, type: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", signerIndex: int, isRequired?: bool, placeholder?: string, fieldId?: string, font?: record, validation?: record, size?: record, dateFormat?: string, timeFormat?: string, radioGroupName?: string, groupName?: string, value?: string, dropdownOptions?: list, imageInfo?: record, hyperlinkText?: string, attachmentInfo?: record, backgroundHexColor?: string, isReadOnly?: bool, offset?: record, label?: string, tabIndex?: int, dataSyncTag?: string, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, characterLimit?: int, formulaFieldSettings?: record, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", collaborationSettings?: record, isMasked?: bool, conditionalRules?: list}
  --enablePrintAndSign: oneof<nothing, bool> # default: false
  --enableReassign: oneof<nothing, bool> # default: true
  --disableExpiryAlert: oneof<nothing, bool> # nullable
  --documentInfo: list # nullable — item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
  --onBehalfOf: string # nullable
  --AutoDetectFields: oneof<nothing, bool> # default: false
  --documentDownloadOption: string@documentDownloadOption-completer # nullable
  --isSandbox: oneof<nothing, bool> # nullable
  --metaData: record # nullable
  --formGroups: list # nullable — item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
  --recipientNotificationSettings: record # shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
  --enableAuditTrailLocalization: oneof<nothing, bool> # nullable
  --downloadFileName: string # nullable
  --scheduledSendTime: int # nullable, format: int64
  --allowScheduledSend: oneof<nothing, bool> # default: false
  --allowedSignatureTypes: list # nullable
  --groupSignerSettings: record # shape: {enabled?: bool, allowedDirectories?: list}
  --enableAllowSignEverywhere: oneof<nothing, bool> # nullable
  --documentTimeZone: string # nullable
]: any -> record<documentId: string, sendUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/document/createEmbeddedRequestUrl")
  let body = {redirectUrl: $redirectUrl, showToolbar: $showToolbar, sendViewOption: $sendViewOption, showSaveButton: $showSaveButton, locale: $locale, showSendButton: $showSendButton, showPreviewButton: $showPreviewButton, showNavigationButtons: $showNavigationButtons, showTooltip: $showTooltip, embeddedSendLinkValidTill: $embeddedSendLinkValidTill, files: $files, title: $title, message: $message, signers: $signers, cc: $cc, enableSigningOrder: $enableSigningOrder, expiryDays: $expiryDays, expiryDateType: $expiryDateType, expiryValue: $expiryValue, reminderSettings: $reminderSettings, enableEmbeddedSigning: $enableEmbeddedSigning, disableEmails: $disableEmails, disableSMS: $disableSMS, brandId: $brandId, hideDocumentId: $hideDocumentId, labels: $labels, fileUrls: $fileUrls, sendLinkValidTill: $sendLinkValidTill, useTextTags: $useTextTags, textTagDefinitions: $textTagDefinitions, enablePrintAndSign: $enablePrintAndSign, enableReassign: $enableReassign, disableExpiryAlert: $disableExpiryAlert, documentInfo: $documentInfo, onBehalfOf: $onBehalfOf, AutoDetectFields: $AutoDetectFields, documentDownloadOption: $documentDownloadOption, isSandbox: $isSandbox, metaData: $metaData, formGroups: $formGroups, recipientNotificationSettings: $recipientNotificationSettings, enableAuditTrailLocalization: $enableAuditTrailLocalization, downloadFileName: $downloadFileName, scheduledSendTime: $scheduledSendTime, allowScheduledSend: $allowScheduledSend, allowedSignatureTypes: $allowedSignatureTypes, groupSignerSettings: $groupSignerSettings, enableAllowSignEverywhere: $enableAllowSignEverywhere, documentTimeZone: $documentTimeZone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generates an embedded edit URL that allows the document editing process to be integrated into your application.
#
# POST /v1/document/createEmbeddedEditUrl
# operationId: createEmbeddedEditUrl
export def "document-create-embedded-edit-url createEmbeddedEditUrl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentId: string
  --redirectUrl: string # nullable, format: uri
  --showToolbar: oneof<nothing, bool> # default: false
  --sendViewOption: string@sendViewOption-completer # default: PreparePage
  --locale: string@locale-completer # default: EN
  --showSendButton: oneof<nothing, bool> # default: true
  --showPreviewButton: oneof<nothing, bool> # default: true
  --showNavigationButtons: oneof<nothing, bool> # default: true
  --linkValidTill: string # nullable, format: date-time
  --onBehalfOf: string # nullable
]: any -> record<editUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/createEmbeddedEditUrl" $qp)
  let body = {redirectUrl: $redirectUrl, showToolbar: $showToolbar, sendViewOption: $sendViewOption, locale: $locale, showSendButton: $showSendButton, showPreviewButton: $showPreviewButton, showNavigationButtons: $showNavigationButtons, linkValidTill: $linkValidTill, onBehalfOf: $onBehalfOf} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List user documents.
#
# GET /v1/document/list
# operationId: ListDocuments
export def "document-list ListDocuments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --SentBy: list
  --Recipients: list
  --TransmitType: string@TransmitType-completer
  --DateFilterType: string@DateFilterType-completer # Date Filter as SentBetween and ExpiresOn.
  --PageSize: int # Page size specified in get document list request. (format: int32, default: 10)
  --Page: int # Page index specified in get document list request. (format: int32, default: 1)
  --StartDate: string # Start date of the document (format: date-time)
  --Status: list # Status of the document such as In-progress, Completed, Decline, Expired, Revoked, Draft.
  --EndDate: string # End date of the document (format: date-time)
  --SearchKey: string # Documents can be listed by the search key present in the document like document title, document ID, sender or recipient(s) name, etc.,
  --Labels: list # Labels of the document.
  --NextCursor: int # Next cursor value for pagination, required for fetching the next set of documents beyond 10,000 records. (format: int64)
  --BrandIds: list # BrandId(s) of the document.
]: nothing -> record<pageDetails: record<pageSize: int, page: int, totalRecordsCount: int, totalPages: int, sortedColumn: string, sortDirection: string>, result: table<documentId: string, senderDetail: record, ccDetails: list, createdDate: int, activityDate: int, activityBy: string, messageTitle: string, status: string, signerDetails: list, expiryDate: int, enableSigningOrder: bool, isDeleted: bool, labels: list, cursor: int, brandId: string, scheduledSendTime: int, inEditingMode: bool, displayStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SentBy" $SentBy "multi") (serialize-qp "Recipients" $Recipients "multi") (serialize-qp "TransmitType" $TransmitType "scalar") (serialize-qp "DateFilterType" $DateFilterType "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "Status" $Status "multi") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "SearchKey" $SearchKey "scalar") (serialize-qp "Labels" $Labels "multi") (serialize-qp "NextCursor" $NextCursor "scalar") (serialize-qp "BrandIds" $BrandIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user Team documents.
#
# GET /v1/document/teamlist
# operationId: TeamDocuments
export def "document-teamlist TeamDocuments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --UserId: list # UserId of the  Team document.
  --TeamId: list # TeamId  of the  Team document.
  --TransmitType: string@TransmitType-completer # Transmit type as Sent, Received and Both.
  --DateFilterType: string@DateFilterType-completer # Date Filter as SentBetween and Expiring.
  --PageSize: int # Page size specified in get document list request. (format: int32, default: 10)
  --Page: int # Page index specified in get document list request. (format: int32, default: 1)
  --StartDate: string # Start date of the document (format: date-time)
  --Status: list # Status of the document such as In-progress, Completed, Decline, Expired, Revoked, Draft.
  --EndDate: string # End date of the document (format: date-time)
  --SearchKey: string # Documents can be listed by the search key present in the document like document title, document ID, sender or recipient(s) name, etc.,
  --Labels: list # Labels of the document.
  --NextCursor: int # Next cursor value for pagination, required for fetching the next set of documents beyond 10,000 records. (format: int64)
  --BrandIds: list # BrandId(s) of the document.
]: nothing -> record<pageDetails: record<pageSize: int, page: int, totalRecordsCount: int, totalPages: int, sortedColumn: string, sortDirection: string>, result: table<documentId: string, senderDetail: record, ccDetails: list, createdDate: int, activityDate: int, activityBy: string, messageTitle: string, status: string, signerDetails: list, expiryDate: int, enableSigningOrder: bool, isDeleted: bool, labels: list, cursor: int, brandId: string, scheduledSendTime: int, inEditingMode: bool, displayStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UserId" $UserId "multi") (serialize-qp "TeamId" $TeamId "multi") (serialize-qp "TransmitType" $TransmitType "scalar") (serialize-qp "DateFilterType" $DateFilterType "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "Status" $Status "multi") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "SearchKey" $SearchKey "scalar") (serialize-qp "Labels" $Labels "multi") (serialize-qp "NextCursor" $NextCursor "scalar") (serialize-qp "BrandIds" $BrandIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/teamlist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the behalf documents.
#
# GET /v1/document/behalfList
# operationId: BehalfDocuments
export def "document-behalf-list BehalfDocuments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageType: string@PageType-completer # The filter used to differentiate between documents sent on the user's behalf and documents sent by the user on behalf of others. The API will return documents based on the specified value.
  --EmailAddress: list # The sender identity's email used to filter the documents returned in the API. The API will return documents that were sent on behalf of the specified email address.
  --Signers: list # A list of signer email addresses used to filter the documents returned in the API. The API will return documents where the signer's email address matches one of the email addresses provided in this list
  --PageSize: int # Page size specified in get document list request. (format: int32, default: 10)
  --Page: int # Page index specified in get document list request. (format: int32, default: 1)
  --StartDate: string # Start date of the document (format: date-time)
  --Status: list # Status of the document such as In-progress, Completed, Decline, Expired, Revoked, Draft.
  --EndDate: string # End date of the document (format: date-time)
  --SearchKey: string # Documents can be listed by the search key present in the document like document title, document ID, sender or recipient(s) name, etc.,
  --Labels: list # Labels of the document.
  --NextCursor: int # Next cursor value for pagination, required for fetching the next set of documents beyond 10,000 records. (format: int64)
  --BrandIds: list # BrandId(s) of the document.
]: nothing -> record<pageDetails: record<pageSize: int, page: int, totalRecordsCount: int, totalPages: int, sortedColumn: string, sortDirection: string>, result: table<behalfOf: record, documentId: string, senderDetail: record, ccDetails: list, createdDate: int, activityDate: int, activityBy: string, messageTitle: string, status: string, signerDetails: list, expiryDate: int, enableSigningOrder: bool, isDeleted: bool, labels: list, cursor: int, brandId: string, scheduledSendTime: int, inEditingMode: bool, displayStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageType" $PageType "scalar") (serialize-qp "EmailAddress" $EmailAddress "multi") (serialize-qp "Signers" $Signers "multi") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "Status" $Status "multi") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "SearchKey" $SearchKey "scalar") (serialize-qp "Labels" $Labels "multi") (serialize-qp "NextCursor" $NextCursor "scalar") (serialize-qp "BrandIds" $BrandIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/behalfList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get summary of the document.
#
# GET /v1/document/properties
# operationId: GetDocumentProperties
export def "document-properties GetDocumentProperties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentId: string
]: nothing -> record<documentId: string, brandId: string, messageTitle: string, documentDescription: string, status: string, files: table<id: string, documentName: string, order: int, pageCount: int, templateName: string, templateId: string>, senderDetail: record<name: string, privateMessage: string, emailAddress: string, isViewed: bool>, signerDetails: table<id: string, signerName: string, signerRole: string, signerEmail: string, status: string, enableAccessCode: bool, isAuthenticationFailed: bool, enableEmailOTP: bool, authenticationType: string, isDeliveryFailed: bool, isViewed: bool, order: int, signerType: string, hostEmail: string, hostName: string, isReassigned: bool, privateMessage: string, allowFieldConfiguration: bool, formFields: list, language: int, locale: string, signType: string, groupId: string, phoneNumber: record, idVerification: record, recipientNotificationSettings: record, authenticationRetryCount: int, enableQes: bool, deliveryMode: string, authenticationSettings: record, groupSigners: list>, formGroups: table<minimumCount: int, maximumCount: int, dataSyncTag: string, groupNames: list, groupValidation: string>, commonFields: table<id: string, formFieldId: string, type: string, value: string, font: string, isRequired: bool, isReadOnly: bool, lineHeight: float, fontSize: float, fontColor: string, isUnderline: bool, isItalic: bool, isBold: bool, groupName: string, label: string, placeholder: string, validationtype: string, validationCustomRegex: string, validationCustomRegexMessage: string, dateFormat: string, timeFormat: string, imageInfo: record, attachmentInfo: record, fileInfo: record, editableDateFieldSettings: record, hyperlinkText: string, conditionalRules: list, bounds: record, pageNumber: int, dataSyncTag: string, dropdownOptions: list, textAlign: string, textDirection: string, characterSpacing: float, backgroundHexColor: string, tabIndex: int, formulaFieldSettings: record, resizeOption: string, allowEditFormField: bool, allowDeleteFormField: bool, collaborationSettings: record, hidden: bool, isMasked: bool>, behalfOf: record<name: string, emailAddress: string>, ccDetails: table<emailAddress: string, isViewed: bool>, reminderSettings: record<enableAutoReminder: bool, reminderDays: int, reminderCount: int>, reassign: table<signerEmail: string, order: int, message: string>, documentHistory: table<id: string, name: string, email: string, fromName: string, fromEmail: string, fromPhoneNumber: string, toName: string, toEmail: string, toPhoneNumber: string, ipaddress: string, action: string, timestamp: int, recipientChangeLog: record, documentChangeLog: record, fieldChangeLog: record>, activityBy: string, activityDate: int, activityAction: string, createdDate: int, expiryDays: int, expiryDate: int, enableSigningOrder: bool, isDeleted: bool, revokeMessage: string, declineMessage: string, applicationId: string, labels: list<string>, disableEmails: bool, enablePrintAndSign: bool, enableReassign: bool, disableExpiryAlert: bool, hideDocumentId: bool, expiryDateType: string, expiryValue: int, documentDownloadOption: string, metaData: record, recipientNotificationSettings: record<signatureRequest: bool, declined: bool, revoked: bool, signed: bool, completed: bool, expired: bool, reassigned: bool, deleted: bool, reminders: bool, editRecipient: bool, editDocument: bool, viewed: bool>, enableAuditTrailLocalization: bool, downloadFileName: string, scheduledSendTime: int, allowedSignatureTypes: list<string>, groupSignerSettings: record<enabled: bool, allowedDirectories: list<string>>, inEditingMode: bool, displayStatus: string, enableAllowSignEverywhere: bool, isCombinedAudit: bool, isCombinedAttachment: bool, documentTimeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/properties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download the document.
#
# GET /v1/document/download
# operationId: DownloadDocument
export def "document-download DownloadDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --documentId: string
  --onBehalfOf: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar") (serialize-qp "onBehalfOf" $onBehalfOf "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/download" $qp)
  let accept_val = ($accept | default "application/json;odata.metadata=minimal;odata.streaming=true")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download the Attachment.
#
# GET /v1/document/downloadAttachment
# operationId: DownloadAttachment
export def "document-download-attachment DownloadAttachment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --documentId: string
  --attachmentId: string
  --onBehalfOf: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar") (serialize-qp "attachmentId" $attachmentId "scalar") (serialize-qp "onBehalfOf" $onBehalfOf "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/downloadAttachment" $qp)
  let accept_val = ($accept | default "application/json;odata.metadata=minimal;odata.streaming=true")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download the audit trail document.
#
# GET /v1/document/downloadAuditLog
# operationId: DownloadAuditLog
export def "document-download-audit-log DownloadAuditLog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --documentId: string
  --onBehalfOf: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar") (serialize-qp "onBehalfOf" $onBehalfOf "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/downloadAuditLog" $qp)
  let accept_val = ($accept | default "application/json;odata.metadata=minimal;odata.streaming=true")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke the document.
#
# POST /v1/document/revoke
# operationId: RevokeDocument
export def "document-revoke RevokeDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentId: string
  message: string
  --onBehalfOf: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/revoke" $qp)
  let body = {message: $message, onBehalfOf: $onBehalfOf} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the document.
#
# DELETE /v1/document/delete
# operationId: DeleteDocument
export def "document-delete DeleteDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentId: string
  --deletePermanently: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar") (serialize-qp "deletePermanently" $deletePermanently "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send reminder to pending signers.
#
# POST /v1/document/remind
# operationId: RemindDocument
# --reminderPhoneNumbers item shape: {countryCode?: string, number?: string}
export def "document-remind RemindDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentId: string
  --receiverEmails: list
  --message: string # nullable
  --onBehalfOf: string # nullable
  --reminderPhoneNumbers: list # nullable — item shape: {countryCode?: string, number?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar") (serialize-qp "receiverEmails" $receiverEmails "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/remind" $qp)
  let body = {message: $message, onBehalfOf: $onBehalfOf, reminderPhoneNumbers: $reminderPhoneNumbers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Changes the access code for the given document signer.
#
# PATCH /v1/document/changeAccessCode
# operationId: ChangeAccessCode
# --phoneNumber shape: {countryCode?: string, number?: string}
export def "document-change-access-code ChangeAccessCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DocumentId: string
  --EmailId: string
  --ZOrder: int # format: int32
  accessCode: string
  --phoneNumber: record # shape: {countryCode?: string, number?: string}
  --onBehalfOf: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DocumentId" $DocumentId "scalar") (serialize-qp "EmailId" $EmailId "scalar") (serialize-qp "ZOrder" $ZOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/changeAccessCode" $qp)
  let body = {accessCode: $accessCode, phoneNumber: $phoneNumber, onBehalfOf: $onBehalfOf} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change recipient details of a document.
#
# PATCH /v1/document/changeRecipient
# operationId: ChangeRecipient
# --phoneNumber shape: {countryCode?: string, number?: string}
# --oldPhoneNumber shape: {countryCode?: string, number?: string}
export def "document-change-recipient ChangeRecipient" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentId: string
  newSignerName: string
  reason: string
  --order: int # nullable, format: int32
  --newSignerEmail: string # nullable, format: email
  --oldSignerEmail: string # nullable, format: email
  --onBehalfOf: string # nullable
  --phoneNumber: record # shape: {countryCode?: string, number?: string}
  --oldPhoneNumber: record # shape: {countryCode?: string, number?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/changeRecipient" $qp)
  let body = {newSignerName: $newSignerName, reason: $reason, order: $order, newSignerEmail: $newSignerEmail, oldSignerEmail: $oldSignerEmail, onBehalfOf: $onBehalfOf, phoneNumber: $phoneNumber, oldPhoneNumber: $oldPhoneNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get sign link for Embedded Sign.
#
# GET /v1/document/getEmbeddedSignLink
# operationId: GetEmbeddedSignLink
export def "document-get-embedded-sign-link GetEmbeddedSignLink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --DocumentId: string
  --SignerEmail: string
  --CountryCode: string
  --PhoneNumber: string
  --SignLinkValidTill: string # format: date-time
  --RedirectUrl: string # format: uri
]: nothing -> record<signLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DocumentId" $DocumentId "scalar") (serialize-qp "SignerEmail" $SignerEmail "scalar") (serialize-qp "CountryCode" $CountryCode "scalar") (serialize-qp "PhoneNumber" $PhoneNumber "scalar") (serialize-qp "SignLinkValidTill" $SignLinkValidTill "scalar") (serialize-qp "RedirectUrl" $RedirectUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/getEmbeddedSignLink" $qp)
  let accept_val = ($accept | default "application/json;odata.metadata=minimal;odata.streaming=true")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add the Tags in Documents.
#
# PATCH /v1/document/addTags
# operationId: AddDocumentTag
export def "document-add-tags AddDocumentTag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  documentId: string
  tags: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/document/addTags")
  let body = {documentId: $documentId, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Tags in Documents.
#
# DELETE /v1/document/deleteTags
# operationId: DeleteDocumentTag
export def "document-delete-tags DeleteDocumentTag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  documentId: string
  tags: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/document/deleteTags")
  let body = {documentId: $documentId, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove the access code for the given document signer.
#
# PATCH /v1/document/RemoveAuthentication
# operationId: RemoveAuthentication
# --phoneNumber shape: {countryCode?: string, number?: string}
export def "document-remove-authentication RemoveAuthentication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DocumentId: string # Document ID of the signature request
  --emailId: string # nullable
  --zOrder: int # nullable, format: int32
  --phoneNumber: record # shape: {countryCode?: string, number?: string}
  --onBehalfOf: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DocumentId" $DocumentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/RemoveAuthentication" $qp)
  let body = {emailId: $emailId, zOrder: $zOrder, phoneNumber: $phoneNumber, onBehalfOf: $onBehalfOf} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# The add authentication to recipient.
#
# PATCH /v1/document/addAuthentication
# operationId: AddAuthentication
# --phoneNumber shape: {countryCode?: string, number?: string}
# --identityVerificationSettings shape: {type?: "EveryAccess"|"UntilSignCompleted"|"OncePerDocument", maximumRetryCount?: int, requireLiveCapture?: bool, requireMatchingSelfie?: bool, nameMatcher?: "Strict"|"Moderate"|"Lenient", holdForPrefill?: bool, allowedDocumentTypes?: list}
# --authenticationSettings shape: {authenticationFrequency?: "None"|"EveryAccess"|"UntilSignCompleted"|"OncePerDocument"}
export def "document-add-authentication AddAuthentication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentId: string
  --emailId: string # nullable
  --order: int # nullable, format: int32
  --accessCode: string # nullable
  authenticationType: string@authenticationType-completer
  --onBehalfOf: string # nullable
  --phoneNumber: record # shape: {countryCode?: string, number?: string}
  --identityVerificationSettings: record # shape: {type?: "EveryAccess"|"UntilSignCompleted"|"OncePerDocument", maximumRetryCount?: int, requireLiveCapture?: bool, requireMatchingSelfie?: bool, nameMatcher?: "Strict"|"Moderate"|"Lenient", holdForPrefill?: bool, allowedDocumentTypes?: list}
  --authenticationRetryCount: int # nullable, format: int32
  --authenticationSettings: record # shape: {authenticationFrequency?: "None"|"EveryAccess"|"UntilSignCompleted"|"OncePerDocument"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/addAuthentication" $qp)
  let body = {emailId: $emailId, order: $order, accessCode: $accessCode, authenticationType: $authenticationType, onBehalfOf: $onBehalfOf, phoneNumber: $phoneNumber, identityVerificationSettings: $identityVerificationSettings, authenticationRetryCount: $authenticationRetryCount, authenticationSettings: $authenticationSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the value (prefill) of the fields in the document.
#
# PATCH /v1/document/prefillFields
# operationId: PrefillFields
# --fields item shape: {id: string, value: string}
export def "document-prefill-fields PrefillFields" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentId: string
  --body-fields: list # item shape: {id: string, value: string}
  --onBehalfOf: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/prefillFields" $qp)
  let body = {fields: $body_fields, onBehalfOf: $onBehalfOf} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sends a draft-status document out for signature.
#
# POST /v1/document/draftSend
# operationId: DraftSend
export def "document-draft-send DraftSend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentId: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/draftSend" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit and updates an existing document.
#
# PUT /v1/document/edit
# operationId: EditDocument
# --files item shape: {editAction: "Add"|"Update"|"Remove", file?: string, fileUrl?: string, id?: string}
# --signers item shape: {editAction: "Add"|"Update"|"Remove", id?: string, name?: string, emailAddress?: string, privateMessage?: string, authenticationType?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", authenticationCode?: string, identityVerificationSettings?: record, signerOrder?: int, enableEmailOTP?: bool, signerType?: "Signer"|"Reviewer"|"InPersonSigner", hostEmail?: string, signerRole?: string, allowFieldConfiguration?: bool, formFields?: list, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", groupId?: string, recipientNotificationSettings?: record, authenticationRetryCount?: int, enableQes?: bool, authenticationSettings?: record}
# --cc item shape: {emailAddress: string}
# --reminderSettings shape: {enableAutoReminder?: bool, reminderDays?: int, reminderCount?: int}
# --textTagDefinitions item shape: {definitionId: string, type: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", signerIndex: int, isRequired?: bool, placeholder?: string, fieldId?: string, font?: record, validation?: record, size?: record, dateFormat?: string, timeFormat?: string, radioGroupName?: string, groupName?: string, value?: string, dropdownOptions?: list, imageInfo?: record, hyperlinkText?: string, attachmentInfo?: record, backgroundHexColor?: string, isReadOnly?: bool, offset?: record, label?: string, tabIndex?: int, dataSyncTag?: string, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, characterLimit?: int, formulaFieldSettings?: record, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", collaborationSettings?: record, isMasked?: bool, conditionalRules?: list}
# --documentInfo item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
# --recipientNotificationSettings shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
# --formGroups item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
# --groupSignerSettings shape: {enabled?: bool, allowedDirectories?: list}
export def "document-edit EditDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentId: string
  --files: list # nullable — item shape: {editAction: "Add"|"Update"|"Remove", file?: string, fileUrl?: string, id?: string}
  --title: string # nullable
  --message: string # nullable
  --signers: list # nullable — item shape: {editAction: "Add"|"Update"|"Remove", id?: string, name?: string, emailAddress?: string, privateMessage?: string, authenticationType?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", authenticationCode?: string, identityVerificationSettings?: record, signerOrder?: int, enableEmailOTP?: bool, signerType?: "Signer"|"Reviewer"|"InPersonSigner", hostEmail?: string, signerRole?: string, allowFieldConfiguration?: bool, formFields?: list, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", groupId?: string, recipientNotificationSettings?: record, authenticationRetryCount?: int, enableQes?: bool, authenticationSettings?: record}
  --cc: list # nullable — item shape: {emailAddress: string}
  --enableSigningOrder: oneof<nothing, bool> # nullable
  --enableAuditTrailLocalization: oneof<nothing, bool> # nullable
  --expiryDateType: string@expiryDateType-completer # nullable
  --expiryValue: int # nullable, format: int64
  --reminderSettings: record # shape: {enableAutoReminder?: bool, reminderDays?: int, reminderCount?: int}
  --disableEmails: oneof<nothing, bool> # nullable
  --disableSMS: oneof<nothing, bool> # nullable
  --brandId: string # nullable
  --hideDocumentId: oneof<nothing, bool> # nullable
  --labels: list # nullable
  --disableExpiryAlert: oneof<nothing, bool> # nullable
  --enablePrintAndSign: oneof<nothing, bool> # nullable
  --enableReassign: oneof<nothing, bool> # nullable
  --useTextTags: oneof<nothing, bool>
  --textTagDefinitions: list # nullable — item shape: {definitionId: string, type: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", signerIndex: int, isRequired?: bool, placeholder?: string, fieldId?: string, font?: record, validation?: record, size?: record, dateFormat?: string, timeFormat?: string, radioGroupName?: string, groupName?: string, value?: string, dropdownOptions?: list, imageInfo?: record, hyperlinkText?: string, attachmentInfo?: record, backgroundHexColor?: string, isReadOnly?: bool, offset?: record, label?: string, tabIndex?: int, dataSyncTag?: string, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, characterLimit?: int, formulaFieldSettings?: record, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", collaborationSettings?: record, isMasked?: bool, conditionalRules?: list}
  --documentInfo: list # nullable — item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
  --onBehalfOf: string # nullable
  --documentDownloadOption: string@documentDownloadOption-completer # nullable
  --metaData: record # nullable
  --recipientNotificationSettings: record # shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
  --formGroups: list # nullable — item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
  --downloadFileName: string # nullable
  --scheduledSendTime: int # nullable, format: int64
  --allowedSignatureTypes: list # nullable
  --groupSignerSettings: record # shape: {enabled?: bool, allowedDirectories?: list}
  --enableAllowSignEverywhere: oneof<nothing, bool> # nullable
  --documentTimeZone: string # nullable
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/edit" $qp)
  let body = {files: $files, title: $title, message: $message, signers: $signers, cc: $cc, enableSigningOrder: $enableSigningOrder, enableAuditTrailLocalization: $enableAuditTrailLocalization, expiryDateType: $expiryDateType, expiryValue: $expiryValue, reminderSettings: $reminderSettings, disableEmails: $disableEmails, disableSMS: $disableSMS, brandId: $brandId, hideDocumentId: $hideDocumentId, labels: $labels, disableExpiryAlert: $disableExpiryAlert, enablePrintAndSign: $enablePrintAndSign, enableReassign: $enableReassign, useTextTags: $useTextTags, textTagDefinitions: $textTagDefinitions, documentInfo: $documentInfo, onBehalfOf: $onBehalfOf, documentDownloadOption: $documentDownloadOption, metaData: $metaData, recipientNotificationSettings: $recipientNotificationSettings, formGroups: $formGroups, downloadFileName: $downloadFileName, scheduledSendTime: $scheduledSendTime, allowedSignatureTypes: $allowedSignatureTypes, groupSignerSettings: $groupSignerSettings, enableAllowSignEverywhere: $enableAllowSignEverywhere, documentTimeZone: $documentTimeZone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancels editing for a document that is currently in edit-mode.
#
# POST /v1/document/cancelEditing
# operationId: cancelEditing
export def "document-cancel-editing cancelEditing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentId: string
  --onBehalfOf: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar") (serialize-qp "onBehalfOf" $onBehalfOf "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/document/cancelEditing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Group Contacts.
#
# GET /v1/contactGroups/list
# operationId: GroupContactList
export def "contact-groups-list GroupContactList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # Page size specified in get user group contact list request. Default value is 10. (format: int32, default: 10)
  --Page: int # Page index specified in get user group contact list request. Default value is 1. (format: int32, default: 1)
  --SearchKey: string # Group Contacts can be listed by the search  based on the Name or Email
  --ContactType: string@ContactType-completer # Group Contact type whether the contact is my contacts or all contacts. Default value is AllContacts.
  --Directories: list # Group Contacts can be listed by the search  based on the directories
]: nothing -> record<pageDetails: record<pageSize: int, page: int, totalRecordsCount: int>, result: table<groupName: string, groupId: string, contacts: list, directories: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "SearchKey" $SearchKey "scalar") (serialize-qp "ContactType" $ContactType "scalar") (serialize-qp "Directories" $Directories "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contactGroups/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Group Contact.
#
# POST /v1/contactGroups/create
# operationId: CreateGroupContact
# --contacts item shape: {name: string, email: string}
export def "contact-groups-create CreateGroupContact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  groupName: string
  --directories: list # nullable
  contacts: list # item shape: {name: string, email: string}
]: any -> record<groupId: string, groupName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contactGroups/create")
  let body = {groupName: $groupName, directories: $directories, contacts: $contacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the Group Contact.
#
# PUT /v1/contactGroups/update
# operationId: UpdateGroupContact
# --contacts item shape: {name: string, email: string}
export def "contact-groups-update UpdateGroupContact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupId: string
  --groupName: string # nullable
  --directories: list # nullable
  --contacts: list # nullable — item shape: {name: string, email: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupId" $groupId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contactGroups/update" $qp)
  let body = {groupName: $groupName, directories: $directories, contacts: $contacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Summary of the Group Contact.
#
# GET /v1/contactGroups/get
# operationId: GetGroupContact
export def "contact-groups-get GetGroupContact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupId: string
]: nothing -> record<groupName: string, groupId: string, contacts: table<name: string, email: string>, creator: record<userId: string, createdBy: string>, directories: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupId" $groupId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contactGroups/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a Group Contact.
#
# DELETE /v1/contactGroups/delete
# operationId: DeleteGroupContact
export def "contact-groups-delete DeleteGroupContact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupId: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupId" $groupId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/contactGroups/delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the ID verification report for the specified document signer.
#
# POST /v1/identityVerification/report
# operationId: Report
export def "identity-verification-report Report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentId: string # format: uuid
  --emailId: string # nullable
  --countryCode: string # nullable
  --phoneNumber: string # nullable
  --order: int # format: int32
  --onBehalfOf: string # nullable
]: any -> record<verificationResult: string, verifiedDate: string, error: record<code: string, message: string>, document: record<type: string, firstName: string, lastName: string, country: string, documentNumber: string, address: record<city: string, country: string, line1: string, line2: string, postalCode: string, state: string>, dob: record<day: int, month: int, year: int>, issuedDate: record<day: int, month: int, year: int>, expirationDate: record<day: int, month: int, year: int>, documentFiles: list<string>, selfieFile: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/identityVerification/report" $qp)
  let body = {emailId: $emailId, countryCode: $countryCode, phoneNumber: $phoneNumber, order: $order, onBehalfOf: $onBehalfOf} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the uploaded ID verification document or selfie image for the specified document signer using the file ID.
#
# POST /v1/identityVerification/image
# operationId: Image
export def "identity-verification-image Image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --documentId: string # format: uuid
  --emailId: string # nullable
  --countryCode: string # nullable
  --phoneNumber: string # nullable
  --order: int # format: int32
  --fileId: string # nullable
  --onBehalfOf: string # nullable
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/identityVerification/image" $qp)
  let body = {emailId: $emailId, countryCode: $countryCode, phoneNumber: $phoneNumber, order: $order, fileId: $fileId, onBehalfOf: $onBehalfOf} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json;odata.metadata=minimal;odata.streaming=true")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate a URL that embeds manual ID verification for the specified document signer into your application.
#
# POST /v1/identityVerification/createEmbeddedVerificationUrl
# operationId: Create Embedded Verification Url
export def "identity-verification-create-embedded-verification-url Create-Embedded-Verification-Url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentId: string # format: uuid
  --emailId: string # nullable
  --countryCode: string # nullable
  --phoneNumber: string # nullable
  --redirectUrl: string # nullable
  --order: int # format: int32
  --onBehalfOf: string # nullable
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $documentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/identityVerification/createEmbeddedVerificationUrl" $qp)
  let body = {emailId: $emailId, countryCode: $countryCode, phoneNumber: $phoneNumber, redirectUrl: $redirectUrl, order: $order, onBehalfOf: $onBehalfOf} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the Api credits details.
#
# GET /v1/plan/apiCreditsCount
# operationId: ApiCreditsCount
export def "plan-api-credits-count ApiCreditsCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<BalanceCredits: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/plan/apiCreditsCount")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates sender identity.
#
# POST /v1/senderIdentities/create
# operationId: CreateSenderIdentities
# --notificationSettings shape: {viewed?: bool, sent?: bool, deliveryFailed?: bool, declined?: bool, revoked?: bool, reassigned?: bool, completed?: bool, signed?: bool, expired?: bool, authenticationFailed?: bool, reminders?: bool, attachSignedDocument?: bool}
export def "sender-identities-create CreateSenderIdentities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # nullable
  email: string
  --notificationSettings: record # shape: {viewed?: bool, sent?: bool, deliveryFailed?: bool, declined?: bool, revoked?: bool, reassigned?: bool, completed?: bool, signed?: bool, expired?: bool, authenticationFailed?: bool, reminders?: bool, attachSignedDocument?: bool}
  --brandId: string # nullable
  --redirectUrl: string # nullable, format: uri
  --metaData: record # nullable
  --locale: string@locale-completer
]: any -> record<senderIdentityId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/senderIdentities/create")
  let body = {name: $name, email: $email, notificationSettings: $notificationSettings, brandId: $brandId, redirectUrl: $redirectUrl, metaData: $metaData, locale: $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates sender identity.
#
# POST /v1/senderIdentities/update
# operationId: UpdateSenderIdentities
# --notificationSettings shape: {viewed?: bool, sent?: bool, deliveryFailed?: bool, declined?: bool, revoked?: bool, reassigned?: bool, completed?: bool, signed?: bool, expired?: bool, authenticationFailed?: bool, reminders?: bool, attachSignedDocument?: bool}
export def "sender-identities-update UpdateSenderIdentities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --name: string # nullable
  --notificationSettings: record # shape: {viewed?: bool, sent?: bool, deliveryFailed?: bool, declined?: bool, revoked?: bool, reassigned?: bool, completed?: bool, signed?: bool, expired?: bool, authenticationFailed?: bool, reminders?: bool, attachSignedDocument?: bool}
  --redirectUrl: string # nullable, format: uri
  --metaData: record # nullable
  --locale: string@locale-completer # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/senderIdentities/update" $qp)
  let body = {name: $name, notificationSettings: $notificationSettings, redirectUrl: $redirectUrl, metaData: $metaData, locale: $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes sender identity.
#
# DELETE /v1/senderIdentities/delete
# operationId: DeleteSenderIdentities
export def "sender-identities-delete DeleteSenderIdentities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/senderIdentities/delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resends sender identity invitation.
#
# POST /v1/senderIdentities/resendInvitation
# operationId: ResendInvitationSenderIdentities
export def "sender-identities-resend-invitation ResendInvitationSenderIdentities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/senderIdentities/resendInvitation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rerequests denied sender identity.
#
# POST /v1/senderIdentities/rerequest
# operationId: ReRequestSenderIdentities
export def "sender-identities-rerequest ReRequestSenderIdentities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/senderIdentities/rerequest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists sender identity.
#
# GET /v1/senderIdentities/list
# operationId: ListSenderIdentities
export def "sender-identities-list ListSenderIdentities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # Page size specified in get sender identity list request. (format: int32, default: 10)
  --Page: int # Page index specified in get sender identity request. (format: int32, default: 1)
  --Search: string # Users can be listed by the search key present in the sender identity like sender identity name and email address
  --BrandIds: list # A list of brand IDs to filter associated with the sender identity.
]: nothing -> record<result: table<id: string, name: string, email: string, status: string, createdBy: string, approvedDate: string, notificationSettings: record, brandId: string, redirectUrl: string, metaData: record, locale: string>, pageDetails: record<pageSize: int, page: int, totalRecordsCount: int, totalPages: int, sortedColumn: string, sortDirection: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "Search" $Search "scalar") (serialize-qp "BrandIds" $BrandIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/senderIdentities/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets sender identity by ID or email.
#
# GET /v1/senderIdentities/properties
# operationId: GetSenderIdentityProperties
export def "sender-identities-properties GetSenderIdentityProperties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --email: string
]: nothing -> record<id: string, name: string, email: string, status: string, createdBy: string, approvedDate: string, notificationSettings: record<viewed: bool, sent: bool, deliveryFailed: bool, declined: bool, revoked: bool, reassigned: bool, completed: bool, signed: bool, expired: bool, authenticationFailed: bool, reminders: bool, attachSignedDocument: bool>, brandId: string, redirectUrl: string, metaData: record, locale: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/senderIdentities/properties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Team details.
#
# GET /v1/teams/get
# operationId: GetTeam
export def "teams-get GetTeam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamId: string
]: nothing -> record<teamId: string, teamName: string, users: table<userId: string, email: string, firstName: string, lastName: string, userRole: string, userStatus: string>, createdDate: int, modifiedDate: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamId" $teamId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/teams/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Teams.
#
# GET /v1/teams/list
# operationId: ListTeams
export def "teams-list ListTeams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Page: int # Page index specified in get team list request. (format: int32, default: 1)
  --PageSize: int # Page size specified in get team list request. (format: int32, default: 10)
  --SearchKey: string # Teams can be listed by the search key
]: nothing -> record<pageDetails: record<pageSize: int, page: int>, results: table<teamName: string, teamId: string, createdDate: int, modifiedDate: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Page" $Page "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "SearchKey" $SearchKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/teams/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Team.
#
# POST /v1/teams/create
# operationId: CreateTeam
export def "teams-create CreateTeam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  teamName: string
]: any -> record<teamId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/teams/create")
  let body = {teamName: $teamName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Team.
#
# PUT /v1/teams/update
# operationId: UpdateTeam
export def "teams-update UpdateTeam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  teamId: string
  teamName: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/teams/update")
  let body = {teamId: $teamId, teamName: $teamName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all the templates.
#
# GET /v1/template/list
# operationId: ListTemplates
export def "template-list ListTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --TemplateType: string@TemplateType-completer
  --PageSize: int # format: int32, default: 10
  --Page: int # format: int32, default: 1
  --SearchKey: string
  --OnBehalfOf: list # The sender identity's email used to filter the templates returned in the API. The API will return templates that were sent on behalf of the specified email address.
  --CreatedBy: list # The templates can be listed by the creator of the template.
  --TemplateLabels: list # Labels of the template.
  --StartDate: string # Start date of the template (format: date-time)
  --EndDate: string # End date of the template (format: date-time)
  --BrandIds: list # BrandId(s) of the template.
  --SharedWithTeamId: list # The templates can be listed by the shared teams.
]: nothing -> record<pageDetails: record<pageSize: int, page: int, totalRecordsCount: int, totalPages: int, sortedColumn: string, sortDirection: string>, result: table<documentId: string, senderDetail: record, ccDetails: list, createdDate: int, activityDate: int, activityBy: string, messageTitle: string, status: string, signerDetails: list, enableSigningOrder: bool, templateName: string, templateDescription: string, accessType: string, accessTid: string, isTemplate: bool, behalfOf: record, templateLabels: list, labels: list, brandId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TemplateType" $TemplateType "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "SearchKey" $SearchKey "scalar") (serialize-qp "OnBehalfOf" $OnBehalfOf "multi") (serialize-qp "CreatedBy" $CreatedBy "multi") (serialize-qp "TemplateLabels" $TemplateLabels "multi") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "BrandIds" $BrandIds "multi") (serialize-qp "SharedWithTeamId" $SharedWithTeamId "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/template/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new template.
#
# POST /v1/template/create
# operationId: CreateTemplate
# --roles item shape: {name?: string, index: int, defaultSignerName?: string, defaultSignerEmail?: string, signerOrder?: int, signerType?: "Signer"|"Reviewer"|"InPersonSigner", hostEmail?: string, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", defaultGroupId?: string, imposeAuthentication?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", allowFieldConfiguration?: bool, formFields?: list, allowRoleEdit?: bool, allowRoleDelete?: bool, recipientNotificationSettings?: record, enableQes?: bool}
# --cc item shape: {emailAddress: string}
# --documentInfo item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
# --textTagDefinitions item shape: {definitionId: string, type: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", signerIndex: int, isRequired?: bool, placeholder?: string, fieldId?: string, font?: record, validation?: record, size?: record, dateFormat?: string, timeFormat?: string, radioGroupName?: string, groupName?: string, value?: string, dropdownOptions?: list, imageInfo?: record, hyperlinkText?: string, attachmentInfo?: record, backgroundHexColor?: string, isReadOnly?: bool, offset?: record, label?: string, tabIndex?: int, dataSyncTag?: string, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, characterLimit?: int, formulaFieldSettings?: record, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", collaborationSettings?: record, isMasked?: bool, conditionalRules?: list}
# --formGroups item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
# --recipientNotificationSettings shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
# --formFieldPermission shape: {canAdd?: bool, canModify?: bool, canModifyDefaultValue?: bool}
# --groupSignerSettings shape: {enabled?: bool, allowedDirectories?: list}
export def "template-create CreateTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string
  --description: string # nullable
  --documentTitle: string # nullable
  --documentMessage: string # nullable
  --files: list # nullable
  --fileUrls: list # nullable
  --roles: list # nullable — item shape: {name?: string, index: int, defaultSignerName?: string, defaultSignerEmail?: string, signerOrder?: int, signerType?: "Signer"|"Reviewer"|"InPersonSigner", hostEmail?: string, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", defaultGroupId?: string, imposeAuthentication?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", allowFieldConfiguration?: bool, formFields?: list, allowRoleEdit?: bool, allowRoleDelete?: bool, recipientNotificationSettings?: record, enableQes?: bool}
  --allowModifyFiles: oneof<nothing, bool> # default: true
  --cc: list # nullable — item shape: {emailAddress: string}
  --brandId: string # nullable
  --allowMessageEditing: oneof<nothing, bool> # default: true
  --allowNewRoles: oneof<nothing, bool> # default: true
  --allowNewFiles: oneof<nothing, bool> # default: true
  --enableReassign: oneof<nothing, bool> # default: true
  --enablePrintAndSign: oneof<nothing, bool> # default: false
  --enableSigningOrder: oneof<nothing, bool> # default: false
  --documentInfo: list # nullable — item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
  --useTextTags: oneof<nothing, bool> # default: false
  --textTagDefinitions: list # nullable — item shape: {definitionId: string, type: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", signerIndex: int, isRequired?: bool, placeholder?: string, fieldId?: string, font?: record, validation?: record, size?: record, dateFormat?: string, timeFormat?: string, radioGroupName?: string, groupName?: string, value?: string, dropdownOptions?: list, imageInfo?: record, hyperlinkText?: string, attachmentInfo?: record, backgroundHexColor?: string, isReadOnly?: bool, offset?: record, label?: string, tabIndex?: int, dataSyncTag?: string, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, characterLimit?: int, formulaFieldSettings?: record, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", collaborationSettings?: record, isMasked?: bool, conditionalRules?: list}
  --autoDetectFields: oneof<nothing, bool> # default: false
  --onBehalfOf: string # nullable
  --labels: list # nullable
  --templateLabels: list # nullable
  --formGroups: list # nullable — item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
  --recipientNotificationSettings: record # shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
  --allowedSignatureTypes: list # nullable
  --formFieldPermission: record # shape: {canAdd?: bool, canModify?: bool, canModifyDefaultValue?: bool}
  --groupSignerSettings: record # shape: {enabled?: bool, allowedDirectories?: list}
  --enableAllowSignEverywhere: oneof<nothing, bool> # nullable
  --documentTimeZone: string # nullable
]: any -> record<templateId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/template/create")
  let body = {title: $title, description: $description, documentTitle: $documentTitle, documentMessage: $documentMessage, files: $files, fileUrls: $fileUrls, roles: $roles, allowModifyFiles: $allowModifyFiles, cc: $cc, brandId: $brandId, allowMessageEditing: $allowMessageEditing, allowNewRoles: $allowNewRoles, allowNewFiles: $allowNewFiles, enableReassign: $enableReassign, enablePrintAndSign: $enablePrintAndSign, enableSigningOrder: $enableSigningOrder, documentInfo: $documentInfo, useTextTags: $useTextTags, textTagDefinitions: $textTagDefinitions, autoDetectFields: $autoDetectFields, onBehalfOf: $onBehalfOf, labels: $labels, templateLabels: $templateLabels, formGroups: $formGroups, recipientNotificationSettings: $recipientNotificationSettings, allowedSignatureTypes: $allowedSignatureTypes, formFieldPermission: $formFieldPermission, groupSignerSettings: $groupSignerSettings, enableAllowSignEverywhere: $enableAllowSignEverywhere, documentTimeZone: $documentTimeZone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generates a create URL to embeds template create process into your application.
#
# POST /v1/template/createEmbeddedTemplateUrl
# operationId: CreateEmbeddedTemplateUrl
# --roles item shape: {name?: string, index: int, defaultSignerName?: string, defaultSignerEmail?: string, signerOrder?: int, signerType?: "Signer"|"Reviewer"|"InPersonSigner", hostEmail?: string, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", defaultGroupId?: string, imposeAuthentication?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", allowFieldConfiguration?: bool, formFields?: list, allowRoleEdit?: bool, allowRoleDelete?: bool, recipientNotificationSettings?: record, enableQes?: bool}
# --cc item shape: {emailAddress: string}
# --documentInfo item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
# --textTagDefinitions item shape: {definitionId: string, type: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", signerIndex: int, isRequired?: bool, placeholder?: string, fieldId?: string, font?: record, validation?: record, size?: record, dateFormat?: string, timeFormat?: string, radioGroupName?: string, groupName?: string, value?: string, dropdownOptions?: list, imageInfo?: record, hyperlinkText?: string, attachmentInfo?: record, backgroundHexColor?: string, isReadOnly?: bool, offset?: record, label?: string, tabIndex?: int, dataSyncTag?: string, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, characterLimit?: int, formulaFieldSettings?: record, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", collaborationSettings?: record, isMasked?: bool, conditionalRules?: list}
# --formGroups item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
# --recipientNotificationSettings shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
# --formFieldPermission shape: {canAdd?: bool, canModify?: bool, canModifyDefaultValue?: bool}
# --groupSignerSettings shape: {enabled?: bool, allowedDirectories?: list}
@deprecated --flag showSendButton
export def "template-create-embedded-template-url CreateEmbeddedTemplateUrl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirectUrl: string # nullable, format: uri
  --showToolbar: oneof<nothing, bool> # default: false
  --viewOption: string@viewOption-completer # default: PreparePage
  --showSaveButton: oneof<nothing, bool> # default: true
  --locale: string@locale-completer # default: EN
  --showSendButton: oneof<nothing, bool> # DEPRECATED, nullable
  --showCreateButton: oneof<nothing, bool> # default: true
  --showPreviewButton: oneof<nothing, bool> # default: true
  --showNavigationButtons: oneof<nothing, bool> # default: true
  --linkValidTill: string # nullable, format: date-time
  --showTooltip: oneof<nothing, bool> # default: false
  title: string
  --description: string # nullable
  --documentTitle: string # nullable
  --documentMessage: string # nullable
  --files: list # nullable
  --fileUrls: list # nullable
  --roles: list # nullable — item shape: {name?: string, index: int, defaultSignerName?: string, defaultSignerEmail?: string, signerOrder?: int, signerType?: "Signer"|"Reviewer"|"InPersonSigner", hostEmail?: string, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", defaultGroupId?: string, imposeAuthentication?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", allowFieldConfiguration?: bool, formFields?: list, allowRoleEdit?: bool, allowRoleDelete?: bool, recipientNotificationSettings?: record, enableQes?: bool}
  --allowModifyFiles: oneof<nothing, bool> # default: true
  --cc: list # nullable — item shape: {emailAddress: string}
  --brandId: string # nullable
  --allowMessageEditing: oneof<nothing, bool> # default: true
  --allowNewRoles: oneof<nothing, bool> # default: true
  --allowNewFiles: oneof<nothing, bool> # default: true
  --enableReassign: oneof<nothing, bool> # default: true
  --enablePrintAndSign: oneof<nothing, bool> # default: false
  --enableSigningOrder: oneof<nothing, bool> # default: false
  --documentInfo: list # nullable — item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
  --useTextTags: oneof<nothing, bool> # default: false
  --textTagDefinitions: list # nullable — item shape: {definitionId: string, type: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", signerIndex: int, isRequired?: bool, placeholder?: string, fieldId?: string, font?: record, validation?: record, size?: record, dateFormat?: string, timeFormat?: string, radioGroupName?: string, groupName?: string, value?: string, dropdownOptions?: list, imageInfo?: record, hyperlinkText?: string, attachmentInfo?: record, backgroundHexColor?: string, isReadOnly?: bool, offset?: record, label?: string, tabIndex?: int, dataSyncTag?: string, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, characterLimit?: int, formulaFieldSettings?: record, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", collaborationSettings?: record, isMasked?: bool, conditionalRules?: list}
  --autoDetectFields: oneof<nothing, bool> # default: false
  --onBehalfOf: string # nullable
  --labels: list # nullable
  --templateLabels: list # nullable
  --formGroups: list # nullable — item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
  --recipientNotificationSettings: record # shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
  --allowedSignatureTypes: list # nullable
  --formFieldPermission: record # shape: {canAdd?: bool, canModify?: bool, canModifyDefaultValue?: bool}
  --groupSignerSettings: record # shape: {enabled?: bool, allowedDirectories?: list}
  --enableAllowSignEverywhere: oneof<nothing, bool> # nullable
  --documentTimeZone: string # nullable
]: any -> record<templateId: string, createUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/template/createEmbeddedTemplateUrl")
  let body = {redirectUrl: $redirectUrl, showToolbar: $showToolbar, viewOption: $viewOption, showSaveButton: $showSaveButton, locale: $locale, showSendButton: $showSendButton, showCreateButton: $showCreateButton, showPreviewButton: $showPreviewButton, showNavigationButtons: $showNavigationButtons, linkValidTill: $linkValidTill, showTooltip: $showTooltip, title: $title, description: $description, documentTitle: $documentTitle, documentMessage: $documentMessage, files: $files, fileUrls: $fileUrls, roles: $roles, allowModifyFiles: $allowModifyFiles, cc: $cc, brandId: $brandId, allowMessageEditing: $allowMessageEditing, allowNewRoles: $allowNewRoles, allowNewFiles: $allowNewFiles, enableReassign: $enableReassign, enablePrintAndSign: $enablePrintAndSign, enableSigningOrder: $enableSigningOrder, documentInfo: $documentInfo, useTextTags: $useTextTags, textTagDefinitions: $textTagDefinitions, autoDetectFields: $autoDetectFields, onBehalfOf: $onBehalfOf, labels: $labels, templateLabels: $templateLabels, formGroups: $formGroups, recipientNotificationSettings: $recipientNotificationSettings, allowedSignatureTypes: $allowedSignatureTypes, formFieldPermission: $formFieldPermission, groupSignerSettings: $groupSignerSettings, enableAllowSignEverywhere: $enableAllowSignEverywhere, documentTimeZone: $documentTimeZone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generates a edit URL to embeds template edit process into your application.
#
# POST /v1/template/getEmbeddedTemplateEditUrl
# operationId: getEmbeddedTemplateEditUrl
export def "template-get-embedded-template-edit-url post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --templateId: string
  --redirectUrl: string # nullable, format: uri
  --showToolbar: oneof<nothing, bool> # default: false
  --viewOption: string@viewOption-completer # default: PreparePage
  --showSaveButton: oneof<nothing, bool> # default: true
  --locale: string@locale-completer # default: EN
  --showCreateButton: oneof<nothing, bool> # default: true
  --showPreviewButton: oneof<nothing, bool> # default: true
  --showNavigationButtons: oneof<nothing, bool> # default: true
  --linkValidTill: string # nullable, format: date-time
  --showTooltip: oneof<nothing, bool> # default: false
  --onBehalfOf: string # nullable
]: any -> record<editUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/template/getEmbeddedTemplateEditUrl" $qp)
  let body = {redirectUrl: $redirectUrl, showToolbar: $showToolbar, viewOption: $viewOption, showSaveButton: $showSaveButton, locale: $locale, showCreateButton: $showCreateButton, showPreviewButton: $showPreviewButton, showNavigationButtons: $showNavigationButtons, linkValidTill: $linkValidTill, showTooltip: $showTooltip, onBehalfOf: $onBehalfOf} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a template.
#
# DELETE /v1/template/delete
# operationId: DeleteTemplate
export def "template-delete DeleteTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --templateId: string
  --onBehalfOf: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar") (serialize-qp "onBehalfOf" $onBehalfOf "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/template/delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send a document for signature using a Template.
#
# POST /v1/template/send
# operationId: SendUsingTemplate
# --roles item shape: {roleIndex?: int, signerName?: string, signerOrder?: int, signerEmail?: string, hostEmail?: string, privateMessage?: string, authenticationCode?: string, enableEmailOTP?: bool, authenticationType?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", signerType?: "Signer"|"Reviewer"|"InPersonSigner", signerRole?: string, allowFieldConfiguration?: bool, formFields?: list, existingFormFields?: list, identityVerificationSettings?: record, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", groupId?: string, recipientNotificationSettings?: record, authenticationRetryCount?: int, enableQes?: bool, authenticationSettings?: record}
# --reminderSettings shape: {enableAutoReminder?: bool, reminderDays?: int, reminderCount?: int}
# --cc item shape: {emailAddress: string}
# --documentInfo item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
# --formGroups item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
# --recipientNotificationSettings shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
# --groupSignerSettings shape: {enabled?: bool, allowedDirectories?: list}
@deprecated --flag expiryDays
export def "template-send SendUsingTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --templateId: string
  --files: list # nullable
  --fileUrls: list # nullable
  --documentId: string # nullable
  --title: string # nullable
  --message: string # nullable
  --roles: list # nullable — item shape: {roleIndex?: int, signerName?: string, signerOrder?: int, signerEmail?: string, hostEmail?: string, privateMessage?: string, authenticationCode?: string, enableEmailOTP?: bool, authenticationType?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", signerType?: "Signer"|"Reviewer"|"InPersonSigner", signerRole?: string, allowFieldConfiguration?: bool, formFields?: list, existingFormFields?: list, identityVerificationSettings?: record, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", groupId?: string, recipientNotificationSettings?: record, authenticationRetryCount?: int, enableQes?: bool, authenticationSettings?: record}
  --brandId: string # nullable
  --labels: list # nullable
  --disableEmails: oneof<nothing, bool>
  --disableSMS: oneof<nothing, bool> # default: false
  --hideDocumentId: oneof<nothing, bool> # nullable
  --reminderSettings: record # shape: {enableAutoReminder?: bool, reminderDays?: int, reminderCount?: int}
  --cc: list # nullable — item shape: {emailAddress: string}
  --expiryDays: int # DEPRECATED, format: int32
  --expiryDateType: string@expiryDateType-completer # nullable
  --expiryValue: int # format: int64, default: 60
  --enablePrintAndSign: oneof<nothing, bool>
  --enableReassign: oneof<nothing, bool> # nullable
  --enableSigningOrder: oneof<nothing, bool> # nullable
  --disableExpiryAlert: oneof<nothing, bool> # nullable
  --documentInfo: list # nullable — item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
  --onBehalfOf: string # nullable
  --isSandbox: oneof<nothing, bool> # nullable
  --roleRemovalIndices: list # nullable
  --documentDownloadOption: string@documentDownloadOption-completer # nullable
  --metaData: record # nullable
  --formGroups: list # nullable — item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
  --removeFormFields: list # nullable
  --recipientNotificationSettings: record # shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
  --enableAuditTrailLocalization: oneof<nothing, bool> # nullable
  --downloadFileName: string # nullable
  --scheduledSendTime: int # nullable, format: int64
  --allowScheduledSend: oneof<nothing, bool> # default: false
  --allowedSignatureTypes: list # nullable
  --groupSignerSettings: record # shape: {enabled?: bool, allowedDirectories?: list}
  --enableAllowSignEverywhere: oneof<nothing, bool> # nullable
  --documentTimeZone: string # nullable
]: any -> record<documentId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/template/send" $qp)
  let body = {files: $files, fileUrls: $fileUrls, documentId: $documentId, title: $title, message: $message, roles: $roles, brandId: $brandId, labels: $labels, disableEmails: $disableEmails, disableSMS: $disableSMS, hideDocumentId: $hideDocumentId, reminderSettings: $reminderSettings, cc: $cc, expiryDays: $expiryDays, expiryDateType: $expiryDateType, expiryValue: $expiryValue, enablePrintAndSign: $enablePrintAndSign, enableReassign: $enableReassign, enableSigningOrder: $enableSigningOrder, disableExpiryAlert: $disableExpiryAlert, documentInfo: $documentInfo, onBehalfOf: $onBehalfOf, isSandbox: $isSandbox, roleRemovalIndices: $roleRemovalIndices, documentDownloadOption: $documentDownloadOption, metaData: $metaData, formGroups: $formGroups, removeFormFields: $removeFormFields, recipientNotificationSettings: $recipientNotificationSettings, enableAuditTrailLocalization: $enableAuditTrailLocalization, downloadFileName: $downloadFileName, scheduledSendTime: $scheduledSendTime, allowScheduledSend: $allowScheduledSend, allowedSignatureTypes: $allowedSignatureTypes, groupSignerSettings: $groupSignerSettings, enableAllowSignEverywhere: $enableAllowSignEverywhere, documentTimeZone: $documentTimeZone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send the document by merging multiple templates.
#
# POST /v1/template/mergeAndSend
# operationId: MergeAndSend
# --textTagDefinitions item shape: {definitionId: string, type: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", signerIndex: int, isRequired?: bool, placeholder?: string, fieldId?: string, font?: record, validation?: record, size?: record, dateFormat?: string, timeFormat?: string, radioGroupName?: string, groupName?: string, value?: string, dropdownOptions?: list, imageInfo?: record, hyperlinkText?: string, attachmentInfo?: record, backgroundHexColor?: string, isReadOnly?: bool, offset?: record, label?: string, tabIndex?: int, dataSyncTag?: string, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, characterLimit?: int, formulaFieldSettings?: record, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", collaborationSettings?: record, isMasked?: bool, conditionalRules?: list}
# --roles item shape: {roleIndex?: int, signerName?: string, signerOrder?: int, signerEmail?: string, hostEmail?: string, privateMessage?: string, authenticationCode?: string, enableEmailOTP?: bool, authenticationType?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", signerType?: "Signer"|"Reviewer"|"InPersonSigner", signerRole?: string, allowFieldConfiguration?: bool, formFields?: list, existingFormFields?: list, identityVerificationSettings?: record, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", groupId?: string, recipientNotificationSettings?: record, authenticationRetryCount?: int, enableQes?: bool, authenticationSettings?: record}
# --reminderSettings shape: {enableAutoReminder?: bool, reminderDays?: int, reminderCount?: int}
# --cc item shape: {emailAddress: string}
# --documentInfo item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
# --formGroups item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
# --recipientNotificationSettings shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
# --groupSignerSettings shape: {enabled?: bool, allowedDirectories?: list}
@deprecated --flag expiryDays
export def "template-merge-and-send MergeAndSend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list # nullable
  --fileUrls: list # nullable
  --templateIds: list # nullable
  --useTextTags: oneof<nothing, bool>
  --textTagDefinitions: list # nullable — item shape: {definitionId: string, type: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", signerIndex: int, isRequired?: bool, placeholder?: string, fieldId?: string, font?: record, validation?: record, size?: record, dateFormat?: string, timeFormat?: string, radioGroupName?: string, groupName?: string, value?: string, dropdownOptions?: list, imageInfo?: record, hyperlinkText?: string, attachmentInfo?: record, backgroundHexColor?: string, isReadOnly?: bool, offset?: record, label?: string, tabIndex?: int, dataSyncTag?: string, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, characterLimit?: int, formulaFieldSettings?: record, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", collaborationSettings?: record, isMasked?: bool, conditionalRules?: list}
  --documentId: string # nullable
  --title: string # nullable
  --message: string # nullable
  --roles: list # nullable — item shape: {roleIndex?: int, signerName?: string, signerOrder?: int, signerEmail?: string, hostEmail?: string, privateMessage?: string, authenticationCode?: string, enableEmailOTP?: bool, authenticationType?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", signerType?: "Signer"|"Reviewer"|"InPersonSigner", signerRole?: string, allowFieldConfiguration?: bool, formFields?: list, existingFormFields?: list, identityVerificationSettings?: record, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", groupId?: string, recipientNotificationSettings?: record, authenticationRetryCount?: int, enableQes?: bool, authenticationSettings?: record}
  --brandId: string # nullable
  --labels: list # nullable
  --disableEmails: oneof<nothing, bool>
  --disableSMS: oneof<nothing, bool> # default: false
  --hideDocumentId: oneof<nothing, bool> # nullable
  --reminderSettings: record # shape: {enableAutoReminder?: bool, reminderDays?: int, reminderCount?: int}
  --cc: list # nullable — item shape: {emailAddress: string}
  --expiryDays: int # DEPRECATED, format: int32
  --expiryDateType: string@expiryDateType-completer # nullable
  --expiryValue: int # format: int64, default: 60
  --enablePrintAndSign: oneof<nothing, bool>
  --enableReassign: oneof<nothing, bool> # nullable
  --enableSigningOrder: oneof<nothing, bool> # nullable
  --disableExpiryAlert: oneof<nothing, bool> # nullable
  --documentInfo: list # nullable — item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
  --onBehalfOf: string # nullable
  --isSandbox: oneof<nothing, bool> # nullable
  --roleRemovalIndices: list # nullable
  --documentDownloadOption: string@documentDownloadOption-completer # nullable
  --metaData: record # nullable
  --formGroups: list # nullable — item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
  --removeFormFields: list # nullable
  --recipientNotificationSettings: record # shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
  --enableAuditTrailLocalization: oneof<nothing, bool> # nullable
  --downloadFileName: string # nullable
  --scheduledSendTime: int # nullable, format: int64
  --allowScheduledSend: oneof<nothing, bool> # default: false
  --allowedSignatureTypes: list # nullable
  --groupSignerSettings: record # shape: {enabled?: bool, allowedDirectories?: list}
  --enableAllowSignEverywhere: oneof<nothing, bool> # nullable
  --documentTimeZone: string # nullable
]: any -> record<documentId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/template/mergeAndSend")
  let body = {files: $files, fileUrls: $fileUrls, templateIds: $templateIds, useTextTags: $useTextTags, textTagDefinitions: $textTagDefinitions, documentId: $documentId, title: $title, message: $message, roles: $roles, brandId: $brandId, labels: $labels, disableEmails: $disableEmails, disableSMS: $disableSMS, hideDocumentId: $hideDocumentId, reminderSettings: $reminderSettings, cc: $cc, expiryDays: $expiryDays, expiryDateType: $expiryDateType, expiryValue: $expiryValue, enablePrintAndSign: $enablePrintAndSign, enableReassign: $enableReassign, enableSigningOrder: $enableSigningOrder, disableExpiryAlert: $disableExpiryAlert, documentInfo: $documentInfo, onBehalfOf: $onBehalfOf, isSandbox: $isSandbox, roleRemovalIndices: $roleRemovalIndices, documentDownloadOption: $documentDownloadOption, metaData: $metaData, formGroups: $formGroups, removeFormFields: $removeFormFields, recipientNotificationSettings: $recipientNotificationSettings, enableAuditTrailLocalization: $enableAuditTrailLocalization, downloadFileName: $downloadFileName, scheduledSendTime: $scheduledSendTime, allowScheduledSend: $allowScheduledSend, allowedSignatureTypes: $allowedSignatureTypes, groupSignerSettings: $groupSignerSettings, enableAllowSignEverywhere: $enableAllowSignEverywhere, documentTimeZone: $documentTimeZone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generates a send URL using a template which embeds document sending process into your application.
#
# POST /v1/template/createEmbeddedRequestUrl
# operationId: CreateEmbeddedRequestUrlTemplate
# --roles item shape: {roleIndex?: int, signerName?: string, signerOrder?: int, signerEmail?: string, hostEmail?: string, privateMessage?: string, authenticationCode?: string, enableEmailOTP?: bool, authenticationType?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", signerType?: "Signer"|"Reviewer"|"InPersonSigner", signerRole?: string, allowFieldConfiguration?: bool, formFields?: list, existingFormFields?: list, identityVerificationSettings?: record, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", groupId?: string, recipientNotificationSettings?: record, authenticationRetryCount?: int, enableQes?: bool, authenticationSettings?: record}
# --reminderSettings shape: {enableAutoReminder?: bool, reminderDays?: int, reminderCount?: int}
# --cc item shape: {emailAddress: string}
# --documentInfo item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
# --formGroups item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
# --recipientNotificationSettings shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
# --groupSignerSettings shape: {enabled?: bool, allowedDirectories?: list}
@deprecated --flag expiryDays
export def "template-create-embedded-request-url CreateEmbeddedRequestUrlTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --templateId: string
  --files: list # nullable
  --fileUrls: list # nullable
  --redirectUrl: string # nullable, format: uri
  --showToolbar: oneof<nothing, bool>
  --sendViewOption: string@sendViewOption-completer
  --showSaveButton: oneof<nothing, bool>
  --locale: string@locale-completer
  --showSendButton: oneof<nothing, bool>
  --showPreviewButton: oneof<nothing, bool>
  --showNavigationButtons: oneof<nothing, bool>
  --sendLinkValidTill: string # nullable, format: date-time
  --showTooltip: oneof<nothing, bool>
  --documentId: string # nullable
  --title: string # nullable
  --message: string # nullable
  --roles: list # nullable — item shape: {roleIndex?: int, signerName?: string, signerOrder?: int, signerEmail?: string, hostEmail?: string, privateMessage?: string, authenticationCode?: string, enableEmailOTP?: bool, authenticationType?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", signerType?: "Signer"|"Reviewer"|"InPersonSigner", signerRole?: string, allowFieldConfiguration?: bool, formFields?: list, existingFormFields?: list, identityVerificationSettings?: record, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", groupId?: string, recipientNotificationSettings?: record, authenticationRetryCount?: int, enableQes?: bool, authenticationSettings?: record}
  --brandId: string # nullable
  --labels: list # nullable
  --disableEmails: oneof<nothing, bool>
  --disableSMS: oneof<nothing, bool> # default: false
  --hideDocumentId: oneof<nothing, bool> # nullable
  --reminderSettings: record # shape: {enableAutoReminder?: bool, reminderDays?: int, reminderCount?: int}
  --cc: list # nullable — item shape: {emailAddress: string}
  --expiryDays: int # DEPRECATED, format: int32
  --expiryDateType: string@expiryDateType-completer # nullable
  --expiryValue: int # format: int64, default: 60
  --enablePrintAndSign: oneof<nothing, bool>
  --enableReassign: oneof<nothing, bool> # nullable
  --enableSigningOrder: oneof<nothing, bool> # nullable
  --disableExpiryAlert: oneof<nothing, bool> # nullable
  --documentInfo: list # nullable — item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
  --onBehalfOf: string # nullable
  --isSandbox: oneof<nothing, bool> # nullable
  --roleRemovalIndices: list # nullable
  --documentDownloadOption: string@documentDownloadOption-completer # nullable
  --metaData: record # nullable
  --formGroups: list # nullable — item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
  --removeFormFields: list # nullable
  --recipientNotificationSettings: record # shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
  --enableAuditTrailLocalization: oneof<nothing, bool> # nullable
  --downloadFileName: string # nullable
  --scheduledSendTime: int # nullable, format: int64
  --allowScheduledSend: oneof<nothing, bool> # default: false
  --allowedSignatureTypes: list # nullable
  --groupSignerSettings: record # shape: {enabled?: bool, allowedDirectories?: list}
  --enableAllowSignEverywhere: oneof<nothing, bool> # nullable
  --documentTimeZone: string # nullable
]: any -> record<documentId: string, sendUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/template/createEmbeddedRequestUrl" $qp)
  let body = {files: $files, fileUrls: $fileUrls, redirectUrl: $redirectUrl, showToolbar: $showToolbar, sendViewOption: $sendViewOption, showSaveButton: $showSaveButton, locale: $locale, showSendButton: $showSendButton, showPreviewButton: $showPreviewButton, showNavigationButtons: $showNavigationButtons, sendLinkValidTill: $sendLinkValidTill, showTooltip: $showTooltip, documentId: $documentId, title: $title, message: $message, roles: $roles, brandId: $brandId, labels: $labels, disableEmails: $disableEmails, disableSMS: $disableSMS, hideDocumentId: $hideDocumentId, reminderSettings: $reminderSettings, cc: $cc, expiryDays: $expiryDays, expiryDateType: $expiryDateType, expiryValue: $expiryValue, enablePrintAndSign: $enablePrintAndSign, enableReassign: $enableReassign, enableSigningOrder: $enableSigningOrder, disableExpiryAlert: $disableExpiryAlert, documentInfo: $documentInfo, onBehalfOf: $onBehalfOf, isSandbox: $isSandbox, roleRemovalIndices: $roleRemovalIndices, documentDownloadOption: $documentDownloadOption, metaData: $metaData, formGroups: $formGroups, removeFormFields: $removeFormFields, recipientNotificationSettings: $recipientNotificationSettings, enableAuditTrailLocalization: $enableAuditTrailLocalization, downloadFileName: $downloadFileName, scheduledSendTime: $scheduledSendTime, allowScheduledSend: $allowScheduledSend, allowedSignatureTypes: $allowedSignatureTypes, groupSignerSettings: $groupSignerSettings, enableAllowSignEverywhere: $enableAllowSignEverywhere, documentTimeZone: $documentTimeZone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generates a merge request URL using a template that combines document merging and sending processes into your application.
#
# POST /v1/template/mergeCreateEmbeddedRequestUrl
# operationId: MergeCreateEmbeddedRequestUrlTemplate
# --textTagDefinitions item shape: {definitionId: string, type: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", signerIndex: int, isRequired?: bool, placeholder?: string, fieldId?: string, font?: record, validation?: record, size?: record, dateFormat?: string, timeFormat?: string, radioGroupName?: string, groupName?: string, value?: string, dropdownOptions?: list, imageInfo?: record, hyperlinkText?: string, attachmentInfo?: record, backgroundHexColor?: string, isReadOnly?: bool, offset?: record, label?: string, tabIndex?: int, dataSyncTag?: string, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, characterLimit?: int, formulaFieldSettings?: record, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", collaborationSettings?: record, isMasked?: bool, conditionalRules?: list}
# --roles item shape: {roleIndex?: int, signerName?: string, signerOrder?: int, signerEmail?: string, hostEmail?: string, privateMessage?: string, authenticationCode?: string, enableEmailOTP?: bool, authenticationType?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", signerType?: "Signer"|"Reviewer"|"InPersonSigner", signerRole?: string, allowFieldConfiguration?: bool, formFields?: list, existingFormFields?: list, identityVerificationSettings?: record, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", groupId?: string, recipientNotificationSettings?: record, authenticationRetryCount?: int, enableQes?: bool, authenticationSettings?: record}
# --reminderSettings shape: {enableAutoReminder?: bool, reminderDays?: int, reminderCount?: int}
# --cc item shape: {emailAddress: string}
# --documentInfo item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
# --formGroups item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
# --recipientNotificationSettings shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
# --groupSignerSettings shape: {enabled?: bool, allowedDirectories?: list}
@deprecated --flag expiryDays
export def "template-merge-create-embedded-request-url MergeCreateEmbeddedRequestUrlTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list # nullable
  --fileUrls: list # nullable
  --redirectUrl: string # nullable, format: uri
  --showToolbar: oneof<nothing, bool>
  --sendViewOption: string@sendViewOption-completer
  --showSaveButton: oneof<nothing, bool>
  --locale: string@locale-completer
  --showSendButton: oneof<nothing, bool>
  --showPreviewButton: oneof<nothing, bool>
  --showNavigationButtons: oneof<nothing, bool>
  --sendLinkValidTill: string # nullable, format: date-time
  --showTooltip: oneof<nothing, bool>
  --templateIds: list # nullable
  --useTextTags: oneof<nothing, bool>
  --textTagDefinitions: list # nullable — item shape: {definitionId: string, type: "Signature"|"Initial"|"CheckBox"|"TextBox"|"Label"|"DateSigned"|"RadioButton"|"Image"|"Attachment"|"EditableDate"|"Hyperlink"|"Dropdown"|"Title"|"Company"|"Formula"|"Drawing", signerIndex: int, isRequired?: bool, placeholder?: string, fieldId?: string, font?: record, validation?: record, size?: record, dateFormat?: string, timeFormat?: string, radioGroupName?: string, groupName?: string, value?: string, dropdownOptions?: list, imageInfo?: record, hyperlinkText?: string, attachmentInfo?: record, backgroundHexColor?: string, isReadOnly?: bool, offset?: record, label?: string, tabIndex?: int, dataSyncTag?: string, textAlign?: "Left"|"Center"|"Right", textDirection?: "LTR"|"RTL", characterSpacing?: float, characterLimit?: int, formulaFieldSettings?: record, resizeOption?: "GrowVertically"|"GrowHorizontally"|"GrowBoth"|"Fixed"|"AutoResizeFont", collaborationSettings?: record, isMasked?: bool, conditionalRules?: list}
  --documentId: string # nullable
  --title: string # nullable
  --message: string # nullable
  --roles: list # nullable — item shape: {roleIndex?: int, signerName?: string, signerOrder?: int, signerEmail?: string, hostEmail?: string, privateMessage?: string, authenticationCode?: string, enableEmailOTP?: bool, authenticationType?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", signerType?: "Signer"|"Reviewer"|"InPersonSigner", signerRole?: string, allowFieldConfiguration?: bool, formFields?: list, existingFormFields?: list, identityVerificationSettings?: record, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", groupId?: string, recipientNotificationSettings?: record, authenticationRetryCount?: int, enableQes?: bool, authenticationSettings?: record}
  --brandId: string # nullable
  --labels: list # nullable
  --disableEmails: oneof<nothing, bool>
  --disableSMS: oneof<nothing, bool> # default: false
  --hideDocumentId: oneof<nothing, bool> # nullable
  --reminderSettings: record # shape: {enableAutoReminder?: bool, reminderDays?: int, reminderCount?: int}
  --cc: list # nullable — item shape: {emailAddress: string}
  --expiryDays: int # DEPRECATED, format: int32
  --expiryDateType: string@expiryDateType-completer # nullable
  --expiryValue: int # format: int64, default: 60
  --enablePrintAndSign: oneof<nothing, bool>
  --enableReassign: oneof<nothing, bool> # nullable
  --enableSigningOrder: oneof<nothing, bool> # nullable
  --disableExpiryAlert: oneof<nothing, bool> # nullable
  --documentInfo: list # nullable — item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
  --onBehalfOf: string # nullable
  --isSandbox: oneof<nothing, bool> # nullable
  --roleRemovalIndices: list # nullable
  --documentDownloadOption: string@documentDownloadOption-completer # nullable
  --metaData: record # nullable
  --formGroups: list # nullable — item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
  --removeFormFields: list # nullable
  --recipientNotificationSettings: record # shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
  --enableAuditTrailLocalization: oneof<nothing, bool> # nullable
  --downloadFileName: string # nullable
  --scheduledSendTime: int # nullable, format: int64
  --allowScheduledSend: oneof<nothing, bool> # default: false
  --allowedSignatureTypes: list # nullable
  --groupSignerSettings: record # shape: {enabled?: bool, allowedDirectories?: list}
  --enableAllowSignEverywhere: oneof<nothing, bool> # nullable
  --documentTimeZone: string # nullable
]: any -> record<documentId: string, sendUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/template/mergeCreateEmbeddedRequestUrl")
  let body = {files: $files, fileUrls: $fileUrls, redirectUrl: $redirectUrl, showToolbar: $showToolbar, sendViewOption: $sendViewOption, showSaveButton: $showSaveButton, locale: $locale, showSendButton: $showSendButton, showPreviewButton: $showPreviewButton, showNavigationButtons: $showNavigationButtons, sendLinkValidTill: $sendLinkValidTill, showTooltip: $showTooltip, templateIds: $templateIds, useTextTags: $useTextTags, textTagDefinitions: $textTagDefinitions, documentId: $documentId, title: $title, message: $message, roles: $roles, brandId: $brandId, labels: $labels, disableEmails: $disableEmails, disableSMS: $disableSMS, hideDocumentId: $hideDocumentId, reminderSettings: $reminderSettings, cc: $cc, expiryDays: $expiryDays, expiryDateType: $expiryDateType, expiryValue: $expiryValue, enablePrintAndSign: $enablePrintAndSign, enableReassign: $enableReassign, enableSigningOrder: $enableSigningOrder, disableExpiryAlert: $disableExpiryAlert, documentInfo: $documentInfo, onBehalfOf: $onBehalfOf, isSandbox: $isSandbox, roleRemovalIndices: $roleRemovalIndices, documentDownloadOption: $documentDownloadOption, metaData: $metaData, formGroups: $formGroups, removeFormFields: $removeFormFields, recipientNotificationSettings: $recipientNotificationSettings, enableAuditTrailLocalization: $enableAuditTrailLocalization, downloadFileName: $downloadFileName, scheduledSendTime: $scheduledSendTime, allowScheduledSend: $allowScheduledSend, allowedSignatureTypes: $allowedSignatureTypes, groupSignerSettings: $groupSignerSettings, enableAllowSignEverywhere: $enableAllowSignEverywhere, documentTimeZone: $documentTimeZone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get summary of the template.
#
# GET /v1/template/properties
# operationId: GetTemplateProperties
export def "template-properties GetTemplateProperties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --templateId: string
]: nothing -> record<templateId: string, title: string, description: string, documentTitle: string, documentMessage: string, files: table<documentId: string, documentName: string, order: int, pageCount: int>, roles: table<name: string, index: int, defaultSignerName: string, defaultSignerEmail: string, phoneNumber: record, signerOrder: int, signerType: string, hostEmail: string, hostName: string, language: int, locale: string, signType: string, defaultGroupId: string, allowRoleEdit: bool, allowRoleDelete: bool, enableAccessCode: bool, enableEmailOTP: bool, imposeAuthentication: string, deliveryMode: string, allowFieldConfiguration: bool, formFields: list, enableEditRecipients: bool, enableDeleteRecipients: bool, recipientNotificationSettings: record, enableQes: bool, groupSigners: list>, formGroups: table<minimumCount: int, maximumCount: int, dataSyncTag: string, groupNames: list, groupValidation: string>, commonFields: table<id: string, fieldType: string, type: string, value: string, font: string, isRequired: bool, isReadOnly: bool, lineHeight: int, fontSize: int, fontHexColor: string, isUnderLineFont: bool, isItalicFont: bool, isBoldFont: bool, groupName: string, label: string, placeholder: string, validationtype: string, validationCustomRegex: string, validationCustomRegexMessage: string, dateFormat: string, timeFormat: string, imageInfo: record, attachmentInfo: record, editableDateFieldSettings: record, dropdownOptions: list, bounds: record, pageNumber: int, conditionalRules: list, dataSyncTag: string, textAlign: string, textDirection: string, characterSpacing: float, characterLimit: int, hyperlinkText: string, backgroundHexColor: string, tabIndex: int, formulaFieldSettings: record, resizeOption: string, allowEditFormField: bool, allowDeleteFormField: bool, collaborationSettings: record, isMasked: bool, isDefaultValueRequired: bool>, cCDetails: list<string>, brandId: string, allowMessageEditing: bool, allowNewRoles: bool, allowNewFiles: bool, allowModifyFiles: bool, enableReassign: bool, EnablePrintAndSign: bool, enableSigningOrder: bool, createdDate: int, createdBy: record<emailAddress: string, name: string>, sharedTemplateDetail: table<teamId: string, accessType: string>, documentInfo: table<language: int, locale: string, title: string, description: string>, labels: list<string>, templateLabels: list<string>, behalfOf: record<name: string, emailAddress: string>, documentDownloadOption: string, recipientNotificationSettings: record<signatureRequest: bool, declined: bool, revoked: bool, signed: bool, completed: bool, expired: bool, reassigned: bool, deleted: bool, reminders: bool, editRecipient: bool, editDocument: bool, viewed: bool>, formFieldPermission: record<canAdd: bool, canModify: bool, canModifyDefaultValue: bool>, allowedSignatureTypes: list<string>, groupSignerSettings: record<enabled: bool, allowedDirectories: list<string>>, sharing: record<teams: list<record>>, enableAllowSignEverywhere: bool, documentTimeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/template/properties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download the template.
#
# GET /v1/template/download
# operationId: Download
export def "template-download Download" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --templateId: string
  --onBehalfOf: string
  --includeFormFieldValues: oneof<nothing, bool> # default: false
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar") (serialize-qp "onBehalfOf" $onBehalfOf "scalar") (serialize-qp "includeFormFieldValues" $includeFormFieldValues "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/template/download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit and updates an existing template.
#
# PUT /v1/template/edit
# operationId: EditTemplate
# --roles item shape: {name?: string, index: int, defaultSignerName?: string, defaultSignerEmail?: string, signerOrder?: int, signerType?: "Signer"|"Reviewer"|"InPersonSigner", hostEmail?: string, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", defaultGroupId?: string, imposeAuthentication?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", allowFieldConfiguration?: bool, formFields?: list, allowRoleEdit?: bool, allowRoleDelete?: bool, recipientNotificationSettings?: record, enableQes?: bool}
# --cc item shape: {emailAddress: string}
# --documentInfo item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
# --formGroups item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
# --recipientNotificationSettings shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
# --formFieldPermission shape: {canAdd?: bool, canModify?: bool, canModifyDefaultValue?: bool}
# --groupSignerSettings shape: {enabled?: bool, allowedDirectories?: list}
export def "template-edit EditTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --templateId: string
  --title: string # nullable
  --description: string # nullable
  --documentTitle: string # nullable
  --documentMessage: string # nullable
  --roles: list # nullable — item shape: {name?: string, index: int, defaultSignerName?: string, defaultSignerEmail?: string, signerOrder?: int, signerType?: "Signer"|"Reviewer"|"InPersonSigner", hostEmail?: string, language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale?: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", signType?: "Single"|"Group", defaultGroupId?: string, imposeAuthentication?: "None"|"EmailOTP"|"AccessCode"|"SMSOTP"|"IdVerification", phoneNumber?: record, deliveryMode?: "Email"|"SMS"|"EmailAndSMS"|"WhatsApp", allowFieldConfiguration?: bool, formFields?: list, allowRoleEdit?: bool, allowRoleDelete?: bool, recipientNotificationSettings?: record, enableQes?: bool}
  --cc: list # nullable — item shape: {emailAddress: string}
  --brandId: string # nullable
  --allowMessageEditing: oneof<nothing, bool> # nullable
  --allowNewRoles: oneof<nothing, bool> # nullable
  --allowNewFiles: oneof<nothing, bool> # nullable
  --allowModifyFiles: oneof<nothing, bool> # nullable
  --enableReassign: oneof<nothing, bool> # nullable
  --enablePrintAndSign: oneof<nothing, bool> # nullable
  --enableSigningOrder: oneof<nothing, bool> # nullable
  --documentInfo: list # nullable — item shape: {language?: "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20", locale: "EN"|"NO"|"FR"|"DE"|"ES"|"BG"|"CS"|"DA"|"IT"|"NL"|"PL"|"PT"|"RO"|"RU"|"SV"|"Default"|"JA"|"TH"|"ZH_CN"|"ZH_TW"|"KO", title: string, description?: string}
  --onBehalfOf: string # nullable
  --labels: list # nullable
  --templateLabels: list # nullable
  --formGroups: list # nullable — item shape: {minimumCount?: int, maximumCount?: int, dataSyncTag?: string, groupNames: list, groupValidation: "Minimum"|"Maximum"|"Absolute"|"Range"}
  --recipientNotificationSettings: record # shape: {signatureRequest?: bool, declined?: bool, revoked?: bool, signed?: bool, completed?: bool, expired?: bool, reassigned?: bool, deleted?: bool, reminders?: bool, editRecipient?: bool, editDocument?: bool, viewed?: bool}
  --allowedSignatureTypes: list # nullable
  --formFieldPermission: record # shape: {canAdd?: bool, canModify?: bool, canModifyDefaultValue?: bool}
  --groupSignerSettings: record # shape: {enabled?: bool, allowedDirectories?: list}
  --enableAllowSignEverywhere: oneof<nothing, bool> # nullable
  --documentTimeZone: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/template/edit" $qp)
  let body = {title: $title, description: $description, documentTitle: $documentTitle, documentMessage: $documentMessage, roles: $roles, cc: $cc, brandId: $brandId, allowMessageEditing: $allowMessageEditing, allowNewRoles: $allowNewRoles, allowNewFiles: $allowNewFiles, allowModifyFiles: $allowModifyFiles, enableReassign: $enableReassign, enablePrintAndSign: $enablePrintAndSign, enableSigningOrder: $enableSigningOrder, documentInfo: $documentInfo, onBehalfOf: $onBehalfOf, labels: $labels, templateLabels: $templateLabels, formGroups: $formGroups, recipientNotificationSettings: $recipientNotificationSettings, allowedSignatureTypes: $allowedSignatureTypes, formFieldPermission: $formFieldPermission, groupSignerSettings: $groupSignerSettings, enableAllowSignEverywhere: $enableAllowSignEverywhere, documentTimeZone: $documentTimeZone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add the Tags in Templates.
#
# PATCH /v1/template/addTags
# operationId: AddTemplateTag
export def "template-add-tags AddTemplateTag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  templateId: string
  --documentLabels: list # nullable
  --templateLabels: list # nullable
  --onBehalfOf: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/template/addTags")
  let body = {templateId: $templateId, documentLabels: $documentLabels, templateLabels: $templateLabels, onBehalfOf: $onBehalfOf} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Tags in Templates.
#
# DELETE /v1/template/deleteTags
# operationId: DeleteTemplateTag
export def "template-delete-tags DeleteTemplateTag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  templateId: string
  --documentLabels: list # nullable
  --templateLabels: list # nullable
  --onBehalfOf: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/template/deleteTags")
  let body = {templateId: $templateId, documentLabels: $documentLabels, templateLabels: $templateLabels, onBehalfOf: $onBehalfOf} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Share a template with teams and manage permissions.
#
# PATCH /v1/template/share
# operationId: ShareTemplate
# --teams item shape: {teamId: string, action: "Grant"|"Revoke", accessLevel?: "Use"|"Edit"}
export def "template-share ShareTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --templateId: string
  --teams: list # nullable — item shape: {teamId: string, action: "Grant"|"Revoke", accessLevel?: "Use"|"Edit"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/template/share" $qp)
  let body = {teams: $teams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generates a preview URL for a template to view it.
#
# POST /v1/template/createEmbeddedPreviewUrl
# operationId: createEmbeddedPreviewUrl
export def "template-create-embedded-preview-url createEmbeddedPreviewUrl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --templateId: string
  --linkValidTill: string # nullable, format: date-time
  --showToolbar: oneof<nothing, bool>
]: any -> record<templateUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateId" $templateId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/template/createEmbeddedPreviewUrl" $qp)
  let body = {linkValidTill: $linkValidTill, showToolbar: $showToolbar} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create the user.
#
# POST /v1/users/create
# operationId: CreateUser
export def "users-create CreateUser" [
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
  let full_url = (build-url $base "/v1/users/create")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update new User role.
#
# PUT /v1/users/update
# operationId: UpdateUser
export def "users-update UpdateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string
  --userRole: string@userRole-completer
  --userStatus: string@userStatus-completer
  --toUserId: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/update")
  let body = {userId: $userId, userRole: $userRole, userStatus: $userStatus, toUserId: $toUserId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resend the users invitation.
#
# POST /v1/users/resendInvitation
# operationId: ResendInvitation
export def "users-resend-invitation ResendInvitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --UserId: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UserId" $UserId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/users/resendInvitation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel the users invitation.
#
# POST /v1/users/cancelInvitation
# operationId: CancelInvitation
export def "users-cancel-invitation CancelInvitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --UserId: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "UserId" $UserId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/users/cancelInvitation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List user documents.
#
# GET /v1/users/list
# operationId: ListUsers
export def "users-list ListUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # Page size specified in get user list request. (format: int32, default: 10)
  --Page: int # Page index specified in get user list request. (format: int32, default: 1)
  --Search: string # Users can be listed by the search  based on the user ID
  --UserId: list # Users can be listed by the search based on the user IDs
]: nothing -> record<pageDetails: record<pageSize: int, page: int>, result: table<userId: string, email: string, firstName: string, lastName: string, teamId: string, teamName: string, role: string, userStatus: string, createdDate: int, modifiedDate: int, metaData: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "Search" $Search "scalar") (serialize-qp "UserId" $UserId "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/users/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get summary of the user.
#
# GET /v1/users/get
# operationId: GetUser
export def "users-get GetUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userId: string
]: nothing -> record<userId: string, email: string, firstName: string, lastName: string, teamId: string, teamName: string, role: string, userStatus: string, createdDate: int, modifiedDate: int, metaData: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/users/get" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update new User meta data details.
#
# PUT /v1/users/updateMetaData
# operationId: updateMetaData
export def "users-update-meta-data updateMetaData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userId: string
  metaData: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/updateMetaData")
  let body = {userId: $userId, metaData: $metaData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change users to other team.
#
# PUT /v1/users/changeTeam
# operationId: ChangeTeam
export def "users-change-team ChangeTeam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userId: string
  toTeamId: string
  --transferDocumentsToUserId: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/users/changeTeam" $qp)
  let body = {toTeamId: $toTeamId, transferDocumentsToUserId: $transferDocumentsToUserId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
