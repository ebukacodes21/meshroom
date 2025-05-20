# ============================
# Stage 1 — Builder
# ============================
FROM nvidia/cuda:11.7.1-runtime-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and tools
RUN apt-get update && apt-get install -y \
    wget unzip python3 python3-pip git libgl1 libglib2.0-0 libxrender1 libsm6 libxext6 exiftool && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /opt

# Download and extract Meshroom
RUN wget https://github.com/alicevision/meshroom/releases/download/v2023.3.0/Meshroom-2023.3.0-linux.tar.gz && \
    tar -xzf Meshroom-2023.3.0-linux.tar.gz && \
    rm Meshroom-2023.3.0-linux.tar.gz

# ============================
# Stage 2 — Final Runtime
# ============================
FROM nvidia/cuda:11.7.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    libgl1 libglib2.0-0 libxrender1 libsm6 libxext6 exiftool python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Copy Meshroom from builder stage — confirm exact folder name here!
COPY --from=builder /opt/Meshroom-2023.3.0 /opt/Meshroom

# Add Meshroom to PATH
ENV PATH="/opt/Meshroom:${PATH}"

# Set working directory for processing jobs
WORKDIR /data

ENTRYPOINT ["python3", "/app/generator.py"] 