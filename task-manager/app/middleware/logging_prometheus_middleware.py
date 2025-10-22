import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
import time
from app.metrics import REQUEST_COUNT, REQUEST_LATENCY

# Configure le logger
logger = logging.getLogger("prometheus_logger")
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
formatter = logging.Formatter('[%(asctime)s] %(levelname)s in %(module)s: %(message)s')
handler.setFormatter(formatter)
if not logger.hasHandlers():
    logger.addHandler(handler)

class LoggingPrometheusMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        response = await call_next(request)
        process_time = time.time() - start_time

        # Log
        logger.info(f"{request.method} {request.url.path} {response.status_code} - {process_time:.3f}s")

        # Prometheus metrics
        REQUEST_COUNT.labels(request.method, request.url.path, response.status_code).inc()
        REQUEST_LATENCY.labels(request.method, request.url.path).observe(process_time)

        return response
