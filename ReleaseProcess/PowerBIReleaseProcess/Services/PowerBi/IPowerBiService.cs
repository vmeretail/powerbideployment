namespace PowerBIReleaseTool.Services.PowerBi
{
    using System;
    using System.Threading;
    using System.Threading.Tasks;

    public interface IPowerBiService
    {
        event EventHandler<String> TraceMessage;
        event EventHandler<String> SuccessMessage;
        event EventHandler<String> ErrorMessage;

        Task Initialise(String datasetOwner = "", String password = "");

        Task<Boolean> DeployDataset(PowerBiCustomerConfiguration customerConfiguration, String datasetFile, CancellationToken cancellationToken);

        Task<Boolean> DeployReport(PowerBiCustomerConfiguration customerConfiguration, String reportFile, CancellationToken cancellationToken);

        Task<String> GetCurrentDeployedVersionNumber(PowerBiCustomerConfiguration customerConfiguration,
                                                     CancellationToken cancellationToken);

        Task UpdateApplicationVersion(PowerBiCustomerConfiguration customerConfiguration,
                                      String newVersion,
                                      CancellationToken cancellationToken);
    }
}