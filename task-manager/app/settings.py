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
    port: int = 443

    ssl_enabled: bool = False
    ssl_cert_path: str = "certs/cert.pem"
    ssl_key_path: str = "certs/key.pem"

    database_url: str = ""

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
