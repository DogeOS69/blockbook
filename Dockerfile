FROM ubuntu:22.04

ARG NETWORK=testnet

RUN apt-get update && apt-get install -y libgflags2.2 libsnappy1v5 zlib1g libzstd1 libzmq5 libbz2-1.0 liblz4-1 jq ca-certificates

COPY build/blockbook /usr/bin/blockbook
COPY build/blockchaincfg_testnet.json /blockchaincfg_testnet.json
COPY build/blockchaincfg_mainnet.json /blockchaincfg_mainnet.json

RUN if [ "$NETWORK" = "testnet" ]; then cp /blockchaincfg_testnet.json /blockchaincfg.json; \
    else cp /blockchaincfg_mainnet.json /blockchaincfg.json; fi

ENV RPC_URL=""
ENV RPC_USER=""
ENV RPC_PASS=""

COPY static /static

COPY <<'EOF' /entrypoint.sh
#!/bin/sh
echo "Starting entrypoint with RPC_URL=$RPC_URL, RPC_USER=$RPC_USER, RPC_PASS=$RPC_PASS"
if [ -n "$RPC_URL" ]; then
  echo "Overriding rpc_url to $RPC_URL"
  jq --arg url "$RPC_URL" '.rpc_url = $url' /blockchaincfg.json > /tmp/cfg.json && mv /tmp/cfg.json /blockchaincfg.json || echo "Failed to override rpc_url"
fi
if [ -n "$RPC_USER" ]; then
  echo "Overriding rpc_user to $RPC_USER"
  jq --arg user "$RPC_USER" '.rpc_user = $user' /blockchaincfg.json > /tmp/cfg.json && mv /tmp/cfg.json /blockchaincfg.json || echo "Failed to override rpc_user"
fi
if [ -n "$RPC_PASS" ]; then
  echo "Overriding rpc_pass to $RPC_PASS"
  jq --arg pass "$RPC_PASS" '.rpc_pass = $pass' /blockchaincfg.json > /tmp/cfg.json && mv /tmp/cfg.json /blockchaincfg.json || echo "Failed to override rpc_pass"
fi
echo "Final config: $(cat /blockchaincfg.json)"
exec /usr/bin/blockbook -blockchaincfg=/blockchaincfg.json -datadir=/data -sync -public=:19139 -internal=:19039 -logtostderr -debug
EOF

RUN chmod +x /entrypoint.sh

VOLUME /data

ENTRYPOINT ["/entrypoint.sh"]
