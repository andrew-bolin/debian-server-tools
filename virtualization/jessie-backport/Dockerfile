#
# szepeviktor/jessie-backport
#
# VERSION       0.2.1
# BUILD         docker build -t szepeviktor/jessie-backport:0.2.1 jessie-backport
# RUN           docker run --rm --tty -v $TARGET_PATH:/opt/results --env PACKAGE="$SOURCE-PACKAGE/$RELEASE" szepeviktor/jessie-backport:0.2.1

FROM szepeviktor/jessie-build

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

COPY debackport.sh /usr/local/bin/debackport.sh

USER debian
WORKDIR /home/debian
VOLUME ["/opt/results"]

ENTRYPOINT ["/usr/local/bin/debackport.sh"]
