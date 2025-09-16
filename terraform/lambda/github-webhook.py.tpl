import boto3 # pyright: ignore[reportMissingImports]
import json
import hmac
import hashlib

ssm = boto3.client('ssm')

jenkins_url = "http://${jenkins_private_ip}:8080"

def lambda_handler(event, context):
    secret = ssm.get_parameter(
        Name='/github/webhook-secret',
        WithDecryption=True
    )['Parameter']['Value']
    
    signature = event['headers'].get('x-hub-signature-256', '')
    if signature:
        expected = 'sha256=' + hmac.new(
            secret.encode(), 
            event['body'].encode(), 
            hashlib.sha256
        ).hexdigest()
        
        if not hmac.compare_digest(signature, expected):
            return {'statusCode': 401, 'body': 'Unauthorized'}
    
    payload = json.loads(event['body'])
    event_type = event['headers'].get('x-github-event')

    if event_type == 'push':
        print(f"Push to {payload['repository']['name']}")
    elif event_type == 'pull_request':
        print(f"PR {payload['action']}: {payload['pull_request']['title']}")

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Webhook processed'})
    }