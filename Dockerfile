FROM alpine:3.19

# Install bash, curl, and jq for shell scripting and JSON processing
RUN apk add --no-cache bash curl jq

# Copy the action script
COPY src/action.sh /action.sh

# Copy the entrypoint wrapper
COPY entrypoint.sh /entrypoint.sh

# Make scripts executable
RUN chmod +x /action.sh /entrypoint.sh

# Set the entrypoint to use the wrapper
ENTRYPOINT ["/entrypoint.sh"]
