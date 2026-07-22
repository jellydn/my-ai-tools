FROM oven/bun:1 AS build
WORKDIR /app
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile
COPY . .
RUN --mount=type=secret,id=OPENAI_API_KEY,env=OPENAI_API_KEY \
    if [ -n "$OPENAI_API_KEY" ]; then bun run index && bun run index:browser; fi

FROM oven/bun:1-slim
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build --chown=bun:bun /app /app
RUN mkdir -p /var/lib/my-ai-bot /tmp/my-ai-bot && chown bun:bun /var/lib/my-ai-bot /tmp/my-ai-bot
ENV NODE_ENV=production BOT_DATA_DIR=/var/lib/my-ai-bot BOT_WORKSPACE_ROOT=/tmp/my-ai-bot
USER bun
VOLUME ["/var/lib/my-ai-bot"]
EXPOSE 3000
CMD ["bun", "run", "server.ts"]
