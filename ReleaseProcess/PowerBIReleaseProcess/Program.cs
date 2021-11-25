namespace PowerBIReleaseProcess
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using Microsoft.Extensions.Configuration;
    using Microsoft.Extensions.Logging;
    using NLog.Extensions.Logging;
    using Vme.Logging;

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
        private static async Task<Int32> Main(String[] args)
        {
            try
            {
                Program.LoadConfiguration();

                if (args.Length != 3)
                {
                    //PrintErrorMessage("Invalid Args"); // TODO: Better message
                    return -1;
                }

                Logger.Initialise(new LoggerFactory().AddNLog().CreateLogger("Logger"));

                // Get the first argument (this is the release package location)
                String releasePackageLocation = args[0];

                // Get the second argument (this is the release package version)
                String releaseVersion = args[1];

                // Get the second argument (this is the customer)
                ReleaseProfile releaseProfile = Program.GetReleaseProfile(args[2]);

                DatabaseManager databaseManager = new DatabaseManager(releaseProfile.ConnectionString);

                await databaseManager.RunScripts();

                ITokenService tokenService = new TokenService();

                Func<String, IPowerBIService> powerBiServiceResolver = (token) =>
                {
                    String powerBiApiUrl = Program.Configuration.GetSection("AppSettings:PowerBiApiUrl").Value;
                    Int32 fileImportCheckRetryAttempts =
                        Int32.Parse(Program.Configuration.GetSection("AppSettings:FileImportCheckRetryAttempts")
                            .Value);
                    Int32 fileImportCheckSleepIntervalInSeconds =
                        Int32.Parse(Program.Configuration
                            .GetSection("AppSettings:FileImportCheckSleepIntervalInSeconds").Value);

                    return new PowerBIService(powerBiApiUrl,
                        token,
                        fileImportCheckRetryAttempts,
                        fileImportCheckSleepIntervalInSeconds);
                };
                Func<IGitHubService> gitHubServiceResolver = () =>
                {
                    String gitHubApiUrl = Program.Configuration.GetSection("AppSettings:GitHubApiUrl").Value;
                    String gitHubAccessToken = Program.Configuration.GetSection("AppSettings:GithubAccessToken").Value;

                    return new GitHubService(gitHubApiUrl, gitHubAccessToken);
                };
                IPowerBiReleaseProcess releaseProcess =
                    new PowerBiReleaseProcess(tokenService, powerBiServiceResolver, gitHubServiceResolver);

                await releaseProcess.DeployRelease(releasePackageLocation, releaseVersion, releaseProfile,
                    CancellationToken.None);

                return 0;
            }
            catch (Exception ex)
            {
                return -1;
            }
        }
        
        private static ReleaseProfile GetReleaseProfile(String organisationName)
        {
            ReleaseProfile? profile = Program.ReleaseProfiles.SingleOrDefault(p => String.Compare(p.Name.ToString() ,organisationName, true) == 0);

            return profile;
        }
        
        #endregion

    }
    
}