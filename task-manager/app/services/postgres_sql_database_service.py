from sqlmodel import create_engine, Session
from typing import Generator
from sqlmodel import SQLModel

class PostgresSQLDatabaseService:

    _database_url: str = ""

    def __init__(self, database_url: str):
        self._database_url = database_url
        self._engine = create_engine(self._database_url, echo=False)

    def create_tables(self):
        SQLModel.metadata.create_all(self._engine)

    def get_session(self) -> Generator[Session, None, None]:
        with Session(self._engine) as session:
            yield session
