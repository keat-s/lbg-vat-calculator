# ----- Stage 1: build the app with webpack -----
# Use an active LTS Node.js image so CRA/webpack dependencies run on a
# supported runtime. Name this stage "build" so nginx can copy from it.
FROM node:20-alpine AS build

# Set /app as the working directory inside the container.
# Subsequent commands run relative to this path; Docker creates it if needed.
WORKDIR /app

# Copy package metadata first so Docker can cache dependency installs.
# Including package-lock.json keeps the image build on the same dependency
# graph tested by Jenkins before the Docker build starts.
COPY package.json package-lock.json ./

# Install the exact locked dependency graph for reproducible CI builds.
RUN npm ci

# Now copy the rest of the source code into /app.
# Done after npm install so editing code doesn't invalidate the cache layer above.
COPY . .

# Run the build script (webpack), which outputs static files to /app/build.
RUN npm run build

# ----- Stage 2: serve the built files with nginx -----
# Start fresh from a lightweight nginx image. Nothing from stage 1 is
# carried over except what we explicitly copy below — this keeps the
# final image small (no Node.js, no node_modules, no source code).
FROM nginx:1.23-alpine

# Copy the compiled static files from the "build" stage into nginx's
# default web root, where nginx serves content from by default.
COPY --from=build /app/build /usr/share/nginx/html

# Copy a custom nginx configuration, replacing the default server config.
# This typically handles things like SPA routing (fallback to index.html).
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Document that the container listens on port 80.
# Note: this is informational — you still need -p 80:80 (or similar) when running.
EXPOSE 80

# Start nginx in the foreground. "daemon off;" keeps it running as the
# container's main process so the container doesn't immediately exit.
CMD ["nginx", "-g", "daemon off;"]
