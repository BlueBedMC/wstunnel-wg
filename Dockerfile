# ---------- Builder ----------
FROM rust:latest AS builder

WORKDIR /app
COPY . .

RUN cargo build --release

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