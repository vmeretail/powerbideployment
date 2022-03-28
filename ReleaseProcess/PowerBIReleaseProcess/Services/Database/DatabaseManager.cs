namespace PowerBIReleaseTool.Services.Database
{
    using System;
    using System.Data.SqlClient;
    using System.Diagnostics;
    using System.IO;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;
    using Vme.Logging;

    public class DatabaseManager : IDatabaseManager
    {
        public async Task ExecuteScript(String connectionString, String sqlFilePath,
                                                 CancellationToken cancellationToken)
        {
            String fileName = Path.GetFileName(sqlFilePath);

            try
            {
                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    using (SqlCommand command = new SqlCommand(File.ReadAllText(sqlFilePath, Encoding.Latin1), connection))
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

                throw;
            }
        }
    }
}