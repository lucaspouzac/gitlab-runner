FROM gitlab/gitlab-runner:v13.0.1
MAINTAINER Lucas POUZAC <julien.bournonville@rouhtiau.fr>

ADD runner.sh /runner.sh
RUN chmod +x /runner.sh

ENTRYPOINT ["/runner.sh"]
