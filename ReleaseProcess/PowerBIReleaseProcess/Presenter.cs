namespace PowerBIReleaseTool
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.IO.Compression;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using System.Windows.Forms;
    using Microsoft.Extensions.Configuration;
    using Services;
    using Services.Database;
    using Services.PowerBi;
    using Vme.Configuration;

    // Tasks
    // TODO: get asset working directory from from configuration???
    // TODO: Support no zipped release artifacts...
    // TODO: Check if any power bi files need to be release before the init??
    // TODO: Add in some kind of configuration service so services are not coupled to the config reader class

    public interface IPresenter
    {
        #region Methods

        Task Start(CancellationToken cancellationToken);

        #endregion
    }

    public class Presenter : IPresenter
    {
        #region Fields

        private readonly IGitHubService GitHubService;

        private readonly IPowerBiService PowerBiService;

        private readonly IDatabaseManager DatabaseManager;

        private readonly IMainForm MainForm;

        private readonly MainFormViewModel MainFormViewModel;

        #endregion

        #region Constructors

        public Presenter(IMainForm mainForm,
                         MainFormViewModel mainFormViewModel,
                         IGitHubService gitHubService,
                         IPowerBiService powerBiService,
                         IDatabaseManager databaseManager)
        {
            this.MainForm = mainForm;
            this.MainFormViewModel = mainFormViewModel;
            this.GitHubService = gitHubService;
            this.PowerBiService = powerBiService;
            this.DatabaseManager = databaseManager;
            this.MainForm.FormLoaded += this.MainForm_FormLoaded;
            this.MainForm.ApplicationSelected += this.MainForm_ApplicationSelected;
            this.MainForm.UpdateApplicationButtonClicked += MainForm_UpdateApplicationButtonClicked;
            this.MainForm.OverrideCredentialsChecked += MainForm_OverrideCredentialsChecked;

            this.PowerBiService.ErrorMessage += PowerBiService_ErrorMessage;
            this.PowerBiService.TraceMessage += PowerBiService_TraceMessage;
            this.PowerBiService.SuccessMessage += PowerBiService_SuccessMessage;
        }

        private void MainForm_OverrideCredentialsChecked(object? sender, bool isChecked)
        {
            if (isChecked)
            {
                this.MainForm.ShowCredentialsOverride();
            }
            else
            {
                this.MainForm.HideCredentialsOverride();
            }
        }

        private void PowerBiService_SuccessMessage(object? sender, string e)
        {
            this.MainForm.writePositive(e);
        }

        private void PowerBiService_TraceMessage(object? sender, string e)
        {
            this.MainForm.writeNormal(e);
        }

        private void PowerBiService_ErrorMessage(object? sender, string e)
        {
            this.MainForm.writeNegative(e);
        }

        private Boolean CopyFilesRecursively(String sourcePath,
                                             String targetPath)
        {
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

        private String CreateCustomerDirectory(String customer,
                                               String outputPath)
        {
            String customerDirectory = $"{outputPath}\\{customer}";
            Directory.CreateDirectory(customerDirectory);

            this.CopyFilesRecursively($"{outputPath}\\extract", customerDirectory);
            this.MainForm.writeNormal($"Copied extracted files to customer working directory [{customerDirectory}]");
            return customerDirectory;
        }

        private async void MainForm_UpdateApplicationButtonClicked(object? sender, string e)
        {
            try
            {
                this.MainForm.DisableUpdatePanel();

                await this.PowerBiService.Initialise(this.MainFormViewModel.OverrideUser, this.MainFormViewModel.OverridePassword);

                PowerBiCustomerConfiguration customerConfiguration = this.MainFormViewModel.SelectedApplication;
                String selectedVersion = e;

                this.MainForm.writeNormal($"About to start release of version {selectedVersion} to customer {customerConfiguration.Name}");
                if (customerConfiguration.DemoApplication == true) {
                    var result = MessageBox.Show($"Applcation {customerConfiguration.Name} will be configured as as demo application, confirm this in intended",
                                    "Confirm Demo Application",
                                    MessageBoxButtons.YesNo,
                                    MessageBoxIcon.Exclamation,
                                    MessageBoxDefaultButton.Button2);

                    // user has setup as demo app in error or just cancelled
                    if (result == DialogResult.Cancel)
                        return;

                    this.MainForm.writeNormal("Application in demo mode");
                }
                
                String outputPath = "C:\\Temp\\PBIWorking";

                CancellationToken cancellationToken = new CancellationToken();

                Directory.CreateDirectory(outputPath);
                this.MainForm.writeNormal($"Working directory is [{outputPath}]");
                this.MainForm.writeNormal($"Get release {selectedVersion} from GitHub");

                GitHubReleaseDTO release = await this.GitHubService.GetRelease(selectedVersion, cancellationToken);
                this.MainForm.writeNormal($"Release {selectedVersion} successfully retrieved from GitHub");

                foreach (GithubReleaseAsset githubReleaseAsset in release.Assets)
                {
                    String assetPath = await this.GitHubService.GetReleaseAsset(githubReleaseAsset.Id, githubReleaseAsset.Name, outputPath, cancellationToken);

                    ZipFile.ExtractToDirectory(assetPath, $"{outputPath}\\extract", overwriteFiles:true);
                }

                this.MainForm.writeNormal($"Assets for release {selectedVersion} successfully retrieved from GitHub");

                // Assets have now been downloaded
                // Create a working folder for the customer
                String customerDirectory = this.CreateCustomerDirectory(customerConfiguration.Name, outputPath);

                String[]? fileCount = Directory.GetFiles($"{customerDirectory}", "*.*", SearchOption.AllDirectories);
                this.MainForm.InitialiseProgressBar(fileCount.Length);

                if (Directory.Exists($"{customerDirectory}\\DataModel") == false)
                {
                    this.MainForm.writeNormal("No database scripts to be released");
                }

                else
                {
                    String[]? databaseScripts = Directory.GetFiles($"{customerDirectory}\\DataModel", "*.sql",
                        SearchOption.AllDirectories);

                    if (databaseScripts.Length == 0)
                    {
                        this.MainForm.writeNormal("No database scripts to be released");
                    }
                    else
                    {
                        this.MainForm.writeNormal(
                            $"About to deploy {databaseScripts.Length} scripts to customers read model");
                        this.MainForm.writeNormal($"Connection String: {customerConfiguration.ConnectionString}");
                        foreach (String databaseScript in databaseScripts)
                        {
                            try
                            {
                                this.MainForm.writeNormal($"About to deploy {databaseScript}");
                                await this.DatabaseManager.ExecuteScript(customerConfiguration.ConnectionString,
                                    databaseScript, cancellationToken);
                                this.MainForm.writePositive($"{databaseScript} deployed successfully");
                                this.MainForm.IncrementProgressBar();
                            }
                            catch (Exception ex)
                            {
                                throw new Exception($"Script: {databaseScript} deployment failed, {ex.Message}");
                            }
                        }
                    }
                }

                if (Directory.Exists($"{customerDirectory}\\Datasets") == false)
                {
                    this.MainForm.writeNormal($"No datasets to deploy found at path {customerDirectory}\\Datasets");
                }

                else
                {

                    String[] datasetFiles = Directory.GetFiles($"{customerDirectory}\\Datasets", "*.pbix",
                        SearchOption.AllDirectories);
                    // TODO: Null check, why is this a null
                    if (datasetFiles == null && datasetFiles.Length == 0)
                    {
                        this.MainForm.writeNormal($"No datasets to deploy found at path {customerDirectory}\\Datasets");
                    }
                    else
                    {
                        // We have some files to release
                        this.MainForm.writeNormal(
                            $"About to deploy {datasetFiles.Length} datasets to customers workspace");

                        foreach (String datasetFile in datasetFiles)
                        {
                            try
                            {
                                this.MainForm.writeNormal($"About to deploy {datasetFile}");
                                Boolean result = await this.PowerBiService.DeployDataset(customerConfiguration,
                                    datasetFile, cancellationToken);
                                if (result == false)
                                {
                                    throw new Exception("deployment failed");
                                }

                                this.MainForm.IncrementProgressBar();
                            }
                            catch (Exception ex)
                            {
                                throw new Exception($"Dataset Name: {datasetFile}, {ex.Message}");
                            }
                        }
                    }
                }

                if (Directory.Exists($"{customerDirectory}\\Datasets") == false)
                {
                    this.MainForm.writeNormal($"No reports to deploy found at path {customerDirectory}\\Reports");
                }
                else
                {
                    var reportFiles = Directory.GetFiles($"{customerDirectory}\\Reports", "*.pbix",
                        SearchOption.AllDirectories);

                    if (reportFiles == null && reportFiles.Length == 0)
                    {
                        this.MainForm.writeNormal($"No reports to deploy found at path {customerDirectory}\\Reports");
                    }
                    else
                    {
                        // We have some files to release
                        this.MainForm.writeNormal(
                            $"About to deploy {reportFiles.Length} reports to customers workspace");

                        foreach (String reportFile in reportFiles)
                        {
                            try
                            {
                                this.MainForm.writeNormal($"About to deploy {reportFile}");
                                Boolean result = await this.PowerBiService.DeployReport(customerConfiguration,
                                    reportFile, cancellationToken);
                                if (result == false)
                                {
                                    throw new Exception("deployment failed");
                                }

                                this.MainForm.IncrementProgressBar();
                            }
                            catch (Exception ex)
                            {
                                throw new Exception($"Report Name: {reportFile}, {ex.Message}");
                            }
                        }
                    }
                }

                await this.PowerBiService.UpdateApplicationVersion(customerConfiguration, selectedVersion, cancellationToken);

                this.MainForm.writePositive($"Release of version {selectedVersion} to customer {customerConfiguration.Name} completed successfully!!");
                this.MainForm.writePositive($"To complete this release please go to the customer workspace and update the application!");

                // Refresh the customer
                await this.LoadCustomersList();
            }
            catch(Exception ex)
            {
                this.MainForm.writeNegative(ex.Message);
            }
            finally
            {
                this.MainForm.EnableUpdatePanel();
            }
        }

        #endregion

        #region Methods

        public async Task Start(CancellationToken cancellationToken)
        {
            Application.Run((Form)this.MainForm);
        }

        private async void MainForm_ApplicationSelected(Object? sender,
                                                        String e)
        {
            CancellationToken cancellationToken = new CancellationToken();

            var selectedApplication = this.MainFormViewModel.PowerBiApplications.Single(a => a.Name == e);
            this.MainFormViewModel.SelectedApplication = selectedApplication;

            try
            {
                this.MainForm.writeNormal("About to get release information from Github");
                this.MainForm.writeNormal($"Github Uri: [{this.GitHubService.GithubApiUrl}]");
                this.MainFormViewModel.AvailableVersions = new List<String>();
                List<GitHubReleaseDTO> releases = await this.GitHubService.GetReleases(cancellationToken);
                releases = releases.OrderByDescending(r => r.Id).ToList();
                foreach (GitHubReleaseDTO gitHubReleaseDto in releases)
                {
                    this.MainFormViewModel.AvailableVersions.Add(gitHubReleaseDto.Tag);
                }

                this.MainForm.writePositive("Release details retrieved successfully!!");

                this.MainForm.LoadApplicationDetails();
                this.MainForm.ShowUpdateOptions();
            }
            catch(Exception ex)
            {
                this.MainForm.writeNegative("Failed to get release details!!");
                this.MainForm.writeNegative(ex.Message);
            }
        }

        private async void MainForm_FormLoaded(Object? sender,
                                               EventArgs e)
        {
            await this.PowerBiService.Initialise();
            await this.LoadCustomersList();
        }

        private async Task LoadCustomersList()
        {
            CancellationToken cancellationToken = new CancellationToken();

            this.MainForm.writeNormal("About to get customer list from Configuration");
            this.MainFormViewModel.PowerBiApplications = Program.Configuration.GetSection("Applications").Get<List<PowerBiCustomerConfiguration>>();

            foreach (PowerBiCustomerConfiguration customerConfiguration in this.MainFormViewModel.PowerBiApplications)
            {
                String version = await this.PowerBiService.GetCurrentDeployedVersionNumber(customerConfiguration, cancellationToken);
                customerConfiguration.CurrentVersion = version;
            }

            this.MainForm.writePositive("Customer list loaded successfully");

            this.MainForm.writeNormal($"Dataset Owner User: {ConfigurationReader.GetValue("DatasetOwnerUser")}");
            this.MainForm.writeNormal($"Power BI Api Url: {ConfigurationReader.GetValue("PowerBiApiUrl")}");

            this.MainForm.Initialise(this.MainFormViewModel);
        }

        #endregion
    }
}