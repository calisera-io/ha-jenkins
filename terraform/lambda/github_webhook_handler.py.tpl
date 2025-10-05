import json
import hmac
import hashlib
import boto3
import urllib.parse
import urllib3

http = urllib3.PoolManager()
ssm = boto3.client('ssm')

jenkins_url = "http://${jenkins_private_ip}:8080"

jenkins_username = ssm.get_parameter(
    Name="/jenkins/dev/jenkins_admin_id",
    WithDecryption=True
)["Parameter"]["Value"]

jenkins_password = ssm.get_parameter(
    Name="/jenkins/dev/jenkins_admin_password",
    WithDecryption=True
)["Parameter"]["Value"]

def get_jenkins_crumb():
    url = f"{jenkins_url}/crumbIssuer/api/json"
    headers = urllib3.util.make_headers(basic_auth=f"{jenkins_username}:{jenkins_password}")
    response = http.request("GET", url, headers=headers)
    data = json.loads(response.data.decode())
    return data["crumbRequestField"], data["crumb"]

def forward_to_jenkins(payload, event_type):
    crumb_field, crumb_value = get_jenkins_crumb()
    
    auth_headers = urllib3.util.make_headers(basic_auth=f"{jenkins_username}:{jenkins_password}")
    headers = {
        "Content-Type": "application/json",
        "X-GitHub-Event": event_type,
        crumb_field: crumb_value,
        **auth_headers
    }

    response = http.request(
        "POST",
        f"{jenkins_url}/github-webhook/",
        body=json.dumps(payload),
        headers=headers,
        timeout=10.0
    )
    return response.status, response.data.decode("utf-8")

def lambda_handler(event, context):

    body = event.get("body")
    if not body:
        return {"statusCode": 400, "body": "Empty body"}
    
    secret = ssm.get_parameter(
        Name="/jenkins/dev/github_webhook_secret",
        WithDecryption=True
    )["Parameter"]["Value"]

    headers = {k.lower(): v for k, v in event.get("headers", {}).items()}

    signature = headers.get("x-hub-signature-256", "")

    if signature:
        expected = "sha256=" + hmac.new(
            secret.encode(),
            body.encode(),
            hashlib.sha256
        ).hexdigest()
        
        if not hmac.compare_digest(signature, expected):
            return {"statusCode": 401, "body": "Unauthorized"}
    else:
        return {"statusCode": 400, "body": "Missing signature"}

    if body.startswith("payload="):
        decoded = urllib.parse.unquote_plus(body[len("payload="):])
        try:
            payload = json.loads(decoded)
        except json.JSONDecodeError as e:
            print(f"JSON decode error: {e}")
            return {"statusCode": 400, "body": "Invalid JSON"}
    else:
        return {"statusCode": 400, "body": "Invalid format"}

    event_type = headers.get("x-github-event", "")
    forward_events = {"push", "pull_request", "status"}

    if event_type in forward_events:
        if event_type == "push":
            print(f"Push to {payload['repository']['name']}")
        elif event_type == "pull_request":
            print(f"PR {payload['action']}: {payload['pull_request']['title']}")
        elif event_type == "status":
            print(f"Status update: {payload['state']} for {payload['sha'][:7]}")

        status, text = forward_to_jenkins(payload, event_type)
        print(f"Forwarded to Jenkins: {status} {text}")
    else:
        print(f"Unhandled event type: {event_type}")

    return {
        "statusCode": 200,
        "body": json.dumps({"message": f"Forwarded to Jenkins: {status} {text}"})
    }
