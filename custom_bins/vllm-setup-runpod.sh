#!/bin/bash
# add uv to path
source $HOME/.local/bin/env
rm -rf $HOME/.venv
uv venv --python 3.12 $HOME/.venv
source $HOME/.venv/bin/activate
uv pip install vllm --torch-backend=auto
uv pip install flash-attn --no-build-isolation
uv pip install transformers accelerate bitsandbytes huggingface_hub datasets fastapi uvicorn pydantic

