# OnionShare-Dl

Download files from [OnionShare](https://onionshare.org)-Servers without having
to install Tor.

## Requirements:

You need to have [Docker](https://docker.com) on your machine.

## Usage:

### Downloading files

Download files from an OnionShare.

```bash
docker run ghcr.io/oktupol/onionshare-dl
```

Provide the onion-host and private key as parameters:

```bash
docker run ghcr.io/oktupol/onionshare-dl -o http://tw6hk...d.onion -k ZU5HN...3Q
```

or as environment variables:

```bash
export ONION_HOST=http://tw6hk...d.onion
export PRIVATE_KEY=ZU5HN...3Q
docker run -e ONION_HOST -e PRIVATE_KEY ghcr.io/oktupol/onionshare-dl
```

### Accessing downloaded files

The shared file will be downloaded into a directory `/download` inside the container.

Copy it onto your machine with

```bash
docker cp [container name]:/download/[file name] .
```

Container name and file name will be told to you by the program.

Alternatively, set up a volume mount so that the file will be directly downloaded onto your machine. When starting the container, provide it with the parameter `-v`:

```bash
mkdir target-dir
docker run -v $PWD/target-dir:/download ghcr.io/oktupol/onionshare-dl
# Your files will be written into target-dir
```

### Cleanup

Once you copied your file onto your machine, remove the container:

```bash
docker rm [container name]
```