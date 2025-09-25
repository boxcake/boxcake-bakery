FROM alpine:3.19

# Install required packages for portainer configuration
RUN apk add --no-cache \
    curl \
    jq \
    bind-tools \
    ca-certificates

# Set working directory
WORKDIR /scripts

# Default command
CMD ["/bin/sh"]