FROM ubuntu:16.04 as builder
WORKDIR /app
COPY . ./
RUN apt-get update
RUN apt-get install -y wget python python-urllib3
RUN apt-get install -y g++ git openjdk-8-jdk openjdk-8-source pkg-config unzip uuid-dev zip zlib1g-dev
RUN apt-get install -y libtool m4 autotools-dev automake
RUN wget https://github.com/bazelbuild/bazel/releases/download/0.21.0/bazel-0.21.0-installer-linux-x86_64.sh
RUN chmod +x bazel-0.21.0-installer-linux-x86_64.sh 
RUN ./bazel-0.21.0-installer-linux-x86_64.sh 
RUN bazel build //src/nginx/main:endpoints-server-proxy


FROM debian:buster
COPY --from=builder /app/bazel-bin/src/nginx/main/endpoints-runtime__amd64.deb /endpoints-runtime.deb

# Install dependencies
RUN apt-get update && \
    apt-get install --no-install-recommends -y -q ca-certificates && \
    apt-get -y -q upgrade && \
    apt-get install -y -q --no-install-recommends \
      apt-utils adduser python \
      libc6 libgcc1 libstdc++6 libuuid1 lsb-base && \
    apt-get clean && rm /var/lib/apt/lists/*_* && \
    dpkg -i /endpoints-runtime.deb && rm /endpoints-runtime.deb

# Create placeholder directories
RUN mkdir -p /var/lib/nginx/optional && \
    mkdir -p /var/lib/nginx/extra && \
    mkdir -p /var/lib/nginx/bin

# Status port 8090 is exposed by default
EXPOSE 8090

# The default HTTP/1.x port is 8080. It might help to expose this port explicitly
# since documentation still refers to using docker without additional EXPOSE step
EXPOSE 8080

ENTRYPOINT ["/usr/sbin/start_esp"]
