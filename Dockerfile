FROM node:22-slim AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:22-slim
RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

# Install gogcli (Google Workspace CLI) for Gmail polling
ARG GOGCLI_VERSION=0.12.0
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL "https://github.com/steipete/gogcli/releases/download/v${GOGCLI_VERSION}/gogcli_${GOGCLI_VERSION}_linux_${ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin gog && \
    chmod +x /usr/local/bin/gog

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY --from=build /app/dist ./dist
COPY .skills/ .skills/

# Install travel-agent-skills for Viajero
RUN git clone --depth 1 https://github.com/loboroboto/travel-agent-skills.git /tmp/travel-skills \
    && cp -r /tmp/travel-skills/skills/* .skills/ \
    && rm -rf /tmp/travel-skills

ENV NODE_ENV=production
EXPOSE 8080

CMD ["node", "dist/main.js"]
