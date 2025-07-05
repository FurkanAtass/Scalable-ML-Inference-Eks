import asyncio
import httpx
import sys
import time

API_URL = "http://localhost:8000/predict"  # LoadBalancer IP with standard port

async def send_request(client, image_path):
    with open(image_path, "rb") as f:
        files = {"file": (image_path, f, "image/jpeg")}
        try:
            response = await client.post(API_URL, files=files)
            print(response.json())
        except Exception as e:
            print(f"Request failed: {e}")

async def main(image_path, n):
    start_time = time.time()
    async with httpx.AsyncClient(timeout=60) as client:
        tasks = [send_request(client, image_path) for _ in range(n)]
        print("Sending requests")
        await asyncio.gather(*tasks)
    end_time = time.time()
    print(f"Time taken: {end_time - start_time} seconds")
if __name__ == "__main__":
    if len(sys.argv) == 1:
        image_path = "test_image.png"
        n = 1
    elif len(sys.argv) == 2:
        n = int(sys.argv[1])
        image_path = "test_image.png"
    else:
        image_path = sys.argv[2]
        n = int(sys.argv[1])
    asyncio.run(main(image_path, n))