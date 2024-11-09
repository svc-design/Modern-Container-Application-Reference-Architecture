# Configure OIDC login for GitHub

This document outlines the steps to configure OpenID Connect (OIDC) login for GitHub using **Auth0 by Okta**.

## Prerequisites:
- Auth0 by Okta set up as an OIDC provider.
- GitHub repository access.

## Steps:

1. **Configure OIDC in GitHub Actions**:
   - Create or update the `.github/workflows/` directory in your GitHub repo.
   - Configure OIDC login by adding the following steps in your workflow file:
     ```yaml
     jobs:
       deploy:
         runs-on: ubuntu-latest
         steps:
           - name: Configure OIDC Login
             uses: actions/oidc-login-action@v1
             with:
               client-id: ${{ secrets.CLIENT_ID }}
               client-secret: ${{ secrets.CLIENT_SECRET }}
               issuer-url: https://your-tenant-name.us.auth0.com/
     ```

2. **Add GitHub Secrets**:
   - Go to your GitHub repo settings.
   - Add **CLIENT_ID** and **CLIENT_SECRET** from your Auth0 application.

3. **Test GitHub Action**:
   - Trigger the GitHub action to validate the OIDC login.
