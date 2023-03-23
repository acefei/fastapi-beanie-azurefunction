import asyncio
import logging
import sys
from collections import defaultdict
from time import perf_counter

from aiohttp import ClientSession


async def gather_requests(base_url, headers, concurrent_num):
    async with ClientSession(headers=headers) as aiohttp_client:
        logging.info(f"Sending {concurrent_num} requests simultaneously.")
        start_time = perf_counter()
        tasks = [aiohttp_client.post(base_url) for _ in range(concurrent_num)]
        responses = await asyncio.gather(*tasks, return_exceptions=True)
        end_time = perf_counter()

        count_status = defaultdict(int)
        for r in responses:
            count_status[r.status] += 1
            if not r.ok:
                logging.debug(f"Response {r.status}: {r.reason}")

        logging.info(f"Running Time: {end_time - start_time:.2f} seconds, HTTP Status: {dict(count_status)}")


async def sequent_requests(base_url, headers, concurrent_num):
    responses = []
    logging.info(f"Sending {concurrent_num} requests sequentially.")
    for _ in range(concurrent_num):
        async with ClientSession(headers=headers) as aiohttp_client:
            res = await aiohttp_client.post(base_url)
            responses.append(res)
            await asyncio.sleep(1)

    count_status = defaultdict(int)
    for r in responses:
        count_status[r.status] += 1
        if not r.ok:
            logging.debug(f"Response {r.status}: {r.reason}")

    logging.info(f"HTTP Status: {dict(count_status)}")


async def main():
    concurrent_num = int(sys.argv[1]) if sys.argv[1:] else 1000
    logging.basicConfig(
        level=logging.DEBUG if "debug" in sys.argv else logging.INFO, format=("[%(levelname)s] %(message)s")
    )

    base_url = "http://localhost:7071/hello/acefei"
    headers = {"User-Agent": "test function app"}
    if "bulk" in sys.argv:
        await gather_requests(base_url, headers, concurrent_num)
    else:
        await sequent_requests(base_url, headers, concurrent_num)


asyncio.run(main())
