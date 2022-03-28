namespace PowerBiReleaseProcess.DatabaseTests
{
    using System;
    using System.Collections.Generic;
    using System.Data.SqlClient;
    using System.Diagnostics;
    using System.IO;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using Ductus.FluentDocker.Builders;
    using Ductus.FluentDocker.Common;
    using Ductus.FluentDocker.Extensions;
    using Ductus.FluentDocker.Model.Builders;
    using Ductus.FluentDocker.Model.Containers;
    using Ductus.FluentDocker.Services;
    using Ductus.FluentDocker.Services.Extensions;
    using Xunit;

    /// <summary>
    /// 
    /// </summary>
    public static class DockerHelper
    {
        #region Fields

        /// <summary>
        /// The SQL server container
        /// </summary>
        public static IContainerService SqlServerContainer;

        public static IContainerService QueryModelWriterContainer;

        /// <summary>
        /// The shared network name
        /// </summary>
        private static readonly String SharedNetworkName = "shared-network-sqlserver";

        /// <summary>
        /// The SQL server container name
        /// </summary>
        private static readonly String SqlServerContainerName = "querymodel-test-sqlserver";

        /// <summary>
        /// The SQL server host port
        /// </summary>
        private static Int32 SqlServerHostPort;

        /// <summary>
        /// The SQL server password
        /// </summary>
        private static readonly String SqlServerPassword = "thisisalongpassword123!";

        #endregion

        #region Properties



        #endregion

        #region Methods

        /// <summary>
        /// Gets the SQL server connection string.
        /// </summary>
        /// <param name="isDocker">if set to <c>true</c> [is docker].</param>
        /// <param name="databaseName">Name of the database.</param>
        /// <returns></returns>
        public static String GetSqlServerConnectionString(Boolean isDocker,
                                                          String databaseName)
        {
            String ipAddress = isDocker ? $"{DockerHelper.SqlServerContainerName},1433" : $"127.0.0.1,{DockerHelper.SqlServerHostPort}";
            return $"server={ipAddress};user id=sa;password={DockerHelper.SqlServerPassword};database={databaseName}";
        }

        private static async Task StartSQLServer(INetworkService sharedNetworkService)
        {
            // Startup SQL Server
            DockerHelper.SqlServerContainer = new Builder().UseContainer().UseImage("mcr.microsoft.com/mssql/server:2019-latest")
                                                           .WithName(DockerHelper.SqlServerContainerName).UseNetwork(sharedNetworkService).KeepContainer().KeepRunning()
                                                           .ReuseIfExists()
                                                           .WithEnvironment("ACCEPT_EULA=Y", $"SA_PASSWORD={DockerHelper.SqlServerPassword}", "MSSQL_PID=Express")
                                                           .ExposePort(1433).WaitForPort("1433/tcp", 30000).Build().Start();

            DockerHelper.SqlServerHostPort = DockerHelper.SqlServerContainer.ToHostExposedEndpoint("1433/tcp").Port;

            Container config = DockerHelper.SqlServerContainer.GetConfiguration(true);
            Assert.Equal(ServiceRunningState.Running, config.State.ToServiceState());

            String connectionString = DockerHelper.GetSqlServerConnectionString(false, "master");

            Boolean dbCheckResult = false;
            Stopwatch stopwatch = Stopwatch.StartNew();

            while (stopwatch.ElapsedMilliseconds < TimeSpan.FromSeconds(60).TotalMilliseconds)
            {
                dbCheckResult = await DockerHelper.CheckForDatabase(connectionString, CancellationToken.None).ConfigureAwait(false);

                if (dbCheckResult)
                {
                    break;
                }

                Thread.Sleep(5000);
            }

            if (!dbCheckResult)
            {
                throw new FluentDockerException("Failed to initialise SQL Server container.");
            }
        }

        /// <summary>
        /// Starts the containers for test run.
        /// </summary>
        public static async Task StartContainersForTestRun()
        {
            //DockerHelper.AwsEcrToken = await DockerHelper.GetAwsEcrToken();
            var sharedNetworkService = new Builder().UseNetwork(DockerHelper.SharedNetworkName).ReuseIfExist().Build();

            String dockerRegistryUrl = ConfigurationReader.GetValue("DockerRegistryUrl");

            await DockerHelper.StartSQLServer(sharedNetworkService);
            await DockerHelper.StartQueryModelWriter(sharedNetworkService, dockerRegistryUrl);
        }
        private static readonly Int32 QueryModelWriterDockerPort = 5023;

        public static Int32 QueryModelWriterHostPort;

        private static async Task StartQueryModelWriter(INetworkService sharedNetworkService, String dockerRegistryUrl)
        {
            String mountDate = DateTime.Now.ToString("yyyy-MM-dd");
            var logFileMountDirectory = FdOs.IsWindows()
                ? $"C:\\home\\forge\\eposity\\trace\\{mountDate}\\DatabaseTest"
                : $"/home/forge/eposity/trace/{mountDate}/DatabaseTest";

            // manually create the folder so permissions are okay
            Directory.CreateDirectory(logFileMountDirectory);

            String connString = $"ConnectionStrings:OrganisationReadModel=\"server={DockerHelper.SqlServerContainerName},1433;user id=sa;password={DockerHelper.SqlServerPassword};Database=OrganisationRead\"";

            // these should always be Eposity as it's the folder on the actual containers
            String containerTraceDir = "/home/forge/eposity/trace/";
            DockerHelper.QueryModelWriterContainer = new Builder().UseContainer()
                                                                  //.UseImage($"{dockerRegistryUrl}/vmeeposityquerymodelwriter:latest", true)
                                                                  .UseImage($"{dockerRegistryUrl}/vmeeposityquerymodelwriter:feature", true)
                                                                  //.UseImage($"vmeeposityquerymodelwriter:latest")
                                                                  .ExposePort(5023)
                                                                  .UseNetwork(sharedNetworkService)
                                                                  .WithName($"querymodel")
                                                                  .WithEnvironment("AppSettings:UseConnectionStringConfig=false",
                                                                                   "AppSettings:InternalSubscriptionService=false",
                                                                                   connString,
                                                                                   "urls=http://0.0.0.0:5023").WaitForPort($"{DockerHelper.QueryModelWriterDockerPort}/tcp", 30000 /*30s*/)
                                                                  .Mount(logFileMountDirectory, containerTraceDir, MountType.ReadWrite)
                                                                  .Build().Start();

            DockerHelper.QueryModelWriterHostPort = DockerHelper.QueryModelWriterContainer.ToHostExposedEndpoint($"{DockerHelper.QueryModelWriterDockerPort}/tcp").Port;
        }

        private static async Task<Boolean> CheckForDatabase(String connectionString,
                                                            CancellationToken cancellationToken)
        {
            using(SqlConnection connection = new SqlConnection(connectionString))
            {
                try
                {
                    connection.Open();

                    SqlCommand command = connection.CreateCommand();
                    command.CommandText = "SELECT * FROM sys.databases";
                    command.ExecuteNonQuery();

                    connection.Close();
                    return true;
                }
                catch(Exception e)
                {
                    return false;
                }
            }
        }
        
        #endregion
    }

    public static class DockerExtensions
    {
        #region Methods

        /// <summary>
        /// ClearUpContainer the container.
        /// </summary>
        /// <param name="containerService">The container service.</param>
        public static void ClearUpContainer(this IContainerService containerService)
        {
            try
            {
                IList<IVolumeService> volumes = new List<IVolumeService>();
                IList<INetworkService> networks = containerService.GetNetworks();

                foreach (INetworkService networkService in networks)
                {
                    networkService.Detatch(containerService, true);
                }

                // Doing a direct call to .GetVolumes throws an exception if there aren't any so we need to check first :|
                Container container = containerService.GetConfiguration(true);
                ContainerConfig containerConfig = container.Config;

                if (containerConfig != null)
                {
                    IDictionary<String, VolumeMount> configurationVolumes = containerConfig.Volumes;
                    if (configurationVolumes != null && configurationVolumes.Any())
                    {
                        volumes = containerService.GetVolumes();
                    }
                }

                containerService.StopOnDispose = true;
                containerService.RemoveOnDispose = true;
                containerService.Dispose();

                foreach (IVolumeService volumeService in volumes)
                {
                    volumeService.Stop();
                    volumeService.Remove(true);
                    volumeService.Dispose();
                }
            }
            catch(Exception e)
            {
                Console.WriteLine($"Failed to stop container {containerService.InstanceId}. [{e}]");
            }
        }

        #endregion
    }
}