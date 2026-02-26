# ---------- Builder ----------
FROM rust:latest AS builder

WORKDIR /app

# 1️⃣ Copy only dependency files first (for caching)
COPY Cargo.toml Cargo.lock ./

# 2️⃣ Create a dummy main so dependencies can be built
RUN mkdir src && echo "fn main() {}" > src/main.rs

# 3️⃣ Build dependencies (this layer gets cached)
RUN cargo build --release && rm -rf src

# 4️⃣ Now copy the real source code
COPY . .

# 5️⃣ Build the actual application
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

CMD ["/home/app/wstunnel", "server", "--restrict-to", "127.0.0.1:51820", "0.0.0.0:8080"]