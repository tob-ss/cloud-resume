## Architecture

The Cloud Resume Challenge implements a serverless architecture using AWS services, with infrastructure managed through Terraform.

![Cloud Resume Architecture](docs/images/cloud-resume-architecture.svg)

### Key Components:
- **Frontend**: S3, CloudFront, Route 53
- **Backend**: API Gateway, Lambda, DynamoDB
- **Infrastructure**: Terraform (~95% coverage)
- **CI/CD**: GitHub Actions