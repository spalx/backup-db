FROM alpine:3.23

RUN apk add --no-cache \
    bash \
    tzdata \
    curl \
    ca-certificates \
    postgresql-client \
    mongodb-tools \
    aws-cli \
    gzip \
    coreutils

# Install supercronic
RUN ARCH=$(uname -m) \
    && case "$ARCH" in \
         x86_64) SC_ARCH=amd64 ;; \
         aarch64) SC_ARCH=arm64 ;; \
         *) echo "unsupported arch: $ARCH" && exit 1 ;; \
       esac \
    && curl -L "https://github.com/aptible/supercronic/releases/latest/download/supercronic-linux-${SC_ARCH}" \
       -o /usr/local/bin/supercronic \
    && chmod +x /usr/local/bin/supercronic

WORKDIR /app

COPY backup.sh .
COPY entrypoint.sh .
COPY list-backups.sh .
COPY mongo-restore.sh .
COPY postgres-restore.sh .

RUN chmod +x *.sh

ENTRYPOINT ["/app/entrypoint.sh"]
