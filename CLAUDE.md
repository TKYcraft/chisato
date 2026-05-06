# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Chisato is a Rails API-only backend for a Minecraft notification bot (TKYcraft). It has no database — ActiveRecord is not loaded. All domain logic lives in `lib/`.

## Commands

```bash
# Start development environment
docker compose up -d --build

# Run all tests (inside container)
docker exec -it chisato-server bundle exec rspec

# Run a single spec
docker exec -it chisato-server bundle exec rspec spec/lib/acl/acl_spec.rb

# Check running containers
docker compose ps
```

## Architecture

### API Endpoints (`app/controllers/api/v1/`)

| Controller | Route | Purpose |
|---|---|---|
| `Servers::StatusController` | `GET /api/v1/servers/status` | Fetch Minecraft server status via TCP |
| `Texture::FaceController` | `GET /api/v1/texture/face/:id.png` | Fetch player face image |
| `HealthCheckController` | `GET /api/v1/health_check` | Health check |
| `TeapotController` | `GET /api/v1/teapot` | 418 response |

### Domain Libraries (`lib/`)

**`lib/acl/acl.rb`** — Validates the user-provided `host` parameter for the server status endpoint. Blocks private/reserved IP ranges and validates TLD against `config/tld_list.yaml`. Raises `Acl::DeniedHostError` on rejection.

**`lib/minetools/server_status_tool/server_status.rb`** — Connects to Minecraft servers via raw TCP socket using the Minecraft handshake protocol. Parses the JSON status payload directly from the byte stream. Default port: 25565.

**`lib/minetools/face_tool/face.rb`** — Fetches Minecraft player face images by calling the Mojang API (`api.mojang.com` → `sessionserver.mojang.com`) to resolve UUID and skin URL, then crops and composites the face + hat layers using RMagick. Raises on errors; the fallback to `app/assets/images/steve.png` is implemented in `Api::V1::Texture::FaceController`.

### Configuration

- **`config/tld_list.yaml`** — Required at boot; app exits if missing. Loaded into `App::Application.config.tld_list`.
- **`MC_PORT_ALLOW_MORE_THAN`** env var — Minimum allowed Minecraft port (default: 1023). Ports must be strictly greater than this value.
- `config/application.rb` loads all `lib/` autoload paths and disables unused Rails frameworks (ActiveRecord, ActionMailer, etc.).

### Testing

Specs mirror the lib structure under `spec/lib/` and request specs under `spec/requests/`. The `compose.rspec.yaml` file is used for running tests in CI against a production-like image build.
