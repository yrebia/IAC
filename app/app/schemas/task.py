from pydantic import BaseModel, ConfigDict
from typing import Optional
from uuid import UUID


class CreateTaskRequest(BaseModel):
    title: str
    content: Optional[str] = None
    due_date: Optional[str] = None
    request_timestamp: str


class UpdateTaskRequest(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    done: Optional[bool] = None
    request_timestamp: str


class DeleteTaskRequest(BaseModel):
    request_timestamp: str


class TaskResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    title: str
    content: Optional[str] = None
    due_date: Optional[str] = None
    done: bool = False
