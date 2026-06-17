# Auto-generated client for Portfolio Optimizer v1.0.9
# Source: https://api.apis.guru/v2/specs/portfoliooptimizer.io/1.0.9/openapi.json
# Auth: --token flag or $env.PORTFOLIO_OPTIMIZER_TOKEN

const BASE_URL = "https://api.portfoliooptimizer.io/v1"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PORTFOLIO_OPTIMIZER_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.portfoliooptimizer.io/v1" "https://eu-west-1.api.portfoliooptimizer.io/v1"] }
def auth-scheme-completer [] { ["x-api-key"] }

# Completers for enum parameters
def denoising-method-completer [] { ["eigenvaluesClipping"] }
def distance-metric-completer [] { ["bures" "correlationMatrix" "euclidean"] }
def target-equicorrelation-matrix-completer [] { ["maximumEquicorrelationMatrix" "minimumEquicorrelationMatrix" "zeroEquicorrelationMatrix"] }
def clustering-method-completer [] { ["averageLinkage" "completeLinkage" "singleLinkage" "wardLinkage"] }
def bootstrap-method-completer [] { ["circularBlock" "iid" "stationaryBlock"] }
def factors-extraction-method-completer [] { ["approximateMinimumLinearTorsion" "exactMinimumLinearTorsion" "principalComponentAnalysis"] }
def confidence-interval-type-completer [] { ["lowerOneSided" "twoSided" "upperOneSided"] }
def clustering-ordering-completer [] { ["optimal" "r-hclust"] }
def across-cluster-allocation-method-completer [] { ["equalWeighting" "inverseVariance" "inverseVolatility"] }
def within-cluster-allocation-method-completer [] { ["equalWeighting" "inverseVariance" "inverseVolatility"] }
def subset-portfolios-aggregation-method-completer [] { ["average" "median"] }
def subset-portfolios-enumeration-method-completer [] { ["complete" "randomSampling"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "assets-analysis-absorption-ratio post" } } | get name | first)
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

# Absorption Ratio
#
# POST /assets/analysis/absorption-ratio
# --assetsCovarianceMatrixEigenvectors shape: {eigenvectorsRetained?: int}
export def "assets-analysis-absorption-ratio post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-covariance-matrix-eigenvectors: record # shape: {eigenvectorsRetained?: int}
]: any -> record<assetsAbsorptionRatio: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/analysis/absorption-ratio")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsCovarianceMatrixEigenvectors": $assets_covariance_matrix_eigenvectors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Turbulence Index
#
# POST /assets/analysis/turbulence-index
export def "assets-analysis-turbulence-index post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_average_returns: list # assetsAverageReturns[i] is the average return of asset i over an historical reference period
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j over an historical reference period
  assets_returns: list # assetsReturns[i] is the return of asset i over a period different from the historical reference period
]: any -> record<assetsTurbulenceIndex: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/analysis/turbulence-index")
  let body = {"assets": $assets, "assetsAverageReturns": $assets_average_returns, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Correlation Matrix
#
# POST /assets/correlation/matrix
# --assets item shape: {assetReturns: list}
export def "assets-correlation-matrix post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: list # item shape: {assetReturns: list}
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> record<assetsCorrelationMatrix: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Correlation Matrix Bounds
#
# POST /assets/correlation/matrix/bounds
export def "assets-correlation-matrix-bounds post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  assets_group: list # assetsGroup[k] is the indexes of the assets belonging to the assets group
]: any -> record<assetsCorrelationMatrixLowerBounds: list<list<float>>, assetsCorrelationMatrixUpperBounds: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/bounds")
  let body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "assetsGroup": $assets_group} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Denoised Correlation Matrix
#
# POST /assets/correlation/matrix/denoised
export def "assets-correlation-matrix-denoised post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  assets_correlation_matrix_aspect_ratio: float # The aspect ratio of the asset correlation matrix, defined as the number of assets divided by the number of asset returns per asset used to compute the asset correlation matrix
  --denoising-method: string@denoising-method-completer # The method used to denoise the asset correlation matrix (default: eigenvaluesClipping)
]: any -> record<assetsCorrelationMatrix: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/denoised")
  let body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "assetsCorrelationMatrixAspectRatio": $assets_correlation_matrix_aspect_ratio, "denoisingMethod": $denoising_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Correlation Matrix Distance
#
# POST /assets/correlation/matrix/distance
export def "assets-correlation-matrix-distance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --distance-metric: string@distance-metric-completer # The distance metric to use to compute the distance between the asset correlation matrix and the reference correlation matrix (default: euclidean)
  reference_correlation_matrix: list # referenceCorrelationMatrix[i][j] is the reference correlation between the asset i and the asset j
]: any -> record<assetsCorrelationMatrixDistance: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/distance")
  let body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "distanceMetric": $distance_metric, "referenceCorrelationMatrix": $reference_correlation_matrix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Correlation Matrix Effective Rank
#
# POST /assets/correlation/matrix/effective-rank
export def "assets-correlation-matrix-effective-rank post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
]: any -> record<assetsCorrelationMatrixEffectiveRank: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/effective-rank")
  let body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Correlation Matrix Informativeness
