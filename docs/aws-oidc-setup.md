# Configure OIDC login for AWS

This document outlines the steps to configure OpenID Connect (OIDC) login for AWS using **Auth0 by Okta**.

## Prerequisites:
- Auth0 by Okta set up as an OIDC provider.
- AWS IAM access.

## Steps:

1. **Set Up Identity Provider in AWS**:
   - Open the **IAM** console in AWS.
   - Go to **Identity Providers** > **Add Provider**.
   - Choose **OpenID Connect** as the provider type.
   - Enter the Auth0 **Issuer URL**: `https://your-tenant-name.us.auth0.com/`.
   - Upload the OIDC metadata or configure manually.

2. **Create an IAM Role for OIDC**:
   - Navigate to **Roles** > **Create role**.
   - Select **Web identity** as the trusted entity.
   - Choose your newly created **Auth0 OIDC provider**.
   - Configure access policies to AWS services (e.g., S3, EC2).

3. **Trust Relationship Configuration**:
   - Update the trust relationship to allow Auth0 users to assume the role:
     ```json
     {
       "Effect": "Allow",
       "Principal": {
         "Federated": "arn:aws:iam::123456789012:oidc-provider/your-tenant-name.us.auth0.com"
       },
       "Action": "sts:AssumeRoleWithWebIdentity",
       "Condition": {
         "StringEquals": {
           "your-tenant-name.us.auth0.com:sub": "user_id"
         }
       }
     }
     ```

4. **Test Authentication**:
   - Use OIDC tokens generated by Auth0 to authenticate and assume the IAM role.
