import boto3
import json

from pydantic_settings import BaseSettings, SettingsConfigDict
from botocore.exceptions import ClientError

def get_aws_secret(secret_name: str, region_name: str) -> dict:
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        raise e

    secret = get_secret_value_response['SecretString']
    return json.loads(secret)

class Settings(BaseSettings):

    app_name: str = "Tasks API"
    app_version: str = "1.0.0"
    debug: bool = False
    log_level: str = "INFO"

    host: str = "0.0.0.0"
    port: int = 8443

    ssl_enabled: bool = False
    ssl_cert_path: str = "certs/cert.pem"
    ssl_key_path: str = "certs/key.pem"

    database_name : str = "db"
    database_username : str = "appdbuser"
    database_password : str = "password"
    database_host: str = "0.0.0.0"
    database_port: int = 5432
    aws_database_password_secret_name: str = ""
    aws_database_password_secret_region: str = ""

    cors_enabled: bool = True
    cors_origins: str = "*"

    bearer_token: str = ""


    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore"
    )


settings = Settings()

# aws_database_secret = get_aws_secret(settings.aws_database_password_secret_name, settings.aws_database_password_secret_region)
# settings.database_password = aws_database_secret.get("password", "")
# settings.database_username = aws_database_secret.get("username", "")
