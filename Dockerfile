FROM node:24-slim

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

ARG OPENAI_BASE_URL=https://openrouter.ai/api/v1
ARG OPENAI_MODEL=openrouter/free
ARG OPENAI_EMBEDDING_MODEL=nvidia/llama-nemotron-embed-vl-1b-v2:free
ENV OPENAI_BASE_URL=${OPENAI_BASE_URL}
ENV OPENAI_MODEL=${OPENAI_MODEL}
ENV OPENAI_EMBEDDING_MODEL=${OPENAI_EMBEDDING_MODEL}

# Secret is only visible in this RUN; export so npm run index inherits a trimmed key.
RUN --mount=type=secret,id=OPENAI_API_KEY,required=true \
	export OPENAI_API_KEY="$(tr -d '\r\n' < /run/secrets/OPENAI_API_KEY | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')" && \
	test -n "$OPENAI_API_KEY" && \
	npm run index && \
	npm run index:browser

ENV NODE_ENV=production
ENV NODE_OPTIONS=--max-old-space-size=512

EXPOSE 3000

CMD ["npm", "start"]
