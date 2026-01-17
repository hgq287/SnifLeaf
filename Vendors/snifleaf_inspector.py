import json
import time
from urllib.parse import urlparse, parse_qs
from mitmproxy import http
import sys

def response(flow: http.HTTPFlow):
    if flow.response:
        try:
            # Filter unnecessary requests
            #   - Skip static requests, e.g., images, fonts, CSS, and JS.
            content_type = flow.response.headers.get("Content-Type", "").lower()
            excluded_types = ["image", "font", "javascript", "css", "video", "audio", "zip", "octet-stream", "application/pdf"]
            if any(x in content_type for x in excluded_types):
                return

            # Handle logic to create Json
            parsed_url = urlparse(flow.request.url)
            host = parsed_url.netloc
            path = parsed_url.path

            query_params_dict = parse_qs(parsed_url.query)
            simplified_query_params = {k: v[0] for k, v in query_params_dict.items()} if query_params_dict else {}
            query_params_json_str = json.dumps(simplified_query_params, ensure_ascii=False) if simplified_query_params else None

            request_body_content = None
            request_content = flow.request.content
            if request_content:
                try:
                    # Size limit: if body > 100kb, do not process
                    if len(request_content) <= 102400:
                        request_body_content = request_content.decode('utf-8')
                    else:
                        request_body_content = f"[Content Truncated: {len(request_content)} bytes]"
                except UnicodeDecodeError:
                    import base64
                    request_body_content = base64.b64encode(request_content).decode('utf-8')

            response_body_content = None
            response_content = flow.response.content
            if response_content:
                try:
                    # Size limit: if body > 100kb, do not process
                    if len(response_content) <= 102400:
                        response_body_content = response_content.decode('utf-8')
                    else:
                        response_body_content = f"[Content Truncated: {len(response_content)} bytes]"
                except UnicodeDecodeError:
                    import base64
                    response_body_content = base64.b64encode(flow.response.content).decode('utf-8')

            request_headers_dict = dict(flow.request.headers)
            request_headers_json_str = json.dumps(request_headers_dict, ensure_ascii=False)

            response_headers_dict = dict(flow.response.headers)
            response_headers_json_str = json.dumps(response_headers_dict, ensure_ascii=False)

            timestamp = int(flow.request.timestamp_start)
            latency = (flow.response.timestamp_end - flow.request.timestamp_start) if flow.response.timestamp_end and flow.request.timestamp_start else 0.0

            log_entry = {
                "id": None,
                "timestamp": timestamp,
                "method": flow.request.method,
                "url": flow.request.url,
                "host": host,
                "path": path,
                "queryParams": query_params_json_str,
                "requestSize": len(flow.request.content) if flow.request.content else 0,
                "responseSize": len(flow.response.content) if flow.response.content else 0,
                "statusCode": flow.response.status_code,
                "latency": latency,
                "requestHeaders": request_headers_json_str,
                "responseHeaders": response_headers_json_str,
                "requestBodyContent": request_body_content,
                "responseBodyContent": response_body_content,
                "trafficCategory": "Unknown"
            }
            
            # Output filtered requests to JSON
            print(json.dumps(log_entry, ensure_ascii=False), flush=True)
        except Exception as e:
            print(f"Error in mitmproxy addon: {e}", file=sys.stderr, flush=True)

addons = [
    response
]
