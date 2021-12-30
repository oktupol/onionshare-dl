FROM alpine:latest

# Install Tor
RUN apk add tor torsocks wget

# Download target dir
RUN mkdir -p /download
ENV DOWNLOAD_DIR /download

# Work dir
RUN mkdir /onionshare-dl
WORKDIR /onionshare-dl

ADD "entrypoint.sh" .
RUN chmod +x ./entrypoint.sh

ENTRYPOINT [ "./entrypoint.sh" ]