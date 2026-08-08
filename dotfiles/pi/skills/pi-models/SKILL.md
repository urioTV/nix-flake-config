---
name: pi-models
description: "Konfiguruje modele AI w pi poprzez models.json. Domyślnie edytuje plik w repo (dotfiles/pi/models.json), nie w ~/.pi/agent. Rozróżnia wbudowanych providerów (llama.cpp, openai, anthropic, etc.) od customowych — dla wbudowanych używa modelOverrides, dla customowych tablicy models[]. Traktuj zawsze najpierw jako źródło prawdy."
---

# Pi Models Configuration Skill

Konfiguracja modeli AI w pi poprzez `models.json`. Skill **domyślnie edytuje plik w repo** (`dotfiles/pi/models.json`), nie w `~/.pi/agent/models.json` (który jest symlinkiem do nix-store).

## Kiedy używać

- "dodaj mi model X do providera Y" / "skonfiguruj model reasoning" / "zmień contextWindow"
- "dodaj provider dla mojego lokalnego serwera" (vLLM, llama.cpp router, LM Studio)
- "nadpisz domyślne ustawienia dla modelu X"
- "jak skonfigurować reasoning model z chat-template"
- użytkownik prosi o konfigurację modelu w pi

**Traktuj zawsze jako źródło prawdy** — domyślna ścieżka to `dotfiles/pi/models.json` w bieżącym repo.

## Kluczowe rozróżnienie: wbudowani vs customowi providerzy

### Wbudowani providerzy (używaj `modelOverrides`)

Pi ma wbudowanych kilka providerów. Dla nich **NIE** używaj tablicy `models` (bo by *zastąpiła* wszystkie modele discoverowane przez pi). Używaj `modelOverrides` do nadpisania pól konkretnych modeli.

**Wbudowani providerzy:**
- `llama.cpp` — router llama-server z discoverowaniem modeli przez `/v1/models` i `/llama`
- `openai` — GPT modele
- `anthropic` — Claude modele
- `google` — Gemini modele
- `openrouter` — routing przez OpenRouter
- `azure-openai` — Azure OpenAI

**Przykład — wbudowany `llama.cpp`:**
```json
{
  "providers": {
    "llama.cpp": {
      "baseUrl": "http://172.16.25.21:8080/v1",
      "api": "openai-completions",
      "modelOverrides": {
        "Qwen3.5-122B-A10B-APEX": {
          "name": "Qwen3.5 122b A10B Apex",
          "reasoning": true,
          "contextWindow": 262144,
          "input": ["text", "image"],
          "compat": {
            "supportsDeveloperRole": false,
            "supportsReasoningEffort": false,
            "thinkingFormat": "chat-template",
            "chatTemplateKwargs": {
              "enable_thinking": {
                "$var": "thinking.enabled"
              }
            }
          }
        }
      }
    }
  }
}
```

**Kluczowe:**
- `modelOverrides` matchuje po **dokładnym id** modelu zwracanym przez `/v1/models` (wielkie litery, myślniki: `Qwen3.5-122B-A10B-APEX`, nie `qwen3.5-122b-a10b-apex`)
- Dla `llama.cpp` z `openai-completions` reasoning wymaga `thinkingFormat: "chat-template"` + `chatTemplateKwargs.enable_thinking: { "$var": "thinking.enabled" }`
- `llama.cpp` nie rozumie `developer` role ani `reasoning_effort` → `supportsDeveloperRole: false`, `supportsReasoningEffort: false`

### Customowi providerzy (używaj tablicy `models`)

Własne providerzy (np. `lm-studio-thinkstation`, `my-vllm`, `local-ollama`) **muszą** mieć tablicę `models` z jawnymi wpisami. Nie mają discoverowania modeli — pi nie wie, jakie modele są dostępne.

**Przykład — customowy `lm-studio-thinkstation`:**
```json
{
  "providers": {
    "lm-studio-thinkstation": {
      "baseUrl": "http://127.0.0.1:1234/",
      "api": "anthropic-messages",
      "models": [
        {
          "id": "qwen3.5-122b-a10b-apex",
          "name": "Qwen3.5 122b A10B Apex",
          "reasoning": true,
          "contextWindow": 262144,
          "input": ["text", "image"]
        }
      ]
    }
  }
}
```

**Kluczowe:**
- Tablica `models` jest **wymagana** dla customowych providerów
- Każdy model w tablicy to jawnie zdefiniowany model — pi nie skanuje `/v1/models`
- `api` może być na poziomie provider (domyślne dla wszystkich modeli) lub modelu (override)

## Weryfikacja obsługi modelu przed konfiguracją

**Kluczowe:** Nie kopiuj ustawień między modelami bez weryfikacji. Każdy model ma inne limity i możliwości.

### Sprawdź co model faktycznie obsługuje

**1. Zapytaj router `/v1/models`:**

```bash
curl -s <baseUrl>/v1/models | jq '.data[] | {id, context_window, max_model_len, max_context_length, architecture}'
```

