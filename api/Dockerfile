FROM node:20 as builder

WORKDIR /app
COPY package*.json ./
RUN npm install

COPY src ./src

FROM node:20

WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY package*.json ./

USER node
EXPOSE 8080
CMD ["npm", "start"]
