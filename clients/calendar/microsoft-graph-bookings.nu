# Auto-generated client for Bookings vv1.0
# Source: https://raw.githubusercontent.com/microsoftgraph/msgraph-sdk-powershell/main/openApiDocs/v1.0/Bookings.yml
# Auth: --token flag or $env.BOOKINGS_TOKEN

const BASE_URL = "https://graph.microsoft.com/v1.0"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BOOKINGS_TOKEN | default "" }
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
def base-url-completer [] { ["https://graph.microsoft.com/v1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def priceType-completer [] { ["callUs" "fixedPrice" "free" "hourly" "notSet" "priceVaries" "startingAt" "undefined" "unknownFutureValue"] }
def answerInputType-completer [] { ["radioButton" "text" "unknownFutureValue"] }
def defaultPriceType-completer [] { ["callUs" "fixedPrice" "free" "hourly" "notSet" "priceVaries" "startingAt" "undefined" "unknownFutureValue"] }
def status-completer [] { ["canceled" "draft" "published" "unknownFutureValue"] }
def audience-completer [] { ["everyone" "organization" "unknownFutureValue"] }
def status-completer-1 [] { ["canceled" "pendingApproval" "registered" "rejectedByOrganizer" "unknownFutureValue" "waitlisted"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "solutions GetSolutionsRoot" } } | get name | first)
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

# Get solutions
#
# GET /solutions
# operationId: solution.solutionsRoot_GetSolutionsRoot
export def "solutions GetSolutionsRoot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<backupRestore: record<id: string, serviceStatus: record<backupServiceConsumer: string, disableReason: string, gracePeriodDateTime: string, lastModifiedBy: record, lastModifiedDateTime: string, restoreAllowedTillDateTime: string, status: string>, browseSessions: list<record>, driveInclusionRules: list<record>, driveProtectionUnits: list<record>, driveProtectionUnitsBulkAdditionJobs: list<record>, exchangeProtectionPolicies: list<record>, exchangeRestoreSessions: list<record>, mailboxInclusionRules: list<record>, mailboxProtectionUnits: list<record>, mailboxProtectionUnitsBulkAdditionJobs: list<record>, oneDriveForBusinessBrowseSessions: list<record>, oneDriveForBusinessProtectionPolicies: list<record>, oneDriveForBusinessRestoreSessions: list<record>, protectionPolicies: list<record>, protectionUnits: list<record>, restorePoints: list<record>, restoreSessions: list<record>, serviceApps: list<record>, sharePointBrowseSessions: list<record>, sharePointProtectionPolicies: list<record>, sharePointRestoreSessions: list<record>, siteInclusionRules: list<record>, siteProtectionUnits: list<record>, siteProtectionUnitsBulkAdditionJobs: list<record>>, bookingBusinesses: table<id: string, address: record, bookingPageSettings: record, businessHours: list, businessType: string, createdDateTime: string, defaultCurrencyIso: string, displayName: string, email: string, isPublished: bool, languageTag: string, lastUpdatedDateTime: string, phone: string, publicUrl: string, schedulingPolicy: record, webSiteUrl: string, appointments: list, calendarView: list, customers: list, customQuestions: list, services: list, staffMembers: list>, bookingCurrencies: table<id: string, symbol: string>, virtualEvents: record<id: string, events: list<record>, townhalls: list<record>, webinars: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/solutions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update solutions
#
# PATCH /solutions
# operationId: solution.solutionsRoot_UpdateSolutionsRoot
# --bookingBusinesses item shape: {id?: string, address?: record, bookingPageSettings?: record, businessHours?: list, businessType?: string, createdDateTime?: string, defaultCurrencyIso?: string, displayName?: string, email?: string, languageTag?: string, lastUpdatedDateTime?: string, phone?: string, schedulingPolicy?: record, webSiteUrl?: string, appointments?: list, calendarView?: list, customers?: list, customQuestions?: list, services?: list, staffMembers?: list}
# --bookingCurrencies item shape: {id?: string, symbol?: string}
export def "solutions UpdateSolutionsRoot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --backupRestore: any
  --bookingBusinesses: list # item shape: {id?: string, address?: record, bookingPageSettings?: record, businessHours?: list, businessType?: string, createdDateTime?: string, defaultCurrencyIso?: string, displayName?: string, email?: string, languageTag?: string, lastUpdatedDateTime?: string, phone?: string, schedulingPolicy?: record, webSiteUrl?: string, appointments?: list, calendarView?: list, customers?: list, customQuestions?: list, services?: list, staffMembers?: list}
  --bookingCurrencies: list # item shape: {id?: string, symbol?: string}
  --virtualEvents: any
]: any -> record<backupRestore: record<id: string, serviceStatus: record<backupServiceConsumer: string, disableReason: string, gracePeriodDateTime: string, lastModifiedBy: record, lastModifiedDateTime: string, restoreAllowedTillDateTime: string, status: string>, browseSessions: list<record>, driveInclusionRules: list<record>, driveProtectionUnits: list<record>, driveProtectionUnitsBulkAdditionJobs: list<record>, exchangeProtectionPolicies: list<record>, exchangeRestoreSessions: list<record>, mailboxInclusionRules: list<record>, mailboxProtectionUnits: list<record>, mailboxProtectionUnitsBulkAdditionJobs: list<record>, oneDriveForBusinessBrowseSessions: list<record>, oneDriveForBusinessProtectionPolicies: list<record>, oneDriveForBusinessRestoreSessions: list<record>, protectionPolicies: list<record>, protectionUnits: list<record>, restorePoints: list<record>, restoreSessions: list<record>, serviceApps: list<record>, sharePointBrowseSessions: list<record>, sharePointProtectionPolicies: list<record>, sharePointRestoreSessions: list<record>, siteInclusionRules: list<record>, siteProtectionUnits: list<record>, siteProtectionUnitsBulkAdditionJobs: list<record>>, bookingBusinesses: table<id: string, address: record, bookingPageSettings: record, businessHours: list, businessType: string, createdDateTime: string, defaultCurrencyIso: string, displayName: string, email: string, isPublished: bool, languageTag: string, lastUpdatedDateTime: string, phone: string, publicUrl: string, schedulingPolicy: record, webSiteUrl: string, appointments: list, calendarView: list, customers: list, customQuestions: list, services: list, staffMembers: list>, bookingCurrencies: table<id: string, symbol: string>, virtualEvents: record<id: string, events: list<record>, townhalls: list<record>, webinars: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/solutions")
  let body = {backupRestore: $backupRestore, bookingBusinesses: $bookingBusinesses, bookingCurrencies: $bookingCurrencies, virtualEvents: $virtualEvents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List bookingBusinesses
#
# GET /solutions/bookingBusinesses
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-list?view=graph-rest-1.0 — Find more info here
# operationId: solution_ListBookingBusiness
export def "solutions-booking-businesses ListBookingBusiness" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/solutions/bookingBusinesses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create bookingBusiness
#
# POST /solutions/bookingBusinesses
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-post-bookingbusinesses?view=graph-rest-1.0 — Find more info here
# operationId: solution_CreateBookingBusiness
# --address shape: {city?: string, countryOrRegion?: string, postalCode?: string, state?: string, street?: string}
# --bookingPageSettings shape: {accessControl?: "unrestricted"|"restrictedToOrganization"|"unknownFutureValue", bookingPageColorCode?: string, businessTimeZone?: string, customerConsentMessage?: string, enforceOneTimePassword?: bool, isBusinessLogoDisplayEnabled?: bool, isCustomerConsentEnabled?: bool, isSearchEngineIndexabilityDisabled?: bool, isTimeSlotTimeZoneSetToBusinessTimeZone?: bool, privacyPolicyWebUrl?: string, termsAndConditionsWebUrl?: string}
# --businessHours item shape: {day?: "sunday"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday", timeSlots?: list}
# --schedulingPolicy shape: {allowStaffSelection?: bool, customAvailabilities?: list, generalAvailability?: record, isMeetingInviteToCustomersEnabled?: bool, maximumAdvance?: string, minimumLeadTime?: string, sendConfirmationsToOwner?: bool, timeSlotInterval?: string}
# --appointments item shape: {id?: string, additionalInformation?: string, anonymousJoinWebUrl?: string, appointmentLabel?: string, createdDateTime?: string, customerEmailAddress?: string, customerName?: string, customerNotes?: string, customerPhone?: string, customers?: list, customerTimeZone?: string, endDateTime?: record, isCustomerAllowedToManageBooking?: bool, isLocationOnline?: bool, joinWebUrl?: string, lastUpdatedDateTime?: string, maximumAttendeesCount?: float, optOutOfCustomerEmail?: bool, postBuffer?: string, preBuffer?: string, price?: float, priceType?: "undefined"|"fixedPrice"|"startingAt"|"hourly"|"free"|"priceVaries"|"callUs"|"notSet"|"unknownFutureValue", reminders?: list, selfServiceAppointmentId?: string, serviceId?: string, serviceLocation?: record, serviceName?: string, serviceNotes?: string, smsNotificationsEnabled?: bool, staffMemberIds?: list, startDateTime?: record}
# --calendarView item shape: {id?: string, additionalInformation?: string, anonymousJoinWebUrl?: string, appointmentLabel?: string, createdDateTime?: string, customerEmailAddress?: string, customerName?: string, customerNotes?: string, customerPhone?: string, customers?: list, customerTimeZone?: string, endDateTime?: record, isCustomerAllowedToManageBooking?: bool, isLocationOnline?: bool, joinWebUrl?: string, lastUpdatedDateTime?: string, maximumAttendeesCount?: float, optOutOfCustomerEmail?: bool, postBuffer?: string, preBuffer?: string, price?: float, priceType?: "undefined"|"fixedPrice"|"startingAt"|"hourly"|"free"|"priceVaries"|"callUs"|"notSet"|"unknownFutureValue", reminders?: list, selfServiceAppointmentId?: string, serviceId?: string, serviceLocation?: record, serviceName?: string, serviceNotes?: string, smsNotificationsEnabled?: bool, staffMemberIds?: list, startDateTime?: record}
# --customers item shape: {id?: string}
# --customQuestions item shape: {id?: string, answerInputType?: "text"|"radioButton"|"unknownFutureValue", answerOptions?: list, createdDateTime?: string, displayName?: string, lastUpdatedDateTime?: string}
# --services item shape: {id?: string, additionalInformation?: string, createdDateTime?: string, customQuestions?: list, defaultDuration?: string, defaultLocation?: record, defaultPrice?: float, defaultPriceType?: "undefined"|"fixedPrice"|"startingAt"|"hourly"|"free"|"priceVaries"|"callUs"|"notSet"|"unknownFutureValue", defaultReminders?: list, description?: string, displayName?: string, isAnonymousJoinEnabled?: bool, isCustomerAllowedToManageBooking?: bool, isHiddenFromCustomers?: bool, isLocationOnline?: bool, languageTag?: string, lastUpdatedDateTime?: string, maximumAttendeesCount?: float, notes?: string, postBuffer?: string, preBuffer?: string, schedulingPolicy?: record, smsNotificationsEnabled?: bool, staffMemberIds?: list}
# --staffMembers item shape: {id?: string}
export def "solutions-booking-businesses CreateBookingBusiness" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --address: record # shape: {city?: string, countryOrRegion?: string, postalCode?: string, state?: string, street?: string}
  --bookingPageSettings: record # shape: {accessControl?: "unrestricted"|"restrictedToOrganization"|"unknownFutureValue", bookingPageColorCode?: string, businessTimeZone?: string, customerConsentMessage?: string, enforceOneTimePassword?: bool, isBusinessLogoDisplayEnabled?: bool, isCustomerConsentEnabled?: bool, isSearchEngineIndexabilityDisabled?: bool, isTimeSlotTimeZoneSetToBusinessTimeZone?: bool, privacyPolicyWebUrl?: string, termsAndConditionsWebUrl?: string}
  --businessHours: list # The hours of operation for the business. — item shape: {day?: "sunday"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday", timeSlots?: list}
  --businessType: string # The type of business. (nullable)
  --createdDateTime: string # The date, time, and time zone when the booking business was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --defaultCurrencyIso: string # The code for the currency that the business operates in on Microsoft Bookings. (nullable)
  --displayName: string # The name of the business, which interfaces with customers. This name appears at the top of the business scheduling page.
  --email: string # The email address for the business. (nullable)
  --languageTag: string # The language of the self-service booking page. (nullable)
  --lastUpdatedDateTime: string # The date, time, and time zone when the booking business was last updated. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --phone: string # The telephone number for the business. The phone property, together with address and webSiteUrl, appear in the footer of a business scheduling page. (nullable)
  --schedulingPolicy: record # This type represents the set of policies that dictate how bookings can be created in a Booking Calendar. — shape: {allowStaffSelection?: bool, customAvailabilities?: list, generalAvailability?: record, isMeetingInviteToCustomersEnabled?: bool, maximumAdvance?: string, minimumLeadTime?: string, sendConfirmationsToOwner?: bool, timeSlotInterval?: string}
  --webSiteUrl: string # The URL of the business web site. The webSiteUrl property, together with address, phone, appear in the footer of a business scheduling page. (nullable)
  --appointments: list # All the appointments of this business. Read-only. Nullable. — item shape: {id?: string, additionalInformation?: string, anonymousJoinWebUrl?: string, appointmentLabel?: string, createdDateTime?: string, customerEmailAddress?: string, customerName?: string, customerNotes?: string, customerPhone?: string, customers?: list, customerTimeZone?: string, endDateTime?: record, isCustomerAllowedToManageBooking?: bool, isLocationOnline?: bool, joinWebUrl?: string, lastUpdatedDateTime?: string, maximumAttendeesCount?: float, optOutOfCustomerEmail?: bool, postBuffer?: string, preBuffer?: string, price?: float, priceType?: "undefined"|"fixedPrice"|"startingAt"|"hourly"|"free"|"priceVaries"|"callUs"|"notSet"|"unknownFutureValue", reminders?: list, selfServiceAppointmentId?: string, serviceId?: string, serviceLocation?: record, serviceName?: string, serviceNotes?: string, smsNotificationsEnabled?: bool, staffMemberIds?: list, startDateTime?: record}
  --calendarView: list # The set of appointments of this business in a specified date range. Read-only. Nullable. — item shape: {id?: string, additionalInformation?: string, anonymousJoinWebUrl?: string, appointmentLabel?: string, createdDateTime?: string, customerEmailAddress?: string, customerName?: string, customerNotes?: string, customerPhone?: string, customers?: list, customerTimeZone?: string, endDateTime?: record, isCustomerAllowedToManageBooking?: bool, isLocationOnline?: bool, joinWebUrl?: string, lastUpdatedDateTime?: string, maximumAttendeesCount?: float, optOutOfCustomerEmail?: bool, postBuffer?: string, preBuffer?: string, price?: float, priceType?: "undefined"|"fixedPrice"|"startingAt"|"hourly"|"free"|"priceVaries"|"callUs"|"notSet"|"unknownFutureValue", reminders?: list, selfServiceAppointmentId?: string, serviceId?: string, serviceLocation?: record, serviceName?: string, serviceNotes?: string, smsNotificationsEnabled?: bool, staffMemberIds?: list, startDateTime?: record}
  --customers: list # All the customers of this business. Read-only. Nullable. — item shape: {id?: string}
  --customQuestions: list # All the custom questions of this business. Read-only. Nullable. — item shape: {id?: string, answerInputType?: "text"|"radioButton"|"unknownFutureValue", answerOptions?: list, createdDateTime?: string, displayName?: string, lastUpdatedDateTime?: string}
  --services: list # All the services offered by this business. Read-only. Nullable. — item shape: {id?: string, additionalInformation?: string, createdDateTime?: string, customQuestions?: list, defaultDuration?: string, defaultLocation?: record, defaultPrice?: float, defaultPriceType?: "undefined"|"fixedPrice"|"startingAt"|"hourly"|"free"|"priceVaries"|"callUs"|"notSet"|"unknownFutureValue", defaultReminders?: list, description?: string, displayName?: string, isAnonymousJoinEnabled?: bool, isCustomerAllowedToManageBooking?: bool, isHiddenFromCustomers?: bool, isLocationOnline?: bool, languageTag?: string, lastUpdatedDateTime?: string, maximumAttendeesCount?: float, notes?: string, postBuffer?: string, preBuffer?: string, schedulingPolicy?: record, smsNotificationsEnabled?: bool, staffMemberIds?: list}
  --staffMembers: list # All the staff members that provide services in this business. Read-only. Nullable. — item shape: {id?: string}
]: any -> record<id: string, address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, bookingPageSettings: record<accessControl: string, bookingPageColorCode: string, businessTimeZone: string, customerConsentMessage: string, enforceOneTimePassword: bool, isBusinessLogoDisplayEnabled: bool, isCustomerConsentEnabled: bool, isSearchEngineIndexabilityDisabled: bool, isTimeSlotTimeZoneSetToBusinessTimeZone: bool, privacyPolicyWebUrl: string, termsAndConditionsWebUrl: string>, businessHours: table<day: string, timeSlots: list>, businessType: string, createdDateTime: string, defaultCurrencyIso: string, displayName: string, email: string, isPublished: bool, languageTag: string, lastUpdatedDateTime: string, phone: string, publicUrl: string, schedulingPolicy: record<allowStaffSelection: bool, customAvailabilities: list<record>, generalAvailability: record<availabilityType: string, businessHours: list>, isMeetingInviteToCustomersEnabled: bool, maximumAdvance: string, minimumLeadTime: string, sendConfirmationsToOwner: bool, timeSlotInterval: string>, webSiteUrl: string, appointments: table<id: string, additionalInformation: string, anonymousJoinWebUrl: string, appointmentLabel: string, createdDateTime: string, customerEmailAddress: string, customerName: string, customerNotes: string, customerPhone: string, customers: list, customerTimeZone: string, duration: string, endDateTime: record, filledAttendeesCount: float, isCustomerAllowedToManageBooking: bool, isLocationOnline: bool, joinWebUrl: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, optOutOfCustomerEmail: bool, postBuffer: string, preBuffer: string, price: float, priceType: string, reminders: list, selfServiceAppointmentId: string, serviceId: string, serviceLocation: record, serviceName: string, serviceNotes: string, smsNotificationsEnabled: bool, staffMemberIds: list, startDateTime: record>, calendarView: table<id: string, additionalInformation: string, anonymousJoinWebUrl: string, appointmentLabel: string, createdDateTime: string, customerEmailAddress: string, customerName: string, customerNotes: string, customerPhone: string, customers: list, customerTimeZone: string, duration: string, endDateTime: record, filledAttendeesCount: float, isCustomerAllowedToManageBooking: bool, isLocationOnline: bool, joinWebUrl: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, optOutOfCustomerEmail: bool, postBuffer: string, preBuffer: string, price: float, priceType: string, reminders: list, selfServiceAppointmentId: string, serviceId: string, serviceLocation: record, serviceName: string, serviceNotes: string, smsNotificationsEnabled: bool, staffMemberIds: list, startDateTime: record>, customers: table<id: string>, customQuestions: table<id: string, answerInputType: string, answerOptions: list, createdDateTime: string, displayName: string, lastUpdatedDateTime: string>, services: table<id: string, additionalInformation: string, createdDateTime: string, customQuestions: list, defaultDuration: string, defaultLocation: record, defaultPrice: float, defaultPriceType: string, defaultReminders: list, description: string, displayName: string, isAnonymousJoinEnabled: bool, isCustomerAllowedToManageBooking: bool, isHiddenFromCustomers: bool, isLocationOnline: bool, languageTag: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, notes: string, postBuffer: string, preBuffer: string, schedulingPolicy: record, smsNotificationsEnabled: bool, staffMemberIds: list, webUrl: string>, staffMembers: table<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/solutions/bookingBusinesses")
  let body = {id: $id, address: $address, bookingPageSettings: $bookingPageSettings, businessHours: $businessHours, businessType: $businessType, createdDateTime: $createdDateTime, defaultCurrencyIso: $defaultCurrencyIso, displayName: $displayName, email: $email, languageTag: $languageTag, lastUpdatedDateTime: $lastUpdatedDateTime, phone: $phone, schedulingPolicy: $schedulingPolicy, webSiteUrl: $webSiteUrl, appointments: $appointments, calendarView: $calendarView, customers: $customers, customQuestions: $customQuestions, services: $services, staffMembers: $staffMembers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get bookingBusiness
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-get?view=graph-rest-1.0 — Find more info here
# operationId: solution_GetBookingBusiness
export def "solutions-booking-businesses GetBookingBusiness" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, bookingPageSettings: record<accessControl: string, bookingPageColorCode: string, businessTimeZone: string, customerConsentMessage: string, enforceOneTimePassword: bool, isBusinessLogoDisplayEnabled: bool, isCustomerConsentEnabled: bool, isSearchEngineIndexabilityDisabled: bool, isTimeSlotTimeZoneSetToBusinessTimeZone: bool, privacyPolicyWebUrl: string, termsAndConditionsWebUrl: string>, businessHours: table<day: string, timeSlots: list>, businessType: string, createdDateTime: string, defaultCurrencyIso: string, displayName: string, email: string, isPublished: bool, languageTag: string, lastUpdatedDateTime: string, phone: string, publicUrl: string, schedulingPolicy: record<allowStaffSelection: bool, customAvailabilities: list<record>, generalAvailability: record<availabilityType: string, businessHours: list>, isMeetingInviteToCustomersEnabled: bool, maximumAdvance: string, minimumLeadTime: string, sendConfirmationsToOwner: bool, timeSlotInterval: string>, webSiteUrl: string, appointments: table<id: string, additionalInformation: string, anonymousJoinWebUrl: string, appointmentLabel: string, createdDateTime: string, customerEmailAddress: string, customerName: string, customerNotes: string, customerPhone: string, customers: list, customerTimeZone: string, duration: string, endDateTime: record, filledAttendeesCount: float, isCustomerAllowedToManageBooking: bool, isLocationOnline: bool, joinWebUrl: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, optOutOfCustomerEmail: bool, postBuffer: string, preBuffer: string, price: float, priceType: string, reminders: list, selfServiceAppointmentId: string, serviceId: string, serviceLocation: record, serviceName: string, serviceNotes: string, smsNotificationsEnabled: bool, staffMemberIds: list, startDateTime: record>, calendarView: table<id: string, additionalInformation: string, anonymousJoinWebUrl: string, appointmentLabel: string, createdDateTime: string, customerEmailAddress: string, customerName: string, customerNotes: string, customerPhone: string, customers: list, customerTimeZone: string, duration: string, endDateTime: record, filledAttendeesCount: float, isCustomerAllowedToManageBooking: bool, isLocationOnline: bool, joinWebUrl: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, optOutOfCustomerEmail: bool, postBuffer: string, preBuffer: string, price: float, priceType: string, reminders: list, selfServiceAppointmentId: string, serviceId: string, serviceLocation: record, serviceName: string, serviceNotes: string, smsNotificationsEnabled: bool, staffMemberIds: list, startDateTime: record>, customers: table<id: string>, customQuestions: table<id: string, answerInputType: string, answerOptions: list, createdDateTime: string, displayName: string, lastUpdatedDateTime: string>, services: table<id: string, additionalInformation: string, createdDateTime: string, customQuestions: list, defaultDuration: string, defaultLocation: record, defaultPrice: float, defaultPriceType: string, defaultReminders: list, description: string, displayName: string, isAnonymousJoinEnabled: bool, isCustomerAllowedToManageBooking: bool, isHiddenFromCustomers: bool, isLocationOnline: bool, languageTag: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, notes: string, postBuffer: string, preBuffer: string, schedulingPolicy: record, smsNotificationsEnabled: bool, staffMemberIds: list, webUrl: string>, staffMembers: table<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update bookingbusiness
#
# PATCH /solutions/bookingBusinesses/{bookingBusiness-id}
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-update?view=graph-rest-1.0 — Find more info here
# operationId: solution_UpdateBookingBusiness
# --address shape: {city?: string, countryOrRegion?: string, postalCode?: string, state?: string, street?: string}
# --bookingPageSettings shape: {accessControl?: "unrestricted"|"restrictedToOrganization"|"unknownFutureValue", bookingPageColorCode?: string, businessTimeZone?: string, customerConsentMessage?: string, enforceOneTimePassword?: bool, isBusinessLogoDisplayEnabled?: bool, isCustomerConsentEnabled?: bool, isSearchEngineIndexabilityDisabled?: bool, isTimeSlotTimeZoneSetToBusinessTimeZone?: bool, privacyPolicyWebUrl?: string, termsAndConditionsWebUrl?: string}
# --businessHours item shape: {day?: "sunday"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday", timeSlots?: list}
# --schedulingPolicy shape: {allowStaffSelection?: bool, customAvailabilities?: list, generalAvailability?: record, isMeetingInviteToCustomersEnabled?: bool, maximumAdvance?: string, minimumLeadTime?: string, sendConfirmationsToOwner?: bool, timeSlotInterval?: string}
# --appointments item shape: {id?: string, additionalInformation?: string, anonymousJoinWebUrl?: string, appointmentLabel?: string, createdDateTime?: string, customerEmailAddress?: string, customerName?: string, customerNotes?: string, customerPhone?: string, customers?: list, customerTimeZone?: string, endDateTime?: record, isCustomerAllowedToManageBooking?: bool, isLocationOnline?: bool, joinWebUrl?: string, lastUpdatedDateTime?: string, maximumAttendeesCount?: float, optOutOfCustomerEmail?: bool, postBuffer?: string, preBuffer?: string, price?: float, priceType?: "undefined"|"fixedPrice"|"startingAt"|"hourly"|"free"|"priceVaries"|"callUs"|"notSet"|"unknownFutureValue", reminders?: list, selfServiceAppointmentId?: string, serviceId?: string, serviceLocation?: record, serviceName?: string, serviceNotes?: string, smsNotificationsEnabled?: bool, staffMemberIds?: list, startDateTime?: record}
# --calendarView item shape: {id?: string, additionalInformation?: string, anonymousJoinWebUrl?: string, appointmentLabel?: string, createdDateTime?: string, customerEmailAddress?: string, customerName?: string, customerNotes?: string, customerPhone?: string, customers?: list, customerTimeZone?: string, endDateTime?: record, isCustomerAllowedToManageBooking?: bool, isLocationOnline?: bool, joinWebUrl?: string, lastUpdatedDateTime?: string, maximumAttendeesCount?: float, optOutOfCustomerEmail?: bool, postBuffer?: string, preBuffer?: string, price?: float, priceType?: "undefined"|"fixedPrice"|"startingAt"|"hourly"|"free"|"priceVaries"|"callUs"|"notSet"|"unknownFutureValue", reminders?: list, selfServiceAppointmentId?: string, serviceId?: string, serviceLocation?: record, serviceName?: string, serviceNotes?: string, smsNotificationsEnabled?: bool, staffMemberIds?: list, startDateTime?: record}
# --customers item shape: {id?: string}
# --customQuestions item shape: {id?: string, answerInputType?: "text"|"radioButton"|"unknownFutureValue", answerOptions?: list, createdDateTime?: string, displayName?: string, lastUpdatedDateTime?: string}
# --services item shape: {id?: string, additionalInformation?: string, createdDateTime?: string, customQuestions?: list, defaultDuration?: string, defaultLocation?: record, defaultPrice?: float, defaultPriceType?: "undefined"|"fixedPrice"|"startingAt"|"hourly"|"free"|"priceVaries"|"callUs"|"notSet"|"unknownFutureValue", defaultReminders?: list, description?: string, displayName?: string, isAnonymousJoinEnabled?: bool, isCustomerAllowedToManageBooking?: bool, isHiddenFromCustomers?: bool, isLocationOnline?: bool, languageTag?: string, lastUpdatedDateTime?: string, maximumAttendeesCount?: float, notes?: string, postBuffer?: string, preBuffer?: string, schedulingPolicy?: record, smsNotificationsEnabled?: bool, staffMemberIds?: list}
# --staffMembers item shape: {id?: string}
export def "solutions-booking-businesses UpdateBookingBusiness" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --address: record # shape: {city?: string, countryOrRegion?: string, postalCode?: string, state?: string, street?: string}
  --bookingPageSettings: record # shape: {accessControl?: "unrestricted"|"restrictedToOrganization"|"unknownFutureValue", bookingPageColorCode?: string, businessTimeZone?: string, customerConsentMessage?: string, enforceOneTimePassword?: bool, isBusinessLogoDisplayEnabled?: bool, isCustomerConsentEnabled?: bool, isSearchEngineIndexabilityDisabled?: bool, isTimeSlotTimeZoneSetToBusinessTimeZone?: bool, privacyPolicyWebUrl?: string, termsAndConditionsWebUrl?: string}
  --businessHours: list # The hours of operation for the business. — item shape: {day?: "sunday"|"monday"|"tuesday"|"wednesday"|"thursday"|"friday"|"saturday", timeSlots?: list}
  --businessType: string # The type of business. (nullable)
  --createdDateTime: string # The date, time, and time zone when the booking business was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --defaultCurrencyIso: string # The code for the currency that the business operates in on Microsoft Bookings. (nullable)
  --displayName: string # The name of the business, which interfaces with customers. This name appears at the top of the business scheduling page.
  --email: string # The email address for the business. (nullable)
  --languageTag: string # The language of the self-service booking page. (nullable)
  --lastUpdatedDateTime: string # The date, time, and time zone when the booking business was last updated. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --phone: string # The telephone number for the business. The phone property, together with address and webSiteUrl, appear in the footer of a business scheduling page. (nullable)
  --schedulingPolicy: record # This type represents the set of policies that dictate how bookings can be created in a Booking Calendar. — shape: {allowStaffSelection?: bool, customAvailabilities?: list, generalAvailability?: record, isMeetingInviteToCustomersEnabled?: bool, maximumAdvance?: string, minimumLeadTime?: string, sendConfirmationsToOwner?: bool, timeSlotInterval?: string}
  --webSiteUrl: string # The URL of the business web site. The webSiteUrl property, together with address, phone, appear in the footer of a business scheduling page. (nullable)
  --appointments: list # All the appointments of this business. Read-only. Nullable. — item shape: {id?: string, additionalInformation?: string, anonymousJoinWebUrl?: string, appointmentLabel?: string, createdDateTime?: string, customerEmailAddress?: string, customerName?: string, customerNotes?: string, customerPhone?: string, customers?: list, customerTimeZone?: string, endDateTime?: record, isCustomerAllowedToManageBooking?: bool, isLocationOnline?: bool, joinWebUrl?: string, lastUpdatedDateTime?: string, maximumAttendeesCount?: float, optOutOfCustomerEmail?: bool, postBuffer?: string, preBuffer?: string, price?: float, priceType?: "undefined"|"fixedPrice"|"startingAt"|"hourly"|"free"|"priceVaries"|"callUs"|"notSet"|"unknownFutureValue", reminders?: list, selfServiceAppointmentId?: string, serviceId?: string, serviceLocation?: record, serviceName?: string, serviceNotes?: string, smsNotificationsEnabled?: bool, staffMemberIds?: list, startDateTime?: record}
  --calendarView: list # The set of appointments of this business in a specified date range. Read-only. Nullable. — item shape: {id?: string, additionalInformation?: string, anonymousJoinWebUrl?: string, appointmentLabel?: string, createdDateTime?: string, customerEmailAddress?: string, customerName?: string, customerNotes?: string, customerPhone?: string, customers?: list, customerTimeZone?: string, endDateTime?: record, isCustomerAllowedToManageBooking?: bool, isLocationOnline?: bool, joinWebUrl?: string, lastUpdatedDateTime?: string, maximumAttendeesCount?: float, optOutOfCustomerEmail?: bool, postBuffer?: string, preBuffer?: string, price?: float, priceType?: "undefined"|"fixedPrice"|"startingAt"|"hourly"|"free"|"priceVaries"|"callUs"|"notSet"|"unknownFutureValue", reminders?: list, selfServiceAppointmentId?: string, serviceId?: string, serviceLocation?: record, serviceName?: string, serviceNotes?: string, smsNotificationsEnabled?: bool, staffMemberIds?: list, startDateTime?: record}
  --customers: list # All the customers of this business. Read-only. Nullable. — item shape: {id?: string}
  --customQuestions: list # All the custom questions of this business. Read-only. Nullable. — item shape: {id?: string, answerInputType?: "text"|"radioButton"|"unknownFutureValue", answerOptions?: list, createdDateTime?: string, displayName?: string, lastUpdatedDateTime?: string}
  --services: list # All the services offered by this business. Read-only. Nullable. — item shape: {id?: string, additionalInformation?: string, createdDateTime?: string, customQuestions?: list, defaultDuration?: string, defaultLocation?: record, defaultPrice?: float, defaultPriceType?: "undefined"|"fixedPrice"|"startingAt"|"hourly"|"free"|"priceVaries"|"callUs"|"notSet"|"unknownFutureValue", defaultReminders?: list, description?: string, displayName?: string, isAnonymousJoinEnabled?: bool, isCustomerAllowedToManageBooking?: bool, isHiddenFromCustomers?: bool, isLocationOnline?: bool, languageTag?: string, lastUpdatedDateTime?: string, maximumAttendeesCount?: float, notes?: string, postBuffer?: string, preBuffer?: string, schedulingPolicy?: record, smsNotificationsEnabled?: bool, staffMemberIds?: list}
  --staffMembers: list # All the staff members that provide services in this business. Read-only. Nullable. — item shape: {id?: string}
]: any -> record<id: string, address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, bookingPageSettings: record<accessControl: string, bookingPageColorCode: string, businessTimeZone: string, customerConsentMessage: string, enforceOneTimePassword: bool, isBusinessLogoDisplayEnabled: bool, isCustomerConsentEnabled: bool, isSearchEngineIndexabilityDisabled: bool, isTimeSlotTimeZoneSetToBusinessTimeZone: bool, privacyPolicyWebUrl: string, termsAndConditionsWebUrl: string>, businessHours: table<day: string, timeSlots: list>, businessType: string, createdDateTime: string, defaultCurrencyIso: string, displayName: string, email: string, isPublished: bool, languageTag: string, lastUpdatedDateTime: string, phone: string, publicUrl: string, schedulingPolicy: record<allowStaffSelection: bool, customAvailabilities: list<record>, generalAvailability: record<availabilityType: string, businessHours: list>, isMeetingInviteToCustomersEnabled: bool, maximumAdvance: string, minimumLeadTime: string, sendConfirmationsToOwner: bool, timeSlotInterval: string>, webSiteUrl: string, appointments: table<id: string, additionalInformation: string, anonymousJoinWebUrl: string, appointmentLabel: string, createdDateTime: string, customerEmailAddress: string, customerName: string, customerNotes: string, customerPhone: string, customers: list, customerTimeZone: string, duration: string, endDateTime: record, filledAttendeesCount: float, isCustomerAllowedToManageBooking: bool, isLocationOnline: bool, joinWebUrl: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, optOutOfCustomerEmail: bool, postBuffer: string, preBuffer: string, price: float, priceType: string, reminders: list, selfServiceAppointmentId: string, serviceId: string, serviceLocation: record, serviceName: string, serviceNotes: string, smsNotificationsEnabled: bool, staffMemberIds: list, startDateTime: record>, calendarView: table<id: string, additionalInformation: string, anonymousJoinWebUrl: string, appointmentLabel: string, createdDateTime: string, customerEmailAddress: string, customerName: string, customerNotes: string, customerPhone: string, customers: list, customerTimeZone: string, duration: string, endDateTime: record, filledAttendeesCount: float, isCustomerAllowedToManageBooking: bool, isLocationOnline: bool, joinWebUrl: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, optOutOfCustomerEmail: bool, postBuffer: string, preBuffer: string, price: float, priceType: string, reminders: list, selfServiceAppointmentId: string, serviceId: string, serviceLocation: record, serviceName: string, serviceNotes: string, smsNotificationsEnabled: bool, staffMemberIds: list, startDateTime: record>, customers: table<id: string>, customQuestions: table<id: string, answerInputType: string, answerOptions: list, createdDateTime: string, displayName: string, lastUpdatedDateTime: string>, services: table<id: string, additionalInformation: string, createdDateTime: string, customQuestions: list, defaultDuration: string, defaultLocation: record, defaultPrice: float, defaultPriceType: string, defaultReminders: list, description: string, displayName: string, isAnonymousJoinEnabled: bool, isCustomerAllowedToManageBooking: bool, isHiddenFromCustomers: bool, isLocationOnline: bool, languageTag: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, notes: string, postBuffer: string, preBuffer: string, schedulingPolicy: record, smsNotificationsEnabled: bool, staffMemberIds: list, webUrl: string>, staffMembers: table<id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)")
  let body = {id: $id, address: $address, bookingPageSettings: $bookingPageSettings, businessHours: $businessHours, businessType: $businessType, createdDateTime: $createdDateTime, defaultCurrencyIso: $defaultCurrencyIso, displayName: $displayName, email: $email, languageTag: $languageTag, lastUpdatedDateTime: $lastUpdatedDateTime, phone: $phone, schedulingPolicy: $schedulingPolicy, webSiteUrl: $webSiteUrl, appointments: $appointments, calendarView: $calendarView, customers: $customers, customQuestions: $customQuestions, services: $services, staffMembers: $staffMembers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete bookingBusiness
#
# DELETE /solutions/bookingBusinesses/{bookingBusiness-id}
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-delete?view=graph-rest-1.0 — Find more info here
# operationId: solution_DeleteBookingBusiness
export def "solutions-booking-businesses DeleteBookingBusiness" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List appointments
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/appointments
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-list-appointments?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_ListAppointment
export def "solutions-booking-businesses-appointments ListAppointment" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/appointments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create bookingAppointment
#
# POST /solutions/bookingBusinesses/{bookingBusiness-id}/appointments
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-post-appointments?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_CreateAppointment
# --endDateTime shape: {dateTime?: string, timeZone?: string}
# --reminders item shape: {message?: string, offset?: string, recipients?: "allAttendees"|"staff"|"customer"|"unknownFutureValue"}
# --serviceLocation shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --startDateTime shape: {dateTime?: string, timeZone?: string}
export def "solutions-booking-businesses-appointments CreateAppointment" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --additionalInformation: string # Additional information that is sent to the customer when an appointment is confirmed. (nullable)
  --anonymousJoinWebUrl: string # The URL of the meeting to join anonymously. (nullable)
  --appointmentLabel: string # The custom label that can be stamped on this appointment by users. (nullable)
  --createdDateTime: string # The date, time, and time zone when the appointment was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --customerEmailAddress: string # The SMTP address of the bookingCustomer who books the appointment. (nullable)
  --customerName: string # The customer's name. (nullable)
  --customerNotes: string # Notes from the customer associated with this appointment. You can get the value only when you read this bookingAppointment by its ID. You can set this property only when you initially create an appointment with a new customer. (nullable)
  --customerPhone: string # The customer's phone number. (nullable)
  --customers: list # A collection of customer properties for an appointment. An appointment contains a list of customer information and each unit will indicate the properties of a customer who is part of that appointment. Optional.
  --customerTimeZone: string # The time zone of the customer. For a list of possible values, see dateTimeTimeZone. (nullable)
  --endDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --isCustomerAllowedToManageBooking: string@bool-completer # Indicates that the customer can manage bookings created by the staff. The default value is false. (nullable)
  --isLocationOnline: string@bool-completer # Indicates that the appointment is held online. The default value is false.
  --joinWebUrl: string # The URL of the online meeting for the appointment. (nullable)
  --lastUpdatedDateTime: string # The date, time, and time zone when the booking business was last updated. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --maximumAttendeesCount: float # The maximum number of customers allowed in an appointment. If maximumAttendeesCount of the service is greater than 1, pass valid customer IDs while creating or updating an appointment. To create a customer, use the Create bookingCustomer operation. (format: int32)
  --optOutOfCustomerEmail: string@bool-completer # If true indicates that the bookingCustomer for this appointment doesn't wish to receive a confirmation for this appointment.
  --postBuffer: string # The amount of time to reserve after the appointment ends, for cleaning up, as an example. The value is expressed in ISO8601 format. (format: duration)
  --preBuffer: string # The amount of time to reserve before the appointment begins, for preparation, as an example. The value is expressed in ISO8601 format. (format: duration)
  --price: float # The regular price for an appointment for the specified bookingService. (nullable, format: double)
  --priceType: string@priceType-completer # Represents the type of pricing of a booking service.
  --reminders: list # The collection of customer reminders sent for this appointment. The value of this property is available only when reading this bookingAppointment by its ID. — item shape: {message?: string, offset?: string, recipients?: "allAttendees"|"staff"|"customer"|"unknownFutureValue"}
  --selfServiceAppointmentId: string # Another tracking ID for the appointment, if the appointment was created directly by the customer on the scheduling page, as opposed to by a staff member on behalf of the customer. (nullable)
  --serviceId: string # The ID of the bookingService associated with this appointment. (nullable)
  --serviceLocation: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --serviceName: string # The name of the bookingService associated with this appointment.This property is optional when creating a new appointment. If not specified, it's computed from the service associated with the appointment by the serviceId property.
  --serviceNotes: string # Notes from a bookingStaffMember. The value of this property is available only when reading this bookingAppointment by its ID. (nullable)
  --smsNotificationsEnabled: string@bool-completer # If true, indicates SMS notifications will be sent to the customers for the appointment. Default value is false.
  --staffMemberIds: list # The ID of each bookingStaffMember who is scheduled in this appointment.
  --startDateTime: record # shape: {dateTime?: string, timeZone?: string}
]: any -> record<id: string, additionalInformation: string, anonymousJoinWebUrl: string, appointmentLabel: string, createdDateTime: string, customerEmailAddress: string, customerName: string, customerNotes: string, customerPhone: string, customers: list<record>, customerTimeZone: string, duration: string, endDateTime: record<dateTime: string, timeZone: string>, filledAttendeesCount: float, isCustomerAllowedToManageBooking: bool, isLocationOnline: bool, joinWebUrl: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, optOutOfCustomerEmail: bool, postBuffer: string, preBuffer: string, price: float, priceType: string, reminders: table<message: string, offset: string, recipients: string>, selfServiceAppointmentId: string, serviceId: string, serviceLocation: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, serviceName: string, serviceNotes: string, smsNotificationsEnabled: bool, staffMemberIds: list<string>, startDateTime: record<dateTime: string, timeZone: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/appointments")
  let body = {id: $id, additionalInformation: $additionalInformation, anonymousJoinWebUrl: $anonymousJoinWebUrl, appointmentLabel: $appointmentLabel, createdDateTime: $createdDateTime, customerEmailAddress: $customerEmailAddress, customerName: $customerName, customerNotes: $customerNotes, customerPhone: $customerPhone, customers: $customers, customerTimeZone: $customerTimeZone, endDateTime: $endDateTime, isCustomerAllowedToManageBooking: $isCustomerAllowedToManageBooking, isLocationOnline: $isLocationOnline, joinWebUrl: $joinWebUrl, lastUpdatedDateTime: $lastUpdatedDateTime, maximumAttendeesCount: $maximumAttendeesCount, optOutOfCustomerEmail: $optOutOfCustomerEmail, postBuffer: $postBuffer, preBuffer: $preBuffer, price: $price, priceType: $priceType, reminders: $reminders, selfServiceAppointmentId: $selfServiceAppointmentId, serviceId: $serviceId, serviceLocation: $serviceLocation, serviceName: $serviceName, serviceNotes: $serviceNotes, smsNotificationsEnabled: $smsNotificationsEnabled, staffMemberIds: $staffMemberIds, startDateTime: $startDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get bookingAppointment
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/appointments/{bookingAppointment-id}
# Docs: https://learn.microsoft.com/graph/api/bookingappointment-get?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_GetAppointment
export def "solutions-booking-businesses-appointments GetAppointment" [
  bookingBusiness_id: string
  bookingAppointment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, additionalInformation: string, anonymousJoinWebUrl: string, appointmentLabel: string, createdDateTime: string, customerEmailAddress: string, customerName: string, customerNotes: string, customerPhone: string, customers: list<record>, customerTimeZone: string, duration: string, endDateTime: record<dateTime: string, timeZone: string>, filledAttendeesCount: float, isCustomerAllowedToManageBooking: bool, isLocationOnline: bool, joinWebUrl: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, optOutOfCustomerEmail: bool, postBuffer: string, preBuffer: string, price: float, priceType: string, reminders: table<message: string, offset: string, recipients: string>, selfServiceAppointmentId: string, serviceId: string, serviceLocation: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, serviceName: string, serviceNotes: string, smsNotificationsEnabled: bool, staffMemberIds: list<string>, startDateTime: record<dateTime: string, timeZone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/appointments/($bookingAppointment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update bookingAppointment
#
# PATCH /solutions/bookingBusinesses/{bookingBusiness-id}/appointments/{bookingAppointment-id}
# Docs: https://learn.microsoft.com/graph/api/bookingappointment-update?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_UpdateAppointment
# --endDateTime shape: {dateTime?: string, timeZone?: string}
# --reminders item shape: {message?: string, offset?: string, recipients?: "allAttendees"|"staff"|"customer"|"unknownFutureValue"}
# --serviceLocation shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --startDateTime shape: {dateTime?: string, timeZone?: string}
export def "solutions-booking-businesses-appointments UpdateAppointment" [
  bookingBusiness_id: string
  bookingAppointment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --additionalInformation: string # Additional information that is sent to the customer when an appointment is confirmed. (nullable)
  --anonymousJoinWebUrl: string # The URL of the meeting to join anonymously. (nullable)
  --appointmentLabel: string # The custom label that can be stamped on this appointment by users. (nullable)
  --createdDateTime: string # The date, time, and time zone when the appointment was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --customerEmailAddress: string # The SMTP address of the bookingCustomer who books the appointment. (nullable)
  --customerName: string # The customer's name. (nullable)
  --customerNotes: string # Notes from the customer associated with this appointment. You can get the value only when you read this bookingAppointment by its ID. You can set this property only when you initially create an appointment with a new customer. (nullable)
  --customerPhone: string # The customer's phone number. (nullable)
  --customers: list # A collection of customer properties for an appointment. An appointment contains a list of customer information and each unit will indicate the properties of a customer who is part of that appointment. Optional.
  --customerTimeZone: string # The time zone of the customer. For a list of possible values, see dateTimeTimeZone. (nullable)
  --endDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --isCustomerAllowedToManageBooking: string@bool-completer # Indicates that the customer can manage bookings created by the staff. The default value is false. (nullable)
  --isLocationOnline: string@bool-completer # Indicates that the appointment is held online. The default value is false.
  --joinWebUrl: string # The URL of the online meeting for the appointment. (nullable)
  --lastUpdatedDateTime: string # The date, time, and time zone when the booking business was last updated. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --maximumAttendeesCount: float # The maximum number of customers allowed in an appointment. If maximumAttendeesCount of the service is greater than 1, pass valid customer IDs while creating or updating an appointment. To create a customer, use the Create bookingCustomer operation. (format: int32)
  --optOutOfCustomerEmail: string@bool-completer # If true indicates that the bookingCustomer for this appointment doesn't wish to receive a confirmation for this appointment.
  --postBuffer: string # The amount of time to reserve after the appointment ends, for cleaning up, as an example. The value is expressed in ISO8601 format. (format: duration)
  --preBuffer: string # The amount of time to reserve before the appointment begins, for preparation, as an example. The value is expressed in ISO8601 format. (format: duration)
  --price: float # The regular price for an appointment for the specified bookingService. (nullable, format: double)
  --priceType: string@priceType-completer # Represents the type of pricing of a booking service.
  --reminders: list # The collection of customer reminders sent for this appointment. The value of this property is available only when reading this bookingAppointment by its ID. — item shape: {message?: string, offset?: string, recipients?: "allAttendees"|"staff"|"customer"|"unknownFutureValue"}
  --selfServiceAppointmentId: string # Another tracking ID for the appointment, if the appointment was created directly by the customer on the scheduling page, as opposed to by a staff member on behalf of the customer. (nullable)
  --serviceId: string # The ID of the bookingService associated with this appointment. (nullable)
  --serviceLocation: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --serviceName: string # The name of the bookingService associated with this appointment.This property is optional when creating a new appointment. If not specified, it's computed from the service associated with the appointment by the serviceId property.
  --serviceNotes: string # Notes from a bookingStaffMember. The value of this property is available only when reading this bookingAppointment by its ID. (nullable)
  --smsNotificationsEnabled: string@bool-completer # If true, indicates SMS notifications will be sent to the customers for the appointment. Default value is false.
  --staffMemberIds: list # The ID of each bookingStaffMember who is scheduled in this appointment.
  --startDateTime: record # shape: {dateTime?: string, timeZone?: string}
]: any -> record<id: string, additionalInformation: string, anonymousJoinWebUrl: string, appointmentLabel: string, createdDateTime: string, customerEmailAddress: string, customerName: string, customerNotes: string, customerPhone: string, customers: list<record>, customerTimeZone: string, duration: string, endDateTime: record<dateTime: string, timeZone: string>, filledAttendeesCount: float, isCustomerAllowedToManageBooking: bool, isLocationOnline: bool, joinWebUrl: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, optOutOfCustomerEmail: bool, postBuffer: string, preBuffer: string, price: float, priceType: string, reminders: table<message: string, offset: string, recipients: string>, selfServiceAppointmentId: string, serviceId: string, serviceLocation: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, serviceName: string, serviceNotes: string, smsNotificationsEnabled: bool, staffMemberIds: list<string>, startDateTime: record<dateTime: string, timeZone: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/appointments/($bookingAppointment_id)")
  let body = {id: $id, additionalInformation: $additionalInformation, anonymousJoinWebUrl: $anonymousJoinWebUrl, appointmentLabel: $appointmentLabel, createdDateTime: $createdDateTime, customerEmailAddress: $customerEmailAddress, customerName: $customerName, customerNotes: $customerNotes, customerPhone: $customerPhone, customers: $customers, customerTimeZone: $customerTimeZone, endDateTime: $endDateTime, isCustomerAllowedToManageBooking: $isCustomerAllowedToManageBooking, isLocationOnline: $isLocationOnline, joinWebUrl: $joinWebUrl, lastUpdatedDateTime: $lastUpdatedDateTime, maximumAttendeesCount: $maximumAttendeesCount, optOutOfCustomerEmail: $optOutOfCustomerEmail, postBuffer: $postBuffer, preBuffer: $preBuffer, price: $price, priceType: $priceType, reminders: $reminders, selfServiceAppointmentId: $selfServiceAppointmentId, serviceId: $serviceId, serviceLocation: $serviceLocation, serviceName: $serviceName, serviceNotes: $serviceNotes, smsNotificationsEnabled: $smsNotificationsEnabled, staffMemberIds: $staffMemberIds, startDateTime: $startDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete bookingAppointment
#
# DELETE /solutions/bookingBusinesses/{bookingBusiness-id}/appointments/{bookingAppointment-id}
# Docs: https://learn.microsoft.com/graph/api/bookingappointment-delete?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_DeleteAppointment
export def "solutions-booking-businesses-appointments DeleteAppointment" [
  bookingBusiness_id: string
  bookingAppointment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/appointments/($bookingAppointment_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke action cancel
#
# POST /solutions/bookingBusinesses/{bookingBusiness-id}/appointments/{bookingAppointment-id}/microsoft.graph.cancel
# Docs: https://learn.microsoft.com/graph/api/bookingappointment-cancel?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness.appointment_cancel
export def "solutions-booking-businesses-appointments-microsoftgraphcancel cancel" [
  bookingBusiness_id: string
  bookingAppointment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cancellationMessage: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/appointments/($bookingAppointment_id)/microsoft.graph.cancel")
  let body = {cancellationMessage: $cancellationMessage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the number of the resource
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/appointments/$count
# operationId: solution.bookingBusiness.appointment_GetCount
export def "solutions-booking-businesses-appointments-count GetCount" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/appointments/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List business calendarView
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/calendarView
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-list-calendarview?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_ListCalendarView
export def "solutions-booking-businesses-calendar-view ListCalendarView" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # The start date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T19:00:00-08:00
  --end: string # The end date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/calendarView" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new navigation property to calendarView for solutions
#
# POST /solutions/bookingBusinesses/{bookingBusiness-id}/calendarView
# operationId: solution.bookingBusiness_CreateCalendarView
# --endDateTime shape: {dateTime?: string, timeZone?: string}
# --reminders item shape: {message?: string, offset?: string, recipients?: "allAttendees"|"staff"|"customer"|"unknownFutureValue"}
# --serviceLocation shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --startDateTime shape: {dateTime?: string, timeZone?: string}
export def "solutions-booking-businesses-calendar-view CreateCalendarView" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --additionalInformation: string # Additional information that is sent to the customer when an appointment is confirmed. (nullable)
  --anonymousJoinWebUrl: string # The URL of the meeting to join anonymously. (nullable)
  --appointmentLabel: string # The custom label that can be stamped on this appointment by users. (nullable)
  --createdDateTime: string # The date, time, and time zone when the appointment was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --customerEmailAddress: string # The SMTP address of the bookingCustomer who books the appointment. (nullable)
  --customerName: string # The customer's name. (nullable)
  --customerNotes: string # Notes from the customer associated with this appointment. You can get the value only when you read this bookingAppointment by its ID. You can set this property only when you initially create an appointment with a new customer. (nullable)
  --customerPhone: string # The customer's phone number. (nullable)
  --customers: list # A collection of customer properties for an appointment. An appointment contains a list of customer information and each unit will indicate the properties of a customer who is part of that appointment. Optional.
  --customerTimeZone: string # The time zone of the customer. For a list of possible values, see dateTimeTimeZone. (nullable)
  --endDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --isCustomerAllowedToManageBooking: string@bool-completer # Indicates that the customer can manage bookings created by the staff. The default value is false. (nullable)
  --isLocationOnline: string@bool-completer # Indicates that the appointment is held online. The default value is false.
  --joinWebUrl: string # The URL of the online meeting for the appointment. (nullable)
  --lastUpdatedDateTime: string # The date, time, and time zone when the booking business was last updated. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --maximumAttendeesCount: float # The maximum number of customers allowed in an appointment. If maximumAttendeesCount of the service is greater than 1, pass valid customer IDs while creating or updating an appointment. To create a customer, use the Create bookingCustomer operation. (format: int32)
  --optOutOfCustomerEmail: string@bool-completer # If true indicates that the bookingCustomer for this appointment doesn't wish to receive a confirmation for this appointment.
  --postBuffer: string # The amount of time to reserve after the appointment ends, for cleaning up, as an example. The value is expressed in ISO8601 format. (format: duration)
  --preBuffer: string # The amount of time to reserve before the appointment begins, for preparation, as an example. The value is expressed in ISO8601 format. (format: duration)
  --price: float # The regular price for an appointment for the specified bookingService. (nullable, format: double)
  --priceType: string@priceType-completer # Represents the type of pricing of a booking service.
  --reminders: list # The collection of customer reminders sent for this appointment. The value of this property is available only when reading this bookingAppointment by its ID. — item shape: {message?: string, offset?: string, recipients?: "allAttendees"|"staff"|"customer"|"unknownFutureValue"}
  --selfServiceAppointmentId: string # Another tracking ID for the appointment, if the appointment was created directly by the customer on the scheduling page, as opposed to by a staff member on behalf of the customer. (nullable)
  --serviceId: string # The ID of the bookingService associated with this appointment. (nullable)
  --serviceLocation: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --serviceName: string # The name of the bookingService associated with this appointment.This property is optional when creating a new appointment. If not specified, it's computed from the service associated with the appointment by the serviceId property.
  --serviceNotes: string # Notes from a bookingStaffMember. The value of this property is available only when reading this bookingAppointment by its ID. (nullable)
  --smsNotificationsEnabled: string@bool-completer # If true, indicates SMS notifications will be sent to the customers for the appointment. Default value is false.
  --staffMemberIds: list # The ID of each bookingStaffMember who is scheduled in this appointment.
  --startDateTime: record # shape: {dateTime?: string, timeZone?: string}
]: any -> record<id: string, additionalInformation: string, anonymousJoinWebUrl: string, appointmentLabel: string, createdDateTime: string, customerEmailAddress: string, customerName: string, customerNotes: string, customerPhone: string, customers: list<record>, customerTimeZone: string, duration: string, endDateTime: record<dateTime: string, timeZone: string>, filledAttendeesCount: float, isCustomerAllowedToManageBooking: bool, isLocationOnline: bool, joinWebUrl: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, optOutOfCustomerEmail: bool, postBuffer: string, preBuffer: string, price: float, priceType: string, reminders: table<message: string, offset: string, recipients: string>, selfServiceAppointmentId: string, serviceId: string, serviceLocation: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, serviceName: string, serviceNotes: string, smsNotificationsEnabled: bool, staffMemberIds: list<string>, startDateTime: record<dateTime: string, timeZone: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/calendarView")
  let body = {id: $id, additionalInformation: $additionalInformation, anonymousJoinWebUrl: $anonymousJoinWebUrl, appointmentLabel: $appointmentLabel, createdDateTime: $createdDateTime, customerEmailAddress: $customerEmailAddress, customerName: $customerName, customerNotes: $customerNotes, customerPhone: $customerPhone, customers: $customers, customerTimeZone: $customerTimeZone, endDateTime: $endDateTime, isCustomerAllowedToManageBooking: $isCustomerAllowedToManageBooking, isLocationOnline: $isLocationOnline, joinWebUrl: $joinWebUrl, lastUpdatedDateTime: $lastUpdatedDateTime, maximumAttendeesCount: $maximumAttendeesCount, optOutOfCustomerEmail: $optOutOfCustomerEmail, postBuffer: $postBuffer, preBuffer: $preBuffer, price: $price, priceType: $priceType, reminders: $reminders, selfServiceAppointmentId: $selfServiceAppointmentId, serviceId: $serviceId, serviceLocation: $serviceLocation, serviceName: $serviceName, serviceNotes: $serviceNotes, smsNotificationsEnabled: $smsNotificationsEnabled, staffMemberIds: $staffMemberIds, startDateTime: $startDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get calendarView from solutions
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/calendarView/{bookingAppointment-id}
# operationId: solution.bookingBusiness_GetCalendarView
export def "solutions-booking-businesses-calendar-view GetCalendarView" [
  bookingBusiness_id: string
  bookingAppointment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # The start date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T19:00:00-08:00
  --end: string # The end date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, additionalInformation: string, anonymousJoinWebUrl: string, appointmentLabel: string, createdDateTime: string, customerEmailAddress: string, customerName: string, customerNotes: string, customerPhone: string, customers: list<record>, customerTimeZone: string, duration: string, endDateTime: record<dateTime: string, timeZone: string>, filledAttendeesCount: float, isCustomerAllowedToManageBooking: bool, isLocationOnline: bool, joinWebUrl: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, optOutOfCustomerEmail: bool, postBuffer: string, preBuffer: string, price: float, priceType: string, reminders: table<message: string, offset: string, recipients: string>, selfServiceAppointmentId: string, serviceId: string, serviceLocation: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, serviceName: string, serviceNotes: string, smsNotificationsEnabled: bool, staffMemberIds: list<string>, startDateTime: record<dateTime: string, timeZone: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/calendarView/($bookingAppointment_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property calendarView in solutions
#
# PATCH /solutions/bookingBusinesses/{bookingBusiness-id}/calendarView/{bookingAppointment-id}
# operationId: solution.bookingBusiness_UpdateCalendarView
# --endDateTime shape: {dateTime?: string, timeZone?: string}
# --reminders item shape: {message?: string, offset?: string, recipients?: "allAttendees"|"staff"|"customer"|"unknownFutureValue"}
# --serviceLocation shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --startDateTime shape: {dateTime?: string, timeZone?: string}
export def "solutions-booking-businesses-calendar-view UpdateCalendarView" [
  bookingBusiness_id: string
  bookingAppointment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --additionalInformation: string # Additional information that is sent to the customer when an appointment is confirmed. (nullable)
  --anonymousJoinWebUrl: string # The URL of the meeting to join anonymously. (nullable)
  --appointmentLabel: string # The custom label that can be stamped on this appointment by users. (nullable)
  --createdDateTime: string # The date, time, and time zone when the appointment was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --customerEmailAddress: string # The SMTP address of the bookingCustomer who books the appointment. (nullable)
  --customerName: string # The customer's name. (nullable)
  --customerNotes: string # Notes from the customer associated with this appointment. You can get the value only when you read this bookingAppointment by its ID. You can set this property only when you initially create an appointment with a new customer. (nullable)
  --customerPhone: string # The customer's phone number. (nullable)
  --customers: list # A collection of customer properties for an appointment. An appointment contains a list of customer information and each unit will indicate the properties of a customer who is part of that appointment. Optional.
  --customerTimeZone: string # The time zone of the customer. For a list of possible values, see dateTimeTimeZone. (nullable)
  --endDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --isCustomerAllowedToManageBooking: string@bool-completer # Indicates that the customer can manage bookings created by the staff. The default value is false. (nullable)
  --isLocationOnline: string@bool-completer # Indicates that the appointment is held online. The default value is false.
  --joinWebUrl: string # The URL of the online meeting for the appointment. (nullable)
  --lastUpdatedDateTime: string # The date, time, and time zone when the booking business was last updated. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --maximumAttendeesCount: float # The maximum number of customers allowed in an appointment. If maximumAttendeesCount of the service is greater than 1, pass valid customer IDs while creating or updating an appointment. To create a customer, use the Create bookingCustomer operation. (format: int32)
  --optOutOfCustomerEmail: string@bool-completer # If true indicates that the bookingCustomer for this appointment doesn't wish to receive a confirmation for this appointment.
  --postBuffer: string # The amount of time to reserve after the appointment ends, for cleaning up, as an example. The value is expressed in ISO8601 format. (format: duration)
  --preBuffer: string # The amount of time to reserve before the appointment begins, for preparation, as an example. The value is expressed in ISO8601 format. (format: duration)
  --price: float # The regular price for an appointment for the specified bookingService. (nullable, format: double)
  --priceType: string@priceType-completer # Represents the type of pricing of a booking service.
  --reminders: list # The collection of customer reminders sent for this appointment. The value of this property is available only when reading this bookingAppointment by its ID. — item shape: {message?: string, offset?: string, recipients?: "allAttendees"|"staff"|"customer"|"unknownFutureValue"}
  --selfServiceAppointmentId: string # Another tracking ID for the appointment, if the appointment was created directly by the customer on the scheduling page, as opposed to by a staff member on behalf of the customer. (nullable)
  --serviceId: string # The ID of the bookingService associated with this appointment. (nullable)
  --serviceLocation: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --serviceName: string # The name of the bookingService associated with this appointment.This property is optional when creating a new appointment. If not specified, it's computed from the service associated with the appointment by the serviceId property.
  --serviceNotes: string # Notes from a bookingStaffMember. The value of this property is available only when reading this bookingAppointment by its ID. (nullable)
  --smsNotificationsEnabled: string@bool-completer # If true, indicates SMS notifications will be sent to the customers for the appointment. Default value is false.
  --staffMemberIds: list # The ID of each bookingStaffMember who is scheduled in this appointment.
  --startDateTime: record # shape: {dateTime?: string, timeZone?: string}
]: any -> record<id: string, additionalInformation: string, anonymousJoinWebUrl: string, appointmentLabel: string, createdDateTime: string, customerEmailAddress: string, customerName: string, customerNotes: string, customerPhone: string, customers: list<record>, customerTimeZone: string, duration: string, endDateTime: record<dateTime: string, timeZone: string>, filledAttendeesCount: float, isCustomerAllowedToManageBooking: bool, isLocationOnline: bool, joinWebUrl: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, optOutOfCustomerEmail: bool, postBuffer: string, preBuffer: string, price: float, priceType: string, reminders: table<message: string, offset: string, recipients: string>, selfServiceAppointmentId: string, serviceId: string, serviceLocation: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, serviceName: string, serviceNotes: string, smsNotificationsEnabled: bool, staffMemberIds: list<string>, startDateTime: record<dateTime: string, timeZone: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/calendarView/($bookingAppointment_id)")
  let body = {id: $id, additionalInformation: $additionalInformation, anonymousJoinWebUrl: $anonymousJoinWebUrl, appointmentLabel: $appointmentLabel, createdDateTime: $createdDateTime, customerEmailAddress: $customerEmailAddress, customerName: $customerName, customerNotes: $customerNotes, customerPhone: $customerPhone, customers: $customers, customerTimeZone: $customerTimeZone, endDateTime: $endDateTime, isCustomerAllowedToManageBooking: $isCustomerAllowedToManageBooking, isLocationOnline: $isLocationOnline, joinWebUrl: $joinWebUrl, lastUpdatedDateTime: $lastUpdatedDateTime, maximumAttendeesCount: $maximumAttendeesCount, optOutOfCustomerEmail: $optOutOfCustomerEmail, postBuffer: $postBuffer, preBuffer: $preBuffer, price: $price, priceType: $priceType, reminders: $reminders, selfServiceAppointmentId: $selfServiceAppointmentId, serviceId: $serviceId, serviceLocation: $serviceLocation, serviceName: $serviceName, serviceNotes: $serviceNotes, smsNotificationsEnabled: $smsNotificationsEnabled, staffMemberIds: $staffMemberIds, startDateTime: $startDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property calendarView for solutions
#
# DELETE /solutions/bookingBusinesses/{bookingBusiness-id}/calendarView/{bookingAppointment-id}
# operationId: solution.bookingBusiness_DeleteCalendarView
export def "solutions-booking-businesses-calendar-view DeleteCalendarView" [
  bookingBusiness_id: string
  bookingAppointment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/calendarView/($bookingAppointment_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke action cancel
#
# POST /solutions/bookingBusinesses/{bookingBusiness-id}/calendarView/{bookingAppointment-id}/microsoft.graph.cancel
# Docs: https://learn.microsoft.com/graph/api/bookingappointment-cancel?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness.calendarView_cancel
export def "solutions-booking-businesses-calendar-view-microsoftgraphcancel cancel" [
  bookingBusiness_id: string
  bookingAppointment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cancellationMessage: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/calendarView/($bookingAppointment_id)/microsoft.graph.cancel")
  let body = {cancellationMessage: $cancellationMessage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the number of the resource
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/calendarView/$count
# operationId: solution.bookingBusiness.calendarView_GetCount
export def "solutions-booking-businesses-calendar-view-count GetCount" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # The start date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T19:00:00-08:00
  --end: string # The end date and time of the time range, represented in ISO 8601 format. For example, 2019-11-08T20:00:00-08:00
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/calendarView/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List customers
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/customers
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-list-customers?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_ListCustomer
export def "solutions-booking-businesses-customers ListCustomer" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/customers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create bookingCustomer
#
# POST /solutions/bookingBusinesses/{bookingBusiness-id}/customers
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-post-customers?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_CreateCustomer
export def "solutions-booking-businesses-customers CreateCustomer" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/customers")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get bookingCustomer
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/customers/{bookingCustomerBase-id}
# Docs: https://learn.microsoft.com/graph/api/bookingcustomer-get?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_GetCustomer
export def "solutions-booking-businesses-customers GetCustomer" [
  bookingBusiness_id: string
  bookingCustomerBase_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/customers/($bookingCustomerBase_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update bookingCustomer
#
# PATCH /solutions/bookingBusinesses/{bookingBusiness-id}/customers/{bookingCustomerBase-id}
# Docs: https://learn.microsoft.com/graph/api/bookingcustomer-update?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_UpdateCustomer
export def "solutions-booking-businesses-customers UpdateCustomer" [
  bookingBusiness_id: string
  bookingCustomerBase_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/customers/($bookingCustomerBase_id)")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete bookingCustomer
#
# DELETE /solutions/bookingBusinesses/{bookingBusiness-id}/customers/{bookingCustomerBase-id}
# Docs: https://learn.microsoft.com/graph/api/bookingcustomer-delete?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_DeleteCustomer
export def "solutions-booking-businesses-customers DeleteCustomer" [
  bookingBusiness_id: string
  bookingCustomerBase_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/customers/($bookingCustomerBase_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/customers/$count
# operationId: solution.bookingBusiness.customer_GetCount
export def "solutions-booking-businesses-customers-count GetCount" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/customers/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List customQuestions
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/customQuestions
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-list-customquestions?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_ListCustomQuestion
export def "solutions-booking-businesses-custom-questions ListCustomQuestion" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/customQuestions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create bookingCustomQuestion
#
# POST /solutions/bookingBusinesses/{bookingBusiness-id}/customQuestions
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-post-customquestions?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_CreateCustomQuestion
export def "solutions-booking-businesses-custom-questions CreateCustomQuestion" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --answerInputType: string@answerInputType-completer
  --answerOptions: list # List of possible answer values.
  --createdDateTime: string # The date, time, and time zone when the custom question was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --displayName: string # The question.
  --lastUpdatedDateTime: string # The date, time, and time zone when the custom question was last updated. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<id: string, answerInputType: string, answerOptions: list<string>, createdDateTime: string, displayName: string, lastUpdatedDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/customQuestions")
  let body = {id: $id, answerInputType: $answerInputType, answerOptions: $answerOptions, createdDateTime: $createdDateTime, displayName: $displayName, lastUpdatedDateTime: $lastUpdatedDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get bookingCustomQuestion
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/customQuestions/{bookingCustomQuestion-id}
# Docs: https://learn.microsoft.com/graph/api/bookingcustomquestion-get?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_GetCustomQuestion
export def "solutions-booking-businesses-custom-questions GetCustomQuestion" [
  bookingBusiness_id: string
  bookingCustomQuestion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, answerInputType: string, answerOptions: list<string>, createdDateTime: string, displayName: string, lastUpdatedDateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/customQuestions/($bookingCustomQuestion_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update bookingCustomQuestion
#
# PATCH /solutions/bookingBusinesses/{bookingBusiness-id}/customQuestions/{bookingCustomQuestion-id}
# Docs: https://learn.microsoft.com/graph/api/bookingcustomquestion-update?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_UpdateCustomQuestion
export def "solutions-booking-businesses-custom-questions UpdateCustomQuestion" [
  bookingBusiness_id: string
  bookingCustomQuestion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --answerInputType: string@answerInputType-completer
  --answerOptions: list # List of possible answer values.
  --createdDateTime: string # The date, time, and time zone when the custom question was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --displayName: string # The question.
  --lastUpdatedDateTime: string # The date, time, and time zone when the custom question was last updated. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
]: any -> record<id: string, answerInputType: string, answerOptions: list<string>, createdDateTime: string, displayName: string, lastUpdatedDateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/customQuestions/($bookingCustomQuestion_id)")
  let body = {id: $id, answerInputType: $answerInputType, answerOptions: $answerOptions, createdDateTime: $createdDateTime, displayName: $displayName, lastUpdatedDateTime: $lastUpdatedDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete bookingCustomQuestion
#
# DELETE /solutions/bookingBusinesses/{bookingBusiness-id}/customQuestions/{bookingCustomQuestion-id}
# Docs: https://learn.microsoft.com/graph/api/bookingcustomquestion-delete?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_DeleteCustomQuestion
export def "solutions-booking-businesses-custom-questions DeleteCustomQuestion" [
  bookingBusiness_id: string
  bookingCustomQuestion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/customQuestions/($bookingCustomQuestion_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/customQuestions/$count
# operationId: solution.bookingBusiness.customQuestion_GetCount
export def "solutions-booking-businesses-custom-questions-count GetCount" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/customQuestions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke action getStaffAvailability
#
# POST /solutions/bookingBusinesses/{bookingBusiness-id}/microsoft.graph.getStaffAvailability
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-getstaffavailability?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_getStaffAvailability
# --startDateTime shape: {dateTime?: string, timeZone?: string}
# --endDateTime shape: {dateTime?: string, timeZone?: string}
export def "solutions-booking-businesses-microsoftgraphget-staff-availability post" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --staffIds: list
  --startDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --endDateTime: record # shape: {dateTime?: string, timeZone?: string}
]: any -> record<value: table<availabilityItems: list, staffId: string>, _odata_nextLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/microsoft.graph.getStaffAvailability")
  let body = {staffIds: $staffIds, startDateTime: $startDateTime, endDateTime: $endDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Invoke action publish
#
# POST /solutions/bookingBusinesses/{bookingBusiness-id}/microsoft.graph.publish
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-publish?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_publish
export def "solutions-booking-businesses-microsoftgraphpublish publish" [
  bookingBusiness_id: string
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
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/microsoft.graph.publish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke action unpublish
#
# POST /solutions/bookingBusinesses/{bookingBusiness-id}/microsoft.graph.unpublish
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-unpublish?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_unpublish
export def "solutions-booking-businesses-microsoftgraphunpublish unpublish" [
  bookingBusiness_id: string
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
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/microsoft.graph.unpublish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List services
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/services
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-list-services?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_ListService
export def "solutions-booking-businesses-services ListService" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create bookingService
#
# POST /solutions/bookingBusinesses/{bookingBusiness-id}/services
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-post-services?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_CreateService
# --customQuestions item shape: {isRequired?: bool, questionId?: string}
# --defaultLocation shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --defaultReminders item shape: {message?: string, offset?: string, recipients?: "allAttendees"|"staff"|"customer"|"unknownFutureValue"}
# --schedulingPolicy shape: {allowStaffSelection?: bool, customAvailabilities?: list, generalAvailability?: record, isMeetingInviteToCustomersEnabled?: bool, maximumAdvance?: string, minimumLeadTime?: string, sendConfirmationsToOwner?: bool, timeSlotInterval?: string}
export def "solutions-booking-businesses-services CreateService" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --additionalInformation: string # Additional information that is sent to the customer when an appointment is confirmed. (nullable)
  --createdDateTime: string # The date, time, and time zone when the service was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --customQuestions: list # Contains the set of custom questions associated with a particular service. — item shape: {isRequired?: bool, questionId?: string}
  --defaultDuration: string # The default length of the service, represented in numbers of days, hours, minutes, and seconds. For example, P11D23H59M59.999999999999S. (format: duration)
  --defaultLocation: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --defaultPrice: float # The default monetary price for the service. (nullable, format: double)
  --defaultPriceType: string@defaultPriceType-completer # Represents the type of pricing of a booking service.
  --defaultReminders: list # The default set of reminders for an appointment of this service. The value of this property is available only when reading this bookingService by its ID. — item shape: {message?: string, offset?: string, recipients?: "allAttendees"|"staff"|"customer"|"unknownFutureValue"}
  --description: string # A text description for the service. (nullable)
  --displayName: string # A service name.
  --isAnonymousJoinEnabled: string@bool-completer # Indicates if an anonymousJoinWebUrl(webrtcUrl) is generated for the appointment booked for this service. The default value is false.
  --isCustomerAllowedToManageBooking: string@bool-completer # Indicates that the customer can manage bookings created by the staff. The default value is false. (nullable)
  --isHiddenFromCustomers: string@bool-completer # True indicates that this service isn't available to customers for booking.
  --isLocationOnline: string@bool-completer # Indicates that the appointments for the service are held online. The default value is false.
  --languageTag: string # The language of the self-service booking page.
  --lastUpdatedDateTime: string # The date, time, and time zone when the service was last updated. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --maximumAttendeesCount: float # The maximum number of customers allowed in a service. If maximumAttendeesCount of the service is greater than 1, pass valid customer IDs while creating or updating an appointment. To create a customer, use the Create bookingCustomer operation. (format: int32)
  --notes: string # Additional information about this service. (nullable)
  --postBuffer: string # The time to buffer after an appointment for this service ends, and before the next customer appointment can be booked. (format: duration)
  --preBuffer: string # The time to buffer before an appointment for this service can start. (format: duration)
  --schedulingPolicy: record # This type represents the set of policies that dictate how bookings can be created in a Booking Calendar. — shape: {allowStaffSelection?: bool, customAvailabilities?: list, generalAvailability?: record, isMeetingInviteToCustomersEnabled?: bool, maximumAdvance?: string, minimumLeadTime?: string, sendConfirmationsToOwner?: bool, timeSlotInterval?: string}
  --smsNotificationsEnabled: string@bool-completer # True indicates SMS notifications can be sent to the customers for the appointment of the service. Default value is false.
  --staffMemberIds: list # Represents those staff members who provide this service.
]: any -> record<id: string, additionalInformation: string, createdDateTime: string, customQuestions: table<isRequired: bool, questionId: string>, defaultDuration: string, defaultLocation: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, defaultPrice: float, defaultPriceType: string, defaultReminders: table<message: string, offset: string, recipients: string>, description: string, displayName: string, isAnonymousJoinEnabled: bool, isCustomerAllowedToManageBooking: bool, isHiddenFromCustomers: bool, isLocationOnline: bool, languageTag: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, notes: string, postBuffer: string, preBuffer: string, schedulingPolicy: record<allowStaffSelection: bool, customAvailabilities: list<record>, generalAvailability: record<availabilityType: string, businessHours: list>, isMeetingInviteToCustomersEnabled: bool, maximumAdvance: string, minimumLeadTime: string, sendConfirmationsToOwner: bool, timeSlotInterval: string>, smsNotificationsEnabled: bool, staffMemberIds: list<string>, webUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/services")
  let body = {id: $id, additionalInformation: $additionalInformation, createdDateTime: $createdDateTime, customQuestions: $customQuestions, defaultDuration: $defaultDuration, defaultLocation: $defaultLocation, defaultPrice: $defaultPrice, defaultPriceType: $defaultPriceType, defaultReminders: $defaultReminders, description: $description, displayName: $displayName, isAnonymousJoinEnabled: $isAnonymousJoinEnabled, isCustomerAllowedToManageBooking: $isCustomerAllowedToManageBooking, isHiddenFromCustomers: $isHiddenFromCustomers, isLocationOnline: $isLocationOnline, languageTag: $languageTag, lastUpdatedDateTime: $lastUpdatedDateTime, maximumAttendeesCount: $maximumAttendeesCount, notes: $notes, postBuffer: $postBuffer, preBuffer: $preBuffer, schedulingPolicy: $schedulingPolicy, smsNotificationsEnabled: $smsNotificationsEnabled, staffMemberIds: $staffMemberIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get bookingService
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/services/{bookingService-id}
# Docs: https://learn.microsoft.com/graph/api/bookingservice-get?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_GetService
export def "solutions-booking-businesses-services GetService" [
  bookingBusiness_id: string
  bookingService_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, additionalInformation: string, createdDateTime: string, customQuestions: table<isRequired: bool, questionId: string>, defaultDuration: string, defaultLocation: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, defaultPrice: float, defaultPriceType: string, defaultReminders: table<message: string, offset: string, recipients: string>, description: string, displayName: string, isAnonymousJoinEnabled: bool, isCustomerAllowedToManageBooking: bool, isHiddenFromCustomers: bool, isLocationOnline: bool, languageTag: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, notes: string, postBuffer: string, preBuffer: string, schedulingPolicy: record<allowStaffSelection: bool, customAvailabilities: list<record>, generalAvailability: record<availabilityType: string, businessHours: list>, isMeetingInviteToCustomersEnabled: bool, maximumAdvance: string, minimumLeadTime: string, sendConfirmationsToOwner: bool, timeSlotInterval: string>, smsNotificationsEnabled: bool, staffMemberIds: list<string>, webUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/services/($bookingService_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update bookingservice
#
# PATCH /solutions/bookingBusinesses/{bookingBusiness-id}/services/{bookingService-id}
# Docs: https://learn.microsoft.com/graph/api/bookingservice-update?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_UpdateService
# --customQuestions item shape: {isRequired?: bool, questionId?: string}
# --defaultLocation shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
# --defaultReminders item shape: {message?: string, offset?: string, recipients?: "allAttendees"|"staff"|"customer"|"unknownFutureValue"}
# --schedulingPolicy shape: {allowStaffSelection?: bool, customAvailabilities?: list, generalAvailability?: record, isMeetingInviteToCustomersEnabled?: bool, maximumAdvance?: string, minimumLeadTime?: string, sendConfirmationsToOwner?: bool, timeSlotInterval?: string}
export def "solutions-booking-businesses-services UpdateService" [
  bookingBusiness_id: string
  bookingService_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --additionalInformation: string # Additional information that is sent to the customer when an appointment is confirmed. (nullable)
  --createdDateTime: string # The date, time, and time zone when the service was created. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --customQuestions: list # Contains the set of custom questions associated with a particular service. — item shape: {isRequired?: bool, questionId?: string}
  --defaultDuration: string # The default length of the service, represented in numbers of days, hours, minutes, and seconds. For example, P11D23H59M59.999999999999S. (format: duration)
  --defaultLocation: record # shape: {address?: record, coordinates?: record, displayName?: string, locationEmailAddress?: string, locationType?: "default"|"conferenceRoom"|"homeAddress"|"businessAddress"|"geoCoordinates"|"streetAddress"|"hotel"|"restaurant"|"localBusiness"|"postalAddress", locationUri?: string, uniqueId?: string, uniqueIdType?: "unknown"|"locationStore"|"directory"|"private"|"bing"}
  --defaultPrice: float # The default monetary price for the service. (nullable, format: double)
  --defaultPriceType: string@defaultPriceType-completer # Represents the type of pricing of a booking service.
  --defaultReminders: list # The default set of reminders for an appointment of this service. The value of this property is available only when reading this bookingService by its ID. — item shape: {message?: string, offset?: string, recipients?: "allAttendees"|"staff"|"customer"|"unknownFutureValue"}
  --description: string # A text description for the service. (nullable)
  --displayName: string # A service name.
  --isAnonymousJoinEnabled: string@bool-completer # Indicates if an anonymousJoinWebUrl(webrtcUrl) is generated for the appointment booked for this service. The default value is false.
  --isCustomerAllowedToManageBooking: string@bool-completer # Indicates that the customer can manage bookings created by the staff. The default value is false. (nullable)
  --isHiddenFromCustomers: string@bool-completer # True indicates that this service isn't available to customers for booking.
  --isLocationOnline: string@bool-completer # Indicates that the appointments for the service are held online. The default value is false.
  --languageTag: string # The language of the self-service booking page.
  --lastUpdatedDateTime: string # The date, time, and time zone when the service was last updated. The timestamp type represents date and time information using ISO 8601 format and is always in UTC. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --maximumAttendeesCount: float # The maximum number of customers allowed in a service. If maximumAttendeesCount of the service is greater than 1, pass valid customer IDs while creating or updating an appointment. To create a customer, use the Create bookingCustomer operation. (format: int32)
  --notes: string # Additional information about this service. (nullable)
  --postBuffer: string # The time to buffer after an appointment for this service ends, and before the next customer appointment can be booked. (format: duration)
  --preBuffer: string # The time to buffer before an appointment for this service can start. (format: duration)
  --schedulingPolicy: record # This type represents the set of policies that dictate how bookings can be created in a Booking Calendar. — shape: {allowStaffSelection?: bool, customAvailabilities?: list, generalAvailability?: record, isMeetingInviteToCustomersEnabled?: bool, maximumAdvance?: string, minimumLeadTime?: string, sendConfirmationsToOwner?: bool, timeSlotInterval?: string}
  --smsNotificationsEnabled: string@bool-completer # True indicates SMS notifications can be sent to the customers for the appointment of the service. Default value is false.
  --staffMemberIds: list # Represents those staff members who provide this service.
]: any -> record<id: string, additionalInformation: string, createdDateTime: string, customQuestions: table<isRequired: bool, questionId: string>, defaultDuration: string, defaultLocation: record<address: record<city: string, countryOrRegion: string, postalCode: string, state: string, street: string>, coordinates: record<accuracy: float, altitude: float, altitudeAccuracy: float, latitude: float, longitude: float>, displayName: string, locationEmailAddress: string, locationType: string, locationUri: string, uniqueId: string, uniqueIdType: string>, defaultPrice: float, defaultPriceType: string, defaultReminders: table<message: string, offset: string, recipients: string>, description: string, displayName: string, isAnonymousJoinEnabled: bool, isCustomerAllowedToManageBooking: bool, isHiddenFromCustomers: bool, isLocationOnline: bool, languageTag: string, lastUpdatedDateTime: string, maximumAttendeesCount: float, notes: string, postBuffer: string, preBuffer: string, schedulingPolicy: record<allowStaffSelection: bool, customAvailabilities: list<record>, generalAvailability: record<availabilityType: string, businessHours: list>, isMeetingInviteToCustomersEnabled: bool, maximumAdvance: string, minimumLeadTime: string, sendConfirmationsToOwner: bool, timeSlotInterval: string>, smsNotificationsEnabled: bool, staffMemberIds: list<string>, webUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/services/($bookingService_id)")
  let body = {id: $id, additionalInformation: $additionalInformation, createdDateTime: $createdDateTime, customQuestions: $customQuestions, defaultDuration: $defaultDuration, defaultLocation: $defaultLocation, defaultPrice: $defaultPrice, defaultPriceType: $defaultPriceType, defaultReminders: $defaultReminders, description: $description, displayName: $displayName, isAnonymousJoinEnabled: $isAnonymousJoinEnabled, isCustomerAllowedToManageBooking: $isCustomerAllowedToManageBooking, isHiddenFromCustomers: $isHiddenFromCustomers, isLocationOnline: $isLocationOnline, languageTag: $languageTag, lastUpdatedDateTime: $lastUpdatedDateTime, maximumAttendeesCount: $maximumAttendeesCount, notes: $notes, postBuffer: $postBuffer, preBuffer: $preBuffer, schedulingPolicy: $schedulingPolicy, smsNotificationsEnabled: $smsNotificationsEnabled, staffMemberIds: $staffMemberIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete bookingService
#
# DELETE /solutions/bookingBusinesses/{bookingBusiness-id}/services/{bookingService-id}
# Docs: https://learn.microsoft.com/graph/api/bookingservice-delete?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_DeleteService
export def "solutions-booking-businesses-services DeleteService" [
  bookingBusiness_id: string
  bookingService_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/services/($bookingService_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/services/$count
# operationId: solution.bookingBusiness.service_GetCount
export def "solutions-booking-businesses-services-count GetCount" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/services/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List staffMembers
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/staffMembers
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-list-staffmembers?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_ListStaffMember
export def "solutions-booking-businesses-staff-members ListStaffMember" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/staffMembers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create bookingStaffMember
#
# POST /solutions/bookingBusinesses/{bookingBusiness-id}/staffMembers
# Docs: https://learn.microsoft.com/graph/api/bookingbusiness-post-staffmembers?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_CreateStaffMember
export def "solutions-booking-businesses-staff-members CreateStaffMember" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/staffMembers")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get bookingStaffMember
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/staffMembers/{bookingStaffMemberBase-id}
# Docs: https://learn.microsoft.com/graph/api/bookingstaffmember-get?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_GetStaffMember
export def "solutions-booking-businesses-staff-members GetStaffMember" [
  bookingBusiness_id: string
  bookingStaffMemberBase_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/staffMembers/($bookingStaffMemberBase_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update bookingstaffmember
#
# PATCH /solutions/bookingBusinesses/{bookingBusiness-id}/staffMembers/{bookingStaffMemberBase-id}
# Docs: https://learn.microsoft.com/graph/api/bookingstaffmember-update?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_UpdateStaffMember
export def "solutions-booking-businesses-staff-members UpdateStaffMember" [
  bookingBusiness_id: string
  bookingStaffMemberBase_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/staffMembers/($bookingStaffMemberBase_id)")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete bookingStaffMember
#
# DELETE /solutions/bookingBusinesses/{bookingBusiness-id}/staffMembers/{bookingStaffMemberBase-id}
# Docs: https://learn.microsoft.com/graph/api/bookingstaffmember-delete?view=graph-rest-1.0 — Find more info here
# operationId: solution.bookingBusiness_DeleteStaffMember
export def "solutions-booking-businesses-staff-members DeleteStaffMember" [
  bookingBusiness_id: string
  bookingStaffMemberBase_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/staffMembers/($bookingStaffMemberBase_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/bookingBusinesses/{bookingBusiness-id}/staffMembers/$count
# operationId: solution.bookingBusiness.staffMember_GetCount
export def "solutions-booking-businesses-staff-members-count GetCount" [
  bookingBusiness_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingBusinesses/($bookingBusiness_id)/staffMembers/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/bookingBusinesses/$count
# operationId: solution.bookingBusiness_GetCount
export def "solutions-booking-businesses-count GetCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/solutions/bookingBusinesses/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List bookingCurrencies
#
# GET /solutions/bookingCurrencies
# Docs: https://learn.microsoft.com/graph/api/bookingcurrency-list?view=graph-rest-1.0 — Find more info here
# operationId: solution_ListBookingCurrency
export def "solutions-booking-currencies ListBookingCurrency" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/solutions/bookingCurrencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new navigation property to bookingCurrencies for solutions
#
# POST /solutions/bookingCurrencies
# operationId: solution_CreateBookingCurrency
export def "solutions-booking-currencies CreateBookingCurrency" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --symbol: string # The currency symbol. For example, the currency symbol for the US dollar and for the Australian dollar is $.
]: any -> record<id: string, symbol: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/solutions/bookingCurrencies")
  let body = {id: $id, symbol: $symbol} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get bookingCurrency
#
# GET /solutions/bookingCurrencies/{bookingCurrency-id}
# Docs: https://learn.microsoft.com/graph/api/bookingcurrency-get?view=graph-rest-1.0 — Find more info here
# operationId: solution_GetBookingCurrency
export def "solutions-booking-currencies GetBookingCurrency" [
  bookingCurrency_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/bookingCurrencies/($bookingCurrency_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property bookingCurrencies in solutions
#
# PATCH /solutions/bookingCurrencies/{bookingCurrency-id}
# operationId: solution_UpdateBookingCurrency
export def "solutions-booking-currencies UpdateBookingCurrency" [
  bookingCurrency_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --symbol: string # The currency symbol. For example, the currency symbol for the US dollar and for the Australian dollar is $.
]: any -> record<id: string, symbol: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingCurrencies/($bookingCurrency_id)")
  let body = {id: $id, symbol: $symbol} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property bookingCurrencies for solutions
#
# DELETE /solutions/bookingCurrencies/{bookingCurrency-id}
# operationId: solution_DeleteBookingCurrency
export def "solutions-booking-currencies DeleteBookingCurrency" [
  bookingCurrency_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/bookingCurrencies/($bookingCurrency_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/bookingCurrencies/$count
# operationId: solution.bookingCurrency_GetCount
export def "solutions-booking-currencies-count GetCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/solutions/bookingCurrencies/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get virtualEvents from solutions
#
# GET /solutions/virtualEvents
# operationId: solution_GetVirtualEvent
export def "solutions-virtual-events GetVirtualEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, events: table<id: string, createdBy: record, description: record, displayName: string, endDateTime: record, externalEventInformation: list, settings: record, startDateTime: record, status: string, presenters: list, sessions: list>, townhalls: table<audience: string, coOrganizers: list, invitedAttendees: list, isInviteOnly: bool>, webinars: table<audience: string, coOrganizers: list, registrationConfiguration: record, registrations: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/solutions/virtualEvents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property virtualEvents in solutions
#
# PATCH /solutions/virtualEvents
# operationId: solution_UpdateVirtualEvent
# --events item shape: {id?: string, createdBy?: any, description?: record, displayName?: string, endDateTime?: record, externalEventInformation?: list, settings?: record, startDateTime?: record, status?: "draft"|"published"|"canceled"|"unknownFutureValue", presenters?: list, sessions?: list}
# --townhalls item shape: {audience?: "everyone"|"organization"|"unknownFutureValue", coOrganizers?: list, invitedAttendees?: list, isInviteOnly?: bool}
# --webinars item shape: {audience?: "everyone"|"organization"|"unknownFutureValue", coOrganizers?: list, registrationConfiguration?: any, registrations?: list}
export def "solutions-virtual-events UpdateVirtualEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --events: list # item shape: {id?: string, createdBy?: any, description?: record, displayName?: string, endDateTime?: record, externalEventInformation?: list, settings?: record, startDateTime?: record, status?: "draft"|"published"|"canceled"|"unknownFutureValue", presenters?: list, sessions?: list}
  --townhalls: list # A collection of town halls. Nullable. — item shape: {audience?: "everyone"|"organization"|"unknownFutureValue", coOrganizers?: list, invitedAttendees?: list, isInviteOnly?: bool}
  --webinars: list # A collection of webinars. Nullable. — item shape: {audience?: "everyone"|"organization"|"unknownFutureValue", coOrganizers?: list, registrationConfiguration?: any, registrations?: list}
]: any -> record<id: string, events: table<id: string, createdBy: record, description: record, displayName: string, endDateTime: record, externalEventInformation: list, settings: record, startDateTime: record, status: string, presenters: list, sessions: list>, townhalls: table<audience: string, coOrganizers: list, invitedAttendees: list, isInviteOnly: bool>, webinars: table<audience: string, coOrganizers: list, registrationConfiguration: record, registrations: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/solutions/virtualEvents")
  let body = {id: $id, events: $events, townhalls: $townhalls, webinars: $webinars} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property virtualEvents for solutions
#
# DELETE /solutions/virtualEvents
# operationId: solution_DeleteVirtualEvent
export def "solutions-virtual-events DeleteVirtualEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/solutions/virtualEvents")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get events from solutions
#
# GET /solutions/virtualEvents/events
# operationId: solution.virtualEvent_ListEvent
export def "solutions-virtual-events-events ListEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/solutions/virtualEvents/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new navigation property to events for solutions
#
# POST /solutions/virtualEvents/events
# operationId: solution.virtualEvent_CreateEvent
# --description shape: {content?: string, contentType?: "text"|"html"}
# --endDateTime shape: {dateTime?: string, timeZone?: string}
# --externalEventInformation item shape: {applicationId?: string, externalEventId?: string}
# --settings shape: {isAttendeeEmailNotificationEnabled?: bool}
# --startDateTime shape: {dateTime?: string, timeZone?: string}
# --presenters item shape: {id?: string, email?: string, identity?: record, presenterDetails?: record}
# --sessions item shape: {endDateTime?: record, startDateTime?: record, videoOnDemandWebUrl?: string}
export def "solutions-virtual-events-events CreateEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --createdBy: any
  --description: record # shape: {content?: string, contentType?: "text"|"html"}
  --displayName: string # The display name of the virtual event. (nullable)
  --endDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --externalEventInformation: list # The external information of a virtual event. Returned only for event organizers or coorganizers; otherwise, null. — item shape: {applicationId?: string, externalEventId?: string}
  --settings: record # shape: {isAttendeeEmailNotificationEnabled?: bool}
  --startDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --status: string@status-completer
  --presenters: list # The virtual event presenters. — item shape: {id?: string, email?: string, identity?: record, presenterDetails?: record}
  --sessions: list # The sessions for the virtual event. — item shape: {endDateTime?: record, startDateTime?: record, videoOnDemandWebUrl?: string}
]: any -> record<id: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>, applicationInstance: record<displayName: string, id: string>, assertedIdentity: record<displayName: string, id: string>, azureCommunicationServicesUser: record<displayName: string, id: string>, encrypted: record<displayName: string, id: string>, endpointType: string, guest: record<displayName: string, id: string>, onPremises: record<displayName: string, id: string>, phone: record<displayName: string, id: string>>, description: record<content: string, contentType: string>, displayName: string, endDateTime: record<dateTime: string, timeZone: string>, externalEventInformation: table<applicationId: string, externalEventId: string>, settings: record<isAttendeeEmailNotificationEnabled: bool>, startDateTime: record<dateTime: string, timeZone: string>, status: string, presenters: table<id: string, email: string, identity: record, presenterDetails: record>, sessions: table<endDateTime: record, startDateTime: record, videoOnDemandWebUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/solutions/virtualEvents/events")
  let body = {id: $id, createdBy: $createdBy, description: $description, displayName: $displayName, endDateTime: $endDateTime, externalEventInformation: $externalEventInformation, settings: $settings, startDateTime: $startDateTime, status: $status, presenters: $presenters, sessions: $sessions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get events from solutions
#
# GET /solutions/virtualEvents/events/{virtualEvent-id}
# operationId: solution.virtualEvent_GetEvent
export def "solutions-virtual-events-events GetEvent" [
  virtualEvent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>, applicationInstance: record<displayName: string, id: string>, assertedIdentity: record<displayName: string, id: string>, azureCommunicationServicesUser: record<displayName: string, id: string>, encrypted: record<displayName: string, id: string>, endpointType: string, guest: record<displayName: string, id: string>, onPremises: record<displayName: string, id: string>, phone: record<displayName: string, id: string>>, description: record<content: string, contentType: string>, displayName: string, endDateTime: record<dateTime: string, timeZone: string>, externalEventInformation: table<applicationId: string, externalEventId: string>, settings: record<isAttendeeEmailNotificationEnabled: bool>, startDateTime: record<dateTime: string, timeZone: string>, status: string, presenters: table<id: string, email: string, identity: record, presenterDetails: record>, sessions: table<endDateTime: record, startDateTime: record, videoOnDemandWebUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property events in solutions
#
# PATCH /solutions/virtualEvents/events/{virtualEvent-id}
# operationId: solution.virtualEvent_UpdateEvent
# --description shape: {content?: string, contentType?: "text"|"html"}
# --endDateTime shape: {dateTime?: string, timeZone?: string}
# --externalEventInformation item shape: {applicationId?: string, externalEventId?: string}
# --settings shape: {isAttendeeEmailNotificationEnabled?: bool}
# --startDateTime shape: {dateTime?: string, timeZone?: string}
# --presenters item shape: {id?: string, email?: string, identity?: record, presenterDetails?: record}
# --sessions item shape: {endDateTime?: record, startDateTime?: record, videoOnDemandWebUrl?: string}
export def "solutions-virtual-events-events UpdateEvent" [
  virtualEvent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --createdBy: any
  --description: record # shape: {content?: string, contentType?: "text"|"html"}
  --displayName: string # The display name of the virtual event. (nullable)
  --endDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --externalEventInformation: list # The external information of a virtual event. Returned only for event organizers or coorganizers; otherwise, null. — item shape: {applicationId?: string, externalEventId?: string}
  --settings: record # shape: {isAttendeeEmailNotificationEnabled?: bool}
  --startDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --status: string@status-completer
  --presenters: list # The virtual event presenters. — item shape: {id?: string, email?: string, identity?: record, presenterDetails?: record}
  --sessions: list # The sessions for the virtual event. — item shape: {endDateTime?: record, startDateTime?: record, videoOnDemandWebUrl?: string}
]: any -> record<id: string, createdBy: record<application: record<displayName: string, id: string>, device: record<displayName: string, id: string>, user: record<displayName: string, id: string>, applicationInstance: record<displayName: string, id: string>, assertedIdentity: record<displayName: string, id: string>, azureCommunicationServicesUser: record<displayName: string, id: string>, encrypted: record<displayName: string, id: string>, endpointType: string, guest: record<displayName: string, id: string>, onPremises: record<displayName: string, id: string>, phone: record<displayName: string, id: string>>, description: record<content: string, contentType: string>, displayName: string, endDateTime: record<dateTime: string, timeZone: string>, externalEventInformation: table<applicationId: string, externalEventId: string>, settings: record<isAttendeeEmailNotificationEnabled: bool>, startDateTime: record<dateTime: string, timeZone: string>, status: string, presenters: table<id: string, email: string, identity: record, presenterDetails: record>, sessions: table<endDateTime: record, startDateTime: record, videoOnDemandWebUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)")
  let body = {id: $id, createdBy: $createdBy, description: $description, displayName: $displayName, endDateTime: $endDateTime, externalEventInformation: $externalEventInformation, settings: $settings, startDateTime: $startDateTime, status: $status, presenters: $presenters, sessions: $sessions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property events for solutions
#
# DELETE /solutions/virtualEvents/events/{virtualEvent-id}
# operationId: solution.virtualEvent_DeleteEvent
export def "solutions-virtual-events-events DeleteEvent" [
  virtualEvent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke action cancel
#
# POST /solutions/virtualEvents/events/{virtualEvent-id}/microsoft.graph.cancel
# operationId: solution.virtualEvent.event_cancel
export def "solutions-virtual-events-events-microsoftgraphcancel cancel" [
  virtualEvent_id: string
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
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/microsoft.graph.cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke action publish
#
# POST /solutions/virtualEvents/events/{virtualEvent-id}/microsoft.graph.publish
# operationId: solution.virtualEvent.event_publish
export def "solutions-virtual-events-events-microsoftgraphpublish publish" [
  virtualEvent_id: string
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
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/microsoft.graph.publish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke action setExternalEventInformation
#
# POST /solutions/virtualEvents/events/{virtualEvent-id}/microsoft.graph.setExternalEventInformation
# operationId: solution.virtualEvent.event_setExternalEventInformation
export def "solutions-virtual-events-events-microsoftgraphset-external-event-information setExternalEventInformation" [
  virtualEvent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --externalEventId: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/microsoft.graph.setExternalEventInformation")
  let body = {externalEventId: $externalEventId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get presenters from solutions
#
# GET /solutions/virtualEvents/events/{virtualEvent-id}/presenters
# operationId: solution.virtualEvent.event_ListPresenter
export def "solutions-virtual-events-events-presenters ListPresenter" [
  virtualEvent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/presenters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new navigation property to presenters for solutions
#
# POST /solutions/virtualEvents/events/{virtualEvent-id}/presenters
# operationId: solution.virtualEvent.event_CreatePresenter
# --identity shape: {displayName?: string, id?: string}
# --presenterDetails shape: {bio?: record, company?: string, jobTitle?: string, linkedInProfileWebUrl?: string, personalSiteWebUrl?: string, photo?: string, twitterProfileWebUrl?: string}
export def "solutions-virtual-events-events-presenters CreatePresenter" [
  virtualEvent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --email: string # Email address of the presenter. (nullable)
  --identity: record # shape: {displayName?: string, id?: string}
  --presenterDetails: record # shape: {bio?: record, company?: string, jobTitle?: string, linkedInProfileWebUrl?: string, personalSiteWebUrl?: string, photo?: string, twitterProfileWebUrl?: string}
]: any -> record<id: string, email: string, identity: record<displayName: string, id: string>, presenterDetails: record<bio: record<content: string, contentType: string>, company: string, jobTitle: string, linkedInProfileWebUrl: string, personalSiteWebUrl: string, photo: string, twitterProfileWebUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/presenters")
  let body = {id: $id, email: $email, identity: $identity, presenterDetails: $presenterDetails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get presenters from solutions
#
# GET /solutions/virtualEvents/events/{virtualEvent-id}/presenters/{virtualEventPresenter-id}
# operationId: solution.virtualEvent.event_GetPresenter
export def "solutions-virtual-events-events-presenters GetPresenter" [
  virtualEvent_id: string
  virtualEventPresenter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, email: string, identity: record<displayName: string, id: string>, presenterDetails: record<bio: record<content: string, contentType: string>, company: string, jobTitle: string, linkedInProfileWebUrl: string, personalSiteWebUrl: string, photo: string, twitterProfileWebUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/presenters/($virtualEventPresenter_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property presenters in solutions
#
# PATCH /solutions/virtualEvents/events/{virtualEvent-id}/presenters/{virtualEventPresenter-id}
# operationId: solution.virtualEvent.event_UpdatePresenter
# --identity shape: {displayName?: string, id?: string}
# --presenterDetails shape: {bio?: record, company?: string, jobTitle?: string, linkedInProfileWebUrl?: string, personalSiteWebUrl?: string, photo?: string, twitterProfileWebUrl?: string}
export def "solutions-virtual-events-events-presenters UpdatePresenter" [
  virtualEvent_id: string
  virtualEventPresenter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --email: string # Email address of the presenter. (nullable)
  --identity: record # shape: {displayName?: string, id?: string}
  --presenterDetails: record # shape: {bio?: record, company?: string, jobTitle?: string, linkedInProfileWebUrl?: string, personalSiteWebUrl?: string, photo?: string, twitterProfileWebUrl?: string}
]: any -> record<id: string, email: string, identity: record<displayName: string, id: string>, presenterDetails: record<bio: record<content: string, contentType: string>, company: string, jobTitle: string, linkedInProfileWebUrl: string, personalSiteWebUrl: string, photo: string, twitterProfileWebUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/presenters/($virtualEventPresenter_id)")
  let body = {id: $id, email: $email, identity: $identity, presenterDetails: $presenterDetails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property presenters for solutions
#
# DELETE /solutions/virtualEvents/events/{virtualEvent-id}/presenters/{virtualEventPresenter-id}
# operationId: solution.virtualEvent.event_DeletePresenter
export def "solutions-virtual-events-events-presenters DeletePresenter" [
  virtualEvent_id: string
  virtualEventPresenter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/presenters/($virtualEventPresenter_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/events/{virtualEvent-id}/presenters/$count
# operationId: solution.virtualEvent.event.presenter_GetCount
export def "solutions-virtual-events-events-presenters-count GetCount" [
  virtualEvent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/presenters/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get sessions from solutions
#
# GET /solutions/virtualEvents/events/{virtualEvent-id}/sessions
# operationId: solution.virtualEvent.event_ListSession
export def "solutions-virtual-events-events-sessions ListSession" [
  virtualEvent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new navigation property to sessions for solutions
#
# POST /solutions/virtualEvents/events/{virtualEvent-id}/sessions
# operationId: solution.virtualEvent.event_CreateSession
# --endDateTime shape: {dateTime?: string, timeZone?: string}
# --startDateTime shape: {dateTime?: string, timeZone?: string}
export def "solutions-virtual-events-events-sessions CreateSession" [
  virtualEvent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --startDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --videoOnDemandWebUrl: string # The URL of the video on demand (VOD) for Microsoft Teams events that allows webinar and town hall organizers to quickly publish and share event recordings. (nullable)
]: any -> record<endDateTime: record<dateTime: string, timeZone: string>, startDateTime: record<dateTime: string, timeZone: string>, videoOnDemandWebUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions")
  let body = {endDateTime: $endDateTime, startDateTime: $startDateTime, videoOnDemandWebUrl: $videoOnDemandWebUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get sessions from solutions
#
# GET /solutions/virtualEvents/events/{virtualEvent-id}/sessions/{virtualEventSession-id}
# operationId: solution.virtualEvent.event_GetSession
export def "solutions-virtual-events-events-sessions GetSession" [
  virtualEvent_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<endDateTime: record<dateTime: string, timeZone: string>, startDateTime: record<dateTime: string, timeZone: string>, videoOnDemandWebUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/($virtualEventSession_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property sessions in solutions
#
# PATCH /solutions/virtualEvents/events/{virtualEvent-id}/sessions/{virtualEventSession-id}
# operationId: solution.virtualEvent.event_UpdateSession
# --endDateTime shape: {dateTime?: string, timeZone?: string}
# --startDateTime shape: {dateTime?: string, timeZone?: string}
export def "solutions-virtual-events-events-sessions UpdateSession" [
  virtualEvent_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --startDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --videoOnDemandWebUrl: string # The URL of the video on demand (VOD) for Microsoft Teams events that allows webinar and town hall organizers to quickly publish and share event recordings. (nullable)
]: any -> record<endDateTime: record<dateTime: string, timeZone: string>, startDateTime: record<dateTime: string, timeZone: string>, videoOnDemandWebUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/($virtualEventSession_id)")
  let body = {endDateTime: $endDateTime, startDateTime: $startDateTime, videoOnDemandWebUrl: $videoOnDemandWebUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property sessions for solutions
#
# DELETE /solutions/virtualEvents/events/{virtualEvent-id}/sessions/{virtualEventSession-id}
# operationId: solution.virtualEvent.event_DeleteSession
export def "solutions-virtual-events-events-sessions DeleteSession" [
  virtualEvent_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/($virtualEventSession_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get attendanceReports from solutions
#
# GET /solutions/virtualEvents/events/{virtualEvent-id}/sessions/{virtualEventSession-id}/attendanceReports
# operationId: solution.virtualEvent.event.session_ListAttendanceReport
export def "solutions-virtual-events-events-sessions-attendance-reports ListAttendanceReport" [
  virtualEvent_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/($virtualEventSession_id)/attendanceReports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new navigation property to attendanceReports for solutions
#
# POST /solutions/virtualEvents/events/{virtualEvent-id}/sessions/{virtualEventSession-id}/attendanceReports
# operationId: solution.virtualEvent.event.session_CreateAttendanceReport
# --externalEventInformation item shape: {applicationId?: string, externalEventId?: string}
# --attendanceRecords item shape: {id?: string, attendanceIntervals?: list, emailAddress?: string, externalRegistrationInformation?: record, identity?: record, registrationId?: string, role?: string, totalAttendanceInSeconds?: float}
export def "solutions-virtual-events-events-sessions-attendance-reports CreateAttendanceReport" [
  virtualEvent_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --externalEventInformation: list # The external information of a virtual event. Returned only for event organizers or coorganizers. Read-only. — item shape: {applicationId?: string, externalEventId?: string}
  --meetingEndDateTime: string # UTC time when the meeting ended. Read-only. (nullable, format: date-time)
  --meetingStartDateTime: string # UTC time when the meeting started. Read-only. (nullable, format: date-time)
  --totalParticipantCount: float # Total number of participants. Read-only. (nullable, format: int32)
  --attendanceRecords: list # List of attendance records of an attendance report. Read-only. — item shape: {id?: string, attendanceIntervals?: list, emailAddress?: string, externalRegistrationInformation?: record, identity?: record, registrationId?: string, role?: string, totalAttendanceInSeconds?: float}
]: any -> record<id: string, externalEventInformation: table<applicationId: string, externalEventId: string>, meetingEndDateTime: string, meetingStartDateTime: string, totalParticipantCount: float, attendanceRecords: table<id: string, attendanceIntervals: list, emailAddress: string, externalRegistrationInformation: record, identity: record, registrationId: string, role: string, totalAttendanceInSeconds: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/($virtualEventSession_id)/attendanceReports")
  let body = {id: $id, externalEventInformation: $externalEventInformation, meetingEndDateTime: $meetingEndDateTime, meetingStartDateTime: $meetingStartDateTime, totalParticipantCount: $totalParticipantCount, attendanceRecords: $attendanceRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get attendanceReports from solutions
#
# GET /solutions/virtualEvents/events/{virtualEvent-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}
# operationId: solution.virtualEvent.event.session_GetAttendanceReport
export def "solutions-virtual-events-events-sessions-attendance-reports GetAttendanceReport" [
  virtualEvent_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, externalEventInformation: table<applicationId: string, externalEventId: string>, meetingEndDateTime: string, meetingStartDateTime: string, totalParticipantCount: float, attendanceRecords: table<id: string, attendanceIntervals: list, emailAddress: string, externalRegistrationInformation: record, identity: record, registrationId: string, role: string, totalAttendanceInSeconds: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property attendanceReports in solutions
#
# PATCH /solutions/virtualEvents/events/{virtualEvent-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}
# operationId: solution.virtualEvent.event.session_UpdateAttendanceReport
# --externalEventInformation item shape: {applicationId?: string, externalEventId?: string}
# --attendanceRecords item shape: {id?: string, attendanceIntervals?: list, emailAddress?: string, externalRegistrationInformation?: record, identity?: record, registrationId?: string, role?: string, totalAttendanceInSeconds?: float}
export def "solutions-virtual-events-events-sessions-attendance-reports UpdateAttendanceReport" [
  virtualEvent_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --externalEventInformation: list # The external information of a virtual event. Returned only for event organizers or coorganizers. Read-only. — item shape: {applicationId?: string, externalEventId?: string}
  --meetingEndDateTime: string # UTC time when the meeting ended. Read-only. (nullable, format: date-time)
  --meetingStartDateTime: string # UTC time when the meeting started. Read-only. (nullable, format: date-time)
  --totalParticipantCount: float # Total number of participants. Read-only. (nullable, format: int32)
  --attendanceRecords: list # List of attendance records of an attendance report. Read-only. — item shape: {id?: string, attendanceIntervals?: list, emailAddress?: string, externalRegistrationInformation?: record, identity?: record, registrationId?: string, role?: string, totalAttendanceInSeconds?: float}
]: any -> record<id: string, externalEventInformation: table<applicationId: string, externalEventId: string>, meetingEndDateTime: string, meetingStartDateTime: string, totalParticipantCount: float, attendanceRecords: table<id: string, attendanceIntervals: list, emailAddress: string, externalRegistrationInformation: record, identity: record, registrationId: string, role: string, totalAttendanceInSeconds: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)")
  let body = {id: $id, externalEventInformation: $externalEventInformation, meetingEndDateTime: $meetingEndDateTime, meetingStartDateTime: $meetingStartDateTime, totalParticipantCount: $totalParticipantCount, attendanceRecords: $attendanceRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property attendanceReports for solutions
#
# DELETE /solutions/virtualEvents/events/{virtualEvent-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}
# operationId: solution.virtualEvent.event.session_DeleteAttendanceReport
export def "solutions-virtual-events-events-sessions-attendance-reports DeleteAttendanceReport" [
  virtualEvent_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get attendanceRecords from solutions
#
# GET /solutions/virtualEvents/events/{virtualEvent-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords
# operationId: solution.virtualEvent.event.session.attendanceReport_ListAttendanceRecord
export def "solutions-virtual-events-events-sessions-attendance-reports-attendance-records ListAttendanceRecord" [
  virtualEvent_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new navigation property to attendanceRecords for solutions
#
# POST /solutions/virtualEvents/events/{virtualEvent-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords
# operationId: solution.virtualEvent.event.session.attendanceReport_CreateAttendanceRecord
# --attendanceIntervals item shape: {durationInSeconds?: float, joinDateTime?: string, leaveDateTime?: string}
# --externalRegistrationInformation shape: {referrer?: string, registrationId?: string}
# --identity shape: {displayName?: string, id?: string}
export def "solutions-virtual-events-events-sessions-attendance-reports-attendance-records CreateAttendanceRecord" [
  virtualEvent_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --attendanceIntervals: list # List of time periods between joining and leaving a meeting. — item shape: {durationInSeconds?: float, joinDateTime?: string, leaveDateTime?: string}
  --emailAddress: string # Email address of the user associated with this attendance record. (nullable)
  --externalRegistrationInformation: record # shape: {referrer?: string, registrationId?: string}
  --identity: record # shape: {displayName?: string, id?: string}
  --registrationId: string # Unique identifier of a virtualEventRegistration that is available to all participants registered for the virtualEventWebinar. (nullable)
  --role: string # Role of the attendee. The possible values are: None, Attendee, Presenter, and Organizer. (nullable)
  --totalAttendanceInSeconds: float # Total duration of the attendances in seconds. (nullable, format: int32)
]: any -> record<id: string, attendanceIntervals: table<durationInSeconds: float, joinDateTime: string, leaveDateTime: string>, emailAddress: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, identity: record<displayName: string, id: string>, registrationId: string, role: string, totalAttendanceInSeconds: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords")
  let body = {id: $id, attendanceIntervals: $attendanceIntervals, emailAddress: $emailAddress, externalRegistrationInformation: $externalRegistrationInformation, identity: $identity, registrationId: $registrationId, role: $role, totalAttendanceInSeconds: $totalAttendanceInSeconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get attendanceRecords from solutions
#
# GET /solutions/virtualEvents/events/{virtualEvent-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords/{attendanceRecord-id}
# operationId: solution.virtualEvent.event.session.attendanceReport_GetAttendanceRecord
export def "solutions-virtual-events-events-sessions-attendance-reports-attendance-records GetAttendanceRecord" [
  virtualEvent_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  attendanceRecord_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, attendanceIntervals: table<durationInSeconds: float, joinDateTime: string, leaveDateTime: string>, emailAddress: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, identity: record<displayName: string, id: string>, registrationId: string, role: string, totalAttendanceInSeconds: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords/($attendanceRecord_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property attendanceRecords in solutions
#
# PATCH /solutions/virtualEvents/events/{virtualEvent-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords/{attendanceRecord-id}
# operationId: solution.virtualEvent.event.session.attendanceReport_UpdateAttendanceRecord
# --attendanceIntervals item shape: {durationInSeconds?: float, joinDateTime?: string, leaveDateTime?: string}
# --externalRegistrationInformation shape: {referrer?: string, registrationId?: string}
# --identity shape: {displayName?: string, id?: string}
export def "solutions-virtual-events-events-sessions-attendance-reports-attendance-records UpdateAttendanceRecord" [
  virtualEvent_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  attendanceRecord_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --attendanceIntervals: list # List of time periods between joining and leaving a meeting. — item shape: {durationInSeconds?: float, joinDateTime?: string, leaveDateTime?: string}
  --emailAddress: string # Email address of the user associated with this attendance record. (nullable)
  --externalRegistrationInformation: record # shape: {referrer?: string, registrationId?: string}
  --identity: record # shape: {displayName?: string, id?: string}
  --registrationId: string # Unique identifier of a virtualEventRegistration that is available to all participants registered for the virtualEventWebinar. (nullable)
  --role: string # Role of the attendee. The possible values are: None, Attendee, Presenter, and Organizer. (nullable)
  --totalAttendanceInSeconds: float # Total duration of the attendances in seconds. (nullable, format: int32)
]: any -> record<id: string, attendanceIntervals: table<durationInSeconds: float, joinDateTime: string, leaveDateTime: string>, emailAddress: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, identity: record<displayName: string, id: string>, registrationId: string, role: string, totalAttendanceInSeconds: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords/($attendanceRecord_id)")
  let body = {id: $id, attendanceIntervals: $attendanceIntervals, emailAddress: $emailAddress, externalRegistrationInformation: $externalRegistrationInformation, identity: $identity, registrationId: $registrationId, role: $role, totalAttendanceInSeconds: $totalAttendanceInSeconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property attendanceRecords for solutions
#
# DELETE /solutions/virtualEvents/events/{virtualEvent-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords/{attendanceRecord-id}
# operationId: solution.virtualEvent.event.session.attendanceReport_DeleteAttendanceRecord
export def "solutions-virtual-events-events-sessions-attendance-reports-attendance-records DeleteAttendanceRecord" [
  virtualEvent_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  attendanceRecord_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords/($attendanceRecord_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/events/{virtualEvent-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords/$count
# operationId: solution.virtualEvent.event.session.attendanceReport.attendanceRecord_GetCount
export def "solutions-virtual-events-events-sessions-attendance-reports-attendance-records-count GetCount" [
  virtualEvent_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/events/{virtualEvent-id}/sessions/{virtualEventSession-id}/attendanceReports/$count
# operationId: solution.virtualEvent.event.session.attendanceReport_GetCount
export def "solutions-virtual-events-events-sessions-attendance-reports-count GetCount" [
  virtualEvent_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/($virtualEventSession_id)/attendanceReports/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/events/{virtualEvent-id}/sessions/$count
# operationId: solution.virtualEvent.event.session_GetCount
export def "solutions-virtual-events-events-sessions-count GetCount" [
  virtualEvent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/events/($virtualEvent_id)/sessions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/events/$count
# operationId: solution.virtualEvent.event_GetCount
export def "solutions-virtual-events-events-count GetCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/solutions/virtualEvents/events/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get virtualEventTownhall
#
# GET /solutions/virtualEvents/townhalls
# operationId: solution.virtualEvent_ListTownhall
export def "solutions-virtual-events-townhalls ListTownhall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/solutions/virtualEvents/townhalls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create virtualEventTownhall
#
# POST /solutions/virtualEvents/townhalls
# Docs: https://learn.microsoft.com/graph/api/virtualeventsroot-post-townhalls?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent_CreateTownhall
# --coOrganizers item shape: {displayName?: string, id?: string, tenantId?: string}
# --invitedAttendees item shape: {displayName?: string, id?: string}
export def "solutions-virtual-events-townhalls CreateTownhall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --audience: string@audience-completer
  --coOrganizers: list # Identity information of the coorganizers of the town hall. — item shape: {displayName?: string, id?: string, tenantId?: string}
  --invitedAttendees: list # The attendees invited to the town hall. The supported identities are: communicationsUserIdentity and communicationsGuestIdentity. — item shape: {displayName?: string, id?: string}
  --isInviteOnly: string@bool-completer # Indicates whether the town hall is only open to invited people and groups within your organization. The isInviteOnly property can only be true if the value of the audience property is set to organization. (nullable)
]: any -> record<audience: string, coOrganizers: table<displayName: string, id: string, tenantId: string>, invitedAttendees: table<displayName: string, id: string>, isInviteOnly: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/solutions/virtualEvents/townhalls")
  let body = {audience: $audience, coOrganizers: $coOrganizers, invitedAttendees: $invitedAttendees, isInviteOnly: $isInviteOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get virtualEventTownhall
#
# GET /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}
# Docs: https://learn.microsoft.com/graph/api/virtualeventtownhall-get?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent_GetTownhall
export def "solutions-virtual-events-townhalls GetTownhall" [
  virtualEventTownhall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<audience: string, coOrganizers: table<displayName: string, id: string, tenantId: string>, invitedAttendees: table<displayName: string, id: string>, isInviteOnly: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update virtualEventTownhall
#
# PATCH /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}
# Docs: https://learn.microsoft.com/graph/api/virtualeventtownhall-update?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent_UpdateTownhall
# --coOrganizers item shape: {displayName?: string, id?: string, tenantId?: string}
# --invitedAttendees item shape: {displayName?: string, id?: string}
export def "solutions-virtual-events-townhalls UpdateTownhall" [
  virtualEventTownhall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --audience: string@audience-completer
  --coOrganizers: list # Identity information of the coorganizers of the town hall. — item shape: {displayName?: string, id?: string, tenantId?: string}
  --invitedAttendees: list # The attendees invited to the town hall. The supported identities are: communicationsUserIdentity and communicationsGuestIdentity. — item shape: {displayName?: string, id?: string}
  --isInviteOnly: string@bool-completer # Indicates whether the town hall is only open to invited people and groups within your organization. The isInviteOnly property can only be true if the value of the audience property is set to organization. (nullable)
]: any -> record<audience: string, coOrganizers: table<displayName: string, id: string, tenantId: string>, invitedAttendees: table<displayName: string, id: string>, isInviteOnly: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)")
  let body = {audience: $audience, coOrganizers: $coOrganizers, invitedAttendees: $invitedAttendees, isInviteOnly: $isInviteOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property townhalls for solutions
#
# DELETE /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}
# operationId: solution.virtualEvent_DeleteTownhall
export def "solutions-virtual-events-townhalls DeleteTownhall" [
  virtualEventTownhall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List presenters
#
# GET /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/presenters
# Docs: https://learn.microsoft.com/graph/api/virtualevent-list-presenters?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.townhall_ListPresenter
export def "solutions-virtual-events-townhalls-presenters ListPresenter" [
  virtualEventTownhall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/presenters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create virtualEventPresenter
#
# POST /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/presenters
# Docs: https://learn.microsoft.com/graph/api/virtualevent-post-presenters?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.townhall_CreatePresenter
# --identity shape: {displayName?: string, id?: string}
# --presenterDetails shape: {bio?: record, company?: string, jobTitle?: string, linkedInProfileWebUrl?: string, personalSiteWebUrl?: string, photo?: string, twitterProfileWebUrl?: string}
export def "solutions-virtual-events-townhalls-presenters CreatePresenter" [
  virtualEventTownhall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --email: string # Email address of the presenter. (nullable)
  --identity: record # shape: {displayName?: string, id?: string}
  --presenterDetails: record # shape: {bio?: record, company?: string, jobTitle?: string, linkedInProfileWebUrl?: string, personalSiteWebUrl?: string, photo?: string, twitterProfileWebUrl?: string}
]: any -> record<id: string, email: string, identity: record<displayName: string, id: string>, presenterDetails: record<bio: record<content: string, contentType: string>, company: string, jobTitle: string, linkedInProfileWebUrl: string, personalSiteWebUrl: string, photo: string, twitterProfileWebUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/presenters")
  let body = {id: $id, email: $email, identity: $identity, presenterDetails: $presenterDetails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get virtualEventPresenter
#
# GET /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/presenters/{virtualEventPresenter-id}
# Docs: https://learn.microsoft.com/graph/api/virtualeventpresenter-get?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.townhall_GetPresenter
export def "solutions-virtual-events-townhalls-presenters GetPresenter" [
  virtualEventTownhall_id: string
  virtualEventPresenter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, email: string, identity: record<displayName: string, id: string>, presenterDetails: record<bio: record<content: string, contentType: string>, company: string, jobTitle: string, linkedInProfileWebUrl: string, personalSiteWebUrl: string, photo: string, twitterProfileWebUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/presenters/($virtualEventPresenter_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property presenters in solutions
#
# PATCH /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/presenters/{virtualEventPresenter-id}
# operationId: solution.virtualEvent.townhall_UpdatePresenter
# --identity shape: {displayName?: string, id?: string}
# --presenterDetails shape: {bio?: record, company?: string, jobTitle?: string, linkedInProfileWebUrl?: string, personalSiteWebUrl?: string, photo?: string, twitterProfileWebUrl?: string}
export def "solutions-virtual-events-townhalls-presenters UpdatePresenter" [
  virtualEventTownhall_id: string
  virtualEventPresenter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --email: string # Email address of the presenter. (nullable)
  --identity: record # shape: {displayName?: string, id?: string}
  --presenterDetails: record # shape: {bio?: record, company?: string, jobTitle?: string, linkedInProfileWebUrl?: string, personalSiteWebUrl?: string, photo?: string, twitterProfileWebUrl?: string}
]: any -> record<id: string, email: string, identity: record<displayName: string, id: string>, presenterDetails: record<bio: record<content: string, contentType: string>, company: string, jobTitle: string, linkedInProfileWebUrl: string, personalSiteWebUrl: string, photo: string, twitterProfileWebUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/presenters/($virtualEventPresenter_id)")
  let body = {id: $id, email: $email, identity: $identity, presenterDetails: $presenterDetails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete virtualEventPresenter
#
# DELETE /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/presenters/{virtualEventPresenter-id}
# Docs: https://learn.microsoft.com/graph/api/virtualeventpresenter-delete?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.townhall_DeletePresenter
export def "solutions-virtual-events-townhalls-presenters DeletePresenter" [
  virtualEventTownhall_id: string
  virtualEventPresenter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/presenters/($virtualEventPresenter_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/presenters/$count
# operationId: solution.virtualEvent.townhall.presenter_GetCount
export def "solutions-virtual-events-townhalls-presenters-count GetCount" [
  virtualEventTownhall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/presenters/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get sessions from solutions
#
# GET /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions
# operationId: solution.virtualEvent.townhall_ListSession
export def "solutions-virtual-events-townhalls-sessions ListSession" [
  virtualEventTownhall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new navigation property to sessions for solutions
#
# POST /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions
# operationId: solution.virtualEvent.townhall_CreateSession
# --endDateTime shape: {dateTime?: string, timeZone?: string}
# --startDateTime shape: {dateTime?: string, timeZone?: string}
export def "solutions-virtual-events-townhalls-sessions CreateSession" [
  virtualEventTownhall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --startDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --videoOnDemandWebUrl: string # The URL of the video on demand (VOD) for Microsoft Teams events that allows webinar and town hall organizers to quickly publish and share event recordings. (nullable)
]: any -> record<endDateTime: record<dateTime: string, timeZone: string>, startDateTime: record<dateTime: string, timeZone: string>, videoOnDemandWebUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions")
  let body = {endDateTime: $endDateTime, startDateTime: $startDateTime, videoOnDemandWebUrl: $videoOnDemandWebUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get sessions from solutions
#
# GET /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/{virtualEventSession-id}
# operationId: solution.virtualEvent.townhall_GetSession
export def "solutions-virtual-events-townhalls-sessions GetSession" [
  virtualEventTownhall_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<endDateTime: record<dateTime: string, timeZone: string>, startDateTime: record<dateTime: string, timeZone: string>, videoOnDemandWebUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/($virtualEventSession_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property sessions in solutions
#
# PATCH /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/{virtualEventSession-id}
# operationId: solution.virtualEvent.townhall_UpdateSession
# --endDateTime shape: {dateTime?: string, timeZone?: string}
# --startDateTime shape: {dateTime?: string, timeZone?: string}
export def "solutions-virtual-events-townhalls-sessions UpdateSession" [
  virtualEventTownhall_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --startDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --videoOnDemandWebUrl: string # The URL of the video on demand (VOD) for Microsoft Teams events that allows webinar and town hall organizers to quickly publish and share event recordings. (nullable)
]: any -> record<endDateTime: record<dateTime: string, timeZone: string>, startDateTime: record<dateTime: string, timeZone: string>, videoOnDemandWebUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/($virtualEventSession_id)")
  let body = {endDateTime: $endDateTime, startDateTime: $startDateTime, videoOnDemandWebUrl: $videoOnDemandWebUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property sessions for solutions
#
# DELETE /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/{virtualEventSession-id}
# operationId: solution.virtualEvent.townhall_DeleteSession
export def "solutions-virtual-events-townhalls-sessions DeleteSession" [
  virtualEventTownhall_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/($virtualEventSession_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List meetingAttendanceReports
#
# GET /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/{virtualEventSession-id}/attendanceReports
# Docs: https://learn.microsoft.com/graph/api/meetingattendancereport-list?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.townhall.session_ListAttendanceReport
export def "solutions-virtual-events-townhalls-sessions-attendance-reports ListAttendanceReport" [
  virtualEventTownhall_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/($virtualEventSession_id)/attendanceReports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new navigation property to attendanceReports for solutions
#
# POST /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/{virtualEventSession-id}/attendanceReports
# operationId: solution.virtualEvent.townhall.session_CreateAttendanceReport
# --externalEventInformation item shape: {applicationId?: string, externalEventId?: string}
# --attendanceRecords item shape: {id?: string, attendanceIntervals?: list, emailAddress?: string, externalRegistrationInformation?: record, identity?: record, registrationId?: string, role?: string, totalAttendanceInSeconds?: float}
export def "solutions-virtual-events-townhalls-sessions-attendance-reports CreateAttendanceReport" [
  virtualEventTownhall_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --externalEventInformation: list # The external information of a virtual event. Returned only for event organizers or coorganizers. Read-only. — item shape: {applicationId?: string, externalEventId?: string}
  --meetingEndDateTime: string # UTC time when the meeting ended. Read-only. (nullable, format: date-time)
  --meetingStartDateTime: string # UTC time when the meeting started. Read-only. (nullable, format: date-time)
  --totalParticipantCount: float # Total number of participants. Read-only. (nullable, format: int32)
  --attendanceRecords: list # List of attendance records of an attendance report. Read-only. — item shape: {id?: string, attendanceIntervals?: list, emailAddress?: string, externalRegistrationInformation?: record, identity?: record, registrationId?: string, role?: string, totalAttendanceInSeconds?: float}
]: any -> record<id: string, externalEventInformation: table<applicationId: string, externalEventId: string>, meetingEndDateTime: string, meetingStartDateTime: string, totalParticipantCount: float, attendanceRecords: table<id: string, attendanceIntervals: list, emailAddress: string, externalRegistrationInformation: record, identity: record, registrationId: string, role: string, totalAttendanceInSeconds: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/($virtualEventSession_id)/attendanceReports")
  let body = {id: $id, externalEventInformation: $externalEventInformation, meetingEndDateTime: $meetingEndDateTime, meetingStartDateTime: $meetingStartDateTime, totalParticipantCount: $totalParticipantCount, attendanceRecords: $attendanceRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get meetingAttendanceReport
#
# GET /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}
# Docs: https://learn.microsoft.com/graph/api/meetingattendancereport-get?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.townhall.session_GetAttendanceReport
export def "solutions-virtual-events-townhalls-sessions-attendance-reports GetAttendanceReport" [
  virtualEventTownhall_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, externalEventInformation: table<applicationId: string, externalEventId: string>, meetingEndDateTime: string, meetingStartDateTime: string, totalParticipantCount: float, attendanceRecords: table<id: string, attendanceIntervals: list, emailAddress: string, externalRegistrationInformation: record, identity: record, registrationId: string, role: string, totalAttendanceInSeconds: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property attendanceReports in solutions
#
# PATCH /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}
# operationId: solution.virtualEvent.townhall.session_UpdateAttendanceReport
# --externalEventInformation item shape: {applicationId?: string, externalEventId?: string}
# --attendanceRecords item shape: {id?: string, attendanceIntervals?: list, emailAddress?: string, externalRegistrationInformation?: record, identity?: record, registrationId?: string, role?: string, totalAttendanceInSeconds?: float}
export def "solutions-virtual-events-townhalls-sessions-attendance-reports UpdateAttendanceReport" [
  virtualEventTownhall_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --externalEventInformation: list # The external information of a virtual event. Returned only for event organizers or coorganizers. Read-only. — item shape: {applicationId?: string, externalEventId?: string}
  --meetingEndDateTime: string # UTC time when the meeting ended. Read-only. (nullable, format: date-time)
  --meetingStartDateTime: string # UTC time when the meeting started. Read-only. (nullable, format: date-time)
  --totalParticipantCount: float # Total number of participants. Read-only. (nullable, format: int32)
  --attendanceRecords: list # List of attendance records of an attendance report. Read-only. — item shape: {id?: string, attendanceIntervals?: list, emailAddress?: string, externalRegistrationInformation?: record, identity?: record, registrationId?: string, role?: string, totalAttendanceInSeconds?: float}
]: any -> record<id: string, externalEventInformation: table<applicationId: string, externalEventId: string>, meetingEndDateTime: string, meetingStartDateTime: string, totalParticipantCount: float, attendanceRecords: table<id: string, attendanceIntervals: list, emailAddress: string, externalRegistrationInformation: record, identity: record, registrationId: string, role: string, totalAttendanceInSeconds: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)")
  let body = {id: $id, externalEventInformation: $externalEventInformation, meetingEndDateTime: $meetingEndDateTime, meetingStartDateTime: $meetingStartDateTime, totalParticipantCount: $totalParticipantCount, attendanceRecords: $attendanceRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property attendanceReports for solutions
#
# DELETE /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}
# operationId: solution.virtualEvent.townhall.session_DeleteAttendanceReport
export def "solutions-virtual-events-townhalls-sessions-attendance-reports DeleteAttendanceReport" [
  virtualEventTownhall_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List attendanceRecords
#
# GET /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords
# Docs: https://learn.microsoft.com/graph/api/attendancerecord-list?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.townhall.session.attendanceReport_ListAttendanceRecord
export def "solutions-virtual-events-townhalls-sessions-attendance-reports-attendance-records ListAttendanceRecord" [
  virtualEventTownhall_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new navigation property to attendanceRecords for solutions
#
# POST /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords
# operationId: solution.virtualEvent.townhall.session.attendanceReport_CreateAttendanceRecord
# --attendanceIntervals item shape: {durationInSeconds?: float, joinDateTime?: string, leaveDateTime?: string}
# --externalRegistrationInformation shape: {referrer?: string, registrationId?: string}
# --identity shape: {displayName?: string, id?: string}
export def "solutions-virtual-events-townhalls-sessions-attendance-reports-attendance-records CreateAttendanceRecord" [
  virtualEventTownhall_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --attendanceIntervals: list # List of time periods between joining and leaving a meeting. — item shape: {durationInSeconds?: float, joinDateTime?: string, leaveDateTime?: string}
  --emailAddress: string # Email address of the user associated with this attendance record. (nullable)
  --externalRegistrationInformation: record # shape: {referrer?: string, registrationId?: string}
  --identity: record # shape: {displayName?: string, id?: string}
  --registrationId: string # Unique identifier of a virtualEventRegistration that is available to all participants registered for the virtualEventWebinar. (nullable)
  --role: string # Role of the attendee. The possible values are: None, Attendee, Presenter, and Organizer. (nullable)
  --totalAttendanceInSeconds: float # Total duration of the attendances in seconds. (nullable, format: int32)
]: any -> record<id: string, attendanceIntervals: table<durationInSeconds: float, joinDateTime: string, leaveDateTime: string>, emailAddress: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, identity: record<displayName: string, id: string>, registrationId: string, role: string, totalAttendanceInSeconds: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords")
  let body = {id: $id, attendanceIntervals: $attendanceIntervals, emailAddress: $emailAddress, externalRegistrationInformation: $externalRegistrationInformation, identity: $identity, registrationId: $registrationId, role: $role, totalAttendanceInSeconds: $totalAttendanceInSeconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get attendanceRecords from solutions
#
# GET /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords/{attendanceRecord-id}
# operationId: solution.virtualEvent.townhall.session.attendanceReport_GetAttendanceRecord
export def "solutions-virtual-events-townhalls-sessions-attendance-reports-attendance-records GetAttendanceRecord" [
  virtualEventTownhall_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  attendanceRecord_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, attendanceIntervals: table<durationInSeconds: float, joinDateTime: string, leaveDateTime: string>, emailAddress: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, identity: record<displayName: string, id: string>, registrationId: string, role: string, totalAttendanceInSeconds: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords/($attendanceRecord_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property attendanceRecords in solutions
#
# PATCH /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords/{attendanceRecord-id}
# operationId: solution.virtualEvent.townhall.session.attendanceReport_UpdateAttendanceRecord
# --attendanceIntervals item shape: {durationInSeconds?: float, joinDateTime?: string, leaveDateTime?: string}
# --externalRegistrationInformation shape: {referrer?: string, registrationId?: string}
# --identity shape: {displayName?: string, id?: string}
export def "solutions-virtual-events-townhalls-sessions-attendance-reports-attendance-records UpdateAttendanceRecord" [
  virtualEventTownhall_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  attendanceRecord_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --attendanceIntervals: list # List of time periods between joining and leaving a meeting. — item shape: {durationInSeconds?: float, joinDateTime?: string, leaveDateTime?: string}
  --emailAddress: string # Email address of the user associated with this attendance record. (nullable)
  --externalRegistrationInformation: record # shape: {referrer?: string, registrationId?: string}
  --identity: record # shape: {displayName?: string, id?: string}
  --registrationId: string # Unique identifier of a virtualEventRegistration that is available to all participants registered for the virtualEventWebinar. (nullable)
  --role: string # Role of the attendee. The possible values are: None, Attendee, Presenter, and Organizer. (nullable)
  --totalAttendanceInSeconds: float # Total duration of the attendances in seconds. (nullable, format: int32)
]: any -> record<id: string, attendanceIntervals: table<durationInSeconds: float, joinDateTime: string, leaveDateTime: string>, emailAddress: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, identity: record<displayName: string, id: string>, registrationId: string, role: string, totalAttendanceInSeconds: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords/($attendanceRecord_id)")
  let body = {id: $id, attendanceIntervals: $attendanceIntervals, emailAddress: $emailAddress, externalRegistrationInformation: $externalRegistrationInformation, identity: $identity, registrationId: $registrationId, role: $role, totalAttendanceInSeconds: $totalAttendanceInSeconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property attendanceRecords for solutions
#
# DELETE /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords/{attendanceRecord-id}
# operationId: solution.virtualEvent.townhall.session.attendanceReport_DeleteAttendanceRecord
export def "solutions-virtual-events-townhalls-sessions-attendance-reports-attendance-records DeleteAttendanceRecord" [
  virtualEventTownhall_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  attendanceRecord_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords/($attendanceRecord_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords/$count
# operationId: solution.virtualEvent.townhall.session.attendanceReport.attendanceRecord_GetCount
export def "solutions-virtual-events-townhalls-sessions-attendance-reports-attendance-records-count GetCount" [
  virtualEventTownhall_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/{virtualEventSession-id}/attendanceReports/$count
# operationId: solution.virtualEvent.townhall.session.attendanceReport_GetCount
export def "solutions-virtual-events-townhalls-sessions-attendance-reports-count GetCount" [
  virtualEventTownhall_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/($virtualEventSession_id)/attendanceReports/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/townhalls/{virtualEventTownhall-id}/sessions/$count
# operationId: solution.virtualEvent.townhall.session_GetCount
export def "solutions-virtual-events-townhalls-sessions-count GetCount" [
  virtualEventTownhall_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/($virtualEventTownhall_id)/sessions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/townhalls/$count
# operationId: solution.virtualEvent.townhall_GetCount
export def "solutions-virtual-events-townhalls-count GetCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/solutions/virtualEvents/townhalls/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke function getByUserIdAndRole
#
# GET /solutions/virtualEvents/townhalls/microsoft.graph.getByUserIdAndRole(userId='{userId}',role='{role}')
# Docs: https://learn.microsoft.com/graph/api/virtualeventtownhall-getbyuseridandrole?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.townhall_getGraphBPreUserIdAndRole
export def "solutions-virtual-events-townhalls-microsoftgraphget-by-user-id-and-roleuser-id-user-id-role-role get" [
  userId: string
  role: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<audience: string, coOrganizers: list, invitedAttendees: list, isInviteOnly: bool>, _odata_nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/microsoft.graph.getByUserIdAndRole(userId='($userId)',role='($role)')" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke function getByUserRole
#
# GET /solutions/virtualEvents/townhalls/microsoft.graph.getByUserRole(role='{role}')
# Docs: https://learn.microsoft.com/graph/api/virtualeventtownhall-getbyuserrole?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.townhall_getGraphBPreUserRole
export def "solutions-virtual-events-townhalls-microsoftgraphget-by-user-rolerole-role get" [
  role: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<audience: string, coOrganizers: list, invitedAttendees: list, isInviteOnly: bool>, _odata_nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/townhalls/microsoft.graph.getByUserRole(role='($role)')" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List webinars
#
# GET /solutions/virtualEvents/webinars
# Docs: https://learn.microsoft.com/graph/api/virtualeventsroot-list-webinars?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent_ListWebinar
export def "solutions-virtual-events-webinars ListWebinar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/solutions/virtualEvents/webinars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create virtualEventWebinar
#
# POST /solutions/virtualEvents/webinars
# Docs: https://learn.microsoft.com/graph/api/virtualeventsroot-post-webinars?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent_CreateWebinar
# --coOrganizers item shape: {displayName?: string, id?: string, tenantId?: string}
# --registrations item shape: {id?: string, cancelationDateTime?: string, email?: string, externalRegistrationInformation?: record, firstName?: string, lastName?: string, preferredLanguage?: string, preferredTimezone?: string, registrationDateTime?: string, registrationQuestionAnswers?: list, status?: "registered"|"canceled"|"waitlisted"|"pendingApproval"|"rejectedByOrganizer"|"unknownFutureValue", userId?: string, sessions?: list}
export def "solutions-virtual-events-webinars CreateWebinar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --audience: string@audience-completer
  --coOrganizers: list # Identity information of coorganizers of the webinar. — item shape: {displayName?: string, id?: string, tenantId?: string}
  --registrationConfiguration: any
  --registrations: list # Registration records of the webinar. — item shape: {id?: string, cancelationDateTime?: string, email?: string, externalRegistrationInformation?: record, firstName?: string, lastName?: string, preferredLanguage?: string, preferredTimezone?: string, registrationDateTime?: string, registrationQuestionAnswers?: list, status?: "registered"|"canceled"|"waitlisted"|"pendingApproval"|"rejectedByOrganizer"|"unknownFutureValue", userId?: string, sessions?: list}
]: any -> record<audience: string, coOrganizers: table<displayName: string, id: string, tenantId: string>, registrationConfiguration: record<isManualApprovalEnabled: bool, isWaitlistEnabled: bool>, registrations: table<id: string, cancelationDateTime: string, email: string, externalRegistrationInformation: record, firstName: string, lastName: string, preferredLanguage: string, preferredTimezone: string, registrationDateTime: string, registrationQuestionAnswers: list, status: string, userId: string, sessions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/solutions/virtualEvents/webinars")
  let body = {audience: $audience, coOrganizers: $coOrganizers, registrationConfiguration: $registrationConfiguration, registrations: $registrations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get virtualEventWebinar
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}
# Docs: https://learn.microsoft.com/graph/api/virtualeventwebinar-get?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent_GetWebinar
export def "solutions-virtual-events-webinars GetWebinar" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<audience: string, coOrganizers: table<displayName: string, id: string, tenantId: string>, registrationConfiguration: record<isManualApprovalEnabled: bool, isWaitlistEnabled: bool>, registrations: table<id: string, cancelationDateTime: string, email: string, externalRegistrationInformation: record, firstName: string, lastName: string, preferredLanguage: string, preferredTimezone: string, registrationDateTime: string, registrationQuestionAnswers: list, status: string, userId: string, sessions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update virtualEventWebinar
#
# PATCH /solutions/virtualEvents/webinars/{virtualEventWebinar-id}
# Docs: https://learn.microsoft.com/graph/api/virtualeventwebinar-update?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent_UpdateWebinar
# --coOrganizers item shape: {displayName?: string, id?: string, tenantId?: string}
# --registrations item shape: {id?: string, cancelationDateTime?: string, email?: string, externalRegistrationInformation?: record, firstName?: string, lastName?: string, preferredLanguage?: string, preferredTimezone?: string, registrationDateTime?: string, registrationQuestionAnswers?: list, status?: "registered"|"canceled"|"waitlisted"|"pendingApproval"|"rejectedByOrganizer"|"unknownFutureValue", userId?: string, sessions?: list}
export def "solutions-virtual-events-webinars UpdateWebinar" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --audience: string@audience-completer
  --coOrganizers: list # Identity information of coorganizers of the webinar. — item shape: {displayName?: string, id?: string, tenantId?: string}
  --registrationConfiguration: any
  --registrations: list # Registration records of the webinar. — item shape: {id?: string, cancelationDateTime?: string, email?: string, externalRegistrationInformation?: record, firstName?: string, lastName?: string, preferredLanguage?: string, preferredTimezone?: string, registrationDateTime?: string, registrationQuestionAnswers?: list, status?: "registered"|"canceled"|"waitlisted"|"pendingApproval"|"rejectedByOrganizer"|"unknownFutureValue", userId?: string, sessions?: list}
]: any -> record<audience: string, coOrganizers: table<displayName: string, id: string, tenantId: string>, registrationConfiguration: record<isManualApprovalEnabled: bool, isWaitlistEnabled: bool>, registrations: table<id: string, cancelationDateTime: string, email: string, externalRegistrationInformation: record, firstName: string, lastName: string, preferredLanguage: string, preferredTimezone: string, registrationDateTime: string, registrationQuestionAnswers: list, status: string, userId: string, sessions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)")
  let body = {audience: $audience, coOrganizers: $coOrganizers, registrationConfiguration: $registrationConfiguration, registrations: $registrations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property webinars for solutions
#
# DELETE /solutions/virtualEvents/webinars/{virtualEventWebinar-id}
# operationId: solution.virtualEvent_DeleteWebinar
export def "solutions-virtual-events-webinars DeleteWebinar" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get presenters from solutions
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/presenters
# operationId: solution.virtualEvent.webinar_ListPresenter
export def "solutions-virtual-events-webinars-presenters ListPresenter" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/presenters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create virtualEventPresenter
#
# POST /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/presenters
# Docs: https://learn.microsoft.com/graph/api/virtualevent-post-presenters?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar_CreatePresenter
# --identity shape: {displayName?: string, id?: string}
# --presenterDetails shape: {bio?: record, company?: string, jobTitle?: string, linkedInProfileWebUrl?: string, personalSiteWebUrl?: string, photo?: string, twitterProfileWebUrl?: string}
export def "solutions-virtual-events-webinars-presenters CreatePresenter" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --email: string # Email address of the presenter. (nullable)
  --identity: record # shape: {displayName?: string, id?: string}
  --presenterDetails: record # shape: {bio?: record, company?: string, jobTitle?: string, linkedInProfileWebUrl?: string, personalSiteWebUrl?: string, photo?: string, twitterProfileWebUrl?: string}
]: any -> record<id: string, email: string, identity: record<displayName: string, id: string>, presenterDetails: record<bio: record<content: string, contentType: string>, company: string, jobTitle: string, linkedInProfileWebUrl: string, personalSiteWebUrl: string, photo: string, twitterProfileWebUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/presenters")
  let body = {id: $id, email: $email, identity: $identity, presenterDetails: $presenterDetails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get presenters from solutions
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/presenters/{virtualEventPresenter-id}
# operationId: solution.virtualEvent.webinar_GetPresenter
export def "solutions-virtual-events-webinars-presenters GetPresenter" [
  virtualEventWebinar_id: string
  virtualEventPresenter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, email: string, identity: record<displayName: string, id: string>, presenterDetails: record<bio: record<content: string, contentType: string>, company: string, jobTitle: string, linkedInProfileWebUrl: string, personalSiteWebUrl: string, photo: string, twitterProfileWebUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/presenters/($virtualEventPresenter_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update virtualEventPresenter
#
# PATCH /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/presenters/{virtualEventPresenter-id}
# Docs: https://learn.microsoft.com/graph/api/virtualeventpresenter-update?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar_UpdatePresenter
# --identity shape: {displayName?: string, id?: string}
# --presenterDetails shape: {bio?: record, company?: string, jobTitle?: string, linkedInProfileWebUrl?: string, personalSiteWebUrl?: string, photo?: string, twitterProfileWebUrl?: string}
export def "solutions-virtual-events-webinars-presenters UpdatePresenter" [
  virtualEventWebinar_id: string
  virtualEventPresenter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --email: string # Email address of the presenter. (nullable)
  --identity: record # shape: {displayName?: string, id?: string}
  --presenterDetails: record # shape: {bio?: record, company?: string, jobTitle?: string, linkedInProfileWebUrl?: string, personalSiteWebUrl?: string, photo?: string, twitterProfileWebUrl?: string}
]: any -> record<id: string, email: string, identity: record<displayName: string, id: string>, presenterDetails: record<bio: record<content: string, contentType: string>, company: string, jobTitle: string, linkedInProfileWebUrl: string, personalSiteWebUrl: string, photo: string, twitterProfileWebUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/presenters/($virtualEventPresenter_id)")
  let body = {id: $id, email: $email, identity: $identity, presenterDetails: $presenterDetails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property presenters for solutions
#
# DELETE /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/presenters/{virtualEventPresenter-id}
# operationId: solution.virtualEvent.webinar_DeletePresenter
export def "solutions-virtual-events-webinars-presenters DeletePresenter" [
  virtualEventWebinar_id: string
  virtualEventPresenter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/presenters/($virtualEventPresenter_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/presenters/$count
# operationId: solution.virtualEvent.webinar.presenter_GetCount
export def "solutions-virtual-events-webinars-presenters-count GetCount" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/presenters/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get virtualEventWebinarRegistrationConfiguration
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrationConfiguration
# Docs: https://learn.microsoft.com/graph/api/virtualeventwebinarregistrationconfiguration-get?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar_GetRegistrationConfiguration
export def "solutions-virtual-events-webinars-registration-configuration GetRegistrationConfiguration" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<isManualApprovalEnabled: bool, isWaitlistEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrationConfiguration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property registrationConfiguration in solutions
#
# PATCH /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrationConfiguration
# operationId: solution.virtualEvent.webinar_UpdateRegistrationConfiguration
export def "solutions-virtual-events-webinars-registration-configuration UpdateRegistrationConfiguration" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isManualApprovalEnabled: string@bool-completer # nullable
  --isWaitlistEnabled: string@bool-completer # nullable
]: any -> record<isManualApprovalEnabled: bool, isWaitlistEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrationConfiguration")
  let body = {isManualApprovalEnabled: $isManualApprovalEnabled, isWaitlistEnabled: $isWaitlistEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property registrationConfiguration for solutions
#
# DELETE /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrationConfiguration
# operationId: solution.virtualEvent.webinar_DeleteRegistrationConfiguration
export def "solutions-virtual-events-webinars-registration-configuration DeleteRegistrationConfiguration" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrationConfiguration")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List questions
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrationConfiguration/questions
# Docs: https://learn.microsoft.com/graph/api/virtualeventregistrationconfiguration-list-questions?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar.registrationConfiguration_ListQuestion
export def "solutions-virtual-events-webinars-registration-configuration-questions ListQuestion" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrationConfiguration/questions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create virtualEventRegistrationCustomQuestion
#
# POST /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrationConfiguration/questions
# Docs: https://learn.microsoft.com/graph/api/virtualeventregistrationconfiguration-post-questions?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar.registrationConfiguration_CreateQuestion
export def "solutions-virtual-events-webinars-registration-configuration-questions CreateQuestion" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --displayName: string # Display name of the registration question. (nullable)
  --isRequired: string@bool-completer # Indicates whether an answer to the question is required. The default value is false. (nullable)
]: any -> record<id: string, displayName: string, isRequired: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrationConfiguration/questions")
  let body = {id: $id, displayName: $displayName, isRequired: $isRequired} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get questions from solutions
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrationConfiguration/questions/{virtualEventRegistrationQuestionBase-id}
# operationId: solution.virtualEvent.webinar.registrationConfiguration_GetQuestion
export def "solutions-virtual-events-webinars-registration-configuration-questions GetQuestion" [
  virtualEventWebinar_id: string
  virtualEventRegistrationQuestionBase_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, displayName: string, isRequired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrationConfiguration/questions/($virtualEventRegistrationQuestionBase_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property questions in solutions
#
# PATCH /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrationConfiguration/questions/{virtualEventRegistrationQuestionBase-id}
# operationId: solution.virtualEvent.webinar.registrationConfiguration_UpdateQuestion
export def "solutions-virtual-events-webinars-registration-configuration-questions UpdateQuestion" [
  virtualEventWebinar_id: string
  virtualEventRegistrationQuestionBase_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --displayName: string # Display name of the registration question. (nullable)
  --isRequired: string@bool-completer # Indicates whether an answer to the question is required. The default value is false. (nullable)
]: any -> record<id: string, displayName: string, isRequired: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrationConfiguration/questions/($virtualEventRegistrationQuestionBase_id)")
  let body = {id: $id, displayName: $displayName, isRequired: $isRequired} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete virtualEventRegistrationQuestionBase
#
# DELETE /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrationConfiguration/questions/{virtualEventRegistrationQuestionBase-id}
# Docs: https://learn.microsoft.com/graph/api/virtualeventregistrationquestionbase-delete?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar.registrationConfiguration_DeleteQuestion
export def "solutions-virtual-events-webinars-registration-configuration-questions DeleteQuestion" [
  virtualEventWebinar_id: string
  virtualEventRegistrationQuestionBase_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrationConfiguration/questions/($virtualEventRegistrationQuestionBase_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrationConfiguration/questions/$count
# operationId: solution.virtualEvent.webinar.registrationConfiguration.question_GetCount
export def "solutions-virtual-events-webinars-registration-configuration-questions-count GetCount" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrationConfiguration/questions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List virtualEventRegistrations
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations
# Docs: https://learn.microsoft.com/graph/api/virtualeventregistration-list?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar_ListRegistration
export def "solutions-virtual-events-webinars-registrations ListRegistration" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create virtualEventRegistration
#
# POST /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations
# Docs: https://learn.microsoft.com/graph/api/virtualeventwebinar-post-registrations?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar_CreateRegistration
# --externalRegistrationInformation shape: {referrer?: string, registrationId?: string}
# --registrationQuestionAnswers item shape: {booleanValue?: bool, displayName?: string, multiChoiceValues?: list, questionId?: string, value?: string}
# --sessions item shape: {endDateTime?: record, startDateTime?: record, videoOnDemandWebUrl?: string}
export def "solutions-virtual-events-webinars-registrations CreateRegistration" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --cancelationDateTime: string # Date and time when the registrant cancels their registration for the virtual event. Only appears when applicable. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --email: string # Email address of the registrant. (nullable)
  --externalRegistrationInformation: record # shape: {referrer?: string, registrationId?: string}
  --firstName: string # First name of the registrant. (nullable)
  --lastName: string # Last name of the registrant. (nullable)
  --preferredLanguage: string # The registrant's preferred language. (nullable)
  --preferredTimezone: string # The registrant's time zone details. (nullable)
  --registrationDateTime: string # Date and time when the registrant registers for the virtual event. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --registrationQuestionAnswers: list # The registrant's answer to the registration questions. — item shape: {booleanValue?: bool, displayName?: string, multiChoiceValues?: list, questionId?: string, value?: string}
  --status: string@status-completer-1
  --userId: string # The registrant's ID in Microsoft Entra ID. Only appears when the registrant is registered in Microsoft Entra ID. (nullable)
  --sessions: list # Sessions for a registration. — item shape: {endDateTime?: record, startDateTime?: record, videoOnDemandWebUrl?: string}
]: any -> record<id: string, cancelationDateTime: string, email: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, firstName: string, lastName: string, preferredLanguage: string, preferredTimezone: string, registrationDateTime: string, registrationQuestionAnswers: table<booleanValue: bool, displayName: string, multiChoiceValues: list, questionId: string, value: string>, status: string, userId: string, sessions: table<endDateTime: record, startDateTime: record, videoOnDemandWebUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations")
  let body = {id: $id, cancelationDateTime: $cancelationDateTime, email: $email, externalRegistrationInformation: $externalRegistrationInformation, firstName: $firstName, lastName: $lastName, preferredLanguage: $preferredLanguage, preferredTimezone: $preferredTimezone, registrationDateTime: $registrationDateTime, registrationQuestionAnswers: $registrationQuestionAnswers, status: $status, userId: $userId, sessions: $sessions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get virtualEventRegistration
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations/{virtualEventRegistration-id}
# Docs: https://learn.microsoft.com/graph/api/virtualeventregistration-get?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar_GetRegistration
export def "solutions-virtual-events-webinars-registrations GetRegistration" [
  virtualEventWebinar_id: string
  virtualEventRegistration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, cancelationDateTime: string, email: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, firstName: string, lastName: string, preferredLanguage: string, preferredTimezone: string, registrationDateTime: string, registrationQuestionAnswers: table<booleanValue: bool, displayName: string, multiChoiceValues: list, questionId: string, value: string>, status: string, userId: string, sessions: table<endDateTime: record, startDateTime: record, videoOnDemandWebUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations/($virtualEventRegistration_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property registrations in solutions
#
# PATCH /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations/{virtualEventRegistration-id}
# operationId: solution.virtualEvent.webinar_UpdateRegistration
# --externalRegistrationInformation shape: {referrer?: string, registrationId?: string}
# --registrationQuestionAnswers item shape: {booleanValue?: bool, displayName?: string, multiChoiceValues?: list, questionId?: string, value?: string}
# --sessions item shape: {endDateTime?: record, startDateTime?: record, videoOnDemandWebUrl?: string}
export def "solutions-virtual-events-webinars-registrations UpdateRegistration" [
  virtualEventWebinar_id: string
  virtualEventRegistration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --cancelationDateTime: string # Date and time when the registrant cancels their registration for the virtual event. Only appears when applicable. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --email: string # Email address of the registrant. (nullable)
  --externalRegistrationInformation: record # shape: {referrer?: string, registrationId?: string}
  --firstName: string # First name of the registrant. (nullable)
  --lastName: string # Last name of the registrant. (nullable)
  --preferredLanguage: string # The registrant's preferred language. (nullable)
  --preferredTimezone: string # The registrant's time zone details. (nullable)
  --registrationDateTime: string # Date and time when the registrant registers for the virtual event. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --registrationQuestionAnswers: list # The registrant's answer to the registration questions. — item shape: {booleanValue?: bool, displayName?: string, multiChoiceValues?: list, questionId?: string, value?: string}
  --status: string@status-completer-1
  --userId: string # The registrant's ID in Microsoft Entra ID. Only appears when the registrant is registered in Microsoft Entra ID. (nullable)
  --sessions: list # Sessions for a registration. — item shape: {endDateTime?: record, startDateTime?: record, videoOnDemandWebUrl?: string}
]: any -> record<id: string, cancelationDateTime: string, email: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, firstName: string, lastName: string, preferredLanguage: string, preferredTimezone: string, registrationDateTime: string, registrationQuestionAnswers: table<booleanValue: bool, displayName: string, multiChoiceValues: list, questionId: string, value: string>, status: string, userId: string, sessions: table<endDateTime: record, startDateTime: record, videoOnDemandWebUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations/($virtualEventRegistration_id)")
  let body = {id: $id, cancelationDateTime: $cancelationDateTime, email: $email, externalRegistrationInformation: $externalRegistrationInformation, firstName: $firstName, lastName: $lastName, preferredLanguage: $preferredLanguage, preferredTimezone: $preferredTimezone, registrationDateTime: $registrationDateTime, registrationQuestionAnswers: $registrationQuestionAnswers, status: $status, userId: $userId, sessions: $sessions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property registrations for solutions
#
# DELETE /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations/{virtualEventRegistration-id}
# operationId: solution.virtualEvent.webinar_DeleteRegistration
export def "solutions-virtual-events-webinars-registrations DeleteRegistration" [
  virtualEventWebinar_id: string
  virtualEventRegistration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations/($virtualEventRegistration_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke action cancel
#
# POST /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations/{virtualEventRegistration-id}/microsoft.graph.cancel
# operationId: solution.virtualEvent.webinar.registration_cancel
export def "solutions-virtual-events-webinars-registrations-microsoftgraphcancel cancel" [
  virtualEventWebinar_id: string
  virtualEventRegistration_id: string
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
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations/($virtualEventRegistration_id)/microsoft.graph.cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List sessions for a virtual event registration
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations/{virtualEventRegistration-id}/sessions
# Docs: https://learn.microsoft.com/graph/api/virtualeventregistration-list-sessions?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar.registration_ListSession
export def "solutions-virtual-events-webinars-registrations-sessions ListSession" [
  virtualEventWebinar_id: string
  virtualEventRegistration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations/($virtualEventRegistration_id)/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get sessions from solutions
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations/{virtualEventRegistration-id}/sessions/{virtualEventSession-id}
# operationId: solution.virtualEvent.webinar.registration_GetSession
export def "solutions-virtual-events-webinars-registrations-sessions GetSession" [
  virtualEventWebinar_id: string
  virtualEventRegistration_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<endDateTime: record<dateTime: string, timeZone: string>, startDateTime: record<dateTime: string, timeZone: string>, videoOnDemandWebUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations/($virtualEventRegistration_id)/sessions/($virtualEventSession_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations/{virtualEventRegistration-id}/sessions/$count
# operationId: solution.virtualEvent.webinar.registration.session_GetCount
export def "solutions-virtual-events-webinars-registrations-sessions-count GetCount" [
  virtualEventWebinar_id: string
  virtualEventRegistration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations/($virtualEventRegistration_id)/sessions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get virtualEventRegistration
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations(email='{email}')
# Docs: https://learn.microsoft.com/graph/api/virtualeventregistration-get?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar.registration_GetGraphBPreEmail
export def "solutions-virtual-events-webinars-registrationsemail-email GetGraphBPreEmail" [
  virtualEventWebinar_id: string
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, cancelationDateTime: string, email: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, firstName: string, lastName: string, preferredLanguage: string, preferredTimezone: string, registrationDateTime: string, registrationQuestionAnswers: table<booleanValue: bool, displayName: string, multiChoiceValues: list, questionId: string, value: string>, status: string, userId: string, sessions: table<endDateTime: record, startDateTime: record, videoOnDemandWebUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations(email='($email)')" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property registrations in solutions
#
# PATCH /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations(email='{email}')
# operationId: solution.virtualEvent.webinar.registration_UpdateGraphBPreEmail
# --externalRegistrationInformation shape: {referrer?: string, registrationId?: string}
# --registrationQuestionAnswers item shape: {booleanValue?: bool, displayName?: string, multiChoiceValues?: list, questionId?: string, value?: string}
# --sessions item shape: {endDateTime?: record, startDateTime?: record, videoOnDemandWebUrl?: string}
export def "solutions-virtual-events-webinars-registrationsemail-email UpdateGraphBPreEmail" [
  virtualEventWebinar_id: string
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --cancelationDateTime: string # Date and time when the registrant cancels their registration for the virtual event. Only appears when applicable. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --body-email: string # Email address of the registrant. (nullable)
  --externalRegistrationInformation: record # shape: {referrer?: string, registrationId?: string}
  --firstName: string # First name of the registrant. (nullable)
  --lastName: string # Last name of the registrant. (nullable)
  --preferredLanguage: string # The registrant's preferred language. (nullable)
  --preferredTimezone: string # The registrant's time zone details. (nullable)
  --registrationDateTime: string # Date and time when the registrant registers for the virtual event. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --registrationQuestionAnswers: list # The registrant's answer to the registration questions. — item shape: {booleanValue?: bool, displayName?: string, multiChoiceValues?: list, questionId?: string, value?: string}
  --status: string@status-completer-1
  --userId: string # The registrant's ID in Microsoft Entra ID. Only appears when the registrant is registered in Microsoft Entra ID. (nullable)
  --sessions: list # Sessions for a registration. — item shape: {endDateTime?: record, startDateTime?: record, videoOnDemandWebUrl?: string}
]: any -> record<id: string, cancelationDateTime: string, email: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, firstName: string, lastName: string, preferredLanguage: string, preferredTimezone: string, registrationDateTime: string, registrationQuestionAnswers: table<booleanValue: bool, displayName: string, multiChoiceValues: list, questionId: string, value: string>, status: string, userId: string, sessions: table<endDateTime: record, startDateTime: record, videoOnDemandWebUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations(email='($email)')")
  let body = {id: $id, cancelationDateTime: $cancelationDateTime, email: $body_email, externalRegistrationInformation: $externalRegistrationInformation, firstName: $firstName, lastName: $lastName, preferredLanguage: $preferredLanguage, preferredTimezone: $preferredTimezone, registrationDateTime: $registrationDateTime, registrationQuestionAnswers: $registrationQuestionAnswers, status: $status, userId: $userId, sessions: $sessions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property registrations for solutions
#
# DELETE /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations(email='{email}')
# operationId: solution.virtualEvent.webinar.registration_DeleteGraphBPreEmail
export def "solutions-virtual-events-webinars-registrationsemail-email DeleteGraphBPreEmail" [
  virtualEventWebinar_id: string
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations(email='($email)')")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke action cancel
#
# POST /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations(email='{email}')/microsoft.graph.cancel
# operationId: solution.virtualEvent.webinar.registration.email_cancel
export def "solutions-virtual-events-webinars-registrationsemail-email-microsoftgraphcancel cancel" [
  virtualEventWebinar_id: string
  email: string
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
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations(email='($email)')/microsoft.graph.cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get virtualEventRegistration
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations(userId='{userId}')
# Docs: https://learn.microsoft.com/graph/api/virtualeventregistration-get?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar.registration_GetGraphBPreUserId
export def "solutions-virtual-events-webinars-registrationsuser-id-user-id GetGraphBPreUserId" [
  virtualEventWebinar_id: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, cancelationDateTime: string, email: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, firstName: string, lastName: string, preferredLanguage: string, preferredTimezone: string, registrationDateTime: string, registrationQuestionAnswers: table<booleanValue: bool, displayName: string, multiChoiceValues: list, questionId: string, value: string>, status: string, userId: string, sessions: table<endDateTime: record, startDateTime: record, videoOnDemandWebUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations(userId='($userId)')" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property registrations in solutions
#
# PATCH /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations(userId='{userId}')
# operationId: solution.virtualEvent.webinar.registration_UpdateGraphBPreUserId
# --externalRegistrationInformation shape: {referrer?: string, registrationId?: string}
# --registrationQuestionAnswers item shape: {booleanValue?: bool, displayName?: string, multiChoiceValues?: list, questionId?: string, value?: string}
# --sessions item shape: {endDateTime?: record, startDateTime?: record, videoOnDemandWebUrl?: string}
export def "solutions-virtual-events-webinars-registrationsuser-id-user-id UpdateGraphBPreUserId" [
  virtualEventWebinar_id: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --cancelationDateTime: string # Date and time when the registrant cancels their registration for the virtual event. Only appears when applicable. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --email: string # Email address of the registrant. (nullable)
  --externalRegistrationInformation: record # shape: {referrer?: string, registrationId?: string}
  --firstName: string # First name of the registrant. (nullable)
  --lastName: string # Last name of the registrant. (nullable)
  --preferredLanguage: string # The registrant's preferred language. (nullable)
  --preferredTimezone: string # The registrant's time zone details. (nullable)
  --registrationDateTime: string # Date and time when the registrant registers for the virtual event. The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time. For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z. (nullable, format: date-time)
  --registrationQuestionAnswers: list # The registrant's answer to the registration questions. — item shape: {booleanValue?: bool, displayName?: string, multiChoiceValues?: list, questionId?: string, value?: string}
  --status: string@status-completer-1
  --body-userId: string # The registrant's ID in Microsoft Entra ID. Only appears when the registrant is registered in Microsoft Entra ID. (nullable)
  --sessions: list # Sessions for a registration. — item shape: {endDateTime?: record, startDateTime?: record, videoOnDemandWebUrl?: string}
]: any -> record<id: string, cancelationDateTime: string, email: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, firstName: string, lastName: string, preferredLanguage: string, preferredTimezone: string, registrationDateTime: string, registrationQuestionAnswers: table<booleanValue: bool, displayName: string, multiChoiceValues: list, questionId: string, value: string>, status: string, userId: string, sessions: table<endDateTime: record, startDateTime: record, videoOnDemandWebUrl: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations(userId='($userId)')")
  let body = {id: $id, cancelationDateTime: $cancelationDateTime, email: $email, externalRegistrationInformation: $externalRegistrationInformation, firstName: $firstName, lastName: $lastName, preferredLanguage: $preferredLanguage, preferredTimezone: $preferredTimezone, registrationDateTime: $registrationDateTime, registrationQuestionAnswers: $registrationQuestionAnswers, status: $status, userId: $body_userId, sessions: $sessions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property registrations for solutions
#
# DELETE /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations(userId='{userId}')
# operationId: solution.virtualEvent.webinar.registration_DeleteGraphBPreUserId
export def "solutions-virtual-events-webinars-registrationsuser-id-user-id DeleteGraphBPreUserId" [
  virtualEventWebinar_id: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations(userId='($userId)')")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke action cancel
#
# POST /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations(userId='{userId}')/microsoft.graph.cancel
# operationId: solution.virtualEvent.webinar.registration.userId_cancel
export def "solutions-virtual-events-webinars-registrationsuser-id-user-id-microsoftgraphcancel cancel" [
  virtualEventWebinar_id: string
  userId: string
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
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations(userId='($userId)')/microsoft.graph.cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/registrations/$count
# operationId: solution.virtualEvent.webinar.registration_GetCount
export def "solutions-virtual-events-webinars-registrations-count GetCount" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/registrations/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List sessions for a virtual event
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions
# Docs: https://learn.microsoft.com/graph/api/virtualevent-list-sessions?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar_ListSession
export def "solutions-virtual-events-webinars-sessions ListSession" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new navigation property to sessions for solutions
#
# POST /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions
# operationId: solution.virtualEvent.webinar_CreateSession
# --endDateTime shape: {dateTime?: string, timeZone?: string}
# --startDateTime shape: {dateTime?: string, timeZone?: string}
export def "solutions-virtual-events-webinars-sessions CreateSession" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --startDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --videoOnDemandWebUrl: string # The URL of the video on demand (VOD) for Microsoft Teams events that allows webinar and town hall organizers to quickly publish and share event recordings. (nullable)
]: any -> record<endDateTime: record<dateTime: string, timeZone: string>, startDateTime: record<dateTime: string, timeZone: string>, videoOnDemandWebUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions")
  let body = {endDateTime: $endDateTime, startDateTime: $startDateTime, videoOnDemandWebUrl: $videoOnDemandWebUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get virtualEventSession
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/{virtualEventSession-id}
# Docs: https://learn.microsoft.com/graph/api/virtualeventsession-get?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar_GetSession
export def "solutions-virtual-events-webinars-sessions GetSession" [
  virtualEventWebinar_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<endDateTime: record<dateTime: string, timeZone: string>, startDateTime: record<dateTime: string, timeZone: string>, videoOnDemandWebUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/($virtualEventSession_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property sessions in solutions
#
# PATCH /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/{virtualEventSession-id}
# operationId: solution.virtualEvent.webinar_UpdateSession
# --endDateTime shape: {dateTime?: string, timeZone?: string}
# --startDateTime shape: {dateTime?: string, timeZone?: string}
export def "solutions-virtual-events-webinars-sessions UpdateSession" [
  virtualEventWebinar_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --startDateTime: record # shape: {dateTime?: string, timeZone?: string}
  --videoOnDemandWebUrl: string # The URL of the video on demand (VOD) for Microsoft Teams events that allows webinar and town hall organizers to quickly publish and share event recordings. (nullable)
]: any -> record<endDateTime: record<dateTime: string, timeZone: string>, startDateTime: record<dateTime: string, timeZone: string>, videoOnDemandWebUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/($virtualEventSession_id)")
  let body = {endDateTime: $endDateTime, startDateTime: $startDateTime, videoOnDemandWebUrl: $videoOnDemandWebUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property sessions for solutions
#
# DELETE /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/{virtualEventSession-id}
# operationId: solution.virtualEvent.webinar_DeleteSession
export def "solutions-virtual-events-webinars-sessions DeleteSession" [
  virtualEventWebinar_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/($virtualEventSession_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List meetingAttendanceReports
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/{virtualEventSession-id}/attendanceReports
# Docs: https://learn.microsoft.com/graph/api/meetingattendancereport-list?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar.session_ListAttendanceReport
export def "solutions-virtual-events-webinars-sessions-attendance-reports ListAttendanceReport" [
  virtualEventWebinar_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/($virtualEventSession_id)/attendanceReports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new navigation property to attendanceReports for solutions
#
# POST /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/{virtualEventSession-id}/attendanceReports
# operationId: solution.virtualEvent.webinar.session_CreateAttendanceReport
# --externalEventInformation item shape: {applicationId?: string, externalEventId?: string}
# --attendanceRecords item shape: {id?: string, attendanceIntervals?: list, emailAddress?: string, externalRegistrationInformation?: record, identity?: record, registrationId?: string, role?: string, totalAttendanceInSeconds?: float}
export def "solutions-virtual-events-webinars-sessions-attendance-reports CreateAttendanceReport" [
  virtualEventWebinar_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --externalEventInformation: list # The external information of a virtual event. Returned only for event organizers or coorganizers. Read-only. — item shape: {applicationId?: string, externalEventId?: string}
  --meetingEndDateTime: string # UTC time when the meeting ended. Read-only. (nullable, format: date-time)
  --meetingStartDateTime: string # UTC time when the meeting started. Read-only. (nullable, format: date-time)
  --totalParticipantCount: float # Total number of participants. Read-only. (nullable, format: int32)
  --attendanceRecords: list # List of attendance records of an attendance report. Read-only. — item shape: {id?: string, attendanceIntervals?: list, emailAddress?: string, externalRegistrationInformation?: record, identity?: record, registrationId?: string, role?: string, totalAttendanceInSeconds?: float}
]: any -> record<id: string, externalEventInformation: table<applicationId: string, externalEventId: string>, meetingEndDateTime: string, meetingStartDateTime: string, totalParticipantCount: float, attendanceRecords: table<id: string, attendanceIntervals: list, emailAddress: string, externalRegistrationInformation: record, identity: record, registrationId: string, role: string, totalAttendanceInSeconds: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/($virtualEventSession_id)/attendanceReports")
  let body = {id: $id, externalEventInformation: $externalEventInformation, meetingEndDateTime: $meetingEndDateTime, meetingStartDateTime: $meetingStartDateTime, totalParticipantCount: $totalParticipantCount, attendanceRecords: $attendanceRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get meetingAttendanceReport
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}
# Docs: https://learn.microsoft.com/graph/api/meetingattendancereport-get?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar.session_GetAttendanceReport
export def "solutions-virtual-events-webinars-sessions-attendance-reports GetAttendanceReport" [
  virtualEventWebinar_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, externalEventInformation: table<applicationId: string, externalEventId: string>, meetingEndDateTime: string, meetingStartDateTime: string, totalParticipantCount: float, attendanceRecords: table<id: string, attendanceIntervals: list, emailAddress: string, externalRegistrationInformation: record, identity: record, registrationId: string, role: string, totalAttendanceInSeconds: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property attendanceReports in solutions
#
# PATCH /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}
# operationId: solution.virtualEvent.webinar.session_UpdateAttendanceReport
# --externalEventInformation item shape: {applicationId?: string, externalEventId?: string}
# --attendanceRecords item shape: {id?: string, attendanceIntervals?: list, emailAddress?: string, externalRegistrationInformation?: record, identity?: record, registrationId?: string, role?: string, totalAttendanceInSeconds?: float}
export def "solutions-virtual-events-webinars-sessions-attendance-reports UpdateAttendanceReport" [
  virtualEventWebinar_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --externalEventInformation: list # The external information of a virtual event. Returned only for event organizers or coorganizers. Read-only. — item shape: {applicationId?: string, externalEventId?: string}
  --meetingEndDateTime: string # UTC time when the meeting ended. Read-only. (nullable, format: date-time)
  --meetingStartDateTime: string # UTC time when the meeting started. Read-only. (nullable, format: date-time)
  --totalParticipantCount: float # Total number of participants. Read-only. (nullable, format: int32)
  --attendanceRecords: list # List of attendance records of an attendance report. Read-only. — item shape: {id?: string, attendanceIntervals?: list, emailAddress?: string, externalRegistrationInformation?: record, identity?: record, registrationId?: string, role?: string, totalAttendanceInSeconds?: float}
]: any -> record<id: string, externalEventInformation: table<applicationId: string, externalEventId: string>, meetingEndDateTime: string, meetingStartDateTime: string, totalParticipantCount: float, attendanceRecords: table<id: string, attendanceIntervals: list, emailAddress: string, externalRegistrationInformation: record, identity: record, registrationId: string, role: string, totalAttendanceInSeconds: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)")
  let body = {id: $id, externalEventInformation: $externalEventInformation, meetingEndDateTime: $meetingEndDateTime, meetingStartDateTime: $meetingStartDateTime, totalParticipantCount: $totalParticipantCount, attendanceRecords: $attendanceRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property attendanceReports for solutions
#
# DELETE /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}
# operationId: solution.virtualEvent.webinar.session_DeleteAttendanceReport
export def "solutions-virtual-events-webinars-sessions-attendance-reports DeleteAttendanceReport" [
  virtualEventWebinar_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List attendanceRecords
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords
# Docs: https://learn.microsoft.com/graph/api/attendancerecord-list?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar.session.attendanceReport_ListAttendanceRecord
export def "solutions-virtual-events-webinars-sessions-attendance-reports-attendance-records ListAttendanceRecord" [
  virtualEventWebinar_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --orderby: list # Order items by property values
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new navigation property to attendanceRecords for solutions
#
# POST /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords
# operationId: solution.virtualEvent.webinar.session.attendanceReport_CreateAttendanceRecord
# --attendanceIntervals item shape: {durationInSeconds?: float, joinDateTime?: string, leaveDateTime?: string}
# --externalRegistrationInformation shape: {referrer?: string, registrationId?: string}
# --identity shape: {displayName?: string, id?: string}
export def "solutions-virtual-events-webinars-sessions-attendance-reports-attendance-records CreateAttendanceRecord" [
  virtualEventWebinar_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --attendanceIntervals: list # List of time periods between joining and leaving a meeting. — item shape: {durationInSeconds?: float, joinDateTime?: string, leaveDateTime?: string}
  --emailAddress: string # Email address of the user associated with this attendance record. (nullable)
  --externalRegistrationInformation: record # shape: {referrer?: string, registrationId?: string}
  --identity: record # shape: {displayName?: string, id?: string}
  --registrationId: string # Unique identifier of a virtualEventRegistration that is available to all participants registered for the virtualEventWebinar. (nullable)
  --role: string # Role of the attendee. The possible values are: None, Attendee, Presenter, and Organizer. (nullable)
  --totalAttendanceInSeconds: float # Total duration of the attendances in seconds. (nullable, format: int32)
]: any -> record<id: string, attendanceIntervals: table<durationInSeconds: float, joinDateTime: string, leaveDateTime: string>, emailAddress: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, identity: record<displayName: string, id: string>, registrationId: string, role: string, totalAttendanceInSeconds: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords")
  let body = {id: $id, attendanceIntervals: $attendanceIntervals, emailAddress: $emailAddress, externalRegistrationInformation: $externalRegistrationInformation, identity: $identity, registrationId: $registrationId, role: $role, totalAttendanceInSeconds: $totalAttendanceInSeconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get attendanceRecords from solutions
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords/{attendanceRecord-id}
# operationId: solution.virtualEvent.webinar.session.attendanceReport_GetAttendanceRecord
export def "solutions-virtual-events-webinars-sessions-attendance-reports-attendance-records GetAttendanceRecord" [
  virtualEventWebinar_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  attendanceRecord_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --select: list # Select properties to be returned
  --expand: list # Expand related entities
]: nothing -> record<id: string, attendanceIntervals: table<durationInSeconds: float, joinDateTime: string, leaveDateTime: string>, emailAddress: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, identity: record<displayName: string, id: string>, registrationId: string, role: string, totalAttendanceInSeconds: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords/($attendanceRecord_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the navigation property attendanceRecords in solutions
#
# PATCH /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords/{attendanceRecord-id}
# operationId: solution.virtualEvent.webinar.session.attendanceReport_UpdateAttendanceRecord
# --attendanceIntervals item shape: {durationInSeconds?: float, joinDateTime?: string, leaveDateTime?: string}
# --externalRegistrationInformation shape: {referrer?: string, registrationId?: string}
# --identity shape: {displayName?: string, id?: string}
export def "solutions-virtual-events-webinars-sessions-attendance-reports-attendance-records UpdateAttendanceRecord" [
  virtualEventWebinar_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  attendanceRecord_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The unique identifier for an entity. Read-only.
  --attendanceIntervals: list # List of time periods between joining and leaving a meeting. — item shape: {durationInSeconds?: float, joinDateTime?: string, leaveDateTime?: string}
  --emailAddress: string # Email address of the user associated with this attendance record. (nullable)
  --externalRegistrationInformation: record # shape: {referrer?: string, registrationId?: string}
  --identity: record # shape: {displayName?: string, id?: string}
  --registrationId: string # Unique identifier of a virtualEventRegistration that is available to all participants registered for the virtualEventWebinar. (nullable)
  --role: string # Role of the attendee. The possible values are: None, Attendee, Presenter, and Organizer. (nullable)
  --totalAttendanceInSeconds: float # Total duration of the attendances in seconds. (nullable, format: int32)
]: any -> record<id: string, attendanceIntervals: table<durationInSeconds: float, joinDateTime: string, leaveDateTime: string>, emailAddress: string, externalRegistrationInformation: record<referrer: string, registrationId: string>, identity: record<displayName: string, id: string>, registrationId: string, role: string, totalAttendanceInSeconds: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords/($attendanceRecord_id)")
  let body = {id: $id, attendanceIntervals: $attendanceIntervals, emailAddress: $emailAddress, externalRegistrationInformation: $externalRegistrationInformation, identity: $identity, registrationId: $registrationId, role: $role, totalAttendanceInSeconds: $totalAttendanceInSeconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete navigation property attendanceRecords for solutions
#
# DELETE /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords/{attendanceRecord-id}
# operationId: solution.virtualEvent.webinar.session.attendanceReport_DeleteAttendanceRecord
export def "solutions-virtual-events-webinars-sessions-attendance-reports-attendance-records DeleteAttendanceRecord" [
  virtualEventWebinar_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  attendanceRecord_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --If-Match: string # ETag
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords/($attendanceRecord_id)")
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/{virtualEventSession-id}/attendanceReports/{meetingAttendanceReport-id}/attendanceRecords/$count
# operationId: solution.virtualEvent.webinar.session.attendanceReport.attendanceRecord_GetCount
export def "solutions-virtual-events-webinars-sessions-attendance-reports-attendance-records-count GetCount" [
  virtualEventWebinar_id: string
  virtualEventSession_id: string
  meetingAttendanceReport_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/($virtualEventSession_id)/attendanceReports/($meetingAttendanceReport_id)/attendanceRecords/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/{virtualEventSession-id}/attendanceReports/$count
# operationId: solution.virtualEvent.webinar.session.attendanceReport_GetCount
export def "solutions-virtual-events-webinars-sessions-attendance-reports-count GetCount" [
  virtualEventWebinar_id: string
  virtualEventSession_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/($virtualEventSession_id)/attendanceReports/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/webinars/{virtualEventWebinar-id}/sessions/$count
# operationId: solution.virtualEvent.webinar.session_GetCount
export def "solutions-virtual-events-webinars-sessions-count GetCount" [
  virtualEventWebinar_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/($virtualEventWebinar_id)/sessions/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the number of the resource
#
# GET /solutions/virtualEvents/webinars/$count
# operationId: solution.virtualEvent.webinar_GetCount
export def "solutions-virtual-events-webinars-count GetCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/solutions/virtualEvents/webinars/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke function getByUserIdAndRole
#
# GET /solutions/virtualEvents/webinars/microsoft.graph.getByUserIdAndRole(userId='{userId}',role='{role}')
# Docs: https://learn.microsoft.com/graph/api/virtualeventwebinar-getbyuseridandrole?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar_getGraphBPreUserIdAndRole
export def "solutions-virtual-events-webinars-microsoftgraphget-by-user-id-and-roleuser-id-user-id-role-role get" [
  userId: string
  role: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<audience: string, coOrganizers: list, registrationConfiguration: record, registrations: list>, _odata_nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/microsoft.graph.getByUserIdAndRole(userId='($userId)',role='($role)')" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke function getByUserRole
#
# GET /solutions/virtualEvents/webinars/microsoft.graph.getByUserRole(role='{role}')
# Docs: https://learn.microsoft.com/graph/api/virtualeventwebinar-getbyuserrole?view=graph-rest-1.0 — Find more info here
# operationId: solution.virtualEvent.webinar_getGraphBPreUserRole
export def "solutions-virtual-events-webinars-microsoftgraphget-by-user-rolerole-role get" [
  role: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --top: int # Show only the first n items (e.g. 50)
  --skip: int # Skip the first n items
  --search: string # Search items by search phrases
  --filter: string # Filter items by property values
  --count: string@bool-completer # Include count of items
  --select: list # Select properties to be returned
  --orderby: list # Order items by property values
  --expand: list # Expand related entities
]: nothing -> record<value: table<audience: string, coOrganizers: list, registrationConfiguration: record, registrations: list>, _odata_nextLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$top" $top "scalar") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "$expand" $expand "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/solutions/virtualEvents/webinars/microsoft.graph.getByUserRole(role='($role)')" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
