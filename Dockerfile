# ============================
# Stage 1 — Builder
# ============================
FROM nvidia/cuda:11.7.1-runtime-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# System deps
RUN apt-get update && apt-get install -y \
    wget unzip python3 python3-pip git libgl1 libglib2.0-0 libxrender1 libsm6 libxext6 && \
    rm -rf /var/lib/apt/lists/*

# Download and extract Meshroom
WORKDIR /opt
RUN wget https://github.com/alicevision/meshroom/releases/download/v2023.3.0/Meshroom-2023.3.0-linux.tar.gz && \
    tar -xzf Meshroom-2023.3.0-linux.tar.gz && \
    rm Meshroom-2023.3.0-linux.tar.gz

# ============================
# Stage 2 — Runtime
# ============================
FROM nvidia/cuda:11.7.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install minimal runtime deps
RUN apt-get update && apt-get install -y \
    libgl1 libglib2.0-0 libxrender1 libsm6 libxext6 \
    python3 python3-pip awscli && \
    rm -rf /var/lib/apt/lists/*

# Python deps
RUN pip3 install boto3

# Copy Meshroom from builder
COPY --from=builder /opt/Meshroom-2023.3.0-linux /opt/Meshroom

# Add Meshroom to PATH
ENV PATH="/opt/Meshroom:${PATH}"

# Copy script
COPY generator.py /app/generator.py

WORKDIR /data
ENTRYPOINT ["python3", "/app/generator.py"]