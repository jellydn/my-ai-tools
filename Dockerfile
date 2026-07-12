FROM oven/bun

WORKDIR /app

COPY package.json .
COPY bun.lock .
RUN bun install

COPY . .

ARG OPENAI_BASE_URL=https://openrouter.ai/api/v1
ARG OPENAI_MODEL=openrouter/free
ARG OPENAI_EMBEDDING_MODEL=nvidia/llama-nemotron-embed-vl-1b-v2:free
ENV OPENAI_BASE_URL=${OPENAI_BASE_URL}
ENV OPENAI_MODEL=${OPENAI_MODEL}
ENV OPENAI_EMBEDDING_MODEL=${OPENAI_EMBEDDING_MODEL}

RUN --mount=type=secret,id=OPENAI_API_KEY \
	export OPENAI_API_KEY=$(cat /run/secrets/OPENAI_API_KEY) && \
	bun run index

ENV NODE_ENV=production

EXPOSE 3000

CMD ["bun", "server.ts"]
