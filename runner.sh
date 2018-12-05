#!/usr/bin/env bash
set -x

pid=0
token=()
gitlab_service_url=${GITLAB_PROTOCOL}://${GITLAB_HOST}

# SIGTERM-handler
term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  gitlab-runner unregister -u ${gitlab_service_url} -t ${token}
  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; term_handler' SIGTERM


if [[ ${SSL_CERTIFICATE} ]]; then
  ln -sf ${SSL_CERTIFICATE} /etc/gitlab-runner/certs/${GITLAB_HOST}.crt
fi

register_params='--url ${gitlab_service_url}'
register_params=${register_params}' --registration-token '${GITLAB_RUNNER_TOKEN}
register_params=${register_params}' --executor docker'
register_params=${register_params}' --name "runner"'
register_params=${register_params}' --output-limit "20480"'
register_params=${register_params}' --docker-image "docker:latest"'
register_params=${register_params}' --docker-volumes /var/run/docker.sock:/var/run/docker.sock'
if [[ ${GITLAB_IP} ]]; then
  register_params=${register_params}' --docker-extra-hosts ${GITLAB_HOST}:${GITLAB_IP}'
fi
if [[ ${GITLAB_TAG_LIST} ]]; then
  register_params=${register_params}' --tag-list "'${GITLAB_TAG_LIST}'"'
fi

# register runner
yes '' | gitlab-runner register ${register_params}

# assign runner token
token=$(cat /etc/gitlab-runner/config.toml | grep token | awk '{print $3}' | tr -d '"')

# run multi-runner
gitlab-ci-multi-runner run --user=gitlab-runner --working-directory=/home/gitlab-runner & pid="$!"

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
