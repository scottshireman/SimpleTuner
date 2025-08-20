#!/bin/bash

# Export useful ENV variables, including all Runpod specific vars, to /etc/rp_environment
# This file can then later be sourced in a login shell
echo "Exporting environment variables..."
printenv |
	grep -E '^RUNPOD_|^PATH=|^HF_HOME=|^HF_TOKEN=|^HUGGING_FACE_HUB_TOKEN=|^WANDB_API_KEY=|^WANDB_TOKEN=|^_=' |
	sed 's/^\(.*\)=\(.*\)$/export \1="\2"/' >>/etc/rp_environment

# Add it to Bash login script
echo 'source /etc/rp_environment' >>~/.bashrc

# Vast.ai uses $SSH_PUBLIC_KEY
if [[ $SSH_PUBLIC_KEY ]]; then
	PUBLIC_KEY="${SSH_PUBLIC_KEY}"
fi

# Runpod uses $PUBLIC_KEY
if [[ $PUBLIC_KEY ]]; then
	mkdir -p ~/.ssh
	chmod 700 ~/.ssh
	echo "${PUBLIC_KEY}" >>~/.ssh/authorized_keys
	chmod 700 -R ~/.ssh
fi

# Start SSH server
service ssh start

# Login to HF
if [[ -n "${HF_TOKEN:-$HUGGING_FACE_HUB_TOKEN}" ]]; then
	# huggingface-cli login --token "${HF_TOKEN:-$HUGGING_FACE_HUB_TOKEN}" --add-to-git-credential
 	hf auth login --token "${HF_TOKEN:-$HUGGING_FACE_HUB_TOKEN}" --add-to-git-credential
else
	echo "HF_TOKEN or HUGGING_FACE_HUB_TOKEN not set; skipping login"
fi

# Login to WanDB
if [[ -n "${WANDB_API_KEY:-$WANDB_TOKEN}" ]]; then
	wandb login "${WANDB_API_KEY:-$WANDB_TOKEN}"
else
	echo "WANDB_API_KEY or WANDB_TOKEN not set; skipping login"
fi

if [[ -n "${JUPYTER_PASSWORD:-}" ]]; then
  echo "Starting JupyterLab"

  # These can fail depending on lab/server versions; don't block startup
  jupyter nbextension enable --py widgetsnbextension || true
  jupyter labextension disable "@jupyterlab/apputils-extension:announcements" || true

  exec jupyter lab \
    --allow-root \
    --no-browser \
    --port=8888 \
    --ip=0.0.0.0 \
    --ServerApp.iopub_msg_rate_limit=10000 \
    --ServerApp.rate_limit_window=3.0 \
    --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' \
    --ServerApp.token="${JUPYTER_PASSWORD}" \
    --ServerApp.allow_origin='*' \
    --ServerApp.preferred_dir=/workspace/crop-n-caption
else
  echo "Container started (no JUPYTER_PASSWORD set)"; exec sleep infinity
fi

# 🫡
# sleep infinity
