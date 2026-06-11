# Auto-generated client for Financial Modeling Prep API v1.0.0
# Source: https://raw.githubusercontent.com/DigiBugCat/fmp-openapi/main/fmp-openapi.yaml
# Auth: --token flag or $env.FINANCIAL_MODELING_PREP_API_TOKEN

const BASE_URL = "https://financialmodelingprep.com/stable"
const DEFAULT_AUTH = "query-apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FINANCIAL_MODELING_PREP_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-apikey" => { {headers: {}, query: $"apikey=($token_val)"} }
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
def base-url-completer [] { ["https://financialmodelingprep.com/stable"] }
def auth-scheme-completer [] { ["query-apikey"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "acquisition-of-beneficial-ownership acquisitionOwnership" } } | get name | first)
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

# Get acquisition ownership data
#
# GET /acquisition-of-beneficial-ownership
# operationId: acquisitionOwnership
export def "acquisition-of-beneficial-ownership acquisitionOwnership" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<cik: string, symbol: string, filingDate: string, acceptedDate: string, cusip: string, nameOfReportingPerson: string, citizenshipOrPlaceOfOrganization: string, soleVotingPower: string, sharedVotingPower: string, soleDispositivePower: string, sharedDispositivePower: string, amountBeneficiallyOwned: string, percentOfClass: string, typeOfReportingPerson: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/acquisition-of-beneficial-ownership" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List actively trading companies
#
# GET /actively-trading-list
# operationId: activelyTradingList
export def "actively-trading-list activelyTradingList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/actively-trading-list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get aftermarket quote
#
# GET /aftermarket-quote
# operationId: aftermarketQuote
export def "aftermarket-quote aftermarketQuote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, bidSize: int, bidPrice: float, askSize: int, askPrice: float, volume: int, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aftermarket-quote" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get aftermarket trade data
#
# GET /aftermarket-trade
# operationId: aftermarketTrade
export def "aftermarket-trade aftermarketTrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, price: float, tradeSize: string, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aftermarket-trade" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get market hours for all exchanges
#
# GET /all-exchange-market-hours
# operationId: allExchangeMarketHours
export def "all-exchange-market-hours allExchangeMarketHours" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<exchange: string, name: string, openingHour: string, closingHour: string, timezone: string, isMarketOpen: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/all-exchange-market-hours")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all SEC industry classifications
#
# GET /all-industry-classification
# operationId: secAllIndustryClassification
export def "all-industry-classification secAllIndustryClassification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, name: string, cik: string, sicCode: string, industryTitle: string, businessAddress: string, phoneNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/all-industry-classification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get analyst financial estimates
#
# GET /analyst-estimates
# operationId: financialEstimates
export def "analyst-estimates financialEstimates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --period: string # Period: annual, quarter
  --page: int # Page number
  --limit: int # Max results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analyst-estimates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available countries
