import json
import os

def handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))

    # Access user information from the API Gateway event's requestContext.authorizer
    # For Cognito User Pool Authorizer, the claims are under claims
    sub_claim = "N/A"
    email_claim = "N/A"
    username_claim = "N/A"

    if 'requestContext' in event and 'authorizer' in event['requestContext'] and 'claims' in event['requestContext']['authorizer']:
        claims = event['requestContext']['authorizer']['claims']
        sub_claim = claims.get('sub', "N/A")
        email_claim = claims.get('email', "N/A")
        username_claim = claims.get('cognito:username', "N/A")
    else:
        print("No authorizer claims found in event. This might be an unauthenticated request or for debugging.")


    # Get environment variables for client-side logout
    user_pool_id = os.environ.get('USER_POOL_ID', 'YOUR_USER_POOL_ID')
    client_id = os.environ.get('CLIENT_ID', 'YOUR_CLIENT_ID')
    aws_region = os.environ.get('AWS_REGION', 'YOUR_AWS_REGION')

    # Important: The Cognito Hosted UI domain is constructed from user_pool_id and region.
    # The user pool ID usually looks like <region>_<uuid>. We need the <uuid> part.
    cognito_domain_prefix_from_id = user_pool_id.split('_')[1] if '_' in user_pool_id else ""
    # For custom domain, you would use that instead:
    # cognito_hosted_ui_base_url = "https://your-custom-domain.com"
    cognito_hosted_ui_base_url = f"https://{cognito_domain_prefix_from_id}.auth.{aws_region}.amazoncognito.com"

    html_content = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Hello World Authenticated</title>
        <style>
            body {{ font-family: Arial, sans-serif; text-align: center; margin-top: 50px; background-color: #f4f4f4; color: #333; }}
            .container {{ background-color: #fff; margin: 20px auto; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); max-width: 600px; }}
            h1 {{ color: #0056b3; }}
            p {{ line-height: 1.6; }}
            .token-info {{ background-color: #e9ecef; padding: 15px; border-radius: 5px; margin-top: 25px; text-align: left; }}
            .token-info p {{ margin: 5px 0; }}
            button {{ background-color: #dc3545; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; font-size: 16px; margin-top: 30px; }}
            button:hover {{ background-color: #c82333; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Hello World!</h1>
            <p>You have successfully authenticated with AWS Cognito and accessed this secure page.</p>

            <div class="token-info">
                <h2>User Details:</h2>
                <p><strong>User ID (sub):</strong> {sub_claim}</p>
                <p><strong>Email:</strong> {email_claim}</p>
                <p><strong>Username:</strong> {username_claim}</p>
            </div>

            <button onclick="logout()">Logout</button>
        </div>

        <script>
            // Get necessary values from hidden elements or global JS vars if not using env vars
            const USER_POOL_ID = "{user_pool_id}";
            const CLIENT_ID = "{client_id}";
            const AWS_REGION = "{aws_region}";
            const COGNITO_HOSTED_UI_BASE_URL = "{cognito_hosted_ui_base_url}";

            function logout() {{
                const currentOrigin = window.location.origin;
                // Redirect to Cognito logout endpoint
                const logoutUrl = `${{COGNITO_HOSTED_UI_BASE_URL}}/logout?client_id=${{CLIENT_ID}}&logout_uri=${{currentOrigin}}/hello`;
                window.location.href = logoutUrl;
            }}

            window.onload = function() {{
                // This script runs when the page loads, which could be directly from API Gateway
                // OR as a redirect from Cognito after authentication.
                const fragment = new URLSearchParams(window.location.hash.substring(1));
                const accessToken = fragment.get('access_token');
                const idToken = fragment.get('id_token');

                if (accessToken && idToken) {{
                    // Tokens found in URL fragment (Implicit flow redirect from Cognito)
                    // You might store these in localStorage/sessionStorage for client-side API calls.
                    console.log("Tokens received from Cognito redirect.");
                    localStorage.setItem('accessToken', accessToken);
                    localStorage.setItem('idToken', idToken);

                    // Clean the URL hash for a better user experience
                    window.history.replaceState({{}}, document.title, window.location.pathname);

                    // If your API Gateway endpoint does not automatically trigger the Lambda with the
                    // authenticated session after the redirect, you might need to make an explicit
                    // fetch call here to your API Gateway with the token.
                    // For this setup, the API Gateway's Gateway Response handles the initial unauthenticated
                    // access, leading to a redirect. Once authenticated, the subsequent request
                    // to the API Gateway will have the Authorization header validated.
                    // The HTML is returned by Lambda in both cases (initial unauth, then auth).
                }} else {{
                    console.log("No tokens found in URL fragment. Might be a direct load or subsequent request.");
                }}
            }};
        </script>
    </body>
    </html>
    """

    final_html = html_content.format(
        sub_claim=sub_claim,
        email_claim=email_claim,
        username_claim=username_claim,
        user_pool_id=user_pool_id,
        client_id=client_id,
        aws_region=aws_region,
        cognito_hosted_ui_base_url=cognito_hosted_ui_base_url
    )

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "text/html", # Crucial for browser to render as HTML
            "Access-Control-Allow-Origin": "*" # Required if frontend is on different origin
        },
        "body": final_html
    }