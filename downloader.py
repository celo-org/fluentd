#!/usr/bin/env python3

import os
import json
import logging
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from google.cloud import storage
from google.api_core.exceptions import GoogleAPIError

LOG_DIR = "/fluentd/log/github-audit/pub-sub/message_queue/"
STATE_FILE = "/fluentd/log/github-audit/pub-sub/state.json"
DOWNLOAD_DIR = "/fluentd/log/github-audit/gcs/input_logs"
MAX_WORKERS = 5  # Number of parallel downloads
MAX_RETRIES = 5
BASE_BACKOFF = 1  # seconds

os.makedirs(DOWNLOAD_DIR, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[logging.StreamHandler()]
)

storage_client = storage.Client()

def load_state():
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE) as f:
            return json.load(f)
    return {}

def save_state(state):
    with open(STATE_FILE, "w") as f:
        json.dump(state, f)

def download_gcs_object(bucket_name, object_name):
    local_path = os.path.join(DOWNLOAD_DIR, object_name.replace('/', '_'))

    if os.path.exists(local_path):
        logging.info(f"File already downloaded: {local_path}")
        return

    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(object_name)

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            blob.download_to_filename(local_path)
            logging.info(f"Downloaded {bucket_name}/{object_name} to {local_path}")
            return
        except GoogleAPIError as e:
            wait_time = BASE_BACKOFF * (2 ** (attempt - 1))
            logging.warning(f"Attempt {attempt} failed to download {bucket_name}/{object_name}: {e}. Retrying in {wait_time}s...")
            time.sleep(wait_time)
        except Exception as e:
            logging.error(f"Unexpected error downloading {bucket_name}/{object_name}: {e}")
            return

    logging.error(f"Failed to download {bucket_name}/{object_name} after {MAX_RETRIES} attempts.")

def process_line(line):
    record = json.loads(line)
    bucket_name = record.get('bucket')
    object_name = record.get('name')

    if not bucket_name or not object_name:
        logging.warning(f"Missing bucket or object name in record: {record}")
        return None  # Indicate nothing to process

    return (bucket_name, object_name)

def poll_logs():
    state = load_state()
    tasks = []

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        for fname in sorted(os.listdir(LOG_DIR)):
            if not fname.startswith("messages.jsonl"):
                continue

            path = os.path.join(LOG_DIR, fname)
            last_offset = state.get(fname, 0)

            with open(path, "r") as f:
                f.seek(last_offset)
                while True:
                    line = f.readline()
                    if not line:
                        break
                    try:
                        result = process_line(line)
                        if result:
                            tasks.append(executor.submit(download_gcs_object, *result))
                    except Exception as e:
                        logging.error(f"Error processing line in {fname}: {e}")
                    last_offset = f.tell()

            state[fname] = last_offset

        # Wait for all downloads to finish
        for future in as_completed(tasks):
            try:
                future.result()
            except Exception as e:
                logging.error(f"Download task error: {e}")

    save_state(state)

if __name__ == "__main__":
    poll_logs()
