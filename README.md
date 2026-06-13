# nu-http-client-collection

Your collection of Nushell HTTP clients, automatically generated from API specifications.

---

## Purpose(s)

#### 1 - Your personal collection

This repository lets you maintain your own collection of HTTP clients and keep it up to date as upstream APIs evolve.

The idea is simple:
- You define a list of wanted clients in `clients.yaml`: where to get the specification, what to generate and how.
- A GitHub action regenerates the collection every night into the `clients/` directory.
- You use the clients in your day to day workflow, in your scripts or wherever you like.

#### 2 - A community registry

This repository also acts as a public registry of HTTP clients for the community to use as it pleases. It mirrors public API registries and generates a Nushell client for every spec they expose.

The only supported registry, as of now, is [apis.guru](https://apis.guru/).

Skim [CLIENTS.md](CLIENTS.md) for the full list of available clients.

## Forking for your own collection

1. Fork and clone.
2. Swap which workflow runs nightly.
    ```nu
    gh workflow disable update-registry.yml  # disables the workflow that mirrors apis.guru
    gh workflow enable update-collection.yml # enables the workflow that regenerates your collection
    ```
3. Edit clients.yaml defining your own entries.
4. Clone the generator alongside this repo.
    ```nu
    git clone https://github.com/lassoColombo/nu-http-client-generator _generator
    ```
5. Generate locally (or push and let update-collection.yml do it nightly).
    ```nu
    nu scripts/generate.nu
    ```
6. Add the clients directory to your NU_LIB_DIRS so you can `use` the clients
    ```nu
    $env.NU_LIB_DIRS = $env.NU_LIB_DIRS | append ~/path/to/the/clients/directory
    ```

### Editing clients.yaml

Clients.yaml is a list of entries, where each entry has the following shape:

```yaml
clients:
  - name: my-api               # output file: clients/my-api.nu
    type: openapi              # or `graphql`
    source: https://example.com/openapi.json
    flags:                     # optional - passed through to the generator
      default-base-url: https://api.example.com
      token-env-var: MY_API_TOKEN
```

Flags control what gets generated and how. Common uses:

- Limit generation to a subset of operations, so your client contains only what you need.
- Tune naming conventions and argument shapes of the generated functions.
- Pick the authentication strategy (token env var, basic auth, etc.).
- Set a default base URL.
- Enable custom completers for IDs, regions, or other domain-specific values.

Flags are simply passed through to the generator for that specific client. See the [nu-http-client-generator](https://github.com/lassoColombo/nu-http-client-generator) docs for the full reference.

### Using the workflow

`update-collection.yml` runs every day at 04:00 UTC. It regenerates every client listed in `clients.yaml` against the current upstream spec, commits the result, and tags `v<UTC-date>` - so any change in an upstream API flows into your collection overnight and you can always roll back to a known-good day.

It commits whatever it managed to produce, even if some clients failed to generate (those entries show up as **Pending** in [CLIENTS.md](CLIENTS.md)). Entries removed from `clients.yaml` are NOT deleted from `clients/` on disk - they're marked **Dismissed** there instead and must be manually deleted.

Of course you are free to customize the `ci.nu` script or to use it in your preferred scheduler.

#### Triggering the workflow by hand

```nu
gh workflow run update-collection.yml
```

Or from the Actions tab in the GitHub UI. Two optional inputs:

| Input            | Default | What it does                                                                                                              |
| ---------------- | ------- | ------------------------------------------------------------------------------------------------------------------------- |
| `generator_ref`  | `main`  | Pin the [generator](https://github.com/lassoColombo/nu-http-client-generator) to a branch, tag, or SHA.                   |
| `jobs`           | `8`     | How many clients to generate in parallel.                                                                                 |


---

## Using a client from this repo

Of course you are free to browse this registry and to grab any client as you please.

A disclaimer:
> This repository intentionally generates clients from complete specifications. That makes them larger than what many real-world workflows require. If you only need a subset of an API, consider trimming the generated module or generating a smaller client using the [nu-http-client-generator](https://github.com/lassoColombo/nu-http-client-generator).

### Manually trimming down a client

The [nu-http-client-generator](https://github.com/lassoColombo/nu-http-client-generator) generates one exported function per operation (verb + endpoint).
All generated functions make use of a set of common helper functions and completers defined at the top of the module.

So, the simplest way is:
1) copy all the unexported functions defined at the top of the module
2) copy the exported functions you need
