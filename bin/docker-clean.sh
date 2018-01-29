#!/bin/bash

set -ex
echo "Deleting containers ..."
docker ps -q -a | xargs docker rm

echo "Delete all untagged images ..."
docker images -q -f dangling=true | xargs --no-run-if-empty docker rmi
