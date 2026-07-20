# Plan: Issue #17 — RFC 9457 JSON errors, 404 for root/unmatched paths, top-level healthcheck

- Issue: https://github.com/TKYcraft/chisato/issues/17 ("fix: root で 404 を返す", open)
- Related: issue #133 (health check endpoint, closed — implemented as `GET /api/v1/health_check`)
- Plan written: 2026-07-05, based on commit `951f2eb` (main). **Line numbers below refer to that commit; re-check them if the base has moved.**
- Environment: Rails 8.1.3 (`config.load_defaults 7.0`), API-only, no database, Ruby 3.4.10.

## Goals

1. Requests to `/` and any unmatched path return **404 with an RFC 9457 (Problem Details) JSON body** instead of an empty body.
2. Add a **top-level healthcheck endpoint** `GET /health_check` and point the Docker healthcheck at it (it currently curls `/`).
3. **Refactor all JSON error responses (4xx/5xx) to RFC 9457** (`application/problem+json`).
4. Healthcheck response body becomes **RFC 9457-style** (same members, served as `application/json` since 2xx must not use `problem+json`).

## Verified facts (no re-investigation needed)

- `GET /` currently returns **200 with an empty body** — NOT 404. The empty 0-byte `public/index.html` is served by `ActionDispatch::Static` (static file server is enabled in all environments: `production.rb`/`test.rb` set `config.public_file_server.enabled = true`, dev defaults to on).
- Unmatched paths return **404 with an empty body**: no catch-all route exists, and `ActionDispatch::PublicExceptions` finds no `public/404.html` (`public/` holds only `favicon.ico`, `robots.txt`, empty `index.html`).
- `config.exceptions_app` is not set anywhere. `config/environments/test.rb:32` has the deprecated boolean `config.action_dispatch.show_exceptions = false` — with the catch-all-route approach no exception is raised on the 404 path, so this file needs no change.
- `compose.yaml:16` healthcheck: `["CMD", "curl", "-m", "5", "http://localhost:3000"]` — hits root, and without `-f` even a 404/500 passes (latent bug, fixed here). `curl` is already installed in the dev image.
- CI (`.github/workflows/rspec.yml`) overlays `compose.rspec.yaml`, which empties the healthcheck, and never curls endpoints — the compose healthcheck change does not affect CI.
- `ApplicationController` (`app/controllers/application_controller.rb`): `before_action :set_response_header` adds `Access-Control-Allow-Origin: *` to every response; `render_status` (shape `{status, status_message, data, messages}`) is **dead code with zero callers**; `message_of(status)` maps 200/201/400/401/403/404/409/418/500 to reason phrases and raises `NotImplementedError` otherwise (no 503 yet).
- Current error/response renderers (complete list):
  - `api/v1/health_check_controller.rb`: `index` → `no_store` + 200 `{message: "ok", status: 200}`; `rescue_from(Exception) { render head: 503 }` (`render head:` is broken syntax; real fix is part of this task).
  - `api/v1/teapot_controller.rb`: 418 `{message: "I m a teapot.", status: 418}` + `expires_in 1.hours, public: true`; same broken `rescue_from`.
  - `api/v1/servers/status_controller.rb:21-36`: rescue clauses render `{message: e.message}` with 400 (ArgumentError, Acl::DeniedHostError), 404 (ServiceUnavailableError), 500 (ConnectionError, bare rescue).
  - `api/v1/texture/face_controller.rb:8,14`: two inline `render json: {message: "..."}, status: 400`; on fetch failure falls back to steve.png **image** with status 404 (`send_data`, `image/png`) — stays an image, see decision 4.
- Specs asserting on bodies that will change:
  - `spec/requests/api/v1/health_check_spec.rb:19` (`message == "ok"`)
  - `spec/requests/api/v1/teapot_spec.rb:20` (`message == "I m a teapot."`)
  - `spec/requests/api/v1/texture/face_spec.rb:111,123` and 10 occurrences at 174–264 (`json["message"]`)
  - `spec/requests/api/v1/servers/status_spec.rb:103-145`, 6 occurrences (`json["message"]`)
  - `spec/requests/static/static_contents_spec.rb:11-21` expects `/` and `/index.html` → 200 (must be removed; they become 404)
- Route helper for the new top-level route will be `health_check_path`; no collision with the existing `api_v1_health_check_index_path`.
- `robots.txt` does not reference `index.html`; favicon/robots keep working via the Static middleware (it runs before the router).

## Design decisions (with rationale)