#
# POST /assets/correlation/matrix/informativeness
export def "assets-correlation-matrix-informativeness post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --distance-metric: string@distance-metric-completer # The distance metric to use to compute the informativeness of the asset correlation matrix (default: euclidean)
]: any -> record<assetsCorrelationMatrixInformativeness: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/informativeness")
  let body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "distanceMetric": $distance_metric} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Nearest Correlation Matrix
#
# POST /assets/correlation/matrix/nearest
export def "assets-correlation-matrix-nearest post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_approximate_correlation_matrix: list # assetsApproximateCorrelationMatrix[i][i] is the approximate correlation between the asset i and the asset j
  --assets-fixed-correlations: list # assetsFixedCorrelations[k] is the couple of indices (i,j) of the assets i and j for which to keep the approximate correlation assetsApproximateCorrelationMatrix[i][j] fixed
]: any -> record<assetsCorrelationMatrix: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/nearest")
  let body = {"assets": $assets, "assetsApproximateCorrelationMatrix": $assets_approximate_correlation_matrix, "assetsFixedCorrelations": $assets_fixed_correlations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Random Correlation Matrix
#
# POST /assets/correlation/matrix/random
export def "assets-correlation-matrix-random post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
]: any -> record<assetsCorrelationMatrix: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/random")
  let body = {"assets": $assets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Correlation Matrix Shrinkage
#
# POST /assets/correlation/matrix/shrinkage
export def "assets-correlation-matrix-shrinkage post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: int
  --assets-correlation-matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --shrinkage-factor: float # The shrinkage factor
  --target-equicorrelation-matrix: string@target-equicorrelation-matrix-completer # The shrinkage target correlation matrix
  --target-correlation-matrix: list # targetCorrelationMatrix[i][j] is the target correlation between the asset i and the asset j
]: any -> record<assetsCorrelationMatrix: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/shrinkage")
  let body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "shrinkageFactor": $shrinkage_factor, "targetEquicorrelationMatrix": $target_equicorrelation_matrix, "targetCorrelationMatrix": $target_correlation_matrix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Theory-Implied Correlation Matrix
#
# POST /assets/correlation/matrix/theory-implied
# --assets item shape: {assetHierarchicalClassification: list}
export def "assets-correlation-matrix-theory-implied post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetHierarchicalClassification: list}
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --clustering-method: string@clustering-method-completer # The hierarchical clustering method to use (default: averageLinkage)
]: any -> record<assetsCorrelationMatrix: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/theory-implied")
  let body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "clusteringMethod": $clustering_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Correlation Matrix Validation
#
# POST /assets/correlation/matrix/validation
export def "assets-correlation-matrix-validation post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/validation")
  let body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Covariance Matrix
#
# POST /assets/covariance/matrix
# --assets item shape: {assetReturns: list}
export def "assets-covariance-matrix post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: list # item shape: {assetReturns: list}
  --assets-correlation-matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --assets-variances: list # assetsVariances[i] is the variance of the asset i
  --assets-volatilities: list # assetsVolatilities[i] is the volatility of the asset i
]: any -> record<assetsCovarianceMatrix: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/covariance/matrix")
  let body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "assetsVariances": $assets_variances, "assetsVolatilities": $assets_volatilities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Covariance Matrix Effective Rank
#
# POST /assets/covariance/matrix/effective-rank
export def "assets-covariance-matrix-effective-rank post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> record<assetsCovarianceMatrixEffectiveRank: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/covariance/matrix/effective-rank")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Exponentially Weighted Covariance Matrix
#
# POST /assets/covariance/matrix/exponentially-weighted
# --assets item shape: {assetReturns: list}
export def "assets-covariance-matrix-exponentially-weighted post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list}
  --decay-factor: float # The exponential decay factor (default: 0.94)
]: any -> record<assetsCovarianceMatrix: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/covariance/matrix/exponentially-weighted")
  let body = {"assets": $assets, "decayFactor": $decay_factor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Covariance Matrix Validation
#
# POST /assets/covariance/matrix/validation
export def "assets-covariance-matrix-validation post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/covariance/matrix/validation")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Kurtosis
#
# POST /assets/kurtosis
# --assets item shape: {assetReturns: list}
export def "assets-kurtosis post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list}
]: any -> record<assets: table<assetKurtosis: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/kurtosis")
  let body = {"assets": $assets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adjusted Prices
#
# POST /assets/prices/adjusted
# --assets item shape: {assetDividends?: list, assetPrices: list, assetSplits?: list}
export def "assets-prices-adjusted post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetDividends?: list, assetPrices: list, assetSplits?: list}
]: any -> record<assets: table<assetAdjustedPrices: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/prices/adjusted")
  let body = {"assets": $assets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Forward-Adjusted Prices
#
# POST /assets/prices/adjusted/forward
# --assets item shape: {assetDividends?: list, assetPrices: list, assetSplits?: list}
export def "assets-prices-adjusted-forward post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetDividends?: list, assetPrices: list, assetSplits?: list}
]: any -> record<assets: table<assetAdjustedPrices: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/prices/adjusted/forward")
  let body = {"assets": $assets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Arithmetic Returns
#
# POST /assets/returns
# --assets item shape: {assetPrices: list}
export def "assets-returns post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list}
]: any -> record<assets: table<assetReturns: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/returns")
  let body = {"assets": $assets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Arithmetic Average Return
#
# POST /assets/returns/average
# --assets item shape: {assetReturns: list}
export def "assets-returns-average post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list}
]: any -> record<assets: table<assetAverageReturn: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/returns/average")
  let body = {"assets": $assets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Bootstrap
#
# POST /assets/returns/simulation/bootstrap
# --assets item shape: {assetReturns: list}
export def "assets-returns-simulation-bootstrap post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list}
  --bootstrap-average-block-length: float # The average length of the blocks to use in case the bootstrap method is 'stationaryBlock', in time periods; if not provided, defaults to the inverse of 3.15 * the common length of the assetReturns arrays^1/3
  --bootstrap-block-length: int # The length of the blocks to use in case the bootstrap method is 'circularBlock', in time periods; if not provided, defaults to [3.15 * the common length of the assetReturns arrays^1/3]
  --bootstrap-method: string@bootstrap-method-completer # The bootstrap method to use (default: stationaryBlock)
  --simulations: int # The number of simulations to perform (default: 25)
  --simulations-length: int # The number of time period(s) to simulate per simulation; if not provided, defaults to the common length of the assetReturns arrays
]: any -> record<simulations: table<assets: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/returns/simulation/bootstrap")
  let body = {"assets": $assets, "bootstrapAverageBlockLength": $bootstrap_average_block_length, "bootstrapBlockLength": $bootstrap_block_length, "bootstrapMethod": $bootstrap_method, "simulations": $simulations, "simulationsLength": $simulations_length} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Skewness