#
# GET /available-countries
# operationId: availableCountries
export def "available-countries availableCountries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<country: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/available-countries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available exchanges
#
# GET /available-exchanges
# operationId: availableExchanges
export def "available-exchanges availableExchanges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<exchange: string, name: string, countryName: string, countryCode: string, symbolSuffix: string, delay: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/available-exchanges")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available industries
#
# GET /available-industries
# operationId: availableIndustries
export def "available-industries availableIndustries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<industry: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/available-industries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available sectors
#
# GET /available-sectors
# operationId: availableSectors
export def "available-sectors availableSectors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<sector: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/available-sectors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get symbols with available transcripts
#
# GET /available-transcript-symbols
# operationId: availableTranscriptSymbols
export def "available-transcript-symbols availableTranscriptSymbols" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/available-transcript-symbols")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get balance sheet statement
#
# GET /balance-sheet-statement
# operationId: balanceSheetStatement
export def "balance-sheet-statement balanceSheetStatement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --period: string # Period: annual, quarter
  --limit: int # Max results
]: nothing -> table<date: string, symbol: string, reportedCurrency: string, cik: string, filingDate: string, acceptedDate: string, fiscalYear: string, period: string, cashAndCashEquivalents: int, shortTermInvestments: int, cashAndShortTermInvestments: int, netReceivables: int, accountsReceivables: int, otherReceivables: int, inventory: int, prepaids: int, otherCurrentAssets: int, totalCurrentAssets: int, propertyPlantEquipmentNet: int, goodwill: int, intangibleAssets: int, goodwillAndIntangibleAssets: int, longTermInvestments: int, taxAssets: int, otherNonCurrentAssets: int, totalNonCurrentAssets: int, otherAssets: int, totalAssets: int, totalPayables: int, accountPayables: int, otherPayables: int, accruedExpenses: int, shortTermDebt: int, capitalLeaseObligationsCurrent: int, taxPayables: int, deferredRevenue: int, otherCurrentLiabilities: int, totalCurrentLiabilities: int, longTermDebt: int, capitalLeaseObligationsNonCurrent: int, deferredRevenueNonCurrent: int, deferredTaxLiabilitiesNonCurrent: int, otherNonCurrentLiabilities: int, totalNonCurrentLiabilities: int, otherLiabilities: int, capitalLeaseObligations: int, totalLiabilities: int, treasuryStock: int, preferredStock: int, commonStock: int, retainedEarnings: int, additionalPaidInCapital: int, accumulatedOtherComprehensiveIncomeLoss: int, otherTotalStockholdersEquity: int, totalStockholdersEquity: int, totalEquity: int, minorityInterest: int, totalLiabilitiesAndTotalEquity: int, totalInvestments: int, totalDebt: int, netDebt: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/balance-sheet-statement" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get balance sheet growth rates
#
# GET /balance-sheet-statement-growth
# operationId: balanceSheetStatementGrowth
export def "balance-sheet-statement-growth balanceSheetStatementGrowth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --period: string # Period: annual, quarter
  --limit: int # Max results
]: nothing -> table<symbol: string, date: string, fiscalYear: string, period: string, reportedCurrency: string, growthCashAndCashEquivalents: float, growthShortTermInvestments: float, growthCashAndShortTermInvestments: float, growthNetReceivables: float, growthInventory: float, growthOtherCurrentAssets: float, growthTotalCurrentAssets: float, growthPropertyPlantEquipmentNet: float, growthGoodwill: int, growthIntangibleAssets: int, growthGoodwillAndIntangibleAssets: int, growthLongTermInvestments: float, growthTaxAssets: float, growthOtherNonCurrentAssets: float, growthTotalNonCurrentAssets: float, growthOtherAssets: int, growthTotalAssets: float, growthAccountPayables: float, growthShortTermDebt: float, growthTaxPayables: int, growthDeferredRevenue: float, growthOtherCurrentLiabilities: float, growthTotalCurrentLiabilities: float, growthLongTermDebt: float, growthDeferredRevenueNonCurrent: int, growthDeferredTaxLiabilitiesNonCurrent: int, growthOtherNonCurrentLiabilities: float, growthTotalNonCurrentLiabilities: float, growthOtherLiabilities: int, growthTotalLiabilities: float, growthPreferredStock: int, growthCommonStock: float, growthRetainedEarnings: float, growthAccumulatedOtherComprehensiveIncomeLoss: float, growthOthertotalStockholdersEquity: int, growthTotalStockholdersEquity: float, growthMinorityInterest: int, growthTotalEquity: float, growthTotalLiabilitiesAndStockholdersEquity: float, growthTotalInvestments: float, growthTotalDebt: float, growthNetDebt: float, growthAccountsReceivables: float, growthOtherReceivables: float, growthPrepaids: int, growthTotalPayables: float, growthOtherPayables: float, growthAccruedExpenses: int, growthCapitalLeaseObligationsCurrent: float, growthAdditionalPaidInCapital: int, growthTreasuryStock: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/balance-sheet-statement-growth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get trailing twelve months balance sheet
#
# GET /balance-sheet-statement-ttm
# operationId: balanceSheetStatementsTtm
export def "balance-sheet-statement-ttm balanceSheetStatementsTtm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<date: string, symbol: string, reportedCurrency: string, cik: string, filingDate: string, acceptedDate: string, fiscalYear: string, period: string, cashAndCashEquivalents: int, shortTermInvestments: int, cashAndShortTermInvestments: int, netReceivables: int, accountsReceivables: int, otherReceivables: int, inventory: int, prepaids: int, otherCurrentAssets: int, totalCurrentAssets: int, propertyPlantEquipmentNet: int, goodwill: int, intangibleAssets: int, goodwillAndIntangibleAssets: int, longTermInvestments: int, taxAssets: int, otherNonCurrentAssets: int, totalNonCurrentAssets: int, otherAssets: int, totalAssets: int, totalPayables: int, accountPayables: int, otherPayables: int, accruedExpenses: int, shortTermDebt: int, capitalLeaseObligationsCurrent: int, taxPayables: int, deferredRevenue: int, otherCurrentLiabilities: int, totalCurrentLiabilities: int, longTermDebt: int, deferredRevenueNonCurrent: int, deferredTaxLiabilitiesNonCurrent: int, otherNonCurrentLiabilities: int, totalNonCurrentLiabilities: int, otherLiabilities: int, capitalLeaseObligations: int, totalLiabilities: int, treasuryStock: int, preferredStock: int, commonStock: int, retainedEarnings: int, additionalPaidInCapital: int, accumulatedOtherComprehensiveIncomeLoss: int, otherTotalStockholdersEquity: int, totalStockholdersEquity: int, totalEquity: int, minorityInterest: int, totalLiabilitiesAndTotalEquity: int, totalInvestments: int, totalDebt: int, netDebt: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/balance-sheet-statement-ttm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get batch aftermarket quotes
#
# GET /batch-aftermarket-quote
# operationId: batchAftermarketQuote
export def "batch-aftermarket-quote batchAftermarketQuote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbols: string # Comma-separated symbols
]: nothing -> table<symbol: string, bidSize: int, bidPrice: float, askSize: int, askPrice: float, volume: int, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batch-aftermarket-quote" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get batch aftermarket trades
#
# GET /batch-aftermarket-trade
# operationId: batchAftermarketTrade
export def "batch-aftermarket-trade batchAftermarketTrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbols: string # Comma-separated symbols
]: nothing -> table<symbol: string, price: float, tradeSize: string, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batch-aftermarket-trade" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all commodity quotes
#
# GET /batch-commodity-quotes
# operationId: fullCommoditiesQuotes
export def "batch-commodity-quotes fullCommoditiesQuotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, price: float, change: int, volume: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batch-commodity-quotes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all forex quotes
#
# GET /batch-forex-quotes
# operationId: fullForexQuotes
export def "batch-forex-quotes fullForexQuotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, price: float, change: float, volume: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batch-forex-quotes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all index quotes
#
# GET /batch-index-quotes
# operationId: allIndexQuotes
export def "batch-index-quotes allIndexQuotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batch-index-quotes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get batch stock quotes
#
# GET /batch-quote
# operationId: batchQuote
export def "batch-quote batchQuote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbols: string # Comma-separated symbols
]: nothing -> table<symbol: string, name: string, price: float, changePercentage: float, change: float, volume: int, dayLow: float, dayHigh: float, yearHigh: float, yearLow: float, marketCap: float, priceAvg50: float, priceAvg200: float, exchange: string, open: float, previousClose: float, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batch-quote" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get batch short quotes
#
# GET /batch-quote-short
# operationId: batchQuoteShort
export def "batch-quote-short batchQuoteShort" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbols: string # Comma-separated symbols
]: nothing -> table<symbol: string, price: float, change: float, volume: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/batch-quote-short" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get biggest gainers today
#
# GET /biggest-gainers
# operationId: biggestGainers
export def "biggest-gainers biggestGainers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, price: float, name: string, change: float, changesPercentage: float, exchange: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/biggest-gainers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get biggest losers today
#
# GET /biggest-losers
# operationId: biggestLosers
export def "biggest-losers biggestLosers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, price: float, name: string, change: float, changesPercentage: float, exchange: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/biggest-losers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get cash flow statement
#
# GET /cash-flow-statement
# operationId: cashflowStatement
export def "cash-flow-statement cashflowStatement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --period: string # Period: annual, quarter
  --limit: int # Max results
]: nothing -> table<date: string, symbol: string, reportedCurrency: string, cik: string, filingDate: string, acceptedDate: string, fiscalYear: string, period: string, netIncome: int, depreciationAndAmortization: int, deferredIncomeTax: int, stockBasedCompensation: int, changeInWorkingCapital: int, accountsReceivables: int, inventory: int, accountsPayables: int, otherWorkingCapital: int, otherNonCashItems: int, netCashProvidedByOperatingActivities: int, investmentsInPropertyPlantAndEquipment: int, acquisitionsNet: int, purchasesOfInvestments: int, salesMaturitiesOfInvestments: int, otherInvestingActivities: int, netCashProvidedByInvestingActivities: int, netDebtIssuance: int, longTermNetDebtIssuance: int, shortTermNetDebtIssuance: int, netStockIssuance: int, netCommonStockIssuance: int, commonStockIssuance: int, commonStockRepurchased: int, netPreferredStockIssuance: int, netDividendsPaid: int, commonDividendsPaid: int, preferredDividendsPaid: int, otherFinancingActivities: int, netCashProvidedByFinancingActivities: int, effectOfForexChangesOnCash: int, netChangeInCash: int, cashAtEndOfPeriod: int, cashAtBeginningOfPeriod: int, operatingCashFlow: int, capitalExpenditure: int, freeCashFlow: int, incomeTaxesPaid: int, interestPaid: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cash-flow-statement" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get cash flow statement growth rates
#
# GET /cash-flow-statement-growth
# operationId: cashflowStatementGrowth
export def "cash-flow-statement-growth cashflowStatementGrowth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --period: string # Period: annual, quarter
  --limit: int # Max results
]: nothing -> table<symbol: string, date: string, fiscalYear: string, period: string, reportedCurrency: string, growthNetIncome: float, growthDepreciationAndAmortization: float, growthDeferredIncomeTax: int, growthStockBasedCompensation: float, growthChangeInWorkingCapital: float, growthAccountsReceivables: float, growthInventory: float, growthAccountsPayables: float, growthOtherWorkingCapital: float, growthOtherNonCashItems: float, growthNetCashProvidedByOperatingActivites: float, growthInvestmentsInPropertyPlantAndEquipment: float, growthAcquisitionsNet: int, growthPurchasesOfInvestments: float, growthSalesMaturitiesOfInvestments: float, growthOtherInvestingActivites: float, growthNetCashUsedForInvestingActivites: float, growthDebtRepayment: float, growthCommonStockIssued: int, growthCommonStockRepurchased: float, growthDividendsPaid: float, growthOtherFinancingActivites: float, growthNetCashUsedProvidedByFinancingActivities: float, growthEffectOfForexChangesOnCash: int, growthNetChangeInCash: float, growthCashAtEndOfPeriod: float, growthCashAtBeginningOfPeriod: float, growthOperatingCashFlow: float, growthCapitalExpenditure: float, growthFreeCashFlow: float, growthNetDebtIssuance: float, growthLongTermNetDebtIssuance: float, growthShortTermNetDebtIssuance: float, growthNetStockIssuance: float, growthPreferredDividendsPaid: float, growthIncomeTaxesPaid: float, growthInterestPaid: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cash-flow-statement-growth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get trailing twelve months cash flow statement
#
# GET /cash-flow-statement-ttm
# operationId: cashflowStatementsTtm
export def "cash-flow-statement-ttm cashflowStatementsTtm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<date: string, symbol: string, reportedCurrency: string, cik: string, filingDate: string, acceptedDate: string, fiscalYear: string, period: string, netIncome: int, depreciationAndAmortization: int, deferredIncomeTax: int, stockBasedCompensation: int, changeInWorkingCapital: int, accountsReceivables: int, inventory: int, accountsPayables: int, otherWorkingCapital: int, otherNonCashItems: int, netCashProvidedByOperatingActivities: int, investmentsInPropertyPlantAndEquipment: int, acquisitionsNet: int, purchasesOfInvestments: int, salesMaturitiesOfInvestments: int, otherInvestingActivities: int, netCashProvidedByInvestingActivities: int, netDebtIssuance: int, longTermNetDebtIssuance: int, shortTermNetDebtIssuance: int, netStockIssuance: int, netCommonStockIssuance: int, commonStockIssuance: int, commonStockRepurchased: int, netPreferredStockIssuance: int, netDividendsPaid: int, commonDividendsPaid: int, preferredDividendsPaid: int, otherFinancingActivities: int, netCashProvidedByFinancingActivities: int, effectOfForexChangesOnCash: int, netChangeInCash: int, cashAtEndOfPeriod: int, cashAtBeginningOfPeriod: int, operatingCashFlow: int, capitalExpenditure: int, freeCashFlow: int, incomeTaxesPaid: int, interestPaid: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cash-flow-statement-ttm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all CIK numbers
#
# GET /cik-list
# operationId: cikList
export def "cik-list cikList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<cik: string, companyName: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cik-list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all commodities
#
# GET /commodities-list
# operationId: commoditiesList
export def "commodities-list commoditiesList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, name: string, exchange: string, tradeMonth: string, currency: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/commodities-list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get company notes
#
# GET /company-notes
# operationId: companyNotes
export def "company-notes companyNotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<cik: string, symbol: string, title: string, exchange: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/company-notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Screen companies by various criteria
#
# GET /company-screener
# operationId: companyScreener
export def "company-screener companyScreener" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --exchange: string # Filter by exchange
  --sector: string # Filter by sector
  --industry: string # Filter by industry
  --country: string # Filter by country
  --marketCapMoreThan: float # Minimum market cap
  --marketCapLowerThan: float # Maximum market cap
  --volumeMoreThan: float # Minimum volume
  --volumeLowerThan: float # Maximum volume
  --priceMoreThan: float # Minimum price
  --priceLowerThan: float # Maximum price
  --betaMoreThan: float # Minimum beta
  --betaLowerThan: float # Maximum beta
  --dividendMoreThan: float # Minimum dividend yield
  --dividendLowerThan: float # Maximum dividend yield
  --isEtf: string@bool-completer # Filter for ETFs
  --isActivelyTrading: string@bool-completer # Filter actively trading
  --limit: int # Max results
]: nothing -> table<symbol: string, companyName: string, marketCap: int, sector: string, industry: string, beta: float, price: float, lastAnnualDividend: float, volume: int, exchange: string, exchangeShortName: string, country: string, isEtf: bool, isFund: bool, isActivelyTrading: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exchange" $exchange "scalar") (serialize-qp "sector" $sector "scalar") (serialize-qp "industry" $industry "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "marketCapMoreThan" $marketCapMoreThan "scalar") (serialize-qp "marketCapLowerThan" $marketCapLowerThan "scalar") (serialize-qp "volumeMoreThan" $volumeMoreThan "scalar") (serialize-qp "volumeLowerThan" $volumeLowerThan "scalar") (serialize-qp "priceMoreThan" $priceMoreThan "scalar") (serialize-qp "priceLowerThan" $priceLowerThan "scalar") (serialize-qp "betaMoreThan" $betaMoreThan "scalar") (serialize-qp "betaLowerThan" $betaLowerThan "scalar") (serialize-qp "dividendMoreThan" $dividendMoreThan "scalar") (serialize-qp "dividendLowerThan" $dividendLowerThan "scalar") (serialize-qp "isEtf" $isEtf "scalar") (serialize-qp "isActivelyTrading" $isActivelyTrading "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/company-screener" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get delisted companies
#
# GET /delisted-companies
# operationId: delistedCompanies
export def "delisted-companies delistedCompanies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Max results
]: nothing -> table<symbol: string, companyName: string, exchange: string, ipoDate: string, delistedDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/delisted-companies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get company dividend history
#
# GET /dividends
# operationId: dividendsCompany
export def "dividends dividendsCompany" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, date: string, recordDate: string, paymentDate: string, declarationDate: string, adjDividend: float, dividend: float, yield: float, frequency: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dividends" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get upcoming dividends calendar
#
# GET /dividends-calendar
# operationId: dividendsCalendar
export def "dividends-calendar dividendsCalendar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<symbol: string, date: string, recordDate: string, paymentDate: string, declarationDate: string, adjDividend: float, dividend: float, yield: float, frequency: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dividends-calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Dow Jones constituents
#
# GET /dowjones-constituent
# operationId: dowJonesConstituents
export def "dowjones-constituent dowJonesConstituents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, name: string, sector: string, subSector: string, headQuarter: string, dateFirstAdded: string, cik: string, founded: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dowjones-constituent")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search earnings call transcripts
#
# GET /earning-call-transcript
# operationId: searchTranscripts
export def "earning-call-transcript searchTranscripts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --year: int # Year
  --quarter: int # Quarter (1-4)
]: nothing -> table<symbol: string, period: string, year: int, date: string, content: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "quarter" $quarter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/earning-call-transcript" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get transcript dates for a symbol
#
# GET /earning-call-transcript-dates
# operationId: transcriptsDatesBySymbol
export def "earning-call-transcript-dates transcriptsDatesBySymbol" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<quarter: int, fiscalYear: int, date: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/earning-call-transcript-dates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get latest earnings call transcripts
#
# GET /earning-call-transcript-latest
# operationId: latestTranscripts
export def "earning-call-transcript-latest latestTranscripts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Max results
]: nothing -> table<symbol: string, period: string, fiscalYear: int, date: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/earning-call-transcript-latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get company earnings history
#
# GET /earnings
# operationId: earningsCompany
export def "earnings earningsCompany" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, date: string, epsActual: float, epsEstimated: float, revenueActual: int, revenueEstimated: int, lastUpdated: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/earnings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get upcoming earnings calendar
#
# GET /earnings-calendar
# operationId: earningsCalendar
export def "earnings-calendar earningsCalendar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<symbol: string, date: string, epsActual: float, epsEstimated: float, revenueActual: int, revenueEstimated: int, lastUpdated: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/earnings-calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List available earnings transcripts
#
# GET /earnings-transcript-list
# operationId: earningsTranscriptList
export def "earnings-transcript-list earningsTranscriptList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, companyName: string, noOfTranscripts: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/earnings-transcript-list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get economics calendar events
#
# GET /economic-calendar
# operationId: economicsCalendar
export def "economic-calendar economicsCalendar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<date: string, country: string, event: string, currency: string, previous: float, estimate: float, actual: float, change: float, impact: string, changePercentage: float, unit: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/economic-calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get economic indicators
#
# GET /economic-indicators
# operationId: economicsIndicators
export def "economic-indicators economicsIndicators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Indicator name (e.g. GDP, CPI, unemployment)
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<name: string, date: string, value: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/economic-indicators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current employee count
#
# GET /employee-count
# operationId: employeeCount
export def "employee-count employeeCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, cik: string, acceptanceTime: string, periodOfReport: string, companyName: string, formType: string, filingDate: string, employeeCount: int, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/employee-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get enterprise values
#
# GET /enterprise-values
# operationId: enterpriseValues
export def "enterprise-values enterpriseValues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --period: string # Period: annual, quarter
  --limit: int # Max results
]: nothing -> table<symbol: string, date: string, stockPrice: float, numberOfShares: int, marketCapitalization: int, minusCashAndCashEquivalents: int, addTotalDebt: int, enterpriseValue: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/enterprise-values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all ETFs
#
# GET /etf-list
# operationId: etfsList
export def "etf-list etfsList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/etf-list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ETF asset exposure
#
# GET /etf/asset-exposure
# operationId: etfAssetExposure
export def "etf-asset-exposure etfAssetExposure" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # ETF symbol
]: nothing -> table<symbol: string, asset: string, sharesNumber: int, weightPercentage: float, marketValue: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/etf/asset-exposure" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ETF country weighting
#
# GET /etf/country-weightings
# operationId: etfCountryWeighting
export def "etf-country-weightings etfCountryWeighting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # ETF symbol
]: nothing -> table<country: string, weightPercentage: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/etf/country-weightings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ETF holdings
#
# GET /etf/holdings
# operationId: etfHoldings
export def "etf-holdings etfHoldings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # ETF symbol
]: nothing -> table<symbol: string, asset: string, name: string, isin: string, securityCusip: string, sharesNumber: int, weightPercentage: float, marketValue: int, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/etf/holdings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ETF information
#
# GET /etf/info
# operationId: etfInformation
export def "etf-info etfInformation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # ETF symbol
]: nothing -> table<symbol: string, name: string, description: string, isin: string, assetClass: string, securityCusip: string, domicile: string, website: string, etfCompany: string, expenseRatio: float, assetsUnderManagement: int, avgVolume: int, inceptionDate: string, nav: float, navCurrency: string, holdingsCount: int, isActivelyTrading: bool, updatedAt: string, sectorsList: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/etf/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ETF sector weighting
#
# GET /etf/sector-weightings
# operationId: etfSectorWeighting
export def "etf-sector-weightings etfSectorWeighting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # ETF symbol
]: nothing -> table<symbol: string, sector: string, weightPercentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/etf/sector-weightings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get market hours for an exchange
#
# GET /exchange-market-hours
# operationId: exchangeMarketHours
export def "exchange-market-hours exchangeMarketHours" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --exchange: string # Exchange name (e.g. NASDAQ)
]: nothing -> table<exchange: string, name: string, openingHour: string, closingHour: string, timezone: string, isMarketOpen: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exchange" $exchange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/exchange-market-hours" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get executive compensation benchmark
#
# GET /executive-compensation-benchmark
# operationId: executiveCompensationBenchmark
export def "executive-compensation-benchmark executiveCompensationBenchmark" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --year: int # Year
]: nothing -> table<industryTitle: string, year: int, averageCompensation: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/executive-compensation-benchmark" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get overall financial statement growth
#
# GET /financial-growth
# operationId: financialStatementGrowth
export def "financial-growth financialStatementGrowth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --period: string # Period: annual, quarter
  --limit: int # Max results
]: nothing -> table<symbol: string, date: string, fiscalYear: string, period: string, reportedCurrency: string, revenueGrowth: float, grossProfitGrowth: float, ebitgrowth: float, operatingIncomeGrowth: float, netIncomeGrowth: float, epsgrowth: float, epsdilutedGrowth: float, weightedAverageSharesGrowth: float, weightedAverageSharesDilutedGrowth: float, dividendsPerShareGrowth: float, operatingCashFlowGrowth: float, receivablesGrowth: float, inventoryGrowth: float, assetGrowth: float, bookValueperShareGrowth: float, debtGrowth: float, rdexpenseGrowth: float, sgaexpensesGrowth: float, freeCashFlowGrowth: float, tenYRevenueGrowthPerShare: float, fiveYRevenueGrowthPerShare: float, threeYRevenueGrowthPerShare: float, tenYOperatingCFGrowthPerShare: float, fiveYOperatingCFGrowthPerShare: float, threeYOperatingCFGrowthPerShare: float, tenYNetIncomeGrowthPerShare: float, fiveYNetIncomeGrowthPerShare: float, threeYNetIncomeGrowthPerShare: float, tenYShareholdersEquityGrowthPerShare: float, fiveYShareholdersEquityGrowthPerShare: float, threeYShareholdersEquityGrowthPerShare: float, tenYDividendperShareGrowthPerShare: float, fiveYDividendperShareGrowthPerShare: float, threeYDividendperShareGrowthPerShare: float, ebitdaGrowth: float, growthCapitalExpenditure: float, tenYBottomLineNetIncomeGrowthPerShare: float, fiveYBottomLineNetIncomeGrowthPerShare: float, threeYBottomLineNetIncomeGrowthPerShare: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/financial-growth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get financial report filing dates
#
# GET /financial-reports-dates
# operationId: financialReportsDates
export def "financial-reports-dates financialReportsDates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, fiscalYear: int, period: string, linkJson: string, linkXlsx: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/financial-reports-dates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get financial scores (Altman Z-Score, Piotroski, etc.)
#
# GET /financial-scores
# operationId: financialScores
export def "financial-scores financialScores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, reportedCurrency: string, altmanZScore: float, piotroskiScore: int, workingCapital: int, totalAssets: int, retainedEarnings: int, ebit: int, marketCap: float, totalLiabilities: int, revenue: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/financial-scores" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all financial statement symbols
#
# GET /financial-statement-symbol-list
# operationId: financialSymbolsList
export def "financial-statement-symbol-list financialSymbolsList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, companyName: string, tradingCurrency: string, reportingCurrency: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/financial-statement-symbol-list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get FMP articles
#
# GET /fmp-articles
# operationId: fmpArticles
export def "fmp-articles fmpArticles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Max results
]: nothing -> table<title: string, date: string, content: string, tickers: string, image: string, link: string, author: string, site: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fmp-articles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all cryptocurrency quotes
#
# GET /full-cryptocurrency-quotes
# operationId: fullCryptocurrencyQuotes
export def "full-cryptocurrency-quotes fullCryptocurrencyQuotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/full-cryptocurrency-quotes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all ETF quotes
#
# GET /full-etf-quotes
# operationId: fullEtfQuotes
export def "full-etf-quotes fullEtfQuotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/full-etf-quotes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all quotes for an exchange
#
# GET /full-exchange-quotes
# operationId: fullExchangeQuotes
export def "full-exchange-quotes fullExchangeQuotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --exchange: string # Exchange name (e.g. NASDAQ)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exchange" $exchange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/full-exchange-quotes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all mutual fund quotes
#
# GET /full-mutualfund-quotes
# operationId: fullMutualFundQuotes
export def "full-mutualfund-quotes fullMutualFundQuotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/full-mutualfund-quotes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get mutual fund disclosures
#
# GET /funds/disclosure
# operationId: mutualFundDisclosures
export def "funds-disclosure mutualFundDisclosures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Fund symbol
  --year: int # Year
  --quarter: int # Quarter (1-4)
  --cik: string # CIK number
]: nothing -> table<cik: string, date: string, acceptedDate: string, symbol: string, name: string, lei: string, title: string, cusip: string, isin: string, balance: int, units: string, cur_cd: string, valUsd: float, pctVal: float, payoffProfile: string, assetCat: string, issuerCat: string, invCountry: string, isRestrictedSec: string, fairValLevel: string, isCashCollateral: string, isNonCashCollateral: string, isLoanByFund: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "quarter" $quarter "scalar") (serialize-qp "cik" $cik "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/funds/disclosure" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get disclosure dates for a fund
#
# GET /funds/disclosure-dates
# operationId: disclosuresDates
export def "funds-disclosure-dates disclosuresDates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Fund symbol
  --cik: string # CIK number
]: nothing -> table<date: string, year: int, quarter: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "cik" $cik "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/funds/disclosure-dates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get latest ETF/fund disclosures
#
# GET /funds/disclosure-holders-latest
# operationId: latestDisclosures
export def "funds-disclosure-holders-latest latestDisclosures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<cik: string, holder: string, securityCusip: string, shares: int, dateReported: string, change: int, weightPercent: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/funds/disclosure-holders-latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search disclosures by name
#
# GET /funds/disclosure-holders-search
# operationId: disclosuresNameSearch
export def "funds-disclosure-holders-search disclosuresNameSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Fund name to search
]: nothing -> table<symbol: string, cik: string, classId: string, seriesId: string, entityName: string, entityOrgType: string, seriesName: string, className: string, reportingFileNumber: string, address: string, city: string, zipCode: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/funds/disclosure-holders-search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get executive compensation data
#
# GET /governance-executive-compensation
# operationId: executiveCompensation
export def "governance-executive-compensation executiveCompensation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<cik: string, symbol: string, companyName: string, filingDate: string, acceptedDate: string, nameAndPosition: string, year: int, salary: int, bonus: int, stockAward: int, optionAward: int, incentivePlanCompensation: int, allOtherCompensation: int, total: int, link: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/governance-executive-compensation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get latest analyst grades
#
# GET /grades
# operationId: grades
export def "grades grades" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, date: string, gradingCompany: string, previousGrade: string, newGrade: string, action: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grades" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get analyst grades summary
#
# GET /grades-consensus
# operationId: gradesSummary
export def "grades-consensus gradesSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, strongBuy: int, buy: int, hold: int, sell: int, strongSell: int, consensus: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grades-consensus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get historical analyst grades
#
# GET /grades-historical
# operationId: historicalGrades
export def "grades-historical historicalGrades" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --limit: int # Max results
]: nothing -> table<symbol: string, date: string, analystRatingsStrongBuy: int, analystRatingsBuy: int, analystRatingsHold: int, analystRatingsSell: int, analystRatingsStrongSell: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grades-historical" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get 15-minute intraday chart data
#
# GET /historical-chart/15min
# operationId: intradayChart15Min
export def "historical-chart-15min intradayChart15Min" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<date: string, open: float, low: float, high: float, close: float, volume: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-chart/15min" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get 1-hour index intraday data
#
# GET /historical-chart/1hour
# operationId: indexIntraday1Hour
export def "historical-chart-1hour indexIntraday1Hour" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Index symbol
  --qp-from: string # Start date
  --qp-to: string # End date
]: nothing -> table<date: string, open: float, low: float, high: float, close: float, volume: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-chart/1hour" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get 1-minute index intraday data
#
# GET /historical-chart/1min
# operationId: indexIntraday1Min
export def "historical-chart-1min indexIntraday1Min" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Index symbol
  --qp-from: string # Start date
  --qp-to: string # End date
]: nothing -> table<date: string, open: float, low: float, high: float, close: float, volume: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-chart/1min" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get 30-minute intraday chart data
#
# GET /historical-chart/30min
# operationId: intradayChart30Min
export def "historical-chart-30min intradayChart30Min" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<date: string, open: float, low: float, high: float, close: float, volume: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-chart/30min" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get 4-hour intraday chart data
#
# GET /historical-chart/4hour
# operationId: intradayChart4Hour
export def "historical-chart-4hour intradayChart4Hour" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<date: string, open: float, low: float, high: float, close: float, volume: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-chart/4hour" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get 5-minute index intraday data
#
# GET /historical-chart/5min
# operationId: indexIntraday5Min
export def "historical-chart-5min indexIntraday5Min" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Index symbol
  --qp-from: string # Start date
  --qp-to: string # End date
]: nothing -> table<date: string, open: float, low: float, high: float, close: float, volume: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-chart/5min" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get historical Dow Jones constituent changes
#
# GET /historical-dowjones-constituent
# operationId: historicalDowJonesConstituents
export def "historical-dowjones-constituent historicalDowJonesConstituents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<dateAdded: string, addedSecurity: string, removedTicker: string, removedSecurity: string, date: string, symbol: string, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/historical-dowjones-constituent")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get historical employee count
#
# GET /historical-employee-count
# operationId: historicalEmployeeCount
export def "historical-employee-count historicalEmployeeCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, cik: string, acceptanceTime: string, periodOfReport: string, companyName: string, formType: string, filingDate: string, employeeCount: int, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-employee-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get historical industry P/E ratios
#
# GET /historical-industry-pe
# operationId: historicalIndustryPe
export def "historical-industry-pe historicalIndustryPe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Date (YYYY-MM-DD)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-industry-pe" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get historical industry performance
#
# GET /historical-industry-performance
# operationId: historicalIndustryPerformance
export def "historical-industry-performance historicalIndustryPerformance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Date (YYYY-MM-DD)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-industry-performance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get historical market capitalization
#
# GET /historical-market-capitalization
# operationId: historicalMarketCap
export def "historical-market-capitalization historicalMarketCap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
  --limit: int # Max results
]: nothing -> table<symbol: string, date: string, marketCap: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-market-capitalization" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get historical Nasdaq constituent changes
#
# GET /historical-nasdaq-constituent
# operationId: historicalNasdaqConstituents
export def "historical-nasdaq-constituent historicalNasdaqConstituents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<dateAdded: string, addedSecurity: string, removedTicker: string, removedSecurity: string, date: string, symbol: string, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/historical-nasdaq-constituent")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get dividend-adjusted end-of-day prices
#
# GET /historical-price-eod/dividend-adjusted
# operationId: historicalPriceEodDividendAdjusted
export def "historical-price-eod-dividend-adjusted historicalPriceEodDividendAdjusted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<symbol: string, date: string, adjOpen: float, adjHigh: float, adjLow: float, adjClose: float, volume: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-price-eod/dividend-adjusted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get full index end-of-day prices
#
# GET /historical-price-eod/full
# operationId: indexHistoricalPriceEodFull
export def "historical-price-eod-full indexHistoricalPriceEodFull" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Index symbol
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<symbol: string, date: string, open: float, high: float, low: float, close: float, volume: int, change: float, changePercent: float, vwap: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-price-eod/full" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get lightweight index end-of-day prices
#
# GET /historical-price-eod/light
# operationId: indexHistoricalPriceEodLight
export def "historical-price-eod-light indexHistoricalPriceEodLight" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Index symbol
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<symbol: string, date: string, price: float, volume: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-price-eod/light" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get non-split-adjusted end-of-day prices
#
# GET /historical-price-eod/non-split-adjusted
# operationId: historicalPriceEodNonSplitAdjusted
export def "historical-price-eod-non-split-adjusted historicalPriceEodNonSplitAdjusted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<symbol: string, date: string, adjOpen: float, adjHigh: float, adjLow: int, adjClose: float, volume: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-price-eod/non-split-adjusted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get historical sector P/E ratios
#
# GET /historical-sector-pe
# operationId: historicalSectorPe
export def "historical-sector-pe historicalSectorPe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Date (YYYY-MM-DD)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-sector-pe" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get historical sector performance
#
# GET /historical-sector-performance
# operationId: historicalSectorPerformance
export def "historical-sector-performance historicalSectorPerformance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Date (YYYY-MM-DD)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/historical-sector-performance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get historical S&P 500 constituent changes
#
# GET /historical-sp500-constituent
# operationId: historicalSp500Constituents
export def "historical-sp500-constituent historicalSp500Constituents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<dateAdded: string, addedSecurity: string, removedTicker: string, removedSecurity: string, date: string, symbol: string, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/historical-sp500-constituent")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get holidays by exchange
#
# GET /holidays-by-exchange
# operationId: holidaysByExchange
export def "holidays-by-exchange holidaysByExchange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --exchange: string # Exchange name
]: nothing -> table<exchange: string, date: string, name: string, isClosed: bool, adjOpenTime: string, adjCloseTime: string, isFullyClosed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exchange" $exchange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/holidays-by-exchange" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get income statement
#
# GET /income-statement
# operationId: incomeStatement
export def "income-statement incomeStatement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --period: string # Period: annual, quarter, Q1, Q2, Q3, Q4, FY
  --limit: int # Max results
]: nothing -> table<date: string, symbol: string, reportedCurrency: string, cik: string, filingDate: string, acceptedDate: string, fiscalYear: string, period: string, revenue: int, costOfRevenue: int, grossProfit: int, researchAndDevelopmentExpenses: int, generalAndAdministrativeExpenses: int, sellingAndMarketingExpenses: int, sellingGeneralAndAdministrativeExpenses: int, otherExpenses: int, operatingExpenses: int, costAndExpenses: int, netInterestIncome: int, interestIncome: int, interestExpense: int, depreciationAndAmortization: int, ebitda: int, ebit: int, nonOperatingIncomeExcludingInterest: int, operatingIncome: int, totalOtherIncomeExpensesNet: int, incomeBeforeTax: int, incomeTaxExpense: int, netIncomeFromContinuingOperations: int, netIncomeFromDiscontinuedOperations: int, otherAdjustmentsToNetIncome: int, netIncome: int, netIncomeDeductions: int, bottomLineNetIncome: int, eps: float, epsDiluted: float, weightedAverageShsOut: int, weightedAverageShsOutDil: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/income-statement" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get income statement growth rates
#
# GET /income-statement-growth
# operationId: incomeStatementGrowth
export def "income-statement-growth incomeStatementGrowth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --period: string # Period: annual, quarter
  --limit: int # Max results
]: nothing -> table<symbol: string, date: string, fiscalYear: string, period: string, reportedCurrency: string, growthRevenue: float, growthCostOfRevenue: float, growthGrossProfit: float, growthGrossProfitRatio: float, growthResearchAndDevelopmentExpenses: float, growthGeneralAndAdministrativeExpenses: int, growthSellingAndMarketingExpenses: int, growthOtherExpenses: int, growthOperatingExpenses: float, growthCostAndExpenses: float, growthInterestIncome: int, growthInterestExpense: int, growthDepreciationAndAmortization: float, growthEBITDA: float, growthOperatingIncome: float, growthIncomeBeforeTax: float, growthIncomeTaxExpense: float, growthNetIncome: float, growthEPS: float, growthEPSDiluted: float, growthWeightedAverageShsOut: float, growthWeightedAverageShsOutDil: float, growthEBIT: float, growthNonOperatingIncomeExcludingInterest: float, growthNetInterestIncome: int, growthTotalOtherIncomeExpensesNet: float, growthNetIncomeFromContinuingOperations: float, growthOtherAdjustmentsToNetIncome: int, growthNetIncomeDeductions: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/income-statement-growth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get trailing twelve months income statement
#
# GET /income-statement-ttm
# operationId: incomeStatementsTtm
export def "income-statement-ttm incomeStatementsTtm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<date: string, symbol: string, reportedCurrency: string, cik: string, filingDate: string, acceptedDate: string, fiscalYear: string, period: string, revenue: int, costOfRevenue: int, grossProfit: int, researchAndDevelopmentExpenses: int, generalAndAdministrativeExpenses: int, sellingAndMarketingExpenses: int, sellingGeneralAndAdministrativeExpenses: int, otherExpenses: int, operatingExpenses: int, costAndExpenses: int, netInterestIncome: int, interestIncome: int, interestExpense: int, depreciationAndAmortization: int, ebitda: int, ebit: int, nonOperatingIncomeExcludingInterest: int, operatingIncome: int, totalOtherIncomeExpensesNet: int, incomeBeforeTax: int, incomeTaxExpense: int, netIncomeFromContinuingOperations: int, netIncomeFromDiscontinuedOperations: int, otherAdjustmentsToNetIncome: int, netIncome: int, netIncomeDeductions: int, bottomLineNetIncome: int, eps: float, epsDiluted: float, weightedAverageShsOut: int, weightedAverageShsOutDil: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/income-statement-ttm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all market indexes
#
# GET /index-list
# operationId: indexesList
export def "index-list indexesList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, name: string, exchange: string, currency: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/index-list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search SEC industry classifications
#
# GET /industry-classification-search
# operationId: secIndustryClassificationSearch
export def "industry-classification-search secIndustryClassificationSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Search query
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/industry-classification-search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current industry P/E ratios
#
# GET /industry-pe-snapshot
# operationId: industryPeSnapshot
export def "industry-pe-snapshot industryPeSnapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Date (YYYY-MM-DD)
  --exchange: string # Exchange filter
]: nothing -> table<date: string, industry: string, exchange: string, pe: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "exchange" $exchange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/industry-pe-snapshot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current industry performance
#
# GET /industry-performance-snapshot
# operationId: industryPerformanceSnapshot
export def "industry-performance-snapshot industryPerformanceSnapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Date (YYYY-MM-DD)
  --exchange: string # Exchange filter
  --industry: string # Industry filter
]: nothing -> table<date: string, industry: string, exchange: string, averageChange: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "exchange" $exchange "scalar") (serialize-qp "industry" $industry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/industry-performance-snapshot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all insider trade transaction types
#
# GET /insider-trading-transaction-type
# operationId: allTransactionTypes
export def "insider-trading-transaction-type allTransactionTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<transactionType: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/insider-trading-transaction-type")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get latest insider trades
#
# GET /insider-trading/latest
# operationId: latestInsiderTrade
export def "insider-trading-latest latestInsiderTrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number
  --limit: int # Max results
]: nothing -> table<symbol: string, filingDate: string, transactionDate: string, reportingCik: string, companyCik: string, transactionType: string, securitiesOwned: int, reportingName: string, typeOfOwner: string, acquisitionOrDisposition: string, directOrIndirect: string, formType: string, securitiesTransacted: int, price: int, securityName: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/insider-trading/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search insider trades by reporting name
#
# GET /insider-trading/reporting-name
# operationId: searchReportingName
export def "insider-trading-reporting-name searchReportingName" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Insider name to search
]: nothing -> table<reportingCik: string, reportingName: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/insider-trading/reporting-name" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search insider trades by symbol
#
# GET /insider-trading/search
# operationId: searchInsiderTrades
export def "insider-trading-search searchInsiderTrades" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --limit: int # Max results
]: nothing -> table<symbol: string, filingDate: string, transactionDate: string, reportingCik: string, companyCik: string, transactionType: string, securitiesOwned: int, reportingName: string, typeOfOwner: string, acquisitionOrDisposition: string, directOrIndirect: string, formType: string, securitiesTransacted: int, price: int, securityName: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/insider-trading/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get insider trade statistics for a company
#
# GET /insider-trading/statistics
# operationId: insiderTradeStatistics
export def "insider-trading-statistics insiderTradeStatistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, cik: string, year: int, quarter: int, acquiredTransactions: int, disposedTransactions: int, acquiredDisposedRatio: int, totalAcquired: int, totalDisposed: int, averageAcquired: float, averageDisposed: float, totalPurchases: int, totalSales: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/insider-trading/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get 13F filing dates for a CIK
#
# GET /institutional-ownership/dates
# operationId: form13fFilingsDates
export def "institutional-ownership-dates form13fFilingsDates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cik: string # CIK number
]: nothing -> table<date: string, year: int, quarter: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cik" $cik "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/institutional-ownership/dates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Extract 13F filing data
#
# GET /institutional-ownership/extract
# operationId: filingsExtract
export def "institutional-ownership-extract filingsExtract" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cik: string # CIK number
  --year: int # Filing year
  --quarter: int # Filing quarter (1-4)
]: nothing -> table<date: string, filingDate: string, acceptedDate: string, cik: string, securityCusip: string, symbol: string, nameOfIssuer: string, shares: int, titleOfClass: string, sharesType: string, putCallShare: string, value: int, link: string, finalLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cik" $cik "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "quarter" $quarter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/institutional-ownership/extract" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get 13F filings with analytics by holder
#
# GET /institutional-ownership/extract-analytics/holder
# operationId: filingsExtractWithAnalyticsByHolder
export def "institutional-ownership-extract-analytics-holder filingsExtractWithAnalyticsByHolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --year: int # Filing year
  --quarter: int # Filing quarter
  --page: int # Page number
  --limit: int # Max results
]: nothing -> table<date: string, cik: string, filingDate: string, investorName: string, symbol: string, securityName: string, typeOfSecurity: string, securityCusip: string, sharesType: string, putCallShare: string, investmentDiscretion: string, industryTitle: string, weight: float, lastWeight: float, changeInWeight: float, changeInWeightPercentage: float, marketValue: int, lastMarketValue: int, changeInMarketValue: int, changeInMarketValuePercentage: float, sharesNumber: int, lastSharesNumber: int, changeInSharesNumber: int, changeInSharesNumberPercentage: float, quarterEndPrice: float, avgPricePaid: float, isNew: bool, isSoldOut: bool, ownership: float, lastOwnership: float, changeInOwnership: float, changeInOwnershipPercentage: float, holdingPeriod: int, firstAdded: string, performance: int, performancePercentage: float, lastPerformance: int, changeInPerformance: int, isCountedForPerformance: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "quarter" $quarter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/institutional-ownership/extract-analytics/holder" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get holder industry breakdown
#
# GET /institutional-ownership/holder-industry-breakdown
# operationId: holdersIndustryBreakdown
export def "institutional-ownership-holder-industry-breakdown holdersIndustryBreakdown" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cik: string # CIK number
  --date: string # Filing date
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cik" $cik "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/institutional-ownership/holder-industry-breakdown" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get holder performance summary
#
# GET /institutional-ownership/holder-performance-summary
# operationId: holderPerformanceSummary
export def "institutional-ownership-holder-performance-summary holderPerformanceSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cik: string # CIK number
]: nothing -> table<date: string, cik: string, investorName: string, portfolioSize: int, securitiesAdded: int, securitiesRemoved: int, marketValue: int, previousMarketValue: int, changeInMarketValue: int, changeInMarketValuePercentage: float, averageHoldingPeriod: int, averageHoldingPeriodTop10: int, averageHoldingPeriodTop20: int, turnover: float, turnoverAlternateSell: float, turnoverAlternateBuy: float, performance: int, performancePercentage: float, lastPerformance: int, changeInPerformance: int, performance1year: int, performancePercentage1year: float, performance3year: int, performancePercentage3year: float, performance5year: int, performancePercentage5year: float, performanceSinceInception: int, performanceSinceInceptionPercentage: float, performanceRelativeToSP500Percentage: float, performance1yearRelativeToSP500Percentage: float, performance3yearRelativeToSP500Percentage: float, performance5yearRelativeToSP500Percentage: float, performanceSinceInceptionRelativeToSP500Percentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cik" $cik "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/institutional-ownership/holder-performance-summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get industry summary for 13F data
#
# GET /institutional-ownership/industry-summary
# operationId: industrySummary
export def "institutional-ownership-industry-summary industrySummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --year: int # Year
  --quarter: int # Quarter (1-4)
]: nothing -> table<industryTitle: string, industryValue: int, date: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "quarter" $quarter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/institutional-ownership/industry-summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get latest 13F filings
#
# GET /institutional-ownership/latest
# operationId: latestFilings13F
export def "institutional-ownership-latest latestFilings13F" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number
  --limit: int # Max results
]: nothing -> table<cik: string, name: string, date: string, filingDate: string, acceptedDate: string, formType: string, link: string, finalLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/institutional-ownership/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get position summary for a holder
#
# GET /institutional-ownership/symbol-positions-summary
# operationId: positionsSummary
export def "institutional-ownership-symbol-positions-summary positionsSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --year: int # Year
  --quarter: int # Quarter (1-4)
]: nothing -> table<symbol: string, cik: string, date: string, investorsHolding: int, lastInvestorsHolding: int, investorsHoldingChange: int, numberOf13Fshares: int, lastNumberOf13Fshares: int, numberOf13FsharesChange: int, totalInvested: int, lastTotalInvested: int, totalInvestedChange: int, ownershipPercent: float, lastOwnershipPercent: float, ownershipPercentChange: float, newPositions: int, lastNewPositions: int, newPositionsChange: int, increasedPositions: int, lastIncreasedPositions: int, increasedPositionsChange: int, closedPositions: int, lastClosedPositions: int, closedPositionsChange: int, reducedPositions: int, lastReducedPositions: int, reducedPositionsChange: int, totalCalls: int, lastTotalCalls: int, totalCallsChange: int, totalPuts: int, lastTotalPuts: int, totalPutsChange: int, putCallRatio: float, lastPutCallRatio: float, putCallRatioChange: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "quarter" $quarter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/institutional-ownership/symbol-positions-summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get upcoming IPO calendar
#
# GET /ipos-calendar
# operationId: iposCalendar
export def "ipos-calendar iposCalendar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<symbol: string, date: string, daa: string, company: string, exchange: string, actions: string, shares: int, priceRange: string, marketCap: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ipos-calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get IPO disclosure filings
#
# GET /ipos-disclosure
# operationId: iposDisclosure
export def "ipos-disclosure iposDisclosure" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<symbol: string, filingDate: string, acceptedDate: string, effectivenessDate: string, cik: string, form: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ipos-disclosure" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get IPO prospectus details
#
# GET /ipos-prospectus
# operationId: iposProspectus
export def "ipos-prospectus iposProspectus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<symbol: string, acceptedDate: string, filingDate: string, ipoDate: string, cik: string, pricePublicPerShare: int, pricePublicTotal: int, discountsAndCommissionsPerShare: int, discountsAndCommissionsTotal: int, proceedsBeforeExpensesPerShare: int, proceedsBeforeExpensesTotal: int, form: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ipos-prospectus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get company executives
#
# GET /key-executives
# operationId: companyExecutives
export def "key-executives companyExecutives" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<title: string, name: string, pay: int, currencyPay: string, gender: string, yearBorn: int, titleSince: string, active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/key-executives" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get key financial metrics
#
# GET /key-metrics
# operationId: keyMetrics
export def "key-metrics keyMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --period: string # Period: annual, quarter
  --limit: int # Max results
]: nothing -> table<symbol: string, date: string, fiscalYear: string, period: string, reportedCurrency: string, marketCap: int, enterpriseValue: int, evToSales: float, evToOperatingCashFlow: float, evToFreeCashFlow: float, evToEBITDA: float, netDebtToEBITDA: float, currentRatio: float, incomeQuality: float, grahamNumber: float, grahamNetNet: float, taxBurden: float, interestBurden: int, workingCapital: int, investedCapital: int, returnOnAssets: float, operatingReturnOnAssets: float, returnOnTangibleAssets: float, returnOnEquity: float, returnOnInvestedCapital: float, returnOnCapitalEmployed: float, earningsYield: float, freeCashFlowYield: float, capexToOperatingCashFlow: float, capexToDepreciation: float, capexToRevenue: float, salesGeneralAndAdministrativeToRevenue: int, researchAndDevelopementToRevenue: float, stockBasedCompensationToRevenue: float, intangiblesToTotalAssets: int, averageReceivables: int, averagePayables: int, averageInventory: int, daysOfSalesOutstanding: float, daysOfPayablesOutstanding: float, daysOfInventoryOutstanding: float, operatingCycle: float, cashConversionCycle: float, freeCashFlowToEquity: int, freeCashFlowToFirm: int, tangibleAssetValue: int, netCurrentAssetValue: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/key-metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get TTM key metrics
#
# GET /key-metrics-ttm
# operationId: keyMetricsTtm
export def "key-metrics-ttm keyMetricsTtm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, marketCap: float, enterpriseValueTTM: float, evToSalesTTM: float, evToOperatingCashFlowTTM: float, evToFreeCashFlowTTM: float, evToEBITDATTM: float, netDebtToEBITDATTM: float, currentRatioTTM: float, incomeQualityTTM: float, grahamNumberTTM: float, grahamNetNetTTM: float, taxBurdenTTM: float, interestBurdenTTM: float, workingCapitalTTM: int, investedCapitalTTM: int, returnOnAssetsTTM: float, operatingReturnOnAssetsTTM: float, returnOnTangibleAssetsTTM: float, returnOnEquityTTM: float, returnOnInvestedCapitalTTM: float, returnOnCapitalEmployedTTM: float, earningsYieldTTM: float, freeCashFlowYieldTTM: float, capexToOperatingCashFlowTTM: float, capexToDepreciationTTM: float, capexToRevenueTTM: float, salesGeneralAndAdministrativeToRevenueTTM: int, researchAndDevelopementToRevenueTTM: float, stockBasedCompensationToRevenueTTM: float, intangiblesToTotalAssetsTTM: int, averageReceivablesTTM: int, averagePayablesTTM: int, averageInventoryTTM: int, daysOfSalesOutstandingTTM: float, daysOfPayablesOutstandingTTM: float, daysOfInventoryOutstandingTTM: float, operatingCycleTTM: float, cashConversionCycleTTM: float, freeCashFlowToEquityTTM: int, freeCashFlowToFirmTTM: float, tangibleAssetValueTTM: int, netCurrentAssetValueTTM: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/key-metrics-ttm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get latest financial statements
#
# GET /latest-financial-statements
# operationId: latestFinancialStatements
export def "latest-financial-statements latestFinancialStatements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Max results
]: nothing -> table<symbol: string, calendarYear: int, period: string, date: string, dateAdded: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/latest-financial-statements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get market cap for multiple symbols
#
# GET /market-capitalization
# operationId: batchMarketCap
export def "market-capitalization batchMarketCap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbols: string # Comma-separated symbols
]: nothing -> table<symbol: string, date: string, marketCap: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/market-capitalization" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get market risk premium by country
#
# GET /market-risk-premium
# operationId: marketRiskPremium
export def "market-risk-premium marketRiskPremium" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<country: string, continent: string, countryRiskPremium: float, totalEquityRiskPremium: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/market-risk-premium")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get latest mergers and acquisitions
#
# GET /mergers-acquisitions-latest
# operationId: latestMergersAcquisitions
export def "mergers-acquisitions-latest latestMergersAcquisitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number
  --limit: int # Max results
]: nothing -> table<symbol: string, companyName: string, cik: string, targetedCompanyName: string, targetedCik: string, targetedSymbol: string, transactionDate: string, acceptedDate: string, link: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mergers-acquisitions-latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search mergers and acquisitions
#
# GET /mergers-acquisitions-search
# operationId: searchMergersAcquisitions
export def "mergers-acquisitions-search searchMergersAcquisitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Company name to search
]: nothing -> table<symbol: string, companyName: string, cik: string, targetedCompanyName: string, targetedCik: string, targetedSymbol: string, transactionDate: string, acceptedDate: string, link: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mergers-acquisitions-search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get most actively traded stocks
#
# GET /most-actives
# operationId: mostActive
export def "most-actives mostActive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, price: float, name: string, change: float, changesPercentage: float, exchange: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/most-actives")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Nasdaq constituents
#
# GET /nasdaq-constituent
# operationId: nasdaqConstituents
export def "nasdaq-constituent nasdaqConstituents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, name: string, sector: string, subSector: string, headQuarter: string, dateFirstAdded: string, cik: string, founded: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/nasdaq-constituent")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search crypto news
#
# GET /news/crypto
# operationId: searchCryptoNews
export def "news-crypto searchCryptoNews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbols: string # Crypto symbol(s)
  --page: int # Page number
  --limit: int # Max results
]: nothing -> table<symbol: string, publishedDate: string, publisher: string, title: string, image: string, site: string, text: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/news/crypto" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get cryptocurrency news
#
# GET /news/crypto-latest
# operationId: cryptoNews
export def "news-crypto-latest cryptoNews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbols: string # Crypto symbol(s)
  --page: int # Page number
  --limit: int # Max results
]: nothing -> table<symbol: string, publishedDate: string, publisher: string, title: string, image: string, site: string, text: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/news/crypto-latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search forex news
#
# GET /news/forex
# operationId: searchForexNews
export def "news-forex searchForexNews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbols: string # Forex pair symbol(s)
  --page: int # Page number
  --limit: int # Max results
]: nothing -> table<symbol: string, publishedDate: string, publisher: string, title: string, image: string, site: string, text: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/news/forex" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get forex news
#
# GET /news/forex-latest
# operationId: forexNews
export def "news-forex-latest forexNews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbols: string # Forex pair symbol(s)
  --page: int # Page number
  --limit: int # Max results
]: nothing -> table<symbol: string, publishedDate: string, publisher: string, title: string, image: string, site: string, text: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/news/forex-latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get general financial news
#
# GET /news/general-latest
# operationId: generalNews
export def "news-general-latest generalNews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number
  --limit: int # Max results
]: nothing -> table<symbol: string, publishedDate: string, publisher: string, title: string, image: string, site: string, text: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/news/general-latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search press releases
#
# GET /news/press-releases
# operationId: searchPressReleases
export def "news-press-releases searchPressReleases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbols: string # Stock ticker symbol(s)
  --page: int # Page number
  --limit: int # Max results
]: nothing -> table<symbol: string, publishedDate: string, publisher: string, title: string, image: string, site: string, text: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/news/press-releases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get press releases
#
# GET /news/press-releases-latest
# operationId: pressReleases
export def "news-press-releases-latest pressReleases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --page: int # Page number
  --limit: int # Max results
]: nothing -> table<symbol: string, publishedDate: string, publisher: string, title: string, image: string, site: string, text: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/news/press-releases-latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search stock news
#
# GET /news/stock
# operationId: searchStockNews
export def "news-stock searchStockNews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbols: string # Stock ticker symbol(s)
  --page: int # Page number
  --limit: int # Max results
]: nothing -> table<symbol: string, publishedDate: string, publisher: string, title: string, image: string, site: string, text: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/news/stock" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get stock-specific news
#
# GET /news/stock-latest
# operationId: stockNews
export def "news-stock-latest stockNews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbols: string # Stock ticker symbol(s)
  --page: int # Page number
  --limit: int # Max results
]: nothing -> table<symbol: string, publishedDate: string, publisher: string, title: string, image: string, site: string, text: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/news/stock-latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get owner earnings (Buffett method)
#
# GET /owner-earnings
# operationId: ownerEarnings
export def "owner-earnings ownerEarnings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, reportedCurrency: string, fiscalYear: string, period: string, date: string, averagePPE: float, maintenanceCapex: int, ownersEarnings: int, growthCapex: int, ownersEarningsPerShare: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/owner-earnings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get consensus price target
#
# GET /price-target-consensus
# operationId: priceTargetConsensus
export def "price-target-consensus priceTargetConsensus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, targetHigh: int, targetLow: int, targetConsensus: float, targetMedian: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/price-target-consensus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get analyst price target summary
#
# GET /price-target-summary
# operationId: priceTargetSummary
export def "price-target-summary priceTargetSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, lastMonthCount: int, lastMonthAvgPriceTarget: float, lastQuarterCount: int, lastQuarterAvgPriceTarget: float, lastYearCount: int, lastYearAvgPriceTarget: float, allTimeCount: int, allTimeAvgPriceTarget: float, publishers: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/price-target-summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get company profile by CIK
#
# GET /profile
# operationId: companyProfileByCik
export def "profile companyProfileByCik" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cik: string # CIK number
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cik" $cik "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/profile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get commodity quote
#
# GET /quote
# operationId: commoditiesQuote
export def "quote commoditiesQuote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Commodity symbol
]: nothing -> table<symbol: string, name: string, price: float, changePercentage: float, change: float, volume: int, dayLow: float, dayHigh: float, yearHigh: float, yearLow: float, marketCap: string, priceAvg50: float, priceAvg200: float, exchange: string, open: int, previousClose: float, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get short commodity quote
#
# GET /quote-short
# operationId: commoditiesQuoteShort
export def "quote-short commoditiesQuoteShort" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Commodity symbol
]: nothing -> table<symbol: string, price: float, change: float, volume: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote-short" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get historical analyst ratings
#
# GET /ratings-historical
# operationId: historicalRatings
export def "ratings-historical historicalRatings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --limit: int # Max results
]: nothing -> table<symbol: string, date: string, rating: string, overallScore: int, discountedCashFlowScore: int, returnOnEquityScore: int, returnOnAssetsScore: int, debtToEquityScore: int, priceToEarningsScore: int, priceToBookScore: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ratings-historical" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current analyst ratings snapshot
#
# GET /ratings-snapshot
# operationId: ratingsSnapshot
export def "ratings-snapshot ratingsSnapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, rating: string, overallScore: int, discountedCashFlowScore: int, returnOnEquityScore: int, returnOnAssetsScore: int, debtToEquityScore: int, priceToEarningsScore: int, priceToBookScore: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ratings-snapshot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get financial ratios and metrics
#
# GET /ratios
# operationId: metricsRatios
export def "ratios metricsRatios" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --period: string # Period: annual, quarter
  --limit: int # Max results
]: nothing -> table<symbol: string, date: string, fiscalYear: string, period: string, reportedCurrency: string, grossProfitMargin: float, ebitMargin: float, ebitdaMargin: float, operatingProfitMargin: float, pretaxProfitMargin: float, continuousOperationsProfitMargin: float, netProfitMargin: float, bottomLineProfitMargin: float, receivablesTurnover: float, payablesTurnover: float, inventoryTurnover: float, fixedAssetTurnover: float, assetTurnover: float, currentRatio: float, quickRatio: float, solvencyRatio: float, cashRatio: float, priceToEarningsRatio: float, priceToEarningsGrowthRatio: float, forwardPriceToEarningsGrowthRatio: float, priceToBookRatio: float, priceToSalesRatio: float, priceToFreeCashFlowRatio: float, priceToOperatingCashFlowRatio: float, debtToAssetsRatio: float, debtToEquityRatio: float, debtToCapitalRatio: float, longTermDebtToCapitalRatio: float, financialLeverageRatio: float, workingCapitalTurnoverRatio: float, operatingCashFlowRatio: float, operatingCashFlowSalesRatio: float, freeCashFlowOperatingCashFlowRatio: float, debtServiceCoverageRatio: float, interestCoverageRatio: int, shortTermOperatingCashFlowCoverageRatio: float, operatingCashFlowCoverageRatio: float, capitalExpenditureCoverageRatio: float, dividendPaidAndCapexCoverageRatio: float, dividendPayoutRatio: float, dividendYield: float, dividendYieldPercentage: float, revenuePerShare: float, netIncomePerShare: float, interestDebtPerShare: float, cashPerShare: float, bookValuePerShare: float, tangibleBookValuePerShare: float, shareholdersEquityPerShare: float, operatingCashFlowPerShare: float, capexPerShare: float, freeCashFlowPerShare: float, netIncomePerEBT: float, ebtPerEbit: float, priceToFairValue: float, debtToMarketCap: float, effectiveTaxRate: float, enterpriseValueMultiple: float, dividendPerShare: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ratios" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get TTM financial ratios
#
# GET /ratios-ttm
# operationId: metricsRatiosTtm
export def "ratios-ttm metricsRatiosTtm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, grossProfitMarginTTM: float, ebitMarginTTM: float, ebitdaMarginTTM: float, operatingProfitMarginTTM: float, pretaxProfitMarginTTM: float, continuousOperationsProfitMarginTTM: float, netProfitMarginTTM: float, bottomLineProfitMarginTTM: float, receivablesTurnoverTTM: float, payablesTurnoverTTM: float, inventoryTurnoverTTM: float, fixedAssetTurnoverTTM: float, assetTurnoverTTM: float, currentRatioTTM: float, quickRatioTTM: float, solvencyRatioTTM: float, cashRatioTTM: float, priceToEarningsRatioTTM: float, priceToEarningsGrowthRatioTTM: float, forwardPriceToEarningsGrowthRatioTTM: float, priceToBookRatioTTM: float, priceToSalesRatioTTM: float, priceToFreeCashFlowRatioTTM: float, priceToOperatingCashFlowRatioTTM: float, debtToAssetsRatioTTM: float, debtToEquityRatioTTM: float, debtToCapitalRatioTTM: float, longTermDebtToCapitalRatioTTM: float, financialLeverageRatioTTM: float, workingCapitalTurnoverRatioTTM: float, operatingCashFlowRatioTTM: float, operatingCashFlowSalesRatioTTM: float, freeCashFlowOperatingCashFlowRatioTTM: float, debtServiceCoverageRatioTTM: float, interestCoverageRatioTTM: int, shortTermOperatingCashFlowCoverageRatioTTM: float, operatingCashFlowCoverageRatioTTM: float, capitalExpenditureCoverageRatioTTM: float, dividendPaidAndCapexCoverageRatioTTM: float, dividendPayoutRatioTTM: float, dividendYieldTTM: float, enterpriseValueTTM: float, revenuePerShareTTM: float, netIncomePerShareTTM: float, interestDebtPerShareTTM: float, cashPerShareTTM: float, bookValuePerShareTTM: float, tangibleBookValuePerShareTTM: float, shareholdersEquityPerShareTTM: float, operatingCashFlowPerShareTTM: float, capexPerShareTTM: float, freeCashFlowPerShareTTM: float, netIncomePerEBTTTM: float, ebtPerEbitTTM: float, priceToFairValueTTM: float, debtToMarketCapTTM: float, effectiveTaxRateTTM: float, enterpriseValueMultipleTTM: float, dividendPerShareTTM: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ratios-ttm" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get revenue by geographic segment
#
# GET /revenue-geographic-segmentation
# operationId: revenueGeographicSegments
export def "revenue-geographic-segmentation revenueGeographicSegments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, fiscalYear: int, period: string, reportedCurrency: string, date: string, data: record<Americas_Segment: int, Europe_Segment: int, Greater_China_Segment: int, Japan_Segment: int, Rest_of_Asia_Pacific_Segment: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/revenue-geographic-segmentation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get revenue by product segment
#
# GET /revenue-product-segmentation
# operationId: revenueProductSegmentation
export def "revenue-product-segmentation revenueProductSegmentation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, fiscalYear: int, period: string, reportedCurrency: string, date: string, data: record<Mac: int, Service: int, Wearables__Home_and_Accessories: int, iPad: int, iPhone: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/revenue-product-segmentation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search by CIK number
#
# GET /search-cik
# operationId: searchCik
export def "search-cik searchCik" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # CIK number to search
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-cik" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search by CUSIP
#
# GET /search-cusip
# operationId: searchCusip
export def "search-cusip searchCusip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # CUSIP to search
]: nothing -> table<symbol: string, companyName: string, cusip: string, marketCap: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-cusip" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search exchange variants for a symbol
#
# GET /search-exchange-variants
# operationId: searchExchangeVariants
export def "search-exchange-variants searchExchangeVariants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, price: float, beta: float, volAvg: int, mktCap: float, lastDiv: float, range: string, changes: float, companyName: string, currency: string, cik: string, isin: string, cusip: string, exchange: string, exchangeShortName: string, industry: string, website: string, description: string, ceo: string, sector: string, country: string, fullTimeEmployees: string, phone: string, address: string, city: string, state: string, zip: string, dcfDiff: float, dcf: float, image: string, ipoDate: string, defaultImage: bool, isEtf: bool, isActivelyTrading: bool, isAdr: bool, isFund: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-exchange-variants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search by ISIN
#
# GET /search-isin
# operationId: searchIsin
export def "search-isin searchIsin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # ISIN to search
]: nothing -> table<symbol: string, name: string, isin: string, marketCap: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-isin" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search by company name
#
# GET /search-name
# operationId: searchName
export def "search-name searchName" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Company name to search
  --limit: int # Max results to return
  --exchange: string # Filter by exchange
]: nothing -> table<symbol: string, name: string, currency: string, exchangeFullName: string, exchange: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "exchange" $exchange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-name" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search by stock ticker symbol
#
# GET /search-symbol
# operationId: searchSymbol
export def "search-symbol searchSymbol" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Search query (ticker symbol)
  --limit: int # Max results to return
  --exchange: string # Filter by exchange (e.g. NASDAQ)
]: nothing -> table<symbol: string, name: string, currency: string, exchangeFullName: string, exchange: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "exchange" $exchange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-symbol" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get latest 8-K filings
#
# GET /sec-filings-8k
# operationId: sec8kLatest
export def "sec-filings-8k sec8kLatest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
  --page: int # Page number
  --limit: int # Max results
]: nothing -> table<symbol: string, cik: string, filingDate: string, acceptedDate: string, formType: string, hasFinancials: string, link: string, finalLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sec-filings-8k" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search SEC company by CIK
#
# GET /sec-filings-company-search/cik
# operationId: secCompanySearchByCik
export def "sec-filings-company-search-cik secCompanySearchByCik" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cik: string # CIK number
]: nothing -> table<symbol: string, name: string, cik: string, sicCode: string, industryTitle: string, businessAddress: string, phoneNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cik" $cik "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sec-filings-company-search/cik" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search SEC filings by company name
#
# GET /sec-filings-company-search/name
# operationId: secSearchByName
export def "sec-filings-company-search-name secSearchByName" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --company: string # Company name to search
]: nothing -> table<symbol: string, name: string, cik: string, sicCode: string, industryTitle: string, businessAddress: string, phoneNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "company" $company "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sec-filings-company-search/name" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search SEC company by symbol
#
# GET /sec-filings-company-search/symbol
# operationId: secCompanySearchBySymbol
export def "sec-filings-company-search-symbol secCompanySearchBySymbol" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, name: string, cik: string, sicCode: string, industryTitle: string, businessAddress: string, phoneNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sec-filings-company-search/symbol" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get latest financial filings (10-K, 10-Q)
#
# GET /sec-filings-financials
# operationId: secFinancialsLatest
export def "sec-filings-financials secFinancialsLatest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
  --page: int # Page number
  --limit: int # Max results
]: nothing -> table<symbol: string, cik: string, filingDate: string, acceptedDate: string, formType: string, hasFinancials: bool, link: string, finalLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sec-filings-financials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search SEC filings by CIK
#
# GET /sec-filings-search/cik
# operationId: secSearchByCik
export def "sec-filings-search-cik secSearchByCik" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cik: string # CIK number
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
  --page: int # Page number
  --limit: int # Max results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cik" $cik "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sec-filings-search/cik" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search SEC filings by form type
