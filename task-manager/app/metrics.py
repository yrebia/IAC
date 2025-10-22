from prometheus_client import Counter, Histogram

REQUEST_COUNT = Counter(
    'http_requests_total',
    'Nombre total de requêtes HTTP',
    ['method', 'endpoint', 'http_status']
)

REQUEST_LATENCY = Histogram(
    'http_request_latency_seconds',
    'Latence des requêtes HTTP en secondes',
    ['method', 'endpoint']
)
