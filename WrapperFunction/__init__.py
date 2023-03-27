import logging

import azure.functions as func
from azure.functions._http_asgi import AsgiRequest, AsgiResponse

from FastAPIApp import app  # Main API application
from FastAPIApp.database import Product


@app.get("/hello/{name}")
async def get_name(
    name: str,
):
    logging.info(f"Connected DB with {app.mongo_client}")
    res = await Product(name=name).create()
    ret = {"message": f"{name}'s product created successfully with {res}"}
    logging.info(ret)
    return ret


# [BUG] Support for ASGI startup events
# async def main(req: func.HttpRequest, context: func.Context) -> func.HttpResponse:
#     return await func.AsgiMiddleware(app).handle_async(req, context)

IS_INITED = False


async def run_setup(app):
    """Workaround to run Starlette startup events on Azure Function Workers."""
    global IS_INITED
    if not IS_INITED:
        await app.router.startup()
        IS_INITED = True


async def handle_asgi_request(req: func.HttpRequest, context: func.Context) -> func.HttpResponse:
    asgi_request = AsgiRequest(req, context)
    scope = asgi_request.to_asgi_http_scope()
    asgi_response = await AsgiResponse.from_app(app, scope, req.get_body())
    return asgi_response.to_func_response()


async def main(req: func.HttpRequest, context: func.Context) -> func.HttpResponse:
    await run_setup(app)
    return await handle_asgi_request(req, context)
