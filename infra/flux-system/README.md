# flux-system

This directory contains additional configurations for the `flux-system` namespace, such as Telegram notifications for FluxCD error events.

## Configuration

1. In `notifications.yaml`, replace `YOUR_CHAT_ID` with your actual Telegram chat ID.
2. In `secrets/flux-system/telegram-token.yaml`, replace `YOUR_BOT_TOKEN` with your actual Telegram bot token, and re-encrypt the file with SOPS:
   `sops -e -i secrets/flux-system/telegram-token.yaml`
