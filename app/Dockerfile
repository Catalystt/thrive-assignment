FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package.json .
RUN npm install --production

# Copy the rest of the application code
COPY index.js .

# Expose port 3000 and define default command
EXPOSE 3000
CMD ["npm", "start"]