Zwróć uwagę na:
- `context_window` / `max_model_len` / `max_context_length` — prawdziwy kontekst modelu
- `architecture.input_modalities` — czy obsługuje image (`["text", "image"]` vs `["text"]`)
- `owned_by` — nazwa modelu

**2. Sprawdź dokumentację modelu:**

Dla modeli z Hugging Face / llama.cpp presets:
- Preset llama.cpp często określa `ctx-size` (context window)
- GGUF metadata zawiera `n_ctx_train` (trenowany kontekst)
- Dokumentacja modelu podaje limity reasoning, multimodalności

**3. Dla reasoning modeli:**

Sprawdź czy model:
- Obsługuje `thinking.type: "adaptive"` (adaptive thinking) vs `thinking.type: "enabled"/"disabled"`
- Wymaga `output_config.effort` dla adaptive thinking
- Ma wyłączone thinking przez template (nie przez API parametry)
- Obsługuje `reasoning_effort` (OpenAI-style) czy `enable_thinking` (chat-template)

**4. Dla multimodalnych modeli:**

Sprawdź:
- `architecture.input_modalities` z `/v1/models`
- Czy mmproj (multimodal projector) jest załadowany
- Czy server obsługuje image w promptach (llama.cpp z `--mmproj`)

**5. Testuj przed użyciem:**

```bash
# Test context window
curl -s <baseUrl>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "<id>", "messages": [{"role": "user", "content": "test"}], "max_tokens": 100}'

# Test image (jeśli multimodalny)
curl -s <baseUrl>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "<id>", "messages": [{"role": "user", "content": [{"type": "image_url", "image_url": {"url": "data:image/png;base64,<base64>"}}, {"type": "text", "text": "opisz"}]}]}'
```

### Procedura konfiguracyjna

### Krok 1: Sprawdź istniejące modele.json

```bash
cat dotfiles/pi/models.json
```

Sprawdź:
- Czy provider już istnieje?
- Czy to wbudowany czy customowy provider?
- Czy już ma `modelOverrides` lub `models`?

### Krok 2: Sprawdź dostępne modele (dla customowych)

Dla customowych providerów z `baseUrl`, sprawdź co serwuje:

```bash
curl -s <baseUrl>/v1/models
```

Zwróć uwagę na:
- Dokładne `id` modelu (matchuje w `modelOverrides` lub `models`)
- `context_window` / `max_context_length`
- `owned_by` (dla nazwy)

### Krok 3: Edytuj models.json

**Dla wbudowanych providerów (llama.cpp, openai, etc.):**

Dodaj/aktualizuj `modelOverrides`:
```json
"llama.cpp": {
  "baseUrl": "...",
  "api": "openai-completions",
  "modelOverrides": {
    "Model-ID-Z-Routera": {
      "name": "Display Name",
      "reasoning": true,
      "contextWindow": 262144,
      "input": ["text", "image"],
      "compat": { ... }
    }
  }
}
```

**Dla customowych providerów:**

Dodaj provider z tablicą `models`:
```json
"my-custom-provider": {
  "baseUrl": "http://localhost:8000/v1",
  "api": "openai-completions",
  "models": [
    {
      "id": "model-id",
      "name": "Model Name",
      "reasoning": true,
      "contextWindow": 128000,
      "input": ["text", "image"]
    }
  ]
}
```

Lub dodaj model do istniejącego customowego providera:
```json
"my-custom-provider": {
  "baseUrl": "...",
  "api": "...",
  "models": [
    { "id": "existing-model" },
    {
      "id": "new-model",
      "name": "New Model",
      "reasoning": true,
      "contextWindow": 262144,
      "input": ["text"]
    }
  ]
}
```

### Krok 4: Walidacja JSON

```bash
python3 -c "import json; json.load(open('dotfiles/pi/models.json')); print('JSON OK')"
```

### Krok 5: Zastosowanie zmian

Plik `~/.pi/agent/models.json` jest symlinkiem do `dotfiles/pi/models.json` (out-of-store symlink przez `mkOutOfStoreSymlink` w `modules/ai/pi/_pi.nix`). Zmiana w repo jest **od razu żywa** — pi przeładowuje plik przy każdym otwarciu `/model`.

Nie potrzebujesz przebudowy home-manager ani restartu pi.

## Compat flags dla różnych providerów

### llama.cpp + openai-completions

```json
{
  "compat": {
    "supportsDeveloperRole": false,
    "supportsReasoningEffort": false,
    "thinkingFormat": "chat-template",
    "chatTemplateKwargs": {
      "enable_thinking": { "$var": "thinking.enabled" }
    }
  }
}
```

**Dlaczego:**
- `--jinja` w llama-server czyta `chat_template_kwargs`
- Nie rozumie `developer` role (używa `system`)
- Nie rozumie `reasoning_effort` (używa `enable_thinking` przez template)

### Ollama + openai-completions

