FROM alpine:3.21

WORKDIR /pb

RUN apk add --no-cache ca-certificates unzip curl

ADD https://github.com/pocketbase/pocketbase/releases/download/v0.40.6/pocketbase_0.40.6_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb && rm /tmp/pb.zip && chmod +x /pb/pocketbase

COPY pocketbase/pb_migrations /pb/pb_migrations
COPY pocketbase/docker-entrypoint.sh /pb/docker-entrypoint.sh
RUN chmod +x /pb/docker-entrypoint.sh

EXPOSE 8090

ENTRYPOINT ["/pb/docker-entrypoint.sh"]
