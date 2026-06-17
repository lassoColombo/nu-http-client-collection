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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "cqactionshtml create-cq-actions" } } | get name | first)
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
export def "cqactionshtml create-cq-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorizable-id: string
  --changelog: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "authorizableId" $authorizable_id "scalar") (serialize-qp "changelog" $changelog "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/.cqactions.html" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/com.adobe.granite.auth.saml.SamlAuthenticationHandler.config
#
# operationId: postConfigAdobeGraniteSamlAuthenticationHandler
export def "apps-system-config-comadobegraniteauthsaml-saml-authentication-handlerconfig create-config-adobe-granite-saml-authentication-handler" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key-store-password: string
  --key-store-password-type-hint: string
  --service-ranking: int
  --service-ranking-type-hint: string
  --idp-http-redirect: oneof<nothing, bool>
  --idp-http-redirect-type-hint: string
  --create-user: oneof<nothing, bool>
  --create-user-type-hint: string
  --default-redirect-url: string
  --default-redirect-url-type-hint: string
  --user-id-attribute: string
  --user-id-attribute-type-hint: string
  --default-groups: list
  --default-groups-type-hint: string
  --idp-cert-alias: string
  --idp-cert-alias-type-hint: string
  --add-group-memberships: oneof<nothing, bool>
  --add-group-memberships-type-hint: string
  --path: list
  --path-type-hint: string
  --synchronize-attributes: list
  --synchronize-attributes-type-hint: string
  --clock-tolerance: int
  --clock-tolerance-type-hint: string
  --group-membership-attribute: string
  --group-membership-attribute-type-hint: string
  --idp-url: string
  --idp-url-type-hint: string
  --logout-url: string
  --logout-url-type-hint: string
  --service-provider-entity-id: string
  --service-provider-entity-id-type-hint: string
  --assertion-consumer-service-url: string
  --assertion-consumer-service-url-type-hint: string
  --handle-logout: oneof<nothing, bool>
  --handle-logout-type-hint: string
  --sp-private-key-alias: string
  --sp-private-key-alias-type-hint: string
  --use-encryption: oneof<nothing, bool>
  --use-encryption-type-hint: string
  --name-id-format: string
  --name-id-format-type-hint: string
  --digest-method: string
  --digest-method-type-hint: string
  --signature-method: string
  --signature-method-type-hint: string
  --user-intermediate-path: string
  --user-intermediate-path-type-hint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyStorePassword" $key_store_password "scalar") (serialize-qp "keyStorePassword@TypeHint" $key_store_password_type_hint "scalar") (serialize-qp "service.ranking" $service_ranking "scalar") (serialize-qp "service.ranking@TypeHint" $service_ranking_type_hint "scalar") (serialize-qp "idpHttpRedirect" $idp_http_redirect "scalar") (serialize-qp "idpHttpRedirect@TypeHint" $idp_http_redirect_type_hint "scalar") (serialize-qp "createUser" $create_user "scalar") (serialize-qp "createUser@TypeHint" $create_user_type_hint "scalar") (serialize-qp "defaultRedirectUrl" $default_redirect_url "scalar") (serialize-qp "defaultRedirectUrl@TypeHint" $default_redirect_url_type_hint "scalar") (serialize-qp "userIDAttribute" $user_id_attribute "scalar") (serialize-qp "userIDAttribute@TypeHint" $user_id_attribute_type_hint "scalar") (serialize-qp "defaultGroups" $default_groups "multi") (serialize-qp "defaultGroups@TypeHint" $default_groups_type_hint "scalar") (serialize-qp "idpCertAlias" $idp_cert_alias "scalar") (serialize-qp "idpCertAlias@TypeHint" $idp_cert_alias_type_hint "scalar") (serialize-qp "addGroupMemberships" $add_group_memberships "scalar") (serialize-qp "addGroupMemberships@TypeHint" $add_group_memberships_type_hint "scalar") (serialize-qp "path" $path "multi") (serialize-qp "path@TypeHint" $path_type_hint "scalar") (serialize-qp "synchronizeAttributes" $synchronize_attributes "multi") (serialize-qp "synchronizeAttributes@TypeHint" $synchronize_attributes_type_hint "scalar") (serialize-qp "clockTolerance" $clock_tolerance "scalar") (serialize-qp "clockTolerance@TypeHint" $clock_tolerance_type_hint "scalar") (serialize-qp "groupMembershipAttribute" $group_membership_attribute "scalar") (serialize-qp "groupMembershipAttribute@TypeHint" $group_membership_attribute_type_hint "scalar") (serialize-qp "idpUrl" $idp_url "scalar") (serialize-qp "idpUrl@TypeHint" $idp_url_type_hint "scalar") (serialize-qp "logoutUrl" $logout_url "scalar") (serialize-qp "logoutUrl@TypeHint" $logout_url_type_hint "scalar") (serialize-qp "serviceProviderEntityId" $service_provider_entity_id "scalar") (serialize-qp "serviceProviderEntityId@TypeHint" $service_provider_entity_id_type_hint "scalar") (serialize-qp "assertionConsumerServiceURL" $assertion_consumer_service_url "scalar") (serialize-qp "assertionConsumerServiceURL@TypeHint" $assertion_consumer_service_url_type_hint "scalar") (serialize-qp "handleLogout" $handle_logout "scalar") (serialize-qp "handleLogout@TypeHint" $handle_logout_type_hint "scalar") (serialize-qp "spPrivateKeyAlias" $sp_private_key_alias "scalar") (serialize-qp "spPrivateKeyAlias@TypeHint" $sp_private_key_alias_type_hint "scalar") (serialize-qp "useEncryption" $use_encryption "scalar") (serialize-qp "useEncryption@TypeHint" $use_encryption_type_hint "scalar") (serialize-qp "nameIdFormat" $name_id_format "scalar") (serialize-qp "nameIdFormat@TypeHint" $name_id_format_type_hint "scalar") (serialize-qp "digestMethod" $digest_method "scalar") (serialize-qp "digestMethod@TypeHint" $digest_method_type_hint "scalar") (serialize-qp "signatureMethod" $signature_method "scalar") (serialize-qp "signatureMethod@TypeHint" $signature_method_type_hint "scalar") (serialize-qp "userIntermediatePath" $user_intermediate_path "scalar") (serialize-qp "userIntermediatePath@TypeHint" $user_intermediate_path_type_hint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/com.adobe.granite.auth.saml.SamlAuthenticationHandler.config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/com.shinesolutions.aem.passwordreset.Activator
#
# operationId: postConfigAemPasswordReset
export def "apps-system-config-comshinesolutionsaempasswordreset-activator create-config-aem-password-reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pwdreset-authorizables: list
  --pwdreset-authorizables-type-hint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pwdreset.authorizables" $pwdreset_authorizables "multi") (serialize-qp "pwdreset.authorizables@TypeHint" $pwdreset_authorizables_type_hint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/com.shinesolutions.aem.passwordreset.Activator" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/com.shinesolutions.healthcheck.hc.impl.ActiveBundleHealthCheck
#
# operationId: postConfigAemHealthCheckServlet
export def "apps-system-config-comshinesolutionshealthcheckhcimpl-active-bundle-health-check create-config-aem-health-check-servlet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bundles-ignored: list
  --bundles-ignored-type-hint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bundles.ignored" $bundles_ignored "multi") (serialize-qp "bundles.ignored@TypeHint" $bundles_ignored_type_hint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/com.shinesolutions.healthcheck.hc.impl.ActiveBundleHealthCheck" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/org.apache.felix.http
#
# operationId: postConfigApacheFelixJettyBasedHttpService
export def "apps-system-config-orgapachefelixhttp create-config-apache-felix-jetty-based-http-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --org-apache-felix-https-nio: oneof<nothing, bool>
  --org-apache-felix-https-nio-type-hint: string
  --org-apache-felix-https-keystore: string
  --org-apache-felix-https-keystore-type-hint: string
  --org-apache-felix-https-keystore-password: string
  --org-apache-felix-https-keystore-password-type-hint: string
  --org-apache-felix-https-keystore-key: string
  --org-apache-felix-https-keystore-key-type-hint: string
  --org-apache-felix-https-keystore-key-password: string
  --org-apache-felix-https-keystore-key-password-type-hint: string
  --org-apache-felix-https-truststore: string
  --org-apache-felix-https-truststore-type-hint: string
  --org-apache-felix-https-truststore-password: string
  --org-apache-felix-https-truststore-password-type-hint: string
  --org-apache-felix-https-clientcertificate: string
  --org-apache-felix-https-clientcertificate-type-hint: string
  --org-apache-felix-https-enable: oneof<nothing, bool>
  --org-apache-felix-https-enable-type-hint: string
  --org-osgi-service-http-port-secure: string
  --org-osgi-service-http-port-secure-type-hint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "org.apache.felix.https.nio" $org_apache_felix_https_nio "scalar") (serialize-qp "org.apache.felix.https.nio@TypeHint" $org_apache_felix_https_nio_type_hint "scalar") (serialize-qp "org.apache.felix.https.keystore" $org_apache_felix_https_keystore "scalar") (serialize-qp "org.apache.felix.https.keystore@TypeHint" $org_apache_felix_https_keystore_type_hint "scalar") (serialize-qp "org.apache.felix.https.keystore.password" $org_apache_felix_https_keystore_password "scalar") (serialize-qp "org.apache.felix.https.keystore.password@TypeHint" $org_apache_felix_https_keystore_password_type_hint "scalar") (serialize-qp "org.apache.felix.https.keystore.key" $org_apache_felix_https_keystore_key "scalar") (serialize-qp "org.apache.felix.https.keystore.key@TypeHint" $org_apache_felix_https_keystore_key_type_hint "scalar") (serialize-qp "org.apache.felix.https.keystore.key.password" $org_apache_felix_https_keystore_key_password "scalar") (serialize-qp "org.apache.felix.https.keystore.key.password@TypeHint" $org_apache_felix_https_keystore_key_password_type_hint "scalar") (serialize-qp "org.apache.felix.https.truststore" $org_apache_felix_https_truststore "scalar") (serialize-qp "org.apache.felix.https.truststore@TypeHint" $org_apache_felix_https_truststore_type_hint "scalar") (serialize-qp "org.apache.felix.https.truststore.password" $org_apache_felix_https_truststore_password "scalar") (serialize-qp "org.apache.felix.https.truststore.password@TypeHint" $org_apache_felix_https_truststore_password_type_hint "scalar") (serialize-qp "org.apache.felix.https.clientcertificate" $org_apache_felix_https_clientcertificate "scalar") (serialize-qp "org.apache.felix.https.clientcertificate@TypeHint" $org_apache_felix_https_clientcertificate_type_hint "scalar") (serialize-qp "org.apache.felix.https.enable" $org_apache_felix_https_enable "scalar") (serialize-qp "org.apache.felix.https.enable@TypeHint" $org_apache_felix_https_enable_type_hint "scalar") (serialize-qp "org.osgi.service.http.port.secure" $org_osgi_service_http_port_secure "scalar") (serialize-qp "org.osgi.service.http.port.secure@TypeHint" $org_osgi_service_http_port_secure_type_hint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/org.apache.felix.http" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/org.apache.http.proxyconfigurator.config
#
# operationId: postConfigApacheHttpComponentsProxyConfiguration
export def "apps-system-config-orgapachehttpproxyconfiguratorconfig create-config-apache-http-components-proxy-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --proxy-host: string
  --proxy-host-type-hint: string
  --proxy-port: int
  --proxy-port-type-hint: string
  --proxy-exceptions: list
  --proxy-exceptions-type-hint: string
  --proxy-enabled: oneof<nothing, bool>
  --proxy-enabled-type-hint: string
  --proxy-user: string
  --proxy-user-type-hint: string
  --proxy-password: string
  --proxy-password-type-hint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "proxy.host" $proxy_host "scalar") (serialize-qp "proxy.host@TypeHint" $proxy_host_type_hint "scalar") (serialize-qp "proxy.port" $proxy_port "scalar") (serialize-qp "proxy.port@TypeHint" $proxy_port_type_hint "scalar") (serialize-qp "proxy.exceptions" $proxy_exceptions "multi") (serialize-qp "proxy.exceptions@TypeHint" $proxy_exceptions_type_hint "scalar") (serialize-qp "proxy.enabled" $proxy_enabled "scalar") (serialize-qp "proxy.enabled@TypeHint" $proxy_enabled_type_hint "scalar") (serialize-qp "proxy.user" $proxy_user "scalar") (serialize-qp "proxy.user@TypeHint" $proxy_user_type_hint "scalar") (serialize-qp "proxy.password" $proxy_password "scalar") (serialize-qp "proxy.password@TypeHint" $proxy_password_type_hint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/org.apache.http.proxyconfigurator.config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/org.apache.sling.jcr.davex.impl.servlets.SlingDavExServlet
#
# operationId: postConfigApacheSlingDavExServlet
export def "apps-system-config-orgapacheslingjcrdaveximplservlets-sling-dav-ex-servlet create-config-apache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --alias-type-hint: string
  --dav-create-absolute-uri: oneof<nothing, bool>
  --dav-create-absolute-uri-type-hint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alias" $alias "scalar") (serialize-qp "alias@TypeHint" $alias_type_hint "scalar") (serialize-qp "dav.create-absolute-uri" $dav_create_absolute_uri "scalar") (serialize-qp "dav.create-absolute-uri@TypeHint" $dav_create_absolute_uri_type_hint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/org.apache.sling.jcr.davex.impl.servlets.SlingDavExServlet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/org.apache.sling.security.impl.ReferrerFilter
#
# operationId: postConfigApacheSlingReferrerFilter
export def "apps-system-config-orgapacheslingsecurityimpl-referrer-filter create-config-apache-sling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-empty: oneof<nothing, bool>
  --allow-empty-type-hint: string
  --allow-hosts: string
  --allow-hosts-type-hint: string
  --allow-hosts-regexp: string
  --allow-hosts-regexp-type-hint: string
  --filter-methods: string
  --filter-methods-type-hint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allow.empty" $allow_empty "scalar") (serialize-qp "allow.empty@TypeHint" $allow_empty_type_hint "scalar") (serialize-qp "allow.hosts" $allow_hosts "scalar") (serialize-qp "allow.hosts@TypeHint" $allow_hosts_type_hint "scalar") (serialize-qp "allow.hosts.regexp" $allow_hosts_regexp "scalar") (serialize-qp "allow.hosts.regexp@TypeHint" $allow_hosts_regexp_type_hint "scalar") (serialize-qp "filter.methods" $filter_methods "scalar") (serialize-qp "filter.methods@TypeHint" $filter_methods_type_hint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/org.apache.sling.security.impl.ReferrerFilter" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/org.apache.sling.servlets.get.DefaultGetServlet
#
# operationId: postConfigApacheSlingGetServlet
export def "apps-system-config-orgapacheslingservletsget-default-get-servlet create-config-apache-sling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --json-maximumresults: string
  --json-maximumresults-type-hint: string
  --enable-html: oneof<nothing, bool>
  --enable-html-type-hint: string
  --enable-txt: oneof<nothing, bool>
  --enable-txt-type-hint: string
  --enable-xml: oneof<nothing, bool>
  --enable-xml-type-hint: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "json.maximumresults" $json_maximumresults "scalar") (serialize-qp "json.maximumresults@TypeHint" $json_maximumresults_type_hint "scalar") (serialize-qp "enable.html" $enable_html "scalar") (serialize-qp "enable.html@TypeHint" $enable_html_type_hint "scalar") (serialize-qp "enable.txt" $enable_txt "scalar") (serialize-qp "enable.txt@TypeHint" $enable_txt_type_hint "scalar") (serialize-qp "enable.xml" $enable_xml "scalar") (serialize-qp "enable.xml@TypeHint" $enable_xml_type_hint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/system/config/org.apache.sling.servlets.get.DefaultGetServlet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /apps/system/config/{configNodeName}
#
# operationId: postConfigProperty
export def "apps-system-config create-config-property" [
  config_node_name: string
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
  let full_url = (build-url $base ({config_node_name: $config_node_name} | format pattern "/apps/system/config/{config_node_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /bin/querybuilder.json
#
# operationId: getQuery
export def "bin-querybuilderjson get-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string
  --p-limit: float
  --1-property: string
  --1-property-value: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "p.limit" $p_limit "scalar") (serialize-qp "1_property" $1_property "scalar") (serialize-qp "1_property.value" $1_property_value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bin/querybuilder.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /bin/querybuilder.json
#
# operationId: postQuery
export def "bin-querybuilderjson create-query" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string
  --p-limit: float
  --1-property: string
  --1-property-value: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "p.limit" $p_limit "scalar") (serialize-qp "1_property" $1_property "scalar") (serialize-qp "1_property.value" $1_property_value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bin/querybuilder.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /crx/explorer/ui/setpassword.jsp
#
# operationId: postSetPassword
export def "crx-explorer-ui-setpasswordjsp create-set-password" [
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
export def "crx-packmgr-installstatusjsp get-install-status" [
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
export def "crx-packmgr-servicejsp create-package-service" [
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
export def "crx-packmgr-service-json create-package" [
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
  --group-name: string
  --package-name: string
  --package-version: string
  --charset: string
  --force: oneof<nothing, bool>
  --recursive: oneof<nothing, bool>
  --package: string # format: binary
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cmd" $cmd "scalar") (serialize-qp "groupName" $group_name "scalar") (serialize-qp "packageName" $package_name "scalar") (serialize-qp "packageVersion" $package_version "scalar") (serialize-qp "_charset_" $charset "scalar") (serialize-qp "force" $force "scalar") (serialize-qp "recursive" $recursive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: $path} | format pattern "/crx/packmgr/service/.json/{path}") $qp)
  let body = {"package": $package} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# GET /crx/packmgr/service/script.html
#
# operationId: getPackageManagerServlet
export def "crx-packmgr-service-scripthtml get-package-manager-servlet" [
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
export def "crx-packmgr-updatejsp create-package-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-name: string
  --package-name: string
  --version: string
  --path: string
  --filter: string
  --charset: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupName" $group_name "scalar") (serialize-qp "packageName" $package_name "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "_charset_" $charset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/crx/packmgr/update.jsp" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /crx/server/crx.default/jcr:root/.1.json
#
# operationId: getCrxdeStatus
export def "crx-server-crxdefault-jcr-root-1json get-crxde-status" [
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
  let full_url = (build-url $base ({group: $group, name: $name, version: $version} | format pattern "/etc/packages/{group}/{name}-{version}.zip"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /etc/packages/{group}/{name}-{version}.zip/jcr:content/vlt:definition/filter.tidy.2.json
#
# operationId: getPackageFilter
export def "etc-packages-jcr-content-vlt-definition-filtertidy2json get-package-filter" [
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
  let full_url = (build-url $base ({group: $group, name: $name, version: $version} | format pattern "/etc/packages/{group}/{name}-{version}.zip/jcr:content/vlt:definition/filter.tidy.2.json"))
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
  let full_url = (build-url $base ({runmode: $runmode} | format pattern "/etc/replication/agents.{runmode}.-1.json"))
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
  let full_url = (build-url $base ({runmode: $runmode, name: $name} | format pattern "/etc/replication/agents.{runmode}/{name}"))
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
  let full_url = (build-url $base ({runmode: $runmode, name: $name} | format pattern "/etc/replication/agents.{runmode}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /etc/replication/agents.{runmode}/{name}
#
# operationId: postAgent
export def "etc-replication-agents-runmode create" [
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
  --jcr-content-cq-distribute: oneof<nothing, bool>
  --jcr-content-cq-distribute-type-hint: string
  --jcr-content-cq-name: string
  --jcr-content-cq-template: string
  --jcr-content-enabled: oneof<nothing, bool>
  --jcr-content-jcr-description: string
  --jcr-content-jcr-last-modified: string
  --jcr-content-jcr-last-modified-by: string
  --jcr-content-jcr-mixin-types: string
  --jcr-content-jcr-title: string
  --jcr-content-log-level: string
  --jcr-content-no-status-update: oneof<nothing, bool>
  --jcr-content-no-versioning: oneof<nothing, bool>
  --jcr-content-protocol-connect-timeout: float
  --jcr-content-protocol-http-connection-closed: oneof<nothing, bool>
  --jcr-content-protocol-http-expired: string
  --jcr-content-protocol-http-headers: list
  --jcr-content-protocol-http-headers-type-hint: string
  --jcr-content-protocol-http-method: string
  --jcr-content-protocol-https-relaxed: oneof<nothing, bool>
  --jcr-content-protocol-interface: string
  --jcr-content-protocol-socket-timeout: float
  --jcr-content-protocol-version: string
  --jcr-content-proxy-ntlm-domain: string
  --jcr-content-proxy-ntlm-host: string
  --jcr-content-proxy-host: string
  --jcr-content-proxy-password: string
  --jcr-content-proxy-port: float
  --jcr-content-proxy-user: string
  --jcr-content-queue-batch-max-size: float
  --jcr-content-queue-batch-mode: string
  --jcr-content-queue-batch-wait-time: float
  --jcr-content-retry-delay: string
  --jcr-content-reverse-replication: oneof<nothing, bool>
  --jcr-content-serialization-type: string
  --jcr-content-sling-resource-type: string
  --jcr-content-ssl: string
  --jcr-content-transport-ntlm-domain: string
  --jcr-content-transport-ntlm-host: string
  --jcr-content-transport-password: string
  --jcr-content-transport-uri: string
  --jcr-content-transport-user: string
  --jcr-content-trigger-distribute: oneof<nothing, bool>
  --jcr-content-trigger-modified: oneof<nothing, bool>
  --jcr-content-trigger-on-off-time: oneof<nothing, bool>
  --jcr-content-trigger-receive: oneof<nothing, bool>
  --jcr-content-trigger-specific: oneof<nothing, bool>
  --jcr-content-user-id: string
  --jcr-primary-type: string
  --operation: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jcr:content/cq:distribute" $jcr_content_cq_distribute "scalar") (serialize-qp "jcr:content/cq:distribute@TypeHint" $jcr_content_cq_distribute_type_hint "scalar") (serialize-qp "jcr:content/cq:name" $jcr_content_cq_name "scalar") (serialize-qp "jcr:content/cq:template" $jcr_content_cq_template "scalar") (serialize-qp "jcr:content/enabled" $jcr_content_enabled "scalar") (serialize-qp "jcr:content/jcr:description" $jcr_content_jcr_description "scalar") (serialize-qp "jcr:content/jcr:lastModified" $jcr_content_jcr_last_modified "scalar") (serialize-qp "jcr:content/jcr:lastModifiedBy" $jcr_content_jcr_last_modified_by "scalar") (serialize-qp "jcr:content/jcr:mixinTypes" $jcr_content_jcr_mixin_types "scalar") (serialize-qp "jcr:content/jcr:title" $jcr_content_jcr_title "scalar") (serialize-qp "jcr:content/logLevel" $jcr_content_log_level "scalar") (serialize-qp "jcr:content/noStatusUpdate" $jcr_content_no_status_update "scalar") (serialize-qp "jcr:content/noVersioning" $jcr_content_no_versioning "scalar") (serialize-qp "jcr:content/protocolConnectTimeout" $jcr_content_protocol_connect_timeout "scalar") (serialize-qp "jcr:content/protocolHTTPConnectionClosed" $jcr_content_protocol_http_connection_closed "scalar") (serialize-qp "jcr:content/protocolHTTPExpired" $jcr_content_protocol_http_expired "scalar") (serialize-qp "jcr:content/protocolHTTPHeaders" $jcr_content_protocol_http_headers "multi") (serialize-qp "jcr:content/protocolHTTPHeaders@TypeHint" $jcr_content_protocol_http_headers_type_hint "scalar") (serialize-qp "jcr:content/protocolHTTPMethod" $jcr_content_protocol_http_method "scalar") (serialize-qp "jcr:content/protocolHTTPSRelaxed" $jcr_content_protocol_https_relaxed "scalar") (serialize-qp "jcr:content/protocolInterface" $jcr_content_protocol_interface "scalar") (serialize-qp "jcr:content/protocolSocketTimeout" $jcr_content_protocol_socket_timeout "scalar") (serialize-qp "jcr:content/protocolVersion" $jcr_content_protocol_version "scalar") (serialize-qp "jcr:content/proxyNTLMDomain" $jcr_content_proxy_ntlm_domain "scalar") (serialize-qp "jcr:content/proxyNTLMHost" $jcr_content_proxy_ntlm_host "scalar") (serialize-qp "jcr:content/proxyHost" $jcr_content_proxy_host "scalar") (serialize-qp "jcr:content/proxyPassword" $jcr_content_proxy_password "scalar") (serialize-qp "jcr:content/proxyPort" $jcr_content_proxy_port "scalar") (serialize-qp "jcr:content/proxyUser" $jcr_content_proxy_user "scalar") (serialize-qp "jcr:content/queueBatchMaxSize" $jcr_content_queue_batch_max_size "scalar") (serialize-qp "jcr:content/queueBatchMode" $jcr_content_queue_batch_mode "scalar") (serialize-qp "jcr:content/queueBatchWaitTime" $jcr_content_queue_batch_wait_time "scalar") (serialize-qp "jcr:content/retryDelay" $jcr_content_retry_delay "scalar") (serialize-qp "jcr:content/reverseReplication" $jcr_content_reverse_replication "scalar") (serialize-qp "jcr:content/serializationType" $jcr_content_serialization_type "scalar") (serialize-qp "jcr:content/sling:resourceType" $jcr_content_sling_resource_type "scalar") (serialize-qp "jcr:content/ssl" $jcr_content_ssl "scalar") (serialize-qp "jcr:content/transportNTLMDomain" $jcr_content_transport_ntlm_domain "scalar") (serialize-qp "jcr:content/transportNTLMHost" $jcr_content_transport_ntlm_host "scalar") (serialize-qp "jcr:content/transportPassword" $jcr_content_transport_password "scalar") (serialize-qp "jcr:content/transportUri" $jcr_content_transport_uri "scalar") (serialize-qp "jcr:content/transportUser" $jcr_content_transport_user "scalar") (serialize-qp "jcr:content/triggerDistribute" $jcr_content_trigger_distribute "scalar") (serialize-qp "jcr:content/triggerModified" $jcr_content_trigger_modified "scalar") (serialize-qp "jcr:content/triggerOnOffTime" $jcr_content_trigger_on_off_time "scalar") (serialize-qp "jcr:content/triggerReceive" $jcr_content_trigger_receive "scalar") (serialize-qp "jcr:content/triggerSpecific" $jcr_content_trigger_specific "scalar") (serialize-qp "jcr:content/userId" $jcr_content_user_id "scalar") (serialize-qp "jcr:primaryType" $jcr_primary_type "scalar") (serialize-qp ":operation" $operation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({runmode: $runmode, name: $name} | format pattern "/etc/replication/agents.{runmode}/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /etc/truststore
#
# operationId: postTruststorePKCS12
export def "etc-truststore create-truststore-pkcs12" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --truststore-p12: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/etc/truststore")
  let body = {"truststore.p12": $truststore_p12} | compact
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
export def "libs-granite-core-content-loginhtml get-login-page" [
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
export def "libs-granite-security-post-authorizables create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorizable-id: string
  --intermediate-path: string
  --create-user: string
  --create-group: string
  --rep-password: string
  --profile-given-name: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "authorizableId" $authorizable_id "scalar") (serialize-qp "intermediatePath" $intermediate_path "scalar") (serialize-qp "createUser" $create_user "scalar") (serialize-qp "createGroup" $create_group "scalar") (serialize-qp "rep:password" $rep_password "scalar") (serialize-qp "profile/givenName" $profile_given_name "scalar")] | flatten | str join "&"
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
  --keystore-password: string
  --keystore-password-confirm: string
  --truststore-password: string
  --truststore-password-confirm: string
  --https-hostname: string
  --https-port: string
  --certificate-file: string # format: binary
  --privatekey-file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keystorePassword" $keystore_password "scalar") (serialize-qp "keystorePasswordConfirm" $keystore_password_confirm "scalar") (serialize-qp "truststorePassword" $truststore_password "scalar") (serialize-qp "truststorePasswordConfirm" $truststore_password_confirm "scalar") (serialize-qp "httpsHostname" $https_hostname "scalar") (serialize-qp "httpsPort" $https_port "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libs/granite/security/post/sslSetup.html" $qp)
  let body = {"certificateFile": $certificate_file, "privatekeyFile": $privatekey_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# POST /libs/granite/security/post/truststore
#
# operationId: postTruststore
export def "libs-granite-security-post-truststore create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string
  --new-password: string
  --re-password: string
  --key-store-type: string
  --remove-alias: string
  --certificate: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp ":operation" $operation "scalar") (serialize-qp "newPassword" $new_password "scalar") (serialize-qp "rePassword" $re_password "scalar") (serialize-qp "keyStoreType" $key_store_type "scalar") (serialize-qp "removeAlias" $remove_alias "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/libs/granite/security/post/truststore" $qp)
  let body = {"certificate": $certificate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# GET /libs/granite/security/truststore.json
#
# operationId: getTruststoreInfo
export def "libs-granite-security-truststorejson get-truststore-info" [
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
export def "libs-replication-treeactivationhtml create-tree-activation" [
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
export def "system-console-bundles create" [
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
  let full_url = (build-url $base ({name: $name} | format pattern "/system/console/bundles/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /system/console/bundles/{name}.json
#
# operationId: getBundleInfo
export def "system-console-bundles get-bundle-info" [
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
  let full_url = (build-url $base ({name: $name} | format pattern "/system/console/bundles/{name}.json"))
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
export def "system-console-config-mgr-comadobegraniteauthsaml-saml-authentication-handler create-saml-configuration" [
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
  --service-ranking: int
  --idp-url: string
  --idp-cert-alias: string
  --idp-http-redirect: oneof<nothing, bool>
  --service-provider-entity-id: string
  --assertion-consumer-service-url: string
  --sp-private-key-alias: string
  --key-store-password: string
  --default-redirect-url: string
  --user-id-attribute: string
  --use-encryption: oneof<nothing, bool>
  --create-user: oneof<nothing, bool>
  --add-group-memberships: oneof<nothing, bool>
  --group-membership-attribute: string
  --default-groups: list
  --name-id-format: string
  --synchronize-attributes: list
  --handle-logout: oneof<nothing, bool>
  --logout-url: string
  --clock-tolerance: int
  --digest-method: string
  --signature-method: string
  --user-intermediate-path: string
  --propertylist: list
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "post" $post "scalar") (serialize-qp "apply" $apply "scalar") (serialize-qp "delete" $delete "scalar") (serialize-qp "action" $action "scalar") (serialize-qp "$location" $location "scalar") (serialize-qp "path" $path "multi") (serialize-qp "service.ranking" $service_ranking "scalar") (serialize-qp "idpUrl" $idp_url "scalar") (serialize-qp "idpCertAlias" $idp_cert_alias "scalar") (serialize-qp "idpHttpRedirect" $idp_http_redirect "scalar") (serialize-qp "serviceProviderEntityId" $service_provider_entity_id "scalar") (serialize-qp "assertionConsumerServiceURL" $assertion_consumer_service_url "scalar") (serialize-qp "spPrivateKeyAlias" $sp_private_key_alias "scalar") (serialize-qp "keyStorePassword" $key_store_password "scalar") (serialize-qp "defaultRedirectUrl" $default_redirect_url "scalar") (serialize-qp "userIDAttribute" $user_id_attribute "scalar") (serialize-qp "useEncryption" $use_encryption "scalar") (serialize-qp "createUser" $create_user "scalar") (serialize-qp "addGroupMemberships" $add_group_memberships "scalar") (serialize-qp "groupMembershipAttribute" $group_membership_attribute "scalar") (serialize-qp "defaultGroups" $default_groups "multi") (serialize-qp "nameIdFormat" $name_id_format "scalar") (serialize-qp "synchronizeAttributes" $synchronize_attributes "multi") (serialize-qp "handleLogout" $handle_logout "scalar") (serialize-qp "logoutUrl" $logout_url "scalar") (serialize-qp "clockTolerance" $clock_tolerance "scalar") (serialize-qp "digestMethod" $digest_method "scalar") (serialize-qp "signatureMethod" $signature_method "scalar") (serialize-qp "userIntermediatePath" $user_intermediate_path "scalar") (serialize-qp "propertylist" $propertylist "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/system/console/configMgr/com.adobe.granite.auth.saml.SamlAuthenticationHandler" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /system/console/jmx/com.adobe.granite:type=Repository/op/{action}
#
# operationId: postJmxRepository
export def "system-console-jmx-comadobegranite-type-repository-op create" [
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
  let full_url = (build-url $base ({action: $action} | format pattern "/system/console/jmx/com.adobe.granite:type=Repository/op/{action}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /system/console/status-productinfo.json
#
# operationId: getAemProductInfo
export def "system-console-status-productinfojson get-aem-product-info" [
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
export def "system-health get-aem-health-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tags: string
  --combine-tags-or: oneof<nothing, bool>
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tags" $tags "scalar") (serialize-qp "combineTagsOr" $combine_tags_or "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/system/health" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{intermediatePath}/{authorizableId}.ks.html
#
# operationId: postAuthorizableKeystore
export def "sling create-authorizable-keystore" [
  intermediate_path: string
  authorizable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --operation: string
  --current-password: string
  --new-password: string
  --re-password: string
  --key-password: string
  --key-store-pass: string
  --alias: string
  --new-alias: string
  --remove-alias: string
  --cert-chain: string # format: binary
  --key-store: string # format: binary
  --pk: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp ":operation" $operation "scalar") (serialize-qp "currentPassword" $current_password "scalar") (serialize-qp "newPassword" $new_password "scalar") (serialize-qp "rePassword" $re_password "scalar") (serialize-qp "keyPassword" $key_password "scalar") (serialize-qp "keyStorePass" $key_store_pass "scalar") (serialize-qp "alias" $alias "scalar") (serialize-qp "newAlias" $new_alias "scalar") (serialize-qp "removeAlias" $remove_alias "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({intermediate_path: $intermediate_path, authorizable_id: $authorizable_id} | format pattern "/{intermediate_path}/{authorizable_id}.ks.html") $qp)
  let body = {"cert-chain": $cert_chain, "keyStore": $key_store, "pk": $pk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# GET /{intermediatePath}/{authorizableId}.ks.json
#
# operationId: getAuthorizableKeystore
export def "sling get-authorizable-keystore" [
  intermediate_path: string
  authorizable_id: string
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
  let full_url = (build-url $base ({intermediate_path: $intermediate_path, authorizable_id: $authorizable_id} | format pattern "/{intermediate_path}/{authorizable_id}.ks.json"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /{intermediatePath}/{authorizableId}/keystore/store.p12
#
# operationId: getKeystore
export def "keystore-storep12 get" [
  intermediate_path: string
  authorizable_id: string
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
  let full_url = (build-url $base ({intermediate_path: $intermediate_path, authorizable_id: $authorizable_id} | format pattern "/{intermediate_path}/{authorizable_id}/keystore/store.p12"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{path}/
#
# operationId: postPath
export def "sling create" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --jcr-primary-type: string
  --name: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jcr:primaryType" $jcr_primary_type "scalar") (serialize-qp ":name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: $path} | format pattern "/{path}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /{path}/{name}
#
# operationId: deleteNode
export def "sling delete-node" [
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
  let full_url = (build-url $base ({path: $path, name: $name} | format pattern "/{path}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /{path}/{name}
#
# operationId: getNode
export def "sling get-node" [
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
  let full_url = (build-url $base ({path: $path, name: $name} | format pattern "/{path}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{path}/{name}
#
# operationId: postNode
export def "sling create-node" [
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
  --operation: string
  --delete-authorizable: string
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp ":operation" $operation "scalar") (serialize-qp "deleteAuthorizable" $delete_authorizable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: $path, name: $name} | format pattern "/{path}/{name}") $qp)
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# POST /{path}/{name}.rw.html
#
# operationId: postNodeRw
export def "sling create-node-rw" [
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
  --add-members: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "addMembers" $add_members "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({path: $path, name: $name} | format pattern "/{path}/{name}.rw.html") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
