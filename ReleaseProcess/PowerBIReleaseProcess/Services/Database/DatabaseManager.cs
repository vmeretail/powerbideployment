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

            String content = File.ReadAllText(fileName, Encoding.Latin1);
            String[] commands = null;
            if (content.Contains("GO", StringComparison.CurrentCulture))
            {
                commands = content.Split("GO;");
            }
            else
            {
                commands = new String[1];
                commands[0] = content;
            }

            try
            {
                Logger.WriteToLog($"Running File {fileName}", LoggerCategory.General, TraceEventType.Information);

                using (SqlConnection connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    foreach (String commandText in commands)
                    {

                        using (SqlCommand command = new SqlCommand(commandText, connection))
                        {

                            await command.ExecuteNonQueryAsync(CancellationToken.None);
                        }
                    }
                }

                Logger.WriteToLog($"File {fileName} executed successfully", LoggerCategory.General, TraceEventType.Information);
            }
            catch (Exception ex)
            {
                Logger.WriteToLog($"Error running File {fileName}{Environment.NewLine}{ex}", LoggerCategory.General, TraceEventType.Error);

                throw;
            }
        }
    }
}