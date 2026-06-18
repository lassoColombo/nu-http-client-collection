# Auto-generated client for Amazon SageMaker Service v2017-07-24
# Source: https://api.apis.guru/v2/specs/amazonaws.com/sagemaker/2017-07-24/openapi.json
# Auth: --token flag or $env.AMAZON_SAGEMAKER_SERVICE_TOKEN

const BASE_URL = "http://api.sagemaker.us-east-1.amazonaws.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_SAGEMAKER_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["http://api.sagemaker.us-east-1.amazonaws.com" "http://api.sagemaker.us-east-2.amazonaws.com" "http://api.sagemaker.us-west-1.amazonaws.com" "http://api.sagemaker.us-west-2.amazonaws.com" "http://api.sagemaker.us-gov-west-1.amazonaws.com" "http://api.sagemaker.us-gov-east-1.amazonaws.com" "http://api.sagemaker.ca-central-1.amazonaws.com" "http://api.sagemaker.eu-north-1.amazonaws.com" "http://api.sagemaker.eu-west-1.amazonaws.com" "http://api.sagemaker.eu-west-2.amazonaws.com" "http://api.sagemaker.eu-west-3.amazonaws.com" "http://api.sagemaker.eu-central-1.amazonaws.com" "http://api.sagemaker.eu-south-1.amazonaws.com" "http://api.sagemaker.af-south-1.amazonaws.com" "http://api.sagemaker.ap-northeast-1.amazonaws.com" "http://api.sagemaker.ap-northeast-2.amazonaws.com" "http://api.sagemaker.ap-northeast-3.amazonaws.com" "http://api.sagemaker.ap-southeast-1.amazonaws.com" "http://api.sagemaker.ap-southeast-2.amazonaws.com" "http://api.sagemaker.ap-east-1.amazonaws.com" "http://api.sagemaker.ap-south-1.amazonaws.com" "http://api.sagemaker.sa-east-1.amazonaws.com" "http://api.sagemaker.me-south-1.amazonaws.com" "https://api.sagemaker.us-east-1.amazonaws.com" "https://api.sagemaker.us-east-2.amazonaws.com" "https://api.sagemaker.us-west-1.amazonaws.com" "https://api.sagemaker.us-west-2.amazonaws.com" "https://api.sagemaker.us-gov-west-1.amazonaws.com" "https://api.sagemaker.us-gov-east-1.amazonaws.com" "https://api.sagemaker.ca-central-1.amazonaws.com" "https://api.sagemaker.eu-north-1.amazonaws.com" "https://api.sagemaker.eu-west-1.amazonaws.com" "https://api.sagemaker.eu-west-2.amazonaws.com" "https://api.sagemaker.eu-west-3.amazonaws.com" "https://api.sagemaker.eu-central-1.amazonaws.com" "https://api.sagemaker.eu-south-1.amazonaws.com" "https://api.sagemaker.af-south-1.amazonaws.com" "https://api.sagemaker.ap-northeast-1.amazonaws.com" "https://api.sagemaker.ap-northeast-2.amazonaws.com" "https://api.sagemaker.ap-northeast-3.amazonaws.com" "https://api.sagemaker.ap-southeast-1.amazonaws.com" "https://api.sagemaker.ap-southeast-2.amazonaws.com" "https://api.sagemaker.ap-east-1.amazonaws.com" "https://api.sagemaker.ap-south-1.amazonaws.com" "https://api.sagemaker.sa-east-1.amazonaws.com" "https://api.sagemaker.me-south-1.amazonaws.com" "http://api.sagemaker.cn-north-1.amazonaws.com.cn" "http://api.sagemaker.cn-northwest-1.amazonaws.com.cn" "https://api.sagemaker.cn-north-1.amazonaws.com.cn" "https://api.sagemaker.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["SageMaker.AddAssociation"] }
def x-amz-target-completer-1 [] { ["SageMaker.AddTags"] }
def x-amz-target-completer-2 [] { ["SageMaker.AssociateTrialComponent"] }
def x-amz-target-completer-3 [] { ["SageMaker.BatchDescribeModelPackage"] }
def x-amz-target-completer-4 [] { ["SageMaker.CreateAction"] }
def x-amz-target-completer-5 [] { ["SageMaker.CreateAlgorithm"] }
def x-amz-target-completer-6 [] { ["SageMaker.CreateApp"] }
def x-amz-target-completer-7 [] { ["SageMaker.CreateAppImageConfig"] }
def x-amz-target-completer-8 [] { ["SageMaker.CreateArtifact"] }
def x-amz-target-completer-9 [] { ["SageMaker.CreateAutoMLJob"] }
def x-amz-target-completer-10 [] { ["SageMaker.CreateAutoMLJobV2"] }
def x-amz-target-completer-11 [] { ["SageMaker.CreateCodeRepository"] }
def x-amz-target-completer-12 [] { ["SageMaker.CreateCompilationJob"] }
def x-amz-target-completer-13 [] { ["SageMaker.CreateContext"] }
def x-amz-target-completer-14 [] { ["SageMaker.CreateDataQualityJobDefinition"] }
def x-amz-target-completer-15 [] { ["SageMaker.CreateDeviceFleet"] }
def x-amz-target-completer-16 [] { ["SageMaker.CreateDomain"] }
def x-amz-target-completer-17 [] { ["SageMaker.CreateEdgeDeploymentPlan"] }
def x-amz-target-completer-18 [] { ["SageMaker.CreateEdgeDeploymentStage"] }
def x-amz-target-completer-19 [] { ["SageMaker.CreateEdgePackagingJob"] }
def x-amz-target-completer-20 [] { ["SageMaker.CreateEndpoint"] }
def x-amz-target-completer-21 [] { ["SageMaker.CreateEndpointConfig"] }
def x-amz-target-completer-22 [] { ["SageMaker.CreateExperiment"] }
def x-amz-target-completer-23 [] { ["SageMaker.CreateFeatureGroup"] }
def x-amz-target-completer-24 [] { ["SageMaker.CreateFlowDefinition"] }
def x-amz-target-completer-25 [] { ["SageMaker.CreateHub"] }
def x-amz-target-completer-26 [] { ["SageMaker.CreateHumanTaskUi"] }
def x-amz-target-completer-27 [] { ["SageMaker.CreateHyperParameterTuningJob"] }
def x-amz-target-completer-28 [] { ["SageMaker.CreateImage"] }
def x-amz-target-completer-29 [] { ["SageMaker.CreateImageVersion"] }
def x-amz-target-completer-30 [] { ["SageMaker.CreateInferenceExperiment"] }
def x-amz-target-completer-31 [] { ["SageMaker.CreateInferenceRecommendationsJob"] }
def x-amz-target-completer-32 [] { ["SageMaker.CreateLabelingJob"] }
def x-amz-target-completer-33 [] { ["SageMaker.CreateModel"] }
def x-amz-target-completer-34 [] { ["SageMaker.CreateModelBiasJobDefinition"] }
def x-amz-target-completer-35 [] { ["SageMaker.CreateModelCard"] }
def x-amz-target-completer-36 [] { ["SageMaker.CreateModelCardExportJob"] }
def x-amz-target-completer-37 [] { ["SageMaker.CreateModelExplainabilityJobDefinition"] }
def x-amz-target-completer-38 [] { ["SageMaker.CreateModelPackage"] }
def x-amz-target-completer-39 [] { ["SageMaker.CreateModelPackageGroup"] }
def x-amz-target-completer-40 [] { ["SageMaker.CreateModelQualityJobDefinition"] }
def x-amz-target-completer-41 [] { ["SageMaker.CreateMonitoringSchedule"] }
def x-amz-target-completer-42 [] { ["SageMaker.CreateNotebookInstance"] }
def x-amz-target-completer-43 [] { ["SageMaker.CreateNotebookInstanceLifecycleConfig"] }
def x-amz-target-completer-44 [] { ["SageMaker.CreatePipeline"] }
def x-amz-target-completer-45 [] { ["SageMaker.CreatePresignedDomainUrl"] }
def x-amz-target-completer-46 [] { ["SageMaker.CreatePresignedNotebookInstanceUrl"] }
def x-amz-target-completer-47 [] { ["SageMaker.CreateProcessingJob"] }
def x-amz-target-completer-48 [] { ["SageMaker.CreateProject"] }
def x-amz-target-completer-49 [] { ["SageMaker.CreateSpace"] }
def x-amz-target-completer-50 [] { ["SageMaker.CreateStudioLifecycleConfig"] }
def x-amz-target-completer-51 [] { ["SageMaker.CreateTrainingJob"] }
def x-amz-target-completer-52 [] { ["SageMaker.CreateTransformJob"] }
def x-amz-target-completer-53 [] { ["SageMaker.CreateTrial"] }
def x-amz-target-completer-54 [] { ["SageMaker.CreateTrialComponent"] }
def x-amz-target-completer-55 [] { ["SageMaker.CreateUserProfile"] }
def x-amz-target-completer-56 [] { ["SageMaker.CreateWorkforce"] }
def x-amz-target-completer-57 [] { ["SageMaker.CreateWorkteam"] }
def x-amz-target-completer-58 [] { ["SageMaker.DeleteAction"] }
def x-amz-target-completer-59 [] { ["SageMaker.DeleteAlgorithm"] }
def x-amz-target-completer-60 [] { ["SageMaker.DeleteApp"] }
def x-amz-target-completer-61 [] { ["SageMaker.DeleteAppImageConfig"] }
def x-amz-target-completer-62 [] { ["SageMaker.DeleteArtifact"] }
def x-amz-target-completer-63 [] { ["SageMaker.DeleteAssociation"] }
def x-amz-target-completer-64 [] { ["SageMaker.DeleteCodeRepository"] }
def x-amz-target-completer-65 [] { ["SageMaker.DeleteContext"] }
def x-amz-target-completer-66 [] { ["SageMaker.DeleteDataQualityJobDefinition"] }
def x-amz-target-completer-67 [] { ["SageMaker.DeleteDeviceFleet"] }
def x-amz-target-completer-68 [] { ["SageMaker.DeleteDomain"] }
def x-amz-target-completer-69 [] { ["SageMaker.DeleteEdgeDeploymentPlan"] }
def x-amz-target-completer-70 [] { ["SageMaker.DeleteEdgeDeploymentStage"] }
def x-amz-target-completer-71 [] { ["SageMaker.DeleteEndpoint"] }
def x-amz-target-completer-72 [] { ["SageMaker.DeleteEndpointConfig"] }
def x-amz-target-completer-73 [] { ["SageMaker.DeleteExperiment"] }
def x-amz-target-completer-74 [] { ["SageMaker.DeleteFeatureGroup"] }
def x-amz-target-completer-75 [] { ["SageMaker.DeleteFlowDefinition"] }
def x-amz-target-completer-76 [] { ["SageMaker.DeleteHub"] }
def x-amz-target-completer-77 [] { ["SageMaker.DeleteHubContent"] }
def x-amz-target-completer-78 [] { ["SageMaker.DeleteHumanTaskUi"] }
def x-amz-target-completer-79 [] { ["SageMaker.DeleteImage"] }
def x-amz-target-completer-80 [] { ["SageMaker.DeleteImageVersion"] }
def x-amz-target-completer-81 [] { ["SageMaker.DeleteInferenceExperiment"] }
def x-amz-target-completer-82 [] { ["SageMaker.DeleteModel"] }
def x-amz-target-completer-83 [] { ["SageMaker.DeleteModelBiasJobDefinition"] }
def x-amz-target-completer-84 [] { ["SageMaker.DeleteModelCard"] }
def x-amz-target-completer-85 [] { ["SageMaker.DeleteModelExplainabilityJobDefinition"] }
def x-amz-target-completer-86 [] { ["SageMaker.DeleteModelPackage"] }
def x-amz-target-completer-87 [] { ["SageMaker.DeleteModelPackageGroup"] }
def x-amz-target-completer-88 [] { ["SageMaker.DeleteModelPackageGroupPolicy"] }
def x-amz-target-completer-89 [] { ["SageMaker.DeleteModelQualityJobDefinition"] }
def x-amz-target-completer-90 [] { ["SageMaker.DeleteMonitoringSchedule"] }
def x-amz-target-completer-91 [] { ["SageMaker.DeleteNotebookInstance"] }
def x-amz-target-completer-92 [] { ["SageMaker.DeleteNotebookInstanceLifecycleConfig"] }
def x-amz-target-completer-93 [] { ["SageMaker.DeletePipeline"] }
def x-amz-target-completer-94 [] { ["SageMaker.DeleteProject"] }
def x-amz-target-completer-95 [] { ["SageMaker.DeleteSpace"] }
def x-amz-target-completer-96 [] { ["SageMaker.DeleteStudioLifecycleConfig"] }
def x-amz-target-completer-97 [] { ["SageMaker.DeleteTags"] }
def x-amz-target-completer-98 [] { ["SageMaker.DeleteTrial"] }
def x-amz-target-completer-99 [] { ["SageMaker.DeleteTrialComponent"] }
def x-amz-target-completer-100 [] { ["SageMaker.DeleteUserProfile"] }
def x-amz-target-completer-101 [] { ["SageMaker.DeleteWorkforce"] }
def x-amz-target-completer-102 [] { ["SageMaker.DeleteWorkteam"] }
def x-amz-target-completer-103 [] { ["SageMaker.DeregisterDevices"] }
def x-amz-target-completer-104 [] { ["SageMaker.DescribeAction"] }
def x-amz-target-completer-105 [] { ["SageMaker.DescribeAlgorithm"] }
def x-amz-target-completer-106 [] { ["SageMaker.DescribeApp"] }
def x-amz-target-completer-107 [] { ["SageMaker.DescribeAppImageConfig"] }
def x-amz-target-completer-108 [] { ["SageMaker.DescribeArtifact"] }
def x-amz-target-completer-109 [] { ["SageMaker.DescribeAutoMLJob"] }
def x-amz-target-completer-110 [] { ["SageMaker.DescribeAutoMLJobV2"] }
def x-amz-target-completer-111 [] { ["SageMaker.DescribeCodeRepository"] }
def x-amz-target-completer-112 [] { ["SageMaker.DescribeCompilationJob"] }
def x-amz-target-completer-113 [] { ["SageMaker.DescribeContext"] }
def x-amz-target-completer-114 [] { ["SageMaker.DescribeDataQualityJobDefinition"] }
def x-amz-target-completer-115 [] { ["SageMaker.DescribeDevice"] }
def x-amz-target-completer-116 [] { ["SageMaker.DescribeDeviceFleet"] }
def x-amz-target-completer-117 [] { ["SageMaker.DescribeDomain"] }
def x-amz-target-completer-118 [] { ["SageMaker.DescribeEdgeDeploymentPlan"] }
def x-amz-target-completer-119 [] { ["SageMaker.DescribeEdgePackagingJob"] }
def x-amz-target-completer-120 [] { ["SageMaker.DescribeEndpoint"] }
def x-amz-target-completer-121 [] { ["SageMaker.DescribeEndpointConfig"] }
def x-amz-target-completer-122 [] { ["SageMaker.DescribeExperiment"] }
def x-amz-target-completer-123 [] { ["SageMaker.DescribeFeatureGroup"] }
def x-amz-target-completer-124 [] { ["SageMaker.DescribeFeatureMetadata"] }
def x-amz-target-completer-125 [] { ["SageMaker.DescribeFlowDefinition"] }
def x-amz-target-completer-126 [] { ["SageMaker.DescribeHub"] }
def x-amz-target-completer-127 [] { ["SageMaker.DescribeHubContent"] }
def x-amz-target-completer-128 [] { ["SageMaker.DescribeHumanTaskUi"] }
def x-amz-target-completer-129 [] { ["SageMaker.DescribeHyperParameterTuningJob"] }
def x-amz-target-completer-130 [] { ["SageMaker.DescribeImage"] }
def x-amz-target-completer-131 [] { ["SageMaker.DescribeImageVersion"] }
def x-amz-target-completer-132 [] { ["SageMaker.DescribeInferenceExperiment"] }
def x-amz-target-completer-133 [] { ["SageMaker.DescribeInferenceRecommendationsJob"] }
def x-amz-target-completer-134 [] { ["SageMaker.DescribeLabelingJob"] }
def x-amz-target-completer-135 [] { ["SageMaker.DescribeLineageGroup"] }
def x-amz-target-completer-136 [] { ["SageMaker.DescribeModel"] }
def x-amz-target-completer-137 [] { ["SageMaker.DescribeModelBiasJobDefinition"] }
def x-amz-target-completer-138 [] { ["SageMaker.DescribeModelCard"] }
def x-amz-target-completer-139 [] { ["SageMaker.DescribeModelCardExportJob"] }
def x-amz-target-completer-140 [] { ["SageMaker.DescribeModelExplainabilityJobDefinition"] }
def x-amz-target-completer-141 [] { ["SageMaker.DescribeModelPackage"] }
def x-amz-target-completer-142 [] { ["SageMaker.DescribeModelPackageGroup"] }
def x-amz-target-completer-143 [] { ["SageMaker.DescribeModelQualityJobDefinition"] }
def x-amz-target-completer-144 [] { ["SageMaker.DescribeMonitoringSchedule"] }
def x-amz-target-completer-145 [] { ["SageMaker.DescribeNotebookInstance"] }
def x-amz-target-completer-146 [] { ["SageMaker.DescribeNotebookInstanceLifecycleConfig"] }
def x-amz-target-completer-147 [] { ["SageMaker.DescribePipeline"] }
def x-amz-target-completer-148 [] { ["SageMaker.DescribePipelineDefinitionForExecution"] }
def x-amz-target-completer-149 [] { ["SageMaker.DescribePipelineExecution"] }
def x-amz-target-completer-150 [] { ["SageMaker.DescribeProcessingJob"] }
def x-amz-target-completer-151 [] { ["SageMaker.DescribeProject"] }
def x-amz-target-completer-152 [] { ["SageMaker.DescribeSpace"] }
def x-amz-target-completer-153 [] { ["SageMaker.DescribeStudioLifecycleConfig"] }
def x-amz-target-completer-154 [] { ["SageMaker.DescribeSubscribedWorkteam"] }
def x-amz-target-completer-155 [] { ["SageMaker.DescribeTrainingJob"] }
def x-amz-target-completer-156 [] { ["SageMaker.DescribeTransformJob"] }
def x-amz-target-completer-157 [] { ["SageMaker.DescribeTrial"] }
def x-amz-target-completer-158 [] { ["SageMaker.DescribeTrialComponent"] }
def x-amz-target-completer-159 [] { ["SageMaker.DescribeUserProfile"] }
def x-amz-target-completer-160 [] { ["SageMaker.DescribeWorkforce"] }
def x-amz-target-completer-161 [] { ["SageMaker.DescribeWorkteam"] }
def x-amz-target-completer-162 [] { ["SageMaker.DisableSagemakerServicecatalogPortfolio"] }
def x-amz-target-completer-163 [] { ["SageMaker.DisassociateTrialComponent"] }
def x-amz-target-completer-164 [] { ["SageMaker.EnableSagemakerServicecatalogPortfolio"] }
def x-amz-target-completer-165 [] { ["SageMaker.GetDeviceFleetReport"] }
def x-amz-target-completer-166 [] { ["SageMaker.GetLineageGroupPolicy"] }
def x-amz-target-completer-167 [] { ["SageMaker.GetModelPackageGroupPolicy"] }
def x-amz-target-completer-168 [] { ["SageMaker.GetSagemakerServicecatalogPortfolioStatus"] }
def x-amz-target-completer-169 [] { ["SageMaker.GetSearchSuggestions"] }
def x-amz-target-completer-170 [] { ["SageMaker.ImportHubContent"] }
def x-amz-target-completer-171 [] { ["SageMaker.ListActions"] }
def x-amz-target-completer-172 [] { ["SageMaker.ListAlgorithms"] }
def x-amz-target-completer-173 [] { ["SageMaker.ListAliases"] }
def x-amz-target-completer-174 [] { ["SageMaker.ListAppImageConfigs"] }
def x-amz-target-completer-175 [] { ["SageMaker.ListApps"] }
def x-amz-target-completer-176 [] { ["SageMaker.ListArtifacts"] }
def x-amz-target-completer-177 [] { ["SageMaker.ListAssociations"] }
def x-amz-target-completer-178 [] { ["SageMaker.ListAutoMLJobs"] }
def x-amz-target-completer-179 [] { ["SageMaker.ListCandidatesForAutoMLJob"] }
def x-amz-target-completer-180 [] { ["SageMaker.ListCodeRepositories"] }
def x-amz-target-completer-181 [] { ["SageMaker.ListCompilationJobs"] }
def x-amz-target-completer-182 [] { ["SageMaker.ListContexts"] }
def x-amz-target-completer-183 [] { ["SageMaker.ListDataQualityJobDefinitions"] }
def x-amz-target-completer-184 [] { ["SageMaker.ListDeviceFleets"] }
def x-amz-target-completer-185 [] { ["SageMaker.ListDevices"] }
def x-amz-target-completer-186 [] { ["SageMaker.ListDomains"] }
def x-amz-target-completer-187 [] { ["SageMaker.ListEdgeDeploymentPlans"] }
def x-amz-target-completer-188 [] { ["SageMaker.ListEdgePackagingJobs"] }
def x-amz-target-completer-189 [] { ["SageMaker.ListEndpointConfigs"] }
def x-amz-target-completer-190 [] { ["SageMaker.ListEndpoints"] }
def x-amz-target-completer-191 [] { ["SageMaker.ListExperiments"] }
def x-amz-target-completer-192 [] { ["SageMaker.ListFeatureGroups"] }
def x-amz-target-completer-193 [] { ["SageMaker.ListFlowDefinitions"] }
def x-amz-target-completer-194 [] { ["SageMaker.ListHubContentVersions"] }
def x-amz-target-completer-195 [] { ["SageMaker.ListHubContents"] }
def x-amz-target-completer-196 [] { ["SageMaker.ListHubs"] }
def x-amz-target-completer-197 [] { ["SageMaker.ListHumanTaskUis"] }
def x-amz-target-completer-198 [] { ["SageMaker.ListHyperParameterTuningJobs"] }
def x-amz-target-completer-199 [] { ["SageMaker.ListImageVersions"] }
def x-amz-target-completer-200 [] { ["SageMaker.ListImages"] }
def x-amz-target-completer-201 [] { ["SageMaker.ListInferenceExperiments"] }
def x-amz-target-completer-202 [] { ["SageMaker.ListInferenceRecommendationsJobSteps"] }
def x-amz-target-completer-203 [] { ["SageMaker.ListInferenceRecommendationsJobs"] }
def x-amz-target-completer-204 [] { ["SageMaker.ListLabelingJobs"] }
def x-amz-target-completer-205 [] { ["SageMaker.ListLabelingJobsForWorkteam"] }
def x-amz-target-completer-206 [] { ["SageMaker.ListLineageGroups"] }
def x-amz-target-completer-207 [] { ["SageMaker.ListModelBiasJobDefinitions"] }
def x-amz-target-completer-208 [] { ["SageMaker.ListModelCardExportJobs"] }
def x-amz-target-completer-209 [] { ["SageMaker.ListModelCardVersions"] }
def x-amz-target-completer-210 [] { ["SageMaker.ListModelCards"] }
def x-amz-target-completer-211 [] { ["SageMaker.ListModelExplainabilityJobDefinitions"] }
def x-amz-target-completer-212 [] { ["SageMaker.ListModelMetadata"] }
def x-amz-target-completer-213 [] { ["SageMaker.ListModelPackageGroups"] }
def x-amz-target-completer-214 [] { ["SageMaker.ListModelPackages"] }
def x-amz-target-completer-215 [] { ["SageMaker.ListModelQualityJobDefinitions"] }
def x-amz-target-completer-216 [] { ["SageMaker.ListModels"] }
def x-amz-target-completer-217 [] { ["SageMaker.ListMonitoringAlertHistory"] }
def x-amz-target-completer-218 [] { ["SageMaker.ListMonitoringAlerts"] }
def x-amz-target-completer-219 [] { ["SageMaker.ListMonitoringExecutions"] }
def x-amz-target-completer-220 [] { ["SageMaker.ListMonitoringSchedules"] }
def x-amz-target-completer-221 [] { ["SageMaker.ListNotebookInstanceLifecycleConfigs"] }
def x-amz-target-completer-222 [] { ["SageMaker.ListNotebookInstances"] }
def x-amz-target-completer-223 [] { ["SageMaker.ListPipelineExecutionSteps"] }
def x-amz-target-completer-224 [] { ["SageMaker.ListPipelineExecutions"] }
def x-amz-target-completer-225 [] { ["SageMaker.ListPipelineParametersForExecution"] }
def x-amz-target-completer-226 [] { ["SageMaker.ListPipelines"] }
def x-amz-target-completer-227 [] { ["SageMaker.ListProcessingJobs"] }
def x-amz-target-completer-228 [] { ["SageMaker.ListProjects"] }
def x-amz-target-completer-229 [] { ["SageMaker.ListSpaces"] }
def x-amz-target-completer-230 [] { ["SageMaker.ListStageDevices"] }
def x-amz-target-completer-231 [] { ["SageMaker.ListStudioLifecycleConfigs"] }
def x-amz-target-completer-232 [] { ["SageMaker.ListSubscribedWorkteams"] }
def x-amz-target-completer-233 [] { ["SageMaker.ListTags"] }
def x-amz-target-completer-234 [] { ["SageMaker.ListTrainingJobs"] }
def x-amz-target-completer-235 [] { ["SageMaker.ListTrainingJobsForHyperParameterTuningJob"] }
def x-amz-target-completer-236 [] { ["SageMaker.ListTransformJobs"] }
def x-amz-target-completer-237 [] { ["SageMaker.ListTrialComponents"] }
def x-amz-target-completer-238 [] { ["SageMaker.ListTrials"] }
def x-amz-target-completer-239 [] { ["SageMaker.ListUserProfiles"] }
def x-amz-target-completer-240 [] { ["SageMaker.ListWorkforces"] }
def x-amz-target-completer-241 [] { ["SageMaker.ListWorkteams"] }
def x-amz-target-completer-242 [] { ["SageMaker.PutModelPackageGroupPolicy"] }
def x-amz-target-completer-243 [] { ["SageMaker.QueryLineage"] }
def x-amz-target-completer-244 [] { ["SageMaker.RegisterDevices"] }
def x-amz-target-completer-245 [] { ["SageMaker.RenderUiTemplate"] }
def x-amz-target-completer-246 [] { ["SageMaker.RetryPipelineExecution"] }
def x-amz-target-completer-247 [] { ["SageMaker.Search"] }
def x-amz-target-completer-248 [] { ["SageMaker.SendPipelineExecutionStepFailure"] }
def x-amz-target-completer-249 [] { ["SageMaker.SendPipelineExecutionStepSuccess"] }
def x-amz-target-completer-250 [] { ["SageMaker.StartEdgeDeploymentStage"] }
def x-amz-target-completer-251 [] { ["SageMaker.StartInferenceExperiment"] }
def x-amz-target-completer-252 [] { ["SageMaker.StartMonitoringSchedule"] }
def x-amz-target-completer-253 [] { ["SageMaker.StartNotebookInstance"] }
def x-amz-target-completer-254 [] { ["SageMaker.StartPipelineExecution"] }
def x-amz-target-completer-255 [] { ["SageMaker.StopAutoMLJob"] }
def x-amz-target-completer-256 [] { ["SageMaker.StopCompilationJob"] }
def x-amz-target-completer-257 [] { ["SageMaker.StopEdgeDeploymentStage"] }
def x-amz-target-completer-258 [] { ["SageMaker.StopEdgePackagingJob"] }
def x-amz-target-completer-259 [] { ["SageMaker.StopHyperParameterTuningJob"] }
def x-amz-target-completer-260 [] { ["SageMaker.StopInferenceExperiment"] }
def x-amz-target-completer-261 [] { ["SageMaker.StopInferenceRecommendationsJob"] }
def x-amz-target-completer-262 [] { ["SageMaker.StopLabelingJob"] }
def x-amz-target-completer-263 [] { ["SageMaker.StopMonitoringSchedule"] }
def x-amz-target-completer-264 [] { ["SageMaker.StopNotebookInstance"] }
def x-amz-target-completer-265 [] { ["SageMaker.StopPipelineExecution"] }
def x-amz-target-completer-266 [] { ["SageMaker.StopProcessingJob"] }
def x-amz-target-completer-267 [] { ["SageMaker.StopTrainingJob"] }
def x-amz-target-completer-268 [] { ["SageMaker.StopTransformJob"] }
def x-amz-target-completer-269 [] { ["SageMaker.UpdateAction"] }
def x-amz-target-completer-270 [] { ["SageMaker.UpdateAppImageConfig"] }
def x-amz-target-completer-271 [] { ["SageMaker.UpdateArtifact"] }
def x-amz-target-completer-272 [] { ["SageMaker.UpdateCodeRepository"] }
def x-amz-target-completer-273 [] { ["SageMaker.UpdateContext"] }
def x-amz-target-completer-274 [] { ["SageMaker.UpdateDeviceFleet"] }
def x-amz-target-completer-275 [] { ["SageMaker.UpdateDevices"] }
def x-amz-target-completer-276 [] { ["SageMaker.UpdateDomain"] }
def x-amz-target-completer-277 [] { ["SageMaker.UpdateEndpoint"] }
def x-amz-target-completer-278 [] { ["SageMaker.UpdateEndpointWeightsAndCapacities"] }
def x-amz-target-completer-279 [] { ["SageMaker.UpdateExperiment"] }
def x-amz-target-completer-280 [] { ["SageMaker.UpdateFeatureGroup"] }
def x-amz-target-completer-281 [] { ["SageMaker.UpdateFeatureMetadata"] }
def x-amz-target-completer-282 [] { ["SageMaker.UpdateHub"] }
def x-amz-target-completer-283 [] { ["SageMaker.UpdateImage"] }
def x-amz-target-completer-284 [] { ["SageMaker.UpdateImageVersion"] }
def x-amz-target-completer-285 [] { ["SageMaker.UpdateInferenceExperiment"] }
def x-amz-target-completer-286 [] { ["SageMaker.UpdateModelCard"] }
def x-amz-target-completer-287 [] { ["SageMaker.UpdateModelPackage"] }
def x-amz-target-completer-288 [] { ["SageMaker.UpdateMonitoringAlert"] }
def x-amz-target-completer-289 [] { ["SageMaker.UpdateMonitoringSchedule"] }
def x-amz-target-completer-290 [] { ["SageMaker.UpdateNotebookInstance"] }
def x-amz-target-completer-291 [] { ["SageMaker.UpdateNotebookInstanceLifecycleConfig"] }
def x-amz-target-completer-292 [] { ["SageMaker.UpdatePipeline"] }
def x-amz-target-completer-293 [] { ["SageMaker.UpdatePipelineExecution"] }
def x-amz-target-completer-294 [] { ["SageMaker.UpdateProject"] }
def x-amz-target-completer-295 [] { ["SageMaker.UpdateSpace"] }
def x-amz-target-completer-296 [] { ["SageMaker.UpdateTrainingJob"] }
def x-amz-target-completer-297 [] { ["SageMaker.UpdateTrial"] }
def x-amz-target-completer-298 [] { ["SageMaker.UpdateTrialComponent"] }
def x-amz-target-completer-299 [] { ["SageMaker.UpdateUserProfile"] }
def x-amz-target-completer-300 [] { ["SageMaker.UpdateWorkforce"] }
def x-amz-target-completer-301 [] { ["SageMaker.UpdateWorkteam"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-sage-maker-add-association create" } } | get name | first)
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

# Creates an association between the source and the destination. A source can be associated with multiple destinations, and a destination can be associated with multiple sources. An association is a lineage tracking entity. For more information, see Amazon SageMaker ML Lineage Tracking (https://docs.aws.amazon.com/sagemaker/latest/dg/lineage-tracking.html).
#
# POST /#X-Amz-Target=SageMaker.AddAssociation
# operationId: AddAssociation
export def "x-amz-target-sage-maker-add-association create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer
  source_arn: any
  destination_arn: any
  --association-type: any
]: any -> record<SourceArn: record, DestinationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.AddAssociation")
  let req_body = {"SourceArn": $source_arn, "DestinationArn": $destination_arn, "AssociationType": $association_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Adds or overwrites one or more tags for the specified SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints. Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see Amazon Web Services Tagging Strategies (https://aws.amazon.com/answers/account-management/aws-tagging-strategies/). Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the Tags parameter of CreateHyperParameterTuningJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateHyperParameterTuningJob.html) Tags that you add to a SageMaker Studio Domain or User Profile by calling this API are also added to any Apps that the Domain or User Profile launches after you call this API, but not to Apps that the Domain or User Profile launched before you called this API. To make sure that the tags associated with a Domain or User Profile are also added to all Apps that the Domain or User Profile launches, add the tags when you first create the Domain or User Profile by specifying them in the Tags parameter of CreateDomain (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateDomain.html) or CreateUserProfile (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateUserProfile.html).
#
# POST /#X-Amz-Target=SageMaker.AddTags
# operationId: AddTags
export def "x-amz-target-sage-maker-add-tags create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-1
  resource_arn: any
  tags: any
]: any -> record<Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.AddTags")
  let req_body = {"ResourceArn": $resource_arn, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the DisassociateTrialComponent (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DisassociateTrialComponent.html) API.
#
# POST /#X-Amz-Target=SageMaker.AssociateTrialComponent
# operationId: AssociateTrialComponent
export def "x-amz-target-sage-maker-associate-trial-component create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-2
  trial_component_name: any
  trial_name: any
]: any -> record<TrialComponentArn: record, TrialArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.AssociateTrialComponent")
  let req_body = {"TrialComponentName": $trial_component_name, "TrialName": $trial_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# This action batch describes a list of versioned model packages
#
# POST /#X-Amz-Target=SageMaker.BatchDescribeModelPackage
# operationId: BatchDescribeModelPackage
export def "x-amz-target-sage-maker-batch-describe-model-package get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-3
  model_package_arn_list: any
]: any -> record<ModelPackageSummaries: record, BatchDescribeModelPackageErrorMap: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.BatchDescribeModelPackage")
  let req_body = {"ModelPackageArnList": $model_package_arn_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an action. An action is a lineage tracking entity that represents an action or activity. For example, a model deployment or an HPO job. Generally, an action involves at least one input or output artifact. For more information, see Amazon SageMaker ML Lineage Tracking (https://docs.aws.amazon.com/sagemaker/latest/dg/lineage-tracking.html).
#
# POST /#X-Amz-Target=SageMaker.CreateAction
# operationId: CreateAction
# --MetadataProperties shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
export def "x-amz-target-sage-maker-create-action create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-4
  action_name: any
  --body-source: any
  action_type: any
  --description: any
  --status: any
  --properties: any
  --metadata-properties: record # Metadata properties of the tracking entity, trial, or trial component. — shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
  --tags: any
]: any -> record<ActionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateAction")
  let req_body = {"ActionName": $action_name, "Source": $body_source, "ActionType": $action_type, "Description": $description, "Status": $status, "Properties": $properties, "MetadataProperties": $metadata_properties, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create a machine learning algorithm that you can use in SageMaker and list in the Amazon Web Services Marketplace.
#
# POST /#X-Amz-Target=SageMaker.CreateAlgorithm
# operationId: CreateAlgorithm
export def "x-amz-target-sage-maker-create-algorithm create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-5
  algorithm_name: any
  --algorithm-description: any
  training_specification: any
  --inference-specification: any
  --validation-specification: any
  --certify-for-marketplace: any
  --tags: any
]: any -> record<AlgorithmArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateAlgorithm")
  let req_body = {"AlgorithmName": $algorithm_name, "AlgorithmDescription": $algorithm_description, "TrainingSpecification": $training_specification, "InferenceSpecification": $inference_specification, "ValidationSpecification": $validation_specification, "CertifyForMarketplace": $certify_for_marketplace, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a running app for the specified UserProfile. This operation is automatically invoked by Amazon SageMaker Studio upon access to the associated Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously.
#
# POST /#X-Amz-Target=SageMaker.CreateApp
# operationId: CreateApp
export def "x-amz-target-sage-maker-create-app create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-6
  domain_id: any
  --user-profile-name: any
  app_type: any
  app_name: any
  --tags: any
  --resource-spec: any
  --space-name: any
]: any -> record<AppArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateApp")
  let req_body = {"DomainId": $domain_id, "UserProfileName": $user_profile_name, "AppType": $app_type, "AppName": $app_name, "Tags": $tags, "ResourceSpec": $resource_spec, "SpaceName": $space_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a configuration for running a SageMaker image as a KernelGateway app. The configuration specifies the Amazon Elastic File System (EFS) storage volume on the image, and a list of the kernels in the image.
#
# POST /#X-Amz-Target=SageMaker.CreateAppImageConfig
# operationId: CreateAppImageConfig
export def "x-amz-target-sage-maker-create-app-image-config create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-7
  app_image_config_name: any
  --tags: any
  --kernel-gateway-image-config: any
]: any -> record<AppImageConfigArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateAppImageConfig")
  let req_body = {"AppImageConfigName": $app_image_config_name, "Tags": $tags, "KernelGatewayImageConfig": $kernel_gateway_image_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an artifact. An artifact is a lineage tracking entity that represents a URI addressable object or data. Some examples are the S3 URI of a dataset and the ECR registry path of an image. For more information, see Amazon SageMaker ML Lineage Tracking (https://docs.aws.amazon.com/sagemaker/latest/dg/lineage-tracking.html).
#
# POST /#X-Amz-Target=SageMaker.CreateArtifact
# operationId: CreateArtifact
# --MetadataProperties shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
export def "x-amz-target-sage-maker-create-artifact create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-8
  --artifact-name: any
  --body-source: any
  artifact_type: any
  --properties: any
  --metadata-properties: record # Metadata properties of the tracking entity, trial, or trial component. — shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
  --tags: any
]: any -> record<ArtifactArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateArtifact")
  let req_body = {"ArtifactName": $artifact_name, "Source": $body_source, "ArtifactType": $artifact_type, "Properties": $properties, "MetadataProperties": $metadata_properties, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an Autopilot job. Find the best-performing model after you run an Autopilot job by calling DescribeAutoMLJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeAutoMLJob.html). For information about how to use Autopilot, see Automate Model Development with Amazon SageMaker Autopilot (https://docs.aws.amazon.com/sagemaker/latest/dg/autopilot-automate-model-development.html).
#
# POST /#X-Amz-Target=SageMaker.CreateAutoMLJob
# operationId: CreateAutoMLJob
export def "x-amz-target-sage-maker-create-auto-ml-job create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-9
  auto_ml_job_name: any
  input_data_config: any
  output_data_config: any
  --problem-type: any
  --auto-ml-job-objective: any
  --auto-ml-job-config: any
  role_arn: any
  --generate-candidate-definitions-only: any
  --tags: any
  --model-deploy-config: any
]: any -> record<AutoMLJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateAutoMLJob")
  let req_body = {"AutoMLJobName": $auto_ml_job_name, "InputDataConfig": $input_data_config, "OutputDataConfig": $output_data_config, "ProblemType": $problem_type, "AutoMLJobObjective": $auto_ml_job_objective, "AutoMLJobConfig": $auto_ml_job_config, "RoleArn": $role_arn, "GenerateCandidateDefinitionsOnly": $generate_candidate_definitions_only, "Tags": $tags, "ModelDeployConfig": $model_deploy_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an Amazon SageMaker AutoML job that uses non-tabular data such as images or text for Computer Vision or Natural Language Processing problems. Find the resulting model after you run an AutoML job V2 by calling DescribeAutoMLJobV2 (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeAutoMLJobV2.html). To create an AutoMLJob using tabular data, see CreateAutoMLJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateAutoMLJob.html). This API action is callable through SageMaker Canvas only. Calling it directly from the CLI or an SDK results in an error.
#
# POST /#X-Amz-Target=SageMaker.CreateAutoMLJobV2
# operationId: CreateAutoMLJobV2
export def "x-amz-target-sage-maker-create-auto-ml-job-v2 create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-10
  auto_ml_job_name: any
  auto_ml_job_input_data_config: any
  output_data_config: any
  auto_ml_problem_type_config: any
  role_arn: any
  --tags: any
  --security-config: any
  --auto-ml-job-objective: any
  --model-deploy-config: any
  --data-split-config: any
]: any -> record<AutoMLJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateAutoMLJobV2")
  let req_body = {"AutoMLJobName": $auto_ml_job_name, "AutoMLJobInputDataConfig": $auto_ml_job_input_data_config, "OutputDataConfig": $output_data_config, "AutoMLProblemTypeConfig": $auto_ml_problem_type_config, "RoleArn": $role_arn, "Tags": $tags, "SecurityConfig": $security_config, "AutoMLJobObjective": $auto_ml_job_objective, "ModelDeployConfig": $model_deploy_config, "DataSplitConfig": $data_split_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a Git repository as a resource in your SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with. The repository can be hosted either in Amazon Web Services CodeCommit (https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html) or in any other Git repository.
#
# POST /#X-Amz-Target=SageMaker.CreateCodeRepository
# operationId: CreateCodeRepository
export def "x-amz-target-sage-maker-create-code-repository create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-11
  code_repository_name: any
  git_config: any
  --tags: any
]: any -> record<CodeRepositoryArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateCodeRepository")
  let req_body = {"CodeRepositoryName": $code_repository_name, "GitConfig": $git_config, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with Amazon Web Services IoT Greengrass. In that case, deploy them as an ML resource. In the request body, you provide the following: A name for the compilation job Information about the input model artifacts The output location for the compiled model and the device (target) that the model runs on The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job. You can also provide a Tag to track the model compilation job's resource use and costs. The response body contains the CompilationJobArn for the compiled job. To stop a model compilation job, use StopCompilationJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_StopCompilationJob.html). To get information about a particular model compilation job, use DescribeCompilationJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeCompilationJob.html). To get information about multiple model compilation jobs, use ListCompilationJobs (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_ListCompilationJobs.html).
#
# POST /#X-Amz-Target=SageMaker.CreateCompilationJob
# operationId: CreateCompilationJob
export def "x-amz-target-sage-maker-create-compilation-job create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-12
  compilation_job_name: any
  role_arn: any
  --model-package-version-arn: any
  --input-config: any
  output_config: any
  --vpc-config: any
  stopping_condition: any
  --tags: any
]: any -> record<CompilationJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateCompilationJob")
  let req_body = {"CompilationJobName": $compilation_job_name, "RoleArn": $role_arn, "ModelPackageVersionArn": $model_package_version_arn, "InputConfig": $input_config, "OutputConfig": $output_config, "VpcConfig": $vpc_config, "StoppingCondition": $stopping_condition, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a context. A context is a lineage tracking entity that represents a logical grouping of other tracking or experiment entities. Some examples are an endpoint and a model package. For more information, see Amazon SageMaker ML Lineage Tracking (https://docs.aws.amazon.com/sagemaker/latest/dg/lineage-tracking.html).
#
# POST /#X-Amz-Target=SageMaker.CreateContext
# operationId: CreateContext
export def "x-amz-target-sage-maker-create-context create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-13
  context_name: any
  --body-source: any
  context_type: any
  --description: any
  --properties: any
  --tags: any
]: any -> record<ContextArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateContext")
  let req_body = {"ContextName": $context_name, "Source": $body_source, "ContextType": $context_type, "Description": $description, "Properties": $properties, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a definition for a job that monitors data quality and drift. For information about model monitor, see Amazon SageMaker Model Monitor (https://docs.aws.amazon.com/sagemaker/latest/dg/model-monitor.html).
#
# POST /#X-Amz-Target=SageMaker.CreateDataQualityJobDefinition
# operationId: CreateDataQualityJobDefinition
# --DataQualityJobOutputConfig shape: {MonitoringOutputs: any, KmsKeyId?: any}
# --JobResources shape: {ClusterConfig: any}
# --StoppingCondition shape: {MaxRuntimeInSeconds: any}
export def "x-amz-target-sage-maker-create-data-quality-job-definition create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-14
  job_definition_name: any
  --data-quality-baseline-config: any
  data_quality_app_specification: any
  data_quality_job_input: any
  data_quality_job_output_config: record # The output configuration for monitoring jobs. — shape: {MonitoringOutputs: any, KmsKeyId?: any}
  job_resources: record # Identifies the resources to deploy for a monitoring job. — shape: {ClusterConfig: any}
  --network-config: any
  role_arn: any
  --stopping-condition: record # A time limit for how long the monitoring job is allowed to run before stopping. — shape: {MaxRuntimeInSeconds: any}
  --tags: any
]: any -> record<JobDefinitionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateDataQualityJobDefinition")
  let req_body = {"JobDefinitionName": $job_definition_name, "DataQualityBaselineConfig": $data_quality_baseline_config, "DataQualityAppSpecification": $data_quality_app_specification, "DataQualityJobInput": $data_quality_job_input, "DataQualityJobOutputConfig": $data_quality_job_output_config, "JobResources": $job_resources, "NetworkConfig": $network_config, "RoleArn": $role_arn, "StoppingCondition": $stopping_condition, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a device fleet.
#
# POST /#X-Amz-Target=SageMaker.CreateDeviceFleet
# operationId: CreateDeviceFleet
export def "x-amz-target-sage-maker-create-device-fleet create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-15
  device_fleet_name: any
  --role-arn: any
  --description: any
  output_config: any
  --tags: any
  --enable-iot-role-alias: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateDeviceFleet")
  let req_body = {"DeviceFleetName": $device_fleet_name, "RoleArn": $role_arn, "Description": $description, "OutputConfig": $output_config, "Tags": $tags, "EnableIotRoleAlias": $enable_iot_role_alias} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a Domain used by Amazon SageMaker Studio. A domain consists of an associated Amazon Elastic File System (EFS) volume, a list of authorized users, and a variety of security, application, policy, and Amazon Virtual Private Cloud (VPC) configurations. Users within a domain can share notebook files and other artifacts with each other. EFS storage When a domain is created, an EFS volume is created for use by all of the users within the domain. Each user receives a private home directory within the EFS volume for notebooks, Git repositories, and data files. SageMaker uses the Amazon Web Services Key Management Service (Amazon Web Services KMS) to encrypt the EFS volume attached to the domain with an Amazon Web Services managed key by default. For more control, you can specify a customer managed key. For more information, see Protect Data at Rest Using Encryption (https://docs.aws.amazon.com/sagemaker/latest/dg/encryption-at-rest.html). VPC configuration All SageMaker Studio traffic between the domain and the EFS volume is through the specified VPC and subnets. For other Studio traffic, you can specify the AppNetworkAccessType parameter. AppNetworkAccessType corresponds to the network access type that you choose when you onboard to Studio. The following options are available: PublicInternetOnly - Non-EFS traffic goes through a VPC managed by Amazon SageMaker, which allows internet access. This is the default value. VpcOnly - All Studio traffic is through the specified VPC and subnets. Internet access is disabled by default. To allow internet access, you must specify a NAT gateway. When internet access is disabled, you won't be able to run a Studio notebook or to train or host models unless your VPC has an interface endpoint to the SageMaker API and runtime or a NAT gateway and your security groups allow outbound connections. NFS traffic over TCP on port 2049 needs to be allowed in both inbound and outbound rules in order to launch a SageMaker Studio app successfully. For more information, see Connect SageMaker Studio Notebooks to Resources in a VPC (https://docs.aws.amazon.com/sagemaker/latest/dg/studio-notebooks-and-internet-access.html).
#
# POST /#X-Amz-Target=SageMaker.CreateDomain
# operationId: CreateDomain
export def "x-amz-target-sage-maker-create-domain create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-16
  domain_name: any
  auth_mode: any
  default_user_settings: any
  subnet_ids: any
  vpc_id: any
  --tags: any
  --app-network-access-type: any
  --home-efs-file-system-kms-key-id: any
  --kms-key-id: any
  --app-security-group-management: any
  --domain-settings: any
  --default-space-settings: any
]: any -> record<DomainArn: record, Url: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateDomain")
  let req_body = {"DomainName": $domain_name, "AuthMode": $auth_mode, "DefaultUserSettings": $default_user_settings, "SubnetIds": $subnet_ids, "VpcId": $vpc_id, "Tags": $tags, "AppNetworkAccessType": $app_network_access_type, "HomeEfsFileSystemKmsKeyId": $home_efs_file_system_kms_key_id, "KmsKeyId": $kms_key_id, "AppSecurityGroupManagement": $app_security_group_management, "DomainSettings": $domain_settings, "DefaultSpaceSettings": $default_space_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an edge deployment plan, consisting of multiple stages. Each stage may have a different deployment configuration and devices.
#
# POST /#X-Amz-Target=SageMaker.CreateEdgeDeploymentPlan
# operationId: CreateEdgeDeploymentPlan
export def "x-amz-target-sage-maker-create-edge-deployment-plan create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-17
  edge_deployment_plan_name: any
  model_configs: any
  device_fleet_name: any
  --stages: any
  --tags: any
]: any -> record<EdgeDeploymentPlanArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateEdgeDeploymentPlan")
  let req_body = {"EdgeDeploymentPlanName": $edge_deployment_plan_name, "ModelConfigs": $model_configs, "DeviceFleetName": $device_fleet_name, "Stages": $stages, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new stage in an existing edge deployment plan.
#
# POST /#X-Amz-Target=SageMaker.CreateEdgeDeploymentStage
# operationId: CreateEdgeDeploymentStage
export def "x-amz-target-sage-maker-create-edge-deployment-stage create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-18
  edge_deployment_plan_name: any
  stages: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateEdgeDeploymentStage")
  let req_body = {"EdgeDeploymentPlanName": $edge_deployment_plan_name, "Stages": $stages} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts a SageMaker Edge Manager model packaging job. Edge Manager will use the model artifacts from the Amazon Simple Storage Service bucket that you specify. After the model has been packaged, Amazon SageMaker saves the resulting artifacts to an S3 bucket that you specify.
#
# POST /#X-Amz-Target=SageMaker.CreateEdgePackagingJob
# operationId: CreateEdgePackagingJob
export def "x-amz-target-sage-maker-create-edge-packaging-job create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-19
  edge_packaging_job_name: any
  compilation_job_name: any
  model_name: any
  model_version: any
  role_arn: any
  output_config: any
  --resource-key: any
  --tags: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateEdgePackagingJob")
  let req_body = {"EdgePackagingJobName": $edge_packaging_job_name, "CompilationJobName": $compilation_job_name, "ModelName": $model_name, "ModelVersion": $model_version, "RoleArn": $role_arn, "OutputConfig": $output_config, "ResourceKey": $resource_key, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an endpoint using the endpoint configuration specified in the request. SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the CreateEndpointConfig (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpointConfig.html) API. Use this API to deploy models using SageMaker hosting services. For an example that calls this method when deploying a model to SageMaker hosting services, see the Create Endpoint example notebook. (https://github.com/aws/amazon-sagemaker-examples/blob/master/sagemaker-fundamentals/create-endpoint/create_endpoint.ipynb) You must not delete an EndpointConfig that is in use by an endpoint that is live or while the UpdateEndpoint or CreateEndpoint operations are being performed on the endpoint. To update an endpoint, you must create a new EndpointConfig. The endpoint name must be unique within an Amazon Web Services Region in your Amazon Web Services account. When it receives the request, SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. When you call CreateEndpoint (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpoint.html), a load call is made to DynamoDB to verify that your endpoint configuration exists. When you read data from a DynamoDB table supporting Eventually Consistent Reads (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadConsistency.html), the response might not reflect the results of a recently completed write operation. The response might include some stale data. If the dependent entities are not yet in DynamoDB, this causes a validation error. If you repeat your read request after a short time, the response should return the latest data. So retry logic is recommended to handle these possible issues. We also recommend that customers call DescribeEndpointConfig (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeEndpointConfig.html) before calling CreateEndpoint (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpoint.html) to minimize the potential impact of a DynamoDB eventually consistent read. When SageMaker receives the request, it sets the endpoint status to Creating. After it creates the endpoint, it sets the status to InService. SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the DescribeEndpoint (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeEndpoint.html) API. If any of the models hosted at this endpoint get model data from an Amazon S3 location, SageMaker uses Amazon Web Services Security Token Service to download model artifacts from the S3 path you provided. Amazon Web Services STS is activated in your Amazon Web Services account by default. If you previously deactivated Amazon Web Services STS for a region, you need to reactivate Amazon Web Services STS for that region. For more information, see Activating and Deactivating Amazon Web Services STS in an Amazon Web Services Region (https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html) in the Amazon Web Services Identity and Access Management User Guide. To add the IAM role policies for using this API operation, go to the IAM console (https://console.aws.amazon.com/iam/), and choose Roles in the left navigation pane. Search the IAM role that you want to grant access to use the CreateEndpoint (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpoint.html) and CreateEndpointConfig (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpointConfig.html) API operations, add the following policies to the role. Option 1: For a full SageMaker access, search and attach the AmazonSageMakerFullAccess policy. Option 2: For granting a limited access to an IAM role, paste the following Action elements manually into the JSON file of the IAM role: "Action": ["sagemaker:CreateEndpoint", "sagemaker:CreateEndpointConfig"] "Resource": [ "arn:aws:sagemaker:region:account-id:endpoint/endpointName" "arn:aws:sagemaker:region:account-id:endpoint-config/endpointConfigName" ] For more information, see SageMaker API Permissions: Actions, Permissions, and Resources Reference (https://docs.aws.amazon.com/sagemaker/latest/dg/api-permissions-reference.html).
#
# POST /#X-Amz-Target=SageMaker.CreateEndpoint
# operationId: CreateEndpoint
# --DeploymentConfig shape: {BlueGreenUpdatePolicy: any, AutoRollbackConfiguration?: any}
export def "x-amz-target-sage-maker-create-endpoint create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-20
  endpoint_name: any
  endpoint_config_name: any
  --deployment-config: record # The deployment configuration for an endpoint, which contains the desired deployment strategy and rollback configurations. — shape: {BlueGreenUpdatePolicy: any, AutoRollbackConfiguration?: any}
  --tags: any
]: any -> record<EndpointArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateEndpoint")
  let req_body = {"EndpointName": $endpoint_name, "EndpointConfigName": $endpoint_config_name, "DeploymentConfig": $deployment_config, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an endpoint configuration that SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the CreateModel API, to deploy and the resources that you want SageMaker to provision. Then you call the CreateEndpoint (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpoint.html) API. Use this API if you want to use SageMaker hosting services to deploy models into production. In the request, you define a ProductionVariant, for each model that you want to deploy. Each ProductionVariant parameter also describes the resources that you want SageMaker to provision. This includes the number and type of ML compute instances to deploy. If you are hosting multiple models, you also assign a VariantWeight to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. When you call CreateEndpoint (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpoint.html), a load call is made to DynamoDB to verify that your endpoint configuration exists. When you read data from a DynamoDB table supporting Eventually Consistent Reads (https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadConsistency.html), the response might not reflect the results of a recently completed write operation. The response might include some stale data. If the dependent entities are not yet in DynamoDB, this causes a validation error. If you repeat your read request after a short time, the response should return the latest data. So retry logic is recommended to handle these possible issues. We also recommend that customers call DescribeEndpointConfig (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeEndpointConfig.html) before calling CreateEndpoint (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpoint.html) to minimize the potential impact of a DynamoDB eventually consistent read.
#
# POST /#X-Amz-Target=SageMaker.CreateEndpointConfig
# operationId: CreateEndpointConfig
# --DataCaptureConfig shape: {EnableCapture?: any, InitialSamplingPercentage: any, DestinationS3Uri: any, KmsKeyId?: any, CaptureOptions: any, CaptureContentTypeHeader?: any}
export def "x-amz-target-sage-maker-create-endpoint-config create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-21
  endpoint_config_name: any
  production_variants: any
  --data-capture-config: record # Configuration to control how SageMaker captures inference data. — shape: {EnableCapture?: any, InitialSamplingPercentage: any, DestinationS3Uri: any, KmsKeyId?: any, CaptureOptions: any, CaptureContentTypeHeader?: any}
  --tags: any
  --kms-key-id: any
  --async-inference-config: any
  --explainer-config: any
  --shadow-production-variants: any
]: any -> record<EndpointConfigArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateEndpointConfig")
  let req_body = {"EndpointConfigName": $endpoint_config_name, "ProductionVariants": $production_variants, "DataCaptureConfig": $data_capture_config, "Tags": $tags, "KmsKeyId": $kms_key_id, "AsyncInferenceConfig": $async_inference_config, "ExplainerConfig": $explainer_config, "ShadowProductionVariants": $shadow_production_variants} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a SageMaker experiment. An experiment is a collection of trials that are observed, compared and evaluated as a group. A trial is a set of steps, called trial components, that produce a machine learning model. In the Studio UI, trials are referred to as run groups and trial components are referred to as runs. The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant. When you use SageMaker Studio or the SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the Amazon Web Services SDK for Python (Boto), you must use the logging APIs provided by the SDK. You can add tags to experiments, trials, trial components and then use the Search (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_Search.html) API to search for the tags. To add a description to an experiment, specify the optional Description parameter. To add a description later, or to change the description, call the UpdateExperiment (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_UpdateExperiment.html) API. To get a list of all your experiments, call the ListExperiments (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_ListExperiments.html) API. To view an experiment's properties, call the DescribeExperiment (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeExperiment.html) API. To get a list of all the trials associated with an experiment, call the ListTrials (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_ListTrials.html) API. To create a trial call the CreateTrial (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTrial.html) API.
#
# POST /#X-Amz-Target=SageMaker.CreateExperiment
# operationId: CreateExperiment
export def "x-amz-target-sage-maker-create-experiment create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-22
  experiment_name: any
  --display-name: any
  --description: any
  --tags: any
]: any -> record<ExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateExperiment")
  let req_body = {"ExperimentName": $experiment_name, "DisplayName": $display_name, "Description": $description, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create a new FeatureGroup. A FeatureGroup is a group of Features defined in the FeatureStore to describe a Record. The FeatureGroup defines the schema and features contained in the FeatureGroup. A FeatureGroup definition is composed of a list of Features, a RecordIdentifierFeatureName, an EventTimeFeatureName and configurations for its OnlineStore and OfflineStore. Check Amazon Web Services service quotas (https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html) to see the FeatureGroups quota for your Amazon Web Services account. You must include at least one of OnlineStoreConfig and OfflineStoreConfig to create a FeatureGroup.
#
# POST /#X-Amz-Target=SageMaker.CreateFeatureGroup
# operationId: CreateFeatureGroup
export def "x-amz-target-sage-maker-create-feature-group create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-23
  feature_group_name: any
  record_identifier_feature_name: any
  event_time_feature_name: any
  feature_definitions: any
  --online-store-config: any
  --offline-store-config: any
  --role-arn: any
  --description: any
  --tags: any
]: any -> record<FeatureGroupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateFeatureGroup")
  let req_body = {"FeatureGroupName": $feature_group_name, "RecordIdentifierFeatureName": $record_identifier_feature_name, "EventTimeFeatureName": $event_time_feature_name, "FeatureDefinitions": $feature_definitions, "OnlineStoreConfig": $online_store_config, "OfflineStoreConfig": $offline_store_config, "RoleArn": $role_arn, "Description": $description, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a flow definition.
#
# POST /#X-Amz-Target=SageMaker.CreateFlowDefinition
# operationId: CreateFlowDefinition
export def "x-amz-target-sage-maker-create-flow-definition create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-24
  flow_definition_name: any
  --human-loop-request-source: any
  --human-loop-activation-config: any
  human_loop_config: any
  output_config: any
  role_arn: any
  --tags: any
]: any -> record<FlowDefinitionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateFlowDefinition")
  let req_body = {"FlowDefinitionName": $flow_definition_name, "HumanLoopRequestSource": $human_loop_request_source, "HumanLoopActivationConfig": $human_loop_activation_config, "HumanLoopConfig": $human_loop_config, "OutputConfig": $output_config, "RoleArn": $role_arn, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create a hub. Hub APIs are only callable through SageMaker Studio.
#
# POST /#X-Amz-Target=SageMaker.CreateHub
# operationId: CreateHub
export def "x-amz-target-sage-maker-create-hub create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-25
  hub_name: any
  hub_description: any
  --hub-display-name: any
  --hub-search-keywords: any
  --s3-storage-config: any
  --tags: any
]: any -> record<HubArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateHub")
  let req_body = {"HubName": $hub_name, "HubDescription": $hub_description, "HubDisplayName": $hub_display_name, "HubSearchKeywords": $hub_search_keywords, "S3StorageConfig": $s3_storage_config, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
#
# POST /#X-Amz-Target=SageMaker.CreateHumanTaskUi
# operationId: CreateHumanTaskUi
# --UiTemplate shape: {Content: any}
export def "x-amz-target-sage-maker-create-human-task-ui create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-26
  human_task_ui_name: any
  ui_template: record # The Liquid template for the worker user interface. — shape: {Content: any}
  --tags: any
]: any -> record<HumanTaskUiArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateHumanTaskUi")
  let req_body = {"HumanTaskUiName": $human_task_ui_name, "UiTemplate": $ui_template, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose. A hyperparameter tuning job automatically creates Amazon SageMaker experiments, trials, and trial components for each training job that it runs. You can view these entities in Amazon SageMaker Studio. For more information, see View Experiments, Trials, and Trial Components (https://docs.aws.amazon.com/sagemaker/latest/dg/experiments-view-compare.html#experiments-view). Do not include any security-sensitive information including account access IDs, secrets or tokens in any hyperparameter field. If the use of security-sensitive credentials are detected, SageMaker will reject your training job request and return an exception error.
#
# POST /#X-Amz-Target=SageMaker.CreateHyperParameterTuningJob
# operationId: CreateHyperParameterTuningJob
export def "x-amz-target-sage-maker-create-hyper-parameter-tuning-job create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-27
  hyper_parameter_tuning_job_name: any
  hyper_parameter_tuning_job_config: any
  --training-job-definition: any
  --training-job-definitions: any
  --warm-start-config: any
  --tags: any
]: any -> record<HyperParameterTuningJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateHyperParameterTuningJob")
  let req_body = {"HyperParameterTuningJobName": $hyper_parameter_tuning_job_name, "HyperParameterTuningJobConfig": $hyper_parameter_tuning_job_config, "TrainingJobDefinition": $training_job_definition, "TrainingJobDefinitions": $training_job_definitions, "WarmStartConfig": $warm_start_config, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a custom SageMaker image. A SageMaker image is a set of image versions. Each image version represents a container image stored in Amazon Elastic Container Registry (ECR). For more information, see Bring your own SageMaker image (https://docs.aws.amazon.com/sagemaker/latest/dg/studio-byoi.html).
#
# POST /#X-Amz-Target=SageMaker.CreateImage
# operationId: CreateImage
export def "x-amz-target-sage-maker-create-image create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-28
  --description: any
  --display-name: any
  image_name: any
  role_arn: any
  --tags: any
]: any -> record<ImageArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateImage")
  let req_body = {"Description": $description, "DisplayName": $display_name, "ImageName": $image_name, "RoleArn": $role_arn, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a version of the SageMaker image specified by ImageName. The version represents the Amazon Elastic Container Registry (ECR) container image specified by BaseImage.
#
# POST /#X-Amz-Target=SageMaker.CreateImageVersion
# operationId: CreateImageVersion
export def "x-amz-target-sage-maker-create-image-version create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29
  base_image: any
  client_token: any
  image_name: any
  --aliases: any
  --vendor-guidance: any
  --job-type: any
  --ml-framework: any
  --programming-lang: any
  --processor: any
  --horovod: any
  --release-notes: any
]: any -> record<ImageVersionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateImageVersion")
  let req_body = {"BaseImage": $base_image, "ClientToken": $client_token, "ImageName": $image_name, "Aliases": $aliases, "VendorGuidance": $vendor_guidance, "JobType": $job_type, "MLFramework": $ml_framework, "ProgrammingLang": $programming_lang, "Processor": $processor, "Horovod": $horovod, "ReleaseNotes": $release_notes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an inference experiment using the configurations specified in the request. Use this API to setup and schedule an experiment to compare model variants on a Amazon SageMaker inference endpoint. For more information about inference experiments, see Shadow tests (https://docs.aws.amazon.com/sagemaker/latest/dg/shadow-tests.html). Amazon SageMaker begins your experiment at the scheduled time and routes traffic to your endpoint's model variants based on your specified configuration. While the experiment is in progress or after it has concluded, you can view metrics that compare your model variants. For more information, see View, monitor, and edit shadow tests (https://docs.aws.amazon.com/sagemaker/latest/dg/shadow-tests-view-monitor-edit.html).
#
# POST /#X-Amz-Target=SageMaker.CreateInferenceExperiment
# operationId: CreateInferenceExperiment
export def "x-amz-target-sage-maker-create-inference-experiment create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-30
  name: any
  type: any
  --schedule: any
  --description: any
  role_arn: any
  endpoint_name: any
  model_variants: any
  --data-storage-config: any
  shadow_mode_config: any
  --kms-key: any
  --tags: any
]: any -> record<InferenceExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateInferenceExperiment")
  let req_body = {"Name": $name, "Type": $type, "Schedule": $schedule, "Description": $description, "RoleArn": $role_arn, "EndpointName": $endpoint_name, "ModelVariants": $model_variants, "DataStorageConfig": $data_storage_config, "ShadowModeConfig": $shadow_mode_config, "KmsKey": $kms_key, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts a recommendation job. You can create either an instance recommendation or load test job.
#
# POST /#X-Amz-Target=SageMaker.CreateInferenceRecommendationsJob
# operationId: CreateInferenceRecommendationsJob
export def "x-amz-target-sage-maker-create-inference-recommendations-job create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-31
  job_name: any
  job_type: any
  role_arn: any
  input_config: any
  --job-description: any
  --stopping-conditions: any
  --output-config: any
  --tags: any
]: any -> record<JobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateInferenceRecommendationsJob")
  let req_body = {"JobName": $job_name, "JobType": $job_type, "RoleArn": $role_arn, "InputConfig": $input_config, "JobDescription": $job_description, "StoppingConditions": $stopping_conditions, "OutputConfig": $output_config, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models. You can select your workforce from one of three providers: A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required. One or more vendors that you select from the Amazon Web Services Marketplace. Vendors provide expertise in specific areas. The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information. You can also use automated data labeling to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses active learning to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see Using Automated Data Labeling (https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html). The data objects to be labeled are contained in an Amazon S3 bucket. You create a manifest file that describes the location of each object. For more information, see Using Input and Output Data (https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html). The output can be used as the manifest file for another labeling job or as training data for your machine learning models. You can use this operation to create a static labeling job or a streaming labeling job. A static labeling job stops if all data objects in the input manifest file identified in ManifestS3Uri have been labeled. A streaming labeling job runs perpetually until it is manually stopped, or remains idle for 10 days. You can send new data objects to an active (InProgress) streaming labeling job in real time. To learn how to create a static labeling job, see Create a Labeling Job (API) (https://docs.aws.amazon.com/sagemaker/latest/dg/sms-create-labeling-job-api.html) in the Amazon SageMaker Developer Guide. To learn how to create a streaming labeling job, see Create a Streaming Labeling Job (https://docs.aws.amazon.com/sagemaker/latest/dg/sms-streaming-create-job.html).
#
# POST /#X-Amz-Target=SageMaker.CreateLabelingJob
# operationId: CreateLabelingJob
export def "x-amz-target-sage-maker-create-labeling-job create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-32
  labeling_job_name: any
  label_attribute_name: any
  input_config: any
  output_config: any
  role_arn: any
  --label-category-config-s3-uri: any
  --stopping-conditions: any
  --labeling-job-algorithms-config: any
  human_task_config: any
  --tags: any
]: any -> record<LabelingJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateLabelingJob")
  let req_body = {"LabelingJobName": $labeling_job_name, "LabelAttributeName": $label_attribute_name, "InputConfig": $input_config, "OutputConfig": $output_config, "RoleArn": $role_arn, "LabelCategoryConfigS3Uri": $label_category_config_s3_uri, "StoppingConditions": $stopping_conditions, "LabelingJobAlgorithmsConfig": $labeling_job_algorithms_config, "HumanTaskConfig": $human_task_config, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a model in SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the Docker image that contains inference code, artifacts (from prior training), and a custom environment map that the inference code uses when you deploy the model for predictions. Use this API to create a model if you want to use SageMaker hosting services or run a batch transform job. To host your model, you create an endpoint configuration with the CreateEndpointConfig API, and then create an endpoint with the CreateEndpoint API. SageMaker then deploys all of the containers that you defined for the model in the hosting environment. For an example that calls this method when deploying a model to SageMaker hosting services, see Create a Model (Amazon Web Services SDK for Python (Boto 3)). (https://docs.aws.amazon.com/sagemaker/latest/dg/realtime-endpoints-deployment.html#realtime-endpoints-deployment-create-model) To run a batch transform using your model, you start a job with the CreateTransformJob API. SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location. In the request, you also provide an IAM role that SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other Amazon Web Services resources, you grant necessary permissions via this role.
#
# POST /#X-Amz-Target=SageMaker.CreateModel
# operationId: CreateModel
export def "x-amz-target-sage-maker-create-model create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-33
  model_name: any
  --primary-container: any
  --containers: any
  --inference-execution-config: any
  execution_role_arn: any
  --tags: any
  --vpc-config: any
  --enable-network-isolation: any
]: any -> record<ModelArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModel")
  let req_body = {"ModelName": $model_name, "PrimaryContainer": $primary_container, "Containers": $containers, "InferenceExecutionConfig": $inference_execution_config, "ExecutionRoleArn": $execution_role_arn, "Tags": $tags, "VpcConfig": $vpc_config, "EnableNetworkIsolation": $enable_network_isolation} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates the definition for a model bias job.
#
# POST /#X-Amz-Target=SageMaker.CreateModelBiasJobDefinition
# operationId: CreateModelBiasJobDefinition
# --ModelBiasJobOutputConfig shape: {MonitoringOutputs: any, KmsKeyId?: any}
# --JobResources shape: {ClusterConfig: any}
# --StoppingCondition shape: {MaxRuntimeInSeconds: any}
export def "x-amz-target-sage-maker-create-model-bias-job-definition create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-34
  job_definition_name: any
  --model-bias-baseline-config: any
  model_bias_app_specification: any
  model_bias_job_input: any
  model_bias_job_output_config: record # The output configuration for monitoring jobs. — shape: {MonitoringOutputs: any, KmsKeyId?: any}
  job_resources: record # Identifies the resources to deploy for a monitoring job. — shape: {ClusterConfig: any}
  --network-config: any
  role_arn: any
  --stopping-condition: record # A time limit for how long the monitoring job is allowed to run before stopping. — shape: {MaxRuntimeInSeconds: any}
  --tags: any
]: any -> record<JobDefinitionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModelBiasJobDefinition")
  let req_body = {"JobDefinitionName": $job_definition_name, "ModelBiasBaselineConfig": $model_bias_baseline_config, "ModelBiasAppSpecification": $model_bias_app_specification, "ModelBiasJobInput": $model_bias_job_input, "ModelBiasJobOutputConfig": $model_bias_job_output_config, "JobResources": $job_resources, "NetworkConfig": $network_config, "RoleArn": $role_arn, "StoppingCondition": $stopping_condition, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an Amazon SageMaker Model Card. For information about how to use model cards, see Amazon SageMaker Model Card (https://docs.aws.amazon.com/sagemaker/latest/dg/model-cards.html).
#
# POST /#X-Amz-Target=SageMaker.CreateModelCard
# operationId: CreateModelCard
export def "x-amz-target-sage-maker-create-model-card create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-35
  model_card_name: any
  --security-config: any
  content: any
  model_card_status: any
  --tags: any
]: any -> record<ModelCardArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModelCard")
  let req_body = {"ModelCardName": $model_card_name, "SecurityConfig": $security_config, "Content": $content, "ModelCardStatus": $model_card_status, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an Amazon SageMaker Model Card export job.
#
# POST /#X-Amz-Target=SageMaker.CreateModelCardExportJob
# operationId: CreateModelCardExportJob
export def "x-amz-target-sage-maker-create-model-card-export-job create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-36
  model_card_name: any
  --model-card-version: any
  model_card_export_job_name: any
  output_config: any
]: any -> record<ModelCardExportJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModelCardExportJob")
  let req_body = {"ModelCardName": $model_card_name, "ModelCardVersion": $model_card_version, "ModelCardExportJobName": $model_card_export_job_name, "OutputConfig": $output_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates the definition for a model explainability job.
#
# POST /#X-Amz-Target=SageMaker.CreateModelExplainabilityJobDefinition
# operationId: CreateModelExplainabilityJobDefinition
# --ModelExplainabilityJobOutputConfig shape: {MonitoringOutputs: any, KmsKeyId?: any}
# --JobResources shape: {ClusterConfig: any}
# --StoppingCondition shape: {MaxRuntimeInSeconds: any}
export def "x-amz-target-sage-maker-create-model-explainability-job-definition create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-37
  job_definition_name: any
  --model-explainability-baseline-config: any
  model_explainability_app_specification: any
  model_explainability_job_input: any
  model_explainability_job_output_config: record # The output configuration for monitoring jobs. — shape: {MonitoringOutputs: any, KmsKeyId?: any}
  job_resources: record # Identifies the resources to deploy for a monitoring job. — shape: {ClusterConfig: any}
  --network-config: any
  role_arn: any
  --stopping-condition: record # A time limit for how long the monitoring job is allowed to run before stopping. — shape: {MaxRuntimeInSeconds: any}
  --tags: any
]: any -> record<JobDefinitionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModelExplainabilityJobDefinition")
  let req_body = {"JobDefinitionName": $job_definition_name, "ModelExplainabilityBaselineConfig": $model_explainability_baseline_config, "ModelExplainabilityAppSpecification": $model_explainability_app_specification, "ModelExplainabilityJobInput": $model_explainability_job_input, "ModelExplainabilityJobOutputConfig": $model_explainability_job_output_config, "JobResources": $job_resources, "NetworkConfig": $network_config, "RoleArn": $role_arn, "StoppingCondition": $stopping_condition, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a model package that you can use to create SageMaker models or list on Amazon Web Services Marketplace, or a versioned model that is part of a model group. Buyers can subscribe to model packages listed on Amazon Web Services Marketplace to create models in SageMaker. To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for InferenceSpecification. To create a model from an algorithm resource that you created or subscribed to in Amazon Web Services Marketplace, provide a value for SourceAlgorithmSpecification. There are two types of model packages: Versioned - a model that is part of a model group in the model registry. Unversioned - a model package that is not part of a model group.
#
# POST /#X-Amz-Target=SageMaker.CreateModelPackage
# operationId: CreateModelPackage
# --MetadataProperties shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
export def "x-amz-target-sage-maker-create-model-package create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-38
  --model-package-name: any
  --model-package-group-name: any
  --model-package-description: any
  --inference-specification: any
  --validation-specification: any
  --source-algorithm-specification: any
  --certify-for-marketplace: any
  --tags: any
  --model-approval-status: any
  --metadata-properties: record # Metadata properties of the tracking entity, trial, or trial component. — shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
  --model-metrics: any
  --client-token: any
  --customer-metadata-properties: any
  --drift-check-baselines: any
  --domain: any
  --task: any
  --sample-payload-url: any
  --additional-inference-specifications: any
]: any -> record<ModelPackageArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModelPackage")
  let req_body = {"ModelPackageName": $model_package_name, "ModelPackageGroupName": $model_package_group_name, "ModelPackageDescription": $model_package_description, "InferenceSpecification": $inference_specification, "ValidationSpecification": $validation_specification, "SourceAlgorithmSpecification": $source_algorithm_specification, "CertifyForMarketplace": $certify_for_marketplace, "Tags": $tags, "ModelApprovalStatus": $model_approval_status, "MetadataProperties": $metadata_properties, "ModelMetrics": $model_metrics, "ClientToken": $client_token, "CustomerMetadataProperties": $customer_metadata_properties, "DriftCheckBaselines": $drift_check_baselines, "Domain": $domain, "Task": $task, "SamplePayloadUrl": $sample_payload_url, "AdditionalInferenceSpecifications": $additional_inference_specifications} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a model group. A model group contains a group of model versions.
#
# POST /#X-Amz-Target=SageMaker.CreateModelPackageGroup
# operationId: CreateModelPackageGroup
export def "x-amz-target-sage-maker-create-model-package-group create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-39
  model_package_group_name: any
  --model-package-group-description: any
  --tags: any
]: any -> record<ModelPackageGroupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModelPackageGroup")
  let req_body = {"ModelPackageGroupName": $model_package_group_name, "ModelPackageGroupDescription": $model_package_group_description, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a definition for a job that monitors model quality and drift. For information about model monitor, see Amazon SageMaker Model Monitor (https://docs.aws.amazon.com/sagemaker/latest/dg/model-monitor.html).
#
# POST /#X-Amz-Target=SageMaker.CreateModelQualityJobDefinition
# operationId: CreateModelQualityJobDefinition
# --ModelQualityJobOutputConfig shape: {MonitoringOutputs: any, KmsKeyId?: any}
# --JobResources shape: {ClusterConfig: any}
# --StoppingCondition shape: {MaxRuntimeInSeconds: any}
export def "x-amz-target-sage-maker-create-model-quality-job-definition create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-40
  job_definition_name: any
  --model-quality-baseline-config: any
  model_quality_app_specification: any
  model_quality_job_input: any
  model_quality_job_output_config: record # The output configuration for monitoring jobs. — shape: {MonitoringOutputs: any, KmsKeyId?: any}
  job_resources: record # Identifies the resources to deploy for a monitoring job. — shape: {ClusterConfig: any}
  --network-config: any
  role_arn: any
  --stopping-condition: record # A time limit for how long the monitoring job is allowed to run before stopping. — shape: {MaxRuntimeInSeconds: any}
  --tags: any
]: any -> record<JobDefinitionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModelQualityJobDefinition")
  let req_body = {"JobDefinitionName": $job_definition_name, "ModelQualityBaselineConfig": $model_quality_baseline_config, "ModelQualityAppSpecification": $model_quality_app_specification, "ModelQualityJobInput": $model_quality_job_input, "ModelQualityJobOutputConfig": $model_quality_job_output_config, "JobResources": $job_resources, "NetworkConfig": $network_config, "RoleArn": $role_arn, "StoppingCondition": $stopping_condition, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endpoint.
#
# POST /#X-Amz-Target=SageMaker.CreateMonitoringSchedule
# operationId: CreateMonitoringSchedule
export def "x-amz-target-sage-maker-create-monitoring-schedule create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-41
  monitoring_schedule_name: any
  monitoring_schedule_config: any
  --tags: any
]: any -> record<MonitoringScheduleArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateMonitoringSchedule")
  let req_body = {"MonitoringScheduleName": $monitoring_schedule_name, "MonitoringScheduleConfig": $monitoring_schedule_config, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. In a CreateNotebookInstance request, specify the type of ML compute instance that you want to run. SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use SageMaker with a specific algorithm or with a machine learning framework. After receiving the request, SageMaker does the following: Creates a network interface in the SageMaker VPC. (Option) If you specified SubnetId, SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC. Launches an EC2 instance of the type specified in the request in the SageMaker VPC. If you specified SubnetId of your VPC, SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it. After creating the notebook instance, SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it. After SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating SageMaker endpoints, and validate hosted models. For more information, see How It Works (https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html).
#
# POST /#X-Amz-Target=SageMaker.CreateNotebookInstance
# operationId: CreateNotebookInstance
export def "x-amz-target-sage-maker-create-notebook-instance create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-42
  notebook_instance_name: any
  instance_type: any
  --subnet-id: any
  --security-group-ids: any
  role_arn: any
  --kms-key-id: any
  --tags: any
  --lifecycle-config-name: any
  --direct-internet-access: any
  --volume-size-in-gb: any
  --accelerator-types: any
  --default-code-repository: any
  --additional-code-repositories: any
  --root-access: any
  --platform-identifier: any
  --instance-metadata-service-configuration: any
]: any -> record<NotebookInstanceArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateNotebookInstance")
  let req_body = {"NotebookInstanceName": $notebook_instance_name, "InstanceType": $instance_type, "SubnetId": $subnet_id, "SecurityGroupIds": $security_group_ids, "RoleArn": $role_arn, "KmsKeyId": $kms_key_id, "Tags": $tags, "LifecycleConfigName": $lifecycle_config_name, "DirectInternetAccess": $direct_internet_access, "VolumeSizeInGB": $volume_size_in_gb, "AcceleratorTypes": $accelerator_types, "DefaultCodeRepository": $default_code_repository, "AdditionalCodeRepositories": $additional_code_repositories, "RootAccess": $root_access, "PlatformIdentifier": $platform_identifier, "InstanceMetadataServiceConfiguration": $instance_metadata_service_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a lifecycle configuration that you can associate with a notebook instance. A lifecycle configuration is a collection of shell scripts that run when you create or start a notebook instance. Each lifecycle configuration script has a limit of 16384 characters. The value of the $PATH environment variable that is available to both scripts is /sbin:bin:/usr/sbin:/usr/bin. View CloudWatch Logs for notebook instance lifecycle configurations in log group /aws/sagemaker/NotebookInstances in log stream [notebook-instance-name]/[LifecycleConfigHook]. Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started. For information about notebook instance lifestyle configurations, see Step 2.1: (Optional) Customize a Notebook Instance (https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html).
#
# POST /#X-Amz-Target=SageMaker.CreateNotebookInstanceLifecycleConfig
# operationId: CreateNotebookInstanceLifecycleConfig
export def "x-amz-target-sage-maker-create-notebook-instance-lifecycle-config create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-43
  notebook_instance_lifecycle_config_name: any
  --on-create: any
  --on-start: any
]: any -> record<NotebookInstanceLifecycleConfigArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateNotebookInstanceLifecycleConfig")
  let req_body = {"NotebookInstanceLifecycleConfigName": $notebook_instance_lifecycle_config_name, "OnCreate": $on_create, "OnStart": $on_start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a pipeline using a JSON pipeline definition.
#
# POST /#X-Amz-Target=SageMaker.CreatePipeline
# operationId: CreatePipeline
export def "x-amz-target-sage-maker-create-pipeline create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-44
  pipeline_name: any
  --pipeline-display-name: any
  --pipeline-definition: any
  --pipeline-definition-s3-location: any
  --pipeline-description: any
  client_request_token: any
  role_arn: any
  --tags: any
  --parallelism-configuration: any
]: any -> record<PipelineArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreatePipeline")
  let req_body = {"PipelineName": $pipeline_name, "PipelineDisplayName": $pipeline_display_name, "PipelineDefinition": $pipeline_definition, "PipelineDefinitionS3Location": $pipeline_definition_s3_location, "PipelineDescription": $pipeline_description, "ClientRequestToken": $client_request_token, "RoleArn": $role_arn, "Tags": $tags, "ParallelismConfiguration": $parallelism_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Studio, and granted access to all of the Apps and files associated with the Domain's Amazon Elastic File System (EFS) volume. This operation can only be called when the authentication mode equals IAM. The IAM role or user passed to this API defines the permissions to access the app. Once the presigned URL is created, no additional permission is required to access this URL. IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the app. You can restrict access to this API and to the URL that it returns to a list of IP addresses, Amazon VPCs or Amazon VPC Endpoints that you specify. For more information, see Connect to SageMaker Studio Through an Interface VPC Endpoint (https://docs.aws.amazon.com/sagemaker/latest/dg/studio-interface-endpoint.html) . The URL that you get from a call to CreatePresignedDomainUrl has a default timeout of 5 minutes. You can configure this value using ExpiresInSeconds. If you try to use the URL after the timeout limit expires, you are directed to the Amazon Web Services console sign-in page.
#
# POST /#X-Amz-Target=SageMaker.CreatePresignedDomainUrl
# operationId: CreatePresignedDomainUrl
export def "x-amz-target-sage-maker-create-presigned-domain-url create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-45
  domain_id: any
  user_profile_name: any
  --session-expiration-duration-in-seconds: any
  --expires-in-seconds: any
  --space-name: any
]: any -> record<AuthorizedUrl: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreatePresignedDomainUrl")
  let req_body = {"DomainId": $domain_id, "UserProfileName": $user_profile_name, "SessionExpirationDurationInSeconds": $session_expiration_duration_in_seconds, "ExpiresInSeconds": $expires_in_seconds, "SpaceName": $space_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the SageMaker console, when you choose Open next to a notebook instance, SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page. The IAM role or user used to call this API defines the permissions to access the notebook instance. Once the presigned URL is created, no additional permission is required to access this URL. IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance. You can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the NotIpAddress condition operator and the aws:SourceIP condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see Limit Access to a Notebook Instance by IP Address (https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter). The URL that you get from a call to CreatePresignedNotebookInstanceUrl (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreatePresignedNotebookInstanceUrl.html) is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the Amazon Web Services console sign-in page.
#
# POST /#X-Amz-Target=SageMaker.CreatePresignedNotebookInstanceUrl
# operationId: CreatePresignedNotebookInstanceUrl
export def "x-amz-target-sage-maker-create-presigned-notebook-instance-url create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46
  notebook_instance_name: any
  --session-expiration-duration-in-seconds: any
]: any -> record<AuthorizedUrl: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreatePresignedNotebookInstanceUrl")
  let req_body = {"NotebookInstanceName": $notebook_instance_name, "SessionExpirationDurationInSeconds": $session_expiration_duration_in_seconds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a processing job.
#
# POST /#X-Amz-Target=SageMaker.CreateProcessingJob
# operationId: CreateProcessingJob
# --ExperimentConfig shape: {ExperimentName?: any, TrialName?: any, TrialComponentDisplayName?: any, RunName?: any}
export def "x-amz-target-sage-maker-create-processing-job create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-47
  --processing-inputs: any
  --processing-output-config: any
  processing_job_name: any
  processing_resources: any
  --stopping-condition: any
  app_specification: any
  --environment: any
  --network-config: any
  role_arn: any
  --tags: any
  --experiment-config: record # Associates a SageMaker job as a trial component with an experiment and trial. Specified when you call the following APIs: CreateProcessingJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateProcessingJob.html) CreateTrainingJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTrainingJob.html) CreateTransformJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTransformJob.html) — shape: {ExperimentName?: any, TrialName?: any, TrialComponentDisplayName?: any, RunName?: any}
]: any -> record<ProcessingJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateProcessingJob")
  let req_body = {"ProcessingInputs": $processing_inputs, "ProcessingOutputConfig": $processing_output_config, "ProcessingJobName": $processing_job_name, "ProcessingResources": $processing_resources, "StoppingCondition": $stopping_condition, "AppSpecification": $app_specification, "Environment": $environment, "NetworkConfig": $network_config, "RoleArn": $role_arn, "Tags": $tags, "ExperimentConfig": $experiment_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a machine learning (ML) project that can contain one or more templates that set up an ML pipeline from training to deploying an approved model.
#
# POST /#X-Amz-Target=SageMaker.CreateProject
# operationId: CreateProject
export def "x-amz-target-sage-maker-create-project create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-48
  project_name: any
  --project-description: any
  service_catalog_provisioning_details: any
  --tags: any
]: any -> record<ProjectArn: record, ProjectId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateProject")
  let req_body = {"ProjectName": $project_name, "ProjectDescription": $project_description, "ServiceCatalogProvisioningDetails": $service_catalog_provisioning_details, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a space used for real time collaboration in a Domain.
#
# POST /#X-Amz-Target=SageMaker.CreateSpace
# operationId: CreateSpace
export def "x-amz-target-sage-maker-create-space create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-49
  domain_id: any
  space_name: any
  --tags: any
  --space-settings: any
]: any -> record<SpaceArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateSpace")
  let req_body = {"DomainId": $domain_id, "SpaceName": $space_name, "Tags": $tags, "SpaceSettings": $space_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new Studio Lifecycle Configuration.
#
# POST /#X-Amz-Target=SageMaker.CreateStudioLifecycleConfig
# operationId: CreateStudioLifecycleConfig
export def "x-amz-target-sage-maker-create-studio-lifecycle-config create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-50
  studio_lifecycle_config_name: any
  studio_lifecycle_config_content: any
  studio_lifecycle_config_app_type: any
  --tags: any
]: any -> record<StudioLifecycleConfigArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateStudioLifecycleConfig")
  let req_body = {"StudioLifecycleConfigName": $studio_lifecycle_config_name, "StudioLifecycleConfigContent": $studio_lifecycle_config_content, "StudioLifecycleConfigAppType": $studio_lifecycle_config_app_type, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts a model training job. After training completes, SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. If you choose to host your model using SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than SageMaker, provided that you know how to use them for inference. In the request body, you provide the following: AlgorithmSpecification - Identifies the training algorithm to use. HyperParameters - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by SageMaker, see Algorithms (https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html). Do not include any security-sensitive information including account access IDs, secrets or tokens in any hyperparameter field. If the use of security-sensitive credentials are detected, SageMaker will reject your training job request and return an exception error. InputDataConfig - Describes the input required by the training job and the Amazon S3, EFS, or FSx location where it is stored. OutputDataConfig - Identifies the Amazon S3 bucket where you want SageMaker to save the results of model training. ResourceConfig - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. EnableManagedSpotTraining - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see Managed Spot Training (https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html). RoleArn - The Amazon Resource Name (ARN) that SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that SageMaker can successfully complete model training. StoppingCondition - To help cap training costs, use MaxRuntimeInSeconds to set a time limit for training. Use MaxWaitTimeInSeconds to specify how long a managed spot training job has to complete. Environment - The environment variables to set in the Docker container. RetryStrategy - The number of times to retry the job when the job fails due to an InternalServerError. For more information about SageMaker, see How It Works (https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html).
#
# POST /#X-Amz-Target=SageMaker.CreateTrainingJob
# operationId: CreateTrainingJob
# --DebugHookConfig shape: {LocalPath?: any, S3OutputPath: any, HookParameters?: any, CollectionConfigurations?: any}
# --TensorBoardOutputConfig shape: {LocalPath?: any, S3OutputPath: any}
# --ExperimentConfig shape: {ExperimentName?: any, TrialName?: any, TrialComponentDisplayName?: any, RunName?: any}
# --ProfilerConfig shape: {S3OutputPath?: any, ProfilingIntervalInMilliseconds?: any, ProfilingParameters?: any, DisableProfiler?: any}
export def "x-amz-target-sage-maker-create-training-job create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-51
  training_job_name: any
  --hyper-parameters: any
  algorithm_specification: any
  role_arn: any
  --input-data-config: any
  output_data_config: any
  resource_config: any
  --vpc-config: any
  stopping_condition: any
  --tags: any
  --enable-network-isolation: any
  --enable-inter-container-traffic-encryption: any
  --enable-managed-spot-training: any
  --checkpoint-config: any
  --debug-hook-config: record # Configuration information for the Amazon SageMaker Debugger hook parameters, metric and tensor collections, and storage paths. To learn more about how to configure the DebugHookConfig parameter, see Use the SageMaker and Debugger Configuration API Operations to Create, Update, and Debug Your Training Job (https://docs.aws.amazon.com/sagemaker/latest/dg/debugger-createtrainingjob-api.html). — shape: {LocalPath?: any, S3OutputPath: any, HookParameters?: any, CollectionConfigurations?: any}
  --debug-rule-configurations: any
  --tensor-board-output-config: record # Configuration of storage locations for the Amazon SageMaker Debugger TensorBoard output data. — shape: {LocalPath?: any, S3OutputPath: any}
  --experiment-config: record # Associates a SageMaker job as a trial component with an experiment and trial. Specified when you call the following APIs: CreateProcessingJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateProcessingJob.html) CreateTrainingJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTrainingJob.html) CreateTransformJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTransformJob.html) — shape: {ExperimentName?: any, TrialName?: any, TrialComponentDisplayName?: any, RunName?: any}
  --profiler-config: record # Configuration information for Amazon SageMaker Debugger system monitoring, framework profiling, and storage paths. — shape: {S3OutputPath?: any, ProfilingIntervalInMilliseconds?: any, ProfilingParameters?: any, DisableProfiler?: any}
  --profiler-rule-configurations: any
  --environment: any
  --retry-strategy: any
]: any -> record<TrainingJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateTrainingJob")
  let req_body = {"TrainingJobName": $training_job_name, "HyperParameters": $hyper_parameters, "AlgorithmSpecification": $algorithm_specification, "RoleArn": $role_arn, "InputDataConfig": $input_data_config, "OutputDataConfig": $output_data_config, "ResourceConfig": $resource_config, "VpcConfig": $vpc_config, "StoppingCondition": $stopping_condition, "Tags": $tags, "EnableNetworkIsolation": $enable_network_isolation, "EnableInterContainerTrafficEncryption": $enable_inter_container_traffic_encryption, "EnableManagedSpotTraining": $enable_managed_spot_training, "CheckpointConfig": $checkpoint_config, "DebugHookConfig": $debug_hook_config, "DebugRuleConfigurations": $debug_rule_configurations, "TensorBoardOutputConfig": $tensor_board_output_config, "ExperimentConfig": $experiment_config, "ProfilerConfig": $profiler_config, "ProfilerRuleConfigurations": $profiler_rule_configurations, "Environment": $environment, "RetryStrategy": $retry_strategy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify. To perform batch transformations, you create a transform job and use the data that you have readily available. In the request body, you provide the following: TransformJobName - Identifies the transform job. The name must be unique within an Amazon Web Services Region in an Amazon Web Services account. ModelName - Identifies the model to use. ModelName must be the name of an existing Amazon SageMaker model in the same Amazon Web Services Region and Amazon Web Services account. For information on creating a model, see CreateModel (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateModel.html). TransformInput - Describes the dataset to be transformed and the Amazon S3 location where it is stored. TransformOutput - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job. TransformResources - Identifies the ML compute instances for the transform job. For more information about how batch transformation works, see Batch Transform (https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html).
#
# POST /#X-Amz-Target=SageMaker.CreateTransformJob
# operationId: CreateTransformJob
# --ExperimentConfig shape: {ExperimentName?: any, TrialName?: any, TrialComponentDisplayName?: any, RunName?: any}
export def "x-amz-target-sage-maker-create-transform-job create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-52
  transform_job_name: any
  model_name: any
  --max-concurrent-transforms: any
  --model-client-config: any
  --max-payload-in-mb: any
  --batch-strategy: any
  --environment: any
  transform_input: any
  transform_output: any
  --data-capture-config: any
  transform_resources: any
  --data-processing: any
  --tags: any
  --experiment-config: record # Associates a SageMaker job as a trial component with an experiment and trial. Specified when you call the following APIs: CreateProcessingJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateProcessingJob.html) CreateTrainingJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTrainingJob.html) CreateTransformJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTransformJob.html) — shape: {ExperimentName?: any, TrialName?: any, TrialComponentDisplayName?: any, RunName?: any}
]: any -> record<TransformJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateTransformJob")
  let req_body = {"TransformJobName": $transform_job_name, "ModelName": $model_name, "MaxConcurrentTransforms": $max_concurrent_transforms, "ModelClientConfig": $model_client_config, "MaxPayloadInMB": $max_payload_in_mb, "BatchStrategy": $batch_strategy, "Environment": $environment, "TransformInput": $transform_input, "TransformOutput": $transform_output, "DataCaptureConfig": $data_capture_config, "TransformResources": $transform_resources, "DataProcessing": $data_processing, "Tags": $tags, "ExperimentConfig": $experiment_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an SageMaker trial. A trial is a set of steps called trial components that produce a machine learning model. A trial is part of a single SageMaker experiment. When you use SageMaker Studio or the SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the Amazon Web Services SDK for Python (Boto), you must use the logging APIs provided by the SDK. You can add tags to a trial and then use the Search (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_Search.html) API to search for the tags. To get a list of all your trials, call the ListTrials (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_ListTrials.html) API. To view a trial's properties, call the DescribeTrial (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeTrial.html) API. To create a trial component, call the CreateTrialComponent (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTrialComponent.html) API.
#
# POST /#X-Amz-Target=SageMaker.CreateTrial
# operationId: CreateTrial
# --MetadataProperties shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
export def "x-amz-target-sage-maker-create-trial create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-53
  trial_name: any
  --display-name: any
  experiment_name: any
  --metadata-properties: record # Metadata properties of the tracking entity, trial, or trial component. — shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
  --tags: any
]: any -> record<TrialArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateTrial")
  let req_body = {"TrialName": $trial_name, "DisplayName": $display_name, "ExperimentName": $experiment_name, "MetadataProperties": $metadata_properties, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a trial component, which is a stage of a machine learning trial. A trial is composed of one or more trial components. A trial component can be used in multiple trials. Trial components include pre-processing jobs, training jobs, and batch transform jobs. When you use SageMaker Studio or the SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the Amazon Web Services SDK for Python (Boto), you must use the logging APIs provided by the SDK. You can add tags to a trial component and then use the Search (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_Search.html) API to search for the tags.
#
# POST /#X-Amz-Target=SageMaker.CreateTrialComponent
# operationId: CreateTrialComponent
# --MetadataProperties shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
export def "x-amz-target-sage-maker-create-trial-component create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-54
  trial_component_name: any
  --display-name: any
  --status: any
  --start-time: any
  --end-time: any
  --parameters: any
  --input-artifacts: any
  --output-artifacts: any
  --metadata-properties: record # Metadata properties of the tracking entity, trial, or trial component. — shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
  --tags: any
]: any -> record<TrialComponentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateTrialComponent")
  let req_body = {"TrialComponentName": $trial_component_name, "DisplayName": $display_name, "Status": $status, "StartTime": $start_time, "EndTime": $end_time, "Parameters": $parameters, "InputArtifacts": $input_artifacts, "OutputArtifacts": $output_artifacts, "MetadataProperties": $metadata_properties, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a user profile. A user profile represents a single user within a domain, and is the main way to reference a "person" for the purposes of sharing, reporting, and other user-oriented features. This entity is created when a user onboards to Amazon SageMaker Studio. If an administrator invites a person by email or imports them from IAM Identity Center, a user profile is automatically created. A user profile is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory.
#
# POST /#X-Amz-Target=SageMaker.CreateUserProfile
# operationId: CreateUserProfile
export def "x-amz-target-sage-maker-create-user-profile create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-55
  domain_id: any
  user_profile_name: any
  --single-sign-on-user-identifier: any
  --single-sign-on-user-value: any
  --tags: any
  --user-settings: any
]: any -> record<UserProfileArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateUserProfile")
  let req_body = {"DomainId": $domain_id, "UserProfileName": $user_profile_name, "SingleSignOnUserIdentifier": $single_sign_on_user_identifier, "SingleSignOnUserValue": $single_sign_on_user_value, "Tags": $tags, "UserSettings": $user_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this operation to create a workforce. This operation will return an error if a workforce already exists in the Amazon Web Services Region that you specify. You can only create one workforce in each Amazon Web Services Region per Amazon Web Services account. If you want to create a new workforce in an Amazon Web Services Region where a workforce already exists, use the DeleteWorkforce (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DeleteWorkforce.html) API operation to delete the existing workforce and then use CreateWorkforce to create a new workforce. To create a private workforce using Amazon Cognito, you must specify a Cognito user pool in CognitoConfig. You can also create an Amazon Cognito workforce using the Amazon SageMaker console. For more information, see Create a Private Workforce (Amazon Cognito) (https://docs.aws.amazon.com/sagemaker/latest/dg/sms-workforce-create-private.html). To create a private workforce using your own OIDC Identity Provider (IdP), specify your IdP configuration in OidcConfig. Your OIDC IdP must support groups because groups are used by Ground Truth and Amazon A2I to create work teams. For more information, see Create a Private Workforce (OIDC IdP) (https://docs.aws.amazon.com/sagemaker/latest/dg/sms-workforce-create-private-oidc.html).
#
# POST /#X-Amz-Target=SageMaker.CreateWorkforce
# operationId: CreateWorkforce
# --SourceIpConfig shape: {Cidrs: any}
export def "x-amz-target-sage-maker-create-workforce create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-56
  --cognito-config: any
  --oidc-config: any
  --source-ip-config: record # A list of IP address ranges (CIDRs (https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html)). Used to create an allow list of IP addresses for a private workforce. Workers will only be able to login to their worker portal from an IP address within this range. By default, a workforce isn't restricted to specific IP addresses. — shape: {Cidrs: any}
  workforce_name: any
  --tags: any
  --workforce-vpc-config: any
]: any -> record<WorkforceArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateWorkforce")
  let req_body = {"CognitoConfig": $cognito_config, "OidcConfig": $oidc_config, "SourceIpConfig": $source_ip_config, "WorkforceName": $workforce_name, "Tags": $tags, "WorkforceVpcConfig": $workforce_vpc_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team. You cannot create more than 25 work teams in an account and region.
#
# POST /#X-Amz-Target=SageMaker.CreateWorkteam
# operationId: CreateWorkteam
export def "x-amz-target-sage-maker-create-workteam create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-57
  workteam_name: any
  --workforce-name: any
  member_definitions: any
  description: any
  --notification-configuration: any
  --tags: any
]: any -> record<WorkteamArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateWorkteam")
  let req_body = {"WorkteamName": $workteam_name, "WorkforceName": $workforce_name, "MemberDefinitions": $member_definitions, "Description": $description, "NotificationConfiguration": $notification_configuration, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an action.
#
# POST /#X-Amz-Target=SageMaker.DeleteAction
# operationId: DeleteAction
export def "x-amz-target-sage-maker-delete-action delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-58
  action_name: any
]: any -> record<ActionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteAction")
  let req_body = {"ActionName": $action_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the specified algorithm from your account.
#
# POST /#X-Amz-Target=SageMaker.DeleteAlgorithm
# operationId: DeleteAlgorithm
export def "x-amz-target-sage-maker-delete-algorithm delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-59
  algorithm_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteAlgorithm")
  let req_body = {"AlgorithmName": $algorithm_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Used to stop and delete an app.
#
# POST /#X-Amz-Target=SageMaker.DeleteApp
# operationId: DeleteApp
export def "x-amz-target-sage-maker-delete-app delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-60
  domain_id: any
  --user-profile-name: any
  app_type: any
  app_name: any
  --space-name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteApp")
  let req_body = {"DomainId": $domain_id, "UserProfileName": $user_profile_name, "AppType": $app_type, "AppName": $app_name, "SpaceName": $space_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an AppImageConfig.
#
# POST /#X-Amz-Target=SageMaker.DeleteAppImageConfig
# operationId: DeleteAppImageConfig
export def "x-amz-target-sage-maker-delete-app-image-config delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-61
  app_image_config_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteAppImageConfig")
  let req_body = {"AppImageConfigName": $app_image_config_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an artifact. Either ArtifactArn or Source must be specified.
#
# POST /#X-Amz-Target=SageMaker.DeleteArtifact
# operationId: DeleteArtifact
export def "x-amz-target-sage-maker-delete-artifact delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-62
  --artifact-arn: any
  --body-source: any
]: any -> record<ArtifactArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteArtifact")
  let req_body = {"ArtifactArn": $artifact_arn, "Source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an association.
#
# POST /#X-Amz-Target=SageMaker.DeleteAssociation
# operationId: DeleteAssociation
export def "x-amz-target-sage-maker-delete-association delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-63
  source_arn: any
  destination_arn: any
]: any -> record<SourceArn: record, DestinationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteAssociation")
  let req_body = {"SourceArn": $source_arn, "DestinationArn": $destination_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes the specified Git repository from your account.
#
# POST /#X-Amz-Target=SageMaker.DeleteCodeRepository
# operationId: DeleteCodeRepository
export def "x-amz-target-sage-maker-delete-code-repository delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-64
  code_repository_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteCodeRepository")
  let req_body = {"CodeRepositoryName": $code_repository_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an context.
#
# POST /#X-Amz-Target=SageMaker.DeleteContext
# operationId: DeleteContext
export def "x-amz-target-sage-maker-delete-context delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-65
  context_name: any
]: any -> record<ContextArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteContext")
  let req_body = {"ContextName": $context_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a data quality monitoring job definition.
#
# POST /#X-Amz-Target=SageMaker.DeleteDataQualityJobDefinition
# operationId: DeleteDataQualityJobDefinition
export def "x-amz-target-sage-maker-delete-data-quality-job-definition delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-66
  job_definition_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteDataQualityJobDefinition")
  let req_body = {"JobDefinitionName": $job_definition_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a fleet.
#
# POST /#X-Amz-Target=SageMaker.DeleteDeviceFleet
# operationId: DeleteDeviceFleet
export def "x-amz-target-sage-maker-delete-device-fleet delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-67
  device_fleet_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteDeviceFleet")
  let req_body = {"DeviceFleetName": $device_fleet_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Used to delete a domain. If you onboarded with IAM mode, you will need to delete your domain to onboard again using IAM Identity Center. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts.
#
# POST /#X-Amz-Target=SageMaker.DeleteDomain
# operationId: DeleteDomain
export def "x-amz-target-sage-maker-delete-domain delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-68
  domain_id: any
  --retention-policy: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteDomain")
  let req_body = {"DomainId": $domain_id, "RetentionPolicy": $retention_policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an edge deployment plan if (and only if) all the stages in the plan are inactive or there are no stages in the plan.
#
# POST /#X-Amz-Target=SageMaker.DeleteEdgeDeploymentPlan
# operationId: DeleteEdgeDeploymentPlan
export def "x-amz-target-sage-maker-delete-edge-deployment-plan delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-69
  edge_deployment_plan_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteEdgeDeploymentPlan")
  let req_body = {"EdgeDeploymentPlanName": $edge_deployment_plan_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a stage in an edge deployment plan if (and only if) the stage is inactive.
#
# POST /#X-Amz-Target=SageMaker.DeleteEdgeDeploymentStage
# operationId: DeleteEdgeDeploymentStage
export def "x-amz-target-sage-maker-delete-edge-deployment-stage delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-70
  edge_deployment_plan_name: any
  stage_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteEdgeDeploymentStage")
  let req_body = {"EdgeDeploymentPlanName": $edge_deployment_plan_name, "StageName": $stage_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an endpoint. SageMaker frees up all of the resources that were deployed when the endpoint was created. SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the RevokeGrant (http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html) API call. When you delete your endpoint, SageMaker asynchronously deletes associated endpoint resources such as KMS key grants. You might still see these resources in your account for a few minutes after deleting your endpoint. Do not delete or revoke the permissions for your ExecutionRoleArn (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateModel.html#sagemaker-CreateModel-request-ExecutionRoleArn) , otherwise SageMaker cannot delete these resources.
#
# POST /#X-Amz-Target=SageMaker.DeleteEndpoint
# operationId: DeleteEndpoint
export def "x-amz-target-sage-maker-delete-endpoint delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-71
  endpoint_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteEndpoint")
  let req_body = {"EndpointName": $endpoint_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an endpoint configuration. The DeleteEndpointConfig API deletes only the specified configuration. It does not delete endpoints created using the configuration. You must not delete an EndpointConfig in use by an endpoint that is live or while the UpdateEndpoint or CreateEndpoint operations are being performed on the endpoint. If you delete the EndpointConfig of an endpoint that is active or being created or updated you may lose visibility into the instance type the endpoint is using. The endpoint must be deleted in order to stop incurring charges.
#
# POST /#X-Amz-Target=SageMaker.DeleteEndpointConfig
# operationId: DeleteEndpointConfig
export def "x-amz-target-sage-maker-delete-endpoint-config delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-72
  endpoint_config_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteEndpointConfig")
  let req_body = {"EndpointConfigName": $endpoint_config_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an SageMaker experiment. All trials associated with the experiment must be deleted first. Use the ListTrials (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_ListTrials.html) API to get a list of the trials associated with the experiment.
#
# POST /#X-Amz-Target=SageMaker.DeleteExperiment
# operationId: DeleteExperiment
export def "x-amz-target-sage-maker-delete-experiment delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-73
  experiment_name: any
]: any -> record<ExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteExperiment")
  let req_body = {"ExperimentName": $experiment_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete the FeatureGroup and any data that was written to the OnlineStore of the FeatureGroup. Data cannot be accessed from the OnlineStore immediately after DeleteFeatureGroup is called. Data written into the OfflineStore will not be deleted. The Amazon Web Services Glue database and tables that are automatically created for your OfflineStore are not deleted.
#
# POST /#X-Amz-Target=SageMaker.DeleteFeatureGroup
# operationId: DeleteFeatureGroup
export def "x-amz-target-sage-maker-delete-feature-group delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-74
  feature_group_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteFeatureGroup")
  let req_body = {"FeatureGroupName": $feature_group_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes the specified flow definition.
#
# POST /#X-Amz-Target=SageMaker.DeleteFlowDefinition
# operationId: DeleteFlowDefinition
export def "x-amz-target-sage-maker-delete-flow-definition delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-75
  flow_definition_name: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteFlowDefinition")
  let req_body = {"FlowDefinitionName": $flow_definition_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a hub. Hub APIs are only callable through SageMaker Studio.
#
# POST /#X-Amz-Target=SageMaker.DeleteHub
# operationId: DeleteHub
export def "x-amz-target-sage-maker-delete-hub delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-76
  hub_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteHub")
  let req_body = {"HubName": $hub_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete the contents of a hub. Hub APIs are only callable through SageMaker Studio.
#
# POST /#X-Amz-Target=SageMaker.DeleteHubContent
# operationId: DeleteHubContent
export def "x-amz-target-sage-maker-delete-hub-content delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-77
  hub_name: any
  hub_content_type: any
  hub_content_name: any
  hub_content_version: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteHubContent")
  let req_body = {"HubName": $hub_name, "HubContentType": $hub_content_type, "HubContentName": $hub_content_name, "HubContentVersion": $hub_content_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this operation to delete a human task user interface (worker task template). To see a list of human task user interfaces (work task templates) in your account, use ListHumanTaskUis (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_ListHumanTaskUis.html). When you delete a worker task template, it no longer appears when you call ListHumanTaskUis.
#
# POST /#X-Amz-Target=SageMaker.DeleteHumanTaskUi
# operationId: DeleteHumanTaskUi
export def "x-amz-target-sage-maker-delete-human-task-ui delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-78
  human_task_ui_name: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteHumanTaskUi")
  let req_body = {"HumanTaskUiName": $human_task_ui_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a SageMaker image and all versions of the image. The container images aren't deleted.
#
# POST /#X-Amz-Target=SageMaker.DeleteImage
# operationId: DeleteImage
export def "x-amz-target-sage-maker-delete-image delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-79
  image_name: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteImage")
  let req_body = {"ImageName": $image_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a version of a SageMaker image. The container image the version represents isn't deleted.
#
# POST /#X-Amz-Target=SageMaker.DeleteImageVersion
# operationId: DeleteImageVersion
export def "x-amz-target-sage-maker-delete-image-version delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-80
  image_name: any
  --version: any
  --alias: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteImageVersion")
  let req_body = {"ImageName": $image_name, "Version": $version, "Alias": $alias} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an inference experiment. This operation does not delete your endpoint, variants, or any underlying resources. This operation only deletes the metadata of your experiment.
#
# POST /#X-Amz-Target=SageMaker.DeleteInferenceExperiment
# operationId: DeleteInferenceExperiment
export def "x-amz-target-sage-maker-delete-inference-experiment delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-81
  name: any
]: any -> record<InferenceExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteInferenceExperiment")
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a model. The DeleteModel API deletes only the model entry that was created in SageMaker when you called the CreateModel API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model.
#
# POST /#X-Amz-Target=SageMaker.DeleteModel
# operationId: DeleteModel
export def "x-amz-target-sage-maker-delete-model delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-82
  model_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModel")
  let req_body = {"ModelName": $model_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an Amazon SageMaker model bias job definition.
#
# POST /#X-Amz-Target=SageMaker.DeleteModelBiasJobDefinition
# operationId: DeleteModelBiasJobDefinition
export def "x-amz-target-sage-maker-delete-model-bias-job-definition delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-83
  job_definition_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModelBiasJobDefinition")
  let req_body = {"JobDefinitionName": $job_definition_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an Amazon SageMaker Model Card.
#
# POST /#X-Amz-Target=SageMaker.DeleteModelCard
# operationId: DeleteModelCard
export def "x-amz-target-sage-maker-delete-model-card delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-84
  model_card_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModelCard")
  let req_body = {"ModelCardName": $model_card_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an Amazon SageMaker model explainability job definition.
#
# POST /#X-Amz-Target=SageMaker.DeleteModelExplainabilityJobDefinition
# operationId: DeleteModelExplainabilityJobDefinition
export def "x-amz-target-sage-maker-delete-model-explainability-job-definition delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-85
  job_definition_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModelExplainabilityJobDefinition")
  let req_body = {"JobDefinitionName": $job_definition_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a model package. A model package is used to create SageMaker models or list on Amazon Web Services Marketplace. Buyers can subscribe to model packages listed on Amazon Web Services Marketplace to create models in SageMaker.
#
# POST /#X-Amz-Target=SageMaker.DeleteModelPackage
# operationId: DeleteModelPackage
export def "x-amz-target-sage-maker-delete-model-package delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-86
  model_package_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModelPackage")
  let req_body = {"ModelPackageName": $model_package_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes the specified model group.
#
# POST /#X-Amz-Target=SageMaker.DeleteModelPackageGroup
# operationId: DeleteModelPackageGroup
export def "x-amz-target-sage-maker-delete-model-package-group delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-87
  model_package_group_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModelPackageGroup")
  let req_body = {"ModelPackageGroupName": $model_package_group_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a model group resource policy.
#
# POST /#X-Amz-Target=SageMaker.DeleteModelPackageGroupPolicy
# operationId: DeleteModelPackageGroupPolicy
export def "x-amz-target-sage-maker-delete-model-package-group-policy delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-88
  model_package_group_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModelPackageGroupPolicy")
  let req_body = {"ModelPackageGroupName": $model_package_group_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes the secified model quality monitoring job definition.
#
# POST /#X-Amz-Target=SageMaker.DeleteModelQualityJobDefinition
# operationId: DeleteModelQualityJobDefinition
export def "x-amz-target-sage-maker-delete-model-quality-job-definition delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-89
  job_definition_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModelQualityJobDefinition")
  let req_body = {"JobDefinitionName": $job_definition_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule.
#
# POST /#X-Amz-Target=SageMaker.DeleteMonitoringSchedule
# operationId: DeleteMonitoringSchedule
export def "x-amz-target-sage-maker-delete-monitoring-schedule delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-90
  monitoring_schedule_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteMonitoringSchedule")
  let req_body = {"MonitoringScheduleName": $monitoring_schedule_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an SageMaker notebook instance. Before you can delete a notebook instance, you must call the StopNotebookInstance API. When you delete a notebook instance, you lose all of your data. SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance.
#
# POST /#X-Amz-Target=SageMaker.DeleteNotebookInstance
# operationId: DeleteNotebookInstance
export def "x-amz-target-sage-maker-delete-notebook-instance delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-91
  notebook_instance_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteNotebookInstance")
  let req_body = {"NotebookInstanceName": $notebook_instance_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a notebook instance lifecycle configuration.
#
# POST /#X-Amz-Target=SageMaker.DeleteNotebookInstanceLifecycleConfig
# operationId: DeleteNotebookInstanceLifecycleConfig
export def "x-amz-target-sage-maker-delete-notebook-instance-lifecycle-config delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-92
  notebook_instance_lifecycle_config_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteNotebookInstanceLifecycleConfig")
  let req_body = {"NotebookInstanceLifecycleConfigName": $notebook_instance_lifecycle_config_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a pipeline if there are no running instances of the pipeline. To delete a pipeline, you must stop all running instances of the pipeline using the StopPipelineExecution API. When you delete a pipeline, all instances of the pipeline are deleted.
#
# POST /#X-Amz-Target=SageMaker.DeletePipeline
# operationId: DeletePipeline
export def "x-amz-target-sage-maker-delete-pipeline delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-93
  pipeline_name: any
  client_request_token: any
]: any -> record<PipelineArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeletePipeline")
  let req_body = {"PipelineName": $pipeline_name, "ClientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete the specified project.
#
# POST /#X-Amz-Target=SageMaker.DeleteProject
# operationId: DeleteProject
export def "x-amz-target-sage-maker-delete-project delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-94
  project_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteProject")
  let req_body = {"ProjectName": $project_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Used to delete a space.
#
# POST /#X-Amz-Target=SageMaker.DeleteSpace
# operationId: DeleteSpace
export def "x-amz-target-sage-maker-delete-space delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-95
  domain_id: any
  space_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteSpace")
  let req_body = {"DomainId": $domain_id, "SpaceName": $space_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes the Studio Lifecycle Configuration. In order to delete the Lifecycle Configuration, there must be no running apps using the Lifecycle Configuration. You must also remove the Lifecycle Configuration from UserSettings in all Domains and UserProfiles.
#
# POST /#X-Amz-Target=SageMaker.DeleteStudioLifecycleConfig
# operationId: DeleteStudioLifecycleConfig
export def "x-amz-target-sage-maker-delete-studio-lifecycle-config delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-96
  studio_lifecycle_config_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteStudioLifecycleConfig")
  let req_body = {"StudioLifecycleConfigName": $studio_lifecycle_config_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes the specified tags from an SageMaker resource. To list a resource's tags, use the ListTags API. When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API. When you call this API to delete tags from a SageMaker Studio Domain or User Profile, the deleted tags are not removed from Apps that the SageMaker Studio Domain or User Profile launched before you called this API.
#
# POST /#X-Amz-Target=SageMaker.DeleteTags
# operationId: DeleteTags
export def "x-amz-target-sage-maker-delete-tags delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-97
  resource_arn: any
  tag_keys: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteTags")
  let req_body = {"ResourceArn": $resource_arn, "TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the DescribeTrialComponent (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeTrialComponent.html) API to get the list of trial components.
#
# POST /#X-Amz-Target=SageMaker.DeleteTrial
# operationId: DeleteTrial
export def "x-amz-target-sage-maker-delete-trial delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-98
  trial_name: any
]: any -> record<TrialArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteTrial")
  let req_body = {"TrialName": $trial_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the DisassociateTrialComponent (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DisassociateTrialComponent.html) API.
#
# POST /#X-Amz-Target=SageMaker.DeleteTrialComponent
# operationId: DeleteTrialComponent
export def "x-amz-target-sage-maker-delete-trial-component delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-99
  trial_component_name: any
]: any -> record<TrialComponentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteTrialComponent")
  let req_body = {"TrialComponentName": $trial_component_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a user profile. When a user profile is deleted, the user loses access to their EFS volume, including data, notebooks, and other artifacts.
#
# POST /#X-Amz-Target=SageMaker.DeleteUserProfile
# operationId: DeleteUserProfile
export def "x-amz-target-sage-maker-delete-user-profile delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-100
  domain_id: any
  user_profile_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteUserProfile")
  let req_body = {"DomainId": $domain_id, "UserProfileName": $user_profile_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this operation to delete a workforce. If you want to create a new workforce in an Amazon Web Services Region where a workforce already exists, use this operation to delete the existing workforce and then use CreateWorkforce (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateWorkforce.html) to create a new workforce. If a private workforce contains one or more work teams, you must use the DeleteWorkteam (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DeleteWorkteam.html) operation to delete all work teams before you delete the workforce. If you try to delete a workforce that contains one or more work teams, you will recieve a ResourceInUse error.
#
# POST /#X-Amz-Target=SageMaker.DeleteWorkforce
# operationId: DeleteWorkforce
export def "x-amz-target-sage-maker-delete-workforce delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-101
  workforce_name: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteWorkforce")
  let req_body = {"WorkforceName": $workforce_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an existing work team. This operation can't be undone.
#
# POST /#X-Amz-Target=SageMaker.DeleteWorkteam
# operationId: DeleteWorkteam
export def "x-amz-target-sage-maker-delete-workteam delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-102
  workteam_name: any
]: any -> record<Success: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteWorkteam")
  let req_body = {"WorkteamName": $workteam_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deregisters the specified devices. After you deregister a device, you will need to re-register the devices.
#
# POST /#X-Amz-Target=SageMaker.DeregisterDevices
# operationId: DeregisterDevices
export def "x-amz-target-sage-maker-deregister-devices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-103
  device_fleet_name: any
  device_names: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeregisterDevices")
  let req_body = {"DeviceFleetName": $device_fleet_name, "DeviceNames": $device_names} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes an action.
#
# POST /#X-Amz-Target=SageMaker.DescribeAction
# operationId: DescribeAction
export def "x-amz-target-sage-maker-describe-action get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-104
  action_name: any
]: any -> record<ActionName: record, ActionArn: record, Source: record<SourceUri: record, SourceType: record, SourceId: record>, ActionType: record, Description: record, Status: record, Properties: record, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, MetadataProperties: record<CommitId: record, Repository: record, GeneratedBy: record, ProjectId: record>, LineageGroupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeAction")
  let req_body = {"ActionName": $action_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a description of the specified algorithm that is in your account.
#
# POST /#X-Amz-Target=SageMaker.DescribeAlgorithm
# operationId: DescribeAlgorithm
export def "x-amz-target-sage-maker-describe-algorithm get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-105
  algorithm_name: any
]: any -> record<AlgorithmName: record, AlgorithmArn: record, AlgorithmDescription: record, CreationTime: record, TrainingSpecification: record<TrainingImage: record, TrainingImageDigest: record, SupportedHyperParameters: record, SupportedTrainingInstanceTypes: record, SupportsDistributedTraining: record, MetricDefinitions: record, TrainingChannels: record, SupportedTuningJobObjectiveMetrics: record>, InferenceSpecification: record<Containers: record, SupportedTransformInstanceTypes: record, SupportedRealtimeInferenceInstanceTypes: record, SupportedContentTypes: record, SupportedResponseMIMETypes: record>, ValidationSpecification: record<ValidationRole: record, ValidationProfiles: record>, AlgorithmStatus: record, AlgorithmStatusDetails: record<ValidationStatuses: record, ImageScanStatuses: record>, ProductId: record, CertifyForMarketplace: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeAlgorithm")
  let req_body = {"AlgorithmName": $algorithm_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes the app.
#
# POST /#X-Amz-Target=SageMaker.DescribeApp
# operationId: DescribeApp
export def "x-amz-target-sage-maker-describe-app get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-106
  domain_id: any
  --user-profile-name: any
  app_type: any
  app_name: any
  --space-name: any
]: any -> record<AppArn: record, AppType: record, AppName: record, DomainId: record, UserProfileName: record, Status: record, LastHealthCheckTimestamp: record, LastUserActivityTimestamp: record, CreationTime: record, FailureReason: record, ResourceSpec: record<SageMakerImageArn: record, SageMakerImageVersionArn: record, InstanceType: record, LifecycleConfigArn: record>, SpaceName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeApp")
  let req_body = {"DomainId": $domain_id, "UserProfileName": $user_profile_name, "AppType": $app_type, "AppName": $app_name, "SpaceName": $space_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes an AppImageConfig.
#
# POST /#X-Amz-Target=SageMaker.DescribeAppImageConfig
# operationId: DescribeAppImageConfig
export def "x-amz-target-sage-maker-describe-app-image-config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-107
  app_image_config_name: any
]: any -> record<AppImageConfigArn: record, AppImageConfigName: record, CreationTime: record, LastModifiedTime: record, KernelGatewayImageConfig: record<KernelSpecs: record, FileSystemConfig: record<MountPath: record, DefaultUid: record, DefaultGid: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeAppImageConfig")
  let req_body = {"AppImageConfigName": $app_image_config_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes an artifact.
#
# POST /#X-Amz-Target=SageMaker.DescribeArtifact
# operationId: DescribeArtifact
export def "x-amz-target-sage-maker-describe-artifact get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-108
  artifact_arn: any
]: any -> record<ArtifactName: record, ArtifactArn: record, Source: record<SourceUri: record, SourceTypes: record>, ArtifactType: record, Properties: record, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, MetadataProperties: record<CommitId: record, Repository: record, GeneratedBy: record, ProjectId: record>, LineageGroupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeArtifact")
  let req_body = {"ArtifactArn": $artifact_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns information about an Amazon SageMaker AutoML job.
#
# POST /#X-Amz-Target=SageMaker.DescribeAutoMLJob
# operationId: DescribeAutoMLJob
export def "x-amz-target-sage-maker-describe-auto-ml-job get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-109
  auto_ml_job_name: any
]: any -> record<AutoMLJobName: record, AutoMLJobArn: record, InputDataConfig: record, OutputDataConfig: record<KmsKeyId: record, S3OutputPath: record>, RoleArn: record, AutoMLJobObjective: record<MetricName: record>, ProblemType: record, AutoMLJobConfig: record<CompletionCriteria: record<MaxCandidates: record, MaxRuntimePerTrainingJobInSeconds: record, MaxAutoMLJobRuntimeInSeconds: record>, SecurityConfig: record<VolumeKmsKeyId: record, EnableInterContainerTrafficEncryption: record, VpcConfig: record>, DataSplitConfig: record<ValidationFraction: record>, CandidateGenerationConfig: record<FeatureSpecificationS3Uri: record, AlgorithmsConfig: record>, Mode: record>, CreationTime: record, EndTime: record, LastModifiedTime: record, FailureReason: record, PartialFailureReasons: record, BestCandidate: record<CandidateName: record, FinalAutoMLJobObjectiveMetric: record<Type: record, MetricName: record, Value: record, StandardMetricName: record>, ObjectiveStatus: record, CandidateSteps: record, CandidateStatus: record, InferenceContainers: record, CreationTime: record, EndTime: record, LastModifiedTime: record, FailureReason: record, CandidateProperties: record<CandidateArtifactLocations: record, CandidateMetrics: record>, InferenceContainerDefinitions: record>, AutoMLJobStatus: record, AutoMLJobSecondaryStatus: record, GenerateCandidateDefinitionsOnly: record, AutoMLJobArtifacts: record<CandidateDefinitionNotebookLocation: record, DataExplorationNotebookLocation: record>, ResolvedAttributes: record<AutoMLJobObjective: record<MetricName: record>, ProblemType: record, CompletionCriteria: record<MaxCandidates: record, MaxRuntimePerTrainingJobInSeconds: record, MaxAutoMLJobRuntimeInSeconds: record>>, ModelDeployConfig: record<AutoGenerateEndpointName: record, EndpointName: record>, ModelDeployResult: record<EndpointName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeAutoMLJob")
  let req_body = {"AutoMLJobName": $auto_ml_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns information about an Amazon SageMaker AutoML V2 job. This API action is callable through SageMaker Canvas only. Calling it directly from the CLI or an SDK results in an error.
#
# POST /#X-Amz-Target=SageMaker.DescribeAutoMLJobV2
# operationId: DescribeAutoMLJobV2
export def "x-amz-target-sage-maker-describe-auto-ml-job-v2 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-110
  auto_ml_job_name: any
]: any -> record<AutoMLJobName: record, AutoMLJobArn: record, AutoMLJobInputDataConfig: record, OutputDataConfig: record<KmsKeyId: record, S3OutputPath: record>, RoleArn: record, AutoMLJobObjective: record<MetricName: record>, AutoMLProblemTypeConfig: record<ImageClassificationJobConfig: record<CompletionCriteria: record>, TextClassificationJobConfig: record<CompletionCriteria: record, ContentColumn: record, TargetLabelColumn: record>>, CreationTime: record, EndTime: record, LastModifiedTime: record, FailureReason: record, PartialFailureReasons: record, BestCandidate: record<CandidateName: record, FinalAutoMLJobObjectiveMetric: record<Type: record, MetricName: record, Value: record, StandardMetricName: record>, ObjectiveStatus: record, CandidateSteps: record, CandidateStatus: record, InferenceContainers: record, CreationTime: record, EndTime: record, LastModifiedTime: record, FailureReason: record, CandidateProperties: record<CandidateArtifactLocations: record, CandidateMetrics: record>, InferenceContainerDefinitions: record>, AutoMLJobStatus: record, AutoMLJobSecondaryStatus: record, ModelDeployConfig: record<AutoGenerateEndpointName: record, EndpointName: record>, ModelDeployResult: record<EndpointName: record>, DataSplitConfig: record<ValidationFraction: record>, SecurityConfig: record<VolumeKmsKeyId: record, EnableInterContainerTrafficEncryption: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeAutoMLJobV2")
  let req_body = {"AutoMLJobName": $auto_ml_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets details about the specified Git repository.
#
# POST /#X-Amz-Target=SageMaker.DescribeCodeRepository
# operationId: DescribeCodeRepository
export def "x-amz-target-sage-maker-describe-code-repository get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-111
  code_repository_name: any
]: any -> record<CodeRepositoryName: record, CodeRepositoryArn: record, CreationTime: record, LastModifiedTime: record, GitConfig: record<RepositoryUrl: record, Branch: record, SecretArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeCodeRepository")
  let req_body = {"CodeRepositoryName": $code_repository_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns information about a model compilation job. To create a model compilation job, use CreateCompilationJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateCompilationJob.html). To get information about multiple model compilation jobs, use ListCompilationJobs (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_ListCompilationJobs.html).
#
# POST /#X-Amz-Target=SageMaker.DescribeCompilationJob
# operationId: DescribeCompilationJob
export def "x-amz-target-sage-maker-describe-compilation-job get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-112
  compilation_job_name: any
]: any -> record<CompilationJobName: record, CompilationJobArn: record, CompilationJobStatus: record, CompilationStartTime: record, CompilationEndTime: record, StoppingCondition: record<MaxRuntimeInSeconds: record, MaxWaitTimeInSeconds: record>, InferenceImage: record, ModelPackageVersionArn: record, CreationTime: record, LastModifiedTime: record, FailureReason: record, ModelArtifacts: record<S3ModelArtifacts: record>, ModelDigests: record<ArtifactDigest: record>, RoleArn: record, InputConfig: record<S3Uri: record, DataInputConfig: record, Framework: record, FrameworkVersion: record>, OutputConfig: record<S3OutputLocation: record, TargetDevice: record, TargetPlatform: record<Os: record, Arch: record, Accelerator: record>, CompilerOptions: record, KmsKeyId: record>, VpcConfig: record<SecurityGroupIds: record, Subnets: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeCompilationJob")
  let req_body = {"CompilationJobName": $compilation_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes a context.
#
# POST /#X-Amz-Target=SageMaker.DescribeContext
# operationId: DescribeContext
export def "x-amz-target-sage-maker-describe-context get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-113
  context_name: any
]: any -> record<ContextName: record, ContextArn: record, Source: record<SourceUri: record, SourceType: record, SourceId: record>, ContextType: record, Description: record, Properties: record, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LineageGroupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeContext")
  let req_body = {"ContextName": $context_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the details of a data quality monitoring job definition.
#
# POST /#X-Amz-Target=SageMaker.DescribeDataQualityJobDefinition
# operationId: DescribeDataQualityJobDefinition
export def "x-amz-target-sage-maker-describe-data-quality-job-definition get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-114
  job_definition_name: any
]: any -> record<JobDefinitionArn: record, JobDefinitionName: record, CreationTime: record, DataQualityBaselineConfig: record<BaseliningJobName: record, ConstraintsResource: record<S3Uri: record>, StatisticsResource: record<S3Uri: record>>, DataQualityAppSpecification: record<ImageUri: record, ContainerEntrypoint: record, ContainerArguments: record, RecordPreprocessorSourceUri: record, PostAnalyticsProcessorSourceUri: record, Environment: record>, DataQualityJobInput: record<EndpointInput: record<EndpointName: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>, BatchTransformInput: record<DataCapturedDestinationS3Uri: record, DatasetFormat: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>>, DataQualityJobOutputConfig: record<MonitoringOutputs: record, KmsKeyId: record>, JobResources: record<ClusterConfig: record<InstanceCount: record, InstanceType: record, VolumeSizeInGB: record, VolumeKmsKeyId: record>>, NetworkConfig: record<EnableInterContainerTrafficEncryption: record, EnableNetworkIsolation: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>>, RoleArn: record, StoppingCondition: record<MaxRuntimeInSeconds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeDataQualityJobDefinition")
  let req_body = {"JobDefinitionName": $job_definition_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes the device.
#
# POST /#X-Amz-Target=SageMaker.DescribeDevice
# operationId: DescribeDevice
export def "x-amz-target-sage-maker-describe-device get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-115
  --next-token: any
  device_name: any
  device_fleet_name: any
]: any -> record<DeviceArn: record, DeviceName: record, Description: record, DeviceFleetName: record, IotThingName: record, RegistrationTime: record, LatestHeartbeat: record, Models: record, MaxModels: record, NextToken: record, AgentVersion: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeDevice")
  let req_body = {"NextToken": $next_token, "DeviceName": $device_name, "DeviceFleetName": $device_fleet_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# A description of the fleet the device belongs to.
#
# POST /#X-Amz-Target=SageMaker.DescribeDeviceFleet
# operationId: DescribeDeviceFleet
export def "x-amz-target-sage-maker-describe-device-fleet get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-116
  device_fleet_name: any
]: any -> record<DeviceFleetName: record, DeviceFleetArn: record, OutputConfig: record<S3OutputLocation: record, KmsKeyId: record, PresetDeploymentType: record, PresetDeploymentConfig: record>, Description: record, CreationTime: record, LastModifiedTime: record, RoleArn: record, IotRoleAlias: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeDeviceFleet")
  let req_body = {"DeviceFleetName": $device_fleet_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# The description of the domain.
#
# POST /#X-Amz-Target=SageMaker.DescribeDomain
# operationId: DescribeDomain
export def "x-amz-target-sage-maker-describe-domain get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-117
  domain_id: any
]: any -> record<DomainArn: record, DomainId: record, DomainName: record, HomeEfsFileSystemId: record, SingleSignOnManagedApplicationInstanceId: record, Status: record, CreationTime: record, LastModifiedTime: record, FailureReason: record, AuthMode: record, DefaultUserSettings: record<ExecutionRole: record, SecurityGroups: record, SharingSettings: record<NotebookOutputOption: record, S3OutputPath: record, S3KmsKeyId: record>, JupyterServerAppSettings: record<DefaultResourceSpec: record, LifecycleConfigArns: record, CodeRepositories: record>, KernelGatewayAppSettings: record<DefaultResourceSpec: record, CustomImages: record, LifecycleConfigArns: record>, TensorBoardAppSettings: record<DefaultResourceSpec: record>, RStudioServerProAppSettings: record<AccessStatus: record, UserGroup: record>, RSessionAppSettings: record<DefaultResourceSpec: record, CustomImages: record>, CanvasAppSettings: record<TimeSeriesForecastingSettings: record, ModelRegisterSettings: record>>, AppNetworkAccessType: record, HomeEfsFileSystemKmsKeyId: record, SubnetIds: record, Url: record, VpcId: record, KmsKeyId: record, DomainSettings: record<SecurityGroupIds: record, RStudioServerProDomainSettings: record<DomainExecutionRoleArn: record, RStudioConnectUrl: record, RStudioPackageManagerUrl: record, DefaultResourceSpec: record>, ExecutionRoleIdentityConfig: record>, AppSecurityGroupManagement: record, SecurityGroupIdForDomainBoundary: record, DefaultSpaceSettings: record<ExecutionRole: record, SecurityGroups: record, JupyterServerAppSettings: record<DefaultResourceSpec: record, LifecycleConfigArns: record, CodeRepositories: record>, KernelGatewayAppSettings: record<DefaultResourceSpec: record, CustomImages: record, LifecycleConfigArns: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeDomain")
  let req_body = {"DomainId": $domain_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes an edge deployment plan with deployment status per stage.
#
# POST /#X-Amz-Target=SageMaker.DescribeEdgeDeploymentPlan
# operationId: DescribeEdgeDeploymentPlan
export def "x-amz-target-sage-maker-describe-edge-deployment-plan get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-118
  edge_deployment_plan_name: any
  --next-token: any
  --max-results: any
]: any -> record<EdgeDeploymentPlanArn: record, EdgeDeploymentPlanName: record, ModelConfigs: record, DeviceFleetName: record, EdgeDeploymentSuccess: record, EdgeDeploymentPending: record, EdgeDeploymentFailed: record, Stages: record, NextToken: record, CreationTime: record, LastModifiedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeEdgeDeploymentPlan")
  let req_body = {"EdgeDeploymentPlanName": $edge_deployment_plan_name, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# A description of edge packaging jobs.
#
# POST /#X-Amz-Target=SageMaker.DescribeEdgePackagingJob
# operationId: DescribeEdgePackagingJob
export def "x-amz-target-sage-maker-describe-edge-packaging-job get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-119
  edge_packaging_job_name: any
]: any -> record<EdgePackagingJobArn: record, EdgePackagingJobName: record, CompilationJobName: record, ModelName: record, ModelVersion: record, RoleArn: record, OutputConfig: record<S3OutputLocation: record, KmsKeyId: record, PresetDeploymentType: record, PresetDeploymentConfig: record>, ResourceKey: record, EdgePackagingJobStatus: record, EdgePackagingJobStatusMessage: record, CreationTime: record, LastModifiedTime: record, ModelArtifact: record, ModelSignature: record, PresetDeploymentOutput: record<Type: record, Artifact: record, Status: record, StatusMessage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeEdgePackagingJob")
  let req_body = {"EdgePackagingJobName": $edge_packaging_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the description of an endpoint.
#
# POST /#X-Amz-Target=SageMaker.DescribeEndpoint
# operationId: DescribeEndpoint
export def "x-amz-target-sage-maker-describe-endpoint get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-120
  endpoint_name: any
]: any -> record<EndpointName: record, EndpointArn: record, EndpointConfigName: record, ProductionVariants: record, DataCaptureConfig: record<EnableCapture: record, CaptureStatus: record, CurrentSamplingPercentage: record, DestinationS3Uri: record, KmsKeyId: record>, EndpointStatus: record, FailureReason: record, CreationTime: record, LastModifiedTime: record, LastDeploymentConfig: record<BlueGreenUpdatePolicy: record<TrafficRoutingConfiguration: record, TerminationWaitInSeconds: record, MaximumExecutionTimeoutInSeconds: record>, AutoRollbackConfiguration: record<Alarms: record>>, AsyncInferenceConfig: record<ClientConfig: record<MaxConcurrentInvocationsPerInstance: record>, OutputConfig: record<KmsKeyId: record, S3OutputPath: record, NotificationConfig: record, S3FailurePath: record>>, PendingDeploymentSummary: record<EndpointConfigName: record, ProductionVariants: record, StartTime: record, ShadowProductionVariants: record>, ExplainerConfig: record<ClarifyExplainerConfig: record<EnableExplanations: record, InferenceConfig: record, ShapConfig: record>>, ShadowProductionVariants: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeEndpoint")
  let req_body = {"EndpointName": $endpoint_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the description of an endpoint configuration created using the CreateEndpointConfig API.
#
# POST /#X-Amz-Target=SageMaker.DescribeEndpointConfig
# operationId: DescribeEndpointConfig
export def "x-amz-target-sage-maker-describe-endpoint-config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-121
  endpoint_config_name: any
]: any -> record<EndpointConfigName: record, EndpointConfigArn: record, ProductionVariants: record, DataCaptureConfig: record<EnableCapture: record, InitialSamplingPercentage: record, DestinationS3Uri: record, KmsKeyId: record, CaptureOptions: record, CaptureContentTypeHeader: record<CsvContentTypes: record, JsonContentTypes: record>>, KmsKeyId: record, CreationTime: record, AsyncInferenceConfig: record<ClientConfig: record<MaxConcurrentInvocationsPerInstance: record>, OutputConfig: record<KmsKeyId: record, S3OutputPath: record, NotificationConfig: record, S3FailurePath: record>>, ExplainerConfig: record<ClarifyExplainerConfig: record<EnableExplanations: record, InferenceConfig: record, ShapConfig: record>>, ShadowProductionVariants: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeEndpointConfig")
  let req_body = {"EndpointConfigName": $endpoint_config_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Provides a list of an experiment's properties.
#
# POST /#X-Amz-Target=SageMaker.DescribeExperiment
# operationId: DescribeExperiment
export def "x-amz-target-sage-maker-describe-experiment get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-122
  experiment_name: any
]: any -> record<ExperimentName: record, ExperimentArn: record, DisplayName: record, Source: record<SourceArn: record, SourceType: record>, Description: record, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeExperiment")
  let req_body = {"ExperimentName": $experiment_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this operation to describe a FeatureGroup. The response includes information on the creation time, FeatureGroup name, the unique identifier for each FeatureGroup, and more.
#
# POST /#X-Amz-Target=SageMaker.DescribeFeatureGroup
# operationId: DescribeFeatureGroup
export def "x-amz-target-sage-maker-describe-feature-group get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-123
  feature_group_name: any
  --next-token: any
]: any -> record<FeatureGroupArn: record, FeatureGroupName: record, RecordIdentifierFeatureName: record, EventTimeFeatureName: record, FeatureDefinitions: record, CreationTime: record, LastModifiedTime: record, OnlineStoreConfig: record<SecurityConfig: record<KmsKeyId: record>, EnableOnlineStore: record>, OfflineStoreConfig: record<S3StorageConfig: record<S3Uri: record, KmsKeyId: record, ResolvedOutputS3Uri: record>, DisableGlueTableCreation: record, DataCatalogConfig: record<TableName: record, Catalog: record, Database: record>, TableFormat: record>, RoleArn: record, FeatureGroupStatus: record, OfflineStoreStatus: record<Status: record, BlockedReason: record>, LastUpdateStatus: record<Status: record, FailureReason: record>, FailureReason: record, Description: record, NextToken: record, OnlineStoreTotalSizeBytes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeFeatureGroup")
  let req_body = {"FeatureGroupName": $feature_group_name, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Shows the metadata for a feature within a feature group.
#
# POST /#X-Amz-Target=SageMaker.DescribeFeatureMetadata
# operationId: DescribeFeatureMetadata
export def "x-amz-target-sage-maker-describe-feature-metadata get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-124
  feature_group_name: any
  feature_name: any
]: any -> record<FeatureGroupArn: record, FeatureGroupName: record, FeatureName: record, FeatureType: record, CreationTime: record, LastModifiedTime: record, Description: record, Parameters: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeFeatureMetadata")
  let req_body = {"FeatureGroupName": $feature_group_name, "FeatureName": $feature_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns information about the specified flow definition.
#
# POST /#X-Amz-Target=SageMaker.DescribeFlowDefinition
# operationId: DescribeFlowDefinition
export def "x-amz-target-sage-maker-describe-flow-definition get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-125
  flow_definition_name: any
]: any -> record<FlowDefinitionArn: record, FlowDefinitionName: record, FlowDefinitionStatus: record, CreationTime: record, HumanLoopRequestSource: record<AwsManagedHumanLoopRequestSource: record>, HumanLoopActivationConfig: record<HumanLoopActivationConditionsConfig: record<HumanLoopActivationConditions: record>>, HumanLoopConfig: record<WorkteamArn: record, HumanTaskUiArn: record, TaskTitle: record, TaskDescription: record, TaskCount: record, TaskAvailabilityLifetimeInSeconds: record, TaskTimeLimitInSeconds: record, TaskKeywords: record, PublicWorkforceTaskPrice: record<AmountInUsd: record>>, OutputConfig: record<S3OutputPath: record, KmsKeyId: record>, RoleArn: record, FailureReason: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeFlowDefinition")
  let req_body = {"FlowDefinitionName": $flow_definition_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describe a hub. Hub APIs are only callable through SageMaker Studio.
#
# POST /#X-Amz-Target=SageMaker.DescribeHub
# operationId: DescribeHub
export def "x-amz-target-sage-maker-describe-hub get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-126
  hub_name: any
]: any -> record<HubName: record, HubArn: record, HubDisplayName: record, HubDescription: record, HubSearchKeywords: record, S3StorageConfig: record<S3OutputPath: record>, HubStatus: record, FailureReason: record, CreationTime: record, LastModifiedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeHub")
  let req_body = {"HubName": $hub_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describe the content of a hub. Hub APIs are only callable through SageMaker Studio.
#
# POST /#X-Amz-Target=SageMaker.DescribeHubContent
# operationId: DescribeHubContent
export def "x-amz-target-sage-maker-describe-hub-content get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-127
  hub_name: any
  hub_content_type: any
  hub_content_name: any
  --hub-content-version: any
]: any -> record<HubContentName: record, HubContentArn: record, HubContentVersion: record, HubContentType: record, DocumentSchemaVersion: record, HubName: record, HubArn: record, HubContentDisplayName: record, HubContentDescription: record, HubContentMarkdown: record, HubContentDocument: record, HubContentSearchKeywords: record, HubContentDependencies: record, HubContentStatus: record, FailureReason: record, CreationTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeHubContent")
  let req_body = {"HubName": $hub_name, "HubContentType": $hub_content_type, "HubContentName": $hub_content_name, "HubContentVersion": $hub_content_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns information about the requested human task user interface (worker task template).
#
# POST /#X-Amz-Target=SageMaker.DescribeHumanTaskUi
# operationId: DescribeHumanTaskUi
export def "x-amz-target-sage-maker-describe-human-task-ui get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-128
  human_task_ui_name: any
]: any -> record<HumanTaskUiArn: record, HumanTaskUiName: record, HumanTaskUiStatus: record, CreationTime: record, UiTemplate: record<Url: record, ContentSha256: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeHumanTaskUi")
  let req_body = {"HumanTaskUiName": $human_task_ui_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a description of a hyperparameter tuning job.
#
# POST /#X-Amz-Target=SageMaker.DescribeHyperParameterTuningJob
# operationId: DescribeHyperParameterTuningJob
export def "x-amz-target-sage-maker-describe-hyper-parameter-tuning-job get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-129
  hyper_parameter_tuning_job_name: any
]: any -> record<HyperParameterTuningJobName: record, HyperParameterTuningJobArn: record, HyperParameterTuningJobConfig: record<Strategy: record, StrategyConfig: record<HyperbandStrategyConfig: record>, HyperParameterTuningJobObjective: record<Type: record, MetricName: record>, ResourceLimits: record<MaxNumberOfTrainingJobs: record, MaxParallelTrainingJobs: record, MaxRuntimeInSeconds: record>, ParameterRanges: record<IntegerParameterRanges: record, ContinuousParameterRanges: record, CategoricalParameterRanges: record>, TrainingJobEarlyStoppingType: record, TuningJobCompletionCriteria: record<TargetObjectiveMetricValue: record, BestObjectiveNotImproving: record, ConvergenceDetected: record>, RandomSeed: record>, TrainingJobDefinition: record<DefinitionName: record, TuningObjective: record<Type: record, MetricName: record>, HyperParameterRanges: record<IntegerParameterRanges: record, ContinuousParameterRanges: record, CategoricalParameterRanges: record>, StaticHyperParameters: record, AlgorithmSpecification: record<TrainingImage: record, TrainingInputMode: string, AlgorithmName: record, MetricDefinitions: record>, RoleArn: record, InputDataConfig: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>, OutputDataConfig: record<KmsKeyId: record, S3OutputPath: record>, ResourceConfig: record<InstanceType: record, InstanceCount: record, VolumeSizeInGB: record, VolumeKmsKeyId: record, InstanceGroups: record, KeepAlivePeriodInSeconds: record>, StoppingCondition: record<MaxRuntimeInSeconds: record, MaxWaitTimeInSeconds: record>, EnableNetworkIsolation: record, EnableInterContainerTrafficEncryption: record, EnableManagedSpotTraining: record, CheckpointConfig: record<S3Uri: record, LocalPath: record>, RetryStrategy: record<MaximumRetryAttempts: record>, HyperParameterTuningResourceConfig: record<InstanceType: record, InstanceCount: record, VolumeSizeInGB: record, VolumeKmsKeyId: record, AllocationStrategy: record, InstanceConfigs: record>, Environment: record>, TrainingJobDefinitions: record, HyperParameterTuningJobStatus: record, CreationTime: record, HyperParameterTuningEndTime: record, LastModifiedTime: record, TrainingJobStatusCounters: record<Completed: record, InProgress: record, RetryableError: record, NonRetryableError: record, Stopped: record>, ObjectiveStatusCounters: record<Succeeded: record, Pending: record, Failed: record>, BestTrainingJob: record<TrainingJobDefinitionName: record, TrainingJobName: record, TrainingJobArn: record, TuningJobName: record, CreationTime: record, TrainingStartTime: record, TrainingEndTime: record, TrainingJobStatus: record, TunedHyperParameters: record, FailureReason: record, FinalHyperParameterTuningJobObjectiveMetric: record<Type: record, MetricName: record, Value: record>, ObjectiveStatus: record>, OverallBestTrainingJob: record<TrainingJobDefinitionName: record, TrainingJobName: record, TrainingJobArn: record, TuningJobName: record, CreationTime: record, TrainingStartTime: record, TrainingEndTime: record, TrainingJobStatus: record, TunedHyperParameters: record, FailureReason: record, FinalHyperParameterTuningJobObjectiveMetric: record<Type: record, MetricName: record, Value: record>, ObjectiveStatus: record>, WarmStartConfig: record<ParentHyperParameterTuningJobs: record, WarmStartType: record>, FailureReason: record, TuningJobCompletionDetails: record<NumberOfTrainingJobsObjectiveNotImproving: record, ConvergenceDetectedTime: record>, ConsumedResources: record<RuntimeInSeconds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeHyperParameterTuningJob")
  let req_body = {"HyperParameterTuningJobName": $hyper_parameter_tuning_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes a SageMaker image.
#
# POST /#X-Amz-Target=SageMaker.DescribeImage
# operationId: DescribeImage
export def "x-amz-target-sage-maker-describe-image get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-130
  image_name: any
]: any -> record<CreationTime: record, Description: record, DisplayName: record, FailureReason: record, ImageArn: record, ImageName: record, ImageStatus: record, LastModifiedTime: record, RoleArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeImage")
  let req_body = {"ImageName": $image_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes a version of a SageMaker image.
#
# POST /#X-Amz-Target=SageMaker.DescribeImageVersion
# operationId: DescribeImageVersion
export def "x-amz-target-sage-maker-describe-image-version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-131
  image_name: any
  --version: any
  --alias: any
]: any -> record<BaseImage: record, ContainerImage: record, CreationTime: record, FailureReason: record, ImageArn: record, ImageVersionArn: record, ImageVersionStatus: record, LastModifiedTime: record, Version: record, VendorGuidance: record, JobType: record, MLFramework: record, ProgrammingLang: record, Processor: record, Horovod: record, ReleaseNotes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeImageVersion")
  let req_body = {"ImageName": $image_name, "Version": $version, "Alias": $alias} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns details about an inference experiment.
#
# POST /#X-Amz-Target=SageMaker.DescribeInferenceExperiment
# operationId: DescribeInferenceExperiment
export def "x-amz-target-sage-maker-describe-inference-experiment get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-132
  name: any
]: any -> record<Arn: record, Name: record, Type: record, Schedule: record<StartTime: record, EndTime: record>, Status: record, StatusReason: record, Description: record, CreationTime: record, CompletionTime: record, LastModifiedTime: record, RoleArn: record, EndpointMetadata: record<EndpointName: record, EndpointConfigName: record, EndpointStatus: record, FailureReason: record>, ModelVariants: record, DataStorageConfig: record<Destination: record, KmsKey: record, ContentType: record<CsvContentTypes: record, JsonContentTypes: record>>, ShadowModeConfig: record<SourceModelVariantName: record, ShadowModelVariants: record>, KmsKey: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeInferenceExperiment")
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Provides the results of the Inference Recommender job. One or more recommendation jobs are returned.
#
# POST /#X-Amz-Target=SageMaker.DescribeInferenceRecommendationsJob
# operationId: DescribeInferenceRecommendationsJob
export def "x-amz-target-sage-maker-describe-inference-recommendations-job get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-133
  job_name: any
]: any -> record<JobName: record, JobDescription: record, JobType: record, JobArn: record, RoleArn: record, Status: record, CreationTime: record, CompletionTime: record, LastModifiedTime: record, FailureReason: record, InputConfig: record<ModelPackageVersionArn: record, JobDurationInSeconds: record, TrafficPattern: record<TrafficType: record, Phases: record>, ResourceLimit: record<MaxNumberOfTests: record, MaxParallelOfTests: record>, EndpointConfigurations: record, VolumeKmsKeyId: record, ContainerConfig: record<Domain: record, Task: record, Framework: record, FrameworkVersion: record, PayloadConfig: record, NearestModelName: record, SupportedInstanceTypes: record, DataInputConfig: record>, Endpoints: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>, ModelName: record>, StoppingConditions: record<MaxInvocations: record, ModelLatencyThresholds: record>, InferenceRecommendations: record, EndpointPerformances: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeInferenceRecommendationsJob")
  let req_body = {"JobName": $job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets information about a labeling job.
#
# POST /#X-Amz-Target=SageMaker.DescribeLabelingJob
# operationId: DescribeLabelingJob
export def "x-amz-target-sage-maker-describe-labeling-job get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-134
  labeling_job_name: any
]: any -> record<LabelingJobStatus: record, LabelCounters: record<TotalLabeled: record, HumanLabeled: record, MachineLabeled: record, FailedNonRetryableError: record, Unlabeled: record>, FailureReason: record, CreationTime: record, LastModifiedTime: record, JobReferenceCode: record, LabelingJobName: record, LabelingJobArn: record, LabelAttributeName: record, InputConfig: record<DataSource: record<S3DataSource: record, SnsDataSource: record>, DataAttributes: record<ContentClassifiers: record>>, OutputConfig: record<S3OutputPath: record, KmsKeyId: record, SnsTopicArn: record>, RoleArn: record, LabelCategoryConfigS3Uri: record, StoppingConditions: record<MaxHumanLabeledObjectCount: record, MaxPercentageOfInputDatasetLabeled: record>, LabelingJobAlgorithmsConfig: record<LabelingJobAlgorithmSpecificationArn: record, InitialActiveLearningModelArn: record, LabelingJobResourceConfig: record<VolumeKmsKeyId: record, VpcConfig: record>>, HumanTaskConfig: record<WorkteamArn: record, UiConfig: record<UiTemplateS3Uri: record, HumanTaskUiArn: record>, PreHumanTaskLambdaArn: record, TaskKeywords: record, TaskTitle: record, TaskDescription: record, NumberOfHumanWorkersPerDataObject: record, TaskTimeLimitInSeconds: record, TaskAvailabilityLifetimeInSeconds: record, MaxConcurrentTaskCount: record, AnnotationConsolidationConfig: record<AnnotationConsolidationLambdaArn: record>, PublicWorkforceTaskPrice: record<AmountInUsd: record>>, Tags: record, LabelingJobOutput: record<OutputDatasetS3Uri: record, FinalActiveLearningModelArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeLabelingJob")
  let req_body = {"LabelingJobName": $labeling_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Provides a list of properties for the requested lineage group. For more information, see Cross-Account Lineage Tracking (https://docs.aws.amazon.com/sagemaker/latest/dg/xaccount-lineage-tracking.html) in the Amazon SageMaker Developer Guide.
#
# POST /#X-Amz-Target=SageMaker.DescribeLineageGroup
# operationId: DescribeLineageGroup
export def "x-amz-target-sage-maker-describe-lineage-group get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-135
  lineage_group_name: any
]: any -> record<LineageGroupName: record, LineageGroupArn: record, DisplayName: record, Description: record, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeLineageGroup")
  let req_body = {"LineageGroupName": $lineage_group_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes a model that you created using the CreateModel API.
#
# POST /#X-Amz-Target=SageMaker.DescribeModel
# operationId: DescribeModel
export def "x-amz-target-sage-maker-describe-model get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-136
  model_name: any
]: any -> record<ModelName: record, PrimaryContainer: record<ContainerHostname: record, Image: record, ImageConfig: record<RepositoryAccessMode: record, RepositoryAuthConfig: record>, Mode: record, ModelDataUrl: record, Environment: record, ModelPackageName: record, InferenceSpecificationName: record, MultiModelConfig: record<ModelCacheSetting: record>>, Containers: record, InferenceExecutionConfig: record<Mode: record>, ExecutionRoleArn: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>, CreationTime: record, ModelArn: record, EnableNetworkIsolation: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModel")
  let req_body = {"ModelName": $model_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a description of a model bias job definition.
#
# POST /#X-Amz-Target=SageMaker.DescribeModelBiasJobDefinition
# operationId: DescribeModelBiasJobDefinition
export def "x-amz-target-sage-maker-describe-model-bias-job-definition get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-137
  job_definition_name: any
]: any -> record<JobDefinitionArn: record, JobDefinitionName: record, CreationTime: record, ModelBiasBaselineConfig: record<BaseliningJobName: record, ConstraintsResource: record<S3Uri: record>>, ModelBiasAppSpecification: record<ImageUri: record, ConfigUri: record, Environment: record>, ModelBiasJobInput: record<EndpointInput: record<EndpointName: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>, BatchTransformInput: record<DataCapturedDestinationS3Uri: record, DatasetFormat: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>, GroundTruthS3Input: record<S3Uri: record>>, ModelBiasJobOutputConfig: record<MonitoringOutputs: record, KmsKeyId: record>, JobResources: record<ClusterConfig: record<InstanceCount: record, InstanceType: record, VolumeSizeInGB: record, VolumeKmsKeyId: record>>, NetworkConfig: record<EnableInterContainerTrafficEncryption: record, EnableNetworkIsolation: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>>, RoleArn: record, StoppingCondition: record<MaxRuntimeInSeconds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModelBiasJobDefinition")
  let req_body = {"JobDefinitionName": $job_definition_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes the content, creation time, and security configuration of an Amazon SageMaker Model Card.
#
# POST /#X-Amz-Target=SageMaker.DescribeModelCard
# operationId: DescribeModelCard
export def "x-amz-target-sage-maker-describe-model-card get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-138
  model_card_name: any
  --model-card-version: any
]: any -> record<ModelCardArn: record, ModelCardName: record, ModelCardVersion: record, Content: record, ModelCardStatus: record, SecurityConfig: record<KmsKeyId: record>, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, ModelCardProcessingStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModelCard")
  let req_body = {"ModelCardName": $model_card_name, "ModelCardVersion": $model_card_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes an Amazon SageMaker Model Card export job.
#
# POST /#X-Amz-Target=SageMaker.DescribeModelCardExportJob
# operationId: DescribeModelCardExportJob
export def "x-amz-target-sage-maker-describe-model-card-export-job get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-139
  model_card_export_job_arn: any
]: any -> record<ModelCardExportJobName: record, ModelCardExportJobArn: record, Status: record, ModelCardName: record, ModelCardVersion: record, OutputConfig: record<S3OutputPath: record>, CreatedAt: record, LastModifiedAt: record, FailureReason: record, ExportArtifacts: record<S3ExportArtifacts: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModelCardExportJob")
  let req_body = {"ModelCardExportJobArn": $model_card_export_job_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a description of a model explainability job definition.
#
# POST /#X-Amz-Target=SageMaker.DescribeModelExplainabilityJobDefinition
# operationId: DescribeModelExplainabilityJobDefinition
export def "x-amz-target-sage-maker-describe-model-explainability-job-definition get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-140
  job_definition_name: any
]: any -> record<JobDefinitionArn: record, JobDefinitionName: record, CreationTime: record, ModelExplainabilityBaselineConfig: record<BaseliningJobName: record, ConstraintsResource: record<S3Uri: record>>, ModelExplainabilityAppSpecification: record<ImageUri: record, ConfigUri: record, Environment: record>, ModelExplainabilityJobInput: record<EndpointInput: record<EndpointName: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>, BatchTransformInput: record<DataCapturedDestinationS3Uri: record, DatasetFormat: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>>, ModelExplainabilityJobOutputConfig: record<MonitoringOutputs: record, KmsKeyId: record>, JobResources: record<ClusterConfig: record<InstanceCount: record, InstanceType: record, VolumeSizeInGB: record, VolumeKmsKeyId: record>>, NetworkConfig: record<EnableInterContainerTrafficEncryption: record, EnableNetworkIsolation: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>>, RoleArn: record, StoppingCondition: record<MaxRuntimeInSeconds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModelExplainabilityJobDefinition")
  let req_body = {"JobDefinitionName": $job_definition_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a description of the specified model package, which is used to create SageMaker models or list them on Amazon Web Services Marketplace. To create models in SageMaker, buyers can subscribe to model packages listed on Amazon Web Services Marketplace.
#
# POST /#X-Amz-Target=SageMaker.DescribeModelPackage
# operationId: DescribeModelPackage
export def "x-amz-target-sage-maker-describe-model-package get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-141
  model_package_name: any
]: any -> record<ModelPackageName: record, ModelPackageGroupName: record, ModelPackageVersion: record, ModelPackageArn: record, ModelPackageDescription: record, CreationTime: record, InferenceSpecification: record<Containers: record, SupportedTransformInstanceTypes: record, SupportedRealtimeInferenceInstanceTypes: record, SupportedContentTypes: record, SupportedResponseMIMETypes: record>, SourceAlgorithmSpecification: record<SourceAlgorithms: record>, ValidationSpecification: record<ValidationRole: record, ValidationProfiles: record>, ModelPackageStatus: record, ModelPackageStatusDetails: record<ValidationStatuses: record, ImageScanStatuses: record>, CertifyForMarketplace: record, ModelApprovalStatus: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, MetadataProperties: record<CommitId: record, Repository: record, GeneratedBy: record, ProjectId: record>, ModelMetrics: record<ModelQuality: record<Statistics: record, Constraints: record>, ModelDataQuality: record<Statistics: record, Constraints: record>, Bias: record<Report: record, PreTrainingReport: record, PostTrainingReport: record>, Explainability: record<Report: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, ApprovalDescription: record, CustomerMetadataProperties: record, DriftCheckBaselines: record<Bias: record<ConfigFile: record, PreTrainingConstraints: record, PostTrainingConstraints: record>, Explainability: record<Constraints: record, ConfigFile: record>, ModelQuality: record<Statistics: record, Constraints: record>, ModelDataQuality: record<Statistics: record, Constraints: record>>, Domain: record, Task: record, SamplePayloadUrl: record, AdditionalInferenceSpecifications: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModelPackage")
  let req_body = {"ModelPackageName": $model_package_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a description for the specified model group.
#
# POST /#X-Amz-Target=SageMaker.DescribeModelPackageGroup
# operationId: DescribeModelPackageGroup
export def "x-amz-target-sage-maker-describe-model-package-group get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-142
  model_package_group_name: any
]: any -> record<ModelPackageGroupName: record, ModelPackageGroupArn: record, ModelPackageGroupDescription: record, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, ModelPackageGroupStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModelPackageGroup")
  let req_body = {"ModelPackageGroupName": $model_package_group_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a description of a model quality job definition.
#
# POST /#X-Amz-Target=SageMaker.DescribeModelQualityJobDefinition
# operationId: DescribeModelQualityJobDefinition
export def "x-amz-target-sage-maker-describe-model-quality-job-definition get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-143
  job_definition_name: any
]: any -> record<JobDefinitionArn: record, JobDefinitionName: record, CreationTime: record, ModelQualityBaselineConfig: record<BaseliningJobName: record, ConstraintsResource: record<S3Uri: record>>, ModelQualityAppSpecification: record<ImageUri: record, ContainerEntrypoint: record, ContainerArguments: record, RecordPreprocessorSourceUri: record, PostAnalyticsProcessorSourceUri: record, ProblemType: record, Environment: record>, ModelQualityJobInput: record<EndpointInput: record<EndpointName: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>, BatchTransformInput: record<DataCapturedDestinationS3Uri: record, DatasetFormat: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>, GroundTruthS3Input: record<S3Uri: record>>, ModelQualityJobOutputConfig: record<MonitoringOutputs: record, KmsKeyId: record>, JobResources: record<ClusterConfig: record<InstanceCount: record, InstanceType: record, VolumeSizeInGB: record, VolumeKmsKeyId: record>>, NetworkConfig: record<EnableInterContainerTrafficEncryption: record, EnableNetworkIsolation: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>>, RoleArn: record, StoppingCondition: record<MaxRuntimeInSeconds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModelQualityJobDefinition")
  let req_body = {"JobDefinitionName": $job_definition_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes the schedule for a monitoring job.
#
# POST /#X-Amz-Target=SageMaker.DescribeMonitoringSchedule
# operationId: DescribeMonitoringSchedule
export def "x-amz-target-sage-maker-describe-monitoring-schedule get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-144
  monitoring_schedule_name: any
]: any -> record<MonitoringScheduleArn: record, MonitoringScheduleName: record, MonitoringScheduleStatus: record, MonitoringType: record, FailureReason: record, CreationTime: record, LastModifiedTime: record, MonitoringScheduleConfig: record<ScheduleConfig: record<ScheduleExpression: record>, MonitoringJobDefinition: record<BaselineConfig: record, MonitoringInputs: record, MonitoringOutputConfig: record, MonitoringResources: record, MonitoringAppSpecification: record, StoppingCondition: record, Environment: record, NetworkConfig: record, RoleArn: record>, MonitoringJobDefinitionName: record, MonitoringType: record>, EndpointName: record, LastMonitoringExecutionSummary: record<MonitoringScheduleName: record, ScheduledTime: record, CreationTime: record, LastModifiedTime: record, MonitoringExecutionStatus: record, ProcessingJobArn: record, EndpointName: record, FailureReason: record, MonitoringJobDefinitionName: record, MonitoringType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeMonitoringSchedule")
  let req_body = {"MonitoringScheduleName": $monitoring_schedule_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns information about a notebook instance.
#
# POST /#X-Amz-Target=SageMaker.DescribeNotebookInstance
# operationId: DescribeNotebookInstance
export def "x-amz-target-sage-maker-describe-notebook-instance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-145
  notebook_instance_name: any
]: any -> record<NotebookInstanceArn: record, NotebookInstanceName: record, NotebookInstanceStatus: record, FailureReason: record, Url: record, InstanceType: record, SubnetId: record, SecurityGroups: record, RoleArn: record, KmsKeyId: record, NetworkInterfaceId: record, LastModifiedTime: record, CreationTime: record, NotebookInstanceLifecycleConfigName: record, DirectInternetAccess: record, VolumeSizeInGB: record, AcceleratorTypes: record, DefaultCodeRepository: record, AdditionalCodeRepositories: record, RootAccess: record, PlatformIdentifier: record, InstanceMetadataServiceConfiguration: record<MinimumInstanceMetadataServiceVersion: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeNotebookInstance")
  let req_body = {"NotebookInstanceName": $notebook_instance_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a description of a notebook instance lifecycle configuration. For information about notebook instance lifestyle configurations, see Step 2.1: (Optional) Customize a Notebook Instance (https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html).
#
# POST /#X-Amz-Target=SageMaker.DescribeNotebookInstanceLifecycleConfig
# operationId: DescribeNotebookInstanceLifecycleConfig
export def "x-amz-target-sage-maker-describe-notebook-instance-lifecycle-config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-146
  notebook_instance_lifecycle_config_name: any
]: any -> record<NotebookInstanceLifecycleConfigArn: record, NotebookInstanceLifecycleConfigName: record, OnCreate: record, OnStart: record, LastModifiedTime: record, CreationTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeNotebookInstanceLifecycleConfig")
  let req_body = {"NotebookInstanceLifecycleConfigName": $notebook_instance_lifecycle_config_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes the details of a pipeline.
#
# POST /#X-Amz-Target=SageMaker.DescribePipeline
# operationId: DescribePipeline
export def "x-amz-target-sage-maker-describe-pipeline get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-147
  pipeline_name: any
]: any -> record<PipelineArn: record, PipelineName: record, PipelineDisplayName: record, PipelineDefinition: record, PipelineDescription: record, RoleArn: record, PipelineStatus: record, CreationTime: record, LastModifiedTime: record, LastRunTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, ParallelismConfiguration: record<MaxParallelExecutionSteps: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribePipeline")
  let req_body = {"PipelineName": $pipeline_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes the details of an execution's pipeline definition.
#
# POST /#X-Amz-Target=SageMaker.DescribePipelineDefinitionForExecution
# operationId: DescribePipelineDefinitionForExecution
export def "x-amz-target-sage-maker-describe-pipeline-definition-for-execution get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-148
  pipeline_execution_arn: any
]: any -> record<PipelineDefinition: record, CreationTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribePipelineDefinitionForExecution")
  let req_body = {"PipelineExecutionArn": $pipeline_execution_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes the details of a pipeline execution.
#
# POST /#X-Amz-Target=SageMaker.DescribePipelineExecution
# operationId: DescribePipelineExecution
export def "x-amz-target-sage-maker-describe-pipeline-execution get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-149
  pipeline_execution_arn: any
]: any -> record<PipelineArn: record, PipelineExecutionArn: record, PipelineExecutionDisplayName: record, PipelineExecutionStatus: record, PipelineExecutionDescription: record, PipelineExperimentConfig: record<ExperimentName: record, TrialName: record>, FailureReason: record, CreationTime: record, LastModifiedTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, ParallelismConfiguration: record<MaxParallelExecutionSteps: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribePipelineExecution")
  let req_body = {"PipelineExecutionArn": $pipeline_execution_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a description of a processing job.
#
# POST /#X-Amz-Target=SageMaker.DescribeProcessingJob
# operationId: DescribeProcessingJob
export def "x-amz-target-sage-maker-describe-processing-job get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-150
  processing_job_name: any
]: any -> record<ProcessingInputs: record, ProcessingOutputConfig: record<Outputs: record, KmsKeyId: record>, ProcessingJobName: record, ProcessingResources: record<ClusterConfig: record<InstanceCount: record, InstanceType: record, VolumeSizeInGB: record, VolumeKmsKeyId: record>>, StoppingCondition: record<MaxRuntimeInSeconds: record>, AppSpecification: record<ImageUri: record, ContainerEntrypoint: record, ContainerArguments: record>, Environment: record, NetworkConfig: record<EnableInterContainerTrafficEncryption: record, EnableNetworkIsolation: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>>, RoleArn: record, ExperimentConfig: record<ExperimentName: record, TrialName: record, TrialComponentDisplayName: record, RunName: record>, ProcessingJobArn: record, ProcessingJobStatus: record, ExitMessage: record, FailureReason: record, ProcessingEndTime: record, ProcessingStartTime: record, LastModifiedTime: record, CreationTime: record, MonitoringScheduleArn: record, AutoMLJobArn: record, TrainingJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeProcessingJob")
  let req_body = {"ProcessingJobName": $processing_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes the details of a project.
#
# POST /#X-Amz-Target=SageMaker.DescribeProject
# operationId: DescribeProject
export def "x-amz-target-sage-maker-describe-project get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-151
  project_name: any
]: any -> record<ProjectArn: record, ProjectName: record, ProjectId: record, ProjectDescription: record, ServiceCatalogProvisioningDetails: record<ProductId: record, ProvisioningArtifactId: record, PathId: record, ProvisioningParameters: record>, ServiceCatalogProvisionedProductDetails: record<ProvisionedProductId: record, ProvisionedProductStatusMessage: record>, ProjectStatus: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, CreationTime: record, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeProject")
  let req_body = {"ProjectName": $project_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes the space.
#
# POST /#X-Amz-Target=SageMaker.DescribeSpace
# operationId: DescribeSpace
export def "x-amz-target-sage-maker-describe-space get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-152
  domain_id: any
  space_name: any
]: any -> record<DomainId: record, SpaceArn: record, SpaceName: record, HomeEfsFileSystemUid: record, Status: record, LastModifiedTime: record, CreationTime: record, FailureReason: record, SpaceSettings: record<JupyterServerAppSettings: record<DefaultResourceSpec: record, LifecycleConfigArns: record, CodeRepositories: record>, KernelGatewayAppSettings: record<DefaultResourceSpec: record, CustomImages: record, LifecycleConfigArns: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeSpace")
  let req_body = {"DomainId": $domain_id, "SpaceName": $space_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes the Studio Lifecycle Configuration.
#
# POST /#X-Amz-Target=SageMaker.DescribeStudioLifecycleConfig
# operationId: DescribeStudioLifecycleConfig
export def "x-amz-target-sage-maker-describe-studio-lifecycle-config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-153
  studio_lifecycle_config_name: any
]: any -> record<StudioLifecycleConfigArn: record, StudioLifecycleConfigName: record, CreationTime: record, LastModifiedTime: record, StudioLifecycleConfigContent: record, StudioLifecycleConfigAppType: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeStudioLifecycleConfig")
  let req_body = {"StudioLifecycleConfigName": $studio_lifecycle_config_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the Amazon Web Services Marketplace.
#
# POST /#X-Amz-Target=SageMaker.DescribeSubscribedWorkteam
# operationId: DescribeSubscribedWorkteam
export def "x-amz-target-sage-maker-describe-subscribed-workteam get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-154
  workteam_arn: any
]: any -> record<SubscribedWorkteam: record<WorkteamArn: record, MarketplaceTitle: record, SellerName: record, MarketplaceDescription: record, ListingId: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeSubscribedWorkteam")
  let req_body = {"WorkteamArn": $workteam_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns information about a training job. Some of the attributes below only appear if the training job successfully starts. If the training job fails, TrainingJobStatus is Failed and, depending on the FailureReason, attributes like TrainingStartTime, TrainingTimeInSeconds, TrainingEndTime, and BillableTimeInSeconds may not be present in the response.
#
# POST /#X-Amz-Target=SageMaker.DescribeTrainingJob
# operationId: DescribeTrainingJob
export def "x-amz-target-sage-maker-describe-training-job get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-155
  training_job_name: any
]: any -> record<TrainingJobName: record, TrainingJobArn: record, TuningJobArn: record, LabelingJobArn: record, AutoMLJobArn: record, ModelArtifacts: record<S3ModelArtifacts: record>, TrainingJobStatus: record, SecondaryStatus: record, FailureReason: record, HyperParameters: record, AlgorithmSpecification: record<TrainingImage: record, AlgorithmName: record, TrainingInputMode: string, MetricDefinitions: record, EnableSageMakerMetricsTimeSeries: record, ContainerEntrypoint: record, ContainerArguments: record, TrainingImageConfig: record<TrainingRepositoryAccessMode: record, TrainingRepositoryAuthConfig: record>>, RoleArn: record, InputDataConfig: record, OutputDataConfig: record<KmsKeyId: record, S3OutputPath: record>, ResourceConfig: record<InstanceType: record, InstanceCount: record, VolumeSizeInGB: record, VolumeKmsKeyId: record, InstanceGroups: record, KeepAlivePeriodInSeconds: record>, VpcConfig: record<SecurityGroupIds: record, Subnets: record>, StoppingCondition: record<MaxRuntimeInSeconds: record, MaxWaitTimeInSeconds: record>, CreationTime: record, TrainingStartTime: record, TrainingEndTime: record, LastModifiedTime: record, SecondaryStatusTransitions: record, FinalMetricDataList: record, EnableNetworkIsolation: record, EnableInterContainerTrafficEncryption: record, EnableManagedSpotTraining: record, CheckpointConfig: record<S3Uri: record, LocalPath: record>, TrainingTimeInSeconds: record, BillableTimeInSeconds: record, DebugHookConfig: record<LocalPath: record, S3OutputPath: record, HookParameters: record, CollectionConfigurations: record>, ExperimentConfig: record<ExperimentName: record, TrialName: record, TrialComponentDisplayName: record, RunName: record>, DebugRuleConfigurations: record, TensorBoardOutputConfig: record<LocalPath: record, S3OutputPath: record>, DebugRuleEvaluationStatuses: record, ProfilerConfig: record<S3OutputPath: record, ProfilingIntervalInMilliseconds: record, ProfilingParameters: record, DisableProfiler: record>, ProfilerRuleConfigurations: record, ProfilerRuleEvaluationStatuses: record, ProfilingStatus: record, RetryStrategy: record<MaximumRetryAttempts: record>, Environment: record, WarmPoolStatus: record<Status: record, ResourceRetainedBillableTimeInSeconds: record, ReusedByJob: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeTrainingJob")
  let req_body = {"TrainingJobName": $training_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns information about a transform job.
#
# POST /#X-Amz-Target=SageMaker.DescribeTransformJob
# operationId: DescribeTransformJob
export def "x-amz-target-sage-maker-describe-transform-job get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-156
  transform_job_name: any
]: any -> record<TransformJobName: record, TransformJobArn: record, TransformJobStatus: record, FailureReason: record, ModelName: record, MaxConcurrentTransforms: record, ModelClientConfig: record<InvocationsTimeoutInSeconds: record, InvocationsMaxRetries: record>, MaxPayloadInMB: record, BatchStrategy: record, Environment: record, TransformInput: record<DataSource: record<S3DataSource: record>, ContentType: record, CompressionType: record, SplitType: record>, TransformOutput: record<S3OutputPath: record, Accept: record, AssembleWith: record, KmsKeyId: record>, DataCaptureConfig: record<DestinationS3Uri: record, KmsKeyId: record, GenerateInferenceId: record>, TransformResources: record<InstanceType: record, InstanceCount: record, VolumeKmsKeyId: record>, CreationTime: record, TransformStartTime: record, TransformEndTime: record, LabelingJobArn: record, AutoMLJobArn: record, DataProcessing: record<InputFilter: record, OutputFilter: record, JoinSource: record>, ExperimentConfig: record<ExperimentName: record, TrialName: record, TrialComponentDisplayName: record, RunName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeTransformJob")
  let req_body = {"TransformJobName": $transform_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Provides a list of a trial's properties.
#
# POST /#X-Amz-Target=SageMaker.DescribeTrial
# operationId: DescribeTrial
export def "x-amz-target-sage-maker-describe-trial get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-157
  trial_name: any
]: any -> record<TrialName: record, TrialArn: record, DisplayName: record, ExperimentName: record, Source: record<SourceArn: record, SourceType: record>, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, MetadataProperties: record<CommitId: record, Repository: record, GeneratedBy: record, ProjectId: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeTrial")
  let req_body = {"TrialName": $trial_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Provides a list of a trials component's properties.
#
# POST /#X-Amz-Target=SageMaker.DescribeTrialComponent
# operationId: DescribeTrialComponent
export def "x-amz-target-sage-maker-describe-trial-component get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-158
  trial_component_name: any
]: any -> record<TrialComponentName: record, TrialComponentArn: record, DisplayName: record, Source: record<SourceArn: record, SourceType: record>, Status: record<PrimaryStatus: record, Message: record>, StartTime: record, EndTime: record, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, Parameters: record, InputArtifacts: record, OutputArtifacts: record, MetadataProperties: record<CommitId: record, Repository: record, GeneratedBy: record, ProjectId: record>, Metrics: record, LineageGroupArn: record, Sources: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeTrialComponent")
  let req_body = {"TrialComponentName": $trial_component_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes a user profile. For more information, see CreateUserProfile.
#
# POST /#X-Amz-Target=SageMaker.DescribeUserProfile
# operationId: DescribeUserProfile
export def "x-amz-target-sage-maker-describe-user-profile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-159
  domain_id: any
  user_profile_name: any
]: any -> record<DomainId: record, UserProfileArn: record, UserProfileName: record, HomeEfsFileSystemUid: record, Status: record, LastModifiedTime: record, CreationTime: record, FailureReason: record, SingleSignOnUserIdentifier: record, SingleSignOnUserValue: record, UserSettings: record<ExecutionRole: record, SecurityGroups: record, SharingSettings: record<NotebookOutputOption: record, S3OutputPath: record, S3KmsKeyId: record>, JupyterServerAppSettings: record<DefaultResourceSpec: record, LifecycleConfigArns: record, CodeRepositories: record>, KernelGatewayAppSettings: record<DefaultResourceSpec: record, CustomImages: record, LifecycleConfigArns: record>, TensorBoardAppSettings: record<DefaultResourceSpec: record>, RStudioServerProAppSettings: record<AccessStatus: record, UserGroup: record>, RSessionAppSettings: record<DefaultResourceSpec: record, CustomImages: record>, CanvasAppSettings: record<TimeSeriesForecastingSettings: record, ModelRegisterSettings: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeUserProfile")
  let req_body = {"DomainId": $domain_id, "UserProfileName": $user_profile_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists private workforce information, including workforce name, Amazon Resource Name (ARN), and, if applicable, allowed IP address ranges (CIDRs (https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html)). Allowable IP address ranges are the IP addresses that workers can use to access tasks. This operation applies only to private workforces.
#
# POST /#X-Amz-Target=SageMaker.DescribeWorkforce
# operationId: DescribeWorkforce
export def "x-amz-target-sage-maker-describe-workforce get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-160
  workforce_name: any
]: any -> record<Workforce: record<WorkforceName: record, WorkforceArn: record, LastUpdatedDate: record, SourceIpConfig: record<Cidrs: record>, SubDomain: record, CognitoConfig: record<UserPool: record, ClientId: record>, OidcConfig: record<ClientId: record, Issuer: record, AuthorizationEndpoint: record, TokenEndpoint: record, UserInfoEndpoint: record, LogoutEndpoint: record, JwksUri: record>, CreateDate: record, WorkforceVpcConfig: record<VpcId: record, SecurityGroupIds: record, Subnets: record, VpcEndpointId: record>, Status: record, FailureReason: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeWorkforce")
  let req_body = {"WorkforceName": $workforce_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
#
# POST /#X-Amz-Target=SageMaker.DescribeWorkteam
# operationId: DescribeWorkteam
export def "x-amz-target-sage-maker-describe-workteam get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-161
  workteam_name: any
]: any -> record<Workteam: record<WorkteamName: record, MemberDefinitions: record, WorkteamArn: record, WorkforceArn: record, ProductListingIds: record, Description: record, SubDomain: record, CreateDate: record, LastUpdatedDate: record, NotificationConfiguration: record<NotificationTopicArn: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeWorkteam")
  let req_body = {"WorkteamName": $workteam_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disables using Service Catalog in SageMaker. Service Catalog is used to create SageMaker projects.
#
# POST /#X-Amz-Target=SageMaker.DisableSagemakerServicecatalogPortfolio
# operationId: DisableSagemakerServicecatalogPortfolio
export def "x-amz-target-sage-maker-disable-sagemaker-servicecatalog-portfolio disable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-162
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DisableSagemakerServicecatalogPortfolio")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the AssociateTrialComponent (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_AssociateTrialComponent.html) API. To get a list of the trials a component is associated with, use the Search (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_Search.html) API. Specify ExperimentTrialComponent for the Resource parameter. The list appears in the response under Results.TrialComponent.Parents.
#
# POST /#X-Amz-Target=SageMaker.DisassociateTrialComponent
# operationId: DisassociateTrialComponent
export def "x-amz-target-sage-maker-disassociate-trial-component create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-163
  trial_component_name: any
  trial_name: any
]: any -> record<TrialComponentArn: record, TrialArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DisassociateTrialComponent")
  let req_body = {"TrialComponentName": $trial_component_name, "TrialName": $trial_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Enables using Service Catalog in SageMaker. Service Catalog is used to create SageMaker projects.
#
# POST /#X-Amz-Target=SageMaker.EnableSagemakerServicecatalogPortfolio
# operationId: EnableSagemakerServicecatalogPortfolio
export def "x-amz-target-sage-maker-enable-sagemaker-servicecatalog-portfolio enable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-164
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.EnableSagemakerServicecatalogPortfolio")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Describes a fleet.
#
# POST /#X-Amz-Target=SageMaker.GetDeviceFleetReport
# operationId: GetDeviceFleetReport
export def "x-amz-target-sage-maker-get-device-fleet-report get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-165
  device_fleet_name: any
]: any -> record<DeviceFleetArn: record, DeviceFleetName: record, OutputConfig: record<S3OutputLocation: record, KmsKeyId: record, PresetDeploymentType: record, PresetDeploymentConfig: record>, Description: record, ReportGenerated: record, DeviceStats: record<ConnectedDeviceCount: record, RegisteredDeviceCount: record>, AgentVersions: record, ModelStats: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.GetDeviceFleetReport")
  let req_body = {"DeviceFleetName": $device_fleet_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# The resource policy for the lineage group.
#
# POST /#X-Amz-Target=SageMaker.GetLineageGroupPolicy
# operationId: GetLineageGroupPolicy
export def "x-amz-target-sage-maker-get-lineage-group-policy get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-166
  lineage_group_name: any
]: any -> record<LineageGroupArn: record, ResourcePolicy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.GetLineageGroupPolicy")
  let req_body = {"LineageGroupName": $lineage_group_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a resource policy that manages access for a model group. For information about resource policies, see Identity-based policies and resource-based policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_identity-vs-resource.html) in the Amazon Web Services Identity and Access Management User Guide..
#
# POST /#X-Amz-Target=SageMaker.GetModelPackageGroupPolicy
# operationId: GetModelPackageGroupPolicy
export def "x-amz-target-sage-maker-get-model-package-group-policy get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-167
  model_package_group_name: any
]: any -> record<ResourcePolicy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.GetModelPackageGroupPolicy")
  let req_body = {"ModelPackageGroupName": $model_package_group_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the status of Service Catalog in SageMaker. Service Catalog is used to create SageMaker projects.
#
# POST /#X-Amz-Target=SageMaker.GetSagemakerServicecatalogPortfolioStatus
# operationId: GetSagemakerServicecatalogPortfolioStatus
export def "x-amz-target-sage-maker-get-sagemaker-servicecatalog-portfolio-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-168
  --body: record
]: any -> record<Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.GetSagemakerServicecatalogPortfolioStatus")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# An auto-complete API for the search functionality in the SageMaker console. It returns suggestions of possible matches for the property name to use in Search queries. Provides suggestions for HyperParameters, Tags, and Metrics.
#
# POST /#X-Amz-Target=SageMaker.GetSearchSuggestions
# operationId: GetSearchSuggestions
export def "x-amz-target-sage-maker-get-search-suggestions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-169
  resource: any
  --suggestion-query: any
]: any -> record<PropertyNameSuggestions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.GetSearchSuggestions")
  let req_body = {"Resource": $resource, "SuggestionQuery": $suggestion_query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Import hub content. Hub APIs are only callable through SageMaker Studio.
#
# POST /#X-Amz-Target=SageMaker.ImportHubContent
# operationId: ImportHubContent
export def "x-amz-target-sage-maker-import-hub-content import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-170
  hub_content_name: any
  --hub-content-version: any
  hub_content_type: any
  document_schema_version: any
  hub_name: any
  --hub-content-display-name: any
  --hub-content-description: any
  --hub-content-markdown: any
  hub_content_document: any
  --hub-content-search-keywords: any
  --tags: any
]: any -> record<HubArn: record, HubContentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ImportHubContent")
  let req_body = {"HubContentName": $hub_content_name, "HubContentVersion": $hub_content_version, "HubContentType": $hub_content_type, "DocumentSchemaVersion": $document_schema_version, "HubName": $hub_name, "HubContentDisplayName": $hub_content_display_name, "HubContentDescription": $hub_content_description, "HubContentMarkdown": $hub_content_markdown, "HubContentDocument": $hub_content_document, "HubContentSearchKeywords": $hub_content_search_keywords, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the actions in your account and their properties.
#
# POST /#X-Amz-Target=SageMaker.ListActions
# operationId: ListActions
export def "x-amz-target-sage-maker-list-actions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-171
  --source-uri: any
  --action-type: any
  --created-after: any
  --created-before: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<ActionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListActions" $qp)
  let req_body = {"SourceUri": $source_uri, "ActionType": $action_type, "CreatedAfter": $created_after, "CreatedBefore": $created_before, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the machine learning algorithms that have been created.
#
# POST /#X-Amz-Target=SageMaker.ListAlgorithms
# operationId: ListAlgorithms
export def "x-amz-target-sage-maker-list-algorithms list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-172
  --creation-time-after: any
  --creation-time-before: any
  --max-results: any
  --name-contains: any
  --next-token: any
  --sort-by: any
  --sort-order: any
]: any -> record<AlgorithmSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListAlgorithms" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "MaxResults": $max_results, "NameContains": $name_contains, "NextToken": $next_token, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the aliases of a specified image or image version.
#
# POST /#X-Amz-Target=SageMaker.ListAliases
# operationId: ListAliases
export def "x-amz-target-sage-maker-list-aliases list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-173
  image_name: any
  --alias: any
  --version: any
  --max-results: any
  --next-token: any
]: any -> record<SageMakerImageVersionAliases: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListAliases" $qp)
  let req_body = {"ImageName": $image_name, "Alias": $alias, "Version": $version, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the AppImageConfigs in your account and their properties. The list can be filtered by creation time or modified time, and whether the AppImageConfig name contains a specified string.
#
# POST /#X-Amz-Target=SageMaker.ListAppImageConfigs
# operationId: ListAppImageConfigs
export def "x-amz-target-sage-maker-list-app-image-configs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-174
  --max-results: any
  --next-token: any
  --name-contains: any
  --creation-time-before: any
  --creation-time-after: any
  --modified-time-before: any
  --modified-time-after: any
  --sort-by: any
  --sort-order: any
]: any -> record<NextToken: record, AppImageConfigs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListAppImageConfigs" $qp)
  let req_body = {"MaxResults": $max_results, "NextToken": $next_token, "NameContains": $name_contains, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after, "ModifiedTimeBefore": $modified_time_before, "ModifiedTimeAfter": $modified_time_after, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists apps.
#
# POST /#X-Amz-Target=SageMaker.ListApps
# operationId: ListApps
export def "x-amz-target-sage-maker-list-apps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-175
  --next-token: any
  --max-results: any
  --sort-order: any
  --sort-by: any
  --domain-id-equals: any
  --user-profile-name-equals: any
  --space-name-equals: any
]: any -> record<Apps: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListApps" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results, "SortOrder": $sort_order, "SortBy": $sort_by, "DomainIdEquals": $domain_id_equals, "UserProfileNameEquals": $user_profile_name_equals, "SpaceNameEquals": $space_name_equals} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the artifacts in your account and their properties.
#
# POST /#X-Amz-Target=SageMaker.ListArtifacts
# operationId: ListArtifacts
export def "x-amz-target-sage-maker-list-artifacts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-176
  --source-uri: any
  --artifact-type: any
  --created-after: any
  --created-before: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<ArtifactSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListArtifacts" $qp)
  let req_body = {"SourceUri": $source_uri, "ArtifactType": $artifact_type, "CreatedAfter": $created_after, "CreatedBefore": $created_before, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the associations in your account and their properties.
#
# POST /#X-Amz-Target=SageMaker.ListAssociations
# operationId: ListAssociations
export def "x-amz-target-sage-maker-list-associations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-177
  --source-arn: any
  --destination-arn: any
  --source-type: any
  --destination-type: any
  --association-type: any
  --created-after: any
  --created-before: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<AssociationSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListAssociations" $qp)
  let req_body = {"SourceArn": $source_arn, "DestinationArn": $destination_arn, "SourceType": $source_type, "DestinationType": $destination_type, "AssociationType": $association_type, "CreatedAfter": $created_after, "CreatedBefore": $created_before, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Request a list of jobs.
#
# POST /#X-Amz-Target=SageMaker.ListAutoMLJobs
# operationId: ListAutoMLJobs
export def "x-amz-target-sage-maker-list-auto-ml-jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-178
  --creation-time-after: any
  --creation-time-before: any
  --last-modified-time-after: any
  --last-modified-time-before: any
  --name-contains: any
  --status-equals: any
  --sort-order: any
  --sort-by: any
  --max-results: any
  --next-token: any
]: any -> record<AutoMLJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListAutoMLJobs" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "NameContains": $name_contains, "StatusEquals": $status_equals, "SortOrder": $sort_order, "SortBy": $sort_by, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the candidates created for the job.
#
# POST /#X-Amz-Target=SageMaker.ListCandidatesForAutoMLJob
# operationId: ListCandidatesForAutoMLJob
export def "x-amz-target-sage-maker-list-candidates-for-auto-ml-job list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-179
  auto_ml_job_name: any
  --status-equals: any
  --candidate-name-equals: any
  --sort-order: any
  --sort-by: any
  --max-results: any
  --next-token: any
]: any -> record<Candidates: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListCandidatesForAutoMLJob" $qp)
  let req_body = {"AutoMLJobName": $auto_ml_job_name, "StatusEquals": $status_equals, "CandidateNameEquals": $candidate_name_equals, "SortOrder": $sort_order, "SortBy": $sort_by, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of the Git repositories in your account.
#
# POST /#X-Amz-Target=SageMaker.ListCodeRepositories
# operationId: ListCodeRepositories
export def "x-amz-target-sage-maker-list-code-repositories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-180
  --creation-time-after: any
  --creation-time-before: any
  --last-modified-time-after: any
  --last-modified-time-before: any
  --max-results: any
  --name-contains: any
  --next-token: any
  --sort-by: any
  --sort-order: any
]: any -> record<CodeRepositorySummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListCodeRepositories" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "MaxResults": $max_results, "NameContains": $name_contains, "NextToken": $next_token, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists model compilation jobs that satisfy various filters. To create a model compilation job, use CreateCompilationJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateCompilationJob.html). To get information about a particular model compilation job you have created, use DescribeCompilationJob (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeCompilationJob.html).
#
# POST /#X-Amz-Target=SageMaker.ListCompilationJobs
# operationId: ListCompilationJobs
export def "x-amz-target-sage-maker-list-compilation-jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-181
  --next-token: any
  --max-results: any
  --creation-time-after: any
  --creation-time-before: any
  --last-modified-time-after: any
  --last-modified-time-before: any
  --name-contains: any
  --status-equals: any
  --sort-by: any
  --sort-order: any
]: any -> record<CompilationJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListCompilationJobs" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results, "CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "NameContains": $name_contains, "StatusEquals": $status_equals, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the contexts in your account and their properties.
#
# POST /#X-Amz-Target=SageMaker.ListContexts
# operationId: ListContexts
export def "x-amz-target-sage-maker-list-contexts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-182
  --source-uri: any
  --context-type: any
  --created-after: any
  --created-before: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<ContextSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListContexts" $qp)
  let req_body = {"SourceUri": $source_uri, "ContextType": $context_type, "CreatedAfter": $created_after, "CreatedBefore": $created_before, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the data quality job definitions in your account.
#
# POST /#X-Amz-Target=SageMaker.ListDataQualityJobDefinitions
# operationId: ListDataQualityJobDefinitions
export def "x-amz-target-sage-maker-list-data-quality-job-definitions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-183
  --endpoint-name: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
  --name-contains: any
  --creation-time-before: any
  --creation-time-after: any
]: any -> record<JobDefinitionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListDataQualityJobDefinitions" $qp)
  let req_body = {"EndpointName": $endpoint_name, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results, "NameContains": $name_contains, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a list of devices in the fleet.
#
# POST /#X-Amz-Target=SageMaker.ListDeviceFleets
# operationId: ListDeviceFleets
export def "x-amz-target-sage-maker-list-device-fleets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-184
  --next-token: any
  --max-results: any
  --creation-time-after: any
  --creation-time-before: any
  --last-modified-time-after: any
  --last-modified-time-before: any
  --name-contains: any
  --sort-by: any
  --sort-order: any
]: any -> record<DeviceFleetSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListDeviceFleets" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results, "CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "NameContains": $name_contains, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# A list of devices.
#
# POST /#X-Amz-Target=SageMaker.ListDevices
# operationId: ListDevices
export def "x-amz-target-sage-maker-list-devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-185
  --next-token: any
  --max-results: any
  --latest-heartbeat-after: any
  --model-name: any
  --device-fleet-name: any
]: any -> record<DeviceSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListDevices" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results, "LatestHeartbeatAfter": $latest_heartbeat_after, "ModelName": $model_name, "DeviceFleetName": $device_fleet_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the domains.
#
# POST /#X-Amz-Target=SageMaker.ListDomains
# operationId: ListDomains
export def "x-amz-target-sage-maker-list-domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-186
  --next-token: any
  --max-results: any
]: any -> record<Domains: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListDomains" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all edge deployment plans.
#
# POST /#X-Amz-Target=SageMaker.ListEdgeDeploymentPlans
# operationId: ListEdgeDeploymentPlans
export def "x-amz-target-sage-maker-list-edge-deployment-plans list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-187
  --next-token: any
  --max-results: any
  --creation-time-after: any
  --creation-time-before: any
  --last-modified-time-after: any
  --last-modified-time-before: any
  --name-contains: any
  --device-fleet-name-contains: any
  --sort-by: any
  --sort-order: any
]: any -> record<EdgeDeploymentPlanSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListEdgeDeploymentPlans" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results, "CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "NameContains": $name_contains, "DeviceFleetNameContains": $device_fleet_name_contains, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a list of edge packaging jobs.
#
# POST /#X-Amz-Target=SageMaker.ListEdgePackagingJobs
# operationId: ListEdgePackagingJobs
export def "x-amz-target-sage-maker-list-edge-packaging-jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-188
  --next-token: any
  --max-results: any
  --creation-time-after: any
  --creation-time-before: any
  --last-modified-time-after: any
  --last-modified-time-before: any
  --name-contains: any
  --model-name-contains: any
  --status-equals: any
  --sort-by: any
  --sort-order: any
]: any -> record<EdgePackagingJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListEdgePackagingJobs" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results, "CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "NameContains": $name_contains, "ModelNameContains": $model_name_contains, "StatusEquals": $status_equals, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists endpoint configurations.
#
# POST /#X-Amz-Target=SageMaker.ListEndpointConfigs
# operationId: ListEndpointConfigs
export def "x-amz-target-sage-maker-list-endpoint-configs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-189
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
  --name-contains: any
  --creation-time-before: any
  --creation-time-after: any
]: any -> record<EndpointConfigs: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListEndpointConfigs" $qp)
  let req_body = {"SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results, "NameContains": $name_contains, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists endpoints.
#
# POST /#X-Amz-Target=SageMaker.ListEndpoints
# operationId: ListEndpoints
export def "x-amz-target-sage-maker-list-endpoints list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-190
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
  --name-contains: any
  --creation-time-before: any
  --creation-time-after: any
  --last-modified-time-before: any
  --last-modified-time-after: any
  --status-equals: any
]: any -> record<Endpoints: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListEndpoints" $qp)
  let req_body = {"SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results, "NameContains": $name_contains, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "StatusEquals": $status_equals} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
#
# POST /#X-Amz-Target=SageMaker.ListExperiments
# operationId: ListExperiments
export def "x-amz-target-sage-maker-list-experiments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-191
  --created-after: any
  --created-before: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<ExperimentSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListExperiments" $qp)
  let req_body = {"CreatedAfter": $created_after, "CreatedBefore": $created_before, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List FeatureGroups based on given filter and order.
#
# POST /#X-Amz-Target=SageMaker.ListFeatureGroups
# operationId: ListFeatureGroups
export def "x-amz-target-sage-maker-list-feature-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-192
  --name-contains: any
  --feature-group-status-equals: any
  --offline-store-status-equals: any
  --creation-time-after: any
  --creation-time-before: any
  --sort-order: any
  --sort-by: any
  --max-results: any
  --next-token: any
]: any -> record<FeatureGroupSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListFeatureGroups" $qp)
  let req_body = {"NameContains": $name_contains, "FeatureGroupStatusEquals": $feature_group_status_equals, "OfflineStoreStatusEquals": $offline_store_status_equals, "CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "SortOrder": $sort_order, "SortBy": $sort_by, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns information about the flow definitions in your account.
#
# POST /#X-Amz-Target=SageMaker.ListFlowDefinitions
# operationId: ListFlowDefinitions
export def "x-amz-target-sage-maker-list-flow-definitions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-193
  --creation-time-after: any
  --creation-time-before: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<FlowDefinitionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListFlowDefinitions" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List hub content versions. Hub APIs are only callable through SageMaker Studio.
#
# POST /#X-Amz-Target=SageMaker.ListHubContentVersions
# operationId: ListHubContentVersions
export def "x-amz-target-sage-maker-list-hub-content-versions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-194
  hub_name: any
  hub_content_type: any
  hub_content_name: any
  --min-version: any
  --max-schema-version: any
  --creation-time-before: any
  --creation-time-after: any
  --sort-by: any
  --sort-order: any
  --max-results: any
  --next-token: any
]: any -> record<HubContentSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListHubContentVersions")
  let req_body = {"HubName": $hub_name, "HubContentType": $hub_content_type, "HubContentName": $hub_content_name, "MinVersion": $min_version, "MaxSchemaVersion": $max_schema_version, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after, "SortBy": $sort_by, "SortOrder": $sort_order, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the contents of a hub. Hub APIs are only callable through SageMaker Studio.
#
# POST /#X-Amz-Target=SageMaker.ListHubContents
# operationId: ListHubContents
export def "x-amz-target-sage-maker-list-hub-contents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-195
  hub_name: any
  hub_content_type: any
  --name-contains: any
  --max-schema-version: any
  --creation-time-before: any
  --creation-time-after: any
  --sort-by: any
  --sort-order: any
  --max-results: any
  --next-token: any
]: any -> record<HubContentSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListHubContents")
  let req_body = {"HubName": $hub_name, "HubContentType": $hub_content_type, "NameContains": $name_contains, "MaxSchemaVersion": $max_schema_version, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after, "SortBy": $sort_by, "SortOrder": $sort_order, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all existing hubs. Hub APIs are only callable through SageMaker Studio.
#
# POST /#X-Amz-Target=SageMaker.ListHubs
# operationId: ListHubs
export def "x-amz-target-sage-maker-list-hubs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-196
  --name-contains: any
  --creation-time-before: any
  --creation-time-after: any
  --last-modified-time-before: any
  --last-modified-time-after: any
  --sort-by: any
  --sort-order: any
  --max-results: any
  --next-token: any
]: any -> record<HubSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListHubs")
  let req_body = {"NameContains": $name_contains, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "SortBy": $sort_by, "SortOrder": $sort_order, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns information about the human task user interfaces in your account.
#
# POST /#X-Amz-Target=SageMaker.ListHumanTaskUis
# operationId: ListHumanTaskUis
export def "x-amz-target-sage-maker-list-human-task-uis list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-197
  --creation-time-after: any
  --creation-time-before: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<HumanTaskUiSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListHumanTaskUis" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of HyperParameterTuningJobSummary (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_HyperParameterTuningJobSummary.html) objects that describe the hyperparameter tuning jobs launched in your account.
#
# POST /#X-Amz-Target=SageMaker.ListHyperParameterTuningJobs
# operationId: ListHyperParameterTuningJobs
export def "x-amz-target-sage-maker-list-hyper-parameter-tuning-jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-198
  --next-token: any
  --max-results: any
  --sort-by: any
  --sort-order: any
  --name-contains: any
  --creation-time-after: any
  --creation-time-before: any
  --last-modified-time-after: any
  --last-modified-time-before: any
  --status-equals: any
]: any -> record<HyperParameterTuningJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListHyperParameterTuningJobs" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results, "SortBy": $sort_by, "SortOrder": $sort_order, "NameContains": $name_contains, "CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "StatusEquals": $status_equals} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the versions of a specified image and their properties. The list can be filtered by creation time or modified time.
#
# POST /#X-Amz-Target=SageMaker.ListImageVersions
# operationId: ListImageVersions
export def "x-amz-target-sage-maker-list-image-versions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-199
  --creation-time-after: any
  --creation-time-before: any
  image_name: any
  --last-modified-time-after: any
  --last-modified-time-before: any
  --max-results: any
  --next-token: any
  --sort-by: any
  --sort-order: any
]: any -> record<ImageVersions: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListImageVersions" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "ImageName": $image_name, "LastModifiedTimeAfter": $last_modified_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "MaxResults": $max_results, "NextToken": $next_token, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the images in your account and their properties. The list can be filtered by creation time or modified time, and whether the image name contains a specified string.
#
# POST /#X-Amz-Target=SageMaker.ListImages
# operationId: ListImages
export def "x-amz-target-sage-maker-list-images list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-200
  --creation-time-after: any
  --creation-time-before: any
  --last-modified-time-after: any
  --last-modified-time-before: any
  --max-results: any
  --name-contains: any
  --next-token: any
  --sort-by: any
  --sort-order: any
]: any -> record<Images: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListImages" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "MaxResults": $max_results, "NameContains": $name_contains, "NextToken": $next_token, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the list of all inference experiments.
#
# POST /#X-Amz-Target=SageMaker.ListInferenceExperiments
# operationId: ListInferenceExperiments
export def "x-amz-target-sage-maker-list-inference-experiments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-201
  --name-contains: any
  --type: any
  --status-equals: any
  --creation-time-after: any
  --creation-time-before: any
  --last-modified-time-after: any
  --last-modified-time-before: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<InferenceExperiments: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListInferenceExperiments" $qp)
  let req_body = {"NameContains": $name_contains, "Type": $type, "StatusEquals": $status_equals, "CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a list of the subtasks for an Inference Recommender job. The supported subtasks are benchmarks, which evaluate the performance of your model on different instance types.
#
# POST /#X-Amz-Target=SageMaker.ListInferenceRecommendationsJobSteps
# operationId: ListInferenceRecommendationsJobSteps
export def "x-amz-target-sage-maker-list-inference-recommendations-job-steps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-202
  job_name: any
  --status: any
  --step-type: any
  --max-results: any
  --next-token: any
]: any -> record<Steps: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListInferenceRecommendationsJobSteps" $qp)
  let req_body = {"JobName": $job_name, "Status": $status, "StepType": $step_type, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists recommendation jobs that satisfy various filters.
#
# POST /#X-Amz-Target=SageMaker.ListInferenceRecommendationsJobs
# operationId: ListInferenceRecommendationsJobs
export def "x-amz-target-sage-maker-list-inference-recommendations-jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-203
  --creation-time-after: any
  --creation-time-before: any
  --last-modified-time-after: any
  --last-modified-time-before: any
  --name-contains: any
  --status-equals: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<InferenceRecommendationsJobs: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListInferenceRecommendationsJobs" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "NameContains": $name_contains, "StatusEquals": $status_equals, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of labeling jobs.
#
# POST /#X-Amz-Target=SageMaker.ListLabelingJobs
# operationId: ListLabelingJobs
export def "x-amz-target-sage-maker-list-labeling-jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-204
  --creation-time-after: any
  --creation-time-before: any
  --last-modified-time-after: any
  --last-modified-time-before: any
  --max-results: any
  --next-token: any
  --name-contains: any
  --sort-by: any
  --sort-order: any
  --status-equals: any
]: any -> record<LabelingJobSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListLabelingJobs" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "MaxResults": $max_results, "NextToken": $next_token, "NameContains": $name_contains, "SortBy": $sort_by, "SortOrder": $sort_order, "StatusEquals": $status_equals} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of labeling jobs assigned to a specified work team.
#
# POST /#X-Amz-Target=SageMaker.ListLabelingJobsForWorkteam
# operationId: ListLabelingJobsForWorkteam
export def "x-amz-target-sage-maker-list-labeling-jobs-for-workteam list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-205
  workteam_arn: any
  --max-results: any
  --next-token: any
  --creation-time-after: any
  --creation-time-before: any
  --job-reference-code-contains: any
  --sort-by: any
  --sort-order: any
]: any -> record<LabelingJobSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListLabelingJobsForWorkteam" $qp)
  let req_body = {"WorkteamArn": $workteam_arn, "MaxResults": $max_results, "NextToken": $next_token, "CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "JobReferenceCodeContains": $job_reference_code_contains, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# A list of lineage groups shared with your Amazon Web Services account. For more information, see Cross-Account Lineage Tracking (https://docs.aws.amazon.com/sagemaker/latest/dg/xaccount-lineage-tracking.html) in the Amazon SageMaker Developer Guide.
#
# POST /#X-Amz-Target=SageMaker.ListLineageGroups
# operationId: ListLineageGroups
export def "x-amz-target-sage-maker-list-lineage-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-206
  --created-after: any
  --created-before: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<LineageGroupSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListLineageGroups" $qp)
  let req_body = {"CreatedAfter": $created_after, "CreatedBefore": $created_before, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists model bias jobs definitions that satisfy various filters.
#
# POST /#X-Amz-Target=SageMaker.ListModelBiasJobDefinitions
# operationId: ListModelBiasJobDefinitions
export def "x-amz-target-sage-maker-list-model-bias-job-definitions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-207
  --endpoint-name: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
  --name-contains: any
  --creation-time-before: any
  --creation-time-after: any
]: any -> record<JobDefinitionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelBiasJobDefinitions" $qp)
  let req_body = {"EndpointName": $endpoint_name, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results, "NameContains": $name_contains, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List the export jobs for the Amazon SageMaker Model Card.
#
# POST /#X-Amz-Target=SageMaker.ListModelCardExportJobs
# operationId: ListModelCardExportJobs
export def "x-amz-target-sage-maker-list-model-card-export-jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-208
  model_card_name: any
  --model-card-version: any
  --creation-time-after: any
  --creation-time-before: any
  --model-card-export-job-name-contains: any
  --status-equals: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<ModelCardExportJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelCardExportJobs" $qp)
  let req_body = {"ModelCardName": $model_card_name, "ModelCardVersion": $model_card_version, "CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "ModelCardExportJobNameContains": $model_card_export_job_name_contains, "StatusEquals": $status_equals, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List existing versions of an Amazon SageMaker Model Card.
#
# POST /#X-Amz-Target=SageMaker.ListModelCardVersions
# operationId: ListModelCardVersions
export def "x-amz-target-sage-maker-list-model-card-versions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-209
  --creation-time-after: any
  --creation-time-before: any
  --max-results: any
  model_card_name: any
  --model-card-status: any
  --next-token: any
  --sort-by: any
  --sort-order: any
]: any -> record<ModelCardVersionSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelCardVersions" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "MaxResults": $max_results, "ModelCardName": $model_card_name, "ModelCardStatus": $model_card_status, "NextToken": $next_token, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List existing model cards.
#
# POST /#X-Amz-Target=SageMaker.ListModelCards
# operationId: ListModelCards
export def "x-amz-target-sage-maker-list-model-cards list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-210
  --creation-time-after: any
  --creation-time-before: any
  --max-results: any
  --name-contains: any
  --model-card-status: any
  --next-token: any
  --sort-by: any
  --sort-order: any
]: any -> record<ModelCardSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelCards" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "MaxResults": $max_results, "NameContains": $name_contains, "ModelCardStatus": $model_card_status, "NextToken": $next_token, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists model explainability job definitions that satisfy various filters.
#
# POST /#X-Amz-Target=SageMaker.ListModelExplainabilityJobDefinitions
# operationId: ListModelExplainabilityJobDefinitions
export def "x-amz-target-sage-maker-list-model-explainability-job-definitions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-211
  --endpoint-name: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
  --name-contains: any
  --creation-time-before: any
  --creation-time-after: any
]: any -> record<JobDefinitionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelExplainabilityJobDefinitions" $qp)
  let req_body = {"EndpointName": $endpoint_name, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results, "NameContains": $name_contains, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the domain, framework, task, and model name of standard machine learning models found in common model zoos.
#
# POST /#X-Amz-Target=SageMaker.ListModelMetadata
# operationId: ListModelMetadata
export def "x-amz-target-sage-maker-list-model-metadata list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-212
  --search-expression: any
  --next-token: any
  --max-results: any
]: any -> record<ModelMetadataSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelMetadata" $qp)
  let req_body = {"SearchExpression": $search_expression, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of the model groups in your Amazon Web Services account.
#
# POST /#X-Amz-Target=SageMaker.ListModelPackageGroups
# operationId: ListModelPackageGroups
export def "x-amz-target-sage-maker-list-model-package-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-213
  --creation-time-after: any
  --creation-time-before: any
  --max-results: any
  --name-contains: any
  --next-token: any
  --sort-by: any
  --sort-order: any
]: any -> record<ModelPackageGroupSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelPackageGroups" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "MaxResults": $max_results, "NameContains": $name_contains, "NextToken": $next_token, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the model packages that have been created.
#
# POST /#X-Amz-Target=SageMaker.ListModelPackages
# operationId: ListModelPackages
export def "x-amz-target-sage-maker-list-model-packages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-214
  --creation-time-after: any
  --creation-time-before: any
  --max-results: any
  --name-contains: any
  --model-approval-status: any
  --model-package-group-name: any
  --model-package-type: any
  --next-token: any
  --sort-by: any
  --sort-order: any
]: any -> record<ModelPackageSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelPackages" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "MaxResults": $max_results, "NameContains": $name_contains, "ModelApprovalStatus": $model_approval_status, "ModelPackageGroupName": $model_package_group_name, "ModelPackageType": $model_package_type, "NextToken": $next_token, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of model quality monitoring job definitions in your account.
#
# POST /#X-Amz-Target=SageMaker.ListModelQualityJobDefinitions
# operationId: ListModelQualityJobDefinitions
export def "x-amz-target-sage-maker-list-model-quality-job-definitions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-215
  --endpoint-name: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
  --name-contains: any
  --creation-time-before: any
  --creation-time-after: any
]: any -> record<JobDefinitionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelQualityJobDefinitions" $qp)
  let req_body = {"EndpointName": $endpoint_name, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results, "NameContains": $name_contains, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists models created with the CreateModel API.
#
# POST /#X-Amz-Target=SageMaker.ListModels
# operationId: ListModels
export def "x-amz-target-sage-maker-list-models list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-216
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
  --name-contains: any
  --creation-time-before: any
  --creation-time-after: any
]: any -> record<Models: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModels" $qp)
  let req_body = {"SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results, "NameContains": $name_contains, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of past alerts in a model monitoring schedule.
#
# POST /#X-Amz-Target=SageMaker.ListMonitoringAlertHistory
# operationId: ListMonitoringAlertHistory
export def "x-amz-target-sage-maker-list-monitoring-alert-history list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-217
  --monitoring-schedule-name: any
  --monitoring-alert-name: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
  --creation-time-before: any
  --creation-time-after: any
  --status-equals: any
]: any -> record<MonitoringAlertHistory: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListMonitoringAlertHistory" $qp)
  let req_body = {"MonitoringScheduleName": $monitoring_schedule_name, "MonitoringAlertName": $monitoring_alert_name, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after, "StatusEquals": $status_equals} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the alerts for a single monitoring schedule.
#
# POST /#X-Amz-Target=SageMaker.ListMonitoringAlerts
# operationId: ListMonitoringAlerts
export def "x-amz-target-sage-maker-list-monitoring-alerts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-218
  monitoring_schedule_name: any
  --next-token: any
  --max-results: any
]: any -> record<MonitoringAlertSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListMonitoringAlerts" $qp)
  let req_body = {"MonitoringScheduleName": $monitoring_schedule_name, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns list of all monitoring job executions.
#
# POST /#X-Amz-Target=SageMaker.ListMonitoringExecutions
# operationId: ListMonitoringExecutions
export def "x-amz-target-sage-maker-list-monitoring-executions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-219
  --monitoring-schedule-name: any
  --endpoint-name: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
  --scheduled-time-before: any
  --scheduled-time-after: any
  --creation-time-before: any
  --creation-time-after: any
  --last-modified-time-before: any
  --last-modified-time-after: any
  --status-equals: any
  --monitoring-job-definition-name: any
  --monitoring-type-equals: any
]: any -> record<MonitoringExecutionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListMonitoringExecutions" $qp)
  let req_body = {"MonitoringScheduleName": $monitoring_schedule_name, "EndpointName": $endpoint_name, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results, "ScheduledTimeBefore": $scheduled_time_before, "ScheduledTimeAfter": $scheduled_time_after, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "StatusEquals": $status_equals, "MonitoringJobDefinitionName": $monitoring_job_definition_name, "MonitoringTypeEquals": $monitoring_type_equals} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns list of all monitoring schedules.
#
# POST /#X-Amz-Target=SageMaker.ListMonitoringSchedules
# operationId: ListMonitoringSchedules
export def "x-amz-target-sage-maker-list-monitoring-schedules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-220
  --endpoint-name: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
  --name-contains: any
  --creation-time-before: any
  --creation-time-after: any
  --last-modified-time-before: any
  --last-modified-time-after: any
  --status-equals: any
  --monitoring-job-definition-name: any
  --monitoring-type-equals: any
]: any -> record<MonitoringScheduleSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListMonitoringSchedules" $qp)
  let req_body = {"EndpointName": $endpoint_name, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results, "NameContains": $name_contains, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "StatusEquals": $status_equals, "MonitoringJobDefinitionName": $monitoring_job_definition_name, "MonitoringTypeEquals": $monitoring_type_equals} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists notebook instance lifestyle configurations created with the CreateNotebookInstanceLifecycleConfig (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateNotebookInstanceLifecycleConfig.html) API.
#
# POST /#X-Amz-Target=SageMaker.ListNotebookInstanceLifecycleConfigs
# operationId: ListNotebookInstanceLifecycleConfigs
export def "x-amz-target-sage-maker-list-notebook-instance-lifecycle-configs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-221
  --next-token: any
  --max-results: any
  --sort-by: any
  --sort-order: any
  --name-contains: any
  --creation-time-before: any
  --creation-time-after: any
  --last-modified-time-before: any
  --last-modified-time-after: any
]: any -> record<NextToken: record, NotebookInstanceLifecycleConfigs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListNotebookInstanceLifecycleConfigs" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results, "SortBy": $sort_by, "SortOrder": $sort_order, "NameContains": $name_contains, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "LastModifiedTimeAfter": $last_modified_time_after} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a list of the SageMaker notebook instances in the requester's account in an Amazon Web Services Region.
#
# POST /#X-Amz-Target=SageMaker.ListNotebookInstances
# operationId: ListNotebookInstances
export def "x-amz-target-sage-maker-list-notebook-instances list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-222
  --next-token: any
  --max-results: any
  --sort-by: any
  --sort-order: any
  --name-contains: any
  --creation-time-before: any
  --creation-time-after: any
  --last-modified-time-before: any
  --last-modified-time-after: any
  --status-equals: any
  --notebook-instance-lifecycle-config-name-contains: any
  --default-code-repository-contains: any
  --additional-code-repository-equals: any
]: any -> record<NextToken: record, NotebookInstances: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListNotebookInstances" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results, "SortBy": $sort_by, "SortOrder": $sort_order, "NameContains": $name_contains, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "StatusEquals": $status_equals, "NotebookInstanceLifecycleConfigNameContains": $notebook_instance_lifecycle_config_name_contains, "DefaultCodeRepositoryContains": $default_code_repository_contains, "AdditionalCodeRepositoryEquals": $additional_code_repository_equals} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of PipeLineExecutionStep objects.
#
# POST /#X-Amz-Target=SageMaker.ListPipelineExecutionSteps
# operationId: ListPipelineExecutionSteps
export def "x-amz-target-sage-maker-list-pipeline-execution-steps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-223
  --pipeline-execution-arn: any
  --next-token: any
  --max-results: any
  --sort-order: any
]: any -> record<PipelineExecutionSteps: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListPipelineExecutionSteps" $qp)
  let req_body = {"PipelineExecutionArn": $pipeline_execution_arn, "NextToken": $next_token, "MaxResults": $max_results, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of the pipeline executions.
#
# POST /#X-Amz-Target=SageMaker.ListPipelineExecutions
# operationId: ListPipelineExecutions
export def "x-amz-target-sage-maker-list-pipeline-executions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-224
  pipeline_name: any
  --created-after: any
  --created-before: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<PipelineExecutionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListPipelineExecutions" $qp)
  let req_body = {"PipelineName": $pipeline_name, "CreatedAfter": $created_after, "CreatedBefore": $created_before, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of parameters for a pipeline execution.
#
# POST /#X-Amz-Target=SageMaker.ListPipelineParametersForExecution
# operationId: ListPipelineParametersForExecution
export def "x-amz-target-sage-maker-list-pipeline-parameters-for-execution list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-225
  pipeline_execution_arn: any
  --next-token: any
  --max-results: any
]: any -> record<PipelineParameters: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListPipelineParametersForExecution" $qp)
  let req_body = {"PipelineExecutionArn": $pipeline_execution_arn, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of pipelines.
#
# POST /#X-Amz-Target=SageMaker.ListPipelines
# operationId: ListPipelines
export def "x-amz-target-sage-maker-list-pipelines list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-226
  --pipeline-name-prefix: any
  --created-after: any
  --created-before: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<PipelineSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListPipelines" $qp)
  let req_body = {"PipelineNamePrefix": $pipeline_name_prefix, "CreatedAfter": $created_after, "CreatedBefore": $created_before, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists processing jobs that satisfy various filters.
#
# POST /#X-Amz-Target=SageMaker.ListProcessingJobs
# operationId: ListProcessingJobs
export def "x-amz-target-sage-maker-list-processing-jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-227
  --creation-time-after: any
  --creation-time-before: any
  --last-modified-time-after: any
  --last-modified-time-before: any
  --name-contains: any
  --status-equals: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<ProcessingJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListProcessingJobs" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "NameContains": $name_contains, "StatusEquals": $status_equals, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of the projects in an Amazon Web Services account.
#
# POST /#X-Amz-Target=SageMaker.ListProjects
# operationId: ListProjects
export def "x-amz-target-sage-maker-list-projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-228
  --creation-time-after: any
  --creation-time-before: any
  --max-results: any
  --name-contains: any
  --next-token: any
  --sort-by: any
  --sort-order: any
]: any -> record<ProjectSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListProjects" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "MaxResults": $max_results, "NameContains": $name_contains, "NextToken": $next_token, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists spaces.
#
# POST /#X-Amz-Target=SageMaker.ListSpaces
# operationId: ListSpaces
export def "x-amz-target-sage-maker-list-spaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-229
  --next-token: any
  --max-results: any
  --sort-order: any
  --sort-by: any
  --domain-id-equals: any
  --space-name-contains: any
]: any -> record<Spaces: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListSpaces" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results, "SortOrder": $sort_order, "SortBy": $sort_by, "DomainIdEquals": $domain_id_equals, "SpaceNameContains": $space_name_contains} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists devices allocated to the stage, containing detailed device information and deployment status.
#
# POST /#X-Amz-Target=SageMaker.ListStageDevices
# operationId: ListStageDevices
export def "x-amz-target-sage-maker-list-stage-devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-230
  --next-token: any
  --max-results: any
  edge_deployment_plan_name: any
  --exclude-devices-deployed-in-other-stage: any
  stage_name: any
]: any -> record<DeviceDeploymentSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListStageDevices" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results, "EdgeDeploymentPlanName": $edge_deployment_plan_name, "ExcludeDevicesDeployedInOtherStage": $exclude_devices_deployed_in_other_stage, "StageName": $stage_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the Studio Lifecycle Configurations in your Amazon Web Services Account.
#
# POST /#X-Amz-Target=SageMaker.ListStudioLifecycleConfigs
# operationId: ListStudioLifecycleConfigs
export def "x-amz-target-sage-maker-list-studio-lifecycle-configs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-231
  --max-results: any
  --next-token: any
  --name-contains: any
  --app-type-equals: any
  --creation-time-before: any
  --creation-time-after: any
  --modified-time-before: any
  --modified-time-after: any
  --sort-by: any
  --sort-order: any
]: any -> record<NextToken: record, StudioLifecycleConfigs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListStudioLifecycleConfigs" $qp)
  let req_body = {"MaxResults": $max_results, "NextToken": $next_token, "NameContains": $name_contains, "AppTypeEquals": $app_type_equals, "CreationTimeBefore": $creation_time_before, "CreationTimeAfter": $creation_time_after, "ModifiedTimeBefore": $modified_time_before, "ModifiedTimeAfter": $modified_time_after, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of the work teams that you are subscribed to in the Amazon Web Services Marketplace. The list may be empty if no work team satisfies the filter specified in the NameContains parameter.
#
# POST /#X-Amz-Target=SageMaker.ListSubscribedWorkteams
# operationId: ListSubscribedWorkteams
export def "x-amz-target-sage-maker-list-subscribed-workteams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-232
  --name-contains: any
  --next-token: any
  --max-results: any
]: any -> record<SubscribedWorkteams: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListSubscribedWorkteams" $qp)
  let req_body = {"NameContains": $name_contains, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the tags for the specified SageMaker resource.
#
# POST /#X-Amz-Target=SageMaker.ListTags
# operationId: ListTags
export def "x-amz-target-sage-maker-list-tags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-233
  resource_arn: any
  --next-token: any
  --max-results: any
]: any -> record<Tags: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListTags" $qp)
  let req_body = {"ResourceArn": $resource_arn, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists training jobs. When StatusEquals and MaxResults are set at the same time, the MaxResults number of training jobs are first retrieved ignoring the StatusEquals parameter and then they are filtered by the StatusEquals parameter, which is returned as a response. For example, if ListTrainingJobs is invoked with the following parameters: { ... MaxResults: 100, StatusEquals: InProgress ... } First, 100 trainings jobs with any status, including those other than InProgress, are selected (sorted according to the creation time, from the most current to the oldest). Next, those with a status of InProgress are returned. You can quickly test the API using the following Amazon Web Services CLI code. aws sagemaker list-training-jobs --max-results 100 --status-equals InProgress
#
# POST /#X-Amz-Target=SageMaker.ListTrainingJobs
# operationId: ListTrainingJobs
export def "x-amz-target-sage-maker-list-training-jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-234
  --next-token: any
  --max-results: any
  --creation-time-after: any
  --creation-time-before: any
  --last-modified-time-after: any
  --last-modified-time-before: any
  --name-contains: any
  --status-equals: any
  --sort-by: any
  --sort-order: any
  --warm-pool-status-equals: any
]: any -> record<TrainingJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListTrainingJobs" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results, "CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "NameContains": $name_contains, "StatusEquals": $status_equals, "SortBy": $sort_by, "SortOrder": $sort_order, "WarmPoolStatusEquals": $warm_pool_status_equals} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of TrainingJobSummary (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_TrainingJobSummary.html) objects that describe the training jobs that a hyperparameter tuning job launched.
#
# POST /#X-Amz-Target=SageMaker.ListTrainingJobsForHyperParameterTuningJob
# operationId: ListTrainingJobsForHyperParameterTuningJob
export def "x-amz-target-sage-maker-list-training-jobs-for-hyper-parameter-tuning-job list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-235
  hyper_parameter_tuning_job_name: any
  --next-token: any
  --max-results: any
  --status-equals: any
  --sort-by: any
  --sort-order: any
]: any -> record<TrainingJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListTrainingJobsForHyperParameterTuningJob" $qp)
  let req_body = {"HyperParameterTuningJobName": $hyper_parameter_tuning_job_name, "NextToken": $next_token, "MaxResults": $max_results, "StatusEquals": $status_equals, "SortBy": $sort_by, "SortOrder": $sort_order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists transform jobs.
#
# POST /#X-Amz-Target=SageMaker.ListTransformJobs
# operationId: ListTransformJobs
export def "x-amz-target-sage-maker-list-transform-jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-236
  --creation-time-after: any
  --creation-time-before: any
  --last-modified-time-after: any
  --last-modified-time-before: any
  --name-contains: any
  --status-equals: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<TransformJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListTransformJobs" $qp)
  let req_body = {"CreationTimeAfter": $creation_time_after, "CreationTimeBefore": $creation_time_before, "LastModifiedTimeAfter": $last_modified_time_after, "LastModifiedTimeBefore": $last_modified_time_before, "NameContains": $name_contains, "StatusEquals": $status_equals, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the trial components in your account. You can sort the list by trial component name or creation time. You can filter the list to show only components that were created in a specific time range. You can also filter on one of the following: ExperimentName SourceArn TrialName
#
# POST /#X-Amz-Target=SageMaker.ListTrialComponents
# operationId: ListTrialComponents
export def "x-amz-target-sage-maker-list-trial-components list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-237
  --experiment-name: any
  --trial-name: any
  --source-arn: any
  --created-after: any
  --created-before: any
  --sort-by: any
  --sort-order: any
  --max-results: any
  --next-token: any
]: any -> record<TrialComponentSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListTrialComponents" $qp)
  let req_body = {"ExperimentName": $experiment_name, "TrialName": $trial_name, "SourceArn": $source_arn, "CreatedAfter": $created_after, "CreatedBefore": $created_before, "SortBy": $sort_by, "SortOrder": $sort_order, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. Specify a trial component name to limit the list to the trials that associated with that trial component. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
#
# POST /#X-Amz-Target=SageMaker.ListTrials
# operationId: ListTrials
export def "x-amz-target-sage-maker-list-trials list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-238
  --experiment-name: any
  --trial-component-name: any
  --created-after: any
  --created-before: any
  --sort-by: any
  --sort-order: any
  --max-results: any
  --next-token: any
]: any -> record<TrialSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListTrials" $qp)
  let req_body = {"ExperimentName": $experiment_name, "TrialComponentName": $trial_component_name, "CreatedAfter": $created_after, "CreatedBefore": $created_before, "SortBy": $sort_by, "SortOrder": $sort_order, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists user profiles.
#
# POST /#X-Amz-Target=SageMaker.ListUserProfiles
# operationId: ListUserProfiles
export def "x-amz-target-sage-maker-list-user-profiles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-239
  --next-token: any
  --max-results: any
  --sort-order: any
  --sort-by: any
  --domain-id-equals: any
  --user-profile-name-contains: any
]: any -> record<UserProfiles: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListUserProfiles" $qp)
  let req_body = {"NextToken": $next_token, "MaxResults": $max_results, "SortOrder": $sort_order, "SortBy": $sort_by, "DomainIdEquals": $domain_id_equals, "UserProfileNameContains": $user_profile_name_contains} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this operation to list all private and vendor workforces in an Amazon Web Services Region. Note that you can only have one private workforce per Amazon Web Services Region.
#
# POST /#X-Amz-Target=SageMaker.ListWorkforces
# operationId: ListWorkforces
export def "x-amz-target-sage-maker-list-workforces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-240
  --sort-by: any
  --sort-order: any
  --name-contains: any
  --next-token: any
  --max-results: any
]: any -> record<Workforces: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListWorkforces" $qp)
  let req_body = {"SortBy": $sort_by, "SortOrder": $sort_order, "NameContains": $name_contains, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of private work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the NameContains parameter.
#
# POST /#X-Amz-Target=SageMaker.ListWorkteams
# operationId: ListWorkteams
export def "x-amz-target-sage-maker-list-workteams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-241
  --sort-by: any
  --sort-order: any
  --name-contains: any
  --next-token: any
  --max-results: any
]: any -> record<Workteams: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListWorkteams" $qp)
  let req_body = {"SortBy": $sort_by, "SortOrder": $sort_order, "NameContains": $name_contains, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Adds a resouce policy to control access to a model group. For information about resoure policies, see Identity-based policies and resource-based policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_identity-vs-resource.html) in the Amazon Web Services Identity and Access Management User Guide..
#
# POST /#X-Amz-Target=SageMaker.PutModelPackageGroupPolicy
# operationId: PutModelPackageGroupPolicy
export def "x-amz-target-sage-maker-put-model-package-group-policy update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-242
  model_package_group_name: any
  resource_policy: any
]: any -> record<ModelPackageGroupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.PutModelPackageGroupPolicy")
  let req_body = {"ModelPackageGroupName": $model_package_group_name, "ResourcePolicy": $resource_policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this action to inspect your lineage and discover relationships between entities. For more information, see Querying Lineage Entities (https://docs.aws.amazon.com/sagemaker/latest/dg/querying-lineage-entities.html) in the Amazon SageMaker Developer Guide.
#
# POST /#X-Amz-Target=SageMaker.QueryLineage
# operationId: QueryLineage
export def "x-amz-target-sage-maker-query-lineage list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-243
  --start-arns: any
  --direction: any
  --include-edges: any
  --filters: any
  --max-depth: any
  --max-results: any
  --next-token: any
]: any -> record<Vertices: record, Edges: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.QueryLineage" $qp)
  let req_body = {"StartArns": $start_arns, "Direction": $direction, "IncludeEdges": $include_edges, "Filters": $filters, "MaxDepth": $max_depth, "MaxResults": $max_results, "NextToken": $next_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Register devices.
#
# POST /#X-Amz-Target=SageMaker.RegisterDevices
# operationId: RegisterDevices
export def "x-amz-target-sage-maker-register-devices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-244
  device_fleet_name: any
  devices: any
  --tags: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.RegisterDevices")
  let req_body = {"DeviceFleetName": $device_fleet_name, "Devices": $devices, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Renders the UI template so that you can preview the worker's experience.
#
# POST /#X-Amz-Target=SageMaker.RenderUiTemplate
# operationId: RenderUiTemplate
export def "x-amz-target-sage-maker-render-ui-template create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-245
  --ui-template: any
  task: any
  role_arn: any
  --human-task-ui-arn: any
]: any -> record<RenderedContent: record, Errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.RenderUiTemplate")
  let req_body = {"UiTemplate": $ui_template, "Task": $task, "RoleArn": $role_arn, "HumanTaskUiArn": $human_task_ui_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retry the execution of the pipeline.
#
# POST /#X-Amz-Target=SageMaker.RetryPipelineExecution
# operationId: RetryPipelineExecution
export def "x-amz-target-sage-maker-retry-pipeline-execution create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-246
  pipeline_execution_arn: any
  client_request_token: any
  --parallelism-configuration: any
]: any -> record<PipelineExecutionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.RetryPipelineExecution")
  let req_body = {"PipelineExecutionArn": $pipeline_execution_arn, "ClientRequestToken": $client_request_token, "ParallelismConfiguration": $parallelism_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Finds SageMaker resources that match a search query. Matching resources are returned as a list of SearchRecord objects in the response. You can sort the search results by any resource property in a ascending or descending order. You can query against the following value types: numeric, text, Boolean, and timestamp. The Search API may provide access to otherwise restricted data. See Amazon SageMaker API Permissions: Actions, Permissions, and Resources Reference (https://docs.aws.amazon.com/sagemaker/latest/dg/api-permissions-reference.html) for more information.
#
# POST /#X-Amz-Target=SageMaker.Search
# operationId: Search
export def "x-amz-target-sage-maker-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-247
  resource: any
  --search-expression: any
  --sort-by: any
  --sort-order: any
  --next-token: any
  --max-results: any
]: any -> record<Results: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.Search" $qp)
  let req_body = {"Resource": $resource, "SearchExpression": $search_expression, "SortBy": $sort_by, "SortOrder": $sort_order, "NextToken": $next_token, "MaxResults": $max_results} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Notifies the pipeline that the execution of a callback step failed, along with a message describing why. When a callback step is run, the pipeline generates a callback token and includes the token in a message sent to Amazon Simple Queue Service (Amazon SQS).
#
# POST /#X-Amz-Target=SageMaker.SendPipelineExecutionStepFailure
# operationId: SendPipelineExecutionStepFailure
export def "x-amz-target-sage-maker-send-pipeline-execution-step-failure send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-248
  callback_token: any
  --failure-reason: any
  --client-request-token: any
]: any -> record<PipelineExecutionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.SendPipelineExecutionStepFailure")
  let req_body = {"CallbackToken": $callback_token, "FailureReason": $failure_reason, "ClientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Notifies the pipeline that the execution of a callback step succeeded and provides a list of the step's output parameters. When a callback step is run, the pipeline generates a callback token and includes the token in a message sent to Amazon Simple Queue Service (Amazon SQS).
#
# POST /#X-Amz-Target=SageMaker.SendPipelineExecutionStepSuccess
# operationId: SendPipelineExecutionStepSuccess
export def "x-amz-target-sage-maker-send-pipeline-execution-step-success send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-249
  callback_token: any
  --output-parameters: any
  --client-request-token: any
]: any -> record<PipelineExecutionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.SendPipelineExecutionStepSuccess")
  let req_body = {"CallbackToken": $callback_token, "OutputParameters": $output_parameters, "ClientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts a stage in an edge deployment plan.
#
# POST /#X-Amz-Target=SageMaker.StartEdgeDeploymentStage
# operationId: StartEdgeDeploymentStage
export def "x-amz-target-sage-maker-start-edge-deployment-stage start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-250
  edge_deployment_plan_name: any
  stage_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StartEdgeDeploymentStage")
  let req_body = {"EdgeDeploymentPlanName": $edge_deployment_plan_name, "StageName": $stage_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts an inference experiment.
#
# POST /#X-Amz-Target=SageMaker.StartInferenceExperiment
# operationId: StartInferenceExperiment
export def "x-amz-target-sage-maker-start-inference-experiment start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-251
  name: any
]: any -> record<InferenceExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StartInferenceExperiment")
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts a previously stopped monitoring schedule. By default, when you successfully create a new schedule, the status of a monitoring schedule is scheduled.
#
# POST /#X-Amz-Target=SageMaker.StartMonitoringSchedule
# operationId: StartMonitoringSchedule
export def "x-amz-target-sage-maker-start-monitoring-schedule start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-252
  monitoring_schedule_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StartMonitoringSchedule")
  let req_body = {"MonitoringScheduleName": $monitoring_schedule_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, SageMaker sets the notebook instance status to InService. A notebook instance's status must be InService before you can connect to your Jupyter notebook.
#
# POST /#X-Amz-Target=SageMaker.StartNotebookInstance
# operationId: StartNotebookInstance
export def "x-amz-target-sage-maker-start-notebook-instance start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-253
  notebook_instance_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StartNotebookInstance")
  let req_body = {"NotebookInstanceName": $notebook_instance_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts a pipeline execution.
#
# POST /#X-Amz-Target=SageMaker.StartPipelineExecution
# operationId: StartPipelineExecution
export def "x-amz-target-sage-maker-start-pipeline-execution start" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-254
  pipeline_name: any
  --pipeline-execution-display-name: any
  --pipeline-parameters: any
  --pipeline-execution-description: any
  client_request_token: any
  --parallelism-configuration: any
]: any -> record<PipelineExecutionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StartPipelineExecution")
  let req_body = {"PipelineName": $pipeline_name, "PipelineExecutionDisplayName": $pipeline_execution_display_name, "PipelineParameters": $pipeline_parameters, "PipelineExecutionDescription": $pipeline_execution_description, "ClientRequestToken": $client_request_token, "ParallelismConfiguration": $parallelism_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# A method for forcing a running job to shut down.
#
# POST /#X-Amz-Target=SageMaker.StopAutoMLJob
# operationId: StopAutoMLJob
export def "x-amz-target-sage-maker-stop-auto-ml-job stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-255
  auto_ml_job_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopAutoMLJob")
  let req_body = {"AutoMLJobName": $auto_ml_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Stops a model compilation job. To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal. When it receives a StopCompilationJob request, Amazon SageMaker changes the CompilationJobStatus of the job to Stopping. After Amazon SageMaker stops the job, it sets the CompilationJobStatus to Stopped.
#
# POST /#X-Amz-Target=SageMaker.StopCompilationJob
# operationId: StopCompilationJob
export def "x-amz-target-sage-maker-stop-compilation-job stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-256
  compilation_job_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopCompilationJob")
  let req_body = {"CompilationJobName": $compilation_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Stops a stage in an edge deployment plan.
#
# POST /#X-Amz-Target=SageMaker.StopEdgeDeploymentStage
# operationId: StopEdgeDeploymentStage
export def "x-amz-target-sage-maker-stop-edge-deployment-stage stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-257
  edge_deployment_plan_name: any
  stage_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopEdgeDeploymentStage")
  let req_body = {"EdgeDeploymentPlanName": $edge_deployment_plan_name, "StageName": $stage_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Request to stop an edge packaging job.
#
# POST /#X-Amz-Target=SageMaker.StopEdgePackagingJob
# operationId: StopEdgePackagingJob
export def "x-amz-target-sage-maker-stop-edge-packaging-job stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-258
  edge_packaging_job_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopEdgePackagingJob")
  let req_body = {"EdgePackagingJobName": $edge_packaging_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched. All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the Stopped state, it releases all reserved resources for the tuning job.
#
# POST /#X-Amz-Target=SageMaker.StopHyperParameterTuningJob
# operationId: StopHyperParameterTuningJob
export def "x-amz-target-sage-maker-stop-hyper-parameter-tuning-job stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-259
  hyper_parameter_tuning_job_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopHyperParameterTuningJob")
  let req_body = {"HyperParameterTuningJobName": $hyper_parameter_tuning_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Stops an inference experiment.
#
# POST /#X-Amz-Target=SageMaker.StopInferenceExperiment
# operationId: StopInferenceExperiment
export def "x-amz-target-sage-maker-stop-inference-experiment stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-260
  name: any
  model_variant_actions: any
  --desired-model-variants: any
  --desired-state: any
  --reason: any
]: any -> record<InferenceExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopInferenceExperiment")
  let req_body = {"Name": $name, "ModelVariantActions": $model_variant_actions, "DesiredModelVariants": $desired_model_variants, "DesiredState": $desired_state, "Reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Stops an Inference Recommender job.
#
# POST /#X-Amz-Target=SageMaker.StopInferenceRecommendationsJob
# operationId: StopInferenceRecommendationsJob
export def "x-amz-target-sage-maker-stop-inference-recommendations-job stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-261
  job_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopInferenceRecommendationsJob")
  let req_body = {"JobName": $job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
#
# POST /#X-Amz-Target=SageMaker.StopLabelingJob
# operationId: StopLabelingJob
export def "x-amz-target-sage-maker-stop-labeling-job stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-262
  labeling_job_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopLabelingJob")
  let req_body = {"LabelingJobName": $labeling_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Stops a previously started monitoring schedule.
#
# POST /#X-Amz-Target=SageMaker.StopMonitoringSchedule
# operationId: StopMonitoringSchedule
export def "x-amz-target-sage-maker-stop-monitoring-schedule stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-263
  monitoring_schedule_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopMonitoringSchedule")
  let req_body = {"MonitoringScheduleName": $monitoring_schedule_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Terminates the ML compute instance. Before terminating the instance, SageMaker disconnects the ML storage volume from it. SageMaker preserves the ML storage volume. SageMaker stops charging you for the ML compute instance when you call StopNotebookInstance. To access data on the ML storage volume for a notebook instance that has been terminated, call the StartNotebookInstance API. StartNotebookInstance launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work.
#
# POST /#X-Amz-Target=SageMaker.StopNotebookInstance
# operationId: StopNotebookInstance
export def "x-amz-target-sage-maker-stop-notebook-instance stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-264
  notebook_instance_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopNotebookInstance")
  let req_body = {"NotebookInstanceName": $notebook_instance_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Stops a pipeline execution. Callback Step A pipeline execution won't stop while a callback step is running. When you call StopPipelineExecution on a pipeline execution with a running callback step, SageMaker Pipelines sends an additional Amazon SQS message to the specified SQS queue. The body of the SQS message contains a "Status" field which is set to "Stopping". You should add logic to your Amazon SQS message consumer to take any needed action (for example, resource cleanup) upon receipt of the message followed by a call to SendPipelineExecutionStepSuccess or SendPipelineExecutionStepFailure. Only when SageMaker Pipelines receives one of these calls will it stop the pipeline execution. Lambda Step A pipeline execution can't be stopped while a lambda step is running because the Lambda function invoked by the lambda step can't be stopped. If you attempt to stop the execution while the Lambda function is running, the pipeline waits for the Lambda function to finish or until the timeout is hit, whichever occurs first, and then stops. If the Lambda function finishes, the pipeline execution status is Stopped. If the timeout is hit the pipeline execution status is Failed.
#
# POST /#X-Amz-Target=SageMaker.StopPipelineExecution
# operationId: StopPipelineExecution
export def "x-amz-target-sage-maker-stop-pipeline-execution stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-265
  pipeline_execution_arn: any
  client_request_token: any
]: any -> record<PipelineExecutionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopPipelineExecution")
  let req_body = {"PipelineExecutionArn": $pipeline_execution_arn, "ClientRequestToken": $client_request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Stops a processing job.
#
# POST /#X-Amz-Target=SageMaker.StopProcessingJob
# operationId: StopProcessingJob
export def "x-amz-target-sage-maker-stop-processing-job stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-266
  processing_job_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopProcessingJob")
  let req_body = {"ProcessingJobName": $processing_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Stops a training job. To stop a job, SageMaker sends the algorithm the SIGTERM signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. When it receives a StopTrainingJob request, SageMaker changes the status of the job to Stopping. After SageMaker stops the job, it sets the status to Stopped.
#
# POST /#X-Amz-Target=SageMaker.StopTrainingJob
# operationId: StopTrainingJob
export def "x-amz-target-sage-maker-stop-training-job stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-267
  training_job_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopTrainingJob")
  let req_body = {"TrainingJobName": $training_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Stops a batch transform job. When Amazon SageMaker receives a StopTransformJob request, the status of the job changes to Stopping. After Amazon SageMaker stops the job, the status is set to Stopped. When you stop a batch transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.
#
# POST /#X-Amz-Target=SageMaker.StopTransformJob
# operationId: StopTransformJob
export def "x-amz-target-sage-maker-stop-transform-job stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-268
  transform_job_name: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopTransformJob")
  let req_body = {"TransformJobName": $transform_job_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates an action.
#
# POST /#X-Amz-Target=SageMaker.UpdateAction
# operationId: UpdateAction
export def "x-amz-target-sage-maker-update-action update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-269
  action_name: any
  --description: any
  --status: any
  --properties: any
  --properties-to-remove: any
]: any -> record<ActionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateAction")
  let req_body = {"ActionName": $action_name, "Description": $description, "Status": $status, "Properties": $properties, "PropertiesToRemove": $properties_to_remove} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the properties of an AppImageConfig.
#
# POST /#X-Amz-Target=SageMaker.UpdateAppImageConfig
# operationId: UpdateAppImageConfig
export def "x-amz-target-sage-maker-update-app-image-config update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-270
  app_image_config_name: any
  --kernel-gateway-image-config: any
]: any -> record<AppImageConfigArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateAppImageConfig")
  let req_body = {"AppImageConfigName": $app_image_config_name, "KernelGatewayImageConfig": $kernel_gateway_image_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates an artifact.
#
# POST /#X-Amz-Target=SageMaker.UpdateArtifact
# operationId: UpdateArtifact
export def "x-amz-target-sage-maker-update-artifact update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-271
  artifact_arn: any
  --artifact-name: any
  --properties: any
  --properties-to-remove: any
]: any -> record<ArtifactArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateArtifact")
  let req_body = {"ArtifactArn": $artifact_arn, "ArtifactName": $artifact_name, "Properties": $properties, "PropertiesToRemove": $properties_to_remove} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the specified Git repository with the specified values.
#
# POST /#X-Amz-Target=SageMaker.UpdateCodeRepository
# operationId: UpdateCodeRepository
export def "x-amz-target-sage-maker-update-code-repository update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-272
  code_repository_name: any
  --git-config: any
]: any -> record<CodeRepositoryArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateCodeRepository")
  let req_body = {"CodeRepositoryName": $code_repository_name, "GitConfig": $git_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates a context.
#
# POST /#X-Amz-Target=SageMaker.UpdateContext
# operationId: UpdateContext
export def "x-amz-target-sage-maker-update-context update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-273
  context_name: any
  --description: any
  --properties: any
  --properties-to-remove: any
]: any -> record<ContextArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateContext")
  let req_body = {"ContextName": $context_name, "Description": $description, "Properties": $properties, "PropertiesToRemove": $properties_to_remove} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates a fleet of devices.
#
# POST /#X-Amz-Target=SageMaker.UpdateDeviceFleet
# operationId: UpdateDeviceFleet
export def "x-amz-target-sage-maker-update-device-fleet update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-274
  device_fleet_name: any
  --role-arn: any
  --description: any
  output_config: any
  --enable-iot-role-alias: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateDeviceFleet")
  let req_body = {"DeviceFleetName": $device_fleet_name, "RoleArn": $role_arn, "Description": $description, "OutputConfig": $output_config, "EnableIotRoleAlias": $enable_iot_role_alias} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates one or more devices in a fleet.
#
# POST /#X-Amz-Target=SageMaker.UpdateDevices
# operationId: UpdateDevices
export def "x-amz-target-sage-maker-update-devices update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-275
  device_fleet_name: any
  devices: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateDevices")
  let req_body = {"DeviceFleetName": $device_fleet_name, "Devices": $devices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the default settings for new user profiles in the domain.
#
# POST /#X-Amz-Target=SageMaker.UpdateDomain
# operationId: UpdateDomain
export def "x-amz-target-sage-maker-update-domain update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-276
  domain_id: any
  --default-user-settings: any
  --domain-settings-for-update: any
  --default-space-settings: any
  --app-security-group-management: any
]: any -> record<DomainArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateDomain")
  let req_body = {"DomainId": $domain_id, "DefaultUserSettings": $default_user_settings, "DomainSettingsForUpdate": $domain_settings_for_update, "DefaultSpaceSettings": $default_space_settings, "AppSecurityGroupManagement": $app_security_group_management} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deploys the new EndpointConfig specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous EndpointConfig (there is no availability loss). When SageMaker receives the request, it sets the endpoint status to Updating. After updating the endpoint, it sets the status to InService. To check the status of an endpoint, use the DescribeEndpoint (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeEndpoint.html) API. You must not delete an EndpointConfig in use by an endpoint that is live or while the UpdateEndpoint or CreateEndpoint operations are being performed on the endpoint. To update an endpoint, you must create a new EndpointConfig. If you delete the EndpointConfig of an endpoint that is active or being created or updated you may lose visibility into the instance type the endpoint is using. The endpoint must be deleted in order to stop incurring charges.
#
# POST /#X-Amz-Target=SageMaker.UpdateEndpoint
# operationId: UpdateEndpoint
export def "x-amz-target-sage-maker-update-endpoint update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-277
  endpoint_name: any
  endpoint_config_name: any
  --retain-all-variant-properties: any
  --exclude-retained-variant-properties: any
  --deployment-config: any
  --retain-deployment-config: any
]: any -> record<EndpointArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateEndpoint")
  let req_body = {"EndpointName": $endpoint_name, "EndpointConfigName": $endpoint_config_name, "RetainAllVariantProperties": $retain_all_variant_properties, "ExcludeRetainedVariantProperties": $exclude_retained_variant_properties, "DeploymentConfig": $deployment_config, "RetainDeploymentConfig": $retain_deployment_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, SageMaker sets the endpoint status to Updating. After updating the endpoint, it sets the status to InService. To check the status of an endpoint, use the DescribeEndpoint (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeEndpoint.html) API.
#
# POST /#X-Amz-Target=SageMaker.UpdateEndpointWeightsAndCapacities
# operationId: UpdateEndpointWeightsAndCapacities
export def "x-amz-target-sage-maker-update-endpoint-weights-and-capacities update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-278
  endpoint_name: any
  desired_weights_and_capacities: any
]: any -> record<EndpointArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateEndpointWeightsAndCapacities")
  let req_body = {"EndpointName": $endpoint_name, "DesiredWeightsAndCapacities": $desired_weights_and_capacities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
#
# POST /#X-Amz-Target=SageMaker.UpdateExperiment
# operationId: UpdateExperiment
export def "x-amz-target-sage-maker-update-experiment update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-279
  experiment_name: any
  --display-name: any
  --description: any
]: any -> record<ExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateExperiment")
  let req_body = {"ExperimentName": $experiment_name, "DisplayName": $display_name, "Description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the feature group.
#
# POST /#X-Amz-Target=SageMaker.UpdateFeatureGroup
# operationId: UpdateFeatureGroup
export def "x-amz-target-sage-maker-update-feature-group update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-280
  feature_group_name: any
  --feature-additions: any
]: any -> record<FeatureGroupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateFeatureGroup")
  let req_body = {"FeatureGroupName": $feature_group_name, "FeatureAdditions": $feature_additions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the description and parameters of the feature group.
#
# POST /#X-Amz-Target=SageMaker.UpdateFeatureMetadata
# operationId: UpdateFeatureMetadata
export def "x-amz-target-sage-maker-update-feature-metadata update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-281
  feature_group_name: any
  feature_name: any
  --description: any
  --parameter-additions: any
  --parameter-removals: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateFeatureMetadata")
  let req_body = {"FeatureGroupName": $feature_group_name, "FeatureName": $feature_name, "Description": $description, "ParameterAdditions": $parameter_additions, "ParameterRemovals": $parameter_removals} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update a hub. Hub APIs are only callable through SageMaker Studio.
#
# POST /#X-Amz-Target=SageMaker.UpdateHub
# operationId: UpdateHub
export def "x-amz-target-sage-maker-update-hub update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-282
  hub_name: any
  --hub-description: any
  --hub-display-name: any
  --hub-search-keywords: any
]: any -> record<HubArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateHub")
  let req_body = {"HubName": $hub_name, "HubDescription": $hub_description, "HubDisplayName": $hub_display_name, "HubSearchKeywords": $hub_search_keywords} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the properties of a SageMaker image. To change the image's tags, use the AddTags (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_AddTags.html) and DeleteTags (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DeleteTags.html) APIs.
#
# POST /#X-Amz-Target=SageMaker.UpdateImage
# operationId: UpdateImage
export def "x-amz-target-sage-maker-update-image update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-283
  --delete-properties: any
  --description: any
  --display-name: any
  image_name: any
  --role-arn: any
]: any -> record<ImageArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateImage")
  let req_body = {"DeleteProperties": $delete_properties, "Description": $description, "DisplayName": $display_name, "ImageName": $image_name, "RoleArn": $role_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the properties of a SageMaker image version.
#
# POST /#X-Amz-Target=SageMaker.UpdateImageVersion
# operationId: UpdateImageVersion
export def "x-amz-target-sage-maker-update-image-version update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-284
  image_name: any
  --alias: any
  --version: any
  --aliases-to-add: any
  --aliases-to-delete: any
  --vendor-guidance: any
  --job-type: any
  --ml-framework: any
  --programming-lang: any
  --processor: any
  --horovod: any
  --release-notes: any
]: any -> record<ImageVersionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateImageVersion")
  let req_body = {"ImageName": $image_name, "Alias": $alias, "Version": $version, "AliasesToAdd": $aliases_to_add, "AliasesToDelete": $aliases_to_delete, "VendorGuidance": $vendor_guidance, "JobType": $job_type, "MLFramework": $ml_framework, "ProgrammingLang": $programming_lang, "Processor": $processor, "Horovod": $horovod, "ReleaseNotes": $release_notes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates an inference experiment that you created. The status of the inference experiment has to be either Created, Running. For more information on the status of an inference experiment, see DescribeInferenceExperiment (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeInferenceExperiment.html).
#
# POST /#X-Amz-Target=SageMaker.UpdateInferenceExperiment
# operationId: UpdateInferenceExperiment
export def "x-amz-target-sage-maker-update-inference-experiment update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-285
  name: any
  --schedule: any
  --description: any
  --model-variants: any
  --data-storage-config: any
  --shadow-mode-config: any
]: any -> record<InferenceExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateInferenceExperiment")
  let req_body = {"Name": $name, "Schedule": $schedule, "Description": $description, "ModelVariants": $model_variants, "DataStorageConfig": $data_storage_config, "ShadowModeConfig": $shadow_mode_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update an Amazon SageMaker Model Card. You cannot update both model card content and model card status in a single call.
#
# POST /#X-Amz-Target=SageMaker.UpdateModelCard
# operationId: UpdateModelCard
export def "x-amz-target-sage-maker-update-model-card update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-286
  model_card_name: any
  --content: any
  --model-card-status: any
]: any -> record<ModelCardArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateModelCard")
  let req_body = {"ModelCardName": $model_card_name, "Content": $content, "ModelCardStatus": $model_card_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates a versioned model.
#
# POST /#X-Amz-Target=SageMaker.UpdateModelPackage
# operationId: UpdateModelPackage
export def "x-amz-target-sage-maker-update-model-package update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-287
  model_package_arn: any
  --model-approval-status: any
  --approval-description: any
  --customer-metadata-properties: any
  --customer-metadata-properties-to-remove: any
  --additional-inference-specifications-to-add: any
]: any -> record<ModelPackageArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateModelPackage")
  let req_body = {"ModelPackageArn": $model_package_arn, "ModelApprovalStatus": $model_approval_status, "ApprovalDescription": $approval_description, "CustomerMetadataProperties": $customer_metadata_properties, "CustomerMetadataPropertiesToRemove": $customer_metadata_properties_to_remove, "AdditionalInferenceSpecificationsToAdd": $additional_inference_specifications_to_add} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update the parameters of a model monitor alert.
#
# POST /#X-Amz-Target=SageMaker.UpdateMonitoringAlert
# operationId: UpdateMonitoringAlert
export def "x-amz-target-sage-maker-update-monitoring-alert update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-288
  monitoring_schedule_name: any
  monitoring_alert_name: any
  datapoints_to_alert: any
  evaluation_period: any
]: any -> record<MonitoringScheduleArn: record, MonitoringAlertName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateMonitoringAlert")
  let req_body = {"MonitoringScheduleName": $monitoring_schedule_name, "MonitoringAlertName": $monitoring_alert_name, "DatapointsToAlert": $datapoints_to_alert, "EvaluationPeriod": $evaluation_period} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates a previously created schedule.
#
# POST /#X-Amz-Target=SageMaker.UpdateMonitoringSchedule
# operationId: UpdateMonitoringSchedule
export def "x-amz-target-sage-maker-update-monitoring-schedule update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-289
  monitoring_schedule_name: any
  monitoring_schedule_config: any
]: any -> record<MonitoringScheduleArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateMonitoringSchedule")
  let req_body = {"MonitoringScheduleName": $monitoring_schedule_name, "MonitoringScheduleConfig": $monitoring_schedule_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
#
# POST /#X-Amz-Target=SageMaker.UpdateNotebookInstance
# operationId: UpdateNotebookInstance
export def "x-amz-target-sage-maker-update-notebook-instance update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-290
  notebook_instance_name: any
  --instance-type: any
  --role-arn: any
  --lifecycle-config-name: any
  --disassociate-lifecycle-config: any
  --volume-size-in-gb: any
  --default-code-repository: any
  --additional-code-repositories: any
  --accelerator-types: any
  --disassociate-accelerator-types: any
  --disassociate-default-code-repository: any
  --disassociate-additional-code-repositories: any
  --root-access: any
  --instance-metadata-service-configuration: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateNotebookInstance")
  let req_body = {"NotebookInstanceName": $notebook_instance_name, "InstanceType": $instance_type, "RoleArn": $role_arn, "LifecycleConfigName": $lifecycle_config_name, "DisassociateLifecycleConfig": $disassociate_lifecycle_config, "VolumeSizeInGB": $volume_size_in_gb, "DefaultCodeRepository": $default_code_repository, "AdditionalCodeRepositories": $additional_code_repositories, "AcceleratorTypes": $accelerator_types, "DisassociateAcceleratorTypes": $disassociate_accelerator_types, "DisassociateDefaultCodeRepository": $disassociate_default_code_repository, "DisassociateAdditionalCodeRepositories": $disassociate_additional_code_repositories, "RootAccess": $root_access, "InstanceMetadataServiceConfiguration": $instance_metadata_service_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates a notebook instance lifecycle configuration created with the CreateNotebookInstanceLifecycleConfig (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateNotebookInstanceLifecycleConfig.html) API.
#
# POST /#X-Amz-Target=SageMaker.UpdateNotebookInstanceLifecycleConfig
# operationId: UpdateNotebookInstanceLifecycleConfig
export def "x-amz-target-sage-maker-update-notebook-instance-lifecycle-config update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-291
  notebook_instance_lifecycle_config_name: any
  --on-create: any
  --on-start: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateNotebookInstanceLifecycleConfig")
  let req_body = {"NotebookInstanceLifecycleConfigName": $notebook_instance_lifecycle_config_name, "OnCreate": $on_create, "OnStart": $on_start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates a pipeline.
#
# POST /#X-Amz-Target=SageMaker.UpdatePipeline
# operationId: UpdatePipeline
export def "x-amz-target-sage-maker-update-pipeline update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-292
  pipeline_name: any
  --pipeline-display-name: any
  --pipeline-definition: any
  --pipeline-definition-s3-location: any
  --pipeline-description: any
  --role-arn: any
  --parallelism-configuration: any
]: any -> record<PipelineArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdatePipeline")
  let req_body = {"PipelineName": $pipeline_name, "PipelineDisplayName": $pipeline_display_name, "PipelineDefinition": $pipeline_definition, "PipelineDefinitionS3Location": $pipeline_definition_s3_location, "PipelineDescription": $pipeline_description, "RoleArn": $role_arn, "ParallelismConfiguration": $parallelism_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates a pipeline execution.
#
# POST /#X-Amz-Target=SageMaker.UpdatePipelineExecution
# operationId: UpdatePipelineExecution
export def "x-amz-target-sage-maker-update-pipeline-execution update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-293
  pipeline_execution_arn: any
  --pipeline-execution-description: any
  --pipeline-execution-display-name: any
  --parallelism-configuration: any
]: any -> record<PipelineExecutionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdatePipelineExecution")
  let req_body = {"PipelineExecutionArn": $pipeline_execution_arn, "PipelineExecutionDescription": $pipeline_execution_description, "PipelineExecutionDisplayName": $pipeline_execution_display_name, "ParallelismConfiguration": $parallelism_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates a machine learning (ML) project that is created from a template that sets up an ML pipeline from training to deploying an approved model. You must not update a project that is in use. If you update the ServiceCatalogProvisioningUpdateDetails of a project that is active or being created, or updated, you may lose resources already created by the project.
#
# POST /#X-Amz-Target=SageMaker.UpdateProject
# operationId: UpdateProject
export def "x-amz-target-sage-maker-update-project update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-294
  project_name: any
  --project-description: any
  --service-catalog-provisioning-update-details: any
  --tags: any
]: any -> record<ProjectArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateProject")
  let req_body = {"ProjectName": $project_name, "ProjectDescription": $project_description, "ServiceCatalogProvisioningUpdateDetails": $service_catalog_provisioning_update_details, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the settings of a space.
#
# POST /#X-Amz-Target=SageMaker.UpdateSpace
# operationId: UpdateSpace
export def "x-amz-target-sage-maker-update-space update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-295
  domain_id: any
  space_name: any
  --space-settings: any
]: any -> record<SpaceArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateSpace")
  let req_body = {"DomainId": $domain_id, "SpaceName": $space_name, "SpaceSettings": $space_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update a model training job to request a new Debugger profiling configuration or to change warm pool retention length.
#
# POST /#X-Amz-Target=SageMaker.UpdateTrainingJob
# operationId: UpdateTrainingJob
export def "x-amz-target-sage-maker-update-training-job update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-296
  training_job_name: any
  --profiler-config: any
  --profiler-rule-configurations: any
  --resource-config: any
]: any -> record<TrainingJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateTrainingJob")
  let req_body = {"TrainingJobName": $training_job_name, "ProfilerConfig": $profiler_config, "ProfilerRuleConfigurations": $profiler_rule_configurations, "ResourceConfig": $resource_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the display name of a trial.
#
# POST /#X-Amz-Target=SageMaker.UpdateTrial
# operationId: UpdateTrial
export def "x-amz-target-sage-maker-update-trial update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-297
  trial_name: any
  --display-name: any
]: any -> record<TrialArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateTrial")
  let req_body = {"TrialName": $trial_name, "DisplayName": $display_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates one or more properties of a trial component.
#
# POST /#X-Amz-Target=SageMaker.UpdateTrialComponent
# operationId: UpdateTrialComponent
export def "x-amz-target-sage-maker-update-trial-component update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-298
  trial_component_name: any
  --display-name: any
  --status: any
  --start-time: any
  --end-time: any
  --parameters: any
  --parameters-to-remove: any
  --input-artifacts: any
  --input-artifacts-to-remove: any
  --output-artifacts: any
  --output-artifacts-to-remove: any
]: any -> record<TrialComponentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateTrialComponent")
  let req_body = {"TrialComponentName": $trial_component_name, "DisplayName": $display_name, "Status": $status, "StartTime": $start_time, "EndTime": $end_time, "Parameters": $parameters, "ParametersToRemove": $parameters_to_remove, "InputArtifacts": $input_artifacts, "InputArtifactsToRemove": $input_artifacts_to_remove, "OutputArtifacts": $output_artifacts, "OutputArtifactsToRemove": $output_artifacts_to_remove} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates a user profile.
#
# POST /#X-Amz-Target=SageMaker.UpdateUserProfile
# operationId: UpdateUserProfile
export def "x-amz-target-sage-maker-update-user-profile update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-299
  domain_id: any
  user_profile_name: any
  --user-settings: any
]: any -> record<UserProfileArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateUserProfile")
  let req_body = {"DomainId": $domain_id, "UserProfileName": $user_profile_name, "UserSettings": $user_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this operation to update your workforce. You can use this operation to require that workers use specific IP addresses to work on tasks and to update your OpenID Connect (OIDC) Identity Provider (IdP) workforce configuration. The worker portal is now supported in VPC and public internet. Use SourceIpConfig to restrict worker access to tasks to a specific range of IP addresses. You specify allowed IP addresses by creating a list of up to ten CIDRs (https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html). By default, a workforce isn't restricted to specific IP addresses. If you specify a range of IP addresses, workers who attempt to access tasks using any IP address outside the specified range are denied and get a Not Found error message on the worker portal. To restrict access to all the workers in public internet, add the SourceIpConfig CIDR value as "10.0.0.0/16". Amazon SageMaker does not support Source Ip restriction for worker portals in VPC. Use OidcConfig to update the configuration of a workforce created using your own OIDC IdP. You can only update your OIDC IdP configuration when there are no work teams associated with your workforce. You can delete work teams using the DeleteWorkteam (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DeleteWorkteam.html) operation. After restricting access to a range of IP addresses or updating your OIDC IdP configuration with this operation, you can view details about your update workforce using the DescribeWorkforce (https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeWorkforce.html) operation. This operation only applies to private workforces.
#
# POST /#X-Amz-Target=SageMaker.UpdateWorkforce
# operationId: UpdateWorkforce
export def "x-amz-target-sage-maker-update-workforce update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-300
  workforce_name: any
  --source-ip-config: any
  --oidc-config: any
  --workforce-vpc-config: any
]: any -> record<Workforce: record<WorkforceName: record, WorkforceArn: record, LastUpdatedDate: record, SourceIpConfig: record<Cidrs: record>, SubDomain: record, CognitoConfig: record<UserPool: record, ClientId: record>, OidcConfig: record<ClientId: record, Issuer: record, AuthorizationEndpoint: record, TokenEndpoint: record, UserInfoEndpoint: record, LogoutEndpoint: record, JwksUri: record>, CreateDate: record, WorkforceVpcConfig: record<VpcId: record, SecurityGroupIds: record, Subnets: record, VpcEndpointId: record>, Status: record, FailureReason: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateWorkforce")
  let req_body = {"WorkforceName": $workforce_name, "SourceIpConfig": $source_ip_config, "OidcConfig": $oidc_config, "WorkforceVpcConfig": $workforce_vpc_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates an existing work team with new member definitions or description.
#
# POST /#X-Amz-Target=SageMaker.UpdateWorkteam
# operationId: UpdateWorkteam
export def "x-amz-target-sage-maker-update-workteam update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-301
  workteam_name: any
  --member-definitions: any
  --description: any
  --notification-configuration: any
]: any -> record<Workteam: record<WorkteamName: record, MemberDefinitions: record, WorkteamArn: record, WorkforceArn: record, ProductListingIds: record, Description: record, SubDomain: record, CreateDate: record, LastUpdatedDate: record, NotificationConfiguration: record<NotificationTopicArn: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateWorkteam")
  let req_body = {"WorkteamName": $workteam_name, "MemberDefinitions": $member_definitions, "Description": $description, "NotificationConfiguration": $notification_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
