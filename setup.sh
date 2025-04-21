#!/bin/bash
set -euo pipefail

MARKER_DIR="$HOME/.lambda_stack_install"
mkdir -p "$MARKER_DIR"

# Initialize skip flags
SKIP_DRIVER=0
SKIP_CUDA=0
SKIP_CUDNN=0
SKIP_CONTAINER=0
SKIP_PYTORCH=0

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-driver)
      SKIP_DRIVER=1
      shift
      ;;
    --skip-cuda)
      SKIP_CUDA=1
      shift
      ;;
    --skip-cudnn)
      SKIP_CUDNN=1
      shift
      ;;
    --skip-container)
      SKIP_CONTAINER=1
      shift
      ;;
    --skip-pytorch)
      SKIP_PYTORCH=1
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

log() {
  echo -e "\n===== $1 =====\n"
}

# Step 1: Install NVIDIA drivers
if [ -f "$MARKER_DIR/step1_driver_installed" ]; then
  log "Step 1 already completed, skipping."
elif [ "$SKIP_DRIVER" -eq 1 ]; then
  log "Skipping Step 1 (NVIDIA driver) for this run."
else
  log "Step 1: Installing NVIDIA driver 560..."
  sudo add-apt-repository -y ppa:graphics-drivers/ppa
  sudo apt update
  sudo apt install -y nvidia-driver-560 nvidia-dkms-560
  touch "$MARKER_DIR/step1_driver_installed"
  log "Step 1 complete. Reboot recommended."
fi

# Step 2: Install CUDA Toolkit
if [ -f "$MARKER_DIR/step2_cuda_installed" ]; then
  log "Step 2 already completed, skipping."
elif [ "$SKIP_CUDA" -eq 1 ]; then
  log "Skipping Step 2 (CUDA) for this run."
else
  log "Step 2: Installing CUDA 12.8..."
  CUDA_RUNFILE="cuda_12.8.1_570.124.06_linux.run"
  if [ ! -f "$CUDA_RUNFILE" ]; then
    wget https://developer.download.nvidia.com/compute/cuda/12.8.1/local_installers/$CUDA_RUNFILE
  fi
  sudo sh $CUDA_RUNFILE --silent --toolkit --samples
  rm -f $CUDA_RUNFILE
  touch "$MARKER_DIR/step2_cuda_installed"
  log "Step 2 complete."
fi

# Step 3: Manual cuDNN installation
if [ -f "$MARKER_DIR/step3_cudnn_installed" ]; then
  log "Step 3 already completed, skipping."
elif [ "$SKIP_CUDNN" -eq 1 ]; then
  log "Skipping Step 3 (cuDNN) for this run."
else
  log "Step 3: Install cuDNN manually, then mark as done."
  log "After installing cuDNN, run: touch $MARKER_DIR/step3_cudnn_installed"
  exit 0
fi

# Step 4: Install NVIDIA Container Toolkit
if [ -f "$MARKER_DIR/step4_container_toolkit_installed" ]; then
  log "Step 4 already completed, skipping."
elif [ "$SKIP_CONTAINER" -eq 1 ]; then
  log "Skipping Step 4 (Container Toolkit) for this run."
else
  log "Step 4: Installing NVIDIA Container Toolkit..."
  distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
  curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/nvidia-docker.gpg > /dev/null
  curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
  sudo apt update
  sudo apt install -y nvidia-container-toolkit
  sudo systemctl restart docker
  touch "$MARKER_DIR/step4_container_toolkit_installed"
  log "Step 4 complete."
fi

# Step 5: Install PyTorch
if [ -f "$MARKER_DIR/step5_pytorch_installed" ]; then
  log "Step 5 already completed, skipping."
elif [ "$SKIP_PYTORCH" -eq 1 ]; then
  log "Skipping Step 5 (PyTorch) for this run."
else
  log "Step 5: Installing PyTorch 2.1.0 (CUDA 11.8)..."
  sudo apt install -y python3 python3-pip
  pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
  touch "$MARKER_DIR/step5_pytorch_installed"
  log "Step 5 complete."
fi

log "Installation complete!"
