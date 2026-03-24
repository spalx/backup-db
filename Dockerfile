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
RUN curl -L https://github.com/aptible/supercronic/releases/latest/download/supercronic-linux-amd64 \
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
