#!/usr/bin/env bash
# Builds and pushes ghcr.io/spalx/db-backup:<version> for linux/amd64 and linux/arm64, then tags the commit.
#
#   ./publish.sh 1.3
set -euo pipefail

IMAGE="ghcr.io/spalx/db-backup"
PLATFORMS="linux/amd64,linux/arm64"
BUILDER="db-backup"

fail() {
  echo "publish.sh: $1" >&2
  exit 1
}

VERSION="${1:-}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || fail "usage: ./publish.sh <version>, e.g. 1.3"

cd "$(dirname "$0")"

[ -z "$(git status --porcelain)" ] || fail "the working tree isn't clean; commit or discard first"

git fetch --quiet origin master
git merge-base --is-ancestor HEAD origin/master || fail "HEAD isn't on origin/master; push it first"

git rev-parse --quiet --verify "refs/tags/v$VERSION" >/dev/null && fail "git tag v$VERSION exists already"
git ls-remote --exit-code --tags origin "refs/tags/v$VERSION" >/dev/null && fail "git tag v$VERSION exists on origin"

if docker buildx imagetools inspect "$IMAGE:$VERSION" >/dev/null 2>&1; then
  fail "$IMAGE:$VERSION is published already; a version is never pushed twice"
fi

# The default docker driver builds only the host's platform, so use a docker-container builder.
docker buildx inspect "$BUILDER" >/dev/null 2>&1 || docker buildx create --name "$BUILDER" --driver docker-container >/dev/null

docker buildx build \
  --builder "$BUILDER" \
  --platform "$PLATFORMS" \
  --provenance=true \
  --tag "$IMAGE:$VERSION" \
  --push \
  .

PUBLISHED=$(docker buildx imagetools inspect "$IMAGE:$VERSION" --raw)
for platform in ${PLATFORMS//,/ }; do
  arch="${platform#linux/}"
  echo "$PUBLISHED" | grep -q "\"architecture\": \"$arch\"" || fail "$IMAGE:$VERSION was pushed without $platform"
done

git tag "v$VERSION"
git push --quiet origin "v$VERSION"

echo "Published $IMAGE:$VERSION for $PLATFORMS from $(git rev-parse --short HEAD), tagged v$VERSION"
