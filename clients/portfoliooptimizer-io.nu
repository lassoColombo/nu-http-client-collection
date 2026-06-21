# Auto-generated client for Portfolio Optimizer v1.0.9
# Source: https://api.apis.guru/v2/specs/portfoliooptimizer.io/1.0.9/openapi.json
# Auth: --token flag or $env.PORTFOLIO_OPTIMIZER_TOKEN

const BASE_URL = "https://api.portfoliooptimizer.io/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PORTFOLIO_OPTIMIZER_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-api-key" => { {scheme: $scheme, headers: {X-API-Key: $token_val}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "assets-analysis-absorption-ratio create" } } | get name | first)
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
export def "assets-analysis-absorption-ratio create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-covariance-matrix-eigenvectors: record # shape: {eigenvectorsRetained?: int}
]: any -> record<assetsAbsorptionRatio: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/analysis/absorption-ratio")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsCovarianceMatrixEigenvectors": $assets_covariance_matrix_eigenvectors} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Turbulence Index
#
# POST /assets/analysis/turbulence-index
export def "assets-analysis-turbulence-index create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_average_returns: list<float> # assetsAverageReturns[i] is the average return of asset i over an historical reference period
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j over an historical reference period
  assets_returns: list<float> # assetsReturns[i] is the return of asset i over a period different from the historical reference period
]: any -> record<assetsTurbulenceIndex: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/analysis/turbulence-index")
  let req_body = {"assets": $assets, "assetsAverageReturns": $assets_average_returns, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Correlation Matrix
#
# POST /assets/correlation/matrix
# --assets item shape: {assetReturns: list<float>}
export def "assets-correlation-matrix create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: list # item shape: {assetReturns: list<float>}
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> record<assetsCorrelationMatrix: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Correlation Matrix Bounds
#
# POST /assets/correlation/matrix/bounds
export def "assets-correlation-matrix-bounds create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  assets_group: list<int> # assetsGroup[k] is the indexes of the assets belonging to the assets group
]: any -> record<assetsCorrelationMatrixLowerBounds: list<list<float>>, assetsCorrelationMatrixUpperBounds: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/bounds")
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "assetsGroup": $assets_group} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Denoised Correlation Matrix
#
# POST /assets/correlation/matrix/denoised
export def "assets-correlation-matrix-denoised create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "assetsCorrelationMatrixAspectRatio": $assets_correlation_matrix_aspect_ratio, "denoisingMethod": $denoising_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Correlation Matrix Distance
#
# POST /assets/correlation/matrix/distance
export def "assets-correlation-matrix-distance create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "distanceMetric": $distance_metric, "referenceCorrelationMatrix": $reference_correlation_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Correlation Matrix Effective Rank
#
# POST /assets/correlation/matrix/effective-rank
export def "assets-correlation-matrix-effective-rank create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
]: any -> record<assetsCorrelationMatrixEffectiveRank: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/effective-rank")
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Correlation Matrix Informativeness
#
# POST /assets/correlation/matrix/informativeness
export def "assets-correlation-matrix-informativeness create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --distance-metric: string@distance-metric-completer # The distance metric to use to compute the informativeness of the asset correlation matrix (default: euclidean)
]: any -> record<assetsCorrelationMatrixInformativeness: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/informativeness")
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "distanceMetric": $distance_metric} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Nearest Correlation Matrix
#
# POST /assets/correlation/matrix/nearest
export def "assets-correlation-matrix-nearest create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_approximate_correlation_matrix: list # assetsApproximateCorrelationMatrix[i][i] is the approximate correlation between the asset i and the asset j
  --assets-fixed-correlations: list # assetsFixedCorrelations[k] is the couple of indices (i,j) of the assets i and j for which to keep the approximate correlation assetsApproximateCorrelationMatrix[i][j] fixed
]: any -> record<assetsCorrelationMatrix: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/nearest")
  let req_body = {"assets": $assets, "assetsApproximateCorrelationMatrix": $assets_approximate_correlation_matrix, "assetsFixedCorrelations": $assets_fixed_correlations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Random Correlation Matrix
#
# POST /assets/correlation/matrix/random
export def "assets-correlation-matrix-random create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
]: any -> record<assetsCorrelationMatrix: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/random")
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Correlation Matrix Shrinkage
#
# POST /assets/correlation/matrix/shrinkage
export def "assets-correlation-matrix-shrinkage create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "shrinkageFactor": $shrinkage_factor, "targetEquicorrelationMatrix": $target_equicorrelation_matrix, "targetCorrelationMatrix": $target_correlation_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Theory-Implied Correlation Matrix
#
# POST /assets/correlation/matrix/theory-implied
# --assets item shape: {assetHierarchicalClassification: list}
export def "assets-correlation-matrix-theory-implied create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetHierarchicalClassification: list}
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --clustering-method: string@clustering-method-completer # The hierarchical clustering method to use (default: averageLinkage)
]: any -> record<assetsCorrelationMatrix: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/theory-implied")
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "clusteringMethod": $clustering_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Correlation Matrix Validation
#
# POST /assets/correlation/matrix/validation
export def "assets-correlation-matrix-validation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/validation")
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Covariance Matrix
#
# POST /assets/covariance/matrix
# --assets item shape: {assetReturns: list<float>}
export def "assets-covariance-matrix create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: list # item shape: {assetReturns: list<float>}
  --assets-correlation-matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --assets-variances: list<float> # assetsVariances[i] is the variance of the asset i
  --assets-volatilities: list<float> # assetsVolatilities[i] is the volatility of the asset i
]: any -> record<assetsCovarianceMatrix: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/covariance/matrix")
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "assetsVariances": $assets_variances, "assetsVolatilities": $assets_volatilities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Covariance Matrix Effective Rank
#
# POST /assets/covariance/matrix/effective-rank
export def "assets-covariance-matrix-effective-rank create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> record<assetsCovarianceMatrixEffectiveRank: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/covariance/matrix/effective-rank")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Exponentially Weighted Covariance Matrix
#
# POST /assets/covariance/matrix/exponentially-weighted
# --assets item shape: {assetReturns: list<float>}
export def "assets-covariance-matrix-exponentially-weighted create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
  --decay-factor: float # The exponential decay factor (default: 0.94)
]: any -> record<assetsCovarianceMatrix: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/covariance/matrix/exponentially-weighted")
  let req_body = {"assets": $assets, "decayFactor": $decay_factor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Covariance Matrix Validation
#
# POST /assets/covariance/matrix/validation
export def "assets-covariance-matrix-validation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/covariance/matrix/validation")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Kurtosis
#
# POST /assets/kurtosis
# --assets item shape: {assetReturns: list<float>}
export def "assets-kurtosis create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
]: any -> record<assets: table<assetKurtosis: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/kurtosis")
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Adjusted Prices
#
# POST /assets/prices/adjusted
# --assets item shape: {assetDividends?: list, assetPrices: list, assetSplits?: list}
export def "assets-prices-adjusted create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetDividends?: list, assetPrices: list, assetSplits?: list}
]: any -> record<assets: table<assetAdjustedPrices: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/prices/adjusted")
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Forward-Adjusted Prices
#
# POST /assets/prices/adjusted/forward
# --assets item shape: {assetDividends?: list, assetPrices: list, assetSplits?: list}
export def "assets-prices-adjusted-forward create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetDividends?: list, assetPrices: list, assetSplits?: list}
]: any -> record<assets: table<assetAdjustedPrices: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/prices/adjusted/forward")
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Arithmetic Returns
#
# POST /assets/returns
# --assets item shape: {assetPrices: list<float>}
export def "assets-returns create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list<float>}
]: any -> record<assets: table<assetReturns: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/returns")
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Arithmetic Average Return
#
# POST /assets/returns/average
# --assets item shape: {assetReturns: list<float>}
export def "assets-returns-average create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
]: any -> record<assets: table<assetAverageReturn: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/returns/average")
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bootstrap
#
# POST /assets/returns/simulation/bootstrap
# --assets item shape: {assetReturns: list<float>}
export def "assets-returns-simulation-bootstrap create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
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
  let req_body = {"assets": $assets, "bootstrapAverageBlockLength": $bootstrap_average_block_length, "bootstrapBlockLength": $bootstrap_block_length, "bootstrapMethod": $bootstrap_method, "simulations": $simulations, "simulationsLength": $simulations_length} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Skewness
