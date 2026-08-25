import urllib.request
import urllib.error
import json
import time
from datetime import datetime, timezone

API_KEY = '988372b529a5d134977e3e3d989d0146'
BASE_URL = 'https://api.fortyguard.com/v1'

def main():
    now = datetime.now(timezone.utc)
    start_date = now.strftime('%Y-%m-%d')
    start_time = now.strftime('%H:%M')
    
    payload = {
        'latitude': 40.4173,
        'longitude': -82.9071,
        'temperature': 90.0,
        'parameters': [
            'temperature_celsius',
            'heat_index_celsius',
            'relative_humidity_percent'
        ],
        'date_time': {
            'filter_type': 1,
            'start_date': start_date,
            'start_time': start_time
        }
    }
    
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(f'{BASE_URL}/env_params', data=data, headers={
        'api-key': API_KEY,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    })
    
    try:
        with urllib.request.urlopen(req) as response:
            resp_body = json.loads(response.read().decode())
            print("POST response:", json.dumps(resp_body))
            
            activity_id = None
            if 'data' in resp_body and isinstance(resp_body['data'], dict):
                activity_id = resp_body['data'].get('activity_id')
            if not activity_id:
                activity_id = resp_body.get('activity_id')
                
            if not activity_id:
                print("No activity_id found")
                return
                
            print("Polling for", activity_id)
            for i in range(15):
                time.sleep(2)
                status_req = urllib.request.Request(f'{BASE_URL}/status/{activity_id}', headers={
                    'api-key': API_KEY,
                    'Accept': 'application/json'
                })
                with urllib.request.urlopen(status_req) as s_resp:
                    s_body = json.loads(s_resp.read().decode())
                    status = None
                    if 'data' in s_body and isinstance(s_body['data'], dict):
                        status = s_body['data'].get('status', s_body.get('status'))
                    else:
                        status = s_body.get('status')
                        
                    print(f"Poll {i} status: {status}")
                    if status and status.lower() == 'completed':
                        print("COMPLETED PAYLOAD:", json.dumps(s_body))
                        return
                    elif status and status.lower() in ['failed', 'error']:
                        print("FAILED:", json.dumps(s_body))
                        return
                        
    except urllib.error.URLError as e:
        print("Error:", e)
        if hasattr(e, 'read'):
            print(e.read().decode())

if __name__ == '__main__':
    main()
