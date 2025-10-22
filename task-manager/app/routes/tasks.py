from fastapi import APIRouter, HTTPException, Depends, Request
from sqlmodel import Session, select
from typing import List
from datetime import datetime
from uuid import UUID
import logging

from app.services import db_service
from app.models import Task
from app.schemas import CreateTaskRequest, UpdateTaskRequest, DeleteTaskRequest, TaskResponse
from app.dependencies import validate_headers

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/tasks", tags=["tasks"])

@router.post("", response_model=TaskResponse, status_code=201)
def create_task(
    task_request: CreateTaskRequest,
    db_session: Session = Depends(db_service.get_session),
    headers: dict = Depends(validate_headers),
):
    logger.info(f"Creating new task: title='{task_request.title}', due_date={task_request.due_date}")
    try:
        task = Task(
            title=task_request.title,
            content=task_request.content,
            due_date=task_request.due_date,
            last_updated=task_request.request_timestamp
        )
        db_session.add(task)
        db_session.commit()
        db_session.refresh(task)
        logger.info(f"Task created successfully: id={task.id}")
        return task
    except Exception as e:
        logger.error(f"Error creating task: {str(e)}", exc_info=True)
        raise


@router.get("", response_model=List[TaskResponse])
def list_tasks(
    db_session: Session = Depends(db_service.get_session),
    headers: dict = Depends(validate_headers),
):
    logger.info("Listing all tasks")
    try:
        tasks = db_session.exec(select(Task)).all()
        logger.info(f"Retrieved {len(tasks)} tasks")
        return tasks
    except Exception as e:
        logger.error(f"Error listing tasks: {str(e)}", exc_info=True)
        raise


@router.get("/{id}", response_model=TaskResponse)
def get_task(
    id: UUID,
    session: Session = Depends(db_service.get_session),
    headers: dict = Depends(validate_headers),
):
    logger.info(f"Retrieving task: id={id}")
    try:
        task = session.get(Task, id)
        if not task:
            logger.warning(f"Task not found: id={id}")
            raise HTTPException(status_code=404, detail="Task not found")
        logger.info(f"Task retrieved successfully: id={id}")
        return task
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving task {id}: {str(e)}", exc_info=True)
        raise


@router.put("/{id}", response_model=TaskResponse)
def update_task(
    id: UUID,
    task_data: UpdateTaskRequest,
    session: Session = Depends(db_service.get_session),
    headers: dict = Depends(validate_headers),
):
    logger.info(f"Updating task: id={id}, request_timestamp={task_data.request_timestamp}")
    try:
        task = session.get(Task, id)
        if not task:
            logger.warning(f"Task not found for update: id={id}")
            raise HTTPException(status_code=404, detail="Task not found")

        if task.last_updated:
            try:
                print(task.last_updated, task_data.request_timestamp)
                last_updated_datetime = datetime.fromisoformat(
                    task.last_updated.replace('Z', '+00:00'))
                request_datetime = datetime.fromisoformat(
                    task_data.request_timestamp.replace('Z', '+00:00'))
                if request_datetime < last_updated_datetime:
                    logger.warning(f"Conflict detected for task {id}: stale update request")
                    raise HTTPException(status_code=409, detail="Conflict: stale update request")
            except (ValueError, AttributeError) as e:
                logger.error(f"Invalid timestamp for task {id}: {str(e)}")
                raise HTTPException(
                    status_code=400, detail="Invalid request timestamp")

        if task_data.title is not None:
            task.title = task_data.title
        if task_data.content is not None:
            task.content = task_data.content
        if task_data.done is not None:
            task.done = task_data.done
        task.last_updated = task_data.request_timestamp

        session.add(task)
        session.commit()
        session.refresh(task)
        logger.info(f"Task updated successfully: id={id}")
        return task
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating task {id}: {str(e)}", exc_info=True)
        raise


@router.delete("/{id}", status_code=200)
def delete_task(
    id: UUID,
    task_data: DeleteTaskRequest,
    session: Session = Depends(db_service.get_session),
    headers: dict = Depends(validate_headers),
):
    logger.info(f"Deleting task: id={id}, request_timestamp={task_data.request_timestamp}")
    try:
        task = session.get(Task, id)
        if not task:
            logger.warning(f"Task not found for deletion: id={id}")
            raise HTTPException(status_code=404, detail="Task not found")

        if task.last_updated:
            try:
                last_updated_datetime = datetime.fromisoformat(
                    task.last_updated.replace('Z', '+00:00'))
                request_datetime = datetime.fromisoformat(
                    task_data.request_timestamp.replace('Z', '+00:00'))
                if request_datetime < last_updated_datetime:
                    logger.warning(f"Stale delete request for task {id}, ignoring")
                    return None
            except (ValueError, AttributeError) as e:
                logger.error(f"Invalid timestamp for task {id} deletion: {str(e)}")
                raise HTTPException(
                    status_code=400, detail="Invalid request timestamp")

        session.delete(task)
        session.commit()
        logger.info(f"Task deleted successfully: id={id}")
        return None
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting task {id}: {str(e)}", exc_info=True)
        raise
