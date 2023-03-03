import fastapi

from FastAPIApp.database import init_db

app = fastapi.FastAPI()


@app.on_event("startup")
async def start_db() -> None:
    await init_db(app)
