# docker build -t mplx/webvirtcloud .
FROM phusion/baseimage:0.9.22

LABEL maintainer="geki007"
LABEL maintainer="mplx <mplx+docker@donotreply.at>"

EXPOSE 80

CMD ["/sbin/my_init"]

RUN apt-get update -qqy && \
    DEBIAN_FRONTEND=noninteractive apt-get -qyy install \
    -o APT::Install-Suggests=false \
    python-virtualenv \
    python-dev \
    libxml2-dev \
    libvirt-dev \
    zlib1g-dev \
    nginx \
    supervisor \
    libsasl2-modules \
    unzip \
    curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    mkdir -p /srv

WORKDIR /srv

ENV COMMITID=1ad2f03b52d5f63393dc26bc3b1709307da9ef9c

RUN curl -L -o $COMMITID.zip https://github.com/honza801/webvirtcloud/archive/$COMMITID.zip && \
    unzip $COMMITID.zip && \
    rm -f $COMMITID.zip && \
    mv webvirtcloud-$COMMITID webvirtcloud

COPY 01-wsproxy.patch /srv/webvirtcloud/01-wsproxy.patch
COPY 02-forwardssl.patch /srv/webvirtcloud/02-forwardssl.patch
COPY startinit.sh /etc/my_init.d/startinit.sh

WORKDIR /srv/webvirtcloud/

RUN cp conf/supervisor/webvirtcloud.conf /etc/supervisor/conf.d && \
    cp conf/nginx/webvirtcloud.conf /etc/nginx/conf.d && \
    chown -R www-data:www-data /srv/webvirtcloud/ && \
    mkdir data && \
    cp webvirtcloud/settings.py.template webvirtcloud/settings.py && \
    sed -i "s/SECRET_KEY = ''/SECRET_KEY = '4y(f4rfqc6f2!i8_vfuu)kav6tdv5#sc=n%o451dm+th0&3uci'/" webvirtcloud/settings.py && \
    sed -i "s|'db.sqlite3'|'data/db.sqlite3'|" webvirtcloud/settings.py && \
    virtualenv venv && \
    . venv/bin/activate && \
    venv/bin/pip install -r conf/requirements.txt && \
    chown -R www-data:www-data /srv/webvirtcloud/ && \
    rm /etc/nginx/sites-enabled/default && \
    echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
    chown -R www-data:www-data /var/lib/nginx && \
    mkdir /etc/service/nginx && \
    mkdir /etc/service/nginx-log-forwarder && \
    mkdir /etc/service/webvirtcloud && \
    mkdir /etc/service/novnc && \
    cp conf/runit/nginx /etc/service/nginx/run && \
    cp conf/runit/nginx-log-forwarder /etc/service/nginx-log-forwarder/run && \
    cp conf/runit/novncd.sh /etc/service/novnc/run && \
    cp conf/runit/webvirtcloud.sh /etc/service/webvirtcloud/run && \
    rm -rf /tmp/* /var/tmp/* && \
    patch -p1 -u <01-wsproxy.patch && \
    patch -p1 -u <02-forwardssl.patch && \
    rm 01-wsproxy.patch && \
    rm 02-forwardssl.patch && \
    cp conf/nginx/webvirtcloud.conf /etc/nginx/conf.d && \
    chown -R www-data:www-data /etc/nginx/conf.d/webvirtcloud.conf
