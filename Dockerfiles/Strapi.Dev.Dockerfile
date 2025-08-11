# Base image
FROM node:24-alpine as base

# Creating multi-stage build for production
FROM base as build
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev vips-dev git > /dev/null 2>&1
ARG NODE_ENV=development
ENV NODE_ENV=development

WORKDIR /opt/
COPY package.json ./
RUN npm cache clean --force
RUN npm install -g node-gyp
RUN npm config set fetch-retry-maxtimeout 600000 -g && npm install
ENV PATH /opt/node_modules/.bin:$PATH
WORKDIR /opt/app
COPY . .
RUN npm run build

# Creating final image
FROM base as final
RUN apk add --no-cache vips-dev
ARG NODE_ENV=development
ENV NODE_ENV=development
WORKDIR /opt/
COPY --from=build /opt/node_modules ./node_modules
WORKDIR /opt/app
COPY --from=build /opt/app ./
ENV PATH /opt/node_modules/.bin:$PATH

RUN chown -R node:node /opt/app
USER node
EXPOSE 1337
CMD ["npm", "run", "develop"]
