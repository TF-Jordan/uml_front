# Build stage
FROM dart:stable AS build

WORKDIR /app

# Copy pubspec files and get dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy source code
COPY . .

# Compile to native executable
RUN dart compile exe bin/server.dart -o bin/server

# Runtime stage
FROM scratch

# Copy runtime dependencies
COPY --from=build /runtime/ /

# Copy the compiled executable
COPY --from=build /app/bin/server /app/bin/server

# Expose port
EXPOSE 8080

# Run the server
CMD ["/app/bin/server"]
