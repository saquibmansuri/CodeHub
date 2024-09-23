### Reference - https://github.com/Joxit/docker-registry-ui   |  https://hub.docker.com/_/registry

# This repository contains compose file that explains how to host custom registry on local machine (without authentication)

## Setup the containers
` docker compose up -d `

## Check if the registry is setup properly
- http://localhost:5000/v2  (base url)
- http://localhost:5000/v2/_catalog  (list repositories)
- http://localhost:5000/v2/[repository-name]/tags/list  (list tags for specific repository)
- http://localhost:5000/v2/[repository-name]/manifests/[tag]  (get manifest for a specific tag)

## Example push any image to local registry

### Pull or build any image in local
- docker pull ubuntu:latest

### Assign a tag
- docker tag ubuntu:latest localhost:5000/project1/ubuntu:latest
- docker tag ubuntu:latest localhost:5000/project2/ubuntu:latest

### Push to local repository
- docker push localhost:5000/project1/ubuntu:latest
- docker push localhost:5000/project2/ubuntu:latest

### Pull from a local registry
- docker pull localhost:5000/project1/ubuntu:latest
- docker pull localhost:5000/project2/ubuntu:latest

## Check images in local registry on the UI
http://localhost:8080