#
# POST /assets/skewness
# --assets item shape: {assetReturns: list<float>}
export def "assets-skewness create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
]: any -> record<assets: table<assetSkewness: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/skewness")
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Variance
#
# POST /assets/variance
# --assets item shape: {assetReturns: list<float>}
export def "assets-variance create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: list # item shape: {assetReturns: list<float>}
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> record<assets: table<assetVariance: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/variance")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Volatility
#
# POST /assets/volatility
# --assets item shape: {assetReturns: list<float>}
export def "assets-volatility create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: list # item shape: {assetReturns: list<float>}
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> record<assets: table<assetVolatility: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/volatility")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Residualization
#
# POST /factors/residualization
# --factors item shape: {factorReturns: list<float>}
export def "factors-residualization create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  factors: list # item shape: {factorReturns: list<float>}
  residualized_factor: int # The index of the factor to residualize
]: any -> record<residualizedFactorReturns: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/factors/residualization")
  let req_body = {"factors": $factors, "residualizedFactor": $residualized_factor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Alpha
#
# POST /portfolio/analysis/alpha
# --portfolios item shape: {portfolioReturns: list<float>}
export def "portfolio-analysis-alpha create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --benchmark-returns: list<float> # benchmarkReturns[t] is the return of the benchmark at the time t; the benchmarkReturns array must have the same length as all the portfolioReturns arrays
  --portfolios: list # item shape: {portfolioReturns: list<float>}
  --risk-free-rate: float # The risk free rate, assumed to be constant for any time t
  --risk-free-returns: list<float> # riskFreeReturns[t] is the risk free return at the time t; the riskFreeReturns array must have the same length as all the portfolioReturns arrays
]: any -> record<portfolios: table<portfolioAlpha: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/alpha")
  let req_body = {"benchmarkReturns": $benchmark_returns, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate, "riskFreeReturns": $risk_free_returns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Beta
#
# POST /portfolio/analysis/beta
# --portfolios item shape: {portfolioReturns: list<float>}
export def "portfolio-analysis-beta create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --benchmark-returns: list<float> # benchmarkReturns[t] is the return of the benchmark at the time t; the benchmarkReturns array must have the same length as all the portfolioReturns arrays
  --portfolios: list # item shape: {portfolioReturns: list<float>}
  --risk-free-rate: float # The risk free rate, assumed to be constant for any time t
  --risk-free-returns: list<float> # riskFreeReturns[t] is the risk free return at the time t; the riskFreeReturns array must have the same length as all the portfolioReturns arrays
]: any -> record<portfolios: table<portfolioBeta: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/beta")
  let req_body = {"benchmarkReturns": $benchmark_returns, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate, "riskFreeReturns": $risk_free_returns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Conditional Value At Risk
#
# POST /portfolio/analysis/conditional-value-at-risk
# --portfolios item shape: {portfolioValues: list<float>}
export def "portfolio-analysis-conditional-value-at-risk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  alpha: float # The conditional value at risk level
  portfolios: list # item shape: {portfolioValues: list<float>}
]: any -> record<portfolios: table<portfolioConditionalValueAtRisk: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/conditional-value-at-risk")
  let req_body = {"alpha": $alpha, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Return Contributions
#
# POST /portfolio/analysis/contributions/return
# --portfolios item shape: {assetsWeights: list<float>}
export def "portfolio-analysis-contributions-return create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-groups: list
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> record<portfolios: table<assetsGroupsReturnContributions: list, assetsReturnContributions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/contributions/return")
  let req_body = {"assets": $assets, "assetsGroups": $assets_groups, "assetsReturns": $assets_returns, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Risk Contributions
#
# POST /portfolio/analysis/contributions/risk
# --portfolios item shape: {assetsWeights: list<float>}
export def "portfolio-analysis-contributions-risk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-groups: list
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> record<portfolios: table<assetsGroupsRiskContributions: list, assetsRiskContributions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/contributions/risk")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsGroups": $assets_groups, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Correlation Spectrum
#
# POST /portfolio/analysis/correlation-spectrum
# --portfolios item shape: {assetsWeights: list<float>}
export def "portfolio-analysis-correlation-spectrum create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> record<portfolios: table<portfolioCorrelationSpectrum: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/correlation-spectrum")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Diversification Ratio
#
# POST /portfolio/analysis/diversification-ratio
# --portfolios item shape: {assetsWeights: list<float>}
export def "portfolio-analysis-diversification-ratio create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> record<portfolios: table<portfolioDiversificationRatio: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/diversification-ratio")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Drawdowns
#
# POST /portfolio/analysis/drawdowns
# --portfolios item shape: {portfolioValues: list<float>}
export def "portfolio-analysis-drawdowns create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolios: list # item shape: {portfolioValues: list<float>}
]: any -> record<portfolios: table<portfolioDrawdowns: list, portfolioWorstDrawdowns: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/drawdowns")
  let req_body = {"portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Effective Number of Bets
#
# POST /portfolio/analysis/effective-number-of-bets
# --portfolios item shape: {assetsWeights: list<float>}
export def "portfolio-analysis-effective-number-of-bets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --factors-extraction-method: string@factors-extraction-method-completer # The method used to extract the uncorrelated risk factors from the asset covariance matrix (default: exactMinimumLinearTorsion)
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> record<portfolios: table<portfolioEffectiveNumberOfBets: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/effective-number-of-bets")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "factorsExtractionMethod": $factors_extraction_method, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Factor Exposures
#
# POST /portfolio/analysis/factors/exposures
# --factors item shape: {factorReturns: list<float>}
# --portfolios item shape: {portfolioReturns: list<float>}
export def "portfolio-analysis-factors-exposures create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --factors: list # item shape: {factorReturns: list<float>}
  portfolios: list # item shape: {portfolioReturns: list<float>}
]: any -> record<portfolios: table<portfolioAlpha: float, portfolioBetas: list, portfolioRSquared: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/factors/exposures")
  let req_body = {"factors": $factors, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Mean-Variance Efficient Frontier
#
# POST /portfolio/analysis/mean-variance/efficient-frontier
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-analysis-mean-variance-efficient-frontier create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  --portfolios: int # The number of portfolios to compute on the mean-variance efficient frontier (default: 25)
]: any -> record<portfolios: table<assetsWeights: list, portfolioReturn: float, portfolioVolatility: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/mean-variance/efficient-frontier")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Mean-Variance Minimum Variance Frontier
#
# POST /portfolio/analysis/mean-variance/minimum-variance-frontier
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-analysis-mean-variance-minimum-variance-frontier create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  --portfolios: int # The number of portfolios to compute on the mean-variance minimum variance frontier (default: 25)
]: any -> record<portfolios: table<assetsWeights: list, portfolioReturn: float, portfolioVolatility: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/mean-variance/minimum-variance-frontier")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Arithmetic Return
#
# POST /portfolio/analysis/return
# --portfolios item shape: {assetsWeights: list<float>}
export def "portfolio-analysis-return create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: int # The number of assets
  --assets-returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> record<portfolios: table<portfolioReturn: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/return")
  let req_body = {"assets": $assets, "assetsReturns": $assets_returns, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Arithmetic Average Return
#
# POST /portfolio/analysis/returns/average
# --portfolios item shape: {portfolioValues: list<float>}
export def "portfolio-analysis-returns-average create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolios: list # item shape: {portfolioValues: list<float>}
]: any -> record<portfolios: table<portfolioAverageReturn: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/returns/average")
  let req_body = {"portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Sharpe Ratio
#
# POST /portfolio/analysis/sharpe-ratio
# --portfolios item shape: {assetsWeights: list<float>}
export def "portfolio-analysis-sharpe-ratio create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --portfolios: list # item shape: {assetsWeights: list<float>}
  --risk-free-rate: float # The risk free rate
]: any -> record<portfolios: table<portfolioSharpeRatio: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/sharpe-ratio")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bias-Adjusted Sharpe Ratio
#
# POST /portfolio/analysis/sharpe-ratio/bias-adjusted
# --portfolios item shape: {portfolioValues: list<float>}
export def "portfolio-analysis-sharpe-ratio-bias-adjusted create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolios: list # item shape: {portfolioValues: list<float>}
  risk_free_rate: float # The risk free rate
]: any -> record<portfolios: table<portfolioBiasAdjustedSharpeRatio: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/sharpe-ratio/bias-adjusted")
  let req_body = {"portfolios": $portfolios, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Sharpe Ratio Confidence Interval
#
# POST /portfolio/analysis/sharpe-ratio/confidence-interval
# --portfolios item shape: {portfolioValues: list<float>}
export def "portfolio-analysis-sharpe-ratio-confidence-interval create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --confidence-interval-type: string@confidence-interval-type-completer # The type of confidence interval to build (default: twoSided)
  --confidence-level: float # The confidence level of the confidence interval to build, in percentage (default: 0.95)
  portfolios: list # item shape: {portfolioValues: list<float>}
  risk_free_rate: float # The risk free rate
]: any -> record<portfolios: table<portfolioSharpeRatioConfidenceInterval: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/sharpe-ratio/confidence-interval")
  let req_body = {"confidenceIntervalType": $confidence_interval_type, "confidenceLevel": $confidence_level, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Probabilistic Sharpe Ratio
#
# POST /portfolio/analysis/sharpe-ratio/probabilistic
# --portfolios item shape: {portfolioValues: list<float>}
export def "portfolio-analysis-sharpe-ratio-probabilistic create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --benchmark-sharpe-ratio: float # The Sharpe ratio of the benchmark, in the same sampling frequency as the sampling frequency of the portfolio values
  --portfolios: list # item shape: {portfolioValues: list<float>}
  --risk-free-rate: float # The risk free rate
  --benchmark-values: list<float> # benchmarkValues[t] is the value of the benchmark at the time t; the benchmarkValues array must have the same length as all the portfolioValues arrays
]: any -> record<portfolios: table<portfolioProbabilisticSharpeRatio: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/sharpe-ratio/probabilistic")
  let req_body = {"benchmarkSharpeRatio": $benchmark_sharpe_ratio, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate, "benchmarkValues": $benchmark_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Minimum Track Record Length
#
# POST /portfolio/analysis/sharpe-ratio/probabilistic/minimum-track-record-length
# --portfolios item shape: {portfolioValues: list<float>}
export def "portfolio-analysis-sharpe-ratio-probabilistic-minimum-track-record-length create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --benchmark-sharpe-ratio: float # The Sharpe ratio of the benchmark, in the same sampling frequency as the sampling frequency of the portfolio values
  --confidence-level: float # The confidence level of the minimum track record length, in percentage (default: 0.95)
  --portfolios: list # item shape: {portfolioValues: list<float>}
  --risk-free-rate: float # The risk free rate
  --benchmark-values: list<float> # benchmarkValues[t] is the value of the benchmark at the time t; the benchmarkValues array must have the same length as all the portfolioValues arrays
]: any -> record<portfolios: table<portfolioSharpeRatioMinimumTrackRecordLength: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/sharpe-ratio/probabilistic/minimum-track-record-length")
  let req_body = {"benchmarkSharpeRatio": $benchmark_sharpe_ratio, "confidenceLevel": $confidence_level, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate, "benchmarkValues": $benchmark_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Tracking Error
#
# POST /portfolio/analysis/tracking-error
# --portfolios item shape: {portfolioReturns: list<float>}
export def "portfolio-analysis-tracking-error create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  benchmark_returns: list<float> # benchmarkReturns[t] is the return of the benchmark at the time t; the benchmarkReturns array must have the same length as all the portfolioReturns arrays
  portfolios: list # item shape: {portfolioReturns: list<float>}
]: any -> record<portfolios: table<portfolioTrackingError: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/tracking-error")
  let req_body = {"benchmarkReturns": $benchmark_returns, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Ulcer Index
#
# POST /portfolio/analysis/ulcer-index
# --portfolios item shape: {portfolioValues: list<float>}
export def "portfolio-analysis-ulcer-index create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolios: list # item shape: {portfolioValues: list<float>}
  risk_free_rate: float # The risk free rate
]: any -> record<portfolios: table<portfolioUlcerIndex: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/ulcer-index")
  let req_body = {"portfolios": $portfolios, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Ulcer Performance Index
#
# POST /portfolio/analysis/ulcer-performance-index
# --portfolios item shape: {portfolioValues: list<float>}
export def "portfolio-analysis-ulcer-performance-index create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  portfolios: list # item shape: {portfolioValues: list<float>}
  risk_free_rate: float # The risk free rate
]: any -> record<portfolios: table<portfolioUlcerPerformanceIndex: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/ulcer-performance-index")
  let req_body = {"portfolios": $portfolios, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Value At Risk
#
# POST /portfolio/analysis/value-at-risk
# --portfolios item shape: {portfolioValues: list<float>}
export def "portfolio-analysis-value-at-risk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  alpha: float # The value at risk level
  portfolios: list # item shape: {portfolioValues: list<float>}
]: any -> record<portfolios: table<portfolioValueAtRisk: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/value-at-risk")
  let req_body = {"alpha": $alpha, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Volatility
#
# POST /portfolio/analysis/volatility
# --portfolios item shape: {assetsWeights: list<float>}
export def "portfolio-analysis-volatility create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> record<portfolios: table<portfolioVolatility: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/volatility")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Investable Portfolio
#
# POST /portfolio/construction/investable
export def "portfolio-construction-investable create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-groups: list
  --assets-groups-weights: list<float> # assetsGroupsWeights[i] is the desired weight of the assets group k in the portfolio, in percentage (can be null to indicate no specific desire); requires assetsGroups to be present
  --assets-minimum-notional-values: list<float> # assetsMinimumNotionalValues[i] is the minimum monetary value that the position in the asset i is required to represent when the asset i is included in the portfolio
  --assets-minimum-positions: list<float> # assetsMinimumPositions[i] is the minimum number of shares of the asset i that is required to purchase when the asset i is included in the portfolio (usual values are the same as for assetsSizeLots)
  assets_prices: list<float> # assetsPrices[i] is the price of the asset i
  --assets-size-lots: list<float> # assetsSizeLots[i] is the number of shares by which it is required to purchase the asset i (usual values are 1 if the asset needs to be purchased share by share, 100 if the asset needs to be purchased by an integer multiple of 100 shares, and 1/1000000 - e.g. for Robinhood broker - if the asset can be purchased by fractional shares)
  --assets-weights: list<float> # assetsWeights[i] is the desired weight of the asset i in the portfolio, in percentage (can be null to indicate no specific desire)
  --maximum-assets-groups-weights: list<float> # maximumAssetsGroupsWeights[k] is the maximum desired weight of the assets group k in the portfolio, in percentage (can be null to indicate no specific desire); requires assetsGroups to be present
  portfolio_value: float # The monetary value of the portfolio
]: any -> record<assetsPositions: list<float>, assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/construction/investable")
  let req_body = {"assets": $assets, "assetsGroups": $assets_groups, "assetsGroupsWeights": $assets_groups_weights, "assetsMinimumNotionalValues": $assets_minimum_notional_values, "assetsMinimumPositions": $assets_minimum_positions, "assetsPrices": $assets_prices, "assetsSizeLots": $assets_size_lots, "assetsWeights": $assets_weights, "maximumAssetsGroupsWeights": $maximum_assets_groups_weights, "portfolioValue": $portfolio_value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Mimicking Portfolio
#
# POST /portfolio/construction/mimicking
# --assets item shape: {assetReturns: list<float>}
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-construction-mimicking create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetReturns: list<float>}
  benchmark_returns: list<float> # benchmarkReturns[t] is the return of the benchmark at the time t; the benchmarkReturns array must have the same length as all the assetReturns arrays
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/construction/mimicking")
  let req_body = {"assets": $assets, "benchmarkReturns": $benchmark_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Random Portfolio
#
# POST /portfolio/construction/random
# --constraints shape: {maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-construction-random create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --constraints: record # shape: {maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  --portfolios: int # The number of portfolios to construct (default: 25)
]: any -> record<portfolios: table<assetsWeights: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/construction/random")
  let req_body = {"assets": $assets, "constraints": $constraints, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Equal Risk Contributions Portfolio
#
# POST /portfolio/optimization/equal-risk-contributions
# --constraints shape: {maximumAssetsWeights?: list<float>, minimumAssetsWeights?: list<float>}
export def "portfolio-optimization-equal-risk-contributions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --constraints: record # shape: {maximumAssetsWeights?: list<float>, minimumAssetsWeights?: list<float>}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/equal-risk-contributions")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Equal Sharpe Ratio Contributions Portfolio
#
# POST /portfolio/optimization/equal-sharpe-ratio-contributions
export def "portfolio-optimization-equal-sharpe-ratio-contributions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  risk_free_rate: float # The risk free rate
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/equal-sharpe-ratio-contributions")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Equal Volatility Weighted Portfolio
#
# POST /portfolio/optimization/equal-volatility-weighted
export def "portfolio-optimization-equal-volatility-weighted create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_volatilities: list<float> # assetsVolatilities[i] is the volatility of the asset i
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/equal-volatility-weighted")
  let req_body = {"assets": $assets, "assetsVolatilities": $assets_volatilities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Equal Weighted Portfolio
#
# POST /portfolio/optimization/equal-weighted
export def "portfolio-optimization-equal-weighted create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/equal-weighted")
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Hierarchical Risk Parity Portfolio
#
# POST /portfolio/optimization/hierarchical-risk-parity
# --constraints shape: {maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-optimization-hierarchical-risk-parity create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --clustering-method: string@clustering-method-completer # The hierarchical clustering method to use (default: singleLinkage)
  --clustering-ordering: string@clustering-ordering-completer # The order to impose on the hierarchical clustering tree leaves (default: r-hclust)
  --constraints: record # shape: {maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/hierarchical-risk-parity")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "clusteringMethod": $clustering_method, "clusteringOrdering": $clustering_ordering, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Hierarchical Clustering-Based Risk Parity Portfolio
