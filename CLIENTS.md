# Available clients

_This file is auto-generated from `clients.yaml` by `scripts/generate.nu`. Do not edit by hand._

## ai

| Client                                 | Type    | Source                                                   |
| -------------------------------------- | ------- | -------------------------------------------------------- |
| [openai](clients/ai/openai.nu)         | openapi | <specs/openai.yaml>                                      |
| [cohere](clients/ai/cohere.nu)         | openapi | <https://docs.cohere.com/openapi/cohere-api.json>        |
| [elevenlabs](clients/ai/elevenlabs.nu) | openapi | <https://api.elevenlabs.io/openapi.json>                 |
| [assemblyai](clients/ai/assemblyai.nu) | openapi | <https://www.assemblyai.com/docs/openapi.json>           |
| [deepgram](clients/ai/deepgram.nu)     | openapi | <https://developers.deepgram.com/reference/openapi.json> |
| [xai](clients/ai/xai.nu)               | openapi | <https://docs.x.ai/openapi.json>                         |
| [deepinfra](clients/ai/deepinfra.nu)   | openapi | <https://api.deepinfra.com/openapi.json>                 |

## analytics

| Client                                                                | Type    | Source                                                                             |
| --------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------- |
| [google-analytics](clients/analytics/google-analytics.nu)             | openapi | <https://api.apis.guru/v2/specs/googleapis.com/analytics/v3/openapi.json>          |
| [google-analytics-data](clients/analytics/google-analytics-data.nu)   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/analyticsdata/v1beta/openapi.json>  |
| [google-analytics-admin](clients/analytics/google-analytics-admin.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/analyticsadmin/v1beta/openapi.json> |
| [posthog](clients/analytics/posthog.nu)                               | openapi | <https://us.posthog.com/api/schema/>                                               |

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

## cdn

| Client                                                          | Type    | Source                                                                                                   |
| --------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------- |
| [cloudflare](clients/cdn/cloudflare.nu)                         | openapi | <https://raw.githubusercontent.com/cloudflare/api-schemas/main/openapi.json>                             |
| [aws-cloudfront](clients/cdn/aws-cloudfront.nu)                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/cloudfront/2020-05-31/openapi.json>                        |
| [aws-global-accelerator](clients/cdn/aws-global-accelerator.nu) | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/globalaccelerator/2018-08-08/openapi.json>                 |
| [azure-cdn](clients/cdn/azure-cdn.nu)                           | openapi | <https://api.apis.guru/v2/specs/azure.com/cdn/2019-06-15-preview/swagger.json>                           |
| [azure-cdn-waf](clients/cdn/azure-cdn-waf.nu)                   | openapi | <https://api.apis.guru/v2/specs/azure.com/cdn-cdnwebapplicationfirewall/2019-06-15-preview/swagger.json> |

## chat

| Client                               | Type    | Source                                                                                                    |
| ------------------------------------ | ------- | --------------------------------------------------------------------------------------------------------- |
| [slack](clients/chat/slack.nu)       | openapi | <https://raw.githubusercontent.com/slackapi/slack-api-specs/master/web-api/slack_web_openapi_v2.json>     |
| [discord](clients/chat/discord.nu)   | openapi | <https://raw.githubusercontent.com/discord/discord-api-spec/main/specs/openapi.json>                      |
| [line](clients/chat/line.nu)         | openapi | <https://raw.githubusercontent.com/line/line-openapi/main/messaging-api.yml>                              |
| [intercom](clients/chat/intercom.nu) | openapi | <https://raw.githubusercontent.com/intercom/Intercom-OpenAPI/main/descriptions/2.11/api.intercom.io.yaml> |
| [zoom](clients/chat/zoom.nu)         | openapi | <https://api.apis.guru/v2/specs/zoom.us/2.0.0/openapi.yaml>                                               |
| [chatwoot](clients/chat/chatwoot.nu) | openapi | <https://raw.githubusercontent.com/chatwoot/chatwoot/develop/swagger/swagger.json>                        |

## cloud

| Client                                                    | Type    | Source                                                                                                  |
| --------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------- |
| [digitalocean](clients/cloud/digitalocean.nu)             | openapi | <https://raw.githubusercontent.com/digitalocean/openapi/main/specification/DigitalOcean-public.v2.yaml> |
| [exoscale](clients/cloud/exoscale.nu)                     | openapi | <https://openapi-v2.exoscale.com/source.json>                                                           |
| [fly-machines](clients/cloud/fly-machines.nu)             | openapi | <https://docs.machines.dev/swagger/doc.json>                                                            |
| [netlify](clients/cloud/netlify.nu)                       | openapi | <https://open-api.netlify.com/openapi.json>                                                             |
| [openshift-clusters](clients/cloud/openshift-clusters.nu) | openapi | <https://api.openshift.com/api/clusters_mgmt/v1/openapi>                                                |
| [openshift-accounts](clients/cloud/openshift-accounts.nu) | openapi | <https://api.openshift.com/api/accounts_mgmt/v1/openapi>                                                |

## commerce

| Client                                                             | Type    | Source                                                                               |
| ------------------------------------------------------------------ | ------- | ------------------------------------------------------------------------------------ |
| [square](clients/commerce/square.nu)                               | openapi | <https://raw.githubusercontent.com/square/connect-api-specification/master/api.json> |
| [ebay-buy-browse](clients/commerce/ebay-buy-browse.nu)             | openapi | <https://api.apis.guru/v2/specs/ebay.com/buy-browse/v1.1.0/swagger.json>             |
| [ebay-sell-fulfillment](clients/commerce/ebay-sell-fulfillment.nu) | openapi | <https://api.apis.guru/v2/specs/ebay.com/sell-fulfillment/v1.19.19/openapi.json>     |
| [walmart-item](clients/commerce/walmart-item.nu)                   | openapi | <https://api.apis.guru/v2/specs/walmart.com/item/3.0.1/swagger.json>                 |
| [walmart-order](clients/commerce/walmart-order.nu)                 | openapi | <https://api.apis.guru/v2/specs/walmart.com/order/3.0.1/swagger.json>                |
| [magento](clients/commerce/magento.nu)                             | openapi | <https://api.apis.guru/v2/specs/magento.com/2.2.10/openapi.json>                     |
| [shop-app](clients/commerce/shop-app.nu)                           | openapi | <https://api.apis.guru/v2/specs/shop.app/v1/openapi.json>                            |

## container-orchestration

| Client                                                              | Type    | Source                                                                                         |
| ------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------- |
| [kubernetes](clients/container-orchestration/kubernetes.nu)         | openapi | <https://raw.githubusercontent.com/kubernetes/kubernetes/master/api/openapi-spec/swagger.json> |
| [nomad](clients/container-orchestration/nomad.nu)                   | openapi | <https://raw.githubusercontent.com/hashicorp/nomad-openapi/main/v1/openapi.yaml>               |
| [argocd](clients/container-orchestration/argocd.nu)                 | openapi | <https://raw.githubusercontent.com/argoproj/argo-cd/master/assets/swagger.json>                |
| [argo-workflows](clients/container-orchestration/argo-workflows.nu) | openapi | <https://raw.githubusercontent.com/argoproj/argo-workflows/main/api/openapi-spec/swagger.json> |
| [openfaas](clients/container-orchestration/openfaas.nu)             | openapi | <https://raw.githubusercontent.com/openfaas/faas/master/api-docs/spec.openapi.yml>             |

## containers

| Client                                                 | Type    | Source                                                                                                                |
| ------------------------------------------------------ | ------- | --------------------------------------------------------------------------------------------------------------------- |
| [docker](clients/containers/docker.nu)                 | openapi | <https://raw.githubusercontent.com/moby/moby/master/api/swagger.yaml>                                                 |
| [podman](clients/containers/podman.nu)                 | openapi | <https://storage.googleapis.com/libpod-master-releases/swagger-latest.yaml>                                           |
| [harbor](clients/containers/harbor.nu)                 | openapi | <https://raw.githubusercontent.com/goharbor/harbor/main/api/v2.0/swagger.yaml>                                        |
| [portainer](clients/containers/portainer.nu)           | openapi | <https://app.swaggerhub.com/apiproxy/registry/portainer/portainer-ce/2.20.0>                                          |
| [anchore-engine](clients/containers/anchore-engine.nu) | openapi | <https://raw.githubusercontent.com/anchore/anchore-engine/master/anchore_engine/services/apiext/swagger/swagger.yaml> |
| [rekor](clients/containers/rekor.nu)                   | openapi | <https://raw.githubusercontent.com/sigstore/rekor/main/openapi.yaml>                                                  |

## dns

| Client                                    | Type    | Source                                                                         |
| ----------------------------------------- | ------- | ------------------------------------------------------------------------------ |
| [aws-route53](clients/dns/aws-route53.nu) | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/route53/2013-04-01/openapi.json> |
| [azure-dns](clients/dns/azure-dns.nu)     | openapi | <https://api.apis.guru/v2/specs/azure.com/dns/2018-05-01/swagger.json>         |
| [google-dns](clients/dns/google-dns.nu)   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/dns/v1/openapi.json>            |
| [powerdns](clients/dns/powerdns.nu)       | openapi | <https://api.apis.guru/v2/specs/powerdns.local/0.0.13/swagger.json>            |

## email

| Client                                | Type    | Source                                                                     |
| ------------------------------------- | ------- | -------------------------------------------------------------------------- |
| [sendgrid](clients/email/sendgrid.nu) | openapi | <https://api.apis.guru/v2/specs/sendgrid.com/1.0.0/openapi.json>           |
| [postmark](clients/email/postmark.nu) | openapi | <https://api.apis.guru/v2/specs/postmarkapp.com/server/1.0.0/swagger.json> |
| [mandrill](clients/email/mandrill.nu) | openapi | <https://api.apis.guru/v2/specs/mandrillapp.com/1.0/swagger.json>          |
| [resend](clients/email/resend.nu)     | openapi | <https://raw.githubusercontent.com/resend/resend-openapi/main/resend.yaml> |

## error-tracking

| Client                                             | Type    | Source                                                                                                          |
| -------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------------------------- |
| [sentry](clients/error-tracking/sentry.nu)         | openapi | <https://raw.githubusercontent.com/getsentry/sentry-api-schema/main/openapi-derefed.json>                       |
| [datadog-v1](clients/error-tracking/datadog-v1.nu) | openapi | <https://raw.githubusercontent.com/DataDog/datadog-api-client-python/master/.generator/schemas/v1/openapi.yaml> |
| [sumo-logic](clients/error-tracking/sumo-logic.nu) | openapi | <https://api.sumologic.com/docs/sumologic-api.yaml>                                                             |

## feature-flags

| Client                                                | Type    | Source                                                               |
| ----------------------------------------------------- | ------- | -------------------------------------------------------------------- |
| [launchdarkly](clients/feature-flags/launchdarkly.nu) | openapi | <https://api.apis.guru/v2/specs/launchdarkly.com/5.3.0/swagger.json> |
| [configcat](clients/feature-flags/configcat.nu)       | openapi | <https://api.apis.guru/v2/specs/configcat.com/v1/openapi.json>       |
| [flagsmith](clients/feature-flags/flagsmith.nu)       | openapi | <https://api.flagsmith.com/api/v1/swagger.json>                      |
| [unleash](clients/feature-flags/unleash.nu)           | openapi | <https://docs.getunleash.io/api/openapi.json>                        |

## finance

| Client                                                        | Type    | Source                                                                                          |
| ------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------- |
| [frankfurter](clients/finance/frankfurter.nu)                 | openapi | <https://api.frankfurter.app/openapi.json>                                                      |
| [polygon-io](clients/finance/polygon-io.nu)                   | openapi | <https://api.apis.guru/v2/specs/polygon.io/1.0.0/swagger.yaml>                                  |
| [exchangerate-api](clients/finance/exchangerate-api.nu)       | openapi | <https://api.apis.guru/v2/specs/exchangerate-api.com/4/openapi.yaml>                            |
| [consumer-finance](clients/finance/consumer-finance.nu)       | openapi | <https://api.apis.guru/v2/specs/consumerfinance.gov/1.0/swagger.yaml>                           |
| [mastercard-currency](clients/finance/mastercard-currency.nu) | openapi | <https://api.apis.guru/v2/specs/mastercard.com/CurrencyConversionCalculator/1.0.0/swagger.yaml> |
| [interzoid-currency](clients/finance/interzoid-currency.nu)   | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getcurrencyrate/1.0.0/openapi.yaml>               |

## gaming

| Client                                         | Type    | Source                                                                 |
| ---------------------------------------------- | ------- | ---------------------------------------------------------------------- |
| [pokeapi](clients/gaming/pokeapi.nu)           | graphql | <https://beta.pokeapi.co/graphql/v1beta>                               |
| [opendota](clients/gaming/opendota.nu)         | openapi | <https://api.opendota.com/api>                                         |
| [bungie](clients/gaming/bungie.nu)             | openapi | <https://raw.githubusercontent.com/Bungie-net/api/master/openapi.json> |
| [roblox-users](clients/gaming/roblox-users.nu) | openapi | <https://users.roblox.com/docs/json/v1>                                |
| [riot](clients/gaming/riot.nu)                 | openapi | <https://mingweisamuel.github.io/riotapi-schema/openapi-3.0.0.json>    |

## identity

| Client                                       | Type    | Source                                                              |
| -------------------------------------------- | ------- | ------------------------------------------------------------------- |
| [okta](clients/identity/okta.nu)             | openapi | <https://api.apis.guru/v2/specs/okta.local/1.0.0/openapi.json>      |
| [keycloak](clients/identity/keycloak.nu)     | openapi | <https://api.apis.guru/v2/specs/keycloak.local/1/openapi.json>      |
| [ory-kratos](clients/identity/ory-kratos.nu) | openapi | <https://raw.githubusercontent.com/ory/kratos/master/spec/api.json> |
| [ory-hydra](clients/identity/ory-hydra.nu)   | openapi | <https://raw.githubusercontent.com/ory/hydra/master/spec/api.json>  |

## incident

| Client                                         | Type    | Source                                                                                      |
| ---------------------------------------------- | ------- | ------------------------------------------------------------------------------------------- |
| [pagerduty](clients/incident/pagerduty.nu)     | openapi | <https://raw.githubusercontent.com/PagerDuty/api-schema/main/reference/REST/openapiv3.json> |
| [opsgenie](clients/incident/opsgenie.nu)       | openapi | <https://raw.githubusercontent.com/opsgenie/opsgenie-oas/master/swagger.json>               |
| [incident-io](clients/incident/incident-io.nu) | openapi | <https://docs.incident.io/openapi/latest.json>                                              |
| [zenduty](clients/incident/zenduty.nu)         | openapi | <https://apidocs.zenduty.com/openapi.json>                                                  |
| [ilert](clients/incident/ilert.nu)             | openapi | <https://api.ilert.com/api-docs/openapi.json>                                               |
| [uptime-com](clients/incident/uptime-com.nu)   | openapi | <https://uptime.com/api/v1/openapi/>                                                        |

## issue-tracking

| Client                                       | Type    | Source                                                                   |
| -------------------------------------------- | ------- | ------------------------------------------------------------------------ |
| [jira](clients/issue-tracking/jira.nu)       | openapi | <https://developer.atlassian.com/cloud/jira/platform/swagger-v3.v3.json> |
| [zendesk](clients/issue-tracking/zendesk.nu) | openapi | <https://developer.zendesk.com/zendesk/oas.yaml>                         |

## maps

| Client                                               | Type    | Source                                                                   |
| ---------------------------------------------------- | ------- | ------------------------------------------------------------------------ |
| [opencagedata](clients/maps/opencagedata.nu)         | openapi | <https://api.apis.guru/v2/specs/opencagedata.com/1/swagger.json>         |
| [here-positioning](clients/maps/here-positioning.nu) | openapi | <https://api.apis.guru/v2/specs/here.com/positioning/2.1.1/openapi.json> |
| [tomtom-search](clients/maps/tomtom-search.nu)       | openapi | <https://api.apis.guru/v2/specs/tomtom.com/search/1.0.0/openapi.json>    |
| [tomtom-routing](clients/maps/tomtom-routing.nu)     | openapi | <https://api.apis.guru/v2/specs/tomtom.com/routing/1.0.0/openapi.json>   |

## monitoring

| Client                                     | Type    | Source                                                                                                          |
| ------------------------------------------ | ------- | --------------------------------------------------------------------------------------------------------------- |
| [grafana](clients/monitoring/grafana.nu)   | openapi | <https://raw.githubusercontent.com/grafana/grafana/main/public/api-merged.json>                                 |
| [datadog](clients/monitoring/datadog.nu)   | openapi | <https://raw.githubusercontent.com/DataDog/datadog-api-client-python/master/.generator/schemas/v2/openapi.yaml> |
| [checkly](clients/monitoring/checkly.nu)   | openapi | <https://api.checklyhq.com/openapi.json>                                                                        |
| [kibana](clients/monitoring/kibana.nu)     | openapi | <https://raw.githubusercontent.com/elastic/kibana/main/oas_docs/output/kibana.serverless.yaml>                  |
| [netdata](clients/monitoring/netdata.nu)   | openapi | <https://raw.githubusercontent.com/netdata/netdata/master/src/web/api/netdata-swagger.yaml>                     |
| [influxdb](clients/monitoring/influxdb.nu) | openapi | <https://raw.githubusercontent.com/influxdata/openapi/master/contracts/cloud.yml>                               |

## music

| Client                                    | Type    | Source                                                                                       |
| ----------------------------------------- | ------- | -------------------------------------------------------------------------------------------- |
| [spotify](clients/music/spotify.nu)       | openapi | <https://raw.githubusercontent.com/sonallux/spotify-web-api/main/fixed-spotify-open-api.yml> |
| [soundcloud](clients/music/soundcloud.nu) | openapi | <https://api.apis.guru/v2/specs/soundcloud.com/1.0.0/openapi.json>                           |
| [tidal](clients/music/tidal.nu)           | openapi | <https://tidal-music.github.io/tidal-api-reference/tidal-api-oas.json>                       |
| [setlistfm](clients/music/setlistfm.nu)   | openapi | <https://api.apis.guru/v2/specs/setlist.fm/1.0/swagger.json>                                 |
| [spinitron](clients/music/spinitron.nu)   | openapi | <https://api.apis.guru/v2/specs/spinitron.com/1.0.0/openapi.json>                            |

## news

| Client                                                           | Type    | Source                                                                           |
| ---------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------- |
| [nytimes-top-stories](clients/news/nytimes-top-stories.nu)       | openapi | <https://api.apis.guru/v2/specs/nytimes.com/top_stories/2.0.0/openapi.json>      |
| [nytimes-books](clients/news/nytimes-books.nu)                   | openapi | <https://api.apis.guru/v2/specs/nytimes.com/books_api/3.0.0/openapi.json>        |
| [nytimes-article-search](clients/news/nytimes-article-search.nu) | openapi | <https://api.apis.guru/v2/specs/nytimes.com/article_search/1.0.0/openapi.json>   |
| [nytimes-archive](clients/news/nytimes-archive.nu)               | openapi | <https://api.apis.guru/v2/specs/nytimes.com/archive/1.0.0/openapi.json>          |
| [nytimes-most-popular](clients/news/nytimes-most-popular.nu)     | openapi | <https://api.apis.guru/v2/specs/nytimes.com/most_popular_api/2.0.0/openapi.json> |

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

## project-mgmt

| Client                                                                     | Type    | Source                                                                       |
| -------------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------- |
| [asana](clients/project-mgmt/asana.nu)                                     | openapi | <https://raw.githubusercontent.com/Asana/openapi/master/defs/asana_oas.yaml> |
| [trello](clients/project-mgmt/trello.nu)                                   | openapi | <https://developer.atlassian.com/cloud/trello/swagger.v3.json>               |
| [notion](clients/project-mgmt/notion.nu)                                   | openapi | <https://developers.notion.com/openapi.json>                                 |
| [linear](clients/project-mgmt/linear.nu)                                   | graphql | <https://api.linear.app/graphql>                                             |
| [jira-service-management](clients/project-mgmt/jira-service-management.nu) | openapi | <https://developer.atlassian.com/cloud/jira/service-desk/swagger.v3.json>    |

## public-data

| Client                                              | Type    | Source                                                       |
| --------------------------------------------------- | ------- | ------------------------------------------------------------ |
| [countries](clients/public-data/countries.nu)       | graphql | <https://countries.trevorblades.com/graphql>                 |
| [wikipedia](clients/public-data/wikipedia.nu)       | openapi | <https://en.wikipedia.org/api/rest_v1/?spec>                 |
| [open-library](clients/public-data/open-library.nu) | openapi | <https://openlibrary.org/static/openapi.json>                |
| [open5e](clients/public-data/open5e.nu)             | openapi | <https://api.open5e.com/schema/?format=json>                 |
| [tfl](clients/public-data/tfl.nu)                   | openapi | <https://api.tfl.gov.uk/swagger/docs/v1>                     |
| [met-norway](clients/public-data/met-norway.nu)     | openapi | <https://api.met.no/weatherapi/locationforecast/2.0/swagger> |

## sandbox

| Client                                                    | Type    | Source                                                                                  |
| --------------------------------------------------------- | ------- | --------------------------------------------------------------------------------------- |
| [petstore](clients/sandbox/petstore.nu)                   | openapi | <https://petstore3.swagger.io/api/v3/openapi.json>                                      |
| [reqres](clients/sandbox/reqres.nu)                       | openapi | <https://reqres.in/openapi.json>                                                        |
| [restful-booker](clients/sandbox/restful-booker.nu)       | openapi | <https://raw.githubusercontent.com/texttest/restful-booker/with_texttests/swagger.json> |
| [catfact](clients/sandbox/catfact.nu)                     | openapi | <https://catfact.ninja/docs>                                                            |
| [spaceflight-news](clients/sandbox/spaceflight-news.nu)   | openapi | <https://api.spaceflightnewsapi.net/v4/schema/>                                         |
| [train-travel](clients/sandbox/train-travel.nu)           | openapi | <https://raw.githubusercontent.com/bump-sh-examples/train-travel-api/main/openapi.yaml> |
| [realworld-conduit](clients/sandbox/realworld-conduit.nu) | openapi | <https://raw.githubusercontent.com/realworld-apps/realworld/main/specs/api/openapi.yml> |

## sci-fi

| Client                                                           | Type    | Source                                                                         |
| ---------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------ |
| [swapi](clients/sci-fi/swapi.nu)                                 | graphql | <https://swapi-graphql.netlify.app/graphql>                                    |
| [rick-and-morty](clients/sci-fi/rick-and-morty.nu)               | graphql | <https://rickandmortyapi.com/graphql>                                          |
| [dnd5e](clients/sci-fi/dnd5e.nu)                                 | openapi | <https://api.apis.guru/v2/specs/dnd5eapi.co/0.1/openapi.json>                  |
| [dnd5e-graphql](clients/sci-fi/dnd5e-graphql.nu)                 | graphql | <https://www.dnd5eapi.co/graphql/2014>                                         |
| [potterdb](clients/sci-fi/potterdb.nu)                           | graphql | <https://api.potterdb.com/graphql>                                             |
| [starwars-translations](clients/sci-fi/starwars-translations.nu) | openapi | <https://api.apis.guru/v2/specs/funtranslations.com/starwars/2.3/swagger.json> |

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

## social

| Client                                   | Type    | Source                                                                             |
| ---------------------------------------- | ------- | ---------------------------------------------------------------------------------- |
| [mastodon](clients/social/mastodon.nu)   | openapi | <https://api.apis.guru/v2/specs/mastodon.local/1.0/openapi.json>                   |
| [discourse](clients/social/discourse.nu) | openapi | <https://raw.githubusercontent.com/discourse/discourse_api_docs/main/openapi.json> |
| [misskey](clients/social/misskey.nu)     | openapi | <https://misskey.io/api.json>                                                      |

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

## telephony

| Client                                          | Type    | Source                                                                                     |
| ----------------------------------------------- | ------- | ------------------------------------------------------------------------------------------ |
| [twilio](clients/telephony/twilio.nu)           | openapi | <https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_api_v2010.json> |
| [telnyx](clients/telephony/telnyx.nu)           | openapi | <https://raw.githubusercontent.com/team-telnyx/openapi/master/openapi/spec3.json>          |
| [ringcentral](clients/telephony/ringcentral.nu) | openapi | <https://netstorage.ringcentral.com/dpw/api-reference/specs/rc-platform.yml>               |
| [bandwidth](clients/telephony/bandwidth.nu)     | openapi | <https://raw.githubusercontent.com/Bandwidth/node-sdk/main/bandwidth.yml>                  |
| [messagebird](clients/telephony/messagebird.nu) | openapi | <https://raw.githubusercontent.com/messagebird/openapi-specs/master/sms/openapi.yaml>      |

## testing

| Client                                                                        | Type    | Source                                                                            |
| ----------------------------------------------------------------------------- | ------- | --------------------------------------------------------------------------------- |
| [httpbin](clients/testing/httpbin.nu)                                         | openapi | <https://httpbin.org/spec.json>                                                   |
| [postman](clients/testing/postman.nu)                                         | openapi | <https://api.apis.guru/v2/specs/getpostman.com/1.20.0/openapi.json>               |
| [apis-guru](clients/testing/apis-guru.nu)                                     | openapi | <https://api.apis.guru/v2/specs/apis.guru/2.2.0/openapi.yaml>                     |
| [fungenerators-uuid](clients/testing/fungenerators-uuid.nu)                   | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/uuid/1.5/openapi.json>          |
| [fungenerators-fake-identity](clients/testing/fungenerators-fake-identity.nu) | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/fake-identity/1.5/swagger.json> |
| [fungenerators-random-facts](clients/testing/fungenerators-random-facts.nu)   | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/random-facts/1.5/openapi.json>  |

## translation

| Client                                                      | Type    | Source                                                                    |
| ----------------------------------------------------------- | ------- | ------------------------------------------------------------------------- |
| [deepl](clients/translation/deepl.nu)                       | openapi | <https://raw.githubusercontent.com/DeepLcom/openapi/main/openapi.json>    |
| [libretranslate](clients/translation/libretranslate.nu)     | openapi | <https://api.apis.guru/v2/specs/libretranslate.local/1.3.9/openapi.json>  |
| [google-translate](clients/translation/google-translate.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/translate/v3/openapi.json> |

## version-control

| Client                                            | Type    | Source                                                                                                               |
| ------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------------------- |
| [github](clients/version-control/github.nu)       | openapi | <https://raw.githubusercontent.com/github/rest-api-description/main/descriptions/api.github.com/api.github.com.json> |
| [gitlab](clients/version-control/gitlab.nu)       | openapi | <https://docs.gitlab.com/api/openapi/openapi_v2.yaml>                                                                |
| [bitbucket](clients/version-control/bitbucket.nu) | openapi | <https://api.bitbucket.org/swagger.json>                                                                             |
| [gitea](clients/version-control/gitea.nu)         | openapi | <https://gitea.com/swagger.v1.json>                                                                                  |
| [codeberg](clients/version-control/codeberg.nu)   | openapi | <https://codeberg.org/swagger.v1.json>                                                                               |
| [forgejo](clients/version-control/forgejo.nu)     | openapi | <https://v11.next.forgejo.org/swagger.v1.json>                                                                       |

## video

| Client                                                  | Type    | Source                                                                                    |
| ------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------- |
| [vimeo](clients/video/vimeo.nu)                         | openapi | <https://api.apis.guru/v2/specs/vimeo.com/3.4/openapi.json>                               |
| [youtube](clients/video/youtube.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/youtube/v3/openapi.json>                   |
| [youtube-reporting](clients/video/youtube-reporting.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/youtubereporting/v1/openapi.json>          |
| [twitch](clients/video/twitch.nu)                       | openapi | <https://raw.githubusercontent.com/DmitryScaletta/twitch-api-swagger/master/openapi.json> |

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
