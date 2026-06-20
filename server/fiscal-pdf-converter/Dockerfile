FROM node:20-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    libreoffice-calc \
    libreoffice-writer \
    fonts-dejavu \
    fonts-liberation \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY src ./src

ENV PORT=8080
ENV VERIFY_SUPABASE_JWT=true
ENV MAX_UPLOAD_BYTES=10485760

EXPOSE 8080

CMD ["npm", "start"]
