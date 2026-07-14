FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
      curl \
      git \
      ca-certificates \
      build-essential \
      python3 \
      nodejs \
      npm \
    && rm -rf /var/lib/apt/lists/*

# Install Cursor Agent CLI at build time (org image factory).
RUN curl -fsSL https://cursor.com/install | bash

ENV PATH="/root/.cursor/bin:/root/.local/bin:/usr/local/bin:$PATH"

WORKDIR /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV PORT=8080

ENTRYPOINT ["/entrypoint.sh"]