```json
{
  "compat": {
    "supportsDeveloperRole": false,
    "supportsReasoningEffort": false
  }
}
```

### OpenRouter + openai-completions

```json
{
  "compat": {
    "openRouterRouting": {
      "only": ["provider1", "provider2"],
      "order": ["provider1", "provider2"]
    }
  }
}
```

### Anthropic-compatible z adaptive thinking

```json
{
  "compat": {
    "forceAdaptiveThinking": true,
    "allowEmptySignature": false
  }
}
```

## Pola modelu

| Pole | Typ | Domyślne | Opis |
|------|-----|----------|------|
| `id` | string | **wymagane** | ID modelu (match z `/v1/models` dla overrides) |
| `name` | string | `id` | Display name |
| `reasoning` | bool | `false` | Czy model wspiera extended thinking |
| `contextWindow` | int | `128000` | Context window w tokenach |
| `maxTokens` | int | `16384` | Maksymalna liczba tokenów wyjścia |
| `input` | array | `["text"]` | `["text"]` lub `["text", "image"]` |
| `api` | string | provider's api | Override API dla tego modelu |
| `compat` | object | - | Compat flags |
| `cost` | object | `{input:0, output:0, ...}` | Koszt na milion tokenów |

## Przykłady z mojej konfiguracji

**llama.cpp (wbudowany) z dwoma modelami:**
```json
{
  "providers": {
    "llama.cpp": {
      "baseUrl": "http://172.16.25.21:8080/v1",
      "api": "openai-completions",
      "modelOverrides": {
        "Qwen3.5-122B-A10B-APEX": {
          "name": "Qwen3.5 122b A10B Apex",
          "reasoning": true,
          "contextWindow": 262144,
          "input": ["text", "image"],
          "compat": {
            "supportsDeveloperRole": false,
            "supportsReasoningEffort": false,
            "thinkingFormat": "chat-template",
            "chatTemplateKwargs": {
              "enable_thinking": { "$var": "thinking.enabled" }
            }
          }
        },
        "unsloth/Laguna-S-2.1-GGUF:MXFP4_MOE": {
          "reasoning": true,
          "contextWindow": 800000,
          "compat": {
            "supportsDeveloperRole": false,
            "supportsReasoningEffort": false,
            "thinkingFormat": "chat-template",
            "chatTemplateKwargs": {
              "enable_thinking": { "$var": "thinking.enabled" }
            }
          }
        }
      }
    }
  }
}
```

**lm-studio-thinkstation (custom) z trzema modelami:**
```json
{
  "providers": {
    "lm-studio-thinkstation": {
      "baseUrl": "http://127.0.0.1:1234/",
      "api": "anthropic-messages",
      "models": [
        {
          "id": "qwen3.5-122b-a10b-apex",
          "name": "Qwen3.5 122b A10B Apex",
          "reasoning": true,
          "contextWindow": 262144,
          "input": ["text", "image"]
        },
        {
          "id": "thinkingcap-qwen3.6-27b",
          "name": "ThinkingCap Qwen3.6 27b",
          "reasoning": true,
          "contextWindow": 262144,
          "input": ["text", "image"]
        },
        {
          "id": "laguna-s-2.1",
          "name": "Laguna-S-2.1-GGUF:MXFP4_MOE",
          "reasoning": true,
          "contextWindow": 800000,
          "input": ["text"]
        }
      ]
    }
  }
}
```

## Pułapki i uwagi

1. **`modelOverrides` nie działa dla customowych providerów bez `models`** — dla customowych providerów modele **muszą** być jawnie zdefiniowane w tablicy `models`. `modelOverrides` działa tylko na modele wbudowane lub extension-registered.

2. **Dokładne matchowanie ID** — `modelOverrides` matchuje po dokładnym ID modelu z `/v1/models`. `Qwen3.5-122B-A10B-APEX` ≠ `qwen3.5-122b-a10b-apex`.

3. **`models` zastępuje, `modelOverrides` nadpisuje** — dla wbudowanych providerów:
   - `models: [...]` zastępuje wszystkie modele (uwaga!)
   - `modelOverrides: { "id": { ... } }` nadpisuje tylko ten jeden model

4. **Żywe przeładowanie** — zmiana w `dotfiles/pi/models.json` jest od razu widoczna w pi (bez rebuildu). Pi przeładowuje plik przy każdym otwarciu `/model`.

5. **API na poziomie modelu** — możesz override'ować `api` dla konkretnego modelu:
   ```json
   {
     "id": "my-model",
     "api": "anthropic-messages",
     "reasoning": true
   }
   ```

## Dokumentacja referencyjna

- `docs/models.md` — pełna dokumentacja `models.json`
- `docs/llama-cpp.md` — konfiguracja llama.cpp
- `docs/custom-provider.md` — custom providerzy i rozszerzenia
- `~/.pi/agent/extensions/custom-providers.ts` — implementacja rozszerzenia custom-providers
