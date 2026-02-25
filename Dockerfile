# -------- Builder Stage --------
FROM rust:1.93-trixie AS builder

RUN apt-get update && \
    apt-get install -y cmake libclang-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN cargo build --release --features jemalloc

# -------- Runtime Stage --------
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

ENV RUST_LOG=INFO
ENV SERVER_PROTOCOL=ws
ENV SERVER_LISTEN=0.0.0.0
ENV SERVER_PORT=8080

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/home/app/wstunnel", "server", "--mode", "websocket", "--listen", "0.0.0.0:8080"]