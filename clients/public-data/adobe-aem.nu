# Auto-generated client for Adobe Experience Manager (AEM) API v3.7.1-pre.0
# Source: https://api.apis.guru/v2/specs/adobe.com/aem/3.7.1-pre.0/openapi.json
# Auth: --token flag or $env.ADOBE_EXPERIENCE_MANAGER_AEM__API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ADOBE_EXPERIENCE_MANAGER_AEM__API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["http://localhost" "http://adobe.local"] }
def auth-scheme-completer [] { ["basic"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "cqactionshtml post" } } | get name | first)
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

# POST /.cqactions.html
#
# operationId: postCqActions
export def "cqactionshtml post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorizableId: string
  --changelog: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "authorizableId" $authorizableId "scalar") (serialize-qp "changelog" $changelog "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/.cqactions.html" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/com.adobe.granite.auth.saml.SamlAuthenticationHandler.config
#
# operationId: postConfigAdobeGraniteSamlAuthenticationHandler
export def "apps-system-config-comadobegraniteauthsaml-saml-authentication-handlerconfig post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyStorePassword: string
  --keyStorePasswordTypeHint: string
  --serviceranking: int
  --servicerankingTypeHint: string
  --idpHttpRedirect: oneof<nothing, bool>
  --idpHttpRedirectTypeHint: string
  --createUser: oneof<nothing, bool>
  --createUserTypeHint: string
  --defaultRedirectUrl: string
  --defaultRedirectUrlTypeHint: string
  --userIDAttribute: string
  --userIDAttributeTypeHint: string
  --defaultGroups: list
  --defaultGroupsTypeHint: string
  --idpCertAlias: string
  --idpCertAliasTypeHint: string
  --addGroupMemberships: oneof<nothing, bool>
  --addGroupMembershipsTypeHint: string
  --path: list
  --pathTypeHint: string
  --synchronizeAttributes: list
  --synchronizeAttributesTypeHint: string
  --clockTolerance: int
  --clockToleranceTypeHint: string
  --groupMembershipAttribute: string
  --groupMembershipAttributeTypeHint: string
  --idpUrl: string
  --idpUrlTypeHint: string
  --logoutUrl: string
  --logoutUrlTypeHint: string
  --serviceProviderEntityId: string
  --serviceProviderEntityIdTypeHint: string
  --assertionConsumerServiceURL: string
  --assertionConsumerServiceURLTypeHint: string
  --handleLogout: oneof<nothing, bool>
  --handleLogoutTypeHint: string
  --spPrivateKeyAlias: string
  --spPrivateKeyAliasTypeHint: string
  --useEncryption: oneof<nothing, bool>
  --useEncryptionTypeHint: string
  --nameIdFormat: string
  --nameIdFormatTypeHint: string
  --digestMethod: string
  --digestMethodTypeHint: string
  --signatureMethod: string
  --signatureMethodTypeHint: string
  --userIntermediatePath: string
  --userIntermediatePathTypeHint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyStorePassword" $keyStorePassword "scalar") (serialize-qp "keyStorePassword@TypeHint" $keyStorePasswordTypeHint "scalar") (serialize-qp "service.ranking" $serviceranking "scalar") (serialize-qp "service.ranking@TypeHint" $servicerankingTypeHint "scalar") (serialize-qp "idpHttpRedirect" $idpHttpRedirect "scalar") (serialize-qp "idpHttpRedirect@TypeHint" $idpHttpRedirectTypeHint "scalar") (serialize-qp "createUser" $createUser "scalar") (serialize-qp "createUser@TypeHint" $createUserTypeHint "scalar") (serialize-qp "defaultRedirectUrl" $defaultRedirectUrl "scalar") (serialize-qp "defaultRedirectUrl@TypeHint" $defaultRedirectUrlTypeHint "scalar") (serialize-qp "userIDAttribute" $userIDAttribute "scalar") (serialize-qp "userIDAttribute@TypeHint" $userIDAttributeTypeHint "scalar") (serialize-qp "defaultGroups" $defaultGroups "multi") (serialize-qp "defaultGroups@TypeHint" $defaultGroupsTypeHint "scalar") (serialize-qp "idpCertAlias" $idpCertAlias "scalar") (serialize-qp "idpCertAlias@TypeHint" $idpCertAliasTypeHint "scalar") (serialize-qp "addGroupMemberships" $addGroupMemberships "scalar") (serialize-qp "addGroupMemberships@TypeHint" $addGroupMembershipsTypeHint "scalar") (serialize-qp "path" $path "multi") (serialize-qp "path@TypeHint" $pathTypeHint "scalar") (serialize-qp "synchronizeAttributes" $synchronizeAttributes "multi") (serialize-qp "synchronizeAttributes@TypeHint" $synchronizeAttributesTypeHint "scalar") (serialize-qp "clockTolerance" $clockTolerance "scalar") (serialize-qp "clockTolerance@TypeHint" $clockToleranceTypeHint "scalar") (serialize-qp "groupMembershipAttribute" $groupMembershipAttribute "scalar") (serialize-qp "groupMembershipAttribute@TypeHint" $groupMembershipAttributeTypeHint "scalar") (serialize-qp "idpUrl" $idpUrl "scalar") (serialize-qp "idpUrl@TypeHint" $idpUrlTypeHint "scalar") (serialize-qp "logoutUrl" $logoutUrl "scalar") (serialize-qp "logoutUrl@TypeHint" $logoutUrlTypeHint "scalar") (serialize-qp "serviceProviderEntityId" $serviceProviderEntityId "scalar") (serialize-qp "serviceProviderEntityId@TypeHint" $serviceProviderEntityIdTypeHint "scalar") (serialize-qp "assertionConsumerServiceURL" $assertionConsumerServiceURL "scalar") (serialize-qp "assertionConsumerServiceURL@TypeHint" $assertionConsumerServiceURLTypeHint "scalar") (serialize-qp "handleLogout" $handleLogout "scalar") (serialize-qp "handleLogout@TypeHint" $handleLogoutTypeHint "scalar") (serialize-qp "spPrivateKeyAlias" $spPrivateKeyAlias "scalar") (serialize-qp "spPrivateKeyAlias@TypeHint" $spPrivateKeyAliasTypeHint "scalar") (serialize-qp "useEncryption" $useEncryption "scalar") (serialize-qp "useEncryption@TypeHint" $useEncryptionTypeHint "scalar") (serialize-qp "nameIdFormat" $nameIdFormat "scalar") (serialize-qp "nameIdFormat@TypeHint" $nameIdFormatTypeHint "scalar") (serialize-qp "digestMethod" $digestMethod "scalar") (serialize-qp "digestMethod@TypeHint" $digestMethodTypeHint "scalar") (serialize-qp "signatureMethod" $signatureMethod "scalar") (serialize-qp "signatureMethod@TypeHint" $signatureMethodTypeHint "scalar") (serialize-qp "userIntermediatePath" $userIntermediatePath "scalar") (serialize-qp "userIntermediatePath@TypeHint" $userIntermediatePathTypeHint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/com.adobe.granite.auth.saml.SamlAuthenticationHandler.config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/com.shinesolutions.aem.passwordreset.Activator
#
# operationId: postConfigAemPasswordReset
export def "apps-system-config-comshinesolutionsaempasswordreset-activator post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pwdresetauthorizables: list
  --pwdresetauthorizablesTypeHint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pwdreset.authorizables" $pwdresetauthorizables "multi") (serialize-qp "pwdreset.authorizables@TypeHint" $pwdresetauthorizablesTypeHint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/com.shinesolutions.aem.passwordreset.Activator" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/com.shinesolutions.healthcheck.hc.impl.ActiveBundleHealthCheck
#
# operationId: postConfigAemHealthCheckServlet
export def "apps-system-config-comshinesolutionshealthcheckhcimpl-active-bundle-health-check post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bundlesignored: list
  --bundlesignoredTypeHint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bundles.ignored" $bundlesignored "multi") (serialize-qp "bundles.ignored@TypeHint" $bundlesignoredTypeHint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/com.shinesolutions.healthcheck.hc.impl.ActiveBundleHealthCheck" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/org.apache.felix.http
#
# operationId: postConfigApacheFelixJettyBasedHttpService
export def "apps-system-config-orgapachefelixhttp post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orgapachefelixhttpsnio: oneof<nothing, bool>
  --orgapachefelixhttpsnioTypeHint: string
  --orgapachefelixhttpskeystore: string
  --orgapachefelixhttpskeystoreTypeHint: string
  --orgapachefelixhttpskeystorepassword: string
  --orgapachefelixhttpskeystorepasswordTypeHint: string
  --orgapachefelixhttpskeystorekey: string
  --orgapachefelixhttpskeystorekeyTypeHint: string
  --orgapachefelixhttpskeystorekeypassword: string
  --orgapachefelixhttpskeystorekeypasswordTypeHint: string
  --orgapachefelixhttpstruststore: string
  --orgapachefelixhttpstruststoreTypeHint: string
  --orgapachefelixhttpstruststorepassword: string
  --orgapachefelixhttpstruststorepasswordTypeHint: string
  --orgapachefelixhttpsclientcertificate: string
  --orgapachefelixhttpsclientcertificateTypeHint: string
  --orgapachefelixhttpsenable: oneof<nothing, bool>
  --orgapachefelixhttpsenableTypeHint: string
  --orgosgiservicehttpportsecure: string
  --orgosgiservicehttpportsecureTypeHint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org.apache.felix.https.nio" $orgapachefelixhttpsnio "scalar") (serialize-qp "org.apache.felix.https.nio@TypeHint" $orgapachefelixhttpsnioTypeHint "scalar") (serialize-qp "org.apache.felix.https.keystore" $orgapachefelixhttpskeystore "scalar") (serialize-qp "org.apache.felix.https.keystore@TypeHint" $orgapachefelixhttpskeystoreTypeHint "scalar") (serialize-qp "org.apache.felix.https.keystore.password" $orgapachefelixhttpskeystorepassword "scalar") (serialize-qp "org.apache.felix.https.keystore.password@TypeHint" $orgapachefelixhttpskeystorepasswordTypeHint "scalar") (serialize-qp "org.apache.felix.https.keystore.key" $orgapachefelixhttpskeystorekey "scalar") (serialize-qp "org.apache.felix.https.keystore.key@TypeHint" $orgapachefelixhttpskeystorekeyTypeHint "scalar") (serialize-qp "org.apache.felix.https.keystore.key.password" $orgapachefelixhttpskeystorekeypassword "scalar") (serialize-qp "org.apache.felix.https.keystore.key.password@TypeHint" $orgapachefelixhttpskeystorekeypasswordTypeHint "scalar") (serialize-qp "org.apache.felix.https.truststore" $orgapachefelixhttpstruststore "scalar") (serialize-qp "org.apache.felix.https.truststore@TypeHint" $orgapachefelixhttpstruststoreTypeHint "scalar") (serialize-qp "org.apache.felix.https.truststore.password" $orgapachefelixhttpstruststorepassword "scalar") (serialize-qp "org.apache.felix.https.truststore.password@TypeHint" $orgapachefelixhttpstruststorepasswordTypeHint "scalar") (serialize-qp "org.apache.felix.https.clientcertificate" $orgapachefelixhttpsclientcertificate "scalar") (serialize-qp "org.apache.felix.https.clientcertificate@TypeHint" $orgapachefelixhttpsclientcertificateTypeHint "scalar") (serialize-qp "org.apache.felix.https.enable" $orgapachefelixhttpsenable "scalar") (serialize-qp "org.apache.felix.https.enable@TypeHint" $orgapachefelixhttpsenableTypeHint "scalar") (serialize-qp "org.osgi.service.http.port.secure" $orgosgiservicehttpportsecure "scalar") (serialize-qp "org.osgi.service.http.port.secure@TypeHint" $orgosgiservicehttpportsecureTypeHint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/org.apache.felix.http" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/org.apache.http.proxyconfigurator.config
#
# operationId: postConfigApacheHttpComponentsProxyConfiguration
export def "apps-system-config-orgapachehttpproxyconfiguratorconfig post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --proxyhost: string
  --proxyhostTypeHint: string
  --proxyport: int
  --proxyportTypeHint: string
  --proxyexceptions: list
  --proxyexceptionsTypeHint: string
  --proxyenabled: oneof<nothing, bool>
  --proxyenabledTypeHint: string
  --proxyuser: string
  --proxyuserTypeHint: string
  --proxypassword: string
  --proxypasswordTypeHint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "proxy.host" $proxyhost "scalar") (serialize-qp "proxy.host@TypeHint" $proxyhostTypeHint "scalar") (serialize-qp "proxy.port" $proxyport "scalar") (serialize-qp "proxy.port@TypeHint" $proxyportTypeHint "scalar") (serialize-qp "proxy.exceptions" $proxyexceptions "multi") (serialize-qp "proxy.exceptions@TypeHint" $proxyexceptionsTypeHint "scalar") (serialize-qp "proxy.enabled" $proxyenabled "scalar") (serialize-qp "proxy.enabled@TypeHint" $proxyenabledTypeHint "scalar") (serialize-qp "proxy.user" $proxyuser "scalar") (serialize-qp "proxy.user@TypeHint" $proxyuserTypeHint "scalar") (serialize-qp "proxy.password" $proxypassword "scalar") (serialize-qp "proxy.password@TypeHint" $proxypasswordTypeHint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/org.apache.http.proxyconfigurator.config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/org.apache.sling.jcr.davex.impl.servlets.SlingDavExServlet
#
# operationId: postConfigApacheSlingDavExServlet
export def "apps-system-config-orgapacheslingjcrdaveximplservlets-sling-dav-ex-servlet post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --aliasTypeHint: string
  --davcreate-absolute-uri: oneof<nothing, bool>
  --davcreate-absolute-uriTypeHint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alias" $alias "scalar") (serialize-qp "alias@TypeHint" $aliasTypeHint "scalar") (serialize-qp "dav.create-absolute-uri" $davcreate_absolute_uri "scalar") (serialize-qp "dav.create-absolute-uri@TypeHint" $davcreate_absolute_uriTypeHint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/org.apache.sling.jcr.davex.impl.servlets.SlingDavExServlet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/org.apache.sling.security.impl.ReferrerFilter
#
# operationId: postConfigApacheSlingReferrerFilter
export def "apps-system-config-orgapacheslingsecurityimpl-referrer-filter post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowempty: oneof<nothing, bool>
  --allowemptyTypeHint: string
  --allowhosts: string
  --allowhostsTypeHint: string
  --allowhostsregexp: string
  --allowhostsregexpTypeHint: string
  --filtermethods: string
  --filtermethodsTypeHint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allow.empty" $allowempty "scalar") (serialize-qp "allow.empty@TypeHint" $allowemptyTypeHint "scalar") (serialize-qp "allow.hosts" $allowhosts "scalar") (serialize-qp "allow.hosts@TypeHint" $allowhostsTypeHint "scalar") (serialize-qp "allow.hosts.regexp" $allowhostsregexp "scalar") (serialize-qp "allow.hosts.regexp@TypeHint" $allowhostsregexpTypeHint "scalar") (serialize-qp "filter.methods" $filtermethods "scalar") (serialize-qp "filter.methods@TypeHint" $filtermethodsTypeHint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/org.apache.sling.security.impl.ReferrerFilter" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/org.apache.sling.servlets.get.DefaultGetServlet
#
# operationId: postConfigApacheSlingGetServlet
export def "apps-system-config-orgapacheslingservletsget-default-get-servlet post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --jsonmaximumresults: string
  --jsonmaximumresultsTypeHint: string
  --enablehtml: oneof<nothing, bool>
  --enablehtmlTypeHint: string
  --enabletxt: oneof<nothing, bool>
  --enabletxtTypeHint: string
  --enablexml: oneof<nothing, bool>
  --enablexmlTypeHint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "json.maximumresults" $jsonmaximumresults "scalar") (serialize-qp "json.maximumresults@TypeHint" $jsonmaximumresultsTypeHint "scalar") (serialize-qp "enable.html" $enablehtml "scalar") (serialize-qp "enable.html@TypeHint" $enablehtmlTypeHint "scalar") (serialize-qp "enable.txt" $enabletxt "scalar") (serialize-qp "enable.txt@TypeHint" $enabletxtTypeHint "scalar") (serialize-qp "enable.xml" $enablexml "scalar") (serialize-qp "enable.xml@TypeHint" $enablexmlTypeHint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/org.apache.sling.servlets.get.DefaultGetServlet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/{configNodeName}
#
# operationId: postConfigProperty
export def "apps-system-config post" [
  configNodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/system/config/($configNodeName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /bin/querybuilder.json
#
# operationId: getQuery
export def "bin-querybuilderjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string
  --plimit: float
  --1-property: string
  --1-propertyvalue: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "p.limit" $plimit "scalar") (serialize-qp "1_property" $1_property "scalar") (serialize-qp "1_property.value" $1_propertyvalue "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bin/querybuilder.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /bin/querybuilder.json
#
# operationId: postQuery
export def "bin-querybuilderjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string
  --plimit: float
  --1-property: string
  --1-propertyvalue: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "p.limit" $plimit "scalar") (serialize-qp "1_property" $1_property "scalar") (serialize-qp "1_property.value" $1_propertyvalue "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bin/querybuilder.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /crx/explorer/ui/setpassword.jsp
#
# operationId: postSetPassword
export def "crx-explorer-ui-setpasswordjsp post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --old: string
  --plain: string
  --verify: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "old" $old "scalar") (serialize-qp "plain" $plain "scalar") (serialize-qp "verify" $verify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/crx/explorer/ui/setpassword.jsp" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /crx/packmgr/installstatus.jsp
#
# operationId: getInstallStatus
export def "crx-packmgr-installstatusjsp get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: record<finished: bool, itemCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/crx/packmgr/installstatus.jsp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /crx/packmgr/service.jsp
#
# operationId: postPackageService
export def "crx-packmgr-servicejsp post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cmd: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cmd" $cmd "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/crx/packmgr/service.jsp" $qp)
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /crx/packmgr/service/.json/{path}
#
# operationId: postPackageServiceJson
export def "crx-packmgr-service-json post" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cmd: string
  --groupName: string
  --packageName: string
  --packageVersion: string
  --charset: string
  --force: oneof<nothing, bool>
  --recursive: oneof<nothing, bool>
  --package: string # format: binary
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cmd" $cmd "scalar") (serialize-qp "groupName" $groupName "scalar") (serialize-qp "packageName" $packageName "scalar") (serialize-qp "packageVersion" $packageVersion "scalar") (serialize-qp "_charset_" $charset "scalar") (serialize-qp "force" $force "scalar") (serialize-qp "recursive" $recursive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/crx/packmgr/service/.json/($path)" $qp)
  let body = {package: $package} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# GET /crx/packmgr/service/script.html
#
# operationId: getPackageManagerServlet
export def "crx-packmgr-service-scripthtml get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/crx/packmgr/service/script.html")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /crx/packmgr/update.jsp
#
# operationId: postPackageUpdate
export def "crx-packmgr-updatejsp post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupName: string
  --packageName: string
  --version: string
  --path: string
  --filter: string
  --charset: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupName" $groupName "scalar") (serialize-qp "packageName" $packageName "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "_charset_" $charset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/crx/packmgr/update.jsp" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /crx/server/crx.default/jcr:root/.1.json