1. **Catch-all route, not `exceptions_app`.** A matching route means no `ActionController::RoutingError`, so request specs get real 404 responses without touching the deprecated `show_exceptions` setting. Controller-internal exceptions are already rescued per controller. (`exceptions_app` for 500-level defense in depth is a possible follow-up, out of scope.)
2. **Delete `render_status` (dead code) and introduce `render_problem`** in `ApplicationController`. Keep `message_of` as the `title` source and add `503 => "Service Unavailable"` (needed by the `rescue_from` blocks; currently 503 would raise `NotImplementedError`).
3. **RFC 9457 mapping**: `type` is `"about:blank"` for now (no custom problem-type URIs in this project); per RFC 9457 §4.2.1, when type is `about:blank` the `title` is the HTTP reason phrase (`message_of`). Former `{message:}` strings move to `detail` **unchanged**, so spec expectations only change key names. `instance` = `request.path`.
4. **Keep the steve.png image fallback in face_controller** (404 + `image/png`): clients embed the URL as an image; a JSON body would break rendering. Only the JSON 400s there are converted.
5. **Teapot (418) is included** in the conversion (it is a 4xx). `title` becomes "I'm a teapot" (from `message_of`), `detail` keeps the original "I m a teapot.".
6. **Reuse `Api::V1::HealthCheckController#index` for `GET /health_check`** via routing only — no new controller. `/api/v1/health_check` remains for backward compatibility (both return the new body).
7. **Healthcheck 200 body**: RFC 9457 is defined for errors only, so the 200 response uses the same member set but `Content-Type: application/json` (NOT `application/problem+json`). See "Open questions".
8. **Routes**: `root to: "errors#not_found", via: :all` (the glob `*path` does not match `/`; `root` accepts `via:` override since it merges options into `match "/"`), plus final `match "*path", to: "errors#not_found", via: :all, format: false` (`format: false` avoids format-segment splitting on paths like `/foo.` / `/foo.png`).

## Implementation steps

### Step 1 — Delete `public/index.html`

```bash
git rm public/index.html
```

`/` and `/index.html` then fall through to the router.

### Step 2 — Refactor `app/controllers/application_controller.rb`

Remove `render_status`, add `render_problem`, add 503 to `message_of`. This file uses **tab indentation** — keep it. Target content:

```ruby
class ApplicationController < ActionController::API
	before_action :set_response_header

	def render_problem _status, _detail=nil, _type="about:blank"
		# guard
		raise ArgumentError unless _status.class == Integer

		render status: _status, content_type: "application/problem+json", json: {
			type: _type,
			title: message_of(_status),
			status: _status,
			detail: _detail,
			instance: request.path
		}.compact
	end

	def message_of _status=500
		# keep the existing case/when body, add one branch:
		# when 503 then
		# 	return "Service Unavailable"
	end

	private def set_response_header
		response.headers['Access-Control-Allow-Origin'] = "*"
	end
end
```

Notes: `render json:` honors the `content_type:` option. `.compact` drops `detail` when nil (all RFC 9457 members are optional).

### Step 3 — New `app/controllers/errors_controller.rb` (tabs)

```ruby
class ErrorsController < ApplicationController
	def not_found
		render_problem 404, "The requested resource could not be found."
	end
end
```

### Step 4 — `config/routes.rb` (keep 2-space indentation)

```ruby
Rails.application.routes.draw do
  get "health_check", to: "api/v1/health_check#index"

  namespace :api do
    namespace :v1 do
      resources :health_check, only: [:index]
      resources :teapot, only: [:index]
      namespace :servers do
        resources :status, only: [:index]
      end
      namespace :texture do
        resources :face, only: [:show]
      end
    end
  end

  root to: "errors#not_found", via: :all
  match "*path", to: "errors#not_found", via: :all, format: false
end
```

Ordering matters: the catch-all MUST be last. The stale generator comment (`# Defines the root path route ("/")`) can be dropped.

### Step 5 — `app/controllers/api/v1/health_check_controller.rb` (2-space file)

```ruby
class Api::V1::HealthCheckController < ApplicationController
  rescue_from(Exception) { render_problem 503 }

  def index
    no_store   # disable cache.
    render status: 200, json: {
      type: "about:blank",
      title: "OK",
      status: 200,
      detail: "Service is healthy.",
      instance: request.path
    }
  end
end
```

### Step 6 — `app/controllers/api/v1/teapot_controller.rb` (2-space file)

```ruby
class Api::V1::TeapotController < ApplicationController
  rescue_from(Exception) { render_problem 503 }

  def index
    expires_in 1.hours, public: true
    render_problem 418, "I m a teapot."
  end
end
```

### Step 7 — `app/controllers/api/v1/servers/status_controller.rb` rescue clauses (lines 21–36, tabs)

Replace each `render status: N, json: {message: e.message}` with `render_problem N, e.message` (keep the `return`s):

