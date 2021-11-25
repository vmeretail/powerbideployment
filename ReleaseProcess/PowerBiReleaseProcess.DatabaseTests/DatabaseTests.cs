namespace PowerBiReleaseProcess.DatabaseTests
{
    using System;
    using System.Collections.Generic;
    using System.Data;
    using System.Data.SqlClient;
    using System.IO;
    using System.Linq;
    using System.Net.Http;
    using System.Reflection;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;
    using Microsoft.Extensions.Configuration;
    using Newtonsoft.Json;
    using PowerBIReleaseProcess;
    using Shouldly;
    using Vme.Logging;
    using Xunit;
    using Xunit.Abstractions;
    using NullLogger = Vme.Logging.NullLogger;

    public class DatabaseTests : IDisposable
    {
        #region Fields

        private readonly ITestOutputHelper Output;
        
        #endregion

        #region Constructors

        public DatabaseTests(ITestOutputHelper output)
        {
            this.Output = output;

            IConfigurationBuilder builder = new ConfigurationBuilder().AddJsonFile("/home/forge/eposity/config/integrationShared.json", true, true)
                                                                      .AddJsonFile("/home/forge/eposity/config/integrationShared.development.json", true, true);

            ConfigurationReader.Initialise(builder.Build());

            var dockerRegistryUrl = ConfigurationReader.GetValue("DockerRegistryUrl");

            Console.WriteLine($"DockerRegistryUrl is {dockerRegistryUrl}");
        }

        #endregion

        #region Methods

        public void Dispose()
        {
            try
            {
                if (DockerHelper.SqlServerContainer != null)
                {
                    DockerHelper.SqlServerContainer.ClearUpContainer();
                }

                if (DockerHelper.QueryModelWriterContainer != null)
                {
                    DockerHelper.QueryModelWriterContainer.ClearUpContainer();
                }
            }
            catch(Exception e)
            {
                Console.WriteLine(e);
            }
        }

        

        [Fact]
        public async Task QueryModel_CanBeCreated_IsCreated()
        {
            Logger.Initialise(new NullLogger());

            // 1. Arrange
            await DockerHelper.StartContainersForTestRun();

            var organisationCreatedEvent = new
                                           {
                                               organisationId = "066e0734-4ea2-480a-ac82-a5adb9e160fe",
                                               dateRegistered = "2021-05-26T09:27:49.7744089+00:00",
                                               organisationName = "Bath Uni"
                                           };

            HttpClient client = new HttpClient();
            HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Post,
                                                                $"http://localhost:{DockerHelper.QueryModelWriterHostPort}/api/events?eventType=OrganisationCreatedEvent");
            request.Content = new StringContent(JsonConvert.SerializeObject(organisationCreatedEvent), Encoding.UTF8, "application/json");

            var response = await client.SendAsync(request, CancellationToken.None);

            if (response.IsSuccessStatusCode == false)
            {
                throw new Exception("Error prosing Organsation Created Event to query rest");
            }

            ShouldlyConfiguration.DefaultTaskTimeout = TimeSpan.FromMinutes(5);
            
            // ensure all sql files are set to be copied to the bin folder.
            this.VerifyCopyToBin().ShouldBeTrue();

            var connectionString = DockerHelper.GetSqlServerConnectionString(false, $"OrganisationRead{organisationCreatedEvent.organisationId}");

            DatabaseManager manager = new DatabaseManager(connectionString);
            await manager.RunScripts();
            
            await this.RunStoredProcedures(connectionString, CancellationToken.None);
        }

        public Boolean VerifyCopyToBin()
        {
            String executingAssemblyLocation = Assembly.GetExecutingAssembly().Location;
            String executingAssemblyFolder = Path.GetDirectoryName(executingAssemblyLocation);
            String binDirectoryPath = $@"{executingAssemblyFolder}/Data Model";

            String solutionDirectoryPath = @"../../../../PowerBIReleaseProcess/Data Model";

            // Get directories
            DirectoryInfo binDirectoryInfo = new DirectoryInfo(binDirectoryPath);
            DirectoryInfo solutionDirectoryInfo = new DirectoryInfo(solutionDirectoryPath);

            // Get all sql files from directories (recursively)
            List<FileInfo> binDirectoryFiles = binDirectoryInfo.GetFiles("*.sql", SearchOption.AllDirectories).ToList();
            List<FileInfo> solutionDirectoryFiles = solutionDirectoryInfo.GetFiles("*.sql", SearchOption.AllDirectories).ToList();

            // Find all files that are in solution but not in bin folder.
            List<FileInfo> queryList1Only = solutionDirectoryFiles.Where(x => binDirectoryFiles.All(y => y.Name != x.Name)).ToList();

            if (queryList1Only.Any())
            {
                StringBuilder stringBuilder = new StringBuilder($"There are [{queryList1Only.Count}] files in the solution but not in the bin folder. The files are: ");

                stringBuilder.AppendLine(string.Empty);
                queryList1Only.ForEach(x => stringBuilder.AppendLine(x.FullName));

                throw new Exception(stringBuilder.ToString());
            }

            return true;
        }
        
        private async Task RunStoredProcedures(String connectionString, CancellationToken cancellationToken)
        {
            List<(String spName, String paramters)> storedProcs = new List<(String spName, String paramters)>();
            using(SqlConnection connection = new SqlConnection(connectionString))
            {
                await connection.OpenAsync(cancellationToken);

                var command = connection.CreateCommand();
                command.CommandText = DatabaseTests.GetStoredProcedureParameters;
                command.CommandType = CommandType.Text;

                var dataReader = await command.ExecuteReaderAsync(cancellationToken);

                if (dataReader.HasRows)
                {
                    while (await dataReader.ReadAsync(cancellationToken))
                    {
                        storedProcs.Add((dataReader.GetString(0), dataReader.GetString(1)));
                    }
                }

                await dataReader.CloseAsync();

                foreach ((String spName, String paramters) storedProc in storedProcs)
                {
                    var spCommand = connection.CreateCommand();
                    spCommand.CommandType = CommandType.StoredProcedure;
                    spCommand.CommandText = storedProc.spName;

                    var parameters = storedProc.paramters.Split(",");
                    foreach (String parameter in parameters)
                    {
                        var param = parameter.Trim().Split(" ");

                        if (param[1] == "uniqueidentifier")
                        {
                            spCommand.Parameters.AddWithValue(param[0].Trim(), Guid.NewGuid());
                        }
                        else if (param[1] == "datetime")
                        {
                            spCommand.Parameters.AddWithValue(param[0].Trim(), DateTime.Now);
                        }
                    }

                    await spCommand.ExecuteNonQueryAsync(cancellationToken);
                }
            }
        }

        #endregion

        #region Others

        private const String GetStoredProcedureParameters = "select " + "obj.name as procedure_name, " +
                                                            "substring(par.parameters, 0, len(par.parameters)) as parameters " + "from sys.objects obj " +
                                                            "cross apply(select p.name + ' ' + TYPE_NAME(p.user_type_id) + ', '  " + "from sys.parameters p " +
                                                            "where p.object_id = obj.object_id " + " and p.parameter_id != 0 " + " for xml path ('') ) par(parameters) " +
                                                            "where obj.type = 'P'";

        #endregion
    }
}