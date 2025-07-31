#!/bin/bash

# vLLM LoRA Server Startup Script
# Usage: ./start_lora_server.sh

set -e

echo "🚀 Starting vLLM server with LoRA support..."

# Set environment variables for your configuration
export MODEL_NAME="huihui-ai/Llama-3.3-70B-Instruct-abliterated-finetuned-GPTQ-Int8"
export TRUST_REMOTE_CODE=true
export DISTRIBUTED_EXECUTOR_BACKEND=mp
export TENSOR_PARALLEL_SIZE=4
export MAX_PARALLEL_LOADING_WORKERS=32
export ENABLE_PREFIX_CACHING=true
export MAX_NUM_BATCHED_TOKENS=8192
export MAX_NUM_SEQS=32
export ENABLE_LORA=true
export MAX_LORAS=2
export MAX_LORA_RANK=64
export FULLY_SHARDED_LORAS=true
export ENABLE_CHUNKED_PREFILL=true
export MAX_CONCURRENCY=14
export MAX_SEQ_LEN_TO_CAPTURE=50000
export MAX_CPU_LORAS=12

# GPU configuration
export CUDA_VISIBLE_DEVICES=0,1,2,3
export NCCL_DEBUG=INFO
export TOKENIZERS_PARALLELISM=false

# Port configuration
PORT=${1:-80}

echo "📋 Configuration:"
echo "   Model: $MODEL_NAME"
echo "   Tensor Parallel: $TENSOR_PARALLEL_SIZE GPUs"
echo "   Max LoRAs: $MAX_LORAS"
echo "   Max LoRA Rank: $MAX_LORA_RANK"
echo "   Port: $PORT"
echo ""

# Create LoRA modules argument
LORA_MODULES_ARG=""
if [ -f "lora_config.json" ]; then
    echo "📁 Found LoRA configuration file"
    # Build separate JSON objects from lora_config.json array
    LORA_MODULES_ARG=$(python3 -c "
import json
with open('lora_config.json', 'r') as f:
    modules = json.load(f)
    # Create separate quoted JSON objects
    lora_args = []
    for module in modules:
        lora_json = json.dumps({
            'name': module['name'],
            'path': module['path'],
            'base_model_name': module['base_model_name']
        })
        # Add single quotes around each JSON object
        lora_args.append(f\"'{lora_json}'\")
    # Join with spaces to create multiple arguments
    print(' '.join(lora_args))
")
    MODULE_COUNT=$(echo "$LORA_MODULES_ARG" | wc -w)
    echo "   Found $MODULE_COUNT LoRA adapters"
else
    echo "⚠️  No LoRA config file found, starting without pre-loaded adapters"
fi

echo ""
echo "🎯 Starting server..."

# Build the command with LoRA modules if available
if [ -n "$LORA_MODULES_ARG" ]; then
    echo "🔗 Loading LoRA adapters..."
    echo "   Args: $LORA_MODULES_ARG"
    # Start vLLM server with LoRA modules as separate arguments
    eval "python -m vllm.entrypoints.openai.api_server \
        --model \"$MODEL_NAME\" \
        --host 0.0.0.0 \
        --port \"$PORT\" \
        --trust-remote-code \
        --distributed-executor-backend \"$DISTRIBUTED_EXECUTOR_BACKEND\" \
        --tensor-parallel-size \"$TENSOR_PARALLEL_SIZE\" \
        --max-parallel-loading-workers \"$MAX_PARALLEL_LOADING_WORKERS\" \
        --enable-prefix-caching \
        --max-num-batched-tokens \"$MAX_NUM_BATCHED_TOKENS\" \
        --max-num-seqs \"$MAX_NUM_SEQS\" \
        --enable-lora \
        --max-loras \"$MAX_LORAS\" \
        --max-lora-rank \"$MAX_LORA_RANK\" \
        --max-cpu-loras \"$MAX_CPU_LORAS\" \
        --fully-sharded-loras \
        --enable-chunked-prefill \
        --max-seq-len-to-capture \"$MAX_SEQ_LEN_TO_CAPTURE\" \
        --disable-log-stats \
        --lora-modules $LORA_MODULES_ARG"
else
    # Start vLLM server without LoRA modules
    python -m vllm.entrypoints.openai.api_server \
        --model "$MODEL_NAME" \
        --host 0.0.0.0 \
        --port "$PORT" \
        --trust-remote-code \
        --distributed-executor-backend "$DISTRIBUTED_EXECUTOR_BACKEND" \
        --tensor-parallel-size "$TENSOR_PARALLEL_SIZE" \
        --max-parallel-loading-workers "$MAX_PARALLEL_LOADING_WORKERS" \
        --enable-prefix-caching \
        --max-num-batched-tokens "$MAX_NUM_BATCHED_TOKENS" \
        --max-num-seqs "$MAX_NUM_SEQS" \
        --enable-lora \
        --max-loras "$MAX_LORAS" \
        --max-lora-rank "$MAX_LORA_RANK" \
        --max-cpu-loras "$MAX_CPU_LORAS" \
        --fully-sharded-loras \
        --enable-chunked-prefill \
        --max-model-len "$MAX_SEQ_LEN_TO_CAPTURE" \
        --disable-log-stats
fi

echo "✅ Server started! Access it at: http://0.0.0.0:$PORT"
echo "📖 API documentation available at: http://0.0.0.0:$PORT/docs"
