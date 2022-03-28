namespace PowerBIReleaseTool.Services.Database
{
    using System;
    using System.IO;
    using System.IO.Abstractions;
    using System.IO.Compression;
    using System.Threading;
    using System.Threading.Tasks;
    using PowerBi;

    //public class ReleaseProcess : IReleaseProcess
    //{
    //    private readonly IDatabaseManager DatabaseManager;

    //    private readonly IPowerBiService PowerBiService;

    //    private readonly IGitHubService GitHubService;

    //    private readonly IFileSystem FileSystem;

    //    private readonly ITokenService TokenService;

    //    public event EventHandler<String> TraceMessage;
    //    public event EventHandler<String> ErrorMessage;
    //    public event EventHandler<String> SuccessMessage;

    //    public ReleaseProcess(IDatabaseManager databaseManager, IPowerBiService powerBiService, IGitHubService gitHubService, IFileSystem fileSystem)
    //    {
    //        this.DatabaseManager = databaseManager;
    //        this.PowerBiService = powerBiService;
    //        this.GitHubService = gitHubService;
    //        this.FileSystem = fileSystem;
    //    }

    //    public async Task StartRelease(PowerBiCustomerConfiguration customerConfiguration,String applicationVersion, CancellationToken cancellationToken)
    //    {
            
    //        try
    //        {
    //            await this.GetReleaseAssets(applicationVersion, outputPath, cancellationToken);

    //            // Assets have now been downloaded
    //            // Create a working folder for the customer
    //            String customerDirectory = this.CreateCustomerDirectory(customerConfiguration.Name, outputPath);
            
    //            // First we need to release any SQL scripts
    //            var dbupdateStatus = await this.ReleaseDatabaseScripts(customerConfiguration.ConnectionString, customerDirectory, cancellationToken);
    //            if (dbupdateStatus == false)
    //                throw new Exception();

    //            // Get the power bi tokens
    //            if (await this.InitialisePowerBIService(cancellationToken))
    //            {
    //                // Now the datasets 
    //                var datasetReleaseStatus = await this.ReleaseDatasets(customerConfiguration, customerDirectory, cancellationToken);
    //                if (datasetReleaseStatus == false)
    //                    throw new Exception();
                    
    //                // Now the reports 
    //                await this.ReleaseReports(customerConfiguration, customerDirectory, cancellationToken);

    //                await this.PowerBiService.UpdateApplicationVersion(customerConfiguration, applicationVersion, cancellationToken);
    //            }

    //            this.SuccessMessage(this, $"Release of version {applicationVersion} to customer {customerConfiguration.Name} completed successfully!!");
    //        }
    //        catch
    //        {
    //            this.ErrorMessage(this, $"Release of version {applicationVersion} to customer {customerConfiguration.Name} failed!!");
    //        }
    //    }

    //    private async Task<Boolean> InitialisePowerBIService(CancellationToken cancellationToken)
    //    {
    //        try
    //        {
    //            this.TraceMessage(this, $"About to initialise Power BI service");
    //            await this.PowerBiService.Initialise();
    //            this.SuccessMessage(this, $"Power BI service initialised successfully!!");
    //            return true;
    //        }
    //        catch (Exception e)
    //        {
    //            this.ErrorMessage(this, $"Error initialising Power BI service!! Error Message [{e.Message}]");
    //            return false;
    //        }
    //    }

    //    private async Task<(Boolean status, String message)> ReleaseDatasets(PowerBiCustomerConfiguration customerConfiguration,
    //                                                                         String customerDirectory,
    //                                                                         CancellationToken cancellationToken)
    //    {
    //        String[]? datasetFiles = this.FileSystem.Directory.GetFiles($"{customerDirectory}\\Datasets", "*.pbix", SearchOption.AllDirectories);

    //        if (datasetFiles.Length == 0)
    //        {
    //            this.TraceMessage(this, "No datasets to be released");
    //            return (true, ;
    //        }
    //        else
    //        {

    //            this.TraceMessage(this, $"About to deploy {datasetFiles.Length} datasets to customers workspace");
    //            foreach (String datasetFile in datasetFiles)
    //            {
    //                try
    //                {
    //                    this.TraceMessage(this, $"About to deploy {datasetFile}");
    //                    (Boolean status, String message) result = await this.PowerBiService.DeployDataset(customerConfiguration, datasetFile, cancellationToken);
    //                    if (result.status == false)
    //                    {
    //                        this.ErrorMessage(this, result.message);
    //                        break;
    //                    }

    //                    this.SuccessMessage(this, result.message);
    //                }
    //                catch(Exception e)
    //                {
    //                    this.ErrorMessage(this, $"Error deploying dataset {datasetFile}!! Error Message [{e.Message}]");
    //                    return false;
    //                }
    //            }
    //        }
    //        return true;
    //    }

    //    private async Task<Boolean> ReleaseReports(PowerBiCustomerConfiguration customerConfiguration, 
    //                                               String customerDirectory,
    //                                               CancellationToken cancellationToken)
    //    {
    //        String[]? reportFiles = this.FileSystem.Directory.GetFiles($"{customerDirectory}\\Reports", "*.pbix", SearchOption.AllDirectories);

    //        if (reportFiles.Length == 0)
    //        {
    //            this.TraceMessage(this, "No reports to be released");
    //        }
    //        else
    //        {
    //            this.TraceMessage(this, $"About to deploy {reportFiles.Length} reports to customers workspace");
    //            foreach (String reportFile in reportFiles)
    //            {
    //                this.TraceMessage(this, $"About to deploy {reportFile}");
    //                (Boolean status, String message) result = await this.PowerBiService.DeployReport(customerConfiguration, reportFile, cancellationToken);
    //                if (result.status == false)
    //                {
    //                    this.ErrorMessage(this, result.message);
    //                    break;
    //                }

    //                this.SuccessMessage(this, result.message);
    //            }
    //        }

    //        return true;
    //    }

    //    private String CreateCustomerDirectory(String customer,
    //                                           String outputPath)
    //    {
    //        String customerDirectory = $"{outputPath}\\{customer}";
    //        this.FileSystem.Directory.CreateDirectory(customerDirectory);

    //        this.CopyFilesRecursively($"{outputPath}\\extract", customerDirectory);
    //        this.TraceMessage(this, $"Copied extracted files to customer  working directory [{customerDirectory}]");
    //        return customerDirectory;
    //    }

    //    private async Task<Boolean> ReleaseDatabaseScripts(String connectionString,
    //                                                       String customerDirectory,
    //                                                       CancellationToken cancellationToken)
    //    {
    //        String[]? databaseScripts = this.FileSystem.Directory.GetFiles($"{customerDirectory}\\DataModel", "*.sql", SearchOption.AllDirectories);

    //        if (databaseScripts.Length == 0)
    //        {
    //            this.TraceMessage(this, "No database scripts to be released");
    //            return true;
    //        }

    //        this.TraceMessage(this, $"About to deploy {databaseScripts.Length} scripts to customers read model");
    //        this.TraceMessage(this, $"Connection String: {connectionString}");
    //        foreach (String databaseScript in databaseScripts)
    //        {
    //            this.TraceMessage(this, $"About to deploy {databaseScript}");
    //            var result = await this.DatabaseManager.ExecuteScript(connectionString, databaseScript, cancellationToken);
    //            if (result.status == false)
    //            {
    //                this.ErrorMessage(this, $"Error deploying script {databaseScript}!! Error Message [{result.message}]");
    //                return false;
    //            }

    //            this.SuccessMessage(this, $"{databaseScript} deployed successfully!!");
    //        }

    //        return true;
    //    }

    //    private async Task GetReleaseAssets(String applicationVersion,
    //                                        String outputPath,
    //                                        CancellationToken cancellationToken)
    //    {
    //        this.FileSystem.Directory.CreateDirectory(outputPath);
    //        this.TraceMessage(this, $"Working directory is [{outputPath}]");
    //        this.TraceMessage(this, $"Get release {applicationVersion} from GitHub");

    //        GitHubReleaseDTO release = await this.GitHubService.GetRelease(applicationVersion, cancellationToken);
    //        this.TraceMessage(this, $"Release {applicationVersion} successfully retrieved from GitHub");

    //        foreach (GithubReleaseAsset githubReleaseAsset in release.Assets)
    //        {
    //            String assetPath = await this.GitHubService.GetReleaseAsset(githubReleaseAsset.Id, githubReleaseAsset.Name, outputPath, cancellationToken);

    //            ZipFile.ExtractToDirectory(assetPath, $"{outputPath}\\extract", overwriteFiles:true);
    //        }

    //        this.TraceMessage(this, $"Assets for release {applicationVersion} successfully retrieved from GitHub");
    //    }

    //    private Boolean CopyFilesRecursively(String sourcePath,
    //                                         String targetPath)
    //    {
    //        //Now Create all of the directories
    //        foreach (String dirPath in this.FileSystem.Directory.GetDirectories(sourcePath, "*", SearchOption.AllDirectories))
    //        {
    //            this.FileSystem.Directory.CreateDirectory(dirPath.Replace(sourcePath, targetPath));
    //        }

    //        //Copy all the files & Replaces any files with the same name
    //        foreach (String newPath in this.FileSystem.Directory.GetFiles(sourcePath, "*.*", SearchOption.AllDirectories))
    //        {
    //            String destFileName = newPath.Replace(sourcePath, targetPath);
    //            File.Copy(newPath, destFileName, true);
    //        }

    //        return true;
    //    }
    //}
}