FROM ubuntu:24.04

ARG RUNNER_VERSION
ENV DEBIAN_FRONTEND=noninteractive

# update the base packages + add a non-sudo user
RUN apt-get update -y && apt-get upgrade -y && useradd -m docker

RUN apt-get update && \
  apt-get install -y ca-certificates curl && \
  install -m 0755 -d /etc/apt/keyrings && \
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
  chmod a+r /etc/apt/keyrings/docker.asc && \
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null \
  && apt-get update

# install the packages and dependencies along with jq so we can parse JSON (add additional packages as necessary)
RUN apt-get install -y --no-install-recommends \
  curl nodejs wget unzip vim git jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip libpq-dev libyaml-dev \
  docker-buildx-plugin docker-compose-plugin docker-ce-cli && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# cd into the user directory, download and unzip the github actions runner
RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
  && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-$(dpkg --print-architecture)-${RUNNER_VERSION}.tar.gz \
  && tar xzf ./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz

# install some additional dependencies
RUN chown -R docker ~docker && /home/docker/actions-runner/bin/installdependencies.sh

# add over the start.sh script
ADD scripts/start.sh start.sh

# make the script executable
RUN chmod +x start.sh

# set the user to "docker" so all subsequent commands are run as the docker user
USER docker

# set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]
