# nu-http-client-collection

Your collection of Nushell HTTP clients, automatically generated from API specifications.

<!-- STATS:START -->
**2,517** clients · **123,336** operations · **4.5M** lines of Nu
<!-- STATS:END -->

> [The full list](CLIENTS.md)

---

- [Purpose(s)](#purpose(s))
  - [A community registry](#a-community-registry)
  - [Your personal collection](#your-personal-collection)
- [1 - Using a client from the registry](#1---using-a-client-from-the-registry)
  - [Manually trimming down a client](#manually-trimming-down-a-client)
- [2 - Forking for your own collection](#2---forking-for-your-own-collection)
  - [Editing clients.yaml](#editing-clients.yaml)
  - [Regenerating the collection](#regenerating-the-collection)
  - [The bundled GitHub action](#the-bundled-github-action)
- [Contributing](#contributing)

---

## Purpose(s)

#### A community registry

This repository acts as a public registry of HTTP clients for the community to use as it pleases. It mirrors public API registries and generates a Nushell client for every spec they expose.

The only supported registry, as of now, is [apis.guru](https://apis.guru/).


#### Your personal collection

This repository lets you maintain your own polished collection of HTTP clients and keep it up to date as upstream APIs evolve.

The idea is simple:
- You define a list of wanted clients in `clients.yaml`: where to get the specification, what to generate and how.
- A GitHub action regenerates the collection every night into the `clients/` directory.
- You use the clients in your day to day workflow, in your scripts or wherever you like.

---

## 1 - Using a client from the registry

Of course you are free to browse this registry and to grab any client as you please.  
This repository uses the [nu-http-client-generator](https://github.com/lassoColombo/nu-http-client-generator) to generate the clients. The generator generates 🙃 regular nushell modules you can simply `use`:
```nu
use petstore.nu
petstore pet-find-by-status findPetsByStatus --status available | where status == "available"
```

A disclaimer:
> This repository intentionally generates clients from complete specifications. That makes them larger than what many real-world workflows require. If you only need a subset of an API, consider trimming the generated module or generating a smaller client using the [nu-http-client-generator](https://github.com/lassoColombo/nu-http-client-generator).

### Manually trimming down a client

The nu-http-client-generator generates one exported function per operation (verb + endpoint).
All generated functions make use of a set of common helper functions and completers defined at the top of the module.

So, the simplest way is:
1) copy all the unexported functions defined at the top of the module
2) copy the exported functions you need

This may copy some extra helpers and completers you don't need. You can optionally remove those as well by inspecting the content of the trimmed module.

## 2 - Forking for your own collection

1. Fork and clone.
2. Swap which workflow runs nightly.
    ```nu
    gh workflow disable update-registry.yml  # disables the workflow that mirrors apis.guru
    gh workflow enable update-collection.yml # optional, enables the workflow that regenerates your collection (see below)
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

### Regenerating the collection

The regeneration is just three small Nushell scripts called in order:

| Script                  | What it does                                                                                                              |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `scripts/generate.nu`   | Generates every client listed in `clients.yaml` against the current upstream spec. Reads flags per entry.                 |
| `scripts/template.nu`   | Refreshes `CLIENTS.md` and the stats block in `README.md` based on what landed on disk.                                   |
| `scripts/ci.nu`         | Commits whatever changed under `clients/`, `clients.yaml`, `CLIENTS.md`, `README.md`, then tags `v<UTC-date>`.             |

You can drive them yourself — from a host cron, a self-hosted runner, a Buildkite pipeline, whatever — or use the bundled GitHub action described below.

### The bundled GitHub action

`update-collection.yml` runs every day at 00:00 UTC. It's the smallest reasonable wrapper around the scripts above:

1. Checks out the repo and installs Nushell.
2. Clones the [generator](https://github.com/lassoColombo/nu-http-client-generator) at the pinned ref into `_generator/`.
3. Snapshots HEAD so the final step can tell whether anything actually changed.
4. Runs `generate.nu --force`. Marked `continue-on-error: true` so a flaky upstream spec doesn't poison the rest of the steps — failing entries show up as **Pending** in [CLIENTS.md](CLIENTS.md).
5. Runs `template.nu` to refresh the listings, even when generation partially failed.
6. Runs `ci.nu commit-and-push` to commit whatever moved.
7. Runs `ci.nu tag-datever` to tag `v<UTC-date>` — only if the previous step produced a new commit, so re-runs against unchanged upstreams don't accumulate empty tags.

Entries removed from `clients.yaml` are NOT deleted from `clients/` on disk — they're marked **Dismissed** in [CLIENTS.md](CLIENTS.md) instead and must be manually deleted.

---

## Contributing

Issues and PRs are welcome. For generator behavior or output shape, open them against [nu-http-client-generator](https://github.com/lassoColombo/nu-http-client-generator) instead.
