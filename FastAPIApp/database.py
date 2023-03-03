""" Setting up the Database """
from datetime import datetime

from beanie import Document, init_beanie
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseSettings, Field, MongoDsn


# Mongodb Config
class MongoDBConfig(BaseSettings):
    DB_URI: MongoDsn = Field(...)
    MONGO_INITDB_DATABASE: str = "azure-function-app"
    COLLECTION_NAME: str = "fastapi-beanie"


settings = MongoDBConfig()


# MongoDB Collection's Schema
class Product(Document):
    name: str  # You can use normal types just like in pydantic
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        # collection name
        name = settings.COLLECTION_NAME

    class Config:
        # example shows up on docs page
        schema_extra = {
            "example": {
                "name": "acefei's",
                "created_at": datetime.utcnow(),
            }
        }


async def init_db(app):
    app.mongo_client = AsyncIOMotorClient(settings.DB_URI)
    await init_beanie(database=app.mongo_client[settings.MONGO_INITDB_DATABASE], document_models=[Product])
