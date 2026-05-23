import random
import time
import requests

TOKEN = "TU_TOKEN"

headers = {
    "Authorization": f"Bearer {TOKEN}"
}

while True:
    data = {
        "humidity": random.randint(20, 80),
        "temperature": random.randint(15, 35),
        "ph": round(random.uniform(5.5, 7.5), 2),
        "parcel_id": 1
    }

    response = requests.post(
        "http://127.0.0.1:8000/api/v1/telemetry",
        json=data,
        headers=headers
    )

    print(response.json())

    time.sleep(5)