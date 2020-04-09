FROM golang:1.12.9-stretch AS builder

# Disable Go 1.11 Modules
ENV GO111MODULE=off

# Install dependencies
RUN DEBIAND_FRONTEND=noninteractive apt-get -y update \
    && apt-get install -y \
	git \
	gcc \
	cmake \
	autoconf \
	libtool \
	pkg-config \
	libmnl-dev \
	libyaml-dev

# Get Free5GC
RUN cd $GOPATH/src \
    && git clone https://github.com/yongs2/free5gc-stage-3 free5gc \
    && cd $GOPATH/src/free5gc \
    && chmod +x ./install_env.sh \
    && ./install_env.sh \
    && tar -C $GOPATH -zxvf free5gc_libs.tar.gz

# Build Control Plane entities (AMF,AUSF,NRF,NSSF,PCF,SMF,UDM,UDR)
RUN cd $GOPATH/src/free5gc/src \
    && for d in * ; do if [ -f "$d/$d.go" ] ; then go build -o ../bin/"$d" -x "$d/$d.go" ; fi ; done ;

# Get Linux kernel module 5G GTP-U, check Linux kernel version if it is 5.0.0-23-generic
#RUN cd $HOME \
#    && git clone https://github.com/PrinzOwO/gtp5g.git gtp5g \
#    && cd $HOME/gtp5g \
#    && make \
#    && make install

# Build User Plane Function (UPF) entity
#RUN cd $GOPATH/src/free5gc/src/upf \
#    && mkdir build \
#    && cd build \
#    && cmake .. \
#    && make -j `nproc`

# Build webconsole
RUN cd $GOPATH/src/free5gc/webconsole \
    && go build -o ./webconsole

FROM ubuntu:18.04

WORKDIR /root/free5gc
COPY --from=builder /go/src/free5gc/bin/* ./
#COPY --from=builder /go/src/free5gc/src/upf/build/bin/* ./

RUN mkdir webconsole
COPY --from=builder /go/src/free5gc/webconsole/* ./webconsole/
RUN apt-get update \
    && apt-get -y install curl gnupg \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get -y update \
    && apt-get -y install yarn \
    && cd webconsole \
    && yarn install
ADD run_webui.sh /root/free5gc
RUN chmod +x /root/free5gc/run_webui.sh

RUN mkdir config/
COPY --from=builder /go/src/free5gc/config/* ./config/
#COPY --from=builder /go/src/free5gc/src/upf/build/config/* ./config/

RUN mkdir -p support/TLS
COPY --from=builder /go/src/free5gc/support/TLS/* ./support/TLS/

#ENV LD_LIBRARY_PATH=
#COPY --from=builder /go/src/free5gc/src/upf/build/libgtpnl/lib/libgtpnl.so* /lib/x86_64-linux-gnu/
#COPY --from=builder  /go/src/free5gc/src/upf/build/utlt_logger/liblogger.so /lib/x86_64-linux-gnu/

RUN DEBIAND_FRONTEND=noninteractive apt-get -y update \
    && apt-get install -y \
    libmnl0 \
	libyaml-0-2

CMD [ "/bin/bash" ]
