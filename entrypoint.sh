#!/bin/ash

set -e

show_help() {
  local bold='\e[1m';
  local rst='\e[0m';
  local image_name="ghcr.io/oktupol/onionshare-dl"
  echo -e "${bold}Usage${rst}: docker run $image_name [-o ONION_HOST] [-k PRIVATE_KEY]"
  echo -e ""
  echo -e "Downloads all files from an OnionShare into its container, at $DOWNLOAD_DIR."
  echo -e "You can then copy the files with 'docker cp -r [container name]:$DOWNLOAD_DIR/ .'"
  echo -e ""
  echo -e "${bold}Options${rst}:"
  echo -e "Each option can be passed either as environment variable or as cli option."
  echo -e "Cli options take precedence over environment variables."
  echo -e ""
  echo -e "${bold}ONION_HOST${rst}:"
  echo -e "    Hostname of the onion service."
  echo -e ""
  echo -e "${bold}PRIVATE_KEY${rst}:"
  echo -e "    Private key of the onion service, if the service has client authorization enabled."
  echo -e ""
  echo -e ""
  echo -e "${bold}Example:${rst}"
  echo -e ""
  echo -e "With environment variables:"
  echo -e "docker run -e ONION_HOST -e PRIVATE_KEY $image_name"
  echo -e ""
  echo -e "With cli options:"
  echo -e "docker run $image_name -o xxxxxxxx.onion -k XXXXXXXX"
}

show_remove_notice() {
  echo -e ""
  echo -e "Once you're done, remove this container with:"
  echo -e ""
  echo -e "    docker rm $HOSTNAME"
}

while getopts "ho:k:" opt; do
  case "$opt" in
    h)
      show_help
      show_remove_notice
      exit 0
      ;;
    o)
      ONION_HOST="$OPTARG"
      ;;
    k)
      PRIVATE_KEY="$OPTARG"
      ;;
  esac
done

if [ ! -n "$ONION_HOST" ]; then
  echo "Error: No ONION_HOST was provided."
  show_help
  show_remove_notice
  exit 1
fi

# Strip http:// and .onion, and re-insert them again to account for inputs without http:// or .onion
# Also, the hostname without .onion is required for setting up the private key.
onion_hostname="$(echo $ONION_HOST | sed 's/^\(http:\/\/\)\?\([a-zA-Z0-9]*\)\(\.onion\)\?/\2/g')"
ONION_HOST="http://${onion_hostname}.onion"

# Configuring private key
if [ -n "$PRIVATE_KEY" ]; then
  mkdir -p ./client-auth
  echo "ClientOnionAuthDir ${PWD}/client-auth" >> /etc/tor/torrc
  echo "${onion_hostname}:descriptor:x25519:${PRIVATE_KEY}" > "./client-auth/${onion_hostname}.auth_private"
fi

# Start tor
echo "Starting Tor..."
/usr/bin/tor > ./tor.log &

# Wait for tor to start up
while [ ! -n "$(grep 'Bootstrapped 100% (done)' ./tor.log)" ]; do
  sleep 1
done

echo "Tor started"

# Download file
old_pwd=$PWD
cd $DOWNLOAD_DIR
torsocks wget --content-disposition "${ONION_HOST}/download"
cd $old_pwd

# If zip, list file contents
downloaded_file="$(ls $DOWNLOAD_DIR)"
echo "Downloaded file $downloaded_file"
if [ -n "$(echo $downloaded_file | grep '.zip$')" ]; then
  echo "File listing of $downloaded_file:"
  unzip -l "$DOWNLOAD_DIR/$downloaded_file"
fi

# If download-dir isn't mounted, show instructions to copy file
if [ ! -n "$(mount | grep " $DOWNLOAD_DIR ")" ]; then
  echo ""
  echo "Copy the file onto your machine with:"
  echo ""
  echo "    docker cp $HOSTNAME:$DOWNLOAD_DIR/$downloaded_file ."
fi

show_remove_notice