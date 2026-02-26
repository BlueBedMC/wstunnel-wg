# ---------- Builder ----------
FROM rust:latest AS builder

WORKDIR /app

# Copy dependency files first (workspace aware)
COPY Cargo.toml Cargo.lock ./
COPY wstunnel/Cargo.toml wstunnel/Cargo.toml
COPY wstunnel-cli/Cargo.toml wstunnel-cli/Cargo.toml

# Pre-fetch dependencies (cached layer)
RUN cargo fetch

# Now copy the full source
COPY . .

# Build release binary
RUN cargo build --release --bin wstunnel


# ---------- Runtime ----------
FROM debian:trixie-slim

RUN useradd -ms /bin/bash app && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        dumb-init && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /home/app

COPY --from=builder /app/target/release/wstunnel /home/app/wstunnel

RUN chown app:app /home/app/wstunnel

USER app

EXPOSE 8080

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["/home/app/wstunnel", "server", "--listen", "0.0.0.0:8080", "--forward", "127.0.0.1:51820"]