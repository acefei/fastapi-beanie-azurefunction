import time

from fastapi import FastAPI, Request

from FastAPIApp.database import init_db

app = FastAPI()


@app.on_event("startup")
async def start_db() -> None:
    await init_db(app)


@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response
