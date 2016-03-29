FROM analogj/capsulecd:latest
MAINTAINER Jason Kulatunga <jason@thesparktree.com>

RUN apk --update --no-cache add nodejs && \
    npm install -g bower

CMD ["capsulecd", "start", "--source", "github", "--package_type", "javascript"]