#
# POST /portfolio/optimization/hierarchical-risk-parity/clustering-based
# --constraints shape: {maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-optimization-hierarchical-risk-parity-clustering-based create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --across-cluster-allocation-method: string@across-cluster-allocation-method-completer # The allocation method to use across clusters (default: equalWeighting)
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --clustering-method: string@clustering-method-completer # The hierarchical clustering method to use (default: wardLinkage)
  --clustering-ordering: string@clustering-ordering-completer # The order to impose on the hierarchical clustering tree leaves (default: r-hclust)
  --clusters: int # The number of clusters to use in the hierarchical clustering tree; if not provided, the number of clusters to use is computed using the gap statistic method, as described in the first reference
  --constraints: record # shape: {maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  --within-cluster-allocation-method: string@within-cluster-allocation-method-completer # The allocation method to use within clusters (default: equalWeighting)
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/hierarchical-risk-parity/clustering-based")
  let req_body = {"acrossClusterAllocationMethod": $across_cluster_allocation_method, "assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "clusteringMethod": $clustering_method, "clusteringOrdering": $clustering_ordering, "clusters": $clusters, "constraints": $constraints, "withinClusterAllocationMethod": $within_cluster_allocation_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Inverse Variance Weighted Portfolio
#
# POST /portfolio/optimization/inverse-variance-weighted
export def "portfolio-optimization-inverse-variance-weighted create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_variances: list<float> # assetsVariances[i] is the variance of the asset i
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/inverse-variance-weighted")
  let req_body = {"assets": $assets, "assetsVariances": $assets_variances} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Inverse Volatility Weighted Portfolio
#
# POST /portfolio/optimization/inverse-volatility-weighted
export def "portfolio-optimization-inverse-volatility-weighted create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_volatilities: list<float> # assetsVolatilities[i] is the volatility of the asset i
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/inverse-volatility-weighted")
  let req_body = {"assets": $assets, "assetsVolatilities": $assets_volatilities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Market Capitalization Weighted Portfolio
#
# POST /portfolio/optimization/market-capitalization-weighted
export def "portfolio-optimization-market-capitalization-weighted create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_market_capitalizations: list<float> # assetsMarketCapitalizations[i] is the market capitalization of the asset i
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/market-capitalization-weighted")
  let req_body = {"assets": $assets, "assetsMarketCapitalizations": $assets_market_capitalizations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Maximum Decorrelation Portfolio
#
# POST /portfolio/optimization/maximum-decorrelation
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-decorrelation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --assets-returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-decorrelation")
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Maximum Return Portfolio
#
# POST /portfolio/optimization/maximum-return
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-return create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-return")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Diversified Maximum Return Portfolio
#
# POST /portfolio/optimization/maximum-return/diversified
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-return-diversified create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-return/diversified")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Subset Resampling-Based Maximum Return Portfolio
#
# POST /portfolio/optimization/maximum-return/subset-resampling-based
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-return-subset-resampling-based create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  --subset-portfolios: int # The number of subset portfolios to compute; only applicable if the enumeration method for the subset portfolios is random sampling (default: 128)
  --subset-portfolios-aggregation-method: string@subset-portfolios-aggregation-method-completer # The method to aggregate the subset portfolios (default: average)
  --subset-portfolios-enumeration-method: string@subset-portfolios-enumeration-method-completer # The method to enumerate the subset portfolios (default: randomSampling)
  --subset-size: int # The number of assets to include in each subset portfolio; defaults to a value of order the square root of the total number of assets
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-return/subset-resampling-based")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "subsetPortfolios": $subset_portfolios, "subsetPortfoliosAggregationMethod": $subset_portfolios_aggregation_method, "subsetPortfoliosEnumerationMethod": $subset_portfolios_enumeration_method, "subsetSize": $subset_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Maximum Sharpe Ratio Portfolio
#
# POST /portfolio/optimization/maximum-sharpe-ratio
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-sharpe-ratio create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  risk_free_rate: float # The risk free rate
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-sharpe-ratio")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Diversified Maximum Sharpe Ratio Portfolio
#
# POST /portfolio/optimization/maximum-sharpe-ratio/diversified
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-sharpe-ratio-diversified create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  risk_free_rate: float # The risk free rate
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-sharpe-ratio/diversified")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Subset Resampling-Based Maximum Sharpe Ratio Portfolio
#
# POST /portfolio/optimization/maximum-sharpe-ratio/subset-resampling-based
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-sharpe-ratio-subset-resampling-based create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
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
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "riskFreeRate": $risk_free_rate, "subsetPortfolios": $subset_portfolios, "subsetPortfoliosAggregationMethod": $subset_portfolios_aggregation_method, "subsetPortfoliosEnumerationMethod": $subset_portfolios_enumeration_method, "subsetSize": $subset_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Maximum Ulcer Performance Index Portfolio
#
# POST /portfolio/optimization/maximum-ulcer-performance-index
# --assets item shape: {assetPrices: list<float>}
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-optimization-maximum-ulcer-performance-index create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list<float>}
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  risk_free_rate: float # The risk free rate
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-ulcer-performance-index")
  let req_body = {"assets": $assets, "constraints": $constraints, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Mean-Variance Efficient Portfolio
#
# POST /portfolio/optimization/mean-variance-efficient
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float, portfolioReturn?: float, portfolioVolatility?: float, riskTolerance?: float}
export def "portfolio-optimization-mean-variance-efficient create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float, portfolioReturn?: float, portfolioVolatility?: float, riskTolerance?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/mean-variance-efficient")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Diversified Mean-Variance Efficient Portfolio
#
# POST /portfolio/optimization/mean-variance-efficient/diversified
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float, portfolioReturn?: float, portfolioVolatility?: float, riskTolerance?: float}
export def "portfolio-optimization-mean-variance-efficient-diversified create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float, portfolioReturn?: float, portfolioVolatility?: float, riskTolerance?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/mean-variance-efficient/diversified")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Subset Resampling-Based Mean-Variance Efficient Portfolio
#
# POST /portfolio/optimization/mean-variance-efficient/subset-resampling-based
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float, portfolioReturn?: float, portfolioVolatility?: float, riskTolerance?: float}
export def "portfolio-optimization-mean-variance-efficient-subset-resampling-based create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  assets_returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float, portfolioReturn?: float, portfolioVolatility?: float, riskTolerance?: float}
  --subset-portfolios: int # The number of subset portfolios to compute; only applicable if the enumeration method for the subset portfolios is random sampling (default: 128)
  --subset-portfolios-aggregation-method: string@subset-portfolios-aggregation-method-completer # The method to aggregate the subset portfolios (default: average)
  --subset-portfolios-enumeration-method: string@subset-portfolios-enumeration-method-completer # The method to enumerate the subset portfolios (default: randomSampling)
  --subset-size: int # The number of assets to include in each subset portfolio; defaults to a value of order the square root of the total number of assets
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/mean-variance-efficient/subset-resampling-based")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "subsetPortfolios": $subset_portfolios, "subsetPortfoliosAggregationMethod": $subset_portfolios_aggregation_method, "subsetPortfoliosEnumerationMethod": $subset_portfolios_enumeration_method, "subsetSize": $subset_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Minimum Correlation Portfolio
#
# POST /portfolio/optimization/minimum-correlation
export def "portfolio-optimization-minimum-correlation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int
  assets_correlation_matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j; required if assetsReturns is not provided
  assets_volatilities: list<float> # assetsVariances[i] is the volatility of the asset i; required if assetsCorrelationMatrix is provided and assetsVariances is not provided
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/minimum-correlation")
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "assetsVolatilities": $assets_volatilities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Minimum Ulcer Index Portfolio
#
# POST /portfolio/optimization/minimum-ulcer-index
# --assets item shape: {assetPrices: list<float>}
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-optimization-minimum-ulcer-index create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list<float>}
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/minimum-ulcer-index")
  let req_body = {"assets": $assets, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Minimum Variance Portfolio
#
# POST /portfolio/optimization/minimum-variance
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-optimization-minimum-variance create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/minimum-variance")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Diversified Minimum Variance Portfolio
#
# POST /portfolio/optimization/minimum-variance/diversified
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-optimization-minimum-variance-diversified create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, deltaReturn?: float, deltaVolatility?: float, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/minimum-variance/diversified")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Subset Resampling-Based Minimum Variance Portfolio
#
# POST /portfolio/optimization/minimum-variance/subset-resampling-based
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-optimization-minimum-variance-subset-resampling-based create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --assets-returns: list<float> # assetsReturns[i] is the arithmetic return of asset i
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
  --subset-portfolios: int # The number of subset portfolios to compute; only applicable if the enumeration method for the subset portfolios is random sampling (default: 128)
  --subset-portfolios-aggregation-method: string@subset-portfolios-aggregation-method-completer # The method to aggregate the subset portfolios (default: average)
  --subset-portfolios-enumeration-method: string@subset-portfolios-enumeration-method-completer # The method to enumerate the subset portfolios (default: randomSampling)
  --subset-size: int # The number of assets to include in each subset portfolio; defaults to a value of order the square root of the total number of assets
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/minimum-variance/subset-resampling-based")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "subsetPortfolios": $subset_portfolios, "subsetPortfoliosAggregationMethod": $subset_portfolios_aggregation_method, "subsetPortfoliosEnumerationMethod": $subset_portfolios_enumeration_method, "subsetSize": $subset_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Most Diversified Portfolio
#
# POST /portfolio/optimization/most-diversified
# --constraints shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
export def "portfolio-optimization-most-diversified create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: int # The number of assets
  assets_covariance_matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
  --constraints: record # shape: {assetsGroups?: list, assetsGroupsMatrix?: list, maximumAssetsGroupsWeights?: list<float>, maximumAssetsWeights?: list<float>, maximumPortfolioExposure?: float, minimumAssetsWeights?: list<float>, minimumPortfolioExposure?: float}
]: any -> record<assetsWeights: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/most-diversified")
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Drift-weight Portfolio Rebalancing
#
# POST /portfolio/simulation/rebalancing/drift-weight
# --assets item shape: {assetPrices: list<float>}
# --portfolios item shape: {assetsWeights: list<float>}
export def "portfolio-simulation-rebalancing-drift-weight create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list<float>}
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> record<portfolios: table<portfolioValues: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/simulation/rebalancing/drift-weight")
  let req_body = {"assets": $assets, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Fixed-weight Portfolio Rebalancing
#
# POST /portfolio/simulation/rebalancing/fixed-weight
# --assets item shape: {assetPrices: list<float>}
# --portfolios item shape: {assetsWeights: list<float>}
export def "portfolio-simulation-rebalancing-fixed-weight create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list<float>}
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> record<portfolios: table<portfolioValues: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/simulation/rebalancing/fixed-weight")
  let req_body = {"assets": $assets, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Random-weight Portfolio Rebalancing
#
# POST /portfolio/simulation/rebalancing/random-weight
# --assets item shape: {assetPrices: list<float>}
export def "portfolio-simulation-rebalancing-random-weight create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  assets: list # item shape: {assetPrices: list<float>}
  --portfolios: int # The number of portfolios to simulate (default: 25)
]: any -> record<portfolios: table<portfolioValues: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/simulation/rebalancing/random-weight")
  let req_body = {"assets": $assets, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
