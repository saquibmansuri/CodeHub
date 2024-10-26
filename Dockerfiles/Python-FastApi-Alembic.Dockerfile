# Base image as python 3.11, choose desired/latest version
FROM python:3.11 as base

# Set the working directory inside the container
WORKDIR /app

# Copy the requirements.txt file into the container
COPY requirements.txt .

# Install the Python dependencies defined in requirements.txt (--no-cache-dir: Don’t store the intermediate caches to save space)
RUN pip install --no-cache-dir -r requirements.txt

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=${PYTHONPATH}:${PWD}

##################################################################################

# Start a new build stage, choose desired/latest version
FROM python:3.11

# Set the working directory in the new image
WORKDIR /app

# Install system dependencies/drivers, these are required in the final image
RUN apt-get update && apt-get install -y \
    libmagic-dev \
    poppler-utils \
    libreoffice \
    pandoc \
    tesseract-ocr \
    && apt-get clean && rm -rf /var/lib/apt/lists/* 

# Copy the installed dependencies from the base image
COPY --from=base /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=base /usr/local/bin /usr/local/bin
COPY --from=base /app /app

# Set environment
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=${PYTHONPATH}:${PWD}

# Copy the rest of the application's code into the container at /app
COPY . .

# Inform Docker that the container listens on port 80 at runtime
EXPOSE 80

# This entry point script is in src/backend/ and it contains commands to perform alembic migrations and then start the application
######### entrypoint.sh content ###########
#  #!/bin/sh
#  alembic upgrade heads
#  uvicorn app:app --host 0.0.0.0 --port 80
###########################################

RUN chmod +x entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
