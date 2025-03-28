#!/bin/bash
set -e

# Ensure the .env file exists
if [ -f .env ]; then
  # Load the environment variables
  source .env
fi

pwd
echo "Building and shipping image to $DOCKER_CI_REGISTRY_IMAGE_BASE/$COMPONENT"
#Build date for opencontainers
BUILDDATE="'$(date '+%FT%T%z' | sed -E -n 's/(\+[0-9]{2})([0-9]{2})$/\1:\2/p')'" #rfc 3339 date
IMAGE_LABELS="$IMAGE_LABELS --label org.opencontainers.image.created=$BUILDDATE --label build-date=$BUILDDATE"
#Description for opencontainers
BUILDTITLE=$(echo $CI_PROJECT_TITLE | tr " " "_")
IMAGE_LABELS="$IMAGE_LABELS --label org.opencontainers.image.title=$BUILDTITLE --label org.opencontainers.image.description=$BUILDTITLE"
#Add ref.name for opencontainers
IMAGE_LABELS="$IMAGE_LABELS --label org.opencontainers.image.ref.name=$DOCKER_CI_REGISTRY_IMAGE_BASE:$CI_COMMIT_REF_NAME"

#Build Version Label and Tag from git tag, LastVersionTagInGit was placed by a previous job artifact
if [[ "$VERSIONLABELMETHOD" == "LastVersionTagInGit" ]]; then VERSIONLABEL=$(cat VERSIONTAG.txt); fi
if [[ "$VERSIONLABELMETHOD" == "OnlyIfThisCommitHasVersion" ]]; then VERSIONLABEL=$CI_COMMIT_TAG; fi
if [[ ! -z "$VERSIONLABEL" ]]; then
  IMAGE_LABELS="$IMAGE_LABELS --label org.opencontainers.image.version=$VERSIONLABEL"
  ADDITIONALTAGLIST="$ADDITIONALTAGLIST $VERSIONLABEL"
fi

#ADDITIONALTAGLIST="$ADDITIONALTAGLIST $CI_COMMIT_REF_NAME $CI_COMMIT_SHORT_SHA"
#ADDITIONALTAGLIST="$ADDITIONALTAGLIST $CI_COMMIT_REF_NAME"
#if [[ "$CI_COMMIT_BRANCH" == "$CI_DEFAULT_BRANCH" ]]; then ADDITIONALTAGLIST="$ADDITIONALTAGLIST latest"; fi
if [[ -n "$ADDITIONALTAGLIST" ]]; then
  for TAG in $ADDITIONALTAGLIST; do
    FORMATTEDTAGLIST="${FORMATTEDTAGLIST} --tag $DOCKER_CI_REGISTRY_IMAGE_BASE/$PROJECT_NAME:$TAG "
  done
fi

#Reformat Docker tags to kaniko's --destination argument:
FORMATTEDTAGLIST=$(echo "${FORMATTEDTAGLIST}" | sed s/\-\-tag/\-\-destination/g)

#env
echo "FORMATTEDTAGLIST: $FORMATTEDTAGLIST"
#echo $IMAGE_LABELS

echo "Kaniko arguments to run: --context $CI_PROJECT_DIR --dockerfile $CI_PROJECT_DIR/infra/docker/$COMPONENT/Dockerfile $KANIKO_CACHE_ARGS $FORMATTEDTAGLIST $IMAGE_LABELS --registry-certificate $DOCKER_CI_REGISTRY=$SSL_CERT_FILE"

docker run -ti --rm -v $(pwd):/workspace -v $(pwd)/config.json:/kaniko/.docker/config.json:ro \
                    -v $(pwd)/additional-ca-cert-bundle.crt:/kaniko/ssl/certs/additional-ca-cert-bundle.crt:ro \
                    gcr.io/kaniko-project/executor:latest \
                    --dockerfile=Dockerfile \
                    --destination=amnexus:9003/it/python/oracle_uv:3.13.2-slim
