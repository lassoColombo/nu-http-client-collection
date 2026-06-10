# Available clients

_This file is auto-generated from `clients.yaml` by `scripts/generate.nu`. Do not edit by hand._

## ai

| Client                         | Type    | Source                                                                        |
| ------------------------------ | ------- | ----------------------------------------------------------------------------- |
| [openai](clients/ai/openai.nu) | openapi | <https://raw.githubusercontent.com/openai/openai-openapi/master/openapi.yaml> |

## anime

| Client                              | Type    | Source                       |
| ----------------------------------- | ------- | ---------------------------- |
| [anilist](clients/anime/anilist.nu) | graphql | <https://graphql.anilist.co> |

## cdn

| Client                                  | Type    | Source                                                                       |
| --------------------------------------- | ------- | ---------------------------------------------------------------------------- |
| [cloudflare](clients/cdn/cloudflare.nu) | openapi | <https://raw.githubusercontent.com/cloudflare/api-schemas/main/openapi.json> |

## chat

| Client                         | Type    | Source                                                                                                |
| ------------------------------ | ------- | ----------------------------------------------------------------------------------------------------- |
| [slack](clients/chat/slack.nu) | openapi | <https://raw.githubusercontent.com/slackapi/slack-api-specs/master/web-api/slack_web_openapi_v2.json> |

## cloud

| Client                                        | Type    | Source                                                                                                  |
| --------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------- |
| [digitalocean](clients/cloud/digitalocean.nu) | openapi | <https://raw.githubusercontent.com/digitalocean/openapi/main/specification/DigitalOcean-public.v2.yaml> |

## commerce

| Client                               | Type    | Source                                                                               |
| ------------------------------------ | ------- | ------------------------------------------------------------------------------------ |
| [square](clients/commerce/square.nu) | openapi | <https://raw.githubusercontent.com/square/connect-api-specification/master/api.json> |

## container-orchestration

| Client                                                      | Type    | Source                                                                                         |
| ----------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------- |
| [kubernetes](clients/container-orchestration/kubernetes.nu) | openapi | <https://raw.githubusercontent.com/kubernetes/kubernetes/master/api/openapi-spec/swagger.json> |

## containers

| Client                                 | Type    | Source                                                                |
| -------------------------------------- | ------- | --------------------------------------------------------------------- |
| [docker](clients/containers/docker.nu) | openapi | <https://raw.githubusercontent.com/moby/moby/master/api/swagger.yaml> |

## error-tracking

| Client                                     | Type    | Source                                                                                    |
| ------------------------------------------ | ------- | ----------------------------------------------------------------------------------------- |
| [sentry](clients/error-tracking/sentry.nu) | openapi | <https://raw.githubusercontent.com/getsentry/sentry-api-schema/main/openapi-derefed.json> |

## finance

| Client                                        | Type    | Source                                     |
| --------------------------------------------- | ------- | ------------------------------------------ |
| [frankfurter](clients/finance/frankfurter.nu) | openapi | <https://api.frankfurter.app/openapi.json> |

## gaming

| Client                               | Type    | Source                                   |
| ------------------------------------ | ------- | ---------------------------------------- |
| [pokeapi](clients/gaming/pokeapi.nu) | graphql | <https://beta.pokeapi.co/graphql/v1beta> |

## incident

| Client                                     | Type    | Source                                                                                      |
| ------------------------------------------ | ------- | ------------------------------------------------------------------------------------------- |
| [pagerduty](clients/incident/pagerduty.nu) | openapi | <https://raw.githubusercontent.com/PagerDuty/api-schema/main/reference/REST/openapiv3.json> |

## issue-tracking

| Client                                 | Type    | Source                                                                   |
| -------------------------------------- | ------- | ------------------------------------------------------------------------ |
| [jira](clients/issue-tracking/jira.nu) | openapi | <https://developer.atlassian.com/cloud/jira/platform/swagger-v3.v3.json> |

## monitoring

| Client                                   | Type    | Source                                                                          |
| ---------------------------------------- | ------- | ------------------------------------------------------------------------------- |
| [grafana](clients/monitoring/grafana.nu) | openapi | <https://raw.githubusercontent.com/grafana/grafana/main/public/api-merged.json> |

## music

| Client                              | Type    | Source                                                                                       |
| ----------------------------------- | ------- | -------------------------------------------------------------------------------------------- |
| [spotify](clients/music/spotify.nu) | openapi | <https://raw.githubusercontent.com/sonallux/spotify-web-api/main/fixed-spotify-open-api.yml> |

## payments

| Client                               | Type    | Source                                                                       |
| ------------------------------------ | ------- | ---------------------------------------------------------------------------- |
| [stripe](clients/payments/stripe.nu) | openapi | <https://raw.githubusercontent.com/stripe/openapi/master/openapi/spec3.json> |

## project-mgmt

| Client                                 | Type    | Source                                                                       |
| -------------------------------------- | ------- | ---------------------------------------------------------------------------- |
| [asana](clients/project-mgmt/asana.nu) | openapi | <https://raw.githubusercontent.com/Asana/openapi/master/defs/asana_oas.yaml> |

## public-data

| Client                                        | Type    | Source                                       |
| --------------------------------------------- | ------- | -------------------------------------------- |
| [countries](clients/public-data/countries.nu) | graphql | <https://countries.trevorblades.com/graphql> |

## sandbox

| Client                                  | Type    | Source                                             |
| --------------------------------------- | ------- | -------------------------------------------------- |
| [petstore](clients/sandbox/petstore.nu) | openapi | <https://petstore3.swagger.io/api/v3/openapi.json> |

## sci-fi

| Client                           | Type    | Source                                      |
| -------------------------------- | ------- | ------------------------------------------- |
| [swapi](clients/sci-fi/swapi.nu) | graphql | <https://swapi-graphql.netlify.app/graphql> |

## search

| Client                                   | Type    | Source                                                                              |
| ---------------------------------------- | ------- | ----------------------------------------------------------------------------------- |
| [typesense](clients/search/typesense.nu) | openapi | <https://raw.githubusercontent.com/typesense/typesense-api-spec/master/openapi.yml> |

## storage

| Client                        | Type    | Source                                                                |
| ----------------------------- | ------- | --------------------------------------------------------------------- |
| [box](clients/storage/box.nu) | openapi | <https://raw.githubusercontent.com/box/box-openapi/main/openapi.json> |

## telephony

| Client                                | Type    | Source                                                                                     |
| ------------------------------------- | ------- | ------------------------------------------------------------------------------------------ |
| [twilio](clients/telephony/twilio.nu) | openapi | <https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_api_v2010.json> |

## testing

| Client                                | Type    | Source                          |
| ------------------------------------- | ------- | ------------------------------- |
| [httpbin](clients/testing/httpbin.nu) | openapi | <https://httpbin.org/spec.json> |

## version-control

| Client                                      | Type    | Source                                                                                                               |
| ------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------------------- |
| [github](clients/version-control/github.nu) | openapi | <https://raw.githubusercontent.com/github/rest-api-description/main/descriptions/api.github.com/api.github.com.json> |

## weather

| Client                                        | Type    | Source                                 |
| --------------------------------------------- | ------- | -------------------------------------- |
| [weather-gov](clients/weather/weather-gov.nu) | openapi | <https://api.weather.gov/openapi.json> |
