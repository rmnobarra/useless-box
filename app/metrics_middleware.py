from prometheus_client import Counter, Histogram
import time

# Métricas de requests
http_requests_total = Counter(
    "http_requests_total", "Total de requisições HTTP",
    ["method", "endpoint", "http_status"]
)

http_request_duration_seconds = Histogram(
    "http_request_duration_seconds", "Tempo de resposta por rota",
    ["method", "endpoint"]
)

class MetricsMiddleware:
    def __init__(self, app):
        self.app = app

    def __call__(self, environ, start_response):
        start_time = time.time()

        def custom_start_response(status, headers, *args):
            status_code = status.split(" ")[0]
            method = environ.get("REQUEST_METHOD")
            path = environ.get("PATH_INFO")

            http_requests_total.labels(method=method, endpoint=path, http_status=status_code).inc()

            duration = time.time() - start_time
            http_request_duration_seconds.labels(method=method, endpoint=path).observe(duration)

            return start_response(status, headers, *args)

        return self.app(environ, custom_start_response)
