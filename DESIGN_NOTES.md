# Design Notes

## Goal

- Serve private assets from S3 through a public CloudFront endpoint without exposing the bucket directly.

## Request Flow

- Client -> CloudFront -> Lambda Function URL -> S3.
- The Lambda maps the request path to an S3 object key and returns the object with the stored content type when available.

## Deployment Model

- Deployment is split into two phases.
- A one-time bootstrap deployment runs with an empty `ImageUri` and creates the shared infrastructure required by the pipeline.
- Later deployments use a digest-based container image reference and create or update the runtime resources.

## CI/CD Flow

- Pull requests run tests and validate that the container image can be built, without publishing artifacts to AWS.
- Pushes to the `main` branch can publish the image and trigger deployment automatically.
- Deployment is triggered from the build workflow through `workflow_run`.
- Deployment uses the exact image digest produced by the build workflow.

## Security Model

- The S3 bucket stays private and denies insecure transport.
- The Lambda Function URL uses `AWS_IAM` and is intended to be reached through CloudFront rather than directly.
- GitHub Actions authenticates to AWS through OIDC instead of long-lived credentials.
- Container deployment accepts only digest-based image references to avoid mutable tags.

## Operational Notes

- The pipeline cannot bootstrap a completely empty AWS setup by itself because the trust path for GitHub Actions is created by the same stack.
- CloudFront caching means asset updates should use versioned object keys or an invalidation step.
- The S3 bucket and ECR repository are retained on stack deletion, so a clean redeploy with the same names may require manual cleanup.
