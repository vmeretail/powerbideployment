namespace PowerBIReleaseProcess
{
    using System;

    /// <summary>
    /// 
    /// </summary>
    public interface ITokenService
    {
        #region Methods

        /// <summary>
        /// Gets the access token.
        /// </summary>
        /// <param name="pbiUsername">The pbi username.</param>
        /// <param name="pbiPassword">The pbi password.</param>
        /// <returns></returns>
        String GetMasterUserAccessToken(String pbiUsername,
                                        String pbiPassword);

        /// <summary>
        /// Gets the service principal access token.
        /// </summary>
        /// <returns></returns>
        String GetServicePrincipalAccessToken();

        #endregion
    }
}