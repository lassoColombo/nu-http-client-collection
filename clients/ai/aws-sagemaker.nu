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
def X-Amz-Target-completer [] { ["SageMaker.AddAssociation"] }
def X-Amz-Target-completer-1 [] { ["SageMaker.AddTags"] }
def X-Amz-Target-completer-2 [] { ["SageMaker.AssociateTrialComponent"] }
def X-Amz-Target-completer-3 [] { ["SageMaker.BatchDescribeModelPackage"] }
def X-Amz-Target-completer-4 [] { ["SageMaker.CreateAction"] }
def X-Amz-Target-completer-5 [] { ["SageMaker.CreateAlgorithm"] }
def X-Amz-Target-completer-6 [] { ["SageMaker.CreateApp"] }
def X-Amz-Target-completer-7 [] { ["SageMaker.CreateAppImageConfig"] }
def X-Amz-Target-completer-8 [] { ["SageMaker.CreateArtifact"] }
def X-Amz-Target-completer-9 [] { ["SageMaker.CreateAutoMLJob"] }
def X-Amz-Target-completer-10 [] { ["SageMaker.CreateAutoMLJobV2"] }
def X-Amz-Target-completer-11 [] { ["SageMaker.CreateCodeRepository"] }
def X-Amz-Target-completer-12 [] { ["SageMaker.CreateCompilationJob"] }
def X-Amz-Target-completer-13 [] { ["SageMaker.CreateContext"] }
def X-Amz-Target-completer-14 [] { ["SageMaker.CreateDataQualityJobDefinition"] }
def X-Amz-Target-completer-15 [] { ["SageMaker.CreateDeviceFleet"] }
def X-Amz-Target-completer-16 [] { ["SageMaker.CreateDomain"] }
def X-Amz-Target-completer-17 [] { ["SageMaker.CreateEdgeDeploymentPlan"] }
def X-Amz-Target-completer-18 [] { ["SageMaker.CreateEdgeDeploymentStage"] }
def X-Amz-Target-completer-19 [] { ["SageMaker.CreateEdgePackagingJob"] }
def X-Amz-Target-completer-20 [] { ["SageMaker.CreateEndpoint"] }
def X-Amz-Target-completer-21 [] { ["SageMaker.CreateEndpointConfig"] }
def X-Amz-Target-completer-22 [] { ["SageMaker.CreateExperiment"] }
def X-Amz-Target-completer-23 [] { ["SageMaker.CreateFeatureGroup"] }
def X-Amz-Target-completer-24 [] { ["SageMaker.CreateFlowDefinition"] }
def X-Amz-Target-completer-25 [] { ["SageMaker.CreateHub"] }
def X-Amz-Target-completer-26 [] { ["SageMaker.CreateHumanTaskUi"] }
def X-Amz-Target-completer-27 [] { ["SageMaker.CreateHyperParameterTuningJob"] }
def X-Amz-Target-completer-28 [] { ["SageMaker.CreateImage"] }
def X-Amz-Target-completer-29 [] { ["SageMaker.CreateImageVersion"] }
def X-Amz-Target-completer-30 [] { ["SageMaker.CreateInferenceExperiment"] }
def X-Amz-Target-completer-31 [] { ["SageMaker.CreateInferenceRecommendationsJob"] }
def X-Amz-Target-completer-32 [] { ["SageMaker.CreateLabelingJob"] }
def X-Amz-Target-completer-33 [] { ["SageMaker.CreateModel"] }
def X-Amz-Target-completer-34 [] { ["SageMaker.CreateModelBiasJobDefinition"] }
def X-Amz-Target-completer-35 [] { ["SageMaker.CreateModelCard"] }
def X-Amz-Target-completer-36 [] { ["SageMaker.CreateModelCardExportJob"] }
def X-Amz-Target-completer-37 [] { ["SageMaker.CreateModelExplainabilityJobDefinition"] }
def X-Amz-Target-completer-38 [] { ["SageMaker.CreateModelPackage"] }
def X-Amz-Target-completer-39 [] { ["SageMaker.CreateModelPackageGroup"] }
def X-Amz-Target-completer-40 [] { ["SageMaker.CreateModelQualityJobDefinition"] }
def X-Amz-Target-completer-41 [] { ["SageMaker.CreateMonitoringSchedule"] }
def X-Amz-Target-completer-42 [] { ["SageMaker.CreateNotebookInstance"] }
def X-Amz-Target-completer-43 [] { ["SageMaker.CreateNotebookInstanceLifecycleConfig"] }
def X-Amz-Target-completer-44 [] { ["SageMaker.CreatePipeline"] }
def X-Amz-Target-completer-45 [] { ["SageMaker.CreatePresignedDomainUrl"] }
def X-Amz-Target-completer-46 [] { ["SageMaker.CreatePresignedNotebookInstanceUrl"] }
def X-Amz-Target-completer-47 [] { ["SageMaker.CreateProcessingJob"] }
def X-Amz-Target-completer-48 [] { ["SageMaker.CreateProject"] }
def X-Amz-Target-completer-49 [] { ["SageMaker.CreateSpace"] }
def X-Amz-Target-completer-50 [] { ["SageMaker.CreateStudioLifecycleConfig"] }
def X-Amz-Target-completer-51 [] { ["SageMaker.CreateTrainingJob"] }
def X-Amz-Target-completer-52 [] { ["SageMaker.CreateTransformJob"] }
def X-Amz-Target-completer-53 [] { ["SageMaker.CreateTrial"] }
def X-Amz-Target-completer-54 [] { ["SageMaker.CreateTrialComponent"] }
def X-Amz-Target-completer-55 [] { ["SageMaker.CreateUserProfile"] }
def X-Amz-Target-completer-56 [] { ["SageMaker.CreateWorkforce"] }
def X-Amz-Target-completer-57 [] { ["SageMaker.CreateWorkteam"] }
def X-Amz-Target-completer-58 [] { ["SageMaker.DeleteAction"] }
def X-Amz-Target-completer-59 [] { ["SageMaker.DeleteAlgorithm"] }
def X-Amz-Target-completer-60 [] { ["SageMaker.DeleteApp"] }
def X-Amz-Target-completer-61 [] { ["SageMaker.DeleteAppImageConfig"] }
def X-Amz-Target-completer-62 [] { ["SageMaker.DeleteArtifact"] }
def X-Amz-Target-completer-63 [] { ["SageMaker.DeleteAssociation"] }
def X-Amz-Target-completer-64 [] { ["SageMaker.DeleteCodeRepository"] }
def X-Amz-Target-completer-65 [] { ["SageMaker.DeleteContext"] }
def X-Amz-Target-completer-66 [] { ["SageMaker.DeleteDataQualityJobDefinition"] }
def X-Amz-Target-completer-67 [] { ["SageMaker.DeleteDeviceFleet"] }
def X-Amz-Target-completer-68 [] { ["SageMaker.DeleteDomain"] }
def X-Amz-Target-completer-69 [] { ["SageMaker.DeleteEdgeDeploymentPlan"] }
def X-Amz-Target-completer-70 [] { ["SageMaker.DeleteEdgeDeploymentStage"] }
def X-Amz-Target-completer-71 [] { ["SageMaker.DeleteEndpoint"] }
def X-Amz-Target-completer-72 [] { ["SageMaker.DeleteEndpointConfig"] }
def X-Amz-Target-completer-73 [] { ["SageMaker.DeleteExperiment"] }
def X-Amz-Target-completer-74 [] { ["SageMaker.DeleteFeatureGroup"] }
def X-Amz-Target-completer-75 [] { ["SageMaker.DeleteFlowDefinition"] }
def X-Amz-Target-completer-76 [] { ["SageMaker.DeleteHub"] }
def X-Amz-Target-completer-77 [] { ["SageMaker.DeleteHubContent"] }
def X-Amz-Target-completer-78 [] { ["SageMaker.DeleteHumanTaskUi"] }
def X-Amz-Target-completer-79 [] { ["SageMaker.DeleteImage"] }
def X-Amz-Target-completer-80 [] { ["SageMaker.DeleteImageVersion"] }
def X-Amz-Target-completer-81 [] { ["SageMaker.DeleteInferenceExperiment"] }
def X-Amz-Target-completer-82 [] { ["SageMaker.DeleteModel"] }
def X-Amz-Target-completer-83 [] { ["SageMaker.DeleteModelBiasJobDefinition"] }
def X-Amz-Target-completer-84 [] { ["SageMaker.DeleteModelCard"] }
def X-Amz-Target-completer-85 [] { ["SageMaker.DeleteModelExplainabilityJobDefinition"] }
def X-Amz-Target-completer-86 [] { ["SageMaker.DeleteModelPackage"] }
def X-Amz-Target-completer-87 [] { ["SageMaker.DeleteModelPackageGroup"] }
def X-Amz-Target-completer-88 [] { ["SageMaker.DeleteModelPackageGroupPolicy"] }
def X-Amz-Target-completer-89 [] { ["SageMaker.DeleteModelQualityJobDefinition"] }
def X-Amz-Target-completer-90 [] { ["SageMaker.DeleteMonitoringSchedule"] }
def X-Amz-Target-completer-91 [] { ["SageMaker.DeleteNotebookInstance"] }
def X-Amz-Target-completer-92 [] { ["SageMaker.DeleteNotebookInstanceLifecycleConfig"] }
def X-Amz-Target-completer-93 [] { ["SageMaker.DeletePipeline"] }
def X-Amz-Target-completer-94 [] { ["SageMaker.DeleteProject"] }
def X-Amz-Target-completer-95 [] { ["SageMaker.DeleteSpace"] }
def X-Amz-Target-completer-96 [] { ["SageMaker.DeleteStudioLifecycleConfig"] }
def X-Amz-Target-completer-97 [] { ["SageMaker.DeleteTags"] }
def X-Amz-Target-completer-98 [] { ["SageMaker.DeleteTrial"] }
def X-Amz-Target-completer-99 [] { ["SageMaker.DeleteTrialComponent"] }
def X-Amz-Target-completer-100 [] { ["SageMaker.DeleteUserProfile"] }
def X-Amz-Target-completer-101 [] { ["SageMaker.DeleteWorkforce"] }
def X-Amz-Target-completer-102 [] { ["SageMaker.DeleteWorkteam"] }
def X-Amz-Target-completer-103 [] { ["SageMaker.DeregisterDevices"] }
def X-Amz-Target-completer-104 [] { ["SageMaker.DescribeAction"] }
def X-Amz-Target-completer-105 [] { ["SageMaker.DescribeAlgorithm"] }
def X-Amz-Target-completer-106 [] { ["SageMaker.DescribeApp"] }
def X-Amz-Target-completer-107 [] { ["SageMaker.DescribeAppImageConfig"] }
def X-Amz-Target-completer-108 [] { ["SageMaker.DescribeArtifact"] }
def X-Amz-Target-completer-109 [] { ["SageMaker.DescribeAutoMLJob"] }
def X-Amz-Target-completer-110 [] { ["SageMaker.DescribeAutoMLJobV2"] }
def X-Amz-Target-completer-111 [] { ["SageMaker.DescribeCodeRepository"] }
def X-Amz-Target-completer-112 [] { ["SageMaker.DescribeCompilationJob"] }
def X-Amz-Target-completer-113 [] { ["SageMaker.DescribeContext"] }
def X-Amz-Target-completer-114 [] { ["SageMaker.DescribeDataQualityJobDefinition"] }
def X-Amz-Target-completer-115 [] { ["SageMaker.DescribeDevice"] }
def X-Amz-Target-completer-116 [] { ["SageMaker.DescribeDeviceFleet"] }
def X-Amz-Target-completer-117 [] { ["SageMaker.DescribeDomain"] }
def X-Amz-Target-completer-118 [] { ["SageMaker.DescribeEdgeDeploymentPlan"] }
def X-Amz-Target-completer-119 [] { ["SageMaker.DescribeEdgePackagingJob"] }
def X-Amz-Target-completer-120 [] { ["SageMaker.DescribeEndpoint"] }
def X-Amz-Target-completer-121 [] { ["SageMaker.DescribeEndpointConfig"] }
def X-Amz-Target-completer-122 [] { ["SageMaker.DescribeExperiment"] }
def X-Amz-Target-completer-123 [] { ["SageMaker.DescribeFeatureGroup"] }
def X-Amz-Target-completer-124 [] { ["SageMaker.DescribeFeatureMetadata"] }
def X-Amz-Target-completer-125 [] { ["SageMaker.DescribeFlowDefinition"] }
def X-Amz-Target-completer-126 [] { ["SageMaker.DescribeHub"] }
def X-Amz-Target-completer-127 [] { ["SageMaker.DescribeHubContent"] }
def X-Amz-Target-completer-128 [] { ["SageMaker.DescribeHumanTaskUi"] }
def X-Amz-Target-completer-129 [] { ["SageMaker.DescribeHyperParameterTuningJob"] }
def X-Amz-Target-completer-130 [] { ["SageMaker.DescribeImage"] }
def X-Amz-Target-completer-131 [] { ["SageMaker.DescribeImageVersion"] }
def X-Amz-Target-completer-132 [] { ["SageMaker.DescribeInferenceExperiment"] }
def X-Amz-Target-completer-133 [] { ["SageMaker.DescribeInferenceRecommendationsJob"] }
def X-Amz-Target-completer-134 [] { ["SageMaker.DescribeLabelingJob"] }
def X-Amz-Target-completer-135 [] { ["SageMaker.DescribeLineageGroup"] }
def X-Amz-Target-completer-136 [] { ["SageMaker.DescribeModel"] }
def X-Amz-Target-completer-137 [] { ["SageMaker.DescribeModelBiasJobDefinition"] }
def X-Amz-Target-completer-138 [] { ["SageMaker.DescribeModelCard"] }
def X-Amz-Target-completer-139 [] { ["SageMaker.DescribeModelCardExportJob"] }
def X-Amz-Target-completer-140 [] { ["SageMaker.DescribeModelExplainabilityJobDefinition"] }
def X-Amz-Target-completer-141 [] { ["SageMaker.DescribeModelPackage"] }
def X-Amz-Target-completer-142 [] { ["SageMaker.DescribeModelPackageGroup"] }
def X-Amz-Target-completer-143 [] { ["SageMaker.DescribeModelQualityJobDefinition"] }
def X-Amz-Target-completer-144 [] { ["SageMaker.DescribeMonitoringSchedule"] }
def X-Amz-Target-completer-145 [] { ["SageMaker.DescribeNotebookInstance"] }
def X-Amz-Target-completer-146 [] { ["SageMaker.DescribeNotebookInstanceLifecycleConfig"] }
def X-Amz-Target-completer-147 [] { ["SageMaker.DescribePipeline"] }
def X-Amz-Target-completer-148 [] { ["SageMaker.DescribePipelineDefinitionForExecution"] }
def X-Amz-Target-completer-149 [] { ["SageMaker.DescribePipelineExecution"] }
def X-Amz-Target-completer-150 [] { ["SageMaker.DescribeProcessingJob"] }
def X-Amz-Target-completer-151 [] { ["SageMaker.DescribeProject"] }
def X-Amz-Target-completer-152 [] { ["SageMaker.DescribeSpace"] }
def X-Amz-Target-completer-153 [] { ["SageMaker.DescribeStudioLifecycleConfig"] }
def X-Amz-Target-completer-154 [] { ["SageMaker.DescribeSubscribedWorkteam"] }
def X-Amz-Target-completer-155 [] { ["SageMaker.DescribeTrainingJob"] }
def X-Amz-Target-completer-156 [] { ["SageMaker.DescribeTransformJob"] }
def X-Amz-Target-completer-157 [] { ["SageMaker.DescribeTrial"] }
def X-Amz-Target-completer-158 [] { ["SageMaker.DescribeTrialComponent"] }
def X-Amz-Target-completer-159 [] { ["SageMaker.DescribeUserProfile"] }
def X-Amz-Target-completer-160 [] { ["SageMaker.DescribeWorkforce"] }
def X-Amz-Target-completer-161 [] { ["SageMaker.DescribeWorkteam"] }
def X-Amz-Target-completer-162 [] { ["SageMaker.DisableSagemakerServicecatalogPortfolio"] }
def X-Amz-Target-completer-163 [] { ["SageMaker.DisassociateTrialComponent"] }
def X-Amz-Target-completer-164 [] { ["SageMaker.EnableSagemakerServicecatalogPortfolio"] }
def X-Amz-Target-completer-165 [] { ["SageMaker.GetDeviceFleetReport"] }
def X-Amz-Target-completer-166 [] { ["SageMaker.GetLineageGroupPolicy"] }
def X-Amz-Target-completer-167 [] { ["SageMaker.GetModelPackageGroupPolicy"] }
def X-Amz-Target-completer-168 [] { ["SageMaker.GetSagemakerServicecatalogPortfolioStatus"] }
def X-Amz-Target-completer-169 [] { ["SageMaker.GetSearchSuggestions"] }
def X-Amz-Target-completer-170 [] { ["SageMaker.ImportHubContent"] }
def X-Amz-Target-completer-171 [] { ["SageMaker.ListActions"] }
def X-Amz-Target-completer-172 [] { ["SageMaker.ListAlgorithms"] }
def X-Amz-Target-completer-173 [] { ["SageMaker.ListAliases"] }
def X-Amz-Target-completer-174 [] { ["SageMaker.ListAppImageConfigs"] }
def X-Amz-Target-completer-175 [] { ["SageMaker.ListApps"] }
def X-Amz-Target-completer-176 [] { ["SageMaker.ListArtifacts"] }
def X-Amz-Target-completer-177 [] { ["SageMaker.ListAssociations"] }
def X-Amz-Target-completer-178 [] { ["SageMaker.ListAutoMLJobs"] }
def X-Amz-Target-completer-179 [] { ["SageMaker.ListCandidatesForAutoMLJob"] }
def X-Amz-Target-completer-180 [] { ["SageMaker.ListCodeRepositories"] }
def X-Amz-Target-completer-181 [] { ["SageMaker.ListCompilationJobs"] }
def X-Amz-Target-completer-182 [] { ["SageMaker.ListContexts"] }
def X-Amz-Target-completer-183 [] { ["SageMaker.ListDataQualityJobDefinitions"] }
def X-Amz-Target-completer-184 [] { ["SageMaker.ListDeviceFleets"] }
def X-Amz-Target-completer-185 [] { ["SageMaker.ListDevices"] }
def X-Amz-Target-completer-186 [] { ["SageMaker.ListDomains"] }
def X-Amz-Target-completer-187 [] { ["SageMaker.ListEdgeDeploymentPlans"] }
def X-Amz-Target-completer-188 [] { ["SageMaker.ListEdgePackagingJobs"] }
def X-Amz-Target-completer-189 [] { ["SageMaker.ListEndpointConfigs"] }
def X-Amz-Target-completer-190 [] { ["SageMaker.ListEndpoints"] }
def X-Amz-Target-completer-191 [] { ["SageMaker.ListExperiments"] }
def X-Amz-Target-completer-192 [] { ["SageMaker.ListFeatureGroups"] }
def X-Amz-Target-completer-193 [] { ["SageMaker.ListFlowDefinitions"] }
def X-Amz-Target-completer-194 [] { ["SageMaker.ListHubContentVersions"] }
def X-Amz-Target-completer-195 [] { ["SageMaker.ListHubContents"] }
def X-Amz-Target-completer-196 [] { ["SageMaker.ListHubs"] }
def X-Amz-Target-completer-197 [] { ["SageMaker.ListHumanTaskUis"] }
def X-Amz-Target-completer-198 [] { ["SageMaker.ListHyperParameterTuningJobs"] }
def X-Amz-Target-completer-199 [] { ["SageMaker.ListImageVersions"] }
def X-Amz-Target-completer-200 [] { ["SageMaker.ListImages"] }
def X-Amz-Target-completer-201 [] { ["SageMaker.ListInferenceExperiments"] }
def X-Amz-Target-completer-202 [] { ["SageMaker.ListInferenceRecommendationsJobSteps"] }
def X-Amz-Target-completer-203 [] { ["SageMaker.ListInferenceRecommendationsJobs"] }
def X-Amz-Target-completer-204 [] { ["SageMaker.ListLabelingJobs"] }
def X-Amz-Target-completer-205 [] { ["SageMaker.ListLabelingJobsForWorkteam"] }
def X-Amz-Target-completer-206 [] { ["SageMaker.ListLineageGroups"] }
def X-Amz-Target-completer-207 [] { ["SageMaker.ListModelBiasJobDefinitions"] }
def X-Amz-Target-completer-208 [] { ["SageMaker.ListModelCardExportJobs"] }
def X-Amz-Target-completer-209 [] { ["SageMaker.ListModelCardVersions"] }
def X-Amz-Target-completer-210 [] { ["SageMaker.ListModelCards"] }
def X-Amz-Target-completer-211 [] { ["SageMaker.ListModelExplainabilityJobDefinitions"] }
def X-Amz-Target-completer-212 [] { ["SageMaker.ListModelMetadata"] }
def X-Amz-Target-completer-213 [] { ["SageMaker.ListModelPackageGroups"] }
def X-Amz-Target-completer-214 [] { ["SageMaker.ListModelPackages"] }
def X-Amz-Target-completer-215 [] { ["SageMaker.ListModelQualityJobDefinitions"] }
def X-Amz-Target-completer-216 [] { ["SageMaker.ListModels"] }
def X-Amz-Target-completer-217 [] { ["SageMaker.ListMonitoringAlertHistory"] }
def X-Amz-Target-completer-218 [] { ["SageMaker.ListMonitoringAlerts"] }
def X-Amz-Target-completer-219 [] { ["SageMaker.ListMonitoringExecutions"] }
def X-Amz-Target-completer-220 [] { ["SageMaker.ListMonitoringSchedules"] }
def X-Amz-Target-completer-221 [] { ["SageMaker.ListNotebookInstanceLifecycleConfigs"] }
def X-Amz-Target-completer-222 [] { ["SageMaker.ListNotebookInstances"] }
def X-Amz-Target-completer-223 [] { ["SageMaker.ListPipelineExecutionSteps"] }
def X-Amz-Target-completer-224 [] { ["SageMaker.ListPipelineExecutions"] }
def X-Amz-Target-completer-225 [] { ["SageMaker.ListPipelineParametersForExecution"] }
def X-Amz-Target-completer-226 [] { ["SageMaker.ListPipelines"] }
def X-Amz-Target-completer-227 [] { ["SageMaker.ListProcessingJobs"] }
def X-Amz-Target-completer-228 [] { ["SageMaker.ListProjects"] }
def X-Amz-Target-completer-229 [] { ["SageMaker.ListSpaces"] }
def X-Amz-Target-completer-230 [] { ["SageMaker.ListStageDevices"] }
def X-Amz-Target-completer-231 [] { ["SageMaker.ListStudioLifecycleConfigs"] }
def X-Amz-Target-completer-232 [] { ["SageMaker.ListSubscribedWorkteams"] }
def X-Amz-Target-completer-233 [] { ["SageMaker.ListTags"] }
def X-Amz-Target-completer-234 [] { ["SageMaker.ListTrainingJobs"] }
def X-Amz-Target-completer-235 [] { ["SageMaker.ListTrainingJobsForHyperParameterTuningJob"] }
def X-Amz-Target-completer-236 [] { ["SageMaker.ListTransformJobs"] }
def X-Amz-Target-completer-237 [] { ["SageMaker.ListTrialComponents"] }
def X-Amz-Target-completer-238 [] { ["SageMaker.ListTrials"] }
def X-Amz-Target-completer-239 [] { ["SageMaker.ListUserProfiles"] }
def X-Amz-Target-completer-240 [] { ["SageMaker.ListWorkforces"] }
def X-Amz-Target-completer-241 [] { ["SageMaker.ListWorkteams"] }
def X-Amz-Target-completer-242 [] { ["SageMaker.PutModelPackageGroupPolicy"] }
def X-Amz-Target-completer-243 [] { ["SageMaker.QueryLineage"] }
def X-Amz-Target-completer-244 [] { ["SageMaker.RegisterDevices"] }
def X-Amz-Target-completer-245 [] { ["SageMaker.RenderUiTemplate"] }
def X-Amz-Target-completer-246 [] { ["SageMaker.RetryPipelineExecution"] }
def X-Amz-Target-completer-247 [] { ["SageMaker.Search"] }
def X-Amz-Target-completer-248 [] { ["SageMaker.SendPipelineExecutionStepFailure"] }
def X-Amz-Target-completer-249 [] { ["SageMaker.SendPipelineExecutionStepSuccess"] }
def X-Amz-Target-completer-250 [] { ["SageMaker.StartEdgeDeploymentStage"] }
def X-Amz-Target-completer-251 [] { ["SageMaker.StartInferenceExperiment"] }
def X-Amz-Target-completer-252 [] { ["SageMaker.StartMonitoringSchedule"] }
def X-Amz-Target-completer-253 [] { ["SageMaker.StartNotebookInstance"] }
def X-Amz-Target-completer-254 [] { ["SageMaker.StartPipelineExecution"] }
def X-Amz-Target-completer-255 [] { ["SageMaker.StopAutoMLJob"] }
def X-Amz-Target-completer-256 [] { ["SageMaker.StopCompilationJob"] }
def X-Amz-Target-completer-257 [] { ["SageMaker.StopEdgeDeploymentStage"] }
def X-Amz-Target-completer-258 [] { ["SageMaker.StopEdgePackagingJob"] }
def X-Amz-Target-completer-259 [] { ["SageMaker.StopHyperParameterTuningJob"] }
def X-Amz-Target-completer-260 [] { ["SageMaker.StopInferenceExperiment"] }
def X-Amz-Target-completer-261 [] { ["SageMaker.StopInferenceRecommendationsJob"] }
def X-Amz-Target-completer-262 [] { ["SageMaker.StopLabelingJob"] }
def X-Amz-Target-completer-263 [] { ["SageMaker.StopMonitoringSchedule"] }
def X-Amz-Target-completer-264 [] { ["SageMaker.StopNotebookInstance"] }
def X-Amz-Target-completer-265 [] { ["SageMaker.StopPipelineExecution"] }
def X-Amz-Target-completer-266 [] { ["SageMaker.StopProcessingJob"] }
def X-Amz-Target-completer-267 [] { ["SageMaker.StopTrainingJob"] }
def X-Amz-Target-completer-268 [] { ["SageMaker.StopTransformJob"] }
def X-Amz-Target-completer-269 [] { ["SageMaker.UpdateAction"] }
def X-Amz-Target-completer-270 [] { ["SageMaker.UpdateAppImageConfig"] }
def X-Amz-Target-completer-271 [] { ["SageMaker.UpdateArtifact"] }
def X-Amz-Target-completer-272 [] { ["SageMaker.UpdateCodeRepository"] }
def X-Amz-Target-completer-273 [] { ["SageMaker.UpdateContext"] }
def X-Amz-Target-completer-274 [] { ["SageMaker.UpdateDeviceFleet"] }
def X-Amz-Target-completer-275 [] { ["SageMaker.UpdateDevices"] }
def X-Amz-Target-completer-276 [] { ["SageMaker.UpdateDomain"] }
def X-Amz-Target-completer-277 [] { ["SageMaker.UpdateEndpoint"] }
def X-Amz-Target-completer-278 [] { ["SageMaker.UpdateEndpointWeightsAndCapacities"] }
def X-Amz-Target-completer-279 [] { ["SageMaker.UpdateExperiment"] }
def X-Amz-Target-completer-280 [] { ["SageMaker.UpdateFeatureGroup"] }
def X-Amz-Target-completer-281 [] { ["SageMaker.UpdateFeatureMetadata"] }
def X-Amz-Target-completer-282 [] { ["SageMaker.UpdateHub"] }
def X-Amz-Target-completer-283 [] { ["SageMaker.UpdateImage"] }
def X-Amz-Target-completer-284 [] { ["SageMaker.UpdateImageVersion"] }
def X-Amz-Target-completer-285 [] { ["SageMaker.UpdateInferenceExperiment"] }
def X-Amz-Target-completer-286 [] { ["SageMaker.UpdateModelCard"] }
def X-Amz-Target-completer-287 [] { ["SageMaker.UpdateModelPackage"] }
def X-Amz-Target-completer-288 [] { ["SageMaker.UpdateMonitoringAlert"] }
def X-Amz-Target-completer-289 [] { ["SageMaker.UpdateMonitoringSchedule"] }
def X-Amz-Target-completer-290 [] { ["SageMaker.UpdateNotebookInstance"] }
def X-Amz-Target-completer-291 [] { ["SageMaker.UpdateNotebookInstanceLifecycleConfig"] }
def X-Amz-Target-completer-292 [] { ["SageMaker.UpdatePipeline"] }
def X-Amz-Target-completer-293 [] { ["SageMaker.UpdatePipelineExecution"] }
def X-Amz-Target-completer-294 [] { ["SageMaker.UpdateProject"] }
def X-Amz-Target-completer-295 [] { ["SageMaker.UpdateSpace"] }
def X-Amz-Target-completer-296 [] { ["SageMaker.UpdateTrainingJob"] }
def X-Amz-Target-completer-297 [] { ["SageMaker.UpdateTrial"] }
def X-Amz-Target-completer-298 [] { ["SageMaker.UpdateTrialComponent"] }
def X-Amz-Target-completer-299 [] { ["SageMaker.UpdateUserProfile"] }
def X-Amz-Target-completer-300 [] { ["SageMaker.UpdateWorkforce"] }
def X-Amz-Target-completer-301 [] { ["SageMaker.UpdateWorkteam"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "x-amz-target-sage-maker-add-association AddAssociation" } } | get name | first)
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

