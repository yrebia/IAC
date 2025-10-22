from app.settings import settings
from .postgres_sql_database_service import PostgresSQLDatabaseService

db_service = PostgresSQLDatabaseService(settings.database_url)
