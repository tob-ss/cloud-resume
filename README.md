# My Cloud Resume Challenge

This is my implementation of the [Cloud Resume Challenge](https://cloudresumechallenge.dev/) using AWS serverless services and Terraform for infrastructure management.

![Cloud Resume Architecture](docs/images/cloud-resume-architecture.svg)

## The Architecture

For my cloud resume, I built a completely serverless architecture on AWS. About 95% of the infrastructure is managed through Terraform, with just the GitHub repository and Actions workflows being set up manually.

### Main Components:
- **Frontend**: S3 for hosting, CloudFront for delivery, and Route 53 for DNS
- **Backend**: API Gateway, Lambda function, and DynamoDB for the visitor counter
- **CI/CD**: GitHub Actions for automating deployments
- **Multiple Environments**: Pre-production for testing and Production for the live site

## How I Built It

Here's a walkthrough of how I approached building this project. I've broken it down into phases to make it easier to follow if you want to build something similar.

### Phase 1: Setting Up the Foundation

First, I needed a reliable way to manage my infrastructure:

1. **AWS Account Structure**
   - Set up separate AWS accounts for pre-prod and prod environments
   - Created AWS CLI profiles for each environment
   - Used profile-based authentication for clear separation

2. **Terraform State Management**
   - Created separate S3 buckets in each account to store Terraform state remotely
   - Added DynamoDB tables for state locking to prevent conflicts
   - Bootstrapped the remote state infrastructure using Terraform itself

3. **Environment Structure**
   - Organized my Terraform code with reusable modules
   - Created separate directories for pre-prod and prod environments
   - Used environment-specific variable files for configuration

### Phase 2: Building the Frontend Infrastructure

For the frontend, I built everything in a logical sequence:

1. **Storage First Approach**
   - Started with S3 buckets for hosting my resume website
   - Configured the buckets with website hosting enabled
   - Set up proper bucket policies to restrict direct access

2. **Security and HTTPS**
   - Registered a domain through Route 53 console for maximum reliability
   - Created SSL certificates through ACM for HTTPS
   - Set up DNS validation for the certificates
   - Ensured certificates were in us-east-1 region for CloudFront compatibility

3. **Content Delivery**
   - Created CloudFront distributions pointing to my S3 buckets
   - Set up Origin Access Identity for S3 bucket security
   - Configured cache behaviors for optimal performance
   - Pointed my domain to CloudFront via Route 53 alias records

### Phase 3: Creating the Backend

For the visitor counter functionality, I needed a simple backend:

1. **Database**
   - Created a DynamoDB table with a simple structure to store visit counts
   - Kept it cost-effective with on-demand capacity
   - Used a simple partition key structure

2. **API Creation**
   - Built a REST API with API Gateway
   - Set up the necessary resources and methods
   - Added CORS configuration so my frontend JavaScript could access it
   - Created separate stages for pre-prod and prod

3. **Lambda Function**
   - Wrote a function to handle incrementing and retrieving the visitor count
   - Set up IAM roles with just the permissions it needed
   - Added error handling and made sure to include logging
   - Packaged it up so Terraform could deploy it

### Phase 4: Developing the Resume Website

Time to create the actual resume:

1. **Resume Design**
   - Created the HTML/CSS for my resume
   - Kept the design clean and professional

2. **Adding the Counter**
   - Wrote JavaScript to call my API and get the current count
   - Handled any potential errors gracefully
   - Updated the counter display on the page
   - Added a small animation to make it more interesting

### Phase 5: Setting Up CI/CD

To make updates easy, I automated the deployment process:

1. **GitHub Repository**
   - Organized my repo with clear folders for frontend, backend, and infrastructure
   - Set up branch protection on main to prevent accidental changes
   - Added AWS access secrets to GitHub securely

2. **GitHub Actions Workflows**
   - Created workflows to deploy infrastructure changes
   - Set up automated frontend builds and deployments
   - Added steps to invalidate CloudFront cache after updates
   - Made sure production deployments required approval

3. **Deployment Process**
   - Set things up to test in pre-prod first
   - Created a promotion workflow to move changes to production
   - Added verification steps before anything went live

### Phase 6: Security and Monitoring

Finally, I made sure everything was secure and observable:

1. **Security Setup**
   - Followed the principle of least privilege for all IAM roles
   - Created specific service roles rather than using broad permissions
   - Regularly reviewed and updated permissions
   - Made sure S3 buckets weren't publicly accessible except through CloudFront

2. **Monitoring**
   - Added CloudWatch alarms for important metrics
   - Set up logging for all services
   - Created a simple dashboard to monitor everything in one place
   - Added email notifications for any issues

## What I Learned

Building this project taught me a lot about serverless architecture and infrastructure as code. The biggest takeaways were:

- Serverless is amazing for projects like this - no servers to manage means less overhead
- Terraform makes it possible to recreate the entire infrastructure reliably
- Having separate environments is crucial for testing changes before they go live
- CI/CD automation saves a ton of time once it's set up

## Future Improvements

There are several things I'd like to add in the future:

- A simple CMS to make resume updates easier
- More comprehensive monitoring
- Additional security features like AWS WAF
- Automated testing for both frontend and backend

## Helpful Resources

If you're looking to build something similar, these resources were invaluable:
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Documentation](https://docs.aws.amazon.com/)
- [Cloud Resume Challenge](https://cloudresumechallenge.dev/)