# Auto-generated client for AWS Config v2014-11-12
# Source: https://api.apis.guru/v2/specs/amazonaws.com/config/2014-11-12/openapi.json
# Auth: --token flag or $env.AWS_CONFIG_TOKEN

const BASE_URL = "http://config.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_CONFIG_TOKEN | default "" }
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

def base-url-completer [] { ["http://config.us-east-1.amazonaws.com" "http://config.us-east-2.amazonaws.com" "http://config.us-west-1.amazonaws.com" "http://config.us-west-2.amazonaws.com" "http://config.us-gov-west-1.amazonaws.com" "http://config.us-gov-east-1.amazonaws.com" "http://config.ca-central-1.amazonaws.com" "http://config.eu-north-1.amazonaws.com" "http://config.eu-west-1.amazonaws.com" "http://config.eu-west-2.amazonaws.com" "http://config.eu-west-3.amazonaws.com" "http://config.eu-central-1.amazonaws.com" "http://config.eu-south-1.amazonaws.com" "http://config.af-south-1.amazonaws.com" "http://config.ap-northeast-1.amazonaws.com" "http://config.ap-northeast-2.amazonaws.com" "http://config.ap-northeast-3.amazonaws.com" "http://config.ap-southeast-1.amazonaws.com" "http://config.ap-southeast-2.amazonaws.com" "http://config.ap-east-1.amazonaws.com" "http://config.ap-south-1.amazonaws.com" "http://config.sa-east-1.amazonaws.com" "http://config.me-south-1.amazonaws.com" "https://config.us-east-1.amazonaws.com" "https://config.us-east-2.amazonaws.com" "https://config.us-west-1.amazonaws.com" "https://config.us-west-2.amazonaws.com" "https://config.us-gov-west-1.amazonaws.com" "https://config.us-gov-east-1.amazonaws.com" "https://config.ca-central-1.amazonaws.com" "https://config.eu-north-1.amazonaws.com" "https://config.eu-west-1.amazonaws.com" "https://config.eu-west-2.amazonaws.com" "https://config.eu-west-3.amazonaws.com" "https://config.eu-central-1.amazonaws.com" "https://config.eu-south-1.amazonaws.com" "https://config.af-south-1.amazonaws.com" "https://config.ap-northeast-1.amazonaws.com" "https://config.ap-northeast-2.amazonaws.com" "https://config.ap-northeast-3.amazonaws.com" "https://config.ap-southeast-1.amazonaws.com" "https://config.ap-southeast-2.amazonaws.com" "https://config.ap-east-1.amazonaws.com" "https://config.ap-south-1.amazonaws.com" "https://config.sa-east-1.amazonaws.com" "https://config.me-south-1.amazonaws.com" "http://config.cn-north-1.amazonaws.com.cn" "http://config.cn-northwest-1.amazonaws.com.cn" "https://config.cn-north-1.amazonaws.com.cn" "https://config.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["StarlingDoveService.BatchGetAggregateResourceConfig"] }
def x-amz-target-completer-1 [] { ["StarlingDoveService.BatchGetResourceConfig"] }
def x-amz-target-completer-2 [] { ["StarlingDoveService.DeleteAggregationAuthorization"] }
def x-amz-target-completer-3 [] { ["StarlingDoveService.DeleteConfigRule"] }
def x-amz-target-completer-4 [] { ["StarlingDoveService.DeleteConfigurationAggregator"] }
def x-amz-target-completer-5 [] { ["StarlingDoveService.DeleteConfigurationRecorder"] }
def x-amz-target-completer-6 [] { ["StarlingDoveService.DeleteConformancePack"] }
def x-amz-target-completer-7 [] { ["StarlingDoveService.DeleteDeliveryChannel"] }
def x-amz-target-completer-8 [] { ["StarlingDoveService.DeleteEvaluationResults"] }
def x-amz-target-completer-9 [] { ["StarlingDoveService.DeleteOrganizationConfigRule"] }
def x-amz-target-completer-10 [] { ["StarlingDoveService.DeleteOrganizationConformancePack"] }
def x-amz-target-completer-11 [] { ["StarlingDoveService.DeletePendingAggregationRequest"] }
def x-amz-target-completer-12 [] { ["StarlingDoveService.DeleteRemediationConfiguration"] }
def x-amz-target-completer-13 [] { ["StarlingDoveService.DeleteRemediationExceptions"] }
def x-amz-target-completer-14 [] { ["StarlingDoveService.DeleteResourceConfig"] }
def x-amz-target-completer-15 [] { ["StarlingDoveService.DeleteRetentionConfiguration"] }
def x-amz-target-completer-16 [] { ["StarlingDoveService.DeleteStoredQuery"] }
def x-amz-target-completer-17 [] { ["StarlingDoveService.DeliverConfigSnapshot"] }
def x-amz-target-completer-18 [] { ["StarlingDoveService.DescribeAggregateComplianceByConfigRules"] }
def x-amz-target-completer-19 [] { ["StarlingDoveService.DescribeAggregateComplianceByConformancePacks"] }
def x-amz-target-completer-20 [] { ["StarlingDoveService.DescribeAggregationAuthorizations"] }
def x-amz-target-completer-21 [] { ["StarlingDoveService.DescribeComplianceByConfigRule"] }
def x-amz-target-completer-22 [] { ["StarlingDoveService.DescribeComplianceByResource"] }
def x-amz-target-completer-23 [] { ["StarlingDoveService.DescribeConfigRuleEvaluationStatus"] }
def x-amz-target-completer-24 [] { ["StarlingDoveService.DescribeConfigRules"] }
def x-amz-target-completer-25 [] { ["StarlingDoveService.DescribeConfigurationAggregatorSourcesStatus"] }
def x-amz-target-completer-26 [] { ["StarlingDoveService.DescribeConfigurationAggregators"] }
def x-amz-target-completer-27 [] { ["StarlingDoveService.DescribeConfigurationRecorderStatus"] }
def x-amz-target-completer-28 [] { ["StarlingDoveService.DescribeConfigurationRecorders"] }
def x-amz-target-completer-29 [] { ["StarlingDoveService.DescribeConformancePackCompliance"] }
def x-amz-target-completer-30 [] { ["StarlingDoveService.DescribeConformancePackStatus"] }
def x-amz-target-completer-31 [] { ["StarlingDoveService.DescribeConformancePacks"] }
def x-amz-target-completer-32 [] { ["StarlingDoveService.DescribeDeliveryChannelStatus"] }
def x-amz-target-completer-33 [] { ["StarlingDoveService.DescribeDeliveryChannels"] }
def x-amz-target-completer-34 [] { ["StarlingDoveService.DescribeOrganizationConfigRuleStatuses"] }
def x-amz-target-completer-35 [] { ["StarlingDoveService.DescribeOrganizationConfigRules"] }
def x-amz-target-completer-36 [] { ["StarlingDoveService.DescribeOrganizationConformancePackStatuses"] }
def x-amz-target-completer-37 [] { ["StarlingDoveService.DescribeOrganizationConformancePacks"] }
def x-amz-target-completer-38 [] { ["StarlingDoveService.DescribePendingAggregationRequests"] }
def x-amz-target-completer-39 [] { ["StarlingDoveService.DescribeRemediationConfigurations"] }
def x-amz-target-completer-40 [] { ["StarlingDoveService.DescribeRemediationExceptions"] }
def x-amz-target-completer-41 [] { ["StarlingDoveService.DescribeRemediationExecutionStatus"] }
def x-amz-target-completer-42 [] { ["StarlingDoveService.DescribeRetentionConfigurations"] }
def compliance-type-completer [] { ["COMPLIANT" "INSUFFICIENT_DATA" "NON_COMPLIANT" "NOT_APPLICABLE"] }
def x-amz-target-completer-43 [] { ["StarlingDoveService.GetAggregateComplianceDetailsByConfigRule"] }
def group-by-key-completer [] { ["ACCOUNT_ID" "AWS_REGION"] }
def x-amz-target-completer-44 [] { ["StarlingDoveService.GetAggregateConfigRuleComplianceSummary"] }
def x-amz-target-completer-45 [] { ["StarlingDoveService.GetAggregateConformancePackComplianceSummary"] }
def group-by-key-completer-1 [] { ["ACCOUNT_ID" "AWS_REGION" "RESOURCE_TYPE"] }
def x-amz-target-completer-46 [] { ["StarlingDoveService.GetAggregateDiscoveredResourceCounts"] }
def x-amz-target-completer-47 [] { ["StarlingDoveService.GetAggregateResourceConfig"] }
def x-amz-target-completer-48 [] { ["StarlingDoveService.GetComplianceDetailsByConfigRule"] }
def x-amz-target-completer-49 [] { ["StarlingDoveService.GetComplianceDetailsByResource"] }
def x-amz-target-completer-50 [] { ["StarlingDoveService.GetComplianceSummaryByConfigRule"] }
def x-amz-target-completer-51 [] { ["StarlingDoveService.GetComplianceSummaryByResourceType"] }
def x-amz-target-completer-52 [] { ["StarlingDoveService.GetConformancePackComplianceDetails"] }
def x-amz-target-completer-53 [] { ["StarlingDoveService.GetConformancePackComplianceSummary"] }
def x-amz-target-completer-54 [] { ["StarlingDoveService.GetCustomRulePolicy"] }
def x-amz-target-completer-55 [] { ["StarlingDoveService.GetDiscoveredResourceCounts"] }
def x-amz-target-completer-56 [] { ["StarlingDoveService.GetOrganizationConfigRuleDetailedStatus"] }
def x-amz-target-completer-57 [] { ["StarlingDoveService.GetOrganizationConformancePackDetailedStatus"] }
def x-amz-target-completer-58 [] { ["StarlingDoveService.GetOrganizationCustomRulePolicy"] }
def resource-type-completer [] { ["AWS::ACM::Certificate" "AWS::AccessAnalyzer::Analyzer" "AWS::AmazonMQ::Broker" "AWS::ApiGateway::RestApi" "AWS::ApiGateway::Stage" "AWS::ApiGatewayV2::Api" "AWS::ApiGatewayV2::Stage" "AWS::AppConfig::Application" "AWS::AppConfig::ConfigurationProfile" "AWS::AppConfig::Environment" "AWS::AppStream::DirectoryConfig" "AWS::AppSync::GraphQLApi" "AWS::Athena::DataCatalog" "AWS::Athena::WorkGroup" "AWS::AutoScaling::AutoScalingGroup" "AWS::AutoScaling::LaunchConfiguration" "AWS::AutoScaling::ScalingPolicy" "AWS::AutoScaling::ScheduledAction" "AWS::AutoScaling::WarmPool" "AWS::Backup::BackupPlan" "AWS::Backup::BackupSelection" "AWS::Backup::BackupVault" "AWS::Backup::RecoveryPoint" "AWS::Backup::ReportPlan" "AWS::Batch::ComputeEnvironment" "AWS::Batch::JobQueue" "AWS::Budgets::BudgetsAction" "AWS::Cloud9::EnvironmentEC2" "AWS::CloudFormation::Stack" "AWS::CloudFront::Distribution" "AWS::CloudFront::StreamingDistribution" "AWS::CloudTrail::Trail" "AWS::CloudWatch::Alarm" "AWS::CodeBuild::Project" "AWS::CodeDeploy::Application" "AWS::CodeDeploy::DeploymentConfig" "AWS::CodeDeploy::DeploymentGroup" "AWS::CodeGuruReviewer::RepositoryAssociation" "AWS::CodePipeline::Pipeline" "AWS::Config::ConformancePackCompliance" "AWS::Config::ResourceCompliance" "AWS::Connect::PhoneNumber" "AWS::CustomerProfiles::Domain" "AWS::DMS::Certificate" "AWS::DMS::EventSubscription" "AWS::DMS::ReplicationSubnetGroup" "AWS::DataSync::LocationEFS" "AWS::DataSync::LocationFSxLustre" "AWS::DataSync::LocationFSxWindows" "AWS::DataSync::LocationHDFS" "AWS::DataSync::LocationNFS" "AWS::DataSync::LocationObjectStorage" "AWS::DataSync::LocationS3" "AWS::DataSync::LocationSMB" "AWS::DataSync::Task" "AWS::Detective::Graph" "AWS::DeviceFarm::TestGridProject" "AWS::DynamoDB::Table" "AWS::EC2::CustomerGateway" "AWS::EC2::DHCPOptions" "AWS::EC2::EIP" "AWS::EC2::EgressOnlyInternetGateway" "AWS::EC2::FlowLog" "AWS::EC2::Host" "AWS::EC2::IPAM" "AWS::EC2::Instance" "AWS::EC2::InternetGateway" "AWS::EC2::LaunchTemplate" "AWS::EC2::NatGateway" "AWS::EC2::NetworkAcl" "AWS::EC2::NetworkInsightsAccessScopeAnalysis" "AWS::EC2::NetworkInsightsPath" "AWS::EC2::NetworkInterface" "AWS::EC2::RegisteredHAInstance" "AWS::EC2::RouteTable" "AWS::EC2::SecurityGroup" "AWS::EC2::Subnet" "AWS::EC2::TrafficMirrorFilter" "AWS::EC2::TrafficMirrorSession" "AWS::EC2::TrafficMirrorTarget" "AWS::EC2::TransitGateway" "AWS::EC2::TransitGatewayAttachment" "AWS::EC2::TransitGatewayRouteTable" "AWS::EC2::VPC" "AWS::EC2::VPCEndpoint" "AWS::EC2::VPCEndpointService" "AWS::EC2::VPCPeeringConnection" "AWS::EC2::VPNConnection" "AWS::EC2::VPNGateway" "AWS::EC2::Volume" "AWS::ECR::PublicRepository" "AWS::ECR::RegistryPolicy" "AWS::ECR::Repository" "AWS::ECS::Cluster" "AWS::ECS::Service" "AWS::ECS::TaskDefinition" "AWS::EFS::AccessPoint" "AWS::EFS::FileSystem" "AWS::EKS::Addon" "AWS::EKS::Cluster" "AWS::EKS::FargateProfile" "AWS::EKS::IdentityProviderConfig" "AWS::EMR::SecurityConfiguration" "AWS::ElasticBeanstalk::Application" "AWS::ElasticBeanstalk::ApplicationVersion" "AWS::ElasticBeanstalk::Environment" "AWS::ElasticLoadBalancing::LoadBalancer" "AWS::ElasticLoadBalancingV2::Listener" "AWS::ElasticLoadBalancingV2::LoadBalancer" "AWS::Elasticsearch::Domain" "AWS::EventSchemas::Discoverer" "AWS::EventSchemas::Registry" "AWS::EventSchemas::RegistryPolicy" "AWS::EventSchemas::Schema" "AWS::Events::ApiDestination" "AWS::Events::Archive" "AWS::Events::Connection" "AWS::Events::Endpoint" "AWS::Events::EventBus" "AWS::Events::Rule" "AWS::FIS::ExperimentTemplate" "AWS::FraudDetector::EntityType" "AWS::FraudDetector::Label" "AWS::FraudDetector::Outcome" "AWS::FraudDetector::Variable" "AWS::GlobalAccelerator::Accelerator" "AWS::GlobalAccelerator::EndpointGroup" "AWS::GlobalAccelerator::Listener" "AWS::Glue::Classifier" "AWS::Glue::Job" "AWS::Glue::MLTransform" "AWS::GuardDuty::Detector" "AWS::GuardDuty::Filter" "AWS::GuardDuty::IPSet" "AWS::GuardDuty::ThreatIntelSet" "AWS::HealthLake::FHIRDatastore" "AWS::IAM::Group" "AWS::IAM::Policy" "AWS::IAM::Role" "AWS::IAM::User" "AWS::IVS::Channel" "AWS::IVS::PlaybackKeyPair" "AWS::IVS::RecordingConfiguration" "AWS::ImageBuilder::ContainerRecipe" "AWS::ImageBuilder::DistributionConfiguration" "AWS::ImageBuilder::InfrastructureConfiguration" "AWS::IoT::AccountAuditConfiguration" "AWS::IoT::Authorizer" "AWS::IoT::CustomMetric" "AWS::IoT::Dimension" "AWS::IoT::MitigationAction" "AWS::IoT::Policy" "AWS::IoT::RoleAlias" "AWS::IoT::ScheduledAudit" "AWS::IoT::SecurityProfile" "AWS::IoTAnalytics::Channel" "AWS::IoTAnalytics::Dataset" "AWS::IoTAnalytics::Datastore" "AWS::IoTAnalytics::Pipeline" "AWS::IoTEvents::AlarmModel" "AWS::IoTEvents::DetectorModel" "AWS::IoTEvents::Input" "AWS::IoTSiteWise::AssetModel" "AWS::IoTSiteWise::Dashboard" "AWS::IoTSiteWise::Gateway" "AWS::IoTSiteWise::Portal" "AWS::IoTSiteWise::Project" "AWS::IoTTwinMaker::Entity" "AWS::IoTTwinMaker::Scene" "AWS::IoTTwinMaker::Workspace" "AWS::KMS::Key" "AWS::Kinesis::Stream" "AWS::Kinesis::StreamConsumer" "AWS::KinesisAnalyticsV2::Application" "AWS::KinesisVideo::SignalingChannel" "AWS::Lambda::Function" "AWS::Lex::Bot" "AWS::Lex::BotAlias" "AWS::Lightsail::Bucket" "AWS::Lightsail::Certificate" "AWS::Lightsail::Disk" "AWS::Lightsail::StaticIp" "AWS::LookoutMetrics::Alert" "AWS::LookoutVision::Project" "AWS::MSK::Cluster" "AWS::MediaPackage::PackagingConfiguration" "AWS::MediaPackage::PackagingGroup" "AWS::NetworkFirewall::Firewall" "AWS::NetworkFirewall::FirewallPolicy" "AWS::NetworkFirewall::RuleGroup" "AWS::NetworkManager::TransitGatewayRegistration" "AWS::OpenSearch::Domain" "AWS::Pinpoint::ApplicationSettings" "AWS::Pinpoint::Segment" "AWS::QLDB::Ledger" "AWS::RDS::DBCluster" "AWS::RDS::DBClusterSnapshot" "AWS::RDS::DBInstance" "AWS::RDS::DBSecurityGroup" "AWS::RDS::DBSnapshot" "AWS::RDS::DBSubnetGroup" "AWS::RDS::EventSubscription" "AWS::RDS::GlobalCluster" "AWS::RUM::AppMonitor" "AWS::Redshift::Cluster" "AWS::Redshift::ClusterParameterGroup" "AWS::Redshift::ClusterSecurityGroup" "AWS::Redshift::ClusterSnapshot" "AWS::Redshift::ClusterSubnetGroup" "AWS::Redshift::EventSubscription" "AWS::ResilienceHub::ResiliencyPolicy" "AWS::RoboMaker::RobotApplication" "AWS::RoboMaker::RobotApplicationVersion" "AWS::RoboMaker::SimulationApplication" "AWS::Route53::HostedZone" "AWS::Route53RecoveryControl::Cluster" "AWS::Route53RecoveryControl::ControlPanel" "AWS::Route53RecoveryControl::RoutingControl" "AWS::Route53RecoveryControl::SafetyRule" "AWS::Route53RecoveryReadiness::Cell" "AWS::Route53RecoveryReadiness::ReadinessCheck" "AWS::Route53RecoveryReadiness::RecoveryGroup" "AWS::Route53RecoveryReadiness::ResourceSet" "AWS::Route53Resolver::FirewallDomainList" "AWS::Route53Resolver::ResolverEndpoint" "AWS::Route53Resolver::ResolverRule" "AWS::Route53Resolver::ResolverRuleAssociation" "AWS::S3::AccountPublicAccessBlock" "AWS::S3::Bucket" "AWS::S3::MultiRegionAccessPoint" "AWS::S3::StorageLens" "AWS::SES::ConfigurationSet" "AWS::SES::ContactList" "AWS::SES::ReceiptFilter" "AWS::SES::ReceiptRuleSet" "AWS::SES::Template" "AWS::SNS::Topic" "AWS::SQS::Queue" "AWS::SSM::AssociationCompliance" "AWS::SSM::FileData" "AWS::SSM::ManagedInstanceInventory" "AWS::SSM::PatchCompliance" "AWS::SageMaker::CodeRepository" "AWS::SageMaker::Model" "AWS::SageMaker::NotebookInstanceLifecycleConfig" "AWS::SageMaker::Workteam" "AWS::SecretsManager::Secret" "AWS::ServiceCatalog::CloudFormationProduct" "AWS::ServiceCatalog::CloudFormationProvisionedProduct" "AWS::ServiceCatalog::Portfolio" "AWS::ServiceDiscovery::HttpNamespace" "AWS::ServiceDiscovery::PublicDnsNamespace" "AWS::ServiceDiscovery::Service" "AWS::Shield::Protection" "AWS::ShieldRegional::Protection" "AWS::StepFunctions::Activity" "AWS::StepFunctions::StateMachine" "AWS::Transfer::Workflow" "AWS::WAF::RateBasedRule" "AWS::WAF::Rule" "AWS::WAF::RuleGroup" "AWS::WAF::WebACL" "AWS::WAFRegional::RateBasedRule" "AWS::WAFRegional::Rule" "AWS::WAFRegional::RuleGroup" "AWS::WAFRegional::WebACL" "AWS::WAFv2::IPSet" "AWS::WAFv2::ManagedRuleSet" "AWS::WAFv2::RegexPatternSet" "AWS::WAFv2::RuleGroup" "AWS::WAFv2::WebACL" "AWS::WorkSpaces::ConnectionAlias" "AWS::WorkSpaces::Workspace" "AWS::XRay::EncryptionConfig"] }
def chronological-order-completer [] { ["Forward" "Reverse"] }
def x-amz-target-completer-59 [] { ["StarlingDoveService.GetResourceConfigHistory"] }
def x-amz-target-completer-60 [] { ["StarlingDoveService.GetResourceEvaluationSummary"] }
def x-amz-target-completer-61 [] { ["StarlingDoveService.GetStoredQuery"] }
def x-amz-target-completer-62 [] { ["StarlingDoveService.ListAggregateDiscoveredResources"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def sort-by-completer [] { ["SCORE"] }
def x-amz-target-completer-63 [] { ["StarlingDoveService.ListConformancePackComplianceScores"] }
def x-amz-target-completer-64 [] { ["StarlingDoveService.ListDiscoveredResources"] }
def x-amz-target-completer-65 [] { ["StarlingDoveService.ListResourceEvaluations"] }
def x-amz-target-completer-66 [] { ["StarlingDoveService.ListStoredQueries"] }
def x-amz-target-completer-67 [] { ["StarlingDoveService.ListTagsForResource"] }
def x-amz-target-completer-68 [] { ["StarlingDoveService.PutAggregationAuthorization"] }
def x-amz-target-completer-69 [] { ["StarlingDoveService.PutConfigRule"] }
def x-amz-target-completer-70 [] { ["StarlingDoveService.PutConfigurationAggregator"] }
def x-amz-target-completer-71 [] { ["StarlingDoveService.PutConfigurationRecorder"] }
def x-amz-target-completer-72 [] { ["StarlingDoveService.PutConformancePack"] }
def x-amz-target-completer-73 [] { ["StarlingDoveService.PutDeliveryChannel"] }
def x-amz-target-completer-74 [] { ["StarlingDoveService.PutEvaluations"] }
def x-amz-target-completer-75 [] { ["StarlingDoveService.PutExternalEvaluation"] }
def x-amz-target-completer-76 [] { ["StarlingDoveService.PutOrganizationConfigRule"] }
def x-amz-target-completer-77 [] { ["StarlingDoveService.PutOrganizationConformancePack"] }
def x-amz-target-completer-78 [] { ["StarlingDoveService.PutRemediationConfigurations"] }
def x-amz-target-completer-79 [] { ["StarlingDoveService.PutRemediationExceptions"] }
def x-amz-target-completer-80 [] { ["StarlingDoveService.PutResourceConfig"] }
def x-amz-target-completer-81 [] { ["StarlingDoveService.PutRetentionConfiguration"] }
def x-amz-target-completer-82 [] { ["StarlingDoveService.PutStoredQuery"] }
def x-amz-target-completer-83 [] { ["StarlingDoveService.SelectAggregateResourceConfig"] }
def x-amz-target-completer-84 [] { ["StarlingDoveService.SelectResourceConfig"] }
def x-amz-target-completer-85 [] { ["StarlingDoveService.StartConfigRulesEvaluation"] }
def x-amz-target-completer-86 [] { ["StarlingDoveService.StartConfigurationRecorder"] }
def x-amz-target-completer-87 [] { ["StarlingDoveService.StartRemediationExecution"] }
def evaluation-mode-completer [] { ["DETECTIVE" "PROACTIVE"] }
def x-amz-target-completer-88 [] { ["StarlingDoveService.StartResourceEvaluation"] }
def x-amz-target-completer-89 [] { ["StarlingDoveService.StopConfigurationRecorder"] }
def x-amz-target-completer-90 [] { ["StarlingDoveService.TagResource"] }
def x-amz-target-completer-91 [] { ["StarlingDoveService.UntagResource"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["batch-get-aggregate-resource-config" "batch-get-resource-config" "delete-aggregation-authorization" "delete-config-rule" "delete-configuration-aggregator" "delete-configuration-recorder" "delete-conformance-pack" "delete-delivery-channel" "delete-evaluation-results" "delete-organization-config-rule" "delete-organization-conformance-pack" "delete-pending-aggregation-request" "delete-remediation-configuration" "delete-remediation-exceptions" "delete-resource-config" "delete-retention-configuration" "delete-stored-query" "deliver-config-snapshot" "describe-aggregate-compliance-by-config-rules" "describe-aggregate-compliance-by-conformance-packs" "describe-aggregation-authorizations" "describe-compliance-by-config-rule" "describe-compliance-by-resource" "describe-config-rule-evaluation-status" "describe-config-rules" "describe-configuration-aggregator-sources-status" "describe-configuration-aggregators" "describe-configuration-recorder-status" "describe-configuration-recorders" "describe-conformance-pack-compliance" "describe-conformance-pack-status" "describe-conformance-packs" "describe-delivery-channel-status" "describe-delivery-channels" "describe-organization-config-rule-statuses" "describe-organization-config-rules" "describe-organization-conformance-pack-statuses" "describe-organization-conformance-packs" "describe-pending-aggregation-requests" "describe-remediation-configurations" "describe-remediation-exceptions" "describe-remediation-execution-status" "describe-retention-configurations" "get-aggregate-compliance-details-by-config-rule" "get-aggregate-config-rule-compliance-summary" "get-aggregate-conformance-pack-compliance-summary" "get-aggregate-discovered-resource-counts" "get-aggregate-resource-config" "get-compliance-details-by-config-rule" "get-compliance-details-by-resource" "get-compliance-summary-by-config-rule" "get-compliance-summary-by-resource-type" "get-conformance-pack-compliance-details" "get-conformance-pack-compliance-summary" "get-custom-rule-policy" "get-discovered-resource-counts" "get-organization-config-rule-detailed-status" "get-organization-conformance-pack-detailed-status" "get-organization-custom-rule-policy" "get-resource-config-history" "get-resource-evaluation-summary" "get-stored-query" "list-aggregate-discovered-resources" "list-conformance-pack-compliance-scores" "list-discovered-resources" "list-resource-evaluations" "list-stored-queries" "list-tags-for-resource" "put-aggregation-authorization" "put-config-rule" "put-configuration-aggregator" "put-configuration-recorder" "put-conformance-pack" "put-delivery-channel" "put-evaluations" "put-external-evaluation" "put-organization-config-rule" "put-organization-conformance-pack" "put-remediation-configurations" "put-remediation-exceptions" "put-resource-config" "put-retention-configuration" "put-stored-query" "select-aggregate-resource-config" "select-resource-config" "start-config-rules-evaluation" "start-configuration-recorder" "start-remediation-execution" "start-resource-evaluation" "stop-configuration-recorder" "tag-resource" "untag-resource" "commands"] | sort) } | get name | first)
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

# Returns the current configuration items for resources that are present in your Config aggregator. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty unprocessedResourceIdentifiers list. The API does not return results for deleted resources. The API does not return tags and relationships.
#
# POST /
# operationId: BatchGetAggregateResourceConfig
export def "batch-get-aggregate-resource-config" [
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
  configuration_aggregator_name: string # The name of the configuration aggregator.
  resource_identifiers: list # A list of aggregate ResourceIdentifiers objects. — item shape: {SourceAccountId: string, SourceRegion: string, ResourceId: string, ... (2 more fields)}
]: any -> oneof<record<BaseConfigurationItems: table<version: string, accountId: string, configurationItemCaptureTime: string, configurationItemStatus: string, configurationStateId: string, arn: string, resourceType: string, resourceId: string, resourceName: string, awsRegion: string, availabilityZone: string, resourceCreationTime: string, configuration: string, supplementaryConfiguration: record>, UnprocessedResourceIdentifiers: table<SourceAccountId: string, SourceRegion: string, ResourceId: string, ResourceType: string, ResourceName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.BatchGetAggregateResourceConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigurationAggregatorName": $configuration_aggregator_name, "ResourceIdentifiers": $resource_identifiers} | compact
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

# Returns the BaseConfigurationItem for one or more requested resources. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty unprocessedResourceKeys list. The API does not return results for deleted resources. The API does not return any tags for the requested resources. This information is filtered out of the supplementaryConfiguration section of the API response.
#
# POST /
# operationId: BatchGetResourceConfig
export def "batch-get-resource-config" [
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
  resource_keys: list # A list of resource keys to be processed with the current request. Each element in the list consists of the resource type and resource ID. — item shape: {resourceType: "AWS::EC2::CustomerGateway"|"AWS::EC2::EIP"|"AWS::EC2::Host"|"AWS::EC2::Instance"|"AWS::EC2::InternetGateway"|"AWS::EC2::NetworkAcl"|"AWS::EC2::NetworkInterface"|"AWS::EC2::RouteTable"|"AWS::EC2::SecurityGroup"|"AWS::EC2::Subnet"|"AWS::CloudTrail::Trail"|"AWS::EC2::Volume"|"AWS::EC2::VPC"|"AWS::EC2::VPNConnection"|"AWS::EC2::VPNGateway"|"AWS::EC2::RegisteredHAInstance"|"AWS::EC2::NatGateway"|"AWS::EC2::EgressOnlyInternetGateway"|"AWS::EC2::VPCEndpoint"|"AWS::EC2::VPCEndpointService"|"AWS::EC2::FlowLog"|"AWS::EC2::VPCPeeringConnection"|"AWS::Elasticsearch::Domain"|"AWS::IAM::Group"|"AWS::IAM::Policy"|"AWS::IAM::Role"|"AWS::IAM::User"|"AWS::ElasticLoadBalancingV2::LoadBalancer"|"AWS::ACM::Certificate"|"AWS::RDS::DBInstance"|"AWS::RDS::DBSubnetGroup"|"AWS::RDS::DBSecurityGroup"|"AWS::RDS::DBSnapshot"|"AWS::RDS::DBCluster"|"AWS::RDS::DBClusterSnapshot"|"AWS::RDS::EventSubscription"|"AWS::S3::Bucket"|"AWS::S3::AccountPublicAccessBlock"|"AWS::Redshift::Cluster"|"AWS::Redshift::ClusterSnapshot"|"AWS::Redshift::ClusterParameterGroup"|"AWS::Redshift::ClusterSecurityGroup"|"AWS::Redshift::ClusterSubnetGroup"|"AWS::Redshift::EventSubscription"|"AWS::SSM::ManagedInstanceInventory"|"AWS::CloudWatch::Alarm"|"AWS::CloudFormation::Stack"|"AWS::ElasticLoadBalancing::LoadBalancer"|"AWS::AutoScaling::AutoScalingGroup"|"AWS::AutoScaling::LaunchConfiguration"|"AWS::AutoScaling::ScalingPolicy"|"AWS::AutoScaling::ScheduledAction"|"AWS::DynamoDB::Table"|"AWS::CodeBuild::Project"|"AWS::WAF::RateBasedRule"|"AWS::WAF::Rule"|"AWS::WAF::RuleGroup"|"AWS::WAF::WebACL"|"AWS::WAFRegional::RateBasedRule"|"AWS::WAFRegional::Rule"|"AWS::WAFRegional::RuleGroup"|"AWS::WAFRegional::WebACL"|"AWS::CloudFront::Distribution"|"AWS::CloudFront::StreamingDistribution"|"AWS::Lambda::Function"|"AWS::NetworkFirewall::Firewall"|"AWS::NetworkFirewall::FirewallPolicy"|"AWS::NetworkFirewall::RuleGroup"|"AWS::ElasticBeanstalk::Application"|"AWS::ElasticBeanstalk::ApplicationVersion"|"AWS::ElasticBeanstalk::Environment"|"AWS::WAFv2::WebACL"|"AWS::WAFv2::RuleGroup"|"AWS::WAFv2::IPSet"|"AWS::WAFv2::RegexPatternSet"|"AWS::WAFv2::ManagedRuleSet"|"AWS::XRay::EncryptionConfig"|"AWS::SSM::AssociationCompliance"|"AWS::SSM::PatchCompliance"|"AWS::Shield::Protection"|"AWS::ShieldRegional::Protection"|"AWS::Config::ConformancePackCompliance"|"AWS::Config::ResourceCompliance"|"AWS::ApiGateway::Stage"|"AWS::ApiGateway::RestApi"|"AWS::ApiGatewayV2::Stage"|"AWS::ApiGatewayV2::Api"|"AWS::CodePipeline::Pipeline"|"AWS::ServiceCatalog::CloudFormationProvisionedProduct"|"AWS::ServiceCatalog::CloudFormationProduct"|"AWS::ServiceCatalog::Portfolio"|"AWS::SQS::Queue"|"AWS::KMS::Key"|"AWS::QLDB::Ledger"|"AWS::SecretsManager::Secret"|"AWS::SNS::Topic"|"AWS::SSM::FileData"|"AWS::Backup::BackupPlan"|"AWS::Backup::BackupSelection"|"AWS::Backup::BackupVault"|"AWS::Backup::RecoveryPoint"|"AWS::ECR::Repository"|"AWS::ECS::Cluster"|"AWS::ECS::Service"|"AWS::ECS::TaskDefinition"|"AWS::EFS::AccessPoint"|"AWS::EFS::FileSystem"|"AWS::EKS::Cluster"|"AWS::OpenSearch::Domain"|"AWS::EC2::TransitGateway"|"AWS::Kinesis::Stream"|"AWS::Kinesis::StreamConsumer"|"AWS::CodeDeploy::Application"|"AWS::CodeDeploy::DeploymentConfig"|"AWS::CodeDeploy::DeploymentGroup"|"AWS::EC2::LaunchTemplate"|"AWS::ECR::PublicRepository"|"AWS::GuardDuty::Detector"|"AWS::EMR::SecurityConfiguration"|"AWS::SageMaker::CodeRepository"|"AWS::Route53Resolver::ResolverEndpoint"|"AWS::Route53Resolver::ResolverRule"|"AWS::Route53Resolver::ResolverRuleAssociation"|"AWS::DMS::ReplicationSubnetGroup"|"AWS::DMS::EventSubscription"|"AWS::MSK::Cluster"|"AWS::StepFunctions::Activity"|"AWS::WorkSpaces::Workspace"|"AWS::WorkSpaces::ConnectionAlias"|"AWS::SageMaker::Model"|"AWS::ElasticLoadBalancingV2::Listener"|"AWS::StepFunctions::StateMachine"|"AWS::Batch::JobQueue"|"AWS::Batch::ComputeEnvironment"|"AWS::AccessAnalyzer::Analyzer"|"AWS::Athena::WorkGroup"|"AWS::Athena::DataCatalog"|"AWS::Detective::Graph"|"AWS::GlobalAccelerator::Accelerator"|"AWS::GlobalAccelerator::EndpointGroup"|"AWS::GlobalAccelerator::Listener"|"AWS::EC2::TransitGatewayAttachment"|"AWS::EC2::TransitGatewayRouteTable"|"AWS::DMS::Certificate"|"AWS::AppConfig::Application"|"AWS::AppSync::GraphQLApi"|"AWS::DataSync::LocationSMB"|"AWS::DataSync::LocationFSxLustre"|"AWS::DataSync::LocationS3"|"AWS::DataSync::LocationEFS"|"AWS::DataSync::Task"|"AWS::DataSync::LocationNFS"|"AWS::EC2::NetworkInsightsAccessScopeAnalysis"|"AWS::EKS::FargateProfile"|"AWS::Glue::Job"|"AWS::GuardDuty::ThreatIntelSet"|"AWS::GuardDuty::IPSet"|"AWS::SageMaker::Workteam"|"AWS::SageMaker::NotebookInstanceLifecycleConfig"|"AWS::ServiceDiscovery::Service"|"AWS::ServiceDiscovery::PublicDnsNamespace"|"AWS::SES::ContactList"|"AWS::SES::ConfigurationSet"|"AWS::Route53::HostedZone"|"AWS::IoTEvents::Input"|"AWS::IoTEvents::DetectorModel"|"AWS::IoTEvents::AlarmModel"|"AWS::ServiceDiscovery::HttpNamespace"|"AWS::Events::EventBus"|"AWS::ImageBuilder::ContainerRecipe"|"AWS::ImageBuilder::DistributionConfiguration"|"AWS::ImageBuilder::InfrastructureConfiguration"|"AWS::DataSync::LocationObjectStorage"|"AWS::DataSync::LocationHDFS"|"AWS::Glue::Classifier"|"AWS::Route53RecoveryReadiness::Cell"|"AWS::Route53RecoveryReadiness::ReadinessCheck"|"AWS::ECR::RegistryPolicy"|"AWS::Backup::ReportPlan"|"AWS::Lightsail::Certificate"|"AWS::RUM::AppMonitor"|"AWS::Events::Endpoint"|"AWS::SES::ReceiptRuleSet"|"AWS::Events::Archive"|"AWS::Events::ApiDestination"|"AWS::Lightsail::Disk"|"AWS::FIS::ExperimentTemplate"|"AWS::DataSync::LocationFSxWindows"|"AWS::SES::ReceiptFilter"|"AWS::GuardDuty::Filter"|"AWS::SES::Template"|"AWS::AmazonMQ::Broker"|"AWS::AppConfig::Environment"|"AWS::AppConfig::ConfigurationProfile"|"AWS::Cloud9::EnvironmentEC2"|"AWS::EventSchemas::Registry"|"AWS::EventSchemas::RegistryPolicy"|"AWS::EventSchemas::Discoverer"|"AWS::FraudDetector::Label"|"AWS::FraudDetector::EntityType"|"AWS::FraudDetector::Variable"|"AWS::FraudDetector::Outcome"|"AWS::IoT::Authorizer"|"AWS::IoT::SecurityProfile"|"AWS::IoT::RoleAlias"|"AWS::IoT::Dimension"|"AWS::IoTAnalytics::Datastore"|"AWS::Lightsail::Bucket"|"AWS::Lightsail::StaticIp"|"AWS::MediaPackage::PackagingGroup"|"AWS::Route53RecoveryReadiness::RecoveryGroup"|"AWS::ResilienceHub::ResiliencyPolicy"|"AWS::Transfer::Workflow"|"AWS::EKS::IdentityProviderConfig"|"AWS::EKS::Addon"|"AWS::Glue::MLTransform"|"AWS::IoT::Policy"|"AWS::IoT::MitigationAction"|"AWS::IoTTwinMaker::Workspace"|"AWS::IoTTwinMaker::Entity"|"AWS::IoTAnalytics::Dataset"|"AWS::IoTAnalytics::Pipeline"|"AWS::IoTAnalytics::Channel"|"AWS::IoTSiteWise::Dashboard"|"AWS::IoTSiteWise::Project"|"AWS::IoTSiteWise::Portal"|"AWS::IoTSiteWise::AssetModel"|"AWS::IVS::Channel"|"AWS::IVS::RecordingConfiguration"|"AWS::IVS::PlaybackKeyPair"|"AWS::KinesisAnalyticsV2::Application"|"AWS::RDS::GlobalCluster"|"AWS::S3::MultiRegionAccessPoint"|"AWS::DeviceFarm::TestGridProject"|"AWS::Budgets::BudgetsAction"|"AWS::Lex::Bot"|"AWS::CodeGuruReviewer::RepositoryAssociation"|"AWS::IoT::CustomMetric"|"AWS::Route53Resolver::FirewallDomainList"|"AWS::RoboMaker::RobotApplicationVersion"|"AWS::EC2::TrafficMirrorSession"|"AWS::IoTSiteWise::Gateway"|"AWS::Lex::BotAlias"|"AWS::LookoutMetrics::Alert"|"AWS::IoT::AccountAuditConfiguration"|"AWS::EC2::TrafficMirrorTarget"|"AWS::S3::StorageLens"|"AWS::IoT::ScheduledAudit"|"AWS::Events::Connection"|"AWS::EventSchemas::Schema"|"AWS::MediaPackage::PackagingConfiguration"|"AWS::KinesisVideo::SignalingChannel"|"AWS::AppStream::DirectoryConfig"|"AWS::LookoutVision::Project"|"AWS::Route53RecoveryControl::Cluster"|"AWS::Route53RecoveryControl::SafetyRule"|"AWS::Route53RecoveryControl::ControlPanel"|"AWS::Route53RecoveryControl::RoutingControl"|"AWS::Route53RecoveryReadiness::ResourceSet"|"AWS::RoboMaker::SimulationApplication"|"AWS::RoboMaker::RobotApplication"|"AWS::HealthLake::FHIRDatastore"|"AWS::Pinpoint::Segment"|"AWS::Pinpoint::ApplicationSettings"|"AWS::Events::Rule"|"AWS::EC2::DHCPOptions"|"AWS::EC2::NetworkInsightsPath"|"AWS::EC2::TrafficMirrorFilter"|"AWS::EC2::IPAM"|"AWS::IoTTwinMaker::Scene"|"AWS::NetworkManager::TransitGatewayRegistration"|"AWS::CustomerProfiles::Domain"|"AWS::AutoScaling::WarmPool"|"AWS::Connect::PhoneNumber", ... (1 more fields)}
]: any -> oneof<record<baseConfigurationItems: table<version: string, accountId: string, configurationItemCaptureTime: string, configurationItemStatus: string, configurationStateId: string, arn: string, resourceType: string, resourceId: string, resourceName: string, awsRegion: string, availabilityZone: string, resourceCreationTime: string, configuration: string, supplementaryConfiguration: record>, unprocessedResourceKeys: table<resourceType: string, resourceId: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.BatchGetResourceConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"resourceKeys": $resource_keys} | compact
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

# Deletes the authorization granted to the specified configuration aggregator account in a specified region.
#
# POST /
# operationId: DeleteAggregationAuthorization
export def "delete-aggregation-authorization" [
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
  authorized_account_id: string # The 12-digit account ID of the account authorized to aggregate data.
  authorized_aws_region: string # The region authorized to collect aggregated data.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeleteAggregationAuthorization")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AuthorizedAccountId": $authorized_account_id, "AuthorizedAwsRegion": $authorized_aws_region} | compact
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

# Deletes the specified Config rule and all of its evaluation results. Config sets the state of a rule to DELETING until the deletion is complete. You cannot update a rule while it is in this state. If you make a PutConfigRule or DeleteConfigRule request for the rule, you will receive a ResourceInUseException. You can check the state of a rule by using the DescribeConfigRules request.
#
# POST /
# operationId: DeleteConfigRule
export def "delete-config-rule" [
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
  config_rule_name: string # The name of the Config rule that you want to delete.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeleteConfigRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigRuleName": $config_rule_name} | compact
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

# Deletes the specified configuration aggregator and the aggregated data associated with the aggregator.
#
# POST /
# operationId: DeleteConfigurationAggregator
export def "delete-configuration-aggregator" [
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
  configuration_aggregator_name: string # The name of the configuration aggregator.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeleteConfigurationAggregator")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigurationAggregatorName": $configuration_aggregator_name} | compact
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

# Deletes the configuration recorder. After the configuration recorder is deleted, Config will not record resource configuration changes until you create a new configuration recorder. This action does not delete the configuration information that was previously recorded. You will be able to access the previously recorded information by using the GetResourceConfigHistory action, but you will not be able to access this information in the Config console until you create a new configuration recorder.
#
# POST /
# operationId: DeleteConfigurationRecorder
export def "delete-configuration-recorder" [
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
  configuration_recorder_name: string # The name of the configuration recorder to be deleted. You can retrieve the name of your configuration recorder by using the DescribeConfigurationRecorders action.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeleteConfigurationRecorder")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigurationRecorderName": $configuration_recorder_name} | compact
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

# Deletes the specified conformance pack and all the Config rules, remediation actions, and all evaluation results within that conformance pack. Config sets the conformance pack to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a conformance pack while it is in this state.
#
# POST /
# operationId: DeleteConformancePack
export def "delete-conformance-pack" [
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
  conformance_pack_name: string # Name of the conformance pack you want to delete.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeleteConformancePack")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConformancePackName": $conformance_pack_name} | compact
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

# Deletes the delivery channel. Before you can delete the delivery channel, you must stop the configuration recorder by using the StopConfigurationRecorder action.
#
# POST /
# operationId: DeleteDeliveryChannel
export def "delete-delivery-channel" [
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
  delivery_channel_name: string # The name of the delivery channel to delete.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeleteDeliveryChannel")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DeliveryChannelName": $delivery_channel_name} | compact
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

# Deletes the evaluation results for the specified Config rule. You can specify one Config rule per request. After you delete the evaluation results, you can call the StartConfigRulesEvaluation API to start evaluating your Amazon Web Services resources against the rule.
#
# POST /
# operationId: DeleteEvaluationResults
export def "delete-evaluation-results" [
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
  config_rule_name: string # The name of the Config rule for which you want to delete the evaluation results.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeleteEvaluationResults")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigRuleName": $config_rule_name} | compact
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

# Deletes the specified organization Config rule and all of its evaluation results from all member accounts in that organization. Only a management account and a delegated administrator account can delete an organization Config rule. When calling this API with a delegated administrator, you must ensure Organizations ListDelegatedAdministrator permissions are added. Config sets the state of a rule to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a rule while it is in this state.
#
# POST /
# operationId: DeleteOrganizationConfigRule
export def "delete-organization-config-rule" [
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
  organization_config_rule_name: string # The name of organization Config rule that you want to delete.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeleteOrganizationConfigRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"OrganizationConfigRuleName": $organization_config_rule_name} | compact
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

# Deletes the specified organization conformance pack and all of the Config rules and remediation actions from all member accounts in that organization. Only a management account or a delegated administrator account can delete an organization conformance pack. When calling this API with a delegated administrator, you must ensure Organizations ListDelegatedAdministrator permissions are added. Config sets the state of a conformance pack to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a conformance pack while it is in this state.
#
# POST /
# operationId: DeleteOrganizationConformancePack
export def "delete-organization-conformance-pack" [
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
  organization_conformance_pack_name: string # The name of organization conformance pack that you want to delete.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeleteOrganizationConformancePack")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"OrganizationConformancePackName": $organization_conformance_pack_name} | compact
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

# Deletes pending authorization requests for a specified aggregator account in a specified region.
#
# POST /
# operationId: DeletePendingAggregationRequest
export def "delete-pending-aggregation-request" [
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
  requester_account_id: string # The 12-digit account ID of the account requesting to aggregate data.
  requester_aws_region: string # The region requesting to aggregate data.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeletePendingAggregationRequest")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RequesterAccountId": $requester_account_id, "RequesterAwsRegion": $requester_aws_region} | compact
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

# Deletes the remediation configuration.
#
# POST /
# operationId: DeleteRemediationConfiguration
export def "delete-remediation-configuration" [
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
  config_rule_name: string # The name of the Config rule for which you want to delete remediation configuration.
  --resource-type: string # The type of a resource.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeleteRemediationConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigRuleName": $config_rule_name, "ResourceType": $resource_type} | compact
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

# Deletes one or more remediation exceptions mentioned in the resource keys. Config generates a remediation exception when a problem occurs executing a remediation action to a specific resource. Remediation exceptions blocks auto-remediation until the exception is cleared.
#
# POST /
# operationId: DeleteRemediationExceptions
export def "delete-remediation-exceptions" [
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
  config_rule_name: string # The name of the Config rule for which you want to delete remediation exception configuration.
  resource_keys: list # An exception list of resource exception keys to be processed with the current request. Config adds exception for each resource key. For example, Config adds 3 exceptions for 3 resource keys. — item shape: {ResourceType?: string, ResourceId?: string}
]: any -> oneof<record<FailedBatches: table<FailureMessage: string, FailedItems: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeleteRemediationExceptions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigRuleName": $config_rule_name, "ResourceKeys": $resource_keys} | compact
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

# Records the configuration state for a custom resource that has been deleted. This API records a new ConfigurationItem with a ResourceDeleted status. You can retrieve the ConfigurationItems recorded for this resource in your Config History.
#
# POST /
# operationId: DeleteResourceConfig
export def "delete-resource-config" [
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
  resource_type: string # The type of the resource.
  resource_id: string # Unique identifier of the resource.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeleteResourceConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceType": $resource_type, "ResourceId": $resource_id} | compact
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

# Deletes the retention configuration.
#
# POST /
# operationId: DeleteRetentionConfiguration
export def "delete-retention-configuration" [
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
  retention_configuration_name: string # The name of the retention configuration to delete.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeleteRetentionConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RetentionConfigurationName": $retention_configuration_name} | compact
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

# Deletes the stored query for a single Amazon Web Services account and a single Amazon Web Services Region.
#
# POST /
# operationId: DeleteStoredQuery
export def "delete-stored-query" [
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
  query_name: string # The name of the query that you want to delete.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeleteStoredQuery")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"QueryName": $query_name} | compact
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

# Schedules delivery of a configuration snapshot to the Amazon S3 bucket in the specified delivery channel. After the delivery has started, Config sends the following notifications using an Amazon SNS topic that you have specified. Notification of the start of the delivery. Notification of the completion of the delivery, if the delivery was successfully completed. Notification of delivery failure, if the delivery failed.
#
# POST /
# operationId: DeliverConfigSnapshot
export def "deliver-config-snapshot" [
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
  delivery_channel_name: string # The name of the delivery channel through which the snapshot is delivered.
]: any -> oneof<record<configSnapshotId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DeliverConfigSnapshot")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"deliveryChannelName": $delivery_channel_name} | compact
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

# Returns a list of compliant and noncompliant rules with the number of resources for compliant and noncompliant rules. Does not display rules that do not have compliance results. The results can return an empty result page, but if you have a nextToken, the results are displayed on the next page.
#
# POST /
# operationId: DescribeAggregateComplianceByConfigRules
export def "describe-aggregate-compliance-by-config-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-18 # required
  configuration_aggregator_name: string # The name of the configuration aggregator.
  --filters: record # Filters the compliance results based on account ID, region, compliance type, and rule name. — shape: {ConfigRuleName?: string, ComplianceType?: "COMPLIANT"|"NON_COMPLIANT"|"NOT_APPLICABLE"|"INSUFFICIENT_DATA", AccountId?: string, AwsRegion?: string}
  --limit-body: int # The maximum number of evaluation results returned on each page. The default is maximum. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<AggregateComplianceByConfigRules: table<ConfigRuleName: string, Compliance: record, AccountId: string, AwsRegion: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeAggregateComplianceByConfigRules")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConfigurationAggregatorName": $configuration_aggregator_name, "Filters": $filters, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of the conformance packs and their associated compliance status with the count of compliant and noncompliant Config rules within each conformance pack. Also returns the total rule count which includes compliant rules, noncompliant rules, and rules that cannot be evaluated due to insufficient data. The results can return an empty result page, but if you have a nextToken, the results are displayed on the next page.
#
# POST /
# operationId: DescribeAggregateComplianceByConformancePacks
export def "describe-aggregate-compliance-by-conformance-packs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-19 # required
  configuration_aggregator_name: string # The name of the configuration aggregator.
  --filters: record # Filters the conformance packs based on an account ID, region, compliance type, and the name of the conformance pack. — shape: {ConformancePackName?: string, ComplianceType?: "COMPLIANT"|"NON_COMPLIANT"|"INSUFFICIENT_DATA", AccountId?: string, AwsRegion?: string}
  --limit-body: int # The maximum number of conformance packs compliance details returned on each page. The default is maximum. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<AggregateComplianceByConformancePacks: table<ConformancePackName: string, Compliance: record, AccountId: string, AwsRegion: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeAggregateComplianceByConformancePacks")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConfigurationAggregatorName": $configuration_aggregator_name, "Filters": $filters, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of authorizations granted to various aggregator accounts and regions.
#
# POST /
# operationId: DescribeAggregationAuthorizations
export def "describe-aggregation-authorizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-20 # required
  --limit-body: int # The maximum number of AggregationAuthorizations returned on each page. The default is maximum. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<AggregationAuthorizations: table<AggregationAuthorizationArn: string, AuthorizedAccountId: string, AuthorizedAwsRegion: string, CreationTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeAggregationAuthorizations")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Indicates whether the specified Config rules are compliant. If a rule is noncompliant, this action returns the number of Amazon Web Services resources that do not comply with the rule. A rule is compliant if all of the evaluated resources comply with it. It is noncompliant if any of these resources do not comply. If Config has no current evaluation results for the rule, it returns INSUFFICIENT_DATA. This result might indicate one of the following conditions: Config has never invoked an evaluation for the rule. To check whether it has, use the DescribeConfigRuleEvaluationStatus action to get the LastSuccessfulInvocationTime and LastFailedInvocationTime. The rule's Lambda function is failing to send evaluation results to Config. Verify that the role you assigned to your configuration recorder includes the config:PutEvaluations permission. If the rule is a custom rule, verify that the Lambda execution role includes the config:PutEvaluations permission. The rule's Lambda function has returned NOT_APPLICABLE for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.
#
# POST /
# operationId: DescribeComplianceByConfigRule
export def "describe-compliance-by-config-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-21 # required
  --config-rule-names: list<string> # Specify one or more Config rule names to filter the results by rule.
  --compliance-types: list<string> # Filters the results by compliance.
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<ComplianceByConfigRules: table<ConfigRuleName: string, Compliance: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeComplianceByConfigRule")
  let qp = [(serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConfigRuleNames": $config_rule_names, "ComplianceTypes": $compliance_types, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Indicates whether the specified Amazon Web Services resources are compliant. If a resource is noncompliant, this action returns the number of Config rules that the resource does not comply with. A resource is compliant if it complies with all the Config rules that evaluate it. It is noncompliant if it does not comply with one or more of these rules. If Config has no current evaluation results for the resource, it returns INSUFFICIENT_DATA. This result might indicate one of the following conditions about the rules that evaluate the resource: Config has never invoked an evaluation for the rule. To check whether it has, use the DescribeConfigRuleEvaluationStatus action to get the LastSuccessfulInvocationTime and LastFailedInvocationTime. The rule's Lambda function is failing to send evaluation results to Config. Verify that the role that you assigned to your configuration recorder includes the config:PutEvaluations permission. If the rule is a custom rule, verify that the Lambda execution role includes the config:PutEvaluations permission. The rule's Lambda function has returned NOT_APPLICABLE for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.
#
# POST /
# operationId: DescribeComplianceByResource
export def "describe-compliance-by-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-22 # required
  --resource-type: string # The types of Amazon Web Services resources for which you want compliance information (for example, AWS::EC2::Instance). For this action, you can specify that the resource type is an Amazon Web Services account by specifying AWS::::Account.
  --resource-id: string # The ID of the Amazon Web Services resource for which you want compliance information. You can specify only one resource ID. If you specify a resource ID, you must also specify a type for ResourceType.
  --compliance-types: list<string> # Filters the results by compliance.
  --limit-body: int # The maximum number of evaluation results returned on each page. The default is 10. You cannot specify a number greater than 100. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<ComplianceByResources: table<ResourceType: string, ResourceId: string, Compliance: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeComplianceByResource")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ResourceType": $resource_type, "ResourceId": $resource_id, "ComplianceTypes": $compliance_types, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns status information for each of your Config managed rules. The status includes information such as the last time Config invoked the rule, the last time Config failed to invoke the rule, and the related error for the last failure.
#
# POST /
# operationId: DescribeConfigRuleEvaluationStatus
export def "describe-config-rule-evaluation-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-23 # required
  --config-rule-names: list<string> # The name of the Config managed rules for which you want status information. If you do not specify any names, Config returns status information for all Config managed rules that you use.
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
  --limit-body: int # The number of rule evaluation results that you want returned. This parameter is required if the rule limit for your account is more than the default of 150 rules. For information about requesting a rule limit increase, see Config Limits (http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_config) in the Amazon Web Services General Reference Guide. (body field)
]: any -> oneof<record<ConfigRulesEvaluationStatus: table<ConfigRuleName: string, ConfigRuleArn: string, ConfigRuleId: string, LastSuccessfulInvocationTime: string, LastFailedInvocationTime: string, LastSuccessfulEvaluationTime: string, LastFailedEvaluationTime: string, FirstActivatedTime: string, LastDeactivatedTime: string, LastErrorCode: string, LastErrorMessage: string, FirstEvaluationStarted: bool, LastDebugLogDeliveryStatus: string, LastDebugLogDeliveryStatusReason: string, LastDebugLogDeliveryTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeConfigRuleEvaluationStatus")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConfigRuleNames": $config_rule_names, "NextToken": $next_token_body, "Limit": $limit_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns details about your Config rules.
#
# POST /
# operationId: DescribeConfigRules
export def "describe-config-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-24 # required
  --config-rule-names: list<string> # The names of the Config rules for which you want details. If you do not specify any names, Config returns details for all your rules.
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
  --filters: record # Returns a filtered list of Detective or Proactive Config rules. By default, if the filter is not defined, this API returns an unfiltered list. For more information on Detective or Proactive Config rules, see Evaluation Mode (https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config-rules.html) in the Config Developer Guide. — shape: {EvaluationMode?: "DETECTIVE"|"PROACTIVE"}
]: any -> oneof<record<ConfigRules: table<ConfigRuleName: string, ConfigRuleArn: string, ConfigRuleId: string, Description: string, Scope: record, Source: record, InputParameters: string, MaximumExecutionFrequency: string, ConfigRuleState: string, CreatedBy: string, EvaluationModes: list>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeConfigRules")
  let qp = [(serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConfigRuleNames": $config_rule_names, "NextToken": $next_token_body, "Filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns status information for sources within an aggregator. The status includes information about the last time Config verified authorization between the source account and an aggregator account. In case of a failure, the status contains the related error code or message.
#
# POST /
# operationId: DescribeConfigurationAggregatorSourcesStatus
export def "describe-configuration-aggregator-sources-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-25 # required
  configuration_aggregator_name: string # The name of the configuration aggregator.
  --update-status: list<string> # Filters the status type. Valid value FAILED indicates errors while moving data. Valid value SUCCEEDED indicates the data was successfully moved. Valid value OUTDATED indicates the data is not the most recent.
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
  --limit-body: int # The maximum number of AggregatorSourceStatus returned on each page. The default is maximum. If you specify 0, Config uses the default. (body field)
]: any -> oneof<record<AggregatedSourceStatusList: table<SourceId: string, SourceType: string, AwsRegion: string, LastUpdateStatus: string, LastUpdateTime: string, LastErrorCode: string, LastErrorMessage: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeConfigurationAggregatorSourcesStatus")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConfigurationAggregatorName": $configuration_aggregator_name, "UpdateStatus": $update_status, "NextToken": $next_token_body, "Limit": $limit_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the details of one or more configuration aggregators. If the configuration aggregator is not specified, this action returns the details for all the configuration aggregators associated with the account.
#
# POST /
# operationId: DescribeConfigurationAggregators
export def "describe-configuration-aggregators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-26 # required
  --configuration-aggregator-names: list<string> # The name of the configuration aggregators.
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
  --limit-body: int # The maximum number of configuration aggregators returned on each page. The default is maximum. If you specify 0, Config uses the default. (body field)
]: any -> oneof<record<ConfigurationAggregators: table<ConfigurationAggregatorName: string, ConfigurationAggregatorArn: string, AccountAggregationSources: list, OrganizationAggregationSource: record, CreationTime: string, LastUpdatedTime: string, CreatedBy: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeConfigurationAggregators")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConfigurationAggregatorNames": $configuration_aggregator_names, "NextToken": $next_token_body, "Limit": $limit_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the current status of the specified configuration recorder as well as the status of the last recording event for the recorder. If a configuration recorder is not specified, this action returns the status of all configuration recorders associated with the account. Currently, you can specify only one configuration recorder per region in your account. For a detailed status of recording events over time, add your Config events to Amazon CloudWatch metrics and use CloudWatch metrics.
#
# POST /
# operationId: DescribeConfigurationRecorderStatus
export def "describe-configuration-recorder-status" [
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
  --configuration-recorder-names: list<string> # The name(s) of the configuration recorder. If the name is not specified, the action returns the current status of all the configuration recorders associated with the account.
]: any -> oneof<record<ConfigurationRecordersStatus: table<name: string, lastStartTime: string, lastStopTime: string, recording: bool, lastStatus: string, lastErrorCode: string, lastErrorMessage: string, lastStatusChangeTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeConfigurationRecorderStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigurationRecorderNames": $configuration_recorder_names} | compact
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

# Returns the details for the specified configuration recorders. If the configuration recorder is not specified, this action returns the details for all configuration recorders associated with the account. Currently, you can specify only one configuration recorder per region in your account.
#
# POST /
# operationId: DescribeConfigurationRecorders
export def "describe-configuration-recorders" [
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
  --configuration-recorder-names: list<string> # A list of configuration recorder names.
]: any -> oneof<record<ConfigurationRecorders: table<name: string, roleARN: string, recordingGroup: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeConfigurationRecorders")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigurationRecorderNames": $configuration_recorder_names} | compact
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

# Returns compliance details for each rule in that conformance pack. You must provide exact rule names.
#
# POST /
# operationId: DescribeConformancePackCompliance
export def "describe-conformance-pack-compliance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29 # required
  conformance_pack_name: string # Name of the conformance pack.
  --filters: record # Filters the conformance pack by compliance types and Config rule names. — shape: {ConfigRuleNames?: list<string>, ComplianceType?: "COMPLIANT"|"NON_COMPLIANT"|"INSUFFICIENT_DATA"}
  --limit-body: int # The maximum number of Config rules within a conformance pack are returned on each page. (body field)
  --next-token-body: string # The nextToken string returned in a previous request that you use to request the next page of results in a paginated response. (body field)
]: any -> oneof<record<ConformancePackName: string, ConformancePackRuleComplianceList: table<ConfigRuleName: string, ComplianceType: string, Controls: list>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeConformancePackCompliance")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConformancePackName": $conformance_pack_name, "Filters": $filters, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Provides one or more conformance packs deployment status. If there are no conformance packs then you will see an empty result.
#
# POST /
# operationId: DescribeConformancePackStatus
export def "describe-conformance-pack-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-30 # required
  --conformance-pack-names: list<string> # Comma-separated list of conformance pack names.
  --limit-body: int # The maximum number of conformance packs status returned on each page. (body field)
  --next-token-body: string # The nextToken string returned in a previous request that you use to request the next page of results in a paginated response. (body field)
]: any -> oneof<record<ConformancePackStatusDetails: table<ConformancePackName: string, ConformancePackId: string, ConformancePackArn: string, ConformancePackState: string, StackArn: string, ConformancePackStatusReason: string, LastUpdateRequestedTime: string, LastUpdateCompletedTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeConformancePackStatus")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConformancePackNames": $conformance_pack_names, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of one or more conformance packs.
#
# POST /
# operationId: DescribeConformancePacks
export def "describe-conformance-packs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-31 # required
  --conformance-pack-names: list<string> # Comma-separated list of conformance pack names for which you want details. If you do not specify any names, Config returns details for all your conformance packs.
  --limit-body: int # The maximum number of conformance packs returned on each page. (body field)
  --next-token-body: string # The nextToken string returned in a previous request that you use to request the next page of results in a paginated response. (body field)
]: any -> oneof<record<ConformancePackDetails: table<ConformancePackName: string, ConformancePackArn: string, ConformancePackId: string, DeliveryS3Bucket: string, DeliveryS3KeyPrefix: string, ConformancePackInputParameters: list, LastUpdateRequestedTime: string, CreatedBy: string, TemplateSSMDocumentDetails: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeConformancePacks")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConformancePackNames": $conformance_pack_names, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the current status of the specified delivery channel. If a delivery channel is not specified, this action returns the current status of all delivery channels associated with the account. Currently, you can specify only one delivery channel per region in your account.
#
# POST /
# operationId: DescribeDeliveryChannelStatus
export def "describe-delivery-channel-status" [
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
  --delivery-channel-names: list<string> # A list of delivery channel names.
]: any -> oneof<record<DeliveryChannelsStatus: table<name: string, configSnapshotDeliveryInfo: record, configHistoryDeliveryInfo: record, configStreamDeliveryInfo: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeDeliveryChannelStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DeliveryChannelNames": $delivery_channel_names} | compact
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

# Returns details about the specified delivery channel. If a delivery channel is not specified, this action returns the details of all delivery channels associated with the account. Currently, you can specify only one delivery channel per region in your account.
#
# POST /
# operationId: DescribeDeliveryChannels
export def "describe-delivery-channels" [
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
  --delivery-channel-names: list<string> # A list of delivery channel names.
]: any -> oneof<record<DeliveryChannels: table<name: string, s3BucketName: string, s3KeyPrefix: string, s3KmsKeyArn: string, snsTopicARN: string, configSnapshotDeliveryProperties: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeDeliveryChannels")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DeliveryChannelNames": $delivery_channel_names} | compact
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

# Provides organization Config rule deployment status for an organization. The status is not considered successful until organization Config rule is successfully deployed in all the member accounts with an exception of excluded accounts. When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization Config rule names. It is only applicable, when you request all the organization Config rules.
#
# POST /
# operationId: DescribeOrganizationConfigRuleStatuses
export def "describe-organization-config-rule-statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-34 # required
  --organization-config-rule-names: list<string> # The names of organization Config rules for which you want status details. If you do not specify any names, Config returns details for all your organization Config rules.
  --limit-body: int # The maximum number of OrganizationConfigRuleStatuses returned on each page. If you do no specify a number, Config uses the default. The default is 100. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<OrganizationConfigRuleStatuses: table<OrganizationConfigRuleName: string, OrganizationRuleStatus: string, ErrorCode: string, ErrorMessage: string, LastUpdateTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeOrganizationConfigRuleStatuses")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"OrganizationConfigRuleNames": $organization_config_rule_names, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of organization Config rules. When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization Config rule names. It is only applicable, when you request all the organization Config rules. For accounts within an organzation If you deploy an organizational rule or conformance pack in an organization administrator account, and then establish a delegated administrator and deploy an organizational rule or conformance pack in the delegated administrator account, you won't be able to see the organizational rule or conformance pack in the organization administrator account from the delegated administrator account or see the organizational rule or conformance pack in the delegated administrator account from organization administrator account. The DescribeOrganizationConfigRules and DescribeOrganizationConformancePacks APIs can only see and interact with the organization-related resource that were deployed from within the account calling those APIs.
#
# POST /
# operationId: DescribeOrganizationConfigRules
export def "describe-organization-config-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-35 # required
  --organization-config-rule-names: list<string> # The names of organization Config rules for which you want details. If you do not specify any names, Config returns details for all your organization Config rules.
  --limit-body: int # The maximum number of organization Config rules returned on each page. If you do no specify a number, Config uses the default. The default is 100. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<OrganizationConfigRules: table<OrganizationConfigRuleName: string, OrganizationConfigRuleArn: string, OrganizationManagedRuleMetadata: record, OrganizationCustomRuleMetadata: record, ExcludedAccounts: list, LastUpdateTime: string, OrganizationCustomPolicyRuleMetadata: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeOrganizationConfigRules")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"OrganizationConfigRuleNames": $organization_config_rule_names, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Provides organization conformance pack deployment status for an organization. The status is not considered successful until organization conformance pack is successfully deployed in all the member accounts with an exception of excluded accounts. When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization conformance pack names. They are only applicable, when you request all the organization conformance packs.
#
# POST /
# operationId: DescribeOrganizationConformancePackStatuses
export def "describe-organization-conformance-pack-statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-36 # required
  --organization-conformance-pack-names: list<string> # The names of organization conformance packs for which you want status details. If you do not specify any names, Config returns details for all your organization conformance packs.
  --limit-body: int # The maximum number of OrganizationConformancePackStatuses returned on each page. If you do no specify a number, Config uses the default. The default is 100. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<OrganizationConformancePackStatuses: table<OrganizationConformancePackName: string, Status: string, ErrorCode: string, ErrorMessage: string, LastUpdateTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeOrganizationConformancePackStatuses")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"OrganizationConformancePackNames": $organization_conformance_pack_names, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of organization conformance packs. When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization conformance packs names. They are only applicable, when you request all the organization conformance packs. For accounts within an organzation If you deploy an organizational rule or conformance pack in an organization administrator account, and then establish a delegated administrator and deploy an organizational rule or conformance pack in the delegated administrator account, you won't be able to see the organizational rule or conformance pack in the organization administrator account from the delegated administrator account or see the organizational rule or conformance pack in the delegated administrator account from organization administrator account. The DescribeOrganizationConfigRules and DescribeOrganizationConformancePacks APIs can only see and interact with the organization-related resource that were deployed from within the account calling those APIs.
#
# POST /
# operationId: DescribeOrganizationConformancePacks
export def "describe-organization-conformance-packs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-37 # required
  --organization-conformance-pack-names: list<string> # The name that you assign to an organization conformance pack.
  --limit-body: int # The maximum number of organization config packs returned on each page. If you do no specify a number, Config uses the default. The default is 100. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<OrganizationConformancePacks: table<OrganizationConformancePackName: string, OrganizationConformancePackArn: string, DeliveryS3Bucket: string, DeliveryS3KeyPrefix: string, ConformancePackInputParameters: list, ExcludedAccounts: list, LastUpdateTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeOrganizationConformancePacks")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"OrganizationConformancePackNames": $organization_conformance_pack_names, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of all pending aggregation requests.
#
# POST /
# operationId: DescribePendingAggregationRequests
export def "describe-pending-aggregation-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-38 # required
  --limit-body: int # The maximum number of evaluation results returned on each page. The default is maximum. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<PendingAggregationRequests: table<RequesterAccountId: string, RequesterAwsRegion: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribePendingAggregationRequests")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the details of one or more remediation configurations.
#
# POST /
# operationId: DescribeRemediationConfigurations
export def "describe-remediation-configurations" [
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
  config_rule_names: list<string> # A list of Config rule names of remediation configurations for which you want details.
]: any -> oneof<record<RemediationConfigurations: table<ConfigRuleName: string, TargetType: string, TargetId: string, TargetVersion: string, Parameters: record, ResourceType: string, Automatic: bool, ExecutionControls: record, MaximumAutomaticAttempts: int, RetryAttemptSeconds: int, Arn: string, CreatedByService: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeRemediationConfigurations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigRuleNames": $config_rule_names} | compact
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

# Returns the details of one or more remediation exceptions. A detailed view of a remediation exception for a set of resources that includes an explanation of an exception and the time when the exception will be deleted. When you specify the limit and the next token, you receive a paginated response. Config generates a remediation exception when a problem occurs executing a remediation action to a specific resource. Remediation exceptions blocks auto-remediation until the exception is cleared. When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you request resources in batch. It is only applicable, when you request all resources.
#
# POST /
# operationId: DescribeRemediationExceptions
export def "describe-remediation-exceptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-40 # required
  config_rule_name: string # The name of the Config rule.
  --resource-keys: list # An exception list of resource exception keys to be processed with the current request. Config adds exception for each resource key. For example, Config adds 3 exceptions for 3 resource keys. — item shape: {ResourceType?: string, ResourceId?: string}
  --limit-body: int # The maximum number of RemediationExceptionResourceKey returned on each page. The default is 25. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned in a previous request that you use to request the next page of results in a paginated response. (body field)
]: any -> oneof<record<RemediationExceptions: table<ConfigRuleName: string, ResourceType: string, ResourceId: string, Message: string, ExpirationTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeRemediationExceptions")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConfigRuleName": $config_rule_name, "ResourceKeys": $resource_keys, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Provides a detailed view of a Remediation Execution for a set of resources including state, timestamps for when steps for the remediation execution occur, and any error messages for steps that have failed. When you specify the limit and the next token, you receive a paginated response.
#
# POST /
# operationId: DescribeRemediationExecutionStatus
export def "describe-remediation-execution-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-41 # required
  config_rule_name: string # A list of Config rule names.
  --resource-keys: list # A list of resource keys to be processed with the current request. Each element in the list consists of the resource type and resource ID. — item shape: {resourceType: "AWS::EC2::CustomerGateway"|"AWS::EC2::EIP"|"AWS::EC2::Host"|"AWS::EC2::Instance"|"AWS::EC2::InternetGateway"|"AWS::EC2::NetworkAcl"|"AWS::EC2::NetworkInterface"|"AWS::EC2::RouteTable"|"AWS::EC2::SecurityGroup"|"AWS::EC2::Subnet"|"AWS::CloudTrail::Trail"|"AWS::EC2::Volume"|"AWS::EC2::VPC"|"AWS::EC2::VPNConnection"|"AWS::EC2::VPNGateway"|"AWS::EC2::RegisteredHAInstance"|"AWS::EC2::NatGateway"|"AWS::EC2::EgressOnlyInternetGateway"|"AWS::EC2::VPCEndpoint"|"AWS::EC2::VPCEndpointService"|"AWS::EC2::FlowLog"|"AWS::EC2::VPCPeeringConnection"|"AWS::Elasticsearch::Domain"|"AWS::IAM::Group"|"AWS::IAM::Policy"|"AWS::IAM::Role"|"AWS::IAM::User"|"AWS::ElasticLoadBalancingV2::LoadBalancer"|"AWS::ACM::Certificate"|"AWS::RDS::DBInstance"|"AWS::RDS::DBSubnetGroup"|"AWS::RDS::DBSecurityGroup"|"AWS::RDS::DBSnapshot"|"AWS::RDS::DBCluster"|"AWS::RDS::DBClusterSnapshot"|"AWS::RDS::EventSubscription"|"AWS::S3::Bucket"|"AWS::S3::AccountPublicAccessBlock"|"AWS::Redshift::Cluster"|"AWS::Redshift::ClusterSnapshot"|"AWS::Redshift::ClusterParameterGroup"|"AWS::Redshift::ClusterSecurityGroup"|"AWS::Redshift::ClusterSubnetGroup"|"AWS::Redshift::EventSubscription"|"AWS::SSM::ManagedInstanceInventory"|"AWS::CloudWatch::Alarm"|"AWS::CloudFormation::Stack"|"AWS::ElasticLoadBalancing::LoadBalancer"|"AWS::AutoScaling::AutoScalingGroup"|"AWS::AutoScaling::LaunchConfiguration"|"AWS::AutoScaling::ScalingPolicy"|"AWS::AutoScaling::ScheduledAction"|"AWS::DynamoDB::Table"|"AWS::CodeBuild::Project"|"AWS::WAF::RateBasedRule"|"AWS::WAF::Rule"|"AWS::WAF::RuleGroup"|"AWS::WAF::WebACL"|"AWS::WAFRegional::RateBasedRule"|"AWS::WAFRegional::Rule"|"AWS::WAFRegional::RuleGroup"|"AWS::WAFRegional::WebACL"|"AWS::CloudFront::Distribution"|"AWS::CloudFront::StreamingDistribution"|"AWS::Lambda::Function"|"AWS::NetworkFirewall::Firewall"|"AWS::NetworkFirewall::FirewallPolicy"|"AWS::NetworkFirewall::RuleGroup"|"AWS::ElasticBeanstalk::Application"|"AWS::ElasticBeanstalk::ApplicationVersion"|"AWS::ElasticBeanstalk::Environment"|"AWS::WAFv2::WebACL"|"AWS::WAFv2::RuleGroup"|"AWS::WAFv2::IPSet"|"AWS::WAFv2::RegexPatternSet"|"AWS::WAFv2::ManagedRuleSet"|"AWS::XRay::EncryptionConfig"|"AWS::SSM::AssociationCompliance"|"AWS::SSM::PatchCompliance"|"AWS::Shield::Protection"|"AWS::ShieldRegional::Protection"|"AWS::Config::ConformancePackCompliance"|"AWS::Config::ResourceCompliance"|"AWS::ApiGateway::Stage"|"AWS::ApiGateway::RestApi"|"AWS::ApiGatewayV2::Stage"|"AWS::ApiGatewayV2::Api"|"AWS::CodePipeline::Pipeline"|"AWS::ServiceCatalog::CloudFormationProvisionedProduct"|"AWS::ServiceCatalog::CloudFormationProduct"|"AWS::ServiceCatalog::Portfolio"|"AWS::SQS::Queue"|"AWS::KMS::Key"|"AWS::QLDB::Ledger"|"AWS::SecretsManager::Secret"|"AWS::SNS::Topic"|"AWS::SSM::FileData"|"AWS::Backup::BackupPlan"|"AWS::Backup::BackupSelection"|"AWS::Backup::BackupVault"|"AWS::Backup::RecoveryPoint"|"AWS::ECR::Repository"|"AWS::ECS::Cluster"|"AWS::ECS::Service"|"AWS::ECS::TaskDefinition"|"AWS::EFS::AccessPoint"|"AWS::EFS::FileSystem"|"AWS::EKS::Cluster"|"AWS::OpenSearch::Domain"|"AWS::EC2::TransitGateway"|"AWS::Kinesis::Stream"|"AWS::Kinesis::StreamConsumer"|"AWS::CodeDeploy::Application"|"AWS::CodeDeploy::DeploymentConfig"|"AWS::CodeDeploy::DeploymentGroup"|"AWS::EC2::LaunchTemplate"|"AWS::ECR::PublicRepository"|"AWS::GuardDuty::Detector"|"AWS::EMR::SecurityConfiguration"|"AWS::SageMaker::CodeRepository"|"AWS::Route53Resolver::ResolverEndpoint"|"AWS::Route53Resolver::ResolverRule"|"AWS::Route53Resolver::ResolverRuleAssociation"|"AWS::DMS::ReplicationSubnetGroup"|"AWS::DMS::EventSubscription"|"AWS::MSK::Cluster"|"AWS::StepFunctions::Activity"|"AWS::WorkSpaces::Workspace"|"AWS::WorkSpaces::ConnectionAlias"|"AWS::SageMaker::Model"|"AWS::ElasticLoadBalancingV2::Listener"|"AWS::StepFunctions::StateMachine"|"AWS::Batch::JobQueue"|"AWS::Batch::ComputeEnvironment"|"AWS::AccessAnalyzer::Analyzer"|"AWS::Athena::WorkGroup"|"AWS::Athena::DataCatalog"|"AWS::Detective::Graph"|"AWS::GlobalAccelerator::Accelerator"|"AWS::GlobalAccelerator::EndpointGroup"|"AWS::GlobalAccelerator::Listener"|"AWS::EC2::TransitGatewayAttachment"|"AWS::EC2::TransitGatewayRouteTable"|"AWS::DMS::Certificate"|"AWS::AppConfig::Application"|"AWS::AppSync::GraphQLApi"|"AWS::DataSync::LocationSMB"|"AWS::DataSync::LocationFSxLustre"|"AWS::DataSync::LocationS3"|"AWS::DataSync::LocationEFS"|"AWS::DataSync::Task"|"AWS::DataSync::LocationNFS"|"AWS::EC2::NetworkInsightsAccessScopeAnalysis"|"AWS::EKS::FargateProfile"|"AWS::Glue::Job"|"AWS::GuardDuty::ThreatIntelSet"|"AWS::GuardDuty::IPSet"|"AWS::SageMaker::Workteam"|"AWS::SageMaker::NotebookInstanceLifecycleConfig"|"AWS::ServiceDiscovery::Service"|"AWS::ServiceDiscovery::PublicDnsNamespace"|"AWS::SES::ContactList"|"AWS::SES::ConfigurationSet"|"AWS::Route53::HostedZone"|"AWS::IoTEvents::Input"|"AWS::IoTEvents::DetectorModel"|"AWS::IoTEvents::AlarmModel"|"AWS::ServiceDiscovery::HttpNamespace"|"AWS::Events::EventBus"|"AWS::ImageBuilder::ContainerRecipe"|"AWS::ImageBuilder::DistributionConfiguration"|"AWS::ImageBuilder::InfrastructureConfiguration"|"AWS::DataSync::LocationObjectStorage"|"AWS::DataSync::LocationHDFS"|"AWS::Glue::Classifier"|"AWS::Route53RecoveryReadiness::Cell"|"AWS::Route53RecoveryReadiness::ReadinessCheck"|"AWS::ECR::RegistryPolicy"|"AWS::Backup::ReportPlan"|"AWS::Lightsail::Certificate"|"AWS::RUM::AppMonitor"|"AWS::Events::Endpoint"|"AWS::SES::ReceiptRuleSet"|"AWS::Events::Archive"|"AWS::Events::ApiDestination"|"AWS::Lightsail::Disk"|"AWS::FIS::ExperimentTemplate"|"AWS::DataSync::LocationFSxWindows"|"AWS::SES::ReceiptFilter"|"AWS::GuardDuty::Filter"|"AWS::SES::Template"|"AWS::AmazonMQ::Broker"|"AWS::AppConfig::Environment"|"AWS::AppConfig::ConfigurationProfile"|"AWS::Cloud9::EnvironmentEC2"|"AWS::EventSchemas::Registry"|"AWS::EventSchemas::RegistryPolicy"|"AWS::EventSchemas::Discoverer"|"AWS::FraudDetector::Label"|"AWS::FraudDetector::EntityType"|"AWS::FraudDetector::Variable"|"AWS::FraudDetector::Outcome"|"AWS::IoT::Authorizer"|"AWS::IoT::SecurityProfile"|"AWS::IoT::RoleAlias"|"AWS::IoT::Dimension"|"AWS::IoTAnalytics::Datastore"|"AWS::Lightsail::Bucket"|"AWS::Lightsail::StaticIp"|"AWS::MediaPackage::PackagingGroup"|"AWS::Route53RecoveryReadiness::RecoveryGroup"|"AWS::ResilienceHub::ResiliencyPolicy"|"AWS::Transfer::Workflow"|"AWS::EKS::IdentityProviderConfig"|"AWS::EKS::Addon"|"AWS::Glue::MLTransform"|"AWS::IoT::Policy"|"AWS::IoT::MitigationAction"|"AWS::IoTTwinMaker::Workspace"|"AWS::IoTTwinMaker::Entity"|"AWS::IoTAnalytics::Dataset"|"AWS::IoTAnalytics::Pipeline"|"AWS::IoTAnalytics::Channel"|"AWS::IoTSiteWise::Dashboard"|"AWS::IoTSiteWise::Project"|"AWS::IoTSiteWise::Portal"|"AWS::IoTSiteWise::AssetModel"|"AWS::IVS::Channel"|"AWS::IVS::RecordingConfiguration"|"AWS::IVS::PlaybackKeyPair"|"AWS::KinesisAnalyticsV2::Application"|"AWS::RDS::GlobalCluster"|"AWS::S3::MultiRegionAccessPoint"|"AWS::DeviceFarm::TestGridProject"|"AWS::Budgets::BudgetsAction"|"AWS::Lex::Bot"|"AWS::CodeGuruReviewer::RepositoryAssociation"|"AWS::IoT::CustomMetric"|"AWS::Route53Resolver::FirewallDomainList"|"AWS::RoboMaker::RobotApplicationVersion"|"AWS::EC2::TrafficMirrorSession"|"AWS::IoTSiteWise::Gateway"|"AWS::Lex::BotAlias"|"AWS::LookoutMetrics::Alert"|"AWS::IoT::AccountAuditConfiguration"|"AWS::EC2::TrafficMirrorTarget"|"AWS::S3::StorageLens"|"AWS::IoT::ScheduledAudit"|"AWS::Events::Connection"|"AWS::EventSchemas::Schema"|"AWS::MediaPackage::PackagingConfiguration"|"AWS::KinesisVideo::SignalingChannel"|"AWS::AppStream::DirectoryConfig"|"AWS::LookoutVision::Project"|"AWS::Route53RecoveryControl::Cluster"|"AWS::Route53RecoveryControl::SafetyRule"|"AWS::Route53RecoveryControl::ControlPanel"|"AWS::Route53RecoveryControl::RoutingControl"|"AWS::Route53RecoveryReadiness::ResourceSet"|"AWS::RoboMaker::SimulationApplication"|"AWS::RoboMaker::RobotApplication"|"AWS::HealthLake::FHIRDatastore"|"AWS::Pinpoint::Segment"|"AWS::Pinpoint::ApplicationSettings"|"AWS::Events::Rule"|"AWS::EC2::DHCPOptions"|"AWS::EC2::NetworkInsightsPath"|"AWS::EC2::TrafficMirrorFilter"|"AWS::EC2::IPAM"|"AWS::IoTTwinMaker::Scene"|"AWS::NetworkManager::TransitGatewayRegistration"|"AWS::CustomerProfiles::Domain"|"AWS::AutoScaling::WarmPool"|"AWS::Connect::PhoneNumber", ... (1 more fields)}
  --limit-body: int # The maximum number of RemediationExecutionStatuses returned on each page. The default is maximum. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<RemediationExecutionStatuses: table<ResourceKey: record, State: string, StepDetails: list, InvocationTime: string, LastUpdatedTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeRemediationExecutionStatus")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConfigRuleName": $config_rule_name, "ResourceKeys": $resource_keys, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the details of one or more retention configurations. If the retention configuration name is not specified, this action returns the details for all the retention configurations for that account. Currently, Config supports only one retention configuration per region in your account.
#
# POST /
# operationId: DescribeRetentionConfigurations
export def "describe-retention-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-42 # required
  --retention-configuration-names: list<string> # A list of names of retention configurations for which you want details. If you do not specify a name, Config returns details for all the retention configurations for that account. Currently, Config supports only one retention configuration per region in your account.
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<RetentionConfigurations: table<Name: string, RetentionPeriodInDays: int>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.DescribeRetentionConfigurations")
  let qp = [(serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"RetentionConfigurationNames": $retention_configuration_names, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the evaluation results for the specified Config rule for a specific resource in a rule. The results indicate which Amazon Web Services resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule. The results can return an empty result page. But if you have a nextToken, the results are displayed on the next page.
#
# POST /
# operationId: GetAggregateComplianceDetailsByConfigRule
export def "get-aggregate-compliance-details-by-config-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-43 # required
  configuration_aggregator_name: string # The name of the configuration aggregator.
  config_rule_name: string # The name of the Config rule for which you want compliance information.
  account_id: string # The 12-digit account ID of the source account.
  aws_region: string # The source region from where the data is aggregated.
  --compliance-type: string@compliance-type-completer # The resource compliance status. For the GetAggregateComplianceDetailsByConfigRuleRequest data type, Config supports only the COMPLIANT and NON_COMPLIANT. Config does not support the NOT_APPLICABLE and INSUFFICIENT_DATA values.
  --limit-body: int # The maximum number of evaluation results returned on each page. The default is 50. You cannot specify a number greater than 100. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<AggregateEvaluationResults: table<EvaluationResultIdentifier: record, ComplianceType: string, ResultRecordedTime: string, ConfigRuleInvokedTime: string, Annotation: string, AccountId: string, AwsRegion: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetAggregateComplianceDetailsByConfigRule")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConfigurationAggregatorName": $configuration_aggregator_name, "ConfigRuleName": $config_rule_name, "AccountId": $account_id, "AwsRegion": $aws_region, "ComplianceType": $compliance_type, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the number of compliant and noncompliant rules for one or more accounts and regions in an aggregator. The results can return an empty result page, but if you have a nextToken, the results are displayed on the next page.
#
# POST /
# operationId: GetAggregateConfigRuleComplianceSummary
export def "get-aggregate-config-rule-compliance-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-44 # required
  configuration_aggregator_name: string # The name of the configuration aggregator.
  --filters: record # Filters the results based on the account IDs and regions. — shape: {AccountId?: string, AwsRegion?: string}
  --group-by-key: string@group-by-key-completer # Groups the result based on ACCOUNT_ID or AWS_REGION.
  --limit-body: int # The maximum number of evaluation results returned on each page. The default is 1000. You cannot specify a number greater than 1000. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<GroupByKey: string, AggregateComplianceCounts: table<GroupName: string, ComplianceSummary: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetAggregateConfigRuleComplianceSummary")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConfigurationAggregatorName": $configuration_aggregator_name, "Filters": $filters, "GroupByKey": $group_by_key, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the count of compliant and noncompliant conformance packs across all Amazon Web Services accounts and Amazon Web Services Regions in an aggregator. You can filter based on Amazon Web Services account ID or Amazon Web Services Region. The results can return an empty result page, but if you have a nextToken, the results are displayed on the next page.
#
# POST /
# operationId: GetAggregateConformancePackComplianceSummary
export def "get-aggregate-conformance-pack-compliance-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-45 # required
  configuration_aggregator_name: string # The name of the configuration aggregator.
  --filters: record # Filters the results based on account ID and region. — shape: {AccountId?: string, AwsRegion?: string}
  --group-by-key: string@group-by-key-completer # Groups the result based on Amazon Web Services account ID or Amazon Web Services Region.
  --limit-body: int # The maximum number of results returned on each page. The default is maximum. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<AggregateConformancePackComplianceSummaries: table<ComplianceSummary: record, GroupName: string>, GroupByKey: string, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetAggregateConformancePackComplianceSummary")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConfigurationAggregatorName": $configuration_aggregator_name, "Filters": $filters, "GroupByKey": $group_by_key, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the resource counts across accounts and regions that are present in your Config aggregator. You can request the resource counts by providing filters and GroupByKey. For example, if the input contains accountID 12345678910 and region us-east-1 in filters, the API returns the count of resources in account ID 12345678910 and region us-east-1. If the input contains ACCOUNT_ID as a GroupByKey, the API returns resource counts for all source accounts that are present in your aggregator.
#
# POST /
# operationId: GetAggregateDiscoveredResourceCounts
export def "get-aggregate-discovered-resource-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46 # required
  configuration_aggregator_name: string # The name of the configuration aggregator.
  --filters: record # Filters the resource count based on account ID, region, and resource type. — shape: {ResourceType?: "AWS::EC2::CustomerGateway"|"AWS::EC2::EIP"|"AWS::EC2::Host"|"AWS::EC2::Instance"|"AWS::EC2::InternetGateway"|"AWS::EC2::NetworkAcl"|"AWS::EC2::NetworkInterface"|"AWS::EC2::RouteTable"|"AWS::EC2::SecurityGroup"|"AWS::EC2::Subnet"|"AWS::CloudTrail::Trail"|"AWS::EC2::Volume"|"AWS::EC2::VPC"|"AWS::EC2::VPNConnection"|"AWS::EC2::VPNGateway"|"AWS::EC2::RegisteredHAInstance"|"AWS::EC2::NatGateway"|"AWS::EC2::EgressOnlyInternetGateway"|"AWS::EC2::VPCEndpoint"|"AWS::EC2::VPCEndpointService"|"AWS::EC2::FlowLog"|"AWS::EC2::VPCPeeringConnection"|"AWS::Elasticsearch::Domain"|"AWS::IAM::Group"|"AWS::IAM::Policy"|"AWS::IAM::Role"|"AWS::IAM::User"|"AWS::ElasticLoadBalancingV2::LoadBalancer"|"AWS::ACM::Certificate"|"AWS::RDS::DBInstance"|"AWS::RDS::DBSubnetGroup"|"AWS::RDS::DBSecurityGroup"|"AWS::RDS::DBSnapshot"|"AWS::RDS::DBCluster"|"AWS::RDS::DBClusterSnapshot"|"AWS::RDS::EventSubscription"|"AWS::S3::Bucket"|"AWS::S3::AccountPublicAccessBlock"|"AWS::Redshift::Cluster"|"AWS::Redshift::ClusterSnapshot"|"AWS::Redshift::ClusterParameterGroup"|"AWS::Redshift::ClusterSecurityGroup"|"AWS::Redshift::ClusterSubnetGroup"|"AWS::Redshift::EventSubscription"|"AWS::SSM::ManagedInstanceInventory"|"AWS::CloudWatch::Alarm"|"AWS::CloudFormation::Stack"|"AWS::ElasticLoadBalancing::LoadBalancer"|"AWS::AutoScaling::AutoScalingGroup"|"AWS::AutoScaling::LaunchConfiguration"|"AWS::AutoScaling::ScalingPolicy"|"AWS::AutoScaling::ScheduledAction"|"AWS::DynamoDB::Table"|"AWS::CodeBuild::Project"|"AWS::WAF::RateBasedRule"|"AWS::WAF::Rule"|"AWS::WAF::RuleGroup"|"AWS::WAF::WebACL"|"AWS::WAFRegional::RateBasedRule"|"AWS::WAFRegional::Rule"|"AWS::WAFRegional::RuleGroup"|"AWS::WAFRegional::WebACL"|"AWS::CloudFront::Distribution"|"AWS::CloudFront::StreamingDistribution"|"AWS::Lambda::Function"|"AWS::NetworkFirewall::Firewall"|"AWS::NetworkFirewall::FirewallPolicy"|"AWS::NetworkFirewall::RuleGroup"|"AWS::ElasticBeanstalk::Application"|"AWS::ElasticBeanstalk::ApplicationVersion"|"AWS::ElasticBeanstalk::Environment"|"AWS::WAFv2::WebACL"|"AWS::WAFv2::RuleGroup"|"AWS::WAFv2::IPSet"|"AWS::WAFv2::RegexPatternSet"|"AWS::WAFv2::ManagedRuleSet"|"AWS::XRay::EncryptionConfig"|"AWS::SSM::AssociationCompliance"|"AWS::SSM::PatchCompliance"|"AWS::Shield::Protection"|"AWS::ShieldRegional::Protection"|"AWS::Config::ConformancePackCompliance"|"AWS::Config::ResourceCompliance"|"AWS::ApiGateway::Stage"|"AWS::ApiGateway::RestApi"|"AWS::ApiGatewayV2::Stage"|"AWS::ApiGatewayV2::Api"|"AWS::CodePipeline::Pipeline"|"AWS::ServiceCatalog::CloudFormationProvisionedProduct"|"AWS::ServiceCatalog::CloudFormationProduct"|"AWS::ServiceCatalog::Portfolio"|"AWS::SQS::Queue"|"AWS::KMS::Key"|"AWS::QLDB::Ledger"|"AWS::SecretsManager::Secret"|"AWS::SNS::Topic"|"AWS::SSM::FileData"|"AWS::Backup::BackupPlan"|"AWS::Backup::BackupSelection"|"AWS::Backup::BackupVault"|"AWS::Backup::RecoveryPoint"|"AWS::ECR::Repository"|"AWS::ECS::Cluster"|"AWS::ECS::Service"|"AWS::ECS::TaskDefinition"|"AWS::EFS::AccessPoint"|"AWS::EFS::FileSystem"|"AWS::EKS::Cluster"|"AWS::OpenSearch::Domain"|"AWS::EC2::TransitGateway"|"AWS::Kinesis::Stream"|"AWS::Kinesis::StreamConsumer"|"AWS::CodeDeploy::Application"|"AWS::CodeDeploy::DeploymentConfig"|"AWS::CodeDeploy::DeploymentGroup"|"AWS::EC2::LaunchTemplate"|"AWS::ECR::PublicRepository"|"AWS::GuardDuty::Detector"|"AWS::EMR::SecurityConfiguration"|"AWS::SageMaker::CodeRepository"|"AWS::Route53Resolver::ResolverEndpoint"|"AWS::Route53Resolver::ResolverRule"|"AWS::Route53Resolver::ResolverRuleAssociation"|"AWS::DMS::ReplicationSubnetGroup"|"AWS::DMS::EventSubscription"|"AWS::MSK::Cluster"|"AWS::StepFunctions::Activity"|"AWS::WorkSpaces::Workspace"|"AWS::WorkSpaces::ConnectionAlias"|"AWS::SageMaker::Model"|"AWS::ElasticLoadBalancingV2::Listener"|"AWS::StepFunctions::StateMachine"|"AWS::Batch::JobQueue"|"AWS::Batch::ComputeEnvironment"|"AWS::AccessAnalyzer::Analyzer"|"AWS::Athena::WorkGroup"|"AWS::Athena::DataCatalog"|"AWS::Detective::Graph"|"AWS::GlobalAccelerator::Accelerator"|"AWS::GlobalAccelerator::EndpointGroup"|"AWS::GlobalAccelerator::Listener"|"AWS::EC2::TransitGatewayAttachment"|"AWS::EC2::TransitGatewayRouteTable"|"AWS::DMS::Certificate"|"AWS::AppConfig::Application"|"AWS::AppSync::GraphQLApi"|"AWS::DataSync::LocationSMB"|"AWS::DataSync::LocationFSxLustre"|"AWS::DataSync::LocationS3"|"AWS::DataSync::LocationEFS"|"AWS::DataSync::Task"|"AWS::DataSync::LocationNFS"|"AWS::EC2::NetworkInsightsAccessScopeAnalysis"|"AWS::EKS::FargateProfile"|"AWS::Glue::Job"|"AWS::GuardDuty::ThreatIntelSet"|"AWS::GuardDuty::IPSet"|"AWS::SageMaker::Workteam"|"AWS::SageMaker::NotebookInstanceLifecycleConfig"|"AWS::ServiceDiscovery::Service"|"AWS::ServiceDiscovery::PublicDnsNamespace"|"AWS::SES::ContactList"|"AWS::SES::ConfigurationSet"|"AWS::Route53::HostedZone"|"AWS::IoTEvents::Input"|"AWS::IoTEvents::DetectorModel"|"AWS::IoTEvents::AlarmModel"|"AWS::ServiceDiscovery::HttpNamespace"|"AWS::Events::EventBus"|"AWS::ImageBuilder::ContainerRecipe"|"AWS::ImageBuilder::DistributionConfiguration"|"AWS::ImageBuilder::InfrastructureConfiguration"|"AWS::DataSync::LocationObjectStorage"|"AWS::DataSync::LocationHDFS"|"AWS::Glue::Classifier"|"AWS::Route53RecoveryReadiness::Cell"|"AWS::Route53RecoveryReadiness::ReadinessCheck"|"AWS::ECR::RegistryPolicy"|"AWS::Backup::ReportPlan"|"AWS::Lightsail::Certificate"|"AWS::RUM::AppMonitor"|"AWS::Events::Endpoint"|"AWS::SES::ReceiptRuleSet"|"AWS::Events::Archive"|"AWS::Events::ApiDestination"|"AWS::Lightsail::Disk"|"AWS::FIS::ExperimentTemplate"|"AWS::DataSync::LocationFSxWindows"|"AWS::SES::ReceiptFilter"|"AWS::GuardDuty::Filter"|"AWS::SES::Template"|"AWS::AmazonMQ::Broker"|"AWS::AppConfig::Environment"|"AWS::AppConfig::ConfigurationProfile"|"AWS::Cloud9::EnvironmentEC2"|"AWS::EventSchemas::Registry"|"AWS::EventSchemas::RegistryPolicy"|"AWS::EventSchemas::Discoverer"|"AWS::FraudDetector::Label"|"AWS::FraudDetector::EntityType"|"AWS::FraudDetector::Variable"|"AWS::FraudDetector::Outcome"|"AWS::IoT::Authorizer"|"AWS::IoT::SecurityProfile"|"AWS::IoT::RoleAlias"|"AWS::IoT::Dimension"|"AWS::IoTAnalytics::Datastore"|"AWS::Lightsail::Bucket"|"AWS::Lightsail::StaticIp"|"AWS::MediaPackage::PackagingGroup"|"AWS::Route53RecoveryReadiness::RecoveryGroup"|"AWS::ResilienceHub::ResiliencyPolicy"|"AWS::Transfer::Workflow"|"AWS::EKS::IdentityProviderConfig"|"AWS::EKS::Addon"|"AWS::Glue::MLTransform"|"AWS::IoT::Policy"|"AWS::IoT::MitigationAction"|"AWS::IoTTwinMaker::Workspace"|"AWS::IoTTwinMaker::Entity"|"AWS::IoTAnalytics::Dataset"|"AWS::IoTAnalytics::Pipeline"|"AWS::IoTAnalytics::Channel"|"AWS::IoTSiteWise::Dashboard"|"AWS::IoTSiteWise::Project"|"AWS::IoTSiteWise::Portal"|"AWS::IoTSiteWise::AssetModel"|"AWS::IVS::Channel"|"AWS::IVS::RecordingConfiguration"|"AWS::IVS::PlaybackKeyPair"|"AWS::KinesisAnalyticsV2::Application"|"AWS::RDS::GlobalCluster"|"AWS::S3::MultiRegionAccessPoint"|"AWS::DeviceFarm::TestGridProject"|"AWS::Budgets::BudgetsAction"|"AWS::Lex::Bot"|"AWS::CodeGuruReviewer::RepositoryAssociation"|"AWS::IoT::CustomMetric"|"AWS::Route53Resolver::FirewallDomainList"|"AWS::RoboMaker::RobotApplicationVersion"|"AWS::EC2::TrafficMirrorSession"|"AWS::IoTSiteWise::Gateway"|"AWS::Lex::BotAlias"|"AWS::LookoutMetrics::Alert"|"AWS::IoT::AccountAuditConfiguration"|"AWS::EC2::TrafficMirrorTarget"|"AWS::S3::StorageLens"|"AWS::IoT::ScheduledAudit"|"AWS::Events::Connection"|"AWS::EventSchemas::Schema"|"AWS::MediaPackage::PackagingConfiguration"|"AWS::KinesisVideo::SignalingChannel"|"AWS::AppStream::DirectoryConfig"|"AWS::LookoutVision::Project"|"AWS::Route53RecoveryControl::Cluster"|"AWS::Route53RecoveryControl::SafetyRule"|"AWS::Route53RecoveryControl::ControlPanel"|"AWS::Route53RecoveryControl::RoutingControl"|"AWS::Route53RecoveryReadiness::ResourceSet"|"AWS::RoboMaker::SimulationApplication"|"AWS::RoboMaker::RobotApplication"|"AWS::HealthLake::FHIRDatastore"|"AWS::Pinpoint::Segment"|"AWS::Pinpoint::ApplicationSettings"|"AWS::Events::Rule"|"AWS::EC2::DHCPOptions"|"AWS::EC2::NetworkInsightsPath"|"AWS::EC2::TrafficMirrorFilter"|"AWS::EC2::IPAM"|"AWS::IoTTwinMaker::Scene"|"AWS::NetworkManager::TransitGatewayRegistration"|"AWS::CustomerProfiles::Domain"|"AWS::AutoScaling::WarmPool"|"AWS::Connect::PhoneNumber", ... (2 more fields)}
  --group-by-key: string@group-by-key-completer-1 # The key to group the resource counts.
  --limit-body: int # The maximum number of GroupedResourceCount objects returned on each page. The default is 1000. You cannot specify a number greater than 1000. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<TotalDiscoveredResources: int, GroupByKey: string, GroupedResourceCounts: table<GroupName: string, ResourceCount: int>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetAggregateDiscoveredResourceCounts")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConfigurationAggregatorName": $configuration_aggregator_name, "Filters": $filters, "GroupByKey": $group_by_key, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns configuration item that is aggregated for your specific resource in a specific source account and region.
#
# POST /
# operationId: GetAggregateResourceConfig
export def "get-aggregate-resource-config" [
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
  configuration_aggregator_name: string # The name of the configuration aggregator.
  resource_identifier: record # The details that identify a resource that is collected by Config aggregator, including the resource type, ID, (if available) the custom resource name, the source account, and source region. — shape: {SourceAccountId: string, SourceRegion: string, ResourceId: string, ... (2 more fields)}
]: any -> oneof<record<ConfigurationItem: record<version: string, accountId: string, configurationItemCaptureTime: string, configurationItemStatus: string, configurationStateId: string, configurationItemMD5Hash: string, arn: string, resourceType: string, resourceId: string, resourceName: string, awsRegion: string, availabilityZone: string, resourceCreationTime: string, tags: record, relatedEvents: list<string>, relationships: list<record>, configuration: string, supplementaryConfiguration: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetAggregateResourceConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigurationAggregatorName": $configuration_aggregator_name, "ResourceIdentifier": $resource_identifier} | compact
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

# Returns the evaluation results for the specified Config rule. The results indicate which Amazon Web Services resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule.
#
# POST /
# operationId: GetComplianceDetailsByConfigRule
export def "get-compliance-details-by-config-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-48 # required
  config_rule_name: string # The name of the Config rule for which you want compliance information.
  --compliance-types: list<string> # Filters the results by compliance. INSUFFICIENT_DATA is a valid ComplianceType that is returned when an Config rule cannot be evaluated. However, INSUFFICIENT_DATA cannot be used as a ComplianceType for filtering results.
  --limit-body: int # The maximum number of evaluation results returned on each page. The default is 10. You cannot specify a number greater than 100. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<EvaluationResults: table<EvaluationResultIdentifier: record, ComplianceType: string, ResultRecordedTime: string, ConfigRuleInvokedTime: string, Annotation: string, ResultToken: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetComplianceDetailsByConfigRule")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConfigRuleName": $config_rule_name, "ComplianceTypes": $compliance_types, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the evaluation results for the specified Amazon Web Services resource. The results indicate which Config rules were used to evaluate the resource, when each rule was last invoked, and whether the resource complies with each rule.
#
# POST /
# operationId: GetComplianceDetailsByResource
export def "get-compliance-details-by-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-49 # required
  --resource-type: string # The type of the Amazon Web Services resource for which you want compliance information.
  --resource-id: string # The ID of the Amazon Web Services resource for which you want compliance information.
  --compliance-types: list<string> # Filters the results by compliance. INSUFFICIENT_DATA is a valid ComplianceType that is returned when an Config rule cannot be evaluated. However, INSUFFICIENT_DATA cannot be used as a ComplianceType for filtering results.
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
  --resource-evaluation-id: string # The unique ID of Amazon Web Services resource execution for which you want to retrieve evaluation results. You need to only provide either a ResourceEvaluationID or a ResourceID and ResourceType.
]: any -> oneof<record<EvaluationResults: table<EvaluationResultIdentifier: record, ComplianceType: string, ResultRecordedTime: string, ConfigRuleInvokedTime: string, Annotation: string, ResultToken: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetComplianceDetailsByResource")
  let qp = [(serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ResourceType": $resource_type, "ResourceId": $resource_id, "ComplianceTypes": $compliance_types, "NextToken": $next_token_body, "ResourceEvaluationId": $resource_evaluation_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the number of Config rules that are compliant and noncompliant, up to a maximum of 25 for each.
#
# POST /
# operationId: GetComplianceSummaryByConfigRule
export def "get-compliance-summary-by-config-rule" [
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
]: nothing -> oneof<record<ComplianceSummary: record<CompliantResourceCount: record<CappedCount: int, CapExceeded: bool>, NonCompliantResourceCount: record<CappedCount: int, CapExceeded: bool>, ComplianceSummaryTimestamp: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetComplianceSummaryByConfigRule")
  let full_url = (build-url $base "/" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Returns the number of resources that are compliant and the number that are noncompliant. You can specify one or more resource types to get these numbers for each resource type. The maximum number returned is 100.
#
# POST /
# operationId: GetComplianceSummaryByResourceType
export def "get-compliance-summary-by-resource-type" [
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
  --x-amz-target: string@x-amz-target-completer-51 # required
  --resource-types: list<string> # Specify one or more resource types to get the number of resources that are compliant and the number that are noncompliant for each resource type. For this request, you can specify an Amazon Web Services resource type such as AWS::EC2::Instance. You can specify that the resource type is an Amazon Web Services account by specifying AWS::::Account.
]: any -> oneof<record<ComplianceSummariesByResourceType: table<ResourceType: string, ComplianceSummary: record>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetComplianceSummaryByResourceType")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceTypes": $resource_types} | compact
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

# Returns compliance details of a conformance pack for all Amazon Web Services resources that are monitered by conformance pack.
#
# POST /
# operationId: GetConformancePackComplianceDetails
export def "get-conformance-pack-compliance-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-52 # required
  conformance_pack_name: string # Name of the conformance pack.
  --filters: record # Filters a conformance pack by Config rule names, compliance types, Amazon Web Services resource types, and resource IDs. — shape: {ConfigRuleNames?: list<string>, ComplianceType?: "COMPLIANT"|"NON_COMPLIANT"|"INSUFFICIENT_DATA", ResourceType?: string, ResourceIds?: list<string>}
  --limit-body: int # The maximum number of evaluation results returned on each page. If you do no specify a number, Config uses the default. The default is 100. (body field)
  --next-token-body: string # The nextToken string returned in a previous request that you use to request the next page of results in a paginated response. (body field)
]: any -> oneof<record<ConformancePackName: string, ConformancePackRuleEvaluationResults: table<ComplianceType: string, EvaluationResultIdentifier: record, ConfigRuleInvokedTime: string, ResultRecordedTime: string, Annotation: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetConformancePackComplianceDetails")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConformancePackName": $conformance_pack_name, "Filters": $filters, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns compliance details for the conformance pack based on the cumulative compliance results of all the rules in that conformance pack.
#
# POST /
# operationId: GetConformancePackComplianceSummary
export def "get-conformance-pack-compliance-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-53 # required
  conformance_pack_names: list<string> # Names of conformance packs.
  --limit-body: int # The maximum number of conformance packs returned on each page. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<ConformancePackComplianceSummaryList: table<ConformancePackName: string, ConformancePackComplianceStatus: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetConformancePackComplianceSummary")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConformancePackNames": $conformance_pack_names, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the policy definition containing the logic for your Config Custom Policy rule.
#
# POST /
# operationId: GetCustomRulePolicy
export def "get-custom-rule-policy" [
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
  --x-amz-target: string@x-amz-target-completer-54 # required
  --config-rule-name: string # The name of your Config Custom Policy rule.
]: any -> oneof<record<PolicyText: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetCustomRulePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigRuleName": $config_rule_name} | compact
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

# Returns the resource types, the number of each resource type, and the total number of resources that Config is recording in this region for your Amazon Web Services account. Example Config is recording three resource types in the US East (Ohio) Region for your account: 25 EC2 instances, 20 IAM users, and 15 S3 buckets. You make a call to the GetDiscoveredResourceCounts action and specify that you want all resource types. Config returns the following: The resource types (EC2 instances, IAM users, and S3 buckets). The number of each resource type (25, 20, and 15). The total number of all resources (60). The response is paginated. By default, Config lists 100 ResourceCount objects on each page. You can customize this number with the limit parameter. The response includes a nextToken string. To get the next page of results, run the request again and specify the string for the nextToken parameter. If you make a call to the GetDiscoveredResourceCounts action, you might not immediately receive resource counts in the following situations: You are a new Config customer. You just enabled resource recording. It might take a few minutes for Config to record and count your resources. Wait a few minutes and then retry the GetDiscoveredResourceCounts action.
#
# POST /
# operationId: GetDiscoveredResourceCounts
export def "get-discovered-resource-counts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-55 # required
  --resource-types: list<string> # The comma-separated list that specifies the resource types that you want Config to return (for example, "AWS::EC2::Instance", "AWS::IAM::User"). If a value for resourceTypes is not specified, Config returns all resource types that Config is recording in the region for your account. If the configuration recorder is turned off, Config returns an empty list of ResourceCount objects. If the configuration recorder is not recording a specific resource type (for example, S3 buckets), that resource type is not returned in the list of ResourceCount objects.
  --limit-body: int # The maximum number of ResourceCount objects returned on each page. The default is 100. You cannot specify a number greater than 100. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<totalDiscoveredResources: int, resourceCounts: table<resourceType: string, count: int>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetDiscoveredResourceCounts")
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"resourceTypes": $resource_types, "limit": $limit_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"limit": $limit, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns detailed status for each member account within an organization for a given organization Config rule.
#
# POST /
# operationId: GetOrganizationConfigRuleDetailedStatus
export def "get-organization-config-rule-detailed-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-56 # required
  organization_config_rule_name: string # The name of your organization Config rule for which you want status details for member accounts.
  --filters: record # Status filter object to filter results based on specific member account ID or status type for an organization Config rule. — shape: {AccountId?: string, MemberAccountRuleStatus?: "CREATE_SUCCESSFUL"|"CREATE_IN_PROGRESS"|"CREATE_FAILED"|"DELETE_SUCCESSFUL"|"DELETE_FAILED"|"DELETE_IN_PROGRESS"|"UPDATE_SUCCESSFUL"|"UPDATE_IN_PROGRESS"|"UPDATE_FAILED"}
  --limit-body: int # The maximum number of OrganizationConfigRuleDetailedStatus returned on each page. If you do not specify a number, Config uses the default. The default is 100. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<OrganizationConfigRuleDetailedStatus: table<AccountId: string, ConfigRuleName: string, MemberAccountRuleStatus: string, ErrorCode: string, ErrorMessage: string, LastUpdateTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetOrganizationConfigRuleDetailedStatus")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"OrganizationConfigRuleName": $organization_config_rule_name, "Filters": $filters, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns detailed status for each member account within an organization for a given organization conformance pack.
#
# POST /
# operationId: GetOrganizationConformancePackDetailedStatus
export def "get-organization-conformance-pack-detailed-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-57 # required
  organization_conformance_pack_name: string # The name of organization conformance pack for which you want status details for member accounts.
  --filters: record # Status filter object to filter results based on specific member account ID or status type for an organization conformance pack. — shape: {AccountId?: string, Status?: "CREATE_SUCCESSFUL"|"CREATE_IN_PROGRESS"|"CREATE_FAILED"|"DELETE_SUCCESSFUL"|"DELETE_FAILED"|"DELETE_IN_PROGRESS"|"UPDATE_SUCCESSFUL"|"UPDATE_IN_PROGRESS"|"UPDATE_FAILED"}
  --limit-body: int # The maximum number of OrganizationConformancePackDetailedStatuses returned on each page. If you do not specify a number, Config uses the default. The default is 100. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<OrganizationConformancePackDetailedStatuses: table<AccountId: string, ConformancePackName: string, Status: string, ErrorCode: string, ErrorMessage: string, LastUpdateTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetOrganizationConformancePackDetailedStatus")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"OrganizationConformancePackName": $organization_conformance_pack_name, "Filters": $filters, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the policy definition containing the logic for your organization Config Custom Policy rule.
#
# POST /
# operationId: GetOrganizationCustomRulePolicy
export def "get-organization-custom-rule-policy" [
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
  --x-amz-target: string@x-amz-target-completer-58 # required
  organization_config_rule_name: string # The name of your organization Config Custom Policy rule.
]: any -> oneof<record<PolicyText: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetOrganizationCustomRulePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"OrganizationConfigRuleName": $organization_config_rule_name} | compact
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

# Returns a list of ConfigurationItems for the specified resource. The list contains details about each state of the resource during the specified time interval. If you specified a retention period to retain your ConfigurationItems between a minimum of 30 days and a maximum of 7 years (2557 days), Config returns the ConfigurationItems for the specified retention period. The response is paginated. By default, Config returns a limit of 10 configuration items per page. You can customize this number with the limit parameter. The response includes a nextToken string. To get the next page of results, run the request again and specify the string for the nextToken parameter. Each call to the API is limited to span a duration of seven days. It is likely that the number of records returned is smaller than the specified limit. In such cases, you can make another call, using the nextToken.
#
# POST /
# operationId: GetResourceConfigHistory
export def "get-resource-config-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-59 # required
  resource_type: string@resource-type-completer # The resource type.
  resource_id: string # The ID of the resource (for example., sg-xxxxxx).
  --later-time: string # The time stamp that indicates a later time. If not specified, current time is taken. (format: date-time)
  --earlier-time: string # The time stamp that indicates an earlier time. If not specified, the action returns paginated results that contain configuration items that start when the first configuration item was recorded. (format: date-time)
  --chronological-order: string@chronological-order-completer # The chronological order for configuration items listed. By default, the results are listed in reverse chronological order.
  --limit-body: int # The maximum number of configuration items returned on each page. The default is 10. You cannot specify a number greater than 100. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<configurationItems: table<version: string, accountId: string, configurationItemCaptureTime: string, configurationItemStatus: string, configurationStateId: string, configurationItemMD5Hash: string, arn: string, resourceType: string, resourceId: string, resourceName: string, awsRegion: string, availabilityZone: string, resourceCreationTime: string, tags: record, relatedEvents: list, relationships: list, configuration: string, supplementaryConfiguration: record>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetResourceConfigHistory")
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"resourceType": $resource_type, "resourceId": $resource_id, "laterTime": $later_time, "earlierTime": $earlier_time, "chronologicalOrder": $chronological_order, "limit": $limit_body, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"limit": $limit, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a summary of resource evaluation for the specified resource evaluation ID from the proactive rules that were run. The results indicate which evaluation context was used to evaluate the rules, which resource details were evaluated, the evaluation mode that was run, and whether the resource details comply with the configuration of the proactive rules. To see additional information about the evaluation result, such as which rule flagged a resource as NON_COMPLIANT, use the GetComplianceDetailsByResource (https://docs.aws.amazon.com/config/latest/APIReference/API_GetComplianceDetailsByResource.html) API. For more information, see the Examples (https://docs.aws.amazon.com/config/latest/APIReference/API_GetResourceEvaluationSummary.html#API_GetResourceEvaluationSummary_Examples) section.
#
# POST /
# operationId: GetResourceEvaluationSummary
export def "get-resource-evaluation-summary" [
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
  --x-amz-target: string@x-amz-target-completer-60 # required
  resource_evaluation_id: string # The unique ResourceEvaluationId of Amazon Web Services resource execution for which you want to retrieve the evaluation summary.
]: any -> oneof<record<ResourceEvaluationId: string, EvaluationMode: string, EvaluationStatus: record<Status: string, FailureReason: string>, EvaluationStartTimestamp: string, Compliance: string, EvaluationContext: record<EvaluationContextIdentifier: string>, ResourceDetails: record<ResourceId: string, ResourceType: string, ResourceConfiguration: string, ResourceConfigurationSchemaType: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetResourceEvaluationSummary")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceEvaluationId": $resource_evaluation_id} | compact
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

# Returns the details of a specific stored query.
#
# POST /
# operationId: GetStoredQuery
export def "get-stored-query" [
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
  --x-amz-target: string@x-amz-target-completer-61 # required
  query_name: string # The name of the query.
]: any -> oneof<record<StoredQuery: record<QueryId: string, QueryArn: string, QueryName: string, Description: string, Expression: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.GetStoredQuery")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"QueryName": $query_name} | compact
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

# Accepts a resource type and returns a list of resource identifiers that are aggregated for a specific resource type across accounts and regions. A resource identifier includes the resource type, ID, (if available) the custom resource name, source account, and source region. You can narrow the results to include only resources that have specific resource IDs, or a resource name, or source account ID, or source region. For example, if the input consists of accountID 12345678910 and the region is us-east-1 for resource type AWS::EC2::Instance then the API returns all the EC2 instance identifiers of accountID 12345678910 and region us-east-1.
#
# POST /
# operationId: ListAggregateDiscoveredResources
export def "list-aggregate-discovered-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-62 # required
  configuration_aggregator_name: string # The name of the configuration aggregator.
  resource_type: string@resource-type-completer # The type of resources that you want Config to list in the response.
  --filters: record # Filters the results by resource account ID, region, resource ID, and resource name. — shape: {AccountId?: string, ResourceId?: string, ResourceName?: string, Region?: string}
  --limit-body: int # The maximum number of resource identifiers returned on each page. You cannot specify a number greater than 100. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<ResourceIdentifiers: table<SourceAccountId: string, SourceRegion: string, ResourceId: string, ResourceType: string, ResourceName: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.ListAggregateDiscoveredResources")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ConfigurationAggregatorName": $configuration_aggregator_name, "ResourceType": $resource_type, "Filters": $filters, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of conformance pack compliance scores. A compliance score is the percentage of the number of compliant rule-resource combinations in a conformance pack compared to the number of total possible rule-resource combinations in the conformance pack. This metric provides you with a high-level view of the compliance state of your conformance packs. You can use it to identify, investigate, and understand the level of compliance in your conformance packs. Conformance packs with no evaluation results will have a compliance score of INSUFFICIENT_DATA.
#
# POST /
# operationId: ListConformancePackComplianceScores
export def "list-conformance-pack-compliance-scores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-63 # required
  --filters: record # A list of filters to apply to the conformance pack compliance score result set. — shape: {ConformancePackNames: list<string>}
  --sort-order: string@sort-order-completer # Determines the order in which conformance pack compliance scores are sorted. Either in ascending or descending order. By default, conformance pack compliance scores are sorted in alphabetical order by name of the conformance pack. Conformance pack compliance scores are sorted in reverse alphabetical order if you enter DESCENDING. You can sort conformance pack compliance scores by the numerical value of the compliance score by entering SCORE in the SortBy action. When compliance scores are sorted by SCORE, conformance packs with a compliance score of INSUFFICIENT_DATA will be last when sorting by ascending order and first when sorting by descending order.
  --sort-by: string@sort-by-completer # Sorts your conformance pack compliance scores in either ascending or descending order, depending on SortOrder. By default, conformance pack compliance scores are sorted in alphabetical order by name of the conformance pack. Enter SCORE, to sort conformance pack compliance scores by the numerical value of the compliance score.
  --limit-body: int # The maximum number of conformance pack compliance scores returned on each page. (body field)
  --next-token-body: string # The nextToken string in a prior request that you can use to get the paginated response for the next set of conformance pack compliance scores. (body field)
]: any -> oneof<record<NextToken: string, ConformancePackComplianceScores: table<Score: string, ConformancePackName: string, LastUpdatedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.ListConformancePackComplianceScores")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "SortOrder": $sort_order, "SortBy": $sort_by, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Accepts a resource type and returns a list of resource identifiers for the resources of that type. A resource identifier includes the resource type, ID, and (if available) the custom resource name. The results consist of resources that Config has discovered, including those that Config is not currently recording. You can narrow the results to include only resources that have specific resource IDs or a resource name. You can specify either resource IDs or a resource name, but not both, in the same request. The response is paginated. By default, Config lists 100 resource identifiers on each page. You can customize this number with the limit parameter. The response includes a nextToken string. To get the next page of results, run the request again and specify the string for the nextToken parameter.
#
# POST /
# operationId: ListDiscoveredResources
export def "list-discovered-resources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-64 # required
  resource_type: string@resource-type-completer # The type of resources that you want Config to list in the response.
  --resource-ids: list<string> # The IDs of only those resources that you want Config to list in the response. If you do not specify this parameter, Config lists all resources of the specified type that it has discovered. You can list a minimum of 1 resourceID and a maximum of 20 resourceIds.
  --resource-name: string # The custom name of only those resources that you want Config to list in the response. If you do not specify this parameter, Config lists all resources of the specified type that it has discovered.
  --limit-body: int # The maximum number of resource identifiers returned on each page. The default is 100. You cannot specify a number greater than 100. If you specify 0, Config uses the default. (body field)
  --include-deleted-resources: oneof<nothing, bool> # Specifies whether Config includes deleted resources in the results. By default, deleted resources are not included.
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<resourceIdentifiers: table<resourceType: string, resourceId: string, resourceName: string, resourceDeletionTime: string>, nextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.ListDiscoveredResources")
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "nextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"resourceType": $resource_type, "resourceIds": $resource_ids, "resourceName": $resource_name, "limit": $limit_body, "includeDeletedResources": $include_deleted_resources, "nextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"limit": $limit, "nextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of proactive resource evaluations.
#
# POST /
# operationId: ListResourceEvaluations
export def "list-resource-evaluations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-65 # required
  --filters: record # Returns details of a resource evaluation based on the selected filter. — shape: {EvaluationMode?: "DETECTIVE"|"PROACTIVE", TimeWindow?: record, EvaluationContextIdentifier?: string}
  --limit-body: int # The maximum number of evaluations returned on each page. The default is 10. You cannot specify a number greater than 100. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<ResourceEvaluations: table<ResourceEvaluationId: string, EvaluationMode: string, EvaluationStartTimestamp: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.ListResourceEvaluations")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the stored queries for a single Amazon Web Services account and a single Amazon Web Services Region. The default is 100.
#
# POST /
# operationId: ListStoredQueries
export def "list-stored-queries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --x-amz-target: string@x-amz-target-completer-66 # required
  --next-token-body: string # The nextToken string returned in a previous request that you use to request the next page of results in a paginated response. (body field)
  --max-results-body: int # The maximum number of results to be returned with a single call. (body field)
]: any -> oneof<record<StoredQueryMetadata: table<QueryId: string, QueryArn: string, QueryName: string, Description: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.ListStoredQueries")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"NextToken": $next_token_body, "MaxResults": $max_results_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List the tags for Config resource.
#
# POST /
# operationId: ListTagsForResource
export def "list-tags-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-67 # required
  resource_arn: string # The Amazon Resource Name (ARN) that identifies the resource for which to list the tags. Currently, the supported resources are ConfigRule, ConfigurationAggregator and AggregatorAuthorization.
  --limit-body: int # The maximum number of tags returned on each page. The limit maximum is 50. You cannot specify a number greater than 50. If you specify 0, Config uses the default. (body field)
  --next-token-body: string # The nextToken string returned on a previous page that you use to get the next page of results in a paginated response. (body field)
]: any -> oneof<record<Tags: table<Key: string, Value: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.ListTagsForResource")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Authorizes the aggregator account and region to collect data from the source account and region. PutAggregationAuthorization is an idempotent API. Subsequent requests won’t create a duplicate resource if one was already created. If a following request has different tags values, Config will ignore these differences and treat it as an idempotent request of the previous. In this case, tags will not be updated, even if they are different.
#
# POST /
# operationId: PutAggregationAuthorization
export def "put-aggregation-authorization" [
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
  --x-amz-target: string@x-amz-target-completer-68 # required
  authorized_account_id: string # The 12-digit account ID of the account authorized to aggregate data.
  authorized_aws_region: string # The region authorized to collect aggregated data.
  --tags: list # An array of tag object. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record<AggregationAuthorization: record<AggregationAuthorizationArn: string, AuthorizedAccountId: string, AuthorizedAwsRegion: string, CreationTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.PutAggregationAuthorization")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AuthorizedAccountId": $authorized_account_id, "AuthorizedAwsRegion": $authorized_aws_region, "Tags": $tags} | compact
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

# Adds or updates an Config rule to evaluate if your Amazon Web Services resources comply with your desired configurations. For information on how many Config rules you can have per account, see Service Limits (https://docs.aws.amazon.com/config/latest/developerguide/configlimits.html) in the Config Developer Guide. There are two types of rules: Config Managed Rules and Config Custom Rules. You can use PutConfigRule to create both Config Managed Rules and Config Custom Rules. Config Managed Rules are predefined, customizable rules created by Config. For a list of managed rules, see List of Config Managed Rules (https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html). If you are adding an Config managed rule, you must specify the rule's identifier for the SourceIdentifier key. Config Custom Rules are rules that you create from scratch. There are two ways to create Config custom rules: with Lambda functions ( Lambda Developer Guide (https://docs.aws.amazon.com/config/latest/developerguide/gettingstarted-concepts.html#gettingstarted-concepts-function)) and with Guard (Guard GitHub Repository (https://github.com/aws-cloudformation/cloudformation-guard)), a policy-as-code language. Config custom rules created with Lambda are called Config Custom Lambda Rules and Config custom rules created with Guard are called Config Custom Policy Rules. If you are adding a new Config Custom Lambda rule, you first need to create an Lambda function that the rule invokes to evaluate your resources. When you use PutConfigRule to add a Custom Lambda rule to Config, you must specify the Amazon Resource Name (ARN) that Lambda assigns to the function. You specify the ARN in the SourceIdentifier key. This key is part of the Source object, which is part of the ConfigRule object. For any new Config rule that you add, specify the ConfigRuleName in the ConfigRule object. Do not specify the ConfigRuleArn or the ConfigRuleId. These values are generated by Config for new rules. If you are updating a rule that you added previously, you can specify the rule by ConfigRuleName, ConfigRuleId, or ConfigRuleArn in the ConfigRule data type that you use in this request. For more information about developing and using Config rules, see Evaluating Resources with Config Rules (https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html) in the Config Developer Guide. PutConfigRule is an idempotent API. Subsequent requests won’t create a duplicate resource if one was already created. If a following request has different tags values, Config will ignore these differences and treat it as an idempotent request of the previous. In this case, tags will not be updated, even if they are different.
#
# POST /
# operationId: PutConfigRule
export def "put-config-rule" [
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
  config_rule: record # Config rules evaluate the configuration settings of your Amazon Web Services resources. A rule can run when Config detects a configuration change to an Amazon Web Services resource or at a periodic frequency that you choose (for example, every 24 hours). There are two types of rules: Config Managed Rules and Config Custom Rules. Config Managed Rules are predefined, customizable rules created by Config. For a list of managed rules, see List of Config Managed Rules (https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html). Config Custom Rules are rules that you create from scratch. There are two ways to create Config custom rules: with Lambda functions ( Lambda Developer Guide (https://docs.aws.amazon.com/config/latest/developerguide/gettingstarted-concepts.html#gettingstarted-concepts-function)) and with Guard (Guard GitHub Repository (https://github.com/aws-cloudformation/cloudformation-guard)), a policy-as-code language. Config custom rules created with Lambda are called Config Custom Lambda Rules and Config custom rules created with Guard are called Config Custom Policy Rules. For more information about developing and using Config rules, see Evaluating Resource with Config Rules (https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html) in the Config Developer Guide. You can use the Amazon Web Services CLI and Amazon Web Services SDKs if you want to create a rule that triggers evaluations for your resources when Config delivers the configuration snapshot. For more information, see ConfigSnapshotDeliveryProperties. — shape: {ConfigRuleName?: string, ConfigRuleArn?: string, ConfigRuleId?: string, Description?: string, Scope?: record, Source: record, InputParameters?: string, MaximumExecutionFrequency?: "One_Hour"|"Three_Hours"|"Six_Hours"|"Twelve_Hours"|"TwentyFour_Hours", ConfigRuleState?: "ACTIVE"|"DELETING"|"DELETING_RESULTS"|"EVALUATING", CreatedBy?: string, EvaluationModes?: list}
  --tags: list # An array of tag object. — item shape: {Key?: string, Value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.PutConfigRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigRule": $config_rule, "Tags": $tags} | compact
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

# Creates and updates the configuration aggregator with the selected source accounts and regions. The source account can be individual account(s) or an organization. accountIds that are passed will be replaced with existing accounts. If you want to add additional accounts into the aggregator, call DescribeConfigurationAggregators to get the previous accounts and then append new ones. Config should be enabled in source accounts and regions you want to aggregate. If your source type is an organization, you must be signed in to the management account or a registered delegated administrator and all the features must be enabled in your organization. If the caller is a management account, Config calls EnableAwsServiceAccess API to enable integration between Config and Organizations. If the caller is a registered delegated administrator, Config calls ListDelegatedAdministrators API to verify whether the caller is a valid delegated administrator. To register a delegated administrator, see Register a Delegated Administrator (https://docs.aws.amazon.com/config/latest/developerguide/set-up-aggregator-cli.html#register-a-delegated-administrator-cli) in the Config developer guide. PutConfigurationAggregator is an idempotent API. Subsequent requests won’t create a duplicate resource if one was already created. If a following request has different tags values, Config will ignore these differences and treat it as an idempotent request of the previous. In this case, tags will not be updated, even if they are different.
#
# POST /
# operationId: PutConfigurationAggregator
export def "put-configuration-aggregator" [
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
  --x-amz-target: string@x-amz-target-completer-70 # required
  configuration_aggregator_name: string # The name of the configuration aggregator.
  --account-aggregation-sources: list # A list of AccountAggregationSource object. — item shape: {AccountIds: list<string>, AllAwsRegions?: bool, AwsRegions?: list<string>}
  --organization-aggregation-source: record # This object contains regions to set up the aggregator and an IAM role to retrieve organization details. — shape: {RoleArn: string, AwsRegions?: list<string>, AllAwsRegions?: bool}
  --tags: list # An array of tag object. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record<ConfigurationAggregator: record<ConfigurationAggregatorName: string, ConfigurationAggregatorArn: string, AccountAggregationSources: list<record>, OrganizationAggregationSource: record<RoleArn: string, AwsRegions: list, AllAwsRegions: bool>, CreationTime: string, LastUpdatedTime: string, CreatedBy: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.PutConfigurationAggregator")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigurationAggregatorName": $configuration_aggregator_name, "AccountAggregationSources": $account_aggregation_sources, "OrganizationAggregationSource": $organization_aggregation_source, "Tags": $tags} | compact
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

# Creates a new configuration recorder to record the selected resource configurations. You can use this action to change the role roleARN or the recordingGroup of an existing recorder. To change the role, call the action on the existing configuration recorder and specify a role. Currently, you can specify only one configuration recorder per region in your account. If ConfigurationRecorder does not have the recordingGroup parameter specified, the default is to record all supported resource types.
#
# POST /
# operationId: PutConfigurationRecorder
export def "put-configuration-recorder" [
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
  configuration_recorder: record # An object that represents the recording of configuration changes of an Amazon Web Services resource. — shape: {name?: string, roleARN?: string, recordingGroup?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.PutConfigurationRecorder")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigurationRecorder": $configuration_recorder} | compact
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

# Creates or updates a conformance pack. A conformance pack is a collection of Config rules that can be easily deployed in an account and a region and across an organization. For information on how many conformance packs you can have per account, see Service Limits (https://docs.aws.amazon.com/config/latest/developerguide/configlimits.html) in the Config Developer Guide. This API creates a service-linked role AWSServiceRoleForConfigConforms in your account. The service-linked role is created only when the role does not exist in your account. You must specify only one of the follow parameters: TemplateS3Uri, TemplateBody or TemplateSSMDocumentDetails.
#
# POST /
# operationId: PutConformancePack
export def "put-conformance-pack" [
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
  conformance_pack_name: string # The unique name of the conformance pack you want to deploy.
  --template-s3-uri: string # The location of the file containing the template body (s3://bucketname/prefix). The uri must point to a conformance pack template (max size: 300 KB) that is located in an Amazon S3 bucket in the same Region as the conformance pack. You must have access to read Amazon S3 bucket.
  --template-body: string # A string containing the full conformance pack template body. The structure containing the template body has a minimum length of 1 byte and a maximum length of 51,200 bytes. You can use a YAML template with two resource types: Config rule (AWS::Config::ConfigRule) and remediation action (AWS::Config::RemediationConfiguration).
  --delivery-s3-bucket: string # The name of the Amazon S3 bucket where Config stores conformance pack templates. This field is optional.
  --delivery-s3-key-prefix: string # The prefix for the Amazon S3 bucket. This field is optional.
  --conformance-pack-input-parameters: list # A list of ConformancePackInputParameter objects. — item shape: {ParameterName: string, ParameterValue: string}
  --template-ssm-document-details: record # This API allows you to create a conformance pack template with an Amazon Web Services Systems Manager document (SSM document). To deploy a conformance pack using an SSM document, first create an SSM document with conformance pack content, and then provide the DocumentName in the PutConformancePack API (https://docs.aws.amazon.com/config/latest/APIReference/API_PutConformancePack.html). You can also provide the DocumentVersion. The TemplateSSMDocumentDetails object contains the name of the SSM document and the version of the SSM document. — shape: {DocumentName: string, DocumentVersion?: string}
]: any -> oneof<record<ConformancePackArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.PutConformancePack")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConformancePackName": $conformance_pack_name, "TemplateS3Uri": $template_s3_uri, "TemplateBody": $template_body, "DeliveryS3Bucket": $delivery_s3_bucket, "DeliveryS3KeyPrefix": $delivery_s3_key_prefix, "ConformancePackInputParameters": $conformance_pack_input_parameters, "TemplateSSMDocumentDetails": $template_ssm_document_details} | compact
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

# Creates a delivery channel object to deliver configuration information to an Amazon S3 bucket and Amazon SNS topic. Before you can create a delivery channel, you must create a configuration recorder. You can use this action to change the Amazon S3 bucket or an Amazon SNS topic of the existing delivery channel. To change the Amazon S3 bucket or an Amazon SNS topic, call this action and specify the changed values for the S3 bucket and the SNS topic. If you specify a different value for either the S3 bucket or the SNS topic, this action will keep the existing value for the parameter that is not changed. You can have only one delivery channel per region in your account.
#
# POST /
# operationId: PutDeliveryChannel
export def "put-delivery-channel" [
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
  delivery_channel: record # The channel through which Config delivers notifications and updated configuration states. — shape: {name?: string, s3BucketName?: string, s3KeyPrefix?: string, s3KmsKeyArn?: string, snsTopicARN?: string, configSnapshotDeliveryProperties?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.PutDeliveryChannel")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DeliveryChannel": $delivery_channel} | compact
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

# Used by an Lambda function to deliver evaluation results to Config. This action is required in every Lambda function that is invoked by an Config rule.
#
# POST /
# operationId: PutEvaluations
export def "put-evaluations" [
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
  --evaluations: list # The assessments that the Lambda function performs. Each evaluation identifies an Amazon Web Services resource and indicates whether it complies with the Config rule that invokes the Lambda function. — item shape: {ComplianceResourceType: string, ComplianceResourceId: string, ComplianceType: "COMPLIANT"|"NON_COMPLIANT"|"NOT_APPLICABLE"|"INSUFFICIENT_DATA", Annotation?: string, OrderingTimestamp: string}
  result_token: string # An encrypted token that associates an evaluation with an Config rule. Identifies the rule and the event that triggered the evaluation.
  --test-mode: oneof<nothing, bool> # Use this parameter to specify a test run for PutEvaluations. You can verify whether your Lambda function will deliver evaluation results to Config. No updates occur to your existing evaluations, and evaluation results are not sent to Config. When TestMode is true, PutEvaluations doesn't require a valid value for the ResultToken parameter, but the value cannot be null.
]: any -> oneof<record<FailedEvaluations: table<ComplianceResourceType: string, ComplianceResourceId: string, ComplianceType: string, Annotation: string, OrderingTimestamp: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.PutEvaluations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Evaluations": $evaluations, "ResultToken": $result_token, "TestMode": $test_mode} | compact
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

# Add or updates the evaluations for process checks. This API checks if the rule is a process check when the name of the Config rule is provided.
#
# POST /
# operationId: PutExternalEvaluation
export def "put-external-evaluation" [
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
  config_rule_name: string # The name of the Config rule.
  external_evaluation: record # Identifies an Amazon Web Services resource and indicates whether it complies with the Config rule that it was evaluated against. — shape: {ComplianceResourceType: string, ComplianceResourceId: string, ComplianceType: "COMPLIANT"|"NON_COMPLIANT"|"NOT_APPLICABLE"|"INSUFFICIENT_DATA", Annotation?: string, OrderingTimestamp: string}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.PutExternalEvaluation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigRuleName": $config_rule_name, "ExternalEvaluation": $external_evaluation} | compact
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

# Adds or updates an Config rule for your entire organization to evaluate if your Amazon Web Services resources comply with your desired configurations. For information on how many organization Config rules you can have per account, see Service Limits (https://docs.aws.amazon.com/config/latest/developerguide/configlimits.html) in the Config Developer Guide. Only a management account and a delegated administrator can create or update an organization Config rule. When calling this API with a delegated administrator, you must ensure Organizations ListDelegatedAdministrator permissions are added. An organization can have up to 3 delegated administrators. This API enables organization service access through the EnableAWSServiceAccess action and creates a service-linked role AWSServiceRoleForConfigMultiAccountSetup in the management or delegated administrator account of your organization. The service-linked role is created only when the role does not exist in the caller account. Config verifies the existence of role with GetRole action. To use this API with delegated administrator, register a delegated administrator by calling Amazon Web Services Organization register-delegated-administrator for config-multiaccountsetup.amazonaws.com. There are two types of rules: Config Managed Rules and Config Custom Rules. You can use PutOrganizationConfigRule to create both Config Managed Rules and Config Custom Rules. Config Managed Rules are predefined, customizable rules created by Config. For a list of managed rules, see List of Config Managed Rules (https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html). If you are adding an Config managed rule, you must specify the rule's identifier for the RuleIdentifier key. Config Custom Rules are rules that you create from scratch. There are two ways to create Config custom rules: with Lambda functions ( Lambda Developer Guide (https://docs.aws.amazon.com/config/latest/developerguide/gettingstarted-concepts.html#gettingstarted-concepts-function)) and with Guard (Guard GitHub Repository (https://github.com/aws-cloudformation/cloudformation-guard)), a policy-as-code language. Config custom rules created with Lambda are called Config Custom Lambda Rules and Config custom rules created with Guard are called Config Custom Policy Rules. If you are adding a new Config Custom Lambda rule, you first need to create an Lambda function in the management account or a delegated administrator that the rule invokes to evaluate your resources. You also need to create an IAM role in the managed account that can be assumed by the Lambda function. When you use PutOrganizationConfigRule to add a Custom Lambda rule to Config, you must specify the Amazon Resource Name (ARN) that Lambda assigns to the function. Prerequisite: Ensure you call EnableAllFeatures API to enable all features in an organization. Make sure to specify one of either OrganizationCustomPolicyRuleMetadata for Custom Policy rules, OrganizationCustomRuleMetadata for Custom Lambda rules, or OrganizationManagedRuleMetadata for managed rules.
#
# POST /
# operationId: PutOrganizationConfigRule
export def "put-organization-config-rule" [
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
  organization_config_rule_name: string # The name that you assign to an organization Config rule.
  --organization-managed-rule-metadata: record # An object that specifies organization managed rule metadata such as resource type and ID of Amazon Web Services resource along with the rule identifier. It also provides the frequency with which you want Config to run evaluations for the rule if the trigger type is periodic. — shape: {Description?: string, RuleIdentifier: string, InputParameters?: string, MaximumExecutionFrequency?: "One_Hour"|"Three_Hours"|"Six_Hours"|"Twelve_Hours"|"TwentyFour_Hours", ResourceTypesScope?: list<string>, ResourceIdScope?: string, TagKeyScope?: string, TagValueScope?: string}
  --organization-custom-rule-metadata: record # An object that specifies organization custom rule metadata such as resource type, resource ID of Amazon Web Services resource, Lambda function ARN, and organization trigger types that trigger Config to evaluate your Amazon Web Services resources against a rule. It also provides the frequency with which you want Config to run evaluations for the rule if the trigger type is periodic. — shape: {Description?: string, LambdaFunctionArn: string, OrganizationConfigRuleTriggerTypes: list<string>, InputParameters?: string, MaximumExecutionFrequency?: "One_Hour"|"Three_Hours"|"Six_Hours"|"Twelve_Hours"|"TwentyFour_Hours", ResourceTypesScope?: list<string>, ResourceIdScope?: string, TagKeyScope?: string, TagValueScope?: string}
  --excluded-accounts: list<string> # A comma-separated list of accounts that you want to exclude from an organization Config rule.
  --organization-custom-policy-rule-metadata: record # An object that specifies metadata for your organization's Config Custom Policy rule. The metadata includes the runtime system in use, which accounts have debug logging enabled, and other custom rule metadata, such as resource type, resource ID of Amazon Web Services resource, and organization trigger types that initiate Config to evaluate Amazon Web Services resources against a rule. — shape: {Description?: string, OrganizationConfigRuleTriggerTypes?: list<string>, InputParameters?: string, MaximumExecutionFrequency?: "One_Hour"|"Three_Hours"|"Six_Hours"|"Twelve_Hours"|"TwentyFour_Hours", ResourceTypesScope?: list<string>, ResourceIdScope?: string, TagKeyScope?: string, TagValueScope?: string, PolicyRuntime: string, PolicyText: string, DebugLogDeliveryAccounts?: list<string>}
]: any -> oneof<record<OrganizationConfigRuleArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.PutOrganizationConfigRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"OrganizationConfigRuleName": $organization_config_rule_name, "OrganizationManagedRuleMetadata": $organization_managed_rule_metadata, "OrganizationCustomRuleMetadata": $organization_custom_rule_metadata, "ExcludedAccounts": $excluded_accounts, "OrganizationCustomPolicyRuleMetadata": $organization_custom_policy_rule_metadata} | compact
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

# Deploys conformance packs across member accounts in an Amazon Web Services Organization. For information on how many organization conformance packs and how many Config rules you can have per account, see Service Limits (https://docs.aws.amazon.com/config/latest/developerguide/configlimits.html) in the Config Developer Guide. Only a management account and a delegated administrator can call this API. When calling this API with a delegated administrator, you must ensure Organizations ListDelegatedAdministrator permissions are added. An organization can have up to 3 delegated administrators. This API enables organization service access for config-multiaccountsetup.amazonaws.com through the EnableAWSServiceAccess action and creates a service-linked role AWSServiceRoleForConfigMultiAccountSetup in the management or delegated administrator account of your organization. The service-linked role is created only when the role does not exist in the caller account. To use this API with delegated administrator, register a delegated administrator by calling Amazon Web Services Organization register-delegate-admin for config-multiaccountsetup.amazonaws.com. Prerequisite: Ensure you call EnableAllFeatures API to enable all features in an organization. You must specify either the TemplateS3Uri or the TemplateBody parameter, but not both. If you provide both Config uses the TemplateS3Uri parameter and ignores the TemplateBody parameter. Config sets the state of a conformance pack to CREATE_IN_PROGRESS and UPDATE_IN_PROGRESS until the conformance pack is created or updated. You cannot update a conformance pack while it is in this state.
#
# POST /
# operationId: PutOrganizationConformancePack
export def "put-organization-conformance-pack" [
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
  --x-amz-target: string@x-amz-target-completer-77 # required
  organization_conformance_pack_name: string # Name of the organization conformance pack you want to create.
  --template-s3-uri: string # Location of file containing the template body. The uri must point to the conformance pack template (max size: 300 KB). You must have access to read Amazon S3 bucket.
  --template-body: string # A string containing full conformance pack template body. Structure containing the template body with a minimum length of 1 byte and a maximum length of 51,200 bytes.
  --delivery-s3-bucket: string # The name of the Amazon S3 bucket where Config stores conformance pack templates. This field is optional. If used, it must be prefixed with awsconfigconforms.
  --delivery-s3-key-prefix: string # The prefix for the Amazon S3 bucket. This field is optional.
  --conformance-pack-input-parameters: list # A list of ConformancePackInputParameter objects. — item shape: {ParameterName: string, ParameterValue: string}
  --excluded-accounts: list<string> # A list of Amazon Web Services accounts to be excluded from an organization conformance pack while deploying a conformance pack.
]: any -> oneof<record<OrganizationConformancePackArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.PutOrganizationConformancePack")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"OrganizationConformancePackName": $organization_conformance_pack_name, "TemplateS3Uri": $template_s3_uri, "TemplateBody": $template_body, "DeliveryS3Bucket": $delivery_s3_bucket, "DeliveryS3KeyPrefix": $delivery_s3_key_prefix, "ConformancePackInputParameters": $conformance_pack_input_parameters, "ExcludedAccounts": $excluded_accounts} | compact
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

# Adds or updates the remediation configuration with a specific Config rule with the selected target or action. The API creates the RemediationConfiguration object for the Config rule. The Config rule must already exist for you to add a remediation configuration. The target (SSM document) must exist and have permissions to use the target. If you make backward incompatible changes to the SSM document, you must call this again to ensure the remediations can run. This API does not support adding remediation configurations for service-linked Config Rules such as Organization Config rules, the rules deployed by conformance packs, and rules deployed by Amazon Web Services Security Hub. For manual remediation configuration, you need to provide a value for automationAssumeRole or use a value in the assumeRolefield to remediate your resources. The SSM automation document can use either as long as it maps to a valid parameter. However, for automatic remediation configuration, the only valid assumeRole field value is AutomationAssumeRole and you need to provide a value for AutomationAssumeRole to remediate your resources.
#
# POST /
# operationId: PutRemediationConfigurations
export def "put-remediation-configurations" [
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
  --x-amz-target: string@x-amz-target-completer-78 # required
  remediation_configurations: list # A list of remediation configuration objects. — item shape: {ConfigRuleName: string, TargetType: "SSM_DOCUMENT", TargetId: string, TargetVersion?: string, Parameters?: record, ResourceType?: string, Automatic?: bool, ExecutionControls?: record, MaximumAutomaticAttempts?: int, RetryAttemptSeconds?: int, Arn?: string, CreatedByService?: string}
]: any -> oneof<record<FailedBatches: table<FailureMessage: string, FailedItems: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.PutRemediationConfigurations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RemediationConfigurations": $remediation_configurations} | compact
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

# A remediation exception is when a specified resource is no longer considered for auto-remediation. This API adds a new exception or updates an existing exception for a specified resource with a specified Config rule. Config generates a remediation exception when a problem occurs running a remediation action for a specified resource. Remediation exceptions blocks auto-remediation until the exception is cleared. When placing an exception on an Amazon Web Services resource, it is recommended that remediation is set as manual remediation until the given Config rule for the specified resource evaluates the resource as NON_COMPLIANT. Once the resource has been evaluated as NON_COMPLIANT, you can add remediation exceptions and change the remediation type back from Manual to Auto if you want to use auto-remediation. Otherwise, using auto-remediation before a NON_COMPLIANT evaluation result can delete resources before the exception is applied. Placing an exception can only be performed on resources that are NON_COMPLIANT. If you use this API for COMPLIANT resources or resources that are NOT_APPLICABLE, a remediation exception will not be generated. For more information on the conditions that initiate the possible Config evaluation results, see Concepts | Config Rules (https://docs.aws.amazon.com/config/latest/developerguide/config-concepts.html#aws-config-rules) in the Config Developer Guide.
#
# POST /
# operationId: PutRemediationExceptions
export def "put-remediation-exceptions" [
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
  --x-amz-target: string@x-amz-target-completer-79 # required
  config_rule_name: string # The name of the Config rule for which you want to create remediation exception.
  resource_keys: list # An exception list of resource exception keys to be processed with the current request. Config adds exception for each resource key. For example, Config adds 3 exceptions for 3 resource keys. — item shape: {ResourceType?: string, ResourceId?: string}
  --message: string # The message contains an explanation of the exception.
  --expiration-time: string # The exception is automatically deleted after the expiration date. (format: date-time)
]: any -> oneof<record<FailedBatches: table<FailureMessage: string, FailedItems: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.PutRemediationExceptions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigRuleName": $config_rule_name, "ResourceKeys": $resource_keys, "Message": $message, "ExpirationTime": $expiration_time} | compact
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

# Records the configuration state for the resource provided in the request. The configuration state of a resource is represented in Config as Configuration Items. Once this API records the configuration item, you can retrieve the list of configuration items for the custom resource type using existing Config APIs. The custom resource type must be registered with CloudFormation. This API accepts the configuration item registered with CloudFormation. When you call this API, Config only stores configuration state of the resource provided in the request. This API does not change or remediate the configuration of the resource. Write-only schema properites are not recorded as part of the published configuration item.
#
# POST /
# operationId: PutResourceConfig
export def "put-resource-config" [
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
  resource_type: string # The type of the resource. The custom resource type must be registered with CloudFormation. You cannot use the organization names “amzn”, “amazon”, “alexa”, “custom” with custom resource types. It is the first part of the ResourceType up to the first ::.
  schema_version_id: string # Version of the schema registered for the ResourceType in CloudFormation.
  resource_id: string # Unique identifier of the resource.
  --resource-name: string # Name of the resource.
  configuration: string # The configuration object of the resource in valid JSON format. It must match the schema registered with CloudFormation. The configuration JSON must not exceed 64 KB.
  --tags: record # Tags associated with the resource. This field is not to be confused with the Amazon Web Services-wide tag feature for Amazon Web Services resources. Tags for PutResourceConfig are tags that you supply for the configuration items of your custom resources.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.PutResourceConfig")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceType": $resource_type, "SchemaVersionId": $schema_version_id, "ResourceId": $resource_id, "ResourceName": $resource_name, "Configuration": $configuration, "Tags": $tags} | compact
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

# Creates and updates the retention configuration with details about retention period (number of days) that Config stores your historical information. The API creates the RetentionConfiguration object and names the object as default. When you have a RetentionConfiguration object named default, calling the API modifies the default object. Currently, Config supports only one retention configuration per region in your account.
#
# POST /
# operationId: PutRetentionConfiguration
export def "put-retention-configuration" [
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
  retention_period_in_days: int # Number of days Config stores your historical information. Currently, only applicable to the configuration item history.
]: any -> oneof<record<RetentionConfiguration: record<Name: string, RetentionPeriodInDays: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.PutRetentionConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RetentionPeriodInDays": $retention_period_in_days} | compact
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

# Saves a new query or updates an existing saved query. The QueryName must be unique for a single Amazon Web Services account and a single Amazon Web Services Region. You can create upto 300 queries in a single Amazon Web Services account and a single Amazon Web Services Region. PutStoredQuery is an idempotent API. Subsequent requests won’t create a duplicate resource if one was already created. If a following request has different tags values, Config will ignore these differences and treat it as an idempotent request of the previous. In this case, tags will not be updated, even if they are different.
#
# POST /
# operationId: PutStoredQuery
export def "put-stored-query" [
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
  stored_query: record # Provides the details of a stored query. — shape: {QueryId?: string, QueryArn?: string, QueryName: string, Description?: string, Expression?: string}
  --tags: list # A list of Tags object. — item shape: {Key?: string, Value?: string}
]: any -> oneof<record<QueryArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.PutStoredQuery")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"StoredQuery": $stored_query, "Tags": $tags} | compact
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

# Accepts a structured query language (SQL) SELECT command and an aggregator to query configuration state of Amazon Web Services resources across multiple accounts and regions, performs the corresponding search, and returns resource configurations matching the properties. For more information about query components, see the Query Components (https://docs.aws.amazon.com/config/latest/developerguide/query-components.html) section in the Config Developer Guide. If you run an aggregation query (i.e., using GROUP BY or using aggregate functions such as COUNT; e.g., SELECT resourceId, COUNT(*) WHERE resourceType = 'AWS::IAM::Role' GROUP BY resourceId) and do not specify the MaxResults or the Limit query parameters, the default page size is set to 500. If you run a non-aggregation query (i.e., not using GROUP BY or aggregate function; e.g., SELECT * WHERE resourceType = 'AWS::IAM::Role') and do not specify the MaxResults or the Limit query parameters, the default page size is set to 25.
#
# POST /
# operationId: SelectAggregateResourceConfig
export def "select-aggregate-resource-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-83 # required
  expression: string # The SQL query SELECT command.
  configuration_aggregator_name: string # The name of the configuration aggregator.
  --limit-body: int # The maximum number of query results returned on each page. (body field)
  --max-results: int # The maximum number of query results returned on each page. Config also allows the Limit request parameter.
  --next-token-body: string # The nextToken string returned in a previous request that you use to request the next page of results in a paginated response. (body field)
]: any -> oneof<record<Results: list<string>, QueryInfo: record<SelectFields: list<record>>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.SelectAggregateResourceConfig")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Expression": $expression, "ConfigurationAggregatorName": $configuration_aggregator_name, "Limit": $limit_body, "MaxResults": $max_results, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Accepts a structured query language (SQL) SELECT command, performs the corresponding search, and returns resource configurations matching the properties. For more information about query components, see the Query Components (https://docs.aws.amazon.com/config/latest/developerguide/query-components.html) section in the Config Developer Guide.
#
# POST /
# operationId: SelectResourceConfig
export def "select-resource-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-84 # required
  expression: string # The SQL query SELECT command.
  --limit-body: int # The maximum number of query results returned on each page. (body field)
  --next-token-body: string # The nextToken string returned in a previous request that you use to request the next page of results in a paginated response. (body field)
]: any -> oneof<record<Results: list<string>, QueryInfo: record<SelectFields: list<record>>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.SelectResourceConfig")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Expression": $expression, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Runs an on-demand evaluation for the specified Config rules against the last known configuration state of the resources. Use StartConfigRulesEvaluation when you want to test that a rule you updated is working as expected. StartConfigRulesEvaluation does not re-record the latest configuration state for your resources. It re-runs an evaluation against the last known state of your resources. You can specify up to 25 Config rules per request. An existing StartConfigRulesEvaluation call for the specified rules must complete before you can call the API again. If you chose to have Config stream to an Amazon SNS topic, you will receive a ConfigRuleEvaluationStarted notification when the evaluation starts. You don't need to call the StartConfigRulesEvaluation API to run an evaluation for a new rule. When you create a rule, Config evaluates your resources against the rule automatically. The StartConfigRulesEvaluation API is useful if you want to run on-demand evaluations, such as the following example: You have a custom rule that evaluates your IAM resources every 24 hours. You update your Lambda function to add additional conditions to your rule. Instead of waiting for the next periodic evaluation, you call the StartConfigRulesEvaluation API. Config invokes your Lambda function and evaluates your IAM resources. Your custom rule will still run periodic evaluations every 24 hours.
#
# POST /
# operationId: StartConfigRulesEvaluation
export def "start-config-rules-evaluation" [
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
  --config-rule-names: list<string> # The list of names of Config rules that you want to run evaluations for.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.StartConfigRulesEvaluation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigRuleNames": $config_rule_names} | compact
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

# Starts recording configurations of the Amazon Web Services resources you have selected to record in your Amazon Web Services account. You must have created at least one delivery channel to successfully start the configuration recorder.
#
# POST /
# operationId: StartConfigurationRecorder
export def "start-configuration-recorder" [
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
  configuration_recorder_name: string # The name of the recorder object that records each configuration change made to the resources.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.StartConfigurationRecorder")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigurationRecorderName": $configuration_recorder_name} | compact
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

# Runs an on-demand remediation for the specified Config rules against the last known remediation configuration. It runs an execution against the current state of your resources. Remediation execution is asynchronous. You can specify up to 100 resource keys per request. An existing StartRemediationExecution call for the specified resource keys must complete before you can call the API again.
#
# POST /
# operationId: StartRemediationExecution
export def "start-remediation-execution" [
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
  config_rule_name: string # The list of names of Config rules that you want to run remediation execution for.
  resource_keys: list # A list of resource keys to be processed with the current request. Each element in the list consists of the resource type and resource ID. — item shape: {resourceType: "AWS::EC2::CustomerGateway"|"AWS::EC2::EIP"|"AWS::EC2::Host"|"AWS::EC2::Instance"|"AWS::EC2::InternetGateway"|"AWS::EC2::NetworkAcl"|"AWS::EC2::NetworkInterface"|"AWS::EC2::RouteTable"|"AWS::EC2::SecurityGroup"|"AWS::EC2::Subnet"|"AWS::CloudTrail::Trail"|"AWS::EC2::Volume"|"AWS::EC2::VPC"|"AWS::EC2::VPNConnection"|"AWS::EC2::VPNGateway"|"AWS::EC2::RegisteredHAInstance"|"AWS::EC2::NatGateway"|"AWS::EC2::EgressOnlyInternetGateway"|"AWS::EC2::VPCEndpoint"|"AWS::EC2::VPCEndpointService"|"AWS::EC2::FlowLog"|"AWS::EC2::VPCPeeringConnection"|"AWS::Elasticsearch::Domain"|"AWS::IAM::Group"|"AWS::IAM::Policy"|"AWS::IAM::Role"|"AWS::IAM::User"|"AWS::ElasticLoadBalancingV2::LoadBalancer"|"AWS::ACM::Certificate"|"AWS::RDS::DBInstance"|"AWS::RDS::DBSubnetGroup"|"AWS::RDS::DBSecurityGroup"|"AWS::RDS::DBSnapshot"|"AWS::RDS::DBCluster"|"AWS::RDS::DBClusterSnapshot"|"AWS::RDS::EventSubscription"|"AWS::S3::Bucket"|"AWS::S3::AccountPublicAccessBlock"|"AWS::Redshift::Cluster"|"AWS::Redshift::ClusterSnapshot"|"AWS::Redshift::ClusterParameterGroup"|"AWS::Redshift::ClusterSecurityGroup"|"AWS::Redshift::ClusterSubnetGroup"|"AWS::Redshift::EventSubscription"|"AWS::SSM::ManagedInstanceInventory"|"AWS::CloudWatch::Alarm"|"AWS::CloudFormation::Stack"|"AWS::ElasticLoadBalancing::LoadBalancer"|"AWS::AutoScaling::AutoScalingGroup"|"AWS::AutoScaling::LaunchConfiguration"|"AWS::AutoScaling::ScalingPolicy"|"AWS::AutoScaling::ScheduledAction"|"AWS::DynamoDB::Table"|"AWS::CodeBuild::Project"|"AWS::WAF::RateBasedRule"|"AWS::WAF::Rule"|"AWS::WAF::RuleGroup"|"AWS::WAF::WebACL"|"AWS::WAFRegional::RateBasedRule"|"AWS::WAFRegional::Rule"|"AWS::WAFRegional::RuleGroup"|"AWS::WAFRegional::WebACL"|"AWS::CloudFront::Distribution"|"AWS::CloudFront::StreamingDistribution"|"AWS::Lambda::Function"|"AWS::NetworkFirewall::Firewall"|"AWS::NetworkFirewall::FirewallPolicy"|"AWS::NetworkFirewall::RuleGroup"|"AWS::ElasticBeanstalk::Application"|"AWS::ElasticBeanstalk::ApplicationVersion"|"AWS::ElasticBeanstalk::Environment"|"AWS::WAFv2::WebACL"|"AWS::WAFv2::RuleGroup"|"AWS::WAFv2::IPSet"|"AWS::WAFv2::RegexPatternSet"|"AWS::WAFv2::ManagedRuleSet"|"AWS::XRay::EncryptionConfig"|"AWS::SSM::AssociationCompliance"|"AWS::SSM::PatchCompliance"|"AWS::Shield::Protection"|"AWS::ShieldRegional::Protection"|"AWS::Config::ConformancePackCompliance"|"AWS::Config::ResourceCompliance"|"AWS::ApiGateway::Stage"|"AWS::ApiGateway::RestApi"|"AWS::ApiGatewayV2::Stage"|"AWS::ApiGatewayV2::Api"|"AWS::CodePipeline::Pipeline"|"AWS::ServiceCatalog::CloudFormationProvisionedProduct"|"AWS::ServiceCatalog::CloudFormationProduct"|"AWS::ServiceCatalog::Portfolio"|"AWS::SQS::Queue"|"AWS::KMS::Key"|"AWS::QLDB::Ledger"|"AWS::SecretsManager::Secret"|"AWS::SNS::Topic"|"AWS::SSM::FileData"|"AWS::Backup::BackupPlan"|"AWS::Backup::BackupSelection"|"AWS::Backup::BackupVault"|"AWS::Backup::RecoveryPoint"|"AWS::ECR::Repository"|"AWS::ECS::Cluster"|"AWS::ECS::Service"|"AWS::ECS::TaskDefinition"|"AWS::EFS::AccessPoint"|"AWS::EFS::FileSystem"|"AWS::EKS::Cluster"|"AWS::OpenSearch::Domain"|"AWS::EC2::TransitGateway"|"AWS::Kinesis::Stream"|"AWS::Kinesis::StreamConsumer"|"AWS::CodeDeploy::Application"|"AWS::CodeDeploy::DeploymentConfig"|"AWS::CodeDeploy::DeploymentGroup"|"AWS::EC2::LaunchTemplate"|"AWS::ECR::PublicRepository"|"AWS::GuardDuty::Detector"|"AWS::EMR::SecurityConfiguration"|"AWS::SageMaker::CodeRepository"|"AWS::Route53Resolver::ResolverEndpoint"|"AWS::Route53Resolver::ResolverRule"|"AWS::Route53Resolver::ResolverRuleAssociation"|"AWS::DMS::ReplicationSubnetGroup"|"AWS::DMS::EventSubscription"|"AWS::MSK::Cluster"|"AWS::StepFunctions::Activity"|"AWS::WorkSpaces::Workspace"|"AWS::WorkSpaces::ConnectionAlias"|"AWS::SageMaker::Model"|"AWS::ElasticLoadBalancingV2::Listener"|"AWS::StepFunctions::StateMachine"|"AWS::Batch::JobQueue"|"AWS::Batch::ComputeEnvironment"|"AWS::AccessAnalyzer::Analyzer"|"AWS::Athena::WorkGroup"|"AWS::Athena::DataCatalog"|"AWS::Detective::Graph"|"AWS::GlobalAccelerator::Accelerator"|"AWS::GlobalAccelerator::EndpointGroup"|"AWS::GlobalAccelerator::Listener"|"AWS::EC2::TransitGatewayAttachment"|"AWS::EC2::TransitGatewayRouteTable"|"AWS::DMS::Certificate"|"AWS::AppConfig::Application"|"AWS::AppSync::GraphQLApi"|"AWS::DataSync::LocationSMB"|"AWS::DataSync::LocationFSxLustre"|"AWS::DataSync::LocationS3"|"AWS::DataSync::LocationEFS"|"AWS::DataSync::Task"|"AWS::DataSync::LocationNFS"|"AWS::EC2::NetworkInsightsAccessScopeAnalysis"|"AWS::EKS::FargateProfile"|"AWS::Glue::Job"|"AWS::GuardDuty::ThreatIntelSet"|"AWS::GuardDuty::IPSet"|"AWS::SageMaker::Workteam"|"AWS::SageMaker::NotebookInstanceLifecycleConfig"|"AWS::ServiceDiscovery::Service"|"AWS::ServiceDiscovery::PublicDnsNamespace"|"AWS::SES::ContactList"|"AWS::SES::ConfigurationSet"|"AWS::Route53::HostedZone"|"AWS::IoTEvents::Input"|"AWS::IoTEvents::DetectorModel"|"AWS::IoTEvents::AlarmModel"|"AWS::ServiceDiscovery::HttpNamespace"|"AWS::Events::EventBus"|"AWS::ImageBuilder::ContainerRecipe"|"AWS::ImageBuilder::DistributionConfiguration"|"AWS::ImageBuilder::InfrastructureConfiguration"|"AWS::DataSync::LocationObjectStorage"|"AWS::DataSync::LocationHDFS"|"AWS::Glue::Classifier"|"AWS::Route53RecoveryReadiness::Cell"|"AWS::Route53RecoveryReadiness::ReadinessCheck"|"AWS::ECR::RegistryPolicy"|"AWS::Backup::ReportPlan"|"AWS::Lightsail::Certificate"|"AWS::RUM::AppMonitor"|"AWS::Events::Endpoint"|"AWS::SES::ReceiptRuleSet"|"AWS::Events::Archive"|"AWS::Events::ApiDestination"|"AWS::Lightsail::Disk"|"AWS::FIS::ExperimentTemplate"|"AWS::DataSync::LocationFSxWindows"|"AWS::SES::ReceiptFilter"|"AWS::GuardDuty::Filter"|"AWS::SES::Template"|"AWS::AmazonMQ::Broker"|"AWS::AppConfig::Environment"|"AWS::AppConfig::ConfigurationProfile"|"AWS::Cloud9::EnvironmentEC2"|"AWS::EventSchemas::Registry"|"AWS::EventSchemas::RegistryPolicy"|"AWS::EventSchemas::Discoverer"|"AWS::FraudDetector::Label"|"AWS::FraudDetector::EntityType"|"AWS::FraudDetector::Variable"|"AWS::FraudDetector::Outcome"|"AWS::IoT::Authorizer"|"AWS::IoT::SecurityProfile"|"AWS::IoT::RoleAlias"|"AWS::IoT::Dimension"|"AWS::IoTAnalytics::Datastore"|"AWS::Lightsail::Bucket"|"AWS::Lightsail::StaticIp"|"AWS::MediaPackage::PackagingGroup"|"AWS::Route53RecoveryReadiness::RecoveryGroup"|"AWS::ResilienceHub::ResiliencyPolicy"|"AWS::Transfer::Workflow"|"AWS::EKS::IdentityProviderConfig"|"AWS::EKS::Addon"|"AWS::Glue::MLTransform"|"AWS::IoT::Policy"|"AWS::IoT::MitigationAction"|"AWS::IoTTwinMaker::Workspace"|"AWS::IoTTwinMaker::Entity"|"AWS::IoTAnalytics::Dataset"|"AWS::IoTAnalytics::Pipeline"|"AWS::IoTAnalytics::Channel"|"AWS::IoTSiteWise::Dashboard"|"AWS::IoTSiteWise::Project"|"AWS::IoTSiteWise::Portal"|"AWS::IoTSiteWise::AssetModel"|"AWS::IVS::Channel"|"AWS::IVS::RecordingConfiguration"|"AWS::IVS::PlaybackKeyPair"|"AWS::KinesisAnalyticsV2::Application"|"AWS::RDS::GlobalCluster"|"AWS::S3::MultiRegionAccessPoint"|"AWS::DeviceFarm::TestGridProject"|"AWS::Budgets::BudgetsAction"|"AWS::Lex::Bot"|"AWS::CodeGuruReviewer::RepositoryAssociation"|"AWS::IoT::CustomMetric"|"AWS::Route53Resolver::FirewallDomainList"|"AWS::RoboMaker::RobotApplicationVersion"|"AWS::EC2::TrafficMirrorSession"|"AWS::IoTSiteWise::Gateway"|"AWS::Lex::BotAlias"|"AWS::LookoutMetrics::Alert"|"AWS::IoT::AccountAuditConfiguration"|"AWS::EC2::TrafficMirrorTarget"|"AWS::S3::StorageLens"|"AWS::IoT::ScheduledAudit"|"AWS::Events::Connection"|"AWS::EventSchemas::Schema"|"AWS::MediaPackage::PackagingConfiguration"|"AWS::KinesisVideo::SignalingChannel"|"AWS::AppStream::DirectoryConfig"|"AWS::LookoutVision::Project"|"AWS::Route53RecoveryControl::Cluster"|"AWS::Route53RecoveryControl::SafetyRule"|"AWS::Route53RecoveryControl::ControlPanel"|"AWS::Route53RecoveryControl::RoutingControl"|"AWS::Route53RecoveryReadiness::ResourceSet"|"AWS::RoboMaker::SimulationApplication"|"AWS::RoboMaker::RobotApplication"|"AWS::HealthLake::FHIRDatastore"|"AWS::Pinpoint::Segment"|"AWS::Pinpoint::ApplicationSettings"|"AWS::Events::Rule"|"AWS::EC2::DHCPOptions"|"AWS::EC2::NetworkInsightsPath"|"AWS::EC2::TrafficMirrorFilter"|"AWS::EC2::IPAM"|"AWS::IoTTwinMaker::Scene"|"AWS::NetworkManager::TransitGatewayRegistration"|"AWS::CustomerProfiles::Domain"|"AWS::AutoScaling::WarmPool"|"AWS::Connect::PhoneNumber", ... (1 more fields)}
]: any -> oneof<record<FailureMessage: string, FailedItems: table<resourceType: string, resourceId: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.StartRemediationExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigRuleName": $config_rule_name, "ResourceKeys": $resource_keys} | compact
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

# Runs an on-demand evaluation for the specified resource to determine whether the resource details will comply with configured Config rules. You can also use it for evaluation purposes. Config recommends using an evaluation context. It runs an execution against the resource details with all of the Config rules in your account that match with the specified proactive mode and resource type. Ensure you have the cloudformation:DescribeType role setup to validate the resource type schema. You can find the Resource type schema (https://docs.aws.amazon.com/cloudformation-cli/latest/userguide/resource-type-schema.html) in "Amazon Web Services public extensions" within the CloudFormation registry or with the following CLI commmand: aws cloudformation describe-type --type-name "AWS::S3::Bucket" --type RESOURCE. For more information, see Managing extensions through the CloudFormation registry (https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/registry.html#registry-view) and Amazon Web Services resource and property types reference (https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html) in the CloudFormation User Guide.
#
# POST /
# operationId: StartResourceEvaluation
export def "start-resource-evaluation" [
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
  resource_details: record # Returns information about the resource being evaluated. — shape: {ResourceId: string, ResourceType: string, ResourceConfiguration: string, ResourceConfigurationSchemaType?: "CFN_RESOURCE_SCHEMA"}
  --evaluation-context: record # Use EvaluationContext to group independently initiated proactive resource evaluations. For example, CFN Stack. If you want to check just a resource definition, you do not need to provide evaluation context. — shape: {EvaluationContextIdentifier?: string}
  evaluation_mode: string@evaluation-mode-completer # The mode of an evaluation. The valid values for this API are DETECTIVE and PROACTIVE.
  --evaluation-timeout: int # The timeout for an evaluation. The default is 900 seconds. You cannot specify a number greater than 3600. If you specify 0, Config uses the default.
  --client-token: string # A client token is a unique, case-sensitive string of up to 64 ASCII characters. To make an idempotent API request using one of these actions, specify a client token in the request. Avoid reusing the same client token for other API requests. If you retry a request that completed successfully using the same client token and the same parameters, the retry succeeds without performing any further actions. If you retry a successful request using the same client token, but one or more of the parameters are different, other than the Region or Availability Zone, the retry fails with an IdempotentParameterMismatch error.
]: any -> oneof<record<ResourceEvaluationId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.StartResourceEvaluation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceDetails": $resource_details, "EvaluationContext": $evaluation_context, "EvaluationMode": $evaluation_mode, "EvaluationTimeout": $evaluation_timeout, "ClientToken": $client_token} | compact
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

# Stops recording configurations of the Amazon Web Services resources you have selected to record in your Amazon Web Services account.
#
# POST /
# operationId: StopConfigurationRecorder
export def "stop-configuration-recorder" [
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
  configuration_recorder_name: string # The name of the recorder object that records each configuration change made to the resources.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.StopConfigurationRecorder")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ConfigurationRecorderName": $configuration_recorder_name} | compact
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

# Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. If existing tags are specified, however, then their values will be updated. When a resource is deleted, the tags associated with that resource are deleted as well.
#
# POST /
# operationId: TagResource
export def "tag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-90 # required
  resource_arn: string # The Amazon Resource Name (ARN) that identifies the resource for which to list the tags. Currently, the supported resources are ConfigRule, ConfigurationAggregator and AggregatorAuthorization.
  tags: list # An array of tag object. — item shape: {Key?: string, Value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.TagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Tags": $tags} | compact
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

# Deletes specified tags from a resource.
#
# POST /
# operationId: UntagResource
export def "untag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-91 # required
  resource_arn: string # The Amazon Resource Name (ARN) that identifies the resource for which to list the tags. Currently, the supported resources are ConfigRule, ConfigurationAggregator and AggregatorAuthorization.
  tag_keys: list<string> # The keys of the tags to be removed.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "StarlingDoveService.UntagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "TagKeys": $tag_keys} | compact
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