#
# operationId: getCrxdeStatus
export def "crx-server-crxdefault-jcr-root-1json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/crx/server/crx.default/jcr:root/.1.json")
  let accept_val = "plain/text"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /etc/packages/{group}/{name}-{version}.zip
#
# operationId: getPackage
export def "etc-packages get" [
  group: string
  name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/etc/packages/($group)/($name)-($version).zip")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /etc/packages/{group}/{name}-{version}.zip/jcr:content/vlt:definition/filter.tidy.2.json
#
# operationId: getPackageFilter
export def "etc-packages-jcr-content-vlt-definition-filtertidy2json get" [
  group: string
  name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/etc/packages/($group)/($name)-($version).zip/jcr:content/vlt:definition/filter.tidy.2.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /etc/replication/agents.{runmode}.-1.json
#
# operationId: getAgents
export def "etc-replication-agents-runmode-1json get" [
  runmode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/etc/replication/agents.($runmode).-1.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /etc/replication/agents.{runmode}/{name}
#
# operationId: deleteAgent
export def "etc-replication-agents-runmode delete" [
  runmode: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/etc/replication/agents.($runmode)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /etc/replication/agents.{runmode}/{name}
#
# operationId: getAgent
export def "etc-replication-agents-runmode get" [
  runmode: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/etc/replication/agents.($runmode)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /etc/replication/agents.{runmode}/{name}
#
# operationId: postAgent
export def "etc-replication-agents-runmode post" [
  runmode: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --jcr:contentcq:distribute: oneof<nothing, bool>
  --jcr:contentcq:distributeTypeHint: string
  --jcr:contentcq:name: string
  --jcr:contentcq:template: string
  --jcr:contentenabled: oneof<nothing, bool>
  --jcr:contentjcr:description: string
  --jcr:contentjcr:lastModified: string
  --jcr:contentjcr:lastModifiedBy: string
  --jcr:contentjcr:mixinTypes: string
  --jcr:contentjcr:title: string
  --jcr:contentlogLevel: string
  --jcr:contentnoStatusUpdate: oneof<nothing, bool>
  --jcr:contentnoVersioning: oneof<nothing, bool>
  --jcr:contentprotocolConnectTimeout: float
  --jcr:contentprotocolHTTPConnectionClosed: oneof<nothing, bool>
  --jcr:contentprotocolHTTPExpired: string
  --jcr:contentprotocolHTTPHeaders: list
  --jcr:contentprotocolHTTPHeadersTypeHint: string
  --jcr:contentprotocolHTTPMethod: string
  --jcr:contentprotocolHTTPSRelaxed: oneof<nothing, bool>
  --jcr:contentprotocolInterface: string
  --jcr:contentprotocolSocketTimeout: float
  --jcr:contentprotocolVersion: string
  --jcr:contentproxyNTLMDomain: string
  --jcr:contentproxyNTLMHost: string
  --jcr:contentproxyHost: string
  --jcr:contentproxyPassword: string
  --jcr:contentproxyPort: float
  --jcr:contentproxyUser: string
  --jcr:contentqueueBatchMaxSize: float
  --jcr:contentqueueBatchMode: string
  --jcr:contentqueueBatchWaitTime: float
  --jcr:contentretryDelay: string
  --jcr:contentreverseReplication: oneof<nothing, bool>
  --jcr:contentserializationType: string
  --jcr:contentsling:resourceType: string
  --jcr:contentssl: string
  --jcr:contenttransportNTLMDomain: string
  --jcr:contenttransportNTLMHost: string
  --jcr:contenttransportPassword: string
  --jcr:contenttransportUri: string
  --jcr:contenttransportUser: string
  --jcr:contenttriggerDistribute: oneof<nothing, bool>
  --jcr:contenttriggerModified: oneof<nothing, bool>
  --jcr:contenttriggerOnOffTime: oneof<nothing, bool>
  --jcr:contenttriggerReceive: oneof<nothing, bool>
  --jcr:contenttriggerSpecific: oneof<nothing, bool>
  --jcr:contentuserId: string
  --jcr:primaryType: string
  --:operation: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jcr:content/cq:distribute" $jcr:contentcq:distribute "scalar") (serialize-qp "jcr:content/cq:distribute@TypeHint" $jcr:contentcq:distributeTypeHint "scalar") (serialize-qp "jcr:content/cq:name" $jcr:contentcq:name "scalar") (serialize-qp "jcr:content/cq:template" $jcr:contentcq:template "scalar") (serialize-qp "jcr:content/enabled" $jcr:contentenabled "scalar") (serialize-qp "jcr:content/jcr:description" $jcr:contentjcr:description "scalar") (serialize-qp "jcr:content/jcr:lastModified" $jcr:contentjcr:lastModified "scalar") (serialize-qp "jcr:content/jcr:lastModifiedBy" $jcr:contentjcr:lastModifiedBy "scalar") (serialize-qp "jcr:content/jcr:mixinTypes" $jcr:contentjcr:mixinTypes "scalar") (serialize-qp "jcr:content/jcr:title" $jcr:contentjcr:title "scalar") (serialize-qp "jcr:content/logLevel" $jcr:contentlogLevel "scalar") (serialize-qp "jcr:content/noStatusUpdate" $jcr:contentnoStatusUpdate "scalar") (serialize-qp "jcr:content/noVersioning" $jcr:contentnoVersioning "scalar") (serialize-qp "jcr:content/protocolConnectTimeout" $jcr:contentprotocolConnectTimeout "scalar") (serialize-qp "jcr:content/protocolHTTPConnectionClosed" $jcr:contentprotocolHTTPConnectionClosed "scalar") (serialize-qp "jcr:content/protocolHTTPExpired" $jcr:contentprotocolHTTPExpired "scalar") (serialize-qp "jcr:content/protocolHTTPHeaders" $jcr:contentprotocolHTTPHeaders "multi") (serialize-qp "jcr:content/protocolHTTPHeaders@TypeHint" $jcr:contentprotocolHTTPHeadersTypeHint "scalar") (serialize-qp "jcr:content/protocolHTTPMethod" $jcr:contentprotocolHTTPMethod "scalar") (serialize-qp "jcr:content/protocolHTTPSRelaxed" $jcr:contentprotocolHTTPSRelaxed "scalar") (serialize-qp "jcr:content/protocolInterface" $jcr:contentprotocolInterface "scalar") (serialize-qp "jcr:content/protocolSocketTimeout" $jcr:contentprotocolSocketTimeout "scalar") (serialize-qp "jcr:content/protocolVersion" $jcr:contentprotocolVersion "scalar") (serialize-qp "jcr:content/proxyNTLMDomain" $jcr:contentproxyNTLMDomain "scalar") (serialize-qp "jcr:content/proxyNTLMHost" $jcr:contentproxyNTLMHost "scalar") (serialize-qp "jcr:content/proxyHost" $jcr:contentproxyHost "scalar") (serialize-qp "jcr:content/proxyPassword" $jcr:contentproxyPassword "scalar") (serialize-qp "jcr:content/proxyPort" $jcr:contentproxyPort "scalar") (serialize-qp "jcr:content/proxyUser" $jcr:contentproxyUser "scalar") (serialize-qp "jcr:content/queueBatchMaxSize" $jcr:contentqueueBatchMaxSize "scalar") (serialize-qp "jcr:content/queueBatchMode" $jcr:contentqueueBatchMode "scalar") (serialize-qp "jcr:content/queueBatchWaitTime" $jcr:contentqueueBatchWaitTime "scalar") (serialize-qp "jcr:content/retryDelay" $jcr:contentretryDelay "scalar") (serialize-qp "jcr:content/reverseReplication" $jcr:contentreverseReplication "scalar") (serialize-qp "jcr:content/serializationType" $jcr:contentserializationType "scalar") (serialize-qp "jcr:content/sling:resourceType" $jcr:contentsling:resourceType "scalar") (serialize-qp "jcr:content/ssl" $jcr:contentssl "scalar") (serialize-qp "jcr:content/transportNTLMDomain" $jcr:contenttransportNTLMDomain "scalar") (serialize-qp "jcr:content/transportNTLMHost" $jcr:contenttransportNTLMHost "scalar") (serialize-qp "jcr:content/transportPassword" $jcr:contenttransportPassword "scalar") (serialize-qp "jcr:content/transportUri" $jcr:contenttransportUri "scalar") (serialize-qp "jcr:content/transportUser" $jcr:contenttransportUser "scalar") (serialize-qp "jcr:content/triggerDistribute" $jcr:contenttriggerDistribute "scalar") (serialize-qp "jcr:content/triggerModified" $jcr:contenttriggerModified "scalar") (serialize-qp "jcr:content/triggerOnOffTime" $jcr:contenttriggerOnOffTime "scalar") (serialize-qp "jcr:content/triggerReceive" $jcr:contenttriggerReceive "scalar") (serialize-qp "jcr:content/triggerSpecific" $jcr:contenttriggerSpecific "scalar") (serialize-qp "jcr:content/userId" $jcr:contentuserId "scalar") (serialize-qp "jcr:primaryType" $jcr:primaryType "scalar") (serialize-qp ":operation" $:operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/etc/replication/agents.($runmode)/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /etc/truststore
#
# operationId: postTruststorePKCS12
export def "etc-truststore post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --truststorep12: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/etc/truststore")
  let body = {truststore.p12: $truststorep12} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# GET /etc/truststore/truststore.p12
#
# operationId: getTruststore
export def "etc-truststore-truststorep12 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/etc/truststore/truststore.p12")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /libs/granite/core/content/login.html
#
# operationId: getLoginPage
export def "libs-granite-core-content-loginhtml get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/libs/granite/core/content/login.html")
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /libs/granite/security/post/authorizables
#
# operationId: postAuthorizables
export def "libs-granite-security-post-authorizables post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorizableId: string
  --intermediatePath: string
  --createUser: string
  --createGroup: string
  --rep:password: string
  --profilegivenName: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "authorizableId" $authorizableId "scalar") (serialize-qp "intermediatePath" $intermediatePath "scalar") (serialize-qp "createUser" $createUser "scalar") (serialize-qp "createGroup" $createGroup "scalar") (serialize-qp "rep:password" $rep:password "scalar") (serialize-qp "profile/givenName" $profilegivenName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libs/granite/security/post/authorizables" $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /libs/granite/security/post/sslSetup.html
#
# operationId: sslSetup
export def "libs-granite-security-post-ssl-setuphtml sslSetup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --keystorePassword: string
  --keystorePasswordConfirm: string
  --truststorePassword: string
  --truststorePasswordConfirm: string
  --httpsHostname: string
  --httpsPort: string
  --certificateFile: string # format: binary
  --privatekeyFile: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keystorePassword" $keystorePassword "scalar") (serialize-qp "keystorePasswordConfirm" $keystorePasswordConfirm "scalar") (serialize-qp "truststorePassword" $truststorePassword "scalar") (serialize-qp "truststorePasswordConfirm" $truststorePasswordConfirm "scalar") (serialize-qp "httpsHostname" $httpsHostname "scalar") (serialize-qp "httpsPort" $httpsPort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libs/granite/security/post/sslSetup.html" $qp)
  let body = {certificateFile: $certificateFile, privatekeyFile: $privatekeyFile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# POST /libs/granite/security/post/truststore
#
# operationId: postTruststore
export def "libs-granite-security-post-truststore post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --:operation: string
  --newPassword: string
  --rePassword: string
  --keyStoreType: string
  --removeAlias: string
  --certificate: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp ":operation" $:operation "scalar") (serialize-qp "newPassword" $newPassword "scalar") (serialize-qp "rePassword" $rePassword "scalar") (serialize-qp "keyStoreType" $keyStoreType "scalar") (serialize-qp "removeAlias" $removeAlias "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libs/granite/security/post/truststore" $qp)
  let body = {certificate: $certificate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# GET /libs/granite/security/truststore.json
#
# operationId: getTruststoreInfo
export def "libs-granite-security-truststorejson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<aliases: table<alias: string, entryType: string, issuer: string, notAfter: string, notBefore: string, serialNumber: int, subject: string>, exists: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/libs/granite/security/truststore.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /libs/replication/treeactivation.html
#
# operationId: postTreeActivation
export def "libs-replication-treeactivationhtml post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignoredeactivated: oneof<nothing, bool>
  --onlymodified: oneof<nothing, bool>
  --path: string
  --cmd: string # default: activate
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignoredeactivated" $ignoredeactivated "scalar") (serialize-qp "onlymodified" $onlymodified "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "cmd" $cmd "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libs/replication/treeactivation.html" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /system/console/bundles/{name}
#
# operationId: postBundle
export def "system-console-bundles post" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/system/console/bundles/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /system/console/bundles/{name}.json
#
# operationId: getBundleInfo
export def "system-console-bundles get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<category: string, fragment: bool, id: int, name: string, props: list, state: string, stateRaw: int, symbolicName: string, version: string>, s: list<int>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/console/bundles/($name).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /system/console/configMgr
#
# operationId: getConfigMgr
export def "system-console-config-mgr get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/console/configMgr")
  let accept_val = "text/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /system/console/configMgr/com.adobe.granite.auth.saml.SamlAuthenticationHandler
#
# operationId: postSamlConfiguration
export def "system-console-config-mgr-comadobegraniteauthsaml-saml-authentication-handler post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --post: oneof<nothing, bool>
  --apply: oneof<nothing, bool>
  --delete: oneof<nothing, bool>
  --action: string
  --location: string
  --path: list
  --serviceranking: int
  --idpUrl: string
  --idpCertAlias: string
  --idpHttpRedirect: oneof<nothing, bool>
  --serviceProviderEntityId: string
  --assertionConsumerServiceURL: string
  --spPrivateKeyAlias: string
  --keyStorePassword: string
  --defaultRedirectUrl: string
  --userIDAttribute: string
  --useEncryption: oneof<nothing, bool>
  --createUser: oneof<nothing, bool>
  --addGroupMemberships: oneof<nothing, bool>
  --groupMembershipAttribute: string
  --defaultGroups: list
  --nameIdFormat: string
  --synchronizeAttributes: list
  --handleLogout: oneof<nothing, bool>
  --logoutUrl: string
  --clockTolerance: int
  --digestMethod: string
  --signatureMethod: string
  --userIntermediatePath: string
  --propertylist: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "post" $post "scalar") (serialize-qp "apply" $apply "scalar") (serialize-qp "delete" $delete "scalar") (serialize-qp "action" $action "scalar") (serialize-qp "$location" $location "scalar") (serialize-qp "path" $path "multi") (serialize-qp "service.ranking" $serviceranking "scalar") (serialize-qp "idpUrl" $idpUrl "scalar") (serialize-qp "idpCertAlias" $idpCertAlias "scalar") (serialize-qp "idpHttpRedirect" $idpHttpRedirect "scalar") (serialize-qp "serviceProviderEntityId" $serviceProviderEntityId "scalar") (serialize-qp "assertionConsumerServiceURL" $assertionConsumerServiceURL "scalar") (serialize-qp "spPrivateKeyAlias" $spPrivateKeyAlias "scalar") (serialize-qp "keyStorePassword" $keyStorePassword "scalar") (serialize-qp "defaultRedirectUrl" $defaultRedirectUrl "scalar") (serialize-qp "userIDAttribute" $userIDAttribute "scalar") (serialize-qp "useEncryption" $useEncryption "scalar") (serialize-qp "createUser" $createUser "scalar") (serialize-qp "addGroupMemberships" $addGroupMemberships "scalar") (serialize-qp "groupMembershipAttribute" $groupMembershipAttribute "scalar") (serialize-qp "defaultGroups" $defaultGroups "multi") (serialize-qp "nameIdFormat" $nameIdFormat "scalar") (serialize-qp "synchronizeAttributes" $synchronizeAttributes "multi") (serialize-qp "handleLogout" $handleLogout "scalar") (serialize-qp "logoutUrl" $logoutUrl "scalar") (serialize-qp "clockTolerance" $clockTolerance "scalar") (serialize-qp "digestMethod" $digestMethod "scalar") (serialize-qp "signatureMethod" $signatureMethod "scalar") (serialize-qp "userIntermediatePath" $userIntermediatePath "scalar") (serialize-qp "propertylist" $propertylist "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/system/console/configMgr/com.adobe.granite.auth.saml.SamlAuthenticationHandler" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /system/console/jmx/com.adobe.granite:type=Repository/op/{action}
#
# operationId: postJmxRepository
export def "system-console-jmx-comadobegranite-type-repository-op post" [
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/system/console/jmx/com.adobe.granite:type=Repository/op/($action)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /system/console/status-productinfo.json
#
# operationId: getAemProductInfo
export def "system-console-status-productinfojson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/system/console/status-productinfo.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /system/health
#
# operationId: getAemHealthCheck
export def "system-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: string
  --combineTagsOr: oneof<nothing, bool>
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tags" $tags "scalar") (serialize-qp "combineTagsOr" $combineTagsOr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/system/health" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{intermediatePath}/{authorizableId}.ks.html
#
# operationId: postAuthorizableKeystore
export def "sling post-by-intermediatePath-authorizableId" [
  intermediatePath: string
  authorizableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --:operation: string
  --currentPassword: string
  --newPassword: string
  --rePassword: string
  --keyPassword: string
  --keyStorePass: string
  --alias: string
  --newAlias: string
  --removeAlias: string
  --cert-chain: string # format: binary
  --keyStore: string # format: binary
  --pk: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp ":operation" $:operation "scalar") (serialize-qp "currentPassword" $currentPassword "scalar") (serialize-qp "newPassword" $newPassword "scalar") (serialize-qp "rePassword" $rePassword "scalar") (serialize-qp "keyPassword" $keyPassword "scalar") (serialize-qp "keyStorePass" $keyStorePass "scalar") (serialize-qp "alias" $alias "scalar") (serialize-qp "newAlias" $newAlias "scalar") (serialize-qp "removeAlias" $removeAlias "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($intermediatePath)/($authorizableId).ks.html" $qp)
  let body = {cert-chain: $cert_chain, keyStore: $keyStore, pk: $pk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# GET /{intermediatePath}/{authorizableId}.ks.json
#
# operationId: getAuthorizableKeystore
export def "sling get-by-intermediatePath-authorizableId" [
  intermediatePath: string
  authorizableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($intermediatePath)/($authorizableId).ks.json")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /{intermediatePath}/{authorizableId}/keystore/store.p12
#
# operationId: getKeystore
export def "keystore-storep12 get" [
  intermediatePath: string
  authorizableId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($intermediatePath)/($authorizableId)/keystore/store.p12")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{path}/
#
# operationId: postPath
export def "sling post-by-path" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --jcr:primaryType: string
  --:name: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jcr:primaryType" $jcr:primaryType "scalar") (serialize-qp ":name" $:name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($path)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /{path}/{name}
#
# operationId: deleteNode
export def "sling delete" [
  path: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($path)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /{path}/{name}
#
# operationId: getNode
export def "sling get-by-path-name" [
  path: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($path)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{path}/{name}
#
# operationId: postNode
export def "sling post-by-path-name" [
  path: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --:operation: string
  --deleteAuthorizable: string
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp ":operation" $:operation "scalar") (serialize-qp "deleteAuthorizable" $deleteAuthorizable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($path)/($name)" $qp)
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# POST /{path}/{name}.rw.html
#
# operationId: postNodeRw
export def "sling post-by-path-name-1" [
  path: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --addMembers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "addMembers" $addMembers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($path)/($name).rw.html" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
