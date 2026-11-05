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

# Pinned with its checksums, so two builds of one commit run the same cron. A newer one is a version of its own.
ARG SUPERCRONIC_VERSION=v0.2.48
ARG SUPERCRONIC_SHA256_AMD64=88c1b66b94c486f972fdd1a4d1f901e3e75ff04f749cddd60c5db573e3a33c6c
ARG SUPERCRONIC_SHA256_ARM64=50ae8755e04fa72812d0a1bc47a112a856811cc91cce7b6c875c378a850788bc
ARG TARGETARCH

RUN case "$TARGETARCH" in \
         amd64) SC_SHA256="$SUPERCRONIC_SHA256_AMD64" ;; \
         arm64) SC_SHA256="$SUPERCRONIC_SHA256_ARM64" ;; \
         *) echo "unsupported arch: $TARGETARCH" && exit 1 ;; \
       esac \
    && curl -fsSL "https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/supercronic-linux-${TARGETARCH}" \
       -o /usr/local/bin/supercronic \
    && echo "${SC_SHA256}  /usr/local/bin/supercronic" | sha256sum -c - \
    && chmod +x /usr/local/bin/supercronic

WORKDIR /app

COPY backup.sh .
COPY entrypoint.sh .
COPY list-backups.sh .
COPY mongo-restore.sh .
COPY postgres-restore.sh .

RUN chmod +x *.sh

ENTRYPOINT ["/app/entrypoint.sh"]
