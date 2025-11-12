FROM alpine:latest

LABEL "repository"="https://github.com/rogeruiz/repasar"
LABEL "homepage"="https://github.com/rogeruiz/repasar"

RUN apk add --no-cache git bash git-subtree openssh-keygen curl

ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
