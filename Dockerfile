FROM alpine:latest

RUN apk --no-cache add ca-certificates

RUN apk add build-base

FROM icr.io/informix/informix-developer-database

#RUN apk --no-cache add ca-certificates
#WORKDIR /root/
#COPY --from=builder /go/src/github.com/alexellis/href-counter/app    .
#CMD ["./app"]

# update the ansible repo
COPY config/sources.list /etc/apt

#RUN  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367

#RUN apt adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
##RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 871920D1991BC93C
#
#
#RUN /bin/sh -c apt-get -y install net-tools libaio1 bc libncurses5 ncurses-bin libpam0g



#RUN sudo /bin/sh/ -c apt-get update && sudo /bin/sh/ -c apt-get install -y \
#  apt-utils \
#  build-essential \
#  libelf-dev \
#  libpam-dev
#  rsync \
#  openssh-server
#
#RUN sudo apt-get install -y --force-yes ansible

#gcc
#make

COPY . .

#RUN ./ids.var

ENV INFORMIXDIR=/opt/ibm/informix

#ENV TERM=vt100
ENV TERMCAP=$INFORMIXDIR/etc/termcap
ENV IFMX_UNDOC_B168163=1
ENV DBDELIMITER="|"
ENV DBDATE=dmy4/

COPY tmp/hello.4gl /tmp

#WORKDIR $INFORMIXDIR
