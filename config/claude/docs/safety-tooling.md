# Safety Tooling (`safetytooling`)

Shared Python library for AI safety research. Unified async LLM inference API across providers (OpenAI, Anthropic, Gemini, Together, OpenRouter, DeepSeek, VLLM) with caching, rate limiting, cost tracking, and batch support.

**Repo**: `https://github.com/safety-research/safety-tooling`

**Install**: Add to `pyproject.toml` with `uv add "safetytooling @ git+https://github.com/safety-research/safety-tooling.git"`, or install directly with `uv pip install "safetytooling @ git+https://github.com/safety-research/safety-tooling.git"`.

## Key Imports

```python
# Inference
from safetytooling.apis import InferenceAPI
from safetytooling.apis.batch_api import BatchInferenceAPI

# Data models
from safetytooling.data_models import ChatMessage, MessageRole, Prompt, LLMParams, LLMResponse

# Experiment config base class
from safetytooling.utils.experiment_utils import ExperimentConfigBase

# Environment setup (loads .env, API keys)
from safetytooling.utils import utils
```

## Minimal Usage

```python
from safetytooling.apis import InferenceAPI
from safetytooling.data_models import ChatMessage, MessageRole, Prompt
from safetytooling.utils import utils
from pathlib import Path

utils.setup_environment()  # loads .env

api = InferenceAPI(cache_dir=Path(".cache"))

prompt = Prompt(messages=[
    ChatMessage(role=MessageRole.user, content="Hello")
])

# InferenceAPI.__call__ is async
response = await api(
    model_id="gpt-4o-mini",
    prompt=prompt,
    print_prompt_and_response=True,
)
# response: list[LLMResponse]
```

## Core Classes

| Class | Module | Purpose |
|-------|--------|---------|
| `InferenceAPI` | `safetytooling.apis` | Main entry point. Async `__call__` dispatches to provider-specific backends. Handles caching, rate limiting, retries, cost tracking. |
| `BatchInferenceAPI` | `safetytooling.apis.batch_api` | Bulk prompt processing via provider batch APIs (OpenAI, Anthropic). |
| `ChatMessage` | `safetytooling.data_models` | Single message with `role` (MessageRole enum) and `content`. Supports text, images, audio. |
| `Prompt` | `safetytooling.data_models` | List of `ChatMessage`s. Converts to provider-specific formats. |
| `LLMResponse` | `safetytooling.data_models` | Response: `completion` (str), `cost` (float), `stop_reason`, `usage`. |
| `LLMParams` | `safetytooling.data_models` | Generation params: `temperature`, `top_p`, `max_tokens`, etc. |
| `ExperimentConfigBase` | `safetytooling.utils.experiment_utils` | Base pydantic config for experiments. Initializes `InferenceAPI`, manages logging directories. |

## Features

- **Caching**: File-based (default) or Redis. Keyed on model + prompt + params.
- **Rate limiting**: Built-in per-provider concurrency limits, configurable.
- **Cost tracking**: Running total for OpenAI models.
- **Response validation**: Pass `is_valid` callable — auto-retries on invalid responses.
- **Prompt logging**: Optional human-readable `.txt` log files.
- **Multi-provider**: Single `model_id` string routes to correct backend.
- **Multimodal**: Images and audio supported for compatible models.

