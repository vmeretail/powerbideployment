namespace PowerBIReleaseProcess
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.IO.Compression;
    using System.Linq;
    using System.Net.NetworkInformation;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;
    using Microsoft.Extensions.Configuration;
    using Microsoft.Extensions.Primitives;
    using Microsoft.PowerBI.Api;
    using Microsoft.PowerBI.Api.Models;
    using Microsoft.Rest;
    using Octokit;
    using RestSharp;

    /// <summary>
    /// 
    /// </summary>
    internal class Program
    {
        #region Fields

        /// <summary>
        /// The configuration
        /// </summary>
        public static IConfigurationRoot Configuration;

        /// <summary>
        /// The release profiles
        /// </summary>
        private static List<ReleaseProfile> ReleaseProfiles;

        /// <summary>
        /// The token service
        /// </summary>
        private static ITokenService TokenService;

        #endregion

        #region Methods
        
        /// <summary>
        /// Loads the configuration.
        /// </summary>
        private static void LoadConfiguration()
        {
            IConfigurationBuilder builder = new ConfigurationBuilder().SetBasePath(Path.Combine(AppContext.BaseDirectory))
                                                                      .AddJsonFile("appsettings.json", optional:true)
                                                                      .AddJsonFile("appsettings.development.json", optional: true);

            Program.Configuration = builder.Build();

            Program.ReleaseProfiles = Program.Configuration.GetSection("ReleaseProfiles").Get<List<ReleaseProfile>>();
        }

        /// <summary>
        /// Defines the entry point of the application.
        /// </summary>
        /// <param name="args">The arguments.</param>
        private static async Task Main(String[] args)
        {
            Program.LoadConfiguration();

            if (args.Length != 3)
            {
                //PrintErrorMessage("Invalid Args"); // TODO: Better message
                return;
            }

            // Get the first argument (this is the release package location)
            String releasePackageLocation = args[0];

            // Get the second argument (this is the release package version)
            String releaseVersion = args[1];
            
            // Get the second argument (this is the customer)
            ReleaseProfile releaseProfile = Program.GetReleaseProfile(args[2]);

            ITokenService tokenService = new TokenService();

            //Func<String, IPowerBIService> powerBiServiceResolver = (token) =>
            //                                                       {
            //                                                           String powerBiApiUrl = Program.Configuration.GetSection("AppSettings:PowerBiApiUrl").Value;
            //                                                           Int32 fileImportCheckRetryAttempts =
            //                                                               Int32.Parse(Program.Configuration.GetSection("AppSettings:FileImportCheckRetryAttempts")
            //                                                                                  .Value);
            //                                                           Int32 fileImportCheckSleepIntervalInSeconds =
            //                                                               Int32.Parse(Program.Configuration
            //                                                                                  .GetSection("AppSettings:FileImportCheckSleepIntervalInSeconds").Value);

            //                                                           TokenCredentials tokenCredentials = new TokenCredentials(token, "Bearer");

            //                                                           IPowerBIClient powerBiClient = new PowerBIClient(tokenCredentials);
            //                                                           return new PowerBIService(powerBiApiUrl,
            //                                                                                     powerBiClient,
            //                                                                                     fileImportCheckRetryAttempts,
            //                                                                                     fileImportCheckSleepIntervalInSeconds);
            //
            // };
            String powerBiApiUrl = Program.Configuration.GetSection("AppSettings:PowerBiApiUrl").Value;
            PowerBIClient powerBiClient = new PowerBIClient(new Uri(powerBiApiUrl), null);
            IRestClient restClient = new RestClient(powerBiApiUrl);
            Int32 fileImportCheckRetryAttempts = Int32.Parse(Program.Configuration.GetSection("AppSettings:FileImportCheckRetryAttempts").Value);
            Int32 fileImportCheckSleepIntervalInSeconds = Int32.Parse(Program.Configuration.GetSection("AppSettings:FileImportCheckSleepIntervalInSeconds").Value);

            PowerBIServiceState powerBiServiceState = new PowerBIServiceState(fileImportCheckRetryAttempts, fileImportCheckSleepIntervalInSeconds, powerBiClient,
                                                                              restClient,)

            //Func<IGitHubService> gitHubServiceResolver = () =>
            //                                             {
            //                                                 String gitHubApiUrl = Program.Configuration.GetSection("AppSettings:GitHubApiUrl").Value;
            //                                                 String gitHubAccessToken = Program.Configuration.GetSection("AppSettings:GithubAccessToken").Value;

            //                                                 return new GitHubService(gitHubApiUrl, gitHubAccessToken);
            //                                             };
            //IPowerBiReleaseProcess releaseProcess = new PowerBiReleaseProcess(tokenService, powerBiServiceResolver, gitHubServiceResolver);

            //await releaseProcess.DeployRelease(releasePackageLocation, releaseVersion, releaseProfile, CancellationToken.None);
        }
        
        private static ReleaseProfile GetReleaseProfile(String organisationName)
        {
            ReleaseProfile? profile = Program.ReleaseProfiles.SingleOrDefault(p => String.Compare(p.Name.ToString() ,organisationName, true) == 0);

            return profile;
        }
        
        #endregion

    }
    
}