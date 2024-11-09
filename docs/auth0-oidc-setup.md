# Set up Auth0 by Okta as the identity provider for OIDC authentication

This document provides the steps to configure **Auth0 by Okta** as the identity provider (IdP) for OpenID Connect (OIDC) authentication.

## Steps:

1. **Create an Auth0 Account**:
   - Go to [Auth0](https://auth0.com/) and create an account if you don’t already have one.

2. **Create a New Application**:
   - Navigate to the **Applications** tab.
   - Click **Create Application**.
   - Select **Regular Web Application** or **Machine to Machine Applications** based on your need.

3. **Configure OIDC Settings**:
   - Record the **Client ID** and **Client Secret** for future reference.
   - Configure allowed callback URLs for the platforms you want to authenticate (AWS, GCP, etc.).

4. **Set Up Tenant Domain**:
   - The domain for your Auth0 instance will look like: `your-tenant-name.us.auth0.com`.

5. **OIDC Configuration**:
   - Use the `.well-known/openid-configuration` URL for your Auth0 tenant.
   - Example: `https://your-tenant-name.us.auth0.com/.well-known/openid-configuration`.

6. **Test OIDC Configuration**:
   - Before integrating with cloud services, ensure that the OIDC configuration works by testing with tools like **Postman**.