#
# POST /assets/skewness
# --assets item shape: {assetReturns: list}
export def "assets-skewness post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list}
]: any -> record<assets: table<assetSkewness: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/skewness")
  let body = {"assets": $assets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Variance
#
# POST /assets/variance
# --assets item shape: {assetReturns: list}
export def "assets-variance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: list # item shape: {assetReturns: list}
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> record<assets: table<assetVariance: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/variance")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Volatility
#
# POST /assets/volatility
# --assets item shape: {assetReturns: list}
export def "assets-volatility post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: list # item shape: {assetReturns: list}
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> record<assets: table<assetVolatility: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/volatility")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Residualization
#
# POST /factors/residualization
# --factors item shape: {factorReturns: list}
export def "factors-residualization post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  factors: list # item shape: {factorReturns: list}
  residualized_factor: int # The index of the factor to residualize
]: any -> record<residualizedFactorReturns: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/factors/residualization")
  let body = {"factors": $factors, "residualizedFactor": $residualized_factor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Alpha
#
# POST /portfolio/analysis/alpha
# --portfolios item shape: {portfolioReturns: list}
export def "portfolio-analysis-alpha post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --benchmark-returns: list # benchmarkReturns[t] is the return of the benchmark at the time t; the benchmarkReturns array must have the same length as all the portfolioReturns arrays
  --portfolios: list # item shape: {portfolioReturns: list}
  --risk-free-rate: float # The risk free rate, assumed to be constant for any time t
  --risk-free-returns: list # riskFreeReturns[t] is the risk free return at the time t; the riskFreeReturns array must have the same length as all the portfolioReturns arrays
]: any -> record<portfolios: table<portfolioAlpha: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/alpha")
  let body = {"benchmarkReturns": $benchmark_returns, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate, "riskFreeReturns": $risk_free_returns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Beta
#
# POST /portfolio/analysis/beta
# --portfolios item shape: {portfolioReturns: list}
export def "portfolio-analysis-beta post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --benchmark-returns: list # benchmarkReturns[t] is the return of the benchmark at the time t; the benchmarkReturns array must have the same length as all the portfolioReturns arrays
  --portfolios: list # item shape: {portfolioReturns: list}
  --risk-free-rate: float # The risk free rate, assumed to be constant for any time t
  --risk-free-returns: list # riskFreeReturns[t] is the risk free return at the time t; the riskFreeReturns array must have the same length as all the portfolioReturns arrays
]: any -> record<portfolios: table<portfolioBeta: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/beta")
  let body = {"benchmarkReturns": $benchmark_returns, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate, "riskFreeReturns": $risk_free_returns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Conditional Value At Risk
#
# POST /portfolio/analysis/conditional-value-at-risk
# --portfolios item shape: {portfolioValues: list}
export def "portfolio-analysis-conditional-value-at-risk post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  alpha: float # The conditional value at risk level
  portfolios: list # item shape: {portfolioValues: list}
]: any -> record<portfolios: table<portfolioConditionalValueAtRisk: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/conditional-value-at-risk")
  let body = {"alpha": $alpha, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return Contributions
#
# POST /portfolio/analysis/contributions/return
# --portfolios item shape: {assetsWeights: list}
export def "portfolio-analysis-contributions-return post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-groups: list
  assets_returns: list # assetsReturns[i] is the arithmetic return of asset i
  portfolios: list # item shape: {assetsWeights: list}
]: any -> record<portfolios: table<assetsGroupsReturnContributions: list, assetsReturnContributions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/contributions/return")
  let body = {"assets": $assets, "assetsGroups": $assets_groups, "assetsReturns": $assets_returns, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Risk Contributions
#
# POST /portfolio/analysis/contributions/risk
# --portfolios item shape: {assetsWeights: list}
export def "portfolio-analysis-contributions-risk post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-groups: list
  portfolios: list # item shape: {assetsWeights: list}
]: any -> record<portfolios: table<assetsGroupsRiskContributions: list, assetsRiskContributions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/contributions/risk")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsGroups": $assets_groups, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Correlation Spectrum
#
# POST /portfolio/analysis/correlation-spectrum
# --portfolios item shape: {assetsWeights: list}
export def "portfolio-analysis-correlation-spectrum post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --portfolios: list # item shape: {assetsWeights: list}
]: any -> record<portfolios: table<portfolioCorrelationSpectrum: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/correlation-spectrum")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Diversification Ratio
#
# POST /portfolio/analysis/diversification-ratio
# --portfolios item shape: {assetsWeights: list}
export def "portfolio-analysis-diversification-ratio post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --portfolios: list # item shape: {assetsWeights: list}
]: any -> record<portfolios: table<portfolioDiversificationRatio: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/diversification-ratio")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Drawdowns
#
# POST /portfolio/analysis/drawdowns
# --portfolios item shape: {portfolioValues: list}
export def "portfolio-analysis-drawdowns post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolios: list # item shape: {portfolioValues: list}
]: any -> record<portfolios: table<portfolioDrawdowns: list, portfolioWorstDrawdowns: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/drawdowns")
  let body = {"portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Effective Number of Bets
#
# POST /portfolio/analysis/effective-number-of-bets
# --portfolios item shape: {assetsWeights: list}
export def "portfolio-analysis-effective-number-of-bets post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --factors-extraction-method: string@factors-extraction-method-completer # The method used to extract the uncorrelated risk factors from the asset covariance matrix (default: exactMinimumLinearTorsion)
  portfolios: list # item shape: {assetsWeights: list}
]: any -> record<portfolios: table<portfolioEffectiveNumberOfBets: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/effective-number-of-bets")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "factorsExtractionMethod": $factors_extraction_method, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Factor Exposures
#
# POST /portfolio/analysis/factors/exposures
# --factors item shape: {factorReturns: list}
# --portfolios item shape: {portfolioReturns: list}
export def "portfolio-analysis-factors-exposures post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --factors: list # item shape: {factorReturns: list}
  portfolios: list # item shape: {portfolioReturns: list}
]: any -> record<portfolios: table<portfolioAlpha: float, portfolioBetas: list, portfolioRSquared: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/factors/exposures")
  let body = {"factors": $factors, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Mean-Variance Efficient Frontier
#
# POST /portfolio/analysis/mean-variance/efficient-frontier
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-analysis-mean-variance-efficient-frontier post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
  --portfolios: int # The number of portfolios to compute on the mean-variance efficient frontier (default: 25)
]: any -> record<portfolios: table<assetsWeights: list, portfolioReturn: float, portfolioVolatility: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/mean-variance/efficient-frontier")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Mean-Variance Minimum Variance Frontier
#
# POST /portfolio/analysis/mean-variance/minimum-variance-frontier
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-analysis-mean-variance-minimum-variance-frontier post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
  --portfolios: int # The number of portfolios to compute on the mean-variance minimum variance frontier (default: 25)
]: any -> record<portfolios: table<assetsWeights: list, portfolioReturn: float, portfolioVolatility: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/mean-variance/minimum-variance-frontier")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Arithmetic Return
#
# POST /portfolio/analysis/return
# --portfolios item shape: {assetsWeights: list}
export def "portfolio-analysis-return post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: int # The number of assets
  --assets-returns: list # assetsReturns[i] is the arithmetic return of asset i
  --portfolios: list # item shape: {assetsWeights: list}
]: any -> record<portfolios: table<portfolioReturn: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/return")
  let body = {"assets": $assets, "assetsReturns": $assets_returns, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Arithmetic Average Return
#
# POST /portfolio/analysis/returns/average
# --portfolios item shape: {portfolioValues: list}
export def "portfolio-analysis-returns-average post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolios: list # item shape: {portfolioValues: list}
]: any -> record<portfolios: table<portfolioAverageReturn: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/returns/average")
  let body = {"portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sharpe Ratio
#
# POST /portfolio/analysis/sharpe-ratio
# --portfolios item shape: {assetsWeights: list}
export def "portfolio-analysis-sharpe-ratio post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-returns: list # assetsReturns[i] is the arithmetic return of asset i
  --portfolios: list # item shape: {assetsWeights: list}
  --risk-free-rate: float # The risk free rate
]: any -> record<portfolios: table<portfolioSharpeRatio: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/sharpe-ratio")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Bias-Adjusted Sharpe Ratio
#
# POST /portfolio/analysis/sharpe-ratio/bias-adjusted
# --portfolios item shape: {portfolioValues: list}
export def "portfolio-analysis-sharpe-ratio-bias-adjusted post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolios: list # item shape: {portfolioValues: list}
  risk_free_rate: float # The risk free rate
]: any -> record<portfolios: table<portfolioBiasAdjustedSharpeRatio: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/sharpe-ratio/bias-adjusted")
  let body = {"portfolios": $portfolios, "riskFreeRate": $risk_free_rate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sharpe Ratio Confidence Interval
#
# POST /portfolio/analysis/sharpe-ratio/confidence-interval
# --portfolios item shape: {portfolioValues: list}
export def "portfolio-analysis-sharpe-ratio-confidence-interval post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --confidence-interval-type: string@confidence-interval-type-completer # The type of confidence interval to build (default: twoSided)
  --confidence-level: float # The confidence level of the confidence interval to build, in percentage (default: 0.95)
  portfolios: list # item shape: {portfolioValues: list}
  risk_free_rate: float # The risk free rate
]: any -> record<portfolios: table<portfolioSharpeRatioConfidenceInterval: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/sharpe-ratio/confidence-interval")
  let body = {"confidenceIntervalType": $confidence_interval_type, "confidenceLevel": $confidence_level, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Probabilistic Sharpe Ratio
#
# POST /portfolio/analysis/sharpe-ratio/probabilistic
# --portfolios item shape: {portfolioValues: list}
export def "portfolio-analysis-sharpe-ratio-probabilistic post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --benchmark-sharpe-ratio: float # The Sharpe ratio of the benchmark, in the same sampling frequency as the sampling frequency of the portfolio values
  --portfolios: list # item shape: {portfolioValues: list}
  --risk-free-rate: float # The risk free rate
  --benchmark-values: list # benchmarkValues[t] is the value of the benchmark at the time t; the benchmarkValues array must have the same length as all the portfolioValues arrays
]: any -> record<portfolios: table<portfolioProbabilisticSharpeRatio: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/sharpe-ratio/probabilistic")
  let body = {"benchmarkSharpeRatio": $benchmark_sharpe_ratio, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate, "benchmarkValues": $benchmark_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Minimum Track Record Length
#
# POST /portfolio/analysis/sharpe-ratio/probabilistic/minimum-track-record-length
# --portfolios item shape: {portfolioValues: list}
export def "portfolio-analysis-sharpe-ratio-probabilistic-minimum-track-record-length post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --benchmark-sharpe-ratio: float # The Sharpe ratio of the benchmark, in the same sampling frequency as the sampling frequency of the portfolio values
  --confidence-level: float # The confidence level of the minimum track record length, in percentage (default: 0.95)
  --portfolios: list # item shape: {portfolioValues: list}
  --risk-free-rate: float # The risk free rate
  --benchmark-values: list # benchmarkValues[t] is the value of the benchmark at the time t; the benchmarkValues array must have the same length as all the portfolioValues arrays
]: any -> record<portfolios: table<portfolioSharpeRatioMinimumTrackRecordLength: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/sharpe-ratio/probabilistic/minimum-track-record-length")
  let body = {"benchmarkSharpeRatio": $benchmark_sharpe_ratio, "confidenceLevel": $confidence_level, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate, "benchmarkValues": $benchmark_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Tracking Error
#
# POST /portfolio/analysis/tracking-error
# --portfolios item shape: {portfolioReturns: list}
export def "portfolio-analysis-tracking-error post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  benchmark_returns: list # benchmarkReturns[t] is the return of the benchmark at the time t; the benchmarkReturns array must have the same length as all the portfolioReturns arrays
  portfolios: list # item shape: {portfolioReturns: list}
]: any -> record<portfolios: table<portfolioTrackingError: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/tracking-error")
  let body = {"benchmarkReturns": $benchmark_returns, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Ulcer Index
#
# POST /portfolio/analysis/ulcer-index
# --portfolios item shape: {portfolioValues: list}
export def "portfolio-analysis-ulcer-index post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolios: list # item shape: {portfolioValues: list}
  risk_free_rate: float # The risk free rate
]: any -> record<portfolios: table<portfolioUlcerIndex: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/ulcer-index")
  let body = {"portfolios": $portfolios, "riskFreeRate": $risk_free_rate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Ulcer Performance Index
#
# POST /portfolio/analysis/ulcer-performance-index
# --portfolios item shape: {portfolioValues: list}
export def "portfolio-analysis-ulcer-performance-index post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolios: list # item shape: {portfolioValues: list}
  risk_free_rate: float # The risk free rate
]: any -> record<portfolios: table<portfolioUlcerPerformanceIndex: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/ulcer-performance-index")
  let body = {"portfolios": $portfolios, "riskFreeRate": $risk_free_rate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Value At Risk
#
# POST /portfolio/analysis/value-at-risk
# --portfolios item shape: {portfolioValues: list}
export def "portfolio-analysis-value-at-risk post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  alpha: float # The value at risk level
  portfolios: list # item shape: {portfolioValues: list}
]: any -> record<portfolios: table<portfolioValueAtRisk: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/value-at-risk")
  let body = {"alpha": $alpha, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Volatility
#
# POST /portfolio/analysis/volatility
# --portfolios item shape: {assetsWeights: list}
export def "portfolio-analysis-volatility post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --portfolios: list # item shape: {assetsWeights: list}
]: any -> record<portfolios: table<portfolioVolatility: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/volatility")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Investable Portfolio
#
# POST /portfolio/construction/investable
export def "portfolio-construction-investable post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-groups: list
  --assets-groups-weights: list # assetsGroupsWeights[i] is the desired weight of the assets group k in the portfolio, in percentage (can be null to indicate no specific desire); requires assetsGroups to be present
  --assets-minimum-notional-values: list # assetsMinimumNotionalValues[i] is the minimum monetary value that the position in the asset i is required to represent when the asset i is included in the portfolio
  --assets-minimum-positions: list # assetsMinimumPositions[i] is the minimum number of shares of the asset i that is required to purchase when the asset i is included in the portfolio (usual values are the same as for assetsSizeLots)
  assets_prices: list # assetsPrices[i] is the price of the asset i
  --assets-size-lots: list # assetsSizeLots[i] is the number of shares by which it is required to purchase the asset i (usual values are 1 if the asset needs to be purchased share by share, 100 if the asset needs to be purchased by an integer multiple of 100 shares, and 1/1000000 - e.g. for Robinhood broker - if the asset can be purchased by fractional shares)
  --assets-weights: list # assetsWeights[i] is the desired weight of the asset i in the portfolio, in percentage (can be null to indicate no specific desire)
  --maximum-assets-groups-weights: list # maximumAssetsGroupsWeights[k] is the maximum desired weight of the assets group k in the portfolio, in percentage (can be null to indicate no specific desire); requires assetsGroups to be present
  portfolio_value: float # The monetary value of the portfolio
]: any -> record<assetsPositions: list<float>, assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/construction/investable")
  let body = {"assets": $assets, "assetsGroups": $assets_groups, "assetsGroupsWeights": $assets_groups_weights, "assetsMinimumNotionalValues": $assets_minimum_notional_values, "assetsMinimumPositions": $assets_minimum_positions, "assetsPrices": $assets_prices, "assetsSizeLots": $assets_size_lots, "assetsWeights": $assets_weights, "maximumAssetsGroupsWeights": $maximum_assets_groups_weights, "portfolioValue": $portfolio_value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Mimicking Portfolio
#
# POST /portfolio/construction/mimicking
# --assets item shape: {assetReturns: list}
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-construction-mimicking post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list}
  benchmark_returns: list # benchmarkReturns[t] is the return of the benchmark at the time t; the benchmarkReturns array must have the same length as all the assetReturns arrays
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/construction/mimicking")
  let body = {"assets": $assets, "benchmarkReturns": $benchmark_returns, "constraints": $constraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Random Portfolio
#
# POST /portfolio/construction/random
# --constraints shape: {maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-construction-random post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --constraints: record # shape: {maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
  --portfolios: int # The number of portfolios to construct (default: 25)
]: any -> record<portfolios: table<assetsWeights: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/construction/random")
  let body = {"assets": $assets, "constraints": $constraints, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Equal Risk Contributions Portfolio
#
# POST /portfolio/optimization/equal-risk-contributions
# --constraints shape: {maximumAssetsWeights?: list, minimumAssetsWeights?: list}
export def "portfolio-optimization-equal-risk-contributions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --constraints: record # shape: {maximumAssetsWeights?: list, minimumAssetsWeights?: list}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/equal-risk-contributions")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "constraints": $constraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Equal Sharpe Ratio Contributions Portfolio
#
# POST /portfolio/optimization/equal-sharpe-ratio-contributions
export def "portfolio-optimization-equal-sharpe-ratio-contributions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list # assetsReturns[i] is the arithmetic return of asset i
  risk_free_rate: float # The risk free rate
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/equal-sharpe-ratio-contributions")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "riskFreeRate": $risk_free_rate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Equal Volatility Weighted Portfolio
#
# POST /portfolio/optimization/equal-volatility-weighted
export def "portfolio-optimization-equal-volatility-weighted post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_volatilities: list # assetsVolatilities[i] is the volatility of the asset i
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/equal-volatility-weighted")
  let body = {"assets": $assets, "assetsVolatilities": $assets_volatilities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Equal Weighted Portfolio
#
# POST /portfolio/optimization/equal-weighted
export def "portfolio-optimization-equal-weighted post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/equal-weighted")
  let body = {"assets": $assets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Hierarchical Risk Parity Portfolio
#
# POST /portfolio/optimization/hierarchical-risk-parity
# --constraints shape: {maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-optimization-hierarchical-risk-parity post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --clustering-method: string@clustering-method-completer # The hierarchical clustering method to use (default: singleLinkage)
  --clustering-ordering: string@clustering-ordering-completer # The order to impose on the hierarchical clustering tree leaves (default: r-hclust)
  --constraints: record # shape: {maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/hierarchical-risk-parity")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "clusteringMethod": $clustering_method, "clusteringOrdering": $clustering_ordering, "constraints": $constraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Hierarchical Clustering-Based Risk Parity Portfolio
#
# POST /portfolio/optimization/hierarchical-risk-parity/clustering-based
# --constraints shape: {maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-optimization-hierarchical-risk-parity-clustering-based post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --across-cluster-allocation-method: string@across-cluster-allocation-method-completer # The allocation method to use across clusters (default: equalWeighting)
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --clustering-method: string@clustering-method-completer # The hierarchical clustering method to use (default: wardLinkage)
  --clustering-ordering: string@clustering-ordering-completer # The order to impose on the hierarchical clustering tree leaves (default: r-hclust)
  --clusters: int # The number of clusters to use in the hierarchical clustering tree; if not provided, the number of clusters to use is computed using the gap statistic method, as described in the first reference
  --constraints: record # shape: {maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
  --within-cluster-allocation-method: string@within-cluster-allocation-method-completer # The allocation method to use within clusters (default: equalWeighting)
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/hierarchical-risk-parity/clustering-based")
  let body = {"acrossClusterAllocationMethod": $across_cluster_allocation_method, "assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "clusteringMethod": $clustering_method, "clusteringOrdering": $clustering_ordering, "clusters": $clusters, "constraints": $constraints, "withinClusterAllocationMethod": $within_cluster_allocation_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Inverse Variance Weighted Portfolio
#
# POST /portfolio/optimization/inverse-variance-weighted
export def "portfolio-optimization-inverse-variance-weighted post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_variances: list # assetsVariances[i] is the variance of the asset i
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/inverse-variance-weighted")
  let body = {"assets": $assets, "assetsVariances": $assets_variances} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Inverse Volatility Weighted Portfolio
#
# POST /portfolio/optimization/inverse-volatility-weighted
export def "portfolio-optimization-inverse-volatility-weighted post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_volatilities: list # assetsVolatilities[i] is the volatility of the asset i
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/inverse-volatility-weighted")
  let body = {"assets": $assets, "assetsVolatilities": $assets_volatilities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Market Capitalization Weighted Portfolio
#
# POST /portfolio/optimization/market-capitalization-weighted
export def "portfolio-optimization-market-capitalization-weighted post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_market_capitalizations: list # assetsMarketCapitalizations[i] is the market capitalization of the asset i
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/market-capitalization-weighted")
  let body = {"assets": $assets, "assetsMarketCapitalizations": $assets_market_capitalizations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Maximum Decorrelation Portfolio
#
# POST /portfolio/optimization/maximum-decorrelation
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-decorrelation post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --assets-returns: list # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-decorrelation")
  let body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Maximum Return Portfolio
#
# POST /portfolio/optimization/maximum-return
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-return post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-return")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Diversified Maximum Return Portfolio
#
# POST /portfolio/optimization/maximum-return/diversified
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-return-diversified post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-return/diversified")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Subset Resampling-Based Maximum Return Portfolio
#
# POST /portfolio/optimization/maximum-return/subset-resampling-based
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-return-subset-resampling-based post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
  --subset-portfolios: int # The number of subset portfolios to compute; only applicable if the enumeration method for the subset portfolios is random sampling (default: 128)
  --subset-portfolios-aggregation-method: string@subset-portfolios-aggregation-method-completer # The method to aggregate the subset portfolios (default: average)
  --subset-portfolios-enumeration-method: string@subset-portfolios-enumeration-method-completer # The method to enumerate the subset portfolios (default: randomSampling)
  --subset-size: int # The number of assets to include in each subset portfolio; defaults to a value of order the square root of the total number of assets
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-return/subset-resampling-based")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "subsetPortfolios": $subset_portfolios, "subsetPortfoliosAggregationMethod": $subset_portfolios_aggregation_method, "subsetPortfoliosEnumerationMethod": $subset_portfolios_enumeration_method, "subsetSize": $subset_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Maximum Sharpe Ratio Portfolio
#
# POST /portfolio/optimization/maximum-sharpe-ratio
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-sharpe-ratio post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
  risk_free_rate: float # The risk free rate
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-sharpe-ratio")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "riskFreeRate": $risk_free_rate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Diversified Maximum Sharpe Ratio Portfolio
#
# POST /portfolio/optimization/maximum-sharpe-ratio/diversified
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-sharpe-ratio-diversified post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
  risk_free_rate: float # The risk free rate
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-sharpe-ratio/diversified")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "riskFreeRate": $risk_free_rate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Subset Resampling-Based Maximum Sharpe Ratio Portfolio
#
# POST /portfolio/optimization/maximum-sharpe-ratio/subset-resampling-based
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-sharpe-ratio-subset-resampling-based post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
  risk_free_rate: float # The risk free rate
  --subset-portfolios: int # The number of subset portfolios to compute; only applicable if the enumeration method for the subset portfolios is random sampling (default: 128)
  --subset-portfolios-aggregation-method: string@subset-portfolios-aggregation-method-completer # The method to aggregate the subset portfolios (default: average)
  --subset-portfolios-enumeration-method: string@subset-portfolios-enumeration-method-completer # The method to enumerate the subset portfolios (default: randomSampling)
  --subset-size: int # The number of assets to include in each subset portfolio; defaults to a value of order the square root of the total number of assets
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-sharpe-ratio/subset-resampling-based")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "riskFreeRate": $risk_free_rate, "subsetPortfolios": $subset_portfolios, "subsetPortfoliosAggregationMethod": $subset_portfolios_aggregation_method, "subsetPortfoliosEnumerationMethod": $subset_portfolios_enumeration_method, "subsetSize": $subset_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Maximum Ulcer Performance Index Portfolio
#
# POST /portfolio/optimization/maximum-ulcer-performance-index
# --assets item shape: {assetPrices: list}
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-ulcer-performance-index post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list}
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
  risk_free_rate: float # The risk free rate
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-ulcer-performance-index")
  let body = {"assets": $assets, "constraints": $constraints, "riskFreeRate": $risk_free_rate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Mean-Variance Efficient Portfolio
#
# POST /portfolio/optimization/mean-variance-efficient
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float, portfolioReturn?: float, portfolioVolatility?: float, riskTolerance?: float}
export def "portfolio-optimization-mean-variance-efficient post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list # assetsReturns[i] is the arithmetic return of asset i
  constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float, portfolioReturn?: float, portfolioVolatility?: float, riskTolerance?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/mean-variance-efficient")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Diversified Mean-Variance Efficient Portfolio
#
# POST /portfolio/optimization/mean-variance-efficient/diversified
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float, portfolioReturn?: float, portfolioVolatility?: float, riskTolerance?: float}
export def "portfolio-optimization-mean-variance-efficient-diversified post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list # assetsReturns[i] is the arithmetic return of asset i
  constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float, portfolioReturn?: float, portfolioVolatility?: float, riskTolerance?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/mean-variance-efficient/diversified")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Subset Resampling-Based Mean-Variance Efficient Portfolio
#
# POST /portfolio/optimization/mean-variance-efficient/subset-resampling-based
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float, portfolioReturn?: float, portfolioVolatility?: float, riskTolerance?: float}
export def "portfolio-optimization-mean-variance-efficient-subset-resampling-based post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list # assetsReturns[i] is the arithmetic return of asset i
  constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float, portfolioReturn?: float, portfolioVolatility?: float, riskTolerance?: float}
  --subset-portfolios: int # The number of subset portfolios to compute; only applicable if the enumeration method for the subset portfolios is random sampling (default: 128)
  --subset-portfolios-aggregation-method: string@subset-portfolios-aggregation-method-completer # The method to aggregate the subset portfolios (default: average)
  --subset-portfolios-enumeration-method: string@subset-portfolios-enumeration-method-completer # The method to enumerate the subset portfolios (default: randomSampling)
  --subset-size: int # The number of assets to include in each subset portfolio; defaults to a value of order the square root of the total number of assets
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/mean-variance-efficient/subset-resampling-based")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "subsetPortfolios": $subset_portfolios, "subsetPortfoliosAggregationMethod": $subset_portfolios_aggregation_method, "subsetPortfoliosEnumerationMethod": $subset_portfolios_enumeration_method, "subsetSize": $subset_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Minimum Correlation Portfolio
#
# POST /portfolio/optimization/minimum-correlation
export def "portfolio-optimization-minimum-correlation post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j; required if assetsReturns is not provided
  assets_volatilities: list # assetsVariances[i] is the volatility of the asset i; required if assetsCorrelationMatrix is provided and assetsVariances is not provided
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/minimum-correlation")
  let body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "assetsVolatilities": $assets_volatilities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Minimum Ulcer Index Portfolio
