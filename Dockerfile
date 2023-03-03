FROM python:3.10-slim-buster AS azure_functions_core_tools
ENV DEBIAN_VERSION=10
RUN apt-get update -y  && apt-get install -y curl gpg libicu-dev\
 && curl -s https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg \
 && mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/ \
 && curl -O https://packages.microsoft.com/config/debian/${DEBIAN_VERSION}/prod.list \
 && mv prod.list /etc/apt/sources.list.d/microsoft-prod.list \
 && chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg \
 && chown root:root /etc/apt/sources.list.d/microsoft-prod.list \
 && apt-get update -y \
 && apt-get install -y azure-functions-core-tools-4 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install -r requirements.txt
WORKDIR /app
CMD ["func", "start"]
