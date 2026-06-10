# nu-http-client-collection

A registry of Nushell HTTP clients, generated from OpenAPI / Swagger / GraphQL specs by [nu-http-client-generator](https://github.com/lassoColombo/nu-http-client-generator).

You can use the clients in this repository as you wish or use the generator script to create your own collection.  
See [`CLIENTS.md`](CLIENTS.md) for the full list of clients in the collection.

## Using a generated client

```nushell
use clients/public-data/countries.nu
countries query country "IT" --fields [name capital emoji]

use clients/sandbox/petstore.nu
petstore pet get-by-id 1 --token $env.MY_TOKEN
```

##### Disclaimer:  
This repository collects clients generated from the whole specification. This means that they tend to be quite heavy and overkill.  
If you don't need the whole client it is suggested to either manually strip it down or to use the generator to build a minimal version.

## Building your own collection

Fork this repository and specify your collection in `clients.yaml`:

```yaml
clients:
  my-category:
    - name: my-service                        # → clients/my-category/my-service.nu
      type: openapi                           # or "graphql"
      source: https://example.com/openapi.json
      flags:                                  # render-only; filter flags are forbidden
        default-base-url: https://example.com
```

Then trigger the workflow (see below). The action commits the generated file for you.
Client names must be unique across categories — the workflow's `client` input is a bare name.

#### Flag value shapes

The driver script forwards `flags` to the generator with the right shape:

| YAML type | Becomes                  | Example                                   |
| --------- | ------------------------ | ----------------------------------------- |
| bool      | switch (when `true`)     | `no-introspection: true`                  |
| string    | `--flag "value"`         | `default-base-url: https://example.com`   |
| list      | `--flag [a b c]`         | `default-headers: [X-Foo: bar]`           |
| record    | `--flag {key: value}`    | `default-headers: {X-Tenant-Id: acme}`    |


## Running the generator

#### Via GitHub Actions

Trigger **Generate clients** under the **Actions** tab. 

Inputs:
- **client** — name from `clients.yaml`, or `all` (default) to regenerate everything.
- **generator_ref** — branch/tag/SHA of `nu-http-client-generator` to use (default `main`).

The workflow commits and pushes any changes back to `main`. If nothing changed, does nothing.  
It also auto-runs on pushes to `main` that touch `clients.yaml`, `scripts/generate.nu`, or the workflow file itself.

#### Locally

```nushell
# one-time: clone the generator next to the script
git clone https://github.com/lassoColombo/nu-http-client-generator _generator

# regenerate everything
nu scripts/generate.nu

# regenerate a single client
nu scripts/generate.nu countries
```
