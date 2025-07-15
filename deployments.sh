#!/bin/bash

set -e

HOST="ubuntu@192.168.1.69"
APP_DIR="/home/ubuntu/app"

echo "[INFO] Connecting to $HOST"
ssh -o StrictHostKeyChecking=no $HOST bash <<EOF
  echo "[INFO] cd $APP_DIR"
  cd $APP_DIR

  echo "[INFO] docker-compose pull"
  docker-compose pull

  echo "[INFO] docker-compose up -d"
  docker-compose up -d

  echo "[INFO] Deployment finished."
