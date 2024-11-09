# Configure OIDC login for Azure

This document outlines the steps to configure OpenID Connect (OIDC) login for Microsoft Azure using **Auth0 by Okta**.

## Prerequisites:
- Auth0 by Okta set up as an OIDC provider.
- Azure Active Directory (AAD) access.

## Steps:

1. **Set Up a New Enterprise Application**:
   - Open **Azure Portal**.
   - Go to **Azure Active Directory** > **Enterprise Applications** > **New Application**.
   - Select **Non-gallery application** and configure the app.

2. **Configure OIDC Single Sign-On**:
   - Go to the **Single Sign-On** tab.
   - Select **OpenID Connect**.
   - Enter the Auth0 **Client ID**, **Client Secret**, and **Issuer URL** (`https://your-tenant-name.us.auth0.com/`).

3. **Configure Permissions and Roles**:
   - In **Azure AD**, assign users or groups to the newly created enterprise application.
   - Configure role assignments based on access needs (e.g., Reader, Contributor roles).

4. **Test Authentication**:
   - Use Auth0 credentials to authenticate through Azure.
