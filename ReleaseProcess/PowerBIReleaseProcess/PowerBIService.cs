namespace PowerBIReleaseProcess
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.IO.Compression;
    using System.Linq;
    using System.Net.Http;
    using System.Runtime.CompilerServices;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;
    using Microsoft.PowerBI.Api;
    using Microsoft.PowerBI.Api.Models;
    using Microsoft.Rest;
    using Newtonsoft.Json;
    using RestSharp;
    using RestSharp.Validation;
    
    public record PowerBIServiceState
    {
        public Int32 FileImportCheckRetryAttempts { get; init; }

        public Int32 FileImportCheckSleepIntervalInSeconds { get; init; }

        public IPowerBIClient PowerBiClient { get; init; }

        public IRestClient RestClient { get; init; }

        public Guid GroupId { get; init; }
        
        public String BearerToken { get; init; }

        public PowerBIServiceState(Int32 fileImportCheckRetryAttempts,
                                   Int32 fileImportCheckSleepIntervalInSeconds,
                                   IPowerBIClient powerBiClient,
                                   IRestClient restClient,
                                   String bearerToken,
                                   Guid groupId)
        {
            this.FileImportCheckRetryAttempts = fileImportCheckRetryAttempts;
            this.FileImportCheckSleepIntervalInSeconds = fileImportCheckSleepIntervalInSeconds;
            this.PowerBiClient = powerBiClient;
            this.RestClient = restClient;
            this.GroupId = groupId;
            this.BearerToken = bearerToken;
        }
    }

    public static class PowerBIServiceStateExtensions
    {
       
        public static async Task<List<Dataset>> GetDatasets(this PowerBIServiceState service,
                                                            CancellationToken cancellationToken) =>
            await service.PowerBiClient.GetDatasets(service.GroupId, cancellationToken);

        public static async Task ChangeDatasetParameters(this PowerBIServiceState service,
                                                         String datasetId,
                                                   Dictionary<String, String> parameters,
                                                   CancellationToken cancellationToken) =>
            await service.PowerBiClient.ChangeDatasetParameters(service.GroupId, datasetId, parameters, cancellationToken);

        public static async Task<Guid> UploadDataSet(this PowerBIServiceState service,
                                         String filePath,
                                         String datasetDisplayName, 
                                         CancellationToken cancellationToken) =>
            await service.RestClient.UploadDataset(service.BearerToken, service.GroupId, filePath, datasetDisplayName, cancellationToken);

        public static async Task<Guid> UploadReport(this PowerBIServiceState service,
                                                    String datasetId,
                                                    String filePath,
                                              String reportDisplayName,
                                              CancellationToken cancellationToken) =>
            await service.RestClient.UploadReport(service.BearerToken, service.GroupId, datasetId, filePath, reportDisplayName, cancellationToken);

        public static async Task RebindReport(this PowerBIServiceState service,
                                              Guid reportId,
                                              String datasetId,
                                              CancellationToken cancellationToken) =>
            await service.PowerBiClient.RebindReport(service.GroupId, reportId, datasetId, cancellationToken);

        public static async Task<String> CheckImportStatus(this PowerBIServiceState service,
                                                           String importId,
                                                           ImportedType importedType,
                                                           CancellationToken cancellationToken) =>
            await service.PowerBiClient.CheckImportStatus(service.GroupId,
                                                          importId,
                                                          service.FileImportCheckRetryAttempts,
                                                          service.FileImportCheckSleepIntervalInSeconds,
                                                          importedType,
                                                          cancellationToken);

        internal static async Task<String> CheckImportStatus(this IPowerBIClient powerBiClient, 
                                                            Guid groupId,
                                                            String importId,
                                                            Int32 fileImportCheckRetryAttempts,
                                                            Int32 fileImportCheckSleepIntervalInSeconds,
                                                            ImportedType importedType,
                                                            CancellationToken cancellationToken)
        {
            var importResponse = await powerBiClient.Imports.GetImportInGroupWithHttpMessagesAsync(groupId, Guid.Parse(importId), null, cancellationToken);
            for (Int32 i = 0; i < fileImportCheckRetryAttempts; i++)
            {
                if (importResponse.Body.ImportState == "Succeeded")
                {
                    break;
                }

                Thread.Sleep(TimeSpan.FromSeconds(fileImportCheckSleepIntervalInSeconds));
                importResponse = await powerBiClient.Imports.GetImportInGroupWithHttpMessagesAsync(groupId, Guid.Parse(importId), null, cancellationToken);
            }

            if (importResponse.Body.ImportState != "Succeeded")
            {
                throw new Exception($"Unable to verify import successful for {importedType} with import Id {importId}");
            }

            switch (importedType)
            {
                case ImportedType.Dataset:
                    Dataset datasetImport = importResponse.Body.Datasets.Single();
                    var dataset =
                        await powerBiClient.Datasets.GetDatasetInGroupWithHttpMessagesAsync(groupId, datasetImport.Id, cancellationToken: cancellationToken);

                    if (dataset.Body.IsRefreshable.HasValue && dataset.Body.IsRefreshable.Value)
                    {
                        // We think this is an import dataset so bomb out the release process
                        throw
                            new InvalidOperationException($"Possible Mixed Mode/Import dataset detected Dataset Name [{dataset.Body.Name}], please verify and update!!");
                    }

                    return dataset.Body.Id;
                case ImportedType.Report:
                    Report report = importResponse.Body.Reports.Single();
                    return report.Id.ToString();
                default:
                    return null;
            }
        }

        internal static async Task RebindReport(this IPowerBIClient powerBiClient, 
                                         Guid groupId,
                                         Guid reportId,
                                         String datasetId,
                                         CancellationToken cancellationToken)
        {
            RebindReportRequest rebindReportRequest = new RebindReportRequest(datasetId);

            await powerBiClient.Reports.RebindReportInGroupWithHttpMessagesAsync(groupId, reportId, rebindReportRequest, null, cancellationToken);
        }

        internal static async Task<Guid> UploadDataset(this IRestClient restClient,
                                                       String bearerToken,
                                                       Guid groupId,
                                              String filePath,
                                              String datasetDisplayName,
                                              CancellationToken cancellationToken)
        {
            String requestUri =
                $"{restClient.BaseUrl}/v1.0/myorg/groups/{groupId}/imports?dataSetDisplayName={datasetDisplayName}&nameConflict=CreateOrOverwrite&skipReport=True";
            RestRequest request = new RestRequest(new Uri(requestUri), Method.POST);
            request.AddHeader("Authorization", $"Bearer {bearerToken}");
            request.AddFile("file0", filePath, "application/x-zip-compressed");

            IRestResponse response = await restClient.ExecuteAsync(request, cancellationToken);

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

        internal static async Task<Guid> UploadReport(this IRestClient restClient,
                                                String bearerToken,
                                                Guid groupId,
                                                String datasetId,
                                                String filePath,
                                                String reportDisplayName,
                                                CancellationToken cancellationToken)
        {
            UpdateConnection(filePath, datasetId);

            // Manual method as cant use client :|
            String requestUri = $"{restClient.BaseUrl}/v1.0/myorg/groups/{groupId}/imports?dataSetDisplayName={reportDisplayName}&nameConflict=CreateOrOverwrite";

            RestRequest request = new RestRequest(new Uri(requestUri), Method.POST);
            request.AddHeader("Authorization", $"Bearer {bearerToken}");
            request.AddFile("file0", filePath, "application/x-zip-compressed");

            IRestResponse response = await restClient.ExecuteAsync(request, cancellationToken);

            if (response.IsSuccessful == false)
            {
                // throw an error
                throw new Exception($"Error uploading report [{filePath}], Http Response is [{response.Content}]");
            }

            var definition = new
                             {
                                 id = Guid.Empty
                             };

            // Get the report id from the reponse
            var responseDto = JsonConvert.DeserializeAnonymousType(response.Content, definition);

            return responseDto.id;
        }

        

        internal static async Task ChangeDatasetParameters(this IPowerBIClient powerBiClient,
                                                   Guid groupId,String datasetId,
                                                   Dictionary<String, String> parameters,
                                                   CancellationToken cancellationToken)
        {
            HttpOperationResponse<MashupParameters> datasetParameters =
                await powerBiClient.Datasets.GetParametersInGroupWithHttpMessagesAsync(groupId, datasetId, cancellationToken: cancellationToken);

            HttpOperationResponse<Dataset> dataset = await powerBiClient.Datasets.GetDatasetInGroupWithHttpMessagesAsync(groupId, datasetId, cancellationToken: cancellationToken);

            UpdateMashupParametersRequest request = CreateUpdateMashupParametersRequest(dataset.Body.Name, parameters, datasetParameters.Body);

            HttpOperationResponse response =
                await powerBiClient.Datasets.UpdateParametersInGroupWithHttpMessagesAsync(groupId, datasetId, request, cancellationToken: cancellationToken);

            if (response.Response.IsSuccessStatusCode == false)
            {
                throw new InvalidOperationException($"Error changing parameters on dataset [{dataset.Body.Name}].");
            }

            // Do a second check (ensure the value has been changed)
            HttpOperationResponse<MashupParameters> updatedDatasetParameters =
                await powerBiClient.Datasets.GetParametersInGroupWithHttpMessagesAsync(groupId, datasetId, cancellationToken: cancellationToken);

            // Do a belt an braces check on the parameter updates
            ValidateParameterUpdates(dataset.Body.Name, parameters, updatedDatasetParameters.Body);
            return;
        }

        internal static Dictionary<String, String> ValidateDatasetParameters(String datasetName,
                                                                           Dictionary<String, String> expectedParameters,
                                                                           List<String> actualDatasetParameters)
        {
            List<KeyValuePair<String, String>> missingParameters = expectedParameters.Where(p => actualDatasetParameters.Select(x => x).Contains(p.Key) == false).Select(m => m).ToList();

            if (missingParameters.Any())
            {
                // We have expected parameters missing from the dataset
                String joined = string.Join(",", missingParameters);

                throw new InvalidOperationException($"The following parameters [{joined}] are missing from DataSet [{datasetName}]");
            }

            return expectedParameters;
        }

        internal static UpdateMashupParameterDetails UpdateMashupParameterDetailsFactory(KeyValuePair<String, String> expectedParameter)
        {
            return new UpdateMashupParameterDetails(expectedParameter.Key, expectedParameter.Value);
        }

        internal static UpdateMashupParametersRequest CreateUpdateMashupParametersRequest(String datasetName,
                                                                                         Dictionary<String, String> expectedParameters,
                                                                                         MashupParameters actualDatasetParameters)
        {
            UpdateMashupParametersRequest state = new UpdateMashupParametersRequest()
                                                  {
                                                      UpdateDetails = new List<UpdateMashupParameterDetails>()
                                                  };

            return ValidateDatasetParameters(datasetName, expectedParameters, actualDatasetParameters.Value.Select(v => v.Name).ToList())
                .Select(UpdateMashupParameterDetailsFactory).ToList().Aggregate(state,
                                                                                               (request,
                                                                                                details) =>
                                                                                               {
                                                                                                   request.UpdateDetails.Add(details);
                                                                                                   return request;
                                                                                               });
        }

        internal static void ValidateParameterUpdates(String datasetName,
                                                    Dictionary<String, String> expectedParameters,
                                                    MashupParameters updatedDatasetParameters)
        {
            var parametersWithIncorrectValue = updatedDatasetParameters.Value.Select(e => e).Where(g => expectedParameters.Contains(new KeyValuePair<String, String>(g.Name, g.CurrentValue)) == false);
            var errors = parametersWithIncorrectValue.Select(g => $"Parameter Name {g.Name} has the incorrect value [{g.CurrentValue}]").ToList();

            if (errors.Any())
            {
                String joined = string.Join(",", errors);
                throw new InvalidOperationException($"The following errors occurred while updating the dataset [{datasetName}] Errors [{joined}]");
            }
        }

        internal static void UpdateConnection(String filepath,
                                            String datasetId)
        {
            using (ZipArchive archive = new ZipArchive(File.Open(filepath, FileMode.Open), ZipArchiveMode.Update, false, null))
            {
                ZipArchiveEntry entry = archive.GetEntry("Connections");
                String newstring;
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

        internal static async Task<List<Dataset>> GetDatasets(this IPowerBIClient powerBiClient,
                                                              Guid groupId,
                                                              CancellationToken cancellationToken)
        {
            HttpOperationResponse<Datasets> response = await powerBiClient.Datasets.GetDatasetsInGroupWithHttpMessagesAsync(groupId, null, cancellationToken);

            return response.Body.Value.ToList();
        }
    }
    
    public enum ImportedType
    {
        Dataset,

        Report
    }

    public class Connection
    {
        #region Properties

        public String ConnectionString { get; set; }

        public String ConnectionType { get; set; }

        public String Name { get; set; }

        public String PbiModelDatabaseName { get; set; }

        public String PbiModelVirtualServerName { get; set; }

        public Int32 PbiServiceModelId { get; set; }

        #endregion
    }

    public class PowerBiConnectionDetails
    {
        #region Properties

        public List<Connection> Connections { get; set; }

        public Int32 Version { get; set; }

        #endregion
    }
}