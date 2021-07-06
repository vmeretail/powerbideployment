using System;
using System.Threading.Tasks;

namespace PowerBIReleaseProcess
{
    using System.Runtime.CompilerServices;
    using System.Threading;

    /// <summary>
    /// 
    /// </summary>
    public interface IPowerBiReleaseProcess
    {
        /// <summary>
        /// Deploys the release.
        /// </summary>
        /// <param name="releaseFolder">The release folder.</param>
        /// <param name="versionNumber">The version number.</param>
        /// <param name="releaseProfile">The release profile.</param>
        /// <param name="cancellationToken">The cancellation token.</param>
        /// <returns></returns>
        Task DeployRelease(String releaseFolder,
                           String versionNumber,
                           ReleaseProfile releaseProfile,
                           CancellationToken cancellationToken);
    }
}
