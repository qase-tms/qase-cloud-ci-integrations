FROM alpine:3.19

# Install bash and curl for shell scripting and API calls
RUN apk add --no-cache bash curl

# Copy the action script
COPY src/action.sh /action.sh

# Copy the entrypoint wrapper
COPY entrypoint.sh /entrypoint.sh

# Make scripts executable
RUN chmod +x /action.sh /entrypoint.sh

# Set the entrypoint to use the wrapper
ENTRYPOINT ["/entrypoint.sh"]
