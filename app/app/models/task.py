from sqlmodel import SQLModel, Field
import uuid
from typing import Optional
from uuid import UUID
from datetime import datetime


class Task(SQLModel, table=True):
    id: Optional[UUID] = Field(
        default_factory=uuid.uuid4, primary_key=True, index=True)
    title: str = Field()
    content: Optional[str] = Field(default=None)
    due_date: Optional[str] = Field(default=None)
    done: bool = Field(default=False)
    last_updated: Optional[str] = Field(default=None)
