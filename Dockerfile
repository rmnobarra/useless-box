FROM python:3.9-slim

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    libffi-dev \
    libssl-dev \
    libev-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

ENV FLASK_ENV=development

CMD ["gunicorn", "--worker-class", "geventwebsocket.gunicorn.workers.GeventWebSocketWorker", "--bind", "0.0.0.0:5000", "wsgi:app"]
