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
           ////////////  
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
    files_to_delete = []

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        for fname in sorted(os.listdir(LOG_DIR)):
            if not fname.startswith("messages.jsonl"):
                continue

            path = os.path.join(LOG_DIR, fname)
            last_offset = state.get(fname, 0)
            file_has_new_data = False

            with open(path, "r") as f:
                f.seek(last_offset)
                while True:
                    line = f.readline()
                    if not line:
                        break
                    file_has_new_data = True
                    try:
                        result = process_line(line)
                        if result:
                            tasks.append(executor.submit(download_gcs_object, *result))
                    except Exception as e:
                        logging.error(f"Error processing line in {fname}: {e}")
                    last_offset = f.tell()

            # Update the state with the new offset
            if file_has_new_data:
                state[fname] = last_offset

            # If the file has been fully processed (no new data was found), mark it for deletion
            if not file_has_new_data and fname in state:
                files_to_delete.append(path)
                # Remove from state to prevent reprocessing in future runs
                del state[fname]

    # Wait for all downloads to finish
    for future in as_completed(tasks):
        try:
            future.result()
        except Exception as e:
            logging.error(f"Download task error: {e}")

    # Save the updated state
    save_state(state)

    # Clean up processed files
    for path in files_to_delete:
        try:
            os.remove(path)
            logging.info(f"Successfully deleted processed log file: {path}")
        except OSError as e:
            logging.error(f"Error deleting file {path}: {e}")

if __name__ == "__main__":
    while True:
        try:
            poll_logs()
        except Exception as e:
            logging.error(f"An unexpected error occurred during polling: {e}")
        
        logging.info("Polling complete. Sleeping for 60 seconds...")
        time.sleep(5) # Sleeps for 60 seconds before the next run
