# Auto-generated client for AWS Service Catalog v2015-12-10
# Source: https://api.apis.guru/v2/specs/amazonaws.com/servicecatalog/2015-12-10/openapi.json
# Auth: --token flag or $env.AWS_SERVICE_CATALOG_TOKEN

const BASE_URL = "http://servicecatalog.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AWS_SERVICE_CATALOG_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://servicecatalog.us-east-1.amazonaws.com" "http://servicecatalog.us-east-2.amazonaws.com" "http://servicecatalog.us-west-1.amazonaws.com" "http://servicecatalog.us-west-2.amazonaws.com" "http://servicecatalog.us-gov-west-1.amazonaws.com" "http://servicecatalog.us-gov-east-1.amazonaws.com" "http://servicecatalog.ca-central-1.amazonaws.com" "http://servicecatalog.eu-north-1.amazonaws.com" "http://servicecatalog.eu-west-1.amazonaws.com" "http://servicecatalog.eu-west-2.amazonaws.com" "http://servicecatalog.eu-west-3.amazonaws.com" "http://servicecatalog.eu-central-1.amazonaws.com" "http://servicecatalog.eu-south-1.amazonaws.com" "http://servicecatalog.af-south-1.amazonaws.com" "http://servicecatalog.ap-northeast-1.amazonaws.com" "http://servicecatalog.ap-northeast-2.amazonaws.com" "http://servicecatalog.ap-northeast-3.amazonaws.com" "http://servicecatalog.ap-southeast-1.amazonaws.com" "http://servicecatalog.ap-southeast-2.amazonaws.com" "http://servicecatalog.ap-east-1.amazonaws.com" "http://servicecatalog.ap-south-1.amazonaws.com" "http://servicecatalog.sa-east-1.amazonaws.com" "http://servicecatalog.me-south-1.amazonaws.com" "https://servicecatalog.us-east-1.amazonaws.com" "https://servicecatalog.us-east-2.amazonaws.com" "https://servicecatalog.us-west-1.amazonaws.com" "https://servicecatalog.us-west-2.amazonaws.com" "https://servicecatalog.us-gov-west-1.amazonaws.com" "https://servicecatalog.us-gov-east-1.amazonaws.com" "https://servicecatalog.ca-central-1.amazonaws.com" "https://servicecatalog.eu-north-1.amazonaws.com" "https://servicecatalog.eu-west-1.amazonaws.com" "https://servicecatalog.eu-west-2.amazonaws.com" "https://servicecatalog.eu-west-3.amazonaws.com" "https://servicecatalog.eu-central-1.amazonaws.com" "https://servicecatalog.eu-south-1.amazonaws.com" "https://servicecatalog.af-south-1.amazonaws.com" "https://servicecatalog.ap-northeast-1.amazonaws.com" "https://servicecatalog.ap-northeast-2.amazonaws.com" "https://servicecatalog.ap-northeast-3.amazonaws.com" "https://servicecatalog.ap-southeast-1.amazonaws.com" "https://servicecatalog.ap-southeast-2.amazonaws.com" "https://servicecatalog.ap-east-1.amazonaws.com" "https://servicecatalog.ap-south-1.amazonaws.com" "https://servicecatalog.sa-east-1.amazonaws.com" "https://servicecatalog.me-south-1.amazonaws.com" "http://servicecatalog.cn-north-1.amazonaws.com.cn" "http://servicecatalog.cn-northwest-1.amazonaws.com.cn" "https://servicecatalog.cn-north-1.amazonaws.com.cn" "https://servicecatalog.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWS242ServiceCatalogService.AcceptPortfolioShare"] }
def x-amz-target-completer-1 [] { ["AWS242ServiceCatalogService.AssociateBudgetWithResource"] }
def x-amz-target-completer-2 [] { ["AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio"] }
def x-amz-target-completer-3 [] { ["AWS242ServiceCatalogService.AssociateProductWithPortfolio"] }
def x-amz-target-completer-4 [] { ["AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact"] }
def x-amz-target-completer-5 [] { ["AWS242ServiceCatalogService.AssociateTagOptionWithResource"] }
def x-amz-target-completer-6 [] { ["AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact"] }
def x-amz-target-completer-7 [] { ["AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact"] }
def x-amz-target-completer-8 [] { ["AWS242ServiceCatalogService.CopyProduct"] }
def x-amz-target-completer-9 [] { ["AWS242ServiceCatalogService.CreateConstraint"] }
def x-amz-target-completer-10 [] { ["AWS242ServiceCatalogService.CreatePortfolio"] }
def x-amz-target-completer-11 [] { ["AWS242ServiceCatalogService.CreatePortfolioShare"] }
def x-amz-target-completer-12 [] { ["AWS242ServiceCatalogService.CreateProduct"] }
def x-amz-target-completer-13 [] { ["AWS242ServiceCatalogService.CreateProvisionedProductPlan"] }
def x-amz-target-completer-14 [] { ["AWS242ServiceCatalogService.CreateProvisioningArtifact"] }
def x-amz-target-completer-15 [] { ["AWS242ServiceCatalogService.CreateServiceAction"] }
def x-amz-target-completer-16 [] { ["AWS242ServiceCatalogService.CreateTagOption"] }
def x-amz-target-completer-17 [] { ["AWS242ServiceCatalogService.DeleteConstraint"] }
def x-amz-target-completer-18 [] { ["AWS242ServiceCatalogService.DeletePortfolio"] }
def x-amz-target-completer-19 [] { ["AWS242ServiceCatalogService.DeletePortfolioShare"] }
def x-amz-target-completer-20 [] { ["AWS242ServiceCatalogService.DeleteProduct"] }
def x-amz-target-completer-21 [] { ["AWS242ServiceCatalogService.DeleteProvisionedProductPlan"] }
def x-amz-target-completer-22 [] { ["AWS242ServiceCatalogService.DeleteProvisioningArtifact"] }
def x-amz-target-completer-23 [] { ["AWS242ServiceCatalogService.DeleteServiceAction"] }
def x-amz-target-completer-24 [] { ["AWS242ServiceCatalogService.DeleteTagOption"] }
def x-amz-target-completer-25 [] { ["AWS242ServiceCatalogService.DescribeConstraint"] }
def x-amz-target-completer-26 [] { ["AWS242ServiceCatalogService.DescribeCopyProductStatus"] }
def x-amz-target-completer-27 [] { ["AWS242ServiceCatalogService.DescribePortfolio"] }
def x-amz-target-completer-28 [] { ["AWS242ServiceCatalogService.DescribePortfolioShareStatus"] }
def x-amz-target-completer-29 [] { ["AWS242ServiceCatalogService.DescribePortfolioShares"] }
def x-amz-target-completer-30 [] { ["AWS242ServiceCatalogService.DescribeProduct"] }
def x-amz-target-completer-31 [] { ["AWS242ServiceCatalogService.DescribeProductAsAdmin"] }
def x-amz-target-completer-32 [] { ["AWS242ServiceCatalogService.DescribeProductView"] }
def x-amz-target-completer-33 [] { ["AWS242ServiceCatalogService.DescribeProvisionedProduct"] }
def x-amz-target-completer-34 [] { ["AWS242ServiceCatalogService.DescribeProvisionedProductPlan"] }
def x-amz-target-completer-35 [] { ["AWS242ServiceCatalogService.DescribeProvisioningArtifact"] }
def x-amz-target-completer-36 [] { ["AWS242ServiceCatalogService.DescribeProvisioningParameters"] }
def x-amz-target-completer-37 [] { ["AWS242ServiceCatalogService.DescribeRecord"] }
def x-amz-target-completer-38 [] { ["AWS242ServiceCatalogService.DescribeServiceAction"] }
def x-amz-target-completer-39 [] { ["AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters"] }
def x-amz-target-completer-40 [] { ["AWS242ServiceCatalogService.DescribeTagOption"] }
def x-amz-target-completer-41 [] { ["AWS242ServiceCatalogService.DisableAWSOrganizationsAccess"] }
def x-amz-target-completer-42 [] { ["AWS242ServiceCatalogService.DisassociateBudgetFromResource"] }
def x-amz-target-completer-43 [] { ["AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio"] }
def x-amz-target-completer-44 [] { ["AWS242ServiceCatalogService.DisassociateProductFromPortfolio"] }
def x-amz-target-completer-45 [] { ["AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact"] }
def x-amz-target-completer-46 [] { ["AWS242ServiceCatalogService.DisassociateTagOptionFromResource"] }
def x-amz-target-completer-47 [] { ["AWS242ServiceCatalogService.EnableAWSOrganizationsAccess"] }
def x-amz-target-completer-48 [] { ["AWS242ServiceCatalogService.ExecuteProvisionedProductPlan"] }
def x-amz-target-completer-49 [] { ["AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction"] }
def x-amz-target-completer-50 [] { ["AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus"] }
def x-amz-target-completer-51 [] { ["AWS242ServiceCatalogService.GetProvisionedProductOutputs"] }
def x-amz-target-completer-52 [] { ["AWS242ServiceCatalogService.ImportAsProvisionedProduct"] }
def x-amz-target-completer-53 [] { ["AWS242ServiceCatalogService.ListAcceptedPortfolioShares"] }
def x-amz-target-completer-54 [] { ["AWS242ServiceCatalogService.ListBudgetsForResource"] }
def x-amz-target-completer-55 [] { ["AWS242ServiceCatalogService.ListConstraintsForPortfolio"] }
def x-amz-target-completer-56 [] { ["AWS242ServiceCatalogService.ListLaunchPaths"] }
def x-amz-target-completer-57 [] { ["AWS242ServiceCatalogService.ListOrganizationPortfolioAccess"] }
def x-amz-target-completer-58 [] { ["AWS242ServiceCatalogService.ListPortfolioAccess"] }
def x-amz-target-completer-59 [] { ["AWS242ServiceCatalogService.ListPortfolios"] }
def x-amz-target-completer-60 [] { ["AWS242ServiceCatalogService.ListPortfoliosForProduct"] }
def x-amz-target-completer-61 [] { ["AWS242ServiceCatalogService.ListPrincipalsForPortfolio"] }
def x-amz-target-completer-62 [] { ["AWS242ServiceCatalogService.ListProvisionedProductPlans"] }
def x-amz-target-completer-63 [] { ["AWS242ServiceCatalogService.ListProvisioningArtifacts"] }
def x-amz-target-completer-64 [] { ["AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction"] }
def x-amz-target-completer-65 [] { ["AWS242ServiceCatalogService.ListRecordHistory"] }
def x-amz-target-completer-66 [] { ["AWS242ServiceCatalogService.ListResourcesForTagOption"] }
def x-amz-target-completer-67 [] { ["AWS242ServiceCatalogService.ListServiceActions"] }
def x-amz-target-completer-68 [] { ["AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact"] }
def x-amz-target-completer-69 [] { ["AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct"] }
def x-amz-target-completer-70 [] { ["AWS242ServiceCatalogService.ListTagOptions"] }
def x-amz-target-completer-71 [] { ["AWS242ServiceCatalogService.NotifyProvisionProductEngineWorkflowResult"] }
def x-amz-target-completer-72 [] { ["AWS242ServiceCatalogService.NotifyTerminateProvisionedProductEngineWorkflowResult"] }
def x-amz-target-completer-73 [] { ["AWS242ServiceCatalogService.NotifyUpdateProvisionedProductEngineWorkflowResult"] }
def x-amz-target-completer-74 [] { ["AWS242ServiceCatalogService.ProvisionProduct"] }
def x-amz-target-completer-75 [] { ["AWS242ServiceCatalogService.RejectPortfolioShare"] }
def x-amz-target-completer-76 [] { ["AWS242ServiceCatalogService.ScanProvisionedProducts"] }
def x-amz-target-completer-77 [] { ["AWS242ServiceCatalogService.SearchProducts"] }
def x-amz-target-completer-78 [] { ["AWS242ServiceCatalogService.SearchProductsAsAdmin"] }
def x-amz-target-completer-79 [] { ["AWS242ServiceCatalogService.SearchProvisionedProducts"] }
def x-amz-target-completer-80 [] { ["AWS242ServiceCatalogService.TerminateProvisionedProduct"] }
def x-amz-target-completer-81 [] { ["AWS242ServiceCatalogService.UpdateConstraint"] }
def x-amz-target-completer-82 [] { ["AWS242ServiceCatalogService.UpdatePortfolio"] }
def x-amz-target-completer-83 [] { ["AWS242ServiceCatalogService.UpdatePortfolioShare"] }
def x-amz-target-completer-84 [] { ["AWS242ServiceCatalogService.UpdateProduct"] }
def x-amz-target-completer-85 [] { ["AWS242ServiceCatalogService.UpdateProvisionedProduct"] }
def x-amz-target-completer-86 [] { ["AWS242ServiceCatalogService.UpdateProvisionedProductProperties"] }
def x-amz-target-completer-87 [] { ["AWS242ServiceCatalogService.UpdateProvisioningArtifact"] }
def x-amz-target-completer-88 [] { ["AWS242ServiceCatalogService.UpdateServiceAction"] }
def x-amz-target-completer-89 [] { ["AWS242ServiceCatalogService.UpdateTagOption"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-aws242-service-catalog-service-accept-portfolio-share create" } } | get name | first)
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

# Accepts an offer to share the specified portfolio.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.AcceptPortfolioShare
# operationId: AcceptPortfolioShare
export def "x-amz-target-aws242-service-catalog-service-accept-portfolio-share create" [
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
  --x-amz-target: string@x-amz-target-completer
  --accept-language: any
  portfolio_id: any
  --portfolio-share-type: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.AcceptPortfolioShare")
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "PortfolioShareType": $portfolio_share_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Associates the specified budget with the specified resource.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.AssociateBudgetWithResource
# operationId: AssociateBudgetWithResource
export def "x-amz-target-aws242-service-catalog-service-associate-budget-with-resource create" [
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
  --x-amz-target: string@x-amz-target-completer-1
  budget_name: any
  resource_id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateBudgetWithResource")
  let req_body = {"BudgetName": $budget_name, "ResourceId": $resource_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Associates the specified principal ARN with the specified portfolio. If you share the portfolio with principal name sharing enabled, the PrincipalARN association is included in the share. The PortfolioID, PrincipalARN, and PrincipalType parameters are required. You can associate a maximum of 10 Principals with a portfolio using PrincipalType as IAM_PATTERN When you associate a principal with portfolio, a potential privilege escalation path may occur when that portfolio is then shared with other accounts. For a user in a recipient account who is not an Service Catalog Admin, but still has the ability to create Principals (Users/Groups/Roles), that user could create a role that matches a principal name association for the portfolio. Although this user may not know which principal names are associated through Service Catalog, they may be able to guess the user. If this potential escalation path is a concern, then Service Catalog recommends using PrincipalType as IAM. With this configuration, the PrincipalARN must already exist in the recipient account before it can be associated.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio
# operationId: AssociatePrincipalWithPortfolio
export def "x-amz-target-aws242-service-catalog-service-associate-principal-with-portfolio create" [
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
  --x-amz-target: string@x-amz-target-completer-2
  --accept-language: any
  portfolio_id: any
  principal_arn: any
  principal_type: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio")
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "PrincipalARN": $principal_arn, "PrincipalType": $principal_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Associates the specified product with the specified portfolio. A delegated admin is authorized to invoke this command.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.AssociateProductWithPortfolio
# operationId: AssociateProductWithPortfolio
export def "x-amz-target-aws242-service-catalog-service-associate-product-with-portfolio create" [
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
  --x-amz-target: string@x-amz-target-completer-3
  --accept-language: any
  product_id: any
  portfolio_id: any
  --source-portfolio-id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateProductWithPortfolio")
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "PortfolioId": $portfolio_id, "SourcePortfolioId": $source_portfolio_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Associates a self-service action with a provisioning artifact.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact
# operationId: AssociateServiceActionWithProvisioningArtifact
export def "x-amz-target-aws242-service-catalog-service-associate-service-action-with-provisioning-artifact create" [
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
  --x-amz-target: string@x-amz-target-completer-4
  product_id: any
  provisioning_artifact_id: any
  service_action_id: any
  --accept-language: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact")
  let req_body = {"ProductId": $product_id, "ProvisioningArtifactId": $provisioning_artifact_id, "ServiceActionId": $service_action_id, "AcceptLanguage": $accept_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Associate the specified TagOption with the specified portfolio or product.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.AssociateTagOptionWithResource
# operationId: AssociateTagOptionWithResource
export def "x-amz-target-aws242-service-catalog-service-associate-tag-option-with-resource tag" [
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
  --x-amz-target: string@x-amz-target-completer-5
  resource_id: any
  tag_option_id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.AssociateTagOptionWithResource")
  let req_body = {"ResourceId": $resource_id, "TagOptionId": $tag_option_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Associates multiple self-service actions with provisioning artifacts.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact
# operationId: BatchAssociateServiceActionWithProvisioningArtifact
export def "x-amz-target-aws242-service-catalog-service-batch-associate-service-action-with-provisioning-artifact create" [
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
  --x-amz-target: string@x-amz-target-completer-6
  service_action_associations: any
  --accept-language: any
]: any -> record<FailedServiceActionAssociations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact")
  let req_body = {"ServiceActionAssociations": $service_action_associations, "AcceptLanguage": $accept_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Disassociates a batch of self-service actions from the specified provisioning artifact.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact
# operationId: BatchDisassociateServiceActionFromProvisioningArtifact
export def "x-amz-target-aws242-service-catalog-service-batch-disassociate-service-action-from-provisioning-artifact create" [
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
  --x-amz-target: string@x-amz-target-completer-7
  service_action_associations: any
  --accept-language: any
]: any -> record<FailedServiceActionAssociations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact")
  let req_body = {"ServiceActionAssociations": $service_action_associations, "AcceptLanguage": $accept_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Copies the specified source product to the specified target product or a new product. You can copy a product to the same account or another account. You can copy a product to the same Region or another Region. If you copy a product to another account, you must first share the product in a portfolio using CreatePortfolioShare. This operation is performed asynchronously. To track the progress of the operation, use DescribeCopyProductStatus.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.CopyProduct
# operationId: CopyProduct
export def "x-amz-target-aws242-service-catalog-service-copy-product copy" [
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
  --x-amz-target: string@x-amz-target-completer-8
  --accept-language: any
  source_product_arn: any
  --target-product-id: any
  --target-product-name: any
  --source-provisioning-artifact-identifiers: any
  --copy-options: any
  idempotency_token: any
]: any -> record<CopyProductToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.CopyProduct")
  let req_body = {"AcceptLanguage": $accept_language, "SourceProductArn": $source_product_arn, "TargetProductId": $target_product_id, "TargetProductName": $target_product_name, "SourceProvisioningArtifactIdentifiers": $source_provisioning_artifact_identifiers, "CopyOptions": $copy_options, "IdempotencyToken": $idempotency_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a constraint. A delegated admin is authorized to invoke this command.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.CreateConstraint
# operationId: CreateConstraint
export def "x-amz-target-aws242-service-catalog-service-create-constraint create" [
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
  --x-amz-target: string@x-amz-target-completer-9
  --accept-language: any
  portfolio_id: any
  product_id: any
  parameters: any
  type: any
  --description: any
  idempotency_token: any
]: any -> record<ConstraintDetail: record<ConstraintId: record, Type: record, Description: record, Owner: record, ProductId: record, PortfolioId: record>, ConstraintParameters: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.CreateConstraint")
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "ProductId": $product_id, "Parameters": $parameters, "Type": $type, "Description": $description, "IdempotencyToken": $idempotency_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a portfolio. A delegated admin is authorized to invoke this command.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolio
# operationId: CreatePortfolio
export def "x-amz-target-aws242-service-catalog-service-create-portfolio create" [
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
  --x-amz-target: string@x-amz-target-completer-10
  --accept-language: any
  display_name: any
  --description: any
  provider_name: any
  --tags: any
  idempotency_token: any
]: any -> record<PortfolioDetail: record<Id: record, ARN: record, DisplayName: record, Description: record, CreatedTime: record, ProviderName: record>, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolio")
  let req_body = {"AcceptLanguage": $accept_language, "DisplayName": $display_name, "Description": $description, "ProviderName": $provider_name, "Tags": $tags, "IdempotencyToken": $idempotency_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the management account of an organization or by a delegated administrator. You can share portfolios to an organization, an organizational unit, or a specific account. Note that if a delegated admin is de-registered, they can no longer create portfolio shares. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node. You can't share a shared resource, including portfolios that contain a shared product. If the portfolio share with the specified account or organization node already exists, this action will have no effect and will not return an error. To update an existing share, you must use the UpdatePortfolioShare API instead. When you associate a principal with portfolio, a potential privilege escalation path may occur when that portfolio is then shared with other accounts. For a user in a recipient account who is not an Service Catalog Admin, but still has the ability to create Principals (Users/Groups/Roles), that user could create a role that matches a principal name association for the portfolio. Although this user may not know which principal names are associated through Service Catalog, they may be able to guess the user. If this potential escalation path is a concern, then Service Catalog recommends using PrincipalType as IAM. With this configuration, the PrincipalARN must already exist in the recipient account before it can be associated.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolioShare
# operationId: CreatePortfolioShare
export def "x-amz-target-aws242-service-catalog-service-create-portfolio-share create" [
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
  --x-amz-target: string@x-amz-target-completer-11
  --accept-language: any
  portfolio_id: any
  --account-id: any
  --organization-node: any
  --share-tag-options: any
  --share-principals: any
]: any -> record<PortfolioShareToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.CreatePortfolioShare")
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "AccountId": $account_id, "OrganizationNode": $organization_node, "ShareTagOptions": $share_tag_options, "SharePrincipals": $share_principals} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a product. A delegated admin is authorized to invoke this command. The user or role that performs this operation must have the cloudformation:GetTemplate IAM policy permission. This policy permission is required when using the ImportFromPhysicalId template source in the information data section.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.CreateProduct
# operationId: CreateProduct
export def "x-amz-target-aws242-service-catalog-service-create-product create" [
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
  --x-amz-target: string@x-amz-target-completer-12
  --accept-language: any
  name: any
  owner: any
  --description: any
  --distributor: any
  --support-description: any
  --support-email: any
  --support-url: any
  product_type: any
  --tags: any
  --provisioning-artifact-parameters: any
  idempotency_token: any
  --source-connection: any
]: any -> record<ProductViewDetail: record<ProductViewSummary: record<Id: record, ProductId: record, Name: record, Owner: record, ShortDescription: record, Type: record, Distributor: record, HasDefaultPath: record, SupportEmail: record, SupportDescription: record, SupportUrl: record>, Status: record, ProductARN: record, CreatedTime: record, SourceConnection: record<Type: record, ConnectionParameters: record, LastSync: record>>, ProvisioningArtifactDetail: record<Id: record, Name: record, Description: record, Type: record, CreatedTime: record, Active: record, Guidance: record, SourceRevision: record>, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProduct")
  let req_body = {"AcceptLanguage": $accept_language, "Name": $name, "Owner": $owner, "Description": $description, "Distributor": $distributor, "SupportDescription": $support_description, "SupportEmail": $support_email, "SupportUrl": $support_url, "ProductType": $product_type, "Tags": $tags, "ProvisioningArtifactParameters": $provisioning_artifact_parameters, "IdempotencyToken": $idempotency_token, "SourceConnection": $source_connection} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed. You can create one plan for each provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILABLE or TAINTED. To view the resource changes in the change set, use DescribeProvisionedProductPlan. To create or modify the provisioned product, use ExecuteProvisionedProductPlan.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisionedProductPlan
# operationId: CreateProvisionedProductPlan
export def "x-amz-target-aws242-service-catalog-service-create-provisioned-product-plan create" [
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
  --x-amz-target: string@x-amz-target-completer-13
  --accept-language: any
  plan_name: any
  plan_type: any
  --notification-arns: any
  --path-id: any
  product_id: any
  provisioned_product_name: any
  provisioning_artifact_id: any
  --provisioning-parameters: any
  idempotency_token: any
  --tags: any
]: any -> record<PlanName: record, PlanId: record, ProvisionProductId: record, ProvisionedProductName: record, ProvisioningArtifactId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisionedProductPlan")
  let req_body = {"AcceptLanguage": $accept_language, "PlanName": $plan_name, "PlanType": $plan_type, "NotificationArns": $notification_arns, "PathId": $path_id, "ProductId": $product_id, "ProvisionedProductName": $provisioned_product_name, "ProvisioningArtifactId": $provisioning_artifact_id, "ProvisioningParameters": $provisioning_parameters, "IdempotencyToken": $idempotency_token, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a provisioning artifact (also known as a version) for the specified product. You cannot create a provisioning artifact for a product that was shared with you. The user or role that performs this operation must have the cloudformation:GetTemplate IAM policy permission. This policy permission is required when using the ImportFromPhysicalId template source in the information data section.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisioningArtifact
# operationId: CreateProvisioningArtifact
export def "x-amz-target-aws242-service-catalog-service-create-provisioning-artifact create" [
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
  --x-amz-target: string@x-amz-target-completer-14
  --accept-language: any
  product_id: any
  parameters: any
  idempotency_token: any
]: any -> record<ProvisioningArtifactDetail: record<Id: record, Name: record, Description: record, Type: record, CreatedTime: record, Active: record, Guidance: record, SourceRevision: record>, Info: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.CreateProvisioningArtifact")
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "Parameters": $parameters, "IdempotencyToken": $idempotency_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a self-service action.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.CreateServiceAction
# operationId: CreateServiceAction
export def "x-amz-target-aws242-service-catalog-service-create-service-action create" [
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
  --x-amz-target: string@x-amz-target-completer-15
  name: any
  definition_type: any
  definition: any
  --description: any
  --accept-language: any
  idempotency_token: any
]: any -> record<ServiceActionDetail: record<ServiceActionSummary: record<Id: record, Name: record, Description: record, DefinitionType: record>, Definition: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.CreateServiceAction")
  let req_body = {"Name": $name, "DefinitionType": $definition_type, "Definition": $definition, "Description": $description, "AcceptLanguage": $accept_language, "IdempotencyToken": $idempotency_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a TagOption.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.CreateTagOption
# operationId: CreateTagOption
export def "x-amz-target-aws242-service-catalog-service-create-tag-option create" [
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
  --x-amz-target: string@x-amz-target-completer-16
  key: any
  value: any
]: any -> record<TagOptionDetail: record<Key: record, Value: record, Active: record, Id: record, Owner: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.CreateTagOption")
  let req_body = {"Key": $key, "Value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the specified constraint. A delegated admin is authorized to invoke this command.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DeleteConstraint
# operationId: DeleteConstraint
export def "x-amz-target-aws242-service-catalog-service-delete-constraint delete" [
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
  --x-amz-target: string@x-amz-target-completer-17
  --accept-language: any
  id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteConstraint")
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the specified portfolio. You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts. A delegated admin is authorized to invoke this command.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolio
# operationId: DeletePortfolio
export def "x-amz-target-aws242-service-catalog-service-delete-portfolio delete" [
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
  --x-amz-target: string@x-amz-target-completer-18
  --accept-language: any
  id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolio")
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the management account of an organization or by a delegated administrator. Note that if a delegated admin is de-registered, portfolio shares created from that account are removed.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolioShare
# operationId: DeletePortfolioShare
export def "x-amz-target-aws242-service-catalog-service-delete-portfolio-share delete" [
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
  --x-amz-target: string@x-amz-target-completer-19
  --accept-language: any
  portfolio_id: any
  --account-id: any
  --organization-node: any
]: any -> record<PortfolioShareToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DeletePortfolioShare")
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "AccountId": $account_id, "OrganizationNode": $organization_node} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the specified product. You cannot delete a product if it was shared with you or is associated with a portfolio. A delegated admin is authorized to invoke this command.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DeleteProduct
# operationId: DeleteProduct
export def "x-amz-target-aws242-service-catalog-service-delete-product delete" [
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
  --x-amz-target: string@x-amz-target-completer-20
  --accept-language: any
  id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProduct")
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the specified plan.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisionedProductPlan
# operationId: DeleteProvisionedProductPlan
export def "x-amz-target-aws242-service-catalog-service-delete-provisioned-product-plan delete" [
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
  --x-amz-target: string@x-amz-target-completer-21
  --accept-language: any
  plan_id: any
  --ignore-errors: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisionedProductPlan")
  let req_body = {"AcceptLanguage": $accept_language, "PlanId": $plan_id, "IgnoreErrors": $ignore_errors} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the specified provisioning artifact (also known as a version) for the specified product. You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisioningArtifact
# operationId: DeleteProvisioningArtifact
export def "x-amz-target-aws242-service-catalog-service-delete-provisioning-artifact delete" [
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
  --x-amz-target: string@x-amz-target-completer-22
  --accept-language: any
  product_id: any
  provisioning_artifact_id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteProvisioningArtifact")
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "ProvisioningArtifactId": $provisioning_artifact_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a self-service action.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DeleteServiceAction
# operationId: DeleteServiceAction
export def "x-amz-target-aws242-service-catalog-service-delete-service-action delete" [
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
  --x-amz-target: string@x-amz-target-completer-23
  id: any
  --accept-language: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteServiceAction")
  let req_body = {"Id": $id, "AcceptLanguage": $accept_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes the specified TagOption. You cannot delete a TagOption if it is associated with a product or portfolio.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DeleteTagOption
# operationId: DeleteTagOption
export def "x-amz-target-aws242-service-catalog-service-delete-tag-option delete" [
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
  --x-amz-target: string@x-amz-target-completer-24
  id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DeleteTagOption")
  let req_body = {"Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about the specified constraint.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribeConstraint
# operationId: DescribeConstraint
export def "x-amz-target-aws242-service-catalog-service-describe-constraint get" [
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
  --x-amz-target: string@x-amz-target-completer-25
  --accept-language: any
  id: any
]: any -> record<ConstraintDetail: record<ConstraintId: record, Type: record, Description: record, Owner: record, ProductId: record, PortfolioId: record>, ConstraintParameters: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeConstraint")
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets the status of the specified copy product operation.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribeCopyProductStatus
# operationId: DescribeCopyProductStatus
export def "x-amz-target-aws242-service-catalog-service-describe-copy-product-status get" [
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
  --x-amz-target: string@x-amz-target-completer-26
  --accept-language: any
  copy_product_token: any
]: any -> record<CopyProductStatus: record, TargetProductId: record, StatusDetail: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeCopyProductStatus")
  let req_body = {"AcceptLanguage": $accept_language, "CopyProductToken": $copy_product_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about the specified portfolio. A delegated admin is authorized to invoke this command.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolio
# operationId: DescribePortfolio
export def "x-amz-target-aws242-service-catalog-service-describe-portfolio get" [
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
  --x-amz-target: string@x-amz-target-completer-27
  --accept-language: any
  id: any
]: any -> record<PortfolioDetail: record<Id: record, ARN: record, DisplayName: record, Description: record, CreatedTime: record, ProviderName: record>, Tags: record, TagOptions: record, Budgets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolio")
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets the status of the specified portfolio share operation. This API can only be called by the management account in the organization or by a delegated admin.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolioShareStatus
# operationId: DescribePortfolioShareStatus
export def "x-amz-target-aws242-service-catalog-service-describe-portfolio-share-status get" [
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
  --x-amz-target: string@x-amz-target-completer-28
  portfolio_share_token: any
]: any -> record<PortfolioShareToken: record, PortfolioId: record, OrganizationNodeValue: record, Status: record, ShareDetails: record<SuccessfulShares: record, ShareErrors: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolioShareStatus")
  let req_body = {"PortfolioShareToken": $portfolio_share_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a summary of each of the portfolio shares that were created for the specified portfolio. You can use this API to determine which accounts or organizational nodes this portfolio have been shared, whether the recipient entity has imported the share, and whether TagOptions are included with the share. The PortfolioId and Type parameters are both required.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolioShares
# operationId: DescribePortfolioShares
export def "x-amz-target-aws242-service-catalog-service-describe-portfolio-shares get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29
  portfolio_id: any
  type: any
  --page-token: any
  --page-size: any
]: any -> record<NextPageToken: record, PortfolioShareDetails: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribePortfolioShares" $qp)
  let req_body = {"PortfolioId": $portfolio_id, "Type": $type, "PageToken": $page_token, "PageSize": $page_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about the specified product. Running this operation with administrator access results in a failure. DescribeProductAsAdmin should be used instead.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribeProduct
# operationId: DescribeProduct
export def "x-amz-target-aws242-service-catalog-service-describe-product get" [
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
  --x-amz-target: string@x-amz-target-completer-30
  --accept-language: any
  --id: any
  --name: any
]: any -> record<ProductViewSummary: record<Id: record, ProductId: record, Name: record, Owner: record, ShortDescription: record, Type: record, Distributor: record, HasDefaultPath: record, SupportEmail: record, SupportDescription: record, SupportUrl: record>, ProvisioningArtifacts: record, Budgets: record, LaunchPaths: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProduct")
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about the specified product. This operation is run with administrator access.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductAsAdmin
# operationId: DescribeProductAsAdmin
export def "x-amz-target-aws242-service-catalog-service-describe-product-as-admin get" [
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
  --x-amz-target: string@x-amz-target-completer-31
  --accept-language: any
  --id: any
  --name: any
  --source-portfolio-id: any
]: any -> record<ProductViewDetail: record<ProductViewSummary: record<Id: record, ProductId: record, Name: record, Owner: record, ShortDescription: record, Type: record, Distributor: record, HasDefaultPath: record, SupportEmail: record, SupportDescription: record, SupportUrl: record>, Status: record, ProductARN: record, CreatedTime: record, SourceConnection: record<Type: record, ConnectionParameters: record, LastSync: record>>, ProvisioningArtifactSummaries: record, Tags: record, TagOptions: record, Budgets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductAsAdmin")
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id, "Name": $name, "SourcePortfolioId": $source_portfolio_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about the specified product.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductView
# operationId: DescribeProductView
export def "x-amz-target-aws242-service-catalog-service-describe-product-view get" [
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
  --x-amz-target: string@x-amz-target-completer-32
  --accept-language: any
  id: any
]: any -> record<ProductViewSummary: record<Id: record, ProductId: record, Name: record, Owner: record, ShortDescription: record, Type: record, Distributor: record, HasDefaultPath: record, SupportEmail: record, SupportDescription: record, SupportUrl: record>, ProvisioningArtifacts: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProductView")
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about the specified provisioned product.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProduct
# operationId: DescribeProvisionedProduct
export def "x-amz-target-aws242-service-catalog-service-describe-provisioned-product get" [
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
  --x-amz-target: string@x-amz-target-completer-33
  --accept-language: any
  --id: any
  --name: any
]: any -> record<ProvisionedProductDetail: record<Name: record, Arn: record, Type: record, Id: record, Status: record, StatusMessage: record, CreatedTime: record, IdempotencyToken: record, LastRecordId: record, LastProvisioningRecordId: record, LastSuccessfulProvisioningRecordId: record, ProductId: record, ProvisioningArtifactId: record, LaunchRoleArn: record>, CloudWatchDashboards: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProduct")
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about the resource changes for the specified plan.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProductPlan
# operationId: DescribeProvisionedProductPlan
export def "x-amz-target-aws242-service-catalog-service-describe-provisioned-product-plan get" [
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
  --x-amz-target: string@x-amz-target-completer-34
  --accept-language: any
  plan_id: any
  --page-size: any
  --page-token: any
]: any -> record<ProvisionedProductPlanDetails: record<CreatedTime: record, PathId: record, ProductId: record, PlanName: record, PlanId: record, ProvisionProductId: record, ProvisionProductName: record, PlanType: record, ProvisioningArtifactId: record, Status: record, UpdatedTime: record, NotificationArns: record, ProvisioningParameters: record, Tags: record, StatusMessage: record>, ResourceChanges: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisionedProductPlan")
  let req_body = {"AcceptLanguage": $accept_language, "PlanId": $plan_id, "PageSize": $page_size, "PageToken": $page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about the specified provisioning artifact (also known as a version) for the specified product.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningArtifact
# operationId: DescribeProvisioningArtifact
export def "x-amz-target-aws242-service-catalog-service-describe-provisioning-artifact get" [
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
  --x-amz-target: string@x-amz-target-completer-35
  --accept-language: any
  --provisioning-artifact-id: any
  --product-id: any
  --provisioning-artifact-name: any
  --product-name: any
  --verbose: any
]: any -> record<ProvisioningArtifactDetail: record<Id: record, Name: record, Description: record, Type: record, CreatedTime: record, Active: record, Guidance: record, SourceRevision: record>, Info: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningArtifact")
  let req_body = {"AcceptLanguage": $accept_language, "ProvisioningArtifactId": $provisioning_artifact_id, "ProductId": $product_id, "ProvisioningArtifactName": $provisioning_artifact_name, "ProductName": $product_name, "Verbose": $verbose} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about the configuration required to provision the specified product using the specified provisioning artifact. If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to ProvisionProduct, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[N]:Value". Tag the provisioned product with the value sc-tagoption-conflict-portfolioId-productId.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningParameters
# operationId: DescribeProvisioningParameters
export def "x-amz-target-aws242-service-catalog-service-describe-provisioning-parameters get" [
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
  --x-amz-target: string@x-amz-target-completer-36
  --accept-language: any
  --product-id: any
  --product-name: any
  --provisioning-artifact-id: any
  --provisioning-artifact-name: any
  --path-id: any
  --path-name: any
]: any -> record<ProvisioningArtifactParameters: record, ConstraintSummaries: record, UsageInstructions: record, TagOptions: record, ProvisioningArtifactPreferences: record<StackSetAccounts: record, StackSetRegions: record>, ProvisioningArtifactOutputs: record, ProvisioningArtifactOutputKeys: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeProvisioningParameters")
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "ProductName": $product_name, "ProvisioningArtifactId": $provisioning_artifact_id, "ProvisioningArtifactName": $provisioning_artifact_name, "PathId": $path_id, "PathName": $path_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about the specified request operation. Use this operation after calling a request operation (for example, ProvisionProduct, TerminateProvisionedProduct, or UpdateProvisionedProduct). If a provisioned product was transferred to a new owner using UpdateProvisionedProductProperties, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use ListRecordHistory to see the product's history from when he was the owner.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribeRecord
# operationId: DescribeRecord
export def "x-amz-target-aws242-service-catalog-service-describe-record get" [
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
  --x-amz-target: string@x-amz-target-completer-37
  --accept-language: any
  id: any
  --page-token: any
  --page-size: any
]: any -> record<RecordDetail: record<RecordId: record, ProvisionedProductName: record, Status: record, CreatedTime: record, UpdatedTime: record, ProvisionedProductType: record, RecordType: record, ProvisionedProductId: record, ProductId: record, ProvisioningArtifactId: record, PathId: record, RecordErrors: record, RecordTags: record, LaunchRoleArn: record>, RecordOutputs: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeRecord")
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id, "PageToken": $page_token, "PageSize": $page_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Describes a self-service action.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceAction
# operationId: DescribeServiceAction
export def "x-amz-target-aws242-service-catalog-service-describe-service-action get" [
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
  --x-amz-target: string@x-amz-target-completer-38
  id: any
  --accept-language: any
]: any -> record<ServiceActionDetail: record<ServiceActionSummary: record<Id: record, Name: record, Description: record, DefinitionType: record>, Definition: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceAction")
  let req_body = {"Id": $id, "AcceptLanguage": $accept_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Finds the default parameters for a specific self-service action on a specific provisioned product and returns a map of the results to the user.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters
# operationId: DescribeServiceActionExecutionParameters
export def "x-amz-target-aws242-service-catalog-service-describe-service-action-execution-parameters get" [
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
  --x-amz-target: string@x-amz-target-completer-39
  provisioned_product_id: any
  service_action_id: any
  --accept-language: any
]: any -> record<ServiceActionParameters: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters")
  let req_body = {"ProvisionedProductId": $provisioned_product_id, "ServiceActionId": $service_action_id, "AcceptLanguage": $accept_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about the specified TagOption.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DescribeTagOption
# operationId: DescribeTagOption
export def "x-amz-target-aws242-service-catalog-service-describe-tag-option get" [
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
  --x-amz-target: string@x-amz-target-completer-40
  id: any
]: any -> record<TagOptionDetail: record<Key: record, Value: record, Active: record, Id: record, Owner: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DescribeTagOption")
  let req_body = {"Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Disable portfolio sharing through the Organizations service. This command will not delete your current shares, but prevents you from creating new shares throughout your organization. Current shares are not kept in sync with your organization structure if the structure changes after calling this API. Only the management account in the organization can call this API. You cannot call this API if there are active delegated administrators in the organization. Note that a delegated administrator is not authorized to invoke DisableAWSOrganizationsAccess. If you share an Service Catalog portfolio in an organization within Organizations, and then disable Organizations access for Service Catalog, the portfolio access permissions will not sync with the latest changes to the organization structure. Specifically, accounts that you removed from the organization after disabling Service Catalog access will retain access to the previously shared portfolio.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DisableAWSOrganizationsAccess
# operationId: DisableAWSOrganizationsAccess
export def "x-amz-target-aws242-service-catalog-service-disable-aws-organizations-access disable" [
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
  --x-amz-target: string@x-amz-target-completer-41
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DisableAWSOrganizationsAccess")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Disassociates the specified budget from the specified resource.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DisassociateBudgetFromResource
# operationId: DisassociateBudgetFromResource
export def "x-amz-target-aws242-service-catalog-service-disassociate-budget-from-resource create" [
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
  --x-amz-target: string@x-amz-target-completer-42
  budget_name: any
  resource_id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateBudgetFromResource")
  let req_body = {"BudgetName": $budget_name, "ResourceId": $resource_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Disassociates a previously associated principal ARN from a specified portfolio. The PrincipalType and PrincipalARN must match the AssociatePrincipalWithPortfolio call request details. For example, to disassociate an association created with a PrincipalARN of PrincipalType IAM you must use the PrincipalType IAM when calling DisassociatePrincipalFromPortfolio. For portfolios that have been shared with principal name sharing enabled: after disassociating a principal, share recipient accounts will no longer be able to provision products in this portfolio using a role matching the name of the associated principal.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio
# operationId: DisassociatePrincipalFromPortfolio
export def "x-amz-target-aws242-service-catalog-service-disassociate-principal-from-portfolio create" [
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
  --x-amz-target: string@x-amz-target-completer-43
  --accept-language: any
  portfolio_id: any
  principal_arn: any
  --principal-type: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio")
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "PrincipalARN": $principal_arn, "PrincipalType": $principal_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Disassociates the specified product from the specified portfolio. A delegated admin is authorized to invoke this command.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DisassociateProductFromPortfolio
# operationId: DisassociateProductFromPortfolio
export def "x-amz-target-aws242-service-catalog-service-disassociate-product-from-portfolio create" [
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
  --x-amz-target: string@x-amz-target-completer-44
  --accept-language: any
  product_id: any
  portfolio_id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateProductFromPortfolio")
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "PortfolioId": $portfolio_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Disassociates the specified self-service action association from the specified provisioning artifact.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact
# operationId: DisassociateServiceActionFromProvisioningArtifact
export def "x-amz-target-aws242-service-catalog-service-disassociate-service-action-from-provisioning-artifact create" [
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
  --x-amz-target: string@x-amz-target-completer-45
  product_id: any
  provisioning_artifact_id: any
  service_action_id: any
  --accept-language: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact")
  let req_body = {"ProductId": $product_id, "ProvisioningArtifactId": $provisioning_artifact_id, "ServiceActionId": $service_action_id, "AcceptLanguage": $accept_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Disassociates the specified TagOption from the specified resource.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.DisassociateTagOptionFromResource
# operationId: DisassociateTagOptionFromResource
export def "x-amz-target-aws242-service-catalog-service-disassociate-tag-option-from-resource tag" [
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
  --x-amz-target: string@x-amz-target-completer-46
  resource_id: any
  tag_option_id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.DisassociateTagOptionFromResource")
  let req_body = {"ResourceId": $resource_id, "TagOptionId": $tag_option_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Enable portfolio sharing feature through Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the management account in the organization. When you call this API, Service Catalog calls organizations:EnableAWSServiceAccess on your behalf so that your shares stay in sync with any changes in your Organizations structure. Note that a delegated administrator is not authorized to invoke EnableAWSOrganizationsAccess. If you have previously disabled Organizations access for Service Catalog, and then enable access again, the portfolio access permissions might not sync with the latest changes to the organization structure. Specifically, accounts that you removed from the organization after disabling Service Catalog access, and before you enabled access again, can retain access to the previously shared portfolio. As a result, an account that has been removed from the organization might still be able to create or manage Amazon Web Services resources when it is no longer authorized to do so. Amazon Web Services is working to resolve this issue.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.EnableAWSOrganizationsAccess
# operationId: EnableAWSOrganizationsAccess
export def "x-amz-target-aws242-service-catalog-service-enable-aws-organizations-access enable" [
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
  --x-amz-target: string@x-amz-target-completer-47
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.EnableAWSOrganizationsAccess")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Provisions or modifies a product based on the resource changes for the specified plan.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductPlan
# operationId: ExecuteProvisionedProductPlan
export def "x-amz-target-aws242-service-catalog-service-execute-provisioned-product-plan create" [
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
  --x-amz-target: string@x-amz-target-completer-48
  --accept-language: any
  plan_id: any
  idempotency_token: any
]: any -> record<RecordDetail: record<RecordId: record, ProvisionedProductName: record, Status: record, CreatedTime: record, UpdatedTime: record, ProvisionedProductType: record, RecordType: record, ProvisionedProductId: record, ProductId: record, ProvisioningArtifactId: record, PathId: record, RecordErrors: record, RecordTags: record, LaunchRoleArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductPlan")
  let req_body = {"AcceptLanguage": $accept_language, "PlanId": $plan_id, "IdempotencyToken": $idempotency_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Executes a self-service action against a provisioned product.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction
# operationId: ExecuteProvisionedProductServiceAction
export def "x-amz-target-aws242-service-catalog-service-execute-provisioned-product-service-action create" [
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
  --x-amz-target: string@x-amz-target-completer-49
  provisioned_product_id: any
  service_action_id: any
  execute_token: any
  --accept-language: any
  --parameters: any
]: any -> record<RecordDetail: record<RecordId: record, ProvisionedProductName: record, Status: record, CreatedTime: record, UpdatedTime: record, ProvisionedProductType: record, RecordType: record, ProvisionedProductId: record, ProductId: record, ProvisioningArtifactId: record, PathId: record, RecordErrors: record, RecordTags: record, LaunchRoleArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction")
  let req_body = {"ProvisionedProductId": $provisioned_product_id, "ServiceActionId": $service_action_id, "ExecuteToken": $execute_token, "AcceptLanguage": $accept_language, "Parameters": $parameters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get the Access Status for Organizations portfolio share feature. This API can only be called by the management account in the organization or by a delegated admin.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus
# operationId: GetAWSOrganizationsAccessStatus
export def "x-amz-target-aws242-service-catalog-service-get-aws-organizations-access-status get" [
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
  --x-amz-target: string@x-amz-target-completer-50
  --body: record
]: any -> record<AccessStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# This API takes either a ProvisonedProductId or a ProvisionedProductName, along with a list of one or more output keys, and responds with the key/value pairs of those outputs.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.GetProvisionedProductOutputs
# operationId: GetProvisionedProductOutputs
export def "x-amz-target-aws242-service-catalog-service-get-provisioned-product-outputs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-51
  --accept-language: any
  --provisioned-product-id: any
  --provisioned-product-name: any
  --output-keys: any
  --page-size: any
  --page-token: any
]: any -> record<Outputs: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.GetProvisionedProductOutputs" $qp)
  let req_body = {"AcceptLanguage": $accept_language, "ProvisionedProductId": $provisioned_product_id, "ProvisionedProductName": $provisioned_product_name, "OutputKeys": $output_keys, "PageSize": $page_size, "PageToken": $page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Requests the import of a resource as an Service Catalog provisioned product that is associated to an Service Catalog product and provisioning artifact. Once imported, all supported governance actions are supported on the provisioned product. Resource import only supports CloudFormation stack ARNs. CloudFormation StackSets, and non-root nested stacks are not supported. The CloudFormation stack must have one of the following statuses to be imported: CREATE_COMPLETE, UPDATE_COMPLETE, UPDATE_ROLLBACK_COMPLETE, IMPORT_COMPLETE, and IMPORT_ROLLBACK_COMPLETE. Import of the resource requires that the CloudFormation stack template matches the associated Service Catalog product provisioning artifact. When you import an existing CloudFormation stack into a portfolio, constraints that are associated with the product aren't applied during the import process. The constraints are applied after you call UpdateProvisionedProduct for the provisioned product. The user or role that performs this operation must have the cloudformation:GetTemplate and cloudformation:DescribeStacks IAM policy permissions.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ImportAsProvisionedProduct
# operationId: ImportAsProvisionedProduct
export def "x-amz-target-aws242-service-catalog-service-import-as-provisioned-product import" [
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
  --x-amz-target: string@x-amz-target-completer-52
  --accept-language: any
  product_id: any
  provisioning_artifact_id: any
  provisioned_product_name: any
  physical_id: any
  idempotency_token: any
]: any -> record<RecordDetail: record<RecordId: record, ProvisionedProductName: record, Status: record, CreatedTime: record, UpdatedTime: record, ProvisionedProductType: record, RecordType: record, ProvisionedProductId: record, ProductId: record, ProvisioningArtifactId: record, PathId: record, RecordErrors: record, RecordTags: record, LaunchRoleArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ImportAsProvisionedProduct")
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "ProvisioningArtifactId": $provisioning_artifact_id, "ProvisionedProductName": $provisioned_product_name, "PhysicalId": $physical_id, "IdempotencyToken": $idempotency_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all imported portfolios for which account-to-account shares were accepted by this account. By specifying the PortfolioShareType, you can list portfolios for which organizational shares were accepted by this account.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListAcceptedPortfolioShares
# operationId: ListAcceptedPortfolioShares
export def "x-amz-target-aws242-service-catalog-service-list-accepted-portfolio-shares list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-53
  --accept-language: any
  --page-token: any
  --page-size: any
  --portfolio-share-type: any
]: any -> record<PortfolioDetails: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListAcceptedPortfolioShares" $qp)
  let req_body = {"AcceptLanguage": $accept_language, "PageToken": $page_token, "PageSize": $page_size, "PortfolioShareType": $portfolio_share_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all the budgets associated to the specified resource.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListBudgetsForResource
# operationId: ListBudgetsForResource
export def "x-amz-target-aws242-service-catalog-service-list-budgets-for-resource list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-54
  --accept-language: any
  resource_id: any
  --page-size: any
  --page-token: any
]: any -> record<Budgets: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListBudgetsForResource" $qp)
  let req_body = {"AcceptLanguage": $accept_language, "ResourceId": $resource_id, "PageSize": $page_size, "PageToken": $page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the constraints for the specified portfolio and product.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListConstraintsForPortfolio
# operationId: ListConstraintsForPortfolio
export def "x-amz-target-aws242-service-catalog-service-list-constraints-for-portfolio list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-55
  --accept-language: any
  portfolio_id: any
  --product-id: any
  --page-size: any
  --page-token: any
]: any -> record<ConstraintDetails: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListConstraintsForPortfolio" $qp)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "ProductId": $product_id, "PageSize": $page_size, "PageToken": $page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the paths to the specified product. A path describes how the user gets access to a specified product and is necessary when provisioning a product. A path also determines the constraints that are put on a product. A path is dependent on a specific product, porfolio, and principal. When provisioning a product that's been added to a portfolio, you must grant your user, group, or role access to the portfolio. For more information, see Granting users access (https://docs.aws.amazon.com/servicecatalog/latest/adminguide/catalogs_portfolios_users.html) in the Service Catalog User Guide.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListLaunchPaths
# operationId: ListLaunchPaths
export def "x-amz-target-aws242-service-catalog-service-list-launch-paths list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-56
  --accept-language: any
  product_id: any
  --page-size: any
  --page-token: any
]: any -> record<LaunchPathSummaries: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListLaunchPaths" $qp)
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "PageSize": $page_size, "PageToken": $page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the organization nodes that have access to the specified portfolio. This API can only be called by the management account in the organization or by a delegated admin. If a delegated admin is de-registered, they can no longer perform this operation.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListOrganizationPortfolioAccess
# operationId: ListOrganizationPortfolioAccess
export def "x-amz-target-aws242-service-catalog-service-list-organization-portfolio-access list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-57
  --accept-language: any
  portfolio_id: any
  organization_node_type: any
  --page-token: any
  --page-size: any
]: any -> record<OrganizationNodes: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListOrganizationPortfolioAccess" $qp)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "OrganizationNodeType": $organization_node_type, "PageToken": $page_token, "PageSize": $page_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the account IDs that have access to the specified portfolio. A delegated admin can list the accounts that have access to the shared portfolio. Note that if a delegated admin is de-registered, they can no longer perform this operation.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolioAccess
# operationId: ListPortfolioAccess
export def "x-amz-target-aws242-service-catalog-service-list-portfolio-access list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-58
  --accept-language: any
  portfolio_id: any
  --organization-parent-id: any
  --page-token: any
  --page-size: any
]: any -> record<AccountIds: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolioAccess" $qp)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "OrganizationParentId": $organization_parent_id, "PageToken": $page_token, "PageSize": $page_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all portfolios in the catalog.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolios
# operationId: ListPortfolios
export def "x-amz-target-aws242-service-catalog-service-list-portfolios list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-59
  --accept-language: any
  --page-token: any
  --page-size: any
]: any -> record<PortfolioDetails: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfolios" $qp)
  let req_body = {"AcceptLanguage": $accept_language, "PageToken": $page_token, "PageSize": $page_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all portfolios that the specified product is associated with.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListPortfoliosForProduct
# operationId: ListPortfoliosForProduct
export def "x-amz-target-aws242-service-catalog-service-list-portfolios-for-product list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-60
  --accept-language: any
  product_id: any
  --page-token: any
  --page-size: any
]: any -> record<PortfolioDetails: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListPortfoliosForProduct" $qp)
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "PageToken": $page_token, "PageSize": $page_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all PrincipalARNs and corresponding PrincipalTypes associated with the specified portfolio.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListPrincipalsForPortfolio
# operationId: ListPrincipalsForPortfolio
export def "x-amz-target-aws242-service-catalog-service-list-principals-for-portfolio list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-61
  --accept-language: any
  portfolio_id: any
  --page-size: any
  --page-token: any
]: any -> record<Principals: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListPrincipalsForPortfolio" $qp)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "PageSize": $page_size, "PageToken": $page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the plans for the specified provisioned product or all plans to which the user has access.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListProvisionedProductPlans
# operationId: ListProvisionedProductPlans
export def "x-amz-target-aws242-service-catalog-service-list-provisioned-product-plans list" [
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
  --x-amz-target: string@x-amz-target-completer-62
  --accept-language: any
  --provision-product-id: any
  --page-size: any
  --page-token: any
  --access-level-filter: any
]: any -> record<ProvisionedProductPlans: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisionedProductPlans")
  let req_body = {"AcceptLanguage": $accept_language, "ProvisionProductId": $provision_product_id, "PageSize": $page_size, "PageToken": $page_token, "AccessLevelFilter": $access_level_filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all provisioning artifacts (also known as versions) for the specified product.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifacts
# operationId: ListProvisioningArtifacts
export def "x-amz-target-aws242-service-catalog-service-list-provisioning-artifacts list" [
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
  --x-amz-target: string@x-amz-target-completer-63
  --accept-language: any
  product_id: any
]: any -> record<ProvisioningArtifactDetails: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifacts")
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all provisioning artifacts (also known as versions) for the specified self-service action.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction
# operationId: ListProvisioningArtifactsForServiceAction
export def "x-amz-target-aws242-service-catalog-service-list-provisioning-artifacts-for-service-action list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-64
  service_action_id: any
  --page-size: any
  --page-token: any
  --accept-language: any
]: any -> record<ProvisioningArtifactViews: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction" $qp)
  let req_body = {"ServiceActionId": $service_action_id, "PageSize": $page_size, "PageToken": $page_token, "AcceptLanguage": $accept_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the specified requests or all performed requests.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListRecordHistory
# operationId: ListRecordHistory
export def "x-amz-target-aws242-service-catalog-service-list-record-history list" [
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
  --x-amz-target: string@x-amz-target-completer-65
  --accept-language: any
  --access-level-filter: any
  --search-filter: any
  --page-size: any
  --page-token: any
]: any -> record<RecordDetails: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListRecordHistory")
  let req_body = {"AcceptLanguage": $accept_language, "AccessLevelFilter": $access_level_filter, "SearchFilter": $search_filter, "PageSize": $page_size, "PageToken": $page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the resources associated with the specified TagOption.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListResourcesForTagOption
# operationId: ListResourcesForTagOption
export def "x-amz-target-aws242-service-catalog-service-list-resources-for-tag-option list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-66
  tag_option_id: any
  --resource-type: any
  --page-size: any
  --page-token: any
]: any -> record<ResourceDetails: record, PageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListResourcesForTagOption" $qp)
  let req_body = {"TagOptionId": $tag_option_id, "ResourceType": $resource_type, "PageSize": $page_size, "PageToken": $page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists all self-service actions.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActions
# operationId: ListServiceActions
export def "x-amz-target-aws242-service-catalog-service-list-service-actions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-67
  --accept-language: any
  --page-size: any
  --page-token: any
]: any -> record<ServiceActionSummaries: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActions" $qp)
  let req_body = {"AcceptLanguage": $accept_language, "PageSize": $page_size, "PageToken": $page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact
# operationId: ListServiceActionsForProvisioningArtifact
export def "x-amz-target-aws242-service-catalog-service-list-service-actions-for-provisioning-artifact list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-68
  product_id: any
  provisioning_artifact_id: any
  --page-size: any
  --page-token: any
  --accept-language: any
]: any -> record<ServiceActionSummaries: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact" $qp)
  let req_body = {"ProductId": $product_id, "ProvisioningArtifactId": $provisioning_artifact_id, "PageSize": $page_size, "PageToken": $page_token, "AcceptLanguage": $accept_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Returns summary information about stack instances that are associated with the specified CFN_STACKSET type provisioned product. You can filter for stack instances that are associated with a specific Amazon Web Services account name or Region.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct
# operationId: ListStackInstancesForProvisionedProduct
export def "x-amz-target-aws242-service-catalog-service-list-stack-instances-for-provisioned-product list" [
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
  --x-amz-target: string@x-amz-target-completer-69
  --accept-language: any
  provisioned_product_id: any
  --page-token: any
  --page-size: any
]: any -> record<StackInstances: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct")
  let req_body = {"AcceptLanguage": $accept_language, "ProvisionedProductId": $provisioned_product_id, "PageToken": $page_token, "PageSize": $page_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the specified TagOptions or all TagOptions.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ListTagOptions
# operationId: ListTagOptions
export def "x-amz-target-aws242-service-catalog-service-list-tag-options list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-70
  --filters: any
  --page-size: any
  --page-token: any
]: any -> record<TagOptionDetails: record, PageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ListTagOptions" $qp)
  let req_body = {"Filters": $filters, "PageSize": $page_size, "PageToken": $page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Notifies the result of the provisioning engine execution.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.NotifyProvisionProductEngineWorkflowResult
# operationId: NotifyProvisionProductEngineWorkflowResult
export def "x-amz-target-aws242-service-catalog-service-notify-provision-product-engine-workflow-result notify" [
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
  --x-amz-target: string@x-amz-target-completer-71
  workflow_token: any
  record_id: any
  status: any
  --failure-reason: any
  --resource-identifier: any
  --outputs: any
  idempotency_token: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.NotifyProvisionProductEngineWorkflowResult")
  let req_body = {"WorkflowToken": $workflow_token, "RecordId": $record_id, "Status": $status, "FailureReason": $failure_reason, "ResourceIdentifier": $resource_identifier, "Outputs": $outputs, "IdempotencyToken": $idempotency_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Notifies the result of the terminate engine execution.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.NotifyTerminateProvisionedProductEngineWorkflowResult
# operationId: NotifyTerminateProvisionedProductEngineWorkflowResult
export def "x-amz-target-aws242-service-catalog-service-notify-terminate-provisioned-product-engine-workflow-result notify" [
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
  --x-amz-target: string@x-amz-target-completer-72
  workflow_token: any
  record_id: any
  status: any
  --failure-reason: any
  idempotency_token: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.NotifyTerminateProvisionedProductEngineWorkflowResult")
  let req_body = {"WorkflowToken": $workflow_token, "RecordId": $record_id, "Status": $status, "FailureReason": $failure_reason, "IdempotencyToken": $idempotency_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Notifies the result of the update engine execution.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.NotifyUpdateProvisionedProductEngineWorkflowResult
# operationId: NotifyUpdateProvisionedProductEngineWorkflowResult
export def "x-amz-target-aws242-service-catalog-service-notify-update-provisioned-product-engine-workflow-result notify" [
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
  --x-amz-target: string@x-amz-target-completer-73
  workflow_token: any
  record_id: any
  status: any
  --failure-reason: any
  --outputs: any
  idempotency_token: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.NotifyUpdateProvisionedProductEngineWorkflowResult")
  let req_body = {"WorkflowToken": $workflow_token, "RecordId": $record_id, "Status": $status, "FailureReason": $failure_reason, "Outputs": $outputs, "IdempotencyToken": $idempotency_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Provisions the specified product. A provisioned product is a resourced instance of a product. For example, provisioning a product that's based on an CloudFormation template launches an CloudFormation stack and its underlying resources. You can check the status of this request using DescribeRecord. If the request contains a tag key with an empty list of values, there's a tag conflict for that key. Don't include conflicted keys as tags, or this will cause the error "Parameter validation failed: Missing required parameter in Tags[N]:Value". When provisioning a product that's been added to a portfolio, you must grant your user, group, or role access to the portfolio. For more information, see Granting users access (https://docs.aws.amazon.com/servicecatalog/latest/adminguide/catalogs_portfolios_users.html) in the Service Catalog User Guide.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ProvisionProduct
# operationId: ProvisionProduct
export def "x-amz-target-aws242-service-catalog-service-provision-product create" [
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
  --x-amz-target: string@x-amz-target-completer-74
  --accept-language: any
  --product-id: any
  --product-name: any
  --provisioning-artifact-id: any
  --provisioning-artifact-name: any
  --path-id: any
  --path-name: any
  provisioned_product_name: any
  --provisioning-parameters: any
  --provisioning-preferences: any
  --tags: any
  --notification-arns: any
  provision_token: any
]: any -> record<RecordDetail: record<RecordId: record, ProvisionedProductName: record, Status: record, CreatedTime: record, UpdatedTime: record, ProvisionedProductType: record, RecordType: record, ProvisionedProductId: record, ProductId: record, ProvisioningArtifactId: record, PathId: record, RecordErrors: record, RecordTags: record, LaunchRoleArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ProvisionProduct")
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "ProductName": $product_name, "ProvisioningArtifactId": $provisioning_artifact_id, "ProvisioningArtifactName": $provisioning_artifact_name, "PathId": $path_id, "PathName": $path_name, "ProvisionedProductName": $provisioned_product_name, "ProvisioningParameters": $provisioning_parameters, "ProvisioningPreferences": $provisioning_preferences, "Tags": $tags, "NotificationArns": $notification_arns, "ProvisionToken": $provision_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Rejects an offer to share the specified portfolio.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.RejectPortfolioShare
# operationId: RejectPortfolioShare
export def "x-amz-target-aws242-service-catalog-service-reject-portfolio-share reject" [
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
  --x-amz-target: string@x-amz-target-completer-75
  --accept-language: any
  portfolio_id: any
  --portfolio-share-type: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.RejectPortfolioShare")
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "PortfolioShareType": $portfolio_share_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Lists the provisioned products that are available (not terminated). To use additional filtering, see SearchProvisionedProducts.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.ScanProvisionedProducts
# operationId: ScanProvisionedProducts
export def "x-amz-target-aws242-service-catalog-service-scan-provisioned-products create" [
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
  --x-amz-target: string@x-amz-target-completer-76
  --accept-language: any
  --access-level-filter: any
  --page-size: any
  --page-token: any
]: any -> record<ProvisionedProducts: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.ScanProvisionedProducts")
  let req_body = {"AcceptLanguage": $accept_language, "AccessLevelFilter": $access_level_filter, "PageSize": $page_size, "PageToken": $page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about the products to which the caller has access.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.SearchProducts
# operationId: SearchProducts
export def "x-amz-target-aws242-service-catalog-service-search-products list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-77
  --accept-language: any
  --filters: any
  --page-size: any
  --sort-by: any
  --sort-order: any
  --page-token: any
]: any -> record<ProductViewSummaries: record, ProductViewAggregations: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProducts" $qp)
  let req_body = {"AcceptLanguage": $accept_language, "Filters": $filters, "PageSize": $page_size, "SortBy": $sort_by, "SortOrder": $sort_order, "PageToken": $page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about the products for the specified portfolio or all products.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.SearchProductsAsAdmin
# operationId: SearchProductsAsAdmin
export def "x-amz-target-aws242-service-catalog-service-search-products-as-admin list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-78
  --accept-language: any
  --portfolio-id: any
  --filters: any
  --sort-by: any
  --sort-order: any
  --page-token: any
  --page-size: any
  --product-source: any
]: any -> record<ProductViewDetails: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProductsAsAdmin" $qp)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "Filters": $filters, "SortBy": $sort_by, "SortOrder": $sort_order, "PageToken": $page_token, "PageSize": $page_size, "ProductSource": $product_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets information about the provisioned products that meet the specified criteria.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.SearchProvisionedProducts
# operationId: SearchProvisionedProducts
export def "x-amz-target-aws242-service-catalog-service-search-provisioned-products list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: string # Pagination limit
  --page-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-79
  --accept-language: any
  --access-level-filter: any
  --filters: any
  --sort-by: any
  --sort-order: any
  --page-size: any
  --page-token: any
]: any -> record<ProvisionedProducts: record, TotalResultsCount: record, NextPageToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.SearchProvisionedProducts" $qp)
  let req_body = {"AcceptLanguage": $accept_language, "AccessLevelFilter": $access_level_filter, "Filters": $filters, "SortBy": $sort_by, "SortOrder": $sort_order, "PageSize": $page_size, "PageToken": $page_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Terminates the specified provisioned product. This operation does not delete any records associated with the provisioned product. You can check the status of this request using DescribeRecord.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.TerminateProvisionedProduct
# operationId: TerminateProvisionedProduct
export def "x-amz-target-aws242-service-catalog-service-terminate-provisioned-product create" [
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
  --x-amz-target: string@x-amz-target-completer-80
  --provisioned-product-name: any
  --provisioned-product-id: any
  terminate_token: any
  --ignore-errors: any
  --accept-language: any
  --retain-physical-resources: any
]: any -> record<RecordDetail: record<RecordId: record, ProvisionedProductName: record, Status: record, CreatedTime: record, UpdatedTime: record, ProvisionedProductType: record, RecordType: record, ProvisionedProductId: record, ProductId: record, ProvisioningArtifactId: record, PathId: record, RecordErrors: record, RecordTags: record, LaunchRoleArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.TerminateProvisionedProduct")
  let req_body = {"ProvisionedProductName": $provisioned_product_name, "ProvisionedProductId": $provisioned_product_id, "TerminateToken": $terminate_token, "IgnoreErrors": $ignore_errors, "AcceptLanguage": $accept_language, "RetainPhysicalResources": $retain_physical_resources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates the specified constraint.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.UpdateConstraint
# operationId: UpdateConstraint
export def "x-amz-target-aws242-service-catalog-service-update-constraint update" [
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
  --x-amz-target: string@x-amz-target-completer-81
  --accept-language: any
  id: any
  --description: any
  --parameters: any
]: any -> record<ConstraintDetail: record<ConstraintId: record, Type: record, Description: record, Owner: record, ProductId: record, PortfolioId: record>, ConstraintParameters: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateConstraint")
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id, "Description": $description, "Parameters": $parameters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates the specified portfolio. You cannot update a product that was shared with you.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.UpdatePortfolio
# operationId: UpdatePortfolio
export def "x-amz-target-aws242-service-catalog-service-update-portfolio update" [
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
  --x-amz-target: string@x-amz-target-completer-82
  --accept-language: any
  id: any
  --display-name: any
  --description: any
  --provider-name: any
  --add-tags: any
  --remove-tags: any
]: any -> record<PortfolioDetail: record<Id: record, ARN: record, DisplayName: record, Description: record, CreatedTime: record, ProviderName: record>, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.UpdatePortfolio")
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id, "DisplayName": $display_name, "Description": $description, "ProviderName": $provider_name, "AddTags": $add_tags, "RemoveTags": $remove_tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates the specified portfolio share. You can use this API to enable or disable TagOptions sharing or Principal sharing for an existing portfolio share. The portfolio share cannot be updated if the CreatePortfolioShare operation is IN_PROGRESS, as the share is not available to recipient entities. In this case, you must wait for the portfolio share to be COMPLETED. You must provide the accountId or organization node in the input, but not both. If the portfolio is shared to both an external account and an organization node, and both shares need to be updated, you must invoke UpdatePortfolioShare separately for each share type. This API cannot be used for removing the portfolio share. You must use DeletePortfolioShare API for that action. When you associate a principal with portfolio, a potential privilege escalation path may occur when that portfolio is then shared with other accounts. For a user in a recipient account who is not an Service Catalog Admin, but still has the ability to create Principals (Users/Groups/Roles), that user could create a role that matches a principal name association for the portfolio. Although this user may not know which principal names are associated through Service Catalog, they may be able to guess the user. If this potential escalation path is a concern, then Service Catalog recommends using PrincipalType as IAM. With this configuration, the PrincipalARN must already exist in the recipient account before it can be associated.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.UpdatePortfolioShare
# operationId: UpdatePortfolioShare
# --OrganizationNode shape: {Type?: any, Value?: any}
export def "x-amz-target-aws242-service-catalog-service-update-portfolio-share update" [
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
  --x-amz-target: string@x-amz-target-completer-83
  --accept-language: any
  portfolio_id: any
  --account-id: any
  --organization-node: record # Information about the organization node. — shape: {Type?: any, Value?: any}
  --share-tag-options: any
  --share-principals: any
]: any -> record<PortfolioShareToken: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.UpdatePortfolioShare")
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "AccountId": $account_id, "OrganizationNode": $organization_node, "ShareTagOptions": $share_tag_options, "SharePrincipals": $share_principals} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates the specified product.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.UpdateProduct
# operationId: UpdateProduct
export def "x-amz-target-aws242-service-catalog-service-update-product update" [
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
  --x-amz-target: string@x-amz-target-completer-84
  --accept-language: any
  id: any
  --name: any
  --owner: any
  --description: any
  --distributor: any
  --support-description: any
  --support-email: any
  --support-url: any
  --add-tags: any
  --remove-tags: any
  --source-connection: any
]: any -> record<ProductViewDetail: record<ProductViewSummary: record<Id: record, ProductId: record, Name: record, Owner: record, ShortDescription: record, Type: record, Distributor: record, HasDefaultPath: record, SupportEmail: record, SupportDescription: record, SupportUrl: record>, Status: record, ProductARN: record, CreatedTime: record, SourceConnection: record<Type: record, ConnectionParameters: record, LastSync: record>>, Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProduct")
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id, "Name": $name, "Owner": $owner, "Description": $description, "Distributor": $distributor, "SupportDescription": $support_description, "SupportEmail": $support_email, "SupportUrl": $support_url, "AddTags": $add_tags, "RemoveTags": $remove_tags, "SourceConnection": $source_connection} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Requests updates to the configuration of the specified provisioned product. If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely. You can check the status of this request using DescribeRecord.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProduct
# operationId: UpdateProvisionedProduct
export def "x-amz-target-aws242-service-catalog-service-update-provisioned-product update" [
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
  --x-amz-target: string@x-amz-target-completer-85
  --accept-language: any
  --provisioned-product-name: any
  --provisioned-product-id: any
  --product-id: any
  --product-name: any
  --provisioning-artifact-id: any
  --provisioning-artifact-name: any
  --path-id: any
  --path-name: any
  --provisioning-parameters: any
  --provisioning-preferences: any
  --tags: any
  update_token: any
]: any -> record<RecordDetail: record<RecordId: record, ProvisionedProductName: record, Status: record, CreatedTime: record, UpdatedTime: record, ProvisionedProductType: record, RecordType: record, ProvisionedProductId: record, ProductId: record, ProvisioningArtifactId: record, PathId: record, RecordErrors: record, RecordTags: record, LaunchRoleArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProduct")
  let req_body = {"AcceptLanguage": $accept_language, "ProvisionedProductName": $provisioned_product_name, "ProvisionedProductId": $provisioned_product_id, "ProductId": $product_id, "ProductName": $product_name, "ProvisioningArtifactId": $provisioning_artifact_id, "ProvisioningArtifactName": $provisioning_artifact_name, "PathId": $path_id, "PathName": $path_name, "ProvisioningParameters": $provisioning_parameters, "ProvisioningPreferences": $provisioning_preferences, "Tags": $tags, "UpdateToken": $update_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Requests updates to the properties of the specified provisioned product.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProductProperties
# operationId: UpdateProvisionedProductProperties
export def "x-amz-target-aws242-service-catalog-service-update-provisioned-product-properties update" [
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
  --x-amz-target: string@x-amz-target-completer-86
  --accept-language: any
  provisioned_product_id: any
  provisioned_product_properties: any
  idempotency_token: any
]: any -> record<ProvisionedProductId: record, ProvisionedProductProperties: record, RecordId: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisionedProductProperties")
  let req_body = {"AcceptLanguage": $accept_language, "ProvisionedProductId": $provisioned_product_id, "ProvisionedProductProperties": $provisioned_product_properties, "IdempotencyToken": $idempotency_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates the specified provisioning artifact (also known as a version) for the specified product. You cannot update a provisioning artifact for a product that was shared with you.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisioningArtifact
# operationId: UpdateProvisioningArtifact
export def "x-amz-target-aws242-service-catalog-service-update-provisioning-artifact update" [
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
  --x-amz-target: string@x-amz-target-completer-87
  --accept-language: any
  product_id: any
  provisioning_artifact_id: any
  --name: any
  --description: any
  --active: any
  --guidance: any
]: any -> record<ProvisioningArtifactDetail: record<Id: record, Name: record, Description: record, Type: record, CreatedTime: record, Active: record, Guidance: record, SourceRevision: record>, Info: record, Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateProvisioningArtifact")
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "ProvisioningArtifactId": $provisioning_artifact_id, "Name": $name, "Description": $description, "Active": $active, "Guidance": $guidance} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates a self-service action.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.UpdateServiceAction
# operationId: UpdateServiceAction
export def "x-amz-target-aws242-service-catalog-service-update-service-action update" [
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
  --x-amz-target: string@x-amz-target-completer-88
  id: any
  --name: any
  --definition: any
  --description: any
  --accept-language: any
]: any -> record<ServiceActionDetail: record<ServiceActionSummary: record<Id: record, Name: record, Description: record, DefinitionType: record>, Definition: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateServiceAction")
  let req_body = {"Id": $id, "Name": $name, "Definition": $definition, "Description": $description, "AcceptLanguage": $accept_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates the specified TagOption.
#
# POST /#X-Amz-Target=AWS242ServiceCatalogService.UpdateTagOption
# operationId: UpdateTagOption
export def "x-amz-target-aws242-service-catalog-service-update-tag-option update" [
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
  --x-amz-target: string@x-amz-target-completer-89
  id: any
  --value: any
  --active: any
]: any -> record<TagOptionDetail: record<Key: record, Value: record, Active: record, Id: record, Owner: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=AWS242ServiceCatalogService.UpdateTagOption")
  let req_body = {"Id": $id, "Value": $value, "Active": $active} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
