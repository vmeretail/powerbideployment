namespace PowerBIReleaseProcess
{
    using System;
    using System.Collections.Generic;
    using System.Threading;
    using System.Threading.Tasks;
    using Microsoft.PowerBI.Api.Models;

    /// <summary>
    /// 
    /// </summary>
    public interface IPowerBIService
    {
        #region Methods

        ///// <summary>
        ///// Changes the dataset parameters.
        ///// </summary>
        ///// <param name="groupId">The group identifier.</param>
        ///// <param name="datasetId">The dataset identifier.</param>
        ///// <param name="cancellationToken">The cancellation token.</param>
        ///// <returns></returns>
        Task ChangeDatasetParameters(Guid groupId,
                                     String datasetId,
                                     Dictionary<String, String> parameters,
                                     CancellationToken cancellationToken);

        /// <summary>
        /// Checks the import status.
        /// </summary>
        /// <param name="groupId">The group identifier.</param>
        /// <param name="importId">The import identifier.</param>
        /// <param name="importType">Type of the import.</param>
        /// <param name="cancellationToken">The cancellation token.</param>
        /// <returns></returns>
        Task<String> CheckImportStatus(Guid groupId,
                                       String importId,
                                       ImportedType importType,
                                       CancellationToken cancellationToken);

        /// <summary>
        /// Gets the data sets.
        /// </summary>
        /// <param name="groupId">The group identifier.</param>
        /// <param name="cancellationToken">The cancellation token.</param>
        /// <returns></returns>
        Task<List<Dataset>> GetDataSets(Guid groupId,
                                        CancellationToken cancellationToken);

        Task RebindReport(Guid groupId,
                          Guid reportId,
                          String datasetId,
                          CancellationToken cancellationToken);

        /// <summary>
        /// Uploads the dataset.
        /// </summary>
        /// <param name="groupId">The group identifier.</param>
        /// <param name="filePath">The file path.</param>
        /// <param name="datasetDisplayName">Display name of the dataset.</param>
        /// <param name="cancellationToken">The cancellation token.</param>
        /// <returns></returns>
        Task<Guid> UploadDataset(Guid groupId,
                                 String filePath,
                                 String datasetDisplayName,
                                 CancellationToken cancellationToken);

        /// <summary>
        /// Uploads the report.
        /// </summary>
        /// <param name="groupId">The group identifier.</param>
        /// <param name="filePath">The file path.</param>
        /// <param name="reportDisplayName">Display name of the report.</param>
        /// <param name="cancellationToken">The cancellation token.</param>
        /// <returns></returns>
        Task<Guid> UploadReport(Guid groupId,
                                String filePath,
                                String reportDisplayName,
                                String datasetId,
                                CancellationToken cancellationToken);

        #endregion
    }
}