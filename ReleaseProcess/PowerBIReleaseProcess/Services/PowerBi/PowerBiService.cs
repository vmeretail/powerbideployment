namespace PowerBIReleaseTool.Services.PowerBi
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.IO.Compression;
    using System.Linq;
    using System.Net.Http;
    using System.Security;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;
    using Microsoft.Identity.Client;
    using Microsoft.PowerBI.Api;
    using Microsoft.PowerBI.Api.Models;
    using Microsoft.Rest;
    using Newtonsoft.Json;
    using RestSharp;
    using Vme.Configuration;

    public class PowerBiService : IPowerBiService
    {
        private readonly ITokenService TokenService;

        private String PowerBiApiUrl;

        private Int32 FileImportCheckRetryAttempts;

        private Int32 FileImportCheckSleepIntervalInSeconds;

        public PowerBiService(ITokenService tokenService)
        {
            this.TokenService = tokenService;
        }

        private String DataSetOwnerToken;

        private String ServicePrincipalToken;

        public async Task Initialise(String datasetOwner = "",
                                     String password = "")
        {
            if (String.IsNullOrEmpty(datasetOwner))
            {
                datasetOwner = ConfigurationReader.GetValue("DatasetOwnerUser");
            }

            if (String.IsNullOrEmpty(password))
            {
                password = ConfigurationReader.GetValue("DatasetOwnerPassword");
            }

            this.DataSetOwnerToken = this.GetDataSetOwnerToken(datasetOwner, password);
            this.ServicePrincipalToken = this.GetServicePrincipalToken();

            this.PowerBiApiUrl = "https://api.powerbi.com";
            this.FileImportCheckRetryAttempts = 5;
            this.FileImportCheckSleepIntervalInSeconds = 5;
        }

        private PowerBIClient GetPowerBIClient(String token)
        {
            TokenCredentials tokenCredentials = new TokenCredentials(token, "Bearer");
            return new PowerBIClient(new Uri(this.PowerBiApiUrl), tokenCredentials);
        }

        private RestClient GetPowerBIHttpClient()
        {
            var restClient = new RestClient(this.PowerBiApiUrl);
            return restClient;
        }

        public event EventHandler<String> TraceMessage;
        public event EventHandler<String> ErrorMessage;
        public event EventHandler<String> SuccessMessage;

        public void SafeInvoke(EventHandler<String> eventHandler, String message)
        {
            if (eventHandler != null)
            {
                eventHandler(this, message);
            }
        }

        public void TraceMessageSafe(String msg) => this.SafeInvoke(this.TraceMessage, msg);
        public void SuccessMessageSafe(String msg) => this.SafeInvoke(this.SuccessMessage, msg);
        public void ErrorMessageSafe(String msg) => this.SafeInvoke(this.ErrorMessage, msg);
        

        public async Task<Boolean> DeployDataset(PowerBiCustomerConfiguration customerConfiguration, String datasetFile, CancellationToken cancellationToken)
        {
            // Upload the pbix file
            (Guid importId, String message) uploadResult  = await this.UploadFile(datasetFile, customerConfiguration.GroupId, ImportedType.Dataset, cancellationToken);

            if (uploadResult.importId == Guid.Empty)
            {
                this.ErrorMessageSafe(uploadResult.message);
                return false;
            }

            this.SuccessMessageSafe($"Dataset {datasetFile} uploaded successfully!!");

            // Check the status of the upload
            (String uploadedFileId, String message) checkResult = await this.CheckUploadStatus(customerConfiguration.GroupId, uploadResult.importId, ImportedType.Dataset, cancellationToken);

            if (String.IsNullOrEmpty(checkResult.uploadedFileId))
            {
                this.ErrorMessageSafe(checkResult.message);
                return false;
            }

            this.SuccessMessageSafe($"Dataset {datasetFile} upload successfully verified!!");

            Dictionary<String, String> parameters = new Dictionary<String, String>();
            parameters.Add("DatabaseName", customerConfiguration.ReadModelDatabaseName);
            parameters.Add("DatabaseServer", customerConfiguration.ReadModelDatabaseSever);

            // Update the parameters of the dataset
            (Boolean success, String message) changeResult = await ChangeDatasetParameters(customerConfiguration.GroupId, checkResult.uploadedFileId, parameters, cancellationToken);

            if (changeResult.success == false)
            {
                this.ErrorMessageSafe(changeResult.message);
                return false;
            }

            this.SuccessMessageSafe($"Dataset {datasetFile} parameters updated successfully!!");
            this.SuccessMessageSafe($"Dataset {datasetFile} successfully deployed");
            return true;

        }
        

        public async Task<Boolean> DeployReport(PowerBiCustomerConfiguration customerConfiguration, String reportFile, CancellationToken cancellationToken)
        {
            // Find the dataset for this report to be bound to
            (Dataset dataset, String message) getDatasetResult  = await GetDataSetForReport(customerConfiguration.GroupId, reportFile, cancellationToken);

            if (getDatasetResult.dataset == null)
            {
                this.ErrorMessageSafe(getDatasetResult.message);
                return false;
            }
            
            this.UpdateConnection(reportFile, getDatasetResult.dataset.Id);

            // Upload the pbix file
            (Guid importId, String message) uploadResult = await this.UploadFile(reportFile, customerConfiguration.GroupId, ImportedType.Report, cancellationToken);

            if (uploadResult.importId == Guid.Empty)
            {
                this.ErrorMessageSafe(uploadResult.message);
                return false;
            }

            // Check the status of the upload
            (String uploadedFileId, String message) checkStatus = await this.CheckUploadStatus(customerConfiguration.GroupId, uploadResult.importId, ImportedType.Report, cancellationToken);

            if (String.IsNullOrEmpty(checkStatus.uploadedFileId))
            {
                this.ErrorMessageSafe(checkStatus.message);
                return false;
            }

            this.SuccessMessageSafe($"Report {reportFile} successfully deployed");
            return true;
        }

        public async Task<String> GetCurrentDeployedVersionNumber(PowerBiCustomerConfiguration customerConfiguration,
                                                                  CancellationToken cancellationToken)
        {
            PowerBIClient powerBiClient = GetPowerBIClient(this.DataSetOwnerToken);

            // Get a list of the datasets for this group
            HttpOperationResponse<Datasets>? response = await powerBiClient.Datasets.GetDatasetsInGroupWithHttpMessagesAsync(customerConfiguration.GroupId, null, cancellationToken);

            // get the products dataset (it holds the version number)
            var productsDataSet = response.Body.Value.SingleOrDefault(d => d.Name == $"VME Master - Products");

            HttpOperationResponse<MashupParameters> datasetParameters = await powerBiClient.Datasets.GetParametersInGroupWithHttpMessagesAsync(customerConfiguration.GroupId, productsDataSet.Id, cancellationToken: cancellationToken);

            var version = datasetParameters.Body.Value.SingleOrDefault(p => p.Name == "Version");

            if (version == null)
            {
                return "N/A";
            }

            return version.CurrentValue;
        }

        private void UpdateConnection(string filepath, String datasetId)
        {
            using (ZipArchive archive = new ZipArchive(File.Open(filepath, FileMode.Open), ZipArchiveMode.Update, false, null))
            {
                ZipArchiveEntry entry = archive.GetEntry("Connections");
                string newstring;
                using (var sr = new StreamReader(entry.Open(), Encoding.Default))
                {

                    var jsonText = sr.ReadToEnd();
                    var connectionDetails = JsonConvert.DeserializeObject<PowerBiConnectionDetails>(jsonText);
                    var conn = connectionDetails.Connections.First();

                    var existingDataSetId = conn.PbiModelDatabaseName;
                    conn.PbiModelDatabaseName = datasetId;
                    conn.ConnectionString = conn.ConnectionString.Replace(existingDataSetId, datasetId);
                    newstring = JsonConvert.SerializeObject(connectionDetails);
                }

                using (var sw = new StreamWriter(entry.Open()))
                {
                    sw.Write(newstring);
                }
            }
        }

        private String GetDataSetOwnerToken(String datasetOwner, String password)
        {
            try
            {
                String accessToken = this.TokenService.GetMasterUserAccessToken(datasetOwner, password);

                return accessToken;
            }
            catch (Exception e)
            {
                throw new Exception("Error getting Dataset Owner token", e);
            }
        }

        private String GetServicePrincipalToken()
        {
            try
            {
                String accessToken = this.TokenService.GetServicePrincipalAccessToken();
                return accessToken;
            }
            catch (Exception e)
            {
                throw new Exception("Error getting Service Principal token", e);
            }
        }

        private async Task<(Dataset dataset,String message)> GetDataSetForReport(Guid groupId, String reportFile, CancellationToken cancellationToken)
        {
            FileInfo file = new FileInfo(reportFile);
            PowerBIClient powerBiClient = GetPowerBIClient(this.DataSetOwnerToken);

            // Get a list of the datasets for this group
            HttpOperationResponse<Datasets>? response = await powerBiClient.Datasets.GetDatasetsInGroupWithHttpMessagesAsync(groupId, null, cancellationToken);

            List<Dataset> datasetList = response.Body.Value.ToList();

            // Find the dataset
            String reportFolder = file.Directory.Name;
            Dataset? dataSetForRebind = datasetList.SingleOrDefault(d => d.Name == $"VME Master - {reportFolder}");

            if (dataSetForRebind == null)
            {
                return (null, $"Cant find the dataset for the {reportFolder} reports");
            }

            return (dataSetForRebind,String.Empty);
        }

        private async Task<(Guid importId, String message)> UploadFile(String datasetFile, Guid groupId, ImportedType importedType, CancellationToken cancellationToken)
        {
            FileInfo file = new FileInfo(datasetFile);
            String datasetDisplayName = file.Name;

            String requestUri =
                $"{this.PowerBiApiUrl}/v1.0/myorg/groups/{groupId}/imports?dataSetDisplayName={datasetDisplayName}&nameConflict=CreateOrOverwrite";

            String token = this.ServicePrincipalToken;
            if (importedType == ImportedType.Dataset)
            {
                requestUri = $"{requestUri}&skipReport=True";
                token = this.DataSetOwnerToken;
            }

            RestRequest request = new RestRequest(new Uri(requestUri), Method.POST);
            request.AddHeader("Authorization", $"Bearer {token}");
            request.AddFile("file0", datasetFile, "application/x-zip-compressed");
            RestClient restClient = this.GetPowerBIHttpClient();
            IRestResponse response = await restClient.ExecuteAsync(request, cancellationToken);

            if (response.IsSuccessful == false)
            {
                return (Guid.Empty, $"Error uploading dataset [{datasetFile}], Http Response is [{response.Content}]");
            }

            // Now check the status of the import call at the Power BI serivce
            var definition = new
                             {
                                 id = Guid.Empty
                             };
            // Get the import id from the import response
            var responseDto = JsonConvert.DeserializeAnonymousType(response.Content, definition);

            return (responseDto.id, String.Empty);
        }

        private async Task<(String uploadedFileId, String message)> CheckUploadStatus(Guid groupId, Guid importId, ImportedType importType, CancellationToken cancellationToken)
        {
            PowerBIClient powerBiClient = GetPowerBIClient(this.DataSetOwnerToken);
            if (importType == ImportedType.Report)
            {
                powerBiClient = GetPowerBIClient(this.ServicePrincipalToken);
            }
            
            var importResponse = await powerBiClient.Imports.GetImportInGroupWithHttpMessagesAsync(groupId, importId, null, cancellationToken);
            for (Int32 i = 0; i < this.FileImportCheckRetryAttempts; i++)
            {
                if (importResponse.Body.ImportState == "Succeeded")
                {
                    break;
                }

                Thread.Sleep(TimeSpan.FromSeconds(this.FileImportCheckSleepIntervalInSeconds));
                importResponse = await powerBiClient.Imports.GetImportInGroupWithHttpMessagesAsync(groupId, importId, null, cancellationToken);
            }

            if (importResponse.Body.ImportState != "Succeeded")
            {
                return (String.Empty, $"Unable to verify import successful for {importType} with import Id {importId}");
            }

            switch (importType)
            {
                case ImportedType.Dataset:
                    Dataset datasetImport = importResponse.Body.Datasets.Single();
                    HttpOperationResponse<Dataset> dataset = await powerBiClient.Datasets.GetDatasetInGroupWithHttpMessagesAsync(groupId, datasetImport.Id, cancellationToken: cancellationToken);

                    HttpOperationResponse<Datasources> dataSources =
                        await powerBiClient.Datasets.GetDatasourcesInGroupWithHttpMessagesAsync(groupId, dataset.Body.Id, cancellationToken: cancellationToken);

                    if (dataSources.Body.Value.Count > 1)
                    {
                        throw new InvalidOperationException($"Dataset Name [{dataset.Body.Name}] has more than once datasource, please verify and update!!");
                    }

                    return (dataset.Body.Id, String.Empty);
                case ImportedType.Report:
                    Report report = importResponse.Body.Reports.Single();
                    return (report.Id.ToString(), String.Empty);
                default:
                    return (String.Empty,String.Empty);
            }
        }

        private async Task<(Boolean success, String message)> ChangeDatasetParameters(Guid groupId, String datasetId, Dictionary<String, String> parameters, CancellationToken cancellationToken)
        {
            PowerBIClient powerBiClient = this.GetPowerBIClient(this.DataSetOwnerToken);

            List<UpdateMashupParameterDetails> details = new List<UpdateMashupParameterDetails>();
            try
            {

                HttpOperationResponse<MashupParameters> datasetParameters =
                    await powerBiClient.Datasets.GetParametersInGroupWithHttpMessagesAsync(groupId, datasetId, cancellationToken:cancellationToken);
                HttpOperationResponse<Dataset>? dataset =
                    await powerBiClient.Datasets.GetDatasetInGroupWithHttpMessagesAsync(groupId, datasetId, cancellationToken:cancellationToken);
                List<String> missingParameterList = new List<String>();

                foreach (KeyValuePair<String, String> param in parameters)
                {
                    var foundParameter = datasetParameters.Body.Value.SingleOrDefault(p => p.Name == param.Key);
                    if (foundParameter == null)
                    {
                        missingParameterList.Add(param.Key);
                    }

                    details.Add(new UpdateMashupParameterDetails(param.Key, param.Value));
                }

                if (missingParameterList.Any())
                {
                    // We have expected parameters missing from the dataset
                    string joined = string.Join(",", missingParameterList);

                    return (false, $"The following parameters[{joined}] are missing from DataSet[{dataset.Body.Name}]");
                }

                UpdateMashupParametersRequest request = new UpdateMashupParametersRequest
                                                        {
                                                            UpdateDetails = details
                                                        };

                HttpOperationResponse? response =
                    await powerBiClient.Datasets.UpdateParametersInGroupWithHttpMessagesAsync(groupId, datasetId, request, cancellationToken:cancellationToken);

                if (response.Response.IsSuccessStatusCode == false)
                {
                    return (false,$"Call to UpdateParametersInGroupWithHttpMessagesAsync unsuccessful [{response.Response.StatusCode}]");
                }

                return (true, String.Empty);
            }
            catch(Exception ex)
            {
                //throw new Exception("Error changing parameters on dataset.", ex);
                return (false, $"Error changing parameters on dataset. Error Message [{ex.Message}]");
            }
        }

        public async Task UpdateApplicationVersion(PowerBiCustomerConfiguration customerConfiguration, String newVersion, CancellationToken cancellationToken)
        {
            List<UpdateMashupParameterDetails> details = new List<UpdateMashupParameterDetails>();
            PowerBIClient powerBiClient = this.GetPowerBIClient(this.DataSetOwnerToken);

            // Get a list of the datasets for this group
            HttpOperationResponse<Datasets>? getDataSetListResponse = await powerBiClient.Datasets.GetDatasetsInGroupWithHttpMessagesAsync(customerConfiguration.GroupId, null, cancellationToken);

            // get the products dataset (it holds the version number)
            Dataset? productsDataSet = getDataSetListResponse.Body.Value.SingleOrDefault(d => d.Name == $"VME Master - Products");

            HttpOperationResponse<MashupParameters> datasetParameters = await powerBiClient.Datasets.GetParametersInGroupWithHttpMessagesAsync(customerConfiguration.GroupId, productsDataSet.Id, cancellationToken: cancellationToken);
            
            details.Add(new UpdateMashupParameterDetails("Version", newVersion));
            
            UpdateMashupParametersRequest request = new UpdateMashupParametersRequest
            {
                UpdateDetails = details
            };

            HttpOperationResponse? response = await powerBiClient.Datasets.UpdateParametersInGroupWithHttpMessagesAsync(customerConfiguration.GroupId, productsDataSet.Id, request, cancellationToken: cancellationToken);

            if (response.Response.IsSuccessStatusCode == false)
            {
                this.ErrorMessageSafe("Error updating application version number");
            }

            this.SuccessMessageSafe($"Application version number updated to {newVersion}");
        }
    }

    public interface ITokenService
    {
        #region Methods

        /// <summary>
        /// Gets the access token.
        /// </summary>
        /// <param name="pbiUsername">The pbi username.</param>
        /// <param name="pbiPassword">The pbi password.</param>
        /// <returns></returns>
        String GetMasterUserAccessToken(String pbiUsername,
                                        String pbiPassword);

        /// <summary>
        /// Gets the service principal access token.
        /// </summary>
        /// <returns></returns>
        String GetServicePrincipalAccessToken();

        #endregion
    }

    public class TokenService : ITokenService
    {
        #region Methods

        public String GetMasterUserAccessToken(String pbiUsername, String pbiPassword)
        {
            AuthenticationResult authenticationResult = null;

            String authorityUri = Program.Configuration.GetSection("AppSettings:AuthorityUri").Value;
            String clientId = Program.Configuration.GetSection("AppSettings:ClientId").Value;
            String[] scopes = Program.Configuration.GetSection("AppSettings:Scopes").Value.Split(",");
            // Create a public client to authorize the app with the AAD app

            IPublicClientApplication clientApp = PublicClientApplicationBuilder.Create(clientId).WithAuthority(authorityUri).Build();
            IEnumerable<IAccount> userAccounts = clientApp.GetAccountsAsync().Result;
            try
            {
                // Retrieve Access token from cache if available
                authenticationResult = clientApp.AcquireTokenSilent(scopes, userAccounts.FirstOrDefault()).ExecuteAsync().Result;
            }
            catch (MsalUiRequiredException)
            {
                SecureString password = new SecureString();
                foreach (var key in pbiPassword)
                {
                    password.AppendChar(key);
                }

                authenticationResult = clientApp.AcquireTokenByUsernamePassword(scopes, pbiUsername, password).ExecuteAsync().Result;
            }

            return authenticationResult.AccessToken;
        }


        /// <summary>
        /// Generates and returns Access token
        /// </summary>
        /// <param name="tokenType">Type of the token.</param>
        /// <returns>
        /// AAD token
        /// </returns>
        public String GetServicePrincipalAccessToken()
        {
            String authorityUri = Program.Configuration.GetSection("AppSettings:AuthorityUri").Value;
            String clientId = Program.Configuration.GetSection("AppSettings:ClientId").Value;
            String[] scopes = Program.Configuration.GetSection("AppSettings:Scopes").Value.Split(",");

            AuthenticationResult authenticationResult = null;

            // Service Principal auth is the recommended by Microsoft to achieve App Owns Data Power BI embedding

            String tenantId = Program.Configuration.GetSection("AppSettings:TenantId").Value;
            String clientSecret = Program.Configuration.GetSection("AppSettings:ClientSecret").Value;
            // For app only authentication, we need the specific tenant id in the authority url
            String tenantSpecificUrl = authorityUri.Replace("organizations", tenantId);

            // Create a confidential client to authorize the app with the AAD app
            IConfidentialClientApplication clientApp = ConfidentialClientApplicationBuilder.Create(clientId).WithClientSecret(clientSecret)
                                                                                           .WithAuthority(tenantSpecificUrl).Build();
            // Make a client call if Access token is not available in cache
            authenticationResult = clientApp.AcquireTokenForClient(scopes).ExecuteAsync().Result;

            return authenticationResult.AccessToken;
        }

        #endregion
    }

    public enum ImportedType
    {
        Dataset,
        Report
    }

    public class PowerBiConnectionDetails
    {
        public int Version { get; set; }
        public List<Connection> Connections { get; set; }
    }

    public class Connection
    {
        public string Name { get; set; }
        public string ConnectionString { get; set; }
        public string ConnectionType { get; set; }
        public int PbiServiceModelId { get; set; }
        public string PbiModelVirtualServerName { get; set; }
        public string PbiModelDatabaseName { get; set; }
    }
}