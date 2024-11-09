# Configure OIDC login for Grafana Cloud

This document outlines the steps to configure OpenID Connect (OIDC) login for Grafana Cloud using **Auth0 by Okta**.

## Prerequisites:
- Auth0 by Okta set up as an OIDC provider.
- Grafana Cloud admin access.

## Steps:

1. **Set Up Grafana OIDC Integration**:
   - Open the **Grafana Cloud** dashboard.
   - Navigate to **Authentication** settings.
   - Select **OIDC** as the authentication type.

2. **Configure OIDC Settings**:
   - Enter the Auth0 **Issuer URL**: `https://your-tenant-name.us.auth0.com/`.
   - Provide the **Client ID** and **Client Secret** from Auth0.
   - Configure allowed callback URLs.

3. **Test OIDC Authentication**:
   - Log in using Auth0 credentials and validate the Grafana dashboard access.
