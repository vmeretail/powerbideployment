using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PowerBiReleaseProcess.DatabaseTests
{
        using System;
        using System.IO;
        using System.Linq;
        using System.Reflection;
        using System.Text;
        using System.Data.SqlClient;
        using System.Threading.Tasks;
        using System.Threading;
        using Vme.Logging;
        using System.Diagnostics;

        public class DatabaseManager
        {
            #region Fields

            private readonly String ConnectionString;

            private readonly String DataModelPath;

            private readonly String ExecutingAssemblyFolder = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);

            #endregion

            #region Constructors

            public DatabaseManager(String connectionString, String dataModelPath)
            {
                this.ConnectionString = connectionString;
                this.DataModelPath = dataModelPath;
            }

            #endregion

            #region Methods

            public async Task RunScripts()
            {
                await this.CreateDataModelViews();
                await this.CreateStoredProcedures();
            }

            /// <summary>
            /// Creates the views.
            /// </summary>
            public async Task CreateDataModelViews()
            {
                String[] directiories = Directory.GetDirectories(this.DataModelPath);
                directiories = directiories.Where(d => d.Contains("StoredProcedures") == false && d.Contains("Tools") == false).OrderBy(d => d).ToArray();

                foreach (String directory in directiories)
                {
                    String[] sqlFiles = Directory.GetFiles(directory, "*.sql");

                    foreach (String sqlFile in sqlFiles.OrderBy(x => x))
                    {
                        await this.ExecuteScript(sqlFile);
                    }
                }
            }

            public async Task CreateStoredProcedures()
            {
                String directory = $@"{this.DataModelPath}/StoredProcedures";

                String[] sqlFiles = Directory.GetFiles(directory, "*.sql");

                foreach (String sqlFile in sqlFiles.OrderBy(x => x))
                {
                    await this.ExecuteScript(sqlFile);
                }
            }

            private async Task ExecuteScript(String sqlFile)
            {
                String fileName = Path.GetFileName(sqlFile);

                try
                {
                    using (SqlConnection connection = new SqlConnection(this.ConnectionString))
                    {
                        await connection.OpenAsync();

                        using (SqlCommand command = new SqlCommand(File.ReadAllText(sqlFile, Encoding.Latin1), connection))
                        {
                            Logger.WriteToLog($"Running File {fileName}", LoggerCategory.General, TraceEventType.Information);

                            await command.ExecuteNonQueryAsync(CancellationToken.None);

                            Logger.WriteToLog($"File {fileName} executed successfully", LoggerCategory.General, TraceEventType.Information);
                        }
                    }
                }
                catch (Exception ex)
                {
                    Logger.WriteToLog($"Error running File {fileName}{Environment.NewLine}{ex}", LoggerCategory.General, TraceEventType.Error);

                    throw new Exception($"Error running File {fileName}{Environment.NewLine}{ex}");
                }
            }

            #endregion
        }
}
