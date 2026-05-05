# Alpine-based Python image — lightweight, well under 300MB limit
FROM python:3.12-alpine

# Create a non-root group and user
# WHY: running as root inside a container is a security risk
# if the app is exploited, the attacker gets root inside the container
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory inside the container
WORKDIR /app

# Copy only what the app needs to run
# WHY not COPY . . — avoids copying certs, configs, README into the image
COPY app/main.py .

# Switch to non-root user before the app starts
USER appuser

# Default environment variables
# WHY here: gives safe fallbacks if docker-compose doesn't inject them
ENV MODE=stable
ENV APP_VERSION=1.0.0
ENV APP_PORT=3000

# Document which port the app listens on
# WHY expose and not ports: expose is internal-only
# the actual port mapping is handled by docker-compose
EXPOSE 3000

# Health check — Docker polls this to know if the container is healthy
# start_period gives the app 10s to boot before failures are counted
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:3000/healthz')" || exit 1

# Command that runs when the container starts
CMD ["python", "main.py"]
