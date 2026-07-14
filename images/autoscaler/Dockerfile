FROM node:20-alpine

WORKDIR /usr/src/app

COPY package.json ./
RUN npm install --omit=dev

COPY index.js ./

ENV PORT=8080

# Simple TCP-friendly keep-alive: Cloud Run Worker Pools expect a listening process.
# The scaler loop runs in-process; a tiny HTTP health stub binds PORT.
CMD ["node", "index.js"]
