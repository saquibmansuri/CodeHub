FROM node:22-bullseye

# Install Chrome dependencies and additional fonts for emoji support
RUN apt-get update && apt-get install -y \
    chromium \
    chromium-sandbox \
    fonts-ipafont-gothic \
    fonts-wqy-zenhei \
    fonts-thai-tlwg \
    fonts-kacst \
    fonts-freefont-ttf \
    fonts-noto-color-emoji \
    fonts-noto-cjk \
    libxss1 \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /usr/src/app

# Set environment variables for Puppeteer
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Install app dependencies
COPY package*.json ./
RUN npm install

# Bundle app source
COPY . .

# Create downloads directory
RUN mkdir -p downloads

EXPOSE 3000

CMD [ "npm", "start" ]
