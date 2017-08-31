FROM ubuntu:16.04
WORKDIR /opt

# Install go, git and monero dependencies
RUN apt-get update --quiet \
 	&& apt-get install --quiet --yes \
		golang \ 
		tree \
		git \
		cmake \
		build-essential \
		libssl-dev \ 
		pkg-config \ 
		libboost-all-dev \ 
		graphviz 

ENV GOPATH /opt/go
RUN	export GOPATH=/opt/go

# Install required packages:
RUN go get github.com/goji/httpauth &&\
	go get github.com/yvasiyarov/gorelic &&\
	go get github.com/gorilla/mux

RUN go list ...

# Create mining dir
RUN mkdir /opt/mining
ENV MINING_DIR /opt/mining

# Clone Monero source:
RUN cd /opt/mining &&\
	git clone https://github.com/monero-project/monero.git
	
# Compile monero (with shared libraries option):	
RUN cd /opt/mining/monero &&\
	git checkout tags/v0.10.3.1 -b v0.10.3.1 &&\
	export MONERO_DIR=$PWD &&\
	cmake -DBUILD_SHARED_LIBS=1 . &&\
	make 

# Clone monero stratum:
RUN cd /opt/mining &&\
	git clone https://github.com/sammy007/monero-stratum.git

# Build monero startum
RUN cd /opt/mining/monero-stratum &&\
	cmake . &&\
	make &&\
	go build -o pool main.go

# Clean APT cache for a lighter image.
RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD config.example.json /opt/mining/monero-stratum/conf/config.example.json

VOLUME ["/opt/mining/monero-stratum/conf"]

# Running Stratum:
CMD ["./pool", "/opt/mining/monero-stratum/conf/config.json"]	
