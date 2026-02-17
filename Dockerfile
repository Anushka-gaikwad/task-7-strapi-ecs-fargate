FROM node:20

WORKDIR /app

# Copy package files and install
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

EXPOSE 1337

# Start Strapi in development mode (change to start for prod)
CMD ["npm", "run", "develop"]

