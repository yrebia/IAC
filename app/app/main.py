from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes import tasks_router
from app.middleware.metrics import MetricsMiddleware
from app.settings import settings
from app.services import db_service
from app.models import Task

from prometheus_client import make_asgi_app as prometheus_asgi_app
from prometheus_fastapi_instrumentator import Instrumentator
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)

logger = logging.getLogger(__name__)

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    debug=settings.debug
)

db_service.create_tables()

if settings.cors_enabled:
    origins_value = settings.cors_origins or ""
    if origins_value.strip() == "*":
        app.add_middleware(
            CORSMiddleware,
            allow_origin_regex=".*",
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )
    else:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=[o.strip() for o in origins_value.split(",") if o.strip()],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

app.add_middleware(MetricsMiddleware)
Instrumentator().instrument(app).expose(app)


@app.get("/health")
def health():
    logger.info("Ping endpoint hit")
    return "OK"

app.include_router(tasks_router)

metrics_app = prometheus_asgi_app()
app.mount("/metrics", metrics_app)