```ruby
		rescue ArgumentError => e
			render_problem 400, e.message
			return
		rescue Acl::DeniedHostError => e
			render_problem 400, e.message
			return
		rescue Minetools::ServerStatusTool::ServiceUnavailableError => e
			render_problem 404, e.message
			return
		rescue Minetools::ServerStatusTool::ConnectionError => e
			render_problem 500, e.message
			return
		rescue => e
			render_problem 500, e.message
			return
		end
```

Do NOT change the 200 success render (`render status: 200, json: convert(...)`).

### Step 8 — `app/controllers/api/v1/texture/face_controller.rb` (lines 8 and 14, tabs)

```ruby
		unless File.extname(@path) == ".png"
			render_problem 400, "file extention must be .png"
			return nil
		end
```

```ruby
		unless @size
			render_problem 400, "parameter size must be Integer (8 ~ size ~ 2048) and multiple of 8"
			return nil
		end
```

Keep the existing `detail` strings byte-identical (specs depend on them). Do NOT touch the steve fallback (`send_data ... status: @status`).

### Step 9 — `compose.yaml` healthcheck (line 16)

```yaml
      test: ["CMD", "curl", "-f", "-m", "5", "http://localhost:3000/health_check"]
```

(`-f` makes non-2xx fail the check; target moves off root.)

### Step 10 — Specs

New `spec/requests/errors_spec.rb` (tab indentation, project request-spec style):

```ruby
require 'rails_helper'

RSpec.describe "Errors", type: :request do
	describe 'not_found' do
		it "returns 404 with /" do
			get "/"
			expect(response).to have_http_status(404)
			expect(response.headers["Access-Control-Allow-Origin"]).to eq "*"
		end

		it "returns 404 with unknown path" do
			get "/nonexistent"
			expect(response).to have_http_status(404)
		end

		it "returns 404 with nested unknown path" do
			get "/api/v2/unknown"
			expect(response).to have_http_status(404)
		end

		it "returns 404 with path including extension" do
			get "/foo.png"
			expect(response).to have_http_status(404)
		end

		it "returns 404 with /index.html" do
			get "/index.html"
			expect(response).to have_http_status(404)
		end

		it "returns 404 with non-GET verb" do
			post "/nonexistent"
			expect(response).to have_http_status(404)
		end

		it "returns 404 with non-GET verb on root" do
			post "/"
			expect(response).to have_http_status(404)
		end

		it "returns RFC 9457 problem details body" do
			get "/nonexistent"
			expect(response.headers["Content-Type"]).to include "application/problem+json"
			json = JSON.parse(response.body)
			expect(json["type"]).to eq "about:blank"
			expect(json["title"]).to eq "Not Found"
			expect(json["status"]).to eq 404
			expect(json["detail"]).to eq "The requested resource could not be found."
			expect(json["instance"]).to eq "/nonexistent"
		end
	end
end
```

New `spec/requests/health_check_spec.rb` (top-level route):

```ruby
require 'rails_helper'

RSpec.describe "HealthCheck", type: :request do
	describe 'index' do
		it "returns http success" do
			get health_check_path
			expect(response).to have_http_status(200)
			expect(response.headers["Access-Control-Allow-Origin"]).to eq "*"
		end

		it "returns Cache-Control header including no-store" do
			get health_check_path
			expect(response.headers["Cache-Control"]).to include "no-store"
		end

		it "returns RFC 9457 style response body" do
			get health_check_path
			json = JSON.parse(response.body)
			expect(json["type"]).to eq "about:blank"
			expect(json["title"]).to eq "OK"
			expect(json["status"]).to eq 200
			expect(json["detail"]).to eq "Service is healthy."
			expect(json["instance"]).to eq "/health_check"
		end
	end
end
```

Existing spec updates:

| File | Change |
|---|---|
| `spec/requests/api/v1/health_check_spec.rb` | Replace body assertions (`message == "ok"`) with `title == "OK"`, `status == 200`, `type == "about:blank"`, `instance == "/api/v1/health_check"` |
| `spec/requests/api/v1/teapot_spec.rb` | `json["message"]` → `json["title"] == "I'm a teapot"` and `json["detail"] == "I m a teapot."`; add `Content-Type` includes `application/problem+json` |
| `spec/requests/api/v1/texture/face_spec.rb` | `json["message"]` → `json["detail"]` (12 places; expected strings unchanged) |
| `spec/requests/api/v1/servers/status_spec.rb` | `json["message"]` → `json["detail"]` (6 places; expected strings unchanged) |
| `spec/requests/static/static_contents_spec.rb` | Delete the `describe "./public/index.html"` block (covered by errors_spec); keep favicon/robots blocks |

### Step 11 — `CLAUDE.md`

