# nu-http-clients

A registry of Nushell HTTP clients, generated from OpenAPI / Swagger / GraphQL specs by
[nu-http-client-generator](https://github.com/lassoColombo/nu-http-client-generator).

You can use the clients in this repository as you wish or fork this to create your own collection.

## Available clients

<!-- BEGIN CLIENTS TABLE -->
| Client                                  | Type    | Source                                                                                                               |
| --------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------------------- |
| [petstore](clients/petstore.nu)         | openapi | <https://petstore3.swagger.io/api/v3/openapi.json>                                                                   |
| [httpbin](clients/httpbin.nu)           | openapi | <https://httpbin.org/spec.json>                                                                                      |
| [countries](clients/countries.nu)       | graphql | <https://countries.trevorblades.com/graphql>                                                                         |
| [swapi](clients/swapi.nu)               | graphql | <https://swapi-graphql.netlify.app/graphql>                                                                          |
| [anilist](clients/anilist.nu)           | graphql | <https://graphql.anilist.co>                                                                                         |
| [pokeapi](clients/pokeapi.nu)           | graphql | <https://beta.pokeapi.co/graphql/v1beta>                                                                             |
| [weather-gov](clients/weather-gov.nu)   | openapi | <https://api.weather.gov/openapi.json>                                                                               |
| [exchangerate](clients/exchangerate.nu) | openapi | <https://api.exchangerate.host/openapi.json>                                                                         |
| [github](clients/github.nu)             | openapi | <https://raw.githubusercontent.com/github/rest-api-description/main/descriptions/api.github.com/api.github.com.json> |
| [gitlab](clients/gitlab.nu)             | openapi | <https://gitlab.com/gitlab-org/gitlab/-/raw/master/doc/api/openapi/openapi_v2.yaml>                                  |
| [bitbucket](clients/bitbucket.nu)       | openapi | <https://api.bitbucket.org/swagger.json>                                                                             |
| [digitalocean](clients/digitalocean.nu) | openapi | <https://raw.githubusercontent.com/digitalocean/openapi/main/specification/DigitalOcean-public.v2.yaml>              |
| [cloudflare](clients/cloudflare.nu)     | openapi | <https://raw.githubusercontent.com/cloudflare/api-schemas/main/openapi.json>                                         |
| [openai](clients/openai.nu)             | openapi | <https://raw.githubusercontent.com/openai/openai-openapi/master/openapi.yaml>                                        |
| [stripe](clients/stripe.nu)             | openapi | <https://raw.githubusercontent.com/stripe/openapi/master/openapi/spec3.json>                                         |
| [square](clients/square.nu)             | openapi | <https://raw.githubusercontent.com/square/connect-api-specification/master/api.json>                                 |
| [slack](clients/slack.nu)               | openapi | <https://raw.githubusercontent.com/slackapi/slack-api-specs/master/web-api/slack_web_openapi_v2.json>                |
| [discord](clients/discord.nu)           | openapi | <https://raw.githubusercontent.com/discord/discord-api-spec/main/specs/openapi.json>                                 |
| [twilio](clients/twilio.nu)             | openapi | <https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_api_v2010.json>                           |
| [asana](clients/asana.nu)               | openapi | <https://raw.githubusercontent.com/Asana/openapi/master/defs/asana_oas.yaml>                                         |
| [pagerduty](clients/pagerduty.nu)       | openapi | <https://raw.githubusercontent.com/PagerDuty/api-schema/main/reference/REST/openapiv3.json>                          |
| [jira](clients/jira.nu)                 | openapi | <https://developer.atlassian.com/cloud/jira/platform/swagger-v3.v3.json>                                             |
| [box](clients/box.nu)                   | openapi | <https://raw.githubusercontent.com/box/box-openapi/main/openapi.json>                                                |
| [spotify](clients/spotify.nu)           | openapi | <https://raw.githubusercontent.com/sonallux/spotify-web-api/main/fixed-spotify-open-api.yml>                         |
<!-- END CLIENTS TABLE -->
## Using a generated client

```nushell
use clients/countries.nu
countries query country "IT" --fields [name capital emoji]

use clients/petstore.nu
petstore pet get-by-id 1 --token $env.MY_TOKEN
```

Generated clients are namespaced by filename, so they don't shadow nushell builtins like
`get`/`delete`. See each client's `--help` for the full command list.

## Building your own collection

Append an entry to `clients.yaml`:

```yaml
- name: my-service                          # → clients/my-service.nu
  type: openapi                             # or "graphql"
  source: https://example.com/openapi.json  # URL or local file
  flags:                                    # forwarded to `http-gen <type>`; use exact kebab-case flag names
    tags: [users, billing]
    exclude-deprecated: true
```

Then trigger the workflow (see below). The action commits `clients/my-service.nu` for you.

#### Flag value shapes

The driver script forwards `flags` to the generator with the right shape:

| YAML type | Becomes                  | Example                                   |
| --------- | ------------------------ | ----------------------------------------- |
| bool      | switch (when `true`)     | `exclude-deprecated: true`                |
| string    | `--flag "value"`         | `default-base-url: https://example.com`   |
| list      | `--flag [a b c]`         | `methods: [get, post]`                    |
| record    | `--flag {key: value}`    | `default-headers: {X-Tenant-Id: acme}`    |

See the [generator README](https://github.com/lassoColombo/nu-http-client-generator) for the full flag reference.

## Running it

#### Via GitHub Actions

Trigger **Generate clients** under the **Actions** tab. Inputs:

- **client** — name from `clients.yaml`, or `all` (default) to regenerate everything.
- **generator_ref** — branch/tag/SHA of `nu-http-client-generator` to use (default `main`).

The workflow commits and pushes any changes back to `main`. If nothing changed, it's a no-op.

It also auto-runs on pushes to `main` that touch `clients.yaml`, `scripts/generate.nu`,
or the workflow file itself.

#### Locally

```nushell
# one-time: clone the generator next to the script
git clone https://github.com/lassoColombo/nu-http-client-generator _generator

# regenerate everything
nu scripts/generate.nu

# regenerate a single client
nu scripts/generate.nu countries
```
