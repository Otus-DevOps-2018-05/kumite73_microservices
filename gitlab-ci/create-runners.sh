docker exec -it gitlab-runner gitlab-runner register --non-interactive \
    --url http://35.198.110.108/ \
    --registration-token bmdgNrSZ4xZCzQqnxaU3 \
    --tag-list linux,xenial,ubuntu,docker \
    --executor "docker" \
    --name "auto-init-runner" \
    --docker-image "alpine:latest" \
    --run-untagged \
    --locked=false
