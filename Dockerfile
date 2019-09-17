FROM ubuntu:18.04

ADD VERSION /

# Use Digital Ocean Mirrors
RUN sed -i 's/archive.ubuntu.com/mirrors.digitalocean.com/g' /etc/apt/sources.list

# Install the bare essentials for administration
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y tmux vim htop python python-pip git software-properties-common wget netcat

# Pull the Scilla sources
RUN add-apt-repository -y ppa:avsm/ppa && apt-get update && apt-get install -y curl \
build-essential m4 ocaml opam pkg-config zlib1g-dev libgmp-dev libffi-dev libssl-dev \
libboost-system-dev libsecp256k1-dev libpcre3-dev
ARG SCILLA_VERSION=v0.4.0
RUN git clone https://github.com/Zilliqa/Scilla.git Scilla && cd Scilla && git checkout ${SCILLA_VERSION}
RUN cd Scilla && make opamdep && echo ". ~/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true" >> ~/.bashrc
RUN cd Scilla && eval `opam config env` && make clean && make

# Pull the Zilliqa sources
RUN apt-get update
RUN apt-get install -y git libboost-system-dev libboost-filesystem-dev libboost-test-dev \
libssl-dev libleveldb-dev libjsoncpp-dev libsnappy-dev cmake libmicrohttpd-dev \
libjsonrpccpp-dev build-essential pkg-config libevent-dev libminiupnpc-dev \
libprotobuf-dev protobuf-compiler libcurl4-openssl-dev libboost-program-options-dev \
libssl-dev
ARG ZILLIQA_VERSION=fuzz-v5.0.1
ARG FORCE_REBUILD=no
RUN git clone https://github.com/nnamon/Zilliqa.git Zilliqa && cd Zilliqa && git checkout ${ZILLIQA_VERSION}
RUN cd Zilliqa && cmake -H. -Bbuild ${CMAKE_EXTRA_OPTIONS} -DCMAKE_BUILD_TYPE=RelWithDebInfo \
-DCMAKE_INSTALL_PREFIX=.. && cmake --build build -- -j`nproc --all`
RUN pip install clint requests setuptools futures

# Get the most recent configuration
ARG FORCE_UPDATE=no
RUN mkdir config && cd config && wget https://mainnet-join.zilliqa.com/configuration.tar.gz && \
tar xvfz configuration.tar.gz

# Setup the Zilliqa path
ENV PATH="${PATH}:${PWD}/Zilliqa/build/bin/:${PWD}/Scilla/bin/"

# Setup the node environment
RUN mkdir node
RUN cp config/*.xml node/
RUN cp config/*.py node/
RUN sed -i "s/\/scilla/\/Scilla/g"  node/constants.xml

# Make Zilliqa log to stdout
RUN ln -s /dev/stdout node/zilliqa-00001-log.txt

# Change the working directory to the node directory
WORKDIR node/
