# Task: Add server icon API (`GET /api/v1/servers/icon`)

Status: **planned, not implemented** (planned on 2026-07-04)

## Context

The server status endpoint (`GET /api/v1/servers/status`) already fetches the full
Minecraft status JSON, which includes the server icon as a `favicon` field
(`"data:image/png;base64,<...>"`), but `Api::V1::Servers::StatusController#convert`
drops it when building the response. There is currently no way to get the server icon.

This task adds a new endpoint that returns the server icon as a PNG image, reusing
the same data source.

### Key findings from investigation

- `Minetools::ServerStatusTool::ServerStatus#fetch_status` (lib/minetools/server_status_tool/server_status.rb)
  parses the whole status payload via `JSON.parse` and keeps it as-is, so
  `@server.status["favicon"]` is already available. The lib spec
  (spec/lib/minetools/server_status_tool/server_status_spec.rb) even asserts that
  `favicon` survives parsing. **No changes to `lib/` are needed.**
- The existing request-spec fixture for status
  (spec/requests/api/v1/servers/status_spec.rb, `server_status` hash) already contains a
  `favicon` field — note it uses `"data: image/png;base64,..."` **with a space after
  `data:`**, which informs how tolerant the prefix parsing must be.
- `Api::V1::Texture::FaceController` is the template for returning PNG binaries
  (`send_data`, cache-control headers).

### Decisions (confirmed with the owner)

| Decision | Choice |
|---|---|
| Path | `GET /api/v1/servers/icon?host=...&port=...` (servers namespace, index action) |
| Response | Decoded PNG binary (`send_data`, `image/png`, inline) |
| No / malformed favicon | `404` with **empty body** (`head :not_found`) |
| Shared validation | Duplicate the host/port/ACL block from StatusController; do NOT extract a concern (codebase style is self-contained controllers; extract only if a 3rd endpoint appears) |
| Cache headers | Yes — copy the FaceController `set_cache_control_header` / `use_cache?` pattern verbatim (`expires_in 1.hours, public: true`, `cache=no` disables) |

## Changes

### 1. `config/routes.rb`

Add one line inside the existing `namespace :servers` block:

```ruby
namespace :servers do
  resources :status, only: [:index]
  resources :icon, only: [:index]
end
```

URL: `/api/v1/servers/icon`, path helper: `api_v1_servers_icon_index_path`.

### 2. `app/controllers/api/v1/servers/icon_controller.rb` (new)

Class `Api::V1::Servers::IconController < ApplicationController`, action `index`.
Use **tab indentation** (all existing controllers use tabs). Reference implementation:

```ruby
class Api::V1::Servers::IconController < ApplicationController
	MC_PORT_ALLOW_MORE_THAN = App::Application.config.mc_port_allow_more_than
	FAVICON_PREFIX = /\Adata:\s*image\/png;base64,/

	before_action :set_cache_control_header

	def index
		@tld_list = App::Application.config.tld_list["TLD"]
		@host = params[:host]
		@port = nil
		@port = params[:port].to_i unless params[:port].nil?

		begin
			if @port.present?
				raise ArgumentError unless MC_PORT_ALLOW_MORE_THAN < @port
			end

			@acl = Acl::Acl.new @host, @tld_list
			@acl.filter!
			@server = Minetools::ServerStatusTool::ServerStatus.new host: @host, port: @port
			@server.fetch_status!

		rescue ArgumentError => e
			render status: 400, json: {message: e.message}
			return
		rescue Acl::DeniedHostError => e
			render status: 400, json: {message: e.message}
			return
		rescue Minetools::ServerStatusTool::ServiceUnavailableError => e
			render status: 404, json: {message: e.message}
			return
		rescue Minetools::ServerStatusTool::ConnectionError => e
			render status: 500, json: {message: e.message}
			return
		rescue => e
			render status: 500, json: {message: e.message}
			return
		end

		@icon_bin = decode_favicon @server.status["favicon"]
		if @icon_bin.nil?
			head :not_found
			return
		end
		send_data @icon_bin, type: "image/png", disposition: 'inline', status: 200
	end

	private def decode_favicon _favicon
		return nil unless _favicon.class == String
		return nil unless FAVICON_PREFIX.match? _favicon
		encoded = _favicon.sub(FAVICON_PREFIX, "").gsub(/\s+/, "")
		return Base64.strict_decode64(encoded)
	rescue ArgumentError
		return nil
	end

	private def use_cache?
		param = params[:cache]
		return true if param.nil?
		return false if param.downcase == "no"
		return true
	end

	private def set_cache_control_header
		if use_cache?
			expires_in 1.hours, public: true
		else
			expires_now
		end
	end
end
```

Design rationale (keep these properties when implementing):

- **Prefix regex `\Adata:\s*image\/png;base64,`** — tolerates the space seen in the
  existing spec fixture (`data: image/png;base64,`) while still rejecting non-PNG
  data URIs. Do not just split on `,`; that would serve arbitrary payloads with an
  `image/png` content type.
