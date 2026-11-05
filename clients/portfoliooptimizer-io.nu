# Auto-generated client for Portfolio Optimizer v1.0.9
# Source: https://api.apis.guru/v2/specs/portfoliooptimizer.io/1.0.9/openapi.json
# Auth: --token flag or $env.PORTFOLIO_OPTIMIZER_TOKEN

const BASE_URL = "https://api.portfoliooptimizer.io/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o PORTFOLIO_OPTIMIZER_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-api-key" => { {scheme: $scheme, headers: {"X-API-Key": $token_val}, query: "", location: "header"} }
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
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["post-assets-analysis-absorption-ratio" "post-assets-analysis-turbulence-index" "post-assets-correlation-matrix" "post-assets-correlation-matrix-bounds" "post-assets-correlation-matrix-denoised" "post-assets-correlation-matrix-distance" "post-assets-correlation-matrix-effective-rank" "post-assets-correlation-matrix-informativeness" "post-assets-correlation-matrix-nearest" "post-assets-correlation-matrix-random" "post-assets-correlation-matrix-shrinkage" "post-assets-correlation-matrix-theory-implied" "post-assets-correlation-matrix-validation" "post-assets-covariance-matrix" "post-assets-covariance-matrix-effective-rank" "post-assets-covariance-matrix-exponentially-weighted" "post-assets-covariance-matrix-validation" "post-assets-kurtosis" "post-assets-prices-adjusted" "post-assets-prices-adjusted-forward" "post-assets-returns" "post-assets-returns-average" "post-assets-returns-simulation-bootstrap" "post-assets-skewness" "post-assets-variance" "post-assets-volatility" "post-factors-residualization" "post-portfolio-analysis-alpha" "post-portfolio-analysis-beta" "post-portfolio-analysis-conditional-value-at-risk" "post-portfolio-analysis-contributions-return" "post-portfolio-analysis-contributions-risk" "post-portfolio-analysis-correlation-spectrum" "post-portfolio-analysis-diversification-ratio" "post-portfolio-analysis-drawdowns" "post-portfolio-analysis-effective-number-of-bets" "post-portfolio-analysis-factors-exposures" "post-portfolio-analysis-mean-variance-efficient-frontier" "post-portfolio-analysis-mean-variance-minimum-variance-frontier" "post-portfolio-analysis-return" "post-portfolio-analysis-returns-average" "post-portfolio-analysis-sharpe-ratio" "post-portfolio-analysis-sharpe-ratio-bias-adjusted" "post-portfolio-analysis-sharpe-ratio-confidence-interval" "post-portfolio-analysis-sharpe-ratio-probabilistic" "post-portfolio-analysis-sharpe-ratio-probabilistic-minimum-track-record-length" "post-portfolio-analysis-tracking-error" "post-portfolio-analysis-ulcer-index" "post-portfolio-analysis-ulcer-performance-index" "post-portfolio-analysis-value-at-risk" "post-portfolio-analysis-volatility" "post-portfolio-construction-investable" "post-portfolio-construction-mimicking" "post-portfolio-construction-random" "post-portfolio-optimization-equal-risk-contributions" "post-portfolio-optimization-equal-sharpe-ratio-contributions" "post-portfolio-optimization-equal-volatility-weighted" "post-portfolio-optimization-equal-weighted" "post-portfolio-optimization-hierarchical-risk-parity" "post-portfolio-optimization-hierarchical-risk-parity-clustering-based" "post-portfolio-optimization-inverse-variance-weighted" "post-portfolio-optimization-inverse-volatility-weighted" "post-portfolio-optimization-market-capitalization-weighted" "post-portfolio-optimization-maximum-decorrelation" "post-portfolio-optimization-maximum-return" "post-portfolio-optimization-maximum-return-diversified" "post-portfolio-optimization-maximum-return-subset-resampling-based" "post-portfolio-optimization-maximum-sharpe-ratio" "post-portfolio-optimization-maximum-sharpe-ratio-diversified" "post-portfolio-optimization-maximum-sharpe-ratio-subset-resampling-based" "post-portfolio-optimization-maximum-ulcer-performance-index" "post-portfolio-optimization-mean-variance-efficient" "post-portfolio-optimization-mean-variance-efficient-diversified" "post-portfolio-optimization-mean-variance-efficient-subset-resampling-based" "post-portfolio-optimization-minimum-correlation" "post-portfolio-optimization-minimum-ulcer-index" "post-portfolio-optimization-minimum-variance" "post-portfolio-optimization-minimum-variance-diversified" "post-portfolio-optimization-minimum-variance-subset-resampling-based" "post-portfolio-optimization-most-diversified" "post-portfolio-simulation-rebalancing-drift-weight" "post-portfolio-simulation-rebalancing-fixed-weight" "post-portfolio-simulation-rebalancing-random-weight" "commands"] | sort) } | get name | first)
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

