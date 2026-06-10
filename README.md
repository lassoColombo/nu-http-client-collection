# nu-http-client-collection

A collection of Nushell HTTP clients generated from OpenAPI, Swagger, and GraphQL specifications using [nu-http-client-generator](https://github.com/lassoColombo/nu-http-client-generator).

You can use the clients in this repository as you wish or use the generator script to create your own collection.

See [`CLIENTS.md`](CLIENTS.md) for the full list of clients in the collection.

---

## Using a client

The nu-http-client-generator generates regular Nushell modules:
```nu
use clients/public-data/countries.nu
countries query country "IT" --fields [name capital emoji]

use clients/sandbox/petstore.nu
petstore pet get-by-id 1 --token $env.MY_TOKEN
```

> This repository intentionally generates clients from complete specifications. That makes them larger than what many real-world workflows require. If you only need a subset of an API, consider trimming the generated module or generating a smaller client.

---

## Building your own collection

This repository can be forked and used as a client registry.
Define your APIs in `clients.yaml`:

```yaml
clients:
  my-category:
    - name: my-service
      type: openapi
      source: https://example.com/openapi.json
      flags:
        default-base-url: https://example.com
```

Each entry produces a Nushell module under:

```text
clients/<category>/<name>.nu
```

Client names must be globally unique. The generation workflow identifies clients by name only, regardless of category.

### Generator flags

The `flags` section is passed directly to the generator:

| YAML type | Generator argument |
| --- | --- |
| `bool` | switch flag when `true` |
| `string` | `--flag "value"` |
| `list` | `--flag [a b c]` |
| `record` | `--flag {key: value}` |


---

## Generating clients

### GitHub Actions

The repository includes a workflow that can regenerate one client or the entire collection.

Run **Generate clients** from the **Actions** tab and provide:

- **client** — a client name from `clients.yaml`, or `all` (default)
- **generator_ref** — branch, tag, or commit of `nu-http-client-generator` (default: `main`)

The workflow commits generated changes automatically. If regeneration produces no changes, nothing is pushed.

Generation is also triggered automatically whenever changes affecting generation are pushed to `main`.

### Local generation


```nu
# Clone the generator alongside this repository:
git clone https://github.com/lassoColombo/nu-http-client-generator _generator
# If you already use the generator you can symlink it
ln -s /path/to/nu-http-client-generator _generator
```

Regenerate the entire collection:

```nu
nu scripts/generate.nu
```

Or regenerate a single client:

```nu
nu scripts/generate.nu countries
```