- Retitle the endpoint section to `### API Endpoints (\`app/controllers/\`)` and add rows for `GET /health_check` (reuses api/v1 controller; Docker healthcheck target) and the `ErrorsController` catch-all.
- Add a note: all 4xx/5xx JSON responses use RFC 9457 Problem Details (`application/problem+json`; members `type`/`title`/`status`/`detail`/`instance`); exception: texture/face fallback returns a steve.png image with status 404.

## Edge cases already analyzed (do not re-derive)

- HEAD: matched via `via: :all`; Rack strips the body → 404 empty body, correct per HTTP.
- Accept headers: irrelevant — explicit `render json:`; no `respond_to`, no `UnknownFormat` risk.
- Invalid-encoding paths (`/%FF`): ActionDispatch returns 400 before routing — pre-existing, out of scope.
- Rails built-in `/up`: not routed here; catch-all 404s it; `/health_check` is the sanctioned endpoint.
- CORS header is applied by `before_action` and therefore present on all `render_problem` responses.

## Breaking changes (MUST be listed in the PR body)

1. Root `/`: 200 empty body → 404 problem+json. External uptime monitors watching `/` must switch to `/health_check`.
2. Error bodies: `{message: "..."}` → RFC 9457 (`message` key is gone; text now in `detail`). **Any client (e.g. the TKYcraft bot) parsing `message` on errors must be updated.**
3. Healthcheck body: `{"message":"ok","status":200}` → RFC 9457-style members. External monitors asserting `message == "ok"` must be updated.
4. Teapot response shape changes likewise.

## Verification

Per the user's global rules: do NOT run tests or code without explicit user permission; ask first, or have the user run these.

```bash
docker compose up -d --build
docker compose ps        # wait for healthy (healthcheck now: /health_check with -f)

curl -i http://localhost:3000/                     # 404 problem+json, title "Not Found"
curl -i http://localhost:3000/nonexistent          # 404 problem+json, instance "/nonexistent"
curl -i http://localhost:3000/foo.png              # 404 problem+json
curl -i -X POST http://localhost:3000/             # 404 problem+json
curl -i http://localhost:3000/index.html           # 404 problem+json
curl -i http://localhost:3000/health_check         # 200 application/json, title "OK", Cache-Control no-store
curl -i http://localhost:3000/api/v1/health_check  # 200, same body shape
curl -i http://localhost:3000/api/v1/teapot        # 418 problem+json, title "I'm a teapot"
curl -i "http://localhost:3000/api/v1/servers/status?host=127.0.0.1"  # 400 problem+json (ACL denied)
curl -i http://localhost:3000/favicon.ico          # 200
curl -i http://localhost:3000/robots.txt           # 200

docker exec -it chisato-server bundle exec rspec
```

## Files changed (summary)

| Op | File |
|---|---|
| delete | `public/index.html` |
| add | `app/controllers/errors_controller.rb` |
| add | `spec/requests/errors_spec.rb` |
| add | `spec/requests/health_check_spec.rb` |
| modify | `app/controllers/application_controller.rb` |
| modify | `app/controllers/api/v1/health_check_controller.rb` |
| modify | `app/controllers/api/v1/teapot_controller.rb` |
| modify | `app/controllers/api/v1/servers/status_controller.rb` |
| modify | `app/controllers/api/v1/texture/face_controller.rb` |
| modify | `config/routes.rb` |
| modify | `compose.yaml` |
| modify | `spec/requests/api/v1/health_check_spec.rb` |
| modify | `spec/requests/api/v1/teapot_spec.rb` |
| modify | `spec/requests/api/v1/texture/face_spec.rb` |
| modify | `spec/requests/api/v1/servers/status_spec.rb` |
| modify | `spec/requests/static/static_contents_spec.rb` |
| modify | `CLAUDE.md` |

## Execution notes for a future session

- Work on a feature branch (never push to main directly), e.g. `fix/issue-17-rfc9457-404`.
- Conventional commit style (see `git log`), e.g. `fix: return RFC 9457 JSON errors for root and unmatched paths`. PR body: `Closes #17` + the breaking-changes list above.
- Indentation is mixed on purpose: app controllers/specs use tabs; `config/routes.rb`, `health_check_controller.rb`, `teapot_controller.rb` use 2 spaces. Match each file's existing style.
- New code comments must be in English (user's global rule).
- Line numbers in this plan are from commit `951f2eb`; verify with a quick read before editing if the branch has advanced.

## Open questions (confirm with the maintainer if possible; defaults chosen below)

1. Healthcheck 200 response: kept as `application/json` with RFC 9457-style members (using `application/problem+json` on a 2xx would violate RFC 9457). Change Step 5's content type if problem+json is explicitly desired.
2. Teapot (418) is included in the RFC 9457 conversion. Drop Step 6 (and the teapot spec change) to exclude it.
3. The texture/face steve-image 404 fallback intentionally stays an image, not JSON.
