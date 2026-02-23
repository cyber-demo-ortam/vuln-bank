FROM python:3.9-slim

# Install build tools (required for pycrypto C extension) and PostgreSQL client
RUN apt-get update && apt-get install -y \
    postgresql-client \
    gcc \
    python3-dev \
    autoconf \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Create necessary directories
RUN mkdir -p static/uploads templates

COPY . .

# Ensure uploads directory exists and has proper permissions
RUN chmod 777 static/uploads

EXPOSE 5000

CMD ["python", "app.py"]