#
# POST /portfolio/optimization/minimum-ulcer-index
# --assets item shape: {assetPrices: list}
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-optimization-minimum-ulcer-index post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list}
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/minimum-ulcer-index")
  let body = {"assets": $assets, "constraints": $constraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Minimum Variance Portfolio
#
# POST /portfolio/optimization/minimum-variance
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-optimization-minimum-variance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-returns: list # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/minimum-variance")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Diversified Minimum Variance Portfolio
#
# POST /portfolio/optimization/minimum-variance/diversified
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-optimization-minimum-variance-diversified post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-returns: list # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/minimum-variance/diversified")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Subset Resampling-Based Minimum Variance Portfolio
#
# POST /portfolio/optimization/minimum-variance/subset-resampling-based
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-optimization-minimum-variance-subset-resampling-based post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-returns: list # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
  --subset-portfolios: int # The number of subset portfolios to compute; only applicable if the enumeration method for the subset portfolios is random sampling (default: 128)
  --subset-portfolios-aggregation-method: string@subset-portfolios-aggregation-method-completer # The method to aggregate the subset portfolios (default: average)
  --subset-portfolios-enumeration-method: string@subset-portfolios-enumeration-method-completer # The method to enumerate the subset portfolios (default: randomSampling)
  --subset-size: int # The number of assets to include in each subset portfolio; defaults to a value of order the square root of the total number of assets
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/minimum-variance/subset-resampling-based")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "subsetPortfolios": $subset_portfolios, "subsetPortfoliosAggregationMethod": $subset_portfolios_aggregation_method, "subsetPortfoliosEnumerationMethod": $subset_portfolios_enumeration_method, "subsetSize": $subset_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Most Diversified Portfolio
#
# POST /portfolio/optimization/most-diversified
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
export def "portfolio-optimization-most-diversified post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list, maximumAssetsWeights?: list, maximumPortfolioExposure?: float, minimumAssetsWeights?: list, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/most-diversified")
  let body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "constraints": $constraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Drift-weight Portfolio Rebalancing
