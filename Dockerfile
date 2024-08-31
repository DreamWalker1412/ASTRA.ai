FROM ghcr.io/ten-framework/astra_agents_build:0.4.0 AS builder

ARG SESSION_CONTROL_CONF=session_control.conf

WORKDIR /app
RUN mkdir -p /app/logs

# 设置 Go 代理
ENV GOPROXY=https://goproxy.cn,https://proxy.golang.org,direct

# Run build commands
COPY . .
COPY agents/${SESSION_CONTROL_CONF} agents/session_control.conf

RUN make clean && make build && \
    cd agents && ./scripts/package.sh

FROM ubuntu:22.04

# 更换 Ubuntu 源并添加多个备用源
RUN sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

# 设置 Go 代理，解决依赖下载问题
ENV GOPROXY=https://goproxy.cn,https://proxy.golang.org,direct

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libasound2 \
    libgstreamer1.0-dev \
    libunwind-dev \
    libc++1 \
    libssl-dev \
    python3 \
    python3-venv \
    python3-pip \
    python3-dev \
    jq \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*

WORKDIR /app
RUN mkdir -p /app/logs

COPY --from=builder /app/.env /app/.env
COPY --from=builder /app/agents/.release/ agents/
COPY --from=builder /app/server/bin/api /app/server/bin/api
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/lib/python3 /usr/lib/python3

EXPOSE 8080

ENV AGORA_APP_ID=a3d7436bd66f4cd49020e77ab8567e47
ENV AGORA_APP_CERTIFICATE=a82e5237a0bc4fc490decd8498fe28f2
ENV AZURE_STT_KEY=c6764883e493410fb581f995d6a99dfc
ENV AZURE_STT_REGION=Eastasia
ENV OPENAI_BASE_URL=https://api.siliconflow.cn/v1
ENV OPENAI_API_KEY=sk-pdvzjlpdoewmwaqbppepmoiacssakgaoetlysagfkgtcphom
ENV AZURE_TTS_KEY=c6764883e493410fb581f995d6a99dfc
ENV AZURE_TTS_REGION=Eastasia


ENTRYPOINT ["/app/server/bin/api"]
