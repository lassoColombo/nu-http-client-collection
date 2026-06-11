# Available clients

_This file is auto-generated from `clients.yaml` by `scripts/generate.nu`. Do not edit by hand._

## ai

| Client                                 | Type    | Source                                                                                                                                                |
| -------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| [openai](clients/ai/openai.nu)         | openapi | <specs/openai.yaml>                                                                                                                                   |
| [cohere](clients/ai/cohere.nu)         | openapi | <https://docs.cohere.com/openapi/cohere-api.json>                                                                                                     |
| [elevenlabs](clients/ai/elevenlabs.nu) | openapi | <https://api.elevenlabs.io/openapi.json>                                                                                                              |
| [assemblyai](clients/ai/assemblyai.nu) | openapi | <https://www.assemblyai.com/docs/openapi.json>                                                                                                        |
| [deepgram](clients/ai/deepgram.nu)     | openapi | <https://developers.deepgram.com/reference/openapi.json>                                                                                              |
| [xai](clients/ai/xai.nu)               | openapi | <https://docs.x.ai/openapi.json>                                                                                                                      |
| [deepinfra](clients/ai/deepinfra.nu)   | openapi | <https://api.deepinfra.com/openapi.json>                                                                                                              |
| [anthropic](clients/ai/anthropic.nu)   | openapi | <https://storage.googleapis.com/stainless-sdk-openapi-specs/anthropic/anthropic-5ce93251152bd7c4c288dacdf5a445383825ba50bc472ff9e9821ee9455e3564.yml> |
| [groq](clients/ai/groq.nu)             | openapi | <https://storage.googleapis.com/stainless-sdk-openapi-specs/groqcloud/groqcloud-0298a69b7d74303a353e8a586d85e5cc769b9560920487fadfe773c0100af249.yml> |
| [mistral](clients/ai/mistral.nu)       | openapi | <https://docs.mistral.ai/openapi.yaml>                                                                                                                |
| [jina](clients/ai/jina.nu)             | openapi | <https://api.jina.ai/openapi.json>                                                                                                                    |

## analytics

