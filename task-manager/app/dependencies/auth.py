from fastapi import Header, HTTPException
from app.settings import settings
from typing import Optional


def validate_headers(
    correlation_id: Optional[str] = Header(..., alias="correlation_id"),
    authorization: Optional[str] = Header(...)
):
    """
    Dependency to validate request headers.
    Ensures correlation_id and authorization are present.
    Validates the Bearer token against the configured token.
    Returns 400 if correlation_id is missing.
    Returns 401 if authorization is missing or invalid.
    """
    # Check for missing correlation_id - returns 400 Bad Request
    if not correlation_id:
        raise HTTPException(
            status_code=400, detail="Missing required header: correlation_id")

    # Check for missing authorization - returns 401 Unauthorized
    if not authorization:
        raise HTTPException(
            status_code=401, detail="Missing required header: authorization")

    # Check authorization format - returns 401 Unauthorized
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401, detail="Invalid authorization header format. Expected 'Bearer <token>'")

    # Extract token from "Bearer <token>"
    token = authorization.split(" ", 1)[1] if len(authorization.split(" ", 1)) > 1 else ""

    # Validate token - returns 401 Unauthorized
    if token != settings.bearer_token:
        raise HTTPException(
            status_code=401, detail="Invalid authentication token")

    return {"correlation_id": correlation_id, "authorization": authorization}
