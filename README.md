# nu-http-client-collection

A collection of Nushell HTTP clients generated from OpenAPI, Swagger, and GraphQL specifications using [nu-http-client-generator](https://github.com/lassoColombo/nu-http-client-generator).

You can use the clients in this repository as you wish or use the generator script to create your own collection.

See [The collection](#the-collection) at the bottom of this file for the full list of clients.

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

Sources (URL or file path) must be globally unique — two entries pointing at the same spec are rejected. Client names only need to be unique within a category. When invoking the workflow with `--name`, every matching client across categories is regenerated.

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

---

## The collection

_This section is auto-generated from `clients.yaml` by `scripts/generate.nu`. Do not edit by hand._

This collection contains 1895 clients.

### advertising

| Client                                                                                  | Type    | Source                                                                                  |
| --------------------------------------------------------------------------------------- | ------- | --------------------------------------------------------------------------------------- |
| [criteo-marketing-solutions](clients/advertising/criteo-marketing-solutions.nu)         | openapi | <https://api.criteo.com/2023-10/marketingsolutions/open-api-specifications.json>        |
| [criteo-retail-media](clients/advertising/criteo-retail-media.nu)                       | openapi | <https://api.criteo.com/2023-10/retailmedia/open-api-specifications.json>               |
| [google-ad-exchange-buyer](clients/advertising/google-ad-exchange-buyer.nu)             | openapi | <https://api.apis.guru/v2/specs/googleapis.com/adexchangebuyer/v1.4/openapi.json>       |
| [google-ad-exchange-buyer2](clients/advertising/google-ad-exchange-buyer2.nu)           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/adexchangebuyer2/v2beta1/openapi.json>   |
| [google-admob](clients/advertising/google-admob.nu)                                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/admob/v1beta/openapi.json>               |
| [google-adsense](clients/advertising/google-adsense.nu)                                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/adsense/v1.4/openapi.json>               |
| [google-adsense-host](clients/advertising/google-adsense-host.nu)                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/adsensehost/v4.1/openapi.json>           |
| [google-displayvideo](clients/advertising/google-displayvideo.nu)                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/displayvideo/v2/openapi.json>            |
| [google-doubleclick-bid-manager](clients/advertising/google-doubleclick-bid-manager.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/doubleclickbidmanager/v1.1/openapi.json> |
| [google-doubleclick-search](clients/advertising/google-doubleclick-search.nu)           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/doubleclicksearch/v2/openapi.json>       |
| [google-reseller](clients/advertising/google-reseller.nu)                               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/reseller/v1/openapi.json>                |
| [google-search-ads-360](clients/advertising/google-search-ads-360.nu)                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/searchads360/v0/openapi.json>            |
| [google-tagmanager](clients/advertising/google-tagmanager.nu)                           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/tagmanager/v2/openapi.json>              |
| [nativeads](clients/advertising/nativeads.nu)                                           | openapi | <https://api.apis.guru/v2/specs/nativeads.com/1.0.0/swagger.json>                       |
| [pinterest-ads](clients/advertising/pinterest-ads.nu)                                   | openapi | <https://raw.githubusercontent.com/pinterest/api-description/main/v5/openapi.yaml>      |
| [postmark-account](clients/advertising/postmark-account.nu)                             | openapi | <https://api.apis.guru/v2/specs/postmarkapp.com/account/0.9.0/swagger.json>             |

### ai

| Client                                                                                   | Type    | Source                                                                                                                                                |
| ---------------------------------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| [ably-platform](clients/ai/ably-platform.nu)                                             | openapi | <https://api.apis.guru/v2/specs/ably.io/platform/1.1.0/openapi.json>                                                                                  |
| [adafruit-io](clients/ai/adafruit-io.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/adafruit.com/2.0.0/swagger.json>                                                                                      |
| [aiception](clients/ai/aiception.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/aiception.com/1.0.0/swagger.json>                                                                                     |
| [anthropic](clients/ai/anthropic.nu)                                                     | openapi | <https://storage.googleapis.com/stainless-sdk-openapi-specs/anthropic/anthropic-5ce93251152bd7c4c288dacdf5a445383825ba50bc472ff9e9821ee9455e3564.yml> |
| [assemblyai](clients/ai/assemblyai.nu)                                                   | openapi | <https://www.assemblyai.com/docs/openapi.json>                                                                                                        |
| [aws-lex-models](clients/ai/aws-lex-models.nu)                                           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/lex-models/2017-04-19/openapi.json>                                                                     |
| [aws-machinelearning](clients/ai/aws-machinelearning.nu)                                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/machinelearning/2014-12-12/openapi.json>                                                                |
| [aws-personalize](clients/ai/aws-personalize.nu)                                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/personalize/2018-05-22/openapi.json>                                                                    |
| [aws-polly](clients/ai/aws-polly.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/polly/2016-06-10/openapi.json>                                                                          |
| [aws-rekognition](clients/ai/aws-rekognition.nu)                                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/rekognition/2016-06-27/openapi.json>                                                                    |
| [aws-sagemaker](clients/ai/aws-sagemaker.nu)                                             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/sagemaker/2017-07-24/openapi.json>                                                                      |
| [aws-textract](clients/ai/aws-textract.nu)                                               | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/textract/2018-06-27/openapi.json>                                                                       |
| [azure-cognitive-anomaly-detector](clients/ai/azure-cognitive-anomaly-detector.nu)       | openapi | <https://api.apis.guru/v2/specs/azure.com/cognitiveservices-AnomalyDetector/1.0/swagger.json>                                                         |
| [azure-cognitive-anomaly-finder](clients/ai/azure-cognitive-anomaly-finder.nu)           | openapi | <https://api.apis.guru/v2/specs/azure.com/cognitiveservices-AnomalyFinder/2.0/swagger.json>                                                           |
| [azure-cognitive-content-moderator](clients/ai/azure-cognitive-content-moderator.nu)     | openapi | <https://api.apis.guru/v2/specs/azure.com/cognitiveservices-ContentModerator/1.0/swagger.json>                                                        |
| [azure-cognitive-face](clients/ai/azure-cognitive-face.nu)                               | openapi | <https://api.apis.guru/v2/specs/azure.com/cognitiveservices-Face/1.0/swagger.json>                                                                    |
| [azure-cognitive-form-recognizer](clients/ai/azure-cognitive-form-recognizer.nu)         | openapi | <https://api.apis.guru/v2/specs/azure.com/cognitiveservices-FormRecognizer/2.0-preview/swagger.json>                                                  |
| [azure-cognitive-ink-recognizer](clients/ai/azure-cognitive-ink-recognizer.nu)           | openapi | <https://api.apis.guru/v2/specs/azure.com/cognitiveservices-InkRecognizer/1.0/swagger.json>                                                           |
| [azure-cognitive-luis-authoring](clients/ai/azure-cognitive-luis-authoring.nu)           | openapi | <https://api.apis.guru/v2/specs/azure.com/cognitiveservices-LUIS-Authoring/3.0-preview/swagger.json>                                                  |
| [azure-cognitive-luis-programmatic](clients/ai/azure-cognitive-luis-programmatic.nu)     | openapi | <https://api.apis.guru/v2/specs/azure.com/cognitiveservices-LUIS-Programmatic/v2.0/swagger.json>                                                      |
| [azure-cognitive-personalizer](clients/ai/azure-cognitive-personalizer.nu)               | openapi | <https://api.apis.guru/v2/specs/azure.com/cognitiveservices-Personalizer/v1.0/swagger.json>                                                           |
| [azure-cognitive-qnamaker](clients/ai/azure-cognitive-qnamaker.nu)                       | openapi | <https://api.apis.guru/v2/specs/azure.com/cognitiveservices-QnAMaker/4.0/swagger.json>                                                                |
| [azure-cognitive-text-analytics](clients/ai/azure-cognitive-text-analytics.nu)           | openapi | <https://api.apis.guru/v2/specs/azure.com/cognitiveservices-TextAnalytics/v2.1-preview/swagger.json>                                                  |
| [azure-machinelearning-webservices](clients/ai/azure-machinelearning-webservices.nu)     | openapi | <https://api.apis.guru/v2/specs/azure.com/machinelearning-webservices/2017-01-01/swagger.json>                                                        |
| [azure-machinelearning-workspaces](clients/ai/azure-machinelearning-workspaces.nu)       | openapi | <https://api.apis.guru/v2/specs/azure.com/machinelearning-workspaces/2019-10-01/swagger.json>                                                         |
| [cloudmersive-ocr](clients/ai/cloudmersive-ocr.nu)                                       | openapi | <https://api.apis.guru/v2/specs/cloudmersive.com/ocr/v1/openapi.json>                                                                                 |
| [cohere](clients/ai/cohere.nu)                                                           | openapi | <https://docs.cohere.com/openapi/cohere-api.json>                                                                                                     |
| [contentgroove-ai](clients/ai/contentgroove-ai.nu)                                       | openapi | <https://api.apis.guru/v2/specs/contentgroove.com/1.0.0/openapi.json>                                                                                 |
| [deeparteffects](clients/ai/deeparteffects.nu)                                           | openapi | <https://api.apis.guru/v2/specs/deeparteffects.com/2017-02-10T162446Z/swagger.json>                                                                   |
| [deepgram](clients/ai/deepgram.nu)                                                       | openapi | <https://developers.deepgram.com/reference/openapi.json>                                                                                              |
| [deepinfra](clients/ai/deepinfra.nu)                                                     | openapi | <https://api.deepinfra.com/openapi.json>                                                                                                              |
| [elevenlabs](clients/ai/elevenlabs.nu)                                                   | openapi | <https://api.elevenlabs.io/openapi.json>                                                                                                              |
| [elevenlabs-apisguru](clients/ai/elevenlabs-apisguru.nu)                                 | openapi | <https://api.apis.guru/v2/specs/elevenlabs.io/1.0/openapi.json>                                                                                       |
| [fireworks-ai](clients/ai/fireworks-ai.nu)                                               | openapi | <https://docs.fireworks.ai/merged.openapi.yaml>                                                                                                       |
| [google-ai-platform](clients/ai/google-ai-platform.nu)                                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/ml/v1/openapi.json>                                                                                    |
| [google-automl](clients/ai/google-automl.nu)                                             | openapi | <https://api.apis.guru/v2/specs/googleapis.com/automl/v1beta1/openapi.json>                                                                           |
| [google-dialogflow](clients/ai/google-dialogflow.nu)                                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/dialogflow/v3beta1/openapi.json>                                                                       |
| [google-dlp](clients/ai/google-dlp.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/dlp/v2/openapi.json>                                                                                   |
| [google-firebaseml](clients/ai/google-firebaseml.nu)                                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/firebaseml/v1beta2/openapi.json>                                                                       |
| [google-language](clients/ai/google-language.nu)                                         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/language/v1beta1/openapi.json>                                                                         |
| [google-speech](clients/ai/google-speech.nu)                                             | openapi | <https://api.apis.guru/v2/specs/googleapis.com/speech/v2beta1/openapi.json>                                                                           |
| [google-texttospeech](clients/ai/google-texttospeech.nu)                                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/texttospeech/v1beta1/openapi.json>                                                                     |
| [google-tpu](clients/ai/google-tpu.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/tpu/v2/openapi.json>                                                                                   |
| [google-vision](clients/ai/google-vision.nu)                                             | openapi | <https://api.apis.guru/v2/specs/googleapis.com/vision/v1p1beta1/openapi.json>                                                                         |
| [google-vision-apisguru](clients/ai/google-vision-apisguru.nu)                           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/vision/v1/openapi.json>                                                                                |
| [groq](clients/ai/groq.nu)                                                               | openapi | <https://storage.googleapis.com/stainless-sdk-openapi-specs/groqcloud/groqcloud-0298a69b7d74303a353e8a586d85e5cc769b9560920487fadfe773c0100af249.yml> |
| [jina](clients/ai/jina.nu)                                                               | openapi | <https://api.jina.ai/openapi.json>                                                                                                                    |
| [logoraisr](clients/ai/logoraisr.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/logoraisr.com/v1/openapi.json>                                                                                        |
| [mistral](clients/ai/mistral.nu)                                                         | openapi | <https://docs.mistral.ai/openapi.yaml>                                                                                                                |
| [moderatecontent](clients/ai/moderatecontent.nu)                                         | openapi | <https://api.apis.guru/v2/specs/moderatecontent.com/1.0.0/swagger.json>                                                                               |
| [ms-cognitive-autosuggest](clients/ai/ms-cognitive-autosuggest.nu)                       | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-AutoSuggest/1.0/swagger.json>                                                         |
| [ms-cognitive-prediction](clients/ai/ms-cognitive-prediction.nu)                         | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-Prediction/3.0/openapi.json>                                                          |
| [ms-cognitive-training](clients/ai/ms-cognitive-training.nu)                             | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-Training/3.2/openapi.json>                                                            |
| [ms-cognitiveservices-computervision](clients/ai/ms-cognitiveservices-computervision.nu) | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-ComputerVision/2.1/openapi.json>                                                      |
| [ms-cognitiveservices-ocr](clients/ai/ms-cognitiveservices-ocr.nu)                       | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-Ocr/2.1/openapi.json>                                                                 |
| [namsor](clients/ai/namsor.nu)                                                           | openapi | <https://api.apis.guru/v2/specs/namsor.com/2.0.24/openapi.json>                                                                                       |
| [nlpcloud](clients/ai/nlpcloud.nu)                                                       | openapi | <https://api.apis.guru/v2/specs/nlpcloud.io/1.0.0/openapi.json>                                                                                       |
| [openai](clients/ai/openai.nu)                                                           | openapi | <specs/openai.yaml>                                                                                                                                   |
| [openai-apisguru](clients/ai/openai-apisguru.nu)                                         | openapi | <https://api.apis.guru/v2/specs/openai.com/1.2.0/openapi.json>                                                                                        |
| [openalpr](clients/ai/openalpr.nu)                                                       | openapi | <https://api.apis.guru/v2/specs/openalpr.com/3.0.1/swagger.json>                                                                                      |
| [pandorabots](clients/ai/pandorabots.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/pandorabots.com/1.0.0/swagger.json>                                                                                   |
| [rapidapi-language-identification](clients/ai/rapidapi-language-identification.nu)       | openapi | <https://api.apis.guru/v2/specs/rapidapi.com/language-identification/1.0.0/swagger.json>                                                              |
| [replicate](clients/ai/replicate.nu)                                                     | openapi | <https://api.replicate.com/openapi.json>                                                                                                              |
| [rev-ai](clients/ai/rev-ai.nu)                                                           | openapi | <https://api.apis.guru/v2/specs/rev.ai/v1/openapi.json>                                                                                               |
| [runpod](clients/ai/runpod.nu)                                                           | openapi | <https://rest.runpod.io/v1/openapi.json>                                                                                                              |
| [seldon-core](clients/ai/seldon-core.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/seldon.local/core/0.1/openapi.json>                                                                                   |
| [seldon-engine](clients/ai/seldon-engine.nu)                                             | openapi | <https://api.apis.guru/v2/specs/seldon.local/engine/0.1/openapi.json>                                                                                 |
| [seldon-wrapper](clients/ai/seldon-wrapper.nu)                                           | openapi | <https://api.apis.guru/v2/specs/seldon.local/wrapper/0.1/openapi.json>                                                                                |
| [symanto](clients/ai/symanto.nu)                                                         | openapi | <https://api.apis.guru/v2/specs/symanto.net/1.0/openapi.json>                                                                                         |
| [taggun](clients/ai/taggun.nu)                                                           | openapi | <https://api.apis.guru/v2/specs/taggun.io/1.10.9/swagger.json>                                                                                        |
| [text2data](clients/ai/text2data.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/text2data.org/v3.4/swagger.json>                                                                                      |
| [together-ai](clients/ai/together-ai.nu)                                                 | openapi | <https://docs.together.ai/openapi.yaml>                                                                                                               |
| [tsapi-cognitive](clients/ai/tsapi-cognitive.nu)                                         | openapi | <https://api.apis.guru/v2/specs/tsapi.net/v1/openapi.json>                                                                                            |
| [visagecloud](clients/ai/visagecloud.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/visagecloud.com/1.1/swagger.json>                                                                                     |
| [visiblethread](clients/ai/visiblethread.nu)                                             | openapi | <https://api.apis.guru/v2/specs/visiblethread.com/1.0/swagger.json>                                                                                   |
| [webscraping-ai](clients/ai/webscraping-ai.nu)                                           | openapi | <https://api.apis.guru/v2/specs/webscraping.ai/2.0.7/openapi.json>                                                                                    |
| [wellknown-ai](clients/ai/wellknown-ai.nu)                                               | openapi | <https://api.apis.guru/v2/specs/wellknown.ai/1.0.0/openapi.json>                                                                                      |
| [xai](clients/ai/xai.nu)                                                                 | openapi | <https://docs.x.ai/openapi.json>                                                                                                                      |

### analytics

| Client                                                                        | Type    | Source                                                                                    |
| ----------------------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------- |
| [adobe-analytics](clients/analytics/adobe-analytics.nu)                       | openapi | <https://raw.githubusercontent.com/AdobeDocs/analytics-2.0-apis/main/static/swagger.json> |
| [azure-powerbi-dedicated](clients/analytics/azure-powerbi-dedicated.nu)       | openapi | <https://api.apis.guru/v2/specs/azure.com/powerbidedicated/2017-10-01/swagger.json>       |
| [azure-powerbi-embedded](clients/analytics/azure-powerbi-embedded.nu)         | openapi | <https://api.apis.guru/v2/specs/azure.com/powerbiembedded/2016-01-29/swagger.json>        |
| [fathom](clients/analytics/fathom.nu)                                         | openapi | <https://usefathom.com/api/openapi.json>                                                  |
| [google-analytics](clients/analytics/google-analytics.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/analytics/v3/openapi.json>                 |
| [google-analytics-admin](clients/analytics/google-analytics-admin.nu)         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/analyticsadmin/v1beta/openapi.json>        |
| [google-analytics-data](clients/analytics/google-analytics-data.nu)           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/analyticsdata/v1beta/openapi.json>         |
| [google-analytics-reporting](clients/analytics/google-analytics-reporting.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/analyticsreporting/v4/openapi.json>        |
| [google-analyticshub](clients/analytics/google-analyticshub.nu)               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/analyticshub/v1/openapi.json>              |
| [google-chromeuxreport](clients/analytics/google-chromeuxreport.nu)           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/chromeuxreport/v1/openapi.json>            |
| [google-fcmdata-analytics](clients/analytics/google-fcmdata-analytics.nu)     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/fcmdata/v1beta1/openapi.json>              |
| [google-firebase](clients/analytics/google-firebase.nu)                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/firebase/v1beta1/openapi.json>             |
| [google-pagespeedonline](clients/analytics/google-pagespeedonline.nu)         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/pagespeedonline/v5/openapi.json>           |
| [hubspot-analytics](clients/analytics/hubspot-analytics.nu)                   | openapi | <https://api.apis.guru/v2/specs/hubapi.com/analytics/v3/openapi.json>                     |
| [journy-io](clients/analytics/journy-io.nu)                                   | openapi | <https://api.apis.guru/v2/specs/journy.io/1.0.0/openapi.json>                             |
| [openpanel](clients/analytics/openpanel.nu)                                   | openapi | <https://api.openpanel.dev/documentation/json>                                            |
| [openreplay](clients/analytics/openreplay.nu)                                 | openapi | <https://api.openreplay.com/openapi.json>                                                 |
| [pendo](clients/analytics/pendo.nu)                                           | openapi | <https://api.apis.guru/v2/specs/pendo.io/1.0.0/swagger.json>                              |
| [posthog](clients/analytics/posthog.nu)                                       | openapi | <https://us.posthog.com/api/schema/>                                                      |
| [statsocial](clients/analytics/statsocial.nu)                                 | openapi | <https://api.apis.guru/v2/specs/statsocial.com/1.0.0/openapi.json>                        |
| [youtube-analytics](clients/analytics/youtube-analytics.nu)                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/youtubeAnalytics/v2/openapi.json>          |

### anime

| Client                                            | Type    | Source                                                                                        |
| ------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------- |
| [anilist](clients/anime/anilist.nu)               | graphql | <https://graphql.anilist.co>                                                                  |
| [animethemes](clients/anime/animethemes.nu)       | graphql | <https://graphql.animethemes.moe>                                                             |
| [bangumi](clients/anime/bangumi.nu)               | openapi | <https://raw.githubusercontent.com/bangumi/api/master/open-api/api.yml>                       |
| [dragonball-api](clients/anime/dragonball-api.nu) | openapi | <https://dragonball-api.com/api-docs-json>                                                    |
| [ghibli](clients/anime/ghibli.nu)                 | openapi | <https://ghibliapi.vercel.app/swagger.yaml>                                                   |
| [jikan](clients/anime/jikan.nu)                   | openapi | <https://raw.githubusercontent.com/jikan-me/jikan-rest/master/storage/api-docs/api-docs.json> |
| [kitsu](clients/anime/kitsu.nu)                   | graphql | <https://kitsu.io/api/graphql>                                                                |
| [mangadex](clients/anime/mangadex.nu)             | openapi | <https://api.mangadex.org/docs/static/api.yaml>                                               |
| [nekosapi](clients/anime/nekosapi.nu)             | openapi | <https://api.nekosapi.com/openapi.json>                                                       |

### arr

| Client                                    | Type    | Source                                                                                                             |
| ----------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------ |
| [prowlarr](clients/arr/prowlarr.nu)       | openapi | <https://raw.githubusercontent.com/Prowlarr/Prowlarr/develop/src/Prowlarr.Api.V1/openapi.json>                     |
| [qbittorrent](clients/arr/qbittorrent.nu) | openapi | <https://raw.githubusercontent.com/qbittorrent-ecosystem/webui-api-openapi/master/specs/v2.8.3/build/openapi.yaml> |
| [radarr](clients/arr/radarr.nu)           | openapi | <https://raw.githubusercontent.com/Radarr/Radarr/develop/src/Radarr.Api.V3/openapi.json>                           |
| [readarr](clients/arr/readarr.nu)         | openapi | <https://raw.githubusercontent.com/Readarr/Readarr/develop/src/Readarr.Api.V1/openapi.json>                        |
| [sonarr](clients/arr/sonarr.nu)           | openapi | <https://raw.githubusercontent.com/Sonarr/Sonarr/develop/src/Sonarr.Api.V3/openapi.json>                           |
| [whisparr](clients/arr/whisparr.nu)       | openapi | <https://raw.githubusercontent.com/Whisparr/Whisparr/develop/src/Whisparr.Api.V3/openapi.json>                     |

### automation

| Client                                               | Type    | Source                                                             |
| ---------------------------------------------------- | ------- | ------------------------------------------------------------------ |
| [make](clients/automation/make.nu)                   | openapi | <https://eu1.make.com/api/v2/openapi.json>                         |
| [n8n](clients/automation/n8n.nu)                     | openapi | <https://docs.n8n.io/api/v1/openapi.yml>                           |
| [svix](clients/automation/svix.nu)                   | openapi | <https://api.svix.com/api/v1/openapi.json>                         |
| [svix-apisguru](clients/automation/svix-apisguru.nu) | openapi | <https://api.apis.guru/v2/specs/svix.com/1.4/openapi.json>         |
| [zapier-nla](clients/automation/zapier-nla.nu)       | openapi | <https://api.apis.guru/v2/specs/zapier.com/nla/1.0.0/openapi.json> |

### billing

| Client                                                                                            | Type    | Source                                                                                           |
| ------------------------------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------ |
| [azure-billing](clients/billing/azure-billing.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/azure.com/billing/2019-10-01-preview/swagger.json>               |
| [azure-consumption](clients/billing/azure-consumption.nu)                                         | openapi | <https://api.apis.guru/v2/specs/azure.com/consumption/2019-06-01/swagger.json>                   |
| [billbee](clients/billing/billbee.nu)                                                             | openapi | <https://api.apis.guru/v2/specs/billbee.io/v1/openapi.json>                                      |
| [chargebee](clients/billing/chargebee.nu)                                                         | openapi | <https://raw.githubusercontent.com/chargebee/openapi/main/spec/chargebee_api_v2_pc_v2_spec.json> |
| [google-billingbudgets](clients/billing/google-billingbudgets.nu)                                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/billingbudgets/v1beta1/openapi.json>              |
| [google-cloudbilling](clients/billing/google-cloudbilling.nu)                                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/cloudbilling/v1beta/openapi.json>                 |
| [google-payments-reseller-subscription](clients/billing/google-payments-reseller-subscription.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/paymentsresellersubscription/v1/openapi.json>     |
| [lago](clients/billing/lago.nu)                                                                   | openapi | <https://raw.githubusercontent.com/getlago/lago-openapi/main/openapi.yaml>                       |
| [metronome](clients/billing/metronome.nu)                                                         | openapi | <https://docs.metronome.com/openapi.json>                                                        |
| [paddle](clients/billing/paddle.nu)                                                               | openapi | <https://raw.githubusercontent.com/PaddleHQ/paddle-openapi/main/v1/openapi.yaml>                 |
| [rebilly](clients/billing/rebilly.nu)                                                             | openapi | <https://api.apis.guru/v2/specs/rebilly.com/2.1/openapi.json>                                    |
| [zuora](clients/billing/zuora.nu)                                                                 | openapi | <https://api.apis.guru/v2/specs/zuora.com/2021-08-20/openapi.json>                               |

### blockchain

| Client                                                 | Type    | Source                                                                                         |
| ------------------------------------------------------ | ------- | ---------------------------------------------------------------------------------------------- |
| [alchemy-data](clients/blockchain/alchemy-data.nu)     | openapi | <https://raw.githubusercontent.com/alchemyplatform/docs-openapi-specs/main/data/v1.yaml>       |
| [alchemy-nft](clients/blockchain/alchemy-nft.nu)       | openapi | <https://raw.githubusercontent.com/alchemyplatform/docs-openapi-specs/main/nft/nfts.yaml>      |
| [alchemy-notify](clients/blockchain/alchemy-notify.nu) | openapi | <https://raw.githubusercontent.com/alchemyplatform/docs-openapi-specs/main/notify/notify.yaml> |
| [alchemy-prices](clients/blockchain/alchemy-prices.nu) | openapi | <https://raw.githubusercontent.com/alchemyplatform/docs-openapi-specs/main/prices/prices.yaml> |
| [moralis](clients/blockchain/moralis.nu)               | openapi | <https://deep-index.moralis.io/api-docs-2.2/v2.2/swagger.json>                                 |

### calendar

| Client                                                                   | Type    | Source                                                                                                                       |
| ------------------------------------------------------------------------ | ------- | ---------------------------------------------------------------------------------------------------------------------------- |
| [acuity-scheduling](clients/calendar/acuity-scheduling.nu)               | openapi | <https://raw.githubusercontent.com/jentic/jentic-public-apis/main/apis/openapi/acuityscheduling.com/main/1.0.0/openapi.json> |
| [cal-com-v2](clients/calendar/cal-com-v2.nu)                             | openapi | <https://raw.githubusercontent.com/calcom/cal.com/main/docs/api-reference/v2/openapi.json>                                   |
| [calendly](clients/calendar/calendly.nu)                                 | openapi | <https://raw.githubusercontent.com/jentic/jentic-public-apis/main/apis/openapi/calendly.com/main/2.0/openapi.json>           |
| [google-calendar](clients/calendar/google-calendar.nu)                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/calendar/v3/openapi.json>                                                     |
| [google-keep](clients/calendar/google-keep.nu)                           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/keep/v1/openapi.json>                                                         |
| [gotomeeting](clients/calendar/gotomeeting.nu)                           | openapi | <https://api.apis.guru/v2/specs/citrixonline.com/gotomeeting/1.0.0/swagger.json>                                             |
| [gototraining](clients/calendar/gototraining.nu)                         | openapi | <https://api.apis.guru/v2/specs/getgo.com/gototraining/1.0.0/swagger.json>                                                   |
| [gotowebinar](clients/calendar/gotowebinar.nu)                           | openapi | <https://api.apis.guru/v2/specs/getgo.com/gotowebinar/1.0.0/swagger.json>                                                    |
| [hetras-booking](clients/calendar/hetras-booking.nu)                     | openapi | <https://api.apis.guru/v2/specs/hetras-certification.net/booking/v0/swagger.json>                                            |
| [hetras-hotel](clients/calendar/hetras-hotel.nu)                         | openapi | <https://api.apis.guru/v2/specs/hetras-certification.net/hotel/v0/swagger.json>                                              |
| [learnifier](clients/calendar/learnifier.nu)                             | openapi | <https://api.apis.guru/v2/specs/learnifier.com/1.1.0/swagger.json>                                                           |
| [microsoft-graph-bookings](clients/calendar/microsoft-graph-bookings.nu) | openapi | <https://raw.githubusercontent.com/microsoftgraph/msgraph-sdk-powershell/main/openApiDocs/v1.0/Bookings.yml>                 |
| [microsoft-graph-calendar](clients/calendar/microsoft-graph-calendar.nu) | openapi | <https://raw.githubusercontent.com/microsoftgraph/msgraph-sdk-powershell/main/openApiDocs/v1.0/Calendar.yml>                 |
| [nylas-v3](clients/calendar/nylas-v3.nu)                                 | openapi | <https://developer.nylas.com/_spec-files/v3-ecc.yaml>                                                                        |
| [onsched-consumer](clients/calendar/onsched-consumer.nu)                 | openapi | <https://api.apis.guru/v2/specs/onsched.com/consumer/v1/openapi.json>                                                        |
| [onsched-setup](clients/calendar/onsched-setup.nu)                       | openapi | <https://api.apis.guru/v2/specs/onsched.com/setup/v1/openapi.json>                                                           |
| [onsched-utility](clients/calendar/onsched-utility.nu)                   | openapi | <https://api.apis.guru/v2/specs/onsched.com/utility/v1/openapi.json>                                                         |

### cdn

| Client                                                            | Type    | Source                                                                                                   |
| ----------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------- |
| [akamai-amfa](clients/cdn/akamai-amfa.nu)                         | openapi | <https://raw.githubusercontent.com/akamai/akamai-apis/main/apis/amfa/v1/openapi.json>                    |
| [akamai-appsec](clients/cdn/akamai-appsec.nu)                     | openapi | <https://raw.githubusercontent.com/akamai/akamai-apis/main/apis/appsec/v1/openapi.json>                  |
| [akamai-ccu](clients/cdn/akamai-ccu.nu)                           | openapi | <https://raw.githubusercontent.com/akamai/akamai-apis/main/apis/ccu/v3/openapi.json>                     |
| [akamai-edge-diagnostics](clients/cdn/akamai-edge-diagnostics.nu) | openapi | <https://raw.githubusercontent.com/akamai/akamai-apis/main/apis/edge-diagnostics/v1/openapi.json>        |
| [akamai-gtm](clients/cdn/akamai-gtm.nu)                           | openapi | <https://raw.githubusercontent.com/akamai/akamai-apis/main/apis/config-gtm/v1/openapi.json>              |
| [aws-cloudfront](clients/cdn/aws-cloudfront.nu)                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/cloudfront/2020-05-31/openapi.json>                        |
| [aws-global-accelerator](clients/cdn/aws-global-accelerator.nu)   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/globalaccelerator/2018-08-08/openapi.json>                 |
| [azure-cdn](clients/cdn/azure-cdn.nu)                             | openapi | <https://api.apis.guru/v2/specs/azure.com/cdn/2019-06-15-preview/swagger.json>                           |
| [azure-cdn-waf](clients/cdn/azure-cdn-waf.nu)                     | openapi | <https://api.apis.guru/v2/specs/azure.com/cdn-cdnwebapplicationfirewall/2019-06-15-preview/swagger.json> |
| [bunny](clients/cdn/bunny.nu)                                     | openapi | <https://core-api-public-docs.b-cdn.net/docs/v3/public.json>                                             |
| [cloudflare](clients/cdn/cloudflare.nu)                           | openapi | <https://raw.githubusercontent.com/cloudflare/api-schemas/main/openapi.json>                             |
| [gcore-cdn](clients/cdn/gcore-cdn.nu)                             | openapi | <https://gcore.com/docs/api-reference/services_docs_mintlify/cdn_api.yaml>                               |
| [gcore-fastedge](clients/cdn/gcore-fastedge.nu)                   | openapi | <https://gcore.com/docs/api-reference/services_docs_mintlify/fastedge_api.yaml>                          |
| [vercel](clients/cdn/vercel.nu)                                   | openapi | <https://openapi.vercel.sh/>                                                                             |

### chat

| Client                                                               | Type    | Source                                                                                                    |
| -------------------------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------------------- |
| [ably-control](clients/chat/ably-control.nu)                         | openapi | <https://api.apis.guru/v2/specs/ably.net/control/1.0.14/openapi.json>                                     |
| [aws-chime](clients/chat/aws-chime.nu)                               | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/chime/2018-05-01/openapi.json>                              |
| [aws-connect](clients/chat/aws-connect.nu)                           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/connect/2017-08-08/openapi.json>                            |
| [aws-connect-contact-lens](clients/chat/aws-connect-contact-lens.nu) | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/connect-contact-lens/2020-08-21/openapi.json>               |
| [aws-sns](clients/chat/aws-sns.nu)                                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/sns/2010-03-31/openapi.json>                                |
| [aws-sqs](clients/chat/aws-sqs.nu)                                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/sqs/2012-11-05/openapi.json>                                |
| [azure-signalr](clients/chat/azure-signalr.nu)                       | openapi | <https://api.apis.guru/v2/specs/azure.com/signalr/2018-10-01/swagger.json>                                |
| [chatwoot](clients/chat/chatwoot.nu)                                 | openapi | <https://raw.githubusercontent.com/chatwoot/chatwoot/develop/swagger/swagger.json>                        |
| [circuitsandbox](clients/chat/circuitsandbox.nu)                     | openapi | <https://api.apis.guru/v2/specs/circuitsandbox.net/2.9.235/openapi.json>                                  |
| [clicksend](clients/chat/clicksend.nu)                               | openapi | <https://api.apis.guru/v2/specs/clicksend.com/1.0.0/openapi.json>                                         |
| [clubhouse](clients/chat/clubhouse.nu)                               | openapi | <https://api.apis.guru/v2/specs/clubhouseapi.com/1/openapi.json>                                          |
| [discord](clients/chat/discord.nu)                                   | openapi | <https://raw.githubusercontent.com/discord/discord-api-spec/main/specs/openapi.json>                      |
| [google-chat](clients/chat/google-chat.nu)                           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/chat/v1/openapi.json>                                      |
| [google-fcm](clients/chat/google-fcm.nu)                             | openapi | <https://api.apis.guru/v2/specs/googleapis.com/fcm/v1/openapi.json>                                       |
| [intercom](clients/chat/intercom.nu)                                 | openapi | <https://raw.githubusercontent.com/intercom/Intercom-OpenAPI/main/descriptions/2.11/api.intercom.io.yaml> |
| [intercom-210](clients/chat/intercom-210.nu)                         | openapi | <https://raw.githubusercontent.com/intercom/Intercom-OpenAPI/main/descriptions/2.10/api.intercom.io.yaml> |
| [line](clients/chat/line.nu)                                         | openapi | <https://raw.githubusercontent.com/line/line-openapi/main/messaging-api.yml>                              |
| [notion-apisguru](clients/chat/notion-apisguru.nu)                   | openapi | <https://api.apis.guru/v2/specs/notion.com/1.0.0/openapi.json>                                            |
| [slack](clients/chat/slack.nu)                                       | openapi | <https://raw.githubusercontent.com/slackapi/slack-api-specs/master/web-api/slack_web_openapi_v2.json>     |
| [slack-apisguru](clients/chat/slack-apisguru.nu)                     | openapi | <https://api.apis.guru/v2/specs/slack.com/1.7.0/openapi.json>                                             |
| [telegram-bot](clients/chat/telegram-bot.nu)                         | openapi | <https://api.apis.guru/v2/specs/telegram.org/5.0.0/openapi.json>                                          |
| [twilio-chat-v3](clients/chat/twilio-chat-v3.nu)                     | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_chat_v3/1.42.0/openapi.json>                            |
| [twilio-conversations](clients/chat/twilio-conversations.nu)         | openapi | <https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_conversations_v1.json>         |
| [twilio-ip-messaging-v2](clients/chat/twilio-ip-messaging-v2.nu)     | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_ip_messaging_v2/1.42.0/openapi.json>                    |
| [twilio-messaging](clients/chat/twilio-messaging.nu)                 | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_messaging_v1/1.42.0/openapi.json>                       |
| [twilio-notify](clients/chat/twilio-notify.nu)                       | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_notify_v1/1.42.0/openapi.json>                          |
| [vonage-conversation](clients/chat/vonage-conversation.nu)           | openapi | <https://api.apis.guru/v2/specs/nexmo.com/conversation/2.0.1/openapi.json>                                |
| [whatsapp](clients/chat/whatsapp.nu)                                 | openapi | <https://api.apis.guru/v2/specs/whatsapp.local/1.0/openapi.json>                                          |
| [zoom](clients/chat/zoom.nu)                                         | openapi | <https://api.apis.guru/v2/specs/zoom.us/2.0.0/openapi.yaml>                                               |
| [zoom-apisguru](clients/chat/zoom-apisguru.nu)                       | openapi | <https://api.apis.guru/v2/specs/zoom.us/2.0.0/openapi.json>                                               |
| [zulip](clients/chat/zulip.nu)                                       | openapi | <https://raw.githubusercontent.com/zulip/zulip/main/zerver/openapi/zulip.yaml>                            |

### ci-cd

| Client                                                                                    | Type    | Source                                                                                                                     |
| ----------------------------------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------------------------- |
| [appveyor](clients/ci-cd/appveyor.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/appveyor.com/1.0.0/swagger.json>                                                           |
| [aws-apigateway](clients/ci-cd/aws-apigateway.nu)                                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/apigateway/2015-07-09/openapi.json>                                          |
| [aws-apigatewayv2](clients/ci-cd/aws-apigatewayv2.nu)                                     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/apigatewayv2/2018-11-29/openapi.json>                                        |
| [aws-cloudformation](clients/ci-cd/aws-cloudformation.nu)                                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/cloudformation/2010-05-15/openapi.json>                                      |
| [aws-codebuild](clients/ci-cd/aws-codebuild.nu)                                           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/codebuild/2016-10-06/openapi.json>                                           |
| [aws-codedeploy](clients/ci-cd/aws-codedeploy.nu)                                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/codedeploy/2014-10-06/openapi.json>                                          |
| [aws-codepipeline](clients/ci-cd/aws-codepipeline.nu)                                     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/codepipeline/2015-07-09/openapi.json>                                        |
| [aws-imagebuilder](clients/ci-cd/aws-imagebuilder.nu)                                     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/imagebuilder/2019-12-02/openapi.json>                                        |
| [aws-serverlessrepo](clients/ci-cd/aws-serverlessrepo.nu)                                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/serverlessrepo/2017-09-08/openapi.json>                                      |
| [azure-acr-build](clients/ci-cd/azure-acr-build.nu)                                       | openapi | <https://api.apis.guru/v2/specs/azure.com/containerregistry-containerregistry_build/2019-06-01-preview/swagger.json>       |
| [azure-apimanagement](clients/ci-cd/azure-apimanagement.nu)                               | openapi | <https://api.apis.guru/v2/specs/azure.com/apimanagement/2018-01-01/swagger.json>                                           |
| [azure-appconfiguration](clients/ci-cd/azure-appconfiguration.nu)                         | openapi | <https://api.apis.guru/v2/specs/azure.com/appconfiguration/2019-11-01-preview/swagger.json>                                |
| [azure-automation-connection](clients/ci-cd/azure-automation-connection.nu)               | openapi | <https://api.apis.guru/v2/specs/azure.com/automation-connection/2015-10-31/swagger.json>                                   |
| [azure-automation-credential](clients/ci-cd/azure-automation-credential.nu)               | openapi | <https://api.apis.guru/v2/specs/azure.com/automation-credential/2015-10-31/swagger.json>                                   |
| [azure-automation-dsc-configuration](clients/ci-cd/azure-automation-dsc-configuration.nu) | openapi | <https://api.apis.guru/v2/specs/azure.com/automation-dscConfiguration/2015-10-31/swagger.json>                             |
| [azure-automation-dsc-node](clients/ci-cd/azure-automation-dsc-node.nu)                   | openapi | <https://api.apis.guru/v2/specs/azure.com/automation-dscNode/2018-01-15/swagger.json>                                      |
| [azure-automation-job](clients/ci-cd/azure-automation-job.nu)                             | openapi | <https://api.apis.guru/v2/specs/azure.com/automation-job/2017-05-15-preview/swagger.json>                                  |
| [azure-automation-module](clients/ci-cd/azure-automation-module.nu)                       | openapi | <https://api.apis.guru/v2/specs/azure.com/automation-module/2015-10-31/swagger.json>                                       |
| [azure-automation-runbook](clients/ci-cd/azure-automation-runbook.nu)                     | openapi | <https://api.apis.guru/v2/specs/azure.com/automation-runbook/2018-06-30/swagger.json>                                      |
| [azure-automation-variable](clients/ci-cd/azure-automation-variable.nu)                   | openapi | <https://api.apis.guru/v2/specs/azure.com/automation-variable/2015-10-31/swagger.json>                                     |
| [azure-automation-watcher](clients/ci-cd/azure-automation-watcher.nu)                     | openapi | <https://api.apis.guru/v2/specs/azure.com/automation-watcher/2015-10-31/swagger.json>                                      |
| [azure-automation-webhook](clients/ci-cd/azure-automation-webhook.nu)                     | openapi | <https://api.apis.guru/v2/specs/azure.com/automation-webhook/2015-10-31/swagger.json>                                      |
| [azure-deploymentmanager](clients/ci-cd/azure-deploymentmanager.nu)                       | openapi | <https://api.apis.guru/v2/specs/azure.com/deploymentmanager/2019-11-01-preview/swagger.json>                               |
| [azure-imagebuilder](clients/ci-cd/azure-imagebuilder.nu)                                 | openapi | <https://api.apis.guru/v2/specs/azure.com/imagebuilder/2019-05-01-preview/swagger.json>                                    |
| [azure-pipelinetemplates](clients/ci-cd/azure-pipelinetemplates.nu)                       | openapi | <https://api.apis.guru/v2/specs/azure.com/visualstudio-PipelineTemplates/2018-08-01-preview/swagger.json>                  |
| [circleci](clients/ci-cd/circleci.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/circleci.com/v1/openapi.json>                                                              |
| [cloudsmith](clients/ci-cd/cloudsmith.nu)                                                 | openapi | <https://api.cloudsmith.io/openapi>                                                                                        |
| [codacy](clients/ci-cd/codacy.nu)                                                         | openapi | <https://api.codacy.com/api/api-docs/swagger.yaml>                                                                         |
| [codecov](clients/ci-cd/codecov.nu)                                                       | openapi | <https://api.codecov.io/api/v2/schema/>                                                                                    |
| [google-apigeeregistry](clients/ci-cd/google-apigeeregistry.nu)                           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/apigeeregistry/v1/openapi.json>                                             |
| [google-artifactregistry](clients/ci-cd/google-artifactregistry.nu)                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/artifactregistry/v1/openapi.json>                                           |
| [google-binaryauthorization](clients/ci-cd/google-binaryauthorization.nu)                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/binaryauthorization/v1/openapi.json>                                        |
| [google-cloudbuild](clients/ci-cd/google-cloudbuild.nu)                                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/cloudbuild/v1/openapi.json>                                                 |
| [google-clouddeploy](clients/ci-cd/google-clouddeploy.nu)                                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/clouddeploy/v1/openapi.json>                                                |
| [google-cloudrun](clients/ci-cd/google-cloudrun.nu)                                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/run/v2/openapi.json>                                                        |
| [google-containeranalysis](clients/ci-cd/google-containeranalysis.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/containeranalysis/v1/openapi.json>                                          |
| [google-deploymentmanager](clients/ci-cd/google-deploymentmanager.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/deploymentmanager/v2/openapi.json>                                          |
| [google-firebase-app-distribution](clients/ci-cd/google-firebase-app-distribution.nu)     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/firebaseappdistribution/v1/openapi.json>                                    |
| [google-ondemandscanning](clients/ci-cd/google-ondemandscanning.nu)                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/ondemandscanning/v1/openapi.json>                                           |
| [google-remotebuildexecution](clients/ci-cd/google-remotebuildexecution.nu)               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/remotebuildexecution/v1alpha/openapi.json>                                  |
| [kubeflow-pipelines](clients/ci-cd/kubeflow-pipelines.nu)                                 | openapi | <https://raw.githubusercontent.com/kubeflow/pipelines/master/backend/api/v2beta1/swagger/kfp_api_single_file.swagger.json> |
| [octopus-deploy](clients/ci-cd/octopus-deploy.nu)                                         | openapi | <https://demo.octopus.app/api/swagger.json>                                                                                |
| [peel-ci](clients/ci-cd/peel-ci.nu)                                                       | openapi | <https://api.apis.guru/v2/specs/peel-ci.com/1.0.0/swagger.json>                                                            |
| [redhat-patchman](clients/ci-cd/redhat-patchman.nu)                                       | openapi | <https://api.apis.guru/v2/specs/redhat.local/patchman-engine/v1.15.3/openapi.json>                                         |
| [snyk-rest](clients/ci-cd/snyk-rest.nu)                                                   | openapi | <https://api.snyk.io/rest/openapi/2025-01-09>                                                                              |
| [turbinelabs](clients/ci-cd/turbinelabs.nu)                                               | openapi | <https://api.apis.guru/v2/specs/turbinelabs.io/1.0/swagger.json>                                                           |

### cloud

| Client                                                          | Type    | Source                                                                                                  |
| --------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------- |
| [aws-lightsail](clients/cloud/aws-lightsail.nu)                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/lightsail/2016-11-28/openapi.json>                        |
| [clever-cloud-apisguru](clients/cloud/clever-cloud-apisguru.nu) | openapi | <https://api.apis.guru/v2/specs/clever-cloud.com/1.0.0/openapi.json>                                    |
| [digitalocean](clients/cloud/digitalocean.nu)                   | openapi | <https://raw.githubusercontent.com/digitalocean/openapi/main/specification/DigitalOcean-public.v2.yaml> |
| [digitalocean-spec](clients/cloud/digitalocean-spec.nu)         | openapi | <https://api.apis.guru/v2/specs/digitalocean.com/2.0/openapi.json>                                      |
| [dokploy](clients/cloud/dokploy.nu)                             | openapi | <https://docs.dokploy.com/openapi.json>                                                                 |
| [exoscale](clients/cloud/exoscale.nu)                           | openapi | <https://openapi-v2.exoscale.com/source.json>                                                           |
| [fly-machines](clients/cloud/fly-machines.nu)                   | openapi | <https://docs.machines.dev/swagger/doc.json>                                                            |
| [hetzner-cloud](clients/cloud/hetzner-cloud.nu)                 | openapi | <https://api.apis.guru/v2/specs/hetzner.cloud/1.0.0/openapi.json>                                       |
| [koyeb](clients/cloud/koyeb.nu)                                 | openapi | <https://raw.githubusercontent.com/koyeb/koyeb-api-client-go/master/api/v1/koyeb/api/openapi.yaml>      |
| [linode](clients/cloud/linode.nu)                               | openapi | <https://api.apis.guru/v2/specs/linode.com/4.145.0/openapi.json>                                        |
| [netlify](clients/cloud/netlify.nu)                             | openapi | <https://open-api.netlify.com/openapi.json>                                                             |
| [netlify-apisguru](clients/cloud/netlify-apisguru.nu)           | openapi | <https://api.apis.guru/v2/specs/netlify.com/2.15.0/swagger.json>                                        |
| [openpolicy-apisguru](clients/cloud/openpolicy-apisguru.nu)     | openapi | <https://api.apis.guru/v2/specs/openpolicy.local/0.28.0/openapi.json>                                   |
| [openshift-accounts](clients/cloud/openshift-accounts.nu)       | openapi | <https://api.openshift.com/api/accounts_mgmt/v1/openapi>                                                |
| [openshift-clusters](clients/cloud/openshift-clusters.nu)       | openapi | <https://api.openshift.com/api/clusters_mgmt/v1/openapi>                                                |
| [render](clients/cloud/render.nu)                               | openapi | <https://api-docs.render.com/openapi/render-public-api-1.json>                                          |
| [simplivpn](clients/cloud/simplivpn.nu)                         | openapi | <https://api.apis.guru/v2/specs/simplivpn.net/1.0/openapi.json>                                         |
| [solarvps](clients/cloud/solarvps.nu)                           | openapi | <https://api.apis.guru/v2/specs/solarvps.com/1.0.0/swagger.json>                                        |
| [vercel-apisguru](clients/cloud/vercel-apisguru.nu)             | openapi | <https://api.apis.guru/v2/specs/vercel.com/0.0.1/openapi.json>                                          |
| [zeit-co](clients/cloud/zeit-co.nu)                             | openapi | <https://api.apis.guru/v2/specs/zeit.co/v2019-01-07/openapi.json>                                       |

### commerce

| Client                                                                   | Type    | Source                                                                                 |
| ------------------------------------------------------------------------ | ------- | -------------------------------------------------------------------------------------- |
| [api2cart](clients/commerce/api2cart.nu)                                 | openapi | <https://api.apis.guru/v2/specs/api2cart.com/1.1/openapi.json>                         |
| [beezup](clients/commerce/beezup.nu)                                     | openapi | <https://api.apis.guru/v2/specs/beezup.com/2.0/openapi.json>                           |
| [ebay-buy-browse](clients/commerce/ebay-buy-browse.nu)                   | openapi | <https://api.apis.guru/v2/specs/ebay.com/buy-browse/v1.1.0/swagger.json>               |
| [ebay-buy-deal](clients/commerce/ebay-buy-deal.nu)                       | openapi | <https://api.apis.guru/v2/specs/ebay.com/buy-deal/v1.3.0/openapi.json>                 |
| [ebay-buy-feed](clients/commerce/ebay-buy-feed.nu)                       | openapi | <https://api.apis.guru/v2/specs/ebay.com/buy-feed/v1_beta.34.0/openapi.json>           |
| [ebay-commerce-catalog](clients/commerce/ebay-commerce-catalog.nu)       | openapi | <https://api.apis.guru/v2/specs/ebay.com/commerce-catalog/v1_beta.5.0/openapi.json>    |
| [ebay-commerce-charity](clients/commerce/ebay-commerce-charity.nu)       | openapi | <https://api.apis.guru/v2/specs/ebay.com/commerce-charity/v1.2.1/openapi.json>         |
| [ebay-commerce-identity](clients/commerce/ebay-commerce-identity.nu)     | openapi | <https://api.apis.guru/v2/specs/apiz.ebay.com/commerce-identity/v1.1.0/openapi.json>   |
| [ebay-commerce-taxonomy](clients/commerce/ebay-commerce-taxonomy.nu)     | openapi | <https://api.apis.guru/v2/specs/ebay.com/commerce-taxonomy/v1.0.0/swagger.json>        |
| [ebay-developer-analytics](clients/commerce/ebay-developer-analytics.nu) | openapi | <https://api.apis.guru/v2/specs/ebay.com/developer-analytics/v1_beta.0.0/openapi.json> |
| [ebay-finances](clients/commerce/ebay-finances.nu)                       | openapi | <https://api.apis.guru/v2/specs/apiz.ebay.com/sell-finances/v1.15.0/openapi.json>      |
| [ebay-sell-account](clients/commerce/ebay-sell-account.nu)               | openapi | <https://api.apis.guru/v2/specs/ebay.com/sell-account/v1.9.0/openapi.json>             |
| [ebay-sell-analytics](clients/commerce/ebay-sell-analytics.nu)           | openapi | <https://api.apis.guru/v2/specs/ebay.com/sell-analytics/1.2.0/openapi.json>            |
| [ebay-sell-compliance](clients/commerce/ebay-sell-compliance.nu)         | openapi | <https://api.apis.guru/v2/specs/api.ebay.com/sell-compliance/1.4.1/openapi.json>       |
| [ebay-sell-feed](clients/commerce/ebay-sell-feed.nu)                     | openapi | <https://api.apis.guru/v2/specs/ebay.com/sell-feed/v1.3.1/openapi.json>                |
| [ebay-sell-fulfillment](clients/commerce/ebay-sell-fulfillment.nu)       | openapi | <https://api.apis.guru/v2/specs/ebay.com/sell-fulfillment/v1.19.19/openapi.json>       |
| [ebay-sell-listing](clients/commerce/ebay-sell-listing.nu)               | openapi | <https://api.apis.guru/v2/specs/ebay.com/sell-listing/v1_beta.3.0/openapi.json>        |
| [ebay-sell-metadata](clients/commerce/ebay-sell-metadata.nu)             | openapi | <https://api.apis.guru/v2/specs/ebay.com/sell-metadata/v1.6.0/openapi.json>            |
| [ebay-sell-negotiation](clients/commerce/ebay-sell-negotiation.nu)       | openapi | <https://api.apis.guru/v2/specs/ebay.com/sell-negotiation/v1.1.0/openapi.json>         |
| [ebay-sell-recommendation](clients/commerce/ebay-sell-recommendation.nu) | openapi | <https://api.apis.guru/v2/specs/ebay.com/sell-recommendation/1.1.0/openapi.json>       |
| [etsy](clients/commerce/etsy.nu)                                         | openapi | <https://www.etsy.com/openapi/generated/oas/3.0.0.json>                                |
| [google-shopping-content](clients/commerce/google-shopping-content.nu)   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/shoppingcontent/v2/openapi.json>        |
| [izettle-products](clients/commerce/izettle-products.nu)                 | openapi | <https://api.apis.guru/v2/specs/izettle.com/products/1.0.0/openapi.json>               |
| [jumpseller](clients/commerce/jumpseller.nu)                             | openapi | <https://api.apis.guru/v2/specs/jumpseller.com/1.0.0/openapi.json>                     |
| [magento](clients/commerce/magento.nu)                                   | openapi | <https://api.apis.guru/v2/specs/magento.com/2.2.10/openapi.json>                       |
| [papinet-order-status](clients/commerce/papinet-order-status.nu)         | openapi | <https://api.apis.guru/v2/specs/papinet.io/order_status/1.0.0/openapi.json>            |
| [redhat-catalog-inventory](clients/commerce/redhat-catalog-inventory.nu) | openapi | <https://api.apis.guru/v2/specs/redhat.com/catalog_inventory/1.0.0/openapi.json>       |
| [reverb-commerce](clients/commerce/reverb-commerce.nu)                   | openapi | <https://api.apis.guru/v2/specs/reverb.com/3.0/openapi.json>                           |
| [shop-app](clients/commerce/shop-app.nu)                                 | openapi | <https://api.apis.guru/v2/specs/shop.app/v1/openapi.json>                              |
| [shop-pro](clients/commerce/shop-pro.nu)                                 | openapi | <https://api.apis.guru/v2/specs/shop-pro.jp/1.0.0/openapi.json>                        |
| [square](clients/commerce/square.nu)                                     | openapi | <https://raw.githubusercontent.com/square/connect-api-specification/master/api.json>   |
| [storecove](clients/commerce/storecove.nu)                               | openapi | <https://api.apis.guru/v2/specs/storecove.com/2.0.1/openapi.json>                      |
| [viator-tours](clients/commerce/viator-tours.nu)                         | openapi | <https://api.apis.guru/v2/specs/viator.com/1.0.0/openapi.json>                         |
| [voodoomfg](clients/commerce/voodoomfg.nu)                               | openapi | <https://api.apis.guru/v2/specs/voodoomfg.com/2.0.0/swagger.json>                      |
| [vtex-catalog](clients/commerce/vtex-catalog.nu)                         | openapi | <https://api.apis.guru/v2/specs/vtex.local/Catalog-API/1.0/openapi.json>               |
| [vtex-checkout](clients/commerce/vtex-checkout.nu)                       | openapi | <https://api.apis.guru/v2/specs/vtex.local/Checkout-API/1.0/openapi.json>              |
| [vtex-giftcard](clients/commerce/vtex-giftcard.nu)                       | openapi | <https://api.apis.guru/v2/specs/vtex.local/Giftcard-API/1.0/openapi.json>              |
| [vtex-headless-cms](clients/commerce/vtex-headless-cms.nu)               | openapi | <https://api.apis.guru/v2/specs/vtex.local/Headless-CMS-API/0.31.2/openapi.json>       |
| [vtex-intelligent-search](clients/commerce/vtex-intelligent-search.nu)   | openapi | <https://api.apis.guru/v2/specs/vtex.local/Intelligent-Search-API/0.1.12/openapi.json> |
| [vtex-license-manager](clients/commerce/vtex-license-manager.nu)         | openapi | <https://api.apis.guru/v2/specs/vtex.local/License-Manager-API/1.0/openapi.json>       |
| [vtex-marketplace](clients/commerce/vtex-marketplace.nu)                 | openapi | <https://api.apis.guru/v2/specs/vtex.local/Marketplace-APIs/1.0/openapi.json>          |
| [vtex-master-data](clients/commerce/vtex-master-data.nu)                 | openapi | <https://api.apis.guru/v2/specs/vtex.local/Master-Data-API-/1.0/openapi.json>          |
| [vtex-orders](clients/commerce/vtex-orders.nu)                           | openapi | <https://api.apis.guru/v2/specs/vtex.local/Orders-API/1.0/openapi.json>                |
| [vtex-pricing](clients/commerce/vtex-pricing.nu)                         | openapi | <https://api.apis.guru/v2/specs/vtex.local/Pricing-API/1.0/openapi.json>               |
| [vtex-search](clients/commerce/vtex-search.nu)                           | openapi | <https://api.apis.guru/v2/specs/vtex.local/Search-API/1.0/openapi.json>                |
| [vtex-session](clients/commerce/vtex-session.nu)                         | openapi | <https://api.apis.guru/v2/specs/vtex.local/Session-Manager-API/1.0/openapi.json>       |
| [vtex-subscriptions-v2](clients/commerce/vtex-subscriptions-v2.nu)       | openapi | <https://api.apis.guru/v2/specs/vtex.local/Subscriptions-API-(v2)/1.0/openapi.json>    |
| [walmart-inventory](clients/commerce/walmart-inventory.nu)               | openapi | <https://api.apis.guru/v2/specs/walmart.com/inventory/1.0.0/openapi.json>              |
| [walmart-item](clients/commerce/walmart-item.nu)                         | openapi | <https://api.apis.guru/v2/specs/walmart.com/item/3.0.1/swagger.json>                   |
| [walmart-order](clients/commerce/walmart-order.nu)                       | openapi | <https://api.apis.guru/v2/specs/walmart.com/order/3.0.1/swagger.json>                  |
| [walmart-price](clients/commerce/walmart-price.nu)                       | openapi | <https://api.apis.guru/v2/specs/walmart.com/price/1.0.0/openapi.json>                  |
| [webflow-apisguru](clients/commerce/webflow-apisguru.nu)                 | openapi | <https://api.apis.guru/v2/specs/webflow.com/2023-03-01T164537Z/openapi.json>           |
| [zalando](clients/commerce/zalando.nu)                                   | openapi | <https://api.apis.guru/v2/specs/zalando.com/v1.0/swagger.json>                         |

### container-orchestration

| Client                                                                                        | Type    | Source                                                                                                       |
| --------------------------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------ |
| [argo-rollouts](clients/container-orchestration/argo-rollouts.nu)                             | openapi | <https://raw.githubusercontent.com/argoproj/argo-rollouts/master/pkg/apiclient/rollout/rollout.swagger.json> |
| [argo-workflows](clients/container-orchestration/argo-workflows.nu)                           | openapi | <https://raw.githubusercontent.com/argoproj/argo-workflows/main/api/openapi-spec/swagger.json>               |
| [argocd](clients/container-orchestration/argocd.nu)                                           | openapi | <https://raw.githubusercontent.com/argoproj/argo-cd/master/assets/swagger.json>                              |
| [aws-application-autoscaling](clients/container-orchestration/aws-application-autoscaling.nu) | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/application-autoscaling/2016-02-06/openapi.json>               |
| [aws-apprunner](clients/container-orchestration/aws-apprunner.nu)                             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/apprunner/2020-05-15/openapi.json>                             |
| [aws-batch](clients/container-orchestration/aws-batch.nu)                                     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/batch/2016-08-10/openapi.json>                                 |
| [aws-cloud-map](clients/container-orchestration/aws-cloud-map.nu)                             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/servicediscovery/2017-03-14/openapi.json>                      |
| [aws-ecr](clients/container-orchestration/aws-ecr.nu)                                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/ecr/2015-09-21/openapi.json>                                   |
| [aws-ecr-public](clients/container-orchestration/aws-ecr-public.nu)                           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/ecr-public/2020-10-30/openapi.json>                            |
| [aws-ecs](clients/container-orchestration/aws-ecs.nu)                                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/ecs/2014-11-13/openapi.json>                                   |
| [aws-eks](clients/container-orchestration/aws-eks.nu)                                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/eks/2017-11-01/openapi.json>                                   |
| [aws-elastic-beanstalk](clients/container-orchestration/aws-elastic-beanstalk.nu)             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/elasticbeanstalk/2010-12-01/openapi.json>                      |
| [aws-lambda](clients/container-orchestration/aws-lambda.nu)                                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/lambda/2015-03-31/openapi.json>                                |
| [aws-opsworks](clients/container-orchestration/aws-opsworks.nu)                               | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/opsworks/2013-02-18/openapi.json>                              |
| [aws-step-functions](clients/container-orchestration/aws-step-functions.nu)                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/states/2016-11-23/openapi.json>                                |
| [aws-swf](clients/container-orchestration/aws-swf.nu)                                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/swf/2012-01-25/openapi.json>                                   |
| [azure-aks](clients/container-orchestration/azure-aks.nu)                                     | openapi | <https://api.apis.guru/v2/specs/azure.com/containerservice-managedClusters/2019-08-01/swagger.json>          |
| [azure-appplatform](clients/container-orchestration/azure-appplatform.nu)                     | openapi | <https://api.apis.guru/v2/specs/azure.com/appplatform/2019-05-01-preview/swagger.json>                       |
| [azure-batch](clients/container-orchestration/azure-batch.nu)                                 | openapi | <https://api.apis.guru/v2/specs/azure.com/batch-BatchService/2019-08-01.10.0/swagger.json>                   |
| [azure-container-instances](clients/container-orchestration/azure-container-instances.nu)     | openapi | <https://api.apis.guru/v2/specs/azure.com/containerinstance-containerInstance/2018-10-01/swagger.json>       |
| [azure-service-fabric](clients/container-orchestration/azure-service-fabric.nu)               | openapi | <https://api.apis.guru/v2/specs/azure.com/servicefabric/6.5.0.36/swagger.json>                               |
| [azure-service-fabric-mesh](clients/container-orchestration/azure-service-fabric-mesh.nu)     | openapi | <https://api.apis.guru/v2/specs/azure.com/servicefabricmesh/2018-09-01-preview/swagger.json>                 |
| [cilium](clients/container-orchestration/cilium.nu)                                           | openapi | <https://raw.githubusercontent.com/cilium/cilium/main/api/v1/openapi.yaml>                                   |
| [google-cloud-batch](clients/container-orchestration/google-cloud-batch.nu)                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/batch/v1/openapi.json>                                        |
| [google-cloud-functions](clients/container-orchestration/google-cloud-functions.nu)           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/cloudfunctions/v2/openapi.json>                               |
| [google-cloud-scheduler](clients/container-orchestration/google-cloud-scheduler.nu)           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/cloudscheduler/v1beta1/openapi.json>                          |
| [google-gke](clients/container-orchestration/google-gke.nu)                                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/container/v1beta1/openapi.json>                               |
| [ibm-bluemix-containers](clients/container-orchestration/ibm-bluemix-containers.nu)           | openapi | <https://api.apis.guru/v2/specs/bluemix.net/containers/3.0.0/openapi.json>                                   |
| [karmada](clients/container-orchestration/karmada.nu)                                         | openapi | <https://raw.githubusercontent.com/karmada-io/karmada/master/api/openapi-spec/swagger.json>                  |
| [kubernetes](clients/container-orchestration/kubernetes.nu)                                   | openapi | <https://raw.githubusercontent.com/kubernetes/kubernetes/master/api/openapi-spec/swagger.json>               |
| [kubernetes-apisguru](clients/container-orchestration/kubernetes-apisguru.nu)                 | openapi | <https://api.apis.guru/v2/specs/kubernetes.io/unversioned/swagger.json>                                      |
| [nomad](clients/container-orchestration/nomad.nu)                                             | openapi | <https://raw.githubusercontent.com/hashicorp/nomad-openapi/main/v1/openapi.yaml>                             |
| [openfaas](clients/container-orchestration/openfaas.nu)                                       | openapi | <specs/openfaas.yaml>                                                                                        |
| [windows-net-batch](clients/container-orchestration/windows-net-batch.nu)                     | openapi | <https://api.apis.guru/v2/specs/windows.net/batch-BatchService/2018-08-01.7.0/swagger.json>                  |

### containers

| Client                                                 | Type    | Source                                                                                                                |
| ------------------------------------------------------ | ------- | --------------------------------------------------------------------------------------------------------------------- |
| [anchore-engine](clients/containers/anchore-engine.nu) | openapi | <https://raw.githubusercontent.com/anchore/anchore-engine/master/anchore_engine/services/apiext/swagger/swagger.yaml> |
| [anchore-io](clients/containers/anchore-io.nu)         | openapi | <https://api.apis.guru/v2/specs/anchore.io/0.1.20/openapi.json>                                                       |
| [docker](clients/containers/docker.nu)                 | openapi | <https://raw.githubusercontent.com/moby/moby/master/api/swagger.yaml>                                                 |
| [docker-dvp](clients/containers/docker-dvp.nu)         | openapi | <https://api.apis.guru/v2/specs/docker.com/dvp/1.0.0/openapi.json>                                                    |
| [docker-engine](clients/containers/docker-engine.nu)   | openapi | <https://api.apis.guru/v2/specs/docker.com/engine/1.33/openapi.json>                                                  |
| [dockerhub](clients/containers/dockerhub.nu)           | openapi | <https://api.apis.guru/v2/specs/docker.com/hub/beta/openapi.json>                                                     |
| [harbor](clients/containers/harbor.nu)                 | openapi | <https://raw.githubusercontent.com/goharbor/harbor/main/api/v2.0/swagger.yaml>                                        |
| [podman](clients/containers/podman.nu)                 | openapi | <https://storage.googleapis.com/libpod-master-releases/swagger-latest.yaml>                                           |
| [portainer](clients/containers/portainer.nu)           | openapi | <https://app.swaggerhub.com/apiproxy/registry/portainer/portainer-ce/2.20.0>                                          |
| [quay](clients/containers/quay.nu)                     | openapi | <https://quay.io/api/v1/discovery>                                                                                    |
| [rekor](clients/containers/rekor.nu)                   | openapi | <https://raw.githubusercontent.com/sigstore/rekor/main/openapi.yaml>                                                  |
| [snyk](clients/containers/snyk.nu)                     | openapi | <https://api.apis.guru/v2/specs/snyk.io/1.0.0/openapi.json>                                                           |
| [zot](clients/containers/zot.nu)                       | openapi | <https://raw.githubusercontent.com/project-zot/zot/main/swagger/swagger.json>                                         |

### crm

| Client                                                                                | Type    | Source                                                                                     |
| ------------------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------ |
| [apideck-ats](clients/crm/apideck-ats.nu)                                             | openapi | <https://api.apis.guru/v2/specs/apideck.com/ats/9.3.0/openapi.json>                        |
| [apideck-connector](clients/crm/apideck-connector.nu)                                 | openapi | <https://api.apis.guru/v2/specs/apideck.com/connector/9.3.0/openapi.json>                  |
| [apideck-crm](clients/crm/apideck-crm.nu)                                             | openapi | <https://api.apis.guru/v2/specs/apideck.com/crm/9.3.0/openapi.json>                        |
| [apideck-ecommerce](clients/crm/apideck-ecommerce.nu)                                 | openapi | <https://api.apis.guru/v2/specs/apideck.com/ecommerce/9.3.0/openapi.json>                  |
| [apideck-ecosystem](clients/crm/apideck-ecosystem.nu)                                 | openapi | <https://api.apis.guru/v2/specs/apideck.com/ecosystem/0.0.6/openapi.json>                  |
| [apideck-hris](clients/crm/apideck-hris.nu)                                           | openapi | <https://api.apis.guru/v2/specs/apideck.com/hris/9.3.0/openapi.json>                       |
| [apideck-lead](clients/crm/apideck-lead.nu)                                           | openapi | <https://api.apis.guru/v2/specs/apideck.com/lead/9.3.0/openapi.json>                       |
| [apideck-pos](clients/crm/apideck-pos.nu)                                             | openapi | <https://api.apis.guru/v2/specs/apideck.com/pos/9.3.0/openapi.json>                        |
| [apideck-proxy](clients/crm/apideck-proxy.nu)                                         | openapi | <https://api.apis.guru/v2/specs/apideck.com/proxy/9.3.0/openapi.json>                      |
| [apideck-vault](clients/crm/apideck-vault.nu)                                         | openapi | <https://api.apis.guru/v2/specs/apideck.com/vault/9.3.0/openapi.json>                      |
| [attio](clients/crm/attio.nu)                                                         | openapi | <https://api.attio.com/openapi/api>                                                        |
| [close-com](clients/crm/close-com.nu)                                                 | openapi | <https://developer.close.com/openapi.json>                                                 |
| [data2crm](clients/crm/data2crm.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/data2crm.com/1/swagger.json>                               |
| [hubspot-auth](clients/crm/hubspot-auth.nu)                                           | openapi | <https://api.apis.guru/v2/specs/hubapi.com/auth/v1/openapi.json>                           |
| [hubspot-automation](clients/crm/hubspot-automation.nu)                               | openapi | <https://api.apis.guru/v2/specs/hubapi.com/automation/v4/openapi.json>                     |
| [hubspot-business-units](clients/crm/hubspot-business-units.nu)                       | openapi | <https://api.apis.guru/v2/specs/hubapi.com/business%20units/v3/openapi.json>               |
| [hubspot-cms](clients/crm/hubspot-cms.nu)                                             | openapi | <https://api.apis.guru/v2/specs/hubapi.com/cms/v3/openapi.json>                            |
| [hubspot-communication-preferences](clients/crm/hubspot-communication-preferences.nu) | openapi | <https://api.apis.guru/v2/specs/hubapi.com/communication-preferences/v3/openapi.json>      |
| [hubspot-conversations](clients/crm/hubspot-conversations.nu)                         | openapi | <https://api.apis.guru/v2/specs/hubapi.com/conversations/v3/openapi.json>                  |
| [hubspot-crm](clients/crm/hubspot-crm.nu)                                             | openapi | <https://api.apis.guru/v2/specs/hubapi.com/crm/v3/openapi.json>                            |
| [hubspot-events](clients/crm/hubspot-events.nu)                                       | openapi | <https://api.apis.guru/v2/specs/hubapi.com/events/v3/openapi.json>                         |
| [hubspot-files](clients/crm/hubspot-files.nu)                                         | openapi | <https://api.apis.guru/v2/specs/hubapi.com/files/v3/openapi.json>                          |
| [hubspot-webhooks](clients/crm/hubspot-webhooks.nu)                                   | openapi | <https://api.apis.guru/v2/specs/hubapi.com/webhooks/v3/openapi.json>                       |
| [outreach](clients/crm/outreach.nu)                                                   | openapi | <https://api.outreach.io/api/v2/schema/openapi.json>                                       |
| [paylocity](clients/crm/paylocity.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/paylocity.com/2/openapi.json>                              |
| [peoplefinderspro](clients/crm/peoplefinderspro.nu)                                   | openapi | <https://api.apis.guru/v2/specs/peoplefinderspro.com/1.0.0/openapi.json>                   |
| [personio-personnel](clients/crm/personio-personnel.nu)                               | openapi | <https://api.apis.guru/v2/specs/personio.de/personnel/1.0/openapi.json>                    |
| [pipedrive](clients/crm/pipedrive.nu)                                                 | openapi | <https://developers.pipedrive.com/docs/api/v1/openapi.yaml>                                |
| [salesforce-einstein](clients/crm/salesforce-einstein.nu)                             | openapi | <https://api.apis.guru/v2/specs/salesforce.local/einstein/2.0.1/openapi.json>              |
| [salesloft](clients/crm/salesloft.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/salesloft.com/v2/openapi.json>                             |
| [streak](clients/crm/streak.nu)                                                       | openapi | <https://www.streak.com/api/openapi.json>                                                  |
| [suitecrm](clients/crm/suitecrm.nu)                                                   | openapi | <https://raw.githubusercontent.com/SuiteCRM/SuiteCRM/master/Api/docs/swagger/swagger.json> |
| [xero-payroll-au](clients/crm/xero-payroll-au.nu)                                     | openapi | <https://api.apis.guru/v2/specs/xero.com/xero-payroll-au/2.9.4/openapi.json>               |
| [zoho-crm-fields](clients/crm/zoho-crm-fields.nu)                                     | openapi | <https://raw.githubusercontent.com/zoho/crm-oas/main/v8.0/fields.json>                     |
| [zoho-crm-modules](clients/crm/zoho-crm-modules.nu)                                   | openapi | <https://raw.githubusercontent.com/zoho/crm-oas/main/v8.0/modules.json>                    |
| [zoho-crm-records](clients/crm/zoho-crm-records.nu)                                   | openapi | <https://raw.githubusercontent.com/zoho/crm-oas/main/v8.0/record.json>                     |
| [zoho-crm-users](clients/crm/zoho-crm-users.nu)                                       | openapi | <https://raw.githubusercontent.com/zoho/crm-oas/main/v8.0/users.json>                      |

### data-pipeline

| Client                                                                          | Type    | Source                                                                                                                  |
| ------------------------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------- |
| [airbyte-config](clients/data-pipeline/airbyte-config.nu)                       | openapi | <https://api.apis.guru/v2/specs/airbyte.local/config/1.0.0/openapi.json>                                                |
| [airbyte-platform-server](clients/data-pipeline/airbyte-platform-server.nu)     | openapi | <https://raw.githubusercontent.com/airbytehq/airbyte-platform/main/airbyte-api/server-api/src/main/openapi/config.yaml> |
| [airflow](clients/data-pipeline/airflow.nu)                                     | openapi | <https://api.apis.guru/v2/specs/apache.org/airflow/2.5.1/openapi.json>                                                  |
| [apache-qakka](clients/data-pipeline/apache-qakka.nu)                           | openapi | <https://api.apis.guru/v2/specs/apache.org/qakka/v1/openapi.json>                                                       |
| [apache-superset](clients/data-pipeline/apache-superset.nu)                     | openapi | <https://api.apis.guru/v2/specs/superset.apache.local/superset/v1/openapi.json>                                         |
| [aws-appflow](clients/data-pipeline/aws-appflow.nu)                             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/appflow/2020-08-23/openapi.json>                                          |
| [aws-datapipeline](clients/data-pipeline/aws-datapipeline.nu)                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/datapipeline/2012-10-29/openapi.json>                                     |
| [aws-datasync](clients/data-pipeline/aws-datasync.nu)                           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/datasync/2018-11-09/openapi.json>                                         |
| [aws-emr](clients/data-pipeline/aws-emr.nu)                                     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/elasticmapreduce/2009-03-31/openapi.json>                                 |
| [aws-glue](clients/data-pipeline/aws-glue.nu)                                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/glue/2017-03-31/openapi.json>                                             |
| [aws-kinesis](clients/data-pipeline/aws-kinesis.nu)                             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/kinesis/2013-12-02/openapi.json>                                          |
| [aws-kinesis-analytics](clients/data-pipeline/aws-kinesis-analytics.nu)         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/kinesisanalyticsv2/2018-05-23/openapi.json>                               |
| [aws-mq](clients/data-pipeline/aws-mq.nu)                                       | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/mq/2017-11-27/openapi.json>                                               |
| [aws-mwaa](clients/data-pipeline/aws-mwaa.nu)                                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/mwaa/2020-07-01/openapi.json>                                             |
| [azure-databricks](clients/data-pipeline/azure-databricks.nu)                   | openapi | <https://api.apis.guru/v2/specs/azure.com/databricks/2018-04-01/swagger.json>                                           |
| [azure-datafactory](clients/data-pipeline/azure-datafactory.nu)                 | openapi | <https://api.apis.guru/v2/specs/azure.com/datafactory/2018-06-01/swagger.json>                                          |
| [azure-datalake-analytics](clients/data-pipeline/azure-datalake-analytics.nu)   | openapi | <https://api.apis.guru/v2/specs/azure.com/datalake-analytics-account/2016-11-01/swagger.json>                           |
| [azure-datalake-store](clients/data-pipeline/azure-datalake-store.nu)           | openapi | <https://api.apis.guru/v2/specs/azure.com/datalake-store-account/2016-11-01/swagger.json>                               |
| [azure-datashare](clients/data-pipeline/azure-datashare.nu)                     | openapi | <https://api.apis.guru/v2/specs/azure.com/datashare-DataShare/2019-11-01/swagger.json>                                  |
| [azure-eventgrid](clients/data-pipeline/azure-eventgrid.nu)                     | openapi | <https://api.apis.guru/v2/specs/azure.com/eventgrid-EventGrid/2019-06-01/swagger.json>                                  |
| [azure-eventhub](clients/data-pipeline/azure-eventhub.nu)                       | openapi | <https://api.apis.guru/v2/specs/azure.com/eventhub-EventHub/2017-04-01/swagger.json>                                    |
| [azure-hdinsight-cluster](clients/data-pipeline/azure-hdinsight-cluster.nu)     | openapi | <https://api.apis.guru/v2/specs/azure.com/hdinsight-cluster/2018-06-01-preview/swagger.json>                            |
| [azure-logic](clients/data-pipeline/azure-logic.nu)                             | openapi | <https://api.apis.guru/v2/specs/azure.com/logic/2019-05-01/swagger.json>                                                |
| [azure-servicebus](clients/data-pipeline/azure-servicebus.nu)                   | openapi | <https://api.apis.guru/v2/specs/azure.com/servicebus/2017-04-01/swagger.json>                                           |
| [azure-stream-analytics](clients/data-pipeline/azure-stream-analytics.nu)       | openapi | <https://api.apis.guru/v2/specs/azure.com/streamanalytics-functions/2016-03-01/swagger.json>                            |
| [google-cloudtasks](clients/data-pipeline/google-cloudtasks.nu)                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/cloudtasks/v2beta3/openapi.json>                                         |
| [google-datacatalog](clients/data-pipeline/google-datacatalog.nu)               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/datacatalog/v1beta1/openapi.json>                                        |
| [google-dataflow](clients/data-pipeline/google-dataflow.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/dataflow/v1b3/openapi.json>                                              |
| [google-datapipelines](clients/data-pipeline/google-datapipelines.nu)           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/datapipelines/v1/openapi.json>                                           |
| [google-dataplex](clients/data-pipeline/google-dataplex.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/dataplex/v1/openapi.json>                                                |
| [google-dataproc](clients/data-pipeline/google-dataproc.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/dataproc/v1/openapi.json>                                                |
| [google-eventarc](clients/data-pipeline/google-eventarc.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/eventarc/v1beta1/openapi.json>                                           |
| [google-pubsublite](clients/data-pipeline/google-pubsublite.nu)                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/pubsublite/v1/openapi.json>                                              |
| [google-workflowexecutions](clients/data-pipeline/google-workflowexecutions.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/workflowexecutions/v1/openapi.json>                                      |
| [google-workflows](clients/data-pipeline/google-workflows.nu)                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/workflows/v1/openapi.json>                                               |
| [ix-api](clients/data-pipeline/ix-api.nu)                                       | openapi | <https://api.apis.guru/v2/specs/ix-api.net/2.1.0/openapi.json>                                                          |
| [kestra](clients/data-pipeline/kestra.nu)                                       | openapi | <https://raw.githubusercontent.com/kestra-io/client-sdk/main/kestra-ee.yml>                                             |
| [maif-otoroshi](clients/data-pipeline/maif-otoroshi.nu)                         | openapi | <https://api.apis.guru/v2/specs/maif.local/otoroshi/1.5.0-dev/openapi.json>                                             |
| [mercure](clients/data-pipeline/mercure.nu)                                     | openapi | <https://api.apis.guru/v2/specs/mercure.local/0.3.2/openapi.json>                                                       |
| [meshery](clients/data-pipeline/meshery.nu)                                     | openapi | <https://api.apis.guru/v2/specs/meshery.local/0.4.27/openapi.json>                                                      |
| [microcks](clients/data-pipeline/microcks.nu)                                   | openapi | <https://api.apis.guru/v2/specs/microcks.local/1.7.0/openapi.json>                                                      |
| [mozilla-kinto](clients/data-pipeline/mozilla-kinto.nu)                         | openapi | <https://api.apis.guru/v2/specs/mozilla.com/kinto/1.22/openapi.json>                                                    |
| [openapi-converter](clients/data-pipeline/openapi-converter.nu)                 | openapi | <https://api.apis.guru/v2/specs/mermade.org.uk/openapi-converter/1.0.0/openapi.json>                                    |
| [prefect-cloud](clients/data-pipeline/prefect-cloud.nu)                         | openapi | <https://api.prefect.cloud/api/openapi.json>                                                                            |
| [rudder](clients/data-pipeline/rudder.nu)                                       | openapi | <https://api.apis.guru/v2/specs/rudder.example.local/16/openapi.json>                                                   |
| [stoplight-apisguru](clients/data-pipeline/stoplight-apisguru.nu)               | openapi | <https://api.apis.guru/v2/specs/stoplight.io/api-v1/openapi.json>                                                       |
| [swagger-io-generator](clients/data-pipeline/swagger-io-generator.nu)           | openapi | <https://api.apis.guru/v2/specs/swagger.io/generator/2.4.30/swagger.json>                                               |
| [swaggerhub](clients/data-pipeline/swaggerhub.nu)                               | openapi | <https://api.apis.guru/v2/specs/swaggerhub.com/1.0.66/swagger.json>                                                     |
| [temporal](clients/data-pipeline/temporal.nu)                                   | openapi | <https://raw.githubusercontent.com/temporalio/api/master/openapi/openapiv3.yaml>                                        |
| [tyk](clients/data-pipeline/tyk.nu)                                             | openapi | <https://api.apis.guru/v2/specs/tyk.com/1.9/swagger.json>                                                               |
| [windmill](clients/data-pipeline/windmill.nu)                                   | openapi | <https://raw.githubusercontent.com/windmill-labs/windmill/main/backend/windmill-api/openapi.yaml>                       |

### database

| Client                                                                         | Type    | Source                                                                                                      |
| ------------------------------------------------------------------------------ | ------- | ----------------------------------------------------------------------------------------------------------- |
| [aws-dynamodb](clients/database/aws-dynamodb.nu)                               | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/dynamodb/2012-08-10/openapi.json>                             |
| [aws-elasticache](clients/database/aws-elasticache.nu)                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/elasticache/2015-02-02/openapi.json>                          |
| [aws-neptune](clients/database/aws-neptune.nu)                                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/neptune/2014-10-31/openapi.json>                              |
| [aws-qldb](clients/database/aws-qldb.nu)                                       | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/qldb/2019-01-02/openapi.json>                                 |
| [aws-rds](clients/database/aws-rds.nu)                                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/rds/2014-10-31/openapi.json>                                  |
| [aws-rds-data](clients/database/aws-rds-data.nu)                               | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/rds-data/2018-08-01/openapi.json>                             |
| [aws-redshift](clients/database/aws-redshift.nu)                               | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/redshift/2012-12-01/openapi.json>                             |
| [aws-timestream-query](clients/database/aws-timestream-query.nu)               | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/timestream-query/2018-11-01/openapi.json>                     |
| [aws-timestream-write](clients/database/aws-timestream-write.nu)               | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/timestream-write/2018-11-01/openapi.json>                     |
| [azure-cosmos-db](clients/database/azure-cosmos-db.nu)                         | openapi | <https://api.apis.guru/v2/specs/azure.com/cosmos-db/2019-08-01/swagger.json>                                |
| [azure-redis](clients/database/azure-redis.nu)                                 | openapi | <https://api.apis.guru/v2/specs/azure.com/redis/2018-03-01/swagger.json>                                    |
| [bigquery](clients/database/bigquery.nu)                                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/bigquery/v2/openapi.json>                                    |
| [cockroachdb-cloud](clients/database/cockroachdb-cloud.nu)                     | openapi | <https://cockroachlabs.cloud/assets/docs/api/latest/openapi.json>                                           |
| [datasette](clients/database/datasette.nu)                                     | openapi | <https://api.apis.guru/v2/specs/datasette.local/v1/openapi.json>                                            |
| [google-bigquery-connection](clients/database/google-bigquery-connection.nu)   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/bigqueryconnection/v1beta1/openapi.json>                     |
| [google-bigquery-reservation](clients/database/google-bigquery-reservation.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/bigqueryreservation/v1beta1/openapi.json>                    |
| [google-bigtable-admin](clients/database/google-bigtable-admin.nu)             | openapi | <https://api.apis.guru/v2/specs/googleapis.com/bigtableadmin/v2/openapi.json>                               |
| [google-datastore](clients/database/google-datastore.nu)                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/datastore/v1beta1/openapi.json>                              |
| [google-firebase-database](clients/database/google-firebase-database.nu)       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/firebasedatabase/v1beta/openapi.json>                        |
| [google-firestore](clients/database/google-firestore.nu)                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/firestore/v1beta2/openapi.json>                              |
| [google-spanner](clients/database/google-spanner.nu)                           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/spanner/v1/openapi.json>                                     |
| [google-sqladmin](clients/database/google-sqladmin.nu)                         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/sqladmin/v1/openapi.json>                                    |
| [mongodb-atlas](clients/database/mongodb-atlas.nu)                             | openapi | <https://raw.githubusercontent.com/mongodb/openapi/main/openapi/v2.json>                                    |
| [neon](clients/database/neon.nu)                                               | openapi | <https://neon.com/api_spec/release/v2.json>                                                                 |
| [openlinksw-osdb](clients/database/openlinksw-osdb.nu)                         | openapi | <https://api.apis.guru/v2/specs/openlinksw.com/osdb/1.0.0/openapi.json>                                     |
| [planetscale](clients/database/planetscale.nu)                                 | openapi | <https://api.planetscale.com/v1/openapi-spec>                                                               |
| [snowflake-account](clients/database/snowflake-account.nu)                     | openapi | <https://raw.githubusercontent.com/snowflakedb/snowflake-rest-api-specs/main/specifications/account.yaml>   |
| [snowflake-database](clients/database/snowflake-database.nu)                   | openapi | <https://raw.githubusercontent.com/snowflakedb/snowflake-rest-api-specs/main/specifications/database.yaml>  |
| [snowflake-sqlapi](clients/database/snowflake-sqlapi.nu)                       | openapi | <https://raw.githubusercontent.com/snowflakedb/snowflake-rest-api-specs/main/specifications/sqlapi.yaml>    |
| [snowflake-warehouse](clients/database/snowflake-warehouse.nu)                 | openapi | <https://raw.githubusercontent.com/snowflakedb/snowflake-rest-api-specs/main/specifications/warehouse.yaml> |
| [supabase-mgmt](clients/database/supabase-mgmt.nu)                             | openapi | <https://api.supabase.com/api/v1-json>                                                                      |
| [turso](clients/database/turso.nu)                                             | openapi | <https://raw.githubusercontent.com/tursodatabase/turso-docs/main/api-reference/openapi.json>                |

### dns

| Client                                                      | Type    | Source                                                                                |
| ----------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------- |
| [aws-route53](clients/dns/aws-route53.nu)                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/route53/2013-04-01/openapi.json>        |
| [aws-route53domains](clients/dns/aws-route53domains.nu)     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/route53domains/2014-05-15/openapi.json> |
| [azure-dns](clients/dns/azure-dns.nu)                       | openapi | <https://api.apis.guru/v2/specs/azure.com/dns/2018-05-01/swagger.json>                |
| [azure-privatedns](clients/dns/azure-privatedns.nu)         | openapi | <https://api.apis.guru/v2/specs/azure.com/privatedns/2018-09-01/swagger.json>         |
| [azure-web-domains](clients/dns/azure-web-domains.nu)       | openapi | <https://api.apis.guru/v2/specs/azure.com/web-Domains/2018-02-01/swagger.json>        |
| [domainsdb](clients/dns/domainsdb.nu)                       | openapi | <https://api.apis.guru/v2/specs/domainsdb.info/1.0/openapi.json>                      |
| [godaddy-aftermarket](clients/dns/godaddy-aftermarket.nu)   | openapi | <https://api.apis.guru/v2/specs/ote-godaddy.com/aftermarket/1.0.0/openapi.json>       |
| [godaddy-agreements](clients/dns/godaddy-agreements.nu)     | openapi | <https://api.apis.guru/v2/specs/ote-godaddy.com/agreements/1.0.0/openapi.json>        |
| [godaddy-certificates](clients/dns/godaddy-certificates.nu) | openapi | <https://api.apis.guru/v2/specs/ote-godaddy.com/certificates/1.0.0/openapi.json>      |
| [godaddy-countries](clients/dns/godaddy-countries.nu)       | openapi | <https://api.apis.guru/v2/specs/ote-godaddy.com/countries/1.0.0/openapi.json>         |
| [godaddy-domains](clients/dns/godaddy-domains.nu)           | openapi | <https://api.apis.guru/v2/specs/ote-godaddy.com/domains/1.0.0/openapi.json>           |
| [godaddy-orders](clients/dns/godaddy-orders.nu)             | openapi | <https://api.apis.guru/v2/specs/ote-godaddy.com/orders/1.0.0/openapi.json>            |
| [google-acmedns](clients/dns/google-acmedns.nu)             | openapi | <https://api.apis.guru/v2/specs/googleapis.com/acmedns/v1/openapi.json>               |
| [google-cloud-domains](clients/dns/google-cloud-domains.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/domains/v1beta1/openapi.json>          |
| [google-dns](clients/dns/google-dns.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/dns/v1/openapi.json>                   |
| [google-domainsrdap](clients/dns/google-domainsrdap.nu)     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/domainsrdap/v1/openapi.json>           |
| [nic-at-domainfinder](clients/dns/nic-at-domainfinder.nu)   | openapi | <https://api.apis.guru/v2/specs/nic.at/domainfinder/1.1.0/openapi.json>               |
| [powerdns](clients/dns/powerdns.nu)                         | openapi | <https://api.apis.guru/v2/specs/powerdns.local/0.0.13/swagger.json>                   |

### email

| Client                                          | Type    | Source                                                                                             |
| ----------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------- |
| [aws-ses](clients/email/aws-ses.nu)             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/email/2010-12-01/openapi.json>                       |
| [aws-sesv2](clients/email/aws-sesv2.nu)         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/sesv2/2019-09-27/openapi.json>                       |
| [brevo](clients/email/brevo.nu)                 | openapi | <https://raw.githubusercontent.com/xdev-software/brevo-java-client/develop/openapi/openapi.yml>    |
| [buttondown](clients/email/buttondown.nu)       | openapi | <https://raw.githubusercontent.com/buttondown/openapi/main/openapi.json>                           |
| [elasticemail](clients/email/elasticemail.nu)   | openapi | <https://raw.githubusercontent.com/elasticemail/elasticemail-go/master/api/openapi.yaml>           |
| [gmail](clients/email/gmail.nu)                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/gmail/v1/openapi.json>                              |
| [inboxroute](clients/email/inboxroute.nu)       | openapi | <https://api.apis.guru/v2/specs/inboxroute.com/0.9/swagger.json>                                   |
| [loops](clients/email/loops.nu)                 | openapi | <https://app.loops.so/openapi.json>                                                                |
| [mailersend](clients/email/mailersend.nu)       | openapi | <https://api.swaggerhub.com/apis/MailerSend/mailersend-api/1.0.0-oas3.1>                           |
| [mailgun](clients/email/mailgun.nu)             | openapi | <https://documentation.mailgun.com/_spec/docs/mailgun/api-reference/send/mailgun.yaml?download>    |
| [mailscript](clients/email/mailscript.nu)       | openapi | <https://api.apis.guru/v2/specs/mailscript.com/0.4.0/openapi.json>                                 |
| [mailtrap](clients/email/mailtrap.nu)           | openapi | <https://raw.githubusercontent.com/mailtrap/mailtrap-openapi/main/specs/email-sending.openapi.yml> |
| [mandrill](clients/email/mandrill.nu)           | openapi | <https://api.apis.guru/v2/specs/mandrillapp.com/1.0/swagger.json>                                  |
| [postmark](clients/email/postmark.nu)           | openapi | <https://api.apis.guru/v2/specs/postmarkapp.com/server/1.0.0/swagger.json>                         |
| [resend](clients/email/resend.nu)               | openapi | <https://raw.githubusercontent.com/resend/resend-openapi/main/resend.yaml>                         |
| [scrapewebsite](clients/email/scrapewebsite.nu) | openapi | <https://api.apis.guru/v2/specs/scrapewebsite.email/0.1/swagger.json>                              |
| [sendgrid](clients/email/sendgrid.nu)           | openapi | <https://api.apis.guru/v2/specs/sendgrid.com/1.0.0/openapi.json>                                   |

### error-tracking

| Client                                                   | Type    | Source                                                                                                          |
| -------------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------------------------- |
| [bugsnag](clients/error-tracking/bugsnag.nu)             | openapi | <https://api.swaggerhub.com/apis/smartbear-public/bugsnag-data-access-api/2/swagger.json>                       |
| [coralogix](clients/error-tracking/coralogix.nu)         | openapi | <https://api.coralogix.com/mgmt/openapi/latest/openapi.yaml>                                                    |
| [datadog-v1](clients/error-tracking/datadog-v1.nu)       | openapi | <https://raw.githubusercontent.com/DataDog/datadog-api-client-python/master/.generator/schemas/v1/openapi.yaml> |
| [elastic-cloud](clients/error-tracking/elastic-cloud.nu) | openapi | <https://api.elastic-cloud.com/api/v1/api-docs-user/swagger.json>                                               |
| [elmah-io](clients/error-tracking/elmah-io.nu)           | openapi | <https://api.apis.guru/v2/specs/elmah.io/v3/openapi.json>                                                       |
| [logflare](clients/error-tracking/logflare.nu)           | openapi | <https://logflare.app/api/openapi>                                                                              |
| [newrelic](clients/error-tracking/newrelic.nu)           | openapi | <https://api.eu.newrelic.com/docs/swagger.yml>                                                                  |
| [rumble](clients/error-tracking/rumble.nu)               | openapi | <https://api.apis.guru/v2/specs/rumble.run/2.15.0/openapi.json>                                                 |
| [sentry](clients/error-tracking/sentry.nu)               | openapi | <https://raw.githubusercontent.com/getsentry/sentry-api-schema/main/openapi-derefed.json>                       |
| [signl4-error](clients/error-tracking/signl4-error.nu)   | openapi | <https://api.apis.guru/v2/specs/signl4.com/v1/openapi.json>                                                     |
| [signoz](clients/error-tracking/signoz.nu)               | openapi | <https://raw.githubusercontent.com/SigNoz/signoz/main/docs/api/openapi.yml>                                     |
| [sumo-logic](clients/error-tracking/sumo-logic.nu)       | openapi | <https://api.sumologic.com/docs/sumologic-api.yaml>                                                             |

### events

| Client                                                             | Type    | Source                                                                                          |
| ------------------------------------------------------------------ | ------- | ----------------------------------------------------------------------------------------------- |
| [predicthq-events](clients/events/predicthq-events.nu)             | openapi | <https://raw.githubusercontent.com/predicthq/api-specs/refs/heads/main/openapi/events-api.yaml> |
| [setlist-fm](clients/events/setlist-fm.nu)                         | openapi | <https://api.setlist.fm/docs/1.0/ui/swagger.json>                                               |
| [ticketmaster-commerce](clients/events/ticketmaster-commerce.nu)   | openapi | <https://api.apis.guru/v2/specs/ticketmaster.com/commerce/v2/swagger.json>                      |
| [ticketmaster-discovery](clients/events/ticketmaster-discovery.nu) | openapi | <https://api.apis.guru/v2/specs/ticketmaster.com/discovery/v2/openapi.json>                     |
| [ticketmaster-publish](clients/events/ticketmaster-publish.nu)     | openapi | <https://api.apis.guru/v2/specs/ticketmaster.com/publish/v2/openapi.json>                       |

### feature-flags

| Client                                                                              | Type    | Source                                                                                                   |
| ----------------------------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------- |
| [configcat](clients/feature-flags/configcat.nu)                                     | openapi | <https://api.apis.guru/v2/specs/configcat.com/v1/openapi.json>                                           |
| [devcycle](clients/feature-flags/devcycle.nu)                                       | openapi | <https://api.devcycle.com/openapi.json>                                                                  |
| [featurehub](clients/feature-flags/featurehub.nu)                                   | openapi | <https://raw.githubusercontent.com/featurehub-io/featurehub/master/backend/mr-api/mr-api.yaml>           |
| [flagsmith](clients/feature-flags/flagsmith.nu)                                     | openapi | <https://api.flagsmith.com/api/v1/swagger.json>                                                          |
| [flipt](clients/feature-flags/flipt.nu)                                             | openapi | <https://raw.githubusercontent.com/flipt-io/flipt/main/openapi.yaml>                                     |
| [go-feature-flag](clients/feature-flags/go-feature-flag.nu)                         | openapi | <https://raw.githubusercontent.com/thomaspoignant/go-feature-flag/main/cmd/relayproxy/docs/swagger.json> |
| [google-recommendationengine](clients/feature-flags/google-recommendationengine.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/recommendationengine/v1beta1/openapi.json>                |
| [google-retail](clients/feature-flags/google-retail.nu)                             | openapi | <https://api.apis.guru/v2/specs/googleapis.com/retail/v2alpha/openapi.json>                              |
| [growthbook](clients/feature-flags/growthbook.nu)                                   | openapi | <https://raw.githubusercontent.com/growthbook/growthbook/main/packages/back-end/generated/spec.yaml>     |
| [harness-ff](clients/feature-flags/harness-ff.nu)                                   | openapi | <https://raw.githubusercontent.com/harness/ff-php-server-sdk/main/api.yaml>                              |
| [launchdarkly](clients/feature-flags/launchdarkly.nu)                               | openapi | <https://api.apis.guru/v2/specs/launchdarkly.com/5.3.0/swagger.json>                                     |
| [openfeature-ofrep](clients/feature-flags/openfeature-ofrep.nu)                     | openapi | <https://raw.githubusercontent.com/open-feature/protocol/main/service/openapi.yaml>                      |
| [optimizely](clients/feature-flags/optimizely.nu)                                   | openapi | <https://api.optimizely.com/swagger.json>                                                                |
| [unleash](clients/feature-flags/unleash.nu)                                         | openapi | <https://docs.getunleash.io/api/openapi.json>                                                            |

### finance

| Client                                                                                          | Type    | Source                                                                                                     |
| ----------------------------------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------------------- |
| [1forge](clients/finance/1forge.nu)                                                             | openapi | <https://api.apis.guru/v2/specs/1forge.com/0.0.1/swagger.json>                                             |
| [afterbanks](clients/finance/afterbanks.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/afterbanks.com/3.0.0/swagger.json>                                         |
| [alpaca-broker](clients/finance/alpaca-broker.nu)                                               | openapi | <https://raw.githubusercontent.com/alpacahq/alpaca-docs/master/oas/broker/openapi.yaml>                    |
| [alpaca-data](clients/finance/alpaca-data.nu)                                                   | openapi | <https://raw.githubusercontent.com/alpacahq/alpaca-docs/master/oas/data/openapi.yaml>                      |
| [alpaca-trading](clients/finance/alpaca-trading.nu)                                             | openapi | <https://raw.githubusercontent.com/alpacahq/alpaca-docs/master/oas/trading/openapi.yaml>                   |
| [apideck-accounting](clients/finance/apideck-accounting.nu)                                     | openapi | <https://api.apis.guru/v2/specs/apideck.com/accounting/9.3.0/openapi.json>                                 |
| [beanstream](clients/finance/beanstream.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/beanstream.com/1.0.1/swagger.json>                                         |
| [binance-spot](clients/finance/binance-spot.nu)                                                 | openapi | <https://raw.githubusercontent.com/binance/binance-api-swagger/master/spot_api.yaml>                       |
| [brex](clients/finance/brex.nu)                                                                 | openapi | <https://api.apis.guru/v2/specs/brex.io/2021.12/openapi.json>                                              |
| [bunq](clients/finance/bunq.nu)                                                                 | openapi | <https://api.apis.guru/v2/specs/bunq.com/1.0/openapi.json>                                                 |
| [codat-accounting](clients/finance/codat-accounting.nu)                                         | openapi | <https://api.apis.guru/v2/specs/codat.io/accounting/2.1.0/openapi.json>                                    |
| [codat-assess](clients/finance/codat-assess.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/codat.io/assess/1.0/openapi.json>                                          |
| [codat-bank-feeds](clients/finance/codat-bank-feeds.nu)                                         | openapi | <https://api.apis.guru/v2/specs/codat.io/bank-feeds/2.1.0/openapi.json>                                    |
| [codat-banking](clients/finance/codat-banking.nu)                                               | openapi | <https://api.apis.guru/v2/specs/codat.io/banking/2.1.0/openapi.json>                                       |
| [codat-commerce](clients/finance/codat-commerce.nu)                                             | openapi | <https://api.apis.guru/v2/specs/codat.io/commerce/2.1.0/openapi.json>                                      |
| [codat-sync-commerce](clients/finance/codat-sync-commerce.nu)                                   | openapi | <https://api.apis.guru/v2/specs/codat.io/sync-for-commerce/1.1/openapi.json>                               |
| [codat-sync-expenses](clients/finance/codat-sync-expenses.nu)                                   | openapi | <https://api.apis.guru/v2/specs/codat.io/sync-for-expenses/prealpha/openapi.json>                          |
| [coingecko](clients/finance/coingecko.nu)                                                       | openapi | <https://raw.githubusercontent.com/coingecko/coingecko-api-oas/main/demo-api.json>                         |
| [coingecko-pro](clients/finance/coingecko-pro.nu)                                               | openapi | <https://raw.githubusercontent.com/coingecko/coingecko-api-oas/main/pro-api.json>                          |
| [consumer-finance](clients/finance/consumer-finance.nu)                                         | openapi | <https://api.apis.guru/v2/specs/consumerfinance.gov/1.0/swagger.yaml>                                      |
| [exchangerate-api](clients/finance/exchangerate-api.nu)                                         | openapi | <https://api.apis.guru/v2/specs/exchangerate-api.com/4/openapi.yaml>                                       |
| [exchangerate-api-apisguru](clients/finance/exchangerate-api-apisguru.nu)                       | openapi | <https://api.apis.guru/v2/specs/exchangerate-api.com/4/openapi.json>                                       |
| [financial-modeling-prep](clients/finance/financial-modeling-prep.nu)                           | openapi | <https://raw.githubusercontent.com/DigiBugCat/fmp-openapi/main/fmp-openapi.yaml>                           |
| [fire-com](clients/finance/fire-com.nu)                                                         | openapi | <https://api.apis.guru/v2/specs/fire.com/1.0/openapi.json>                                                 |
| [frankfurter](clients/finance/frankfurter.nu)                                                   | openapi | <https://api.frankfurter.app/openapi.json>                                                                 |
| [frankie-financial](clients/finance/frankie-financial.nu)                                       | openapi | <https://api.apis.guru/v2/specs/frankiefinancial.io/1.5.3/swagger.json>                                    |
| [globalwinescore](clients/finance/globalwinescore.nu)                                           | openapi | <https://api.apis.guru/v2/specs/globalwinescore.com/8234aab51481d37a30757d925b7f4221a659427e/openapi.json> |
| [hsbc-atm](clients/finance/hsbc-atm.nu)                                                         | openapi | <https://api.apis.guru/v2/specs/hsbc.com/atm/2.2.1/swagger.json>                                           |
| [hsbc-branches](clients/finance/hsbc-branches.nu)                                               | openapi | <https://api.apis.guru/v2/specs/hsbc.com/branches/2.2.1/swagger.json>                                      |
| [hsbc-product](clients/finance/hsbc-product.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/hsbc.com/product/2.2.1/swagger.json>                                       |
| [increase](clients/finance/increase.nu)                                                         | openapi | <https://api.apis.guru/v2/specs/increase.com/0.0.1/openapi.json>                                           |
| [interactivebrokers](clients/finance/interactivebrokers.nu)                                     | openapi | <https://api.apis.guru/v2/specs/interactivebrokers.com/1.0.0/openapi.json>                                 |
| [interzoid-convertcurrency](clients/finance/interzoid-convertcurrency.nu)                       | openapi | <https://api.apis.guru/v2/specs/interzoid.com/convertcurrency/1.0.0/openapi.json>                          |
| [interzoid-currency](clients/finance/interzoid-currency.nu)                                     | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getcurrencyrate/1.0.0/openapi.yaml>                          |
| [interzoid-getcurrencyrate](clients/finance/interzoid-getcurrencyrate.nu)                       | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getcurrencyrate/1.0.0/openapi.json>                          |
| [klarna-openai](clients/finance/klarna-openai.nu)                                               | openapi | <https://api.apis.guru/v2/specs/klarna.com/openai/v0/openapi.json>                                         |
| [loket](clients/finance/loket.nu)                                                               | openapi | <https://api.apis.guru/v2/specs/loket.nl/V2/openapi.json>                                                  |
| [mastercard-billpay](clients/finance/mastercard-billpay.nu)                                     | openapi | <https://api.apis.guru/v2/specs/mastercard.com/BillPay/1.0/swagger.json>                                   |
| [mastercard-bintable](clients/finance/mastercard-bintable.nu)                                   | openapi | <https://api.apis.guru/v2/specs/mastercard.com/BINTableResource/1.0/swagger.json>                          |
| [mastercard-currency](clients/finance/mastercard-currency.nu)                                   | openapi | <https://api.apis.guru/v2/specs/mastercard.com/CurrencyConversionCalculator/1.0.0/swagger.yaml>            |
| [mastercard-currency-conversion](clients/finance/mastercard-currency-conversion.nu)             | openapi | <https://api.apis.guru/v2/specs/mastercard.com/CurrencyConversionCalculator/1.0.0/swagger.json>            |
| [mastercard-locations](clients/finance/mastercard-locations.nu)                                 | openapi | <https://api.apis.guru/v2/specs/mastercard.com/Locations/1.0.0/swagger.json>                               |
| [mastercard-masterpassqr](clients/finance/mastercard-masterpassqr.nu)                           | openapi | <https://api.apis.guru/v2/specs/mastercard.com/masterpassqr/V1/swagger.json>                               |
| [mastercard-match](clients/finance/mastercard-match.nu)                                         | openapi | <https://api.apis.guru/v2/specs/mastercard.com/MATCH/1.0.0/swagger.json>                                   |
| [mastercard-maws](clients/finance/mastercard-maws.nu)                                           | openapi | <https://api.apis.guru/v2/specs/mastercard.com/MAWS/1.1.0/swagger.json>                                    |
| [mastercard-mdes](clients/finance/mastercard-mdes.nu)                                           | openapi | <https://api.apis.guru/v2/specs/mastercard.com/MDES/2.0.7/swagger.json>                                    |
| [mastercard-merchant-id](clients/finance/mastercard-merchant-id.nu)                             | openapi | <https://api.apis.guru/v2/specs/mastercard.com/MerchantIdentifier/2.0.0/swagger.json>                      |
| [mastercard-openbanking-connect-pis](clients/finance/mastercard-openbanking-connect-pis.nu)     | openapi | <https://api.apis.guru/v2/specs/mastercard.com/open-banking-connect-pis/1.16.0/swagger.json>               |
| [mastercard-payment-account-reference](clients/finance/mastercard-payment-account-reference.nu) | openapi | <https://api.apis.guru/v2/specs/mastercard.com/PaymentAccountReferenceInquiryAPI/1.1/swagger.json>         |
| [mastercard-personalized-loyalty](clients/finance/mastercard-personalized-loyalty.nu)           | openapi | <https://api.apis.guru/v2/specs/mastercard.com/PersonalizedLoyaltyOffers/1.3/swagger.json>                 |
| [mastercard-repower](clients/finance/mastercard-repower.nu)                                     | openapi | <https://api.apis.guru/v2/specs/mastercard.com/Repower/V2/swagger.json>                                    |
| [mastercard-spending-pulse](clients/finance/mastercard-spending-pulse.nu)                       | openapi | <https://api.apis.guru/v2/specs/mastercard.com/SpendingPulse/1.0/swagger.json>                             |
| [naviplan-factfinder](clients/finance/naviplan-factfinder.nu)                                   | openapi | <https://api.apis.guru/v2/specs/naviplancentral.com/factfinder/v1/swagger.json>                            |
| [naviplan-plan](clients/finance/naviplan-plan.nu)                                               | openapi | <https://api.apis.guru/v2/specs/naviplancentral.com/plan/v1/swagger.json>                                  |
| [nbg](clients/finance/nbg.nu)                                                                   | openapi | <https://api.apis.guru/v2/specs/nbg.gr/v3.1.5/openapi.json>                                                |
| [nebl](clients/finance/nebl.nu)                                                                 | openapi | <https://api.apis.guru/v2/specs/nebl.io/1.3.0/openapi.json>                                                |
| [nfusionsolutions](clients/finance/nfusionsolutions.nu)                                         | openapi | <https://api.apis.guru/v2/specs/nfusionsolutions.biz/1/openapi.json>                                       |
| [nordigen](clients/finance/nordigen.nu)                                                         | openapi | <https://api.apis.guru/v2/specs/nordigen.com/2.0%20(v2)/openapi.json>                                      |
| [nordigen-apisguru](clients/finance/nordigen-apisguru.nu)                                       | openapi | <https://api.apis.guru/v2/specs/nordigen.com/2.0%20%28v2%29/openapi.json>                                  |
| [ntropy](clients/finance/ntropy.nu)                                                             | openapi | <https://api.apis.guru/v2/specs/ntropy.network/1.0.0/openapi.json>                                         |
| [obono](clients/finance/obono.nu)                                                               | openapi | <https://api.apis.guru/v2/specs/obono.at/1.4.0.0/openapi.json>                                             |
| [openbanking-accountinfo](clients/finance/openbanking-accountinfo.nu)                           | openapi | <https://api.apis.guru/v2/specs/openbanking.org.uk/account-info-openapi/3.1.7/openapi.json>                |
| [openbanking-event-notifications](clients/finance/openbanking-event-notifications.nu)           | openapi | <https://api.apis.guru/v2/specs/openbanking.org.uk/event-notifications-openapi/3.1.7/openapi.json>         |
| [openbanking-paymentinit](clients/finance/openbanking-paymentinit.nu)                           | openapi | <https://api.apis.guru/v2/specs/openbanking.org.uk/payment-initiation-openapi/3.1.7/openapi.json>          |
| [openbanking-uk](clients/finance/openbanking-uk.nu)                                             | openapi | <https://api.apis.guru/v2/specs/openbanking.org.uk/v1.3/openapi.json>                                      |
| [openbanking-uk-confirmation-funds](clients/finance/openbanking-uk-confirmation-funds.nu)       | openapi | <https://api.apis.guru/v2/specs/openbanking.org.uk/confirmation-funds-openapi/3.1.7/openapi.json>          |
| [openfintech](clients/finance/openfintech.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/openfintech.io/2017-08-24/swagger.json>                                    |
| [payments-gov-uk](clients/finance/payments-gov-uk.nu)                                           | openapi | <https://api.apis.guru/v2/specs/payments.service.gov.uk/payments/1.0.3/swagger.json>                       |
| [paypi](clients/finance/paypi.nu)                                                               | openapi | <https://api.apis.guru/v2/specs/paypi.dev/1.0.0/openapi.json>                                              |
| [payrun](clients/finance/payrun.nu)                                                             | openapi | <https://api.apis.guru/v2/specs/payrun.io/22.23.10.42/openapi.json>                                        |
| [plaid-apisguru](clients/finance/plaid-apisguru.nu)                                             | openapi | <https://api.apis.guru/v2/specs/plaid.com/2020-09-14_1.334.0/openapi.json>                                 |
| [pocketsmith](clients/finance/pocketsmith.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/pocketsmith.com/2.0/openapi.json>                                          |
| [polygon-apisguru](clients/finance/polygon-apisguru.nu)                                         | openapi | <https://api.apis.guru/v2/specs/polygon.io/1.0.0/swagger.json>                                             |
| [polygon-io](clients/finance/polygon-io.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/polygon.io/1.0.0/swagger.yaml>                                             |
| [portfoliooptimizer](clients/finance/portfoliooptimizer.nu)                                     | openapi | <https://api.apis.guru/v2/specs/portfoliooptimizer.io/1.0.9/openapi.json>                                  |
| [qualpay](clients/finance/qualpay.nu)                                                           | openapi | <https://api.apis.guru/v2/specs/qualpay.com/1.7.0/swagger.json>                                            |
| [sinao](clients/finance/sinao.nu)                                                               | openapi | <https://api.apis.guru/v2/specs/sinao.app/1.1.0/openapi.json>                                              |
| [sonar-trading](clients/finance/sonar-trading.nu)                                               | openapi | <https://api.apis.guru/v2/specs/sonar.trading/1.0/swagger.json>                                            |
| [spectrocoin](clients/finance/spectrocoin.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/spectrocoin.com/1.0.0/swagger.json>                                        |
| [tokenmetrics](clients/finance/tokenmetrics.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/tokenmetrics.com/1.0.0/openapi.json>                                       |
| [tradematic](clients/finance/tradematic.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/tradematic.com/1.0.2/swagger.json>                                         |
| [truora](clients/finance/truora.nu)                                                             | openapi | <https://api.apis.guru/v2/specs/truora.com/1.0.0/openapi.json>                                             |
| [up-com-au](clients/finance/up-com-au.nu)                                                       | openapi | <https://api.apis.guru/v2/specs/up.com.au/v1/openapi.json>                                                 |
| [velopayments](clients/finance/velopayments.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/velopayments.com/2.34.63/openapi.json>                                     |
| [vestorly](clients/finance/vestorly.nu)                                                         | openapi | <https://api.apis.guru/v2/specs/vestorly.com/1.0.0/swagger.json>                                           |
| [wealthreader](clients/finance/wealthreader.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/wealthreader.com/1.0.0/openapi.json>                                       |
| [whapi-accounts](clients/finance/whapi-accounts.nu)                                             | openapi | <https://api.apis.guru/v2/specs/whapi.com/accounts/2.0.0/swagger.json>                                     |
| [whapi-bets](clients/finance/whapi-bets.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/whapi.com/bets/2.0.0/openapi.json>                                         |
| [whapi-locations](clients/finance/whapi-locations.nu)                                           | openapi | <https://api.apis.guru/v2/specs/whapi.com/locations/2.0/swagger.json>                                      |
| [whapi-numbers](clients/finance/whapi-numbers.nu)                                               | openapi | <https://api.apis.guru/v2/specs/whapi.com/numbers/2.0/swagger.json>                                        |
| [whapi-sessions](clients/finance/whapi-sessions.nu)                                             | openapi | <https://api.apis.guru/v2/specs/whapi.com/sessions/2.0.0/swagger.json>                                     |
| [xero-accounting](clients/finance/xero-accounting.nu)                                           | openapi | <https://api.apis.guru/v2/specs/xero.com/xero_accounting/2.9.4/openapi.json>                               |
| [xero-assets](clients/finance/xero-assets.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/xero.com/xero_assets/2.9.4/openapi.json>                                   |
| [xero-bankfeeds](clients/finance/xero-bankfeeds.nu)                                             | openapi | <https://api.apis.guru/v2/specs/xero.com/xero_bankfeeds/2.9.4/openapi.json>                                |
| [xero-files](clients/finance/xero-files.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/xero.com/xero_files/2.9.4/openapi.json>                                    |
| [yodlee](clients/finance/yodlee.nu)                                                             | openapi | <https://api.apis.guru/v2/specs/yodlee.com/1.1.0/openapi.json>                                             |
| [youneedabudget](clients/finance/youneedabudget.nu)                                             | openapi | <https://api.apis.guru/v2/specs/youneedabudget.com/1.0.0/openapi.json>                                     |

### food

| Client                                                         | Type    | Source                                                                                               |
| -------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------------- |
| [bigoven](clients/food/bigoven.nu)                             | openapi | <https://api.apis.guru/v2/specs/bigoven.com/partner/openapi.json>                                    |
| [calorieninjas](clients/food/calorieninjas.nu)                 | openapi | <https://api.apis.guru/v2/specs/calorieninjas.com/1.0.0/openapi.json>                                |
| [just-eat](clients/food/just-eat.nu)                           | openapi | <https://api.apis.guru/v2/specs/just-eat.co.uk/1.0.0/openapi.json>                                   |
| [openfoodfacts](clients/food/openfoodfacts.nu)                 | openapi | <https://raw.githubusercontent.com/openfoodfacts/openfoodfacts-server/main/docs/api/ref/api.yaml>    |
| [openfoodfacts-v3](clients/food/openfoodfacts-v3.nu)           | openapi | <https://raw.githubusercontent.com/openfoodfacts/openfoodfacts-server/main/docs/api/ref/api-v3.yaml> |
| [spoonacular](clients/food/spoonacular.nu)                     | openapi | <https://api.apis.guru/v2/specs/spoonacular.com/1.1/openapi.json>                                    |
| [usda-fooddata-central](clients/food/usda-fooddata-central.nu) | openapi | <https://api.swaggerhub.com/apis/fdcnal/food-data_central_api/1.0.1/swagger.json>                    |

### forms

| Client                                                                        | Type    | Source                                                                                                                                           |
| ----------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| [api2pdf](clients/forms/api2pdf.nu)                                           | openapi | <https://api.apis.guru/v2/specs/api2pdf.com/1.0.0/openapi.json>                                                                                  |
| [azure-form-recognizer](clients/forms/azure-form-recognizer.nu)               | openapi | <https://api.apis.guru/v2/specs/azure.com/cognitiveservices-FormRecognizer/2.0-preview/swagger.yaml>                                             |
| [boldsign](clients/forms/boldsign.nu)                                         | openapi | <https://api.boldsign.com/swagger/v1/swagger.json>                                                                                               |
| [docuseal](clients/forms/docuseal.nu)                                         | openapi | <https://console.docuseal.com/openapi.json>                                                                                                      |
| [docusign-admin](clients/forms/docusign-admin.nu)                             | openapi | <https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/admin.rest.swagger-v2.1.json>                                          |
| [docusign-agreement-manager](clients/forms/docusign-agreement-manager.nu)     | openapi | <https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/agreementmanager.rest.swagger-1.0.0.json>                              |
| [docusign-click](clients/forms/docusign-click.nu)                             | openapi | <https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/click.rest.swagger-v2.json>                                            |
| [docusign-connected-fields](clients/forms/docusign-connected-fields.nu)       | openapi | <https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/connected-fields.rest.swagger.json>                                    |
| [docusign-maestro](clients/forms/docusign-maestro.nu)                         | openapi | <https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/maestro.rest.swagger-v1.0.0.json>                                      |
| [docusign-monitor](clients/forms/docusign-monitor.nu)                         | openapi | <https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/monitor.rest.swagger-v2.0.json>                                        |
| [docusign-navigator](clients/forms/docusign-navigator.nu)                     | openapi | <https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/navigator.rest.swagger.json>                                           |
| [docusign-rooms](clients/forms/docusign-rooms.nu)                             | openapi | <https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/rooms.rest.swagger-v2.json>                                            |
| [docusign-webforms](clients/forms/docusign-webforms.nu)                       | openapi | <https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/webforms.rest.swagger-v1.1.0.json>                                     |
| [docusign-workflow-builder](clients/forms/docusign-workflow-builder.nu)       | openapi | <https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/workflowbuilder.rest.swagger-1.0.0.json>                               |
| [docusign-workspaces](clients/forms/docusign-workspaces.nu)                   | openapi | <https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/workspaces.rest.swagger.json>                                          |
| [dropbox-sign](clients/forms/dropbox-sign.nu)                                 | openapi | <https://raw.githubusercontent.com/hellosign/hellosign-openapi/main/openapi.yaml>                                                                |
| [easypdfserver](clients/forms/easypdfserver.nu)                               | openapi | <https://api.apis.guru/v2/specs/easypdfserver.com/1/openapi.json>                                                                                |
| [envoice-apisguru](clients/forms/envoice-apisguru.nu)                         | openapi | <https://api.apis.guru/v2/specs/envoice.in/v1/openapi.json>                                                                                      |
| [formapi-io](clients/forms/formapi-io.nu)                                     | openapi | <https://api.apis.guru/v2/specs/formapi.io/v1/openapi.json>                                                                                      |
| [google-docs](clients/forms/google-docs.nu)                                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/docs/v1/openapi.json>                                                                             |
| [google-forms](clients/forms/google-forms.nu)                                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/forms/v1/openapi.json>                                                                            |
| [google-sheets](clients/forms/google-sheets.nu)                               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/sheets/v4/openapi.json>                                                                           |
| [google-slides](clients/forms/google-slides.nu)                               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/slides/v1/openapi.json>                                                                           |
| [handwrytten](clients/forms/handwrytten.nu)                                   | openapi | <https://api.apis.guru/v2/specs/handwrytten.com/1.0.0/swagger.json>                                                                              |
| [hubspot-forms](clients/forms/hubspot-forms.nu)                               | openapi | <https://raw.githubusercontent.com/HubSpot/HubSpot-public-api-spec-collection/main/PublicApiSpecs/Marketing/Forms/Rollouts/144909/v3/forms.json> |
| [magick-nu](clients/forms/magick-nu.nu)                                       | openapi | <https://api.apis.guru/v2/specs/magick.nu/1.0/swagger.json>                                                                                      |
| [pandadoc](clients/forms/pandadoc.nu)                                         | openapi | <https://raw.githubusercontent.com/PandaDoc/pandadoc-openapi-specification/main/openapi.yaml>                                                    |
| [pdfblocks](clients/forms/pdfblocks.nu)                                       | openapi | <https://api.apis.guru/v2/specs/pdfblocks.com/1.5.0/openapi.json>                                                                                |
| [pdfbroker](clients/forms/pdfbroker.nu)                                       | openapi | <https://api.apis.guru/v2/specs/pdfbroker.io/v1/openapi.json>                                                                                    |
| [pdfgeneratorapi](clients/forms/pdfgeneratorapi.nu)                           | openapi | <https://api.apis.guru/v2/specs/pdfgeneratorapi.com/3.1.1/openapi.json>                                                                          |
| [presalytics-converter](clients/forms/presalytics-converter.nu)               | openapi | <https://api.apis.guru/v2/specs/presalytics.io/converter/0.1/openapi.json>                                                                       |
| [presalytics-ooxml](clients/forms/presalytics-ooxml.nu)                       | openapi | <https://api.apis.guru/v2/specs/presalytics.io/ooxml/0.1.0/openapi.json>                                                                         |
| [qualtrics](clients/forms/qualtrics.nu)                                       | openapi | <https://api.apis.guru/v2/specs/qualtrics.com/0.2/openapi.json>                                                                                  |
| [rapidapi-dynamicdocs](clients/forms/rapidapi-dynamicdocs.nu)                 | openapi | <https://api.apis.guru/v2/specs/rapidapi.com/dynamicdocs/1.0/openapi.json>                                                                       |
| [scideas-perfectpdf](clients/forms/scideas-perfectpdf.nu)                     | openapi | <https://api.apis.guru/v2/specs/scideas.net/perfectpdf/1.0/openapi.json>                                                                         |
| [scideas-regression](clients/forms/scideas-regression.nu)                     | openapi | <https://api.apis.guru/v2/specs/scideas.net/regression/1.0/openapi.json>                                                                         |
| [selectpdf](clients/forms/selectpdf.nu)                                       | openapi | <https://api.apis.guru/v2/specs/selectpdf.com/1.0.0/swagger.json>                                                                                |
| [slideroom](clients/forms/slideroom.nu)                                       | openapi | <https://api.apis.guru/v2/specs/slideroom.com/v2/swagger.json>                                                                                   |
| [surveysparrow](clients/forms/surveysparrow.nu)                               | openapi | <https://api.surveysparrow.com/swagger.json>                                                                                                     |
| [tally](clients/forms/tally.nu)                                               | openapi | <https://api.tally.so/openapi.json>                                                                                                              |
| [va-gov-benefits](clients/forms/va-gov-benefits.nu)                           | openapi | <https://api.apis.guru/v2/specs/va.gov/benefits/1.0.0/openapi.yaml>                                                                              |
| [va-gov-benefits-apisguru](clients/forms/va-gov-benefits-apisguru.nu)         | openapi | <https://api.apis.guru/v2/specs/va.gov/benefits/1.0.0/openapi.json>                                                                              |
| [va-gov-confirmation](clients/forms/va-gov-confirmation.nu)                   | openapi | <https://api.apis.guru/v2/specs/va.gov/confirmation/0.0.1/openapi.yaml>                                                                          |
| [va-gov-confirmation-apisguru](clients/forms/va-gov-confirmation-apisguru.nu) | openapi | <https://api.apis.guru/v2/specs/va.gov/confirmation/0.0.1/openapi.json>                                                                          |
| [va-gov-forms](clients/forms/va-gov-forms.nu)                                 | openapi | <https://api.apis.guru/v2/specs/va.gov/forms/0.0.0/openapi.json>                                                                                 |

### fraud

| Client                                                                                | Type    | Source                                                                                                         |
| ------------------------------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------------- |
| [adyen-bin-lookup](clients/fraud/adyen-bin-lookup.nu)                                 | openapi | <https://api.apis.guru/v2/specs/adyen.com/BinLookupService/54/openapi.json>                                    |
| [authentiq](clients/fraud/authentiq.nu)                                               | openapi | <https://api.apis.guru/v2/specs/authentiq.io/1.0/openapi.json>                                                 |
| [authentiq-app](clients/fraud/authentiq-app.nu)                                       | openapi | <https://api.apis.guru/v2/specs/6-dot-authentiqio.appspot.com/6/openapi.json>                                  |
| [aws-detective](clients/fraud/aws-detective.nu)                                       | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/detective/2018-10-26/openapi.json>                               |
| [aws-fraud-detector](clients/fraud/aws-fraud-detector.nu)                             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/frauddetector/2019-11-15/openapi.json>                           |
| [aws-guardduty](clients/fraud/aws-guardduty.nu)                                       | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/guardduty/2017-11-28/openapi.json>                               |
| [aws-inspector](clients/fraud/aws-inspector.nu)                                       | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/inspector/2016-02-16/openapi.json>                               |
| [aws-macie2](clients/fraud/aws-macie2.nu)                                             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/macie2/2020-01-01/openapi.json>                                  |
| [aws-securityhub](clients/fraud/aws-securityhub.nu)                                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/securityhub/2018-10-26/openapi.json>                             |
| [aws-waf](clients/fraud/aws-waf.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/waf/2015-08-24/openapi.json>                                     |
| [aws-wafv2](clients/fraud/aws-wafv2.nu)                                               | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/wafv2/2019-07-29/openapi.json>                                   |
| [azure-advanced-threat-protection](clients/fraud/azure-advanced-threat-protection.nu) | openapi | <https://api.apis.guru/v2/specs/azure.com/security-advancedThreatProtectionSettings/2019-01-01/swagger.json>   |
| [azure-security-insights](clients/fraud/azure-security-insights.nu)                   | openapi | <https://api.apis.guru/v2/specs/azure.com/securityinsights-SecurityInsights/2020-01-01/swagger.json>           |
| [circl-hashlookup](clients/fraud/circl-hashlookup.nu)                                 | openapi | <https://api.apis.guru/v2/specs/circl.lu/hashlookup/1.2/openapi.json>                                          |
| [facecheck-id](clients/fraud/facecheck-id.nu)                                         | openapi | <https://api.apis.guru/v2/specs/facecheck.id/v1.02/openapi.json>                                               |
| [fraudlabspro-fraud-detection](clients/fraud/fraudlabspro-fraud-detection.nu)         | openapi | <https://api.apis.guru/v2/specs/fraudlabspro.com/fraud-detection/1.1/openapi.json>                             |
| [fraudlabspro-sms-verification](clients/fraud/fraudlabspro-sms-verification.nu)       | openapi | <https://api.apis.guru/v2/specs/fraudlabspro.com/sms-verification/1.0/openapi.json>                            |
| [godaddy-abuse](clients/fraud/godaddy-abuse.nu)                                       | openapi | <https://api.apis.guru/v2/specs/ote-godaddy.com/abuse/1.0.0/openapi.json>                                      |
| [google-cloud-identity](clients/fraud/google-cloud-identity.nu)                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/cloudidentity/v1beta1/openapi.json>                             |
| [google-identity-toolkit](clients/fraud/google-identity-toolkit.nu)                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/identitytoolkit/v2/openapi.json>                                |
| [google-mybusiness-verifications](clients/fraud/google-mybusiness-verifications.nu)   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/mybusinessverifications/v1/openapi.json>                        |
| [google-safe-browsing](clients/fraud/google-safe-browsing.nu)                         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/safebrowsing/v4/openapi.json>                                   |
| [google-site-verification](clients/fraud/google-site-verification.nu)                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/siteVerification/v1/openapi.json>                               |
| [google-webrisk](clients/fraud/google-webrisk.nu)                                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/webrisk/v1/openapi.json>                                        |
| [ipqualityscore](clients/fraud/ipqualityscore.nu)                                     | openapi | <https://api.apis.guru/v2/specs/ipqualityscore.com/1.0.0/openapi.json>                                         |
| [mailboxvalidator-checker](clients/fraud/mailboxvalidator-checker.nu)                 | openapi | <https://api.apis.guru/v2/specs/mailboxvalidator.com/checker/1.0.0/openapi.json>                               |
| [mailboxvalidator-disposable](clients/fraud/mailboxvalidator-disposable.nu)           | openapi | <https://api.apis.guru/v2/specs/mailboxvalidator.com/disposable/1.0.0/openapi.json>                            |
| [mailboxvalidator-validation](clients/fraud/mailboxvalidator-validation.nu)           | openapi | <https://api.apis.guru/v2/specs/mailboxvalidator.com/validation/0.1/openapi.json>                              |
| [onfido](clients/fraud/onfido.nu)                                                     | openapi | <https://raw.githubusercontent.com/onfido/onfido-openapi-spec/master/generated/artifacts/openapi/openapi.json> |
| [patrowl](clients/fraud/patrowl.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/patrowl.local/1.0.0/openapi.json>                                              |
| [probely](clients/fraud/probely.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/probely.com/1.2.0/openapi.json>                                                |
| [threatjammer](clients/fraud/threatjammer.nu)                                         | openapi | <https://api.apis.guru/v2/specs/threatjammer.com/1.2.20/openapi.json>                                          |
| [truanon](clients/fraud/truanon.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/truanon.com/1.0.0/openapi.json>                                                |
| [twilio-lookups-v1](clients/fraud/twilio-lookups-v1.nu)                               | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_lookups_v1/1.42.0/openapi.json>                              |
| [twilio-trusthub](clients/fraud/twilio-trusthub.nu)                                   | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_trusthub_v1/1.42.0/openapi.json>                             |
| [twilio-verify](clients/fraud/twilio-verify.nu)                                       | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_verify_v2/1.42.0/openapi.json>                               |
| [vonage-number-insight](clients/fraud/vonage-number-insight.nu)                       | openapi | <https://api.apis.guru/v2/specs/nexmo.com/number-insight/1.2.1/openapi.json>                                   |
| [vonage-verify](clients/fraud/vonage-verify.nu)                                       | openapi | <https://api.apis.guru/v2/specs/nexmo.com/verify/1.2.4/openapi.json>                                           |

### gaming

| Client                                                                               | Type    | Source                                                                                          |
| ------------------------------------------------------------------------------------ | ------- | ----------------------------------------------------------------------------------------------- |
| [bungie](clients/gaming/bungie.nu)                                                   | openapi | <https://raw.githubusercontent.com/Bungie-net/api/master/openapi.json>                          |
| [dodo-ac](clients/gaming/dodo-ac.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/dodo.ac/1.5.0/openapi.json>                                     |
| [evemarketer](clients/gaming/evemarketer.nu)                                         | openapi | <https://api.apis.guru/v2/specs/evemarketer.com/1.0.1/swagger.json>                             |
| [evetech](clients/gaming/evetech.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/evetech.net/0.8.6/swagger.json>                                 |
| [fortnite-skynewz-apisguru](clients/gaming/fortnite-skynewz-apisguru.nu)             | openapi | <https://api.apis.guru/v2/specs/skynewz-api-fortnite.herokuapp.com/3.1.5/swagger.json>          |
| [gamesparks-details](clients/gaming/gamesparks-details.nu)                           | openapi | <https://api.apis.guru/v2/specs/gamesparks.net/game-details/v2/openapi.json>                    |
| [google-play-games](clients/gaming/google-play-games.nu)                             | openapi | <https://api.apis.guru/v2/specs/googleapis.com/games/v1/openapi.json>                           |
| [google-play-games-configuration](clients/gaming/google-play-games-configuration.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/gamesConfiguration/v1configuration/openapi.json> |
| [google-play-games-management](clients/gaming/google-play-games-management.nu)       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/gamesManagement/v1management/openapi.json>       |
| [halo-metadata](clients/gaming/halo-metadata.nu)                                     | openapi | <https://api.apis.guru/v2/specs/haloapi.com/metadata/1.0/swagger.json>                          |
| [halo-profile](clients/gaming/halo-profile.nu)                                       | openapi | <https://api.apis.guru/v2/specs/haloapi.com/profile/1.0/swagger.json>                           |
| [halo-stats](clients/gaming/halo-stats.nu)                                           | openapi | <https://api.apis.guru/v2/specs/haloapi.com/stats/1.0/swagger.json>                             |
| [halo-ugc](clients/gaming/halo-ugc.nu)                                               | openapi | <https://api.apis.guru/v2/specs/haloapi.com/ugc/1.0/swagger.json>                               |
| [mineskin](clients/gaming/mineskin.nu)                                               | openapi | <https://api.apis.guru/v2/specs/mineskin.org/1.0.0/openapi.json>                                |
| [nba](clients/gaming/nba.nu)                                                         | openapi | <https://api.apis.guru/v2/specs/nba.com/version/swagger.json>                                   |
| [opendota](clients/gaming/opendota.nu)                                               | openapi | <https://api.opendota.com/api>                                                                  |
| [pandascore](clients/gaming/pandascore.nu)                                           | openapi | <https://api.apis.guru/v2/specs/pandascore.co/2.23.1/openapi.json>                              |
| [pokeapi](clients/gaming/pokeapi.nu)                                                 | graphql | <https://beta.pokeapi.co/graphql/v1beta>                                                        |
| [pokeapi-github](clients/gaming/pokeapi-github.nu)                                   | openapi | <https://raw.githubusercontent.com/PokeAPI/pokeapi/master/openapi.yml>                          |
| [rawg](clients/gaming/rawg.nu)                                                       | openapi | <https://api.apis.guru/v2/specs/rawg.io/v1.0/openapi.json>                                      |
| [riot](clients/gaming/riot.nu)                                                       | openapi | <https://mingweisamuel.github.io/riotapi-schema/openapi-3.0.0.json>                             |
| [roblox-users](clients/gaming/roblox-users.nu)                                       | openapi | <https://users.roblox.com/docs/json/v1>                                                         |
| [twitch-helix](clients/gaming/twitch-helix.nu)                                       | openapi | <https://raw.githubusercontent.com/DmitryScaletta/twitch-api-swagger/main/openapi.json>         |

### healthcare

| Client                                                                     | Type    | Source                                                                                            |
| -------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------- |
| [apisetu-aiimsmangalagiri](clients/healthcare/apisetu-aiimsmangalagiri.nu) | openapi | <https://api.apis.guru/v2/specs/apisetu.gov.in/aiimsmangalagiri/3.0.0/openapi.json>               |
| [apisetu-aiimspatna](clients/healthcare/apisetu-aiimspatna.nu)             | openapi | <https://api.apis.guru/v2/specs/apisetu.gov.in/aiimspatna/3.0.0/openapi.json>                     |
| [apisetu-aiimsrishikesh](clients/healthcare/apisetu-aiimsrishikesh.nu)     | openapi | <https://api.apis.guru/v2/specs/apisetu.gov.in/aiimsrishikesh/3.0.0/openapi.json>                 |
| [aws-comprehend-medical](clients/healthcare/aws-comprehend-medical.nu)     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/comprehendmedical/2018-10-30/openapi.json>          |
| [aws-healthlake](clients/healthcare/aws-healthlake.nu)                     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/healthlake/2017-07-01/openapi.json>                 |
| [azure-healthcare-apis](clients/healthcare/azure-healthcare-apis.nu)       | openapi | <https://api.apis.guru/v2/specs/azure.com/healthcareapis-healthcare-apis/2019-09-16/swagger.json> |
| [cdc-prime-data-hub](clients/healthcare/cdc-prime-data-hub.nu)             | openapi | <https://api.apis.guru/v2/specs/cdcgov.local/prime-data-hub/0.2.0-oas3/openapi.json>              |
| [climatekuul](clients/healthcare/climatekuul.nu)                           | openapi | <https://api.apis.guru/v2/specs/climatekuul.com/1.0/openapi.json>                                 |
| [covid19-api](clients/healthcare/covid19-api.nu)                           | openapi | <https://api.apis.guru/v2/specs/covid19-api.com/1.2.6/openapi.json>                               |
| [crediwatch-covid19](clients/healthcare/crediwatch-covid19.nu)             | openapi | <https://api.apis.guru/v2/specs/crediwatch.com/covid19/1.3.0/openapi.json>                        |
| [drchrono](clients/healthcare/drchrono.nu)                                 | openapi | <https://api.apis.guru/v2/specs/drchrono.com/v4%20%28Hunt%20Valley%29/openapi.json>               |
| [google-fitness](clients/healthcare/google-fitness.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/fitness/v1/openapi.json>                           |
| [google-genomics](clients/healthcare/google-genomics.nu)                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/genomics/v2alpha1/openapi.json>                    |
| [google-healthcare](clients/healthcare/google-healthcare.nu)               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/healthcare/v1beta1/openapi.json>                   |
| [google-lifesciences](clients/healthcare/google-lifesciences.nu)           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/lifesciences/v2beta/openapi.json>                  |
| [healthcare-gov](clients/healthcare/healthcare-gov.nu)                     | openapi | <https://api.apis.guru/v2/specs/healthcare.gov/1.0.0/openapi.json>                                |
| [hhs-gov](clients/healthcare/hhs-gov.nu)                                   | openapi | <https://api.apis.guru/v2/specs/hhs.gov/2/openapi.json>                                           |
| [infermedica](clients/healthcare/infermedica.nu)                           | openapi | <https://api.apis.guru/v2/specs/infermedica.com/v2/swagger.json>                                  |
| [mcw-edu](clients/healthcare/mcw-edu.nu)                                   | openapi | <https://api.apis.guru/v2/specs/mcw.edu/1.1/openapi.json>                                         |
| [medcorder](clients/healthcare/medcorder.nu)                               | openapi | <https://api.apis.guru/v2/specs/medcorder.com/1.0.0/swagger.json>                                 |
| [ndhm-healthid](clients/healthcare/ndhm-healthid.nu)                       | openapi | <https://api.apis.guru/v2/specs/ndhm.gov.in/ndhm-healthid/1.0/openapi.json>                       |
| [opentrials](clients/healthcare/opentrials.nu)                             | openapi | <https://api.apis.guru/v2/specs/opentrials.local/0.0.1/swagger.json>                              |
| [orthanc](clients/healthcare/orthanc.nu)                                   | openapi | <https://api.apis.guru/v2/specs/orthanc-server.com/1.11.3/openapi.json>                           |
| [patientview](clients/healthcare/patientview.nu)                           | openapi | <https://api.apis.guru/v2/specs/patientview.org/1.0/openapi.json>                                 |
| [slicebox](clients/healthcare/slicebox.nu)                                 | openapi | <https://api.apis.guru/v2/specs/slicebox.local/2.0/swagger.json>                                  |
| [twine-health](clients/healthcare/twine-health.nu)                         | openapi | <https://api.apis.guru/v2/specs/twinehealth.com/v7.78.1/openapi.json>                             |

### identity

| Client                                                                             | Type    | Source                                                                                                                           |
| ---------------------------------------------------------------------------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------- |
| [1password-connect-spec](clients/identity/1password-connect-spec.nu)               | openapi | <https://api.apis.guru/v2/specs/1password.local/connect/1.5.7/openapi.json>                                                      |
| [auth0](clients/identity/auth0.nu)                                                 | openapi | <https://auth0.com/docs/api/management/openapi.json>                                                                             |
| [authentik](clients/identity/authentik.nu)                                         | openapi | <https://raw.githubusercontent.com/goauthentik/authentik/main/schema.yml>                                                        |
| [aws-clouddirectory](clients/identity/aws-clouddirectory.nu)                       | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/clouddirectory/2017-01-11/openapi.json>                                            |
| [aws-cognito-identity](clients/identity/aws-cognito-identity.nu)                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/cognito-identity/2014-06-30/openapi.json>                                          |
| [aws-cognito-idp](clients/identity/aws-cognito-idp.nu)                             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/cognito-idp/2016-04-18/openapi.json>                                               |
| [aws-iam](clients/identity/aws-iam.nu)                                             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/iam/2010-05-08/openapi.json>                                                       |
| [aws-identitystore](clients/identity/aws-identitystore.nu)                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/identitystore/2020-06-15/openapi.json>                                             |
| [aws-secretsmanager](clients/identity/aws-secretsmanager.nu)                       | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/secretsmanager/2017-10-17/openapi.json>                                            |
| [aws-ssm](clients/identity/aws-ssm.nu)                                             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/ssm/2014-11-06/openapi.json>                                                       |
| [aws-sso](clients/identity/aws-sso.nu)                                             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/sso/2019-06-10/openapi.json>                                                       |
| [aws-sso-admin](clients/identity/aws-sso-admin.nu)                                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/sso-admin/2020-07-20/openapi.json>                                                 |
| [aws-sso-oidc](clients/identity/aws-sso-oidc.nu)                                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/sso-oidc/2019-06-10/openapi.json>                                                  |
| [azure-activedirectory](clients/identity/azure-activedirectory.nu)                 | openapi | <https://api.apis.guru/v2/specs/azure.com/azureactivedirectory/2017-04-01/swagger.json>                                          |
| [azure-graphrbac](clients/identity/azure-graphrbac.nu)                             | openapi | <https://api.apis.guru/v2/specs/windows.net/graphrbac/1.6/openapi.json>                                                          |
| [casdoor](clients/identity/casdoor.nu)                                             | openapi | <https://raw.githubusercontent.com/casdoor/casdoor/master/swagger/swagger.json>                                                  |
| [citrixonline-scim](clients/identity/citrixonline-scim.nu)                         | openapi | <https://api.apis.guru/v2/specs/citrixonline.com/scim/NA/swagger.json>                                                           |
| [clerk-backend](clients/identity/clerk-backend.nu)                                 | openapi | <https://raw.githubusercontent.com/clerk/openapi-specs/main/bapi/2026-05-12.yml>                                                 |
| [clerk-frontend](clients/identity/clerk-frontend.nu)                               | openapi | <https://raw.githubusercontent.com/clerk/openapi-specs/main/fapi/2026-05-12.yml>                                                 |
| [digitallocker-authpartner](clients/identity/digitallocker-authpartner.nu)         | openapi | <https://api.apis.guru/v2/specs/digitallocker.gov.in/authpartner/1.0.0/openapi.json>                                             |
| [fusionauth](clients/identity/fusionauth.nu)                                       | openapi | <https://raw.githubusercontent.com/FusionAuth/fusionauth-openapi/main/openapi.yaml>                                              |
| [godaddy-ote-shoppers](clients/identity/godaddy-ote-shoppers.nu)                   | openapi | <https://api.apis.guru/v2/specs/ote-godaddy.com/shoppers/1.0.0/openapi.json>                                                     |
| [google-accessapproval](clients/identity/google-accessapproval.nu)                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/accessapproval/v1/openapi.json>                                                   |
| [google-accesscontextmanager](clients/identity/google-accesscontextmanager.nu)     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/accesscontextmanager/v1beta/openapi.json>                                         |
| [google-admin-directory](clients/identity/google-admin-directory.nu)               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/admin/directory_v1/openapi.json>                                                  |
| [google-certificatemanager](clients/identity/google-certificatemanager.nu)         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/certificatemanager/v1/openapi.json>                                               |
| [google-cloudkms](clients/identity/google-cloudkms.nu)                             | openapi | <https://api.apis.guru/v2/specs/googleapis.com/cloudkms/v1/openapi.json>                                                         |
| [google-firebase-app-check](clients/identity/google-firebase-app-check.nu)         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/firebaseappcheck/v1/openapi.json>                                                 |
| [google-iam](clients/identity/google-iam.nu)                                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/iam/v2/openapi.json>                                                              |
| [google-iamcredentials](clients/identity/google-iamcredentials.nu)                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/iamcredentials/v1/openapi.json>                                                   |
| [google-iap](clients/identity/google-iap.nu)                                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/iap/v1beta1/openapi.json>                                                         |
| [google-kmsinventory](clients/identity/google-kmsinventory.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/kmsinventory/v1/openapi.json>                                                     |
| [google-oauth2](clients/identity/google-oauth2.nu)                                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/oauth2/v2/openapi.json>                                                           |
| [google-play-integrity](clients/identity/google-play-integrity.nu)                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/playintegrity/v1/openapi.json>                                                    |
| [google-privateca](clients/identity/google-privateca.nu)                           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/privateca/v1beta1/openapi.json>                                                   |
| [google-websecurityscanner](clients/identity/google-websecurityscanner.nu)         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/websecurityscanner/v1beta/openapi.json>                                           |
| [idtbeyond](clients/identity/idtbeyond.nu)                                         | openapi | <https://api.apis.guru/v2/specs/idtbeyond.com/1.1.7/swagger.json>                                                                |
| [jumpcloud-v1](clients/identity/jumpcloud-v1.nu)                                   | openapi | <https://docs.jumpcloud.com/api/1.0/index.yaml>                                                                                  |
| [jumpcloud-v2](clients/identity/jumpcloud-v2.nu)                                   | openapi | <https://docs.jumpcloud.com/api/2.0/index.yaml>                                                                                  |
| [keycloak](clients/identity/keycloak.nu)                                           | openapi | <https://api.apis.guru/v2/specs/keycloak.local/1/openapi.json>                                                                   |
| [keyserv](clients/identity/keyserv.nu)                                             | openapi | <https://api.apis.guru/v2/specs/keyserv.solutions/1.4.5/openapi.json>                                                            |
| [linuxfoundation-reimbursement](clients/identity/linuxfoundation-reimbursement.nu) | openapi | <https://api.apis.guru/v2/specs/linuxfoundation.org/reimbursement/1.0/swagger.json>                                              |
| [n-auth](clients/identity/n-auth.nu)                                               | openapi | <https://api.apis.guru/v2/specs/n-auth.com/2.2/swagger.json>                                                                     |
| [netlicensing](clients/identity/netlicensing.nu)                                   | openapi | <https://api.apis.guru/v2/specs/netlicensing.io/2.x/openapi.json>                                                                |
| [npr-identity](clients/identity/npr-identity.nu)                                   | openapi | <https://api.apis.guru/v2/specs/npr.org/identity/2/swagger.json>                                                                 |
| [okta](clients/identity/okta.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/okta.local/1.0.0/openapi.json>                                                                   |
| [onepassword-connect](clients/identity/onepassword-connect.nu)                     | openapi | <https://raw.githubusercontent.com/1Password/connect/main/docs/openapi/spec.yaml>                                                |
| [onepassword-events-api](clients/identity/onepassword-events-api.nu)               | openapi | <https://api.apis.guru/v2/specs/1password.com/events/1.0.0/openapi.json>                                                         |
| [ory-hydra](clients/identity/ory-hydra.nu)                                         | openapi | <https://raw.githubusercontent.com/ory/hydra/master/spec/api.json>                                                               |
| [ory-keto](clients/identity/ory-keto.nu)                                           | openapi | <https://raw.githubusercontent.com/ory/keto/master/spec/api.json>                                                                |
| [ory-kratos](clients/identity/ory-kratos.nu)                                       | openapi | <https://raw.githubusercontent.com/ory/kratos/master/spec/api.json>                                                              |
| [ory-oathkeeper](clients/identity/ory-oathkeeper.nu)                               | openapi | <https://raw.githubusercontent.com/ory/oathkeeper/master/spec/api.json>                                                          |
| [passwordutility](clients/identity/passwordutility.nu)                             | openapi | <https://api.apis.guru/v2/specs/passwordutility.net/v1/swagger.json>                                                             |
| [personio-authentication](clients/identity/personio-authentication.nu)             | openapi | <https://api.apis.guru/v2/specs/personio.de/authentication/1.0/openapi.json>                                                     |
| [phantauth](clients/identity/phantauth.nu)                                         | openapi | <https://api.apis.guru/v2/specs/phantauth.net/1.0.0/openapi.json>                                                                |
| [pingone](clients/identity/pingone.nu)                                             | openapi | <https://raw.githubusercontent.com/pingidentity/pingone-openapi-specifications/main/specification/3.1/api/combined/openapi.yaml> |
| [stytch](clients/identity/stytch.nu)                                               | openapi | <https://raw.githubusercontent.com/stytchauth/stytch-openapi/main/openapi.yml>                                                   |
| [tokenjay](clients/identity/tokenjay.nu)                                           | openapi | <https://api.apis.guru/v2/specs/tokenjay.app/1.0.0/openapi.json>                                                                 |
| [twilio-oauth](clients/identity/twilio-oauth.nu)                                   | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_oauth_v1/1.42.0/openapi.json>                                                  |
| [workos](clients/identity/workos.nu)                                               | openapi | <https://raw.githubusercontent.com/workos/openapi-spec/main/spec/open-api-spec.yaml>                                             |
| [wso2-transform](clients/identity/wso2-transform.nu)                               | openapi | <https://api.apis.guru/v2/specs/wso2apistore.com/transform/1.0.0/openapi.json>                                                   |
| [xero-identity](clients/identity/xero-identity.nu)                                 | openapi | <https://api.apis.guru/v2/specs/xero.com/xero-identity/2.9.4/openapi.json>                                                       |

### incident

| Client                                                       | Type    | Source                                                                                                         |
| ------------------------------------------------------------ | ------- | -------------------------------------------------------------------------------------------------------------- |
| [aws-ssm-contacts](clients/incident/aws-ssm-contacts.nu)     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/ssm-contacts/2021-05-03/openapi.json>                            |
| [aws-ssm-incidents](clients/incident/aws-ssm-incidents.nu)   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/ssm-incidents/2018-05-10/openapi.json>                           |
| [better-stack](clients/incident/better-stack.nu)             | openapi | <https://raw.githubusercontent.com/api-evangelist/better-stack/main/openapi/better-stack-openapi.yml>          |
| [firehydrant](clients/incident/firehydrant.nu)               | openapi | <https://raw.githubusercontent.com/firehydrant/firehydrant-go-sdk/main/openapi.yaml>                           |
| [ilert](clients/incident/ilert.nu)                           | openapi | <https://api.ilert.com/api-docs/openapi.json>                                                                  |
| [incident-io](clients/incident/incident-io.nu)               | openapi | <https://docs.incident.io/openapi/latest.json>                                                                 |
| [instatus](clients/incident/instatus.nu)                     | openapi | <https://raw.githubusercontent.com/instatushq/openapi/main/instatus.yaml>                                      |
| [opsgenie](clients/incident/opsgenie.nu)                     | openapi | <https://raw.githubusercontent.com/opsgenie/opsgenie-oas/master/swagger.json>                                  |
| [pagerduty](clients/incident/pagerduty.nu)                   | openapi | <https://raw.githubusercontent.com/PagerDuty/api-schema/main/reference/REST/openapiv3.json>                    |
| [rootly](clients/incident/rootly.nu)                         | openapi | <https://raw.githubusercontent.com/Rootly-AI-Labs/Rootly-MCP-server/main/rootly_openapi.json>                  |
| [statuspage](clients/incident/statuspage.nu)                 | openapi | <https://raw.githubusercontent.com/sbecker59/statuspage-api-client-go/main/api/v1/statuspage/api/openapi.yaml> |
| [uptime-com](clients/incident/uptime-com.nu)                 | openapi | <https://uptime.com/api/v1/openapi/>                                                                           |
| [victorops-apisguru](clients/incident/victorops-apisguru.nu) | openapi | <https://api.apis.guru/v2/specs/victorops.com/0.0.3/swagger.json>                                              |
| [zenduty](clients/incident/zenduty.nu)                       | openapi | <https://apidocs.zenduty.com/openapi.json>                                                                     |

### iot

| Client                                                                      | Type    | Source                                                                                               |
| --------------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------------- |
| [aws-greengrass](clients/iot/aws-greengrass.nu)                             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/greengrass/2017-06-07/openapi.json>                    |
| [aws-greengrass-v2](clients/iot/aws-greengrass-v2.nu)                       | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/greengrassv2/2020-11-30/openapi.json>                  |
| [aws-iot](clients/iot/aws-iot.nu)                                           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/iot/2015-05-28/openapi.json>                           |
| [aws-iot-1click-devices](clients/iot/aws-iot-1click-devices.nu)             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/iot1click-devices/2018-05-14/openapi.json>             |
| [aws-iot-1click-projects](clients/iot/aws-iot-1click-projects.nu)           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/iot1click-projects/2018-05-14/openapi.json>            |
| [aws-iot-analytics](clients/iot/aws-iot-analytics.nu)                       | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/iotanalytics/2017-11-27/openapi.json>                  |
| [aws-iot-data](clients/iot/aws-iot-data.nu)                                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/iot-data/2015-05-28/openapi.json>                      |
| [aws-iot-device-advisor](clients/iot/aws-iot-device-advisor.nu)             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/iotdeviceadvisor/2020-09-18/openapi.json>              |
| [aws-iot-events](clients/iot/aws-iot-events.nu)                             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/iotevents/2018-07-27/openapi.json>                     |
| [aws-iot-events-data](clients/iot/aws-iot-events-data.nu)                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/iotevents-data/2018-10-23/openapi.json>                |
| [aws-iot-fleethub](clients/iot/aws-iot-fleethub.nu)                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/iotfleethub/2020-11-03/openapi.json>                   |
| [aws-iot-jobs-data](clients/iot/aws-iot-jobs-data.nu)                       | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/iot-jobs-data/2017-09-29/openapi.json>                 |
| [aws-iot-secure-tunneling](clients/iot/aws-iot-secure-tunneling.nu)         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/iotsecuretunneling/2018-10-05/openapi.json>            |
| [aws-iot-sitewise](clients/iot/aws-iot-sitewise.nu)                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/iotsitewise/2019-12-02/openapi.json>                   |
| [aws-iot-things-graph](clients/iot/aws-iot-things-graph.nu)                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/iotthingsgraph/2018-09-06/openapi.json>                |
| [aws-iot-wireless](clients/iot/aws-iot-wireless.nu)                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/iotwireless/2020-11-22/openapi.json>                   |
| [azure-databox-edge](clients/iot/azure-databox-edge.nu)                     | openapi | <https://api.apis.guru/v2/specs/azure.com/databoxedge/2019-07-01/swagger.json>                       |
| [azure-iot-central](clients/iot/azure-iot-central.nu)                       | openapi | <https://api.apis.guru/v2/specs/azure.com/iotcentral/2018-09-01/swagger.json>                        |
| [azure-iot-dps](clients/iot/azure-iot-dps.nu)                               | openapi | <https://api.apis.guru/v2/specs/azure.com/deviceprovisioningservices-iotdps/2018-01-22/swagger.json> |
| [azure-iot-hub](clients/iot/azure-iot-hub.nu)                               | openapi | <https://api.apis.guru/v2/specs/azure.com/iothub/2019-07-01-preview/swagger.json>                    |
| [azure-windows-iot-services](clients/iot/azure-windows-iot-services.nu)     | openapi | <https://api.apis.guru/v2/specs/azure.com/windowsiot-WindowsIotServices/2019-06-01/swagger.json>     |
| [clarify](clients/iot/clarify.nu)                                           | openapi | <https://api.apis.guru/v2/specs/clarify.io/1.3.7/swagger.json>                                       |
| [dweet-io](clients/iot/dweet-io.nu)                                         | openapi | <https://api.apis.guru/v2/specs/dweet.io/2.0/swagger.json>                                           |
| [edrv](clients/iot/edrv.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/edrv.io/v1/openapi.json>                                             |
| [enode](clients/iot/enode.nu)                                               | openapi | <https://api.apis.guru/v2/specs/enode.io/1.3.10/openapi.json>                                        |
| [firmalyzer-iotvas](clients/iot/firmalyzer-iotvas.nu)                       | openapi | <https://api.apis.guru/v2/specs/firmalyzer.com/iotvas/1.0/openapi.json>                              |
| [gambitcomm-mimic](clients/iot/gambitcomm-mimic.nu)                         | openapi | <https://api.apis.guru/v2/specs/gambitcomm.local/mimic/21.00/openapi.json>                           |
| [google-cloud-iot](clients/iot/google-cloud-iot.nu)                         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/cloudiot/v1/openapi.json>                             |
| [google-homegraph](clients/iot/google-homegraph.nu)                         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/homegraph/v1/openapi.json>                            |
| [google-smartdevicemanagement](clients/iot/google-smartdevicemanagement.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/smartdevicemanagement/v1/openapi.json>                |
| [hillbillysoftware-shinobi](clients/iot/hillbillysoftware-shinobi.nu)       | openapi | <https://api.apis.guru/v2/specs/hillbillysoftware.com/shinobi/v1/swagger.json>                       |
| [id4i](clients/iot/id4i.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/id4i.de/1.0.2/openapi.json>                                          |
| [ijenko](clients/iot/ijenko.nu)                                             | openapi | <https://api.apis.guru/v2/specs/ijenko.net/3.0.0/swagger.json>                                       |
| [intel-product-catalogue](clients/iot/intel-product-catalogue.nu)           | openapi | <https://api.apis.guru/v2/specs/intel.com/product-catalogue/0.1.0/swagger.json>                      |
| [intellifi](clients/iot/intellifi.nu)                                       | openapi | <https://api.apis.guru/v2/specs/intellifi.nl/2.23.2+0.gfbc3926.dirty/openapi.json>                   |
| [mbus](clients/iot/mbus.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/mbus.local/0.3.5/openapi.json>                                       |
| [meraki](clients/iot/meraki.nu)                                             | openapi | <https://api.apis.guru/v2/specs/meraki.com/v1.31.0/openapi.json>                                     |
| [meraki-apisguru](clients/iot/meraki-apisguru.nu)                           | openapi | <https://api.apis.guru/v2/specs/meraki.com/0.0.0-streaming/openapi.json>                             |
| [mist](clients/iot/mist.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/mist.com/0.36.1/openapi.json>                                        |
| [netbox](clients/iot/netbox.nu)                                             | openapi | <https://api.apis.guru/v2/specs/netbox.dev/3.4/openapi.json>                                         |
| [netboxdemo](clients/iot/netboxdemo.nu)                                     | openapi | <https://api.apis.guru/v2/specs/netboxdemo.com/2.8/openapi.json>                                     |
| [opto22-groov](clients/iot/opto22-groov.nu)                                 | openapi | <https://api.apis.guru/v2/specs/opto22.com/groov/R4.2a/swagger.json>                                 |
| [opto22-pac](clients/iot/opto22-pac.nu)                                     | openapi | <https://api.apis.guru/v2/specs/opto22.com/pac/R1.0a/swagger.json>                                   |
| [osisoft](clients/iot/osisoft.nu)                                           | openapi | <https://api.apis.guru/v2/specs/osisoft.com/1.11.1.5383/swagger.json>                                |
| [shotstack](clients/iot/shotstack.nu)                                       | openapi | <https://api.apis.guru/v2/specs/shotstack.io/v1/openapi.json>                                        |
| [smart-me](clients/iot/smart-me.nu)                                         | openapi | <https://api.apis.guru/v2/specs/smart-me.com/v1/openapi.json>                                        |
| [telematicssdk](clients/iot/telematicssdk.nu)                               | openapi | <https://api.apis.guru/v2/specs/telematicssdk.com/1.0.0/openapi.json>                                |
| [waterlinked](clients/iot/waterlinked.nu)                                   | openapi | <https://api.apis.guru/v2/specs/waterlinked.com/1.0.0/swagger.json>                                  |

### issue-tracking

| Client                                                                         | Type    | Source                                                                                                               |
| ------------------------------------------------------------------------------ | ------- | -------------------------------------------------------------------------------------------------------------------- |
| [apideck-customer-support](clients/issue-tracking/apideck-customer-support.nu) | openapi | <https://api.apis.guru/v2/specs/apideck.com/customer-support/9.3.0/openapi.json>                                     |
| [azure-devops](clients/issue-tracking/azure-devops.nu)                         | openapi | <https://api.apis.guru/v2/specs/azure.com/devops/2019-07-01-preview/swagger.json>                                    |
| [clickup](clients/issue-tracking/clickup.nu)                                   | openapi | <https://api.apis.guru/v2/specs/clickup.com/1.0.0/openapi.json>                                                      |
| [front](clients/issue-tracking/front.nu)                                       | openapi | <https://raw.githubusercontent.com/frontapp/front-api-specs/main/core-api/core-api.json>                             |
| [github-rest](clients/issue-tracking/github-rest.nu)                           | openapi | <https://raw.githubusercontent.com/github/rest-api-description/main/descriptions/api.github.com/api.github.com.json> |
| [jira](clients/issue-tracking/jira.nu)                                         | openapi | <https://developer.atlassian.com/cloud/jira/platform/swagger-v3.v3.json>                                             |
| [jira-atlassian](clients/issue-tracking/jira-atlassian.nu)                     | openapi | <https://api.apis.guru/v2/specs/atlassian.com/jira/1001.0.0-SNAPSHOT/openapi.json>                                   |
| [jira-service-desk](clients/issue-tracking/jira-service-desk.nu)               | openapi | <https://developer.atlassian.com/cloud/jira/service-desk/swagger.v3.json>                                            |
| [jira-software](clients/issue-tracking/jira-software.nu)                       | openapi | <https://developer.atlassian.com/cloud/jira/software/swagger.v3.json>                                                |
| [jirafe-apisguru](clients/issue-tracking/jirafe-apisguru.nu)                   | openapi | <https://api.apis.guru/v2/specs/jirafe.com/2.0.0/swagger.json>                                                       |
| [lgtm](clients/issue-tracking/lgtm.nu)                                         | openapi | <https://api.apis.guru/v2/specs/lgtm.com/v1.0/openapi.json>                                                          |
| [mantis](clients/issue-tracking/mantis.nu)                                     | openapi | <https://raw.githubusercontent.com/mantisbt/mantisbt/master/api/rest/swagger.json>                                   |
| [redmine](clients/issue-tracking/redmine.nu)                                   | openapi | <https://raw.githubusercontent.com/d-yoshi/redmine-openapi/main/openapi.yaml>                                        |
| [tuleap](clients/issue-tracking/tuleap.nu)                                     | openapi | <https://tuleap.net/api/explorer/swagger.json>                                                                       |
| [zendesk](clients/issue-tracking/zendesk.nu)                                   | openapi | <https://developer.zendesk.com/zendesk/oas.yaml>                                                                     |

### maps

| Client                                                                         | Type    | Source                                                                                                                 |
| ------------------------------------------------------------------------------ | ------- | ---------------------------------------------------------------------------------------------------------------------- |
| [abstract-geolocation](clients/maps/abstract-geolocation.nu)                   | openapi | <https://api.apis.guru/v2/specs/abstractapi.com/geolocation/1.0.0/openapi.json>                                        |
| [aws-location](clients/maps/aws-location.nu)                                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/location/2020-11-19/openapi.json>                                        |
| [bc-geocoder](clients/maps/bc-geocoder.nu)                                     | openapi | <https://api.apis.guru/v2/specs/gov.bc.ca/geocoder/2.0.0/openapi.json>                                                 |
| [bigdatacloud](clients/maps/bigdatacloud.nu)                                   | openapi | <https://api.apis.guru/v2/specs/bigdatacloud.net/1.0.0/openapi.json>                                                   |
| [geoapify-address-autocomplete](clients/maps/geoapify-address-autocomplete.nu) | openapi | <https://raw.githubusercontent.com/geoapify/geoapify-openapi-specs/main/api-specs/geocoding/address_autocomplete.yaml> |
| [geoapify-forward-geocoding](clients/maps/geoapify-forward-geocoding.nu)       | openapi | <https://raw.githubusercontent.com/geoapify/geoapify-openapi-specs/main/api-specs/geocoding/forward_geocoding.yaml>    |
| [geoapify-isoline](clients/maps/geoapify-isoline.nu)                           | openapi | <https://raw.githubusercontent.com/geoapify/geoapify-openapi-specs/main/api-specs/isoline/isoline.yaml>                |
| [geoapify-places](clients/maps/geoapify-places.nu)                             | openapi | <https://raw.githubusercontent.com/geoapify/geoapify-openapi-specs/main/api-specs/places/places.yaml>                  |
| [geoapify-reverse-geocoding](clients/maps/geoapify-reverse-geocoding.nu)       | openapi | <https://raw.githubusercontent.com/geoapify/geoapify-openapi-specs/main/api-specs/geocoding/reverse_geocoding.yaml>    |
| [geoapify-routing](clients/maps/geoapify-routing.nu)                           | openapi | <https://raw.githubusercontent.com/geoapify/geoapify-openapi-specs/main/api-specs/routing/routing.yaml>                |
| [geodatasource](clients/maps/geodatasource.nu)                                 | openapi | <https://api.apis.guru/v2/specs/geodatasource.com/1.0/openapi.json>                                                    |
| [geodb](clients/maps/geodb.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/mashape.com/geodb/1.0.0/swagger.json>                                                  |
| [geode-systems](clients/maps/geode-systems.nu)                                 | openapi | <https://api.apis.guru/v2/specs/geodesystems.com/1.0.0/openapi.json>                                                   |
| [getthedata-bng2latlong](clients/maps/getthedata-bng2latlong.nu)               | openapi | <https://api.apis.guru/v2/specs/getthedata.com/bng2latlong/1.0/openapi.json>                                           |
| [gisgraphy](clients/maps/gisgraphy.nu)                                         | openapi | <https://api.apis.guru/v2/specs/gisgraphy.com/4.0.0/swagger.json>                                                      |
| [google-playable-locations](clients/maps/google-playable-locations.nu)         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/playablelocations/v3/openapi.json>                                      |
| [google-vectortile](clients/maps/google-vectortile.nu)                         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/vectortile/v1/openapi.json>                                             |
| [graphhopper](clients/maps/graphhopper.nu)                                     | openapi | <https://api.apis.guru/v2/specs/graphhopper.com/1.0.0/openapi.json>                                                    |
| [here-positioning](clients/maps/here-positioning.nu)                           | openapi | <https://api.apis.guru/v2/specs/here.com/positioning/2.1.1/openapi.json>                                               |
| [here-tracking-apisguru](clients/maps/here-tracking-apisguru.nu)               | openapi | <https://api.apis.guru/v2/specs/here.com/tracking/2.1.191/openapi.json>                                                |
| [ideal-postcodes-apisguru](clients/maps/ideal-postcodes-apisguru.nu)           | openapi | <https://api.apis.guru/v2/specs/ideal-postcodes.co.uk/3.7.0/openapi.json>                                              |
| [interzoid-getaddressmatch](clients/maps/interzoid-getaddressmatch.nu)         | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getaddressmatch/1.0.0/openapi.json>                                      |
| [interzoid-getareacode](clients/maps/interzoid-getareacode.nu)                 | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getareacodefromnumber/1.0.0/openapi.json>                                |
| [interzoid-getcitymatch](clients/maps/interzoid-getcitymatch.nu)               | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getcitymatch/1.0.0/openapi.json>                                         |
| [interzoid-getcountrymatch](clients/maps/interzoid-getcountrymatch.nu)         | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getcountrymatch/1.0.0/openapi.json>                                      |
| [interzoid-zipinfo](clients/maps/interzoid-zipinfo.nu)                         | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getzipinfo/1.0.0/openapi.json>                                           |
| [ip2location-io](clients/maps/ip2location-io.nu)                               | openapi | <https://api.apis.guru/v2/specs/ip2location.io/1.0/openapi.json>                                                       |
| [lotadata](clients/maps/lotadata.nu)                                           | openapi | <https://api.apis.guru/v2/specs/lotadata.com/2.0.0/swagger.json>                                                       |
| [miataru](clients/maps/miataru.nu)                                             | openapi | <https://api.apis.guru/v2/specs/miataru.com/1.0.0/swagger.json>                                                        |
| [opencagedata](clients/maps/opencagedata.nu)                                   | openapi | <https://api.apis.guru/v2/specs/opencagedata.com/1/swagger.json>                                                       |
| [rapidapi-idealspot](clients/maps/rapidapi-idealspot.nu)                       | openapi | <https://api.apis.guru/v2/specs/rapidapi.com/idealspot-geodata/1.0/openapi.json>                                       |
| [stadia-maps](clients/maps/stadia-maps.nu)                                     | openapi | <https://api.stadiamaps.com/openapi.yaml>                                                                              |
| [tomtom-maps](clients/maps/tomtom-maps.nu)                                     | openapi | <https://api.apis.guru/v2/specs/tomtom.com/maps/1.0.0/openapi.json>                                                    |
| [tomtom-routing](clients/maps/tomtom-routing.nu)                               | openapi | <https://api.apis.guru/v2/specs/tomtom.com/routing/1.0.0/openapi.json>                                                 |
| [tomtom-search](clients/maps/tomtom-search.nu)                                 | openapi | <https://api.apis.guru/v2/specs/tomtom.com/search/1.0.0/openapi.json>                                                  |
| [traccar](clients/maps/traccar.nu)                                             | openapi | <https://api.apis.guru/v2/specs/traccar.org/5.6/openapi.json>                                                          |
| [transitfeeds](clients/maps/transitfeeds.nu)                                   | openapi | <https://api.apis.guru/v2/specs/transitfeeds.com/1.0.0/swagger.json>                                                   |
| [trapstreet](clients/maps/trapstreet.nu)                                       | openapi | <https://api.apis.guru/v2/specs/trapstreet.com/1.0.0/openapi.json>                                                     |
| [uebermaps](clients/maps/uebermaps.nu)                                         | openapi | <https://api.apis.guru/v2/specs/uebermaps.com/2.0/swagger.json>                                                        |

### marketing

| Client                                                                                                | Type    | Source                                                                                                       |
| ----------------------------------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------ |
| [apideck-sms](clients/marketing/apideck-sms.nu)                                                       | openapi | <https://api.apis.guru/v2/specs/apideck.com/sms/9.3.0/openapi.json>                                          |
| [aws-customer-profiles](clients/marketing/aws-customer-profiles.nu)                                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/customer-profiles/2020-08-15/openapi.json>                     |
| [aws-pinpoint](clients/marketing/aws-pinpoint.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/pinpoint/2016-12-01/openapi.json>                              |
| [aws-pinpoint-email](clients/marketing/aws-pinpoint-email.nu)                                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/pinpoint-email/2018-07-26/openapi.json>                        |
| [aws-pinpoint-sms-voice](clients/marketing/aws-pinpoint-sms-voice.nu)                                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/sms-voice/2018-09-05/openapi.json>                             |
| [azure-customer-insights](clients/marketing/azure-customer-insights.nu)                               | openapi | <https://api.apis.guru/v2/specs/azure.com/customer-insights/2017-04-26/swagger.json>                         |
| [azure-engagement-fabric](clients/marketing/azure-engagement-fabric.nu)                               | openapi | <https://api.apis.guru/v2/specs/azure.com/engagementfabric-EngagementFabric/2018-09-01-preview/swagger.json> |
| [azure-mobile-engagement](clients/marketing/azure-mobile-engagement.nu)                               | openapi | <https://api.apis.guru/v2/specs/azure.com/mobileengagement-mobile-engagement/2014-12-01/swagger.json>        |
| [azure-notification-hubs](clients/marketing/azure-notification-hubs.nu)                               | openapi | <https://api.apis.guru/v2/specs/azure.com/notificationhubs/2017-04-01/swagger.json>                          |
| [braze](clients/marketing/braze.nu)                                                                   | openapi | <https://api.apis.guru/v2/specs/braze.com/1.0.0/openapi.json>                                                |
| [buffer](clients/marketing/buffer.nu)                                                                 | openapi | <https://api.apis.guru/v2/specs/bufferapp.com/1/swagger.json>                                                |
| [ebay-buy-marketing](clients/marketing/ebay-buy-marketing.nu)                                         | openapi | <https://api.apis.guru/v2/specs/ebay.com/buy-marketing/v1_beta.2.0/openapi.json>                             |
| [ebay-sell-marketing](clients/marketing/ebay-sell-marketing.nu)                                       | openapi | <https://api.apis.guru/v2/specs/ebay.com/sell-marketing/v1.14.0/openapi.json>                                |
| [google-authorizedbuyersmarketplace](clients/marketing/google-authorizedbuyersmarketplace.nu)         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/authorizedbuyersmarketplace/v1/openapi.json>                  |
| [google-business-profile-performance](clients/marketing/google-business-profile-performance.nu)       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/businessprofileperformance/v1/openapi.json>                   |
| [google-mybusiness-account-management](clients/marketing/google-mybusiness-account-management.nu)     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/mybusinessaccountmanagement/v1/openapi.json>                  |
| [google-mybusiness-business-information](clients/marketing/google-mybusiness-business-information.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/mybusinessbusinessinformation/v1/openapi.json>                |
| [google-mybusiness-lodging](clients/marketing/google-mybusiness-lodging.nu)                           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/mybusinesslodging/v1/openapi.json>                            |
| [google-mybusiness-notifications](clients/marketing/google-mybusiness-notifications.nu)               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/mybusinessnotifications/v1/openapi.json>                      |
| [google-mybusiness-place-actions](clients/marketing/google-mybusiness-place-actions.nu)               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/mybusinessplaceactions/v1/openapi.json>                       |
| [google-mybusiness-qanda](clients/marketing/google-mybusiness-qanda.nu)                               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/mybusinessqanda/v1/openapi.json>                              |
| [google-realtimebidding](clients/marketing/google-realtimebidding.nu)                                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/realtimebidding/v1alpha/openapi.json>                         |
| [hubspot-marketing](clients/marketing/hubspot-marketing.nu)                                           | openapi | <https://api.apis.guru/v2/specs/hubapi.com/marketing/v3/openapi.json>                                        |
| [iterable](clients/marketing/iterable.nu)                                                             | openapi | <https://api.iterable.com/api-docs>                                                                          |
| [klaviyo](clients/marketing/klaviyo.nu)                                                               | openapi | <https://raw.githubusercontent.com/klaviyo/openapi/main/openapi/stable.json>                                 |
| [knock](clients/marketing/knock.nu)                                                                   | openapi | <https://api.knock.app/v1/openapi>                                                                           |
| [koomalooma](clients/marketing/koomalooma.nu)                                                         | openapi | <https://api.apis.guru/v2/specs/koomalooma.com/1.0/swagger.json>                                             |
| [mailchimp-marketing](clients/marketing/mailchimp-marketing.nu)                                       | openapi | <https://api.mailchimp.com/schema/3.0/Swagger.json?expand>                                                   |
| [novu](clients/marketing/novu.nu)                                                                     | openapi | <https://api.novu.co/openapi.json>                                                                           |
| [onesignal](clients/marketing/onesignal.nu)                                                           | openapi | <https://documentation.onesignal.com/openapi.json>                                                           |
| [redeal](clients/marketing/redeal.nu)                                                                 | openapi | <https://api.apis.guru/v2/specs/redeal.io/1.0.0/openapi.json>                                                |
| [redeal-analytics](clients/marketing/redeal-analytics.nu)                                             | openapi | <https://api.apis.guru/v2/specs/redeal.io/analytics/1.0.0/openapi.json>                                      |
| [reloadly-apisguru](clients/marketing/reloadly-apisguru.nu)                                           | openapi | <https://api.apis.guru/v2/specs/reloadly.com/1.0.0/openapi.json>                                             |
| [ritekit](clients/marketing/ritekit.nu)                                                               | openapi | <https://api.apis.guru/v2/specs/ritekit.com/1.0.0/openapi.json>                                              |
| [vtex-profile-system](clients/marketing/vtex-profile-system.nu)                                       | openapi | <https://api.apis.guru/v2/specs/vtex.local/Profile-System/1.0/openapi.json>                                  |
| [vtex-promotions](clients/marketing/vtex-promotions.nu)                                               | openapi | <https://api.apis.guru/v2/specs/vtex.local/Promotions-/1.0/openapi.json>                                     |
| [vtex-reviews-ratings](clients/marketing/vtex-reviews-ratings.nu)                                     | openapi | <https://api.apis.guru/v2/specs/vtex.local/Reviews-and-Ratings-API/1.0/openapi.json>                         |

### monitoring

| Client                                                                           | Type    | Source                                                                                                       |
| -------------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------ |
| [aws-cloudtrail](clients/monitoring/aws-cloudtrail.nu)                           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/cloudtrail/2013-11-01/openapi.json>                            |
| [aws-cloudwatch](clients/monitoring/aws-cloudwatch.nu)                           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/monitoring/2010-08-01/openapi.json>                            |
| [aws-xray](clients/monitoring/aws-xray.nu)                                       | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/xray/2016-04-12/openapi.json>                                  |
| [azure-advisor](clients/monitoring/azure-advisor.nu)                             | openapi | <https://api.apis.guru/v2/specs/azure.com/advisor/2017-04-19/swagger.json>                                   |
| [azure-alerts-management](clients/monitoring/azure-alerts-management.nu)         | openapi | <https://api.apis.guru/v2/specs/azure.com/alertsmanagement-AlertsManagement/2019-05-05-preview/swagger.json> |
| [azure-monitor-action-groups](clients/monitoring/azure-monitor-action-groups.nu) | openapi | <https://api.apis.guru/v2/specs/azure.com/monitor-actionGroups_API/2019-06-01/swagger.json>                  |
| [azure-monitor-activity-logs](clients/monitoring/azure-monitor-activity-logs.nu) | openapi | <https://api.apis.guru/v2/specs/azure.com/monitor-activityLogs_API/2015-04-01/swagger.json>                  |
| [azure-monitor-autoscale](clients/monitoring/azure-monitor-autoscale.nu)         | openapi | <https://api.apis.guru/v2/specs/azure.com/monitor-autoscale_API/2015-04-01/swagger.json>                     |
| [azure-monitor-log-profiles](clients/monitoring/azure-monitor-log-profiles.nu)   | openapi | <https://api.apis.guru/v2/specs/azure.com/monitor-logProfiles_API/2016-03-01/swagger.json>                   |
| [azure-monitor-metric-alert](clients/monitoring/azure-monitor-metric-alert.nu)   | openapi | <https://api.apis.guru/v2/specs/azure.com/monitor-metricAlert_API/2018-03-01/swagger.json>                   |
| [azure-monitor-metrics](clients/monitoring/azure-monitor-metrics.nu)             | openapi | <https://api.apis.guru/v2/specs/azure.com/monitor-metrics_API/2018-01-01/swagger.json>                       |
| [checkly](clients/monitoring/checkly.nu)                                         | openapi | <https://api.checklyhq.com/openapi.json>                                                                     |
| [dash0](clients/monitoring/dash0.nu)                                             | openapi | <https://api.eu-west-1.aws.dash0.com/openapi.json>                                                           |
| [datadog](clients/monitoring/datadog.nu)                                         | openapi | <specs/datadog.yaml>                                                                                         |
| [google-cloud-monitoring](clients/monitoring/google-cloud-monitoring.nu)         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/monitoring/v3/openapi.json>                                   |
| [google-cloudasset](clients/monitoring/google-cloudasset.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/cloudasset/v1p7beta1/openapi.json>                            |
| [google-clouderrorreporting](clients/monitoring/google-clouderrorreporting.nu)   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/clouderrorreporting/v1beta1/openapi.json>                     |
| [google-cloudprofiler](clients/monitoring/google-cloudprofiler.nu)               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/cloudprofiler/v2/openapi.json>                                |
| [google-logging](clients/monitoring/google-logging.nu)                           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/logging/v2/openapi.json>                                      |
| [google-monitoring](clients/monitoring/google-monitoring.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/monitoring/v1/openapi.json>                                   |
| [grafana](clients/monitoring/grafana.nu)                                         | openapi | <https://raw.githubusercontent.com/grafana/grafana/main/public/api-merged.json>                              |
| [influxdata](clients/monitoring/influxdata.nu)                                   | openapi | <https://api.apis.guru/v2/specs/influxdata.com/2.0.0/openapi.json>                                           |
| [influxdb](clients/monitoring/influxdb.nu)                                       | openapi | <https://raw.githubusercontent.com/influxdata/openapi/master/contracts/cloud.yml>                            |
| [kibana](clients/monitoring/kibana.nu)                                           | openapi | <https://raw.githubusercontent.com/elastic/kibana/main/oas_docs/output/kibana.serverless.yaml>               |
| [logfire](clients/monitoring/logfire.nu)                                         | openapi | <https://logfire-api.pydantic.dev/openapi.json>                                                              |
| [netdata](clients/monitoring/netdata.nu)                                         | openapi | <https://raw.githubusercontent.com/netdata/netdata/master/src/web/api/netdata-swagger.yaml>                  |
| [solarwinds-observability](clients/monitoring/solarwinds-observability.nu)       | openapi | <https://api.na-01.cloud.solarwinds.com/v1/openapi.json>                                                     |
| [truesight](clients/monitoring/truesight.nu)                                     | openapi | <https://api.apis.guru/v2/specs/truesight.local/11.1.00/openapi.json>                                        |
| [twilio-monitor](clients/monitoring/twilio-monitor.nu)                           | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_monitor_v1/1.42.0/openapi.json>                            |
| [vmware-vrni](clients/monitoring/vmware-vrni.nu)                                 | openapi | <https://api.apis.guru/v2/specs/vmware.local/vrni/1.0.0/openapi.json>                                        |

### music

| Client                                                                  | Type    | Source                                                                                        |
| ----------------------------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------- |
| [apple-music](clients/music/apple-music.nu)                             | openapi | <https://raw.githubusercontent.com/schroedan/apple-music-api/main/openapi.yaml>               |
| [apple-sirikit-cloud-media](clients/music/apple-sirikit-cloud-media.nu) | openapi | <https://api.apis.guru/v2/specs/apple.com/sirikit-cloud-media/1.0.2/openapi.json>             |
| [art19](clients/music/art19.nu)                                         | openapi | <https://api.apis.guru/v2/specs/art19.com/1.0.0/openapi.json>                                 |
| [audius](clients/music/audius.nu)                                       | openapi | <https://raw.githubusercontent.com/AudiusProject/api-docs/master/swagger/swagger.json>        |
| [bandsintown](clients/music/bandsintown.nu)                             | openapi | <https://api.apis.guru/v2/specs/bandsintown.com/3.0.0/swagger.json>                           |
| [discogs](clients/music/discogs.nu)                                     | openapi | <https://raw.githubusercontent.com/wyattowalsh/discogs-api-spec/main/discogs.json>            |
| [flat-io](clients/music/flat-io.nu)                                     | openapi | <https://api.apis.guru/v2/specs/flat.io/2.13.0/openapi.json>                                  |
| [freesound](clients/music/freesound.nu)                                 | openapi | <https://api.apis.guru/v2/specs/freesound.org/2.0.0/swagger.json>                             |
| [hubhopper](clients/music/hubhopper.nu)                                 | openapi | <https://api.apis.guru/v2/specs/hubhopper.com/v5/swagger.json>                                |
| [jellyfin](clients/music/jellyfin.nu)                                   | openapi | <https://api.jellyfin.org/openapi/jellyfin-openapi-stable.json>                               |
| [jellyfin-apisguru](clients/music/jellyfin-apisguru.nu)                 | openapi | <https://api.apis.guru/v2/specs/jellyfin.local/v1/openapi.json>                               |
| [lidarr](clients/music/lidarr.nu)                                       | openapi | <https://raw.githubusercontent.com/Lidarr/Lidarr/develop/src/Lidarr.Api.V1/openapi.json>      |
| [listennotes](clients/music/listennotes.nu)                             | openapi | <https://api.apis.guru/v2/specs/listennotes.com/2.0/openapi.json>                             |
| [musixmatch](clients/music/musixmatch.nu)                               | openapi | <https://api.apis.guru/v2/specs/musixmatch.com/1.1.0/swagger.json>                            |
| [setlistfm](clients/music/setlistfm.nu)                                 | openapi | <https://api.apis.guru/v2/specs/setlist.fm/1.0/swagger.json>                                  |
| [sonos](clients/music/sonos.nu)                                         | openapi | <https://raw.githubusercontent.com/antxxxx/sonos-swagger-api/master/api/swagger/swagger.yaml> |
| [soundcloud](clients/music/soundcloud.nu)                               | openapi | <https://api.apis.guru/v2/specs/soundcloud.com/1.0.0/openapi.json>                            |
| [spinitron](clients/music/spinitron.nu)                                 | openapi | <https://api.apis.guru/v2/specs/spinitron.com/1.0.0/openapi.json>                             |
| [spotify](clients/music/spotify.nu)                                     | openapi | <https://raw.githubusercontent.com/sonallux/spotify-web-api/main/fixed-spotify-open-api.yml>  |
| [spotify-sonallux](clients/music/spotify-sonallux.nu)                   | openapi | <https://api.apis.guru/v2/specs/spotify.com/sonallux/2023.2.27/openapi.json>                  |
| [synq-fm](clients/music/synq-fm.nu)                                     | openapi | <https://api.apis.guru/v2/specs/synq.fm/1.9.1/swagger.json>                                   |
| [tidal](clients/music/tidal.nu)                                         | openapi | <https://tidal-music.github.io/tidal-api-reference/tidal-api-oas.json>                        |
| [vocadb](clients/music/vocadb.nu)                                       | openapi | <https://api.apis.guru/v2/specs/vocadb.net/1.0/openapi.json>                                  |
| [zeno-fm](clients/music/zeno-fm.nu)                                     | openapi | <https://api.apis.guru/v2/specs/zeno.fm/0.6-99cfdac/openapi.json>                             |

### news

| Client                                                                 | Type    | Source                                                                                              |
| ---------------------------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------------- |
| [bbc](clients/news/bbc.nu)                                             | openapi | <https://api.apis.guru/v2/specs/bbc.com/1.0.0/openapi.json>                                         |
| [bing-news-search](clients/news/bing-news-search.nu)                   | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-NewsSearch/1.0/swagger.json>        |
| [biztoc](clients/news/biztoc.nu)                                       | openapi | <https://api.apis.guru/v2/specs/biztoc.com/v1/openapi.json>                                         |
| [channel4](clients/news/channel4.nu)                                   | openapi | <https://api.apis.guru/v2/specs/channel4.com/1.0.0/swagger.json>                                    |
| [gdelt-cloud](clients/news/gdelt-cloud.nu)                             | openapi | <https://docs.gdeltcloud.com/api-reference/openapi-v2.json>                                         |
| [hacker-news](clients/news/hacker-news.nu)                             | openapi | <https://gist.githubusercontent.com/wing328/44a6cb6c899feda4c2bd44747e9dcbc8/raw>                   |
| [newsdata-io](clients/news/newsdata-io.nu)                             | openapi | <https://newsdata.io/openapi.json>                                                                  |
| [npr-authorization](clients/news/npr-authorization.nu)                 | openapi | <https://api.apis.guru/v2/specs/npr.org/authorization/2/swagger.json>                               |
| [npr-listening](clients/news/npr-listening.nu)                         | openapi | <https://api.apis.guru/v2/specs/npr.org/listening/2/swagger.json>                                   |
| [npr-sponsorship](clients/news/npr-sponsorship.nu)                     | openapi | <https://api.apis.guru/v2/specs/npr.org/sponsorship/2/swagger.json>                                 |
| [npr-station-finder](clients/news/npr-station-finder.nu)               | openapi | <https://api.apis.guru/v2/specs/npr.org/station-finder/3/swagger.json>                              |
| [nytimes-archive](clients/news/nytimes-archive.nu)                     | openapi | <https://api.apis.guru/v2/specs/nytimes.com/archive/1.0.0/openapi.json>                             |
| [nytimes-article-search](clients/news/nytimes-article-search.nu)       | openapi | <https://api.apis.guru/v2/specs/nytimes.com/article_search/1.0.0/openapi.json>                      |
| [nytimes-books](clients/news/nytimes-books.nu)                         | openapi | <https://api.apis.guru/v2/specs/nytimes.com/books_api/3.0.0/openapi.json>                           |
| [nytimes-community](clients/news/nytimes-community.nu)                 | openapi | <https://api.apis.guru/v2/specs/nytimes.com/community/3.0.0/openapi.json>                           |
| [nytimes-geo](clients/news/nytimes-geo.nu)                             | openapi | <https://api.apis.guru/v2/specs/nytimes.com/geo_api/1.0.0/openapi.json>                             |
| [nytimes-most-popular](clients/news/nytimes-most-popular.nu)           | openapi | <https://api.apis.guru/v2/specs/nytimes.com/most_popular_api/2.0.0/openapi.json>                    |
| [nytimes-movie-reviews](clients/news/nytimes-movie-reviews.nu)         | openapi | <https://api.apis.guru/v2/specs/nytimes.com/movie_reviews/2.0.0/openapi.json>                       |
| [nytimes-semantic-apisguru](clients/news/nytimes-semantic-apisguru.nu) | openapi | <https://api.apis.guru/v2/specs/nytimes.com/semantic_api/2.0.0/openapi.json>                        |
| [nytimes-tags](clients/news/nytimes-tags.nu)                           | openapi | <https://api.apis.guru/v2/specs/nytimes.com/times_tags/1.0.0/openapi.json>                          |
| [nytimes-timeswire](clients/news/nytimes-timeswire.nu)                 | openapi | <https://api.apis.guru/v2/specs/nytimes.com/timeswire/3.0.0/openapi.json>                           |
| [nytimes-top-stories](clients/news/nytimes-top-stories.nu)             | openapi | <https://api.apis.guru/v2/specs/nytimes.com/top_stories/2.0.0/openapi.json>                         |
| [owler](clients/news/owler.nu)                                         | openapi | <https://api.apis.guru/v2/specs/owler.com/1.0.0/swagger.json>                                       |
| [pressassociation](clients/news/pressassociation.nu)                   | openapi | <https://api.apis.guru/v2/specs/pressassociation.io/2.0/openapi.json>                               |
| [prss](clients/news/prss.nu)                                           | openapi | <https://api.apis.guru/v2/specs/prss.org/2.0.0/openapi.json>                                        |
| [sportsdata-mlb-news](clients/news/sportsdata-mlb-news.nu)             | openapi | <https://api.apis.guru/v2/specs/sportsdata.io/mlb-v3-rotoballer-premium-news/1.0/openapi.json>      |
| [sportsdata-nba-news](clients/news/sportsdata-nba-news.nu)             | openapi | <https://api.apis.guru/v2/specs/sportsdata.io/nba-v3-rotoballer-premium-news/1.0/openapi.json>      |
| [sportsdata-nfl-news](clients/news/sportsdata-nfl-news.nu)             | openapi | <https://api.apis.guru/v2/specs/sportsdata.io/nfl-v3-rotoballer-premium-news/1.0/openapi.json>      |
| [worldnewsapi](clients/news/worldnewsapi.nu)                           | openapi | <https://raw.githubusercontent.com/ddsky/world-news-api-clients/main/world-news-api-openapi-3.json> |

### payments

| Client                                                                     | Type    | Source                                                                                                          |
| -------------------------------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------------------------- |
| [adyen-account-service](clients/payments/adyen-account-service.nu)         | openapi | <https://api.apis.guru/v2/specs/adyen.com/AccountService/6/openapi.json>                                        |
| [adyen-balance-control](clients/payments/adyen-balance-control.nu)         | openapi | <https://api.apis.guru/v2/specs/adyen.com/BalanceControlService/1/openapi.json>                                 |
| [adyen-balance-platform](clients/payments/adyen-balance-platform.nu)       | openapi | <https://api.apis.guru/v2/specs/adyen.com/BalancePlatformService/2/openapi.json>                                |
| [adyen-checkout](clients/payments/adyen-checkout.nu)                       | openapi | <https://raw.githubusercontent.com/Adyen/adyen-openapi/main/yaml/CheckoutService-v71.yaml>                      |
| [adyen-data-protection](clients/payments/adyen-data-protection.nu)         | openapi | <https://api.apis.guru/v2/specs/adyen.com/DataProtectionService/1/openapi.json>                                 |
| [adyen-fund-service](clients/payments/adyen-fund-service.nu)               | openapi | <https://api.apis.guru/v2/specs/adyen.com/FundService/6/openapi.json>                                           |
| [adyen-hop](clients/payments/adyen-hop.nu)                                 | openapi | <https://api.apis.guru/v2/specs/adyen.com/HopService/6/openapi.json>                                            |
| [adyen-legal-entity](clients/payments/adyen-legal-entity.nu)               | openapi | <https://api.apis.guru/v2/specs/adyen.com/LegalEntityService/3/openapi.json>                                    |
| [adyen-management](clients/payments/adyen-management.nu)                   | openapi | <https://raw.githubusercontent.com/Adyen/adyen-openapi/main/yaml/ManagementService-v3.yaml>                     |
| [adyen-notification-config](clients/payments/adyen-notification-config.nu) | openapi | <https://api.apis.guru/v2/specs/adyen.com/NotificationConfigurationService/6/openapi.json>                      |
| [adyen-payment-service](clients/payments/adyen-payment-service.nu)         | openapi | <https://api.apis.guru/v2/specs/adyen.com/PaymentService/68/openapi.json>                                       |
| [adyen-payments](clients/payments/adyen-payments.nu)                       | openapi | <https://raw.githubusercontent.com/Adyen/adyen-openapi/main/yaml/PaymentService-v68.yaml>                       |
| [adyen-payout](clients/payments/adyen-payout.nu)                           | openapi | <https://api.apis.guru/v2/specs/adyen.com/PayoutService/68/openapi.json>                                        |
| [adyen-recurring](clients/payments/adyen-recurring.nu)                     | openapi | <https://raw.githubusercontent.com/Adyen/adyen-openapi/main/yaml/RecurringService-v68.yaml>                     |
| [adyen-stored-value](clients/payments/adyen-stored-value.nu)               | openapi | <https://api.apis.guru/v2/specs/adyen.com/StoredValueService/46/openapi.json>                                   |
| [adyen-test-card](clients/payments/adyen-test-card.nu)                     | openapi | <https://api.apis.guru/v2/specs/adyen.com/TestCardService/1/openapi.json>                                       |
| [adyen-tfm](clients/payments/adyen-tfm.nu)                                 | openapi | <https://api.apis.guru/v2/specs/adyen.com/TfmAPIService/1/openapi.json>                                         |
| [adyen-transfer](clients/payments/adyen-transfer.nu)                       | openapi | <https://api.apis.guru/v2/specs/adyen.com/TransferService/3/openapi.json>                                       |
| [btcpay-server](clients/payments/btcpay-server.nu)                         | openapi | <https://docs.btcpayserver.org/API/Greenfield/v1/swagger.json>                                                  |
| [hyperswitch](clients/payments/hyperswitch.nu)                             | openapi | <https://raw.githubusercontent.com/juspay/hyperswitch/main/api-reference/v1/openapi_spec_v1.json>               |
| [hyperswitch-v2](clients/payments/hyperswitch-v2.nu)                       | openapi | <https://raw.githubusercontent.com/juspay/hyperswitch/main/api-reference/v2/openapi_spec_v2.json>               |
| [klarna-payments](clients/payments/klarna-payments.nu)                     | openapi | <https://api.apis.guru/v2/specs/klarna.com/payments/1.0.0/openapi.json>                                         |
| [nowpayments](clients/payments/nowpayments.nu)                             | openapi | <https://api.apis.guru/v2/specs/nowpayments.io/1.0.0/openapi.json>                                              |
| [pay1-link](clients/payments/pay1-link.nu)                                 | openapi | <https://api.apis.guru/v2/specs/pay1.de/link/v1/openapi.json>                                                   |
| [paypal-invoicing](clients/payments/paypal-invoicing.nu)                   | openapi | <https://raw.githubusercontent.com/paypal/paypal-rest-api-specifications/main/openapi/invoicing_v2.json>        |
| [paypal-orders](clients/payments/paypal-orders.nu)                         | openapi | <https://raw.githubusercontent.com/paypal/paypal-rest-api-specifications/main/openapi/checkout_orders_v2.json>  |
| [paypal-payments](clients/payments/paypal-payments.nu)                     | openapi | <https://raw.githubusercontent.com/paypal/paypal-rest-api-specifications/main/openapi/payments_payment_v2.json> |
| [paystack](clients/payments/paystack.nu)                                   | openapi | <https://raw.githubusercontent.com/PaystackOSS/openapi/main/dist/paystack.yaml>                                 |
| [plaid](clients/payments/plaid.nu)                                         | openapi | <https://raw.githubusercontent.com/plaid/plaid-openapi/master/2020-09-14.yml>                                   |
| [recurly](clients/payments/recurly.nu)                                     | openapi | <https://raw.githubusercontent.com/recurly/recurly-client-go/master/openapi/api.yaml>                           |
| [spreedly](clients/payments/spreedly.nu)                                   | openapi | <https://raw.githubusercontent.com/venuenext/spreedly_openapi/master/spreedly.openapi3.yml>                     |
| [stripe](clients/payments/stripe.nu)                                       | openapi | <https://raw.githubusercontent.com/stripe/openapi/master/openapi/spec3.json>                                    |
| [tebex-checkout](clients/payments/tebex-checkout.nu)                       | openapi | <https://raw.githubusercontent.com/tebexio/TebexCheckout-OpenAPI/main/sdks/openapi/openapi.json>                |

### project-mgmt

| Client                                                         | Type    | Source                                                                                                      |
| -------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------- |
| [apacta](clients/project-mgmt/apacta.nu)                       | openapi | <https://api.apis.guru/v2/specs/apacta.com/0.0.42/openapi.json>                                             |
| [asana](clients/project-mgmt/asana.nu)                         | openapi | <https://raw.githubusercontent.com/Asana/openapi/master/defs/asana_oas.yaml>                                |
| [asana-github](clients/project-mgmt/asana-github.nu)           | openapi | <https://raw.githubusercontent.com/asana/openapi/master/defs/asana_oas.yaml>                                |
| [asana-spec](clients/project-mgmt/asana-spec.nu)               | openapi | <https://api.apis.guru/v2/specs/asana.com/1.0/openapi.json>                                                 |
| [atlassian-compass](clients/project-mgmt/atlassian-compass.nu) | openapi | <https://developer.atlassian.com/cloud/compass/swagger.v3.json>                                             |
| [basecamp](clients/project-mgmt/basecamp.nu)                   | openapi | <https://raw.githubusercontent.com/basecamp/basecamp-sdk/main/openapi.json>                                 |
| [bluescape](clients/project-mgmt/bluescape.nu)                 | openapi | <https://api.apps.us.bluescape.com/v3/openapi.json>                                                         |
| [clockify](clients/project-mgmt/clockify.nu)                   | openapi | <https://docs.clockify.me/openapi.json>                                                                     |
| [coda](clients/project-mgmt/coda.nu)                           | openapi | <https://coda.io/apis/v1/openapi.json>                                                                      |
| [confluence](clients/project-mgmt/confluence.nu)               | openapi | <https://developer.atlassian.com/cloud/confluence/swagger.v3.json>                                          |
| [etherpad](clients/project-mgmt/etherpad.nu)                   | openapi | <https://api.apis.guru/v2/specs/etherpad.local/1.2.15/openapi.json>                                         |
| [google-tasks](clients/project-mgmt/google-tasks.nu)           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/tasks/v1/openapi.json>                                       |
| [letmc-basic](clients/project-mgmt/letmc-basic.nu)             | openapi | <https://api.apis.guru/v2/specs/letmc.com/basic-tier/v2-basic-tier/swagger.json>                            |
| [letmc-customer](clients/project-mgmt/letmc-customer.nu)       | openapi | <https://api.apis.guru/v2/specs/letmc.com/customer/v2-customer/openapi.json>                                |
| [letmc-diary](clients/project-mgmt/letmc-diary.nu)             | openapi | <https://api.apis.guru/v2/specs/letmc.com/diary/v3-diary/openapi.json>                                      |
| [letmc-maintenance](clients/project-mgmt/letmc-maintenance.nu) | openapi | <https://api.apis.guru/v2/specs/letmc.com/maintenance/v3-maintenance/openapi.json>                          |
| [letmc-reporting](clients/project-mgmt/letmc-reporting.nu)     | openapi | <https://api.apis.guru/v2/specs/letmc.com/reporting/v3-reporting/swagger.json>                              |
| [microsoft-planner](clients/project-mgmt/microsoft-planner.nu) | openapi | <https://raw.githubusercontent.com/microsoftgraph/msgraph-sdk-powershell/main/openApiDocs/v1.0/Planner.yml> |
| [miro](clients/project-mgmt/miro.nu)                           | openapi | <https://raw.githubusercontent.com/miroapp/api-clients/main/packages/generator/spec.json>                   |
| [noosh](clients/project-mgmt/noosh.nu)                         | openapi | <https://api.apis.guru/v2/specs/noosh.com/1.0/openapi.json>                                                 |
| [notion](clients/project-mgmt/notion.nu)                       | openapi | <https://developers.notion.com/openapi.json>                                                                |
| [openproject](clients/project-mgmt/openproject.nu)             | openapi | <https://community.openproject.org/api/v3/spec.json>                                                        |
| [pims](clients/project-mgmt/pims.nu)                           | openapi | <https://api.apis.guru/v2/specs/pims.io/1.0/swagger.json>                                                   |
| [toggl-track](clients/project-mgmt/toggl-track.nu)             | openapi | <https://engineering.toggl.com/assets/files/api-d56ecbd7b19d9020283019e0581d80ca.json>                      |
| [trello](clients/project-mgmt/trello.nu)                       | openapi | <https://developer.atlassian.com/cloud/trello/swagger.v3.json>                                              |
| [trello-apisguru](clients/project-mgmt/trello-apisguru.nu)     | openapi | <https://api.apis.guru/v2/specs/trello.com/1.0/openapi.json>                                                |
| [wrike](clients/project-mgmt/wrike.nu)                         | openapi | <https://developers.wrike.com/openapi/wrike_api_v4_ver154.yaml>                                             |

### public-data

| Client                                                                                    | Type    | Source                                                                                      |
| ----------------------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------- |
| [adobe-aem](clients/public-data/adobe-aem.nu)                                             | openapi | <https://api.apis.guru/v2/specs/adobe.com/aem/3.7.1-pre.0/openapi.json>                     |
| [agco-ats](clients/public-data/agco-ats.nu)                                               | openapi | <https://api.apis.guru/v2/specs/agco-ats.com/v1/openapi.json>                               |
| [airport-web](clients/public-data/airport-web.nu)                                         | openapi | <https://api.apis.guru/v2/specs/airport-web.appspot.com/v1/swagger.json>                    |
| [akeneo](clients/public-data/akeneo.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/akeneo.com/1.0.0/swagger.json>                              |
| [alertersystem](clients/public-data/alertersystem.nu)                                     | openapi | <https://api.apis.guru/v2/specs/alertersystem.com/1.6.0/openapi.json>                       |
| [amentum-atmosphere](clients/public-data/amentum-atmosphere.nu)                           | openapi | <https://api.apis.guru/v2/specs/amentum.space/atmosphere/1.1.1/openapi.json>                |
| [amentum-aviation-radiation](clients/public-data/amentum-aviation-radiation.nu)           | openapi | <https://api.apis.guru/v2/specs/amentum.space/aviation_radiation/1.5.0/openapi.json>        |
| [amentum-global-magnet](clients/public-data/amentum-global-magnet.nu)                     | openapi | <https://api.apis.guru/v2/specs/amentum.space/global-magnet/1.3.0/openapi.json>             |
| [amentum-gravity](clients/public-data/amentum-gravity.nu)                                 | openapi | <https://api.apis.guru/v2/specs/amentum.space/gravity/1.1.1/openapi.json>                   |
| [amentum-space-radiation](clients/public-data/amentum-space-radiation.nu)                 | openapi | <https://api.apis.guru/v2/specs/amentum.space/space_radiation/1.1.2/openapi.json>           |
| [apidapp](clients/public-data/apidapp.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/apidapp.com/2019-02-14T164701Z/openapi.json>                |
| [apigee-marketcheck-cars](clients/public-data/apigee-marketcheck-cars.nu)                 | openapi | <https://api.apis.guru/v2/specs/apigee.net/marketcheck-cars/2.01/openapi.json>              |
| [apimatic](clients/public-data/apimatic.nu)                                               | openapi | <https://api.apis.guru/v2/specs/apimatic.io/1.0/openapi.json>                               |
| [apisetu-acko](clients/public-data/apisetu-acko.nu)                                       | openapi | <https://api.apis.guru/v2/specs/apisetu.gov.in/acko/3.0.0/openapi.json>                     |
| [apisetu-bajajallianz](clients/public-data/apisetu-bajajallianz.nu)                       | openapi | <https://api.apis.guru/v2/specs/apisetu.gov.in/bajajallianz/3.0.0/openapi.json>             |
| [apisetu-bharatpetroleum](clients/public-data/apisetu-bharatpetroleum.nu)                 | openapi | <https://api.apis.guru/v2/specs/apisetu.gov.in/bharatpetroleum/3.0.0/openapi.json>          |
| [apisetu-bhavishya](clients/public-data/apisetu-bhavishya.nu)                             | openapi | <https://api.apis.guru/v2/specs/apisetu.gov.in/bhavishya/3.0.0/openapi.json>                |
| [apisetu-cbse](clients/public-data/apisetu-cbse.nu)                                       | openapi | <https://api.apis.guru/v2/specs/apisetu.gov.in/cbse/3.0.0/openapi.json>                     |
| [apisetu-chitkarauniversity](clients/public-data/apisetu-chitkarauniversity.nu)           | openapi | <https://api.apis.guru/v2/specs/apisetu.gov.in/chitkarauniversity/3.0.0/openapi.json>       |
| [apisetu-cisce](clients/public-data/apisetu-cisce.nu)                                     | openapi | <https://api.apis.guru/v2/specs/apisetu.gov.in/cisce/3.0.0/openapi.json>                    |
| [apisetu-csc](clients/public-data/apisetu-csc.nu)                                         | openapi | <https://api.apis.guru/v2/specs/apisetu.gov.in/csc/3.0.0/openapi.json>                      |
| [apisetu-dgft](clients/public-data/apisetu-dgft.nu)                                       | openapi | <https://api.apis.guru/v2/specs/apisetu.gov.in/dgft/3.0.0/openapi.json>                     |
| [apisetu-epfindia](clients/public-data/apisetu-epfindia.nu)                               | openapi | <https://api.apis.guru/v2/specs/apisetu.gov.in/epfindia/3.0.0/openapi.json>                 |
| [apispot](clients/public-data/apispot.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/apispot.io/whois/1.0/openapi.json>                          |
| [appcenter-ms](clients/public-data/appcenter-ms.nu)                                       | openapi | <https://api.apis.guru/v2/specs/appcenter.ms/v0.1/openapi.json>                             |
| [apple-app-store-connect](clients/public-data/apple-app-store-connect.nu)                 | openapi | <https://api.apis.guru/v2/specs/apple.com/app-store-connect/1.4.1/openapi.json>             |
| [apptigent](clients/public-data/apptigent.nu)                                             | openapi | <https://api.apis.guru/v2/specs/apptigent.com/2021.1.01/openapi.json>                       |
| [archive-org-search](clients/public-data/archive-org-search.nu)                           | openapi | <https://api.apis.guru/v2/specs/archive.org/search/1.0.0/openapi.json>                      |
| [archive-org-wayback](clients/public-data/archive-org-wayback.nu)                         | openapi | <https://api.apis.guru/v2/specs/archive.org/wayback/1.0.0/openapi.json>                     |
| [ato-gov-au](clients/public-data/ato-gov-au.nu)                                           | openapi | <https://api.apis.guru/v2/specs/ato.gov.au/0.0.6/openapi.json>                              |
| [aucklandmuseum](clients/public-data/aucklandmuseum.nu)                                   | openapi | <https://api.apis.guru/v2/specs/aucklandmuseum.com/2.0.0/swagger.json>                      |
| [autodealerdata](clients/public-data/autodealerdata.nu)                                   | openapi | <https://api.apis.guru/v2/specs/autodealerdata.com/1.0/openapi.json>                        |
| [axesso](clients/public-data/axesso.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/axesso.de/1.0.0/openapi.json>                               |
| [bc-bcdc](clients/public-data/bc-bcdc.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/gov.bc.ca/bcdc/3.0.1/openapi.json>                          |
| [bc-bcgnws](clients/public-data/bc-bcgnws.nu)                                             | openapi | <https://api.apis.guru/v2/specs/gov.bc.ca/bcgnws/3.x.x/openapi.json>                        |
| [bc-geomark](clients/public-data/bc-geomark.nu)                                           | openapi | <https://api.apis.guru/v2/specs/gov.bc.ca/geomark/4.1.2/openapi.json>                       |
| [bc-gwells](clients/public-data/bc-gwells.nu)                                             | openapi | <https://api.apis.guru/v2/specs/gov.bc.ca/gwells/v1/openapi.json>                           |
| [bc-jobposting](clients/public-data/bc-jobposting.nu)                                     | openapi | <https://api.apis.guru/v2/specs/gov.bc.ca/jobposting/1.0.0/openapi.json>                    |
| [bc-news](clients/public-data/bc-news.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/gov.bc.ca/news/1.0/openapi.json>                            |
| [bc-open511](clients/public-data/bc-open511.nu)                                           | openapi | <https://api.apis.guru/v2/specs/gov.bc.ca/open511/1.0.0/openapi.json>                       |
| [bc-router](clients/public-data/bc-router.nu)                                             | openapi | <https://api.apis.guru/v2/specs/gov.bc.ca/router/2.0.0/openapi.json>                        |
| [bclaws](clients/public-data/bclaws.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/bclaws.ca/bclaws/1.0.0/openapi.json>                        |
| [betfair](clients/public-data/betfair.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/betfair.com/1.0.1423/openapi.json>                          |
| [bethmardutho](clients/public-data/bethmardutho.nu)                                       | openapi | <https://api.apis.guru/v2/specs/bethmardutho.org/1.0.0/swagger.json>                        |
| [bhagavadgita](clients/public-data/bhagavadgita.nu)                                       | openapi | <https://api.apis.guru/v2/specs/bhagavadgita.io/1.0/openapi.json>                           |
| [biapi-pro](clients/public-data/biapi-pro.nu)                                             | openapi | <https://api.apis.guru/v2/specs/biapi.pro/2.0/openapi.json>                                 |
| [bigredcloud](clients/public-data/bigredcloud.nu)                                         | openapi | <https://api.apis.guru/v2/specs/bigredcloud.com/v1/openapi.json>                            |
| [bikewise](clients/public-data/bikewise.nu)                                               | openapi | <https://api.apis.guru/v2/specs/bikewise.org/v2/openapi.json>                               |
| [bintable](clients/public-data/bintable.nu)                                               | openapi | <https://api.apis.guru/v2/specs/bintable.com/1.0.0-oas3/openapi.json>                       |
| [botify](clients/public-data/botify.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/botify.com/1.0.0/openapi.json>                              |
| [brainbi](clients/public-data/brainbi.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/brainbi.net/1.0.0/openapi.json>                             |
| [brandlovers](clients/public-data/brandlovers.nu)                                         | openapi | <https://api.apis.guru/v2/specs/brandlovers.com/1.0.0/swagger.json>                         |
| [bridgedb](clients/public-data/bridgedb.nu)                                               | openapi | <https://api.apis.guru/v2/specs/bridgedb.org/0.9.0/swagger.json>                            |
| [britbox](clients/public-data/britbox.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/britbox.co.uk/3.730.300-ref-1-39-0/openapi.json>            |
| [byautomata](clients/public-data/byautomata.nu)                                           | openapi | <https://api.apis.guru/v2/specs/byautomata.io/1.0.1/openapi.json>                           |
| [cambase](clients/public-data/cambase.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/cambase.io/1.0/swagger.json>                                |
| [canada-holidays](clients/public-data/canada-holidays.nu)                                 | openapi | <https://api.apis.guru/v2/specs/canada-holidays.ca/1.8.0/openapi.json>                      |
| [carbondoomsday](clients/public-data/carbondoomsday.nu)                                   | openapi | <https://api.apis.guru/v2/specs/carbondoomsday.com/v1/swagger.json>                         |
| [cenit](clients/public-data/cenit.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/cenit.io/v1/swagger.json>                                   |
| [chaingateway](clients/public-data/chaingateway.nu)                                       | openapi | <https://api.apis.guru/v2/specs/chaingateway.io/1.0/openapi.json>                           |
| [chompthis](clients/public-data/chompthis.nu)                                             | openapi | <https://api.apis.guru/v2/specs/chompthis.com/1.0.0-oas3/openapi.json>                      |
| [cisco](clients/public-data/cisco.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/cisco.com/0.0.3/swagger.json>                               |
| [citycontext](clients/public-data/citycontext.nu)                                         | openapi | <https://api.apis.guru/v2/specs/citycontext.com/1.0.0/swagger.json>                         |
| [clearblade](clients/public-data/clearblade.nu)                                           | openapi | <https://api.apis.guru/v2/specs/clearblade.com/3.0/swagger.json>                            |
| [clever](clients/public-data/clever.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/clever.com/1.2.0/openapi.json>                              |
| [clever-cloud-ecwid](clients/public-data/clever-cloud-ecwid.nu)                           | openapi | <https://api.apis.guru/v2/specs/cloud-elements.com/ecwid/api-v2/swagger.json>               |
| [cloudrf](clients/public-data/cloudrf.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/cloudrf.com/2.0.0/openapi.json>                             |
| [cnab-online](clients/public-data/cnab-online.nu)                                         | openapi | <https://api.apis.guru/v2/specs/cnab-online.herokuapp.com/1.0.0/swagger.json>               |
| [codesearch-debian](clients/public-data/codesearch-debian.nu)                             | openapi | <https://api.apis.guru/v2/specs/codesearch.debian.net/1.4.0/openapi.json>                   |
| [color-pizza](clients/public-data/color-pizza.nu)                                         | openapi | <https://api.apis.guru/v2/specs/color.pizza/1.0.0/openapi.json>                             |
| [combell](clients/public-data/combell.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/combell.com/v2/openapi.json>                                |
| [core-ac-uk](clients/public-data/core-ac-uk.nu)                                           | openapi | <https://api.apis.guru/v2/specs/core.ac.uk/2.0/swagger.json>                                |
| [countries](clients/public-data/countries.nu)                                             | graphql | <https://countries.trevorblades.com/graphql>                                                |
| [crossref](clients/public-data/crossref.nu)                                               | openapi | <https://api.crossref.org/swagger-docs>                                                     |
| [cybertaxonomy](clients/public-data/cybertaxonomy.nu)                                     | openapi | <https://api.apis.guru/v2/specs/cybertaxonomy.eu/1.0/swagger.json>                          |
| [cycat](clients/public-data/cycat.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/cycat.org/0.9/swagger.json>                                 |
| [data-gov](clients/public-data/data-gov.nu)                                               | openapi | <https://api.apis.guru/v2/specs/data.gov/3.0/swagger.json>                                  |
| [dataatwork](clients/public-data/dataatwork.nu)                                           | openapi | <https://api.apis.guru/v2/specs/dataatwork.org/1.0/swagger.json>                            |
| [dataflowkit](clients/public-data/dataflowkit.nu)                                         | openapi | <https://api.apis.guru/v2/specs/dataflowkit.com/1.3/openapi.json>                           |
| [departureboard](clients/public-data/departureboard.nu)                                   | openapi | <https://api.apis.guru/v2/specs/departureboard.io/2.0/openapi.json>                         |
| [deutsche-bahn-betriebsstellen](clients/public-data/deutsche-bahn-betriebsstellen.nu)     | openapi | <https://api.apis.guru/v2/specs/deutschebahn.com/betriebsstellen/v1/swagger.json>           |
| [deutsche-bahn-fahrplan](clients/public-data/deutsche-bahn-fahrplan.nu)                   | openapi | <https://api.apis.guru/v2/specs/deutschebahn.com/fahrplan/v1/swagger.json>                  |
| [deutsche-bahn-fasta](clients/public-data/deutsche-bahn-fasta.nu)                         | openapi | <https://api.apis.guru/v2/specs/deutschebahn.com/fasta/2.1/swagger.json>                    |
| [deutsche-bahn-flinkster](clients/public-data/deutsche-bahn-flinkster.nu)                 | openapi | <https://api.apis.guru/v2/specs/deutschebahn.com/flinkster/v1/swagger.json>                 |
| [deutsche-bahn-stada](clients/public-data/deutsche-bahn-stada.nu)                         | openapi | <https://api.apis.guru/v2/specs/deutschebahn.com/stada/2.2.01/swagger.json>                 |
| [deutschebahn-reisezentren](clients/public-data/deutschebahn-reisezentren.nu)             | openapi | <https://api.apis.guru/v2/specs/deutschebahn.com/reisezentren/v1/openapi.json>              |
| [digitalnz](clients/public-data/digitalnz.nu)                                             | openapi | <https://api.apis.guru/v2/specs/digitallinguistics.io/0.3.1/swagger.json>                   |
| [digitalnz-apisguru](clients/public-data/digitalnz-apisguru.nu)                           | openapi | <https://api.apis.guru/v2/specs/digitalnz.org/3/openapi.json>                               |
| [ebi-ac](clients/public-data/ebi-ac.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/ebi.ac.uk/1.0/swagger.json>                                 |
| [ebi-proteins](clients/public-data/ebi-proteins.nu)                                       | openapi | <https://www.ebi.ac.uk/proteins/api/openapi.json>                                           |
| [ena-portal](clients/public-data/ena-portal.nu)                                           | openapi | <https://www.ebi.ac.uk/ena/portal/api/api-docs?group=public>                                |
| [epa-air](clients/public-data/epa-air.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/epa.gov/air/2019.10.15/swagger.json>                        |
| [epa-case](clients/public-data/epa-case.nu)                                               | openapi | <https://api.apis.guru/v2/specs/epa.gov/case/1.0.0/swagger.json>                            |
| [epa-cwa](clients/public-data/epa-cwa.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/epa.gov/cwa/2019.10.15/swagger.json>                        |
| [epa-dfr](clients/public-data/epa-dfr.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/epa.gov/dfr/0.0.0/swagger.json>                             |
| [epa-echo](clients/public-data/epa-echo.nu)                                               | openapi | <https://api.apis.guru/v2/specs/epa.gov/echo/2019.10.15/swagger.json>                       |
| [epa-eff](clients/public-data/epa-eff.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/epa.gov/eff/2019.10.15/swagger.json>                        |
| [epa-rcra](clients/public-data/epa-rcra.nu)                                               | openapi | <https://api.apis.guru/v2/specs/epa.gov/rcra/2019.10.15/swagger.json>                       |
| [epa-sdw](clients/public-data/epa-sdw.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/epa.gov/sdw/2019.10.15/swagger.json>                        |
| [esgenterprise](clients/public-data/esgenterprise.nu)                                     | openapi | <https://api.apis.guru/v2/specs/esgenterprise.com/1.0.0/openapi.json>                       |
| [europeana](clients/public-data/europeana.nu)                                             | openapi | <https://api.apis.guru/v2/specs/europeana.eu/version%20unknown/swagger.json>                |
| [exlibrisgroup-tasklists](clients/public-data/exlibrisgroup-tasklists.nu)                 | openapi | <https://api.apis.guru/v2/specs/exlibrisgroup.com/tasklists/1.0/openapi.json>               |
| [extendsclass-json](clients/public-data/extendsclass-json.nu)                             | openapi | <https://api.apis.guru/v2/specs/extendsclass.com/json-storage/0.1/openapi.json>             |
| [extpose](clients/public-data/extpose.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/extpose.com/1.0.0/openapi.json>                             |
| [exude-api](clients/public-data/exude-api.nu)                                             | openapi | <https://api.apis.guru/v2/specs/exude-api.herokuapp.com/1.0.0/openapi.json>                 |
| [fbi-wanted](clients/public-data/fbi-wanted.nu)                                           | openapi | <https://api.fbi.gov/openapi.json>                                                          |
| [fec](clients/public-data/fec.nu)                                                         | openapi | <https://api.apis.guru/v2/specs/fec.gov/1.0/openapi.json>                                   |
| [fecru](clients/public-data/fecru.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/fecru.local/1.0.0/swagger.json>                             |
| [figshare](clients/public-data/figshare.nu)                                               | openapi | <https://api.apis.guru/v2/specs/figshare.com/2.0.0/openapi.json>                            |
| [firebrowse](clients/public-data/firebrowse.nu)                                           | openapi | <https://api.apis.guru/v2/specs/firebrowse.org/1.1.38/swagger.json>                         |
| [flickr](clients/public-data/flickr.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/flickr.com/1.0.0/openapi.json>                              |
| [gbif-literature](clients/public-data/gbif-literature.nu)                                 | openapi | <https://techdocs.gbif.org/openapi/literature.json>                                         |
| [gbif-occurrence](clients/public-data/gbif-occurrence.nu)                                 | openapi | <https://techdocs.gbif.org/openapi/occurrence.json>                                         |
| [gbif-registry](clients/public-data/gbif-registry.nu)                                     | openapi | <https://techdocs.gbif.org/openapi/registry.json>                                           |
| [gbif-validator](clients/public-data/gbif-validator.nu)                                   | openapi | <https://techdocs.gbif.org/openapi/validator.json>                                          |
| [gbif-vocabulary](clients/public-data/gbif-vocabulary.nu)                                 | openapi | <https://techdocs.gbif.org/openapi/vocabulary.json>                                         |
| [gettyimages](clients/public-data/gettyimages.nu)                                         | openapi | <https://api.apis.guru/v2/specs/gettyimages.com/3/openapi.json>                             |
| [giphy](clients/public-data/giphy.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/giphy.com/1.0/openapi.json>                                 |
| [go-upc](clients/public-data/go-upc.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/go-upc.com/1.0.0/openapi.json>                              |
| [google-books](clients/public-data/google-books.nu)                                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/books/v1/openapi.json>                       |
| [google-civicinfo](clients/public-data/google-civicinfo.nu)                               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/civicinfo/v2/openapi.json>                   |
| [google-classroom](clients/public-data/google-classroom.nu)                               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/classroom/v1/openapi.json>                   |
| [google-indexing](clients/public-data/google-indexing.nu)                                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/indexing/v3/openapi.json>                    |
| [google-jobs](clients/public-data/google-jobs.nu)                                         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/jobs/v3p1beta1/openapi.json>                 |
| [google-mirror](clients/public-data/google-mirror.nu)                                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/mirror/v1/openapi.json>                      |
| [google-poly](clients/public-data/google-poly.nu)                                         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/poly/v1/openapi.json>                        |
| [google-searchconsole](clients/public-data/google-searchconsole.nu)                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/searchconsole/v1/openapi.json>               |
| [google-streetviewpublish](clients/public-data/google-streetviewpublish.nu)               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/streetviewpublish/v1/openapi.json>           |
| [google-vault](clients/public-data/google-vault.nu)                                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/vault/v1/openapi.json>                       |
| [google-versionhistory](clients/public-data/google-versionhistory.nu)                     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/versionhistory/v1/openapi.json>              |
| [google-webfonts](clients/public-data/google-webfonts.nu)                                 | openapi | <https://api.apis.guru/v2/specs/googleapis.com/webfonts/v1/openapi.json>                    |
| [google-webmasters](clients/public-data/google-webmasters.nu)                             | openapi | <https://api.apis.guru/v2/specs/googleapis.com/webmasters/v3/openapi.json>                  |
| [greip](clients/public-data/greip.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/greip.io/1.0.0/openapi.json>                                |
| [gsa-gov](clients/public-data/gsa-gov.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/gsa.gov/0.1/swagger.json>                                   |
| [highways-tfl](clients/public-data/highways-tfl.nu)                                       | openapi | <https://api.apis.guru/v2/specs/tfl.gov.uk/v1/openapi.json>                                 |
| [highwaysengland](clients/public-data/highwaysengland.nu)                                 | openapi | <https://api.apis.guru/v2/specs/highwaysengland.co.uk/v1/openapi.json>                      |
| [ibanapi](clients/public-data/ibanapi.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/ibanapi.com/1.0.0/openapi.json>                             |
| [icons8](clients/public-data/icons8.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/icons8.com/1.0.0/openapi.json>                              |
| [inaturalist](clients/public-data/inaturalist.nu)                                         | openapi | <https://api.inaturalist.org/v1/swagger.json>                                               |
| [inpe-dados-abertos](clients/public-data/inpe-dados-abertos.nu)                           | openapi | <https://api.apis.guru/v2/specs/inpe.br/dados-abertos/1.0/swagger.json>                     |
| [interzoid-citystandard](clients/public-data/interzoid-citystandard.nu)                   | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getcitystandard/1.0.0/openapi.json>           |
| [interzoid-companymatch](clients/public-data/interzoid-companymatch.nu)                   | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getcompanymatch/1.0.0/openapi.json>           |
| [interzoid-countrystandard](clients/public-data/interzoid-countrystandard.nu)             | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getcountrystandard/1.0.0/openapi.json>        |
| [interzoid-getemailinfo](clients/public-data/interzoid-getemailinfo.nu)                   | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getemailinfo/1.0.0/openapi.json>              |
| [interzoid-getfullnamematch](clients/public-data/interzoid-getfullnamematch.nu)           | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getfullnamematch/1.0.0/openapi.json>          |
| [interzoid-getfullnameparsed](clients/public-data/interzoid-getfullnameparsed.nu)         | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getfullnameparsedmatch/1.0.0/openapi.json>    |
| [interzoid-getglobalnumberinfo](clients/public-data/interzoid-getglobalnumberinfo.nu)     | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getglobalnumberinfo/1.0.0/openapi.json>       |
| [interzoid-getglobaltime](clients/public-data/interzoid-getglobaltime.nu)                 | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getglobaltime/1.0.0/openapi.json>             |
| [interzoid-getstateabbr](clients/public-data/interzoid-getstateabbr.nu)                   | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getstateabbreviation/1.0.0/openapi.json>      |
| [interzoid-globalpageload](clients/public-data/interzoid-globalpageload.nu)               | openapi | <https://api.apis.guru/v2/specs/interzoid.com/globalpageload/1.0.0/openapi.json>            |
| [interzoid-lookupareacode](clients/public-data/interzoid-lookupareacode.nu)               | openapi | <https://api.apis.guru/v2/specs/interzoid.com/lookupareacode/1.0.0/openapi.json>            |
| [ip2location](clients/public-data/ip2location.nu)                                         | openapi | <https://api.apis.guru/v2/specs/ip2location.com/geolocation/1.0/openapi.json>               |
| [ip2proxy](clients/public-data/ip2proxy.nu)                                               | openapi | <https://api.apis.guru/v2/specs/ip2proxy.com/1.0/openapi.json>                              |
| [ip2whois](clients/public-data/ip2whois.nu)                                               | openapi | <https://api.apis.guru/v2/specs/ip2whois.com/1.0/openapi.json>                              |
| [iptwist](clients/public-data/iptwist.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/iptwist.com/1.0.0/openapi.json>                             |
| [iqualify](clients/public-data/iqualify.nu)                                               | openapi | <https://api.apis.guru/v2/specs/iqualify.com/v1/openapi.json>                               |
| [isbndb](clients/public-data/isbndb.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/isbndb.com/1.0.1/swagger.json>                              |
| [javatpoint](clients/public-data/javatpoint.nu)                                           | openapi | <https://api.apis.guru/v2/specs/javatpoint.com/v1/openapi.json>                             |
| [landregistry-deed](clients/public-data/landregistry-deed.nu)                             | openapi | <https://api.apis.guru/v2/specs/landregistry.gov.uk/deed/1.0.0/swagger.json>                |
| [launch-library2](clients/public-data/launch-library2.nu)                                 | openapi | <https://ll.thespacedevs.com/2.3.0/schema/>                                                 |
| [link-fish](clients/public-data/link-fish.nu)                                             | openapi | <https://api.apis.guru/v2/specs/link.fish/2018-07-05/swagger.json>                          |
| [lumminary](clients/public-data/lumminary.nu)                                             | openapi | <https://api.apis.guru/v2/specs/lumminary.com/1.0/swagger.json>                             |
| [math-tools](clients/public-data/math-tools.nu)                                           | openapi | <https://api.apis.guru/v2/specs/math.tools/1.5/openapi.json>                                |
| [mercedes-configurator](clients/public-data/mercedes-configurator.nu)                     | openapi | <https://api.apis.guru/v2/specs/mercedes-benz.com/configurator/1.0/swagger.json>            |
| [mercedes-dealer](clients/public-data/mercedes-dealer.nu)                                 | openapi | <https://api.apis.guru/v2/specs/mercedes-benz.com/dealer/1.0/swagger.json>                  |
| [mercedes-diagnostics](clients/public-data/mercedes-diagnostics.nu)                       | openapi | <https://api.apis.guru/v2/specs/mercedes-benz.com/diagnostics/1.0/swagger.json>             |
| [mercedes-image](clients/public-data/mercedes-image.nu)                                   | openapi | <https://api.apis.guru/v2/specs/mercedes-benz.com/image/1.0/swagger.json>                   |
| [met-norway](clients/public-data/met-norway.nu)                                           | openapi | <https://api.met.no/weatherapi/locationforecast/2.0/swagger>                                |
| [monarchinitiative](clients/public-data/monarchinitiative.nu)                             | openapi | <https://api.apis.guru/v2/specs/monarchinitiative.org/1.1.14/openapi.json>                  |
| [mtaa](clients/public-data/mtaa.nu)                                                       | openapi | <https://api.apis.guru/v2/specs/mtaa-api.herokuapp.com/1.0/openapi.json>                    |
| [nager-date](clients/public-data/nager-date.nu)                                           | openapi | <https://date.nager.at/openapi/v3.json>                                                     |
| [nasa-apod](clients/public-data/nasa-apod.nu)                                             | openapi | <https://api.apis.guru/v2/specs/nasa.gov/apod/1.0.0/openapi.json>                           |
| [nasa-neows](clients/public-data/nasa-neows.nu)                                           | openapi | <https://api.apis.guru/v2/specs/nasa.gov/asteroids%20neows/3.4.0/openapi.json>              |
| [ndhm-cm](clients/public-data/ndhm-cm.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/ndhm.gov.in/ndhm-cm/0.5/openapi.json>                       |
| [ndhm-gateway](clients/public-data/ndhm-gateway.nu)                                       | openapi | <https://api.apis.guru/v2/specs/ndhm.gov.in/ndhm-gateway/0.5/openapi.json>                  |
| [ndhm-hip](clients/public-data/ndhm-hip.nu)                                               | openapi | <https://api.apis.guru/v2/specs/ndhm.gov.in/ndhm-hip/0.5/openapi.json>                      |
| [ndhm-hiu](clients/public-data/ndhm-hiu.nu)                                               | openapi | <https://api.apis.guru/v2/specs/ndhm.gov.in/ndhm-hiu/0.5/openapi.json>                      |
| [neowsapp](clients/public-data/neowsapp.nu)                                               | openapi | <https://api.apis.guru/v2/specs/neowsapp.com/1.0/openapi.json>                              |
| [neutrinoapi](clients/public-data/neutrinoapi.nu)                                         | openapi | <https://api.apis.guru/v2/specs/neutrinoapi.net/3.6.3/openapi.json>                         |
| [nrel-buildings](clients/public-data/nrel-buildings.nu)                                   | openapi | <https://api.apis.guru/v2/specs/nrel.gov/building-case-studies/1.0/swagger.json>            |
| [nrel-transport-incentives](clients/public-data/nrel-transport-incentives.nu)             | openapi | <https://api.apis.guru/v2/specs/nrel.gov/transportation-incentives-laws/0.1.0/openapi.json> |
| [nrm-georg](clients/public-data/nrm-georg.nu)                                             | openapi | <https://api.apis.guru/v2/specs/nrm.se/georg/2.1/swagger.json>                              |
| [nsidc](clients/public-data/nsidc.nu)                                                     | openapi | <https://api.apis.guru/v2/specs/nsidc.org/1.0.0/openapi.json>                               |
| [o2-cz-mobility](clients/public-data/o2-cz-mobility.nu)                                   | openapi | <https://api.apis.guru/v2/specs/o2.cz/mobility/1.2.0/swagger.json>                          |
| [o2-cz-sociodemo](clients/public-data/o2-cz-sociodemo.nu)                                 | openapi | <https://api.apis.guru/v2/specs/o2.cz/sociodemo/1.2.0/swagger.json>                         |
| [open-library](clients/public-data/open-library.nu)                                       | openapi | <https://openlibrary.org/static/openapi.json>                                               |
| [open5e](clients/public-data/open5e.nu)                                                   | openapi | <https://api.open5e.com/schema/?format=json>                                                |
| [openaq](clients/public-data/openaq.nu)                                                   | openapi | <https://api.openaq.org/openapi.json>                                                       |
| [openaq-apisguru](clients/public-data/openaq-apisguru.nu)                                 | openapi | <https://api.apis.guru/v2/specs/openaq.local/2.0.0/openapi.json>                            |
| [openchannel-market](clients/public-data/openchannel-market.nu)                           | openapi | <https://api.apis.guru/v2/specs/openchannel.io/market/2.0.24/openapi.json>                  |
| [opendatanetwork](clients/public-data/opendatanetwork.nu)                                 | openapi | <https://api.apis.guru/v2/specs/opendatanetwork.com/1.0.0/openapi.json>                     |
| [opendatasoft](clients/public-data/opendatasoft.nu)                                       | openapi | <https://api.apis.guru/v2/specs/opendatasoft.com/2.1.0/swagger.json>                        |
| [openf1](clients/public-data/openf1.nu)                                                   | openapi | <https://api.openf1.org/openapi.json>                                                       |
| [openfigi](clients/public-data/openfigi.nu)                                               | openapi | <https://api.apis.guru/v2/specs/openfigi.com/1.4.0/openapi.json>                            |
| [openfoodfacts-folksonomy](clients/public-data/openfoodfacts-folksonomy.nu)               | openapi | <https://api.folksonomy.openfoodfacts.org/openapi.json>                                     |
| [openfoodfacts-search](clients/public-data/openfoodfacts-search.nu)                       | openapi | <https://search.openfoodfacts.org/openapi.json>                                             |
| [openstates](clients/public-data/openstates.nu)                                           | openapi | <https://api.apis.guru/v2/specs/openstates.org/2021.11.12/openapi.json>                     |
| [opentargets](clients/public-data/opentargets.nu)                                         | openapi | <https://api.apis.guru/v2/specs/opentargets.io/19.02.1/openapi.json>                        |
| [openuv-uv](clients/public-data/openuv-uv.nu)                                             | openapi | <https://api.apis.guru/v2/specs/openuv.io/v1/openapi.json>                                  |
| [optimade](clients/public-data/optimade.nu)                                               | openapi | <https://api.apis.guru/v2/specs/optimade.local/1.1.0~develop/openapi.json>                  |
| [orghunter](clients/public-data/orghunter.nu)                                             | openapi | <https://api.apis.guru/v2/specs/orghunter.com/1.0.0/swagger.json>                           |
| [ornl-daymet](clients/public-data/ornl-daymet.nu)                                         | openapi | <https://api.apis.guru/v2/specs/ornl.gov/daymet/1.0.2/swagger.json>                         |
| [osf](clients/public-data/osf.nu)                                                         | openapi | <https://api.apis.guru/v2/specs/osf.io/2.0/openapi.json>                                    |
| [oxforddictionaries](clients/public-data/oxforddictionaries.nu)                           | openapi | <https://api.apis.guru/v2/specs/oxforddictionaries.com/1.11.0/openapi.json>                 |
| [parliament-bills](clients/public-data/parliament-bills.nu)                               | openapi | <https://api.apis.guru/v2/specs/parliament.uk/bills/v1/openapi.json>                        |
| [parliament-commonsvotes](clients/public-data/parliament-commonsvotes.nu)                 | openapi | <https://api.apis.guru/v2/specs/parliament.uk/commonsvotes/v1/swagger.json>                 |
| [parliament-erskine-may](clients/public-data/parliament-erskine-may.nu)                   | openapi | <https://api.apis.guru/v2/specs/parliament.uk/erskine-may/v1/openapi.json>                  |
| [parliament-lordsvotes](clients/public-data/parliament-lordsvotes.nu)                     | openapi | <https://api.apis.guru/v2/specs/parliament.uk/lordsvotes/v1/openapi.json>                   |
| [parliament-members](clients/public-data/parliament-members.nu)                           | openapi | <https://api.apis.guru/v2/specs/parliament.uk/members/v1/openapi.json>                      |
| [parliament-now](clients/public-data/parliament-now.nu)                                   | openapi | <https://api.apis.guru/v2/specs/parliament.uk/now/v1/openapi.json>                          |
| [parliament-oralquestions](clients/public-data/parliament-oralquestions.nu)               | openapi | <https://api.apis.guru/v2/specs/parliament.uk/oralquestions/v1/openapi.json>                |
| [parliament-search](clients/public-data/parliament-search.nu)                             | openapi | <https://api.apis.guru/v2/specs/parliament.uk/search/Live/openapi.json>                     |
| [parliament-statutoryinstruments](clients/public-data/parliament-statutoryinstruments.nu) | openapi | <https://api.apis.guru/v2/specs/parliament.uk/statutoryinstruments/v1/openapi.json>         |
| [parliament-treaties](clients/public-data/parliament-treaties.nu)                         | openapi | <https://api.apis.guru/v2/specs/parliament.uk/treaties/v1/openapi.json>                     |
| [parliament-writtenquestions](clients/public-data/parliament-writtenquestions.nu)         | openapi | <https://api.apis.guru/v2/specs/parliament.uk/writtenquestions/v1/openapi.json>             |
| [phila-pollingplaces](clients/public-data/phila-pollingplaces.nu)                         | openapi | <https://api.apis.guru/v2/specs/phila.gov/pollingplaces/1.0/swagger.json>                   |
| [poemist](clients/public-data/poemist.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/poemist.com/1.0/swagger.json>                               |
| [ptv-vic](clients/public-data/ptv-vic.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/ptv.vic.gov.au/v3/openapi.json>                             |
| [quarantine-country](clients/public-data/quarantine-country.nu)                           | openapi | <https://api.apis.guru/v2/specs/quarantine.country/1.0/swagger.json>                        |
| [quicksold-location](clients/public-data/quicksold-location.nu)                           | openapi | <https://api.apis.guru/v2/specs/quicksold.co.uk/location/1.0/swagger.json>                  |
| [redirection-io](clients/public-data/redirection-io.nu)                                   | openapi | <https://api.apis.guru/v2/specs/redirection.io/1.1.0/swagger.json>                          |
| [refugerestrooms](clients/public-data/refugerestrooms.nu)                                 | openapi | <https://api.apis.guru/v2/specs/refugerestrooms.org/0.0.1/swagger.json>                     |
| [regcheck](clients/public-data/regcheck.nu)                                               | openapi | <https://api.apis.guru/v2/specs/regcheck.org.uk/1.0.0/swagger.json>                         |
| [removebg](clients/public-data/removebg.nu)                                               | openapi | <https://api.apis.guru/v2/specs/remove.bg/1.0.0/openapi.json>                               |
| [roaring](clients/public-data/roaring.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/roaring.io/1.0/swagger.json>                                |
| [schooldigger](clients/public-data/schooldigger.nu)                                       | openapi | <https://api.apis.guru/v2/specs/schooldigger.com/v2.0/swagger.json>                         |
| [schooldigger-apisguru](clients/public-data/schooldigger-apisguru.nu)                     | openapi | <https://api.apis.guru/v2/specs/schooldigger.com/v1/swagger.json>                           |
| [semantic-scholar](clients/public-data/semantic-scholar.nu)                               | openapi | <https://api.semanticscholar.org/graph/v1/swagger.json>                                     |
| [semantria](clients/public-data/semantria.nu)                                             | openapi | <https://api.apis.guru/v2/specs/semantria.com/4.0/swagger.json>                             |
| [sheerseo](clients/public-data/sheerseo.nu)                                               | openapi | <https://api.apis.guru/v2/specs/sheerseo.com/0.0.1/swagger.json>                            |
| [sheetlabs-rigveda](clients/public-data/sheetlabs-rigveda.nu)                             | openapi | <https://api.apis.guru/v2/specs/sheetlabs.com/rig-veda/1.2/swagger.json>                    |
| [sheetlabs-vedic-society](clients/public-data/sheetlabs-vedic-society.nu)                 | openapi | <https://api.apis.guru/v2/specs/sheetlabs.com/vedic-society/1.2/swagger.json>               |
| [shorten-rest](clients/public-data/shorten-rest.nu)                                       | openapi | <https://api.apis.guru/v2/specs/shorten.rest/1.0.0/openapi.json>                            |
| [shutterstock](clients/public-data/shutterstock.nu)                                       | openapi | <https://api.apis.guru/v2/specs/shutterstock.com/1.1.32/openapi.json>                       |
| [simplyrets](clients/public-data/simplyrets.nu)                                           | openapi | <https://api.apis.guru/v2/specs/simplyrets.com/1.0.0/swagger.json>                          |
| [surrey-open511](clients/public-data/surrey-open511.nu)                                   | openapi | <https://api.apis.guru/v2/specs/surrey.ca/open511/0.1/swagger.json>                         |
| [surrey-trafficloops](clients/public-data/surrey-trafficloops.nu)                         | openapi | <https://api.apis.guru/v2/specs/surrey.ca/trafficloops/0.1/swagger.json>                    |
| [tfl](clients/public-data/tfl.nu)                                                         | openapi | <https://api.tfl.gov.uk/swagger/docs/v1>                                                    |
| [thenounproject](clients/public-data/thenounproject.nu)                                   | openapi | <https://api.apis.guru/v2/specs/thenounproject.com/1.0.0/swagger.json>                      |
| [tinyuid](clients/public-data/tinyuid.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/tinyuid.com/1.0.0/swagger.json>                             |
| [transavia](clients/public-data/transavia.nu)                                             | openapi | <https://api.apis.guru/v2/specs/transavia.com/1.0/swagger.json>                             |
| [uk-vehicle-enquiry](clients/public-data/uk-vehicle-enquiry.nu)                           | openapi | <https://api.apis.guru/v2/specs/api.gov.uk/vehicle-enquiry/1.1.0/openapi.json>              |
| [uk-water-quality](clients/public-data/uk-water-quality.nu)                               | openapi | <https://environment.data.gov.uk/water-quality/openapi.json>                                |
| [unicourt](clients/public-data/unicourt.nu)                                               | openapi | <https://api.apis.guru/v2/specs/unicourt.com/1.0.0/openapi.json>                            |
| [uscann](clients/public-data/uscann.nu)                                                   | openapi | <https://api.apis.guru/v2/specs/uscann.net/1.0/swagger.json>                                |
| [uspto-bdss](clients/public-data/uspto-bdss.nu)                                           | openapi | <https://api.apis.guru/v2/specs/uspto.gov/bdss/1.0.0/swagger.json>                          |
| [va-facilities](clients/public-data/va-facilities.nu)                                     | openapi | <https://api.apis.guru/v2/specs/va.gov/facilities/0.0.1/openapi.json>                       |
| [vatapi-apisguru](clients/public-data/vatapi-apisguru.nu)                                 | openapi | <https://api.apis.guru/v2/specs/vatapi.com/1/swagger.json>                                  |
| [warwick-enterobase](clients/public-data/warwick-enterobase.nu)                           | openapi | <https://api.apis.guru/v2/specs/warwick.ac.uk/enterobase/v2.0/openapi.json>                 |
| [weber-gesamtausgabe](clients/public-data/weber-gesamtausgabe.nu)                         | openapi | <https://api.apis.guru/v2/specs/weber-gesamtausgabe.de/1.0.0/swagger.json>                  |
| [wikidata-rest](clients/public-data/wikidata-rest.nu)                                     | openapi | <https://www.wikidata.org/api/rest_v1/?spec>                                                |
| [wikimedia](clients/public-data/wikimedia.nu)                                             | openapi | <https://api.apis.guru/v2/specs/wikimedia.org/1.0.0/swagger.json>                           |
| [wikipathways](clients/public-data/wikipathways.nu)                                       | openapi | <https://api.apis.guru/v2/specs/wikipathways.org/1.0/openapi.json>                          |
| [wikipedia](clients/public-data/wikipedia.nu)                                             | openapi | <https://en.wikipedia.org/api/rest_v1/?spec>                                                |
| [wiktionary](clients/public-data/wiktionary.nu)                                           | openapi | <https://en.wiktionary.org/api/rest_v1/?spec>                                               |
| [wmata-bus-realtime](clients/public-data/wmata-bus-realtime.nu)                           | openapi | <https://api.apis.guru/v2/specs/wmata.com/bus-realtime/1.0/swagger.json>                    |
| [wmata-bus-route](clients/public-data/wmata-bus-route.nu)                                 | openapi | <https://api.apis.guru/v2/specs/wmata.com/bus-route/1.0/swagger.json>                       |
| [wmata-incidents](clients/public-data/wmata-incidents.nu)                                 | openapi | <https://api.apis.guru/v2/specs/wmata.com/incidents/1.0/swagger.json>                       |
| [wmata-rail-realtime](clients/public-data/wmata-rail-realtime.nu)                         | openapi | <https://api.apis.guru/v2/specs/wmata.com/rail-realtime/1.0/swagger.json>                   |
| [wmata-rail-station](clients/public-data/wmata-rail-station.nu)                           | openapi | <https://api.apis.guru/v2/specs/wmata.com/rail-station/1.0/swagger.json>                    |
| [wolframalpha](clients/public-data/wolframalpha.nu)                                       | openapi | <https://api.apis.guru/v2/specs/wolframalpha.com/v0.1/openapi.json>                         |
| [wordassociations](clients/public-data/wordassociations.nu)                               | openapi | <https://api.apis.guru/v2/specs/wordassociations.net/1.0/swagger.json>                      |
| [wordnik](clients/public-data/wordnik.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/wordnik.com/4.0/openapi.json>                               |
| [worldtimeapi](clients/public-data/worldtimeapi.nu)                                       | openapi | <https://api.apis.guru/v2/specs/worldtimeapi.org/20210108/openapi.json>                     |
| [zappiti](clients/public-data/zappiti.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/zappiti.com/4.15.174/swagger.json>                          |

### sandbox

| Client                                                    | Type    | Source                                                                                           |
| --------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------ |
| [catfact](clients/sandbox/catfact.nu)                     | openapi | <https://catfact.ninja/docs>                                                                     |
| [ergast-f1](clients/sandbox/ergast-f1.nu)                 | openapi | <https://raw.githubusercontent.com/adampax/ergast-f1-openapi-doc/master/ergast-openapi-doc.yaml> |
| [getsandbox](clients/sandbox/getsandbox.nu)               | openapi | <https://api.apis.guru/v2/specs/getsandbox.com/v1/swagger.json>                                  |
| [groundhog-day](clients/sandbox/groundhog-day.nu)         | openapi | <https://api.apis.guru/v2/specs/groundhog-day.com/1.2.1/openapi.json>                            |
| [hackathonwatch](clients/sandbox/hackathonwatch.nu)       | openapi | <https://api.apis.guru/v2/specs/hackathonwatch.com/0.1/openapi.json>                             |
| [httpbin-apisguru](clients/sandbox/httpbin-apisguru.nu)   | openapi | <https://api.apis.guru/v2/specs/httpbin.org/0.9.2/openapi.json>                                  |
| [jsonplaceholder](clients/sandbox/jsonplaceholder.nu)     | openapi | <https://raw.githubusercontent.com/sebastienlevert/jsonplaceholder-api/main/openapi.yaml>        |
| [openapi-space](clients/sandbox/openapi-space.nu)         | openapi | <https://api.apis.guru/v2/specs/openapi.space/1.0.0/swagger.json>                                |
| [petstore](clients/sandbox/petstore.nu)                   | openapi | <https://petstore3.swagger.io/api/v3/openapi.json>                                               |
| [postman-spec](clients/sandbox/postman-spec.nu)           | openapi | <https://api.apis.guru/v2/specs/getpostman.com/1.20.0/openapi.json>                              |
| [presalytics-story](clients/sandbox/presalytics-story.nu) | openapi | <https://api.apis.guru/v2/specs/presalytics.io/story/0.3.1/openapi.json>                         |
| [proxykingdom](clients/sandbox/proxykingdom.nu)           | openapi | <https://api.apis.guru/v2/specs/proxykingdom.com/v1/openapi.json>                                |
| [randomlovecraft](clients/sandbox/randomlovecraft.nu)     | openapi | <https://api.apis.guru/v2/specs/randomlovecraft.com/1.0/openapi.json>                            |
| [randommer](clients/sandbox/randommer.nu)                 | openapi | <https://api.apis.guru/v2/specs/randommer.io/v1/openapi.json>                                    |
| [realworld-conduit](clients/sandbox/realworld-conduit.nu) | openapi | <https://raw.githubusercontent.com/realworld-apps/realworld/main/specs/api/openapi.yml>          |
| [reqres](clients/sandbox/reqres.nu)                       | openapi | <https://reqres.in/openapi.json>                                                                 |
| [restful-booker](clients/sandbox/restful-booker.nu)       | openapi | <https://raw.githubusercontent.com/texttest/restful-booker/with_texttests/swagger.json>          |
| [restful4up](clients/sandbox/restful4up.nu)               | openapi | <https://api.apis.guru/v2/specs/restful4up.local/1.0.0/openapi.json>                             |
| [spaceflight-news](clients/sandbox/spaceflight-news.nu)   | openapi | <https://api.spaceflightnewsapi.net/v4/schema/>                                                  |
| [train-travel](clients/sandbox/train-travel.nu)           | openapi | <https://raw.githubusercontent.com/bump-sh-examples/train-travel-api/main/openapi.yaml>          |
| [urlbox](clients/sandbox/urlbox.nu)                       | openapi | <https://api.apis.guru/v2/specs/urlbox.io/v1/openapi.json>                                       |
| [watchful](clients/sandbox/watchful.nu)                   | openapi | <https://api.apis.guru/v2/specs/watchful.li/1.0.0/swagger.json>                                  |
| [wheretocredit](clients/sandbox/wheretocredit.nu)         | openapi | <https://api.apis.guru/v2/specs/wheretocredit.com/1.0/openapi.json>                              |
| [who-hosts-this](clients/sandbox/who-hosts-this.nu)       | openapi | <https://api.apis.guru/v2/specs/who-hosts-this.com/0.0.1/swagger.json>                           |

### sci-fi

| Client                                                             | Type    | Source                                                                                                                                            |
| ------------------------------------------------------------------ | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| [dnd5e](clients/sci-fi/dnd5e.nu)                                   | openapi | <https://api.apis.guru/v2/specs/dnd5eapi.co/0.1/openapi.json>                                                                                     |
| [dnd5e-graphql](clients/sci-fi/dnd5e-graphql.nu)                   | graphql | <https://www.dnd5eapi.co/graphql/2014>                                                                                                            |
| [etmdb](clients/sci-fi/etmdb.nu)                                   | openapi | <https://api.apis.guru/v2/specs/etmdb.com/1.0.0/openapi.json>                                                                                     |
| [futurama](clients/sci-fi/futurama.nu)                             | openapi | <https://futuramaapi.com/openapi.json>                                                                                                            |
| [hydramovies](clients/sci-fi/hydramovies.nu)                       | openapi | <https://api.apis.guru/v2/specs/hydramovies.com/1.1/swagger.json>                                                                                 |
| [marvel](clients/sci-fi/marvel.nu)                                 | openapi | <https://gist.githubusercontent.com/wing328/30692487826e07962ae487dbb63a2fa1/raw/03e47f54adbef78800e128bb6b5e4c2aa9683972/marvel.openapi.v2.json> |
| [omdbapi](clients/sci-fi/omdbapi.nu)                               | openapi | <https://api.apis.guru/v2/specs/omdbapi.com/1/swagger.json>                                                                                       |
| [overfast](clients/sci-fi/overfast.nu)                             | openapi | <https://overfast-api.tekrop.fr/openapi.json>                                                                                                     |
| [potterdb](clients/sci-fi/potterdb.nu)                             | graphql | <https://api.potterdb.com/graphql>                                                                                                                |
| [rottentomatoes](clients/sci-fi/rottentomatoes.nu)                 | openapi | <https://api.apis.guru/v2/specs/rottentomatoes.com/1.0/swagger.json>                                                                              |
| [scryfall](clients/sci-fi/scryfall.nu)                             | openapi | <https://raw.githubusercontent.com/jdharmon/scryfallapi/master/swagger.yaml>                                                                      |
| [stapi](clients/sci-fi/stapi.nu)                                   | openapi | <https://stapi.co/api/v1/rest/common/download/stapi.yaml>                                                                                         |
| [starwars-translations](clients/sci-fi/starwars-translations.nu)   | openapi | <https://api.apis.guru/v2/specs/funtranslations.com/starwars/2.3/swagger.json>                                                                    |
| [streaming-availability](clients/sci-fi/streaming-availability.nu) | openapi | <https://raw.githubusercontent.com/movieofthenight/streaming-availability-api/main/openapi.yaml>                                                  |
| [swapi](clients/sci-fi/swapi.nu)                                   | graphql | <https://swapi-graphql.netlify.app/graphql>                                                                                                       |
| [tcgdex](clients/sci-fi/tcgdex.nu)                                 | openapi | <https://api.apis.guru/v2/specs/tcgdex.net/2.0.0/openapi.json>                                                                                    |
| [thebluealliance](clients/sci-fi/thebluealliance.nu)               | openapi | <https://api.apis.guru/v2/specs/thebluealliance.com/3.8.2/openapi.json>                                                                           |
| [thetvdb](clients/sci-fi/thetvdb.nu)                               | openapi | <https://api.apis.guru/v2/specs/thetvdb.com/3.0.0/swagger.json>                                                                                   |
| [thronesapi](clients/sci-fi/thronesapi.nu)                         | openapi | <https://thronesapi.com/swagger/v1/swagger.json>                                                                                                  |
| [tibiadata](clients/sci-fi/tibiadata.nu)                           | openapi | <https://docs.tibiadata.com/swagger.json>                                                                                                         |
| [tmdb](clients/sci-fi/tmdb.nu)                                     | openapi | <https://raw.githubusercontent.com/ckatle/oas-tmdb/master/openapi.yml>                                                                            |
| [trakt-tv](clients/sci-fi/trakt-tv.nu)                             | openapi | <https://api.apis.guru/v2/specs/trakt.tv/1.0.0/openapi.json>                                                                                      |
| [tvmaze](clients/sci-fi/tvmaze.nu)                                 | openapi | <https://api.apis.guru/v2/specs/tvmaze.com/1.0/openapi.json>                                                                                      |
| [wizard-world](clients/sci-fi/wizard-world.nu)                     | openapi | <https://wizard-world-api.herokuapp.com/swagger/v1/swagger.json>                                                                                  |
| [xivapi](clients/sci-fi/xivapi.nu)                                 | openapi | <https://v2.xivapi.com/api/openapi.json>                                                                                                          |
| [xkcd](clients/sci-fi/xkcd.nu)                                     | openapi | <https://api.apis.guru/v2/specs/xkcd.com/1.0.0/openapi.json>                                                                                      |

### search

| Client                                                                   | Type    | Source                                                                                                                                            |
| ------------------------------------------------------------------------ | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| [algolia](clients/search/algolia.nu)                                     | openapi | <https://raw.githubusercontent.com/algolia/api-clients-automation/main/specs/bundled/search.yml>                                                  |
| [asuarez-searchly](clients/search/asuarez-searchly.nu)                   | openapi | <https://api.apis.guru/v2/specs/asuarez.dev/searchly/1.0/openapi.json>                                                                            |
| [aws-cloudsearch](clients/search/aws-cloudsearch.nu)                     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/cloudsearch/2013-01-01/openapi.json>                                                                |
| [aws-cloudsearchdomain](clients/search/aws-cloudsearchdomain.nu)         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/cloudsearchdomain/2013-01-01/openapi.json>                                                          |
| [aws-kendra](clients/search/aws-kendra.nu)                               | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/kendra/2019-02-03/openapi.json>                                                                     |
| [azure-search](clients/search/azure-search.nu)                           | openapi | <https://api.apis.guru/v2/specs/azure.com/search/2015-08-19/swagger.json>                                                                         |
| [azure-search-index](clients/search/azure-search-index.nu)               | openapi | <https://api.apis.guru/v2/specs/azure.com/search-searchindex/2019-05-06-Preview/swagger.json>                                                     |
| [azure-search-service](clients/search/azure-search-service.nu)           | openapi | <https://api.apis.guru/v2/specs/azure.com/search-searchservice/2019-05-06-Preview/swagger.json>                                                   |
| [coveo](clients/search/coveo.nu)                                         | openapi | <https://raw.githubusercontent.com/watson-developer-cloud/assistant-toolkit/master/integrations/extensions/starter-kits/coveo/coveo.openapi.json> |
| [customsearch-google](clients/search/customsearch-google.nu)             | openapi | <https://api.apis.guru/v2/specs/googleapis.com/customsearch/v1/openapi.json>                                                                      |
| [elastic-app-search](clients/search/elastic-app-search.nu)               | openapi | <https://raw.githubusercontent.com/elastic/app-search-php/master/resources/api/api-spec.yml>                                                      |
| [elasticsearch](clients/search/elasticsearch.nu)                         | openapi | <https://raw.githubusercontent.com/elastic/elasticsearch-specification/main/output/openapi/elasticsearch-openapi.json>                            |
| [importio-data](clients/search/importio-data.nu)                         | openapi | <https://api.apis.guru/v2/specs/import.io/data/1.0/swagger.json>                                                                                  |
| [importio-extraction](clients/search/importio-extraction.nu)             | openapi | <https://api.apis.guru/v2/specs/import.io/extraction/1.0/swagger.json>                                                                            |
| [importio-rss](clients/search/importio-rss.nu)                           | openapi | <https://api.apis.guru/v2/specs/import.io/rss/1.0/swagger.json>                                                                                   |
| [importio-run](clients/search/importio-run.nu)                           | openapi | <https://api.apis.guru/v2/specs/import.io/run/1.0/swagger.json>                                                                                   |
| [importio-schedule](clients/search/importio-schedule.nu)                 | openapi | <https://api.apis.guru/v2/specs/import.io/schedule/1.0/swagger.json>                                                                              |
| [kagi](clients/search/kagi.nu)                                           | openapi | <https://kagi.com/api/docs/_spec/openapi.yaml>                                                                                                    |
| [manticore](clients/search/manticore.nu)                                 | openapi | <https://raw.githubusercontent.com/manticoresoftware/manticoresearch-go/master/api/openapi.yaml>                                                  |
| [meilisearch](clients/search/meilisearch.nu)                             | openapi | <https://raw.githubusercontent.com/meilisearch/specifications/main/open-api.yaml>                                                                 |
| [meilisearch-apisguru](clients/search/meilisearch-apisguru.nu)           | openapi | <https://api.apis.guru/v2/specs/meilisearch.com/1.0.0/openapi.json>                                                                               |
| [ms-bing-customimagesearch](clients/search/ms-bing-customimagesearch.nu) | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-CustomImageSearch/1.0/swagger.json>                                               |
| [ms-bing-customsearch](clients/search/ms-bing-customsearch.nu)           | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-CustomSearch/1.0/swagger.json>                                                    |
| [ms-bing-entitysearch](clients/search/ms-bing-entitysearch.nu)           | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-EntitySearch/1.0/swagger.json>                                                    |
| [ms-bing-imagesearch](clients/search/ms-bing-imagesearch.nu)             | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-ImageSearch/1.0/swagger.json>                                                     |
| [ms-bing-localsearch](clients/search/ms-bing-localsearch.nu)             | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-LocalSearch/1.0/swagger.json>                                                     |
| [ms-bing-spellcheck](clients/search/ms-bing-spellcheck.nu)               | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-SpellCheck/1.0/swagger.json>                                                      |
| [ms-bing-videosearch](clients/search/ms-bing-videosearch.nu)             | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-VideoSearch/1.0/swagger.json>                                                     |
| [ms-bing-visualsearch](clients/search/ms-bing-visualsearch.nu)           | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-VisualSearch/1.0/swagger.json>                                                    |
| [ms-bing-websearch](clients/search/ms-bing-websearch.nu)                 | openapi | <https://api.apis.guru/v2/specs/microsoft.com/cognitiveservices-WebSearch/1.0/swagger.json>                                                       |
| [openindex](clients/search/openindex.nu)                                 | openapi | <https://api.apis.guru/v2/specs/openindex.ai/1.0.0/openapi.json>                                                                                  |
| [opensearch](clients/search/opensearch.nu)                               | openapi | <https://github.com/opensearch-project/opensearch-api-specification/releases/latest/download/opensearch-openapi.yaml>                             |
| [openserp](clients/search/openserp.nu)                                   | openapi | <https://raw.githubusercontent.com/karust/openserp/main/docs/openapi.yaml>                                                                        |
| [qdrant](clients/search/qdrant.nu)                                       | openapi | <https://raw.githubusercontent.com/qdrant/qdrant/master/docs/redoc/master/openapi.json>                                                           |
| [swiftype](clients/search/swiftype.nu)                                   | openapi | <https://raw.githubusercontent.com/swiftype/swiftype-site-search-php/master/resources/api/api-spec.yml>                                           |
| [typesense](clients/search/typesense.nu)                                 | openapi | <https://raw.githubusercontent.com/typesense/typesense-api-spec/master/openapi.yml>                                                               |
| [weaviate](clients/search/weaviate.nu)                                   | openapi | <https://raw.githubusercontent.com/weaviate/weaviate/main/openapi-specs/schema.json>                                                              |
| [yext-answers](clients/search/yext-answers.nu)                           | openapi | <https://raw.githubusercontent.com/yext/openapi/main/yaml/answersapi.yaml>                                                                        |
| [you-com](clients/search/you-com.nu)                                     | openapi | <https://api.you.com/openapi.json>                                                                                                                |

### shipping

| Client                                                                             | Type    | Source                                                                                                                                            |
| ---------------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| [aftership-tracking](clients/shipping/aftership-tracking.nu)                       | openapi | <https://stoplight.io/api/v1/projects/automizely/docs-api-aftership-com/nodes/reference/api.json?branch=production/2026-01&deref=optimizedBundle> |
| [arcbest](clients/shipping/arcbest.nu)                                             | openapi | <https://raw.githubusercontent.com/api-evangelist/arcbest/main/openapi/arcbest-api.yaml>                                                          |
| [clickpost](clients/shipping/clickpost.nu)                                         | openapi | <https://raw.githubusercontent.com/api-evangelist/clickpost/main/openapi/clickpost-openapi.yml>                                                   |
| [dhl](clients/shipping/dhl.nu)                                                     | openapi | <https://raw.githubusercontent.com/api-evangelist/dhl/main/openapi/dhl-openapi.yml>                                                               |
| [easypost](clients/shipping/easypost.nu)                                           | openapi | <https://raw.githubusercontent.com/api-evangelist/easypost/main/openapi/easypost-openapi.yml>                                                     |
| [easyship](clients/shipping/easyship.nu)                                           | openapi | <https://raw.githubusercontent.com/api-evangelist/easyship/main/openapi/easyship-openapi.yml>                                                     |
| [ebay-logistics](clients/shipping/ebay-logistics.nu)                               | openapi | <https://api.apis.guru/v2/specs/ebay.com/sell-logistics/v1_beta.0.0/openapi.json>                                                                 |
| [fedex](clients/shipping/fedex.nu)                                                 | openapi | <https://raw.githubusercontent.com/api-evangelist/fedex/main/openapi/fedex-openapi.yml>                                                           |
| [flexport](clients/shipping/flexport.nu)                                           | openapi | <https://raw.githubusercontent.com/api-evangelist/flexport/main/openapi/flexport-openapi.yml>                                                     |
| [forto](clients/shipping/forto.nu)                                                 | openapi | <https://raw.githubusercontent.com/api-evangelist/forto/main/openapi/forto-openapi.yml>                                                           |
| [fulfillment-com](clients/shipping/fulfillment-com.nu)                             | openapi | <https://api.apis.guru/v2/specs/fulfillment.com/2.0/openapi.json>                                                                                 |
| [furkot](clients/shipping/furkot.nu)                                               | openapi | <https://api.apis.guru/v2/specs/furkot.com/1.0.0/swagger.json>                                                                                    |
| [google-travelimpactmodel](clients/shipping/google-travelimpactmodel.nu)           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/travelimpactmodel/v1/openapi.json>                                                                 |
| [gsmtasks](clients/shipping/gsmtasks.nu)                                           | openapi | <https://api.apis.guru/v2/specs/gsmtasks.com/2.4.13/openapi.json>                                                                                 |
| [karrio](clients/shipping/karrio.nu)                                               | openapi | <https://raw.githubusercontent.com/karrioapi/karrio/main/schemas/openapi.yml>                                                                     |
| [loadsmart-opendock](clients/shipping/loadsmart-opendock.nu)                       | openapi | <https://raw.githubusercontent.com/api-evangelist/loadsmart/main/openapi/loadsmart-opendock-openapi.yml>                                          |
| [loadsmart-shipperguide](clients/shipping/loadsmart-shipperguide.nu)               | openapi | <https://raw.githubusercontent.com/api-evangelist/loadsmart/main/openapi/loadsmart-shipperguide-openapi.yml>                                      |
| [maersk-track-and-trace](clients/shipping/maersk-track-and-trace.nu)               | openapi | <https://raw.githubusercontent.com/api-evangelist/maersk-line/main/openapi/maersk-track-and-trace-api-openapi.yml>                                |
| [marinetraffic](clients/shipping/marinetraffic.nu)                                 | openapi | <https://raw.githubusercontent.com/api-evangelist/marinetraffic/main/openapi/marinetraffic-ais-openapi.yml>                                       |
| [norfolk-southern-shipment](clients/shipping/norfolk-southern-shipment.nu)         | openapi | <https://raw.githubusercontent.com/api-evangelist/norfolk-southern/main/openapi/norfolk-southern-shipment-status-api.yml>                         |
| [old-dominion-freight-tracking](clients/shipping/old-dominion-freight-tracking.nu) | openapi | <https://raw.githubusercontent.com/api-evangelist/old-dominion-freight-line/main/openapi/old-dominion-freight-line-tracking-api-openapi.yml>      |
| [onfleet-tasks](clients/shipping/onfleet-tasks.nu)                                 | openapi | <https://raw.githubusercontent.com/api-evangelist/onfleet/main/openapi/onfleet-tasks-api-openapi.yml>                                             |
| [paccurate](clients/shipping/paccurate.nu)                                         | openapi | <https://api.apis.guru/v2/specs/paccurate.io/0.1.1/swagger.json>                                                                                  |
| [parcellab](clients/shipping/parcellab.nu)                                         | openapi | <https://raw.githubusercontent.com/api-evangelist/parcellab/main/openapi/parcellab-openapi.yml>                                                   |
| [pitney-bowes](clients/shipping/pitney-bowes.nu)                                   | openapi | <https://raw.githubusercontent.com/api-evangelist/pitney-bowes/main/openapi/pitney-bowes-openapi.yml>                                             |
| [project44-tracking](clients/shipping/project44-tracking.nu)                       | openapi | <https://raw.githubusercontent.com/api-evangelist/project44/main/openapi/project44-tracking-openapi.yml>                                          |
| [routific](clients/shipping/routific.nu)                                           | openapi | <https://raw.githubusercontent.com/api-evangelist/routific/main/openapi/routific-route-optimization-api-openapi.yml>                              |
| [royalmail-click-and-drop](clients/shipping/royalmail-click-and-drop.nu)           | openapi | <https://api.apis.guru/v2/specs/royalmail.com/click-and-drop/1.0.0/swagger.json>                                                                  |
| [sendle-orders](clients/shipping/sendle-orders.nu)                                 | openapi | <https://raw.githubusercontent.com/api-evangelist/sendle/main/openapi/sendle-orders-api-openapi.yml>                                              |
| [ship24](clients/shipping/ship24.nu)                                               | openapi | <https://raw.githubusercontent.com/api-evangelist/ship24/main/openapi/ship24-tracking-api-openapi.yml>                                            |
| [shipbob](clients/shipping/shipbob.nu)                                             | openapi | <https://raw.githubusercontent.com/api-evangelist/shipbob/main/openapi/shipbob-openapi.json>                                                      |
| [shipengine](clients/shipping/shipengine.nu)                                       | openapi | <https://raw.githubusercontent.com/ShipEngine/shipengine-openapi/master/openapi.yaml>                                                             |
| [shipengine-apisguru](clients/shipping/shipengine-apisguru.nu)                     | openapi | <https://api.apis.guru/v2/specs/shipengine.com/1.1.202303022103/openapi.json>                                                                     |
| [shippingeasy](clients/shipping/shippingeasy.nu)                                   | openapi | <https://raw.githubusercontent.com/api-evangelist/shippingeasy/main/openapi/shippingeasy-customer-api-openapi.yml>                                |
| [shippo](clients/shipping/shippo.nu)                                               | openapi | <https://docs.goshippo.com/spec/shippoapi/public-api.yaml>                                                                                        |
| [shipstation](clients/shipping/shipstation.nu)                                     | openapi | <https://api.apis.guru/v2/specs/shipstation.com/1.0.0/openapi.json>                                                                               |
| [track-pod](clients/shipping/track-pod.nu)                                         | openapi | <https://raw.githubusercontent.com/api-evangelist/track-pod/main/openapi/track-pod-openapi.yml>                                                   |
| [uber-direct](clients/shipping/uber-direct.nu)                                     | openapi | <https://raw.githubusercontent.com/api-evangelist/uber-direct/main/openapi/uber-direct-openapi.yml>                                               |
| [ups-address-validation](clients/shipping/ups-address-validation.nu)               | openapi | <https://raw.githubusercontent.com/UPS-API/api-documentation/main/AddressValidation.yaml>                                                         |
| [ups-locator](clients/shipping/ups-locator.nu)                                     | openapi | <https://raw.githubusercontent.com/UPS-API/api-documentation/main/Locator.yaml>                                                                   |
| [ups-paperless](clients/shipping/ups-paperless.nu)                                 | openapi | <https://raw.githubusercontent.com/UPS-API/api-documentation/main/Paperless.yaml>                                                                 |
| [ups-pickup](clients/shipping/ups-pickup.nu)                                       | openapi | <https://raw.githubusercontent.com/UPS-API/api-documentation/main/Pickup.yaml>                                                                    |
| [ups-prenotification](clients/shipping/ups-prenotification.nu)                     | openapi | <https://raw.githubusercontent.com/UPS-API/api-documentation/main/PreNotification.yaml>                                                           |
| [ups-rating](clients/shipping/ups-rating.nu)                                       | openapi | <https://raw.githubusercontent.com/UPS-API/api-documentation/main/Rating.yaml>                                                                    |
| [ups-shipping](clients/shipping/ups-shipping.nu)                                   | openapi | <https://raw.githubusercontent.com/UPS-API/api-documentation/main/Shipping.yaml>                                                                  |
| [ups-tracking](clients/shipping/ups-tracking.nu)                                   | openapi | <https://raw.githubusercontent.com/UPS-API/api-documentation/main/Tracking.yaml>                                                                  |
| [vizion](clients/shipping/vizion.nu)                                               | openapi | <https://raw.githubusercontent.com/api-evangelist/vizion/main/openapi/vizion-container-tracking-openapi.yml>                                      |
| [vtex-logistics](clients/shipping/vtex-logistics.nu)                               | openapi | <https://api.apis.guru/v2/specs/vtex.local/Logistics-API/1.0/openapi.json>                                                                        |

### social

| Client                                                     | Type    | Source                                                                                           |
| ---------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------ |
| [daniweb](clients/social/daniweb.nu)                       | openapi | <https://api.apis.guru/v2/specs/daniweb.com/4/openapi.json>                                      |
| [dev-to](clients/social/dev-to.nu)                         | openapi | <https://api.apis.guru/v2/specs/dev.to/1.0.0/openapi.json>                                       |
| [discourse](clients/social/discourse.nu)                   | openapi | <https://raw.githubusercontent.com/discourse/discourse_api_docs/main/openapi.json>               |
| [discourse-apisguru](clients/social/discourse-apisguru.nu) | openapi | <https://api.apis.guru/v2/specs/discourse.local/latest/openapi.json>                             |
| [forem](clients/social/forem.nu)                           | openapi | <https://raw.githubusercontent.com/forem/forem/main/swagger/v1/api_v1.json>                      |
| [google-blogger](clients/social/google-blogger.nu)         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/blogger/v3/openapi.json>                          |
| [google-people](clients/social/google-people.nu)           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/people/v1/openapi.json>                           |
| [gotosocial](clients/social/gotosocial.nu)                 | openapi | <https://docs.gotosocial.org/en/latest/api/swagger.yaml>                                         |
| [instagram](clients/social/instagram.nu)                   | openapi | <https://api.apis.guru/v2/specs/instagram.com/1.0.0/swagger.json>                                |
| [lemmy](clients/social/lemmy.nu)                           | openapi | <https://raw.githubusercontent.com/MV-GH/lemmy_openapi_spec/master/lemmy_spec.yaml>              |
| [mastodon](clients/social/mastodon.nu)                     | openapi | <https://api.apis.guru/v2/specs/mastodon.local/1.0/openapi.json>                                 |
| [medium](clients/social/medium.nu)                         | openapi | <https://api.apis.guru/v2/specs/medium.com/1.0/openapi.json>                                     |
| [misskey](clients/social/misskey.nu)                       | openapi | <https://misskey.io/api.json>                                                                    |
| [orbit-love](clients/social/orbit-love.nu)                 | openapi | <https://api.apis.guru/v2/specs/orbit.love/v1/openapi.json>                                      |
| [peertube](clients/social/peertube.nu)                     | openapi | <https://raw.githubusercontent.com/Chocobozzz/PeerTube/develop/support/doc/api/openapi.yaml>     |
| [stackexchange](clients/social/stackexchange.nu)           | openapi | <https://api.apis.guru/v2/specs/stackexchange.com/2.0/openapi.json>                              |
| [trashnothing](clients/social/trashnothing.nu)             | openapi | <https://api.apis.guru/v2/specs/trashnothing.com/1.3/openapi.json>                               |
| [twitter](clients/social/twitter.nu)                       | openapi | <https://raw.githubusercontent.com/fa0311/twitter-openapi/main/dist/compatible/openapi-3.0.yaml> |
| [twitter-current](clients/social/twitter-current.nu)       | openapi | <https://api.apis.guru/v2/specs/twitter.com/current/2.61/openapi.json>                           |
| [twitter-legacy](clients/social/twitter-legacy.nu)         | openapi | <https://api.apis.guru/v2/specs/twitter.com/legacy/1.1/swagger.json>                             |

### sports

| Client                                                                 | Type    | Source                                                                                                  |
| ---------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------- |
| [balldontlie](clients/sports/balldontlie.nu)                           | openapi | <https://api.apis.guru/v2/specs/balldontlie.io/1.0.0/openapi.json>                                      |
| [collegefootballdata](clients/sports/collegefootballdata.nu)           | openapi | <https://api.apis.guru/v2/specs/collegefootballdata.com/4.4.12/openapi.json>                            |
| [fitbit](clients/sports/fitbit.nu)                                     | openapi | <https://raw.githubusercontent.com/allenporter/fitbit-web-api/main/openapi/fitbit-web-api-openapi.json> |
| [football-prediction](clients/sports/football-prediction.nu)           | openapi | <https://api.apis.guru/v2/specs/rapidapi.com/football-prediction/2/openapi.json>                        |
| [sportsdata-cbb-scores](clients/sports/sportsdata-cbb-scores.nu)       | openapi | <https://api.apis.guru/v2/specs/sportsdata.io/cbb-v3-scores/1.0/openapi.json>                           |
| [sportsdata-cfb-scores](clients/sports/sportsdata-cfb-scores.nu)       | openapi | <https://api.apis.guru/v2/specs/sportsdata.io/cfb-v3-scores/1.0/openapi.json>                           |
| [sportsdata-golf](clients/sports/sportsdata-golf.nu)                   | openapi | <https://api.apis.guru/v2/specs/sportsdata.io/golf-v2/1.0/openapi.json>                                 |
| [sportsdata-mlb-scores](clients/sports/sportsdata-mlb-scores.nu)       | openapi | <https://api.apis.guru/v2/specs/sportsdata.io/mlb-v3-scores/1.0/openapi.json>                           |
| [sportsdata-nascar](clients/sports/sportsdata-nascar.nu)               | openapi | <https://api.apis.guru/v2/specs/sportsdata.io/nascar-v2/1.0/openapi.json>                               |
| [sportsdata-nba-scores](clients/sports/sportsdata-nba-scores.nu)       | openapi | <https://api.apis.guru/v2/specs/sportsdata.io/nba-v3-scores/1.0/openapi.json>                           |
| [sportsdata-nfl-scores](clients/sports/sportsdata-nfl-scores.nu)       | openapi | <https://api.apis.guru/v2/specs/sportsdata.io/nfl-v3-scores/1.0/openapi.json>                           |
| [sportsdata-nhl-scores](clients/sports/sportsdata-nhl-scores.nu)       | openapi | <https://api.apis.guru/v2/specs/sportsdata.io/nhl-v3-scores/1.0/openapi.json>                           |
| [sportsdata-soccer-scores](clients/sports/sportsdata-soccer-scores.nu) | openapi | <https://api.apis.guru/v2/specs/sportsdata.io/soccer-v3-scores/1.0/openapi.json>                        |
| [strava](clients/sports/strava.nu)                                     | openapi | <https://developers.strava.com/swagger/swagger.json>                                                    |
| [whapi-sportsdata](clients/sports/whapi-sportsdata.nu)                 | openapi | <https://api.apis.guru/v2/specs/whapi.com/sportsdata/2/swagger.json>                                    |

### storage

| Client                                                                | Type    | Source                                                                                   |
| --------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------- |
| [apideck-file-storage](clients/storage/apideck-file-storage.nu)       | openapi | <https://api.apis.guru/v2/specs/apideck.com/file-storage/9.3.0/openapi.json>             |
| [aws-backup](clients/storage/aws-backup.nu)                           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/backup/2018-11-15/openapi.json>            |
| [aws-fsx](clients/storage/aws-fsx.nu)                                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/fsx/2018-03-01/openapi.json>               |
| [aws-s3-control](clients/storage/aws-s3-control.nu)                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/s3control/2018-08-20/openapi.json>         |
| [aws-workdocs](clients/storage/aws-workdocs.nu)                       | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/workdocs/2016-05-01/openapi.json>          |
| [azure-blob](clients/storage/azure-blob.nu)                           | openapi | <https://api.apis.guru/v2/specs/azure.com/storage-blob/2019-04-01/swagger.json>          |
| [azure-file](clients/storage/azure-file.nu)                           | openapi | <https://api.apis.guru/v2/specs/azure.com/storage-file/2019-06-01/swagger.json>          |
| [box](clients/storage/box.nu)                                         | openapi | <https://raw.githubusercontent.com/box/box-openapi/main/openapi.json>                    |
| [doqs](clients/storage/doqs.nu)                                       | openapi | <https://api.apis.guru/v2/specs/doqs.dev/1.0/openapi.json>                               |
| [dracoon](clients/storage/dracoon.nu)                                 | openapi | <https://api.apis.guru/v2/specs/dracoon.team/4.42.2/openapi.json>                        |
| [efs](clients/storage/efs.nu)                                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/elasticfilesystem/2015-02-01/openapi.json> |
| [exavault](clients/storage/exavault.nu)                               | openapi | <https://api.apis.guru/v2/specs/exavault.com/2.0/openapi.json>                           |
| [files-com](clients/storage/files-com.nu)                             | openapi | <https://api.apis.guru/v2/specs/files.com/0.0.1/openapi.json>                            |
| [gcs](clients/storage/gcs.nu)                                         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/storage/v1/openapi.yaml>                  |
| [glacier](clients/storage/glacier.nu)                                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/glacier/2012-06-01/openapi.json>           |
| [google-drive](clients/storage/google-drive.nu)                       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/drive/v3/openapi.json>                    |
| [google-driveactivity](clients/storage/google-driveactivity.nu)       | openapi | <https://api.apis.guru/v2/specs/googleapis.com/driveactivity/v2/openapi.json>            |
| [google-drivelabels](clients/storage/google-drivelabels.nu)           | openapi | <https://api.apis.guru/v2/specs/googleapis.com/drivelabels/v2beta/openapi.json>          |
| [google-file](clients/storage/google-file.nu)                         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/file/v1/openapi.json>                     |
| [google-firebase-storage](clients/storage/google-firebase-storage.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/firebasestorage/v1beta/openapi.json>      |
| [google-storagetransfer](clients/storage/google-storagetransfer.nu)   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/storagetransfer/v1/openapi.json>          |
| [googledrive](clients/storage/googledrive.nu)                         | openapi | <https://api.apis.guru/v2/specs/googleapis.com/drive/v3/openapi.yaml>                    |
| [s3](clients/storage/s3.nu)                                           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/s3/2006-03-01/openapi.json>                |
| [storage-gateway](clients/storage/storage-gateway.nu)                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/storagegateway/2013-06-30/openapi.json>    |

### tax

| Client                                                                                                  | Type    | Source                                                                                                                                |
| ------------------------------------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| [billingo](clients/tax/billingo.nu)                                                                     | openapi | <https://api.apis.guru/v2/specs/billingo.hu/3.0.7/openapi.json>                                                                       |
| [hmrc-agent-authorisation](clients/tax/hmrc-agent-authorisation.nu)                                     | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/agent-authorisation-api/2.0/oas/resolved>                   |
| [hmrc-business-details](clients/tax/hmrc-business-details.nu)                                           | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/business-details-api/2.0/oas/resolved>                      |
| [hmrc-business-rates](clients/tax/hmrc-business-rates.nu)                                               | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/business-rates-api/2.0/oas/resolved>                        |
| [hmrc-check-eori-number](clients/tax/hmrc-check-eori-number.nu)                                         | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/check-eori-number-api/1.0/oas/resolved>                     |
| [hmrc-cis-deductions](clients/tax/hmrc-cis-deductions.nu)                                               | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/cis-deductions-api/3.0/oas/resolved>                        |
| [hmrc-individual-benefits](clients/tax/hmrc-individual-benefits.nu)                                     | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individual-benefits/2.0/oas/resolved>                       |
| [hmrc-individual-calculations](clients/tax/hmrc-individual-calculations.nu)                             | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individual-calculations-api/8.0/oas/resolved>               |
| [hmrc-individuals-capital-gains-income](clients/tax/hmrc-individuals-capital-gains-income.nu)           | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individuals-capital-gains-income-api/3.0/oas/resolved>      |
| [hmrc-individuals-charges](clients/tax/hmrc-individuals-charges.nu)                                     | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individuals-charges-api/3.0/oas/resolved>                   |
| [hmrc-individuals-disclosures](clients/tax/hmrc-individuals-disclosures.nu)                             | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individuals-disclosures-api/2.0/oas/resolved>               |
| [hmrc-individuals-dividends-income](clients/tax/hmrc-individuals-dividends-income.nu)                   | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individuals-dividends-income-api/2.0/oas/resolved>          |
| [hmrc-individuals-employments-income](clients/tax/hmrc-individuals-employments-income.nu)               | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individuals-employments-income-api/2.0/oas/resolved>        |
| [hmrc-individuals-expenses](clients/tax/hmrc-individuals-expenses.nu)                                   | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individuals-expenses-api/3.0/oas/resolved>                  |
| [hmrc-individuals-foreign-income](clients/tax/hmrc-individuals-foreign-income.nu)                       | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individuals-foreign-income-api/2.0/oas/resolved>            |
| [hmrc-individuals-insurance-policies-income](clients/tax/hmrc-individuals-insurance-policies-income.nu) | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individuals-insurance-policies-income-api/2.0/oas/resolved> |
| [hmrc-individuals-other-income](clients/tax/hmrc-individuals-other-income.nu)                           | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individuals-other-income-api/2.0/oas/resolved>              |
| [hmrc-individuals-partner-income](clients/tax/hmrc-individuals-partner-income.nu)                       | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individuals-partner-income-api/1.0/oas/resolved>            |
| [hmrc-individuals-pensions-income](clients/tax/hmrc-individuals-pensions-income.nu)                     | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individuals-pensions-income-api/2.0/oas/resolved>           |
| [hmrc-individuals-reliefs](clients/tax/hmrc-individuals-reliefs.nu)                                     | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individuals-reliefs-api/3.0/oas/resolved>                   |
| [hmrc-individuals-savings-income](clients/tax/hmrc-individuals-savings-income.nu)                       | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individuals-savings-income-api/2.0/oas/resolved>            |
| [hmrc-individuals-state-benefits](clients/tax/hmrc-individuals-state-benefits.nu)                       | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individuals-state-benefits-api/2.0/oas/resolved>            |
| [hmrc-individuals-tax-liability-adjustments](clients/tax/hmrc-individuals-tax-liability-adjustments.nu) | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/individuals-tax-liability-adjustments-api/1.0/oas/resolved> |
| [hmrc-lisa](clients/tax/hmrc-lisa.nu)                                                                   | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/lisa-api/2.0/oas/resolved>                                  |
| [hmrc-marriage-allowance](clients/tax/hmrc-marriage-allowance.nu)                                       | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/marriage-allowance/2.0/oas/resolved>                        |
| [hmrc-obligations](clients/tax/hmrc-obligations.nu)                                                     | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/obligations-api/3.0/oas/resolved>                           |
| [hmrc-other-deductions](clients/tax/hmrc-other-deductions.nu)                                           | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/other-deductions-api/2.0/oas/resolved>                      |
| [hmrc-pillar2-submission](clients/tax/hmrc-pillar2-submission.nu)                                       | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/pillar2-submission-api/1.0/oas/resolved>                    |
| [hmrc-property-business](clients/tax/hmrc-property-business.nu)                                         | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/property-business-api/6.0/oas/resolved>                     |
| [hmrc-self-assessment-accounts](clients/tax/hmrc-self-assessment-accounts.nu)                           | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/self-assessment-accounts-api/4.0/oas/resolved>              |
| [hmrc-self-assessment-biss](clients/tax/hmrc-self-assessment-biss.nu)                                   | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/self-assessment-biss-api/3.0/oas/resolved>                  |
| [hmrc-self-assessment-bsas](clients/tax/hmrc-self-assessment-bsas.nu)                                   | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/self-assessment-bsas-api/7.0/oas/resolved>                  |
| [hmrc-self-assessment-individual-details](clients/tax/hmrc-self-assessment-individual-details.nu)       | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/self-assessment-individual-details-api/2.0/oas/resolved>    |
| [hmrc-self-assessment-liability](clients/tax/hmrc-self-assessment-liability.nu)                         | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/self-assessment-liability-api/1.0/oas/resolved>             |
| [hmrc-self-employment-business](clients/tax/hmrc-self-employment-business.nu)                           | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/self-employment-business-api/5.0/oas/resolved>              |
| [hmrc-vat](clients/tax/hmrc-vat.nu)                                                                     | openapi | <https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/vat-api/1.0/oas/resolved>                                   |
| [taxamo](clients/tax/taxamo.nu)                                                                         | openapi | <https://api.apis.guru/v2/specs/taxamo.com/1/swagger.json>                                                                            |
| [taxrates-io](clients/tax/taxrates-io.nu)                                                               | openapi | <https://api.apis.guru/v2/specs/taxrates.io/1.0.0/openapi.json>                                                                       |

### telephony

| Client                                                                        | Type    | Source                                                                                         |
| ----------------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------- |
| [bandwidth](clients/telephony/bandwidth.nu)                                   | openapi | <https://raw.githubusercontent.com/Bandwidth/node-sdk/main/bandwidth.yml>                      |
| [bulksms](clients/telephony/bulksms.nu)                                       | openapi | <https://api.apis.guru/v2/specs/bulksms.com/1.0.0/openapi.json>                                |
| [callcontrol](clients/telephony/callcontrol.nu)                               | openapi | <https://api.apis.guru/v2/specs/callcontrol.com/2015-11-01/swagger.json>                       |
| [callfire](clients/telephony/callfire.nu)                                     | openapi | <https://api.apis.guru/v2/specs/callfire.com/V2/openapi.json>                                  |
| [d7networks](clients/telephony/d7networks.nu)                                 | openapi | <https://api.apis.guru/v2/specs/d7networks.com/1.0.2/openapi.json>                             |
| [isendpro](clients/telephony/isendpro.nu)                                     | openapi | <https://api.apis.guru/v2/specs/isendpro.com/1.1.1/openapi.json>                               |
| [messagebird](clients/telephony/messagebird.nu)                               | openapi | <https://raw.githubusercontent.com/messagebird/openapi-specs/master/sms/openapi.yaml>          |
| [nexmo-account](clients/telephony/nexmo-account.nu)                           | openapi | <https://api.apis.guru/v2/specs/nexmo.com/account/1.0.4/openapi.json>                          |
| [nexmo-audit](clients/telephony/nexmo-audit.nu)                               | openapi | <https://api.apis.guru/v2/specs/nexmo.com/audit/1.0.4/openapi.json>                            |
| [nexmo-dispatch](clients/telephony/nexmo-dispatch.nu)                         | openapi | <https://api.apis.guru/v2/specs/nexmo.com/dispatch/0.3.4/openapi.json>                         |
| [nexmo-messages](clients/telephony/nexmo-messages.nu)                         | openapi | <https://api.apis.guru/v2/specs/nexmo.com/messages-olympus/1.4.0/openapi.json>                 |
| [nexmo-numbers](clients/telephony/nexmo-numbers.nu)                           | openapi | <https://api.apis.guru/v2/specs/nexmo.com/numbers/1.0.20/openapi.json>                         |
| [nexmo-pricing](clients/telephony/nexmo-pricing.nu)                           | openapi | <https://api.apis.guru/v2/specs/nexmo.com/pricing/0.0.3/openapi.json>                          |
| [nexmo-redact](clients/telephony/nexmo-redact.nu)                             | openapi | <https://api.apis.guru/v2/specs/nexmo.com/redact/1.0.6/openapi.json>                           |
| [nexmo-reports](clients/telephony/nexmo-reports.nu)                           | openapi | <https://api.apis.guru/v2/specs/nexmo.com/reports/2.2.2/openapi.json>                          |
| [nexmo-sms](clients/telephony/nexmo-sms.nu)                                   | openapi | <https://api.apis.guru/v2/specs/nexmo.com/sms/1.2.0/openapi.json>                              |
| [ringcentral](clients/telephony/ringcentral.nu)                               | openapi | <https://netstorage.ringcentral.com/dpw/api-reference/specs/rc-platform.yml>                   |
| [sakari](clients/telephony/sakari.nu)                                         | openapi | <https://api.apis.guru/v2/specs/sakari.io/1.0.1/openapi.json>                                  |
| [sms77](clients/telephony/sms77.nu)                                           | openapi | <https://api.apis.guru/v2/specs/sms77.io/1.0.0/openapi.json>                                   |
| [surevoip](clients/telephony/surevoip.nu)                                     | openapi | <https://api.apis.guru/v2/specs/surevoip.co.uk/9dcb0dc8/openapi.json>                          |
| [telnyx](clients/telephony/telnyx.nu)                                         | openapi | <https://raw.githubusercontent.com/team-telnyx/openapi/master/openapi/spec3.json>              |
| [telnyx-apisguru](clients/telephony/telnyx-apisguru.nu)                       | openapi | <https://api.apis.guru/v2/specs/telnyx.com/2.0.0/openapi.json>                                 |
| [thesmsworks](clients/telephony/thesmsworks.nu)                               | openapi | <https://api.apis.guru/v2/specs/thesmsworks.co.uk/1.8.0/swagger.json>                          |
| [twilio](clients/telephony/twilio.nu)                                         | openapi | <https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_api_v2010.json>     |
| [twilio-api-apisguru](clients/telephony/twilio-api-apisguru.nu)               | openapi | <https://api.apis.guru/v2/specs/twilio.com/api/1.42.0/openapi.json>                            |
| [twilio-autopilot](clients/telephony/twilio-autopilot.nu)                     | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_autopilot_v1/1.42.0/openapi.json>            |
| [twilio-bulkexports](clients/telephony/twilio-bulkexports.nu)                 | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_bulkexports_v1/1.42.0/openapi.json>          |
| [twilio-content](clients/telephony/twilio-content.nu)                         | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_content_v1/1.42.0/openapi.json>              |
| [twilio-events](clients/telephony/twilio-events.nu)                           | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_events_v1/1.42.0/openapi.json>               |
| [twilio-fax](clients/telephony/twilio-fax.nu)                                 | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_fax_v1/1.29.1/openapi.json>                  |
| [twilio-flex-v1](clients/telephony/twilio-flex-v1.nu)                         | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_flex_v1/1.42.0/openapi.json>                 |
| [twilio-frontline](clients/telephony/twilio-frontline.nu)                     | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_frontline_v1/1.42.0/openapi.json>            |
| [twilio-insights](clients/telephony/twilio-insights.nu)                       | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_insights_v1/1.42.0/openapi.json>             |
| [twilio-lookups](clients/telephony/twilio-lookups.nu)                         | openapi | <https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_lookups_v2.json>    |
| [twilio-media](clients/telephony/twilio-media.nu)                             | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_media_v1/1.42.0/openapi.json>                |
| [twilio-messaging-v1-github](clients/telephony/twilio-messaging-v1-github.nu) | openapi | <https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_messaging_v1.json>  |
| [twilio-microvisor](clients/telephony/twilio-microvisor.nu)                   | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_microvisor_v1/1.42.0/openapi.json>           |
| [twilio-pricing-v1](clients/telephony/twilio-pricing-v1.nu)                   | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_pricing_v1/1.42.0/openapi.json>              |
| [twilio-proxy](clients/telephony/twilio-proxy.nu)                             | openapi | <https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_proxy_v1.json>      |
| [twilio-routes](clients/telephony/twilio-routes.nu)                           | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_routes_v2/1.42.0/openapi.json>               |
| [twilio-serverless](clients/telephony/twilio-serverless.nu)                   | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_serverless_v1/1.42.0/openapi.json>           |
| [twilio-studio](clients/telephony/twilio-studio.nu)                           | openapi | <https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_studio_v2.json>     |
| [twilio-supersim](clients/telephony/twilio-supersim.nu)                       | openapi | <https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_supersim_v1.json>   |
| [twilio-sync](clients/telephony/twilio-sync.nu)                               | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_sync_v1/1.42.0/openapi.json>                 |
| [twilio-taskrouter](clients/telephony/twilio-taskrouter.nu)                   | openapi | <https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_taskrouter_v1.json> |
| [twilio-trunking](clients/telephony/twilio-trunking.nu)                       | openapi | <https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_trunking_v1.json>   |
| [twilio-voice](clients/telephony/twilio-voice.nu)                             | openapi | <https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_voice_v1.json>      |
| [twilio-wireless](clients/telephony/twilio-wireless.nu)                       | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_wireless_v1/1.42.0/openapi.json>             |
| [vonage](clients/telephony/vonage.nu)                                         | openapi | <https://api.apis.guru/v2/specs/nexmo.com/voice/1.3.10/openapi.json>                           |
| [vonage-account](clients/telephony/vonage-account.nu)                         | openapi | <https://api.apis.guru/v2/specs/vonage.com/account/1.11.8/openapi.json>                        |
| [vonage-application](clients/telephony/vonage-application.nu)                 | openapi | <https://api.apis.guru/v2/specs/nexmo.com/application/1.0.2/openapi.json>                      |
| [vonage-application-v2](clients/telephony/vonage-application-v2.nu)           | openapi | <https://api.apis.guru/v2/specs/nexmo.com/application.v2/2.1.4/openapi.json>                   |
| [vonage-conversation-v2](clients/telephony/vonage-conversation-v2.nu)         | openapi | <https://api.apis.guru/v2/specs/nexmo.com/conversation.v2/1.0.1/openapi.json>                  |
| [vonage-conversion](clients/telephony/vonage-conversion.nu)                   | openapi | <https://api.apis.guru/v2/specs/nexmo.com/conversion/1.0.1/openapi.json>                       |
| [vonage-extension](clients/telephony/vonage-extension.nu)                     | openapi | <https://api.apis.guru/v2/specs/vonage.com/extension/1.11.8/openapi.json>                      |
| [vonage-external-accounts](clients/telephony/vonage-external-accounts.nu)     | openapi | <https://api.apis.guru/v2/specs/nexmo.com/external-accounts/0.1.5/openapi.json>                |
| [vonage-media](clients/telephony/vonage-media.nu)                             | openapi | <https://api.apis.guru/v2/specs/nexmo.com/media/1.0.2/openapi.json>                            |
| [vonage-reports](clients/telephony/vonage-reports.nu)                         | openapi | <https://api.apis.guru/v2/specs/vonage.com/reports/1.0.1/openapi.json>                         |
| [vonage-subaccounts](clients/telephony/vonage-subaccounts.nu)                 | openapi | <https://api.apis.guru/v2/specs/nexmo.com/subaccounts/1.0.8/openapi.json>                      |
| [vonage-user](clients/telephony/vonage-user.nu)                               | openapi | <https://api.apis.guru/v2/specs/vonage.com/user/1.11.8/openapi.json>                           |
| [vonage-vgis](clients/telephony/vonage-vgis.nu)                               | openapi | <https://api.apis.guru/v2/specs/vonage.com/vgis/1.0.1/openapi.json>                            |
| [winsms](clients/telephony/winsms.nu)                                         | openapi | <https://api.apis.guru/v2/specs/winsms.co.za/1.0.0/swagger.json>                               |
| [zoomconnect](clients/telephony/zoomconnect.nu)                               | openapi | <https://api.apis.guru/v2/specs/zoomconnect.com/1/swagger.json>                                |

### testing

| Client                                                                        | Type    | Source                                                                                                                                                    |
| ----------------------------------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [apify](clients/testing/apify.nu)                                             | openapi | <https://api.apify.com/v2/openapi.json>                                                                                                                   |
| [apis-guru](clients/testing/apis-guru.nu)                                     | openapi | <https://api.apis.guru/v2/specs/apis.guru/2.2.0/openapi.yaml>                                                                                             |
| [aws-fis](clients/testing/aws-fis.nu)                                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/fis/2020-12-01/openapi.json>                                                                                |
| [blazemeter](clients/testing/blazemeter.nu)                                   | openapi | <https://api.apis.guru/v2/specs/blazemeter.com/4/swagger.json>                                                                                            |
| [browserbase](clients/testing/browserbase.nu)                                 | openapi | <https://storage.googleapis.com/stainless-sdk-openapi-specs/browserbase/browserbase-f39b852755134d01a440f7c37701f6c5397f43d13740d9ba08739cae488382a7.yml> |
| [browserless](clients/testing/browserless.nu)                                 | openapi | <https://docs.browserless.io/redocusaurus/plugin-redoc-0.yaml>                                                                                            |
| [browshot](clients/testing/browshot.nu)                                       | openapi | <https://api.apis.guru/v2/specs/browshot.com/1.17.0/swagger.json>                                                                                         |
| [clickmeter](clients/testing/clickmeter.nu)                                   | openapi | <https://api.apis.guru/v2/specs/clickmeter.com/v2/openapi.json>                                                                                           |
| [fungenerators-barcode](clients/testing/fungenerators-barcode.nu)             | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/barcode/1.5/openapi.json>                                                                               |
| [fungenerators-fake-identity](clients/testing/fungenerators-fake-identity.nu) | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/fake-identity/1.5/swagger.json>                                                                         |
| [fungenerators-lottery](clients/testing/fungenerators-lottery.nu)             | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/lottery/1.5/swagger.json>                                                                               |
| [fungenerators-namegen](clients/testing/fungenerators-namegen.nu)             | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/namegen/1.5/swagger.json>                                                                               |
| [fungenerators-pirate](clients/testing/fungenerators-pirate.nu)               | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/pirate/1.5/openapi.json>                                                                                |
| [fungenerators-qrcode](clients/testing/fungenerators-qrcode.nu)               | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/qrcode/1.5/swagger.json>                                                                                |
| [fungenerators-random-facts](clients/testing/fungenerators-random-facts.nu)   | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/random-facts/1.5/openapi.json>                                                                          |
| [fungenerators-riddle](clients/testing/fungenerators-riddle.nu)               | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/riddle/1.5/openapi.json>                                                                                |
| [fungenerators-shakespeare](clients/testing/fungenerators-shakespeare.nu)     | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/shakespeare/1.5/openapi.json>                                                                           |
| [fungenerators-taunt](clients/testing/fungenerators-taunt.nu)                 | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/taunt/1.5/swagger.json>                                                                                 |
| [fungenerators-trivia](clients/testing/fungenerators-trivia.nu)               | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/trivia/1.5/swagger.json>                                                                                |
| [fungenerators-uuid](clients/testing/fungenerators-uuid.nu)                   | openapi | <https://api.apis.guru/v2/specs/fungenerators.com/uuid/1.5/openapi.json>                                                                                  |
| [google-toolresults](clients/testing/google-toolresults.nu)                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/toolresults/v1beta3/openapi.json>                                                                          |
| [httpbin](clients/testing/httpbin.nu)                                         | openapi | <https://httpbin.org/spec.json>                                                                                                                           |
| [image-charts](clients/testing/image-charts.nu)                               | openapi | <https://api.apis.guru/v2/specs/image-charts.com/6.1.19/swagger.json>                                                                                     |
| [jokes-one](clients/testing/jokes-one.nu)                                     | openapi | <https://api.apis.guru/v2/specs/jokes.one/1.1/swagger.json>                                                                                               |
| [lambdatest-screenshots](clients/testing/lambdatest-screenshots.nu)           | openapi | <https://api.apis.guru/v2/specs/lambdatest.com/1.0.1/openapi.json>                                                                                        |
| [linqr](clients/testing/linqr.nu)                                             | openapi | <https://api.apis.guru/v2/specs/linqr.app/2.0/openapi.json>                                                                                               |
| [moonmoonmoonmoon](clients/testing/moonmoonmoonmoon.nu)                       | openapi | <https://api.apis.guru/v2/specs/moonmoonmoonmoon.com/1.0/swagger.json>                                                                                    |
| [openstf](clients/testing/openstf.nu)                                         | openapi | <https://api.apis.guru/v2/specs/openstf.io/2.3.0/swagger.json>                                                                                            |
| [peoplegeneratorapi](clients/testing/peoplegeneratorapi.nu)                   | openapi | <https://api.apis.guru/v2/specs/peoplegeneratorapi.live/v0/openapi.json>                                                                                  |
| [quickchart](clients/testing/quickchart.nu)                                   | openapi | <https://api.apis.guru/v2/specs/quickchart.io/1.0.0/openapi.json>                                                                                         |
| [quotes-rest](clients/testing/quotes-rest.nu)                                 | openapi | <https://api.apis.guru/v2/specs/quotes.rest/3.1/openapi.json>                                                                                             |
| [rbaskets](clients/testing/rbaskets.nu)                                       | openapi | <https://api.apis.guru/v2/specs/rbaskets.in/1.0.0/swagger.json>                                                                                           |
| [readme](clients/testing/readme.nu)                                           | openapi | <https://api.apis.guru/v2/specs/readme.io/2.0.0/openapi.json>                                                                                             |
| [ritc](clients/testing/ritc.nu)                                               | openapi | <https://api.apis.guru/v2/specs/ritc.io/1.0.0/swagger.json>                                                                                               |
| [runscope](clients/testing/runscope.nu)                                       | openapi | <https://api.apis.guru/v2/specs/runscope.com/1.0.0/swagger.json>                                                                                          |
| [stellastra](clients/testing/stellastra.nu)                                   | openapi | <https://api.apis.guru/v2/specs/stellastra.com/1.0/openapi.json>                                                                                          |
| [testfire-altoroj](clients/testing/testfire-altoroj.nu)                       | openapi | <https://api.apis.guru/v2/specs/testfire.net/altoroj/1.0.2/swagger.json>                                                                                  |
| [wiremock-admin](clients/testing/wiremock-admin.nu)                           | openapi | <https://api.apis.guru/v2/specs/wiremock.org/admin/2.35.0/openapi.json>                                                                                   |

### translation

| Client                                                                        | Type    | Source                                                                                                                                                        |
| ----------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [aws-comprehend](clients/translation/aws-comprehend.nu)                       | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/comprehend/2017-11-27/openapi.json>                                                                             |
| [aws-translate](clients/translation/aws-translate.nu)                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/translate/2017-07-01/openapi.json>                                                                              |
| [azure-translator](clients/translation/azure-translator.nu)                   | openapi | <https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/TranslatorText/stable/v3.0/TranslatorText.json> |
| [datumbox](clients/translation/datumbox.nu)                                   | openapi | <https://api.apis.guru/v2/specs/datumbox.com/1.0/openapi.json>                                                                                                |
| [deepl](clients/translation/deepl.nu)                                         | openapi | <https://raw.githubusercontent.com/DeepLcom/openapi/main/openapi.json>                                                                                        |
| [ebay-commerce-translation](clients/translation/ebay-commerce-translation.nu) | openapi | <https://api.apis.guru/v2/specs/ebay.com/commerce-translation/1/openapi.json>                                                                                 |
| [funtranslations](clients/translation/funtranslations.nu)                     | openapi | <https://api.apis.guru/v2/specs/funtranslations.com/index/2.3/swagger.json>                                                                                   |
| [funtranslations-braile](clients/translation/funtranslations-braile.nu)       | openapi | <https://api.apis.guru/v2/specs/funtranslations.com/braile/2.3/swagger.json>                                                                                  |
| [geneea](clients/translation/geneea.nu)                                       | openapi | <https://api.apis.guru/v2/specs/geneea.com/1.0/swagger.json>                                                                                                  |
| [google-natural-language](clients/translation/google-natural-language.nu)     | openapi | <https://api.apis.guru/v2/specs/googleapis.com/language/v1/openapi.json>                                                                                      |
| [google-translate](clients/translation/google-translate.nu)                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/translate/v3/openapi.json>                                                                                     |
| [languagetool](clients/translation/languagetool.nu)                           | openapi | <https://api.apis.guru/v2/specs/languagetool.org/1.1.2/swagger.json>                                                                                          |
| [libretranslate](clients/translation/libretranslate.nu)                       | openapi | <https://api.apis.guru/v2/specs/libretranslate.local/1.3.9/openapi.json>                                                                                      |
| [lingvanex](clients/translation/lingvanex.nu)                                 | openapi | <https://lingvanex.com/openapi.json>                                                                                                                          |
| [motaword](clients/translation/motaword.nu)                                   | openapi | <https://api.apis.guru/v2/specs/motaword.com/1.0/openapi.json>                                                                                                |
| [rapidapi-spellcheckpro](clients/translation/rapidapi-spellcheckpro.nu)       | openapi | <https://api.apis.guru/v2/specs/rapidapi.com/spellcheckpro/1.0.0/openapi.json>                                                                                |
| [spinbot](clients/translation/spinbot.nu)                                     | openapi | <https://api.apis.guru/v2/specs/spinbot.net/1.0/swagger.json>                                                                                                 |
| [tafqit](clients/translation/tafqit.nu)                                       | openapi | <https://api.apis.guru/v2/specs/tafqit.herokuapp.com/v1/openapi.json>                                                                                         |
| [tisane](clients/translation/tisane.nu)                                       | openapi | <https://api.apis.guru/v2/specs/tisane.ai/1.0.0/openapi.json>                                                                                                 |
| [tolgee](clients/translation/tolgee.nu)                                       | openapi | <https://app.tolgee.io/v3/api-docs>                                                                                                                           |
| [xtrf](clients/translation/xtrf.nu)                                           | openapi | <https://api.apis.guru/v2/specs/xtrf.eu/2.0/openapi.json>                                                                                                     |

### travel

| Client                                                                                         | Type    | Source                                                                                                    |
| ---------------------------------------------------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------------------- |
| [amadeus](clients/travel/amadeus.nu)                                                           | openapi | <https://api.apis.guru/v2/specs/amadeus.com/2.2.0/openapi.json>                                           |
| [amadeus-airline-code-lookup](clients/travel/amadeus-airline-code-lookup.nu)                   | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-airline-code-lookup/1.1.1/swagger.json>               |
| [amadeus-airport-city-search](clients/travel/amadeus-airport-city-search.nu)                   | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-airport-&-city-search/1.2.3/swagger.json>             |
| [amadeus-airport-nearest](clients/travel/amadeus-airport-nearest.nu)                           | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-airport-nearest-relevant/1.1.2/swagger.json>          |
| [amadeus-airport-on-time](clients/travel/amadeus-airport-on-time.nu)                           | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-airport-on-time-performance/1.0.4/swagger.json>       |
| [amadeus-branded-fares-upsell](clients/travel/amadeus-branded-fares-upsell.nu)                 | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-branded-fares-upsell/1.0.1/swagger.json>              |
| [amadeus-flight-availabilities-search](clients/travel/amadeus-flight-availabilities-search.nu) | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-flight-availabilities-search/1.0.2/swagger.json>      |
| [amadeus-flight-busiest-period](clients/travel/amadeus-flight-busiest-period.nu)               | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-flight-busiest-traveling-period/1.0.2/swagger.json>   |
| [amadeus-flight-cheapest-date-search](clients/travel/amadeus-flight-cheapest-date-search.nu)   | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-flight-cheapest-date-search/1.0.6/swagger.json>       |
| [amadeus-flight-check-in-links](clients/travel/amadeus-flight-check-in-links.nu)               | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-flight-check-in-links/2.1.2/swagger.json>             |
| [amadeus-flight-choice-prediction](clients/travel/amadeus-flight-choice-prediction.nu)         | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-flight-choice-prediction/2.0.2/swagger.json>          |
| [amadeus-flight-create-orders](clients/travel/amadeus-flight-create-orders.nu)                 | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-flight-create-orders/1.9.0/swagger.json>              |
| [amadeus-flight-delay-prediction](clients/travel/amadeus-flight-delay-prediction.nu)           | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-flight-delay-prediction/1.0.6/swagger.json>           |
| [amadeus-flight-inspiration-search](clients/travel/amadeus-flight-inspiration-search.nu)       | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-flight-inspiration-search/1.0.6/swagger.json>         |
| [amadeus-flight-most-booked](clients/travel/amadeus-flight-most-booked.nu)                     | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-flight-most-booked-destinations/1.1.1/swagger.json>   |
| [amadeus-flight-most-traveled](clients/travel/amadeus-flight-most-traveled.nu)                 | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-flight-most-traveled-destinations/1.1.1/swagger.json> |
| [amadeus-flight-offers-price](clients/travel/amadeus-flight-offers-price.nu)                   | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-flight-offers-price/1.2.2/swagger.json>               |
| [amadeus-flight-order-management](clients/travel/amadeus-flight-order-management.nu)           | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-flight-order-management/1.9.0/swagger.json>           |
| [amadeus-flight-price-analysis](clients/travel/amadeus-flight-price-analysis.nu)               | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-flight-price-analysis/1.0.1/openapi.json>             |
| [amadeus-hotel-booking](clients/travel/amadeus-hotel-booking.nu)                               | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-hotel-booking/1.1.3/swagger.json>                     |
| [amadeus-hotel-name-autocomplete](clients/travel/amadeus-hotel-name-autocomplete.nu)           | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-hotel-name-autocomplete/1.0.3/swagger.json>           |
| [amadeus-hotel-ratings](clients/travel/amadeus-hotel-ratings.nu)                               | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-hotel-ratings/1.0.2/swagger.json>                     |
| [amadeus-hotel-search](clients/travel/amadeus-hotel-search.nu)                                 | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-hotel-search/3.0.8/swagger.json>                      |
| [amadeus-location-score](clients/travel/amadeus-location-score.nu)                             | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-location-score/1.0.2/openapi.json>                    |
| [amadeus-on-demand-flight-status](clients/travel/amadeus-on-demand-flight-status.nu)           | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-on-demand-flight-status/2.0.2/swagger.json>           |
| [amadeus-points-of-interest](clients/travel/amadeus-points-of-interest.nu)                     | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-points-of-interest/1.1.1/swagger.json>                |
| [amadeus-safe-place](clients/travel/amadeus-safe-place.nu)                                     | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-safe-place-/1.0.0/swagger.json>                       |
| [amadeus-seatmap-display](clients/travel/amadeus-seatmap-display.nu)                           | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-seatmap-display/1.9.2/swagger.json>                   |
| [amadeus-tours-and-activities](clients/travel/amadeus-tours-and-activities.nu)                 | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-tours-and-activities/1.0.2/swagger.json>              |
| [amadeus-travel-recommendations](clients/travel/amadeus-travel-recommendations.nu)             | openapi | <https://api.apis.guru/v2/specs/amadeus.com/amadeus-travel-recommendations/1.0.3/openapi.json>            |
| [aviationdata-systems](clients/travel/aviationdata-systems.nu)                                 | openapi | <https://api.apis.guru/v2/specs/aviationdata.systems/v1/swagger.json>                                     |
| [flightaware-aeroapi](clients/travel/flightaware-aeroapi.nu)                                   | openapi | <https://www.flightaware.com/commercial/aeroapi/resources/aeroapi-openapi.yml>                            |
| [impala-hotels](clients/travel/impala-hotels.nu)                                               | openapi | <https://api.apis.guru/v2/specs/impala.travel/hotels/1.003/openapi.json>                                  |
| [lufthansa-partner](clients/travel/lufthansa-partner.nu)                                       | openapi | <https://api.apis.guru/v2/specs/lufthansa.com/partner/1.0/openapi.json>                                   |
| [lufthansa-public](clients/travel/lufthansa-public.nu)                                         | openapi | <https://api.apis.guru/v2/specs/lufthansa.com/public/1.0/openapi.json>                                    |
| [lyft](clients/travel/lyft.nu)                                                                 | openapi | <https://api.apis.guru/v2/specs/lyft.com/1.0.0/swagger.json>                                              |
| [mon-voyage-pas-cher](clients/travel/mon-voyage-pas-cher.nu)                                   | openapi | <https://api.apis.guru/v2/specs/mon-voyage-pas-cher.com/0.0.1/swagger.json>                               |
| [oceandrivers](clients/travel/oceandrivers.nu)                                                 | openapi | <https://api.apis.guru/v2/specs/oceandrivers.com/1.0/openapi.json>                                        |

### vector-database

| Client                                                                              | Type    | Source                                                                                                                               |
| ----------------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| [chroma](clients/vector-database/chroma.nu)                                         | openapi | <https://docs.trychroma.com/openapi.json>                                                                                            |
| [milvus](clients/vector-database/milvus.nu)                                         | openapi | <https://raw.githubusercontent.com/milvus-io/web-content/master/API_Reference/milvus-restful/v2.4.x/Restful%20API%20v2.openapi.json> |
| [mongodb-atlas-admin](clients/vector-database/mongodb-atlas-admin.nu)               | openapi | <https://raw.githubusercontent.com/mongodb/openapi/main/openapi/v2.yaml>                                                             |
| [pinecone](clients/vector-database/pinecone.nu)                                     | openapi | <https://api.apis.guru/v2/specs/pinecone.io/20230401.1/openapi.json>                                                                 |
| [pinecone-admin](clients/vector-database/pinecone-admin.nu)                         | openapi | <https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/admin_2026-04.oas.yaml>                                     |
| [pinecone-assistant-control](clients/vector-database/pinecone-assistant-control.nu) | openapi | <https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/assistant_control_2026-04.oas.yaml>                         |
| [pinecone-assistant-data](clients/vector-database/pinecone-assistant-data.nu)       | openapi | <https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/assistant_data_2026-04.oas.yaml>                            |
| [pinecone-db-control](clients/vector-database/pinecone-db-control.nu)               | openapi | <https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/db_control_2026-04.oas.yaml>                                |
| [pinecone-db-data](clients/vector-database/pinecone-db-data.nu)                     | openapi | <https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/db_data_2026-04.oas.yaml>                                   |
| [pinecone-inference](clients/vector-database/pinecone-inference.nu)                 | openapi | <https://raw.githubusercontent.com/pinecone-io/pinecone-api/main/2026-04/inference_2026-04.oas.yaml>                                 |
| [semadb](clients/vector-database/semadb.nu)                                         | openapi | <https://raw.githubusercontent.com/Semafind/semadb/main/httpapi/v2/openapi.yaml>                                                     |
| [turbopuffer](clients/vector-database/turbopuffer.nu)                               | openapi | <https://raw.githubusercontent.com/turbopuffer/turbopuffer-openapi/next/openapi.yml>                                                 |
| [vectara](clients/vector-database/vectara.nu)                                       | openapi | <https://docs.vectara.com/vectara-oas-v2.yaml>                                                                                       |
| [vectara-apisguru](clients/vector-database/vectara-apisguru.nu)                     | openapi | <https://api.apis.guru/v2/specs/vectara.io/1.0.0/openapi.json>                                                                       |

### version-control

| Client                                                                              | Type    | Source                                                                                                     |
| ----------------------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------------------- |
| [aws-codeartifact](clients/version-control/aws-codeartifact.nu)                     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/codeartifact/2018-09-22/openapi.json>                        |
| [aws-codecommit](clients/version-control/aws-codecommit.nu)                         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/codecommit/2015-04-13/openapi.json>                          |
| [aws-codeguru-reviewer](clients/version-control/aws-codeguru-reviewer.nu)           | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/codeguru-reviewer/2019-09-19/openapi.json>                   |
| [aws-codestar](clients/version-control/aws-codestar.nu)                             | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/codestar/2017-04-19/openapi.json>                            |
| [aws-codestar-connections](clients/version-control/aws-codestar-connections.nu)     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/codestar-connections/2019-12-01/openapi.json>                |
| [aws-codestar-notifications](clients/version-control/aws-codestar-notifications.nu) | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/codestar-notifications/2019-10-15/openapi.json>              |
| [aws-signer](clients/version-control/aws-signer.nu)                                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/signer/2017-08-25/openapi.json>                              |
| [bitbucket](clients/version-control/bitbucket.nu)                                   | openapi | <https://api.bitbucket.org/swagger.json>                                                                   |
| [bitbucket-server](clients/version-control/bitbucket-server.nu)                     | openapi | <https://dac-static.atlassian.com/server/bitbucket/10.3.swagger.v3.json>                                   |
| [codeberg](clients/version-control/codeberg.nu)                                     | openapi | <https://codeberg.org/swagger.v1.json>                                                                     |
| [forgejo](clients/version-control/forgejo.nu)                                       | openapi | <https://v11.next.forgejo.org/swagger.v1.json>                                                             |
| [gitea](clients/version-control/gitea.nu)                                           | openapi | <https://gitea.com/swagger.v1.json>                                                                        |
| [gitea-apisguru](clients/version-control/gitea-apisguru.nu)                         | openapi | <https://api.apis.guru/v2/specs/gitea.io/1.20.0+dev-93-g6886706f5/openapi.json>                            |
| [gitea-osmocom](clients/version-control/gitea-osmocom.nu)                           | openapi | <https://gitea.osmocom.org/swagger.v1.json>                                                                |
| [gitguardian](clients/version-control/gitguardian.nu)                               | openapi | <https://api.gitguardian.com/v1/openapi.json>                                                              |
| [github-enterprise-server](clients/version-control/github-enterprise-server.nu)     | openapi | <https://raw.githubusercontent.com/github/rest-api-description/main/descriptions/ghes-3.11/ghes-3.11.json> |
| [gitlab](clients/version-control/gitlab.nu)                                         | openapi | <https://docs.gitlab.com/api/openapi/openapi_v2.yaml>                                                      |
| [gitlab-apisguru](clients/version-control/gitlab-apisguru.nu)                       | openapi | <https://api.apis.guru/v2/specs/gitlab.com/v3/swagger.json>                                                |
| [mergify](clients/version-control/mergify.nu)                                       | openapi | <https://api.mergify.com/v1/openapi.json>                                                                  |
| [openapi-generator](clients/version-control/openapi-generator.nu)                   | openapi | <https://api.apis.guru/v2/specs/openapi-generator.tech/6.2.1/openapi.json>                                 |
| [opendev](clients/version-control/opendev.nu)                                       | openapi | <https://opendev.org/swagger.v1.json>                                                                      |
| [opensuse-obs](clients/version-control/opensuse-obs.nu)                             | openapi | <https://api.apis.guru/v2/specs/opensuse.org/obs/2.10.50/openapi.json>                                     |
| [sourcegraph](clients/version-control/sourcegraph.nu)                               | graphql | <https://sourcegraph.com/.api/graphql>                                                                     |
| [versioneye](clients/version-control/versioneye.nu)                                 | openapi | <https://api.apis.guru/v2/specs/versioneye.com/v1/openapi.json>                                            |
| [visualstudio-apisguru](clients/version-control/visualstudio-apisguru.nu)           | openapi | <https://api.apis.guru/v2/specs/visualstudio.com/v1/openapi.json>                                          |

### video

| Client                                                                | Type    | Source                                                                                    |
| --------------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------- |
| [api-video](clients/video/api-video.nu)                               | openapi | <https://api.apis.guru/v2/specs/api.video/1/openapi.json>                                 |
| [aws-ivs](clients/video/aws-ivs.nu)                                   | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/ivs/2020-07-14/openapi.json>                |
| [aws-kinesisvideo](clients/video/aws-kinesisvideo.nu)                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/kinesisvideo/2017-09-30/openapi.json>       |
| [aws-mediaconnect](clients/video/aws-mediaconnect.nu)                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/mediaconnect/2018-11-14/openapi.json>       |
| [aws-mediaconvert](clients/video/aws-mediaconvert.nu)                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/mediaconvert/2017-08-29/openapi.json>       |
| [aws-medialive](clients/video/aws-medialive.nu)                       | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/medialive/2017-10-14/openapi.json>          |
| [aws-mediapackage](clients/video/aws-mediapackage.nu)                 | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/mediapackage/2017-10-12/openapi.json>       |
| [aws-mediapackage-vod](clients/video/aws-mediapackage-vod.nu)         | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/mediapackage-vod/2018-11-07/openapi.json>   |
| [aws-mediastore](clients/video/aws-mediastore.nu)                     | openapi | <https://api.apis.guru/v2/specs/amazonaws.com/mediastore/2017-09-01/openapi.json>         |
| [bunny-stream](clients/video/bunny-stream.nu)                         | openapi | <https://video.bunnycdn.com/openapi/bunnynet-video-api.public.json>                       |
| [daily-co](clients/video/daily-co.nu)                                 | openapi | <https://docs.daily.co/openapi.json>                                                      |
| [google-transcoder](clients/video/google-transcoder.nu)               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/transcoder/v1/openapi.json>                |
| [google-videointelligence](clients/video/google-videointelligence.nu) | openapi | <https://api.apis.guru/v2/specs/googleapis.com/videointelligence/v1/openapi.json>         |
| [json2video](clients/video/json2video.nu)                             | openapi | <https://api.apis.guru/v2/specs/json2video.com/2.0.0/openapi.json>                        |
| [stream-io](clients/video/stream-io.nu)                               | openapi | <https://api.apis.guru/v2/specs/stream-io-api.com/v79.19.1/openapi.json>                  |
| [twilio-video](clients/video/twilio-video.nu)                         | openapi | <https://api.apis.guru/v2/specs/twilio.com/twilio_video_v1/1.42.0/openapi.json>           |
| [twitch](clients/video/twitch.nu)                                     | openapi | <https://raw.githubusercontent.com/DmitryScaletta/twitch-api-swagger/master/openapi.json> |
| [vimeo](clients/video/vimeo.nu)                                       | openapi | <https://api.apis.guru/v2/specs/vimeo.com/3.4/openapi.json>                               |
| [wowza](clients/video/wowza.nu)                                       | openapi | <https://api.apis.guru/v2/specs/wowza.com/1/swagger.json>                                 |
| [youtube](clients/video/youtube.nu)                                   | openapi | <https://api.apis.guru/v2/specs/googleapis.com/youtube/v3/openapi.json>                   |
| [youtube-reporting](clients/video/youtube-reporting.nu)               | openapi | <https://api.apis.guru/v2/specs/googleapis.com/youtubereporting/v1/openapi.json>          |

### weather

| Client                                                                | Type    | Source                                                                                        |
| --------------------------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------- |
| [brightsky](clients/weather/brightsky.nu)                             | openapi | <https://api.brightsky.dev/openapi.json>                                                      |
| [climate-com](clients/weather/climate-com.nu)                         | openapi | <https://api.apis.guru/v2/specs/climate.com/4.0.11/openapi.json>                              |
| [corrently](clients/weather/corrently.nu)                             | openapi | <https://api.apis.guru/v2/specs/corrently.io/2.0.0/openapi.json>                              |
| [interzoid-getweatherzip](clients/weather/interzoid-getweatherzip.nu) | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getweatherzip/1.0.0/openapi.json>               |
| [interzoid-weathercity](clients/weather/interzoid-weathercity.nu)     | openapi | <https://api.apis.guru/v2/specs/interzoid.com/getweathercity/1.0.0/openapi.json>              |
| [meteosource](clients/weather/meteosource.nu)                         | openapi | <https://api.apis.guru/v2/specs/meteosource.com/v1/openapi.json>                              |
| [netatmo](clients/weather/netatmo.nu)                                 | openapi | <https://api.apis.guru/v2/specs/netatmo.net/1.1.5/openapi.json>                               |
| [open-meteo-air-quality](clients/weather/open-meteo-air-quality.nu)   | openapi | <https://raw.githubusercontent.com/open-meteo/open-meteo/main/openapi/air-quality.yml>        |
| [open-meteo-forecast](clients/weather/open-meteo-forecast.nu)         | openapi | <https://raw.githubusercontent.com/open-meteo/open-meteo/main/openapi/forecast.yml>           |
| [open-meteo-historical](clients/weather/open-meteo-historical.nu)     | openapi | <https://raw.githubusercontent.com/open-meteo/open-meteo/main/openapi/historical-weather.yml> |
| [open-meteo-marine](clients/weather/open-meteo-marine.nu)             | openapi | <https://raw.githubusercontent.com/open-meteo/open-meteo/main/openapi/marine.yml>             |
| [rapidapi-ecowetter](clients/weather/rapidapi-ecowetter.nu)           | openapi | <https://api.apis.guru/v2/specs/rapidapi.com/ecowetter/1.0.0/openapi.json>                    |
| [stormglass](clients/weather/stormglass.nu)                           | openapi | <https://api.apis.guru/v2/specs/stormglass.io/1.0.1/swagger.json>                             |
| [visualcrossing-weather](clients/weather/visualcrossing-weather.nu)   | openapi | <https://api.apis.guru/v2/specs/visualcrossing.com/weather/4.6/openapi.json>                  |
| [weather-gov](clients/weather/weather-gov.nu)                         | openapi | <https://api.weather.gov/openapi.json>                                                        |
| [weatherbit](clients/weather/weatherbit.nu)                           | openapi | <https://api.apis.guru/v2/specs/weatherbit.io/2.0.0/swagger.json>                             |