#
# POST /portfolio/simulation/rebalancing/drift-weight
# --assets item shape: {assetPrices: list}
# --portfolios item shape: {assetsWeights: list}
export def "portfolio-simulation-rebalancing-drift-weight post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list}
  portfolios: list # item shape: {assetsWeights: list}
]: any -> record<portfolios: table<portfolioValues: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/simulation/rebalancing/drift-weight")
  let body = {"assets": $assets, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fixed-weight Portfolio Rebalancing
#
# POST /portfolio/simulation/rebalancing/fixed-weight
# --assets item shape: {assetPrices: list}
# --portfolios item shape: {assetsWeights: list}
export def "portfolio-simulation-rebalancing-fixed-weight post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list}
  portfolios: list # item shape: {assetsWeights: list}
]: any -> record<portfolios: table<portfolioValues: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/simulation/rebalancing/fixed-weight")
  let body = {"assets": $assets, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Random-weight Portfolio Rebalancing
#
# POST /portfolio/simulation/rebalancing/random-weight
# --assets item shape: {assetPrices: list}
export def "portfolio-simulation-rebalancing-random-weight post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list}
  --portfolios: int # The number of portfolios to simulate (default: 25)
]: any -> record<portfolios: table<portfolioValues: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/simulation/rebalancing/random-weight")
  let body = {"assets": $assets, "portfolios": $portfolios} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
