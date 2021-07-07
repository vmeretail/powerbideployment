namespace PowerBIReleaseProcess
{
    using System;

    /// <summary>
    /// 
    /// </summary>
    public class ReleaseProfile
    {
        /// <summary>
        /// Gets or sets the identifier.
        /// </summary>
        /// <value>
        /// The identifier.
        /// </value>
        public Int32 Id { get; set; }
        /// <summary>
        /// Gets or sets the name.
        /// </summary>
        /// <value>
        /// The name.
        /// </value>
        public String Name { get; set; }

        /// <summary>
        /// Gets or sets the organisation identifier.
        /// </summary>
        /// <value>
        /// The organisation identifier.
        /// </value>
        public Guid OrganisationId { get; set; }

        /// <summary>
        /// Gets or sets the group identifier.
        /// </summary>
        /// <value>
        /// The group identifier.
        /// </value>
        public Guid GroupId { get; set; }

        /// <summary>
        /// Gets or sets the release folder.
        /// </summary>
        /// <value>
        /// The release folder.
        /// </value>
        public String ReleaseFolder { get; set; }

        /// <summary>
        /// Gets the name of the read model database.
        /// </summary>
        /// <value>
        /// The name of the read model database.
        /// </value>
        public String ReadModelDatabaseName => $"OrganisationRead{this.OrganisationId}";

        public String ReadModelDatabaseSever {get;set;}
    }
}