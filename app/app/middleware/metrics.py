from time import perf_counter
from typing import Optional

from prometheus_client import Counter, Histogram
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request


# Prometheus metrics
HTTP_REQUESTS_TOTAL = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "path", "status"],
)

HTTP_REQUEST_DURATION_SECONDS = Histogram(
    "http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method", "path", "status"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10),
)


def _label_path(request: Request) -> str:
    # Try to use route name/path template for cardinality control
    route: Optional[object] = request.scope.get("route")
    if route and hasattr(route, "path_format"):
        return getattr(route, "path_format")  # FastAPI provides path_format
    if route and hasattr(route, "path"):
        return getattr(route, "path")
    return request.url.path


class MetricsMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        method = request.method
        path = _label_path(request)
        start = perf_counter()
        try:
            response = await call_next(request)
            status = str(response.status_code)
            return response
        except Exception:
            status = "500"
            raise
        finally:
            duration = perf_counter() - start
            HTTP_REQUESTS_TOTAL.labels(method=method, path=path, status=status).inc()
            HTTP_REQUEST_DURATION_SECONDS.labels(method=method, path=path, status=status).observe(duration)
