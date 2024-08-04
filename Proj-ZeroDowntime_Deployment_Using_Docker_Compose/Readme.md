# DOCKER ROLLOUT

## This is the url of the repository that explains everything
https://github.com/Wowu/docker-rollout

## Only 1 small change, after the performing the installation steps given by the developer, add user in docker group and refresh the group settings, otherwise the cli wont be able to recognise the docker rollout plugin
```
# Steps given by developer
# Create directory for Docker cli plugins
mkdir -p ~/.docker/cli-plugins

# Download docker-rollout script to Docker cli plugins directory
curl https://raw.githubusercontent.com/wowu/docker-rollout/master/docker-rollout -o ~/.docker/cli-plugins/docker-rollout

# Make the script executable
chmod +x ~/.docker/cli-plugins/docker-rollout

# Two additional steps
# Add user to docker group
sudo usermod -aG docker $USER

# Refresh group
newgrp docker
```