| Client                                                                        | Type    | Source                                                                             |
| ----------------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------- |
| [google-analytics](clients/analytics/google-analytics.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/analytics/v3/openapi.json>          |
| [google-analytics-data](clients/analytics/google-analytics-data.nu)           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/analyticsdata/v1beta/openapi.json>  |
| [google-analytics-admin](clients/analytics/google-analytics-admin.nu)         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/analyticsadmin/v1beta/openapi.json> |
| [posthog](clients/analytics/posthog.nu)                                       | openapi | <https://us.posthog.com/api/schema/>                                               |
| [google-analytics-reporting](clients/analytics/google-analytics-reporting.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/analyticsreporting/v4/openapi.json> |
| [hubspot-analytics](clients/analytics/hubspot-analytics.nu)                   | openapi | <https://api.apis.guru/v2/specs/hubapi.com/analytics/v3/openapi.json>              |
| [youtube-analytics](clients/analytics/youtube-analytics.nu)                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/youtubeAnalytics/v2/openapi.json>   |

## anime

| Client                                            | Type    | Source                                                                                        |
| ------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------- |
| [anilist](clients/anime/anilist.nu)               | graphql | <https://graphql.anilist.co>                                                                  |
| [jikan](clients/anime/jikan.nu)                   | openapi | <https://raw.githubusercontent.com/jikan-me/jikan-rest/master/storage/api-docs/api-docs.json> |
| [kitsu](clients/anime/kitsu.nu)                   | graphql | <https://kitsu.io/api/graphql>                                                                |
| [bangumi](clients/anime/bangumi.nu)               | openapi | <https://raw.githubusercontent.com/bangumi/api/master/open-api/api.yml>                       |
| [nekosapi](clients/anime/nekosapi.nu)             | openapi | <https://api.nekosapi.com/openapi.json>                                                       |
| [dragonball-api](clients/anime/dragonball-api.nu) | openapi | <https://dragonball-api.com/api-docs-json>                                                    |
| [ghibli](clients/anime/ghibli.nu)                 | openapi | <https://ghibliapi.vercel.app/swagger.yaml>                                                   |
| [mangadex](clients/anime/mangadex.nu)             | openapi | <https://api.mangadex.org/docs/static/api.yaml>                                               |
| [animethemes](clients/anime/animethemes.nu)       | graphql | <https://graphql.animethemes.moe>                                                             |

## calendar

| Client                                                                   | Type    | Source                                                                                                       |
| ------------------------------------------------------------------------ | ------- | ------------------------------------------------------------------------------------------------------------ |
| [google-calendar](clients/calendar/google-calendar.nu)                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/calendar/v3/openapi.json>                                     |
| [onsched-consumer](clients/calendar/onsched-consumer.nu)                 | openapi | <https://api.apis.guru/v2/specs/onsched.com/consumer/v1/openapi.json>                                        |
| [onsched-setup](clients/calendar/onsched-setup.nu)                       | openapi | <https://api.apis.guru/v2/specs/onsched.com/setup/v1/openapi.json>                                           |
| [onsched-utility](clients/calendar/onsched-utility.nu)                   | openapi | <https://api.apis.guru/v2/specs/onsched.com/utility/v1/openapi.json>                                         |
| [hetras-booking](clients/calendar/hetras-booking.nu)                     | openapi | <https://api.apis.guru/v2/specs/hetras-certification.net/booking/v0/swagger.json>                            |
| [gotomeeting](clients/calendar/gotomeeting.nu)                           | openapi | <https://api.apis.guru/v2/specs/citrixonline.com/gotomeeting/1.0.0/swagger.json>                             |
| [microsoft-graph-calendar](clients/calendar/microsoft-graph-calendar.nu) | openapi | <https://raw.githubusercontent.com/microsoftgraph/msgraph-sdk-powershell/main/openApiDocs/v1.0/Calendar.yml> |
| [microsoft-graph-bookings](clients/calendar/microsoft-graph-bookings.nu) | openapi | <https://raw.githubusercontent.com/microsoftgraph/msgraph-sdk-powershell/main/openApiDocs/v1.0/Bookings.yml> |

## cdn

| Client                                                          | Type    | Source                                                                                                   |
| --------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------- |
| [cloudflare](clients/cdn/cloudflare.nu)                         | openapi | <https://raw.githubusercontent.com/cloudflare/api-schemas/main/openapi.json>                             |
| [aws-cloudfront](clients/cdn/aws-cloudfront.nu)                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/cloudfront/2020-05-31/openapi.json>                        |
| [aws-global-accelerator](clients/cdn/aws-global-accelerator.nu) | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/globalaccelerator/2018-08-08/openapi.json>                 |
| [azure-cdn](clients/cdn/azure-cdn.nu)                           | openapi | <https://api.apis.guru/v2/specs/azure.com/cdn/2019-06-15-preview/swagger.json>                           |
| [azure-cdn-waf](clients/cdn/azure-cdn-waf.nu)                   | openapi | <https://api.apis.guru/v2/specs/azure.com/cdn-cdnwebapplicationfirewall/2019-06-15-preview/swagger.json> |
| [vercel](clients/cdn/vercel.nu)                                 | openapi | <https://openapi.vercel.sh/>                                                                             |
| [bunny](clients/cdn/bunny.nu)                                   | openapi | <https://core-api-public-docs.b-cdn.net/docs/v3/public.json>                                             |
| [gcore-cdn](clients/cdn/gcore-cdn.nu)                           | openapi | <https://gcore.com/docs/api-reference/services_docs_mintlify/cdn_api.yaml>                               |
| [gcore-fastedge](clients/cdn/gcore-fastedge.nu)                 | openapi | <https://gcore.com/docs/api-reference/services_docs_mintlify/fastedge_api.yaml>                          |

## chat

| Client                                                       | Type    | Source                                                                                                    |
| ------------------------------------------------------------ | ------- | --------------------------------------------------------------------------------------------------------- |
| [slack](clients/chat/slack.nu)                               | openapi | <https://raw.githubusercontent.com/slackapi/slack-api-specs/master/web-api/slack_web_openapi_v2.json>     |
| [discord](clients/chat/discord.nu)                           | openapi | <https://raw.githubusercontent.com/discord/discord-api-spec/main/specs/openapi.json>                      |
| [line](clients/chat/line.nu)                                 | openapi | <https://raw.githubusercontent.com/line/line-openapi/main/messaging-api.yml>                              |
| [intercom](clients/chat/intercom.nu)                         | openapi | <https://raw.githubusercontent.com/intercom/Intercom-OpenAPI/main/descriptions/2.11/api.intercom.io.yaml> |
| [zoom](clients/chat/zoom.nu)                                 | openapi | <https://api.apis.guru/v2/specs/zoom.us/2.0.0/openapi.yaml>                                               |
| [chatwoot](clients/chat/chatwoot.nu)                         | openapi | <https://raw.githubusercontent.com/chatwoot/chatwoot/develop/swagger/swagger.json>                        |
| [telegram-bot](clients/chat/telegram-bot.nu)                 | openapi | <https://api.apis.guru/v2/specs/telegram.org/5.0.0/openapi.json>                                          |
| [zulip](clients/chat/zulip.nu)                               | openapi | <https://raw.githubusercontent.com/zulip/zulip/main/zerver/openapi/zulip.yaml>                            |
| [twilio-conversations](clients/chat/twilio-conversations.nu) | openapi | <https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_conversations_v1.json>         |

## ci-cd

| Client                                                    | Type    | Source                                                                              |
| --------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------- |
| [circleci](clients/ci-cd/circleci.nu)                     | openapi | <https://api.apis.guru/v2/specs/circleci.com/v1/openapi.json>                       |
| [aws-codebuild](clients/ci-cd/aws-codebuild.nu)           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/codebuild/2016-10-06/openapi.json>    |
| [aws-codedeploy](clients/ci-cd/aws-codedeploy.nu)         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/codedeploy/2014-10-06/openapi.json>   |
| [aws-codepipeline](clients/ci-cd/aws-codepipeline.nu)     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/codepipeline/2015-07-09/openapi.json> |
| [google-cloudbuild](clients/ci-cd/google-cloudbuild.nu)   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/cloudbuild/v1/openapi.json>          |
| [google-clouddeploy](clients/ci-cd/google-clouddeploy.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/clouddeploy/v1/openapi.json>         |
| [octopus-deploy](clients/ci-cd/octopus-deploy.nu)         | openapi | <https://demo.octopus.app/api/swagger.json>                                         |

## cloud

| Client                                                    | Type    | Source                                                                                                  |
| --------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------- |
| [digitalocean](clients/cloud/digitalocean.nu)             | openapi | <https://raw.githubusercontent.com/digitalocean/openapi/main/specification/DigitalOcean-public.v2.yaml> |
| [exoscale](clients/cloud/exoscale.nu)                     | openapi | <https://openapi-v2.exoscale.com/source.json>                                                           |
| [fly-machines](clients/cloud/fly-machines.nu)             | openapi | <https://docs.machines.dev/swagger/doc.json>                                                            |
| [netlify](clients/cloud/netlify.nu)                       | openapi | <https://open-api.netlify.com/openapi.json>                                                             |
| [openshift-clusters](clients/cloud/openshift-clusters.nu) | openapi | <https://api.openshift.com/api/clusters_mgmt/v1/openapi>                                                |
| [openshift-accounts](clients/cloud/openshift-accounts.nu) | openapi | <https://api.openshift.com/api/accounts_mgmt/v1/openapi>                                                |
| [linode](clients/cloud/linode.nu)                         | openapi | <https://api.apis.guru/v2/specs/linode.com/4.145.0/openapi.json>                                        |
| [hetzner-cloud](clients/cloud/hetzner-cloud.nu)           | openapi | <https://api.apis.guru/v2/specs/hetzner.cloud/1.0.0/openapi.json>                                       |
| [aws-lightsail](clients/cloud/aws-lightsail.nu)           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/lightsail/2016-11-28/openapi.json>                        |
| [koyeb](clients/cloud/koyeb.nu)                           | openapi | <https://raw.githubusercontent.com/koyeb/koyeb-api-client-go/master/api/v1/koyeb/api/openapi.yaml>      |

## commerce

| Client                                                                 | Type    | Source                                                                               |
| ---------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------ |
| [square](clients/commerce/square.nu)                                   | openapi | <https://raw.githubusercontent.com/square/connect-api-specification/master/api.json> |
| [ebay-buy-browse](clients/commerce/ebay-buy-browse.nu)                 | openapi | <https://api.apis.guru/v2/specs/ebay.com/buy-browse/v1.1.0/swagger.json>             |
| [ebay-sell-fulfillment](clients/commerce/ebay-sell-fulfillment.nu)     | openapi | <https://api.apis.guru/v2/specs/ebay.com/sell-fulfillment/v1.19.19/openapi.json>     |
| [walmart-item](clients/commerce/walmart-item.nu)                       | openapi | <https://api.apis.guru/v2/specs/walmart.com/item/3.0.1/swagger.json>                 |
| [walmart-order](clients/commerce/walmart-order.nu)                     | openapi | <https://api.apis.guru/v2/specs/walmart.com/order/3.0.1/swagger.json>                |
| [magento](clients/commerce/magento.nu)                                 | openapi | <https://api.apis.guru/v2/specs/magento.com/2.2.10/openapi.json>                     |
| [shop-app](clients/commerce/shop-app.nu)                               | openapi | <https://api.apis.guru/v2/specs/shop.app/v1/openapi.json>                            |
| [etsy](clients/commerce/etsy.nu)                                       | openapi | <https://www.etsy.com/openapi/generated/oas/3.0.0.json>                              |
| [google-shopping-content](clients/commerce/google-shopping-content.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/shoppingcontent/v2/openapi.json>      |
| [ebay-commerce-catalog](clients/commerce/ebay-commerce-catalog.nu)     | openapi | <https://api.apis.guru/v2/specs/ebay.com/commerce-catalog/v1_beta.5.0/openapi.json>  |
| [ebay-commerce-taxonomy](clients/commerce/ebay-commerce-taxonomy.nu)   | openapi | <https://api.apis.guru/v2/specs/ebay.com/commerce-taxonomy/v1.0.0/swagger.json>      |
| [shop-pro](clients/commerce/shop-pro.nu)                               | openapi | <https://api.apis.guru/v2/specs/shop-pro.jp/1.0.0/openapi.json>                      |

## container-orchestration

| Client                                                              | Type    | Source                                                                                                       |
| ------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------ |
| [kubernetes](clients/container-orchestration/kubernetes.nu)         | openapi | <https://raw.githubusercontent.com/kubernetes/kubernetes/master/api/openapi-spec/swagger.json>               |
| [nomad](clients/container-orchestration/nomad.nu)                   | openapi | <https://raw.githubusercontent.com/hashicorp/nomad-openapi/main/v1/openapi.yaml>                             |
| [argocd](clients/container-orchestration/argocd.nu)                 | openapi | <https://raw.githubusercontent.com/argoproj/argo-cd/master/assets/swagger.json>                              |
| [argo-workflows](clients/container-orchestration/argo-workflows.nu) | openapi | <https://raw.githubusercontent.com/argoproj/argo-workflows/main/api/openapi-spec/swagger.json>               |
| [openfaas](clients/container-orchestration/openfaas.nu)             | openapi | <https://raw.githubusercontent.com/openfaas/faas/master/api-docs/spec.openapi.yml>                           |
| [argo-rollouts](clients/container-orchestration/argo-rollouts.nu)   | openapi | <https://raw.githubusercontent.com/argoproj/argo-rollouts/master/pkg/apiclient/rollout/rollout.swagger.json> |
| [karmada](clients/container-orchestration/karmada.nu)               | openapi | <https://raw.githubusercontent.com/karmada-io/karmada/master/api/openapi-spec/swagger.json>                  |

## containers

| Client                                                 | Type    | Source                                                                                                                |
| ------------------------------------------------------ | ------- | --------------------------------------------------------------------------------------------------------------------- |
| [docker](clients/containers/docker.nu)                 | openapi | <https://raw.githubusercontent.com/moby/moby/master/api/swagger.yaml>                                                 |
| [podman](clients/containers/podman.nu)                 | openapi | <https://storage.googleapis.com/libpod-master-releases/swagger-latest.yaml>                                           |
| [harbor](clients/containers/harbor.nu)                 | openapi | <https://raw.githubusercontent.com/goharbor/harbor/main/api/v2.0/swagger.yaml>                                        |
| [portainer](clients/containers/portainer.nu)           | openapi | <https://app.swaggerhub.com/apiproxy/registry/portainer/portainer-ce/2.20.0>                                          |
| [anchore-engine](clients/containers/anchore-engine.nu) | openapi | <https://raw.githubusercontent.com/anchore/anchore-engine/master/anchore_engine/services/apiext/swagger/swagger.yaml> |
| [rekor](clients/containers/rekor.nu)                   | openapi | <https://raw.githubusercontent.com/sigstore/rekor/main/openapi.yaml>                                                  |
| [quay](clients/containers/quay.nu)                     | openapi | <https://quay.io/api/v1/discovery>                                                                                    |
| [dockerhub](clients/containers/dockerhub.nu)           | openapi | <https://api.apis.guru/v2/specs/docker.com/hub/beta/openapi.json>                                                     |
| [snyk](clients/containers/snyk.nu)                     | openapi | <https://api.apis.guru/v2/specs/snyk.io/1.0.0/openapi.json>                                                           |

## crm

| Client                                    | Type    | Source                                                          |
| ----------------------------------------- | ------- | --------------------------------------------------------------- |
| [hubspot-crm](clients/crm/hubspot-crm.nu) | openapi | <https://api.apis.guru/v2/specs/hubapi.com/crm/v3/openapi.json> |

## data-pipeline

| Client                                                                          | Type    | Source                                                                                                                  |
| ------------------------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------- |
| [airflow](clients/data-pipeline/airflow.nu)                                     | openapi | <https://api.apis.guru/v2/specs/apache.org/airflow/2.5.1/openapi.json>                                                  |
| [airbyte-config](clients/data-pipeline/airbyte-config.nu)                       | openapi | <https://api.apis.guru/v2/specs/airbyte.local/config/1.0.0/openapi.json>                                                |
| [airbyte-platform-server](clients/data-pipeline/airbyte-platform-server.nu)     | openapi | <https://raw.githubusercontent.com/airbytehq/airbyte-platform/main/airbyte-api/server-api/src/main/openapi/config.yaml> |
| [prefect-cloud](clients/data-pipeline/prefect-cloud.nu)                         | openapi | <https://api.prefect.cloud/api/openapi.json>                                                                            |
| [windmill](clients/data-pipeline/windmill.nu)                                   | openapi | <https://raw.githubusercontent.com/windmill-labs/windmill/main/backend/windmill-api/openapi.yaml>                       |
| [temporal](clients/data-pipeline/temporal.nu)                                   | openapi | <https://raw.githubusercontent.com/temporalio/api/master/openapi/openapiv3.yaml>                                        |
| [google-datapipelines](clients/data-pipeline/google-datapipelines.nu)           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/datapipelines/v1/openapi.json>                                           |
| [google-workflows](clients/data-pipeline/google-workflows.nu)                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/workflows/v1/openapi.json>                                               |
| [google-workflowexecutions](clients/data-pipeline/google-workflowexecutions.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/workflowexecutions/v1/openapi.json>                                      |
| [aws-datapipeline](clients/data-pipeline/aws-datapipeline.nu)                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/datapipeline/2012-10-29/openapi.json>                                     |

## dns

| Client                                    | Type    | Source                                                                         |
| ----------------------------------------- | ------- | ------------------------------------------------------------------------------ |
| [aws-route53](clients/dns/aws-route53.nu) | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/route53/2013-04-01/openapi.json> |
| [azure-dns](clients/dns/azure-dns.nu)     | openapi | <https://api.apis.guru/v2/specs/azure.com/dns/2018-05-01/swagger.json>         |
| [google-dns](clients/dns/google-dns.nu)   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/dns/v1/openapi.json>            |
| [powerdns](clients/dns/powerdns.nu)       | openapi | <https://api.apis.guru/v2/specs/powerdns.local/0.0.13/swagger.json>            |

## email

| Client                                    | Type    | Source                                                                                          |
| ----------------------------------------- | ------- | ----------------------------------------------------------------------------------------------- |
| [sendgrid](clients/email/sendgrid.nu)     | openapi | <https://api.apis.guru/v2/specs/sendgrid.com/1.0.0/openapi.json>                                |
| [postmark](clients/email/postmark.nu)     | openapi | <https://api.apis.guru/v2/specs/postmarkapp.com/server/1.0.0/swagger.json>                      |
| [mandrill](clients/email/mandrill.nu)     | openapi | <https://api.apis.guru/v2/specs/mandrillapp.com/1.0/swagger.json>                               |
| [resend](clients/email/resend.nu)         | openapi | <https://raw.githubusercontent.com/resend/resend-openapi/main/resend.yaml>                      |
| [mailgun](clients/email/mailgun.nu)       | openapi | <https://documentation.mailgun.com/_spec/docs/mailgun/api-reference/send/mailgun.yaml?download> |
| [brevo](clients/email/brevo.nu)           | openapi | <https://raw.githubusercontent.com/xdev-software/brevo-java-client/develop/openapi/openapi.yml> |
| [mailersend](clients/email/mailersend.nu) | openapi | <https://api.swaggerhub.com/apis/MailerSend/mailersend-api/1.0.0-oas3.1>                        |
| [loops](clients/email/loops.nu)           | openapi | <https://app.loops.so/openapi.json>                                                             |

## error-tracking

| Client                                             | Type    | Source                                                                                                          |
| -------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------------------------- |
| [sentry](clients/error-tracking/sentry.nu)         | openapi | <https://raw.githubusercontent.com/getsentry/sentry-api-schema/main/openapi-derefed.json>                       |
| [datadog-v1](clients/error-tracking/datadog-v1.nu) | openapi | <https://raw.githubusercontent.com/DataDog/datadog-api-client-python/master/.generator/schemas/v1/openapi.yaml> |
| [sumo-logic](clients/error-tracking/sumo-logic.nu) | openapi | <https://api.sumologic.com/docs/sumologic-api.yaml>                                                             |
| [bugsnag](clients/error-tracking/bugsnag.nu)       | openapi | <https://api.swaggerhub.com/apis/smartbear-public/bugsnag-data-access-api/2/swagger.json>                       |

## feature-flags

| Client                                                | Type    | Source                                                                                               |
| ----------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------------- |
| [launchdarkly](clients/feature-flags/launchdarkly.nu) | openapi | <https://api.apis.guru/v2/specs/launchdarkly.com/5.3.0/swagger.json>                                 |
| [configcat](clients/feature-flags/configcat.nu)       | openapi | <https://api.apis.guru/v2/specs/configcat.com/v1/openapi.json>                                       |
| [flagsmith](clients/feature-flags/flagsmith.nu)       | openapi | <https://api.flagsmith.com/api/v1/swagger.json>                                                      |
| [unleash](clients/feature-flags/unleash.nu)           | openapi | <https://docs.getunleash.io/api/openapi.json>                                                        |
| [statsig](clients/feature-flags/statsig.nu)           | openapi | <https://docs.statsig.com/openapi.json>                                                              |
| [devcycle](clients/feature-flags/devcycle.nu)         | openapi | <https://api.devcycle.com/openapi.json>                                                              |
| [growthbook](clients/feature-flags/growthbook.nu)     | openapi | <https://raw.githubusercontent.com/growthbook/growthbook/main/packages/back-end/generated/spec.yaml> |
| [optimizely](clients/feature-flags/optimizely.nu)     | openapi | <https://api.optimizely.com/swagger.json>                                                            |

## finance

| Client                                                        | Type    | Source                                                                                          |
| ------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------- |
| [frankfurter](clients/finance/frankfurter.nu)                 | openapi | <https://api.frankfurter.app/openapi.json>                                                      |
| [polygon-io](clients/finance/polygon-io.nu)                   | openapi | <https://api.apis.guru/v2/specs/polygon.io/1.0.0/swagger.yaml>                                  |
| [exchangerate-api](clients/finance/exchangerate-api.nu)       | openapi | <https://api.apis.guru/v2/specs/exchangerate-api.com/4/openapi.yaml>                            |
| [consumer-finance](clients/finance/consumer-finance.nu)       | openapi | <https://api.apis.guru/v2/specs/consumerfinance.gov/1.0/swagger.yaml>                           |
| [mastercard-currency](clients/finance/mastercard-currency.nu) | openapi | <https://api.apis.guru/v2/specs/mastercard.com/CurrencyConversionCalculator/1.0.0/swagger.yaml> |
| [interzoid-currency](clients/finance/interzoid-currency.nu)   | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getcurrencyrate/1.0.0/openapi.yaml>               |
| [sonar-trading](clients/finance/sonar-trading.nu)             | openapi | <https://api.apis.guru/v2/specs/sonar.trading/1.0/swagger.json>                                 |
| [binance-spot](clients/finance/binance-spot.nu)               | openapi | <https://raw.githubusercontent.com/binance/binance-api-swagger/master/spot_api.yaml>            |

## forms

| Client                                          | Type    | Source                                                                                                                                           |
| ----------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| [google-forms](clients/forms/google-forms.nu)   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/forms/v1/openapi.json>                                                                            |
| [formapi-io](clients/forms/formapi-io.nu)       | openapi | <https://api.apis.guru/v2/specs/formapi.io/v1/openapi.json>                                                                                      |
| [qualtrics](clients/forms/qualtrics.nu)         | openapi | <https://api.apis.guru/v2/specs/qualtrics.com/0.2/openapi.json>                                                                                  |
| [va-gov-forms](clients/forms/va-gov-forms.nu)   | openapi | <https://api.apis.guru/v2/specs/va.gov/forms/0.0.0/openapi.json>                                                                                 |
| [hubspot-forms](clients/forms/hubspot-forms.nu) | openapi | <https://raw.githubusercontent.com/HubSpot/HubSpot-public-api-spec-collection/main/PublicApiSpecs/Marketing/Forms/Rollouts/144909/v3/forms.json> |
| [tally](clients/forms/tally.nu)                 | openapi | <https://api.tally.so/openapi.json>                                                                                                              |

## fraud

| Client                                                                          | Type    | Source                                                                                                         |
| ------------------------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------------- |
| [aws-fraud-detector](clients/fraud/aws-fraud-detector.nu)                       | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/frauddetector/2019-11-15/openapi.json>                           |
| [fraudlabspro-fraud-detection](clients/fraud/fraudlabspro-fraud-detection.nu)   | openapi | <https://api.apis.guru/v2/specs/fraudlabspro.com/fraud-detection/1.1/openapi.json>                             |
| [fraudlabspro-sms-verification](clients/fraud/fraudlabspro-sms-verification.nu) | openapi | <https://api.apis.guru/v2/specs/fraudlabspro.com/sms-verification/1.0/openapi.json>                            |
| [google-webrisk](clients/fraud/google-webrisk.nu)                               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/webrisk/v1/openapi.json>                                        |
| [vonage-verify](clients/fraud/vonage-verify.nu)                                 | openapi | <https://api.apis.guru/v2/specs/nexmo.com/verify/1.2.4/openapi.json>                                           |
| [twilio-verify](clients/fraud/twilio-verify.nu)                                 | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_verify_v2/1.42.0/openapi.json>                               |
| [onfido](clients/fraud/onfido.nu)                                               | openapi | <https://raw.githubusercontent.com/onfido/onfido-openapi-spec/master/generated/artifacts/openapi/openapi.json> |

## gaming

| Client                                                                               | Type    | Source                                                                                          |
| ------------------------------------------------------------------------------------ | ------- | ----------------------------------------------------------------------------------------------- |
| [pokeapi](clients/gaming/pokeapi.nu)                                                 | graphql | <https://beta.pokeapi.co/graphql/v1beta>                                                        |
| [opendota](clients/gaming/opendota.nu)                                               | openapi | <https://api.opendota.com/api>                                                                  |
| [bungie](clients/gaming/bungie.nu)                                                   | openapi | <https://raw.githubusercontent.com/Bungie-net/api/master/openapi.json>                          |
| [roblox-users](clients/gaming/roblox-users.nu)                                       | openapi | <https://users.roblox.com/docs/json/v1>                                                         |
| [riot](clients/gaming/riot.nu)                                                       | openapi | <https://mingweisamuel.github.io/riotapi-schema/openapi-3.0.0.json>                             |
| [rawg](clients/gaming/rawg.nu)                                                       | openapi | <https://api.apis.guru/v2/specs/rawg.io/v1.0/openapi.json>                                      |
| [google-play-games](clients/gaming/google-play-games.nu)                             | openapi | <https://api.apis.guru/v2/specs/googleapis.com/games/v1/openapi.json>                           |
| [google-play-games-configuration](clients/gaming/google-play-games-configuration.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/gamesConfiguration/v1configuration/openapi.json> |
| [google-play-games-management](clients/gaming/google-play-games-management.nu)       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/gamesManagement/v1management/openapi.json>       |

## healthcare

| Client                                                                 | Type    | Source                                                                                            |
| ---------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------- |
| [google-healthcare](clients/healthcare/google-healthcare.nu)           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/healthcare/v1beta1/openapi.json>                   |
| [aws-comprehend-medical](clients/healthcare/aws-comprehend-medical.nu) | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/comprehendmedical/2018-10-30/openapi.json>          |
| [aws-healthlake](clients/healthcare/aws-healthlake.nu)                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/healthlake/2017-07-01/openapi.json>                 |
| [azure-healthcare-apis](clients/healthcare/azure-healthcare-apis.nu)   | openapi | <https://api.apis.guru/v2/specs/azure.com/healthcareapis-healthcare-apis/2019-09-16/swagger.json> |
| [cdc-prime-data-hub](clients/healthcare/cdc-prime-data-hub.nu)         | openapi | <https://api.apis.guru/v2/specs/cdcgov.local/prime-data-hub/0.2.0-oas3/openapi.json>              |
| [healthcare-gov](clients/healthcare/healthcare-gov.nu)                 | openapi | <https://api.apis.guru/v2/specs/healthcare.gov/1.0.0/openapi.json>                                |
| [infermedica](clients/healthcare/infermedica.nu)                       | openapi | <https://api.apis.guru/v2/specs/infermedica.com/v2/swagger.json>                                  |
| [ndhm-healthid](clients/healthcare/ndhm-healthid.nu)                   | openapi | <https://api.apis.guru/v2/specs/ndhm.gov.in/ndhm-healthid/1.0/openapi.json>                       |
| [patientview](clients/healthcare/patientview.nu)                       | openapi | <https://api.apis.guru/v2/specs/patientview.org/1.0/openapi.json>                                 |
| [twine-health](clients/healthcare/twine-health.nu)                     | openapi | <https://api.apis.guru/v2/specs/twinehealth.com/v7.78.1/openapi.json>                             |

## identity

| Client                                               | Type    | Source                                                                              |
| ---------------------------------------------------- | ------- | ----------------------------------------------------------------------------------- |
| [okta](clients/identity/okta.nu)                     | openapi | <https://api.apis.guru/v2/specs/okta.local/1.0.0/openapi.json>                      |
| [keycloak](clients/identity/keycloak.nu)             | openapi | <https://api.apis.guru/v2/specs/keycloak.local/1/openapi.json>                      |
| [ory-kratos](clients/identity/ory-kratos.nu)         | openapi | <https://raw.githubusercontent.com/ory/kratos/master/spec/api.json>                 |
| [ory-hydra](clients/identity/ory-hydra.nu)           | openapi | <https://raw.githubusercontent.com/ory/hydra/master/spec/api.json>                  |
| [ory-keto](clients/identity/ory-keto.nu)             | openapi | <https://raw.githubusercontent.com/ory/keto/master/spec/api.json>                   |
| [ory-oathkeeper](clients/identity/ory-oathkeeper.nu) | openapi | <https://raw.githubusercontent.com/ory/oathkeeper/master/spec/api.json>             |
| [casdoor](clients/identity/casdoor.nu)               | openapi | <https://raw.githubusercontent.com/casdoor/casdoor/master/swagger/swagger.json>     |
| [fusionauth](clients/identity/fusionauth.nu)         | openapi | <https://raw.githubusercontent.com/FusionAuth/fusionauth-openapi/main/openapi.yaml> |

## incident

| Client                                           | Type    | Source                                                                                                         |
| ------------------------------------------------ | ------- | -------------------------------------------------------------------------------------------------------------- |
| [pagerduty](clients/incident/pagerduty.nu)       | openapi | <https://raw.githubusercontent.com/PagerDuty/api-schema/main/reference/REST/openapiv3.json>                    |
| [opsgenie](clients/incident/opsgenie.nu)         | openapi | <https://raw.githubusercontent.com/opsgenie/opsgenie-oas/master/swagger.json>                                  |
| [incident-io](clients/incident/incident-io.nu)   | openapi | <https://docs.incident.io/openapi/latest.json>                                                                 |
| [zenduty](clients/incident/zenduty.nu)           | openapi | <https://apidocs.zenduty.com/openapi.json>                                                                     |
| [ilert](clients/incident/ilert.nu)               | openapi | <https://api.ilert.com/api-docs/openapi.json>                                                                  |
| [uptime-com](clients/incident/uptime-com.nu)     | openapi | <https://uptime.com/api/v1/openapi/>                                                                           |
| [statuspage](clients/incident/statuspage.nu)     | openapi | <https://raw.githubusercontent.com/sbecker59/statuspage-api-client-go/main/api/v1/statuspage/api/openapi.yaml> |
| [instatus](clients/incident/instatus.nu)         | openapi | <https://raw.githubusercontent.com/instatushq/openapi/main/instatus.yaml>                                      |
| [better-stack](clients/incident/better-stack.nu) | openapi | <https://raw.githubusercontent.com/api-evangelist/better-stack/main/openapi/better-stack-openapi.yml>          |

## issue-tracking

| Client                                       | Type    | Source                                                                             |
| -------------------------------------------- | ------- | ---------------------------------------------------------------------------------- |
| [jira](clients/issue-tracking/jira.nu)       | openapi | <https://developer.atlassian.com/cloud/jira/platform/swagger-v3.v3.json>           |
| [zendesk](clients/issue-tracking/zendesk.nu) | openapi | <https://developer.zendesk.com/zendesk/oas.yaml>                                   |
| [redmine](clients/issue-tracking/redmine.nu) | openapi | <https://raw.githubusercontent.com/d-yoshi/redmine-openapi/main/openapi.yaml>      |
| [mantis](clients/issue-tracking/mantis.nu)   | openapi | <https://raw.githubusercontent.com/mantisbt/mantisbt/master/api/rest/swagger.json> |

## maps

| Client                                               | Type    | Source                                                                          |
| ---------------------------------------------------- | ------- | ------------------------------------------------------------------------------- |
| [opencagedata](clients/maps/opencagedata.nu)         | openapi | <https://api.apis.guru/v2/specs/opencagedata.com/1/swagger.json>                |
| [here-positioning](clients/maps/here-positioning.nu) | openapi | <https://api.apis.guru/v2/specs/here.com/positioning/2.1.1/openapi.json>        |
| [tomtom-search](clients/maps/tomtom-search.nu)       | openapi | <https://api.apis.guru/v2/specs/tomtom.com/search/1.0.0/openapi.json>           |
| [tomtom-routing](clients/maps/tomtom-routing.nu)     | openapi | <https://api.apis.guru/v2/specs/tomtom.com/routing/1.0.0/openapi.json>          |
| [tomtom-maps](clients/maps/tomtom-maps.nu)           | openapi | <https://api.apis.guru/v2/specs/tomtom.com/maps/1.0.0/openapi.json>             |
| [aws-location](clients/maps/aws-location.nu)         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/location/2020-11-19/openapi.json> |
| [geodb](clients/maps/geodb.nu)                       | openapi | <https://api.apis.guru/v2/specs/mashape.com/geodb/1.0.0/swagger.json>           |
| [bc-geocoder](clients/maps/bc-geocoder.nu)           | openapi | <https://api.apis.guru/v2/specs/gov.bc.ca/geocoder/2.0.0/openapi.json>          |
| [ip2location-io](clients/maps/ip2location-io.nu)     | openapi | <https://api.apis.guru/v2/specs/ip2location.io/1.0/openapi.json>                |

## marketing

| Client                                                          | Type    | Source                                                                          |
| --------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------- |
| [braze](clients/marketing/braze.nu)                             | openapi | <https://api.apis.guru/v2/specs/braze.com/1.0.0/openapi.json>                   |
| [hubspot-marketing](clients/marketing/hubspot-marketing.nu)     | openapi | <https://api.apis.guru/v2/specs/hubapi.com/marketing/v3/openapi.json>           |
| [klaviyo](clients/marketing/klaviyo.nu)                         | openapi | <https://raw.githubusercontent.com/klaviyo/openapi/main/openapi/stable.json>    |
| [mailchimp-marketing](clients/marketing/mailchimp-marketing.nu) | openapi | <https://api.mailchimp.com/schema/3.0/Swagger.json?expand>                      |
| [iterable](clients/marketing/iterable.nu)                       | openapi | <https://api.iterable.com/api-docs>                                             |
| [onesignal](clients/marketing/onesignal.nu)                     | openapi | <https://documentation.onesignal.com/openapi.json>                              |
| [aws-pinpoint](clients/marketing/aws-pinpoint.nu)               | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/pinpoint/2016-12-01/openapi.json> |

## monitoring

| Client                                                                   | Type    | Source                                                                                                          |
| ------------------------------------------------------------------------ | ------- | --------------------------------------------------------------------------------------------------------------- |
| [grafana](clients/monitoring/grafana.nu)                                 | openapi | <https://raw.githubusercontent.com/grafana/grafana/main/public/api-merged.json>                                 |
| [datadog](clients/monitoring/datadog.nu)                                 | openapi | <https://raw.githubusercontent.com/DataDog/datadog-api-client-python/master/.generator/schemas/v2/openapi.yaml> |
| [checkly](clients/monitoring/checkly.nu)                                 | openapi | <https://api.checklyhq.com/openapi.json>                                                                        |
| [kibana](clients/monitoring/kibana.nu)                                   | openapi | <https://raw.githubusercontent.com/elastic/kibana/main/oas_docs/output/kibana.serverless.yaml>                  |
| [netdata](clients/monitoring/netdata.nu)                                 | openapi | <https://raw.githubusercontent.com/netdata/netdata/master/src/web/api/netdata-swagger.yaml>                     |
| [influxdb](clients/monitoring/influxdb.nu)                               | openapi | <https://raw.githubusercontent.com/influxdata/openapi/master/contracts/cloud.yml>                               |
| [google-cloud-monitoring](clients/monitoring/google-cloud-monitoring.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/monitoring/v3/openapi.json>                                      |
| [aws-cloudwatch](clients/monitoring/aws-cloudwatch.nu)                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/monitoring/2010-08-01/openapi.json>                               |

## music

| Client                                      | Type    | Source                                                                                       |
| ------------------------------------------- | ------- | -------------------------------------------------------------------------------------------- |
| [spotify](clients/music/spotify.nu)         | openapi | <https://raw.githubusercontent.com/sonallux/spotify-web-api/main/fixed-spotify-open-api.yml> |
| [soundcloud](clients/music/soundcloud.nu)   | openapi | <https://api.apis.guru/v2/specs/soundcloud.com/1.0.0/openapi.json>                           |
| [tidal](clients/music/tidal.nu)             | openapi | <https://tidal-music.github.io/tidal-api-reference/tidal-api-oas.json>                       |
| [setlistfm](clients/music/setlistfm.nu)     | openapi | <https://api.apis.guru/v2/specs/setlist.fm/1.0/swagger.json>                                 |
| [spinitron](clients/music/spinitron.nu)     | openapi | <https://api.apis.guru/v2/specs/spinitron.com/1.0.0/openapi.json>                            |
| [discogs](clients/music/discogs.nu)         | openapi | <https://raw.githubusercontent.com/wyattowalsh/discogs-api-spec/main/discogs.json>           |
| [apple-music](clients/music/apple-music.nu) | openapi | <https://raw.githubusercontent.com/schroedan/apple-music-api/main/openapi.yaml>              |
| [bandsintown](clients/music/bandsintown.nu) | openapi | <https://api.apis.guru/v2/specs/bandsintown.com/3.0.0/swagger.json>                          |

## news

| Client                                                           | Type    | Source                                                                                       |
| ---------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------- |
| [nytimes-top-stories](clients/news/nytimes-top-stories.nu)       | openapi | <https://api.apis.guru/v2/specs/nytimes.com/top_stories/2.0.0/openapi.json>                  |
| [nytimes-books](clients/news/nytimes-books.nu)                   | openapi | <https://api.apis.guru/v2/specs/nytimes.com/books_api/3.0.0/openapi.json>                    |
| [nytimes-article-search](clients/news/nytimes-article-search.nu) | openapi | <https://api.apis.guru/v2/specs/nytimes.com/article_search/1.0.0/openapi.json>               |
| [nytimes-archive](clients/news/nytimes-archive.nu)               | openapi | <https://api.apis.guru/v2/specs/nytimes.com/archive/1.0.0/openapi.json>                      |
| [nytimes-most-popular](clients/news/nytimes-most-popular.nu)     | openapi | <https://api.apis.guru/v2/specs/nytimes.com/most_popular_api/2.0.0/openapi.json>             |
| [nytimes-timeswire](clients/news/nytimes-timeswire.nu)           | openapi | <https://api.apis.guru/v2/specs/nytimes.com/timeswire/3.0.0/openapi.json>                    |
| [newsdata-io](clients/news/newsdata-io.nu)                       | openapi | <https://newsdata.io/openapi.json>                                                           |
| [bing-news-search](clients/news/bing-news-search.nu)             | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-NewsSearch/1.0/swagger.json> |

## payments

| Client                                                   | Type    | Source                                                                                                          |
| -------------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------------------------- |
| [stripe](clients/payments/stripe.nu)                     | openapi | <https://raw.githubusercontent.com/stripe/openapi/master/openapi/spec3.json>                                    |
| [paypal-orders](clients/payments/paypal-orders.nu)       | openapi | <https://raw.githubusercontent.com/paypal/paypal-rest-api-specifications/main/openapi/checkout_orders_v2.json>  |
| [paypal-payments](clients/payments/paypal-payments.nu)   | openapi | <https://raw.githubusercontent.com/paypal/paypal-rest-api-specifications/main/openapi/payments_payment_v2.json> |
| [paypal-invoicing](clients/payments/paypal-invoicing.nu) | openapi | <https://raw.githubusercontent.com/paypal/paypal-rest-api-specifications/main/openapi/invoicing_v2.json>        |
| [adyen-checkout](clients/payments/adyen-checkout.nu)     | openapi | <https://raw.githubusercontent.com/Adyen/adyen-openapi/main/yaml/CheckoutService-v71.yaml>                      |
| [adyen-recurring](clients/payments/adyen-recurring.nu)   | openapi | <https://raw.githubusercontent.com/Adyen/adyen-openapi/main/yaml/RecurringService-v68.yaml>                     |
| [plaid](clients/payments/plaid.nu)                       | openapi | <https://raw.githubusercontent.com/plaid/plaid-openapi/master/2020-09-14.yml>                                   |
| [klarna-payments](clients/payments/klarna-payments.nu)   | openapi | <https://api.apis.guru/v2/specs/klarna.com/payments/1.0.0/openapi.json>                                         |
| [recurly](clients/payments/recurly.nu)                   | openapi | <https://raw.githubusercontent.com/recurly/recurly-client-go/master/openapi/api.yaml>                           |
| [adyen-payments](clients/payments/adyen-payments.nu)     | openapi | <https://raw.githubusercontent.com/Adyen/adyen-openapi/main/yaml/PaymentService-v68.yaml>                       |
| [adyen-management](clients/payments/adyen-management.nu) | openapi | <https://raw.githubusercontent.com/Adyen/adyen-openapi/main/yaml/ManagementService-v3.yaml>                     |

## project-mgmt

| Client                                                                     | Type    | Source                                                                       |
| -------------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------- |
| [asana](clients/project-mgmt/asana.nu)                                     | openapi | <https://raw.githubusercontent.com/Asana/openapi/master/defs/asana_oas.yaml> |
| [trello](clients/project-mgmt/trello.nu)                                   | openapi | <https://developer.atlassian.com/cloud/trello/swagger.v3.json>               |
| [notion](clients/project-mgmt/notion.nu)                                   | openapi | <https://developers.notion.com/openapi.json>                                 |
| [linear](clients/project-mgmt/linear.nu)                                   | graphql | <https://api.linear.app/graphql>                                             |
| [jira-service-management](clients/project-mgmt/jira-service-management.nu) | openapi | <https://developer.atlassian.com/cloud/jira/service-desk/swagger.v3.json>    |
| [coda](clients/project-mgmt/coda.nu)                                       | openapi | <https://coda.io/apis/v1/openapi.json>                                       |
| [atlassian-compass](clients/project-mgmt/atlassian-compass.nu)             | openapi | <https://developer.atlassian.com/cloud/compass/swagger.v3.json>              |

## public-data

| Client                                              | Type    | Source                                                            |
| --------------------------------------------------- | ------- | ----------------------------------------------------------------- |
| [countries](clients/public-data/countries.nu)       | graphql | <https://countries.trevorblades.com/graphql>                      |
| [wikipedia](clients/public-data/wikipedia.nu)       | openapi | <https://en.wikipedia.org/api/rest_v1/?spec>                      |
| [open-library](clients/public-data/open-library.nu) | openapi | <https://openlibrary.org/static/openapi.json>                     |
| [open5e](clients/public-data/open5e.nu)             | openapi | <https://api.open5e.com/schema/?format=json>                      |
| [tfl](clients/public-data/tfl.nu)                   | openapi | <https://api.tfl.gov.uk/swagger/docs/v1>                          |
| [met-norway](clients/public-data/met-norway.nu)     | openapi | <https://api.met.no/weatherapi/locationforecast/2.0/swagger>      |
| [nasa-apod](clients/public-data/nasa-apod.nu)       | openapi | <https://api.apis.guru/v2/specs/nasa.gov/apod/1.0.0/openapi.json> |
| [fec](clients/public-data/fec.nu)                   | openapi | <https://api.apis.guru/v2/specs/fec.gov/1.0/openapi.json>         |
| [crossref](clients/public-data/crossref.nu)         | openapi | <https://api.crossref.org/swagger-docs>                           |

## sandbox

| Client                                                    | Type    | Source                                                                                           |
| --------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------ |
| [petstore](clients/sandbox/petstore.nu)                   | openapi | <https://petstore3.swagger.io/api/v3/openapi.json>                                               |
| [reqres](clients/sandbox/reqres.nu)                       | openapi | <https://reqres.in/openapi.json>                                                                 |
| [restful-booker](clients/sandbox/restful-booker.nu)       | openapi | <https://raw.githubusercontent.com/texttest/restful-booker/with_texttests/swagger.json>          |
| [catfact](clients/sandbox/catfact.nu)                     | openapi | <https://catfact.ninja/docs>                                                                     |
| [spaceflight-news](clients/sandbox/spaceflight-news.nu)   | openapi | <https://api.spaceflightnewsapi.net/v4/schema/>                                                  |
| [train-travel](clients/sandbox/train-travel.nu)           | openapi | <https://raw.githubusercontent.com/bump-sh-examples/train-travel-api/main/openapi.yaml>          |
| [realworld-conduit](clients/sandbox/realworld-conduit.nu) | openapi | <https://raw.githubusercontent.com/realworld-apps/realworld/main/specs/api/openapi.yml>          |
| [jsonplaceholder](clients/sandbox/jsonplaceholder.nu)     | openapi | <https://raw.githubusercontent.com/sebastienlevert/jsonplaceholder-api/main/openapi.yaml>        |
| [ergast-f1](clients/sandbox/ergast-f1.nu)                 | openapi | <https://raw.githubusercontent.com/adampax/ergast-f1-openapi-doc/master/ergast-openapi-doc.yaml> |

## sci-fi

| Client                                                           | Type    | Source                                                                         |
| ---------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------ |
| [swapi](clients/sci-fi/swapi.nu)                                 | graphql | <https://swapi-graphql.netlify.app/graphql>                                    |
| [rick-and-morty](clients/sci-fi/rick-and-morty.nu)               | graphql | <https://rickandmortyapi.com/graphql>                                          |
| [dnd5e](clients/sci-fi/dnd5e.nu)                                 | openapi | <https://api.apis.guru/v2/specs/dnd5eapi.co/0.1/openapi.json>                  |
| [dnd5e-graphql](clients/sci-fi/dnd5e-graphql.nu)                 | graphql | <https://www.dnd5eapi.co/graphql/2014>                                         |
| [potterdb](clients/sci-fi/potterdb.nu)                           | graphql | <https://api.potterdb.com/graphql>                                             |
| [starwars-translations](clients/sci-fi/starwars-translations.nu) | openapi | <https://api.apis.guru/v2/specs/funtranslations.com/starwars/2.3/swagger.json> |
| [futurama](clients/sci-fi/futurama.nu)                           | openapi | <https://futuramaapi.com/openapi.json>                                         |
| [thronesapi](clients/sci-fi/thronesapi.nu)                       | openapi | <https://thronesapi.com/swagger/v1/swagger.json>                               |

## search

| Client                                           | Type    | Source                                                                                                                 |
| ------------------------------------------------ | ------- | ---------------------------------------------------------------------------------------------------------------------- |
| [typesense](clients/search/typesense.nu)         | openapi | <https://raw.githubusercontent.com/typesense/typesense-api-spec/master/openapi.yml>                                    |
| [algolia](clients/search/algolia.nu)             | openapi | <https://raw.githubusercontent.com/algolia/api-clients-automation/main/specs/bundled/search.yml>                       |
| [elasticsearch](clients/search/elasticsearch.nu) | openapi | <https://raw.githubusercontent.com/elastic/elasticsearch-specification/main/output/openapi/elasticsearch-openapi.json> |
| [opensearch](clients/search/opensearch.nu)       | openapi | <https://github.com/opensearch-project/opensearch-api-specification/releases/latest/download/opensearch-openapi.yaml>  |
| [meilisearch](clients/search/meilisearch.nu)     | openapi | <https://raw.githubusercontent.com/meilisearch/specifications/main/open-api.yaml>                                      |
| [qdrant](clients/search/qdrant.nu)               | openapi | <https://raw.githubusercontent.com/qdrant/qdrant/master/docs/redoc/master/openapi.json>                                |
| [weaviate](clients/search/weaviate.nu)           | openapi | <https://raw.githubusercontent.com/weaviate/weaviate/main/openapi-specs/schema.json>                                   |
| [manticore](clients/search/manticore.nu)         | openapi | <https://raw.githubusercontent.com/manticoresoftware/manticoresearch-go/master/api/openapi.yaml>                       |

## social

| Client                                   | Type    | Source                                                                                       |
| ---------------------------------------- | ------- | -------------------------------------------------------------------------------------------- |
| [mastodon](clients/social/mastodon.nu)   | openapi | <https://api.apis.guru/v2/specs/mastodon.local/1.0/openapi.json>                             |
| [discourse](clients/social/discourse.nu) | openapi | <https://raw.githubusercontent.com/discourse/discourse_api_docs/main/openapi.json>           |
| [misskey](clients/social/misskey.nu)     | openapi | <https://misskey.io/api.json>                                                                |
| [peertube](clients/social/peertube.nu)   | openapi | <https://raw.githubusercontent.com/Chocobozzz/PeerTube/develop/support/doc/api/openapi.yaml> |

## storage

| Client                                                | Type    | Source                                                                                   |
| ----------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------- |
| [box](clients/storage/box.nu)                         | openapi | <https://raw.githubusercontent.com/box/box-openapi/main/openapi.json>                    |
| [googledrive](clients/storage/googledrive.nu)         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/drive/v3/openapi.yaml>                    |
| [gcs](clients/storage/gcs.nu)                         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/storage/v1/openapi.yaml>                  |
| [s3](clients/storage/s3.nu)                           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/s3/2006-03-01/openapi.json>                |
| [glacier](clients/storage/glacier.nu)                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/glacier/2012-06-01/openapi.json>           |
| [storage-gateway](clients/storage/storage-gateway.nu) | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/storagegateway/2013-06-30/openapi.json>    |
| [efs](clients/storage/efs.nu)                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/elasticfilesystem/2015-02-01/openapi.json> |
| [azure-blob](clients/storage/azure-blob.nu)           | openapi | <https://api.apis.guru/v2/specs/azure.com/storage-blob/2019-04-01/swagger.json>          |
| [azure-file](clients/storage/azure-file.nu)           | openapi | <https://api.apis.guru/v2/specs/azure.com/storage-file/2019-06-01/swagger.json>          |
| [aws-fsx](clients/storage/aws-fsx.nu)                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/fsx/2018-03-01/openapi.json>               |
| [aws-backup](clients/storage/aws-backup.nu)           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/backup/2018-11-15/openapi.json>            |

## telephony

| Client                                          | Type    | Source                                                                                     |
| ----------------------------------------------- | ------- | ------------------------------------------------------------------------------------------ |
| [twilio](clients/telephony/twilio.nu)           | openapi | <https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_api_v2010.json> |
| [telnyx](clients/telephony/telnyx.nu)           | openapi | <https://raw.githubusercontent.com/team-telnyx/openapi/master/openapi/spec3.json>          |
| [ringcentral](clients/telephony/ringcentral.nu) | openapi | <https://netstorage.ringcentral.com/dpw/api-reference/specs/rc-platform.yml>               |
| [bandwidth](clients/telephony/bandwidth.nu)     | openapi | <https://raw.githubusercontent.com/Bandwidth/node-sdk/main/bandwidth.yml>                  |
| [messagebird](clients/telephony/messagebird.nu) | openapi | <https://raw.githubusercontent.com/messagebird/openapi-specs/master/sms/openapi.yaml>      |
| [vonage](clients/telephony/vonage.nu)           | openapi | <https://api.apis.guru/v2/specs/nexmo.com/voice/1.3.10/openapi.json>                       |

## testing

| Client                                                                        | Type    | Source                                                                            |
| ----------------------------------------------------------------------------- | ------- | --------------------------------------------------------------------------------- |
| [httpbin](clients/testing/httpbin.nu)                                         | openapi | <https://httpbin.org/spec.json>                                                   |
| [postman](clients/testing/postman.nu)                                         | openapi | <https://api.apis.guru/v2/specs/getpostman.com/1.20.0/openapi.json>               |
| [apis-guru](clients/testing/apis-guru.nu)                                     | openapi | <https://api.apis.guru/v2/specs/apis.guru/2.2.0/openapi.yaml>                     |
| [fungenerators-uuid](clients/testing/fungenerators-uuid.nu)                   | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/uuid/1.5/openapi.json>          |
| [fungenerators-fake-identity](clients/testing/fungenerators-fake-identity.nu) | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/fake-identity/1.5/swagger.json> |
| [fungenerators-random-facts](clients/testing/fungenerators-random-facts.nu)   | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/random-facts/1.5/openapi.json>  |
| [wiremock-admin](clients/testing/wiremock-admin.nu)                           | openapi | <https://api.apis.guru/v2/specs/wiremock.org/admin/2.35.0/openapi.json>           |
| [jokes-one](clients/testing/jokes-one.nu)                                     | openapi | <https://api.apis.guru/v2/specs/jokes.one/1.1/swagger.json>                       |
| [quotes-rest](clients/testing/quotes-rest.nu)                                 | openapi | <https://api.apis.guru/v2/specs/quotes.rest/3.1/openapi.json>                     |

## translation

| Client                                                                        | Type    | Source                                                                                                                                                        |
| ----------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [deepl](clients/translation/deepl.nu)                                         | openapi | <https://raw.githubusercontent.com/DeepLcom/openapi/main/openapi.json>                                                                                        |
| [libretranslate](clients/translation/libretranslate.nu)                       | openapi | <https://api.apis.guru/v2/specs/libretranslate.local/1.3.9/openapi.json>                                                                                      |
| [google-translate](clients/translation/google-translate.nu)                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/translate/v3/openapi.json>                                                                                     |
| [aws-translate](clients/translation/aws-translate.nu)                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/translate/2017-07-01/openapi.json>                                                                              |
| [azure-translator](clients/translation/azure-translator.nu)                   | openapi | <https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/TranslatorText/stable/v3.0/TranslatorText.json> |
| [ebay-commerce-translation](clients/translation/ebay-commerce-translation.nu) | openapi | <https://api.apis.guru/v2/specs/ebay.com/commerce-translation/1/openapi.json>                                                                                 |

## vector-database

| Client                                                                              | Type    | Source                                                                                                       |
| ----------------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------ |
| [pinecone](clients/vector-database/pinecone.nu)                                     | openapi | <https://api.apis.guru/v2/specs/pinecone.io/20230401.1/openapi.json>                                         |
| [pinecone-db-data](clients/vector-database/pinecone-db-data.nu)                     | openapi | <https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/db_data_2026-04.oas.yaml>           |
| [pinecone-db-control](clients/vector-database/pinecone-db-control.nu)               | openapi | <https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/db_control_2026-04.oas.yaml>        |
| [pinecone-inference](clients/vector-database/pinecone-inference.nu)                 | openapi | <https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/inference_2026-04.oas.yaml>         |
| [pinecone-admin](clients/vector-database/pinecone-admin.nu)                         | openapi | <https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/admin_2026-04.oas.yaml>             |
| [pinecone-assistant-control](clients/vector-database/pinecone-assistant-control.nu) | openapi | <https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/assistant_control_2026-04.oas.yaml> |
| [pinecone-assistant-data](clients/vector-database/pinecone-assistant-data.nu)       | openapi | <https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/assistant_data_2026-04.oas.yaml>    |
| [chroma](clients/vector-database/chroma.nu)                                         | openapi | <https://docs.trychroma.com/openapi.json>                                                                    |

## version-control

| Client                                                          | Type    | Source                                                                                                               |
| --------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------------------- |
| [github](clients/version-control/github.nu)                     | openapi | <https://raw.githubusercontent.com/github/rest-api-description/main/descriptions/api.github.com/api.github.com.json> |
| [gitlab](clients/version-control/gitlab.nu)                     | openapi | <https://docs.gitlab.com/api/openapi/openapi_v2.yaml>                                                                |
| [bitbucket](clients/version-control/bitbucket.nu)               | openapi | <https://api.bitbucket.org/swagger.json>                                                                             |
| [gitea](clients/version-control/gitea.nu)                       | openapi | <https://gitea.com/swagger.v1.json>                                                                                  |
| [codeberg](clients/version-control/codeberg.nu)                 | openapi | <https://codeberg.org/swagger.v1.json>                                                                               |
| [forgejo](clients/version-control/forgejo.nu)                   | openapi | <https://v11.next.forgejo.org/swagger.v1.json>                                                                       |
| [bitbucket-server](clients/version-control/bitbucket-server.nu) | openapi | <https://dac-static.atlassian.com/server/bitbucket/10.3.swagger.v3.json>                                             |

## video

| Client                                                  | Type    | Source                                                                                    |
| ------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------- |
| [vimeo](clients/video/vimeo.nu)                         | openapi | <https://api.apis.guru/v2/specs/vimeo.com/3.4/openapi.json>                               |
| [youtube](clients/video/youtube.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/youtube/v3/openapi.json>                   |
| [youtube-reporting](clients/video/youtube-reporting.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/youtubereporting/v1/openapi.json>          |
| [twitch](clients/video/twitch.nu)                       | openapi | <https://raw.githubusercontent.com/DmitryScaletta/twitch-api-swagger/master/openapi.json> |
| [bunny-stream](clients/video/bunny-stream.nu)           | openapi | <https://video.bunnycdn.com/openapi/bunnynet-video-api.public.json>                       |

## weather

| Client                                                                | Type    | Source                                                                                        |
| --------------------------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------- |
| [weather-gov](clients/weather/weather-gov.nu)                         | openapi | <https://api.weather.gov/openapi.json>                                                        |
| [open-meteo-forecast](clients/weather/open-meteo-forecast.nu)         | openapi | <https://raw.githubusercontent.com/open-meteo/open-meteo/main/openapi/forecast.yml>           |
| [open-meteo-marine](clients/weather/open-meteo-marine.nu)             | openapi | <https://raw.githubusercontent.com/open-meteo/open-meteo/main/openapi/marine.yml>             |
| [open-meteo-air-quality](clients/weather/open-meteo-air-quality.nu)   | openapi | <https://raw.githubusercontent.com/open-meteo/open-meteo/main/openapi/air-quality.yml>        |
| [open-meteo-historical](clients/weather/open-meteo-historical.nu)     | openapi | <https://raw.githubusercontent.com/open-meteo/open-meteo/main/openapi/historical-weather.yml> |
| [met-no-locationforecast](clients/weather/met-no-locationforecast.nu) | openapi | <https://api.met.no/weatherapi/locationforecast/2.0/swagger>                                  |
| [brightsky](clients/weather/brightsky.nu)                             | openapi | <https://api.brightsky.dev/openapi.json>                                                      |
| [visualcrossing-weather](clients/weather/visualcrossing-weather.nu)   | openapi | <https://api.apis.guru/v2/specs/visualcrossing.com/weather/4.6/openapi.json>                  |
| [weatherbit](clients/weather/weatherbit.nu)                           | openapi | <https://api.apis.guru/v2/specs/weatherbit.io/2.0.0/swagger.json>                             |
| [meteosource](clients/weather/meteosource.nu)                         | openapi | <https://api.apis.guru/v2/specs/meteosource.com/v1/openapi.json>                              |
