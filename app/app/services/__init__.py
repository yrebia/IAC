from app.settings import settings
from .postgres_sql_database_service import PostgresSQLDatabaseService

db_service = PostgresSQLDatabaseService(
    f"postgresql://{settings.database_username}:{settings.database_password}@{settings.database_host}:{settings.database_port}/{settings.database_name}"
)