# Creates an <i>association</i> between the source and the destination. A source can be associated with multiple destinations, and a destination can be associated with multiple sources. An association is a lineage tracking entity. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/lineage-tracking.html">Amazon SageMaker ML Lineage Tracking</a>.
#
# POST /#X-Amz-Target=SageMaker.AddAssociation
# operationId: AddAssociation
export def "x-amz-target-sage-maker-add-association AddAssociation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer
  SourceArn: any
  DestinationArn: any
  --AssociationType: any
]: any -> record<SourceArn: record, DestinationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.AddAssociation")
  let body = {SourceArn: $SourceArn, DestinationArn: $DestinationArn, AssociationType: $AssociationType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Adds or overwrites one or more tags for the specified SageMaker resource. You can add tags to notebook instances, training jobs, hyperparameter tuning jobs, batch transform jobs, models, labeling jobs, work teams, endpoint configurations, and endpoints.</p> <p>Each tag consists of a key and an optional value. Tag keys must be unique per resource. For more information about tags, see For more information, see <a href="https://aws.amazon.com/answers/account-management/aws-tagging-strategies/">Amazon Web Services Tagging Strategies</a>.</p> <note> <p>Tags that you add to a hyperparameter tuning job by calling this API are also added to any training jobs that the hyperparameter tuning job launches after you call this API, but not to training jobs that the hyperparameter tuning job launched before you called this API. To make sure that the tags associated with a hyperparameter tuning job are also added to all training jobs that the hyperparameter tuning job launches, add the tags when you first create the tuning job by specifying them in the <code>Tags</code> parameter of <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateHyperParameterTuningJob.html">CreateHyperParameterTuningJob</a> </p> </note> <note> <p>Tags that you add to a SageMaker Studio Domain or User Profile by calling this API are also added to any Apps that the Domain or User Profile launches after you call this API, but not to Apps that the Domain or User Profile launched before you called this API. To make sure that the tags associated with a Domain or User Profile are also added to all Apps that the Domain or User Profile launches, add the tags when you first create the Domain or User Profile by specifying them in the <code>Tags</code> parameter of <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateDomain.html">CreateDomain</a> or <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateUserProfile.html">CreateUserProfile</a>.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.AddTags
# operationId: AddTags
export def "x-amz-target-sage-maker-add-tags AddTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-1
  ResourceArn: any
  Tags: any
]: any -> record<Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.AddTags")
  let body = {ResourceArn: $ResourceArn, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Associates a trial component with a trial. A trial component can be associated with multiple trials. To disassociate a trial component from a trial, call the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DisassociateTrialComponent.html">DisassociateTrialComponent</a> API.
#
# POST /#X-Amz-Target=SageMaker.AssociateTrialComponent
# operationId: AssociateTrialComponent
export def "x-amz-target-sage-maker-associate-trial-component AssociateTrialComponent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-2
  TrialComponentName: any
  TrialName: any
]: any -> record<TrialComponentArn: record, TrialArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.AssociateTrialComponent")
  let body = {TrialComponentName: $TrialComponentName, TrialName: $TrialName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This action batch describes a list of versioned model packages
#
# POST /#X-Amz-Target=SageMaker.BatchDescribeModelPackage
# operationId: BatchDescribeModelPackage
export def "x-amz-target-sage-maker-batch-describe-model-package BatchDescribeModelPackage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-3
  ModelPackageArnList: any
]: any -> record<ModelPackageSummaries: record, BatchDescribeModelPackageErrorMap: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.BatchDescribeModelPackage")
  let body = {ModelPackageArnList: $ModelPackageArnList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an <i>action</i>. An action is a lineage tracking entity that represents an action or activity. For example, a model deployment or an HPO job. Generally, an action involves at least one input or output artifact. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/lineage-tracking.html">Amazon SageMaker ML Lineage Tracking</a>.
#
# POST /#X-Amz-Target=SageMaker.CreateAction
# operationId: CreateAction
# --MetadataProperties shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
export def "x-amz-target-sage-maker-create-action CreateAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-4
  ActionName: any
  Source: any
  ActionType: any
  --Description: any
  --Status: any
  --Properties: any
  --MetadataProperties: record # Metadata properties of the tracking entity, trial, or trial component. — shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
  --Tags: any
]: any -> record<ActionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateAction")
  let body = {ActionName: $ActionName, Source: $Source, ActionType: $ActionType, Description: $Description, Status: $Status, Properties: $Properties, MetadataProperties: $MetadataProperties, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a machine learning algorithm that you can use in SageMaker and list in the Amazon Web Services Marketplace.
#
# POST /#X-Amz-Target=SageMaker.CreateAlgorithm
# operationId: CreateAlgorithm
export def "x-amz-target-sage-maker-create-algorithm CreateAlgorithm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-5
  AlgorithmName: any
  --AlgorithmDescription: any
  TrainingSpecification: any
  --InferenceSpecification: any
  --ValidationSpecification: any
  --CertifyForMarketplace: any
  --Tags: any
]: any -> record<AlgorithmArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateAlgorithm")
  let body = {AlgorithmName: $AlgorithmName, AlgorithmDescription: $AlgorithmDescription, TrainingSpecification: $TrainingSpecification, InferenceSpecification: $InferenceSpecification, ValidationSpecification: $ValidationSpecification, CertifyForMarketplace: $CertifyForMarketplace, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a running app for the specified UserProfile. This operation is automatically invoked by Amazon SageMaker Studio upon access to the associated Domain, and when new kernel configurations are selected by the user. A user may have multiple Apps active simultaneously.
#
# POST /#X-Amz-Target=SageMaker.CreateApp
# operationId: CreateApp
export def "x-amz-target-sage-maker-create-app CreateApp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-6
  DomainId: any
  --UserProfileName: any
  AppType: any
  AppName: any
  --Tags: any
  --ResourceSpec: any
  --SpaceName: any
]: any -> record<AppArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateApp")
  let body = {DomainId: $DomainId, UserProfileName: $UserProfileName, AppType: $AppType, AppName: $AppName, Tags: $Tags, ResourceSpec: $ResourceSpec, SpaceName: $SpaceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a configuration for running a SageMaker image as a KernelGateway app. The configuration specifies the Amazon Elastic File System (EFS) storage volume on the image, and a list of the kernels in the image.
#
# POST /#X-Amz-Target=SageMaker.CreateAppImageConfig
# operationId: CreateAppImageConfig
export def "x-amz-target-sage-maker-create-app-image-config CreateAppImageConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-7
  AppImageConfigName: any
  --Tags: any
  --KernelGatewayImageConfig: any
]: any -> record<AppImageConfigArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateAppImageConfig")
  let body = {AppImageConfigName: $AppImageConfigName, Tags: $Tags, KernelGatewayImageConfig: $KernelGatewayImageConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an <i>artifact</i>. An artifact is a lineage tracking entity that represents a URI addressable object or data. Some examples are the S3 URI of a dataset and the ECR registry path of an image. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/lineage-tracking.html">Amazon SageMaker ML Lineage Tracking</a>.
#
# POST /#X-Amz-Target=SageMaker.CreateArtifact
# operationId: CreateArtifact
# --MetadataProperties shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
export def "x-amz-target-sage-maker-create-artifact CreateArtifact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-8
  --ArtifactName: any
  Source: any
  ArtifactType: any
  --Properties: any
  --MetadataProperties: record # Metadata properties of the tracking entity, trial, or trial component. — shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
  --Tags: any
]: any -> record<ArtifactArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateArtifact")
  let body = {ArtifactName: $ArtifactName, Source: $Source, ArtifactType: $ArtifactType, Properties: $Properties, MetadataProperties: $MetadataProperties, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates an Autopilot job.</p> <p>Find the best-performing model after you run an Autopilot job by calling <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeAutoMLJob.html">DescribeAutoMLJob</a>.</p> <p>For information about how to use Autopilot, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/autopilot-automate-model-development.html">Automate Model Development with Amazon SageMaker Autopilot</a>.</p>
#
# POST /#X-Amz-Target=SageMaker.CreateAutoMLJob
# operationId: CreateAutoMLJob
export def "x-amz-target-sage-maker-create-auto-ml-job CreateAutoMLJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-9
  AutoMLJobName: any
  InputDataConfig: any
  OutputDataConfig: any
  --ProblemType: any
  --AutoMLJobObjective: any
  --AutoMLJobConfig: any
  RoleArn: any
  --GenerateCandidateDefinitionsOnly: any
  --Tags: any
  --ModelDeployConfig: any
]: any -> record<AutoMLJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateAutoMLJob")
  let body = {AutoMLJobName: $AutoMLJobName, InputDataConfig: $InputDataConfig, OutputDataConfig: $OutputDataConfig, ProblemType: $ProblemType, AutoMLJobObjective: $AutoMLJobObjective, AutoMLJobConfig: $AutoMLJobConfig, RoleArn: $RoleArn, GenerateCandidateDefinitionsOnly: $GenerateCandidateDefinitionsOnly, Tags: $Tags, ModelDeployConfig: $ModelDeployConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates an Amazon SageMaker AutoML job that uses non-tabular data such as images or text for Computer Vision or Natural Language Processing problems.</p> <p>Find the resulting model after you run an AutoML job V2 by calling <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeAutoMLJobV2.html">DescribeAutoMLJobV2</a>.</p> <p>To create an <code>AutoMLJob</code> using tabular data, see <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateAutoMLJob.html">CreateAutoMLJob</a>.</p> <note> <p>This API action is callable through SageMaker Canvas only. Calling it directly from the CLI or an SDK results in an error.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.CreateAutoMLJobV2
# operationId: CreateAutoMLJobV2
export def "x-amz-target-sage-maker-create-auto-ml-job-v2 CreateAutoMLJobV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-10
  AutoMLJobName: any
  AutoMLJobInputDataConfig: any
  OutputDataConfig: any
  AutoMLProblemTypeConfig: any
  RoleArn: any
  --Tags: any
  --SecurityConfig: any
  --AutoMLJobObjective: any
  --ModelDeployConfig: any
  --DataSplitConfig: any
]: any -> record<AutoMLJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateAutoMLJobV2")
  let body = {AutoMLJobName: $AutoMLJobName, AutoMLJobInputDataConfig: $AutoMLJobInputDataConfig, OutputDataConfig: $OutputDataConfig, AutoMLProblemTypeConfig: $AutoMLProblemTypeConfig, RoleArn: $RoleArn, Tags: $Tags, SecurityConfig: $SecurityConfig, AutoMLJobObjective: $AutoMLJobObjective, ModelDeployConfig: $ModelDeployConfig, DataSplitConfig: $DataSplitConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a Git repository as a resource in your SageMaker account. You can associate the repository with notebook instances so that you can use Git source control for the notebooks you create. The Git repository is a resource in your SageMaker account, so it can be associated with more than one notebook instance, and it persists independently from the lifecycle of any notebook instances it is associated with.</p> <p>The repository can be hosted either in <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">Amazon Web Services CodeCommit</a> or in any other Git repository.</p>
#
# POST /#X-Amz-Target=SageMaker.CreateCodeRepository
# operationId: CreateCodeRepository
export def "x-amz-target-sage-maker-create-code-repository CreateCodeRepository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-11
  CodeRepositoryName: any
  GitConfig: any
  --Tags: any
]: any -> record<CodeRepositoryArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateCodeRepository")
  let body = {CodeRepositoryName: $CodeRepositoryName, GitConfig: $GitConfig, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Starts a model compilation job. After the model has been compiled, Amazon SageMaker saves the resulting model artifacts to an Amazon Simple Storage Service (Amazon S3) bucket that you specify. </p> <p>If you choose to host your model using Amazon SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts with Amazon Web Services IoT Greengrass. In that case, deploy them as an ML resource.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p>A name for the compilation job</p> </li> <li> <p> Information about the input model artifacts </p> </li> <li> <p>The output location for the compiled model and the device (target) that the model runs on </p> </li> <li> <p>The Amazon Resource Name (ARN) of the IAM role that Amazon SageMaker assumes to perform the model compilation job. </p> </li> </ul> <p>You can also provide a <code>Tag</code> to track the model compilation job's resource use and costs. The response body contains the <code>CompilationJobArn</code> for the compiled job.</p> <p>To stop a model compilation job, use <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_StopCompilationJob.html">StopCompilationJob</a>. To get information about a particular model compilation job, use <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeCompilationJob.html">DescribeCompilationJob</a>. To get information about multiple model compilation jobs, use <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_ListCompilationJobs.html">ListCompilationJobs</a>.</p>
#
# POST /#X-Amz-Target=SageMaker.CreateCompilationJob
# operationId: CreateCompilationJob
export def "x-amz-target-sage-maker-create-compilation-job CreateCompilationJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-12
  CompilationJobName: any
  RoleArn: any
  --ModelPackageVersionArn: any
  --InputConfig: any
  OutputConfig: any
  --VpcConfig: any
  StoppingCondition: any
  --Tags: any
]: any -> record<CompilationJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateCompilationJob")
  let body = {CompilationJobName: $CompilationJobName, RoleArn: $RoleArn, ModelPackageVersionArn: $ModelPackageVersionArn, InputConfig: $InputConfig, OutputConfig: $OutputConfig, VpcConfig: $VpcConfig, StoppingCondition: $StoppingCondition, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a <i>context</i>. A context is a lineage tracking entity that represents a logical grouping of other tracking or experiment entities. Some examples are an endpoint and a model package. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/lineage-tracking.html">Amazon SageMaker ML Lineage Tracking</a>.
#
# POST /#X-Amz-Target=SageMaker.CreateContext
# operationId: CreateContext
export def "x-amz-target-sage-maker-create-context CreateContext" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-13
  ContextName: any
  Source: any
  ContextType: any
  --Description: any
  --Properties: any
  --Tags: any
]: any -> record<ContextArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateContext")
  let body = {ContextName: $ContextName, Source: $Source, ContextType: $ContextType, Description: $Description, Properties: $Properties, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a definition for a job that monitors data quality and drift. For information about model monitor, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-monitor.html">Amazon SageMaker Model Monitor</a>.
#
# POST /#X-Amz-Target=SageMaker.CreateDataQualityJobDefinition
# operationId: CreateDataQualityJobDefinition
# --DataQualityJobOutputConfig shape: {MonitoringOutputs: any, KmsKeyId?: any}
# --JobResources shape: {ClusterConfig: any}
# --StoppingCondition shape: {MaxRuntimeInSeconds: any}
export def "x-amz-target-sage-maker-create-data-quality-job-definition CreateDataQualityJobDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-14
  JobDefinitionName: any
  --DataQualityBaselineConfig: any
  DataQualityAppSpecification: any
  DataQualityJobInput: any
  DataQualityJobOutputConfig: record # The output configuration for monitoring jobs. — shape: {MonitoringOutputs: any, KmsKeyId?: any}
  JobResources: record # Identifies the resources to deploy for a monitoring job. — shape: {ClusterConfig: any}
  --NetworkConfig: any
  RoleArn: any
  --StoppingCondition: record # A time limit for how long the monitoring job is allowed to run before stopping. — shape: {MaxRuntimeInSeconds: any}
  --Tags: any
]: any -> record<JobDefinitionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateDataQualityJobDefinition")
  let body = {JobDefinitionName: $JobDefinitionName, DataQualityBaselineConfig: $DataQualityBaselineConfig, DataQualityAppSpecification: $DataQualityAppSpecification, DataQualityJobInput: $DataQualityJobInput, DataQualityJobOutputConfig: $DataQualityJobOutputConfig, JobResources: $JobResources, NetworkConfig: $NetworkConfig, RoleArn: $RoleArn, StoppingCondition: $StoppingCondition, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a device fleet.
#
# POST /#X-Amz-Target=SageMaker.CreateDeviceFleet
# operationId: CreateDeviceFleet
export def "x-amz-target-sage-maker-create-device-fleet CreateDeviceFleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-15
  DeviceFleetName: any
  --RoleArn: any
  --Description: any
  OutputConfig: any
  --Tags: any
  --EnableIotRoleAlias: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateDeviceFleet")
  let body = {DeviceFleetName: $DeviceFleetName, RoleArn: $RoleArn, Description: $Description, OutputConfig: $OutputConfig, Tags: $Tags, EnableIotRoleAlias: $EnableIotRoleAlias} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a <code>Domain</code> used by Amazon SageMaker Studio. A domain consists of an associated Amazon Elastic File System (EFS) volume, a list of authorized users, and a variety of security, application, policy, and Amazon Virtual Private Cloud (VPC) configurations. Users within a domain can share notebook files and other artifacts with each other.</p> <p> <b>EFS storage</b> </p> <p>When a domain is created, an EFS volume is created for use by all of the users within the domain. Each user receives a private home directory within the EFS volume for notebooks, Git repositories, and data files.</p> <p>SageMaker uses the Amazon Web Services Key Management Service (Amazon Web Services KMS) to encrypt the EFS volume attached to the domain with an Amazon Web Services managed key by default. For more control, you can specify a customer managed key. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/encryption-at-rest.html">Protect Data at Rest Using Encryption</a>.</p> <p> <b>VPC configuration</b> </p> <p>All SageMaker Studio traffic between the domain and the EFS volume is through the specified VPC and subnets. For other Studio traffic, you can specify the <code>AppNetworkAccessType</code> parameter. <code>AppNetworkAccessType</code> corresponds to the network access type that you choose when you onboard to Studio. The following options are available:</p> <ul> <li> <p> <code>PublicInternetOnly</code> - Non-EFS traffic goes through a VPC managed by Amazon SageMaker, which allows internet access. This is the default value.</p> </li> <li> <p> <code>VpcOnly</code> - All Studio traffic is through the specified VPC and subnets. Internet access is disabled by default. To allow internet access, you must specify a NAT gateway.</p> <p>When internet access is disabled, you won't be able to run a Studio notebook or to train or host models unless your VPC has an interface endpoint to the SageMaker API and runtime or a NAT gateway and your security groups allow outbound connections.</p> </li> </ul> <important> <p>NFS traffic over TCP on port 2049 needs to be allowed in both inbound and outbound rules in order to launch a SageMaker Studio app successfully.</p> </important> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/studio-notebooks-and-internet-access.html">Connect SageMaker Studio Notebooks to Resources in a VPC</a>.</p>
#
# POST /#X-Amz-Target=SageMaker.CreateDomain
# operationId: CreateDomain
export def "x-amz-target-sage-maker-create-domain CreateDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-16
  DomainName: any
  AuthMode: any
  DefaultUserSettings: any
  SubnetIds: any
  VpcId: any
  --Tags: any
  --AppNetworkAccessType: any
  --HomeEfsFileSystemKmsKeyId: any
  --KmsKeyId: any
  --AppSecurityGroupManagement: any
  --DomainSettings: any
  --DefaultSpaceSettings: any
]: any -> record<DomainArn: record, Url: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateDomain")
  let body = {DomainName: $DomainName, AuthMode: $AuthMode, DefaultUserSettings: $DefaultUserSettings, SubnetIds: $SubnetIds, VpcId: $VpcId, Tags: $Tags, AppNetworkAccessType: $AppNetworkAccessType, HomeEfsFileSystemKmsKeyId: $HomeEfsFileSystemKmsKeyId, KmsKeyId: $KmsKeyId, AppSecurityGroupManagement: $AppSecurityGroupManagement, DomainSettings: $DomainSettings, DefaultSpaceSettings: $DefaultSpaceSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an edge deployment plan, consisting of multiple stages. Each stage may have a different deployment configuration and devices.
#
# POST /#X-Amz-Target=SageMaker.CreateEdgeDeploymentPlan
# operationId: CreateEdgeDeploymentPlan
export def "x-amz-target-sage-maker-create-edge-deployment-plan CreateEdgeDeploymentPlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-17
  EdgeDeploymentPlanName: any
  ModelConfigs: any
  DeviceFleetName: any
  --Stages: any
  --Tags: any
]: any -> record<EdgeDeploymentPlanArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateEdgeDeploymentPlan")
  let body = {EdgeDeploymentPlanName: $EdgeDeploymentPlanName, ModelConfigs: $ModelConfigs, DeviceFleetName: $DeviceFleetName, Stages: $Stages, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new stage in an existing edge deployment plan.
#
# POST /#X-Amz-Target=SageMaker.CreateEdgeDeploymentStage
# operationId: CreateEdgeDeploymentStage
export def "x-amz-target-sage-maker-create-edge-deployment-stage CreateEdgeDeploymentStage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-18
  EdgeDeploymentPlanName: any
  Stages: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateEdgeDeploymentStage")
  let body = {EdgeDeploymentPlanName: $EdgeDeploymentPlanName, Stages: $Stages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Starts a SageMaker Edge Manager model packaging job. Edge Manager will use the model artifacts from the Amazon Simple Storage Service bucket that you specify. After the model has been packaged, Amazon SageMaker saves the resulting artifacts to an S3 bucket that you specify.
#
# POST /#X-Amz-Target=SageMaker.CreateEdgePackagingJob
# operationId: CreateEdgePackagingJob
export def "x-amz-target-sage-maker-create-edge-packaging-job CreateEdgePackagingJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-19
  EdgePackagingJobName: any
  CompilationJobName: any
  ModelName: any
  ModelVersion: any
  RoleArn: any
  OutputConfig: any
  --ResourceKey: any
  --Tags: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateEdgePackagingJob")
  let body = {EdgePackagingJobName: $EdgePackagingJobName, CompilationJobName: $CompilationJobName, ModelName: $ModelName, ModelVersion: $ModelVersion, RoleArn: $RoleArn, OutputConfig: $OutputConfig, ResourceKey: $ResourceKey, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates an endpoint using the endpoint configuration specified in the request. SageMaker uses the endpoint to provision resources and deploy models. You create the endpoint configuration with the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API. </p> <p> Use this API to deploy models using SageMaker hosting services. </p> <p>For an example that calls this method when deploying a model to SageMaker hosting services, see the <a href="https://github.com/aws/amazon-sagemaker-examples/blob/master/sagemaker-fundamentals/create-endpoint/create_endpoint.ipynb">Create Endpoint example notebook.</a> </p> <note> <p> You must not delete an <code>EndpointConfig</code> that is in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> </note> <p>The endpoint name must be unique within an Amazon Web Services Region in your Amazon Web Services account. </p> <p>When it receives the request, SageMaker creates the endpoint, launches the resources (ML compute instances), and deploys the model(s) on them. </p> <note> <p>When you call <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpoint.html">CreateEndpoint</a>, a load call is made to DynamoDB to verify that your endpoint configuration exists. When you read data from a DynamoDB table supporting <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadConsistency.html"> <code>Eventually Consistent Reads</code> </a>, the response might not reflect the results of a recently completed write operation. The response might include some stale data. If the dependent entities are not yet in DynamoDB, this causes a validation error. If you repeat your read request after a short time, the response should return the latest data. So retry logic is recommended to handle these possible issues. We also recommend that customers call <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeEndpointConfig.html">DescribeEndpointConfig</a> before calling <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpoint.html">CreateEndpoint</a> to minimize the potential impact of a DynamoDB eventually consistent read.</p> </note> <p>When SageMaker receives the request, it sets the endpoint status to <code>Creating</code>. After it creates the endpoint, it sets the status to <code>InService</code>. SageMaker can then process incoming requests for inferences. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeEndpoint.html">DescribeEndpoint</a> API.</p> <p>If any of the models hosted at this endpoint get model data from an Amazon S3 location, SageMaker uses Amazon Web Services Security Token Service to download model artifacts from the S3 path you provided. Amazon Web Services STS is activated in your Amazon Web Services account by default. If you previously deactivated Amazon Web Services STS for a region, you need to reactivate Amazon Web Services STS for that region. For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html">Activating and Deactivating Amazon Web Services STS in an Amazon Web Services Region</a> in the <i>Amazon Web Services Identity and Access Management User Guide</i>.</p> <note> <p> To add the IAM role policies for using this API operation, go to the <a href="https://console.aws.amazon.com/iam/">IAM console</a>, and choose Roles in the left navigation pane. Search the IAM role that you want to grant access to use the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpoint.html">CreateEndpoint</a> and <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpointConfig.html">CreateEndpointConfig</a> API operations, add the following policies to the role. </p> <ul> <li> <p>Option 1: For a full SageMaker access, search and attach the <code>AmazonSageMakerFullAccess</code> policy.</p> </li> <li> <p>Option 2: For granting a limited access to an IAM role, paste the following Action elements manually into the JSON file of the IAM role: </p> <p> <code>"Action": ["sagemaker:CreateEndpoint", "sagemaker:CreateEndpointConfig"]</code> </p> <p> <code>"Resource": [</code> </p> <p> <code>"arn:aws:sagemaker:region:account-id:endpoint/endpointName"</code> </p> <p> <code>"arn:aws:sagemaker:region:account-id:endpoint-config/endpointConfigName"</code> </p> <p> <code>]</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/api-permissions-reference.html">SageMaker API Permissions: Actions, Permissions, and Resources Reference</a>.</p> </li> </ul> </note>
#
# POST /#X-Amz-Target=SageMaker.CreateEndpoint
# operationId: CreateEndpoint
# --DeploymentConfig shape: {BlueGreenUpdatePolicy: any, AutoRollbackConfiguration?: any}
export def "x-amz-target-sage-maker-create-endpoint CreateEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-20
  EndpointName: any
  EndpointConfigName: any
  --DeploymentConfig: record # The deployment configuration for an endpoint, which contains the desired deployment strategy and rollback configurations. — shape: {BlueGreenUpdatePolicy: any, AutoRollbackConfiguration?: any}
  --Tags: any
]: any -> record<EndpointArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateEndpoint")
  let body = {EndpointName: $EndpointName, EndpointConfigName: $EndpointConfigName, DeploymentConfig: $DeploymentConfig, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates an endpoint configuration that SageMaker hosting services uses to deploy models. In the configuration, you identify one or more models, created using the <code>CreateModel</code> API, to deploy and the resources that you want SageMaker to provision. Then you call the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpoint.html">CreateEndpoint</a> API.</p> <note> <p> Use this API if you want to use SageMaker hosting services to deploy models into production. </p> </note> <p>In the request, you define a <code>ProductionVariant</code>, for each model that you want to deploy. Each <code>ProductionVariant</code> parameter also describes the resources that you want SageMaker to provision. This includes the number and type of ML compute instances to deploy. </p> <p>If you are hosting multiple models, you also assign a <code>VariantWeight</code> to specify how much traffic you want to allocate to each model. For example, suppose that you want to host two models, A and B, and you assign traffic weight 2 for model A and 1 for model B. SageMaker distributes two-thirds of the traffic to Model A, and one-third to model B. </p> <note> <p>When you call <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpoint.html">CreateEndpoint</a>, a load call is made to DynamoDB to verify that your endpoint configuration exists. When you read data from a DynamoDB table supporting <a href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadConsistency.html"> <code>Eventually Consistent Reads</code> </a>, the response might not reflect the results of a recently completed write operation. The response might include some stale data. If the dependent entities are not yet in DynamoDB, this causes a validation error. If you repeat your read request after a short time, the response should return the latest data. So retry logic is recommended to handle these possible issues. We also recommend that customers call <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeEndpointConfig.html">DescribeEndpointConfig</a> before calling <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateEndpoint.html">CreateEndpoint</a> to minimize the potential impact of a DynamoDB eventually consistent read.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.CreateEndpointConfig
# operationId: CreateEndpointConfig
# --DataCaptureConfig shape: {EnableCapture?: any, InitialSamplingPercentage: any, DestinationS3Uri: any, KmsKeyId?: any, CaptureOptions: any, CaptureContentTypeHeader?: any}
export def "x-amz-target-sage-maker-create-endpoint-config CreateEndpointConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-21
  EndpointConfigName: any
  ProductionVariants: any
  --DataCaptureConfig: record # Configuration to control how SageMaker captures inference data. — shape: {EnableCapture?: any, InitialSamplingPercentage: any, DestinationS3Uri: any, KmsKeyId?: any, CaptureOptions: any, CaptureContentTypeHeader?: any}
  --Tags: any
  --KmsKeyId: any
  --AsyncInferenceConfig: any
  --ExplainerConfig: any
  --ShadowProductionVariants: any
]: any -> record<EndpointConfigArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateEndpointConfig")
  let body = {EndpointConfigName: $EndpointConfigName, ProductionVariants: $ProductionVariants, DataCaptureConfig: $DataCaptureConfig, Tags: $Tags, KmsKeyId: $KmsKeyId, AsyncInferenceConfig: $AsyncInferenceConfig, ExplainerConfig: $ExplainerConfig, ShadowProductionVariants: $ShadowProductionVariants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a SageMaker <i>experiment</i>. An experiment is a collection of <i>trials</i> that are observed, compared and evaluated as a group. A trial is a set of steps, called <i>trial components</i>, that produce a machine learning model.</p> <note> <p>In the Studio UI, trials are referred to as <i>run groups</i> and trial components are referred to as <i>runs</i>.</p> </note> <p>The goal of an experiment is to determine the components that produce the best model. Multiple trials are performed, each one isolating and measuring the impact of a change to one or more inputs, while keeping the remaining inputs constant.</p> <p>When you use SageMaker Studio or the SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the Amazon Web Services SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to experiments, trials, trial components and then use the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_Search.html">Search</a> API to search for the tags.</p> <p>To add a description to an experiment, specify the optional <code>Description</code> parameter. To add a description later, or to change the description, call the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_UpdateExperiment.html">UpdateExperiment</a> API.</p> <p>To get a list of all your experiments, call the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_ListExperiments.html">ListExperiments</a> API. To view an experiment's properties, call the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeExperiment.html">DescribeExperiment</a> API. To get a list of all the trials associated with an experiment, call the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_ListTrials.html">ListTrials</a> API. To create a trial call the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTrial.html">CreateTrial</a> API.</p>
#
# POST /#X-Amz-Target=SageMaker.CreateExperiment
# operationId: CreateExperiment
export def "x-amz-target-sage-maker-create-experiment CreateExperiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-22
  ExperimentName: any
  --DisplayName: any
  --Description: any
  --Tags: any
]: any -> record<ExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateExperiment")
  let body = {ExperimentName: $ExperimentName, DisplayName: $DisplayName, Description: $Description, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Create a new <code>FeatureGroup</code>. A <code>FeatureGroup</code> is a group of <code>Features</code> defined in the <code>FeatureStore</code> to describe a <code>Record</code>. </p> <p>The <code>FeatureGroup</code> defines the schema and features contained in the FeatureGroup. A <code>FeatureGroup</code> definition is composed of a list of <code>Features</code>, a <code>RecordIdentifierFeatureName</code>, an <code>EventTimeFeatureName</code> and configurations for its <code>OnlineStore</code> and <code>OfflineStore</code>. Check <a href="https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html">Amazon Web Services service quotas</a> to see the <code>FeatureGroup</code>s quota for your Amazon Web Services account.</p> <important> <p>You must include at least one of <code>OnlineStoreConfig</code> and <code>OfflineStoreConfig</code> to create a <code>FeatureGroup</code>.</p> </important>
#
# POST /#X-Amz-Target=SageMaker.CreateFeatureGroup
# operationId: CreateFeatureGroup
export def "x-amz-target-sage-maker-create-feature-group CreateFeatureGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-23
  FeatureGroupName: any
  RecordIdentifierFeatureName: any
  EventTimeFeatureName: any
  FeatureDefinitions: any
  --OnlineStoreConfig: any
  --OfflineStoreConfig: any
  --RoleArn: any
  --Description: any
  --Tags: any
]: any -> record<FeatureGroupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateFeatureGroup")
  let body = {FeatureGroupName: $FeatureGroupName, RecordIdentifierFeatureName: $RecordIdentifierFeatureName, EventTimeFeatureName: $EventTimeFeatureName, FeatureDefinitions: $FeatureDefinitions, OnlineStoreConfig: $OnlineStoreConfig, OfflineStoreConfig: $OfflineStoreConfig, RoleArn: $RoleArn, Description: $Description, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a flow definition.
#
# POST /#X-Amz-Target=SageMaker.CreateFlowDefinition
# operationId: CreateFlowDefinition
export def "x-amz-target-sage-maker-create-flow-definition CreateFlowDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-24
  FlowDefinitionName: any
  --HumanLoopRequestSource: any
  --HumanLoopActivationConfig: any
  HumanLoopConfig: any
  OutputConfig: any
  RoleArn: any
  --Tags: any
]: any -> record<FlowDefinitionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateFlowDefinition")
  let body = {FlowDefinitionName: $FlowDefinitionName, HumanLoopRequestSource: $HumanLoopRequestSource, HumanLoopActivationConfig: $HumanLoopActivationConfig, HumanLoopConfig: $HumanLoopConfig, OutputConfig: $OutputConfig, RoleArn: $RoleArn, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Create a hub.</p> <note> <p>Hub APIs are only callable through SageMaker Studio.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.CreateHub
# operationId: CreateHub
export def "x-amz-target-sage-maker-create-hub CreateHub" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-25
  HubName: any
  HubDescription: any
  --HubDisplayName: any
  --HubSearchKeywords: any
  --S3StorageConfig: any
  --Tags: any
]: any -> record<HubArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateHub")
  let body = {HubName: $HubName, HubDescription: $HubDescription, HubDisplayName: $HubDisplayName, HubSearchKeywords: $HubSearchKeywords, S3StorageConfig: $S3StorageConfig, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Defines the settings you will use for the human review workflow user interface. Reviewers will see a three-panel interface with an instruction area, the item to review, and an input area.
#
# POST /#X-Amz-Target=SageMaker.CreateHumanTaskUi
# operationId: CreateHumanTaskUi
# --UiTemplate shape: {Content: any}
export def "x-amz-target-sage-maker-create-human-task-ui CreateHumanTaskUi" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-26
  HumanTaskUiName: any
  UiTemplate: record # The Liquid template for the worker user interface. — shape: {Content: any}
  --Tags: any
]: any -> record<HumanTaskUiArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateHumanTaskUi")
  let body = {HumanTaskUiName: $HumanTaskUiName, UiTemplate: $UiTemplate, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Starts a hyperparameter tuning job. A hyperparameter tuning job finds the best version of a model by running many training jobs on your dataset using the algorithm you choose and values for hyperparameters within ranges that you specify. It then chooses the hyperparameter values that result in a model that performs the best, as measured by an objective metric that you choose.</p> <p>A hyperparameter tuning job automatically creates Amazon SageMaker experiments, trials, and trial components for each training job that it runs. You can view these entities in Amazon SageMaker Studio. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/experiments-view-compare.html#experiments-view">View Experiments, Trials, and Trial Components</a>.</p> <important> <p>Do not include any security-sensitive information including account access IDs, secrets or tokens in any hyperparameter field. If the use of security-sensitive credentials are detected, SageMaker will reject your training job request and return an exception error.</p> </important>
#
# POST /#X-Amz-Target=SageMaker.CreateHyperParameterTuningJob
# operationId: CreateHyperParameterTuningJob
export def "x-amz-target-sage-maker-create-hyper-parameter-tuning-job CreateHyperParameterTuningJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-27
  HyperParameterTuningJobName: any
  HyperParameterTuningJobConfig: any
  --TrainingJobDefinition: any
  --TrainingJobDefinitions: any
  --WarmStartConfig: any
  --Tags: any
]: any -> record<HyperParameterTuningJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateHyperParameterTuningJob")
  let body = {HyperParameterTuningJobName: $HyperParameterTuningJobName, HyperParameterTuningJobConfig: $HyperParameterTuningJobConfig, TrainingJobDefinition: $TrainingJobDefinition, TrainingJobDefinitions: $TrainingJobDefinitions, WarmStartConfig: $WarmStartConfig, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a custom SageMaker image. A SageMaker image is a set of image versions. Each image version represents a container image stored in Amazon Elastic Container Registry (ECR). For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/studio-byoi.html">Bring your own SageMaker image</a>.
#
# POST /#X-Amz-Target=SageMaker.CreateImage
# operationId: CreateImage
export def "x-amz-target-sage-maker-create-image CreateImage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-28
  --Description: any
  --DisplayName: any
  ImageName: any
  RoleArn: any
  --Tags: any
]: any -> record<ImageArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateImage")
  let body = {Description: $Description, DisplayName: $DisplayName, ImageName: $ImageName, RoleArn: $RoleArn, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a version of the SageMaker image specified by <code>ImageName</code>. The version represents the Amazon Elastic Container Registry (ECR) container image specified by <code>BaseImage</code>.
#
# POST /#X-Amz-Target=SageMaker.CreateImageVersion
# operationId: CreateImageVersion
export def "x-amz-target-sage-maker-create-image-version CreateImageVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-29
  BaseImage: any
  ClientToken: any
  ImageName: any
  --Aliases: any
  --VendorGuidance: any
  --JobType: any
  --MLFramework: any
  --ProgrammingLang: any
  --Processor: any
  --Horovod: any
  --ReleaseNotes: any
]: any -> record<ImageVersionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateImageVersion")
  let body = {BaseImage: $BaseImage, ClientToken: $ClientToken, ImageName: $ImageName, Aliases: $Aliases, VendorGuidance: $VendorGuidance, JobType: $JobType, MLFramework: $MLFramework, ProgrammingLang: $ProgrammingLang, Processor: $Processor, Horovod: $Horovod, ReleaseNotes: $ReleaseNotes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p> Creates an inference experiment using the configurations specified in the request. </p> <p> Use this API to setup and schedule an experiment to compare model variants on a Amazon SageMaker inference endpoint. For more information about inference experiments, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/shadow-tests.html">Shadow tests</a>. </p> <p> Amazon SageMaker begins your experiment at the scheduled time and routes traffic to your endpoint's model variants based on your specified configuration. </p> <p> While the experiment is in progress or after it has concluded, you can view metrics that compare your model variants. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/shadow-tests-view-monitor-edit.html">View, monitor, and edit shadow tests</a>. </p>
#
# POST /#X-Amz-Target=SageMaker.CreateInferenceExperiment
# operationId: CreateInferenceExperiment
export def "x-amz-target-sage-maker-create-inference-experiment CreateInferenceExperiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-30
  Name: any
  Type: any
  --Schedule: any
  --Description: any
  RoleArn: any
  EndpointName: any
  ModelVariants: any
  --DataStorageConfig: any
  ShadowModeConfig: any
  --KmsKey: any
  --Tags: any
]: any -> record<InferenceExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateInferenceExperiment")
  let body = {Name: $Name, Type: $Type, Schedule: $Schedule, Description: $Description, RoleArn: $RoleArn, EndpointName: $EndpointName, ModelVariants: $ModelVariants, DataStorageConfig: $DataStorageConfig, ShadowModeConfig: $ShadowModeConfig, KmsKey: $KmsKey, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Starts a recommendation job. You can create either an instance recommendation or load test job.
#
# POST /#X-Amz-Target=SageMaker.CreateInferenceRecommendationsJob
# operationId: CreateInferenceRecommendationsJob
export def "x-amz-target-sage-maker-create-inference-recommendations-job CreateInferenceRecommendationsJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-31
  JobName: any
  JobType: any
  RoleArn: any
  InputConfig: any
  --JobDescription: any
  --StoppingConditions: any
  --OutputConfig: any
  --Tags: any
]: any -> record<JobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateInferenceRecommendationsJob")
  let body = {JobName: $JobName, JobType: $JobType, RoleArn: $RoleArn, InputConfig: $InputConfig, JobDescription: $JobDescription, StoppingConditions: $StoppingConditions, OutputConfig: $OutputConfig, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a job that uses workers to label the data objects in your input dataset. You can use the labeled data to train machine learning models. </p> <p>You can select your workforce from one of three providers:</p> <ul> <li> <p>A private workforce that you create. It can include employees, contractors, and outside experts. Use a private workforce when want the data to stay within your organization or when a specific set of skills is required.</p> </li> <li> <p>One or more vendors that you select from the Amazon Web Services Marketplace. Vendors provide expertise in specific areas. </p> </li> <li> <p>The Amazon Mechanical Turk workforce. This is the largest workforce, but it should only be used for public data or data that has been stripped of any personally identifiable information.</p> </li> </ul> <p>You can also use <i>automated data labeling</i> to reduce the number of data objects that need to be labeled by a human. Automated data labeling uses <i>active learning</i> to determine if a data object can be labeled by machine or if it needs to be sent to a human worker. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-automated-labeling.html">Using Automated Data Labeling</a>.</p> <p>The data objects to be labeled are contained in an Amazon S3 bucket. You create a <i>manifest file</i> that describes the location of each object. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-data.html">Using Input and Output Data</a>.</p> <p>The output can be used as the manifest file for another labeling job or as training data for your machine learning models.</p> <p>You can use this operation to create a static labeling job or a streaming labeling job. A static labeling job stops if all data objects in the input manifest file identified in <code>ManifestS3Uri</code> have been labeled. A streaming labeling job runs perpetually until it is manually stopped, or remains idle for 10 days. You can send new data objects to an active (<code>InProgress</code>) streaming labeling job in real time. To learn how to create a static labeling job, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-create-labeling-job-api.html">Create a Labeling Job (API) </a> in the Amazon SageMaker Developer Guide. To learn how to create a streaming labeling job, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-streaming-create-job.html">Create a Streaming Labeling Job</a>.</p>
#
# POST /#X-Amz-Target=SageMaker.CreateLabelingJob
# operationId: CreateLabelingJob
export def "x-amz-target-sage-maker-create-labeling-job CreateLabelingJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-32
  LabelingJobName: any
  LabelAttributeName: any
  InputConfig: any
  OutputConfig: any
  RoleArn: any
  --LabelCategoryConfigS3Uri: any
  --StoppingConditions: any
  --LabelingJobAlgorithmsConfig: any
  HumanTaskConfig: any
  --Tags: any
]: any -> record<LabelingJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateLabelingJob")
  let body = {LabelingJobName: $LabelingJobName, LabelAttributeName: $LabelAttributeName, InputConfig: $InputConfig, OutputConfig: $OutputConfig, RoleArn: $RoleArn, LabelCategoryConfigS3Uri: $LabelCategoryConfigS3Uri, StoppingConditions: $StoppingConditions, LabelingJobAlgorithmsConfig: $LabelingJobAlgorithmsConfig, HumanTaskConfig: $HumanTaskConfig, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a model in SageMaker. In the request, you name the model and describe a primary container. For the primary container, you specify the Docker image that contains inference code, artifacts (from prior training), and a custom environment map that the inference code uses when you deploy the model for predictions.</p> <p>Use this API to create a model if you want to use SageMaker hosting services or run a batch transform job.</p> <p>To host your model, you create an endpoint configuration with the <code>CreateEndpointConfig</code> API, and then create an endpoint with the <code>CreateEndpoint</code> API. SageMaker then deploys all of the containers that you defined for the model in the hosting environment. </p> <p>For an example that calls this method when deploying a model to SageMaker hosting services, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/realtime-endpoints-deployment.html#realtime-endpoints-deployment-create-model">Create a Model (Amazon Web Services SDK for Python (Boto 3)).</a> </p> <p>To run a batch transform using your model, you start a job with the <code>CreateTransformJob</code> API. SageMaker uses your model and your dataset to get inferences which are then saved to a specified S3 location.</p> <p>In the request, you also provide an IAM role that SageMaker can assume to access model artifacts and docker image for deployment on ML compute hosting instances or for batch transform jobs. In addition, you also use the IAM role to manage permissions the inference code needs. For example, if the inference code access any other Amazon Web Services resources, you grant necessary permissions via this role.</p>
#
# POST /#X-Amz-Target=SageMaker.CreateModel
# operationId: CreateModel
export def "x-amz-target-sage-maker-create-model CreateModel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-33
  ModelName: any
  --PrimaryContainer: any
  --Containers: any
  --InferenceExecutionConfig: any
  ExecutionRoleArn: any
  --Tags: any
  --VpcConfig: any
  --EnableNetworkIsolation: any
]: any -> record<ModelArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModel")
  let body = {ModelName: $ModelName, PrimaryContainer: $PrimaryContainer, Containers: $Containers, InferenceExecutionConfig: $InferenceExecutionConfig, ExecutionRoleArn: $ExecutionRoleArn, Tags: $Tags, VpcConfig: $VpcConfig, EnableNetworkIsolation: $EnableNetworkIsolation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates the definition for a model bias job.
#
# POST /#X-Amz-Target=SageMaker.CreateModelBiasJobDefinition
# operationId: CreateModelBiasJobDefinition
# --ModelBiasJobOutputConfig shape: {MonitoringOutputs: any, KmsKeyId?: any}
# --JobResources shape: {ClusterConfig: any}
# --StoppingCondition shape: {MaxRuntimeInSeconds: any}
export def "x-amz-target-sage-maker-create-model-bias-job-definition CreateModelBiasJobDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-34
  JobDefinitionName: any
  --ModelBiasBaselineConfig: any
  ModelBiasAppSpecification: any
  ModelBiasJobInput: any
  ModelBiasJobOutputConfig: record # The output configuration for monitoring jobs. — shape: {MonitoringOutputs: any, KmsKeyId?: any}
  JobResources: record # Identifies the resources to deploy for a monitoring job. — shape: {ClusterConfig: any}
  --NetworkConfig: any
  RoleArn: any
  --StoppingCondition: record # A time limit for how long the monitoring job is allowed to run before stopping. — shape: {MaxRuntimeInSeconds: any}
  --Tags: any
]: any -> record<JobDefinitionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModelBiasJobDefinition")
  let body = {JobDefinitionName: $JobDefinitionName, ModelBiasBaselineConfig: $ModelBiasBaselineConfig, ModelBiasAppSpecification: $ModelBiasAppSpecification, ModelBiasJobInput: $ModelBiasJobInput, ModelBiasJobOutputConfig: $ModelBiasJobOutputConfig, JobResources: $JobResources, NetworkConfig: $NetworkConfig, RoleArn: $RoleArn, StoppingCondition: $StoppingCondition, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates an Amazon SageMaker Model Card.</p> <p>For information about how to use model cards, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-cards.html">Amazon SageMaker Model Card</a>.</p>
#
# POST /#X-Amz-Target=SageMaker.CreateModelCard
# operationId: CreateModelCard
export def "x-amz-target-sage-maker-create-model-card CreateModelCard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-35
  ModelCardName: any
  --SecurityConfig: any
  Content: any
  ModelCardStatus: any
  --Tags: any
]: any -> record<ModelCardArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModelCard")
  let body = {ModelCardName: $ModelCardName, SecurityConfig: $SecurityConfig, Content: $Content, ModelCardStatus: $ModelCardStatus, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an Amazon SageMaker Model Card export job.
#
# POST /#X-Amz-Target=SageMaker.CreateModelCardExportJob
# operationId: CreateModelCardExportJob
export def "x-amz-target-sage-maker-create-model-card-export-job CreateModelCardExportJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-36
  ModelCardName: any
  --ModelCardVersion: any
  ModelCardExportJobName: any
  OutputConfig: any
]: any -> record<ModelCardExportJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModelCardExportJob")
  let body = {ModelCardName: $ModelCardName, ModelCardVersion: $ModelCardVersion, ModelCardExportJobName: $ModelCardExportJobName, OutputConfig: $OutputConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates the definition for a model explainability job.
#
# POST /#X-Amz-Target=SageMaker.CreateModelExplainabilityJobDefinition
# operationId: CreateModelExplainabilityJobDefinition
# --ModelExplainabilityJobOutputConfig shape: {MonitoringOutputs: any, KmsKeyId?: any}
# --JobResources shape: {ClusterConfig: any}
# --StoppingCondition shape: {MaxRuntimeInSeconds: any}
export def "x-amz-target-sage-maker-create-model-explainability-job-definition CreateModelExplainabilityJobDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-37
  JobDefinitionName: any
  --ModelExplainabilityBaselineConfig: any
  ModelExplainabilityAppSpecification: any
  ModelExplainabilityJobInput: any
  ModelExplainabilityJobOutputConfig: record # The output configuration for monitoring jobs. — shape: {MonitoringOutputs: any, KmsKeyId?: any}
  JobResources: record # Identifies the resources to deploy for a monitoring job. — shape: {ClusterConfig: any}
  --NetworkConfig: any
  RoleArn: any
  --StoppingCondition: record # A time limit for how long the monitoring job is allowed to run before stopping. — shape: {MaxRuntimeInSeconds: any}
  --Tags: any
]: any -> record<JobDefinitionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModelExplainabilityJobDefinition")
  let body = {JobDefinitionName: $JobDefinitionName, ModelExplainabilityBaselineConfig: $ModelExplainabilityBaselineConfig, ModelExplainabilityAppSpecification: $ModelExplainabilityAppSpecification, ModelExplainabilityJobInput: $ModelExplainabilityJobInput, ModelExplainabilityJobOutputConfig: $ModelExplainabilityJobOutputConfig, JobResources: $JobResources, NetworkConfig: $NetworkConfig, RoleArn: $RoleArn, StoppingCondition: $StoppingCondition, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a model package that you can use to create SageMaker models or list on Amazon Web Services Marketplace, or a versioned model that is part of a model group. Buyers can subscribe to model packages listed on Amazon Web Services Marketplace to create models in SageMaker.</p> <p>To create a model package by specifying a Docker container that contains your inference code and the Amazon S3 location of your model artifacts, provide values for <code>InferenceSpecification</code>. To create a model from an algorithm resource that you created or subscribed to in Amazon Web Services Marketplace, provide a value for <code>SourceAlgorithmSpecification</code>.</p> <note> <p>There are two types of model packages:</p> <ul> <li> <p>Versioned - a model that is part of a model group in the model registry.</p> </li> <li> <p>Unversioned - a model package that is not part of a model group.</p> </li> </ul> </note>
#
# POST /#X-Amz-Target=SageMaker.CreateModelPackage
# operationId: CreateModelPackage
# --MetadataProperties shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
export def "x-amz-target-sage-maker-create-model-package CreateModelPackage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-38
  --ModelPackageName: any
  --ModelPackageGroupName: any
  --ModelPackageDescription: any
  --InferenceSpecification: any
  --ValidationSpecification: any
  --SourceAlgorithmSpecification: any
  --CertifyForMarketplace: any
  --Tags: any
  --ModelApprovalStatus: any
  --MetadataProperties: record # Metadata properties of the tracking entity, trial, or trial component. — shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
  --ModelMetrics: any
  --ClientToken: any
  --CustomerMetadataProperties: any
  --DriftCheckBaselines: any
  --Domain: any
  --Task: any
  --SamplePayloadUrl: any
  --AdditionalInferenceSpecifications: any
]: any -> record<ModelPackageArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModelPackage")
  let body = {ModelPackageName: $ModelPackageName, ModelPackageGroupName: $ModelPackageGroupName, ModelPackageDescription: $ModelPackageDescription, InferenceSpecification: $InferenceSpecification, ValidationSpecification: $ValidationSpecification, SourceAlgorithmSpecification: $SourceAlgorithmSpecification, CertifyForMarketplace: $CertifyForMarketplace, Tags: $Tags, ModelApprovalStatus: $ModelApprovalStatus, MetadataProperties: $MetadataProperties, ModelMetrics: $ModelMetrics, ClientToken: $ClientToken, CustomerMetadataProperties: $CustomerMetadataProperties, DriftCheckBaselines: $DriftCheckBaselines, Domain: $Domain, Task: $Task, SamplePayloadUrl: $SamplePayloadUrl, AdditionalInferenceSpecifications: $AdditionalInferenceSpecifications} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a model group. A model group contains a group of model versions.
#
# POST /#X-Amz-Target=SageMaker.CreateModelPackageGroup
# operationId: CreateModelPackageGroup
export def "x-amz-target-sage-maker-create-model-package-group CreateModelPackageGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-39
  ModelPackageGroupName: any
  --ModelPackageGroupDescription: any
  --Tags: any
]: any -> record<ModelPackageGroupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModelPackageGroup")
  let body = {ModelPackageGroupName: $ModelPackageGroupName, ModelPackageGroupDescription: $ModelPackageGroupDescription, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a definition for a job that monitors model quality and drift. For information about model monitor, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-monitor.html">Amazon SageMaker Model Monitor</a>.
#
# POST /#X-Amz-Target=SageMaker.CreateModelQualityJobDefinition
# operationId: CreateModelQualityJobDefinition
# --ModelQualityJobOutputConfig shape: {MonitoringOutputs: any, KmsKeyId?: any}
# --JobResources shape: {ClusterConfig: any}
# --StoppingCondition shape: {MaxRuntimeInSeconds: any}
export def "x-amz-target-sage-maker-create-model-quality-job-definition CreateModelQualityJobDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-40
  JobDefinitionName: any
  --ModelQualityBaselineConfig: any
  ModelQualityAppSpecification: any
  ModelQualityJobInput: any
  ModelQualityJobOutputConfig: record # The output configuration for monitoring jobs. — shape: {MonitoringOutputs: any, KmsKeyId?: any}
  JobResources: record # Identifies the resources to deploy for a monitoring job. — shape: {ClusterConfig: any}
  --NetworkConfig: any
  RoleArn: any
  --StoppingCondition: record # A time limit for how long the monitoring job is allowed to run before stopping. — shape: {MaxRuntimeInSeconds: any}
  --Tags: any
]: any -> record<JobDefinitionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateModelQualityJobDefinition")
  let body = {JobDefinitionName: $JobDefinitionName, ModelQualityBaselineConfig: $ModelQualityBaselineConfig, ModelQualityAppSpecification: $ModelQualityAppSpecification, ModelQualityJobInput: $ModelQualityJobInput, ModelQualityJobOutputConfig: $ModelQualityJobOutputConfig, JobResources: $JobResources, NetworkConfig: $NetworkConfig, RoleArn: $RoleArn, StoppingCondition: $StoppingCondition, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a schedule that regularly starts Amazon SageMaker Processing Jobs to monitor the data captured for an Amazon SageMaker Endpoint.
#
# POST /#X-Amz-Target=SageMaker.CreateMonitoringSchedule
# operationId: CreateMonitoringSchedule
export def "x-amz-target-sage-maker-create-monitoring-schedule CreateMonitoringSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-41
  MonitoringScheduleName: any
  MonitoringScheduleConfig: any
  --Tags: any
]: any -> record<MonitoringScheduleArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateMonitoringSchedule")
  let body = {MonitoringScheduleName: $MonitoringScheduleName, MonitoringScheduleConfig: $MonitoringScheduleConfig, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates an SageMaker notebook instance. A notebook instance is a machine learning (ML) compute instance running on a Jupyter notebook. </p> <p>In a <code>CreateNotebookInstance</code> request, specify the type of ML compute instance that you want to run. SageMaker launches the instance, installs common libraries that you can use to explore datasets for model training, and attaches an ML storage volume to the notebook instance. </p> <p>SageMaker also provides a set of example notebooks. Each notebook demonstrates how to use SageMaker with a specific algorithm or with a machine learning framework. </p> <p>After receiving the request, SageMaker does the following:</p> <ol> <li> <p>Creates a network interface in the SageMaker VPC.</p> </li> <li> <p>(Option) If you specified <code>SubnetId</code>, SageMaker creates a network interface in your own VPC, which is inferred from the subnet ID that you provide in the input. When creating this network interface, SageMaker attaches the security group that you specified in the request to the network interface that it creates in your VPC.</p> </li> <li> <p>Launches an EC2 instance of the type specified in the request in the SageMaker VPC. If you specified <code>SubnetId</code> of your VPC, SageMaker specifies both network interfaces when launching this instance. This enables inbound traffic from your own VPC to the notebook instance, assuming that the security groups allow it.</p> </li> </ol> <p>After creating the notebook instance, SageMaker returns its Amazon Resource Name (ARN). You can't change the name of a notebook instance after you create it.</p> <p>After SageMaker creates the notebook instance, you can connect to the Jupyter server and work in Jupyter notebooks. For example, you can write code to explore a dataset that you can use for model training, train a model, host models by creating SageMaker endpoints, and validate hosted models. </p> <p>For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
#
# POST /#X-Amz-Target=SageMaker.CreateNotebookInstance
# operationId: CreateNotebookInstance
export def "x-amz-target-sage-maker-create-notebook-instance CreateNotebookInstance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-42
  NotebookInstanceName: any
  InstanceType: any
  --SubnetId: any
  --SecurityGroupIds: any
  RoleArn: any
  --KmsKeyId: any
  --Tags: any
  --LifecycleConfigName: any
  --DirectInternetAccess: any
  --VolumeSizeInGB: any
  --AcceleratorTypes: any
  --DefaultCodeRepository: any
  --AdditionalCodeRepositories: any
  --RootAccess: any
  --PlatformIdentifier: any
  --InstanceMetadataServiceConfiguration: any
]: any -> record<NotebookInstanceArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateNotebookInstance")
  let body = {NotebookInstanceName: $NotebookInstanceName, InstanceType: $InstanceType, SubnetId: $SubnetId, SecurityGroupIds: $SecurityGroupIds, RoleArn: $RoleArn, KmsKeyId: $KmsKeyId, Tags: $Tags, LifecycleConfigName: $LifecycleConfigName, DirectInternetAccess: $DirectInternetAccess, VolumeSizeInGB: $VolumeSizeInGB, AcceleratorTypes: $AcceleratorTypes, DefaultCodeRepository: $DefaultCodeRepository, AdditionalCodeRepositories: $AdditionalCodeRepositories, RootAccess: $RootAccess, PlatformIdentifier: $PlatformIdentifier, InstanceMetadataServiceConfiguration: $InstanceMetadataServiceConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a lifecycle configuration that you can associate with a notebook instance. A <i>lifecycle configuration</i> is a collection of shell scripts that run when you create or start a notebook instance.</p> <p>Each lifecycle configuration script has a limit of 16384 characters.</p> <p>The value of the <code>$PATH</code> environment variable that is available to both scripts is <code>/sbin:bin:/usr/sbin:/usr/bin</code>.</p> <p>View CloudWatch Logs for notebook instance lifecycle configurations in log group <code>/aws/sagemaker/NotebookInstances</code> in log stream <code>[notebook-instance-name]/[LifecycleConfigHook]</code>.</p> <p>Lifecycle configuration scripts cannot run for longer than 5 minutes. If a script runs for longer than 5 minutes, it fails and the notebook instance is not created or started.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
#
# POST /#X-Amz-Target=SageMaker.CreateNotebookInstanceLifecycleConfig
# operationId: CreateNotebookInstanceLifecycleConfig
export def "x-amz-target-sage-maker-create-notebook-instance-lifecycle-config CreateNotebookInstanceLifecycleConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-43
  NotebookInstanceLifecycleConfigName: any
  --OnCreate: any
  --OnStart: any
]: any -> record<NotebookInstanceLifecycleConfigArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateNotebookInstanceLifecycleConfig")
  let body = {NotebookInstanceLifecycleConfigName: $NotebookInstanceLifecycleConfigName, OnCreate: $OnCreate, OnStart: $OnStart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a pipeline using a JSON pipeline definition.
#
# POST /#X-Amz-Target=SageMaker.CreatePipeline
# operationId: CreatePipeline
export def "x-amz-target-sage-maker-create-pipeline CreatePipeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-44
  PipelineName: any
  --PipelineDisplayName: any
  --PipelineDefinition: any
  --PipelineDefinitionS3Location: any
  --PipelineDescription: any
  ClientRequestToken: any
  RoleArn: any
  --Tags: any
  --ParallelismConfiguration: any
]: any -> record<PipelineArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreatePipeline")
  let body = {PipelineName: $PipelineName, PipelineDisplayName: $PipelineDisplayName, PipelineDefinition: $PipelineDefinition, PipelineDefinitionS3Location: $PipelineDefinitionS3Location, PipelineDescription: $PipelineDescription, ClientRequestToken: $ClientRequestToken, RoleArn: $RoleArn, Tags: $Tags, ParallelismConfiguration: $ParallelismConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a URL for a specified UserProfile in a Domain. When accessed in a web browser, the user will be automatically signed in to Amazon SageMaker Studio, and granted access to all of the Apps and files associated with the Domain's Amazon Elastic File System (EFS) volume. This operation can only be called when the authentication mode equals IAM. </p> <p>The IAM role or user passed to this API defines the permissions to access the app. Once the presigned URL is created, no additional permission is required to access this URL. IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the app.</p> <p>You can restrict access to this API and to the URL that it returns to a list of IP addresses, Amazon VPCs or Amazon VPC Endpoints that you specify. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/studio-interface-endpoint.html">Connect to SageMaker Studio Through an Interface VPC Endpoint</a> .</p> <note> <p>The URL that you get from a call to <code>CreatePresignedDomainUrl</code> has a default timeout of 5 minutes. You can configure this value using <code>ExpiresInSeconds</code>. If you try to use the URL after the timeout limit expires, you are directed to the Amazon Web Services console sign-in page.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.CreatePresignedDomainUrl
# operationId: CreatePresignedDomainUrl
export def "x-amz-target-sage-maker-create-presigned-domain-url CreatePresignedDomainUrl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-45
  DomainId: any
  UserProfileName: any
  --SessionExpirationDurationInSeconds: any
  --ExpiresInSeconds: any
  --SpaceName: any
]: any -> record<AuthorizedUrl: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreatePresignedDomainUrl")
  let body = {DomainId: $DomainId, UserProfileName: $UserProfileName, SessionExpirationDurationInSeconds: $SessionExpirationDurationInSeconds, ExpiresInSeconds: $ExpiresInSeconds, SpaceName: $SpaceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns a URL that you can use to connect to the Jupyter server from a notebook instance. In the SageMaker console, when you choose <code>Open</code> next to a notebook instance, SageMaker opens a new tab showing the Jupyter server home page from the notebook instance. The console uses this API to get the URL and show the page.</p> <p> The IAM role or user used to call this API defines the permissions to access the notebook instance. Once the presigned URL is created, no additional permission is required to access this URL. IAM authorization policies for this API are also enforced for every HTTP request and WebSocket frame that attempts to connect to the notebook instance.</p> <p>You can restrict access to this API and to the URL that it returns to a list of IP addresses that you specify. Use the <code>NotIpAddress</code> condition operator and the <code>aws:SourceIP</code> condition context key to specify the list of IP addresses that you want to have access to the notebook instance. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#nbi-ip-filter">Limit Access to a Notebook Instance by IP Address</a>.</p> <note> <p>The URL that you get from a call to <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreatePresignedNotebookInstanceUrl.html">CreatePresignedNotebookInstanceUrl</a> is valid only for 5 minutes. If you try to use the URL after the 5-minute limit expires, you are directed to the Amazon Web Services console sign-in page.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.CreatePresignedNotebookInstanceUrl
# operationId: CreatePresignedNotebookInstanceUrl
export def "x-amz-target-sage-maker-create-presigned-notebook-instance-url CreatePresignedNotebookInstanceUrl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-46
  NotebookInstanceName: any
  --SessionExpirationDurationInSeconds: any
]: any -> record<AuthorizedUrl: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreatePresignedNotebookInstanceUrl")
  let body = {NotebookInstanceName: $NotebookInstanceName, SessionExpirationDurationInSeconds: $SessionExpirationDurationInSeconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a processing job.
#
# POST /#X-Amz-Target=SageMaker.CreateProcessingJob
# operationId: CreateProcessingJob
# --ExperimentConfig shape: {ExperimentName?: any, TrialName?: any, TrialComponentDisplayName?: any, RunName?: any}
export def "x-amz-target-sage-maker-create-processing-job CreateProcessingJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-47
  --ProcessingInputs: any
  --ProcessingOutputConfig: any
  ProcessingJobName: any
  ProcessingResources: any
  --StoppingCondition: any
  AppSpecification: any
  --Environment: any
  --NetworkConfig: any
  RoleArn: any
  --Tags: any
  --ExperimentConfig: record # <p>Associates a SageMaker job as a trial component with an experiment and trial. Specified when you call the following APIs:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateProcessingJob.html">CreateProcessingJob</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTrainingJob.html">CreateTrainingJob</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTransformJob.html">CreateTransformJob</a> </p> </li> </ul> — shape: {ExperimentName?: any, TrialName?: any, TrialComponentDisplayName?: any, RunName?: any}
]: any -> record<ProcessingJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateProcessingJob")
  let body = {ProcessingInputs: $ProcessingInputs, ProcessingOutputConfig: $ProcessingOutputConfig, ProcessingJobName: $ProcessingJobName, ProcessingResources: $ProcessingResources, StoppingCondition: $StoppingCondition, AppSpecification: $AppSpecification, Environment: $Environment, NetworkConfig: $NetworkConfig, RoleArn: $RoleArn, Tags: $Tags, ExperimentConfig: $ExperimentConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a machine learning (ML) project that can contain one or more templates that set up an ML pipeline from training to deploying an approved model.
#
# POST /#X-Amz-Target=SageMaker.CreateProject
# operationId: CreateProject
export def "x-amz-target-sage-maker-create-project CreateProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-48
  ProjectName: any
  --ProjectDescription: any
  ServiceCatalogProvisioningDetails: any
  --Tags: any
]: any -> record<ProjectArn: record, ProjectId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateProject")
  let body = {ProjectName: $ProjectName, ProjectDescription: $ProjectDescription, ServiceCatalogProvisioningDetails: $ServiceCatalogProvisioningDetails, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a space used for real time collaboration in a Domain.
#
# POST /#X-Amz-Target=SageMaker.CreateSpace
# operationId: CreateSpace
export def "x-amz-target-sage-maker-create-space CreateSpace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-49
  DomainId: any
  SpaceName: any
  --Tags: any
  --SpaceSettings: any
]: any -> record<SpaceArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateSpace")
  let body = {DomainId: $DomainId, SpaceName: $SpaceName, Tags: $Tags, SpaceSettings: $SpaceSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new Studio Lifecycle Configuration.
#
# POST /#X-Amz-Target=SageMaker.CreateStudioLifecycleConfig
# operationId: CreateStudioLifecycleConfig
export def "x-amz-target-sage-maker-create-studio-lifecycle-config CreateStudioLifecycleConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-50
  StudioLifecycleConfigName: any
  StudioLifecycleConfigContent: any
  StudioLifecycleConfigAppType: any
  --Tags: any
]: any -> record<StudioLifecycleConfigArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateStudioLifecycleConfig")
  let body = {StudioLifecycleConfigName: $StudioLifecycleConfigName, StudioLifecycleConfigContent: $StudioLifecycleConfigContent, StudioLifecycleConfigAppType: $StudioLifecycleConfigAppType, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Starts a model training job. After training completes, SageMaker saves the resulting model artifacts to an Amazon S3 location that you specify. </p> <p>If you choose to host your model using SageMaker hosting services, you can use the resulting model artifacts as part of the model. You can also use the artifacts in a machine learning service other than SageMaker, provided that you know how to use them for inference. </p> <p>In the request body, you provide the following: </p> <ul> <li> <p> <code>AlgorithmSpecification</code> - Identifies the training algorithm to use. </p> </li> <li> <p> <code>HyperParameters</code> - Specify these algorithm-specific parameters to enable the estimation of model parameters during training. Hyperparameters can be tuned to optimize this learning process. For a list of hyperparameters for each training algorithm provided by SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/algos.html">Algorithms</a>. </p> <important> <p>Do not include any security-sensitive information including account access IDs, secrets or tokens in any hyperparameter field. If the use of security-sensitive credentials are detected, SageMaker will reject your training job request and return an exception error.</p> </important> </li> <li> <p> <code>InputDataConfig</code> - Describes the input required by the training job and the Amazon S3, EFS, or FSx location where it is stored.</p> </li> <li> <p> <code>OutputDataConfig</code> - Identifies the Amazon S3 bucket where you want SageMaker to save the results of model training. </p> </li> <li> <p> <code>ResourceConfig</code> - Identifies the resources, ML compute instances, and ML storage volumes to deploy for model training. In distributed training, you specify more than one instance. </p> </li> <li> <p> <code>EnableManagedSpotTraining</code> - Optimize the cost of training machine learning models by up to 80% by using Amazon EC2 Spot instances. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/model-managed-spot-training.html">Managed Spot Training</a>. </p> </li> <li> <p> <code>RoleArn</code> - The Amazon Resource Name (ARN) that SageMaker assumes to perform tasks on your behalf during model training. You must grant this role the necessary permissions so that SageMaker can successfully complete model training. </p> </li> <li> <p> <code>StoppingCondition</code> - To help cap training costs, use <code>MaxRuntimeInSeconds</code> to set a time limit for training. Use <code>MaxWaitTimeInSeconds</code> to specify how long a managed spot training job has to complete. </p> </li> <li> <p> <code>Environment</code> - The environment variables to set in the Docker container.</p> </li> <li> <p> <code>RetryStrategy</code> - The number of times to retry the job when the job fails due to an <code>InternalServerError</code>.</p> </li> </ul> <p> For more information about SageMaker, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works.html">How It Works</a>. </p>
#
# POST /#X-Amz-Target=SageMaker.CreateTrainingJob
# operationId: CreateTrainingJob
# --DebugHookConfig shape: {LocalPath?: any, S3OutputPath: any, HookParameters?: any, CollectionConfigurations?: any}
# --TensorBoardOutputConfig shape: {LocalPath?: any, S3OutputPath: any}
# --ExperimentConfig shape: {ExperimentName?: any, TrialName?: any, TrialComponentDisplayName?: any, RunName?: any}
# --ProfilerConfig shape: {S3OutputPath?: any, ProfilingIntervalInMilliseconds?: any, ProfilingParameters?: any, DisableProfiler?: any}
export def "x-amz-target-sage-maker-create-training-job CreateTrainingJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-51
  TrainingJobName: any
  --HyperParameters: any
  AlgorithmSpecification: any
  RoleArn: any
  --InputDataConfig: any
  OutputDataConfig: any
  ResourceConfig: any
  --VpcConfig: any
  StoppingCondition: any
  --Tags: any
  --EnableNetworkIsolation: any
  --EnableInterContainerTrafficEncryption: any
  --EnableManagedSpotTraining: any
  --CheckpointConfig: any
  --DebugHookConfig: record # Configuration information for the Amazon SageMaker Debugger hook parameters, metric and tensor collections, and storage paths. To learn more about how to configure the <code>DebugHookConfig</code> parameter, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/debugger-createtrainingjob-api.html">Use the SageMaker and Debugger Configuration API Operations to Create, Update, and Debug Your Training Job</a>. — shape: {LocalPath?: any, S3OutputPath: any, HookParameters?: any, CollectionConfigurations?: any}
  --DebugRuleConfigurations: any
  --TensorBoardOutputConfig: record # Configuration of storage locations for the Amazon SageMaker Debugger TensorBoard output data. — shape: {LocalPath?: any, S3OutputPath: any}
  --ExperimentConfig: record # <p>Associates a SageMaker job as a trial component with an experiment and trial. Specified when you call the following APIs:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateProcessingJob.html">CreateProcessingJob</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTrainingJob.html">CreateTrainingJob</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTransformJob.html">CreateTransformJob</a> </p> </li> </ul> — shape: {ExperimentName?: any, TrialName?: any, TrialComponentDisplayName?: any, RunName?: any}
  --ProfilerConfig: record # Configuration information for Amazon SageMaker Debugger system monitoring, framework profiling, and storage paths. — shape: {S3OutputPath?: any, ProfilingIntervalInMilliseconds?: any, ProfilingParameters?: any, DisableProfiler?: any}
  --ProfilerRuleConfigurations: any
  --Environment: any
  --RetryStrategy: any
]: any -> record<TrainingJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateTrainingJob")
  let body = {TrainingJobName: $TrainingJobName, HyperParameters: $HyperParameters, AlgorithmSpecification: $AlgorithmSpecification, RoleArn: $RoleArn, InputDataConfig: $InputDataConfig, OutputDataConfig: $OutputDataConfig, ResourceConfig: $ResourceConfig, VpcConfig: $VpcConfig, StoppingCondition: $StoppingCondition, Tags: $Tags, EnableNetworkIsolation: $EnableNetworkIsolation, EnableInterContainerTrafficEncryption: $EnableInterContainerTrafficEncryption, EnableManagedSpotTraining: $EnableManagedSpotTraining, CheckpointConfig: $CheckpointConfig, DebugHookConfig: $DebugHookConfig, DebugRuleConfigurations: $DebugRuleConfigurations, TensorBoardOutputConfig: $TensorBoardOutputConfig, ExperimentConfig: $ExperimentConfig, ProfilerConfig: $ProfilerConfig, ProfilerRuleConfigurations: $ProfilerRuleConfigurations, Environment: $Environment, RetryStrategy: $RetryStrategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Starts a transform job. A transform job uses a trained model to get inferences on a dataset and saves these results to an Amazon S3 location that you specify.</p> <p>To perform batch transformations, you create a transform job and use the data that you have readily available.</p> <p>In the request body, you provide the following:</p> <ul> <li> <p> <code>TransformJobName</code> - Identifies the transform job. The name must be unique within an Amazon Web Services Region in an Amazon Web Services account.</p> </li> <li> <p> <code>ModelName</code> - Identifies the model to use. <code>ModelName</code> must be the name of an existing Amazon SageMaker model in the same Amazon Web Services Region and Amazon Web Services account. For information on creating a model, see <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateModel.html">CreateModel</a>.</p> </li> <li> <p> <code>TransformInput</code> - Describes the dataset to be transformed and the Amazon S3 location where it is stored.</p> </li> <li> <p> <code>TransformOutput</code> - Identifies the Amazon S3 location where you want Amazon SageMaker to save the results from the transform job.</p> </li> <li> <p> <code>TransformResources</code> - Identifies the ML compute instances for the transform job.</p> </li> </ul> <p>For more information about how batch transformation works, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/batch-transform.html">Batch Transform</a>.</p>
#
# POST /#X-Amz-Target=SageMaker.CreateTransformJob
# operationId: CreateTransformJob
# --ExperimentConfig shape: {ExperimentName?: any, TrialName?: any, TrialComponentDisplayName?: any, RunName?: any}
export def "x-amz-target-sage-maker-create-transform-job CreateTransformJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-52
  TransformJobName: any
  ModelName: any
  --MaxConcurrentTransforms: any
  --ModelClientConfig: any
  --MaxPayloadInMB: any
  --BatchStrategy: any
  --Environment: any
  TransformInput: any
  TransformOutput: any
  --DataCaptureConfig: any
  TransformResources: any
  --DataProcessing: any
  --Tags: any
  --ExperimentConfig: record # <p>Associates a SageMaker job as a trial component with an experiment and trial. Specified when you call the following APIs:</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateProcessingJob.html">CreateProcessingJob</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTrainingJob.html">CreateTrainingJob</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTransformJob.html">CreateTransformJob</a> </p> </li> </ul> — shape: {ExperimentName?: any, TrialName?: any, TrialComponentDisplayName?: any, RunName?: any}
]: any -> record<TransformJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateTransformJob")
  let body = {TransformJobName: $TransformJobName, ModelName: $ModelName, MaxConcurrentTransforms: $MaxConcurrentTransforms, ModelClientConfig: $ModelClientConfig, MaxPayloadInMB: $MaxPayloadInMB, BatchStrategy: $BatchStrategy, Environment: $Environment, TransformInput: $TransformInput, TransformOutput: $TransformOutput, DataCaptureConfig: $DataCaptureConfig, TransformResources: $TransformResources, DataProcessing: $DataProcessing, Tags: $Tags, ExperimentConfig: $ExperimentConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates an SageMaker <i>trial</i>. A trial is a set of steps called <i>trial components</i> that produce a machine learning model. A trial is part of a single SageMaker <i>experiment</i>.</p> <p>When you use SageMaker Studio or the SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the Amazon Web Services SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial and then use the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_Search.html">Search</a> API to search for the tags.</p> <p>To get a list of all your trials, call the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_ListTrials.html">ListTrials</a> API. To view a trial's properties, call the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeTrial.html">DescribeTrial</a> API. To create a trial component, call the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateTrialComponent.html">CreateTrialComponent</a> API.</p>
#
# POST /#X-Amz-Target=SageMaker.CreateTrial
# operationId: CreateTrial
# --MetadataProperties shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
export def "x-amz-target-sage-maker-create-trial CreateTrial" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-53
  TrialName: any
  --DisplayName: any
  ExperimentName: any
  --MetadataProperties: record # Metadata properties of the tracking entity, trial, or trial component. — shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
  --Tags: any
]: any -> record<TrialArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateTrial")
  let body = {TrialName: $TrialName, DisplayName: $DisplayName, ExperimentName: $ExperimentName, MetadataProperties: $MetadataProperties, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a <i>trial component</i>, which is a stage of a machine learning <i>trial</i>. A trial is composed of one or more trial components. A trial component can be used in multiple trials.</p> <p>Trial components include pre-processing jobs, training jobs, and batch transform jobs.</p> <p>When you use SageMaker Studio or the SageMaker Python SDK, all experiments, trials, and trial components are automatically tracked, logged, and indexed. When you use the Amazon Web Services SDK for Python (Boto), you must use the logging APIs provided by the SDK.</p> <p>You can add tags to a trial component and then use the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_Search.html">Search</a> API to search for the tags.</p>
#
# POST /#X-Amz-Target=SageMaker.CreateTrialComponent
# operationId: CreateTrialComponent
# --MetadataProperties shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
export def "x-amz-target-sage-maker-create-trial-component CreateTrialComponent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-54
  TrialComponentName: any
  --DisplayName: any
  --Status: any
  --StartTime: any
  --EndTime: any
  --Parameters: any
  --InputArtifacts: any
  --OutputArtifacts: any
  --MetadataProperties: record # Metadata properties of the tracking entity, trial, or trial component. — shape: {CommitId?: any, Repository?: any, GeneratedBy?: any, ProjectId?: any}
  --Tags: any
]: any -> record<TrialComponentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateTrialComponent")
  let body = {TrialComponentName: $TrialComponentName, DisplayName: $DisplayName, Status: $Status, StartTime: $StartTime, EndTime: $EndTime, Parameters: $Parameters, InputArtifacts: $InputArtifacts, OutputArtifacts: $OutputArtifacts, MetadataProperties: $MetadataProperties, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a user profile. A user profile represents a single user within a domain, and is the main way to reference a "person" for the purposes of sharing, reporting, and other user-oriented features. This entity is created when a user onboards to Amazon SageMaker Studio. If an administrator invites a person by email or imports them from IAM Identity Center, a user profile is automatically created. A user profile is the primary holder of settings for an individual user and has a reference to the user's private Amazon Elastic File System (EFS) home directory. 
#
# POST /#X-Amz-Target=SageMaker.CreateUserProfile
# operationId: CreateUserProfile
export def "x-amz-target-sage-maker-create-user-profile CreateUserProfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-55
  DomainId: any
  UserProfileName: any
  --SingleSignOnUserIdentifier: any
  --SingleSignOnUserValue: any
  --Tags: any
  --UserSettings: any
]: any -> record<UserProfileArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateUserProfile")
  let body = {DomainId: $DomainId, UserProfileName: $UserProfileName, SingleSignOnUserIdentifier: $SingleSignOnUserIdentifier, SingleSignOnUserValue: $SingleSignOnUserValue, Tags: $Tags, UserSettings: $UserSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Use this operation to create a workforce. This operation will return an error if a workforce already exists in the Amazon Web Services Region that you specify. You can only create one workforce in each Amazon Web Services Region per Amazon Web Services account.</p> <p>If you want to create a new workforce in an Amazon Web Services Region where a workforce already exists, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DeleteWorkforce.html">DeleteWorkforce</a> API operation to delete the existing workforce and then use <code>CreateWorkforce</code> to create a new workforce.</p> <p>To create a private workforce using Amazon Cognito, you must specify a Cognito user pool in <code>CognitoConfig</code>. You can also create an Amazon Cognito workforce using the Amazon SageMaker console. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-workforce-create-private.html"> Create a Private Workforce (Amazon Cognito)</a>.</p> <p>To create a private workforce using your own OIDC Identity Provider (IdP), specify your IdP configuration in <code>OidcConfig</code>. Your OIDC IdP must support <i>groups</i> because groups are used by Ground Truth and Amazon A2I to create work teams. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/sms-workforce-create-private-oidc.html"> Create a Private Workforce (OIDC IdP)</a>.</p>
#
# POST /#X-Amz-Target=SageMaker.CreateWorkforce
# operationId: CreateWorkforce
# --SourceIpConfig shape: {Cidrs: any}
export def "x-amz-target-sage-maker-create-workforce CreateWorkforce" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-56
  --CognitoConfig: any
  --OidcConfig: any
  --SourceIpConfig: record # A list of IP address ranges (<a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>). Used to create an allow list of IP addresses for a private workforce. Workers will only be able to login to their worker portal from an IP address within this range. By default, a workforce isn't restricted to specific IP addresses. — shape: {Cidrs: any}
  WorkforceName: any
  --Tags: any
  --WorkforceVpcConfig: any
]: any -> record<WorkforceArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateWorkforce")
  let body = {CognitoConfig: $CognitoConfig, OidcConfig: $OidcConfig, SourceIpConfig: $SourceIpConfig, WorkforceName: $WorkforceName, Tags: $Tags, WorkforceVpcConfig: $WorkforceVpcConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Creates a new work team for labeling your data. A work team is defined by one or more Amazon Cognito user pools. You must first create the user pools before you can create a work team.</p> <p>You cannot create more than 25 work teams in an account and region.</p>
#
# POST /#X-Amz-Target=SageMaker.CreateWorkteam
# operationId: CreateWorkteam
export def "x-amz-target-sage-maker-create-workteam CreateWorkteam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-57
  WorkteamName: any
  --WorkforceName: any
  MemberDefinitions: any
  Description: any
  --NotificationConfiguration: any
  --Tags: any
]: any -> record<WorkteamArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.CreateWorkteam")
  let body = {WorkteamName: $WorkteamName, WorkforceName: $WorkforceName, MemberDefinitions: $MemberDefinitions, Description: $Description, NotificationConfiguration: $NotificationConfiguration, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an action.
#
# POST /#X-Amz-Target=SageMaker.DeleteAction
# operationId: DeleteAction
export def "x-amz-target-sage-maker-delete-action DeleteAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-58
  ActionName: any
]: any -> record<ActionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteAction")
  let body = {ActionName: $ActionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes the specified algorithm from your account.
#
# POST /#X-Amz-Target=SageMaker.DeleteAlgorithm
# operationId: DeleteAlgorithm
export def "x-amz-target-sage-maker-delete-algorithm DeleteAlgorithm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-59
  AlgorithmName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteAlgorithm")
  let body = {AlgorithmName: $AlgorithmName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used to stop and delete an app.
#
# POST /#X-Amz-Target=SageMaker.DeleteApp
# operationId: DeleteApp
export def "x-amz-target-sage-maker-delete-app DeleteApp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-60
  DomainId: any
  --UserProfileName: any
  AppType: any
  AppName: any
  --SpaceName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteApp")
  let body = {DomainId: $DomainId, UserProfileName: $UserProfileName, AppType: $AppType, AppName: $AppName, SpaceName: $SpaceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an AppImageConfig.
#
# POST /#X-Amz-Target=SageMaker.DeleteAppImageConfig
# operationId: DeleteAppImageConfig
export def "x-amz-target-sage-maker-delete-app-image-config DeleteAppImageConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-61
  AppImageConfigName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteAppImageConfig")
  let body = {AppImageConfigName: $AppImageConfigName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an artifact. Either <code>ArtifactArn</code> or <code>Source</code> must be specified.
#
# POST /#X-Amz-Target=SageMaker.DeleteArtifact
# operationId: DeleteArtifact
export def "x-amz-target-sage-maker-delete-artifact DeleteArtifact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-62
  --ArtifactArn: any
  --Source: any
]: any -> record<ArtifactArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteArtifact")
  let body = {ArtifactArn: $ArtifactArn, Source: $Source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an association.
#
# POST /#X-Amz-Target=SageMaker.DeleteAssociation
# operationId: DeleteAssociation
export def "x-amz-target-sage-maker-delete-association DeleteAssociation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-63
  SourceArn: any
  DestinationArn: any
]: any -> record<SourceArn: record, DestinationArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteAssociation")
  let body = {SourceArn: $SourceArn, DestinationArn: $DestinationArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the specified Git repository from your account.
#
# POST /#X-Amz-Target=SageMaker.DeleteCodeRepository
# operationId: DeleteCodeRepository
export def "x-amz-target-sage-maker-delete-code-repository DeleteCodeRepository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-64
  CodeRepositoryName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteCodeRepository")
  let body = {CodeRepositoryName: $CodeRepositoryName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an context.
#
# POST /#X-Amz-Target=SageMaker.DeleteContext
# operationId: DeleteContext
export def "x-amz-target-sage-maker-delete-context DeleteContext" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-65
  ContextName: any
]: any -> record<ContextArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteContext")
  let body = {ContextName: $ContextName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a data quality monitoring job definition.
#
# POST /#X-Amz-Target=SageMaker.DeleteDataQualityJobDefinition
# operationId: DeleteDataQualityJobDefinition
export def "x-amz-target-sage-maker-delete-data-quality-job-definition DeleteDataQualityJobDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-66
  JobDefinitionName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteDataQualityJobDefinition")
  let body = {JobDefinitionName: $JobDefinitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a fleet.
#
# POST /#X-Amz-Target=SageMaker.DeleteDeviceFleet
# operationId: DeleteDeviceFleet
export def "x-amz-target-sage-maker-delete-device-fleet DeleteDeviceFleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-67
  DeviceFleetName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteDeviceFleet")
  let body = {DeviceFleetName: $DeviceFleetName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used to delete a domain. If you onboarded with IAM mode, you will need to delete your domain to onboard again using IAM Identity Center. Use with caution. All of the members of the domain will lose access to their EFS volume, including data, notebooks, and other artifacts. 
#
# POST /#X-Amz-Target=SageMaker.DeleteDomain
# operationId: DeleteDomain
export def "x-amz-target-sage-maker-delete-domain DeleteDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-68
  DomainId: any
  --RetentionPolicy: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteDomain")
  let body = {DomainId: $DomainId, RetentionPolicy: $RetentionPolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an edge deployment plan if (and only if) all the stages in the plan are inactive or there are no stages in the plan.
#
# POST /#X-Amz-Target=SageMaker.DeleteEdgeDeploymentPlan
# operationId: DeleteEdgeDeploymentPlan
export def "x-amz-target-sage-maker-delete-edge-deployment-plan DeleteEdgeDeploymentPlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-69
  EdgeDeploymentPlanName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteEdgeDeploymentPlan")
  let body = {EdgeDeploymentPlanName: $EdgeDeploymentPlanName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a stage in an edge deployment plan if (and only if) the stage is inactive.
#
# POST /#X-Amz-Target=SageMaker.DeleteEdgeDeploymentStage
# operationId: DeleteEdgeDeploymentStage
export def "x-amz-target-sage-maker-delete-edge-deployment-stage DeleteEdgeDeploymentStage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-70
  EdgeDeploymentPlanName: any
  StageName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteEdgeDeploymentStage")
  let body = {EdgeDeploymentPlanName: $EdgeDeploymentPlanName, StageName: $StageName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes an endpoint. SageMaker frees up all of the resources that were deployed when the endpoint was created. </p> <p>SageMaker retires any custom KMS key grants associated with the endpoint, meaning you don't need to use the <a href="http://docs.aws.amazon.com/kms/latest/APIReference/API_RevokeGrant.html">RevokeGrant</a> API call.</p> <p>When you delete your endpoint, SageMaker asynchronously deletes associated endpoint resources such as KMS key grants. You might still see these resources in your account for a few minutes after deleting your endpoint. Do not delete or revoke the permissions for your <code> <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateModel.html#sagemaker-CreateModel-request-ExecutionRoleArn">ExecutionRoleArn</a> </code>, otherwise SageMaker cannot delete these resources.</p>
#
# POST /#X-Amz-Target=SageMaker.DeleteEndpoint
# operationId: DeleteEndpoint
export def "x-amz-target-sage-maker-delete-endpoint DeleteEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-71
  EndpointName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteEndpoint")
  let body = {EndpointName: $EndpointName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes an endpoint configuration. The <code>DeleteEndpointConfig</code> API deletes only the specified configuration. It does not delete endpoints created using the configuration. </p> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. If you delete the <code>EndpointConfig</code> of an endpoint that is active or being created or updated you may lose visibility into the instance type the endpoint is using. The endpoint must be deleted in order to stop incurring charges.</p>
#
# POST /#X-Amz-Target=SageMaker.DeleteEndpointConfig
# operationId: DeleteEndpointConfig
export def "x-amz-target-sage-maker-delete-endpoint-config DeleteEndpointConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-72
  EndpointConfigName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteEndpointConfig")
  let body = {EndpointConfigName: $EndpointConfigName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an SageMaker experiment. All trials associated with the experiment must be deleted first. Use the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_ListTrials.html">ListTrials</a> API to get a list of the trials associated with the experiment.
#
# POST /#X-Amz-Target=SageMaker.DeleteExperiment
# operationId: DeleteExperiment
export def "x-amz-target-sage-maker-delete-experiment DeleteExperiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-73
  ExperimentName: any
]: any -> record<ExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteExperiment")
  let body = {ExperimentName: $ExperimentName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Delete the <code>FeatureGroup</code> and any data that was written to the <code>OnlineStore</code> of the <code>FeatureGroup</code>. Data cannot be accessed from the <code>OnlineStore</code> immediately after <code>DeleteFeatureGroup</code> is called. </p> <p>Data written into the <code>OfflineStore</code> will not be deleted. The Amazon Web Services Glue database and tables that are automatically created for your <code>OfflineStore</code> are not deleted. </p>
#
# POST /#X-Amz-Target=SageMaker.DeleteFeatureGroup
# operationId: DeleteFeatureGroup
export def "x-amz-target-sage-maker-delete-feature-group DeleteFeatureGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-74
  FeatureGroupName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteFeatureGroup")
  let body = {FeatureGroupName: $FeatureGroupName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the specified flow definition.
#
# POST /#X-Amz-Target=SageMaker.DeleteFlowDefinition
# operationId: DeleteFlowDefinition
export def "x-amz-target-sage-maker-delete-flow-definition DeleteFlowDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-75
  FlowDefinitionName: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteFlowDefinition")
  let body = {FlowDefinitionName: $FlowDefinitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Delete a hub.</p> <note> <p>Hub APIs are only callable through SageMaker Studio.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.DeleteHub
# operationId: DeleteHub
export def "x-amz-target-sage-maker-delete-hub DeleteHub" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-76
  HubName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteHub")
  let body = {HubName: $HubName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Delete the contents of a hub.</p> <note> <p>Hub APIs are only callable through SageMaker Studio.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.DeleteHubContent
# operationId: DeleteHubContent
export def "x-amz-target-sage-maker-delete-hub-content DeleteHubContent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-77
  HubName: any
  HubContentType: any
  HubContentName: any
  HubContentVersion: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteHubContent")
  let body = {HubName: $HubName, HubContentType: $HubContentType, HubContentName: $HubContentName, HubContentVersion: $HubContentVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Use this operation to delete a human task user interface (worker task template).</p> <p> To see a list of human task user interfaces (work task templates) in your account, use <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_ListHumanTaskUis.html">ListHumanTaskUis</a>. When you delete a worker task template, it no longer appears when you call <code>ListHumanTaskUis</code>.</p>
#
# POST /#X-Amz-Target=SageMaker.DeleteHumanTaskUi
# operationId: DeleteHumanTaskUi
export def "x-amz-target-sage-maker-delete-human-task-ui DeleteHumanTaskUi" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-78
  HumanTaskUiName: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteHumanTaskUi")
  let body = {HumanTaskUiName: $HumanTaskUiName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a SageMaker image and all versions of the image. The container images aren't deleted.
#
# POST /#X-Amz-Target=SageMaker.DeleteImage
# operationId: DeleteImage
export def "x-amz-target-sage-maker-delete-image DeleteImage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-79
  ImageName: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteImage")
  let body = {ImageName: $ImageName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a version of a SageMaker image. The container image the version represents isn't deleted.
#
# POST /#X-Amz-Target=SageMaker.DeleteImageVersion
# operationId: DeleteImageVersion
export def "x-amz-target-sage-maker-delete-image-version DeleteImageVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-80
  ImageName: any
  --Version: any
  --Alias: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteImageVersion")
  let body = {ImageName: $ImageName, Version: $Version, Alias: $Alias} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes an inference experiment.</p> <note> <p> This operation does not delete your endpoint, variants, or any underlying resources. This operation only deletes the metadata of your experiment. </p> </note>
#
# POST /#X-Amz-Target=SageMaker.DeleteInferenceExperiment
# operationId: DeleteInferenceExperiment
export def "x-amz-target-sage-maker-delete-inference-experiment DeleteInferenceExperiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-81
  Name: any
]: any -> record<InferenceExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteInferenceExperiment")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a model. The <code>DeleteModel</code> API deletes only the model entry that was created in SageMaker when you called the <code>CreateModel</code> API. It does not delete model artifacts, inference code, or the IAM role that you specified when creating the model. 
#
# POST /#X-Amz-Target=SageMaker.DeleteModel
# operationId: DeleteModel
export def "x-amz-target-sage-maker-delete-model DeleteModel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-82
  ModelName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModel")
  let body = {ModelName: $ModelName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an Amazon SageMaker model bias job definition.
#
# POST /#X-Amz-Target=SageMaker.DeleteModelBiasJobDefinition
# operationId: DeleteModelBiasJobDefinition
export def "x-amz-target-sage-maker-delete-model-bias-job-definition DeleteModelBiasJobDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-83
  JobDefinitionName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModelBiasJobDefinition")
  let body = {JobDefinitionName: $JobDefinitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an Amazon SageMaker Model Card.
#
# POST /#X-Amz-Target=SageMaker.DeleteModelCard
# operationId: DeleteModelCard
export def "x-amz-target-sage-maker-delete-model-card DeleteModelCard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-84
  ModelCardName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModelCard")
  let body = {ModelCardName: $ModelCardName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an Amazon SageMaker model explainability job definition.
#
# POST /#X-Amz-Target=SageMaker.DeleteModelExplainabilityJobDefinition
# operationId: DeleteModelExplainabilityJobDefinition
export def "x-amz-target-sage-maker-delete-model-explainability-job-definition DeleteModelExplainabilityJobDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-85
  JobDefinitionName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModelExplainabilityJobDefinition")
  let body = {JobDefinitionName: $JobDefinitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes a model package.</p> <p>A model package is used to create SageMaker models or list on Amazon Web Services Marketplace. Buyers can subscribe to model packages listed on Amazon Web Services Marketplace to create models in SageMaker.</p>
#
# POST /#X-Amz-Target=SageMaker.DeleteModelPackage
# operationId: DeleteModelPackage
export def "x-amz-target-sage-maker-delete-model-package DeleteModelPackage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-86
  ModelPackageName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModelPackage")
  let body = {ModelPackageName: $ModelPackageName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the specified model group.
#
# POST /#X-Amz-Target=SageMaker.DeleteModelPackageGroup
# operationId: DeleteModelPackageGroup
export def "x-amz-target-sage-maker-delete-model-package-group DeleteModelPackageGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-87
  ModelPackageGroupName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModelPackageGroup")
  let body = {ModelPackageGroupName: $ModelPackageGroupName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a model group resource policy.
#
# POST /#X-Amz-Target=SageMaker.DeleteModelPackageGroupPolicy
# operationId: DeleteModelPackageGroupPolicy
export def "x-amz-target-sage-maker-delete-model-package-group-policy DeleteModelPackageGroupPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-88
  ModelPackageGroupName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModelPackageGroupPolicy")
  let body = {ModelPackageGroupName: $ModelPackageGroupName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the secified model quality monitoring job definition.
#
# POST /#X-Amz-Target=SageMaker.DeleteModelQualityJobDefinition
# operationId: DeleteModelQualityJobDefinition
export def "x-amz-target-sage-maker-delete-model-quality-job-definition DeleteModelQualityJobDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-89
  JobDefinitionName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteModelQualityJobDefinition")
  let body = {JobDefinitionName: $JobDefinitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a monitoring schedule. Also stops the schedule had not already been stopped. This does not delete the job execution history of the monitoring schedule. 
#
# POST /#X-Amz-Target=SageMaker.DeleteMonitoringSchedule
# operationId: DeleteMonitoringSchedule
export def "x-amz-target-sage-maker-delete-monitoring-schedule DeleteMonitoringSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-90
  MonitoringScheduleName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteMonitoringSchedule")
  let body = {MonitoringScheduleName: $MonitoringScheduleName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p> Deletes an SageMaker notebook instance. Before you can delete a notebook instance, you must call the <code>StopNotebookInstance</code> API. </p> <important> <p>When you delete a notebook instance, you lose all of your data. SageMaker removes the ML compute instance, and deletes the ML storage volume and the network interface associated with the notebook instance. </p> </important>
#
# POST /#X-Amz-Target=SageMaker.DeleteNotebookInstance
# operationId: DeleteNotebookInstance
export def "x-amz-target-sage-maker-delete-notebook-instance DeleteNotebookInstance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-91
  NotebookInstanceName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteNotebookInstance")
  let body = {NotebookInstanceName: $NotebookInstanceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a notebook instance lifecycle configuration.
#
# POST /#X-Amz-Target=SageMaker.DeleteNotebookInstanceLifecycleConfig
# operationId: DeleteNotebookInstanceLifecycleConfig
export def "x-amz-target-sage-maker-delete-notebook-instance-lifecycle-config DeleteNotebookInstanceLifecycleConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-92
  NotebookInstanceLifecycleConfigName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteNotebookInstanceLifecycleConfig")
  let body = {NotebookInstanceLifecycleConfigName: $NotebookInstanceLifecycleConfigName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a pipeline if there are no running instances of the pipeline. To delete a pipeline, you must stop all running instances of the pipeline using the <code>StopPipelineExecution</code> API. When you delete a pipeline, all instances of the pipeline are deleted.
#
# POST /#X-Amz-Target=SageMaker.DeletePipeline
# operationId: DeletePipeline
export def "x-amz-target-sage-maker-delete-pipeline DeletePipeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-93
  PipelineName: any
  ClientRequestToken: any
]: any -> record<PipelineArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeletePipeline")
  let body = {PipelineName: $PipelineName, ClientRequestToken: $ClientRequestToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the specified project.
#
# POST /#X-Amz-Target=SageMaker.DeleteProject
# operationId: DeleteProject
export def "x-amz-target-sage-maker-delete-project DeleteProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-94
  ProjectName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteProject")
  let body = {ProjectName: $ProjectName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used to delete a space.
#
# POST /#X-Amz-Target=SageMaker.DeleteSpace
# operationId: DeleteSpace
export def "x-amz-target-sage-maker-delete-space DeleteSpace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-95
  DomainId: any
  SpaceName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteSpace")
  let body = {DomainId: $DomainId, SpaceName: $SpaceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the Studio Lifecycle Configuration. In order to delete the Lifecycle Configuration, there must be no running apps using the Lifecycle Configuration. You must also remove the Lifecycle Configuration from UserSettings in all Domains and UserProfiles.
#
# POST /#X-Amz-Target=SageMaker.DeleteStudioLifecycleConfig
# operationId: DeleteStudioLifecycleConfig
export def "x-amz-target-sage-maker-delete-studio-lifecycle-config DeleteStudioLifecycleConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-96
  StudioLifecycleConfigName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteStudioLifecycleConfig")
  let body = {StudioLifecycleConfigName: $StudioLifecycleConfigName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deletes the specified tags from an SageMaker resource.</p> <p>To list a resource's tags, use the <code>ListTags</code> API. </p> <note> <p>When you call this API to delete tags from a hyperparameter tuning job, the deleted tags are not removed from training jobs that the hyperparameter tuning job launched before you called this API.</p> </note> <note> <p>When you call this API to delete tags from a SageMaker Studio Domain or User Profile, the deleted tags are not removed from Apps that the SageMaker Studio Domain or User Profile launched before you called this API.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.DeleteTags
# operationId: DeleteTags
export def "x-amz-target-sage-maker-delete-tags DeleteTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-97
  ResourceArn: any
  TagKeys: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteTags")
  let body = {ResourceArn: $ResourceArn, TagKeys: $TagKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the specified trial. All trial components that make up the trial must be deleted first. Use the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeTrialComponent.html">DescribeTrialComponent</a> API to get the list of trial components.
#
# POST /#X-Amz-Target=SageMaker.DeleteTrial
# operationId: DeleteTrial
export def "x-amz-target-sage-maker-delete-trial DeleteTrial" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-98
  TrialName: any
]: any -> record<TrialArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteTrial")
  let body = {TrialName: $TrialName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the specified trial component. A trial component must be disassociated from all trials before the trial component can be deleted. To disassociate a trial component from a trial, call the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DisassociateTrialComponent.html">DisassociateTrialComponent</a> API.
#
# POST /#X-Amz-Target=SageMaker.DeleteTrialComponent
# operationId: DeleteTrialComponent
export def "x-amz-target-sage-maker-delete-trial-component DeleteTrialComponent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-99
  TrialComponentName: any
]: any -> record<TrialComponentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteTrialComponent")
  let body = {TrialComponentName: $TrialComponentName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a user profile. When a user profile is deleted, the user loses access to their EFS volume, including data, notebooks, and other artifacts.
#
# POST /#X-Amz-Target=SageMaker.DeleteUserProfile
# operationId: DeleteUserProfile
export def "x-amz-target-sage-maker-delete-user-profile DeleteUserProfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-100
  DomainId: any
  UserProfileName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteUserProfile")
  let body = {DomainId: $DomainId, UserProfileName: $UserProfileName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Use this operation to delete a workforce.</p> <p>If you want to create a new workforce in an Amazon Web Services Region where a workforce already exists, use this operation to delete the existing workforce and then use <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateWorkforce.html">CreateWorkforce</a> to create a new workforce.</p> <important> <p>If a private workforce contains one or more work teams, you must use the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DeleteWorkteam.html">DeleteWorkteam</a> operation to delete all work teams before you delete the workforce. If you try to delete a workforce that contains one or more work teams, you will recieve a <code>ResourceInUse</code> error.</p> </important>
#
# POST /#X-Amz-Target=SageMaker.DeleteWorkforce
# operationId: DeleteWorkforce
export def "x-amz-target-sage-maker-delete-workforce DeleteWorkforce" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-101
  WorkforceName: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteWorkforce")
  let body = {WorkforceName: $WorkforceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an existing work team. This operation can't be undone.
#
# POST /#X-Amz-Target=SageMaker.DeleteWorkteam
# operationId: DeleteWorkteam
export def "x-amz-target-sage-maker-delete-workteam DeleteWorkteam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-102
  WorkteamName: any
]: any -> record<Success: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeleteWorkteam")
  let body = {WorkteamName: $WorkteamName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deregisters the specified devices. After you deregister a device, you will need to re-register the devices.
#
# POST /#X-Amz-Target=SageMaker.DeregisterDevices
# operationId: DeregisterDevices
export def "x-amz-target-sage-maker-deregister-devices DeregisterDevices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-103
  DeviceFleetName: any
  DeviceNames: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DeregisterDevices")
  let body = {DeviceFleetName: $DeviceFleetName, DeviceNames: $DeviceNames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes an action.
#
# POST /#X-Amz-Target=SageMaker.DescribeAction
# operationId: DescribeAction
export def "x-amz-target-sage-maker-describe-action DescribeAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-104
  ActionName: any
]: any -> record<ActionName: record, ActionArn: record, Source: record<SourceUri: record, SourceType: record, SourceId: record>, ActionType: record, Description: record, Status: record, Properties: record, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, MetadataProperties: record<CommitId: record, Repository: record, GeneratedBy: record, ProjectId: record>, LineageGroupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeAction")
  let body = {ActionName: $ActionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a description of the specified algorithm that is in your account.
#
# POST /#X-Amz-Target=SageMaker.DescribeAlgorithm
# operationId: DescribeAlgorithm
export def "x-amz-target-sage-maker-describe-algorithm DescribeAlgorithm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-105
  AlgorithmName: any
]: any -> record<AlgorithmName: record, AlgorithmArn: record, AlgorithmDescription: record, CreationTime: record, TrainingSpecification: record<TrainingImage: record, TrainingImageDigest: record, SupportedHyperParameters: record, SupportedTrainingInstanceTypes: record, SupportsDistributedTraining: record, MetricDefinitions: record, TrainingChannels: record, SupportedTuningJobObjectiveMetrics: record>, InferenceSpecification: record<Containers: record, SupportedTransformInstanceTypes: record, SupportedRealtimeInferenceInstanceTypes: record, SupportedContentTypes: record, SupportedResponseMIMETypes: record>, ValidationSpecification: record<ValidationRole: record, ValidationProfiles: record>, AlgorithmStatus: record, AlgorithmStatusDetails: record<ValidationStatuses: record, ImageScanStatuses: record>, ProductId: record, CertifyForMarketplace: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeAlgorithm")
  let body = {AlgorithmName: $AlgorithmName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the app.
#
# POST /#X-Amz-Target=SageMaker.DescribeApp
# operationId: DescribeApp
export def "x-amz-target-sage-maker-describe-app DescribeApp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-106
  DomainId: any
  --UserProfileName: any
  AppType: any
  AppName: any
  --SpaceName: any
]: any -> record<AppArn: record, AppType: record, AppName: record, DomainId: record, UserProfileName: record, Status: record, LastHealthCheckTimestamp: record, LastUserActivityTimestamp: record, CreationTime: record, FailureReason: record, ResourceSpec: record<SageMakerImageArn: record, SageMakerImageVersionArn: record, InstanceType: record, LifecycleConfigArn: record>, SpaceName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeApp")
  let body = {DomainId: $DomainId, UserProfileName: $UserProfileName, AppType: $AppType, AppName: $AppName, SpaceName: $SpaceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes an AppImageConfig.
#
# POST /#X-Amz-Target=SageMaker.DescribeAppImageConfig
# operationId: DescribeAppImageConfig
export def "x-amz-target-sage-maker-describe-app-image-config DescribeAppImageConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-107
  AppImageConfigName: any
]: any -> record<AppImageConfigArn: record, AppImageConfigName: record, CreationTime: record, LastModifiedTime: record, KernelGatewayImageConfig: record<KernelSpecs: record, FileSystemConfig: record<MountPath: record, DefaultUid: record, DefaultGid: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeAppImageConfig")
  let body = {AppImageConfigName: $AppImageConfigName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes an artifact.
#
# POST /#X-Amz-Target=SageMaker.DescribeArtifact
# operationId: DescribeArtifact
export def "x-amz-target-sage-maker-describe-artifact DescribeArtifact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-108
  ArtifactArn: any
]: any -> record<ArtifactName: record, ArtifactArn: record, Source: record<SourceUri: record, SourceTypes: record>, ArtifactType: record, Properties: record, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, MetadataProperties: record<CommitId: record, Repository: record, GeneratedBy: record, ProjectId: record>, LineageGroupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeArtifact")
  let body = {ArtifactArn: $ArtifactArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about an Amazon SageMaker AutoML job.
#
# POST /#X-Amz-Target=SageMaker.DescribeAutoMLJob
# operationId: DescribeAutoMLJob
export def "x-amz-target-sage-maker-describe-auto-ml-job DescribeAutoMLJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-109
  AutoMLJobName: any
]: any -> record<AutoMLJobName: record, AutoMLJobArn: record, InputDataConfig: record, OutputDataConfig: record<KmsKeyId: record, S3OutputPath: record>, RoleArn: record, AutoMLJobObjective: record<MetricName: record>, ProblemType: record, AutoMLJobConfig: record<CompletionCriteria: record<MaxCandidates: record, MaxRuntimePerTrainingJobInSeconds: record, MaxAutoMLJobRuntimeInSeconds: record>, SecurityConfig: record<VolumeKmsKeyId: record, EnableInterContainerTrafficEncryption: record, VpcConfig: record>, DataSplitConfig: record<ValidationFraction: record>, CandidateGenerationConfig: record<FeatureSpecificationS3Uri: record, AlgorithmsConfig: record>, Mode: record>, CreationTime: record, EndTime: record, LastModifiedTime: record, FailureReason: record, PartialFailureReasons: record, BestCandidate: record<CandidateName: record, FinalAutoMLJobObjectiveMetric: record<Type: record, MetricName: record, Value: record, StandardMetricName: record>, ObjectiveStatus: record, CandidateSteps: record, CandidateStatus: record, InferenceContainers: record, CreationTime: record, EndTime: record, LastModifiedTime: record, FailureReason: record, CandidateProperties: record<CandidateArtifactLocations: record, CandidateMetrics: record>, InferenceContainerDefinitions: record>, AutoMLJobStatus: record, AutoMLJobSecondaryStatus: record, GenerateCandidateDefinitionsOnly: record, AutoMLJobArtifacts: record<CandidateDefinitionNotebookLocation: record, DataExplorationNotebookLocation: record>, ResolvedAttributes: record<AutoMLJobObjective: record<MetricName: record>, ProblemType: record, CompletionCriteria: record<MaxCandidates: record, MaxRuntimePerTrainingJobInSeconds: record, MaxAutoMLJobRuntimeInSeconds: record>>, ModelDeployConfig: record<AutoGenerateEndpointName: record, EndpointName: record>, ModelDeployResult: record<EndpointName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeAutoMLJob")
  let body = {AutoMLJobName: $AutoMLJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns information about an Amazon SageMaker AutoML V2 job.</p> <note> <p>This API action is callable through SageMaker Canvas only. Calling it directly from the CLI or an SDK results in an error.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.DescribeAutoMLJobV2
# operationId: DescribeAutoMLJobV2
export def "x-amz-target-sage-maker-describe-auto-ml-job-v2 DescribeAutoMLJobV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-110
  AutoMLJobName: any
]: any -> record<AutoMLJobName: record, AutoMLJobArn: record, AutoMLJobInputDataConfig: record, OutputDataConfig: record<KmsKeyId: record, S3OutputPath: record>, RoleArn: record, AutoMLJobObjective: record<MetricName: record>, AutoMLProblemTypeConfig: record<ImageClassificationJobConfig: record<CompletionCriteria: record>, TextClassificationJobConfig: record<CompletionCriteria: record, ContentColumn: record, TargetLabelColumn: record>>, CreationTime: record, EndTime: record, LastModifiedTime: record, FailureReason: record, PartialFailureReasons: record, BestCandidate: record<CandidateName: record, FinalAutoMLJobObjectiveMetric: record<Type: record, MetricName: record, Value: record, StandardMetricName: record>, ObjectiveStatus: record, CandidateSteps: record, CandidateStatus: record, InferenceContainers: record, CreationTime: record, EndTime: record, LastModifiedTime: record, FailureReason: record, CandidateProperties: record<CandidateArtifactLocations: record, CandidateMetrics: record>, InferenceContainerDefinitions: record>, AutoMLJobStatus: record, AutoMLJobSecondaryStatus: record, ModelDeployConfig: record<AutoGenerateEndpointName: record, EndpointName: record>, ModelDeployResult: record<EndpointName: record>, DataSplitConfig: record<ValidationFraction: record>, SecurityConfig: record<VolumeKmsKeyId: record, EnableInterContainerTrafficEncryption: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeAutoMLJobV2")
  let body = {AutoMLJobName: $AutoMLJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets details about the specified Git repository.
#
# POST /#X-Amz-Target=SageMaker.DescribeCodeRepository
# operationId: DescribeCodeRepository
export def "x-amz-target-sage-maker-describe-code-repository DescribeCodeRepository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-111
  CodeRepositoryName: any
]: any -> record<CodeRepositoryName: record, CodeRepositoryArn: record, CreationTime: record, LastModifiedTime: record, GitConfig: record<RepositoryUrl: record, Branch: record, SecretArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeCodeRepository")
  let body = {CodeRepositoryName: $CodeRepositoryName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns information about a model compilation job.</p> <p>To create a model compilation job, use <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateCompilationJob.html">CreateCompilationJob</a>. To get information about multiple model compilation jobs, use <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_ListCompilationJobs.html">ListCompilationJobs</a>.</p>
#
# POST /#X-Amz-Target=SageMaker.DescribeCompilationJob
# operationId: DescribeCompilationJob
export def "x-amz-target-sage-maker-describe-compilation-job DescribeCompilationJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-112
  CompilationJobName: any
]: any -> record<CompilationJobName: record, CompilationJobArn: record, CompilationJobStatus: record, CompilationStartTime: record, CompilationEndTime: record, StoppingCondition: record<MaxRuntimeInSeconds: record, MaxWaitTimeInSeconds: record>, InferenceImage: record, ModelPackageVersionArn: record, CreationTime: record, LastModifiedTime: record, FailureReason: record, ModelArtifacts: record<S3ModelArtifacts: record>, ModelDigests: record<ArtifactDigest: record>, RoleArn: record, InputConfig: record<S3Uri: record, DataInputConfig: record, Framework: record, FrameworkVersion: record>, OutputConfig: record<S3OutputLocation: record, TargetDevice: record, TargetPlatform: record<Os: record, Arch: record, Accelerator: record>, CompilerOptions: record, KmsKeyId: record>, VpcConfig: record<SecurityGroupIds: record, Subnets: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeCompilationJob")
  let body = {CompilationJobName: $CompilationJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes a context.
#
# POST /#X-Amz-Target=SageMaker.DescribeContext
# operationId: DescribeContext
export def "x-amz-target-sage-maker-describe-context DescribeContext" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-113
  ContextName: any
]: any -> record<ContextName: record, ContextArn: record, Source: record<SourceUri: record, SourceType: record, SourceId: record>, ContextType: record, Description: record, Properties: record, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LineageGroupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeContext")
  let body = {ContextName: $ContextName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the details of a data quality monitoring job definition.
#
# POST /#X-Amz-Target=SageMaker.DescribeDataQualityJobDefinition
# operationId: DescribeDataQualityJobDefinition
export def "x-amz-target-sage-maker-describe-data-quality-job-definition DescribeDataQualityJobDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-114
  JobDefinitionName: any
]: any -> record<JobDefinitionArn: record, JobDefinitionName: record, CreationTime: record, DataQualityBaselineConfig: record<BaseliningJobName: record, ConstraintsResource: record<S3Uri: record>, StatisticsResource: record<S3Uri: record>>, DataQualityAppSpecification: record<ImageUri: record, ContainerEntrypoint: record, ContainerArguments: record, RecordPreprocessorSourceUri: record, PostAnalyticsProcessorSourceUri: record, Environment: record>, DataQualityJobInput: record<EndpointInput: record<EndpointName: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>, BatchTransformInput: record<DataCapturedDestinationS3Uri: record, DatasetFormat: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>>, DataQualityJobOutputConfig: record<MonitoringOutputs: record, KmsKeyId: record>, JobResources: record<ClusterConfig: record<InstanceCount: record, InstanceType: record, VolumeSizeInGB: record, VolumeKmsKeyId: record>>, NetworkConfig: record<EnableInterContainerTrafficEncryption: record, EnableNetworkIsolation: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>>, RoleArn: record, StoppingCondition: record<MaxRuntimeInSeconds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeDataQualityJobDefinition")
  let body = {JobDefinitionName: $JobDefinitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the device.
#
# POST /#X-Amz-Target=SageMaker.DescribeDevice
# operationId: DescribeDevice
export def "x-amz-target-sage-maker-describe-device DescribeDevice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-115
  --NextToken: any
  DeviceName: any
  DeviceFleetName: any
]: any -> record<DeviceArn: record, DeviceName: record, Description: record, DeviceFleetName: record, IotThingName: record, RegistrationTime: record, LatestHeartbeat: record, Models: record, MaxModels: record, NextToken: record, AgentVersion: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeDevice")
  let body = {NextToken: $NextToken, DeviceName: $DeviceName, DeviceFleetName: $DeviceFleetName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# A description of the fleet the device belongs to.
#
# POST /#X-Amz-Target=SageMaker.DescribeDeviceFleet
# operationId: DescribeDeviceFleet
export def "x-amz-target-sage-maker-describe-device-fleet DescribeDeviceFleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-116
  DeviceFleetName: any
]: any -> record<DeviceFleetName: record, DeviceFleetArn: record, OutputConfig: record<S3OutputLocation: record, KmsKeyId: record, PresetDeploymentType: record, PresetDeploymentConfig: record>, Description: record, CreationTime: record, LastModifiedTime: record, RoleArn: record, IotRoleAlias: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeDeviceFleet")
  let body = {DeviceFleetName: $DeviceFleetName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# The description of the domain.
#
# POST /#X-Amz-Target=SageMaker.DescribeDomain
# operationId: DescribeDomain
export def "x-amz-target-sage-maker-describe-domain DescribeDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-117
  DomainId: any
]: any -> record<DomainArn: record, DomainId: record, DomainName: record, HomeEfsFileSystemId: record, SingleSignOnManagedApplicationInstanceId: record, Status: record, CreationTime: record, LastModifiedTime: record, FailureReason: record, AuthMode: record, DefaultUserSettings: record<ExecutionRole: record, SecurityGroups: record, SharingSettings: record<NotebookOutputOption: record, S3OutputPath: record, S3KmsKeyId: record>, JupyterServerAppSettings: record<DefaultResourceSpec: record, LifecycleConfigArns: record, CodeRepositories: record>, KernelGatewayAppSettings: record<DefaultResourceSpec: record, CustomImages: record, LifecycleConfigArns: record>, TensorBoardAppSettings: record<DefaultResourceSpec: record>, RStudioServerProAppSettings: record<AccessStatus: record, UserGroup: record>, RSessionAppSettings: record<DefaultResourceSpec: record, CustomImages: record>, CanvasAppSettings: record<TimeSeriesForecastingSettings: record, ModelRegisterSettings: record>>, AppNetworkAccessType: record, HomeEfsFileSystemKmsKeyId: record, SubnetIds: record, Url: record, VpcId: record, KmsKeyId: record, DomainSettings: record<SecurityGroupIds: record, RStudioServerProDomainSettings: record<DomainExecutionRoleArn: record, RStudioConnectUrl: record, RStudioPackageManagerUrl: record, DefaultResourceSpec: record>, ExecutionRoleIdentityConfig: record>, AppSecurityGroupManagement: record, SecurityGroupIdForDomainBoundary: record, DefaultSpaceSettings: record<ExecutionRole: record, SecurityGroups: record, JupyterServerAppSettings: record<DefaultResourceSpec: record, LifecycleConfigArns: record, CodeRepositories: record>, KernelGatewayAppSettings: record<DefaultResourceSpec: record, CustomImages: record, LifecycleConfigArns: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeDomain")
  let body = {DomainId: $DomainId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes an edge deployment plan with deployment status per stage.
#
# POST /#X-Amz-Target=SageMaker.DescribeEdgeDeploymentPlan
# operationId: DescribeEdgeDeploymentPlan
export def "x-amz-target-sage-maker-describe-edge-deployment-plan DescribeEdgeDeploymentPlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-118
  EdgeDeploymentPlanName: any
  --NextToken: any
  --MaxResults: any
]: any -> record<EdgeDeploymentPlanArn: record, EdgeDeploymentPlanName: record, ModelConfigs: record, DeviceFleetName: record, EdgeDeploymentSuccess: record, EdgeDeploymentPending: record, EdgeDeploymentFailed: record, Stages: record, NextToken: record, CreationTime: record, LastModifiedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeEdgeDeploymentPlan")
  let body = {EdgeDeploymentPlanName: $EdgeDeploymentPlanName, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# A description of edge packaging jobs.
#
# POST /#X-Amz-Target=SageMaker.DescribeEdgePackagingJob
# operationId: DescribeEdgePackagingJob
export def "x-amz-target-sage-maker-describe-edge-packaging-job DescribeEdgePackagingJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-119
  EdgePackagingJobName: any
]: any -> record<EdgePackagingJobArn: record, EdgePackagingJobName: record, CompilationJobName: record, ModelName: record, ModelVersion: record, RoleArn: record, OutputConfig: record<S3OutputLocation: record, KmsKeyId: record, PresetDeploymentType: record, PresetDeploymentConfig: record>, ResourceKey: record, EdgePackagingJobStatus: record, EdgePackagingJobStatusMessage: record, CreationTime: record, LastModifiedTime: record, ModelArtifact: record, ModelSignature: record, PresetDeploymentOutput: record<Type: record, Artifact: record, Status: record, StatusMessage: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeEdgePackagingJob")
  let body = {EdgePackagingJobName: $EdgePackagingJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the description of an endpoint.
#
# POST /#X-Amz-Target=SageMaker.DescribeEndpoint
# operationId: DescribeEndpoint
export def "x-amz-target-sage-maker-describe-endpoint DescribeEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-120
  EndpointName: any
]: any -> record<EndpointName: record, EndpointArn: record, EndpointConfigName: record, ProductionVariants: record, DataCaptureConfig: record<EnableCapture: record, CaptureStatus: record, CurrentSamplingPercentage: record, DestinationS3Uri: record, KmsKeyId: record>, EndpointStatus: record, FailureReason: record, CreationTime: record, LastModifiedTime: record, LastDeploymentConfig: record<BlueGreenUpdatePolicy: record<TrafficRoutingConfiguration: record, TerminationWaitInSeconds: record, MaximumExecutionTimeoutInSeconds: record>, AutoRollbackConfiguration: record<Alarms: record>>, AsyncInferenceConfig: record<ClientConfig: record<MaxConcurrentInvocationsPerInstance: record>, OutputConfig: record<KmsKeyId: record, S3OutputPath: record, NotificationConfig: record, S3FailurePath: record>>, PendingDeploymentSummary: record<EndpointConfigName: record, ProductionVariants: record, StartTime: record, ShadowProductionVariants: record>, ExplainerConfig: record<ClarifyExplainerConfig: record<EnableExplanations: record, InferenceConfig: record, ShapConfig: record>>, ShadowProductionVariants: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeEndpoint")
  let body = {EndpointName: $EndpointName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the description of an endpoint configuration created using the <code>CreateEndpointConfig</code> API.
#
# POST /#X-Amz-Target=SageMaker.DescribeEndpointConfig
# operationId: DescribeEndpointConfig
export def "x-amz-target-sage-maker-describe-endpoint-config DescribeEndpointConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-121
  EndpointConfigName: any
]: any -> record<EndpointConfigName: record, EndpointConfigArn: record, ProductionVariants: record, DataCaptureConfig: record<EnableCapture: record, InitialSamplingPercentage: record, DestinationS3Uri: record, KmsKeyId: record, CaptureOptions: record, CaptureContentTypeHeader: record<CsvContentTypes: record, JsonContentTypes: record>>, KmsKeyId: record, CreationTime: record, AsyncInferenceConfig: record<ClientConfig: record<MaxConcurrentInvocationsPerInstance: record>, OutputConfig: record<KmsKeyId: record, S3OutputPath: record, NotificationConfig: record, S3FailurePath: record>>, ExplainerConfig: record<ClarifyExplainerConfig: record<EnableExplanations: record, InferenceConfig: record, ShapConfig: record>>, ShadowProductionVariants: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeEndpointConfig")
  let body = {EndpointConfigName: $EndpointConfigName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Provides a list of an experiment's properties.
#
# POST /#X-Amz-Target=SageMaker.DescribeExperiment
# operationId: DescribeExperiment
export def "x-amz-target-sage-maker-describe-experiment DescribeExperiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-122
  ExperimentName: any
]: any -> record<ExperimentName: record, ExperimentArn: record, DisplayName: record, Source: record<SourceArn: record, SourceType: record>, Description: record, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeExperiment")
  let body = {ExperimentName: $ExperimentName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use this operation to describe a <code>FeatureGroup</code>. The response includes information on the creation time, <code>FeatureGroup</code> name, the unique identifier for each <code>FeatureGroup</code>, and more.
#
# POST /#X-Amz-Target=SageMaker.DescribeFeatureGroup
# operationId: DescribeFeatureGroup
export def "x-amz-target-sage-maker-describe-feature-group DescribeFeatureGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-123
  FeatureGroupName: any
  --NextToken: any
]: any -> record<FeatureGroupArn: record, FeatureGroupName: record, RecordIdentifierFeatureName: record, EventTimeFeatureName: record, FeatureDefinitions: record, CreationTime: record, LastModifiedTime: record, OnlineStoreConfig: record<SecurityConfig: record<KmsKeyId: record>, EnableOnlineStore: record>, OfflineStoreConfig: record<S3StorageConfig: record<S3Uri: record, KmsKeyId: record, ResolvedOutputS3Uri: record>, DisableGlueTableCreation: record, DataCatalogConfig: record<TableName: record, Catalog: record, Database: record>, TableFormat: record>, RoleArn: record, FeatureGroupStatus: record, OfflineStoreStatus: record<Status: record, BlockedReason: record>, LastUpdateStatus: record<Status: record, FailureReason: record>, FailureReason: record, Description: record, NextToken: record, OnlineStoreTotalSizeBytes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeFeatureGroup")
  let body = {FeatureGroupName: $FeatureGroupName, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Shows the metadata for a feature within a feature group.
#
# POST /#X-Amz-Target=SageMaker.DescribeFeatureMetadata
# operationId: DescribeFeatureMetadata
export def "x-amz-target-sage-maker-describe-feature-metadata DescribeFeatureMetadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-124
  FeatureGroupName: any
  FeatureName: any
]: any -> record<FeatureGroupArn: record, FeatureGroupName: record, FeatureName: record, FeatureType: record, CreationTime: record, LastModifiedTime: record, Description: record, Parameters: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeFeatureMetadata")
  let body = {FeatureGroupName: $FeatureGroupName, FeatureName: $FeatureName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about the specified flow definition.
#
# POST /#X-Amz-Target=SageMaker.DescribeFlowDefinition
# operationId: DescribeFlowDefinition
export def "x-amz-target-sage-maker-describe-flow-definition DescribeFlowDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-125
  FlowDefinitionName: any
]: any -> record<FlowDefinitionArn: record, FlowDefinitionName: record, FlowDefinitionStatus: record, CreationTime: record, HumanLoopRequestSource: record<AwsManagedHumanLoopRequestSource: record>, HumanLoopActivationConfig: record<HumanLoopActivationConditionsConfig: record<HumanLoopActivationConditions: record>>, HumanLoopConfig: record<WorkteamArn: record, HumanTaskUiArn: record, TaskTitle: record, TaskDescription: record, TaskCount: record, TaskAvailabilityLifetimeInSeconds: record, TaskTimeLimitInSeconds: record, TaskKeywords: record, PublicWorkforceTaskPrice: record<AmountInUsd: record>>, OutputConfig: record<S3OutputPath: record, KmsKeyId: record>, RoleArn: record, FailureReason: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeFlowDefinition")
  let body = {FlowDefinitionName: $FlowDefinitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Describe a hub.</p> <note> <p>Hub APIs are only callable through SageMaker Studio.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.DescribeHub
# operationId: DescribeHub
export def "x-amz-target-sage-maker-describe-hub DescribeHub" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-126
  HubName: any
]: any -> record<HubName: record, HubArn: record, HubDisplayName: record, HubDescription: record, HubSearchKeywords: record, S3StorageConfig: record<S3OutputPath: record>, HubStatus: record, FailureReason: record, CreationTime: record, LastModifiedTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeHub")
  let body = {HubName: $HubName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Describe the content of a hub.</p> <note> <p>Hub APIs are only callable through SageMaker Studio.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.DescribeHubContent
# operationId: DescribeHubContent
export def "x-amz-target-sage-maker-describe-hub-content DescribeHubContent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-127
  HubName: any
  HubContentType: any
  HubContentName: any
  --HubContentVersion: any
]: any -> record<HubContentName: record, HubContentArn: record, HubContentVersion: record, HubContentType: record, DocumentSchemaVersion: record, HubName: record, HubArn: record, HubContentDisplayName: record, HubContentDescription: record, HubContentMarkdown: record, HubContentDocument: record, HubContentSearchKeywords: record, HubContentDependencies: record, HubContentStatus: record, FailureReason: record, CreationTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeHubContent")
  let body = {HubName: $HubName, HubContentType: $HubContentType, HubContentName: $HubContentName, HubContentVersion: $HubContentVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about the requested human task user interface (worker task template).
#
# POST /#X-Amz-Target=SageMaker.DescribeHumanTaskUi
# operationId: DescribeHumanTaskUi
export def "x-amz-target-sage-maker-describe-human-task-ui DescribeHumanTaskUi" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-128
  HumanTaskUiName: any
]: any -> record<HumanTaskUiArn: record, HumanTaskUiName: record, HumanTaskUiStatus: record, CreationTime: record, UiTemplate: record<Url: record, ContentSha256: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeHumanTaskUi")
  let body = {HumanTaskUiName: $HumanTaskUiName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a description of a hyperparameter tuning job.
#
# POST /#X-Amz-Target=SageMaker.DescribeHyperParameterTuningJob
# operationId: DescribeHyperParameterTuningJob
export def "x-amz-target-sage-maker-describe-hyper-parameter-tuning-job DescribeHyperParameterTuningJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-129
  HyperParameterTuningJobName: any
]: any -> record<HyperParameterTuningJobName: record, HyperParameterTuningJobArn: record, HyperParameterTuningJobConfig: record<Strategy: record, StrategyConfig: record<HyperbandStrategyConfig: record>, HyperParameterTuningJobObjective: record<Type: record, MetricName: record>, ResourceLimits: record<MaxNumberOfTrainingJobs: record, MaxParallelTrainingJobs: record, MaxRuntimeInSeconds: record>, ParameterRanges: record<IntegerParameterRanges: record, ContinuousParameterRanges: record, CategoricalParameterRanges: record>, TrainingJobEarlyStoppingType: record, TuningJobCompletionCriteria: record<TargetObjectiveMetricValue: record, BestObjectiveNotImproving: record, ConvergenceDetected: record>, RandomSeed: record>, TrainingJobDefinition: record<DefinitionName: record, TuningObjective: record<Type: record, MetricName: record>, HyperParameterRanges: record<IntegerParameterRanges: record, ContinuousParameterRanges: record, CategoricalParameterRanges: record>, StaticHyperParameters: record, AlgorithmSpecification: record<TrainingImage: record, TrainingInputMode: string, AlgorithmName: record, MetricDefinitions: record>, RoleArn: record, InputDataConfig: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>, OutputDataConfig: record<KmsKeyId: record, S3OutputPath: record>, ResourceConfig: record<InstanceType: record, InstanceCount: record, VolumeSizeInGB: record, VolumeKmsKeyId: record, InstanceGroups: record, KeepAlivePeriodInSeconds: record>, StoppingCondition: record<MaxRuntimeInSeconds: record, MaxWaitTimeInSeconds: record>, EnableNetworkIsolation: record, EnableInterContainerTrafficEncryption: record, EnableManagedSpotTraining: record, CheckpointConfig: record<S3Uri: record, LocalPath: record>, RetryStrategy: record<MaximumRetryAttempts: record>, HyperParameterTuningResourceConfig: record<InstanceType: record, InstanceCount: record, VolumeSizeInGB: record, VolumeKmsKeyId: record, AllocationStrategy: record, InstanceConfigs: record>, Environment: record>, TrainingJobDefinitions: record, HyperParameterTuningJobStatus: record, CreationTime: record, HyperParameterTuningEndTime: record, LastModifiedTime: record, TrainingJobStatusCounters: record<Completed: record, InProgress: record, RetryableError: record, NonRetryableError: record, Stopped: record>, ObjectiveStatusCounters: record<Succeeded: record, Pending: record, Failed: record>, BestTrainingJob: record<TrainingJobDefinitionName: record, TrainingJobName: record, TrainingJobArn: record, TuningJobName: record, CreationTime: record, TrainingStartTime: record, TrainingEndTime: record, TrainingJobStatus: record, TunedHyperParameters: record, FailureReason: record, FinalHyperParameterTuningJobObjectiveMetric: record<Type: record, MetricName: record, Value: record>, ObjectiveStatus: record>, OverallBestTrainingJob: record<TrainingJobDefinitionName: record, TrainingJobName: record, TrainingJobArn: record, TuningJobName: record, CreationTime: record, TrainingStartTime: record, TrainingEndTime: record, TrainingJobStatus: record, TunedHyperParameters: record, FailureReason: record, FinalHyperParameterTuningJobObjectiveMetric: record<Type: record, MetricName: record, Value: record>, ObjectiveStatus: record>, WarmStartConfig: record<ParentHyperParameterTuningJobs: record, WarmStartType: record>, FailureReason: record, TuningJobCompletionDetails: record<NumberOfTrainingJobsObjectiveNotImproving: record, ConvergenceDetectedTime: record>, ConsumedResources: record<RuntimeInSeconds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeHyperParameterTuningJob")
  let body = {HyperParameterTuningJobName: $HyperParameterTuningJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes a SageMaker image.
#
# POST /#X-Amz-Target=SageMaker.DescribeImage
# operationId: DescribeImage
export def "x-amz-target-sage-maker-describe-image DescribeImage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-130
  ImageName: any
]: any -> record<CreationTime: record, Description: record, DisplayName: record, FailureReason: record, ImageArn: record, ImageName: record, ImageStatus: record, LastModifiedTime: record, RoleArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeImage")
  let body = {ImageName: $ImageName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes a version of a SageMaker image.
#
# POST /#X-Amz-Target=SageMaker.DescribeImageVersion
# operationId: DescribeImageVersion
export def "x-amz-target-sage-maker-describe-image-version DescribeImageVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-131
  ImageName: any
  --Version: any
  --Alias: any
]: any -> record<BaseImage: record, ContainerImage: record, CreationTime: record, FailureReason: record, ImageArn: record, ImageVersionArn: record, ImageVersionStatus: record, LastModifiedTime: record, Version: record, VendorGuidance: record, JobType: record, MLFramework: record, ProgrammingLang: record, Processor: record, Horovod: record, ReleaseNotes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeImageVersion")
  let body = {ImageName: $ImageName, Version: $Version, Alias: $Alias} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns details about an inference experiment.
#
# POST /#X-Amz-Target=SageMaker.DescribeInferenceExperiment
# operationId: DescribeInferenceExperiment
export def "x-amz-target-sage-maker-describe-inference-experiment DescribeInferenceExperiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-132
  Name: any
]: any -> record<Arn: record, Name: record, Type: record, Schedule: record<StartTime: record, EndTime: record>, Status: record, StatusReason: record, Description: record, CreationTime: record, CompletionTime: record, LastModifiedTime: record, RoleArn: record, EndpointMetadata: record<EndpointName: record, EndpointConfigName: record, EndpointStatus: record, FailureReason: record>, ModelVariants: record, DataStorageConfig: record<Destination: record, KmsKey: record, ContentType: record<CsvContentTypes: record, JsonContentTypes: record>>, ShadowModeConfig: record<SourceModelVariantName: record, ShadowModelVariants: record>, KmsKey: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeInferenceExperiment")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Provides the results of the Inference Recommender job. One or more recommendation jobs are returned.
#
# POST /#X-Amz-Target=SageMaker.DescribeInferenceRecommendationsJob
# operationId: DescribeInferenceRecommendationsJob
export def "x-amz-target-sage-maker-describe-inference-recommendations-job DescribeInferenceRecommendationsJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-133
  JobName: any
]: any -> record<JobName: record, JobDescription: record, JobType: record, JobArn: record, RoleArn: record, Status: record, CreationTime: record, CompletionTime: record, LastModifiedTime: record, FailureReason: record, InputConfig: record<ModelPackageVersionArn: record, JobDurationInSeconds: record, TrafficPattern: record<TrafficType: record, Phases: record>, ResourceLimit: record<MaxNumberOfTests: record, MaxParallelOfTests: record>, EndpointConfigurations: record, VolumeKmsKeyId: record, ContainerConfig: record<Domain: record, Task: record, Framework: record, FrameworkVersion: record, PayloadConfig: record, NearestModelName: record, SupportedInstanceTypes: record, DataInputConfig: record>, Endpoints: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>, ModelName: record>, StoppingConditions: record<MaxInvocations: record, ModelLatencyThresholds: record>, InferenceRecommendations: record, EndpointPerformances: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeInferenceRecommendationsJob")
  let body = {JobName: $JobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets information about a labeling job.
#
# POST /#X-Amz-Target=SageMaker.DescribeLabelingJob
# operationId: DescribeLabelingJob
export def "x-amz-target-sage-maker-describe-labeling-job DescribeLabelingJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-134
  LabelingJobName: any
]: any -> record<LabelingJobStatus: record, LabelCounters: record<TotalLabeled: record, HumanLabeled: record, MachineLabeled: record, FailedNonRetryableError: record, Unlabeled: record>, FailureReason: record, CreationTime: record, LastModifiedTime: record, JobReferenceCode: record, LabelingJobName: record, LabelingJobArn: record, LabelAttributeName: record, InputConfig: record<DataSource: record<S3DataSource: record, SnsDataSource: record>, DataAttributes: record<ContentClassifiers: record>>, OutputConfig: record<S3OutputPath: record, KmsKeyId: record, SnsTopicArn: record>, RoleArn: record, LabelCategoryConfigS3Uri: record, StoppingConditions: record<MaxHumanLabeledObjectCount: record, MaxPercentageOfInputDatasetLabeled: record>, LabelingJobAlgorithmsConfig: record<LabelingJobAlgorithmSpecificationArn: record, InitialActiveLearningModelArn: record, LabelingJobResourceConfig: record<VolumeKmsKeyId: record, VpcConfig: record>>, HumanTaskConfig: record<WorkteamArn: record, UiConfig: record<UiTemplateS3Uri: record, HumanTaskUiArn: record>, PreHumanTaskLambdaArn: record, TaskKeywords: record, TaskTitle: record, TaskDescription: record, NumberOfHumanWorkersPerDataObject: record, TaskTimeLimitInSeconds: record, TaskAvailabilityLifetimeInSeconds: record, MaxConcurrentTaskCount: record, AnnotationConsolidationConfig: record<AnnotationConsolidationLambdaArn: record>, PublicWorkforceTaskPrice: record<AmountInUsd: record>>, Tags: record, LabelingJobOutput: record<OutputDatasetS3Uri: record, FinalActiveLearningModelArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeLabelingJob")
  let body = {LabelingJobName: $LabelingJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Provides a list of properties for the requested lineage group. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/xaccount-lineage-tracking.html"> Cross-Account Lineage Tracking </a> in the <i>Amazon SageMaker Developer Guide</i>.
#
# POST /#X-Amz-Target=SageMaker.DescribeLineageGroup
# operationId: DescribeLineageGroup
export def "x-amz-target-sage-maker-describe-lineage-group DescribeLineageGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-135
  LineageGroupName: any
]: any -> record<LineageGroupName: record, LineageGroupArn: record, DisplayName: record, Description: record, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeLineageGroup")
  let body = {LineageGroupName: $LineageGroupName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes a model that you created using the <code>CreateModel</code> API.
#
# POST /#X-Amz-Target=SageMaker.DescribeModel
# operationId: DescribeModel
export def "x-amz-target-sage-maker-describe-model DescribeModel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-136
  ModelName: any
]: any -> record<ModelName: record, PrimaryContainer: record<ContainerHostname: record, Image: record, ImageConfig: record<RepositoryAccessMode: record, RepositoryAuthConfig: record>, Mode: record, ModelDataUrl: record, Environment: record, ModelPackageName: record, InferenceSpecificationName: record, MultiModelConfig: record<ModelCacheSetting: record>>, Containers: record, InferenceExecutionConfig: record<Mode: record>, ExecutionRoleArn: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>, CreationTime: record, ModelArn: record, EnableNetworkIsolation: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModel")
  let body = {ModelName: $ModelName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a description of a model bias job definition.
#
# POST /#X-Amz-Target=SageMaker.DescribeModelBiasJobDefinition
# operationId: DescribeModelBiasJobDefinition
export def "x-amz-target-sage-maker-describe-model-bias-job-definition DescribeModelBiasJobDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-137
  JobDefinitionName: any
]: any -> record<JobDefinitionArn: record, JobDefinitionName: record, CreationTime: record, ModelBiasBaselineConfig: record<BaseliningJobName: record, ConstraintsResource: record<S3Uri: record>>, ModelBiasAppSpecification: record<ImageUri: record, ConfigUri: record, Environment: record>, ModelBiasJobInput: record<EndpointInput: record<EndpointName: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>, BatchTransformInput: record<DataCapturedDestinationS3Uri: record, DatasetFormat: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>, GroundTruthS3Input: record<S3Uri: record>>, ModelBiasJobOutputConfig: record<MonitoringOutputs: record, KmsKeyId: record>, JobResources: record<ClusterConfig: record<InstanceCount: record, InstanceType: record, VolumeSizeInGB: record, VolumeKmsKeyId: record>>, NetworkConfig: record<EnableInterContainerTrafficEncryption: record, EnableNetworkIsolation: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>>, RoleArn: record, StoppingCondition: record<MaxRuntimeInSeconds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModelBiasJobDefinition")
  let body = {JobDefinitionName: $JobDefinitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the content, creation time, and security configuration of an Amazon SageMaker Model Card.
#
# POST /#X-Amz-Target=SageMaker.DescribeModelCard
# operationId: DescribeModelCard
export def "x-amz-target-sage-maker-describe-model-card DescribeModelCard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-138
  ModelCardName: any
  --ModelCardVersion: any
]: any -> record<ModelCardArn: record, ModelCardName: record, ModelCardVersion: record, Content: record, ModelCardStatus: record, SecurityConfig: record<KmsKeyId: record>, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, ModelCardProcessingStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModelCard")
  let body = {ModelCardName: $ModelCardName, ModelCardVersion: $ModelCardVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes an Amazon SageMaker Model Card export job.
#
# POST /#X-Amz-Target=SageMaker.DescribeModelCardExportJob
# operationId: DescribeModelCardExportJob
export def "x-amz-target-sage-maker-describe-model-card-export-job DescribeModelCardExportJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-139
  ModelCardExportJobArn: any
]: any -> record<ModelCardExportJobName: record, ModelCardExportJobArn: record, Status: record, ModelCardName: record, ModelCardVersion: record, OutputConfig: record<S3OutputPath: record>, CreatedAt: record, LastModifiedAt: record, FailureReason: record, ExportArtifacts: record<S3ExportArtifacts: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModelCardExportJob")
  let body = {ModelCardExportJobArn: $ModelCardExportJobArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a description of a model explainability job definition.
#
# POST /#X-Amz-Target=SageMaker.DescribeModelExplainabilityJobDefinition
# operationId: DescribeModelExplainabilityJobDefinition
export def "x-amz-target-sage-maker-describe-model-explainability-job-definition DescribeModelExplainabilityJobDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-140
  JobDefinitionName: any
]: any -> record<JobDefinitionArn: record, JobDefinitionName: record, CreationTime: record, ModelExplainabilityBaselineConfig: record<BaseliningJobName: record, ConstraintsResource: record<S3Uri: record>>, ModelExplainabilityAppSpecification: record<ImageUri: record, ConfigUri: record, Environment: record>, ModelExplainabilityJobInput: record<EndpointInput: record<EndpointName: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>, BatchTransformInput: record<DataCapturedDestinationS3Uri: record, DatasetFormat: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>>, ModelExplainabilityJobOutputConfig: record<MonitoringOutputs: record, KmsKeyId: record>, JobResources: record<ClusterConfig: record<InstanceCount: record, InstanceType: record, VolumeSizeInGB: record, VolumeKmsKeyId: record>>, NetworkConfig: record<EnableInterContainerTrafficEncryption: record, EnableNetworkIsolation: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>>, RoleArn: record, StoppingCondition: record<MaxRuntimeInSeconds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModelExplainabilityJobDefinition")
  let body = {JobDefinitionName: $JobDefinitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns a description of the specified model package, which is used to create SageMaker models or list them on Amazon Web Services Marketplace.</p> <p>To create models in SageMaker, buyers can subscribe to model packages listed on Amazon Web Services Marketplace.</p>
#
# POST /#X-Amz-Target=SageMaker.DescribeModelPackage
# operationId: DescribeModelPackage
export def "x-amz-target-sage-maker-describe-model-package DescribeModelPackage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-141
  ModelPackageName: any
]: any -> record<ModelPackageName: record, ModelPackageGroupName: record, ModelPackageVersion: record, ModelPackageArn: record, ModelPackageDescription: record, CreationTime: record, InferenceSpecification: record<Containers: record, SupportedTransformInstanceTypes: record, SupportedRealtimeInferenceInstanceTypes: record, SupportedContentTypes: record, SupportedResponseMIMETypes: record>, SourceAlgorithmSpecification: record<SourceAlgorithms: record>, ValidationSpecification: record<ValidationRole: record, ValidationProfiles: record>, ModelPackageStatus: record, ModelPackageStatusDetails: record<ValidationStatuses: record, ImageScanStatuses: record>, CertifyForMarketplace: record, ModelApprovalStatus: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, MetadataProperties: record<CommitId: record, Repository: record, GeneratedBy: record, ProjectId: record>, ModelMetrics: record<ModelQuality: record<Statistics: record, Constraints: record>, ModelDataQuality: record<Statistics: record, Constraints: record>, Bias: record<Report: record, PreTrainingReport: record, PostTrainingReport: record>, Explainability: record<Report: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, ApprovalDescription: record, CustomerMetadataProperties: record, DriftCheckBaselines: record<Bias: record<ConfigFile: record, PreTrainingConstraints: record, PostTrainingConstraints: record>, Explainability: record<Constraints: record, ConfigFile: record>, ModelQuality: record<Statistics: record, Constraints: record>, ModelDataQuality: record<Statistics: record, Constraints: record>>, Domain: record, Task: record, SamplePayloadUrl: record, AdditionalInferenceSpecifications: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModelPackage")
  let body = {ModelPackageName: $ModelPackageName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a description for the specified model group.
#
# POST /#X-Amz-Target=SageMaker.DescribeModelPackageGroup
# operationId: DescribeModelPackageGroup
export def "x-amz-target-sage-maker-describe-model-package-group DescribeModelPackageGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-142
  ModelPackageGroupName: any
]: any -> record<ModelPackageGroupName: record, ModelPackageGroupArn: record, ModelPackageGroupDescription: record, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, ModelPackageGroupStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModelPackageGroup")
  let body = {ModelPackageGroupName: $ModelPackageGroupName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a description of a model quality job definition.
#
# POST /#X-Amz-Target=SageMaker.DescribeModelQualityJobDefinition
# operationId: DescribeModelQualityJobDefinition
export def "x-amz-target-sage-maker-describe-model-quality-job-definition DescribeModelQualityJobDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-143
  JobDefinitionName: any
]: any -> record<JobDefinitionArn: record, JobDefinitionName: record, CreationTime: record, ModelQualityBaselineConfig: record<BaseliningJobName: record, ConstraintsResource: record<S3Uri: record>>, ModelQualityAppSpecification: record<ImageUri: record, ContainerEntrypoint: record, ContainerArguments: record, RecordPreprocessorSourceUri: record, PostAnalyticsProcessorSourceUri: record, ProblemType: record, Environment: record>, ModelQualityJobInput: record<EndpointInput: record<EndpointName: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>, BatchTransformInput: record<DataCapturedDestinationS3Uri: record, DatasetFormat: record, LocalPath: record, S3InputMode: record, S3DataDistributionType: record, FeaturesAttribute: record, InferenceAttribute: record, ProbabilityAttribute: record, ProbabilityThresholdAttribute: record, StartTimeOffset: record, EndTimeOffset: record>, GroundTruthS3Input: record<S3Uri: record>>, ModelQualityJobOutputConfig: record<MonitoringOutputs: record, KmsKeyId: record>, JobResources: record<ClusterConfig: record<InstanceCount: record, InstanceType: record, VolumeSizeInGB: record, VolumeKmsKeyId: record>>, NetworkConfig: record<EnableInterContainerTrafficEncryption: record, EnableNetworkIsolation: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>>, RoleArn: record, StoppingCondition: record<MaxRuntimeInSeconds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeModelQualityJobDefinition")
  let body = {JobDefinitionName: $JobDefinitionName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the schedule for a monitoring job.
#
# POST /#X-Amz-Target=SageMaker.DescribeMonitoringSchedule
# operationId: DescribeMonitoringSchedule
export def "x-amz-target-sage-maker-describe-monitoring-schedule DescribeMonitoringSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-144
  MonitoringScheduleName: any
]: any -> record<MonitoringScheduleArn: record, MonitoringScheduleName: record, MonitoringScheduleStatus: record, MonitoringType: record, FailureReason: record, CreationTime: record, LastModifiedTime: record, MonitoringScheduleConfig: record<ScheduleConfig: record<ScheduleExpression: record>, MonitoringJobDefinition: record<BaselineConfig: record, MonitoringInputs: record, MonitoringOutputConfig: record, MonitoringResources: record, MonitoringAppSpecification: record, StoppingCondition: record, Environment: record, NetworkConfig: record, RoleArn: record>, MonitoringJobDefinitionName: record, MonitoringType: record>, EndpointName: record, LastMonitoringExecutionSummary: record<MonitoringScheduleName: record, ScheduledTime: record, CreationTime: record, LastModifiedTime: record, MonitoringExecutionStatus: record, ProcessingJobArn: record, EndpointName: record, FailureReason: record, MonitoringJobDefinitionName: record, MonitoringType: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeMonitoringSchedule")
  let body = {MonitoringScheduleName: $MonitoringScheduleName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about a notebook instance.
#
# POST /#X-Amz-Target=SageMaker.DescribeNotebookInstance
# operationId: DescribeNotebookInstance
export def "x-amz-target-sage-maker-describe-notebook-instance DescribeNotebookInstance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-145
  NotebookInstanceName: any
]: any -> record<NotebookInstanceArn: record, NotebookInstanceName: record, NotebookInstanceStatus: record, FailureReason: record, Url: record, InstanceType: record, SubnetId: record, SecurityGroups: record, RoleArn: record, KmsKeyId: record, NetworkInterfaceId: record, LastModifiedTime: record, CreationTime: record, NotebookInstanceLifecycleConfigName: record, DirectInternetAccess: record, VolumeSizeInGB: record, AcceleratorTypes: record, DefaultCodeRepository: record, AdditionalCodeRepositories: record, RootAccess: record, PlatformIdentifier: record, InstanceMetadataServiceConfiguration: record<MinimumInstanceMetadataServiceVersion: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeNotebookInstance")
  let body = {NotebookInstanceName: $NotebookInstanceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns a description of a notebook instance lifecycle configuration.</p> <p>For information about notebook instance lifestyle configurations, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-lifecycle-config.html">Step 2.1: (Optional) Customize a Notebook Instance</a>.</p>
#
# POST /#X-Amz-Target=SageMaker.DescribeNotebookInstanceLifecycleConfig
# operationId: DescribeNotebookInstanceLifecycleConfig
export def "x-amz-target-sage-maker-describe-notebook-instance-lifecycle-config DescribeNotebookInstanceLifecycleConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-146
  NotebookInstanceLifecycleConfigName: any
]: any -> record<NotebookInstanceLifecycleConfigArn: record, NotebookInstanceLifecycleConfigName: record, OnCreate: record, OnStart: record, LastModifiedTime: record, CreationTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeNotebookInstanceLifecycleConfig")
  let body = {NotebookInstanceLifecycleConfigName: $NotebookInstanceLifecycleConfigName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the details of a pipeline.
#
# POST /#X-Amz-Target=SageMaker.DescribePipeline
# operationId: DescribePipeline
export def "x-amz-target-sage-maker-describe-pipeline DescribePipeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-147
  PipelineName: any
]: any -> record<PipelineArn: record, PipelineName: record, PipelineDisplayName: record, PipelineDefinition: record, PipelineDescription: record, RoleArn: record, PipelineStatus: record, CreationTime: record, LastModifiedTime: record, LastRunTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, ParallelismConfiguration: record<MaxParallelExecutionSteps: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribePipeline")
  let body = {PipelineName: $PipelineName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the details of an execution's pipeline definition.
#
# POST /#X-Amz-Target=SageMaker.DescribePipelineDefinitionForExecution
# operationId: DescribePipelineDefinitionForExecution
export def "x-amz-target-sage-maker-describe-pipeline-definition-for-execution DescribePipelineDefinitionForExecution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-148
  PipelineExecutionArn: any
]: any -> record<PipelineDefinition: record, CreationTime: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribePipelineDefinitionForExecution")
  let body = {PipelineExecutionArn: $PipelineExecutionArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the details of a pipeline execution.
#
# POST /#X-Amz-Target=SageMaker.DescribePipelineExecution
# operationId: DescribePipelineExecution
export def "x-amz-target-sage-maker-describe-pipeline-execution DescribePipelineExecution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-149
  PipelineExecutionArn: any
]: any -> record<PipelineArn: record, PipelineExecutionArn: record, PipelineExecutionDisplayName: record, PipelineExecutionStatus: record, PipelineExecutionDescription: record, PipelineExperimentConfig: record<ExperimentName: record, TrialName: record>, FailureReason: record, CreationTime: record, LastModifiedTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, ParallelismConfiguration: record<MaxParallelExecutionSteps: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribePipelineExecution")
  let body = {PipelineExecutionArn: $PipelineExecutionArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a description of a processing job.
#
# POST /#X-Amz-Target=SageMaker.DescribeProcessingJob
# operationId: DescribeProcessingJob
export def "x-amz-target-sage-maker-describe-processing-job DescribeProcessingJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-150
  ProcessingJobName: any
]: any -> record<ProcessingInputs: record, ProcessingOutputConfig: record<Outputs: record, KmsKeyId: record>, ProcessingJobName: record, ProcessingResources: record<ClusterConfig: record<InstanceCount: record, InstanceType: record, VolumeSizeInGB: record, VolumeKmsKeyId: record>>, StoppingCondition: record<MaxRuntimeInSeconds: record>, AppSpecification: record<ImageUri: record, ContainerEntrypoint: record, ContainerArguments: record>, Environment: record, NetworkConfig: record<EnableInterContainerTrafficEncryption: record, EnableNetworkIsolation: record, VpcConfig: record<SecurityGroupIds: record, Subnets: record>>, RoleArn: record, ExperimentConfig: record<ExperimentName: record, TrialName: record, TrialComponentDisplayName: record, RunName: record>, ProcessingJobArn: record, ProcessingJobStatus: record, ExitMessage: record, FailureReason: record, ProcessingEndTime: record, ProcessingStartTime: record, LastModifiedTime: record, CreationTime: record, MonitoringScheduleArn: record, AutoMLJobArn: record, TrainingJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeProcessingJob")
  let body = {ProcessingJobName: $ProcessingJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the details of a project.
#
# POST /#X-Amz-Target=SageMaker.DescribeProject
# operationId: DescribeProject
export def "x-amz-target-sage-maker-describe-project DescribeProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-151
  ProjectName: any
]: any -> record<ProjectArn: record, ProjectName: record, ProjectId: record, ProjectDescription: record, ServiceCatalogProvisioningDetails: record<ProductId: record, ProvisioningArtifactId: record, PathId: record, ProvisioningParameters: record>, ServiceCatalogProvisionedProductDetails: record<ProvisionedProductId: record, ProvisionedProductStatusMessage: record>, ProjectStatus: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, CreationTime: record, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeProject")
  let body = {ProjectName: $ProjectName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the space.
#
# POST /#X-Amz-Target=SageMaker.DescribeSpace
# operationId: DescribeSpace
export def "x-amz-target-sage-maker-describe-space DescribeSpace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-152
  DomainId: any
  SpaceName: any
]: any -> record<DomainId: record, SpaceArn: record, SpaceName: record, HomeEfsFileSystemUid: record, Status: record, LastModifiedTime: record, CreationTime: record, FailureReason: record, SpaceSettings: record<JupyterServerAppSettings: record<DefaultResourceSpec: record, LifecycleConfigArns: record, CodeRepositories: record>, KernelGatewayAppSettings: record<DefaultResourceSpec: record, CustomImages: record, LifecycleConfigArns: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeSpace")
  let body = {DomainId: $DomainId, SpaceName: $SpaceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes the Studio Lifecycle Configuration.
#
# POST /#X-Amz-Target=SageMaker.DescribeStudioLifecycleConfig
# operationId: DescribeStudioLifecycleConfig
export def "x-amz-target-sage-maker-describe-studio-lifecycle-config DescribeStudioLifecycleConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-153
  StudioLifecycleConfigName: any
]: any -> record<StudioLifecycleConfigArn: record, StudioLifecycleConfigName: record, CreationTime: record, LastModifiedTime: record, StudioLifecycleConfigContent: record, StudioLifecycleConfigAppType: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeStudioLifecycleConfig")
  let body = {StudioLifecycleConfigName: $StudioLifecycleConfigName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets information about a work team provided by a vendor. It returns details about the subscription with a vendor in the Amazon Web Services Marketplace.
#
# POST /#X-Amz-Target=SageMaker.DescribeSubscribedWorkteam
# operationId: DescribeSubscribedWorkteam
export def "x-amz-target-sage-maker-describe-subscribed-workteam DescribeSubscribedWorkteam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-154
  WorkteamArn: any
]: any -> record<SubscribedWorkteam: record<WorkteamArn: record, MarketplaceTitle: record, SellerName: record, MarketplaceDescription: record, ListingId: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeSubscribedWorkteam")
  let body = {WorkteamArn: $WorkteamArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns information about a training job. </p> <p>Some of the attributes below only appear if the training job successfully starts. If the training job fails, <code>TrainingJobStatus</code> is <code>Failed</code> and, depending on the <code>FailureReason</code>, attributes like <code>TrainingStartTime</code>, <code>TrainingTimeInSeconds</code>, <code>TrainingEndTime</code>, and <code>BillableTimeInSeconds</code> may not be present in the response.</p>
#
# POST /#X-Amz-Target=SageMaker.DescribeTrainingJob
# operationId: DescribeTrainingJob
export def "x-amz-target-sage-maker-describe-training-job DescribeTrainingJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-155
  TrainingJobName: any
]: any -> record<TrainingJobName: record, TrainingJobArn: record, TuningJobArn: record, LabelingJobArn: record, AutoMLJobArn: record, ModelArtifacts: record<S3ModelArtifacts: record>, TrainingJobStatus: record, SecondaryStatus: record, FailureReason: record, HyperParameters: record, AlgorithmSpecification: record<TrainingImage: record, AlgorithmName: record, TrainingInputMode: string, MetricDefinitions: record, EnableSageMakerMetricsTimeSeries: record, ContainerEntrypoint: record, ContainerArguments: record, TrainingImageConfig: record<TrainingRepositoryAccessMode: record, TrainingRepositoryAuthConfig: record>>, RoleArn: record, InputDataConfig: record, OutputDataConfig: record<KmsKeyId: record, S3OutputPath: record>, ResourceConfig: record<InstanceType: record, InstanceCount: record, VolumeSizeInGB: record, VolumeKmsKeyId: record, InstanceGroups: record, KeepAlivePeriodInSeconds: record>, VpcConfig: record<SecurityGroupIds: record, Subnets: record>, StoppingCondition: record<MaxRuntimeInSeconds: record, MaxWaitTimeInSeconds: record>, CreationTime: record, TrainingStartTime: record, TrainingEndTime: record, LastModifiedTime: record, SecondaryStatusTransitions: record, FinalMetricDataList: record, EnableNetworkIsolation: record, EnableInterContainerTrafficEncryption: record, EnableManagedSpotTraining: record, CheckpointConfig: record<S3Uri: record, LocalPath: record>, TrainingTimeInSeconds: record, BillableTimeInSeconds: record, DebugHookConfig: record<LocalPath: record, S3OutputPath: record, HookParameters: record, CollectionConfigurations: record>, ExperimentConfig: record<ExperimentName: record, TrialName: record, TrialComponentDisplayName: record, RunName: record>, DebugRuleConfigurations: record, TensorBoardOutputConfig: record<LocalPath: record, S3OutputPath: record>, DebugRuleEvaluationStatuses: record, ProfilerConfig: record<S3OutputPath: record, ProfilingIntervalInMilliseconds: record, ProfilingParameters: record, DisableProfiler: record>, ProfilerRuleConfigurations: record, ProfilerRuleEvaluationStatuses: record, ProfilingStatus: record, RetryStrategy: record<MaximumRetryAttempts: record>, Environment: record, WarmPoolStatus: record<Status: record, ResourceRetainedBillableTimeInSeconds: record, ReusedByJob: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeTrainingJob")
  let body = {TrainingJobName: $TrainingJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about a transform job.
#
# POST /#X-Amz-Target=SageMaker.DescribeTransformJob
# operationId: DescribeTransformJob
export def "x-amz-target-sage-maker-describe-transform-job DescribeTransformJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-156
  TransformJobName: any
]: any -> record<TransformJobName: record, TransformJobArn: record, TransformJobStatus: record, FailureReason: record, ModelName: record, MaxConcurrentTransforms: record, ModelClientConfig: record<InvocationsTimeoutInSeconds: record, InvocationsMaxRetries: record>, MaxPayloadInMB: record, BatchStrategy: record, Environment: record, TransformInput: record<DataSource: record<S3DataSource: record>, ContentType: record, CompressionType: record, SplitType: record>, TransformOutput: record<S3OutputPath: record, Accept: record, AssembleWith: record, KmsKeyId: record>, DataCaptureConfig: record<DestinationS3Uri: record, KmsKeyId: record, GenerateInferenceId: record>, TransformResources: record<InstanceType: record, InstanceCount: record, VolumeKmsKeyId: record>, CreationTime: record, TransformStartTime: record, TransformEndTime: record, LabelingJobArn: record, AutoMLJobArn: record, DataProcessing: record<InputFilter: record, OutputFilter: record, JoinSource: record>, ExperimentConfig: record<ExperimentName: record, TrialName: record, TrialComponentDisplayName: record, RunName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeTransformJob")
  let body = {TransformJobName: $TransformJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Provides a list of a trial's properties.
#
# POST /#X-Amz-Target=SageMaker.DescribeTrial
# operationId: DescribeTrial
export def "x-amz-target-sage-maker-describe-trial DescribeTrial" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-157
  TrialName: any
]: any -> record<TrialName: record, TrialArn: record, DisplayName: record, ExperimentName: record, Source: record<SourceArn: record, SourceType: record>, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, MetadataProperties: record<CommitId: record, Repository: record, GeneratedBy: record, ProjectId: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeTrial")
  let body = {TrialName: $TrialName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Provides a list of a trials component's properties.
#
# POST /#X-Amz-Target=SageMaker.DescribeTrialComponent
# operationId: DescribeTrialComponent
export def "x-amz-target-sage-maker-describe-trial-component DescribeTrialComponent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-158
  TrialComponentName: any
]: any -> record<TrialComponentName: record, TrialComponentArn: record, DisplayName: record, Source: record<SourceArn: record, SourceType: record>, Status: record<PrimaryStatus: record, Message: record>, StartTime: record, EndTime: record, CreationTime: record, CreatedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, LastModifiedTime: record, LastModifiedBy: record<UserProfileArn: record, UserProfileName: record, DomainId: record, IamIdentity: record<Arn: record, PrincipalId: record, SourceIdentity: record>>, Parameters: record, InputArtifacts: record, OutputArtifacts: record, MetadataProperties: record<CommitId: record, Repository: record, GeneratedBy: record, ProjectId: record>, Metrics: record, LineageGroupArn: record, Sources: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeTrialComponent")
  let body = {TrialComponentName: $TrialComponentName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes a user profile. For more information, see <code>CreateUserProfile</code>.
#
# POST /#X-Amz-Target=SageMaker.DescribeUserProfile
# operationId: DescribeUserProfile
export def "x-amz-target-sage-maker-describe-user-profile DescribeUserProfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-159
  DomainId: any
  UserProfileName: any
]: any -> record<DomainId: record, UserProfileArn: record, UserProfileName: record, HomeEfsFileSystemUid: record, Status: record, LastModifiedTime: record, CreationTime: record, FailureReason: record, SingleSignOnUserIdentifier: record, SingleSignOnUserValue: record, UserSettings: record<ExecutionRole: record, SecurityGroups: record, SharingSettings: record<NotebookOutputOption: record, S3OutputPath: record, S3KmsKeyId: record>, JupyterServerAppSettings: record<DefaultResourceSpec: record, LifecycleConfigArns: record, CodeRepositories: record>, KernelGatewayAppSettings: record<DefaultResourceSpec: record, CustomImages: record, LifecycleConfigArns: record>, TensorBoardAppSettings: record<DefaultResourceSpec: record>, RStudioServerProAppSettings: record<AccessStatus: record, UserGroup: record>, RSessionAppSettings: record<DefaultResourceSpec: record, CustomImages: record>, CanvasAppSettings: record<TimeSeriesForecastingSettings: record, ModelRegisterSettings: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeUserProfile")
  let body = {DomainId: $DomainId, UserProfileName: $UserProfileName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Lists private workforce information, including workforce name, Amazon Resource Name (ARN), and, if applicable, allowed IP address ranges (<a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>). Allowable IP address ranges are the IP addresses that workers can use to access tasks. </p> <important> <p>This operation applies only to private workforces.</p> </important>
#
# POST /#X-Amz-Target=SageMaker.DescribeWorkforce
# operationId: DescribeWorkforce
export def "x-amz-target-sage-maker-describe-workforce DescribeWorkforce" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-160
  WorkforceName: any
]: any -> record<Workforce: record<WorkforceName: record, WorkforceArn: record, LastUpdatedDate: record, SourceIpConfig: record<Cidrs: record>, SubDomain: record, CognitoConfig: record<UserPool: record, ClientId: record>, OidcConfig: record<ClientId: record, Issuer: record, AuthorizationEndpoint: record, TokenEndpoint: record, UserInfoEndpoint: record, LogoutEndpoint: record, JwksUri: record>, CreateDate: record, WorkforceVpcConfig: record<VpcId: record, SecurityGroupIds: record, Subnets: record, VpcEndpointId: record>, Status: record, FailureReason: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeWorkforce")
  let body = {WorkforceName: $WorkforceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets information about a specific work team. You can see information such as the create date, the last updated date, membership information, and the work team's Amazon Resource Name (ARN).
#
# POST /#X-Amz-Target=SageMaker.DescribeWorkteam
# operationId: DescribeWorkteam
export def "x-amz-target-sage-maker-describe-workteam DescribeWorkteam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-161
  WorkteamName: any
]: any -> record<Workteam: record<WorkteamName: record, MemberDefinitions: record, WorkteamArn: record, WorkforceArn: record, ProductListingIds: record, Description: record, SubDomain: record, CreateDate: record, LastUpdatedDate: record, NotificationConfiguration: record<NotificationTopicArn: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DescribeWorkteam")
  let body = {WorkteamName: $WorkteamName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disables using Service Catalog in SageMaker. Service Catalog is used to create SageMaker projects.
#
# POST /#X-Amz-Target=SageMaker.DisableSagemakerServicecatalogPortfolio
# operationId: DisableSagemakerServicecatalogPortfolio
export def "x-amz-target-sage-maker-disable-sagemaker-servicecatalog-portfolio DisableSagemakerServicecatalogPortfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-162
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DisableSagemakerServicecatalogPortfolio")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Disassociates a trial component from a trial. This doesn't effect other trials the component is associated with. Before you can delete a component, you must disassociate the component from all trials it is associated with. To associate a trial component with a trial, call the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_AssociateTrialComponent.html">AssociateTrialComponent</a> API.</p> <p>To get a list of the trials a component is associated with, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_Search.html">Search</a> API. Specify <code>ExperimentTrialComponent</code> for the <code>Resource</code> parameter. The list appears in the response under <code>Results.TrialComponent.Parents</code>.</p>
#
# POST /#X-Amz-Target=SageMaker.DisassociateTrialComponent
# operationId: DisassociateTrialComponent
export def "x-amz-target-sage-maker-disassociate-trial-component DisassociateTrialComponent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-163
  TrialComponentName: any
  TrialName: any
]: any -> record<TrialComponentArn: record, TrialArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.DisassociateTrialComponent")
  let body = {TrialComponentName: $TrialComponentName, TrialName: $TrialName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Enables using Service Catalog in SageMaker. Service Catalog is used to create SageMaker projects.
#
# POST /#X-Amz-Target=SageMaker.EnableSagemakerServicecatalogPortfolio
# operationId: EnableSagemakerServicecatalogPortfolio
export def "x-amz-target-sage-maker-enable-sagemaker-servicecatalog-portfolio EnableSagemakerServicecatalogPortfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-164
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.EnableSagemakerServicecatalogPortfolio")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Describes a fleet.
#
# POST /#X-Amz-Target=SageMaker.GetDeviceFleetReport
# operationId: GetDeviceFleetReport
export def "x-amz-target-sage-maker-get-device-fleet-report GetDeviceFleetReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-165
  DeviceFleetName: any
]: any -> record<DeviceFleetArn: record, DeviceFleetName: record, OutputConfig: record<S3OutputLocation: record, KmsKeyId: record, PresetDeploymentType: record, PresetDeploymentConfig: record>, Description: record, ReportGenerated: record, DeviceStats: record<ConnectedDeviceCount: record, RegisteredDeviceCount: record>, AgentVersions: record, ModelStats: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.GetDeviceFleetReport")
  let body = {DeviceFleetName: $DeviceFleetName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# The resource policy for the lineage group.
#
# POST /#X-Amz-Target=SageMaker.GetLineageGroupPolicy
# operationId: GetLineageGroupPolicy
export def "x-amz-target-sage-maker-get-lineage-group-policy GetLineageGroupPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-166
  LineageGroupName: any
]: any -> record<LineageGroupArn: record, ResourcePolicy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.GetLineageGroupPolicy")
  let body = {LineageGroupName: $LineageGroupName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a resource policy that manages access for a model group. For information about resource policies, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_identity-vs-resource.html">Identity-based policies and resource-based policies</a> in the <i>Amazon Web Services Identity and Access Management User Guide.</i>.
#
# POST /#X-Amz-Target=SageMaker.GetModelPackageGroupPolicy
# operationId: GetModelPackageGroupPolicy
export def "x-amz-target-sage-maker-get-model-package-group-policy GetModelPackageGroupPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-167
  ModelPackageGroupName: any
]: any -> record<ResourcePolicy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.GetModelPackageGroupPolicy")
  let body = {ModelPackageGroupName: $ModelPackageGroupName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the status of Service Catalog in SageMaker. Service Catalog is used to create SageMaker projects.
#
# POST /#X-Amz-Target=SageMaker.GetSagemakerServicecatalogPortfolioStatus
# operationId: GetSagemakerServicecatalogPortfolioStatus
export def "x-amz-target-sage-maker-get-sagemaker-servicecatalog-portfolio-status GetSagemakerServicecatalogPortfolioStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-168
  --body: record
]: any -> record<Status: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.GetSagemakerServicecatalogPortfolioStatus")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# An auto-complete API for the search functionality in the SageMaker console. It returns suggestions of possible matches for the property name to use in <code>Search</code> queries. Provides suggestions for <code>HyperParameters</code>, <code>Tags</code>, and <code>Metrics</code>.
#
# POST /#X-Amz-Target=SageMaker.GetSearchSuggestions
# operationId: GetSearchSuggestions
export def "x-amz-target-sage-maker-get-search-suggestions GetSearchSuggestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-169
  Resource: any
  --SuggestionQuery: any
]: any -> record<PropertyNameSuggestions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.GetSearchSuggestions")
  let body = {Resource: $Resource, SuggestionQuery: $SuggestionQuery} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Import hub content.</p> <note> <p>Hub APIs are only callable through SageMaker Studio.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.ImportHubContent
# operationId: ImportHubContent
export def "x-amz-target-sage-maker-import-hub-content ImportHubContent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-170
  HubContentName: any
  --HubContentVersion: any
  HubContentType: any
  DocumentSchemaVersion: any
  HubName: any
  --HubContentDisplayName: any
  --HubContentDescription: any
  --HubContentMarkdown: any
  HubContentDocument: any
  --HubContentSearchKeywords: any
  --Tags: any
]: any -> record<HubArn: record, HubContentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ImportHubContent")
  let body = {HubContentName: $HubContentName, HubContentVersion: $HubContentVersion, HubContentType: $HubContentType, DocumentSchemaVersion: $DocumentSchemaVersion, HubName: $HubName, HubContentDisplayName: $HubContentDisplayName, HubContentDescription: $HubContentDescription, HubContentMarkdown: $HubContentMarkdown, HubContentDocument: $HubContentDocument, HubContentSearchKeywords: $HubContentSearchKeywords, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the actions in your account and their properties.
#
# POST /#X-Amz-Target=SageMaker.ListActions
# operationId: ListActions
export def "x-amz-target-sage-maker-list-actions ListActions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-171
  --SourceUri: any
  --ActionType: any
  --CreatedAfter: any
  --CreatedBefore: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<ActionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListActions" $qp)
  let body = {SourceUri: $SourceUri, ActionType: $ActionType, CreatedAfter: $CreatedAfter, CreatedBefore: $CreatedBefore, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the machine learning algorithms that have been created.
#
# POST /#X-Amz-Target=SageMaker.ListAlgorithms
# operationId: ListAlgorithms
export def "x-amz-target-sage-maker-list-algorithms ListAlgorithms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-172
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --MaxResults: any
  --NameContains: any
  --NextToken: any
  --SortBy: any
  --SortOrder: any
]: any -> record<AlgorithmSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListAlgorithms" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, MaxResults: $MaxResults, NameContains: $NameContains, NextToken: $NextToken, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the aliases of a specified image or image version.
#
# POST /#X-Amz-Target=SageMaker.ListAliases
# operationId: ListAliases
export def "x-amz-target-sage-maker-list-aliases ListAliases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-173
  ImageName: any
  --Alias: any
  --Version: any
  --MaxResults: any
  --NextToken: any
]: any -> record<SageMakerImageVersionAliases: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListAliases" $qp)
  let body = {ImageName: $ImageName, Alias: $Alias, Version: $Version, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the AppImageConfigs in your account and their properties. The list can be filtered by creation time or modified time, and whether the AppImageConfig name contains a specified string.
#
# POST /#X-Amz-Target=SageMaker.ListAppImageConfigs
# operationId: ListAppImageConfigs
export def "x-amz-target-sage-maker-list-app-image-configs ListAppImageConfigs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-174
  --MaxResults: any
  --NextToken: any
  --NameContains: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
  --ModifiedTimeBefore: any
  --ModifiedTimeAfter: any
  --SortBy: any
  --SortOrder: any
]: any -> record<NextToken: record, AppImageConfigs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListAppImageConfigs" $qp)
  let body = {MaxResults: $MaxResults, NextToken: $NextToken, NameContains: $NameContains, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter, ModifiedTimeBefore: $ModifiedTimeBefore, ModifiedTimeAfter: $ModifiedTimeAfter, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists apps.
#
# POST /#X-Amz-Target=SageMaker.ListApps
# operationId: ListApps
export def "x-amz-target-sage-maker-list-apps ListApps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-175
  --NextToken: any
  --MaxResults: any
  --SortOrder: any
  --SortBy: any
  --DomainIdEquals: any
  --UserProfileNameEquals: any
  --SpaceNameEquals: any
]: any -> record<Apps: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListApps" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults, SortOrder: $SortOrder, SortBy: $SortBy, DomainIdEquals: $DomainIdEquals, UserProfileNameEquals: $UserProfileNameEquals, SpaceNameEquals: $SpaceNameEquals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the artifacts in your account and their properties.
#
# POST /#X-Amz-Target=SageMaker.ListArtifacts
# operationId: ListArtifacts
export def "x-amz-target-sage-maker-list-artifacts ListArtifacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-176
  --SourceUri: any
  --ArtifactType: any
  --CreatedAfter: any
  --CreatedBefore: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<ArtifactSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListArtifacts" $qp)
  let body = {SourceUri: $SourceUri, ArtifactType: $ArtifactType, CreatedAfter: $CreatedAfter, CreatedBefore: $CreatedBefore, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the associations in your account and their properties.
#
# POST /#X-Amz-Target=SageMaker.ListAssociations
# operationId: ListAssociations
export def "x-amz-target-sage-maker-list-associations ListAssociations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-177
  --SourceArn: any
  --DestinationArn: any
  --SourceType: any
  --DestinationType: any
  --AssociationType: any
  --CreatedAfter: any
  --CreatedBefore: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<AssociationSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListAssociations" $qp)
  let body = {SourceArn: $SourceArn, DestinationArn: $DestinationArn, SourceType: $SourceType, DestinationType: $DestinationType, AssociationType: $AssociationType, CreatedAfter: $CreatedAfter, CreatedBefore: $CreatedBefore, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request a list of jobs.
#
# POST /#X-Amz-Target=SageMaker.ListAutoMLJobs
# operationId: ListAutoMLJobs
export def "x-amz-target-sage-maker-list-auto-ml-jobs ListAutoMLJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-178
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --LastModifiedTimeAfter: any
  --LastModifiedTimeBefore: any
  --NameContains: any
  --StatusEquals: any
  --SortOrder: any
  --SortBy: any
  --MaxResults: any
  --NextToken: any
]: any -> record<AutoMLJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListAutoMLJobs" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, NameContains: $NameContains, StatusEquals: $StatusEquals, SortOrder: $SortOrder, SortBy: $SortBy, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the candidates created for the job.
#
# POST /#X-Amz-Target=SageMaker.ListCandidatesForAutoMLJob
# operationId: ListCandidatesForAutoMLJob
export def "x-amz-target-sage-maker-list-candidates-for-auto-ml-job ListCandidatesForAutoMLJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-179
  AutoMLJobName: any
  --StatusEquals: any
  --CandidateNameEquals: any
  --SortOrder: any
  --SortBy: any
  --MaxResults: any
  --NextToken: any
]: any -> record<Candidates: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListCandidatesForAutoMLJob" $qp)
  let body = {AutoMLJobName: $AutoMLJobName, StatusEquals: $StatusEquals, CandidateNameEquals: $CandidateNameEquals, SortOrder: $SortOrder, SortBy: $SortBy, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of the Git repositories in your account.
#
# POST /#X-Amz-Target=SageMaker.ListCodeRepositories
# operationId: ListCodeRepositories
export def "x-amz-target-sage-maker-list-code-repositories ListCodeRepositories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-180
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --LastModifiedTimeAfter: any
  --LastModifiedTimeBefore: any
  --MaxResults: any
  --NameContains: any
  --NextToken: any
  --SortBy: any
  --SortOrder: any
]: any -> record<CodeRepositorySummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListCodeRepositories" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, MaxResults: $MaxResults, NameContains: $NameContains, NextToken: $NextToken, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Lists model compilation jobs that satisfy various filters.</p> <p>To create a model compilation job, use <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateCompilationJob.html">CreateCompilationJob</a>. To get information about a particular model compilation job you have created, use <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeCompilationJob.html">DescribeCompilationJob</a>.</p>
#
# POST /#X-Amz-Target=SageMaker.ListCompilationJobs
# operationId: ListCompilationJobs
export def "x-amz-target-sage-maker-list-compilation-jobs ListCompilationJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-181
  --NextToken: any
  --MaxResults: any
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --LastModifiedTimeAfter: any
  --LastModifiedTimeBefore: any
  --NameContains: any
  --StatusEquals: any
  --SortBy: any
  --SortOrder: any
]: any -> record<CompilationJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListCompilationJobs" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults, CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, NameContains: $NameContains, StatusEquals: $StatusEquals, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the contexts in your account and their properties.
#
# POST /#X-Amz-Target=SageMaker.ListContexts
# operationId: ListContexts
export def "x-amz-target-sage-maker-list-contexts ListContexts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-182
  --SourceUri: any
  --ContextType: any
  --CreatedAfter: any
  --CreatedBefore: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<ContextSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListContexts" $qp)
  let body = {SourceUri: $SourceUri, ContextType: $ContextType, CreatedAfter: $CreatedAfter, CreatedBefore: $CreatedBefore, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the data quality job definitions in your account.
#
# POST /#X-Amz-Target=SageMaker.ListDataQualityJobDefinitions
# operationId: ListDataQualityJobDefinitions
export def "x-amz-target-sage-maker-list-data-quality-job-definitions ListDataQualityJobDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-183
  --EndpointName: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
  --NameContains: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
]: any -> record<JobDefinitionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListDataQualityJobDefinitions" $qp)
  let body = {EndpointName: $EndpointName, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults, NameContains: $NameContains, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of devices in the fleet.
#
# POST /#X-Amz-Target=SageMaker.ListDeviceFleets
# operationId: ListDeviceFleets
export def "x-amz-target-sage-maker-list-device-fleets ListDeviceFleets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-184
  --NextToken: any
  --MaxResults: any
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --LastModifiedTimeAfter: any
  --LastModifiedTimeBefore: any
  --NameContains: any
  --SortBy: any
  --SortOrder: any
]: any -> record<DeviceFleetSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListDeviceFleets" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults, CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, NameContains: $NameContains, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# A list of devices.
#
# POST /#X-Amz-Target=SageMaker.ListDevices
# operationId: ListDevices
export def "x-amz-target-sage-maker-list-devices ListDevices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-185
  --NextToken: any
  --MaxResults: any
  --LatestHeartbeatAfter: any
  --ModelName: any
  --DeviceFleetName: any
]: any -> record<DeviceSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListDevices" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults, LatestHeartbeatAfter: $LatestHeartbeatAfter, ModelName: $ModelName, DeviceFleetName: $DeviceFleetName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the domains.
#
# POST /#X-Amz-Target=SageMaker.ListDomains
# operationId: ListDomains
export def "x-amz-target-sage-maker-list-domains ListDomains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-186
  --NextToken: any
  --MaxResults: any
]: any -> record<Domains: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListDomains" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all edge deployment plans.
#
# POST /#X-Amz-Target=SageMaker.ListEdgeDeploymentPlans
# operationId: ListEdgeDeploymentPlans
export def "x-amz-target-sage-maker-list-edge-deployment-plans ListEdgeDeploymentPlans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-187
  --NextToken: any
  --MaxResults: any
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --LastModifiedTimeAfter: any
  --LastModifiedTimeBefore: any
  --NameContains: any
  --DeviceFleetNameContains: any
  --SortBy: any
  --SortOrder: any
]: any -> record<EdgeDeploymentPlanSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListEdgeDeploymentPlans" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults, CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, NameContains: $NameContains, DeviceFleetNameContains: $DeviceFleetNameContains, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of edge packaging jobs.
#
# POST /#X-Amz-Target=SageMaker.ListEdgePackagingJobs
# operationId: ListEdgePackagingJobs
export def "x-amz-target-sage-maker-list-edge-packaging-jobs ListEdgePackagingJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-188
  --NextToken: any
  --MaxResults: any
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --LastModifiedTimeAfter: any
  --LastModifiedTimeBefore: any
  --NameContains: any
  --ModelNameContains: any
  --StatusEquals: any
  --SortBy: any
  --SortOrder: any
]: any -> record<EdgePackagingJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListEdgePackagingJobs" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults, CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, NameContains: $NameContains, ModelNameContains: $ModelNameContains, StatusEquals: $StatusEquals, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists endpoint configurations.
#
# POST /#X-Amz-Target=SageMaker.ListEndpointConfigs
# operationId: ListEndpointConfigs
export def "x-amz-target-sage-maker-list-endpoint-configs ListEndpointConfigs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-189
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
  --NameContains: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
]: any -> record<EndpointConfigs: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListEndpointConfigs" $qp)
  let body = {SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults, NameContains: $NameContains, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists endpoints.
#
# POST /#X-Amz-Target=SageMaker.ListEndpoints
# operationId: ListEndpoints
export def "x-amz-target-sage-maker-list-endpoints ListEndpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-190
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
  --NameContains: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
  --LastModifiedTimeBefore: any
  --LastModifiedTimeAfter: any
  --StatusEquals: any
]: any -> record<Endpoints: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListEndpoints" $qp)
  let body = {SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults, NameContains: $NameContains, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, StatusEquals: $StatusEquals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all the experiments in your account. The list can be filtered to show only experiments that were created in a specific time range. The list can be sorted by experiment name or creation time.
#
# POST /#X-Amz-Target=SageMaker.ListExperiments
# operationId: ListExperiments
export def "x-amz-target-sage-maker-list-experiments ListExperiments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-191
  --CreatedAfter: any
  --CreatedBefore: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<ExperimentSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListExperiments" $qp)
  let body = {CreatedAfter: $CreatedAfter, CreatedBefore: $CreatedBefore, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List <code>FeatureGroup</code>s based on given filter and order.
#
# POST /#X-Amz-Target=SageMaker.ListFeatureGroups
# operationId: ListFeatureGroups
export def "x-amz-target-sage-maker-list-feature-groups ListFeatureGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-192
  --NameContains: any
  --FeatureGroupStatusEquals: any
  --OfflineStoreStatusEquals: any
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --SortOrder: any
  --SortBy: any
  --MaxResults: any
  --NextToken: any
]: any -> record<FeatureGroupSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListFeatureGroups" $qp)
  let body = {NameContains: $NameContains, FeatureGroupStatusEquals: $FeatureGroupStatusEquals, OfflineStoreStatusEquals: $OfflineStoreStatusEquals, CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, SortOrder: $SortOrder, SortBy: $SortBy, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about the flow definitions in your account.
#
# POST /#X-Amz-Target=SageMaker.ListFlowDefinitions
# operationId: ListFlowDefinitions
export def "x-amz-target-sage-maker-list-flow-definitions ListFlowDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-193
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<FlowDefinitionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListFlowDefinitions" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>List hub content versions.</p> <note> <p>Hub APIs are only callable through SageMaker Studio.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.ListHubContentVersions
# operationId: ListHubContentVersions
export def "x-amz-target-sage-maker-list-hub-content-versions ListHubContentVersions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-194
  HubName: any
  HubContentType: any
  HubContentName: any
  --MinVersion: any
  --MaxSchemaVersion: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
  --SortBy: any
  --SortOrder: any
  --MaxResults: any
  --NextToken: any
]: any -> record<HubContentSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListHubContentVersions")
  let body = {HubName: $HubName, HubContentType: $HubContentType, HubContentName: $HubContentName, MinVersion: $MinVersion, MaxSchemaVersion: $MaxSchemaVersion, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter, SortBy: $SortBy, SortOrder: $SortOrder, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>List the contents of a hub.</p> <note> <p>Hub APIs are only callable through SageMaker Studio.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.ListHubContents
# operationId: ListHubContents
export def "x-amz-target-sage-maker-list-hub-contents ListHubContents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-195
  HubName: any
  HubContentType: any
  --NameContains: any
  --MaxSchemaVersion: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
  --SortBy: any
  --SortOrder: any
  --MaxResults: any
  --NextToken: any
]: any -> record<HubContentSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListHubContents")
  let body = {HubName: $HubName, HubContentType: $HubContentType, NameContains: $NameContains, MaxSchemaVersion: $MaxSchemaVersion, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter, SortBy: $SortBy, SortOrder: $SortOrder, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>List all existing hubs.</p> <note> <p>Hub APIs are only callable through SageMaker Studio.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.ListHubs
# operationId: ListHubs
export def "x-amz-target-sage-maker-list-hubs ListHubs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-196
  --NameContains: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
  --LastModifiedTimeBefore: any
  --LastModifiedTimeAfter: any
  --SortBy: any
  --SortOrder: any
  --MaxResults: any
  --NextToken: any
]: any -> record<HubSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListHubs")
  let body = {NameContains: $NameContains, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, SortBy: $SortBy, SortOrder: $SortOrder, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns information about the human task user interfaces in your account.
#
# POST /#X-Amz-Target=SageMaker.ListHumanTaskUis
# operationId: ListHumanTaskUis
export def "x-amz-target-sage-maker-list-human-task-uis ListHumanTaskUis" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-197
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<HumanTaskUiSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListHumanTaskUis" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_HyperParameterTuningJobSummary.html">HyperParameterTuningJobSummary</a> objects that describe the hyperparameter tuning jobs launched in your account.
#
# POST /#X-Amz-Target=SageMaker.ListHyperParameterTuningJobs
# operationId: ListHyperParameterTuningJobs
export def "x-amz-target-sage-maker-list-hyper-parameter-tuning-jobs ListHyperParameterTuningJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-198
  --NextToken: any
  --MaxResults: any
  --SortBy: any
  --SortOrder: any
  --NameContains: any
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --LastModifiedTimeAfter: any
  --LastModifiedTimeBefore: any
  --StatusEquals: any
]: any -> record<HyperParameterTuningJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListHyperParameterTuningJobs" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults, SortBy: $SortBy, SortOrder: $SortOrder, NameContains: $NameContains, CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, StatusEquals: $StatusEquals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the versions of a specified image and their properties. The list can be filtered by creation time or modified time.
#
# POST /#X-Amz-Target=SageMaker.ListImageVersions
# operationId: ListImageVersions
export def "x-amz-target-sage-maker-list-image-versions ListImageVersions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-199
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  ImageName: any
  --LastModifiedTimeAfter: any
  --LastModifiedTimeBefore: any
  --MaxResults: any
  --NextToken: any
  --SortBy: any
  --SortOrder: any
]: any -> record<ImageVersions: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListImageVersions" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, ImageName: $ImageName, LastModifiedTimeAfter: $LastModifiedTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, MaxResults: $MaxResults, NextToken: $NextToken, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the images in your account and their properties. The list can be filtered by creation time or modified time, and whether the image name contains a specified string.
#
# POST /#X-Amz-Target=SageMaker.ListImages
# operationId: ListImages
export def "x-amz-target-sage-maker-list-images ListImages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-200
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --LastModifiedTimeAfter: any
  --LastModifiedTimeBefore: any
  --MaxResults: any
  --NameContains: any
  --NextToken: any
  --SortBy: any
  --SortOrder: any
]: any -> record<Images: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListImages" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, MaxResults: $MaxResults, NameContains: $NameContains, NextToken: $NextToken, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the list of all inference experiments.
#
# POST /#X-Amz-Target=SageMaker.ListInferenceExperiments
# operationId: ListInferenceExperiments
export def "x-amz-target-sage-maker-list-inference-experiments ListInferenceExperiments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-201
  --NameContains: any
  --Type: any
  --StatusEquals: any
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --LastModifiedTimeAfter: any
  --LastModifiedTimeBefore: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<InferenceExperiments: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListInferenceExperiments" $qp)
  let body = {NameContains: $NameContains, Type: $Type, StatusEquals: $StatusEquals, CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Returns a list of the subtasks for an Inference Recommender job.</p> <p>The supported subtasks are benchmarks, which evaluate the performance of your model on different instance types.</p>
#
# POST /#X-Amz-Target=SageMaker.ListInferenceRecommendationsJobSteps
# operationId: ListInferenceRecommendationsJobSteps
export def "x-amz-target-sage-maker-list-inference-recommendations-job-steps ListInferenceRecommendationsJobSteps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-202
  JobName: any
  --Status: any
  --StepType: any
  --MaxResults: any
  --NextToken: any
]: any -> record<Steps: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListInferenceRecommendationsJobSteps" $qp)
  let body = {JobName: $JobName, Status: $Status, StepType: $StepType, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists recommendation jobs that satisfy various filters.
#
# POST /#X-Amz-Target=SageMaker.ListInferenceRecommendationsJobs
# operationId: ListInferenceRecommendationsJobs
export def "x-amz-target-sage-maker-list-inference-recommendations-jobs ListInferenceRecommendationsJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-203
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --LastModifiedTimeAfter: any
  --LastModifiedTimeBefore: any
  --NameContains: any
  --StatusEquals: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<InferenceRecommendationsJobs: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListInferenceRecommendationsJobs" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, NameContains: $NameContains, StatusEquals: $StatusEquals, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of labeling jobs.
#
# POST /#X-Amz-Target=SageMaker.ListLabelingJobs
# operationId: ListLabelingJobs
export def "x-amz-target-sage-maker-list-labeling-jobs ListLabelingJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-204
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --LastModifiedTimeAfter: any
  --LastModifiedTimeBefore: any
  --MaxResults: any
  --NextToken: any
  --NameContains: any
  --SortBy: any
  --SortOrder: any
  --StatusEquals: any
]: any -> record<LabelingJobSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListLabelingJobs" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, MaxResults: $MaxResults, NextToken: $NextToken, NameContains: $NameContains, SortBy: $SortBy, SortOrder: $SortOrder, StatusEquals: $StatusEquals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of labeling jobs assigned to a specified work team.
#
# POST /#X-Amz-Target=SageMaker.ListLabelingJobsForWorkteam
# operationId: ListLabelingJobsForWorkteam
export def "x-amz-target-sage-maker-list-labeling-jobs-for-workteam ListLabelingJobsForWorkteam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-205
  WorkteamArn: any
  --MaxResults: any
  --NextToken: any
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --JobReferenceCodeContains: any
  --SortBy: any
  --SortOrder: any
]: any -> record<LabelingJobSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListLabelingJobsForWorkteam" $qp)
  let body = {WorkteamArn: $WorkteamArn, MaxResults: $MaxResults, NextToken: $NextToken, CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, JobReferenceCodeContains: $JobReferenceCodeContains, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# A list of lineage groups shared with your Amazon Web Services account. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/xaccount-lineage-tracking.html"> Cross-Account Lineage Tracking </a> in the <i>Amazon SageMaker Developer Guide</i>.
#
# POST /#X-Amz-Target=SageMaker.ListLineageGroups
# operationId: ListLineageGroups
export def "x-amz-target-sage-maker-list-lineage-groups ListLineageGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-206
  --CreatedAfter: any
  --CreatedBefore: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<LineageGroupSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListLineageGroups" $qp)
  let body = {CreatedAfter: $CreatedAfter, CreatedBefore: $CreatedBefore, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists model bias jobs definitions that satisfy various filters.
#
# POST /#X-Amz-Target=SageMaker.ListModelBiasJobDefinitions
# operationId: ListModelBiasJobDefinitions
export def "x-amz-target-sage-maker-list-model-bias-job-definitions ListModelBiasJobDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-207
  --EndpointName: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
  --NameContains: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
]: any -> record<JobDefinitionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelBiasJobDefinitions" $qp)
  let body = {EndpointName: $EndpointName, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults, NameContains: $NameContains, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the export jobs for the Amazon SageMaker Model Card.
#
# POST /#X-Amz-Target=SageMaker.ListModelCardExportJobs
# operationId: ListModelCardExportJobs
export def "x-amz-target-sage-maker-list-model-card-export-jobs ListModelCardExportJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-208
  ModelCardName: any
  --ModelCardVersion: any
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --ModelCardExportJobNameContains: any
  --StatusEquals: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<ModelCardExportJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelCardExportJobs" $qp)
  let body = {ModelCardName: $ModelCardName, ModelCardVersion: $ModelCardVersion, CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, ModelCardExportJobNameContains: $ModelCardExportJobNameContains, StatusEquals: $StatusEquals, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List existing versions of an Amazon SageMaker Model Card.
#
# POST /#X-Amz-Target=SageMaker.ListModelCardVersions
# operationId: ListModelCardVersions
export def "x-amz-target-sage-maker-list-model-card-versions ListModelCardVersions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-209
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --MaxResults: any
  ModelCardName: any
  --ModelCardStatus: any
  --NextToken: any
  --SortBy: any
  --SortOrder: any
]: any -> record<ModelCardVersionSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelCardVersions" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, MaxResults: $MaxResults, ModelCardName: $ModelCardName, ModelCardStatus: $ModelCardStatus, NextToken: $NextToken, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List existing model cards.
#
# POST /#X-Amz-Target=SageMaker.ListModelCards
# operationId: ListModelCards
export def "x-amz-target-sage-maker-list-model-cards ListModelCards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-210
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --MaxResults: any
  --NameContains: any
  --ModelCardStatus: any
  --NextToken: any
  --SortBy: any
  --SortOrder: any
]: any -> record<ModelCardSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelCards" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, MaxResults: $MaxResults, NameContains: $NameContains, ModelCardStatus: $ModelCardStatus, NextToken: $NextToken, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists model explainability job definitions that satisfy various filters.
#
# POST /#X-Amz-Target=SageMaker.ListModelExplainabilityJobDefinitions
# operationId: ListModelExplainabilityJobDefinitions
export def "x-amz-target-sage-maker-list-model-explainability-job-definitions ListModelExplainabilityJobDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-211
  --EndpointName: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
  --NameContains: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
]: any -> record<JobDefinitionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelExplainabilityJobDefinitions" $qp)
  let body = {EndpointName: $EndpointName, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults, NameContains: $NameContains, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the domain, framework, task, and model name of standard machine learning models found in common model zoos.
#
# POST /#X-Amz-Target=SageMaker.ListModelMetadata
# operationId: ListModelMetadata
export def "x-amz-target-sage-maker-list-model-metadata ListModelMetadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-212
  --SearchExpression: any
  --NextToken: any
  --MaxResults: any
]: any -> record<ModelMetadataSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelMetadata" $qp)
  let body = {SearchExpression: $SearchExpression, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of the model groups in your Amazon Web Services account.
#
# POST /#X-Amz-Target=SageMaker.ListModelPackageGroups
# operationId: ListModelPackageGroups
export def "x-amz-target-sage-maker-list-model-package-groups ListModelPackageGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-213
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --MaxResults: any
  --NameContains: any
  --NextToken: any
  --SortBy: any
  --SortOrder: any
]: any -> record<ModelPackageGroupSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelPackageGroups" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, MaxResults: $MaxResults, NameContains: $NameContains, NextToken: $NextToken, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the model packages that have been created.
#
# POST /#X-Amz-Target=SageMaker.ListModelPackages
# operationId: ListModelPackages
export def "x-amz-target-sage-maker-list-model-packages ListModelPackages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-214
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --MaxResults: any
  --NameContains: any
  --ModelApprovalStatus: any
  --ModelPackageGroupName: any
  --ModelPackageType: any
  --NextToken: any
  --SortBy: any
  --SortOrder: any
]: any -> record<ModelPackageSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelPackages" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, MaxResults: $MaxResults, NameContains: $NameContains, ModelApprovalStatus: $ModelApprovalStatus, ModelPackageGroupName: $ModelPackageGroupName, ModelPackageType: $ModelPackageType, NextToken: $NextToken, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of model quality monitoring job definitions in your account.
#
# POST /#X-Amz-Target=SageMaker.ListModelQualityJobDefinitions
# operationId: ListModelQualityJobDefinitions
export def "x-amz-target-sage-maker-list-model-quality-job-definitions ListModelQualityJobDefinitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-215
  --EndpointName: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
  --NameContains: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
]: any -> record<JobDefinitionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModelQualityJobDefinitions" $qp)
  let body = {EndpointName: $EndpointName, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults, NameContains: $NameContains, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists models created with the <code>CreateModel</code> API.
#
# POST /#X-Amz-Target=SageMaker.ListModels
# operationId: ListModels
export def "x-amz-target-sage-maker-list-models ListModels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-216
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
  --NameContains: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
]: any -> record<Models: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListModels" $qp)
  let body = {SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults, NameContains: $NameContains, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of past alerts in a model monitoring schedule.
#
# POST /#X-Amz-Target=SageMaker.ListMonitoringAlertHistory
# operationId: ListMonitoringAlertHistory
export def "x-amz-target-sage-maker-list-monitoring-alert-history ListMonitoringAlertHistory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-217
  --MonitoringScheduleName: any
  --MonitoringAlertName: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
  --StatusEquals: any
]: any -> record<MonitoringAlertHistory: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListMonitoringAlertHistory" $qp)
  let body = {MonitoringScheduleName: $MonitoringScheduleName, MonitoringAlertName: $MonitoringAlertName, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter, StatusEquals: $StatusEquals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the alerts for a single monitoring schedule.
#
# POST /#X-Amz-Target=SageMaker.ListMonitoringAlerts
# operationId: ListMonitoringAlerts
export def "x-amz-target-sage-maker-list-monitoring-alerts ListMonitoringAlerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-218
  MonitoringScheduleName: any
  --NextToken: any
  --MaxResults: any
]: any -> record<MonitoringAlertSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListMonitoringAlerts" $qp)
  let body = {MonitoringScheduleName: $MonitoringScheduleName, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of all monitoring job executions.
#
# POST /#X-Amz-Target=SageMaker.ListMonitoringExecutions
# operationId: ListMonitoringExecutions
export def "x-amz-target-sage-maker-list-monitoring-executions ListMonitoringExecutions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-219
  --MonitoringScheduleName: any
  --EndpointName: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
  --ScheduledTimeBefore: any
  --ScheduledTimeAfter: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
  --LastModifiedTimeBefore: any
  --LastModifiedTimeAfter: any
  --StatusEquals: any
  --MonitoringJobDefinitionName: any
  --MonitoringTypeEquals: any
]: any -> record<MonitoringExecutionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListMonitoringExecutions" $qp)
  let body = {MonitoringScheduleName: $MonitoringScheduleName, EndpointName: $EndpointName, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults, ScheduledTimeBefore: $ScheduledTimeBefore, ScheduledTimeAfter: $ScheduledTimeAfter, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, StatusEquals: $StatusEquals, MonitoringJobDefinitionName: $MonitoringJobDefinitionName, MonitoringTypeEquals: $MonitoringTypeEquals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of all monitoring schedules.
#
# POST /#X-Amz-Target=SageMaker.ListMonitoringSchedules
# operationId: ListMonitoringSchedules
export def "x-amz-target-sage-maker-list-monitoring-schedules ListMonitoringSchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-220
  --EndpointName: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
  --NameContains: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
  --LastModifiedTimeBefore: any
  --LastModifiedTimeAfter: any
  --StatusEquals: any
  --MonitoringJobDefinitionName: any
  --MonitoringTypeEquals: any
]: any -> record<MonitoringScheduleSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListMonitoringSchedules" $qp)
  let body = {EndpointName: $EndpointName, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults, NameContains: $NameContains, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, StatusEquals: $StatusEquals, MonitoringJobDefinitionName: $MonitoringJobDefinitionName, MonitoringTypeEquals: $MonitoringTypeEquals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists notebook instance lifestyle configurations created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateNotebookInstanceLifecycleConfig.html">CreateNotebookInstanceLifecycleConfig</a> API.
#
# POST /#X-Amz-Target=SageMaker.ListNotebookInstanceLifecycleConfigs
# operationId: ListNotebookInstanceLifecycleConfigs
export def "x-amz-target-sage-maker-list-notebook-instance-lifecycle-configs ListNotebookInstanceLifecycleConfigs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-221
  --NextToken: any
  --MaxResults: any
  --SortBy: any
  --SortOrder: any
  --NameContains: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
  --LastModifiedTimeBefore: any
  --LastModifiedTimeAfter: any
]: any -> record<NextToken: record, NotebookInstanceLifecycleConfigs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListNotebookInstanceLifecycleConfigs" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults, SortBy: $SortBy, SortOrder: $SortOrder, NameContains: $NameContains, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of the SageMaker notebook instances in the requester's account in an Amazon Web Services Region. 
#
# POST /#X-Amz-Target=SageMaker.ListNotebookInstances
# operationId: ListNotebookInstances
export def "x-amz-target-sage-maker-list-notebook-instances ListNotebookInstances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-222
  --NextToken: any
  --MaxResults: any
  --SortBy: any
  --SortOrder: any
  --NameContains: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
  --LastModifiedTimeBefore: any
  --LastModifiedTimeAfter: any
  --StatusEquals: any
  --NotebookInstanceLifecycleConfigNameContains: any
  --DefaultCodeRepositoryContains: any
  --AdditionalCodeRepositoryEquals: any
]: any -> record<NextToken: record, NotebookInstances: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListNotebookInstances" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults, SortBy: $SortBy, SortOrder: $SortOrder, NameContains: $NameContains, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, StatusEquals: $StatusEquals, NotebookInstanceLifecycleConfigNameContains: $NotebookInstanceLifecycleConfigNameContains, DefaultCodeRepositoryContains: $DefaultCodeRepositoryContains, AdditionalCodeRepositoryEquals: $AdditionalCodeRepositoryEquals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of <code>PipeLineExecutionStep</code> objects.
#
# POST /#X-Amz-Target=SageMaker.ListPipelineExecutionSteps
# operationId: ListPipelineExecutionSteps
export def "x-amz-target-sage-maker-list-pipeline-execution-steps ListPipelineExecutionSteps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-223
  --PipelineExecutionArn: any
  --NextToken: any
  --MaxResults: any
  --SortOrder: any
]: any -> record<PipelineExecutionSteps: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListPipelineExecutionSteps" $qp)
  let body = {PipelineExecutionArn: $PipelineExecutionArn, NextToken: $NextToken, MaxResults: $MaxResults, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of the pipeline executions.
#
# POST /#X-Amz-Target=SageMaker.ListPipelineExecutions
# operationId: ListPipelineExecutions
export def "x-amz-target-sage-maker-list-pipeline-executions ListPipelineExecutions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-224
  PipelineName: any
  --CreatedAfter: any
  --CreatedBefore: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<PipelineExecutionSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListPipelineExecutions" $qp)
  let body = {PipelineName: $PipelineName, CreatedAfter: $CreatedAfter, CreatedBefore: $CreatedBefore, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of parameters for a pipeline execution.
#
# POST /#X-Amz-Target=SageMaker.ListPipelineParametersForExecution
# operationId: ListPipelineParametersForExecution
export def "x-amz-target-sage-maker-list-pipeline-parameters-for-execution ListPipelineParametersForExecution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-225
  PipelineExecutionArn: any
  --NextToken: any
  --MaxResults: any
]: any -> record<PipelineParameters: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListPipelineParametersForExecution" $qp)
  let body = {PipelineExecutionArn: $PipelineExecutionArn, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of pipelines.
#
# POST /#X-Amz-Target=SageMaker.ListPipelines
# operationId: ListPipelines
export def "x-amz-target-sage-maker-list-pipelines ListPipelines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-226
  --PipelineNamePrefix: any
  --CreatedAfter: any
  --CreatedBefore: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<PipelineSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListPipelines" $qp)
  let body = {PipelineNamePrefix: $PipelineNamePrefix, CreatedAfter: $CreatedAfter, CreatedBefore: $CreatedBefore, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists processing jobs that satisfy various filters.
#
# POST /#X-Amz-Target=SageMaker.ListProcessingJobs
# operationId: ListProcessingJobs
export def "x-amz-target-sage-maker-list-processing-jobs ListProcessingJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-227
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --LastModifiedTimeAfter: any
  --LastModifiedTimeBefore: any
  --NameContains: any
  --StatusEquals: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<ProcessingJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListProcessingJobs" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, NameContains: $NameContains, StatusEquals: $StatusEquals, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of the projects in an Amazon Web Services account.
#
# POST /#X-Amz-Target=SageMaker.ListProjects
# operationId: ListProjects
export def "x-amz-target-sage-maker-list-projects ListProjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-228
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --MaxResults: any
  --NameContains: any
  --NextToken: any
  --SortBy: any
  --SortOrder: any
]: any -> record<ProjectSummaryList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListProjects" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, MaxResults: $MaxResults, NameContains: $NameContains, NextToken: $NextToken, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists spaces.
#
# POST /#X-Amz-Target=SageMaker.ListSpaces
# operationId: ListSpaces
export def "x-amz-target-sage-maker-list-spaces ListSpaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-229
  --NextToken: any
  --MaxResults: any
  --SortOrder: any
  --SortBy: any
  --DomainIdEquals: any
  --SpaceNameContains: any
]: any -> record<Spaces: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListSpaces" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults, SortOrder: $SortOrder, SortBy: $SortBy, DomainIdEquals: $DomainIdEquals, SpaceNameContains: $SpaceNameContains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists devices allocated to the stage, containing detailed device information and deployment status.
#
# POST /#X-Amz-Target=SageMaker.ListStageDevices
# operationId: ListStageDevices
export def "x-amz-target-sage-maker-list-stage-devices ListStageDevices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-230
  --NextToken: any
  --MaxResults: any
  EdgeDeploymentPlanName: any
  --ExcludeDevicesDeployedInOtherStage: any
  StageName: any
]: any -> record<DeviceDeploymentSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListStageDevices" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults, EdgeDeploymentPlanName: $EdgeDeploymentPlanName, ExcludeDevicesDeployedInOtherStage: $ExcludeDevicesDeployedInOtherStage, StageName: $StageName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the Studio Lifecycle Configurations in your Amazon Web Services Account.
#
# POST /#X-Amz-Target=SageMaker.ListStudioLifecycleConfigs
# operationId: ListStudioLifecycleConfigs
export def "x-amz-target-sage-maker-list-studio-lifecycle-configs ListStudioLifecycleConfigs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-231
  --MaxResults: any
  --NextToken: any
  --NameContains: any
  --AppTypeEquals: any
  --CreationTimeBefore: any
  --CreationTimeAfter: any
  --ModifiedTimeBefore: any
  --ModifiedTimeAfter: any
  --SortBy: any
  --SortOrder: any
]: any -> record<NextToken: record, StudioLifecycleConfigs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListStudioLifecycleConfigs" $qp)
  let body = {MaxResults: $MaxResults, NextToken: $NextToken, NameContains: $NameContains, AppTypeEquals: $AppTypeEquals, CreationTimeBefore: $CreationTimeBefore, CreationTimeAfter: $CreationTimeAfter, ModifiedTimeBefore: $ModifiedTimeBefore, ModifiedTimeAfter: $ModifiedTimeAfter, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of the work teams that you are subscribed to in the Amazon Web Services Marketplace. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
#
# POST /#X-Amz-Target=SageMaker.ListSubscribedWorkteams
# operationId: ListSubscribedWorkteams
export def "x-amz-target-sage-maker-list-subscribed-workteams ListSubscribedWorkteams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-232
  --NameContains: any
  --NextToken: any
  --MaxResults: any
]: any -> record<SubscribedWorkteams: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListSubscribedWorkteams" $qp)
  let body = {NameContains: $NameContains, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the tags for the specified SageMaker resource.
#
# POST /#X-Amz-Target=SageMaker.ListTags
# operationId: ListTags
export def "x-amz-target-sage-maker-list-tags ListTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-233
  ResourceArn: any
  --NextToken: any
  --MaxResults: any
]: any -> record<Tags: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListTags" $qp)
  let body = {ResourceArn: $ResourceArn, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Lists training jobs.</p> <note> <p>When <code>StatusEquals</code> and <code>MaxResults</code> are set at the same time, the <code>MaxResults</code> number of training jobs are first retrieved ignoring the <code>StatusEquals</code> parameter and then they are filtered by the <code>StatusEquals</code> parameter, which is returned as a response.</p> <p>For example, if <code>ListTrainingJobs</code> is invoked with the following parameters:</p> <p> <code>{ ... MaxResults: 100, StatusEquals: InProgress ... }</code> </p> <p>First, 100 trainings jobs with any status, including those other than <code>InProgress</code>, are selected (sorted according to the creation time, from the most current to the oldest). Next, those with a status of <code>InProgress</code> are returned.</p> <p>You can quickly test the API using the following Amazon Web Services CLI code.</p> <p> <code>aws sagemaker list-training-jobs --max-results 100 --status-equals InProgress</code> </p> </note>
#
# POST /#X-Amz-Target=SageMaker.ListTrainingJobs
# operationId: ListTrainingJobs
export def "x-amz-target-sage-maker-list-training-jobs ListTrainingJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-234
  --NextToken: any
  --MaxResults: any
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --LastModifiedTimeAfter: any
  --LastModifiedTimeBefore: any
  --NameContains: any
  --StatusEquals: any
  --SortBy: any
  --SortOrder: any
  --WarmPoolStatusEquals: any
]: any -> record<TrainingJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListTrainingJobs" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults, CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, NameContains: $NameContains, StatusEquals: $StatusEquals, SortBy: $SortBy, SortOrder: $SortOrder, WarmPoolStatusEquals: $WarmPoolStatusEquals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_TrainingJobSummary.html">TrainingJobSummary</a> objects that describe the training jobs that a hyperparameter tuning job launched.
#
# POST /#X-Amz-Target=SageMaker.ListTrainingJobsForHyperParameterTuningJob
# operationId: ListTrainingJobsForHyperParameterTuningJob
export def "x-amz-target-sage-maker-list-training-jobs-for-hyper-parameter-tuning-job ListTrainingJobsForHyperParameterTuningJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-235
  HyperParameterTuningJobName: any
  --NextToken: any
  --MaxResults: any
  --StatusEquals: any
  --SortBy: any
  --SortOrder: any
]: any -> record<TrainingJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListTrainingJobsForHyperParameterTuningJob" $qp)
  let body = {HyperParameterTuningJobName: $HyperParameterTuningJobName, NextToken: $NextToken, MaxResults: $MaxResults, StatusEquals: $StatusEquals, SortBy: $SortBy, SortOrder: $SortOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists transform jobs.
#
# POST /#X-Amz-Target=SageMaker.ListTransformJobs
# operationId: ListTransformJobs
export def "x-amz-target-sage-maker-list-transform-jobs ListTransformJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-236
  --CreationTimeAfter: any
  --CreationTimeBefore: any
  --LastModifiedTimeAfter: any
  --LastModifiedTimeBefore: any
  --NameContains: any
  --StatusEquals: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<TransformJobSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListTransformJobs" $qp)
  let body = {CreationTimeAfter: $CreationTimeAfter, CreationTimeBefore: $CreationTimeBefore, LastModifiedTimeAfter: $LastModifiedTimeAfter, LastModifiedTimeBefore: $LastModifiedTimeBefore, NameContains: $NameContains, StatusEquals: $StatusEquals, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Lists the trial components in your account. You can sort the list by trial component name or creation time. You can filter the list to show only components that were created in a specific time range. You can also filter on one of the following:</p> <ul> <li> <p> <code>ExperimentName</code> </p> </li> <li> <p> <code>SourceArn</code> </p> </li> <li> <p> <code>TrialName</code> </p> </li> </ul>
#
# POST /#X-Amz-Target=SageMaker.ListTrialComponents
# operationId: ListTrialComponents
export def "x-amz-target-sage-maker-list-trial-components ListTrialComponents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-237
  --ExperimentName: any
  --TrialName: any
  --SourceArn: any
  --CreatedAfter: any
  --CreatedBefore: any
  --SortBy: any
  --SortOrder: any
  --MaxResults: any
  --NextToken: any
]: any -> record<TrialComponentSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListTrialComponents" $qp)
  let body = {ExperimentName: $ExperimentName, TrialName: $TrialName, SourceArn: $SourceArn, CreatedAfter: $CreatedAfter, CreatedBefore: $CreatedBefore, SortBy: $SortBy, SortOrder: $SortOrder, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the trials in your account. Specify an experiment name to limit the list to the trials that are part of that experiment. Specify a trial component name to limit the list to the trials that associated with that trial component. The list can be filtered to show only trials that were created in a specific time range. The list can be sorted by trial name or creation time.
#
# POST /#X-Amz-Target=SageMaker.ListTrials
# operationId: ListTrials
export def "x-amz-target-sage-maker-list-trials ListTrials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-238
  --ExperimentName: any
  --TrialComponentName: any
  --CreatedAfter: any
  --CreatedBefore: any
  --SortBy: any
  --SortOrder: any
  --MaxResults: any
  --NextToken: any
]: any -> record<TrialSummaries: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListTrials" $qp)
  let body = {ExperimentName: $ExperimentName, TrialComponentName: $TrialComponentName, CreatedAfter: $CreatedAfter, CreatedBefore: $CreatedBefore, SortBy: $SortBy, SortOrder: $SortOrder, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists user profiles.
#
# POST /#X-Amz-Target=SageMaker.ListUserProfiles
# operationId: ListUserProfiles
export def "x-amz-target-sage-maker-list-user-profiles ListUserProfiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-239
  --NextToken: any
  --MaxResults: any
  --SortOrder: any
  --SortBy: any
  --DomainIdEquals: any
  --UserProfileNameContains: any
]: any -> record<UserProfiles: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListUserProfiles" $qp)
  let body = {NextToken: $NextToken, MaxResults: $MaxResults, SortOrder: $SortOrder, SortBy: $SortBy, DomainIdEquals: $DomainIdEquals, UserProfileNameContains: $UserProfileNameContains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use this operation to list all private and vendor workforces in an Amazon Web Services Region. Note that you can only have one private workforce per Amazon Web Services Region.
#
# POST /#X-Amz-Target=SageMaker.ListWorkforces
# operationId: ListWorkforces
export def "x-amz-target-sage-maker-list-workforces ListWorkforces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-240
  --SortBy: any
  --SortOrder: any
  --NameContains: any
  --NextToken: any
  --MaxResults: any
]: any -> record<Workforces: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListWorkforces" $qp)
  let body = {SortBy: $SortBy, SortOrder: $SortOrder, NameContains: $NameContains, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of private work teams that you have defined in a region. The list may be empty if no work team satisfies the filter specified in the <code>NameContains</code> parameter.
#
# POST /#X-Amz-Target=SageMaker.ListWorkteams
# operationId: ListWorkteams
export def "x-amz-target-sage-maker-list-workteams ListWorkteams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-241
  --SortBy: any
  --SortOrder: any
  --NameContains: any
  --NextToken: any
  --MaxResults: any
]: any -> record<Workteams: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.ListWorkteams" $qp)
  let body = {SortBy: $SortBy, SortOrder: $SortOrder, NameContains: $NameContains, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds a resouce policy to control access to a model group. For information about resoure policies, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_identity-vs-resource.html">Identity-based policies and resource-based policies</a> in the <i>Amazon Web Services Identity and Access Management User Guide.</i>.
#
# POST /#X-Amz-Target=SageMaker.PutModelPackageGroupPolicy
# operationId: PutModelPackageGroupPolicy
export def "x-amz-target-sage-maker-put-model-package-group-policy PutModelPackageGroupPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-242
  ModelPackageGroupName: any
  ResourcePolicy: any
]: any -> record<ModelPackageGroupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.PutModelPackageGroupPolicy")
  let body = {ModelPackageGroupName: $ModelPackageGroupName, ResourcePolicy: $ResourcePolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use this action to inspect your lineage and discover relationships between entities. For more information, see <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/querying-lineage-entities.html"> Querying Lineage Entities</a> in the <i>Amazon SageMaker Developer Guide</i>.
#
# POST /#X-Amz-Target=SageMaker.QueryLineage
# operationId: QueryLineage
export def "x-amz-target-sage-maker-query-lineage QueryLineage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-243
  --StartArns: any
  --Direction: any
  --IncludeEdges: any
  --Filters: any
  --MaxDepth: any
  --MaxResults: any
  --NextToken: any
]: any -> record<Vertices: record, Edges: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.QueryLineage" $qp)
  let body = {StartArns: $StartArns, Direction: $Direction, IncludeEdges: $IncludeEdges, Filters: $Filters, MaxDepth: $MaxDepth, MaxResults: $MaxResults, NextToken: $NextToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Register devices.
#
# POST /#X-Amz-Target=SageMaker.RegisterDevices
# operationId: RegisterDevices
export def "x-amz-target-sage-maker-register-devices RegisterDevices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-244
  DeviceFleetName: any
  Devices: any
  --Tags: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.RegisterDevices")
  let body = {DeviceFleetName: $DeviceFleetName, Devices: $Devices, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Renders the UI template so that you can preview the worker's experience. 
#
# POST /#X-Amz-Target=SageMaker.RenderUiTemplate
# operationId: RenderUiTemplate
export def "x-amz-target-sage-maker-render-ui-template RenderUiTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-245
  --UiTemplate: any
  Task: any
  RoleArn: any
  --HumanTaskUiArn: any
]: any -> record<RenderedContent: record, Errors: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.RenderUiTemplate")
  let body = {UiTemplate: $UiTemplate, Task: $Task, RoleArn: $RoleArn, HumanTaskUiArn: $HumanTaskUiArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retry the execution of the pipeline.
#
# POST /#X-Amz-Target=SageMaker.RetryPipelineExecution
# operationId: RetryPipelineExecution
export def "x-amz-target-sage-maker-retry-pipeline-execution RetryPipelineExecution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-246
  PipelineExecutionArn: any
  ClientRequestToken: any
  --ParallelismConfiguration: any
]: any -> record<PipelineExecutionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.RetryPipelineExecution")
  let body = {PipelineExecutionArn: $PipelineExecutionArn, ClientRequestToken: $ClientRequestToken, ParallelismConfiguration: $ParallelismConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Finds SageMaker resources that match a search query. Matching resources are returned as a list of <code>SearchRecord</code> objects in the response. You can sort the search results by any resource property in a ascending or descending order.</p> <p>You can query against the following value types: numeric, text, Boolean, and timestamp.</p> <note> <p>The Search API may provide access to otherwise restricted data. See <a href="https://docs.aws.amazon.com/sagemaker/latest/dg/api-permissions-reference.html">Amazon SageMaker API Permissions: Actions, Permissions, and Resources Reference</a> for more information.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.Search
# operationId: Search
export def "x-amz-target-sage-maker-search Search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MaxResults: string # Pagination limit
  --NextToken: string # Pagination token
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-247
  Resource: any
  --SearchExpression: any
  --SortBy: any
  --SortOrder: any
  --NextToken: any
  --MaxResults: any
]: any -> record<Results: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "NextToken" $NextToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.Search" $qp)
  let body = {Resource: $Resource, SearchExpression: $SearchExpression, SortBy: $SortBy, SortOrder: $SortOrder, NextToken: $NextToken, MaxResults: $MaxResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Notifies the pipeline that the execution of a callback step failed, along with a message describing why. When a callback step is run, the pipeline generates a callback token and includes the token in a message sent to Amazon Simple Queue Service (Amazon SQS).
#
# POST /#X-Amz-Target=SageMaker.SendPipelineExecutionStepFailure
# operationId: SendPipelineExecutionStepFailure
export def "x-amz-target-sage-maker-send-pipeline-execution-step-failure SendPipelineExecutionStepFailure" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-248
  CallbackToken: any
  --FailureReason: any
  --ClientRequestToken: any
]: any -> record<PipelineExecutionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.SendPipelineExecutionStepFailure")
  let body = {CallbackToken: $CallbackToken, FailureReason: $FailureReason, ClientRequestToken: $ClientRequestToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Notifies the pipeline that the execution of a callback step succeeded and provides a list of the step's output parameters. When a callback step is run, the pipeline generates a callback token and includes the token in a message sent to Amazon Simple Queue Service (Amazon SQS).
#
# POST /#X-Amz-Target=SageMaker.SendPipelineExecutionStepSuccess
# operationId: SendPipelineExecutionStepSuccess
export def "x-amz-target-sage-maker-send-pipeline-execution-step-success SendPipelineExecutionStepSuccess" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-249
  CallbackToken: any
  --OutputParameters: any
  --ClientRequestToken: any
]: any -> record<PipelineExecutionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.SendPipelineExecutionStepSuccess")
  let body = {CallbackToken: $CallbackToken, OutputParameters: $OutputParameters, ClientRequestToken: $ClientRequestToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Starts a stage in an edge deployment plan.
#
# POST /#X-Amz-Target=SageMaker.StartEdgeDeploymentStage
# operationId: StartEdgeDeploymentStage
export def "x-amz-target-sage-maker-start-edge-deployment-stage StartEdgeDeploymentStage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-250
  EdgeDeploymentPlanName: any
  StageName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StartEdgeDeploymentStage")
  let body = {EdgeDeploymentPlanName: $EdgeDeploymentPlanName, StageName: $StageName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Starts an inference experiment.
#
# POST /#X-Amz-Target=SageMaker.StartInferenceExperiment
# operationId: StartInferenceExperiment
export def "x-amz-target-sage-maker-start-inference-experiment StartInferenceExperiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-251
  Name: any
]: any -> record<InferenceExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StartInferenceExperiment")
  let body = {Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Starts a previously stopped monitoring schedule.</p> <note> <p>By default, when you successfully create a new schedule, the status of a monitoring schedule is <code>scheduled</code>.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.StartMonitoringSchedule
# operationId: StartMonitoringSchedule
export def "x-amz-target-sage-maker-start-monitoring-schedule StartMonitoringSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-252
  MonitoringScheduleName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StartMonitoringSchedule")
  let body = {MonitoringScheduleName: $MonitoringScheduleName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Launches an ML compute instance with the latest version of the libraries and attaches your ML storage volume. After configuring the notebook instance, SageMaker sets the notebook instance status to <code>InService</code>. A notebook instance's status must be <code>InService</code> before you can connect to your Jupyter notebook. 
#
# POST /#X-Amz-Target=SageMaker.StartNotebookInstance
# operationId: StartNotebookInstance
export def "x-amz-target-sage-maker-start-notebook-instance StartNotebookInstance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-253
  NotebookInstanceName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StartNotebookInstance")
  let body = {NotebookInstanceName: $NotebookInstanceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Starts a pipeline execution.
#
# POST /#X-Amz-Target=SageMaker.StartPipelineExecution
# operationId: StartPipelineExecution
export def "x-amz-target-sage-maker-start-pipeline-execution StartPipelineExecution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-254
  PipelineName: any
  --PipelineExecutionDisplayName: any
  --PipelineParameters: any
  --PipelineExecutionDescription: any
  ClientRequestToken: any
  --ParallelismConfiguration: any
]: any -> record<PipelineExecutionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StartPipelineExecution")
  let body = {PipelineName: $PipelineName, PipelineExecutionDisplayName: $PipelineExecutionDisplayName, PipelineParameters: $PipelineParameters, PipelineExecutionDescription: $PipelineExecutionDescription, ClientRequestToken: $ClientRequestToken, ParallelismConfiguration: $ParallelismConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# A method for forcing a running job to shut down.
#
# POST /#X-Amz-Target=SageMaker.StopAutoMLJob
# operationId: StopAutoMLJob
export def "x-amz-target-sage-maker-stop-auto-ml-job StopAutoMLJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-255
  AutoMLJobName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopAutoMLJob")
  let body = {AutoMLJobName: $AutoMLJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Stops a model compilation job.</p> <p> To stop a job, Amazon SageMaker sends the algorithm the SIGTERM signal. This gracefully shuts the job down. If the job hasn't stopped, it sends the SIGKILL signal.</p> <p>When it receives a <code>StopCompilationJob</code> request, Amazon SageMaker changes the <code>CompilationJobStatus</code> of the job to <code>Stopping</code>. After Amazon SageMaker stops the job, it sets the <code>CompilationJobStatus</code> to <code>Stopped</code>. </p>
#
# POST /#X-Amz-Target=SageMaker.StopCompilationJob
# operationId: StopCompilationJob
export def "x-amz-target-sage-maker-stop-compilation-job StopCompilationJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-256
  CompilationJobName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopCompilationJob")
  let body = {CompilationJobName: $CompilationJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stops a stage in an edge deployment plan.
#
# POST /#X-Amz-Target=SageMaker.StopEdgeDeploymentStage
# operationId: StopEdgeDeploymentStage
export def "x-amz-target-sage-maker-stop-edge-deployment-stage StopEdgeDeploymentStage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-257
  EdgeDeploymentPlanName: any
  StageName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopEdgeDeploymentStage")
  let body = {EdgeDeploymentPlanName: $EdgeDeploymentPlanName, StageName: $StageName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request to stop an edge packaging job.
#
# POST /#X-Amz-Target=SageMaker.StopEdgePackagingJob
# operationId: StopEdgePackagingJob
export def "x-amz-target-sage-maker-stop-edge-packaging-job StopEdgePackagingJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-258
  EdgePackagingJobName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopEdgePackagingJob")
  let body = {EdgePackagingJobName: $EdgePackagingJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Stops a running hyperparameter tuning job and all running training jobs that the tuning job launched.</p> <p>All model artifacts output from the training jobs are stored in Amazon Simple Storage Service (Amazon S3). All data that the training jobs write to Amazon CloudWatch Logs are still available in CloudWatch. After the tuning job moves to the <code>Stopped</code> state, it releases all reserved resources for the tuning job.</p>
#
# POST /#X-Amz-Target=SageMaker.StopHyperParameterTuningJob
# operationId: StopHyperParameterTuningJob
export def "x-amz-target-sage-maker-stop-hyper-parameter-tuning-job StopHyperParameterTuningJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-259
  HyperParameterTuningJobName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopHyperParameterTuningJob")
  let body = {HyperParameterTuningJobName: $HyperParameterTuningJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stops an inference experiment.
#
# POST /#X-Amz-Target=SageMaker.StopInferenceExperiment
# operationId: StopInferenceExperiment
export def "x-amz-target-sage-maker-stop-inference-experiment StopInferenceExperiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-260
  Name: any
  ModelVariantActions: any
  --DesiredModelVariants: any
  --DesiredState: any
  --Reason: any
]: any -> record<InferenceExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopInferenceExperiment")
  let body = {Name: $Name, ModelVariantActions: $ModelVariantActions, DesiredModelVariants: $DesiredModelVariants, DesiredState: $DesiredState, Reason: $Reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stops an Inference Recommender job.
#
# POST /#X-Amz-Target=SageMaker.StopInferenceRecommendationsJob
# operationId: StopInferenceRecommendationsJob
export def "x-amz-target-sage-maker-stop-inference-recommendations-job StopInferenceRecommendationsJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-261
  JobName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopInferenceRecommendationsJob")
  let body = {JobName: $JobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stops a running labeling job. A job that is stopped cannot be restarted. Any results obtained before the job is stopped are placed in the Amazon S3 output bucket.
#
# POST /#X-Amz-Target=SageMaker.StopLabelingJob
# operationId: StopLabelingJob
export def "x-amz-target-sage-maker-stop-labeling-job StopLabelingJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-262
  LabelingJobName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopLabelingJob")
  let body = {LabelingJobName: $LabelingJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stops a previously started monitoring schedule.
#
# POST /#X-Amz-Target=SageMaker.StopMonitoringSchedule
# operationId: StopMonitoringSchedule
export def "x-amz-target-sage-maker-stop-monitoring-schedule StopMonitoringSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-263
  MonitoringScheduleName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopMonitoringSchedule")
  let body = {MonitoringScheduleName: $MonitoringScheduleName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Terminates the ML compute instance. Before terminating the instance, SageMaker disconnects the ML storage volume from it. SageMaker preserves the ML storage volume. SageMaker stops charging you for the ML compute instance when you call <code>StopNotebookInstance</code>.</p> <p>To access data on the ML storage volume for a notebook instance that has been terminated, call the <code>StartNotebookInstance</code> API. <code>StartNotebookInstance</code> launches another ML compute instance, configures it, and attaches the preserved ML storage volume so you can continue your work. </p>
#
# POST /#X-Amz-Target=SageMaker.StopNotebookInstance
# operationId: StopNotebookInstance
export def "x-amz-target-sage-maker-stop-notebook-instance StopNotebookInstance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-264
  NotebookInstanceName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopNotebookInstance")
  let body = {NotebookInstanceName: $NotebookInstanceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Stops a pipeline execution.</p> <p> <b>Callback Step</b> </p> <p>A pipeline execution won't stop while a callback step is running. When you call <code>StopPipelineExecution</code> on a pipeline execution with a running callback step, SageMaker Pipelines sends an additional Amazon SQS message to the specified SQS queue. The body of the SQS message contains a "Status" field which is set to "Stopping".</p> <p>You should add logic to your Amazon SQS message consumer to take any needed action (for example, resource cleanup) upon receipt of the message followed by a call to <code>SendPipelineExecutionStepSuccess</code> or <code>SendPipelineExecutionStepFailure</code>.</p> <p>Only when SageMaker Pipelines receives one of these calls will it stop the pipeline execution.</p> <p> <b>Lambda Step</b> </p> <p>A pipeline execution can't be stopped while a lambda step is running because the Lambda function invoked by the lambda step can't be stopped. If you attempt to stop the execution while the Lambda function is running, the pipeline waits for the Lambda function to finish or until the timeout is hit, whichever occurs first, and then stops. If the Lambda function finishes, the pipeline execution status is <code>Stopped</code>. If the timeout is hit the pipeline execution status is <code>Failed</code>.</p>
#
# POST /#X-Amz-Target=SageMaker.StopPipelineExecution
# operationId: StopPipelineExecution
export def "x-amz-target-sage-maker-stop-pipeline-execution StopPipelineExecution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-265
  PipelineExecutionArn: any
  ClientRequestToken: any
]: any -> record<PipelineExecutionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopPipelineExecution")
  let body = {PipelineExecutionArn: $PipelineExecutionArn, ClientRequestToken: $ClientRequestToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stops a processing job.
#
# POST /#X-Amz-Target=SageMaker.StopProcessingJob
# operationId: StopProcessingJob
export def "x-amz-target-sage-maker-stop-processing-job StopProcessingJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-266
  ProcessingJobName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopProcessingJob")
  let body = {ProcessingJobName: $ProcessingJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Stops a training job. To stop a job, SageMaker sends the algorithm the <code>SIGTERM</code> signal, which delays job termination for 120 seconds. Algorithms might use this 120-second window to save the model artifacts, so the results of the training is not lost. </p> <p>When it receives a <code>StopTrainingJob</code> request, SageMaker changes the status of the job to <code>Stopping</code>. After SageMaker stops the job, it sets the status to <code>Stopped</code>.</p>
#
# POST /#X-Amz-Target=SageMaker.StopTrainingJob
# operationId: StopTrainingJob
export def "x-amz-target-sage-maker-stop-training-job StopTrainingJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-267
  TrainingJobName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopTrainingJob")
  let body = {TrainingJobName: $TrainingJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Stops a batch transform job.</p> <p>When Amazon SageMaker receives a <code>StopTransformJob</code> request, the status of the job changes to <code>Stopping</code>. After Amazon SageMaker stops the job, the status is set to <code>Stopped</code>. When you stop a batch transform job before it is completed, Amazon SageMaker doesn't store the job's output in Amazon S3.</p>
#
# POST /#X-Amz-Target=SageMaker.StopTransformJob
# operationId: StopTransformJob
export def "x-amz-target-sage-maker-stop-transform-job StopTransformJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-268
  TransformJobName: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.StopTransformJob")
  let body = {TransformJobName: $TransformJobName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an action.
#
# POST /#X-Amz-Target=SageMaker.UpdateAction
# operationId: UpdateAction
export def "x-amz-target-sage-maker-update-action UpdateAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-269
  ActionName: any
  --Description: any
  --Status: any
  --Properties: any
  --PropertiesToRemove: any
]: any -> record<ActionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateAction")
  let body = {ActionName: $ActionName, Description: $Description, Status: $Status, Properties: $Properties, PropertiesToRemove: $PropertiesToRemove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the properties of an AppImageConfig.
#
# POST /#X-Amz-Target=SageMaker.UpdateAppImageConfig
# operationId: UpdateAppImageConfig
export def "x-amz-target-sage-maker-update-app-image-config UpdateAppImageConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-270
  AppImageConfigName: any
  --KernelGatewayImageConfig: any
]: any -> record<AppImageConfigArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateAppImageConfig")
  let body = {AppImageConfigName: $AppImageConfigName, KernelGatewayImageConfig: $KernelGatewayImageConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an artifact.
#
# POST /#X-Amz-Target=SageMaker.UpdateArtifact
# operationId: UpdateArtifact
export def "x-amz-target-sage-maker-update-artifact UpdateArtifact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-271
  ArtifactArn: any
  --ArtifactName: any
  --Properties: any
  --PropertiesToRemove: any
]: any -> record<ArtifactArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateArtifact")
  let body = {ArtifactArn: $ArtifactArn, ArtifactName: $ArtifactName, Properties: $Properties, PropertiesToRemove: $PropertiesToRemove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the specified Git repository with the specified values.
#
# POST /#X-Amz-Target=SageMaker.UpdateCodeRepository
# operationId: UpdateCodeRepository
export def "x-amz-target-sage-maker-update-code-repository UpdateCodeRepository" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-272
  CodeRepositoryName: any
  --GitConfig: any
]: any -> record<CodeRepositoryArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateCodeRepository")
  let body = {CodeRepositoryName: $CodeRepositoryName, GitConfig: $GitConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a context.
#
# POST /#X-Amz-Target=SageMaker.UpdateContext
# operationId: UpdateContext
export def "x-amz-target-sage-maker-update-context UpdateContext" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-273
  ContextName: any
  --Description: any
  --Properties: any
  --PropertiesToRemove: any
]: any -> record<ContextArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateContext")
  let body = {ContextName: $ContextName, Description: $Description, Properties: $Properties, PropertiesToRemove: $PropertiesToRemove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a fleet of devices.
#
# POST /#X-Amz-Target=SageMaker.UpdateDeviceFleet
# operationId: UpdateDeviceFleet
export def "x-amz-target-sage-maker-update-device-fleet UpdateDeviceFleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-274
  DeviceFleetName: any
  --RoleArn: any
  --Description: any
  OutputConfig: any
  --EnableIotRoleAlias: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateDeviceFleet")
  let body = {DeviceFleetName: $DeviceFleetName, RoleArn: $RoleArn, Description: $Description, OutputConfig: $OutputConfig, EnableIotRoleAlias: $EnableIotRoleAlias} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates one or more devices in a fleet.
#
# POST /#X-Amz-Target=SageMaker.UpdateDevices
# operationId: UpdateDevices
export def "x-amz-target-sage-maker-update-devices UpdateDevices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-275
  DeviceFleetName: any
  Devices: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateDevices")
  let body = {DeviceFleetName: $DeviceFleetName, Devices: $Devices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the default settings for new user profiles in the domain.
#
# POST /#X-Amz-Target=SageMaker.UpdateDomain
# operationId: UpdateDomain
export def "x-amz-target-sage-maker-update-domain UpdateDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-276
  DomainId: any
  --DefaultUserSettings: any
  --DomainSettingsForUpdate: any
  --DefaultSpaceSettings: any
  --AppSecurityGroupManagement: any
]: any -> record<DomainArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateDomain")
  let body = {DomainId: $DomainId, DefaultUserSettings: $DefaultUserSettings, DomainSettingsForUpdate: $DomainSettingsForUpdate, DefaultSpaceSettings: $DefaultSpaceSettings, AppSecurityGroupManagement: $AppSecurityGroupManagement} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Deploys the new <code>EndpointConfig</code> specified in the request, switches to using newly created endpoint, and then deletes resources provisioned for the endpoint using the previous <code>EndpointConfig</code> (there is no availability loss). </p> <p>When SageMaker receives the request, it sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeEndpoint.html">DescribeEndpoint</a> API. </p> <note> <p>You must not delete an <code>EndpointConfig</code> in use by an endpoint that is live or while the <code>UpdateEndpoint</code> or <code>CreateEndpoint</code> operations are being performed on the endpoint. To update an endpoint, you must create a new <code>EndpointConfig</code>.</p> <p>If you delete the <code>EndpointConfig</code> of an endpoint that is active or being created or updated you may lose visibility into the instance type the endpoint is using. The endpoint must be deleted in order to stop incurring charges.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.UpdateEndpoint
# operationId: UpdateEndpoint
export def "x-amz-target-sage-maker-update-endpoint UpdateEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-277
  EndpointName: any
  EndpointConfigName: any
  --RetainAllVariantProperties: any
  --ExcludeRetainedVariantProperties: any
  --DeploymentConfig: any
  --RetainDeploymentConfig: any
]: any -> record<EndpointArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateEndpoint")
  let body = {EndpointName: $EndpointName, EndpointConfigName: $EndpointConfigName, RetainAllVariantProperties: $RetainAllVariantProperties, ExcludeRetainedVariantProperties: $ExcludeRetainedVariantProperties, DeploymentConfig: $DeploymentConfig, RetainDeploymentConfig: $RetainDeploymentConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates variant weight of one or more variants associated with an existing endpoint, or capacity of one variant associated with an existing endpoint. When it receives the request, SageMaker sets the endpoint status to <code>Updating</code>. After updating the endpoint, it sets the status to <code>InService</code>. To check the status of an endpoint, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeEndpoint.html">DescribeEndpoint</a> API. 
#
# POST /#X-Amz-Target=SageMaker.UpdateEndpointWeightsAndCapacities
# operationId: UpdateEndpointWeightsAndCapacities
export def "x-amz-target-sage-maker-update-endpoint-weights-and-capacities UpdateEndpointWeightsAndCapacities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-278
  EndpointName: any
  DesiredWeightsAndCapacities: any
]: any -> record<EndpointArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateEndpointWeightsAndCapacities")
  let body = {EndpointName: $EndpointName, DesiredWeightsAndCapacities: $DesiredWeightsAndCapacities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds, updates, or removes the description of an experiment. Updates the display name of an experiment.
#
# POST /#X-Amz-Target=SageMaker.UpdateExperiment
# operationId: UpdateExperiment
export def "x-amz-target-sage-maker-update-experiment UpdateExperiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-279
  ExperimentName: any
  --DisplayName: any
  --Description: any
]: any -> record<ExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateExperiment")
  let body = {ExperimentName: $ExperimentName, DisplayName: $DisplayName, Description: $Description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the feature group.
#
# POST /#X-Amz-Target=SageMaker.UpdateFeatureGroup
# operationId: UpdateFeatureGroup
export def "x-amz-target-sage-maker-update-feature-group UpdateFeatureGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-280
  FeatureGroupName: any
  --FeatureAdditions: any
]: any -> record<FeatureGroupArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateFeatureGroup")
  let body = {FeatureGroupName: $FeatureGroupName, FeatureAdditions: $FeatureAdditions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the description and parameters of the feature group.
#
# POST /#X-Amz-Target=SageMaker.UpdateFeatureMetadata
# operationId: UpdateFeatureMetadata
export def "x-amz-target-sage-maker-update-feature-metadata UpdateFeatureMetadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-281
  FeatureGroupName: any
  FeatureName: any
  --Description: any
  --ParameterAdditions: any
  --ParameterRemovals: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateFeatureMetadata")
  let body = {FeatureGroupName: $FeatureGroupName, FeatureName: $FeatureName, Description: $Description, ParameterAdditions: $ParameterAdditions, ParameterRemovals: $ParameterRemovals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Update a hub.</p> <note> <p>Hub APIs are only callable through SageMaker Studio.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.UpdateHub
# operationId: UpdateHub
export def "x-amz-target-sage-maker-update-hub UpdateHub" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-282
  HubName: any
  --HubDescription: any
  --HubDisplayName: any
  --HubSearchKeywords: any
]: any -> record<HubArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateHub")
  let body = {HubName: $HubName, HubDescription: $HubDescription, HubDisplayName: $HubDisplayName, HubSearchKeywords: $HubSearchKeywords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the properties of a SageMaker image. To change the image's tags, use the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_AddTags.html">AddTags</a> and <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DeleteTags.html">DeleteTags</a> APIs.
#
# POST /#X-Amz-Target=SageMaker.UpdateImage
# operationId: UpdateImage
export def "x-amz-target-sage-maker-update-image UpdateImage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-283
  --DeleteProperties: any
  --Description: any
  --DisplayName: any
  ImageName: any
  --RoleArn: any
]: any -> record<ImageArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateImage")
  let body = {DeleteProperties: $DeleteProperties, Description: $Description, DisplayName: $DisplayName, ImageName: $ImageName, RoleArn: $RoleArn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the properties of a SageMaker image version.
#
# POST /#X-Amz-Target=SageMaker.UpdateImageVersion
# operationId: UpdateImageVersion
export def "x-amz-target-sage-maker-update-image-version UpdateImageVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-284
  ImageName: any
  --Alias: any
  --Version: any
  --AliasesToAdd: any
  --AliasesToDelete: any
  --VendorGuidance: any
  --JobType: any
  --MLFramework: any
  --ProgrammingLang: any
  --Processor: any
  --Horovod: any
  --ReleaseNotes: any
]: any -> record<ImageVersionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateImageVersion")
  let body = {ImageName: $ImageName, Alias: $Alias, Version: $Version, AliasesToAdd: $AliasesToAdd, AliasesToDelete: $AliasesToDelete, VendorGuidance: $VendorGuidance, JobType: $JobType, MLFramework: $MLFramework, ProgrammingLang: $ProgrammingLang, Processor: $Processor, Horovod: $Horovod, ReleaseNotes: $ReleaseNotes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

#  Updates an inference experiment that you created. The status of the inference experiment has to be either <code>Created</code>, <code>Running</code>. For more information on the status of an inference experiment, see <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeInferenceExperiment.html">DescribeInferenceExperiment</a>. 
#
# POST /#X-Amz-Target=SageMaker.UpdateInferenceExperiment
# operationId: UpdateInferenceExperiment
export def "x-amz-target-sage-maker-update-inference-experiment UpdateInferenceExperiment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-285
  Name: any
  --Schedule: any
  --Description: any
  --ModelVariants: any
  --DataStorageConfig: any
  --ShadowModeConfig: any
]: any -> record<InferenceExperimentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateInferenceExperiment")
  let body = {Name: $Name, Schedule: $Schedule, Description: $Description, ModelVariants: $ModelVariants, DataStorageConfig: $DataStorageConfig, ShadowModeConfig: $ShadowModeConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Update an Amazon SageMaker Model Card.</p> <important> <p>You cannot update both model card content and model card status in a single call.</p> </important>
#
# POST /#X-Amz-Target=SageMaker.UpdateModelCard
# operationId: UpdateModelCard
export def "x-amz-target-sage-maker-update-model-card UpdateModelCard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-286
  ModelCardName: any
  --Content: any
  --ModelCardStatus: any
]: any -> record<ModelCardArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateModelCard")
  let body = {ModelCardName: $ModelCardName, Content: $Content, ModelCardStatus: $ModelCardStatus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a versioned model.
#
# POST /#X-Amz-Target=SageMaker.UpdateModelPackage
# operationId: UpdateModelPackage
export def "x-amz-target-sage-maker-update-model-package UpdateModelPackage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-287
  ModelPackageArn: any
  --ModelApprovalStatus: any
  --ApprovalDescription: any
  --CustomerMetadataProperties: any
  --CustomerMetadataPropertiesToRemove: any
  --AdditionalInferenceSpecificationsToAdd: any
]: any -> record<ModelPackageArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateModelPackage")
  let body = {ModelPackageArn: $ModelPackageArn, ModelApprovalStatus: $ModelApprovalStatus, ApprovalDescription: $ApprovalDescription, CustomerMetadataProperties: $CustomerMetadataProperties, CustomerMetadataPropertiesToRemove: $CustomerMetadataPropertiesToRemove, AdditionalInferenceSpecificationsToAdd: $AdditionalInferenceSpecificationsToAdd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the parameters of a model monitor alert.
#
# POST /#X-Amz-Target=SageMaker.UpdateMonitoringAlert
# operationId: UpdateMonitoringAlert
export def "x-amz-target-sage-maker-update-monitoring-alert UpdateMonitoringAlert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-288
  MonitoringScheduleName: any
  MonitoringAlertName: any
  DatapointsToAlert: any
  EvaluationPeriod: any
]: any -> record<MonitoringScheduleArn: record, MonitoringAlertName: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateMonitoringAlert")
  let body = {MonitoringScheduleName: $MonitoringScheduleName, MonitoringAlertName: $MonitoringAlertName, DatapointsToAlert: $DatapointsToAlert, EvaluationPeriod: $EvaluationPeriod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a previously created schedule.
#
# POST /#X-Amz-Target=SageMaker.UpdateMonitoringSchedule
# operationId: UpdateMonitoringSchedule
export def "x-amz-target-sage-maker-update-monitoring-schedule UpdateMonitoringSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-289
  MonitoringScheduleName: any
  MonitoringScheduleConfig: any
]: any -> record<MonitoringScheduleArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateMonitoringSchedule")
  let body = {MonitoringScheduleName: $MonitoringScheduleName, MonitoringScheduleConfig: $MonitoringScheduleConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a notebook instance. NotebookInstance updates include upgrading or downgrading the ML compute instance used for your notebook instance to accommodate changes in your workload requirements.
#
# POST /#X-Amz-Target=SageMaker.UpdateNotebookInstance
# operationId: UpdateNotebookInstance
export def "x-amz-target-sage-maker-update-notebook-instance UpdateNotebookInstance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-290
  NotebookInstanceName: any
  --InstanceType: any
  --RoleArn: any
  --LifecycleConfigName: any
  --DisassociateLifecycleConfig: any
  --VolumeSizeInGB: any
  --DefaultCodeRepository: any
  --AdditionalCodeRepositories: any
  --AcceleratorTypes: any
  --DisassociateAcceleratorTypes: any
  --DisassociateDefaultCodeRepository: any
  --DisassociateAdditionalCodeRepositories: any
  --RootAccess: any
  --InstanceMetadataServiceConfiguration: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateNotebookInstance")
  let body = {NotebookInstanceName: $NotebookInstanceName, InstanceType: $InstanceType, RoleArn: $RoleArn, LifecycleConfigName: $LifecycleConfigName, DisassociateLifecycleConfig: $DisassociateLifecycleConfig, VolumeSizeInGB: $VolumeSizeInGB, DefaultCodeRepository: $DefaultCodeRepository, AdditionalCodeRepositories: $AdditionalCodeRepositories, AcceleratorTypes: $AcceleratorTypes, DisassociateAcceleratorTypes: $DisassociateAcceleratorTypes, DisassociateDefaultCodeRepository: $DisassociateDefaultCodeRepository, DisassociateAdditionalCodeRepositories: $DisassociateAdditionalCodeRepositories, RootAccess: $RootAccess, InstanceMetadataServiceConfiguration: $InstanceMetadataServiceConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a notebook instance lifecycle configuration created with the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateNotebookInstanceLifecycleConfig.html">CreateNotebookInstanceLifecycleConfig</a> API.
#
# POST /#X-Amz-Target=SageMaker.UpdateNotebookInstanceLifecycleConfig
# operationId: UpdateNotebookInstanceLifecycleConfig
export def "x-amz-target-sage-maker-update-notebook-instance-lifecycle-config UpdateNotebookInstanceLifecycleConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-291
  NotebookInstanceLifecycleConfigName: any
  --OnCreate: any
  --OnStart: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateNotebookInstanceLifecycleConfig")
  let body = {NotebookInstanceLifecycleConfigName: $NotebookInstanceLifecycleConfigName, OnCreate: $OnCreate, OnStart: $OnStart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a pipeline.
#
# POST /#X-Amz-Target=SageMaker.UpdatePipeline
# operationId: UpdatePipeline
export def "x-amz-target-sage-maker-update-pipeline UpdatePipeline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-292
  PipelineName: any
  --PipelineDisplayName: any
  --PipelineDefinition: any
  --PipelineDefinitionS3Location: any
  --PipelineDescription: any
  --RoleArn: any
  --ParallelismConfiguration: any
]: any -> record<PipelineArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdatePipeline")
  let body = {PipelineName: $PipelineName, PipelineDisplayName: $PipelineDisplayName, PipelineDefinition: $PipelineDefinition, PipelineDefinitionS3Location: $PipelineDefinitionS3Location, PipelineDescription: $PipelineDescription, RoleArn: $RoleArn, ParallelismConfiguration: $ParallelismConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a pipeline execution.
#
# POST /#X-Amz-Target=SageMaker.UpdatePipelineExecution
# operationId: UpdatePipelineExecution
export def "x-amz-target-sage-maker-update-pipeline-execution UpdatePipelineExecution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-293
  PipelineExecutionArn: any
  --PipelineExecutionDescription: any
  --PipelineExecutionDisplayName: any
  --ParallelismConfiguration: any
]: any -> record<PipelineExecutionArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdatePipelineExecution")
  let body = {PipelineExecutionArn: $PipelineExecutionArn, PipelineExecutionDescription: $PipelineExecutionDescription, PipelineExecutionDisplayName: $PipelineExecutionDisplayName, ParallelismConfiguration: $ParallelismConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Updates a machine learning (ML) project that is created from a template that sets up an ML pipeline from training to deploying an approved model.</p> <note> <p>You must not update a project that is in use. If you update the <code>ServiceCatalogProvisioningUpdateDetails</code> of a project that is active or being created, or updated, you may lose resources already created by the project.</p> </note>
#
# POST /#X-Amz-Target=SageMaker.UpdateProject
# operationId: UpdateProject
export def "x-amz-target-sage-maker-update-project UpdateProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-294
  ProjectName: any
  --ProjectDescription: any
  --ServiceCatalogProvisioningUpdateDetails: any
  --Tags: any
]: any -> record<ProjectArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateProject")
  let body = {ProjectName: $ProjectName, ProjectDescription: $ProjectDescription, ServiceCatalogProvisioningUpdateDetails: $ServiceCatalogProvisioningUpdateDetails, Tags: $Tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the settings of a space.
#
# POST /#X-Amz-Target=SageMaker.UpdateSpace
# operationId: UpdateSpace
export def "x-amz-target-sage-maker-update-space UpdateSpace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-295
  DomainId: any
  SpaceName: any
  --SpaceSettings: any
]: any -> record<SpaceArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateSpace")
  let body = {DomainId: $DomainId, SpaceName: $SpaceName, SpaceSettings: $SpaceSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a model training job to request a new Debugger profiling configuration or to change warm pool retention length.
#
# POST /#X-Amz-Target=SageMaker.UpdateTrainingJob
# operationId: UpdateTrainingJob
export def "x-amz-target-sage-maker-update-training-job UpdateTrainingJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-296
  TrainingJobName: any
  --ProfilerConfig: any
  --ProfilerRuleConfigurations: any
  --ResourceConfig: any
]: any -> record<TrainingJobArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateTrainingJob")
  let body = {TrainingJobName: $TrainingJobName, ProfilerConfig: $ProfilerConfig, ProfilerRuleConfigurations: $ProfilerRuleConfigurations, ResourceConfig: $ResourceConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the display name of a trial.
#
# POST /#X-Amz-Target=SageMaker.UpdateTrial
# operationId: UpdateTrial
export def "x-amz-target-sage-maker-update-trial UpdateTrial" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-297
  TrialName: any
  --DisplayName: any
]: any -> record<TrialArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateTrial")
  let body = {TrialName: $TrialName, DisplayName: $DisplayName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates one or more properties of a trial component.
#
# POST /#X-Amz-Target=SageMaker.UpdateTrialComponent
# operationId: UpdateTrialComponent
export def "x-amz-target-sage-maker-update-trial-component UpdateTrialComponent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-298
  TrialComponentName: any
  --DisplayName: any
  --Status: any
  --StartTime: any
  --EndTime: any
  --Parameters: any
  --ParametersToRemove: any
  --InputArtifacts: any
  --InputArtifactsToRemove: any
  --OutputArtifacts: any
  --OutputArtifactsToRemove: any
]: any -> record<TrialComponentArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateTrialComponent")
  let body = {TrialComponentName: $TrialComponentName, DisplayName: $DisplayName, Status: $Status, StartTime: $StartTime, EndTime: $EndTime, Parameters: $Parameters, ParametersToRemove: $ParametersToRemove, InputArtifacts: $InputArtifacts, InputArtifactsToRemove: $InputArtifactsToRemove, OutputArtifacts: $OutputArtifacts, OutputArtifactsToRemove: $OutputArtifactsToRemove} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a user profile.
#
# POST /#X-Amz-Target=SageMaker.UpdateUserProfile
# operationId: UpdateUserProfile
export def "x-amz-target-sage-maker-update-user-profile UpdateUserProfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-299
  DomainId: any
  UserProfileName: any
  --UserSettings: any
]: any -> record<UserProfileArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateUserProfile")
  let body = {DomainId: $DomainId, UserProfileName: $UserProfileName, UserSettings: $UserSettings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <p>Use this operation to update your workforce. You can use this operation to require that workers use specific IP addresses to work on tasks and to update your OpenID Connect (OIDC) Identity Provider (IdP) workforce configuration.</p> <p>The worker portal is now supported in VPC and public internet.</p> <p> Use <code>SourceIpConfig</code> to restrict worker access to tasks to a specific range of IP addresses. You specify allowed IP addresses by creating a list of up to ten <a href="https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html">CIDRs</a>. By default, a workforce isn't restricted to specific IP addresses. If you specify a range of IP addresses, workers who attempt to access tasks using any IP address outside the specified range are denied and get a <code>Not Found</code> error message on the worker portal.</p> <p>To restrict access to all the workers in public internet, add the <code>SourceIpConfig</code> CIDR value as "10.0.0.0/16".</p> <important> <p>Amazon SageMaker does not support Source Ip restriction for worker portals in VPC.</p> </important> <p>Use <code>OidcConfig</code> to update the configuration of a workforce created using your own OIDC IdP. </p> <important> <p>You can only update your OIDC IdP configuration when there are no work teams associated with your workforce. You can delete work teams using the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DeleteWorkteam.html">DeleteWorkteam</a> operation.</p> </important> <p>After restricting access to a range of IP addresses or updating your OIDC IdP configuration with this operation, you can view details about your update workforce using the <a href="https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DescribeWorkforce.html">DescribeWorkforce</a> operation.</p> <important> <p>This operation only applies to private workforces.</p> </important>
#
# POST /#X-Amz-Target=SageMaker.UpdateWorkforce
# operationId: UpdateWorkforce
export def "x-amz-target-sage-maker-update-workforce UpdateWorkforce" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-300
  WorkforceName: any
  --SourceIpConfig: any
  --OidcConfig: any
  --WorkforceVpcConfig: any
]: any -> record<Workforce: record<WorkforceName: record, WorkforceArn: record, LastUpdatedDate: record, SourceIpConfig: record<Cidrs: record>, SubDomain: record, CognitoConfig: record<UserPool: record, ClientId: record>, OidcConfig: record<ClientId: record, Issuer: record, AuthorizationEndpoint: record, TokenEndpoint: record, UserInfoEndpoint: record, LogoutEndpoint: record, JwksUri: record>, CreateDate: record, WorkforceVpcConfig: record<VpcId: record, SecurityGroupIds: record, Subnets: record, VpcEndpointId: record>, Status: record, FailureReason: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateWorkforce")
  let body = {WorkforceName: $WorkforceName, SourceIpConfig: $SourceIpConfig, OidcConfig: $OidcConfig, WorkforceVpcConfig: $WorkforceVpcConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an existing work team with new member definitions or description.
#
# POST /#X-Amz-Target=SageMaker.UpdateWorkteam
# operationId: UpdateWorkteam
export def "x-amz-target-sage-maker-update-workteam UpdateWorkteam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Amz-Content-Sha256: string
  --X-Amz-Date: string
  --X-Amz-Algorithm: string
  --X-Amz-Credential: string
  --X-Amz-Security-Token: string
  --X-Amz-Signature: string
  --X-Amz-SignedHeaders: string
  --X-Amz-Target: string@X-Amz-Target-completer-301
  WorkteamName: any
  --MemberDefinitions: any
  --Description: any
  --NotificationConfiguration: any
]: any -> record<Workteam: record<WorkteamName: record, MemberDefinitions: record, WorkteamArn: record, WorkforceArn: record, ProductListingIds: record, Description: record, SubDomain: record, CreateDate: record, LastUpdatedDate: record, NotificationConfiguration: record<NotificationTopicArn: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/#X-Amz-Target=SageMaker.UpdateWorkteam")
  let body = {WorkteamName: $WorkteamName, MemberDefinitions: $MemberDefinitions, Description: $Description, NotificationConfiguration: $NotificationConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Amz-Content-Sha256": $X_Amz_Content_Sha256, "X-Amz-Date": $X_Amz_Date, "X-Amz-Algorithm": $X_Amz_Algorithm, "X-Amz-Credential": $X_Amz_Credential, "X-Amz-Security-Token": $X_Amz_Security_Token, "X-Amz-Signature": $X_Amz_Signature, "X-Amz-SignedHeaders": $X_Amz_SignedHeaders, "X-Amz-Target": $X_Amz_Target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
