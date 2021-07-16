using System;
using Xunit;

namespace PowerBiReleaseProcessUnitTests
{
    using System.Collections.Generic;
    using System.Net;
    using System.Net.Http;
    using System.Threading;
    using System.Threading.Tasks;
    using Castle.Components.DictionaryAdapter;
    using Microsoft.PowerBI.Api;
    using Microsoft.PowerBI.Api.Models;
    using Microsoft.Rest;
    using Moq;
    using PowerBIReleaseProcess;
    using RestSharp;
    using Shouldly;

    public class PowerBIServiceStateTests
    {
        private PowerBIServiceState GetPowerBiServiceState(Mock<IPowerBIClient> powerBiClient,
                                                           Mock<IRestClient> restClient)
        {
            Int32 fileImportCheckRetryAttempts = 1;
            Int32 fileImportCheckSleepIntervalInSeconds = 1;
            String bearerToken = "Token";
            Guid groupId = Guid.Parse("5FAD0449-F693-4F14-8595-195B68231E96");

            PowerBIServiceState p = new PowerBIServiceState(fileImportCheckRetryAttempts,
                                                            fileImportCheckSleepIntervalInSeconds,
                                                            powerBiClient.Object,
                                                            restClient.Object,
                                                            bearerToken,
                                                            groupId);

            return p;
        }

        [Fact]
        public async Task PowerBIServiceState_GetDataSets_DatasetsReturned()
        {
            Mock<IPowerBIClient> powerBiClient = new Mock<IPowerBIClient>();
            Mock<IRestClient> restClient = new Mock<IRestClient>();

            PowerBIServiceState p = GetPowerBiServiceState(powerBiClient, restClient);

            HttpOperationResponse<Datasets> httpOperationResponse = new HttpOperationResponse<Datasets>();
            httpOperationResponse.Body = new Datasets
                                         {
                                             Value = new List<Dataset>
                                                     {
                                                         new Dataset()
                                                     }
                                         };

            powerBiClient.Setup(p => p.Datasets.GetDatasetsInGroupWithHttpMessagesAsync(It.IsAny<Guid>(),
                                                                                        It.IsAny<Dictionary<String, List<String>>>(),
                                                                                        It.IsAny<CancellationToken>())).ReturnsAsync(httpOperationResponse);


            var datasets = await p.GetDatasets(CancellationToken.None);
            
            datasets.Count.ShouldBe(httpOperationResponse.Body.Value.Count);
        }
        
        [Fact]
        public async Task PowerBiServiceState_RebindReport_ReportIsRebound()
        {
            Mock<IPowerBIClient> powerBiClient = new Mock<IPowerBIClient>();
            Mock<IRestClient> restClient = new Mock<IRestClient>();

            HttpOperationResponse response = new HttpOperationResponse();
            
            powerBiClient.Setup(p => p.Reports.RebindReportInGroupWithHttpMessagesAsync(It.IsAny<Guid>(),
                                                                                        It.IsAny<Guid>(),
                                                                                        It.IsAny<RebindReportRequest>(),
                                                                                        It.IsAny<Dictionary<String, List<String>>>(),
                                                                                        It.IsAny<CancellationToken>())).ReturnsAsync(response);

            PowerBIServiceState p = GetPowerBiServiceState(powerBiClient, restClient);
            
            Guid reportId = Guid.Parse("94661DA3-B0D7-4246-809A-60255BF9B7D6");
            String datasetId = "3586788B-430E-40A5-AE64-7CF62F76F98E";

            Should.NotThrow(async () =>
                            {
                                await p.RebindReport(reportId, datasetId, CancellationToken.None);
                            });
        }
        
        [Fact]
        public async Task PowerBiServiceState_ChangeDatasetParameters_ParametersChanged()
        {
            Mock<IPowerBIClient> powerBiClient = new Mock<IPowerBIClient>();
            Mock<IRestClient> restClient = new Mock<IRestClient>();

            HttpOperationResponse<MashupParameters> getParametersInGroupResponse = new HttpOperationResponse<MashupParameters>();
            getParametersInGroupResponse.Body = new MashupParameters();
            getParametersInGroupResponse.Body.Value = new List<MashupParameter>
                                                      {
                                                          new MashupParameter("Parameter1", "Text", false, null),
                                                          new MashupParameter("Parameter2", "Text", false, null)
                                                      };

            HttpOperationResponse<MashupParameters> getUpdatedParametersInGroupResponse = new HttpOperationResponse<MashupParameters>();
            getUpdatedParametersInGroupResponse.Body = new MashupParameters();
            getUpdatedParametersInGroupResponse.Body.Value = new List<MashupParameter>
                                                             {
                                                                 new MashupParameter("Parameter1", "Text", false, "Value1"),
                                                                 new MashupParameter("Parameter2", "Text", false, "Value2")
                                                             };
            HttpOperationResponse<Dataset> getDatasetInGroupResponse = new HttpOperationResponse<Dataset>();
            getDatasetInGroupResponse.Body = new Dataset();

            HttpOperationResponse updateParametersInGroupResponse = new HttpOperationResponse();
            updateParametersInGroupResponse.Response = new HttpResponseMessage(HttpStatusCode.OK);

            powerBiClient.SetupSequence(p => p.Datasets.GetParametersInGroupWithHttpMessagesAsync(It.IsAny<Guid>(),
                                                                                          It.IsAny<String>(),
                                                                                          It.IsAny<Dictionary<String, List<String>>>(),
                                                                                          It.IsAny<CancellationToken>()))
                         .ReturnsAsync(getParametersInGroupResponse)
                         .ReturnsAsync(getUpdatedParametersInGroupResponse);

            powerBiClient.Setup(p => p.Datasets.GetDatasetInGroupWithHttpMessagesAsync(It.IsAny<Guid>(),
                                                                                       It.IsAny<String>(),
                                                                                       It.IsAny<Dictionary<String, List<String>>>(),
                                                                                       It.IsAny<CancellationToken>()))
                         .ReturnsAsync(getDatasetInGroupResponse);

            powerBiClient.Setup(p => p.Datasets.UpdateParametersInGroupWithHttpMessagesAsync(It.IsAny<Guid>(),
                                                                                             It.IsAny<String>(),
                                                                                             It.IsAny<UpdateMashupParametersRequest>(),
                                                                                             It.IsAny<Dictionary<String, List<String>>>(),
                                                                                             It.IsAny<CancellationToken>()))
                         .ReturnsAsync(updateParametersInGroupResponse);

            PowerBIServiceState p = GetPowerBiServiceState(powerBiClient, restClient);
            String datasetId = "60D205C9-2F19-4ED7-AB00-77033789B623";
            Dictionary<String, String> parameters = new Dictionary<String, String>();
            parameters.Add("Parameter1", "Value1");
            parameters.Add("Parameter2", "Value2");

            Should.NotThrow(async () =>
                            {
                                await p.ChangeDatasetParameters(datasetId, parameters, CancellationToken.None);
                            });

        }
    }
}
