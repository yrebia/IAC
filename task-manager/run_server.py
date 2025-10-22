import uvicorn
from app.settings import settings


def main():
    use_ssl = settings.ssl_enabled and settings.ssl_cert_path and settings.ssl_key_path

    if not use_ssl:
        uvicorn.run(
            "app.main:app",
            host=settings.host,
            port=settings.port,
            reload=settings.debug,
            log_level=settings.log_level.lower()
        )
        return
    else:
        uvicorn.run(
            "app.main:app",
            host=settings.host,
            port=settings.port,
            ssl_keyfile=settings.ssl_key_path,
            ssl_certfile=settings.ssl_cert_path,
            reload=settings.debug,
            log_level=settings.log_level.lower()
        )


if __name__ == "__main__":
    main()
