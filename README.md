## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_api_gateway"></a> [api\_gateway](#module\_api\_gateway) | ./modules/api_gateway | n/a |
| <a name="module_cognito"></a> [cognito](#module\_cognito) | ./modules/cognito | n/a |
| <a name="module_lambda"></a> [lambda](#module\_lambda) | ./modules/lambda | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_gateway_stage_name"></a> [api\_gateway\_stage\_name](#input\_api\_gateway\_stage\_name) | The name of the API Gateway deployment stage. | `string` | `"dev"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to deploy resources in. | `string` | `"ap-south-1"` | no |
| <a name="input_cognito_domain_prefix"></a> [cognito\_domain\_prefix](#input\_cognito\_domain\_prefix) | The custom domain prefix for your Cognito User Pool Hosted UI (e.g., 'myauthapp-login'). MUST BE GLOBALLY UNIQUE. | `string` | `"myhelloapp-login-unique"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources. | `map(string)` | <pre>{<br>  "Environment": "development",<br>  "ManagedBy": "Terraform",<br>  "Project": "UserAuthHelloDemo"<br>}</pre> | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | A prefix for all resource names. | `string` | `"MyHelloAuthApp"` | no |
| <a name="input_resource_path_part"></a> [resource\_path\_part](#input\_resource\_path\_part) | The path part for the API Gateway resource (e.g., 'hello'). | `string` | `"hello"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_gateway_url"></a> [api\_gateway\_url](#output\_api\_gateway\_url) | The URL of the API Gateway endpoint. |
| <a name="output_cognito_user_pool_client_id"></a> [cognito\_user\_pool\_client\_id](#output\_cognito\_user\_pool\_client\_id) | The ID of the Cognito User Pool Client. |
| <a name="output_cognito_user_pool_id"></a> [cognito\_user\_pool\_id](#output\_cognito\_user\_pool\_id) | The ID of the Cognito User Pool. |
