# modules/lambda/hello_world.py

import json

def lambda_handler(event, context):
    """
    A simple Lambda function that returns a "Hello World" HTML page.
    """
    print(f"Received event: {json.dumps(event)}")

    # For authenticated requests, the user's claims will be in event['requestContext']['authorizer']['claims']
    # You can access user information like:
    # user_email = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('email')
    # user_sub = event.get('requestContext', {}).get('authorizer', {}).get('claims', {}).get('sub')

    # Basic HTML content
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Hello World!</title>
        <style>
            body {{ font-family: sans-serif; text-align: center; margin-top: 50px; }}
            h1 {{ color: #333; }}
            p {{ color: #666; }}
        </style>
    </head>
    <body>
        <h1>Hello World from AWS Lambda!</h1>
        <p>This page was served via API Gateway and Lambda.</p>
        <p>You are successfully authenticated with AWS Cognito.</p>
    </body>
    </html>
    """

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'text/html'
        },
        'body': html_content
    }