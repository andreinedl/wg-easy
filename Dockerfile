FROM docker.io/library/node:20-alpine AS build_node_modules

# Copy Web UI
COPY src/ /app/
WORKDIR /app
RUN npm ci --production

# Copy build result to a new image.
# This saves a lot of disk space.
FROM docker.io/library/node:20-alpine
COPY --from=build_node_modules /app /app

# Move node_modules one directory up, so during development
# we don't have to mount it in a volume.
# This results in much faster reloading!
#
# Also, some node_modules might be native, and
# the architecture & OS of your development machine might differ
# than what runs inside of docker.
RUN mv /app/node_modules /node_modules

# Enable this to run `npm run serve`
RUN npm i -g nodemon

# Install Linux packages
RUN apk add -U --no-cache \
  ip6tables iptables \
  wireguard-tools \
  dumb-init \
  coreutils \
  openrc

COPY dnscrypt-proxy.toml /etc/dnscrypt-proxy/
RUN apk add dnscrypt-proxy
COPY dnscrypt-proxy.toml /etc/dnscrypt-proxy/

# Expose Ports
EXPOSE 51820/udp
EXPOSE 51821/tcp

# Set Environment
ENV DEBUG=Server,WireGuard

# Run VPN
WORKDIR /app
COPY entrypoint.sh /app
RUN chmod +x entrypoint.sh
ENTRYPOINT ["/usr/bin/dumb-init", "./entrypoint.sh"]
