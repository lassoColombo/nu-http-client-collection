# Auto-generated client for AWS Service Catalog v2015-12-10
# Source: https://api.apis.guru/v2/specs/amazonaws.com/servicecatalog/2015-12-10/openapi.json
# Auth: --token flag or $env.AWS_SERVICE_CATALOG_TOKEN

const BASE_URL = "http://servicecatalog.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_SERVICE_CATALOG_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
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

def base-url-completer [] { ["http://servicecatalog.us-east-1.amazonaws.com" "http://servicecatalog.us-east-2.amazonaws.com" "http://servicecatalog.us-west-1.amazonaws.com" "http://servicecatalog.us-west-2.amazonaws.com" "http://servicecatalog.us-gov-west-1.amazonaws.com" "http://servicecatalog.us-gov-east-1.amazonaws.com" "http://servicecatalog.ca-central-1.amazonaws.com" "http://servicecatalog.eu-north-1.amazonaws.com" "http://servicecatalog.eu-west-1.amazonaws.com" "http://servicecatalog.eu-west-2.amazonaws.com" "http://servicecatalog.eu-west-3.amazonaws.com" "http://servicecatalog.eu-central-1.amazonaws.com" "http://servicecatalog.eu-south-1.amazonaws.com" "http://servicecatalog.af-south-1.amazonaws.com" "http://servicecatalog.ap-northeast-1.amazonaws.com" "http://servicecatalog.ap-northeast-2.amazonaws.com" "http://servicecatalog.ap-northeast-3.amazonaws.com" "http://servicecatalog.ap-southeast-1.amazonaws.com" "http://servicecatalog.ap-southeast-2.amazonaws.com" "http://servicecatalog.ap-east-1.amazonaws.com" "http://servicecatalog.ap-south-1.amazonaws.com" "http://servicecatalog.sa-east-1.amazonaws.com" "http://servicecatalog.me-south-1.amazonaws.com" "https://servicecatalog.us-east-1.amazonaws.com" "https://servicecatalog.us-east-2.amazonaws.com" "https://servicecatalog.us-west-1.amazonaws.com" "https://servicecatalog.us-west-2.amazonaws.com" "https://servicecatalog.us-gov-west-1.amazonaws.com" "https://servicecatalog.us-gov-east-1.amazonaws.com" "https://servicecatalog.ca-central-1.amazonaws.com" "https://servicecatalog.eu-north-1.amazonaws.com" "https://servicecatalog.eu-west-1.amazonaws.com" "https://servicecatalog.eu-west-2.amazonaws.com" "https://servicecatalog.eu-west-3.amazonaws.com" "https://servicecatalog.eu-central-1.amazonaws.com" "https://servicecatalog.eu-south-1.amazonaws.com" "https://servicecatalog.af-south-1.amazonaws.com" "https://servicecatalog.ap-northeast-1.amazonaws.com" "https://servicecatalog.ap-northeast-2.amazonaws.com" "https://servicecatalog.ap-northeast-3.amazonaws.com" "https://servicecatalog.ap-southeast-1.amazonaws.com" "https://servicecatalog.ap-southeast-2.amazonaws.com" "https://servicecatalog.ap-east-1.amazonaws.com" "https://servicecatalog.ap-south-1.amazonaws.com" "https://servicecatalog.sa-east-1.amazonaws.com" "https://servicecatalog.me-south-1.amazonaws.com" "http://servicecatalog.cn-north-1.amazonaws.com.cn" "http://servicecatalog.cn-northwest-1.amazonaws.com.cn" "https://servicecatalog.cn-north-1.amazonaws.com.cn" "https://servicecatalog.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def portfolio-share-type-completer [] { ["AWS_ORGANIZATIONS" "AWS_SERVICECATALOG" "IMPORTED"] }
def x-amz-target-completer [] { ["AWS242ServiceCatalogService.AcceptPortfolioShare"] }
def x-amz-target-completer-1 [] { ["AWS242ServiceCatalogService.AssociateBudgetWithResource"] }
def principal-type-completer [] { ["IAM" "IAM_PATTERN"] }
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
def product-type-completer [] { ["CLOUD_FORMATION_TEMPLATE" "MARKETPLACE" "TERRAFORM_OPEN_SOURCE"] }
def x-amz-target-completer-12 [] { ["AWS242ServiceCatalogService.CreateProduct"] }
def plan-type-completer [] { ["CLOUDFORMATION"] }
def x-amz-target-completer-13 [] { ["AWS242ServiceCatalogService.CreateProvisionedProductPlan"] }
def x-amz-target-completer-14 [] { ["AWS242ServiceCatalogService.CreateProvisioningArtifact"] }
def definition-type-completer [] { ["SSM_AUTOMATION"] }
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
def type-completer [] { ["ACCOUNT" "ORGANIZATION" "ORGANIZATIONAL_UNIT" "ORGANIZATION_MEMBER_ACCOUNT"] }
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
def organization-node-type-completer [] { ["ACCOUNT" "ORGANIZATION" "ORGANIZATIONAL_UNIT"] }
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
def status-completer [] { ["FAILED" "SUCCEEDED"] }
def x-amz-target-completer-71 [] { ["AWS242ServiceCatalogService.NotifyProvisionProductEngineWorkflowResult"] }
def x-amz-target-completer-72 [] { ["AWS242ServiceCatalogService.NotifyTerminateProvisionedProductEngineWorkflowResult"] }
def x-amz-target-completer-73 [] { ["AWS242ServiceCatalogService.NotifyUpdateProvisionedProductEngineWorkflowResult"] }
def x-amz-target-completer-74 [] { ["AWS242ServiceCatalogService.ProvisionProduct"] }
def x-amz-target-completer-75 [] { ["AWS242ServiceCatalogService.RejectPortfolioShare"] }
def x-amz-target-completer-76 [] { ["AWS242ServiceCatalogService.ScanProvisionedProducts"] }
def sort-by-completer [] { ["CreationDate" "Title" "VersionCount"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def x-amz-target-completer-77 [] { ["AWS242ServiceCatalogService.SearchProducts"] }
def product-source-completer [] { ["ACCOUNT"] }
def x-amz-target-completer-78 [] { ["AWS242ServiceCatalogService.SearchProductsAsAdmin"] }
def x-amz-target-completer-79 [] { ["AWS242ServiceCatalogService.SearchProvisionedProducts"] }
def x-amz-target-completer-80 [] { ["AWS242ServiceCatalogService.TerminateProvisionedProduct"] }
def x-amz-target-completer-81 [] { ["AWS242ServiceCatalogService.UpdateConstraint"] }
def x-amz-target-completer-82 [] { ["AWS242ServiceCatalogService.UpdatePortfolio"] }
def x-amz-target-completer-83 [] { ["AWS242ServiceCatalogService.UpdatePortfolioShare"] }
def x-amz-target-completer-84 [] { ["AWS242ServiceCatalogService.UpdateProduct"] }
def x-amz-target-completer-85 [] { ["AWS242ServiceCatalogService.UpdateProvisionedProduct"] }
def x-amz-target-completer-86 [] { ["AWS242ServiceCatalogService.UpdateProvisionedProductProperties"] }
def guidance-completer [] { ["DEFAULT" "DEPRECATED"] }
def x-amz-target-completer-87 [] { ["AWS242ServiceCatalogService.UpdateProvisioningArtifact"] }
def x-amz-target-completer-88 [] { ["AWS242ServiceCatalogService.UpdateServiceAction"] }
def x-amz-target-completer-89 [] { ["AWS242ServiceCatalogService.UpdateTagOption"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-portfolio-share" "associate-budget-with-resource" "associate-principal-with-portfolio" "associate-product-with-portfolio" "associate-service-action-with-provisioning-artifact" "associate-tag-option-with-resource" "batch-associate-service-action-with-provisioning-artifact" "batch-disassociate-service-action-from-provisioning-artifact" "copy-product" "create-constraint" "create-portfolio" "create-portfolio-share" "create-product" "create-provisioned-product-plan" "create-provisioning-artifact" "create-service-action" "create-tag-option" "delete-constraint" "delete-portfolio" "delete-portfolio-share" "delete-product" "delete-provisioned-product-plan" "delete-provisioning-artifact" "delete-service-action" "delete-tag-option" "describe-constraint" "describe-copy-product-status" "describe-portfolio" "describe-portfolio-share-status" "describe-portfolio-shares" "describe-product" "describe-product-as-admin" "describe-product-view" "describe-provisioned-product" "describe-provisioned-product-plan" "describe-provisioning-artifact" "describe-provisioning-parameters" "describe-record" "describe-service-action" "describe-service-action-execution-parameters" "describe-tag-option" "disable-aws-organizations-access" "disassociate-budget-from-resource" "disassociate-principal-from-portfolio" "disassociate-product-from-portfolio" "disassociate-service-action-from-provisioning-artifact" "disassociate-tag-option-from-resource" "enable-aws-organizations-access" "execute-provisioned-product-plan" "execute-provisioned-product-service-action" "get-aws-organizations-access-status" "get-provisioned-product-outputs" "import-as-provisioned-product" "list-accepted-portfolio-shares" "list-budgets-for-resource" "list-constraints-for-portfolio" "list-launch-paths" "list-organization-portfolio-access" "list-portfolio-access" "list-portfolios" "list-portfolios-for-product" "list-principals-for-portfolio" "list-provisioned-product-plans" "list-provisioning-artifacts" "list-provisioning-artifacts-for-service-action" "list-record-history" "list-resources-for-tag-option" "list-service-actions" "list-service-actions-for-provisioning-artifact" "list-stack-instances-for-provisioned-product" "list-tag-options" "notify-provision-product-engine-workflow-result" "notify-terminate-provisioned-product-engine-workflow-result" "notify-update-provisioned-product-engine-workflow-result" "provision-product" "reject-portfolio-share" "scan-provisioned-products" "search-products" "search-products-as-admin" "search-provisioned-products" "terminate-provisioned-product" "update-constraint" "update-portfolio" "update-portfolio-share" "update-product" "update-provisioned-product" "update-provisioned-product-properties" "update-provisioning-artifact" "update-service-action" "update-tag-option" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
# POST /
# operationId: AcceptPortfolioShare
export def "accept-portfolio-share" [
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  --portfolio-share-type: string@portfolio-share-type-completer # The type of shared portfolios to accept. The default is to accept imported portfolios. AWS_ORGANIZATIONS - Accept portfolios shared by the management account of your organization. IMPORTED - Accept imported portfolios. AWS_SERVICECATALOG - Not supported. (Throws ResourceNotFoundException.) For example, aws servicecatalog accept-portfolio-share --portfolio-id "port-2qwzkwxt3y5fk" --portfolio-share-type AWS_ORGANIZATIONS
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.AcceptPortfolioShare")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "PortfolioShareType": $portfolio_share_type} | compact
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

# Associates the specified budget with the specified resource.
#
# POST /
# operationId: AssociateBudgetWithResource
export def "associate-budget-with-resource" [
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
  budget_name: string # The name of the budget you want to associate.
  resource_id: string # The resource identifier. Either a portfolio-id or a product-id.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.AssociateBudgetWithResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BudgetName": $budget_name, "ResourceId": $resource_id} | compact
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

# Associates the specified principal ARN with the specified portfolio. If you share the portfolio with principal name sharing enabled, the PrincipalARN association is included in the share. The PortfolioID, PrincipalARN, and PrincipalType parameters are required. You can associate a maximum of 10 Principals with a portfolio using PrincipalType as IAM_PATTERN When you associate a principal with portfolio, a potential privilege escalation path may occur when that portfolio is then shared with other accounts. For a user in a recipient account who is not an Service Catalog Admin, but still has the ability to create Principals (Users/Groups/Roles), that user could create a role that matches a principal name association for the portfolio. Although this user may not know which principal names are associated through Service Catalog, they may be able to guess the user. If this potential escalation path is a concern, then Service Catalog recommends using PrincipalType as IAM. With this configuration, the PrincipalARN must already exist in the recipient account before it can be associated.
#
# POST /
# operationId: AssociatePrincipalWithPortfolio
export def "associate-principal-with-portfolio" [
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  principal_arn: string # The ARN of the principal (user, role, or group). This field allows an ARN with no accountID if PrincipalType is IAM_PATTERN. You can associate multiple IAM patterns even if the account has no principal with that name. This is useful in Principal Name Sharing if you want to share a principal without creating it in the account that owns the portfolio.
  principal_type: string@principal-type-completer # The principal type. The supported value is IAM if you use a fully defined ARN, or IAM_PATTERN if you use an ARN with no accountID.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.AssociatePrincipalWithPortfolio")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "PrincipalARN": $principal_arn, "PrincipalType": $principal_type} | compact
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

# Associates the specified product with the specified portfolio. A delegated admin is authorized to invoke this command.
#
# POST /
# operationId: AssociateProductWithPortfolio
export def "associate-product-with-portfolio" [
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  portfolio_id: string # The portfolio identifier.
  --source-portfolio-id: string # The identifier of the source portfolio.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.AssociateProductWithPortfolio")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "PortfolioId": $portfolio_id, "SourcePortfolioId": $source_portfolio_id} | compact
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

# Associates a self-service action with a provisioning artifact.
#
# POST /
# operationId: AssociateServiceActionWithProvisioningArtifact
export def "associate-service-action-with-provisioning-artifact" [
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
  product_id: string # The product identifier. For example, prod-abcdzk7xy33qa.
  provisioning_artifact_id: string # The identifier of the provisioning artifact. For example, pa-4abcdjnxjj6ne.
  service_action_id: string # The self-service action identifier. For example, act-fs7abcd89wxyz.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.AssociateServiceActionWithProvisioningArtifact")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ProductId": $product_id, "ProvisioningArtifactId": $provisioning_artifact_id, "ServiceActionId": $service_action_id, "AcceptLanguage": $accept_language} | compact
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

# Associate the specified TagOption with the specified portfolio or product.
#
# POST /
# operationId: AssociateTagOptionWithResource
export def "associate-tag-option-with-resource" [
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
  resource_id: string # The resource identifier.
  tag_option_id: string # The TagOption identifier.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.AssociateTagOptionWithResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceId": $resource_id, "TagOptionId": $tag_option_id} | compact
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

# Associates multiple self-service actions with provisioning artifacts.
#
# POST /
# operationId: BatchAssociateServiceActionWithProvisioningArtifact
export def "batch-associate-service-action-with-provisioning-artifact" [
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
  --x-amz-target: string@x-amz-target-completer-6 # required
  service_action_associations: list # One or more associations, each consisting of the Action ID, the Product ID, and the Provisioning Artifact ID. — item shape: {ServiceActionId: string, ProductId: string, ProvisioningArtifactId: string}
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record<FailedServiceActionAssociations: table<ServiceActionId: string, ProductId: string, ProvisioningArtifactId: string, ErrorCode: string, ErrorMessage: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.BatchAssociateServiceActionWithProvisioningArtifact")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ServiceActionAssociations": $service_action_associations, "AcceptLanguage": $accept_language} | compact
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

# Disassociates a batch of self-service actions from the specified provisioning artifact.
#
# POST /
# operationId: BatchDisassociateServiceActionFromProvisioningArtifact
export def "batch-disassociate-service-action-from-provisioning-artifact" [
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  service_action_associations: list # One or more associations, each consisting of the Action ID, the Product ID, and the Provisioning Artifact ID. — item shape: {ServiceActionId: string, ProductId: string, ProvisioningArtifactId: string}
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record<FailedServiceActionAssociations: table<ServiceActionId: string, ProductId: string, ProvisioningArtifactId: string, ErrorCode: string, ErrorMessage: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.BatchDisassociateServiceActionFromProvisioningArtifact")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ServiceActionAssociations": $service_action_associations, "AcceptLanguage": $accept_language} | compact
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

# Copies the specified source product to the specified target product or a new product. You can copy a product to the same account or another account. You can copy a product to the same Region or another Region. If you copy a product to another account, you must first share the product in a portfolio using CreatePortfolioShare. This operation is performed asynchronously. To track the progress of the operation, use DescribeCopyProductStatus.
#
# POST /
# operationId: CopyProduct
export def "copy-product" [
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  source_product_arn: string # The Amazon Resource Name (ARN) of the source product.
  --target-product-id: string # The identifier of the target product. By default, a new product is created.
  --target-product-name: string # A name for the target product. The default is the name of the source product.
  --source-provisioning-artifact-identifiers: list # The identifiers of the provisioning artifacts (also known as versions) of the product to copy. By default, all provisioning artifacts are copied.
  --copy-options: list<string> # The copy options. If the value is CopyTags, the tags from the source product are copied to the target product.
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
]: any -> oneof<record<CopyProductToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.CopyProduct")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "SourceProductArn": $source_product_arn, "TargetProductId": $target_product_id, "TargetProductName": $target_product_name, "SourceProvisioningArtifactIdentifiers": $source_provisioning_artifact_identifiers, "CopyOptions": $copy_options, "IdempotencyToken": $idempotency_token} | compact
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

# Creates a constraint. A delegated admin is authorized to invoke this command.
#
# POST /
# operationId: CreateConstraint
export def "create-constraint" [
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  product_id: string # The product identifier.
  parameters: string # The constraint parameters, in JSON format. The syntax depends on the constraint type as follows: LAUNCH You are required to specify either the RoleArn or the LocalRoleName but can't use both. Specify the RoleArn property as follows: {"RoleArn" : "arn:aws:iam::123456789012:role/LaunchRole"} Specify the LocalRoleName property as follows: {"LocalRoleName": "SCBasicLaunchRole"} If you specify the LocalRoleName property, when an account uses the launch constraint, the IAM role with that name in the account will be used. This allows launch-role constraints to be account-agnostic so the administrator can create fewer resources per shared account. The given role name must exist in the account used to create the launch constraint and the account of the user who launches a product with this launch constraint. You cannot have both a LAUNCH and a STACKSET constraint. You also cannot have more than one LAUNCH constraint on a product and portfolio. NOTIFICATION Specify the NotificationArns property as follows: {"NotificationArns" : ["arn:aws:sns:us-east-1:123456789012:Topic"]} RESOURCE_UPDATE Specify the TagUpdatesOnProvisionedProduct property as follows: {"Version":"2.0","Properties":{"TagUpdateOnProvisionedProduct":"String"}} The TagUpdatesOnProvisionedProduct property accepts a string value of ALLOWED or NOT_ALLOWED. STACKSET Specify the Parameters property as follows: {"Version": "String", "Properties": {"AccountList": [ "String" ], "RegionList": [ "String" ], "AdminRole": "String", "ExecutionRole": "String"}} You cannot have both a LAUNCH and a STACKSET constraint. You also cannot have more than one STACKSET constraint on a product and portfolio. Products with a STACKSET constraint will launch an CloudFormation stack set. TEMPLATE Specify the Rules property. For more information, see Template Constraint Rules (http://docs.aws.amazon.com/servicecatalog/latest/adminguide/reference-template_constraint_rules.html).
  type: string # The type of constraint. LAUNCH NOTIFICATION RESOURCE_UPDATE STACKSET TEMPLATE
  --description: string # The description of the constraint.
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
]: any -> oneof<record<ConstraintDetail: record<ConstraintId: string, Type: string, Description: string, Owner: string, ProductId: string, PortfolioId: string>, ConstraintParameters: string, Status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.CreateConstraint")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "ProductId": $product_id, "Parameters": $parameters, "Type": $type, "Description": $description, "IdempotencyToken": $idempotency_token} | compact
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

# Creates a portfolio. A delegated admin is authorized to invoke this command.
#
# POST /
# operationId: CreatePortfolio
export def "create-portfolio" [
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  display_name: string # The name to use for display purposes.
  --description: string # The description of the portfolio.
  provider_name: string # The name of the portfolio provider.
  --tags: list # One or more tags. — item shape: {Key: string, Value: string}
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
]: any -> oneof<record<PortfolioDetail: record<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, Tags: table<Key: string, Value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.CreatePortfolio")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "DisplayName": $display_name, "Description": $description, "ProviderName": $provider_name, "Tags": $tags, "IdempotencyToken": $idempotency_token} | compact
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

# Shares the specified portfolio with the specified account or organization node. Shares to an organization node can only be created by the management account of an organization or by a delegated administrator. You can share portfolios to an organization, an organizational unit, or a specific account. Note that if a delegated admin is de-registered, they can no longer create portfolio shares. AWSOrganizationsAccess must be enabled in order to create a portfolio share to an organization node. You can't share a shared resource, including portfolios that contain a shared product. If the portfolio share with the specified account or organization node already exists, this action will have no effect and will not return an error. To update an existing share, you must use the UpdatePortfolioShare API instead. When you associate a principal with portfolio, a potential privilege escalation path may occur when that portfolio is then shared with other accounts. For a user in a recipient account who is not an Service Catalog Admin, but still has the ability to create Principals (Users/Groups/Roles), that user could create a role that matches a principal name association for the portfolio. Although this user may not know which principal names are associated through Service Catalog, they may be able to guess the user. If this potential escalation path is a concern, then Service Catalog recommends using PrincipalType as IAM. With this configuration, the PrincipalARN must already exist in the recipient account before it can be associated.
#
# POST /
# operationId: CreatePortfolioShare
export def "create-portfolio-share" [
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  --account-id: string # The Amazon Web Services account ID. For example, 123456789012.
  --organization-node: record # Information about the organization node. — shape: {Type?: "ORGANIZATION"|"ORGANIZATIONAL_UNIT"|"ACCOUNT", Value?: string}
  --share-tag-options: oneof<nothing, bool> # Enables or disables TagOptions sharing when creating the portfolio share. If this flag is not provided, TagOptions sharing is disabled.
  --share-principals: oneof<nothing, bool> # Enables or disables Principal sharing when creating the portfolio share. If this flag is not provided, principal sharing is disabled. When you enable Principal Name Sharing for a portfolio share, the share recipient account end users with a principal that matches any of the associated IAM patterns can provision products from the portfolio. Once shared, the share recipient can view associations of PrincipalType: IAM_PATTERN on their portfolio. You can create the principals in the recipient account before or after creating the share.
]: any -> oneof<record<PortfolioShareToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.CreatePortfolioShare")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "AccountId": $account_id, "OrganizationNode": $organization_node, "ShareTagOptions": $share_tag_options, "SharePrincipals": $share_principals} | compact
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

# Creates a product. A delegated admin is authorized to invoke this command. The user or role that performs this operation must have the cloudformation:GetTemplate IAM policy permission. This policy permission is required when using the ImportFromPhysicalId template source in the information data section.
#
# POST /
# operationId: CreateProduct
export def "create-product" [
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
  --x-amz-target: string@x-amz-target-completer-12 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  name: string # The name of the product.
  owner: string # The owner of the product.
  --description: string # The description of the product.
  --distributor: string # The distributor of the product.
  --support-description: string # The support information about the product.
  --support-email: string # The contact email for product support.
  --support-url: string # The contact URL for product support. ^https?:\/\// / is the pattern used to validate SupportUrl.
  product_type: string@product-type-completer # The type of product.
  --tags: list # One or more tags. — item shape: {Key: string, Value: string}
  --provisioning-artifact-parameters: record # Information about a provisioning artifact (also known as a version) for a product. — shape: {Name?: string, Description?: string, Info?: record, Type?: "CLOUD_FORMATION_TEMPLATE"|"MARKETPLACE_AMI"|"MARKETPLACE_CAR"|"TERRAFORM_OPEN_SOURCE", DisableTemplateValidation?: bool}
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
  --source-connection: record # A top level ProductViewDetail response containing details about the product’s connection. Service Catalog returns this field for the CreateProduct, UpdateProduct, DescribeProductAsAdmin, and SearchProductAsAdmin APIs. This response contains the same fields as the ConnectionParameters request, with the addition of the LastSync response. — shape: {Type?: "CODESTAR", ConnectionParameters: record}
]: any -> oneof<record<ProductViewDetail: record<ProductViewSummary: record<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, Status: string, ProductARN: string, CreatedTime: string, SourceConnection: record<Type: string, ConnectionParameters: record, LastSync: record>>, ProvisioningArtifactDetail: record<Id: string, Name: string, Description: string, Type: string, CreatedTime: string, Active: bool, Guidance: string, SourceRevision: string>, Tags: table<Key: string, Value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.CreateProduct")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "Name": $name, "Owner": $owner, "Description": $description, "Distributor": $distributor, "SupportDescription": $support_description, "SupportEmail": $support_email, "SupportUrl": $support_url, "ProductType": $product_type, "Tags": $tags, "ProvisioningArtifactParameters": $provisioning_artifact_parameters, "IdempotencyToken": $idempotency_token, "SourceConnection": $source_connection} | compact
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

# Creates a plan. A plan includes the list of resources to be created (when provisioning a new product) or modified (when updating a provisioned product) when the plan is executed. You can create one plan for each provisioned product. To create a plan for an existing provisioned product, the product status must be AVAILABLE or TAINTED. To view the resource changes in the change set, use DescribeProvisionedProductPlan. To create or modify the provisioned product, use ExecuteProvisionedProductPlan.
#
# POST /
# operationId: CreateProvisionedProductPlan
export def "create-provisioned-product-plan" [
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  plan_name: string # The name of the plan.
  plan_type: string@plan-type-completer # The plan type.
  --notification-arns: list<string> # Passed to CloudFormation. The SNS topic ARNs to which to publish stack-related events.
  --path-id: string # The path identifier of the product. This value is optional if the product has a default path, and required if the product has more than one path. To list the paths for a product, use ListLaunchPaths.
  product_id: string # The product identifier.
  provisioned_product_name: string # A user-friendly name for the provisioned product. This value must be unique for the Amazon Web Services account and cannot be updated after the product is provisioned.
  provisioning_artifact_id: string # The identifier of the provisioning artifact.
  --provisioning-parameters: list # Parameters specified by the administrator that are required for provisioning the product. — item shape: {Key?: string, Value?: string, UsePreviousValue?: bool}
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
  --tags: list # One or more tags. If the plan is for an existing provisioned product, the product must have a RESOURCE_UPDATE constraint with TagUpdatesOnProvisionedProduct set to ALLOWED to allow tag updates. — item shape: {Key: string, Value: string}
]: any -> oneof<record<PlanName: string, PlanId: string, ProvisionProductId: string, ProvisionedProductName: string, ProvisioningArtifactId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.CreateProvisionedProductPlan")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PlanName": $plan_name, "PlanType": $plan_type, "NotificationArns": $notification_arns, "PathId": $path_id, "ProductId": $product_id, "ProvisionedProductName": $provisioned_product_name, "ProvisioningArtifactId": $provisioning_artifact_id, "ProvisioningParameters": $provisioning_parameters, "IdempotencyToken": $idempotency_token, "Tags": $tags} | compact
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

# Creates a provisioning artifact (also known as a version) for the specified product. You cannot create a provisioning artifact for a product that was shared with you. The user or role that performs this operation must have the cloudformation:GetTemplate IAM policy permission. This policy permission is required when using the ImportFromPhysicalId template source in the information data section.
#
# POST /
# operationId: CreateProvisioningArtifact
export def "create-provisioning-artifact" [
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  parameters: record # Information about a provisioning artifact (also known as a version) for a product. — shape: {Name?: string, Description?: string, Info?: record, Type?: "CLOUD_FORMATION_TEMPLATE"|"MARKETPLACE_AMI"|"MARKETPLACE_CAR"|"TERRAFORM_OPEN_SOURCE", DisableTemplateValidation?: bool}
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
]: any -> oneof<record<ProvisioningArtifactDetail: record<Id: string, Name: string, Description: string, Type: string, CreatedTime: string, Active: bool, Guidance: string, SourceRevision: string>, Info: record, Status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.CreateProvisioningArtifact")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "Parameters": $parameters, "IdempotencyToken": $idempotency_token} | compact
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

# Creates a self-service action.
#
# POST /
# operationId: CreateServiceAction
export def "create-service-action" [
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
  name: string # The self-service action name.
  definition_type: string@definition-type-completer # The service action definition type. For example, SSM_AUTOMATION.
  definition: record # The self-service action definition. Can be one of the following: Name The name of the Amazon Web Services Systems Manager document (SSM document). For example, AWS-RestartEC2Instance. If you are using a shared SSM document, you must provide the ARN instead of the name. Version The Amazon Web Services Systems Manager automation document version. For example, "Version": "1" AssumeRole The Amazon Resource Name (ARN) of the role that performs the self-service actions on your behalf. For example, "AssumeRole": "arn:aws:iam::12345678910:role/ActionRole". To reuse the provisioned product launch role, set to "AssumeRole": "LAUNCH_ROLE". Parameters The list of parameters in JSON format. For example: [{\"Name\":\"InstanceId\",\"Type\":\"TARGET\"}] or [{\"Name\":\"InstanceId\",\"Type\":\"TEXT_VALUE\"}].
  --description: string # The self-service action description.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
]: any -> oneof<record<ServiceActionDetail: record<ServiceActionSummary: record<Id: string, Name: string, Description: string, DefinitionType: string>, Definition: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.CreateServiceAction")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "DefinitionType": $definition_type, "Definition": $definition, "Description": $description, "AcceptLanguage": $accept_language, "IdempotencyToken": $idempotency_token} | compact
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

# Creates a TagOption.
#
# POST /
# operationId: CreateTagOption
export def "create-tag-option" [
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
  key: string # The TagOption key.
  value: string # The TagOption value.
]: any -> oneof<record<TagOptionDetail: record<Key: string, Value: string, Active: bool, Id: string, Owner: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.CreateTagOption")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Key": $key, "Value": $value} | compact
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

# Deletes the specified constraint. A delegated admin is authorized to invoke this command.
#
# POST /
# operationId: DeleteConstraint
export def "delete-constraint" [
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The identifier of the constraint.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DeleteConstraint")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id} | compact
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

# Deletes the specified portfolio. You cannot delete a portfolio if it was shared with you or if it has associated products, users, constraints, or shared accounts. A delegated admin is authorized to invoke this command.
#
# POST /
# operationId: DeletePortfolio
export def "delete-portfolio" [
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
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The portfolio identifier.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DeletePortfolio")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id} | compact
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

# Stops sharing the specified portfolio with the specified account or organization node. Shares to an organization node can only be deleted by the management account of an organization or by a delegated administrator. Note that if a delegated admin is de-registered, portfolio shares created from that account are removed.
#
# POST /
# operationId: DeletePortfolioShare
export def "delete-portfolio-share" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  --account-id: string # The Amazon Web Services account ID.
  --organization-node: record # Information about the organization node. — shape: {Type?: "ORGANIZATION"|"ORGANIZATIONAL_UNIT"|"ACCOUNT", Value?: string}
]: any -> oneof<record<PortfolioShareToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DeletePortfolioShare")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "AccountId": $account_id, "OrganizationNode": $organization_node} | compact
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

# Deletes the specified product. You cannot delete a product if it was shared with you or is associated with a portfolio. A delegated admin is authorized to invoke this command.
#
# POST /
# operationId: DeleteProduct
export def "delete-product" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The product identifier.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DeleteProduct")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id} | compact
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

# Deletes the specified plan.
#
# POST /
# operationId: DeleteProvisionedProductPlan
export def "delete-provisioned-product-plan" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  plan_id: string # The plan identifier.
  --ignore-errors: oneof<nothing, bool> # If set to true, Service Catalog stops managing the specified provisioned product even if it cannot delete the underlying resources.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DeleteProvisionedProductPlan")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PlanId": $plan_id, "IgnoreErrors": $ignore_errors} | compact
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

# Deletes the specified provisioning artifact (also known as a version) for the specified product. You cannot delete a provisioning artifact associated with a product that was shared with you. You cannot delete the last provisioning artifact for a product, because a product must have at least one provisioning artifact.
#
# POST /
# operationId: DeleteProvisioningArtifact
export def "delete-provisioning-artifact" [
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
  --x-amz-target: string@x-amz-target-completer-22 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  provisioning_artifact_id: string # The identifier of the provisioning artifact.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DeleteProvisioningArtifact")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "ProvisioningArtifactId": $provisioning_artifact_id} | compact
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

# Deletes a self-service action.
#
# POST /
# operationId: DeleteServiceAction
export def "delete-service-action" [
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  id: string # The self-service action identifier. For example, act-fs7abcd89wxyz.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DeleteServiceAction")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Id": $id, "AcceptLanguage": $accept_language} | compact
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

# Deletes the specified TagOption. You cannot delete a TagOption if it is associated with a product or portfolio.
#
# POST /
# operationId: DeleteTagOption
export def "delete-tag-option" [
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
  --x-amz-target: string@x-amz-target-completer-24 # required
  id: string # The TagOption identifier.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DeleteTagOption")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Id": $id} | compact
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

# Gets information about the specified constraint.
#
# POST /
# operationId: DescribeConstraint
export def "describe-constraint" [
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
  --x-amz-target: string@x-amz-target-completer-25 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The identifier of the constraint.
]: any -> oneof<record<ConstraintDetail: record<ConstraintId: string, Type: string, Description: string, Owner: string, ProductId: string, PortfolioId: string>, ConstraintParameters: string, Status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribeConstraint")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id} | compact
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

# Gets the status of the specified copy product operation.
#
# POST /
# operationId: DescribeCopyProductStatus
export def "describe-copy-product-status" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  copy_product_token: string # The token for the copy product operation. This token is returned by CopyProduct.
]: any -> oneof<record<CopyProductStatus: string, TargetProductId: string, StatusDetail: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribeCopyProductStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "CopyProductToken": $copy_product_token} | compact
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

# Gets information about the specified portfolio. A delegated admin is authorized to invoke this command.
#
# POST /
# operationId: DescribePortfolio
export def "describe-portfolio" [
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
  --x-amz-target: string@x-amz-target-completer-27 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The portfolio identifier.
]: any -> oneof<record<PortfolioDetail: record<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, Tags: table<Key: string, Value: string>, TagOptions: table<Key: string, Value: string, Active: bool, Id: string, Owner: string>, Budgets: table<BudgetName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribePortfolio")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id} | compact
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

# Gets the status of the specified portfolio share operation. This API can only be called by the management account in the organization or by a delegated admin.
#
# POST /
# operationId: DescribePortfolioShareStatus
export def "describe-portfolio-share-status" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  portfolio_share_token: string # The token for the portfolio share operation. This token is returned either by CreatePortfolioShare or by DeletePortfolioShare.
]: any -> oneof<record<PortfolioShareToken: string, PortfolioId: string, OrganizationNodeValue: string, Status: string, ShareDetails: record<SuccessfulShares: list<string>, ShareErrors: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribePortfolioShareStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"PortfolioShareToken": $portfolio_share_token} | compact
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

# Returns a summary of each of the portfolio shares that were created for the specified portfolio. You can use this API to determine which accounts or organizational nodes this portfolio have been shared, whether the recipient entity has imported the share, and whether TagOptions are included with the share. The PortfolioId and Type parameters are both required.
#
# POST /
# operationId: DescribePortfolioShares
export def "describe-portfolio-shares" [
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
  --x-amz-target: string@x-amz-target-completer-29 # required
  portfolio_id: string # The unique identifier of the portfolio for which shares will be retrieved.
  type: string@type-completer # The type of portfolio share to summarize. This field acts as a filter on the type of portfolio share, which can be one of the following: 1. ACCOUNT - Represents an external account to account share. 2. ORGANIZATION - Represents a share to an organization. This share is available to every account in the organization. 3. ORGANIZATIONAL_UNIT - Represents a share to an organizational unit. 4. ORGANIZATION_MEMBER_ACCOUNT - Represents a share to an account in the organization.
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
  --page-size-body: int # The maximum number of items to return with this call. (body field)
]: any -> oneof<record<NextPageToken: string, PortfolioShareDetails: table<PrincipalId: string, Type: string, Accepted: bool, ShareTagOptions: bool, SharePrincipals: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribePortfolioShares")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"PortfolioId": $portfolio_id, "Type": $type, "PageToken": $page_token_body, "PageSize": $page_size_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets information about the specified product. Running this operation with administrator access results in a failure. DescribeProductAsAdmin should be used instead.
#
# POST /
# operationId: DescribeProduct
export def "describe-product" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --id: string # The product identifier.
  --name: string # The product name.
]: any -> oneof<record<ProductViewSummary: record<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, ProvisioningArtifacts: table<Id: string, Name: string, Description: string, CreatedTime: string, Guidance: string>, Budgets: table<BudgetName: string>, LaunchPaths: table<Id: string, Name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribeProduct")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id, "Name": $name} | compact
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

# Gets information about the specified product. This operation is run with administrator access.
#
# POST /
# operationId: DescribeProductAsAdmin
export def "describe-product-as-admin" [
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --id: string # The product identifier.
  --name: string # The product name.
  --source-portfolio-id: string # The unique identifier of the shared portfolio that the specified product is associated with. You can provide this parameter to retrieve the shared TagOptions associated with the product. If this parameter is provided and if TagOptions sharing is enabled in the portfolio share, the API returns both local and shared TagOptions associated with the product. Otherwise only local TagOptions will be returned.
]: any -> oneof<record<ProductViewDetail: record<ProductViewSummary: record<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, Status: string, ProductARN: string, CreatedTime: string, SourceConnection: record<Type: string, ConnectionParameters: record, LastSync: record>>, ProvisioningArtifactSummaries: table<Id: string, Name: string, Description: string, CreatedTime: string, ProvisioningArtifactMetadata: record>, Tags: table<Key: string, Value: string>, TagOptions: table<Key: string, Value: string, Active: bool, Id: string, Owner: string>, Budgets: table<BudgetName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribeProductAsAdmin")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id, "Name": $name, "SourcePortfolioId": $source_portfolio_id} | compact
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

# Gets information about the specified product.
#
# POST /
# operationId: DescribeProductView
export def "describe-product-view" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The product view identifier.
]: any -> oneof<record<ProductViewSummary: record<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, ProvisioningArtifacts: table<Id: string, Name: string, Description: string, CreatedTime: string, Guidance: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribeProductView")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id} | compact
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

# Gets information about the specified provisioned product.
#
# POST /
# operationId: DescribeProvisionedProduct
export def "describe-provisioned-product" [
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --id: string # The provisioned product identifier. You must provide the name or ID, but not both. If you do not provide a name or ID, or you provide both name and ID, an InvalidParametersException will occur.
  --name: string # The name of the provisioned product. You must provide the name or ID, but not both. If you do not provide a name or ID, or you provide both name and ID, an InvalidParametersException will occur.
]: any -> oneof<record<ProvisionedProductDetail: record<Name: string, Arn: string, Type: string, Id: string, Status: string, StatusMessage: string, CreatedTime: string, IdempotencyToken: string, LastRecordId: string, LastProvisioningRecordId: string, LastSuccessfulProvisioningRecordId: string, ProductId: string, ProvisioningArtifactId: string, LaunchRoleArn: string>, CloudWatchDashboards: table<Name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribeProvisionedProduct")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id, "Name": $name} | compact
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

# Gets information about the resource changes for the specified plan.
#
# POST /
# operationId: DescribeProvisionedProductPlan
export def "describe-provisioned-product-plan" [
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
  --x-amz-target: string@x-amz-target-completer-34 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  plan_id: string # The plan identifier.
  --page-size: int # The maximum number of items to return with this call.
  --page-token: string # The page token for the next set of results. To retrieve the first set of results, use null.
]: any -> oneof<record<ProvisionedProductPlanDetails: record<CreatedTime: string, PathId: string, ProductId: string, PlanName: string, PlanId: string, ProvisionProductId: string, ProvisionProductName: string, PlanType: string, ProvisioningArtifactId: string, Status: string, UpdatedTime: string, NotificationArns: list<string>, ProvisioningParameters: list<record>, Tags: list<record>, StatusMessage: string>, ResourceChanges: table<Action: string, LogicalResourceId: string, PhysicalResourceId: string, ResourceType: string, Replacement: string, Scope: list, Details: list>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribeProvisionedProductPlan")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PlanId": $plan_id, "PageSize": $page_size, "PageToken": $page_token} | compact
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

# Gets information about the specified provisioning artifact (also known as a version) for the specified product.
#
# POST /
# operationId: DescribeProvisioningArtifact
export def "describe-provisioning-artifact" [
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --provisioning-artifact-id: string # The identifier of the provisioning artifact.
  --product-id: string # The product identifier.
  --provisioning-artifact-name: string # The provisioning artifact name.
  --product-name: string # The product name.
  --verbose: oneof<nothing, bool> # Indicates whether a verbose level of detail is enabled.
]: any -> oneof<record<ProvisioningArtifactDetail: record<Id: string, Name: string, Description: string, Type: string, CreatedTime: string, Active: bool, Guidance: string, SourceRevision: string>, Info: record, Status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribeProvisioningArtifact")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProvisioningArtifactId": $provisioning_artifact_id, "ProductId": $product_id, "ProvisioningArtifactName": $provisioning_artifact_name, "ProductName": $product_name, "Verbose": $verbose} | compact
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

# Gets information about the configuration required to provision the specified product using the specified provisioning artifact. If the output contains a TagOption key with an empty list of values, there is a TagOption conflict for that key. The end user cannot take action to fix the conflict, and launch is not blocked. In subsequent calls to ProvisionProduct, do not include conflicted TagOption keys as tags, or this causes the error "Parameter validation failed: Missing required parameter in Tags[N]:Value". Tag the provisioned product with the value sc-tagoption-conflict-portfolioId-productId.
#
# POST /
# operationId: DescribeProvisioningParameters
export def "describe-provisioning-parameters" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --product-id: string # The product identifier. You must provide the product name or ID, but not both.
  --product-name: string # The name of the product. You must provide the name or ID, but not both.
  --provisioning-artifact-id: string # The identifier of the provisioning artifact. You must provide the name or ID, but not both.
  --provisioning-artifact-name: string # The name of the provisioning artifact. You must provide the name or ID, but not both.
  --path-id: string # The path identifier of the product. This value is optional if the product has a default path, and required if the product has more than one path. To list the paths for a product, use ListLaunchPaths. You must provide the name or ID, but not both.
  --path-name: string # The name of the path. You must provide the name or ID, but not both.
]: any -> oneof<record<ProvisioningArtifactParameters: table<ParameterKey: string, DefaultValue: string, ParameterType: string, IsNoEcho: bool, Description: string, ParameterConstraints: record>, ConstraintSummaries: table<Type: string, Description: string>, UsageInstructions: table<Type: string, Value: string>, TagOptions: table<Key: string, Values: list>, ProvisioningArtifactPreferences: record<StackSetAccounts: list<string>, StackSetRegions: list<string>>, ProvisioningArtifactOutputs: table<Key: string, Description: string>, ProvisioningArtifactOutputKeys: table<Key: string, Description: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribeProvisioningParameters")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "ProductName": $product_name, "ProvisioningArtifactId": $provisioning_artifact_id, "ProvisioningArtifactName": $provisioning_artifact_name, "PathId": $path_id, "PathName": $path_name} | compact
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

# Gets information about the specified request operation. Use this operation after calling a request operation (for example, ProvisionProduct, TerminateProvisionedProduct, or UpdateProvisionedProduct). If a provisioned product was transferred to a new owner using UpdateProvisionedProductProperties, the new owner will be able to describe all past records for that product. The previous owner will no longer be able to describe the records, but will be able to use ListRecordHistory to see the product's history from when he was the owner.
#
# POST /
# operationId: DescribeRecord
export def "describe-record" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The record identifier of the provisioned product. This identifier is returned by the request operation.
  --page-token: string # The page token for the next set of results. To retrieve the first set of results, use null.
  --page-size: int # The maximum number of items to return with this call.
]: any -> oneof<record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>, RecordOutputs: table<OutputKey: string, OutputValue: string, Description: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribeRecord")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id, "PageToken": $page_token, "PageSize": $page_size} | compact
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

# Describes a self-service action.
#
# POST /
# operationId: DescribeServiceAction
export def "describe-service-action" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  id: string # The self-service action identifier.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record<ServiceActionDetail: record<ServiceActionSummary: record<Id: string, Name: string, Description: string, DefinitionType: string>, Definition: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribeServiceAction")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Id": $id, "AcceptLanguage": $accept_language} | compact
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

# Finds the default parameters for a specific self-service action on a specific provisioned product and returns a map of the results to the user.
#
# POST /
# operationId: DescribeServiceActionExecutionParameters
export def "describe-service-action-execution-parameters" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  provisioned_product_id: string # The identifier of the provisioned product.
  service_action_id: string # The self-service action identifier.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record<ServiceActionParameters: table<Name: string, Type: string, DefaultValues: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribeServiceActionExecutionParameters")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ProvisionedProductId": $provisioned_product_id, "ServiceActionId": $service_action_id, "AcceptLanguage": $accept_language} | compact
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

# Gets information about the specified TagOption.
#
# POST /
# operationId: DescribeTagOption
export def "describe-tag-option" [
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
  --x-amz-target: string@x-amz-target-completer-40 # required
  id: string # The TagOption identifier.
]: any -> oneof<record<TagOptionDetail: record<Key: string, Value: string, Active: bool, Id: string, Owner: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DescribeTagOption")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Id": $id} | compact
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

# Disable portfolio sharing through the Organizations service. This command will not delete your current shares, but prevents you from creating new shares throughout your organization. Current shares are not kept in sync with your organization structure if the structure changes after calling this API. Only the management account in the organization can call this API. You cannot call this API if there are active delegated administrators in the organization. Note that a delegated administrator is not authorized to invoke DisableAWSOrganizationsAccess. If you share an Service Catalog portfolio in an organization within Organizations, and then disable Organizations access for Service Catalog, the portfolio access permissions will not sync with the latest changes to the organization structure. Specifically, accounts that you removed from the organization after disabling Service Catalog access will retain access to the previously shared portfolio.
#
# POST /
# operationId: DisableAWSOrganizationsAccess
export def "disable-aws-organizations-access" [
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
  --x-amz-target: string@x-amz-target-completer-41 # required
  --body: record
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DisableAWSOrganizationsAccess")
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

# Disassociates the specified budget from the specified resource.
#
# POST /
# operationId: DisassociateBudgetFromResource
export def "disassociate-budget-from-resource" [
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  budget_name: string # The name of the budget you want to disassociate.
  resource_id: string # The resource identifier you want to disassociate from. Either a portfolio-id or a product-id.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DisassociateBudgetFromResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BudgetName": $budget_name, "ResourceId": $resource_id} | compact
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

# Disassociates a previously associated principal ARN from a specified portfolio. The PrincipalType and PrincipalARN must match the AssociatePrincipalWithPortfolio call request details. For example, to disassociate an association created with a PrincipalARN of PrincipalType IAM you must use the PrincipalType IAM when calling DisassociatePrincipalFromPortfolio. For portfolios that have been shared with principal name sharing enabled: after disassociating a principal, share recipient accounts will no longer be able to provision products in this portfolio using a role matching the name of the associated principal.
#
# POST /
# operationId: DisassociatePrincipalFromPortfolio
export def "disassociate-principal-from-portfolio" [
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  principal_arn: string # The ARN of the principal (user, role, or group). This field allows an ARN with no accountID if PrincipalType is IAM_PATTERN.
  --principal-type: string@principal-type-completer # The supported value is IAM if you use a fully defined ARN, or IAM_PATTERN if you use no accountID.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DisassociatePrincipalFromPortfolio")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "PrincipalARN": $principal_arn, "PrincipalType": $principal_type} | compact
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

# Disassociates the specified product from the specified portfolio. A delegated admin is authorized to invoke this command.
#
# POST /
# operationId: DisassociateProductFromPortfolio
export def "disassociate-product-from-portfolio" [
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
  --x-amz-target: string@x-amz-target-completer-44 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  portfolio_id: string # The portfolio identifier.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DisassociateProductFromPortfolio")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "PortfolioId": $portfolio_id} | compact
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

# Disassociates the specified self-service action association from the specified provisioning artifact.
#
# POST /
# operationId: DisassociateServiceActionFromProvisioningArtifact
export def "disassociate-service-action-from-provisioning-artifact" [
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
  --x-amz-target: string@x-amz-target-completer-45 # required
  product_id: string # The product identifier. For example, prod-abcdzk7xy33qa.
  provisioning_artifact_id: string # The identifier of the provisioning artifact. For example, pa-4abcdjnxjj6ne.
  service_action_id: string # The self-service action identifier. For example, act-fs7abcd89wxyz.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DisassociateServiceActionFromProvisioningArtifact")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ProductId": $product_id, "ProvisioningArtifactId": $provisioning_artifact_id, "ServiceActionId": $service_action_id, "AcceptLanguage": $accept_language} | compact
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

# Disassociates the specified TagOption from the specified resource.
#
# POST /
# operationId: DisassociateTagOptionFromResource
export def "disassociate-tag-option-from-resource" [
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
  --x-amz-target: string@x-amz-target-completer-46 # required
  resource_id: string # The resource identifier.
  tag_option_id: string # The TagOption identifier.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.DisassociateTagOptionFromResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceId": $resource_id, "TagOptionId": $tag_option_id} | compact
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

# Enable portfolio sharing feature through Organizations. This API will allow Service Catalog to receive updates on your organization in order to sync your shares with the current structure. This API can only be called by the management account in the organization. When you call this API, Service Catalog calls organizations:EnableAWSServiceAccess on your behalf so that your shares stay in sync with any changes in your Organizations structure. Note that a delegated administrator is not authorized to invoke EnableAWSOrganizationsAccess. If you have previously disabled Organizations access for Service Catalog, and then enable access again, the portfolio access permissions might not sync with the latest changes to the organization structure. Specifically, accounts that you removed from the organization after disabling Service Catalog access, and before you enabled access again, can retain access to the previously shared portfolio. As a result, an account that has been removed from the organization might still be able to create or manage Amazon Web Services resources when it is no longer authorized to do so. Amazon Web Services is working to resolve this issue.
#
# POST /
# operationId: EnableAWSOrganizationsAccess
export def "enable-aws-organizations-access" [
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
  --x-amz-target: string@x-amz-target-completer-47 # required
  --body: record
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.EnableAWSOrganizationsAccess")
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

# Provisions or modifies a product based on the resource changes for the specified plan.
#
# POST /
# operationId: ExecuteProvisionedProductPlan
export def "execute-provisioned-product-plan" [
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
  --x-amz-target: string@x-amz-target-completer-48 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  plan_id: string # The plan identifier.
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
]: any -> oneof<record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ExecuteProvisionedProductPlan")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PlanId": $plan_id, "IdempotencyToken": $idempotency_token} | compact
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

# Executes a self-service action against a provisioned product.
#
# POST /
# operationId: ExecuteProvisionedProductServiceAction
export def "execute-provisioned-product-service-action" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  provisioned_product_id: string # The identifier of the provisioned product.
  service_action_id: string # The self-service action identifier. For example, act-fs7abcd89wxyz.
  execute_token: string # An idempotency token that uniquely identifies the execute request.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --parameters: record # A map of all self-service action parameters and their values. If a provided parameter is of a special type, such as TARGET, the provided value will override the default value generated by Service Catalog. If the parameters field is not provided, no additional parameters are passed and default values will be used for any special parameters such as TARGET.
]: any -> oneof<record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ExecuteProvisionedProductServiceAction")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ProvisionedProductId": $provisioned_product_id, "ServiceActionId": $service_action_id, "ExecuteToken": $execute_token, "AcceptLanguage": $accept_language, "Parameters": $parameters} | compact
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

# Get the Access Status for Organizations portfolio share feature. This API can only be called by the management account in the organization or by a delegated admin.
#
# POST /
# operationId: GetAWSOrganizationsAccessStatus
export def "get-aws-organizations-access-status" [
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
  --x-amz-target: string@x-amz-target-completer-50 # required
  --body: record
]: any -> oneof<record<AccessStatus: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.GetAWSOrganizationsAccessStatus")
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

# This API takes either a ProvisonedProductId or a ProvisionedProductName, along with a list of one or more output keys, and responds with the key/value pairs of those outputs.
#
# POST /
# operationId: GetProvisionedProductOutputs
export def "get-provisioned-product-outputs" [
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
  --x-amz-target: string@x-amz-target-completer-51 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --provisioned-product-id: string # The identifier of the provisioned product that you want the outputs from.
  --provisioned-product-name: string # The name of the provisioned product that you want the outputs from.
  --output-keys: list<string> # The list of keys that the API should return with their values. If none are provided, the API will return all outputs of the provisioned product.
  --page-size-body: int # The maximum number of items to return with this call. (body field)
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
]: any -> oneof<record<Outputs: table<OutputKey: string, OutputValue: string, Description: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.GetProvisionedProductOutputs")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProvisionedProductId": $provisioned_product_id, "ProvisionedProductName": $provisioned_product_name, "OutputKeys": $output_keys, "PageSize": $page_size_body, "PageToken": $page_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Requests the import of a resource as an Service Catalog provisioned product that is associated to an Service Catalog product and provisioning artifact. Once imported, all supported governance actions are supported on the provisioned product. Resource import only supports CloudFormation stack ARNs. CloudFormation StackSets, and non-root nested stacks are not supported. The CloudFormation stack must have one of the following statuses to be imported: CREATE_COMPLETE, UPDATE_COMPLETE, UPDATE_ROLLBACK_COMPLETE, IMPORT_COMPLETE, and IMPORT_ROLLBACK_COMPLETE. Import of the resource requires that the CloudFormation stack template matches the associated Service Catalog product provisioning artifact. When you import an existing CloudFormation stack into a portfolio, constraints that are associated with the product aren't applied during the import process. The constraints are applied after you call UpdateProvisionedProduct for the provisioned product. The user or role that performs this operation must have the cloudformation:GetTemplate and cloudformation:DescribeStacks IAM policy permissions.
#
# POST /
# operationId: ImportAsProvisionedProduct
export def "import-as-provisioned-product" [
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
  --x-amz-target: string@x-amz-target-completer-52 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  provisioning_artifact_id: string # The identifier of the provisioning artifact.
  provisioned_product_name: string # The user-friendly name of the provisioned product. The value must be unique for the Amazon Web Services account. The name cannot be updated after the product is provisioned.
  physical_id: string # The unique identifier of the resource to be imported. It only currently supports CloudFormation stack IDs.
  idempotency_token: string # A unique identifier that you provide to ensure idempotency. If multiple requests differ only by the idempotency token, the same response is returned for each repeated request.
]: any -> oneof<record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ImportAsProvisionedProduct")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "ProvisioningArtifactId": $provisioning_artifact_id, "ProvisionedProductName": $provisioned_product_name, "PhysicalId": $physical_id, "IdempotencyToken": $idempotency_token} | compact
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

# Lists all imported portfolios for which account-to-account shares were accepted by this account. By specifying the PortfolioShareType, you can list portfolios for which organizational shares were accepted by this account.
#
# POST /
# operationId: ListAcceptedPortfolioShares
export def "list-accepted-portfolio-shares" [
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
  --x-amz-target: string@x-amz-target-completer-53 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
  --page-size-body: int # The maximum number of items to return with this call. (body field)
  --portfolio-share-type: string@portfolio-share-type-completer # The type of shared portfolios to list. The default is to list imported portfolios. AWS_ORGANIZATIONS - List portfolios accepted and shared via organizational sharing by the management account or delegated administrator of your organization. AWS_SERVICECATALOG - Deprecated type. IMPORTED - List imported portfolios that have been accepted and shared through account-to-account sharing.
]: any -> oneof<record<PortfolioDetails: table<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListAcceptedPortfolioShares")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PageToken": $page_token_body, "PageSize": $page_size_body, "PortfolioShareType": $portfolio_share_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists all the budgets associated to the specified resource.
#
# POST /
# operationId: ListBudgetsForResource
export def "list-budgets-for-resource" [
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
  --x-amz-target: string@x-amz-target-completer-54 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  resource_id: string # The resource identifier.
  --page-size-body: int # The maximum number of items to return with this call. (body field)
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
]: any -> oneof<record<Budgets: table<BudgetName: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListBudgetsForResource")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ResourceId": $resource_id, "PageSize": $page_size_body, "PageToken": $page_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the constraints for the specified portfolio and product.
#
# POST /
# operationId: ListConstraintsForPortfolio
export def "list-constraints-for-portfolio" [
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
  --x-amz-target: string@x-amz-target-completer-55 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  --product-id: string # The product identifier.
  --page-size-body: int # The maximum number of items to return with this call. (body field)
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
]: any -> oneof<record<ConstraintDetails: table<ConstraintId: string, Type: string, Description: string, Owner: string, ProductId: string, PortfolioId: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListConstraintsForPortfolio")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "ProductId": $product_id, "PageSize": $page_size_body, "PageToken": $page_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the paths to the specified product. A path describes how the user gets access to a specified product and is necessary when provisioning a product. A path also determines the constraints that are put on a product. A path is dependent on a specific product, porfolio, and principal. When provisioning a product that's been added to a portfolio, you must grant your user, group, or role access to the portfolio. For more information, see Granting users access (https://docs.aws.amazon.com/servicecatalog/latest/adminguide/catalogs_portfolios_users.html) in the Service Catalog User Guide.
#
# POST /
# operationId: ListLaunchPaths
export def "list-launch-paths" [
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
  --x-amz-target: string@x-amz-target-completer-56 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  --page-size-body: int # The maximum number of items to return with this call. (body field)
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
]: any -> oneof<record<LaunchPathSummaries: table<Id: string, ConstraintSummaries: list, Tags: list, Name: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListLaunchPaths")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "PageSize": $page_size_body, "PageToken": $page_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the organization nodes that have access to the specified portfolio. This API can only be called by the management account in the organization or by a delegated admin. If a delegated admin is de-registered, they can no longer perform this operation.
#
# POST /
# operationId: ListOrganizationPortfolioAccess
export def "list-organization-portfolio-access" [
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
  --x-amz-target: string@x-amz-target-completer-57 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier. For example, port-2abcdext3y5fk.
  organization_node_type: string@organization-node-type-completer # The organization node type that will be returned in the output. ORGANIZATION - Organization that has access to the portfolio. ORGANIZATIONAL_UNIT - Organizational unit that has access to the portfolio within your organization. ACCOUNT - Account that has access to the portfolio within your organization.
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
  --page-size-body: int # The maximum number of items to return with this call. (body field)
]: any -> oneof<record<OrganizationNodes: table<Type: string, Value: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListOrganizationPortfolioAccess")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "OrganizationNodeType": $organization_node_type, "PageToken": $page_token_body, "PageSize": $page_size_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the account IDs that have access to the specified portfolio. A delegated admin can list the accounts that have access to the shared portfolio. Note that if a delegated admin is de-registered, they can no longer perform this operation.
#
# POST /
# operationId: ListPortfolioAccess
export def "list-portfolio-access" [
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
  --x-amz-target: string@x-amz-target-completer-58 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  --organization-parent-id: string # The ID of an organization node the portfolio is shared with. All children of this node with an inherited portfolio share will be returned.
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
  --page-size-body: int # The maximum number of items to return with this call. (body field)
]: any -> oneof<record<AccountIds: list<string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListPortfolioAccess")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "OrganizationParentId": $organization_parent_id, "PageToken": $page_token_body, "PageSize": $page_size_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists all portfolios in the catalog.
#
# POST /
# operationId: ListPortfolios
export def "list-portfolios" [
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
  --x-amz-target: string@x-amz-target-completer-59 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
  --page-size-body: int # The maximum number of items to return with this call. (body field)
]: any -> oneof<record<PortfolioDetails: table<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListPortfolios")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PageToken": $page_token_body, "PageSize": $page_size_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists all portfolios that the specified product is associated with.
#
# POST /
# operationId: ListPortfoliosForProduct
export def "list-portfolios-for-product" [
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
  --x-amz-target: string@x-amz-target-completer-60 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
  --page-size-body: int # The maximum number of items to return with this call. (body field)
]: any -> oneof<record<PortfolioDetails: table<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListPortfoliosForProduct")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "PageToken": $page_token_body, "PageSize": $page_size_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists all PrincipalARNs and corresponding PrincipalTypes associated with the specified portfolio.
#
# POST /
# operationId: ListPrincipalsForPortfolio
export def "list-principals-for-portfolio" [
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
  --x-amz-target: string@x-amz-target-completer-61 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  --page-size-body: int # The maximum number of items to return with this call. (body field)
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
]: any -> oneof<record<Principals: table<PrincipalARN: string, PrincipalType: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListPrincipalsForPortfolio")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "PageSize": $page_size_body, "PageToken": $page_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the plans for the specified provisioned product or all plans to which the user has access.
#
# POST /
# operationId: ListProvisionedProductPlans
export def "list-provisioned-product-plans" [
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
  --x-amz-target: string@x-amz-target-completer-62 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --provision-product-id: string # The product identifier.
  --page-size: int # The maximum number of items to return with this call.
  --page-token: string # The page token for the next set of results. To retrieve the first set of results, use null.
  --access-level-filter: record # The access level to use to filter results. — shape: {Key?: "Account"|"Role"|"User", Value?: string}
]: any -> oneof<record<ProvisionedProductPlans: table<PlanName: string, PlanId: string, ProvisionProductId: string, ProvisionProductName: string, PlanType: string, ProvisioningArtifactId: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListProvisionedProductPlans")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProvisionProductId": $provision_product_id, "PageSize": $page_size, "PageToken": $page_token, "AccessLevelFilter": $access_level_filter} | compact
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

# Lists all provisioning artifacts (also known as versions) for the specified product.
#
# POST /
# operationId: ListProvisioningArtifacts
export def "list-provisioning-artifacts" [
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
  --x-amz-target: string@x-amz-target-completer-63 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
]: any -> oneof<record<ProvisioningArtifactDetails: table<Id: string, Name: string, Description: string, Type: string, CreatedTime: string, Active: bool, Guidance: string, SourceRevision: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListProvisioningArtifacts")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id} | compact
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

# Lists all provisioning artifacts (also known as versions) for the specified self-service action.
#
# POST /
# operationId: ListProvisioningArtifactsForServiceAction
export def "list-provisioning-artifacts-for-service-action" [
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
  --x-amz-target: string@x-amz-target-completer-64 # required
  service_action_id: string # The self-service action identifier. For example, act-fs7abcd89wxyz.
  --page-size-body: int # The maximum number of items to return with this call. (body field)
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record<ProvisioningArtifactViews: table<ProductViewSummary: record, ProvisioningArtifact: record>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListProvisioningArtifactsForServiceAction")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ServiceActionId": $service_action_id, "PageSize": $page_size_body, "PageToken": $page_token_body, "AcceptLanguage": $accept_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the specified requests or all performed requests.
#
# POST /
# operationId: ListRecordHistory
export def "list-record-history" [
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
  --x-amz-target: string@x-amz-target-completer-65 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --access-level-filter: record # The access level to use to filter results. — shape: {Key?: "Account"|"Role"|"User", Value?: string}
  --search-filter: record # The search filter to use when listing history records. — shape: {Key?: string, Value?: string}
  --page-size: int # The maximum number of items to return with this call.
  --page-token: string # The page token for the next set of results. To retrieve the first set of results, use null.
]: any -> oneof<record<RecordDetails: table<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list, RecordTags: list, LaunchRoleArn: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListRecordHistory")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "AccessLevelFilter": $access_level_filter, "SearchFilter": $search_filter, "PageSize": $page_size, "PageToken": $page_token} | compact
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

# Lists the resources associated with the specified TagOption.
#
# POST /
# operationId: ListResourcesForTagOption
export def "list-resources-for-tag-option" [
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
  --x-amz-target: string@x-amz-target-completer-66 # required
  tag_option_id: string # The TagOption identifier.
  --resource-type: string # The resource type. Portfolio Product
  --page-size-body: int # The maximum number of items to return with this call. (body field)
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
]: any -> oneof<record<ResourceDetails: table<Id: string, ARN: string, Name: string, Description: string, CreatedTime: string>, PageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListResourcesForTagOption")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"TagOptionId": $tag_option_id, "ResourceType": $resource_type, "PageSize": $page_size_body, "PageToken": $page_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists all self-service actions.
#
# POST /
# operationId: ListServiceActions
export def "list-service-actions" [
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
  --x-amz-target: string@x-amz-target-completer-67 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --page-size-body: int # The maximum number of items to return with this call. (body field)
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
]: any -> oneof<record<ServiceActionSummaries: table<Id: string, Name: string, Description: string, DefinitionType: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListServiceActions")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PageSize": $page_size_body, "PageToken": $page_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a paginated list of self-service actions associated with the specified Product ID and Provisioning Artifact ID.
#
# POST /
# operationId: ListServiceActionsForProvisioningArtifact
export def "list-service-actions-for-provisioning-artifact" [
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
  --x-amz-target: string@x-amz-target-completer-68 # required
  product_id: string # The product identifier. For example, prod-abcdzk7xy33qa.
  provisioning_artifact_id: string # The identifier of the provisioning artifact. For example, pa-4abcdjnxjj6ne.
  --page-size-body: int # The maximum number of items to return with this call. (body field)
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record<ServiceActionSummaries: table<Id: string, Name: string, Description: string, DefinitionType: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListServiceActionsForProvisioningArtifact")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ProductId": $product_id, "ProvisioningArtifactId": $provisioning_artifact_id, "PageSize": $page_size_body, "PageToken": $page_token_body, "AcceptLanguage": $accept_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns summary information about stack instances that are associated with the specified CFN_STACKSET type provisioned product. You can filter for stack instances that are associated with a specific Amazon Web Services account name or Region.
#
# POST /
# operationId: ListStackInstancesForProvisionedProduct
export def "list-stack-instances-for-provisioned-product" [
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
  --x-amz-target: string@x-amz-target-completer-69 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  provisioned_product_id: string # The identifier of the provisioned product.
  --page-token: string # The page token for the next set of results. To retrieve the first set of results, use null.
  --page-size: int # The maximum number of items to return with this call.
]: any -> oneof<record<StackInstances: table<Account: string, Region: string, StackInstanceStatus: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListStackInstancesForProvisionedProduct")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProvisionedProductId": $provisioned_product_id, "PageToken": $page_token, "PageSize": $page_size} | compact
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

# Lists the specified TagOptions or all TagOptions.
#
# POST /
# operationId: ListTagOptions
export def "list-tag-options" [
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
  --x-amz-target: string@x-amz-target-completer-70 # required
  --filters: record # Filters to use when listing TagOptions. — shape: {Key?: string, Value?: string, Active?: bool}
  --page-size-body: int # The maximum number of items to return with this call. (body field)
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
]: any -> oneof<record<TagOptionDetails: table<Key: string, Value: string, Active: bool, Id: string, Owner: string>, PageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ListTagOptions")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "PageSize": $page_size_body, "PageToken": $page_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Notifies the result of the provisioning engine execution.
#
# POST /
# operationId: NotifyProvisionProductEngineWorkflowResult
export def "notify-provision-product-engine-workflow-result" [
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
  --x-amz-target: string@x-amz-target-completer-71 # required
  workflow_token: string # The encrypted contents of the provisioning engine execution payload that Service Catalog sends after the Terraform product provisioning workflow starts.
  record_id: string # The identifier of the record.
  status: string@status-completer # The status of the provisioning engine execution.
  --failure-reason: string # The reason why the provisioning engine execution failed.
  --resource-identifier: record # The ID for the provisioned product resources that are part of a resource group. — shape: {UniqueTag?: record}
  --outputs: list # The output of the provisioning engine execution. — item shape: {OutputKey?: string, OutputValue?: string, Description?: string}
  idempotency_token: string # The idempotency token that identifies the provisioning engine execution.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.NotifyProvisionProductEngineWorkflowResult")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WorkflowToken": $workflow_token, "RecordId": $record_id, "Status": $status, "FailureReason": $failure_reason, "ResourceIdentifier": $resource_identifier, "Outputs": $outputs, "IdempotencyToken": $idempotency_token} | compact
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

# Notifies the result of the terminate engine execution.
#
# POST /
# operationId: NotifyTerminateProvisionedProductEngineWorkflowResult
export def "notify-terminate-provisioned-product-engine-workflow-result" [
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
  --x-amz-target: string@x-amz-target-completer-72 # required
  workflow_token: string # The encrypted contents of the terminate engine execution payload that Service Catalog sends after the Terraform product terminate workflow starts.
  record_id: string # The identifier of the record.
  status: string@status-completer # The status of the terminate engine execution.
  --failure-reason: string # The reason why the terminate engine execution failed.
  idempotency_token: string # The idempotency token that identifies the terminate engine execution.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.NotifyTerminateProvisionedProductEngineWorkflowResult")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WorkflowToken": $workflow_token, "RecordId": $record_id, "Status": $status, "FailureReason": $failure_reason, "IdempotencyToken": $idempotency_token} | compact
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

# Notifies the result of the update engine execution.
#
# POST /
# operationId: NotifyUpdateProvisionedProductEngineWorkflowResult
export def "notify-update-provisioned-product-engine-workflow-result" [
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
  --x-amz-target: string@x-amz-target-completer-73 # required
  workflow_token: string # The encrypted contents of the update engine execution payload that Service Catalog sends after the Terraform product update workflow starts.
  record_id: string # The identifier of the record.
  status: string@status-completer # The status of the update engine execution.
  --failure-reason: string # The reason why the update engine execution failed.
  --outputs: list # The output of the update engine execution. — item shape: {OutputKey?: string, OutputValue?: string, Description?: string}
  idempotency_token: string # The idempotency token that identifies the update engine execution.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.NotifyUpdateProvisionedProductEngineWorkflowResult")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WorkflowToken": $workflow_token, "RecordId": $record_id, "Status": $status, "FailureReason": $failure_reason, "Outputs": $outputs, "IdempotencyToken": $idempotency_token} | compact
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

# Provisions the specified product. A provisioned product is a resourced instance of a product. For example, provisioning a product that's based on an CloudFormation template launches an CloudFormation stack and its underlying resources. You can check the status of this request using DescribeRecord. If the request contains a tag key with an empty list of values, there's a tag conflict for that key. Don't include conflicted keys as tags, or this will cause the error "Parameter validation failed: Missing required parameter in Tags[N]:Value". When provisioning a product that's been added to a portfolio, you must grant your user, group, or role access to the portfolio. For more information, see Granting users access (https://docs.aws.amazon.com/servicecatalog/latest/adminguide/catalogs_portfolios_users.html) in the Service Catalog User Guide.
#
# POST /
# operationId: ProvisionProduct
export def "provision-product" [
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
  --x-amz-target: string@x-amz-target-completer-74 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --product-id: string # The product identifier. You must provide the name or ID, but not both.
  --product-name: string # The name of the product. You must provide the name or ID, but not both.
  --provisioning-artifact-id: string # The identifier of the provisioning artifact. You must provide the name or ID, but not both.
  --provisioning-artifact-name: string # The name of the provisioning artifact. You must provide the name or ID, but not both.
  --path-id: string # The path identifier of the product. This value is optional if the product has a default path, and required if the product has more than one path. To list the paths for a product, use ListLaunchPaths. You must provide the name or ID, but not both.
  --path-name: string # The name of the path. You must provide the name or ID, but not both.
  provisioned_product_name: string # A user-friendly name for the provisioned product. This value must be unique for the Amazon Web Services account and cannot be updated after the product is provisioned.
  --provisioning-parameters: list # Parameters specified by the administrator that are required for provisioning the product. — item shape: {Key?: string, Value?: string}
  --provisioning-preferences: record # The user-defined preferences that will be applied when updating a provisioned product. Not all preferences are applicable to all provisioned product type One or more Amazon Web Services accounts that will have access to the provisioned product. Applicable only to a CFN_STACKSET provisioned product type. The Amazon Web Services accounts specified should be within the list of accounts in the STACKSET constraint. To get the list of accounts in the STACKSET constraint, use the DescribeProvisioningParameters operation. If no values are specified, the default value is all accounts from the STACKSET constraint. — shape: {StackSetAccounts?: list<string>, StackSetRegions?: list<string>, StackSetFailureToleranceCount?: int, StackSetFailureTolerancePercentage?: int, StackSetMaxConcurrencyCount?: int, StackSetMaxConcurrencyPercentage?: int}
  --tags: list # One or more tags. — item shape: {Key: string, Value: string}
  --notification-arns: list<string> # Passed to CloudFormation. The SNS topic ARNs to which to publish stack-related events.
  provision_token: string # An idempotency token that uniquely identifies the provisioning request.
]: any -> oneof<record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ProvisionProduct")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "ProductName": $product_name, "ProvisioningArtifactId": $provisioning_artifact_id, "ProvisioningArtifactName": $provisioning_artifact_name, "PathId": $path_id, "PathName": $path_name, "ProvisionedProductName": $provisioned_product_name, "ProvisioningParameters": $provisioning_parameters, "ProvisioningPreferences": $provisioning_preferences, "Tags": $tags, "NotificationArns": $notification_arns, "ProvisionToken": $provision_token} | compact
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

# Rejects an offer to share the specified portfolio.
#
# POST /
# operationId: RejectPortfolioShare
export def "reject-portfolio-share" [
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
  --x-amz-target: string@x-amz-target-completer-75 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The portfolio identifier.
  --portfolio-share-type: string@portfolio-share-type-completer # The type of shared portfolios to reject. The default is to reject imported portfolios. AWS_ORGANIZATIONS - Reject portfolios shared by the management account of your organization. IMPORTED - Reject imported portfolios. AWS_SERVICECATALOG - Not supported. (Throws ResourceNotFoundException.) For example, aws servicecatalog reject-portfolio-share --portfolio-id "port-2qwzkwxt3y5fk" --portfolio-share-type AWS_ORGANIZATIONS
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.RejectPortfolioShare")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "PortfolioShareType": $portfolio_share_type} | compact
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

# Lists the provisioned products that are available (not terminated). To use additional filtering, see SearchProvisionedProducts.
#
# POST /
# operationId: ScanProvisionedProducts
export def "scan-provisioned-products" [
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
  --x-amz-target: string@x-amz-target-completer-76 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --access-level-filter: record # The access level to use to filter results. — shape: {Key?: "Account"|"Role"|"User", Value?: string}
  --page-size: int # The maximum number of items to return with this call.
  --page-token: string # The page token for the next set of results. To retrieve the first set of results, use null.
]: any -> oneof<record<ProvisionedProducts: table<Name: string, Arn: string, Type: string, Id: string, Status: string, StatusMessage: string, CreatedTime: string, IdempotencyToken: string, LastRecordId: string, LastProvisioningRecordId: string, LastSuccessfulProvisioningRecordId: string, ProductId: string, ProvisioningArtifactId: string, LaunchRoleArn: string>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.ScanProvisionedProducts")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "AccessLevelFilter": $access_level_filter, "PageSize": $page_size, "PageToken": $page_token} | compact
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

# Gets information about the products to which the caller has access.
#
# POST /
# operationId: SearchProducts
export def "search-products" [
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
  --x-amz-target: string@x-amz-target-completer-77 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --filters: record # The search filters. If no search filters are specified, the output includes all products to which the caller has access.
  --page-size-body: int # The maximum number of items to return with this call. (body field)
  --sort-by: string@sort-by-completer # The sort field. If no value is specified, the results are not sorted.
  --sort-order: string@sort-order-completer # The sort order. If no value is specified, the results are not sorted.
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
]: any -> oneof<record<ProductViewSummaries: table<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, ProductViewAggregations: record, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.SearchProducts")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "Filters": $filters, "PageSize": $page_size_body, "SortBy": $sort_by, "SortOrder": $sort_order, "PageToken": $page_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets information about the products for the specified portfolio or all products.
#
# POST /
# operationId: SearchProductsAsAdmin
export def "search-products-as-admin" [
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
  --x-amz-target: string@x-amz-target-completer-78 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --portfolio-id: string # The portfolio identifier.
  --filters: record # The search filters. If no search filters are specified, the output includes all products to which the administrator has access.
  --sort-by: string@sort-by-completer # The sort field. If no value is specified, the results are not sorted.
  --sort-order: string@sort-order-completer # The sort order. If no value is specified, the results are not sorted.
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
  --page-size-body: int # The maximum number of items to return with this call. (body field)
  --product-source: string@product-source-completer # Access level of the source of the product.
]: any -> oneof<record<ProductViewDetails: table<ProductViewSummary: record, Status: string, ProductARN: string, CreatedTime: string, SourceConnection: record>, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.SearchProductsAsAdmin")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "Filters": $filters, "SortBy": $sort_by, "SortOrder": $sort_order, "PageToken": $page_token_body, "PageSize": $page_size_body, "ProductSource": $product_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets information about the provisioned products that meet the specified criteria.
#
# POST /
# operationId: SearchProvisionedProducts
export def "search-provisioned-products" [
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
  --x-amz-target: string@x-amz-target-completer-79 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --access-level-filter: record # The access level to use to filter results. — shape: {Key?: "Account"|"Role"|"User", Value?: string}
  --filters: record # The search filters. When the key is SearchQuery, the searchable fields are arn, createdTime, id, lastRecordId, idempotencyToken, name, physicalId, productId, provisioningArtifact, type, status, tags, userArn, userArnSession, lastProvisioningRecordId, lastSuccessfulProvisioningRecordId, productName, and provisioningArtifactName. Example: "SearchQuery":["status:AVAILABLE"]
  --sort-by: string # The sort field. If no value is specified, the results are not sorted. The valid values are arn, id, name, and lastRecordId.
  --sort-order: string@sort-order-completer # The sort order. If no value is specified, the results are not sorted.
  --page-size-body: int # The maximum number of items to return with this call. (body field)
  --page-token-body: string # The page token for the next set of results. To retrieve the first set of results, use null. (body field)
]: any -> oneof<record<ProvisionedProducts: table<Name: string, Arn: string, Type: string, Id: string, Status: string, StatusMessage: string, CreatedTime: string, IdempotencyToken: string, LastRecordId: string, LastProvisioningRecordId: string, LastSuccessfulProvisioningRecordId: string, Tags: list, PhysicalId: string, ProductId: string, ProductName: string, ProvisioningArtifactId: string, ProvisioningArtifactName: string, UserArn: string, UserArnSession: string>, TotalResultsCount: int, NextPageToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.SearchProvisionedProducts")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "AccessLevelFilter": $access_level_filter, "Filters": $filters, "SortBy": $sort_by, "SortOrder": $sort_order, "PageSize": $page_size_body, "PageToken": $page_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"PageSize": $page_size, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Terminates the specified provisioned product. This operation does not delete any records associated with the provisioned product. You can check the status of this request using DescribeRecord.
#
# POST /
# operationId: TerminateProvisionedProduct
export def "terminate-provisioned-product" [
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
  --x-amz-target: string@x-amz-target-completer-80 # required
  --provisioned-product-name: string # The name of the provisioned product. You cannot specify both ProvisionedProductName and ProvisionedProductId.
  --provisioned-product-id: string # The identifier of the provisioned product. You cannot specify both ProvisionedProductName and ProvisionedProductId.
  terminate_token: string # An idempotency token that uniquely identifies the termination request. This token is only valid during the termination process. After the provisioned product is terminated, subsequent requests to terminate the same provisioned product always return ResourceNotFound.
  --ignore-errors: oneof<nothing, bool> # If set to true, Service Catalog stops managing the specified provisioned product even if it cannot delete the underlying resources.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --retain-physical-resources: oneof<nothing, bool> # When this boolean parameter is set to true, the TerminateProvisionedProduct API deletes the Service Catalog provisioned product. However, it does not remove the CloudFormation stack, stack set, or the underlying resources of the deleted provisioned product. The default value is false.
]: any -> oneof<record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.TerminateProvisionedProduct")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ProvisionedProductName": $provisioned_product_name, "ProvisionedProductId": $provisioned_product_id, "TerminateToken": $terminate_token, "IgnoreErrors": $ignore_errors, "AcceptLanguage": $accept_language, "RetainPhysicalResources": $retain_physical_resources} | compact
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

# Updates the specified constraint.
#
# POST /
# operationId: UpdateConstraint
export def "update-constraint" [
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
  --x-amz-target: string@x-amz-target-completer-81 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The identifier of the constraint.
  --description: string # The updated description of the constraint.
  --parameters: string # The constraint parameters, in JSON format. The syntax depends on the constraint type as follows: LAUNCH You are required to specify either the RoleArn or the LocalRoleName but can't use both. Specify the RoleArn property as follows: {"RoleArn" : "arn:aws:iam::123456789012:role/LaunchRole"} Specify the LocalRoleName property as follows: {"LocalRoleName": "SCBasicLaunchRole"} If you specify the LocalRoleName property, when an account uses the launch constraint, the IAM role with that name in the account will be used. This allows launch-role constraints to be account-agnostic so the administrator can create fewer resources per shared account. The given role name must exist in the account used to create the launch constraint and the account of the user who launches a product with this launch constraint. You cannot have both a LAUNCH and a STACKSET constraint. You also cannot have more than one LAUNCH constraint on a product and portfolio. NOTIFICATION Specify the NotificationArns property as follows: {"NotificationArns" : ["arn:aws:sns:us-east-1:123456789012:Topic"]} RESOURCE_UPDATE Specify the TagUpdatesOnProvisionedProduct property as follows: {"Version":"2.0","Properties":{"TagUpdateOnProvisionedProduct":"String"}} The TagUpdatesOnProvisionedProduct property accepts a string value of ALLOWED or NOT_ALLOWED. STACKSET Specify the Parameters property as follows: {"Version": "String", "Properties": {"AccountList": [ "String" ], "RegionList": [ "String" ], "AdminRole": "String", "ExecutionRole": "String"}} You cannot have both a LAUNCH and a STACKSET constraint. You also cannot have more than one STACKSET constraint on a product and portfolio. Products with a STACKSET constraint will launch an CloudFormation stack set. TEMPLATE Specify the Rules property. For more information, see Template Constraint Rules (http://docs.aws.amazon.com/servicecatalog/latest/adminguide/reference-template_constraint_rules.html).
]: any -> oneof<record<ConstraintDetail: record<ConstraintId: string, Type: string, Description: string, Owner: string, ProductId: string, PortfolioId: string>, ConstraintParameters: string, Status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.UpdateConstraint")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id, "Description": $description, "Parameters": $parameters} | compact
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

# Updates the specified portfolio. You cannot update a product that was shared with you.
#
# POST /
# operationId: UpdatePortfolio
export def "update-portfolio" [
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
  --x-amz-target: string@x-amz-target-completer-82 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The portfolio identifier.
  --display-name: string # The name to use for display purposes.
  --description: string # The updated description of the portfolio.
  --provider-name: string # The updated name of the portfolio provider.
  --add-tags: list # The tags to add. — item shape: {Key: string, Value: string}
  --remove-tags: list<string> # The tags to remove.
]: any -> oneof<record<PortfolioDetail: record<Id: string, ARN: string, DisplayName: string, Description: string, CreatedTime: string, ProviderName: string>, Tags: table<Key: string, Value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.UpdatePortfolio")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id, "DisplayName": $display_name, "Description": $description, "ProviderName": $provider_name, "AddTags": $add_tags, "RemoveTags": $remove_tags} | compact
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

# Updates the specified portfolio share. You can use this API to enable or disable TagOptions sharing or Principal sharing for an existing portfolio share. The portfolio share cannot be updated if the CreatePortfolioShare operation is IN_PROGRESS, as the share is not available to recipient entities. In this case, you must wait for the portfolio share to be COMPLETED. You must provide the accountId or organization node in the input, but not both. If the portfolio is shared to both an external account and an organization node, and both shares need to be updated, you must invoke UpdatePortfolioShare separately for each share type. This API cannot be used for removing the portfolio share. You must use DeletePortfolioShare API for that action. When you associate a principal with portfolio, a potential privilege escalation path may occur when that portfolio is then shared with other accounts. For a user in a recipient account who is not an Service Catalog Admin, but still has the ability to create Principals (Users/Groups/Roles), that user could create a role that matches a principal name association for the portfolio. Although this user may not know which principal names are associated through Service Catalog, they may be able to guess the user. If this potential escalation path is a concern, then Service Catalog recommends using PrincipalType as IAM. With this configuration, the PrincipalARN must already exist in the recipient account before it can be associated.
#
# POST /
# operationId: UpdatePortfolioShare
export def "update-portfolio-share" [
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
  --x-amz-target: string@x-amz-target-completer-83 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  portfolio_id: string # The unique identifier of the portfolio for which the share will be updated.
  --account-id: string # The Amazon Web Services account Id of the recipient account. This field is required when updating an external account to account type share.
  --organization-node: record # Information about the organization node. — shape: {Type?: "ORGANIZATION"|"ORGANIZATIONAL_UNIT"|"ACCOUNT", Value?: string}
  --share-tag-options: oneof<nothing, bool> # Enables or disables TagOptions sharing for the portfolio share. If this field is not provided, the current state of TagOptions sharing on the portfolio share will not be modified.
  --share-principals: oneof<nothing, bool> # A flag to enables or disables Principals sharing in the portfolio. If this field is not provided, the current state of the Principals sharing on the portfolio share will not be modified.
]: any -> oneof<record<PortfolioShareToken: string, Status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.UpdatePortfolioShare")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "PortfolioId": $portfolio_id, "AccountId": $account_id, "OrganizationNode": $organization_node, "ShareTagOptions": $share_tag_options, "SharePrincipals": $share_principals} | compact
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

# Updates the specified product.
#
# POST /
# operationId: UpdateProduct
export def "update-product" [
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
  --x-amz-target: string@x-amz-target-completer-84 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  id: string # The product identifier.
  --name: string # The updated product name.
  --owner: string # The updated owner of the product.
  --description: string # The updated description of the product.
  --distributor: string # The updated distributor of the product.
  --support-description: string # The updated support description for the product.
  --support-email: string # The updated support email for the product.
  --support-url: string # The updated support URL for the product.
  --add-tags: list # The tags to add to the product. — item shape: {Key: string, Value: string}
  --remove-tags: list<string> # The tags to remove from the product.
  --source-connection: record # A top level ProductViewDetail response containing details about the product’s connection. Service Catalog returns this field for the CreateProduct, UpdateProduct, DescribeProductAsAdmin, and SearchProductAsAdmin APIs. This response contains the same fields as the ConnectionParameters request, with the addition of the LastSync response. — shape: {Type?: "CODESTAR", ConnectionParameters: record}
]: any -> oneof<record<ProductViewDetail: record<ProductViewSummary: record<Id: string, ProductId: string, Name: string, Owner: string, ShortDescription: string, Type: string, Distributor: string, HasDefaultPath: bool, SupportEmail: string, SupportDescription: string, SupportUrl: string>, Status: string, ProductARN: string, CreatedTime: string, SourceConnection: record<Type: string, ConnectionParameters: record, LastSync: record>>, Tags: table<Key: string, Value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.UpdateProduct")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "Id": $id, "Name": $name, "Owner": $owner, "Description": $description, "Distributor": $distributor, "SupportDescription": $support_description, "SupportEmail": $support_email, "SupportUrl": $support_url, "AddTags": $add_tags, "RemoveTags": $remove_tags, "SourceConnection": $source_connection} | compact
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

# Requests updates to the configuration of the specified provisioned product. If there are tags associated with the object, they cannot be updated or added. Depending on the specific updates requested, this operation can update with no interruption, with some interruption, or replace the provisioned product entirely. You can check the status of this request using DescribeRecord.
#
# POST /
# operationId: UpdateProvisionedProduct
export def "update-provisioned-product" [
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
  --x-amz-target: string@x-amz-target-completer-85 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  --provisioned-product-name: string # The name of the provisioned product. You cannot specify both ProvisionedProductName and ProvisionedProductId.
  --provisioned-product-id: string # The identifier of the provisioned product. You must provide the name or ID, but not both.
  --product-id: string # The identifier of the product. You must provide the name or ID, but not both.
  --product-name: string # The name of the product. You must provide the name or ID, but not both.
  --provisioning-artifact-id: string # The identifier of the provisioning artifact.
  --provisioning-artifact-name: string # The name of the provisioning artifact. You must provide the name or ID, but not both.
  --path-id: string # The path identifier. This value is optional if the product has a default path, and required if the product has more than one path. You must provide the name or ID, but not both.
  --path-name: string # The name of the path. You must provide the name or ID, but not both.
  --provisioning-parameters: list # The new parameters. — item shape: {Key?: string, Value?: string, UsePreviousValue?: bool}
  --provisioning-preferences: record # The user-defined preferences that will be applied when updating a provisioned product. Not all preferences are applicable to all provisioned product types. — shape: {StackSetAccounts?: list<string>, StackSetRegions?: list<string>, StackSetFailureToleranceCount?: int, StackSetFailureTolerancePercentage?: int, StackSetMaxConcurrencyCount?: int, StackSetMaxConcurrencyPercentage?: int, StackSetOperationType?: "CREATE"|"UPDATE"|"DELETE"}
  --tags: list # One or more tags. Requires the product to have RESOURCE_UPDATE constraint with TagUpdatesOnProvisionedProduct set to ALLOWED to allow tag updates. — item shape: {Key: string, Value: string}
  update_token: string # The idempotency token that uniquely identifies the provisioning update request.
]: any -> oneof<record<RecordDetail: record<RecordId: string, ProvisionedProductName: string, Status: string, CreatedTime: string, UpdatedTime: string, ProvisionedProductType: string, RecordType: string, ProvisionedProductId: string, ProductId: string, ProvisioningArtifactId: string, PathId: string, RecordErrors: list<record>, RecordTags: list<record>, LaunchRoleArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.UpdateProvisionedProduct")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProvisionedProductName": $provisioned_product_name, "ProvisionedProductId": $provisioned_product_id, "ProductId": $product_id, "ProductName": $product_name, "ProvisioningArtifactId": $provisioning_artifact_id, "ProvisioningArtifactName": $provisioning_artifact_name, "PathId": $path_id, "PathName": $path_name, "ProvisioningParameters": $provisioning_parameters, "ProvisioningPreferences": $provisioning_preferences, "Tags": $tags, "UpdateToken": $update_token} | compact
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

# Requests updates to the properties of the specified provisioned product.
#
# POST /
# operationId: UpdateProvisionedProductProperties
export def "update-provisioned-product-properties" [
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
  --x-amz-target: string@x-amz-target-completer-86 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  provisioned_product_id: string # The identifier of the provisioned product.
  provisioned_product_properties: record # A map that contains the provisioned product properties to be updated. The LAUNCH_ROLE key accepts role ARNs. This key allows an administrator to call UpdateProvisionedProductProperties to update the launch role that is associated with a provisioned product. This role is used when an end user calls a provisioning operation such as UpdateProvisionedProduct, TerminateProvisionedProduct, or ExecuteProvisionedProductServiceAction. Only a role ARN is valid. A user ARN is invalid. The OWNER key accepts user ARNs, IAM role ARNs, and STS assumed-role ARNs. The owner is the user that has permission to see, update, terminate, and execute service actions in the provisioned product. The administrator can change the owner of a provisioned product to another IAM or STS entity within the same account. Both end user owners and administrators can see ownership history of the provisioned product using the ListRecordHistory API. The new owner can describe all past records for the provisioned product using the DescribeRecord API. The previous owner can no longer use DescribeRecord, but can still see the product's history from when he was an owner using ListRecordHistory. If a provisioned product ownership is assigned to an end user, they can see and perform any action through the API or Service Catalog console such as update, terminate, and execute service actions. If an end user provisions a product and the owner is updated to someone else, they will no longer be able to see or perform any actions through API or the Service Catalog console on that provisioned product.
  idempotency_token: string # The idempotency token that uniquely identifies the provisioning product update request.
]: any -> oneof<record<ProvisionedProductId: string, ProvisionedProductProperties: record, RecordId: string, Status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.UpdateProvisionedProductProperties")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProvisionedProductId": $provisioned_product_id, "ProvisionedProductProperties": $provisioned_product_properties, "IdempotencyToken": $idempotency_token} | compact
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

# Updates the specified provisioning artifact (also known as a version) for the specified product. You cannot update a provisioning artifact for a product that was shared with you.
#
# POST /
# operationId: UpdateProvisioningArtifact
export def "update-provisioning-artifact" [
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
  --x-amz-target: string@x-amz-target-completer-87 # required
  --accept-language: string # The language code. jp - Japanese zh - Chinese
  product_id: string # The product identifier.
  provisioning_artifact_id: string # The identifier of the provisioning artifact.
  --name: string # The updated name of the provisioning artifact.
  --description: string # The updated description of the provisioning artifact.
  --active: oneof<nothing, bool> # Indicates whether the product version is active. Inactive provisioning artifacts are invisible to end users. End users cannot launch or update a provisioned product from an inactive provisioning artifact.
  --guidance: string@guidance-completer # Information set by the administrator to provide guidance to end users about which provisioning artifacts to use. The DEFAULT value indicates that the product version is active. The administrator can set the guidance to DEPRECATED to inform users that the product version is deprecated. Users are able to make updates to a provisioned product of a deprecated version but cannot launch new provisioned products using a deprecated version.
]: any -> oneof<record<ProvisioningArtifactDetail: record<Id: string, Name: string, Description: string, Type: string, CreatedTime: string, Active: bool, Guidance: string, SourceRevision: string>, Info: record, Status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.UpdateProvisioningArtifact")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AcceptLanguage": $accept_language, "ProductId": $product_id, "ProvisioningArtifactId": $provisioning_artifact_id, "Name": $name, "Description": $description, "Active": $active, "Guidance": $guidance} | compact
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

# Updates a self-service action.
#
# POST /
# operationId: UpdateServiceAction
export def "update-service-action" [
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
  --x-amz-target: string@x-amz-target-completer-88 # required
  id: string # The self-service action identifier.
  --name: string # The self-service action name.
  --definition: record # A map that defines the self-service action.
  --description: string # The self-service action description.
  --accept-language: string # The language code. jp - Japanese zh - Chinese
]: any -> oneof<record<ServiceActionDetail: record<ServiceActionSummary: record<Id: string, Name: string, Description: string, DefinitionType: string>, Definition: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.UpdateServiceAction")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Id": $id, "Name": $name, "Definition": $definition, "Description": $description, "AcceptLanguage": $accept_language} | compact
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

# Updates the specified TagOption.
#
# POST /
# operationId: UpdateTagOption
export def "update-tag-option" [
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
  --x-amz-target: string@x-amz-target-completer-89 # required
  id: string # The TagOption identifier.
  --value: string # The updated value.
  --active: oneof<nothing, bool> # The updated active state.
]: any -> oneof<record<TagOptionDetail: record<Key: string, Value: string, Active: bool, Id: string, Owner: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWS242ServiceCatalogService.UpdateTagOption")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Id": $id, "Value": $value, "Active": $active} | compact
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
