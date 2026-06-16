# Auto-generated client for Groups Settings API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/groupssettings/v1/openapi.json
# Auth: --token flag or $env.GROUPS_SETTINGS_API_TOKEN

const BASE_URL = "https://www.googleapis.com/groups/v1/groups"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GROUPS_SETTINGS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://www.googleapis.com/groups/v1/groups"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def alt-completer [] { ["atom" "json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "groups groupsSettingsgroupsget" } } | get name | first)
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

# Gets one resource by id.
#
# GET /{groupUniqueId}
# operationId: groupsSettings.groups.get
export def "groups groupsSettingsgroupsget" [
  groupUniqueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
]: nothing -> record<allowExternalMembers: string, allowGoogleCommunication: string, allowWebPosting: string, archiveOnly: string, customFooterText: string, customReplyTo: string, customRolesEnabledForSettingsToBeMerged: string, defaultMessageDenyNotificationText: string, default_sender: string, description: string, email: string, enableCollaborativeInbox: string, favoriteRepliesOnTop: string, includeCustomFooter: string, includeInGlobalAddressList: string, isArchived: string, kind: string, maxMessageBytes: int, membersCanPostAsTheGroup: string, messageDisplayFont: string, messageModerationLevel: string, name: string, primaryLanguage: string, replyTo: string, sendMessageDenyNotification: string, showInGroupDirectory: string, spamModerationLevel: string, whoCanAdd: string, whoCanAddReferences: string, whoCanApproveMembers: string, whoCanApproveMessages: string, whoCanAssignTopics: string, whoCanAssistContent: string, whoCanBanUsers: string, whoCanContactOwner: string, whoCanDeleteAnyPost: string, whoCanDeleteTopics: string, whoCanDiscoverGroup: string, whoCanEnterFreeFormTags: string, whoCanHideAbuse: string, whoCanInvite: string, whoCanJoin: string, whoCanLeaveGroup: string, whoCanLockTopics: string, whoCanMakeTopicsSticky: string, whoCanMarkDuplicate: string, whoCanMarkFavoriteReplyOnAnyTopic: string, whoCanMarkFavoriteReplyOnOwnTopic: string, whoCanMarkNoResponseNeeded: string, whoCanModerateContent: string, whoCanModerateMembers: string, whoCanModifyMembers: string, whoCanModifyTagsAndCategories: string, whoCanMoveTopicsIn: string, whoCanMoveTopicsOut: string, whoCanPostAnnouncements: string, whoCanPostMessage: string, whoCanTakeTopics: string, whoCanUnassignTopic: string, whoCanUnmarkFavoriteReplyOnAnyTopic: string, whoCanViewGroup: string, whoCanViewMembership: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($groupUniqueId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing resource. This method supports patch semantics.
#
# PATCH /{groupUniqueId}
# operationId: groupsSettings.groups.patch
export def "groups groupsSettingsgroupspatch" [
  groupUniqueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --allowExternalMembers: string # Identifies whether members external to your organization can join the group. Possible values are:   - true: G Suite users external to your organization can become members of this group.  - false: Users not belonging to the organization are not allowed to become members of this group.
  --allowGoogleCommunication: string # Deprecated. Allows Google to contact administrator of the group.   - true: Allow Google to contact managers of this group. Occasionally Google may send updates on the latest features, ask for input on new features, or ask for permission to highlight your group.  - false: Google can not contact managers of this group.
  --allowWebPosting: string # Allows posting from web. Possible values are:   - true: Allows any member to post to the group forum.  - false: Members only use Gmail to communicate with the group.
  --archiveOnly: string # Allows the group to be archived only. Possible values are:   - true: Group is archived and the group is inactive. New messages to this group are rejected. The older archived messages are browseable and searchable.   - If true, the whoCanPostMessage property is set to NONE_CAN_POST.   - If reverted from true to false, whoCanPostMessages is set to ALL_MANAGERS_CAN_POST.   - false: The group is active and can receive messages.   - When false, updating whoCanPostMessage to NONE_CAN_POST, results in an error.
  --customFooterText: string # Set the content of custom footer text. The maximum number of characters is 1,000.
  --customReplyTo: string # An email address used when replying to a message if the replyTo property is set to REPLY_TO_CUSTOM. This address is defined by an account administrator.   - When the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property holds a custom email address used when replying to a message.  - If the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property must have a text value or an error is returned.
  --customRolesEnabledForSettingsToBeMerged: string # Specifies whether the group has a custom role that's included in one of the settings being merged. This field is read-only and update/patch requests to it are ignored. Possible values are:   - true  - false
  --defaultMessageDenyNotificationText: string # When a message is rejected, this is text for the rejection notification sent to the message's author. By default, this property is empty and has no value in the API's response body. The maximum notification text size is 10,000 characters. Note: Requires sendMessageDenyNotification property to be true.
  --default-sender: string # Default sender for members who can post messages as the group. Possible values are: - `DEFAULT_SELF`: By default messages will be sent from the user - `GROUP`: By default messages will be sent from the group
  --description: string # Description of the group. This property value may be an empty string if no group description has been entered. If entered, the maximum group description is no more than 300 characters.
  --email: string # The group's email address. This property can be updated using the Directory API. Note: Only a group owner can change a group's email address. A group manager can't do this. When you change your group's address using the Directory API or the control panel, you are changing the address your subscribers use to send email and the web address people use to access your group. People can't reach your group by visiting the old address.
  --enableCollaborativeInbox: string # Specifies whether a collaborative inbox will remain turned on for the group. Possible values are:   - true  - false
  --favoriteRepliesOnTop: string # Indicates if favorite replies should be displayed above other replies.   - true: Favorite replies will be displayed above other replies.  - false: Favorite replies will not be displayed above other replies.
  --includeCustomFooter: string # Whether to include custom footer. Possible values are:   - true  - false
  --includeInGlobalAddressList: string # Enables the group to be included in the Global Address List. For more information, see the help center. Possible values are:   - true: Group is included in the Global Address List.  - false: Group is not included in the Global Address List.
  --isArchived: string # Allows the Group contents to be archived. Possible values are:   - true: Archive messages sent to the group.  - false: Do not keep an archive of messages sent to this group. If false, previously archived messages remain in the archive.
  --kind: string # The type of the resource. It is always groupsSettings#groups. (default: groupsSettings#groups)
  --maxMessageBytes: int # Deprecated. The maximum size of a message is 25Mb. (format: int32)
  --membersCanPostAsTheGroup: string # Enables members to post messages as the group. Possible values are:   - true: Group member can post messages using the group's email address instead of their own email address. Message appear to originate from the group itself. Note: When true, any message moderation settings on individual users or new members do not apply to posts made on behalf of the group.  - false: Members can not post in behalf of the group's email address.
  --messageDisplayFont: string # Deprecated. The default message display font always has a value of "DEFAULT_FONT".
  --messageModerationLevel: string # Moderation level of incoming messages. Possible values are:   - MODERATE_ALL_MESSAGES: All messages are sent to the group owner's email address for approval. If approved, the message is sent to the group.  - MODERATE_NON_MEMBERS: All messages from non group members are sent to the group owner's email address for approval. If approved, the message is sent to the group.  - MODERATE_NEW_MEMBERS: All messages from new members are sent to the group owner's email address for approval. If approved, the message is sent to the group.  - MODERATE_NONE: No moderator approval is required. Messages are delivered directly to the group. Note: When the whoCanPostMessage is set to ANYONE_CAN_POST, we recommend the messageModerationLevel be set to MODERATE_NON_MEMBERS to protect the group from possible spam. When memberCanPostAsTheGroup is true, any message moderation settings on individual users or new members will not apply to posts made on behalf of the group.
  --name: string # Name of the group, which has a maximum size of 75 characters.
  --primaryLanguage: string # The primary language for group. For a group's primary language use the language tags from the G Suite languages found at G Suite Email Settings API Email Language Tags.
  --replyTo: string # Specifies who receives the default reply. Possible values are:   - REPLY_TO_CUSTOM: For replies to messages, use the group's custom email address. When the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property holds the custom email address used when replying to a message. If the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property must have a value. Otherwise an error is returned.   - REPLY_TO_SENDER: The reply sent to author of message.  - REPLY_TO_LIST: This reply message is sent to the group.  - REPLY_TO_OWNER: The reply is sent to the owner(s) of the group. This does not include the group's managers.  - REPLY_TO_IGNORE: Group users individually decide where the message reply is sent.  - REPLY_TO_MANAGERS: This reply message is sent to the group's managers, which includes all managers and the group owner.
  --sendMessageDenyNotification: string # Allows a member to be notified if the member's message to the group is denied by the group owner. Possible values are:   - true: When a message is rejected, send the deny message notification to the message author. The defaultMessageDenyNotificationText property is dependent on the sendMessageDenyNotification property being true.   - false: When a message is rejected, no notification is sent.
  --showInGroupDirectory: string # Deprecated. This is merged into the new whoCanDiscoverGroup setting. Allows the group to be visible in the Groups Directory. Possible values are:   - true: All groups in the account are listed in the Groups directory.  - false: All groups in the account are not listed in the directory.
  --spamModerationLevel: string # Specifies moderation levels for messages detected as spam. Possible values are:   - ALLOW: Post the message to the group.  - MODERATE: Send the message to the moderation queue. This is the default.  - SILENTLY_MODERATE: Send the message to the moderation queue, but do not send notification to moderators.  - REJECT: Immediately reject the message.
  --whoCanAdd: string # Deprecated. This is merged into the new whoCanModerateMembers setting. Permissions to add members. Possible values are:   - ALL_MEMBERS_CAN_ADD: Managers and members can directly add new members.  - ALL_MANAGERS_CAN_ADD: Only managers can directly add new members. this includes the group's owner.  - ALL_OWNERS_CAN_ADD: Only owners can directly add new members.  - NONE_CAN_ADD: No one can directly add new members.
  --whoCanAddReferences: string # Deprecated. This functionality is no longer supported in the Google Groups UI. The value is always "NONE".
  --whoCanApproveMembers: string # Specifies who can approve members who ask to join groups. This permission will be deprecated once it is merged into the new whoCanModerateMembers setting. Possible values are:   - ALL_MEMBERS_CAN_APPROVE  - ALL_MANAGERS_CAN_APPROVE  - ALL_OWNERS_CAN_APPROVE  - NONE_CAN_APPROVE
  --whoCanApproveMessages: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can approve pending messages in the moderation queue. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanAssignTopics: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to assign topics in a forum to another user. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanAssistContent: string # Specifies who can moderate metadata. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanBanUsers: string # Specifies who can deny membership to users. This permission will be deprecated once it is merged into the new whoCanModerateMembers setting. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanContactOwner: string # Permission to contact owner of the group via web UI. Possible values are:   - ALL_IN_DOMAIN_CAN_CONTACT  - ALL_MANAGERS_CAN_CONTACT  - ALL_MEMBERS_CAN_CONTACT  - ANYONE_CAN_CONTACT  - ALL_OWNERS_CAN_CONTACT
  --whoCanDeleteAnyPost: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can delete replies to topics. (Authors can always delete their own posts). Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanDeleteTopics: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can delete topics. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanDiscoverGroup: string # Specifies the set of users for whom this group is discoverable. Possible values are:   - ANYONE_CAN_DISCOVER  - ALL_IN_DOMAIN_CAN_DISCOVER  - ALL_MEMBERS_CAN_DISCOVER
  --whoCanEnterFreeFormTags: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to enter free form tags for topics in a forum. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanHideAbuse: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can hide posts by reporting them as abuse. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanInvite: string # Deprecated. This is merged into the new whoCanModerateMembers setting. Permissions to invite new members. Possible values are:   - ALL_MEMBERS_CAN_INVITE: Managers and members can invite a new member candidate.  - ALL_MANAGERS_CAN_INVITE: Only managers can invite a new member. This includes the group's owner.  - ALL_OWNERS_CAN_INVITE: Only owners can invite a new member.  - NONE_CAN_INVITE: No one can invite a new member candidate.
  --whoCanJoin: string # Permission to join group. Possible values are:   - ANYONE_CAN_JOIN: Anyone in the account domain can join. This includes accounts with multiple domains.  - ALL_IN_DOMAIN_CAN_JOIN: Any Internet user who is outside your domain can access your Google Groups service and view the list of groups in your Groups directory. Warning: Group owners can add external addresses, outside of the domain to their groups. They can also allow people outside your domain to join their groups. If you later disable this option, any external addresses already added to users' groups remain in those groups.  - INVITED_CAN_JOIN: Candidates for membership can be invited to join.   - CAN_REQUEST_TO_JOIN: Non members can request an invitation to join.
  --whoCanLeaveGroup: string # Permission to leave the group. Possible values are:   - ALL_MANAGERS_CAN_LEAVE  - ALL_MEMBERS_CAN_LEAVE  - NONE_CAN_LEAVE
  --whoCanLockTopics: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can prevent users from posting replies to topics. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanMakeTopicsSticky: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can make topics appear at the top of the topic list. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanMarkDuplicate: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark a topic as a duplicate of another topic. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanMarkFavoriteReplyOnAnyTopic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark any other user's post as a favorite reply. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanMarkFavoriteReplyOnOwnTopic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark a post for a topic they started as a favorite reply. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanMarkNoResponseNeeded: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark a topic as not needing a response. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanModerateContent: string # Specifies who can moderate content. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanModerateMembers: string # Specifies who can manage members. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanModifyMembers: string # Deprecated. This is merged into the new whoCanModerateMembers setting. Specifies who can change group members' roles. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanModifyTagsAndCategories: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to change tags and categories. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanMoveTopicsIn: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can move topics into the group or forum. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanMoveTopicsOut: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can move topics out of the group or forum. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanPostAnnouncements: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can post announcements, a special topic type. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanPostMessage: string # Permissions to post messages. Possible values are:   - NONE_CAN_POST: The group is disabled and archived. No one can post a message to this group.   - When archiveOnly is false, updating whoCanPostMessage to NONE_CAN_POST, results in an error.  - If archiveOnly is reverted from true to false, whoCanPostMessages is set to ALL_MANAGERS_CAN_POST.   - ALL_MANAGERS_CAN_POST: Managers, including group owners, can post messages.  - ALL_MEMBERS_CAN_POST: Any group member can post a message.  - ALL_OWNERS_CAN_POST: Only group owners can post a message.  - ALL_IN_DOMAIN_CAN_POST: Anyone in the account can post a message.   - ANYONE_CAN_POST: Any Internet user who outside your account can access your Google Groups service and post a message. Note: When whoCanPostMessage is set to ANYONE_CAN_POST, we recommend the messageModerationLevel be set to MODERATE_NON_MEMBERS to protect the group from possible spam.
  --whoCanTakeTopics: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to take topics in a forum. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanUnassignTopic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to unassign any topic in a forum. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanUnmarkFavoriteReplyOnAnyTopic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to unmark any post from a favorite reply. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanViewGroup: string # Permissions to view group messages. Possible values are:   - ANYONE_CAN_VIEW: Any Internet user can view the group's messages.   - ALL_IN_DOMAIN_CAN_VIEW: Anyone in your account can view this group's messages.  - ALL_MEMBERS_CAN_VIEW: All group members can view the group's messages.  - ALL_MANAGERS_CAN_VIEW: Any group manager can view this group's messages.
  --whoCanViewMembership: string # Permissions to view membership. Possible values are:   - ALL_IN_DOMAIN_CAN_VIEW: Anyone in the account can view the group members list. If a group already has external members, those members can still send email to this group.   - ALL_MEMBERS_CAN_VIEW: The group members can view the group members list.  - ALL_MANAGERS_CAN_VIEW: The group managers can view group members list.
]: any -> record<allowExternalMembers: string, allowGoogleCommunication: string, allowWebPosting: string, archiveOnly: string, customFooterText: string, customReplyTo: string, customRolesEnabledForSettingsToBeMerged: string, defaultMessageDenyNotificationText: string, default_sender: string, description: string, email: string, enableCollaborativeInbox: string, favoriteRepliesOnTop: string, includeCustomFooter: string, includeInGlobalAddressList: string, isArchived: string, kind: string, maxMessageBytes: int, membersCanPostAsTheGroup: string, messageDisplayFont: string, messageModerationLevel: string, name: string, primaryLanguage: string, replyTo: string, sendMessageDenyNotification: string, showInGroupDirectory: string, spamModerationLevel: string, whoCanAdd: string, whoCanAddReferences: string, whoCanApproveMembers: string, whoCanApproveMessages: string, whoCanAssignTopics: string, whoCanAssistContent: string, whoCanBanUsers: string, whoCanContactOwner: string, whoCanDeleteAnyPost: string, whoCanDeleteTopics: string, whoCanDiscoverGroup: string, whoCanEnterFreeFormTags: string, whoCanHideAbuse: string, whoCanInvite: string, whoCanJoin: string, whoCanLeaveGroup: string, whoCanLockTopics: string, whoCanMakeTopicsSticky: string, whoCanMarkDuplicate: string, whoCanMarkFavoriteReplyOnAnyTopic: string, whoCanMarkFavoriteReplyOnOwnTopic: string, whoCanMarkNoResponseNeeded: string, whoCanModerateContent: string, whoCanModerateMembers: string, whoCanModifyMembers: string, whoCanModifyTagsAndCategories: string, whoCanMoveTopicsIn: string, whoCanMoveTopicsOut: string, whoCanPostAnnouncements: string, whoCanPostMessage: string, whoCanTakeTopics: string, whoCanUnassignTopic: string, whoCanUnmarkFavoriteReplyOnAnyTopic: string, whoCanViewGroup: string, whoCanViewMembership: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($groupUniqueId)" $qp)
  let body = {allowExternalMembers: $allowExternalMembers, allowGoogleCommunication: $allowGoogleCommunication, allowWebPosting: $allowWebPosting, archiveOnly: $archiveOnly, customFooterText: $customFooterText, customReplyTo: $customReplyTo, customRolesEnabledForSettingsToBeMerged: $customRolesEnabledForSettingsToBeMerged, defaultMessageDenyNotificationText: $defaultMessageDenyNotificationText, default_sender: $default_sender, description: $description, email: $email, enableCollaborativeInbox: $enableCollaborativeInbox, favoriteRepliesOnTop: $favoriteRepliesOnTop, includeCustomFooter: $includeCustomFooter, includeInGlobalAddressList: $includeInGlobalAddressList, isArchived: $isArchived, kind: $kind, maxMessageBytes: $maxMessageBytes, membersCanPostAsTheGroup: $membersCanPostAsTheGroup, messageDisplayFont: $messageDisplayFont, messageModerationLevel: $messageModerationLevel, name: $name, primaryLanguage: $primaryLanguage, replyTo: $replyTo, sendMessageDenyNotification: $sendMessageDenyNotification, showInGroupDirectory: $showInGroupDirectory, spamModerationLevel: $spamModerationLevel, whoCanAdd: $whoCanAdd, whoCanAddReferences: $whoCanAddReferences, whoCanApproveMembers: $whoCanApproveMembers, whoCanApproveMessages: $whoCanApproveMessages, whoCanAssignTopics: $whoCanAssignTopics, whoCanAssistContent: $whoCanAssistContent, whoCanBanUsers: $whoCanBanUsers, whoCanContactOwner: $whoCanContactOwner, whoCanDeleteAnyPost: $whoCanDeleteAnyPost, whoCanDeleteTopics: $whoCanDeleteTopics, whoCanDiscoverGroup: $whoCanDiscoverGroup, whoCanEnterFreeFormTags: $whoCanEnterFreeFormTags, whoCanHideAbuse: $whoCanHideAbuse, whoCanInvite: $whoCanInvite, whoCanJoin: $whoCanJoin, whoCanLeaveGroup: $whoCanLeaveGroup, whoCanLockTopics: $whoCanLockTopics, whoCanMakeTopicsSticky: $whoCanMakeTopicsSticky, whoCanMarkDuplicate: $whoCanMarkDuplicate, whoCanMarkFavoriteReplyOnAnyTopic: $whoCanMarkFavoriteReplyOnAnyTopic, whoCanMarkFavoriteReplyOnOwnTopic: $whoCanMarkFavoriteReplyOnOwnTopic, whoCanMarkNoResponseNeeded: $whoCanMarkNoResponseNeeded, whoCanModerateContent: $whoCanModerateContent, whoCanModerateMembers: $whoCanModerateMembers, whoCanModifyMembers: $whoCanModifyMembers, whoCanModifyTagsAndCategories: $whoCanModifyTagsAndCategories, whoCanMoveTopicsIn: $whoCanMoveTopicsIn, whoCanMoveTopicsOut: $whoCanMoveTopicsOut, whoCanPostAnnouncements: $whoCanPostAnnouncements, whoCanPostMessage: $whoCanPostMessage, whoCanTakeTopics: $whoCanTakeTopics, whoCanUnassignTopic: $whoCanUnassignTopic, whoCanUnmarkFavoriteReplyOnAnyTopic: $whoCanUnmarkFavoriteReplyOnAnyTopic, whoCanViewGroup: $whoCanViewGroup, whoCanViewMembership: $whoCanViewMembership} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an existing resource.
#
# PUT /{groupUniqueId}
# operationId: groupsSettings.groups.update
export def "groups groupsSettingsgroupsupdate" [
  groupUniqueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alt: string@alt-completer # Data format for the response.
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # An opaque string that represents a user for quota purposes. Must not exceed 40 characters.
  --userIp: string # Deprecated. Please use quotaUser instead.
  --allowExternalMembers: string # Identifies whether members external to your organization can join the group. Possible values are:   - true: G Suite users external to your organization can become members of this group.  - false: Users not belonging to the organization are not allowed to become members of this group.
  --allowGoogleCommunication: string # Deprecated. Allows Google to contact administrator of the group.   - true: Allow Google to contact managers of this group. Occasionally Google may send updates on the latest features, ask for input on new features, or ask for permission to highlight your group.  - false: Google can not contact managers of this group.
  --allowWebPosting: string # Allows posting from web. Possible values are:   - true: Allows any member to post to the group forum.  - false: Members only use Gmail to communicate with the group.
  --archiveOnly: string # Allows the group to be archived only. Possible values are:   - true: Group is archived and the group is inactive. New messages to this group are rejected. The older archived messages are browseable and searchable.   - If true, the whoCanPostMessage property is set to NONE_CAN_POST.   - If reverted from true to false, whoCanPostMessages is set to ALL_MANAGERS_CAN_POST.   - false: The group is active and can receive messages.   - When false, updating whoCanPostMessage to NONE_CAN_POST, results in an error.
  --customFooterText: string # Set the content of custom footer text. The maximum number of characters is 1,000.
  --customReplyTo: string # An email address used when replying to a message if the replyTo property is set to REPLY_TO_CUSTOM. This address is defined by an account administrator.   - When the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property holds a custom email address used when replying to a message.  - If the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property must have a text value or an error is returned.
  --customRolesEnabledForSettingsToBeMerged: string # Specifies whether the group has a custom role that's included in one of the settings being merged. This field is read-only and update/patch requests to it are ignored. Possible values are:   - true  - false
  --defaultMessageDenyNotificationText: string # When a message is rejected, this is text for the rejection notification sent to the message's author. By default, this property is empty and has no value in the API's response body. The maximum notification text size is 10,000 characters. Note: Requires sendMessageDenyNotification property to be true.
  --default-sender: string # Default sender for members who can post messages as the group. Possible values are: - `DEFAULT_SELF`: By default messages will be sent from the user - `GROUP`: By default messages will be sent from the group
  --description: string # Description of the group. This property value may be an empty string if no group description has been entered. If entered, the maximum group description is no more than 300 characters.
  --email: string # The group's email address. This property can be updated using the Directory API. Note: Only a group owner can change a group's email address. A group manager can't do this. When you change your group's address using the Directory API or the control panel, you are changing the address your subscribers use to send email and the web address people use to access your group. People can't reach your group by visiting the old address.
  --enableCollaborativeInbox: string # Specifies whether a collaborative inbox will remain turned on for the group. Possible values are:   - true  - false
  --favoriteRepliesOnTop: string # Indicates if favorite replies should be displayed above other replies.   - true: Favorite replies will be displayed above other replies.  - false: Favorite replies will not be displayed above other replies.
  --includeCustomFooter: string # Whether to include custom footer. Possible values are:   - true  - false
  --includeInGlobalAddressList: string # Enables the group to be included in the Global Address List. For more information, see the help center. Possible values are:   - true: Group is included in the Global Address List.  - false: Group is not included in the Global Address List.
  --isArchived: string # Allows the Group contents to be archived. Possible values are:   - true: Archive messages sent to the group.  - false: Do not keep an archive of messages sent to this group. If false, previously archived messages remain in the archive.
  --kind: string # The type of the resource. It is always groupsSettings#groups. (default: groupsSettings#groups)
  --maxMessageBytes: int # Deprecated. The maximum size of a message is 25Mb. (format: int32)
  --membersCanPostAsTheGroup: string # Enables members to post messages as the group. Possible values are:   - true: Group member can post messages using the group's email address instead of their own email address. Message appear to originate from the group itself. Note: When true, any message moderation settings on individual users or new members do not apply to posts made on behalf of the group.  - false: Members can not post in behalf of the group's email address.
  --messageDisplayFont: string # Deprecated. The default message display font always has a value of "DEFAULT_FONT".
  --messageModerationLevel: string # Moderation level of incoming messages. Possible values are:   - MODERATE_ALL_MESSAGES: All messages are sent to the group owner's email address for approval. If approved, the message is sent to the group.  - MODERATE_NON_MEMBERS: All messages from non group members are sent to the group owner's email address for approval. If approved, the message is sent to the group.  - MODERATE_NEW_MEMBERS: All messages from new members are sent to the group owner's email address for approval. If approved, the message is sent to the group.  - MODERATE_NONE: No moderator approval is required. Messages are delivered directly to the group. Note: When the whoCanPostMessage is set to ANYONE_CAN_POST, we recommend the messageModerationLevel be set to MODERATE_NON_MEMBERS to protect the group from possible spam. When memberCanPostAsTheGroup is true, any message moderation settings on individual users or new members will not apply to posts made on behalf of the group.
  --name: string # Name of the group, which has a maximum size of 75 characters.
  --primaryLanguage: string # The primary language for group. For a group's primary language use the language tags from the G Suite languages found at G Suite Email Settings API Email Language Tags.
  --replyTo: string # Specifies who receives the default reply. Possible values are:   - REPLY_TO_CUSTOM: For replies to messages, use the group's custom email address. When the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property holds the custom email address used when replying to a message. If the group's ReplyTo property is set to REPLY_TO_CUSTOM, the customReplyTo property must have a value. Otherwise an error is returned.   - REPLY_TO_SENDER: The reply sent to author of message.  - REPLY_TO_LIST: This reply message is sent to the group.  - REPLY_TO_OWNER: The reply is sent to the owner(s) of the group. This does not include the group's managers.  - REPLY_TO_IGNORE: Group users individually decide where the message reply is sent.  - REPLY_TO_MANAGERS: This reply message is sent to the group's managers, which includes all managers and the group owner.
  --sendMessageDenyNotification: string # Allows a member to be notified if the member's message to the group is denied by the group owner. Possible values are:   - true: When a message is rejected, send the deny message notification to the message author. The defaultMessageDenyNotificationText property is dependent on the sendMessageDenyNotification property being true.   - false: When a message is rejected, no notification is sent.
  --showInGroupDirectory: string # Deprecated. This is merged into the new whoCanDiscoverGroup setting. Allows the group to be visible in the Groups Directory. Possible values are:   - true: All groups in the account are listed in the Groups directory.  - false: All groups in the account are not listed in the directory.
  --spamModerationLevel: string # Specifies moderation levels for messages detected as spam. Possible values are:   - ALLOW: Post the message to the group.  - MODERATE: Send the message to the moderation queue. This is the default.  - SILENTLY_MODERATE: Send the message to the moderation queue, but do not send notification to moderators.  - REJECT: Immediately reject the message.
  --whoCanAdd: string # Deprecated. This is merged into the new whoCanModerateMembers setting. Permissions to add members. Possible values are:   - ALL_MEMBERS_CAN_ADD: Managers and members can directly add new members.  - ALL_MANAGERS_CAN_ADD: Only managers can directly add new members. this includes the group's owner.  - ALL_OWNERS_CAN_ADD: Only owners can directly add new members.  - NONE_CAN_ADD: No one can directly add new members.
  --whoCanAddReferences: string # Deprecated. This functionality is no longer supported in the Google Groups UI. The value is always "NONE".
  --whoCanApproveMembers: string # Specifies who can approve members who ask to join groups. This permission will be deprecated once it is merged into the new whoCanModerateMembers setting. Possible values are:   - ALL_MEMBERS_CAN_APPROVE  - ALL_MANAGERS_CAN_APPROVE  - ALL_OWNERS_CAN_APPROVE  - NONE_CAN_APPROVE
  --whoCanApproveMessages: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can approve pending messages in the moderation queue. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanAssignTopics: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to assign topics in a forum to another user. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanAssistContent: string # Specifies who can moderate metadata. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanBanUsers: string # Specifies who can deny membership to users. This permission will be deprecated once it is merged into the new whoCanModerateMembers setting. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanContactOwner: string # Permission to contact owner of the group via web UI. Possible values are:   - ALL_IN_DOMAIN_CAN_CONTACT  - ALL_MANAGERS_CAN_CONTACT  - ALL_MEMBERS_CAN_CONTACT  - ANYONE_CAN_CONTACT  - ALL_OWNERS_CAN_CONTACT
  --whoCanDeleteAnyPost: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can delete replies to topics. (Authors can always delete their own posts). Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanDeleteTopics: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can delete topics. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanDiscoverGroup: string # Specifies the set of users for whom this group is discoverable. Possible values are:   - ANYONE_CAN_DISCOVER  - ALL_IN_DOMAIN_CAN_DISCOVER  - ALL_MEMBERS_CAN_DISCOVER
  --whoCanEnterFreeFormTags: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to enter free form tags for topics in a forum. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanHideAbuse: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can hide posts by reporting them as abuse. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanInvite: string # Deprecated. This is merged into the new whoCanModerateMembers setting. Permissions to invite new members. Possible values are:   - ALL_MEMBERS_CAN_INVITE: Managers and members can invite a new member candidate.  - ALL_MANAGERS_CAN_INVITE: Only managers can invite a new member. This includes the group's owner.  - ALL_OWNERS_CAN_INVITE: Only owners can invite a new member.  - NONE_CAN_INVITE: No one can invite a new member candidate.
  --whoCanJoin: string # Permission to join group. Possible values are:   - ANYONE_CAN_JOIN: Anyone in the account domain can join. This includes accounts with multiple domains.  - ALL_IN_DOMAIN_CAN_JOIN: Any Internet user who is outside your domain can access your Google Groups service and view the list of groups in your Groups directory. Warning: Group owners can add external addresses, outside of the domain to their groups. They can also allow people outside your domain to join their groups. If you later disable this option, any external addresses already added to users' groups remain in those groups.  - INVITED_CAN_JOIN: Candidates for membership can be invited to join.   - CAN_REQUEST_TO_JOIN: Non members can request an invitation to join.
  --whoCanLeaveGroup: string # Permission to leave the group. Possible values are:   - ALL_MANAGERS_CAN_LEAVE  - ALL_MEMBERS_CAN_LEAVE  - NONE_CAN_LEAVE
  --whoCanLockTopics: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can prevent users from posting replies to topics. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanMakeTopicsSticky: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can make topics appear at the top of the topic list. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanMarkDuplicate: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark a topic as a duplicate of another topic. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanMarkFavoriteReplyOnAnyTopic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark any other user's post as a favorite reply. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanMarkFavoriteReplyOnOwnTopic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark a post for a topic they started as a favorite reply. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanMarkNoResponseNeeded: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to mark a topic as not needing a response. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanModerateContent: string # Specifies who can moderate content. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanModerateMembers: string # Specifies who can manage members. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanModifyMembers: string # Deprecated. This is merged into the new whoCanModerateMembers setting. Specifies who can change group members' roles. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanModifyTagsAndCategories: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to change tags and categories. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanMoveTopicsIn: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can move topics into the group or forum. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanMoveTopicsOut: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can move topics out of the group or forum. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanPostAnnouncements: string # Deprecated. This is merged into the new whoCanModerateContent setting. Specifies who can post announcements, a special topic type. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - OWNERS_ONLY  - NONE
  --whoCanPostMessage: string # Permissions to post messages. Possible values are:   - NONE_CAN_POST: The group is disabled and archived. No one can post a message to this group.   - When archiveOnly is false, updating whoCanPostMessage to NONE_CAN_POST, results in an error.  - If archiveOnly is reverted from true to false, whoCanPostMessages is set to ALL_MANAGERS_CAN_POST.   - ALL_MANAGERS_CAN_POST: Managers, including group owners, can post messages.  - ALL_MEMBERS_CAN_POST: Any group member can post a message.  - ALL_OWNERS_CAN_POST: Only group owners can post a message.  - ALL_IN_DOMAIN_CAN_POST: Anyone in the account can post a message.   - ANYONE_CAN_POST: Any Internet user who outside your account can access your Google Groups service and post a message. Note: When whoCanPostMessage is set to ANYONE_CAN_POST, we recommend the messageModerationLevel be set to MODERATE_NON_MEMBERS to protect the group from possible spam.
  --whoCanTakeTopics: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to take topics in a forum. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanUnassignTopic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to unassign any topic in a forum. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanUnmarkFavoriteReplyOnAnyTopic: string # Deprecated. This is merged into the new whoCanAssistContent setting. Permission to unmark any post from a favorite reply. Possible values are:   - ALL_MEMBERS  - OWNERS_AND_MANAGERS  - MANAGERS_ONLY  - OWNERS_ONLY  - NONE
  --whoCanViewGroup: string # Permissions to view group messages. Possible values are:   - ANYONE_CAN_VIEW: Any Internet user can view the group's messages.   - ALL_IN_DOMAIN_CAN_VIEW: Anyone in your account can view this group's messages.  - ALL_MEMBERS_CAN_VIEW: All group members can view the group's messages.  - ALL_MANAGERS_CAN_VIEW: Any group manager can view this group's messages.
  --whoCanViewMembership: string # Permissions to view membership. Possible values are:   - ALL_IN_DOMAIN_CAN_VIEW: Anyone in the account can view the group members list. If a group already has external members, those members can still send email to this group.   - ALL_MEMBERS_CAN_VIEW: The group members can view the group members list.  - ALL_MANAGERS_CAN_VIEW: The group managers can view group members list.
]: any -> record<allowExternalMembers: string, allowGoogleCommunication: string, allowWebPosting: string, archiveOnly: string, customFooterText: string, customReplyTo: string, customRolesEnabledForSettingsToBeMerged: string, defaultMessageDenyNotificationText: string, default_sender: string, description: string, email: string, enableCollaborativeInbox: string, favoriteRepliesOnTop: string, includeCustomFooter: string, includeInGlobalAddressList: string, isArchived: string, kind: string, maxMessageBytes: int, membersCanPostAsTheGroup: string, messageDisplayFont: string, messageModerationLevel: string, name: string, primaryLanguage: string, replyTo: string, sendMessageDenyNotification: string, showInGroupDirectory: string, spamModerationLevel: string, whoCanAdd: string, whoCanAddReferences: string, whoCanApproveMembers: string, whoCanApproveMessages: string, whoCanAssignTopics: string, whoCanAssistContent: string, whoCanBanUsers: string, whoCanContactOwner: string, whoCanDeleteAnyPost: string, whoCanDeleteTopics: string, whoCanDiscoverGroup: string, whoCanEnterFreeFormTags: string, whoCanHideAbuse: string, whoCanInvite: string, whoCanJoin: string, whoCanLeaveGroup: string, whoCanLockTopics: string, whoCanMakeTopicsSticky: string, whoCanMarkDuplicate: string, whoCanMarkFavoriteReplyOnAnyTopic: string, whoCanMarkFavoriteReplyOnOwnTopic: string, whoCanMarkNoResponseNeeded: string, whoCanModerateContent: string, whoCanModerateMembers: string, whoCanModifyMembers: string, whoCanModifyTagsAndCategories: string, whoCanMoveTopicsIn: string, whoCanMoveTopicsOut: string, whoCanPostAnnouncements: string, whoCanPostMessage: string, whoCanTakeTopics: string, whoCanUnassignTopic: string, whoCanUnmarkFavoriteReplyOnAnyTopic: string, whoCanViewGroup: string, whoCanViewMembership: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alt" $alt "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "userIp" $userIp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($groupUniqueId)" $qp)
  let body = {allowExternalMembers: $allowExternalMembers, allowGoogleCommunication: $allowGoogleCommunication, allowWebPosting: $allowWebPosting, archiveOnly: $archiveOnly, customFooterText: $customFooterText, customReplyTo: $customReplyTo, customRolesEnabledForSettingsToBeMerged: $customRolesEnabledForSettingsToBeMerged, defaultMessageDenyNotificationText: $defaultMessageDenyNotificationText, default_sender: $default_sender, description: $description, email: $email, enableCollaborativeInbox: $enableCollaborativeInbox, favoriteRepliesOnTop: $favoriteRepliesOnTop, includeCustomFooter: $includeCustomFooter, includeInGlobalAddressList: $includeInGlobalAddressList, isArchived: $isArchived, kind: $kind, maxMessageBytes: $maxMessageBytes, membersCanPostAsTheGroup: $membersCanPostAsTheGroup, messageDisplayFont: $messageDisplayFont, messageModerationLevel: $messageModerationLevel, name: $name, primaryLanguage: $primaryLanguage, replyTo: $replyTo, sendMessageDenyNotification: $sendMessageDenyNotification, showInGroupDirectory: $showInGroupDirectory, spamModerationLevel: $spamModerationLevel, whoCanAdd: $whoCanAdd, whoCanAddReferences: $whoCanAddReferences, whoCanApproveMembers: $whoCanApproveMembers, whoCanApproveMessages: $whoCanApproveMessages, whoCanAssignTopics: $whoCanAssignTopics, whoCanAssistContent: $whoCanAssistContent, whoCanBanUsers: $whoCanBanUsers, whoCanContactOwner: $whoCanContactOwner, whoCanDeleteAnyPost: $whoCanDeleteAnyPost, whoCanDeleteTopics: $whoCanDeleteTopics, whoCanDiscoverGroup: $whoCanDiscoverGroup, whoCanEnterFreeFormTags: $whoCanEnterFreeFormTags, whoCanHideAbuse: $whoCanHideAbuse, whoCanInvite: $whoCanInvite, whoCanJoin: $whoCanJoin, whoCanLeaveGroup: $whoCanLeaveGroup, whoCanLockTopics: $whoCanLockTopics, whoCanMakeTopicsSticky: $whoCanMakeTopicsSticky, whoCanMarkDuplicate: $whoCanMarkDuplicate, whoCanMarkFavoriteReplyOnAnyTopic: $whoCanMarkFavoriteReplyOnAnyTopic, whoCanMarkFavoriteReplyOnOwnTopic: $whoCanMarkFavoriteReplyOnOwnTopic, whoCanMarkNoResponseNeeded: $whoCanMarkNoResponseNeeded, whoCanModerateContent: $whoCanModerateContent, whoCanModerateMembers: $whoCanModerateMembers, whoCanModifyMembers: $whoCanModifyMembers, whoCanModifyTagsAndCategories: $whoCanModifyTagsAndCategories, whoCanMoveTopicsIn: $whoCanMoveTopicsIn, whoCanMoveTopicsOut: $whoCanMoveTopicsOut, whoCanPostAnnouncements: $whoCanPostAnnouncements, whoCanPostMessage: $whoCanPostMessage, whoCanTakeTopics: $whoCanTakeTopics, whoCanUnassignTopic: $whoCanUnassignTopic, whoCanUnmarkFavoriteReplyOnAnyTopic: $whoCanUnmarkFavoriteReplyOnAnyTopic, whoCanViewGroup: $whoCanViewGroup, whoCanViewMembership: $whoCanViewMembership} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