- **`Base64.strict_decode64` after stripping whitespace** — lenient `decode64`
  silently drops invalid characters and can emit garbage bytes labeled as PNG.
  The `gsub(/\s+/, "")` covers servers that wrap base64 with newlines. The `base64`
  gem is already in Gemfile.lock (via activesupport); no Gemfile change needed.
- **Decoding happens AFTER the main begin/rescue block** — `strict_decode64` raises
  `ArgumentError`, which must not fall into the port-validation `ArgumentError → 400`
  handler. `decode_favicon` rescues it locally and returns nil (→ 404 empty body).
- **Missing / wrong-prefix / undecodable favicon all → 404 empty body** — from the
  client's contract perspective all three mean "this server has no usable icon".
- **Class-level `MC_PORT_ALLOW_MORE_THAN` constant** — required so specs can
  `stub_const("Api::V1::Servers::IconController::MC_PORT_ALLOW_MORE_THAN", ...)`
  exactly like the status spec does.

### 3. `spec/requests/api/v1/servers/icon_spec.rb` (new)

`RSpec.describe "Api::V1::Servers::Icons", type: :request`. Follow the idioms of
`spec/requests/api/v1/servers/status_spec.rb` (tabs, `instance_spy` on
`Minetools::ServerStatusTool::ServerStatus` and `Acl::Acl`, canned status hash with
`deep_stringify_keys.freeze`, `stub_const` for the port constant) and of
`spec/requests/api/v1/texture/face_spec.rb` (image/cache-header assertions).

For success cases use a favicon that actually decodes:

```ruby
let(:favicon_bytes) { "fake png bytes" }
# in the status hash:
favicon: "data:image/png;base64,#{Base64.strict_encode64(favicon_bytes)}"
```

Cases to cover:

1. **200 success**: `get api_v1_servers_icon_index_path, params: {host: "example.com"}`
   → status 200, `Content-Type == "image/png"`, `response.body == favicon_bytes`,
   `Access-Control-Allow-Origin == "*"`, `Cache-Control` includes `public` and `max-age=3600`.
2. **Space-in-prefix fixture form**: favicon `"data: image/png;base64,<valid b64>"` → 200, decodes.
3. **`cache=no` param** → 200 and `Cache-Control` includes `no-cache` (see face_spec).
4. **favicon key absent** from status hash → 404, empty body.
5. **Malformed favicon — wrong MIME prefix** (`"data:image/jpeg;base64,..."`) → 404, empty body.
6. **Malformed favicon — invalid base64** (`"data:image/png;base64,%%%"`) → 404, empty body.
7. **Port validation** with `stub_const("Api::V1::Servers::IconController::MC_PORT_ALLOW_MORE_THAN", 8888)`:
   port 8887 → 400 (and neither `ServerStatus` nor `Acl::Acl` received `:new`),
   port 8888 → 400, port 8889 → 200 (mirrors status_spec).
8. **ACL denied**: in a context where only `ServerStatus` is stubbed (real `Acl::Acl`),
   `host: "192.168.0.1"` → 400 with `json["message"] == "given IP Address is not allowed length."`.
9. **`ServiceUnavailableError`** raised from `fetch_status!` → 404 with JSON `message`.
10. **`ConnectionError`** raised from `fetch_status!` → 500 with JSON `message`.

### 4. `CLAUDE.md`

Add a row to the "API Endpoints" table:

```
| `Servers::IconController` | `GET /api/v1/servers/icon` | Fetch Minecraft server icon (favicon) as PNG |
```

## Implementation order

1. Route in `config/routes.rb`
2. `app/controllers/api/v1/servers/icon_controller.rb`
3. `spec/requests/api/v1/servers/icon_spec.rb`
4. CLAUDE.md endpoint table

## Verification

```bash
docker compose up -d --build
docker exec -it chisato-server bundle exec rspec spec/requests/api/v1/servers/icon_spec.rb
docker exec -it chisato-server bundle exec rspec   # full suite, check for regressions

# Optional manual check against a real public Minecraft server:
curl -sv "http://localhost:3000/api/v1/servers/icon?host=<public-mc-host>" -o icon.png
curl -sv "http://localhost:3000/api/v1/servers/icon?host=192.168.0.1"   # expect 400 (ACL denied)
```

## Reference files

- `app/controllers/api/v1/servers/status_controller.rb` — validation/rescue pattern to copy
- `app/controllers/api/v1/texture/face_controller.rb` — `send_data` + cache header pattern
- `lib/minetools/server_status_tool/server_status.rb` — status source (no changes)
- `spec/requests/api/v1/servers/status_spec.rb` — request spec idioms + favicon fixture
- `spec/requests/api/v1/texture/face_spec.rb` — image/cache-header spec idioms
