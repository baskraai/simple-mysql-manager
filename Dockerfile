FROM python:3.9-buster
LABEL Maintainer Bas Kraai <bas@kraai.email>

WORKDIR /app

# Install tools
RUN apt-get update \
    && apt-get install --no-install-recommends -y wget mariadb-client jq \
    && rm -rf /var/lib/apt/lists/*

# Install packages
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Install Minio Client
RUN cd /usr/bin \
    && wget https://dl.min.io/client/mc/release/linux-amd64/mc \
    && chmod +x mc

EXPOSE 5000

COPY . /app

RUN chmod +x docker-entrypoint.sh
ENTRYPOINT ["/app/docker-entrypoint.sh"]
