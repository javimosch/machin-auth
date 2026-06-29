# machin-auth

A **self-hostable auth broker** — Google sign-in to a signed identity token, in one
~76 kB binary. Your keys, no SaaS, no cross-app tracking. A self-hostable take on
[Shoo](https://shoo.dev) (which is hosted-only).

## What it does

- **Google sign-in** (OAuth2 authorization-code flow) for any of your apps, from one broker.
- Issues a **domain-scoped, EdDSA-signed JWT** — the subject is `HMAC(secret, google_sub | your_origin)`, so the same person is a *different, unlinkable* id at every app (no cross-app tracking).
- Apps verify the token with **any standard JOSE library** against the published JWKS — no SDK, no callback to this server. (Verified interoperable with Node's standard `crypto` Ed25519.)

## How an app uses it

```
1. send the user to:   https://auth.you.com/login?redirect=https://yourapp.com/cb
2. they sign in with Google
3. we redirect back to: https://yourapp.com/cb?token=<JWT>
4. verify the JWT against  https://auth.you.com/.well-known/jwks.json
```

The token: `{ iss, sub: <scoped id>, email, aud: <your origin>, iat, exp }`, `alg: EdDSA`.

Verify it like any JWT — e.g. with [`jose`](https://github.com/panva/jose):

```js
import { jwtVerify, createRemoteJWKSet } from 'jose'
const JWKS = createRemoteJWKSet(new URL('https://auth.you.com/.well-known/jwks.json'))
const { payload } = await jwtVerify(token, JWKS, { issuer: 'https://auth.you.com' })
// payload.sub is the user's stable id at your app; payload.email is their address
```

## Run it

Register one Google OAuth client (the broker's `/callback` is the redirect URI), then:

```bash
GOOGLE_CLIENT_ID=...  GOOGLE_CLIENT_SECRET=...  \
  AUTH_BASE_URL=https://auth.you.com \
  ALLOWED_ORIGINS=https://yourapp.com,https://other.com \
  ./build.sh && ./machin-auth
```

Or Docker: `docker build -t machin-auth . && docker run -p 8080:8080 -v $PWD/data:/data machin-auth`.

| env | meaning |
|---|---|
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | your Google OAuth client |
| `AUTH_BASE_URL` | the broker's public URL (its `/callback` is the OAuth redirect URI) |
| `ALLOWED_ORIGINS` | comma list of app origins allowed to receive tokens (open-redirect guard) |
| `TOKEN_TTL` | token lifetime in seconds (default 3600) |
| `PORT` | listen port (default 8080) |
| `DEMO=1` | enable `/demo` — issues a token for a fake user (no Google), for testing |

Try the flow with **no Google setup**: run with `DEMO=1 ALLOWED_ORIGINS=http://localhost:8080`, open the page, click *Try the demo sign-in*.

## Security

- The Ed25519 **signing key persists to `auth-seed.hex`** on first run — it's the key to every token; protect the file (it's git-ignored), back it up, mount it as a volume in Docker. Rotating it invalidates outstanding tokens.
- `ALLOWED_ORIGINS` is an open-redirect guard — only listed origins can receive a token.
- Terminate TLS at a reverse proxy (nginx/Caddy/Cloudflare); see the [machin deploy skill](https://github.com/javimosch/machin/blob/main/skills/machin-deploy/SKILL.md).
- It stores **nothing** — no user database, no session table. Identity lives only in the token it hands back.

## Built with machin

~250 lines of [machin](https://github.com/javimosch/machin) (MFL), **no new builtins** — composed from `machweb` (HTTP, signed cookies), `sso.src` (the OAuth dance + userinfo), and the crypto builtins (`ed25519_sign`/`ed25519_pub`, `hmac_sha256`, `base64`). One static-ish native binary; the EdDSA JWT + JWKS are hand-built and verified against standard JOSE tooling.

## License

MIT — Javier Leandro Arancibia. Built with [machin](https://github.com/javimosch/machin).
