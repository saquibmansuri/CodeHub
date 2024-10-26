# Base Image, use latest version
FROM python:3.11
 
# Set the working directory inside the container to /app
WORKDIR /app

# Copy the requirements.txt file into the container at /app
COPY requirements.txt .

# Install the Python dependencies defined in requirements.txt (--no-cache-dir: Don’t store the intermediate caches to save space)
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application's code into the container at /app
COPY . .

# Set the environment variable PYTHONUNBUFFERED to 1 to ensure that the Python output is sent straight to terminal (container log) and not buffered
ENV PYTHONUNBUFFERED=1

# Inform Docker that the container listens on port 8000 at runtime
EXPOSE 80

# The command to run when the container starts, which is starting the Uvicorn server with the FastAPI app
# --host 0.0.0.0: Makes the server accessible from outside the container
# --port 80: Specifies the port on which to run the application inside the container
# main is the entrypoint
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