# Absorption Ratio
#
# POST /assets/analysis/absorption-ratio
export def "post-assets-analysis-absorption-ratio" [
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
]: any -> oneof<record<assetsAbsorptionRatio: float>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/analysis/absorption-ratio" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsCovarianceMatrixEigenvectors": $assets_covariance_matrix_eigenvectors} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Turbulence Index
#
# POST /assets/analysis/turbulence-index
export def "post-assets-analysis-turbulence-index" [
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
]: any -> oneof<record<assetsTurbulenceIndex: float>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/analysis/turbulence-index" $auth.query)
  let req_body = {"assets": $assets, "assetsAverageReturns": $assets_average_returns, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Correlation Matrix
#
# POST /assets/correlation/matrix
export def "post-assets-correlation-matrix" [
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
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> oneof<record<assetsCorrelationMatrix: list<list<float>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Correlation Matrix Bounds
#
# POST /assets/correlation/matrix/bounds
export def "post-assets-correlation-matrix-bounds" [
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
]: any -> oneof<record<assetsCorrelationMatrixLowerBounds: list<list<float>>, assetsCorrelationMatrixUpperBounds: list<list<float>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/bounds" $auth.query)
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "assetsGroup": $assets_group} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Denoised Correlation Matrix
#
# POST /assets/correlation/matrix/denoised
export def "post-assets-correlation-matrix-denoised" [
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
]: any -> oneof<record<assetsCorrelationMatrix: list<list<float>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/denoised" $auth.query)
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "assetsCorrelationMatrixAspectRatio": $assets_correlation_matrix_aspect_ratio, "denoisingMethod": $denoising_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Correlation Matrix Distance
#
# POST /assets/correlation/matrix/distance
export def "post-assets-correlation-matrix-distance" [
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
]: any -> oneof<record<assetsCorrelationMatrixDistance: float>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/distance" $auth.query)
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "distanceMetric": $distance_metric, "referenceCorrelationMatrix": $reference_correlation_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Correlation Matrix Effective Rank
#
# POST /assets/correlation/matrix/effective-rank
export def "post-assets-correlation-matrix-effective-rank" [
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
]: any -> oneof<record<assetsCorrelationMatrixEffectiveRank: list<list<float>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/effective-rank" $auth.query)
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Correlation Matrix Informativeness
#
# POST /assets/correlation/matrix/informativeness
export def "post-assets-correlation-matrix-informativeness" [
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
]: any -> oneof<record<assetsCorrelationMatrixInformativeness: float>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/informativeness" $auth.query)
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "distanceMetric": $distance_metric} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Nearest Correlation Matrix
#
# POST /assets/correlation/matrix/nearest
export def "post-assets-correlation-matrix-nearest" [
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
]: any -> oneof<record<assetsCorrelationMatrix: list<list<float>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/nearest" $auth.query)
  let req_body = {"assets": $assets, "assetsApproximateCorrelationMatrix": $assets_approximate_correlation_matrix, "assetsFixedCorrelations": $assets_fixed_correlations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Random Correlation Matrix
#
# POST /assets/correlation/matrix/random
export def "post-assets-correlation-matrix-random" [
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
]: any -> oneof<record<assetsCorrelationMatrix: list<list<float>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/random" $auth.query)
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Correlation Matrix Shrinkage
#
# POST /assets/correlation/matrix/shrinkage
export def "post-assets-correlation-matrix-shrinkage" [
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
  shrinkage_factor: float # The shrinkage factor
  --target-equicorrelation-matrix: string@target-equicorrelation-matrix-completer # The shrinkage target correlation matrix
  --target-correlation-matrix: list # targetCorrelationMatrix[i][j] is the target correlation between the asset i and the asset j
]: any -> oneof<record<assetsCorrelationMatrix: list<list<float>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/shrinkage" $auth.query)
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "shrinkageFactor": $shrinkage_factor, "targetEquicorrelationMatrix": $target_equicorrelation_matrix, "targetCorrelationMatrix": $target_correlation_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Theory-Implied Correlation Matrix
#
# POST /assets/correlation/matrix/theory-implied
export def "post-assets-correlation-matrix-theory-implied" [
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
]: any -> oneof<record<assetsCorrelationMatrix: list<list<float>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/theory-implied" $auth.query)
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "clusteringMethod": $clustering_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Correlation Matrix Validation
#
# POST /assets/correlation/matrix/validation
export def "post-assets-correlation-matrix-validation" [
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
]: any -> oneof<record<message: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/correlation/matrix/validation" $auth.query)
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Covariance Matrix
#
# POST /assets/covariance/matrix
export def "post-assets-covariance-matrix" [
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
  --assets-correlation-matrix: list # assetsCorrelationMatrix[i][j] is the correlation between the asset i and the asset j
  --assets-variances: list<float> # assetsVariances[i] is the variance of the asset i
  --assets-volatilities: list<float> # assetsVolatilities[i] is the volatility of the asset i
]: any -> oneof<record<assetsCovarianceMatrix: list<list<float>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/covariance/matrix" $auth.query)
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "assetsVariances": $assets_variances, "assetsVolatilities": $assets_volatilities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Covariance Matrix Effective Rank
#
# POST /assets/covariance/matrix/effective-rank
export def "post-assets-covariance-matrix-effective-rank" [
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
]: any -> oneof<record<assetsCovarianceMatrixEffectiveRank: list<list<float>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/covariance/matrix/effective-rank" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Exponentially Weighted Covariance Matrix
#
# POST /assets/covariance/matrix/exponentially-weighted
export def "post-assets-covariance-matrix-exponentially-weighted" [
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
]: any -> oneof<record<assetsCovarianceMatrix: list<list<float>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/covariance/matrix/exponentially-weighted" $auth.query)
  let req_body = {"assets": $assets, "decayFactor": $decay_factor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Covariance Matrix Validation
#
# POST /assets/covariance/matrix/validation
export def "post-assets-covariance-matrix-validation" [
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
]: any -> oneof<record<message: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/covariance/matrix/validation" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Kurtosis
#
# POST /assets/kurtosis
export def "post-assets-kurtosis" [
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
]: any -> oneof<record<assets: table<assetKurtosis: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/kurtosis" $auth.query)
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Adjusted Prices
#
# POST /assets/prices/adjusted
export def "post-assets-prices-adjusted" [
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
]: any -> oneof<record<assets: table<assetAdjustedPrices: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/prices/adjusted" $auth.query)
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Forward-Adjusted Prices
#
# POST /assets/prices/adjusted/forward
export def "post-assets-prices-adjusted-forward" [
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
]: any -> oneof<record<assets: table<assetAdjustedPrices: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/prices/adjusted/forward" $auth.query)
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Arithmetic Returns
#
# POST /assets/returns
export def "post-assets-returns" [
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
]: any -> oneof<record<assets: table<assetReturns: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/returns" $auth.query)
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Arithmetic Average Return
#
# POST /assets/returns/average
export def "post-assets-returns-average" [
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
]: any -> oneof<record<assets: table<assetAverageReturn: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/returns/average" $auth.query)
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Bootstrap
#
# POST /assets/returns/simulation/bootstrap
export def "post-assets-returns-simulation-bootstrap" [
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
]: any -> oneof<record<simulations: table<assets: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/returns/simulation/bootstrap" $auth.query)
  let req_body = {"assets": $assets, "bootstrapAverageBlockLength": $bootstrap_average_block_length, "bootstrapBlockLength": $bootstrap_block_length, "bootstrapMethod": $bootstrap_method, "simulations": $simulations, "simulationsLength": $simulations_length} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Skewness
#
# POST /assets/skewness
export def "post-assets-skewness" [
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
]: any -> oneof<record<assets: table<assetSkewness: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/skewness" $auth.query)
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Variance
#
# POST /assets/variance
export def "post-assets-variance" [
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
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> oneof<record<assets: table<assetVariance: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/variance" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Volatility
#
# POST /assets/volatility
export def "post-assets-volatility" [
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
  --assets-covariance-matrix: list # assetsCovarianceMatrix[i][j] is the covariance between the asset i and the asset j
]: any -> oneof<record<assets: table<assetVolatility: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets/volatility" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Residualization
#
# POST /factors/residualization
export def "post-factors-residualization" [
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
]: any -> oneof<record<residualizedFactorReturns: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/factors/residualization" $auth.query)
  let req_body = {"factors": $factors, "residualizedFactor": $residualized_factor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Alpha
#
# POST /portfolio/analysis/alpha
export def "post-portfolio-analysis-alpha" [
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
  --risk-free-rate: float # The risk free rate, assumed to be constant for any time t
  --risk-free-returns: list<float> # riskFreeReturns[t] is the risk free return at the time t; the riskFreeReturns array must have the same length as all the portfolioReturns arrays
]: any -> oneof<record<portfolios: table<portfolioAlpha: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/alpha" $auth.query)
  let req_body = {"benchmarkReturns": $benchmark_returns, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate, "riskFreeReturns": $risk_free_returns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Beta
#
# POST /portfolio/analysis/beta
export def "post-portfolio-analysis-beta" [
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
  --risk-free-rate: float # The risk free rate, assumed to be constant for any time t
  --risk-free-returns: list<float> # riskFreeReturns[t] is the risk free return at the time t; the riskFreeReturns array must have the same length as all the portfolioReturns arrays
]: any -> oneof<record<portfolios: table<portfolioBeta: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/beta" $auth.query)
  let req_body = {"benchmarkReturns": $benchmark_returns, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate, "riskFreeReturns": $risk_free_returns} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Conditional Value At Risk
#
# POST /portfolio/analysis/conditional-value-at-risk
export def "post-portfolio-analysis-conditional-value-at-risk" [
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
]: any -> oneof<record<portfolios: table<portfolioConditionalValueAtRisk: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/conditional-value-at-risk" $auth.query)
  let req_body = {"alpha": $alpha, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Return Contributions
#
# POST /portfolio/analysis/contributions/return
export def "post-portfolio-analysis-contributions-return" [
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
]: any -> oneof<record<portfolios: table<assetsGroupsReturnContributions: list, assetsReturnContributions: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/contributions/return" $auth.query)
  let req_body = {"assets": $assets, "assetsGroups": $assets_groups, "assetsReturns": $assets_returns, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Risk Contributions
#
# POST /portfolio/analysis/contributions/risk
export def "post-portfolio-analysis-contributions-risk" [
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
]: any -> oneof<record<portfolios: table<assetsGroupsRiskContributions: list, assetsRiskContributions: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/contributions/risk" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsGroups": $assets_groups, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Correlation Spectrum
#
# POST /portfolio/analysis/correlation-spectrum
export def "post-portfolio-analysis-correlation-spectrum" [
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
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> oneof<record<portfolios: table<portfolioCorrelationSpectrum: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/correlation-spectrum" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Diversification Ratio
#
# POST /portfolio/analysis/diversification-ratio
export def "post-portfolio-analysis-diversification-ratio" [
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
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> oneof<record<portfolios: table<portfolioDiversificationRatio: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/diversification-ratio" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Drawdowns
#
# POST /portfolio/analysis/drawdowns
export def "post-portfolio-analysis-drawdowns" [
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
]: any -> oneof<record<portfolios: table<portfolioDrawdowns: list, portfolioWorstDrawdowns: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/drawdowns" $auth.query)
  let req_body = {"portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Effective Number of Bets
#
# POST /portfolio/analysis/effective-number-of-bets
export def "post-portfolio-analysis-effective-number-of-bets" [
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
]: any -> oneof<record<portfolios: table<portfolioEffectiveNumberOfBets: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/effective-number-of-bets" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "factorsExtractionMethod": $factors_extraction_method, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Factor Exposures
#
# POST /portfolio/analysis/factors/exposures
export def "post-portfolio-analysis-factors-exposures" [
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
]: any -> oneof<record<portfolios: table<portfolioAlpha: float, portfolioBetas: list, portfolioRSquared: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/factors/exposures" $auth.query)
  let req_body = {"factors": $factors, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Mean-Variance Efficient Frontier
#
# POST /portfolio/analysis/mean-variance/efficient-frontier
export def "post-portfolio-analysis-mean-variance-efficient-frontier" [
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
]: any -> oneof<record<portfolios: table<assetsWeights: list, portfolioReturn: float, portfolioVolatility: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/mean-variance/efficient-frontier" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Mean-Variance Minimum Variance Frontier
#
# POST /portfolio/analysis/mean-variance/minimum-variance-frontier
export def "post-portfolio-analysis-mean-variance-minimum-variance-frontier" [
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
]: any -> oneof<record<portfolios: table<assetsWeights: list, portfolioReturn: float, portfolioVolatility: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/mean-variance/minimum-variance-frontier" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Arithmetic Return
#
# POST /portfolio/analysis/return
export def "post-portfolio-analysis-return" [
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
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> oneof<record<portfolios: table<portfolioReturn: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/return" $auth.query)
  let req_body = {"assets": $assets, "assetsReturns": $assets_returns, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Arithmetic Average Return
#
# POST /portfolio/analysis/returns/average
export def "post-portfolio-analysis-returns-average" [
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
]: any -> oneof<record<portfolios: table<portfolioAverageReturn: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/returns/average" $auth.query)
  let req_body = {"portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Sharpe Ratio
#
# POST /portfolio/analysis/sharpe-ratio
export def "post-portfolio-analysis-sharpe-ratio" [
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
  portfolios: list # item shape: {assetsWeights: list<float>}
  risk_free_rate: float # The risk free rate
]: any -> oneof<record<portfolios: table<portfolioSharpeRatio: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/sharpe-ratio" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Bias-Adjusted Sharpe Ratio
#
# POST /portfolio/analysis/sharpe-ratio/bias-adjusted
export def "post-portfolio-analysis-sharpe-ratio-bias-adjusted" [
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
]: any -> oneof<record<portfolios: table<portfolioBiasAdjustedSharpeRatio: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/sharpe-ratio/bias-adjusted" $auth.query)
  let req_body = {"portfolios": $portfolios, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Sharpe Ratio Confidence Interval
#
# POST /portfolio/analysis/sharpe-ratio/confidence-interval
export def "post-portfolio-analysis-sharpe-ratio-confidence-interval" [
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
]: any -> oneof<record<portfolios: table<portfolioSharpeRatioConfidenceInterval: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/sharpe-ratio/confidence-interval" $auth.query)
  let req_body = {"confidenceIntervalType": $confidence_interval_type, "confidenceLevel": $confidence_level, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Probabilistic Sharpe Ratio
#
# POST /portfolio/analysis/sharpe-ratio/probabilistic
export def "post-portfolio-analysis-sharpe-ratio-probabilistic" [
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
  portfolios: list # item shape: {portfolioValues: list<float>}
  risk_free_rate: float # The risk free rate
  --benchmark-values: list<float> # benchmarkValues[t] is the value of the benchmark at the time t; the benchmarkValues array must have the same length as all the portfolioValues arrays
]: any -> oneof<record<portfolios: table<portfolioProbabilisticSharpeRatio: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/sharpe-ratio/probabilistic" $auth.query)
  let req_body = {"benchmarkSharpeRatio": $benchmark_sharpe_ratio, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate, "benchmarkValues": $benchmark_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Minimum Track Record Length
#
# POST /portfolio/analysis/sharpe-ratio/probabilistic/minimum-track-record-length
export def "post-portfolio-analysis-sharpe-ratio-probabilistic-minimum-track-record-length" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  benchmark_sharpe_ratio: float # The Sharpe ratio of the benchmark, in the same sampling frequency as the sampling frequency of the portfolio values
  --confidence-level: float # The confidence level of the minimum track record length, in percentage (default: 0.95)
  portfolios: list # item shape: {portfolioValues: list<float>}
  risk_free_rate: float # The risk free rate
  --benchmark-values: list<float> # benchmarkValues[t] is the value of the benchmark at the time t; the benchmarkValues array must have the same length as all the portfolioValues arrays
]: any -> oneof<record<portfolios: table<portfolioSharpeRatioMinimumTrackRecordLength: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/sharpe-ratio/probabilistic/minimum-track-record-length" $auth.query)
  let req_body = {"benchmarkSharpeRatio": $benchmark_sharpe_ratio, "confidenceLevel": $confidence_level, "portfolios": $portfolios, "riskFreeRate": $risk_free_rate, "benchmarkValues": $benchmark_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Tracking Error
#
# POST /portfolio/analysis/tracking-error
export def "post-portfolio-analysis-tracking-error" [
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
]: any -> oneof<record<portfolios: table<portfolioTrackingError: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/tracking-error" $auth.query)
  let req_body = {"benchmarkReturns": $benchmark_returns, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Ulcer Index
#
# POST /portfolio/analysis/ulcer-index
export def "post-portfolio-analysis-ulcer-index" [
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
]: any -> oneof<record<portfolios: table<portfolioUlcerIndex: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/ulcer-index" $auth.query)
  let req_body = {"portfolios": $portfolios, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Ulcer Performance Index
#
# POST /portfolio/analysis/ulcer-performance-index
export def "post-portfolio-analysis-ulcer-performance-index" [
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
]: any -> oneof<record<portfolios: table<portfolioUlcerPerformanceIndex: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/ulcer-performance-index" $auth.query)
  let req_body = {"portfolios": $portfolios, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Value At Risk
#
# POST /portfolio/analysis/value-at-risk
export def "post-portfolio-analysis-value-at-risk" [
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
]: any -> oneof<record<portfolios: table<portfolioValueAtRisk: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/value-at-risk" $auth.query)
  let req_body = {"alpha": $alpha, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Volatility
#
# POST /portfolio/analysis/volatility
export def "post-portfolio-analysis-volatility" [
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
  portfolios: list # item shape: {assetsWeights: list<float>}
]: any -> oneof<record<portfolios: table<portfolioVolatility: float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/analysis/volatility" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Investable Portfolio
#
# POST /portfolio/construction/investable
export def "post-portfolio-construction-investable" [
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
]: any -> oneof<record<assetsPositions: list<float>, assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/construction/investable" $auth.query)
  let req_body = {"assets": $assets, "assetsGroups": $assets_groups, "assetsGroupsWeights": $assets_groups_weights, "assetsMinimumNotionalValues": $assets_minimum_notional_values, "assetsMinimumPositions": $assets_minimum_positions, "assetsPrices": $assets_prices, "assetsSizeLots": $assets_size_lots, "assetsWeights": $assets_weights, "maximumAssetsGroupsWeights": $maximum_assets_groups_weights, "portfolioValue": $portfolio_value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Mimicking Portfolio
#
# POST /portfolio/construction/mimicking
export def "post-portfolio-construction-mimicking" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/construction/mimicking" $auth.query)
  let req_body = {"assets": $assets, "benchmarkReturns": $benchmark_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Random Portfolio
#
# POST /portfolio/construction/random
export def "post-portfolio-construction-random" [
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
]: any -> oneof<record<portfolios: table<assetsWeights: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/construction/random" $auth.query)
  let req_body = {"assets": $assets, "constraints": $constraints, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Equal Risk Contributions Portfolio
#
# POST /portfolio/optimization/equal-risk-contributions
export def "post-portfolio-optimization-equal-risk-contributions" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/equal-risk-contributions" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Equal Sharpe Ratio Contributions Portfolio
#
# POST /portfolio/optimization/equal-sharpe-ratio-contributions
export def "post-portfolio-optimization-equal-sharpe-ratio-contributions" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/equal-sharpe-ratio-contributions" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Equal Volatility Weighted Portfolio
#
# POST /portfolio/optimization/equal-volatility-weighted
export def "post-portfolio-optimization-equal-volatility-weighted" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/equal-volatility-weighted" $auth.query)
  let req_body = {"assets": $assets, "assetsVolatilities": $assets_volatilities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Equal Weighted Portfolio
#
# POST /portfolio/optimization/equal-weighted
export def "post-portfolio-optimization-equal-weighted" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/equal-weighted" $auth.query)
  let req_body = {"assets": $assets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Hierarchical Risk Parity Portfolio
#
# POST /portfolio/optimization/hierarchical-risk-parity
export def "post-portfolio-optimization-hierarchical-risk-parity" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/hierarchical-risk-parity" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "clusteringMethod": $clustering_method, "clusteringOrdering": $clustering_ordering, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Hierarchical Clustering-Based Risk Parity Portfolio
#
# POST /portfolio/optimization/hierarchical-risk-parity/clustering-based
export def "post-portfolio-optimization-hierarchical-risk-parity-clustering-based" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/hierarchical-risk-parity/clustering-based" $auth.query)
  let req_body = {"acrossClusterAllocationMethod": $across_cluster_allocation_method, "assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "clusteringMethod": $clustering_method, "clusteringOrdering": $clustering_ordering, "clusters": $clusters, "constraints": $constraints, "withinClusterAllocationMethod": $within_cluster_allocation_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Inverse Variance Weighted Portfolio
#
# POST /portfolio/optimization/inverse-variance-weighted
export def "post-portfolio-optimization-inverse-variance-weighted" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/inverse-variance-weighted" $auth.query)
  let req_body = {"assets": $assets, "assetsVariances": $assets_variances} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Inverse Volatility Weighted Portfolio
#
# POST /portfolio/optimization/inverse-volatility-weighted
export def "post-portfolio-optimization-inverse-volatility-weighted" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/inverse-volatility-weighted" $auth.query)
  let req_body = {"assets": $assets, "assetsVolatilities": $assets_volatilities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Market Capitalization Weighted Portfolio
#
# POST /portfolio/optimization/market-capitalization-weighted
export def "post-portfolio-optimization-market-capitalization-weighted" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/market-capitalization-weighted" $auth.query)
  let req_body = {"assets": $assets, "assetsMarketCapitalizations": $assets_market_capitalizations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Maximum Decorrelation Portfolio
#
# POST /portfolio/optimization/maximum-decorrelation
export def "post-portfolio-optimization-maximum-decorrelation" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-decorrelation" $auth.query)
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Maximum Return Portfolio
#
# POST /portfolio/optimization/maximum-return
export def "post-portfolio-optimization-maximum-return" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-return" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Diversified Maximum Return Portfolio
#
# POST /portfolio/optimization/maximum-return/diversified
export def "post-portfolio-optimization-maximum-return-diversified" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-return/diversified" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Subset Resampling-Based Maximum Return Portfolio
#
# POST /portfolio/optimization/maximum-return/subset-resampling-based
export def "post-portfolio-optimization-maximum-return-subset-resampling-based" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-return/subset-resampling-based" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "subsetPortfolios": $subset_portfolios, "subsetPortfoliosAggregationMethod": $subset_portfolios_aggregation_method, "subsetPortfoliosEnumerationMethod": $subset_portfolios_enumeration_method, "subsetSize": $subset_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Maximum Sharpe Ratio Portfolio
#
# POST /portfolio/optimization/maximum-sharpe-ratio
export def "post-portfolio-optimization-maximum-sharpe-ratio" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-sharpe-ratio" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Diversified Maximum Sharpe Ratio Portfolio
#
# POST /portfolio/optimization/maximum-sharpe-ratio/diversified
export def "post-portfolio-optimization-maximum-sharpe-ratio-diversified" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-sharpe-ratio/diversified" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Subset Resampling-Based Maximum Sharpe Ratio Portfolio
#
# POST /portfolio/optimization/maximum-sharpe-ratio/subset-resampling-based
export def "post-portfolio-optimization-maximum-sharpe-ratio-subset-resampling-based" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-sharpe-ratio/subset-resampling-based" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "riskFreeRate": $risk_free_rate, "subsetPortfolios": $subset_portfolios, "subsetPortfoliosAggregationMethod": $subset_portfolios_aggregation_method, "subsetPortfoliosEnumerationMethod": $subset_portfolios_enumeration_method, "subsetSize": $subset_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Maximum Ulcer Performance Index Portfolio
#
# POST /portfolio/optimization/maximum-ulcer-performance-index
export def "post-portfolio-optimization-maximum-ulcer-performance-index" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/maximum-ulcer-performance-index" $auth.query)
  let req_body = {"assets": $assets, "constraints": $constraints, "riskFreeRate": $risk_free_rate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Mean-Variance Efficient Portfolio
#
# POST /portfolio/optimization/mean-variance-efficient
export def "post-portfolio-optimization-mean-variance-efficient" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/mean-variance-efficient" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Diversified Mean-Variance Efficient Portfolio
#
# POST /portfolio/optimization/mean-variance-efficient/diversified
export def "post-portfolio-optimization-mean-variance-efficient-diversified" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/mean-variance-efficient/diversified" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Subset Resampling-Based Mean-Variance Efficient Portfolio
#
# POST /portfolio/optimization/mean-variance-efficient/subset-resampling-based
export def "post-portfolio-optimization-mean-variance-efficient-subset-resampling-based" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/mean-variance-efficient/subset-resampling-based" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "subsetPortfolios": $subset_portfolios, "subsetPortfoliosAggregationMethod": $subset_portfolios_aggregation_method, "subsetPortfoliosEnumerationMethod": $subset_portfolios_enumeration_method, "subsetSize": $subset_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Minimum Correlation Portfolio
#
# POST /portfolio/optimization/minimum-correlation
export def "post-portfolio-optimization-minimum-correlation" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/minimum-correlation" $auth.query)
  let req_body = {"assets": $assets, "assetsCorrelationMatrix": $assets_correlation_matrix, "assetsVolatilities": $assets_volatilities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Minimum Ulcer Index Portfolio
#
# POST /portfolio/optimization/minimum-ulcer-index
export def "post-portfolio-optimization-minimum-ulcer-index" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/minimum-ulcer-index" $auth.query)
  let req_body = {"assets": $assets, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Minimum Variance Portfolio
#
# POST /portfolio/optimization/minimum-variance
export def "post-portfolio-optimization-minimum-variance" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/minimum-variance" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Diversified Minimum Variance Portfolio
#
# POST /portfolio/optimization/minimum-variance/diversified
export def "post-portfolio-optimization-minimum-variance-diversified" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/minimum-variance/diversified" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Subset Resampling-Based Minimum Variance Portfolio
#
# POST /portfolio/optimization/minimum-variance/subset-resampling-based
export def "post-portfolio-optimization-minimum-variance-subset-resampling-based" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/minimum-variance/subset-resampling-based" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "assetsReturns": $assets_returns, "constraints": $constraints, "subsetPortfolios": $subset_portfolios, "subsetPortfoliosAggregationMethod": $subset_portfolios_aggregation_method, "subsetPortfoliosEnumerationMethod": $subset_portfolios_enumeration_method, "subsetSize": $subset_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Most Diversified Portfolio
#
# POST /portfolio/optimization/most-diversified
export def "post-portfolio-optimization-most-diversified" [
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
]: any -> oneof<record<assetsWeights: list<float>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/optimization/most-diversified" $auth.query)
  let req_body = {"assets": $assets, "assetsCovarianceMatrix": $assets_covariance_matrix, "constraints": $constraints} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Drift-weight Portfolio Rebalancing
#
# POST /portfolio/simulation/rebalancing/drift-weight
export def "post-portfolio-simulation-rebalancing-drift-weight" [
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
]: any -> oneof<record<portfolios: table<portfolioValues: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/simulation/rebalancing/drift-weight" $auth.query)
  let req_body = {"assets": $assets, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Fixed-weight Portfolio Rebalancing
#
# POST /portfolio/simulation/rebalancing/fixed-weight
export def "post-portfolio-simulation-rebalancing-fixed-weight" [
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
]: any -> oneof<record<portfolios: table<portfolioValues: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/simulation/rebalancing/fixed-weight" $auth.query)
  let req_body = {"assets": $assets, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Random-weight Portfolio Rebalancing
#
# POST /portfolio/simulation/rebalancing/random-weight
export def "post-portfolio-simulation-rebalancing-random-weight" [
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
]: any -> oneof<record<portfolios: table<portfolioValues: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portfolio/simulation/rebalancing/random-weight" $auth.query)
  let req_body = {"assets": $assets, "portfolios": $portfolios} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
