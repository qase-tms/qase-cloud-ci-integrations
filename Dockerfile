FROM alpine:3.19

# Install bash, curl, jq, and required libraries for qasectl
RUN apk add --no-cache bash curl jq libc6-compat

# Install qasectl v0.3.9 - automatically detect architecture
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; fi && \
    curl -L https://github.com/qase-tms/qasectl/releases/download/v0.3.9/qasectl-linux-${ARCH} -o /usr/local/bin/qasectl && \
    chmod +x /usr/local/bin/qasectl && \
    /usr/local/bin/qasectl version || echo "qasectl installation test failed"

# Copy the action script
COPY src/action.sh /action.sh

# Copy the entrypoint wrapper
COPY entrypoint.sh /entrypoint.sh

# Make scripts executable
RUN chmod +x /action.sh /entrypoint.sh

# Set the entrypoint to use the wrapper
ENTRYPOINT ["/entrypoint.sh"]
