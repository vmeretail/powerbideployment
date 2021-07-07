namespace PowerBIReleaseProcess
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;
    using Microsoft.PowerBI.Api.Models;
    using NLog;

    /// <summary>
    /// 
    /// </summary>
    /// <seealso cref="PowerBIReleaseProcess.IPowerBiReleaseProcess" />
    public class PowerBiReleaseProcess : IPowerBiReleaseProcess
    {
        #region Fields

        /// <summary>
        /// The git hub service resolver
        /// </summary>
        private readonly Func<IGitHubService> GitHubServiceResolver;

        /// <summary>
        /// The logger
        /// </summary>
        private readonly Logger Logger;

        /// <summary>
        /// The power bi service resolver
        /// </summary>
        private readonly Func<String, IPowerBIService> PowerBiServiceResolver;

        /// <summary>
        /// The token service
        /// </summary>
        private readonly ITokenService TokenService;

        #endregion

        #region Constructors

        /// <summary>
        /// Initializes a new instance of the <see cref="PowerBiReleaseProcess"/> class.
        /// </summary>
        /// <param name="tokenService">The token service.</param>
        /// <param name="powerBiServiceResolver">The power bi service resolver.</param>
        /// <param name="gitHubServiceResolver">The git hub service resolver.</param>
        public PowerBiReleaseProcess(ITokenService tokenService,
                                     Func<String, IPowerBIService> powerBiServiceResolver,
                                     Func<IGitHubService> gitHubServiceResolver)
        {
            this.TokenService = tokenService;
            this.PowerBiServiceResolver = powerBiServiceResolver;
            this.GitHubServiceResolver = gitHubServiceResolver;
            this.Logger = LogManager.GetCurrentClassLogger();
        }

        #endregion

        #region Methods

        /// <summary>
        /// Deploys the release.
        /// </summary>
        /// <param name="releaseFolder">The release folder.</param>
        /// <param name="versionNumber">The version number.</param>
        /// <param name="releaseProfile">The release profile.</param>
        /// <param name="cancellationToken">The cancellation token.</param>
        /// <exception cref="Exception">
        /// Datasets update failed
        /// or
        /// Report uploads failed
        /// </exception>
        public async Task DeployRelease(String releaseFolder,
                                        String versionNumber,
                                        ReleaseProfile releaseProfile,
                                        CancellationToken cancellationToken)
        {
            this.Logger.Info($"Organisation {releaseProfile.Name} Release Started");

            // Cache the working release folder
            releaseProfile.ReleaseFolder = $"{Directory.GetCurrentDirectory()}\\{releaseProfile.OrganisationId}";
            
            // Copy the files to the customer release folder
            this.CopyFilesRecursively(releaseFolder, releaseProfile.ReleaseFolder);

            try
            {
                Boolean dataSetsResult = await this.UpdateDatasets(releaseProfile, cancellationToken);
                if (dataSetsResult == false)
                {
                    throw new Exception("Datasets update failed");
                }

                Boolean reportsResult = await this.UpdateReports(releaseProfile, cancellationToken);
                if (reportsResult == false)
                {
                    throw new Exception("Report uploads failed");
                }

                // Update github release notes
                await this.UpdateGitHubReleaseNote(releaseProfile.Name, versionNumber, cancellationToken);

                this.Logger.Info($"Organisation {releaseProfile.Name} Release Completed");
            }
            catch(Exception e)
            {
                // TODO: Log Error
                this.Logger.Error(e);
                this.Logger.Error($"Organisation {releaseProfile.Name} Release Not Completed");
            }
            finally
            {
                // Clean up the release folder
                Directory.Delete(releaseProfile.ReleaseFolder, true);
            }
        }

        /// <summary>
        /// Copies the files recursively.
        /// </summary>
        /// <param name="sourcePath">The source path.</param>
        /// <param name="targetPath">The target path.</param>
        /// <returns></returns>
        private Boolean CopyFilesRecursively(String sourcePath,
                                             String targetPath)
        {
            this.Logger.Trace($"Source Path [{sourcePath}");
            this.Logger.Trace($"Target Path [{targetPath}");

            //Now Create all of the directories
            foreach (String dirPath in Directory.GetDirectories(sourcePath, "*", SearchOption.AllDirectories))
            {
                Directory.CreateDirectory(dirPath.Replace(sourcePath, targetPath));
            }

            //Copy all the files & Replaces any files with the same name
            foreach (String newPath in Directory.GetFiles(sourcePath, "*.*", SearchOption.AllDirectories))
            {
                String destFileName = newPath.Replace(sourcePath, targetPath);
                File.Copy(newPath, destFileName, true);
            }

            return true;
        }

        /// <summary>
        /// Gets the data set owner token.
        /// </summary>
        /// <returns></returns>
        private String GetDataSetOwnerToken()
        {
            try
            {
                String userName = Program.Configuration.GetSection("AppSettings:DatasetOwnerUser").Value;
                String pass = Program.Configuration.GetSection("AppSettings:DatasetOwnerPassword").Value;

                String accessToken = this.TokenService.GetMasterUserAccessToken(userName, pass);

                return accessToken;
            }
            catch(Exception e)
            {
                this.Logger.Error(e);
                return null;
            }
        }

        /// <summary>
        /// Gets the service principal token.
        /// </summary>
        /// <returns></returns>
        private String GetServicePrincipalToken()
        {
            try
            {
                this.Logger.Info("About to get Service Principal token");
                String accessToken = this.TokenService.GetServicePrincipalAccessToken();
                this.Logger.Info("Service Principal token retrived");
                return accessToken;
            }
            catch(Exception e)
            {
                this.Logger.Error(e);
                throw;
            }
        }

        /// <summary>
        /// Updates the datasets.
        /// </summary>
        /// <param name="releaseProfile">The release profile.</param>
        /// <param name="cancellationToken">The cancellation token.</param>
        /// <returns></returns>
        private async Task<Boolean> UpdateDatasets(ReleaseProfile releaseProfile,
                                                   CancellationToken cancellationToken)
        {
            this.Logger.Info("---- Update Datasets ----");
            String accessToken = this.GetDataSetOwnerToken();

            if (accessToken == null)
            {
                return false;
            }

            // Create the Power BI Service
            IPowerBIService powerBiService = this.PowerBiServiceResolver(accessToken);

            // Get the datasets from the release folder
            String[] dataSets = Directory.GetFiles($"{releaseProfile.ReleaseFolder}\\Datasets");

            foreach (String dataSet in dataSets)
            {
                var success = await this.UploadDataSet(powerBiService, releaseProfile, dataSet, cancellationToken);
            }

            this.Logger.Info("Datasets Uploaded Successfully");
            return true;
        }

        /// <summary>
        /// Updates the git hub release note.
        /// </summary>
        /// <param name="releaseProfileName">Name of the release profile.</param>
        /// <param name="tag">The tag.</param>
        /// <param name="cancellationToken">The cancellation token.</param>
        private async Task UpdateGitHubReleaseNote(String releaseProfileName,
                                                   String tag,
                                                   CancellationToken cancellationToken)
        {
            IGitHubService gitHubService = this.GitHubServiceResolver();
            (String releaseId, String body) release = await gitHubService.GetReleaseFromTag(tag, CancellationToken.None);
            StringBuilder stringBuilder = new StringBuilder(release.body);
            
            stringBuilder.AppendLine($"* Released To {releaseProfileName} {DateTime.Now:dd/MM/yyyy}");

            await gitHubService.UpdateRelease(release.releaseId, stringBuilder.ToString(), CancellationToken.None);
        }

        /// <summary>
        /// Updates the reports.
        /// </summary>
        /// <param name="releaseProfile">The release profile.</param>
        /// <param name="cancellationToken">The cancellation token.</param>
        /// <returns></returns>
        private async Task<Boolean> UpdateReports(ReleaseProfile releaseProfile,
                                                  CancellationToken cancellationToken)
        {
            String accessToken = this.GetServicePrincipalToken();

            // Create the Power BI Service
            IPowerBIService powerBiService = this.PowerBiServiceResolver(accessToken);

            String[] reports = Directory.GetFiles($"{releaseProfile.ReleaseFolder}\\Reports", "", SearchOption.AllDirectories);
            foreach (String report in reports)
            {
                FileInfo file = new FileInfo(report);
                await this.UploadReport(powerBiService, releaseProfile, report, cancellationToken);

                // Move file to processed folder
                //MoveProcessedFile(releaseProfile.ReleaseFolder, report);
            }

            this.Logger.Info("Reports Uploaded Successfully");
            return true;
        }

        /// <summary>
        /// Uploads the data set.
        /// </summary>
        /// <param name="powerBiService">The power bi service.</param>
        /// <param name="releaseProfile">The release profile.</param>
        /// <param name="datasetFile">The dataset file.</param>
        /// <param name="cancellationToken">The cancellation token.</param>
        /// <returns></returns>
        private async Task<Boolean> UploadDataSet(IPowerBIService powerBiService,
                                                  ReleaseProfile releaseProfile,
                                                  String datasetFile,
                                                  CancellationToken cancellationToken)
        {
            String dataSetName = null;
            try
            {
                FileInfo file = new FileInfo(datasetFile);
                dataSetName = file.Name;

                this.Logger.Info($"About to upload Dataset {datasetFile}");
                Guid importId = await powerBiService.UploadDataset(releaseProfile.GroupId, datasetFile, dataSetName, cancellationToken);
                this.Logger.Info($"Dataset {datasetFile} uploaded successfully");

                // Checking Import Status
                this.Logger.Info($"About to check status of dataset {datasetFile}");
                String datasetId = await powerBiService.CheckImportStatus(releaseProfile.GroupId, importId.ToString(), ImportedType.Dataset, cancellationToken);
                this.Logger.Info($"Dataset {datasetFile} verified successfully");

                Dictionary<String, String> parameters = new Dictionary<String, String>();
                parameters.Add("DatabaseName", releaseProfile.ReadModelDatabaseName);
                parameters.Add("DatabaseServer", releaseProfile.ReadModelDatabaseSever);

                this.Logger.Info($"About to change Dataset {datasetFile} parameters");
                await powerBiService.ChangeDatasetParameters(releaseProfile.GroupId, datasetId, parameters, cancellationToken);

                this.Logger.Info($"Dataset {datasetFile} parameters changed sucessfully");
                return true;
            }
            catch(InvalidOperationException iex)
            {
                this.Logger.Error(iex);
                throw;
            }
            catch(Exception ex)
            {
                this.Logger.Error(ex);
                return false;
            }
        }

        /// <summary>
        /// Uploads the report.
        /// </summary>
        /// <param name="powerBiService">The power bi service.</param>
        /// <param name="releaseProfile">The release profile.</param>
        /// <param name="reportFile">The report file.</param>
        /// <param name="cancellationToken">The cancellation token.</param>
        /// <returns></returns>
        /// <exception cref="Exception">Cant find the dataset for the {reportFolder} reprts</exception>
        private async Task<Boolean> UploadReport(IPowerBIService powerBiService,
                                                 ReleaseProfile releaseProfile,
                                                 String reportFile,
                                                 CancellationToken cancellationToken)
        {
            String reportName = null;
            try
            {
                FileInfo file = new FileInfo(reportFile);
                reportName = file.Name;
                // Get a list of the datasets for this group
                List<Dataset> datasets = await powerBiService.GetDataSets(releaseProfile.GroupId, cancellationToken);

                // Find the dataset
                String reportFolder = file.Directory.Name;
                Dataset? dataSetForRebind = datasets.SingleOrDefault(d => d.Name.Contains(reportFolder));

                if (dataSetForRebind == null)
                {
                    throw new Exception($"Cant find the dataset for the {reportFolder} reprts");
                }

                this.Logger.Info($"About to upload report {reportFile}");
                Guid importId = await powerBiService.UploadReport(releaseProfile.GroupId, reportFile, file.Name, dataSetForRebind.Id, cancellationToken);
                this.Logger.Info($"Report {reportFile} uploaded successfully");

                this.Logger.Info($"About to check status of report {reportFile}");
                // Checking Import Status
                await powerBiService.CheckImportStatus(releaseProfile.GroupId, importId.ToString(), ImportedType.Report, cancellationToken);

                this.Logger.Info($"Report {reportFile} verified successfully");

                return true;
            }
            catch(Exception ex)
            {
                return false;
            }
        }

        #endregion
    }
}