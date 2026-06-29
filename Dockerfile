# Build with the released machin (no language features beyond v0.82 needed), then a
# slim runtime: the binary links OpenSSL (Ed25519/HMAC + the HTTPS calls to Google)
# and needs CA certs to verify Google's TLS.
FROM debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends curl gcc libc6-dev libssl-dev libsqlite3-dev ca-certificates && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://raw.githubusercontent.com/javimosch/machin/main/install.sh | sh && cp /root/.local/bin/machin /usr/local/bin/machin
COPY . /src
RUN cd /src && machin encode framework/machweb.src framework/sso.src ui.src app.src > app.mfl && machin build app.mfl -o /usr/local/bin/machin-auth

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends libssl3 libsqlite3-0 ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=build /usr/local/bin/machin-auth /usr/local/bin/machin-auth
ENV PORT=8080
WORKDIR /data
EXPOSE 8080
ENTRYPOINT ["machin-auth"]