#
# GET /sec-filings-search/form-type
# operationId: secSearchByFormType
export def "sec-filings-search-form-type secSearchByFormType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --formType: string # Form type (e.g. 10-K, 10-Q, 8-K)
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
  --page: int # Page number
  --limit: int # Max results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "formType" $formType "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sec-filings-search/form-type" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search SEC filings by symbol
#
# GET /sec-filings-search/symbol
# operationId: secSearchBySymbol
export def "sec-filings-search-symbol secSearchBySymbol" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
  --page: int # Page number
  --limit: int # Max results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sec-filings-search/symbol" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get SEC company full profile
#
# GET /sec-profile
# operationId: secCompanyFullProfile
export def "sec-profile secCompanyFullProfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, cik: string, registrantName: string, sicCode: string, sicDescription: string, sicGroup: string, isin: string, businessAddress: string, mailingAddress: string, phoneNumber: string, postalCode: string, city: string, state: string, country: string, description: string, ceo: string, website: string, exchange: string, stateLocation: string, stateOfIncorporation: string, fiscalYearEnd: string, ipoDate: string, employees: string, secFilingsUrl: string, taxIdentificationNumber: string, fiftyTwoWeekRange: string, isActive: bool, assetType: string, openFigiComposite: string, priceCurrency: string, marketSector: string, securityType: string, isEtf: bool, isAdr: bool, isFund: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sec-profile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current sector P/E ratios
#
# GET /sector-pe-snapshot
# operationId: sectorPeSnapshot
export def "sector-pe-snapshot sectorPeSnapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Date (YYYY-MM-DD)
  --exchange: string # Exchange filter
]: nothing -> table<date: string, sector: string, exchange: string, pe: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "exchange" $exchange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sector-pe-snapshot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current sector performance
#
# GET /sector-performance-snapshot
# operationId: sectorPerformanceSnapshot
export def "sector-performance-snapshot sectorPerformanceSnapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Date (YYYY-MM-DD)
  --exchange: string # Exchange filter
  --sector: string # Sector filter
]: nothing -> table<date: string, sector: string, exchange: string, averageChange: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "exchange" $exchange "scalar") (serialize-qp "sector" $sector "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sector-performance-snapshot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get shares float data
#
# GET /shares-float
# operationId: sharesFloat
export def "shares-float sharesFloat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, date: string, freeFloat: float, floatShares: int, outstandingShares: int, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shares-float" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get shares float for all companies
#
# GET /shares-float-all
# operationId: allSharesFloat
export def "shares-float-all allSharesFloat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number
  --limit: int # Max results per page
]: nothing -> table<symbol: string, date: string, freeFloat: float, floatShares: int, outstandingShares: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shares-float-all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get S&P 500 constituents
#
# GET /sp500-constituent
# operationId: sp500Constituents
export def "sp500-constituent sp500Constituents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, name: string, sector: string, subSector: string, headQuarter: string, dateFirstAdded: string, cik: string, founded: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sp500-constituent")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get company stock split history
#
# GET /splits
# operationId: splitsCompany
export def "splits splitsCompany" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, date: string, numerator: int, denominator: int, splitType: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/splits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get upcoming stock splits calendar
#
# GET /splits-calendar
# operationId: splitsCalendar
export def "splits-calendar splitsCalendar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<symbol: string, date: string, numerator: int, denominator: int, splitType: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/splits-calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List SEC industry classifications (SIC codes)
#
# GET /standard-industrial-classification-list
# operationId: secIndustryClassificationList
export def "standard-industrial-classification-list secIndustryClassificationList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<office: string, sicCode: string, industryTitle: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/standard-industrial-classification-list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all company symbols
#
# GET /stock-list
# operationId: companySymbolsList
export def "stock-list companySymbolsList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<symbol: string, companyName: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stock-list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get company peers
#
# GET /stock-peers
# operationId: companyPeers
export def "stock-peers companyPeers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, companyName: string, price: float, mktCap: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stock-peers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get quote price change
#
# GET /stock-price-change
# operationId: quoteChange
export def "stock-price-change quoteChange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
]: nothing -> table<symbol: string, 1D: float, 5D: float, 1M: float, 3M: float, 6M: float, ytd: float, 1Y: float, 3Y: float, 5Y: float, 10Y: float, max: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stock-price-change" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List symbol changes
#
# GET /symbol-change
# operationId: symbolChangesList
export def "symbol-change symbolChangesList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<date: string, companyName: string, oldSymbol: string, newSymbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/symbol-change")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Average Directional Index
#
# GET /technical-indicators/adx
# operationId: adx
export def "technical-indicators-adx adx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --periodLength: int # Number of periods
  --timeframe: string # Timeframe
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<date: string, open: float, high: float, low: float, close: float, volume: int, adx: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/technical-indicators/adx" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Double Exponential Moving Average
#
# GET /technical-indicators/dema
# operationId: dema
export def "technical-indicators-dema dema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --periodLength: int # Number of periods
  --timeframe: string # Timeframe
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<date: string, open: float, high: float, low: float, close: float, volume: int, dema: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/technical-indicators/dema" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Exponential Moving Average
#
# GET /technical-indicators/ema
# operationId: ema
export def "technical-indicators-ema ema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --periodLength: int # Number of periods
  --timeframe: string # Timeframe: 1min, 5min, 15min, 30min, 1hour, 4hour, 1day
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<date: string, open: float, high: float, low: float, close: float, volume: int, ema: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/technical-indicators/ema" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Relative Strength Index
#
# GET /technical-indicators/rsi
# operationId: rsi
export def "technical-indicators-rsi rsi" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --periodLength: int # Number of periods (default 14)
  --timeframe: string # Timeframe
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<date: string, open: float, high: float, low: float, close: float, volume: int, rsi: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/technical-indicators/rsi" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Simple Moving Average
#
# GET /technical-indicators/sma
# operationId: sma
export def "technical-indicators-sma sma" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --periodLength: int # Number of periods
  --timeframe: string # Timeframe: 1min, 5min, 15min, 30min, 1hour, 4hour, 1day
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<date: string, open: float, high: float, low: float, close: float, volume: int, sma: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/technical-indicators/sma" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Standard Deviation
#
# GET /technical-indicators/standardDeviation
# operationId: standardDeviation
export def "technical-indicators-standard-deviation standardDeviation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --periodLength: int # Number of periods
  --timeframe: string # Timeframe
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<date: string, open: float, high: float, low: float, close: float, volume: int, standardDeviation: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/technical-indicators/standardDeviation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Triple Exponential Moving Average
#
# GET /technical-indicators/tema
# operationId: tema
export def "technical-indicators-tema tema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --periodLength: int # Number of periods
  --timeframe: string # Timeframe
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<date: string, open: float, high: float, low: float, close: float, volume: int, tema: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/technical-indicators/tema" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Williams %R
#
# GET /technical-indicators/williams
# operationId: williams
export def "technical-indicators-williams williams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --periodLength: int # Number of periods
  --timeframe: string # Timeframe
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<date: string, open: float, high: float, low: float, close: float, volume: int, williams: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/technical-indicators/williams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Weighted Moving Average
#
# GET /technical-indicators/wma
# operationId: wma
export def "technical-indicators-wma wma" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Stock ticker symbol
  --periodLength: int # Number of periods
  --timeframe: string # Timeframe
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<date: string, open: float, high: float, low: float, close: float, volume: int, wma: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/technical-indicators/wma" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get treasury rates
#
# GET /treasury-rates
# operationId: treasuryRates
export def "treasury-rates treasuryRates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Start date (YYYY-MM-DD)
  --qp-to: string # End date (YYYY-MM-DD)
]: nothing -> table<date: string, month1: float, month2: float, month3: float, month6: float, year1: float, year2: float, year3: float, year5: float, year7: float, year10: float, year20: float, year30: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/treasury-rates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
