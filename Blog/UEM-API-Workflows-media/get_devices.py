import requests
import os
import sys
from dotenv import load_dotenv
from datetime import datetime, timedelta
load_dotenv()
HOST = os.getenv("HOST")
API_KEY = os.getenv("API_KEY")
CLIENT_ID = os.getenv("CLIENT_ID")
CLIENT_SECRET = os.getenv("CLIENT_SECRET")

AUTH_HOST = "na.uemauth.vmwservices.com"

# Global variables for caching the token
bearer_token = ""
script_run_time = datetime.now()
token_expiry = script_run_time
expires_in = 0

# Function to handle API requests with error handling
def make_request(method, url, headers=None, data=None):
    try:
        response = requests.request(method, url, headers=headers, data=data)
        response.raise_for_status()  # Raise an exception for HTTP errors
        return response
    except requests.exceptions.HTTPError as http_err:
        print(f"HTTP error occurred: {http_err}")
    except requests.exceptions.ConnectionError as conn_err:
        print(f"Connection error occurred: {conn_err}")
    except requests.exceptions.Timeout as timeout_err:
        print(f"Timeout error occurred: {timeout_err}")
    except requests.exceptions.RequestException as req_err:
        print(f"An error occurred: {req_err}")
    return None


# Function to get Bearer Token with caching
def get_bearer_token():
    global bearer_token, token_expiry, expires_in

    current_time = datetime.now()
    if bearer_token and token_expiry > current_time + timedelta(seconds=expires_in):
        return bearer_token

    url = f"https://{AUTH_HOST}/connect/token"
    payload = f'grant_type=client_credentials&client_id={CLIENT_ID}&client_secret={CLIENT_SECRET}'
    headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Chrome',
        'Accept': 'application/json'
    }
    response = make_request("POST", url, headers=headers, data=payload)
    if response is None:
        sys.exit("Failed to obtain access token.")

    response_json = response.json()
    bearer_token = response_json["access_token"]
    expires_in = response_json["expires_in"]
    token_expiry = current_time + timedelta(seconds=expires_in - 120)  # 2 minute buffer

    return bearer_token

# Function to get devices list
def get_devices_list(headers):
    url = f"https://{HOST}/api/system/devices/search?searchtext=%"
    headers["Authorization"] = f'Bearer {get_bearer_token()}'
    response = make_request("GET", url, headers=headers)
    if response is None:
        sys.exit("Failed to get devices list.")
    return response.json()


headers = {
    "aw-tenant-code": API_KEY,
    "Accept": "application/json;version=2;"
}

print(get_devices_list(headers))