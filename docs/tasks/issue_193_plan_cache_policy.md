# Issue #193 Plan: Fix cache policy (client `max-age=10` / CDN `s-maxage=3600`)

> **Note**: This plan is written to be self-contained so it can be executed in a different session without re-investigation.
> Repo: `/Users/yuuma/developments/chisato` (TKYcraft/chisato, Rails 8.1.3 (actionpack 8.1.3) / API-only / no DB).
> Base commit: `951f2eb` (main). Plan written: 2026-07-05. If other changes merge first, re-locate the code by string search instead of line numbers.

## Context

- **Issue #193** (open, "cache policyの修正", by Alicey0719): The Cloudflare (CF) cache configuration was changed so that the previously forced `no-store` is no longer applied. As a result, the origin's `Cache-Control: max-age=3600, public` now reaches clients directly, and **clients also keep a 3600-second cache**. The issue asks for something like `max-age=10, s-maxage=3600` (the issue text says "s-max-age", but the correct directive name is **`s-maxage`**).
- The issue references `spec/requests/api/v1/texture/face_spec.rb#L30` (the `max-age=3600` assertion).
- Intent: browsers (private caches) expire after **10 seconds**, while CF (shared cache) keeps the response for **1 hour via `s-maxage=3600`** to protect the origin. Shared caches prefer `s-maxage` over `max-age` (RFC 9111). The CF-side "respect origin headers" configuration change is already done (infra side, outside this repo).

## Findings (verified facts)

The following is the **complete** list of places that set cache headers (verified with `grep -rn "cache\|expires\|no_store" app/`):

| File | Current behavior | Action in this plan |
|---|---|---|
| `app/controllers/api/v1/texture/face_controller.rb:54-60` | `before_action :set_cache_control_header`. When `use_cache?` is true (default): `expires_in 1.hours, public: true` → `Cache-Control: max-age=3600, public`. Only with `cache=no` param: `expires_now` → `no-cache` | **Change** (main target of the issue) |
| `app/controllers/api/v1/teapot_controller.rb:5` | `expires_in 1.hours, public: true` | **Change** (same CF zone, apply the same policy) |
| `app/controllers/api/v1/health_check_controller.rb:5` | `no_store` | Keep (health checks must never be cached) |
| `app/controllers/api/v1/servers/status_controller.rb` | No explicit cache header → Rails default (`max-age=0, private, must-revalidate`). Not cached by CF or clients | Keep (server status needs freshness) |

Additional facts:

- `use_cache?` in the face controller is false only for `cache=no` (case-insensitive). `cache=false` / `cache=0` still enable caching (existing specs explicitly assert this behavior — it is intentional).
- The **404 steve fallback also gets the same header** (`set_cache_control_header` is a `before_action`, so it applies regardless of status). Today the 404 is already client-cached for 1h; after this change it will be CF-edge-cached for up to 1h (equivalent behavior; see Open Question 3).
- `config/environments/*.rb` `public_file_server.headers` (static files) are out of scope.

### Existing specs asserting cache headers (to update; line numbers at base commit)

| File:line | Current assertion |
|---|---|
| `spec/requests/api/v1/texture/face_spec.rb:30` | `include "max-age=3600"` (L31 asserts `include "public"`) |
| `spec/requests/api/v1/texture/face_spec.rb:282` | `include("max-age=3600")` (L281 asserts `include("public")`, "response headers" context) |
| `spec/requests/api/v1/teapot_spec.rb:14` | `include("max-age=3600")` (L13 asserts `include("public")`) |
| `spec/requests/api/v1/texture/face_spec.rb:56,65,74,83` | `cache=no` → `no-cache` / `cache=yes,false,0` → `public` (**unchanged**, do not touch) |
| `spec/requests/api/v1/health_check_spec.rb:13` | `no-store` (unchanged) |

## Design

### Mechanism: `expires_in` extras

actionpack's `ActionController::ConditionalGet#expires_in` emits any option key other than the known ones (`:public`, etc.) as a `"key=value"` extra in `Cache-Control` (behavior since Rails 5; same in actionpack 8.1.3). Therefore:

```ruby
expires_in 10.seconds, public: true, "s-maxage": 3600
```

produces `Cache-Control: max-age=10, public, s-maxage=3600` (directive order is an internal implementation detail, so specs keep asserting with `include`).

### Keep the policy in one place

To avoid duplicating the values (10 / 3600) in both the face and teapot controllers, add a helper to `ApplicationController` and call it from both:

```ruby
	def expires_with_cdn_cache
		# Client (private cache) expires in 10s; CDN (shared cache) keeps 3600s.
		# See issue #193.
		expires_in 10.seconds, public: true, "s-maxage": 3600
	end
```

- No env var (like the `MC_PORT_ALLOW_MORE_THAN` pattern): the issue only asks for fixed values and they are not expected to change often. Can be a follow-up if needed.

## Implementation steps

### Step 1 — Add helper to `app/controllers/application_controller.rb`

Add `expires_with_cdn_cache` (code above) after `message_of` (before `private def set_response_header`). **This file uses tab indentation.** Comments in English.

### Step 2 — `app/controllers/api/v1/teapot_controller.rb:5`

```ruby
    expires_in 1.hours, public: true
```
→
```ruby
    expires_with_cdn_cache
```

**This file uses 2-space indentation** (keep it).

### Step 3 — `app/controllers/api/v1/texture/face_controller.rb:56`

Inside `set_cache_control_header`:

