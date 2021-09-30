namespace PowerBIReleaseProcess
{
    using System;
    using System.Collections.Generic;
    using System.Data.Common;
    using System.IO;
    using System.IO.Compression;
    using System.Linq;
    using System.Net.Http;
    using System.Net.Http.Headers;
    using System.Runtime.InteropServices;
    using System.Text;
    using System.Text.Encodings.Web;
    using System.Threading;
    using System.Threading.Tasks;
    using Microsoft.PowerBI.Api;
    using Microsoft.PowerBI.Api.Models;
    using Microsoft.Rest;
    using Newtonsoft.Json;
    using RestSharp;

    public class PowerBIService : IPowerBIService
    {
        public PowerBIService(String powerBiUrl, String token, Int32 fileImportCheckRetryAttempts, Int32 fileImportCheckSleepIntervalInSeconds)
        {
            this.PowerBiUrl = powerBiUrl;
            this.Token = token;
            this.FileImportCheckRetryAttempts = fileImportCheckRetryAttempts;
            this.FileImportCheckSleepIntervalInSeconds = fileImportCheckSleepIntervalInSeconds;
            this.PowerBIClient = this.GetPowerBIClient(token);
            this.RestClient = this.GetPowerBIHttpClient();
        }

        private readonly String PowerBiUrl;
        private readonly String Token;

        private readonly Int32 FileImportCheckRetryAttempts;

        private readonly Int32 FileImportCheckSleepIntervalInSeconds;

        private readonly PowerBIClient PowerBIClient;

        private readonly RestClient RestClient;
        
        private PowerBIClient GetPowerBIClient(String token)
        {
            TokenCredentials tokenCredentials = new TokenCredentials(token, "Bearer");
            return new PowerBIClient(new Uri(this.PowerBiUrl), tokenCredentials);
        }

        private RestClient GetPowerBIHttpClient()
        {
            var restClient = new RestClient(this.PowerBiUrl);
            return restClient;
        }

        public async Task<Guid> UploadDataset(Guid groupId,
                                        String filePath,
                                        String datasetDisplayName,
                                        CancellationToken cancellationToken)
        {
                String requestUri =
                    $"{this.PowerBiUrl}/v1.0/myorg/groups/{groupId}/imports?dataSetDisplayName={datasetDisplayName}&nameConflict=CreateOrOverwrite&skipReport=True";

                RestRequest request = new RestRequest(new Uri(requestUri), Method.POST);
                request.AddHeader("Authorization", $"Bearer {this.Token}");
                request.AddFile("file0", filePath, "application/x-zip-compressed");

                IRestResponse response = await this.RestClient.ExecuteAsync(request, cancellationToken);

                if (response.IsSuccessful == false)
                {
                    // throw an error
                    throw new HttpRequestException($"Error uploading dataset [{filePath}], Http Response is [{response.Content}]");
                }

                // Now check the status of the import call at the Power BI serivce
                var definition = new
                                 {
                                     id = Guid.Empty
                                 };
                // Get the import id from the import response
                var responseDto = JsonConvert.DeserializeAnonymousType(response.Content, definition);

                return responseDto.id;
        }

        /// <summary>
        /// Checks the import status.
        /// </summary>
        /// <param name="groupId">The group identifier.</param>
        /// <param name="importId">The import identifier.</param>
        /// <param name="importType">Type of the import.</param>
        /// <param name="cancellationToken">The cancellation token.</param>
        /// <returns></returns>
        /// <exception cref="Exception">Unable to verify import successful for {importType} with import Id {importId}</exception>
        public async Task<String> CheckImportStatus(Guid groupId, String importId, ImportedType importType, CancellationToken cancellationToken)
        {
            var importResponse = await this.PowerBIClient.Imports.GetImportInGroupWithHttpMessagesAsync(groupId, Guid.Parse(importId), null, cancellationToken);
            for (Int32 i = 0; i < this.FileImportCheckRetryAttempts; i++)
            {
                if (importResponse.Body.ImportState == "Succeeded")
                {
                    break;
                }

                Thread.Sleep(TimeSpan.FromSeconds(this.FileImportCheckSleepIntervalInSeconds));
                importResponse = await this.PowerBIClient.Imports.GetImportInGroupWithHttpMessagesAsync(groupId, Guid.Parse(importId), null, cancellationToken);
            }

            if (importResponse.Body.ImportState != "Succeeded")
            {
                throw new InvalidOperationException($"Unable to verify import successful for {importType} with import Id {importId}");
            }

            switch(importType)
            {
                case ImportedType.Dataset:
                    Dataset datasetImport = importResponse.Body.Datasets.Single();
                    HttpOperationResponse<Dataset> dataset = await this.PowerBIClient.Datasets.GetDatasetInGroupWithHttpMessagesAsync(groupId, datasetImport.Id, cancellationToken:cancellationToken);
                    
                    HttpOperationResponse<Datasources> dataSources =
                        await this.PowerBIClient.Datasets.GetDatasourcesInGroupWithHttpMessagesAsync(groupId, dataset.Body.Id, cancellationToken:cancellationToken);

                    if (dataSources.Body.Value.Count > 1)
                    {
                        throw new InvalidOperationException($"Dataset Name [{dataset.Body.Name}] has more than once datasource, please verify and update!!");
                    }
                    
                    return dataset.Body.Id;
                case ImportedType.Report:
                    Report report = importResponse.Body.Reports.Single();
                    return report.Id.ToString();
                default:
                    return null;
            }
            
        }

        public async Task<Guid> UploadReport(Guid groupId,
                                       String filePath,
                                       String reportDisplayName,
                                       String datasetId,
                                       CancellationToken cancellationToken)
        {
            UpdateConnection(filePath, datasetId);

            // Manual method as cant use client :|
            String requestUri =
                $"{this.PowerBiUrl}/v1.0/myorg/groups/{groupId}/imports?dataSetDisplayName={reportDisplayName}&nameConflict=CreateOrOverwrite";
            
            RestRequest request = new RestRequest(new Uri(requestUri), Method.POST);
            request.AddHeader("Authorization", $"Bearer {this.Token}");
            request.AddFile("file0", filePath, "application/x-zip-compressed");

            IRestResponse response = await this.RestClient.ExecuteAsync(request, cancellationToken);

            if (response.IsSuccessful == false)
            {
                // throw an error
                throw new Exception($"Error uploading report [{filePath}], Http Response is [{response.Content}]");
            }
            var definition = new { id = Guid.Empty };

            // Get the report id from the reponse
            var responseDto = JsonConvert.DeserializeAnonymousType(response.Content, definition);
            
            return responseDto.id;
        }

        public static void UpdateConnection(string filepath, String datasetId)
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

        public async Task RebindReport(Guid groupId,
                                       Guid reportId,
                                       String datasetId,
                                       CancellationToken cancellationToken)
        {
            RebindReportRequest rebindReportRequest = new RebindReportRequest(datasetId);

            var response = await this.PowerBIClient.Reports.RebindReportInGroupWithHttpMessagesAsync(groupId,reportId, rebindReportRequest, null, cancellationToken);

            if (response.Response.IsSuccessStatusCode == false)
            {
                throw new InvalidOperationException("Error rebinding report");
            }
        }

        public async Task<List<Dataset>> GetDataSets(Guid groupId,
                                                     CancellationToken cancellationToken)
        {
            var response = await this.PowerBIClient.Datasets.GetDatasetsInGroupWithHttpMessagesAsync(groupId, null, cancellationToken);

            return response.Body.Value.ToList();
        }

        public async Task ChangeDatasetParameters(Guid groupId, String datasetId, Dictionary<String,String> parameters, CancellationToken cancellationToken)
        {
            List<UpdateMashupParameterDetails> details = new List<UpdateMashupParameterDetails>();

            HttpOperationResponse<MashupParameters> datasetParameters = await this.PowerBIClient.Datasets.GetParametersInGroupWithHttpMessagesAsync(groupId, datasetId, cancellationToken: cancellationToken);
            var dataset = await this.PowerBIClient.Datasets.GetDatasetInGroupWithHttpMessagesAsync(groupId, datasetId, cancellationToken: cancellationToken);
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

                throw new InvalidOperationException($"The following parameters [{joined}] are missing from DataSet [{dataset.Body.Name}]");
            }

            UpdateMashupParametersRequest request = new UpdateMashupParametersRequest
            {
                UpdateDetails = details
            };

            var response = await this.PowerBIClient.Datasets.UpdateParametersInGroupWithHttpMessagesAsync(groupId, datasetId, request, cancellationToken: cancellationToken);

            if (response.Response.IsSuccessStatusCode == false)
            {
                throw new InvalidOperationException("Error changing parameters on dataset.");
            }
        }
    }

    public enum ImportedType
    {
        Dataset,
        Report
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

    public class PowerBiConnectionDetails
    {
        public int Version { get; set; }
        public List<Connection> Connections { get; set; }
    }
}