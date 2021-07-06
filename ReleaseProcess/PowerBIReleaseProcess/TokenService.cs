namespace PowerBIReleaseProcess
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Security;
    using Microsoft.Identity.Client;

    /// <summary>
    /// 
    /// </summary>
    /// <seealso cref="PowerBIReleaseProcess.ITokenService" />
    public class TokenService : ITokenService
    {
        #region Methods

        public String GetMasterUserAccessToken(String pbiUsername, String pbiPassword)
        {
            AuthenticationResult authenticationResult = null;

            String authorityUri = Program.Configuration.GetSection("AppSettings:AuthorityUri").Value;
            String clientId = Program.Configuration.GetSection("AppSettings:ClientId").Value;
            String[] scopes = Program.Configuration.GetSection("AppSettings:Scopes").Value.Split(",");
            // Create a public client to authorize the app with the AAD app

            IPublicClientApplication clientApp = PublicClientApplicationBuilder.Create(clientId).WithAuthority(authorityUri).Build();
            IEnumerable<IAccount> userAccounts = clientApp.GetAccountsAsync().Result;
            try
            {
                // Retrieve Access token from cache if available
                authenticationResult = clientApp.AcquireTokenSilent(scopes, userAccounts.FirstOrDefault()).ExecuteAsync().Result;
            }
            catch (MsalUiRequiredException)
            {
                SecureString password = new SecureString();
                foreach (var key in pbiPassword)
                {
                    password.AppendChar(key);
                }

                authenticationResult = clientApp.AcquireTokenByUsernamePassword(scopes, pbiUsername, password).ExecuteAsync().Result;
            }

            return authenticationResult.AccessToken;
        }


        /// <summary>
        /// Generates and returns Access token
        /// </summary>
        /// <param name="tokenType">Type of the token.</param>
        /// <returns>
        /// AAD token
        /// </returns>
        public String GetServicePrincipalAccessToken()
        {
            String authorityUri = Program.Configuration.GetSection("AppSettings:AuthorityUri").Value;
            String clientId = Program.Configuration.GetSection("AppSettings:ClientId").Value;
            String[] scopes = Program.Configuration.GetSection("AppSettings:Scopes").Value.Split(",");

            AuthenticationResult authenticationResult = null;
            
            // Service Principal auth is the recommended by Microsoft to achieve App Owns Data Power BI embedding

            String tenantId = Program.Configuration.GetSection("AppSettings:TenantId").Value;
            String clientSecret = Program.Configuration.GetSection("AppSettings:ClientSecret").Value;
            // For app only authentication, we need the specific tenant id in the authority url
            String tenantSpecificUrl = authorityUri.Replace("organizations", tenantId);

            // Create a confidential client to authorize the app with the AAD app
            IConfidentialClientApplication clientApp = ConfidentialClientApplicationBuilder.Create(clientId).WithClientSecret(clientSecret)
                                                                                           .WithAuthority(tenantSpecificUrl).Build();
            // Make a client call if Access token is not available in cache
            authenticationResult = clientApp.AcquireTokenForClient(scopes).ExecuteAsync().Result;

            return authenticationResult.AccessToken;
        }

        #endregion
    }
}