```ruby
			expires_in 1.hours, public: true
```
→
```ruby
			expires_with_cdn_cache
```

Do not touch the `expires_now` branch (`cache=no`). **This file uses tab indentation.**

### Step 4 — Update specs

**`spec/requests/api/v1/texture/face_spec.rb`** (tab indentation):

- L30 (inside the "success 200" example) — replace `max-age=3600` with `max-age=10` and add one `s-maxage=3600` assertion (keep the existing `public` line at L31):
  ```ruby
  			expect(response.headers["Cache-Control"]).to include "max-age=10"
  			expect(response.headers["Cache-Control"]).to include "s-maxage=3600"
  			expect(response.headers["Cache-Control"]).to include "public"
  ```
  Note on `include` substring matching: `include "max-age=10"` cannot false-match against `s-maxage=3600`, so it is safe. But the old assertion `include "max-age=3600"` **would keep passing as a substring of `s-maxage=3600`** — it must be rewritten to `max-age=10`, not left in place.
- L282 (inside the "have correct cache-control" example): same change — `max-age=3600` → `max-age=10`, plus one `s-maxage=3600` assertion.
- L56/65/74/83 (cache param context): unchanged.

**`spec/requests/api/v1/teapot_spec.rb`** (tab indentation):

- Update the example at L11-15:
  ```ruby
  		it "returns Cache-Control header including public, max-age" do
  			get api_v1_teapot_index_path
  			expect(response.headers["Cache-Control"]).to include("public")
  			expect(response.headers["Cache-Control"]).to include("max-age=10")
  			expect(response.headers["Cache-Control"]).to include("s-maxage=3600")
  		end
  ```

### Step 5 — Update `CLAUDE.md` (recommended)

Add one line to the Configuration section:
- "Cacheable endpoints (texture/face, teapot) send `Cache-Control: max-age=10, public, s-maxage=3600` via `ApplicationController#expires_with_cdn_cache` — short client cache, 1h Cloudflare edge cache (issue #193)."

## Verification

> Per the user's global CLAUDE.md, ask for permission before running tests or any code.

```bash
docker compose up -d --build

curl -sI http://localhost:3000/api/v1/teapot | grep -i cache-control
# → Cache-Control: max-age=10, public, s-maxage=3600 (directive order may vary)
curl -sI "http://localhost:3000/api/v1/texture/face/KrisJelbring.png" | grep -i cache-control
# → same (face calls the real Mojang API; even the 404 steve fallback carries the same header)
curl -sI "http://localhost:3000/api/v1/texture/face/KrisJelbring.png?cache=no" | grep -i cache-control
# → no-cache (unchanged)
curl -sI http://localhost:3000/api/v1/health_check | grep -i cache-control
# → contains no-store (unchanged)

# All specs
docker exec -it chisato-server bundle exec rspec
```

## Files changed

| Action | File |
|---|---|
| Modify | `app/controllers/application_controller.rb` (add `expires_with_cdn_cache` helper) |
| Modify | `app/controllers/api/v1/teapot_controller.rb` |
| Modify | `app/controllers/api/v1/texture/face_controller.rb` |
| Modify | `spec/requests/api/v1/texture/face_spec.rb` (2 places) |
| Modify | `spec/requests/api/v1/teapot_spec.rb` (1 place) |
| Modify | `CLAUDE.md` (1 line) |

## ⚠️ Interaction with the issue #17 plan (`docs/tasks/issue_17_plan.md`)

Both plans touch `teapot_controller.rb` / `teapot_spec.rb` / `face_spec.rb` / `application_controller.rb` / `CLAUDE.md`. **Whichever plan is executed second must adjust**:

- Step 6 of the issue #17 plan (teapot rewrite) assumes `expires_in 1.hours, public: true`. If #193 merges first, keep the `expires_with_cdn_cache` line as-is there.
- Both plans reference spec line numbers at base commit `951f2eb`. Once either merges, line numbers shift — the later one must re-locate targets by string search, not line numbers.
- If both are done on one branch, applying #17 (structural changes) before #193 (header changes) is easier.

## Behavior changes (state these in the PR)

1. Clients (browsers / the bot's HTTP cache) will cache face and teapot responses for only **10 seconds instead of 3600**. However, the CF edge caches them for 1h via `s-maxage=3600`, so origin traffic should barely increase (CF hits are served from the edge).
2. Skin-update propagation becomes "up to 1h at the CF edge + 10s at the client" (previously 1h at the client, with no way to purge). Being able to purge the CF cache for immediate propagation is the point of this fix.

## PR / commit

- Branch name example: `fix/issue-193-cache-policy`
- Commit example (conventional commits): `fix: split client and CDN cache TTL (max-age=10, s-maxage=3600)`
- PR body: include `Closes #193` and the behavior changes above.

## Open questions for plan review (defaults chosen)

1. **Teapot is included** (it has the same `expires_in 1.hours` and sits behind the same CF zone). To limit the change to face only, drop Step 2 and the teapot_spec change.
2. **Values are fixed to `max-age=10` / `s-maxage=3600` as written in the issue** (the issue says "等" / "or similar", so other values are possible). Not made configurable via env var.
3. **The face 404 steve fallback carries the same header** (existing behavior preserved). The 404 image can stay in the CF edge cache for up to 1h. If faster propagation for newly-created users is desired, a shorter TTL for the 404 path would need extra work (out of scope here).
4. The `cache=no` param behavior (`no-cache`, not cached by CF or clients) is unchanged.
