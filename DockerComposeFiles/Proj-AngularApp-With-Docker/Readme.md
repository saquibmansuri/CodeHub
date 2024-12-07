# Deploy angular app with docker

There are two approches
1. Build the project outside docker
2. Build the project inside docker

## Build the project outside docker (Use Dockerfile given in this repository)
Note: Project needs to be build first then docker container needs to be started
Step1: Project should be built first: npm run build-myapp  (command can be found in package.json)
Step2: Then start the container: docker compose up -d

## Build the project inside docker (Use BuildWithDocker.Dockerfile given in this repostory)
Create multistage dockerfile
Stage1- build the project
Stage2- copies static bundle from stage1 and runs the app
