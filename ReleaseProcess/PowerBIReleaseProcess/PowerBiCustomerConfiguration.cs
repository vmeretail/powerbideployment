namespace PowerBIReleaseTool
{
    using System;

    public class PowerBiCustomerConfiguration
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
        public String OrganisationId { get; set; }

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

        public String DatasetOwner { get; set; }

        /// <summary>
        /// Gets the name of the read model database.
        /// </summary>
        /// <value>
        /// The name of the read model database.
        /// </value>
        public String ReadModelDatabaseName => $"OrganisationRead{this.OrganisationId}";

        public String ReadModelDatabaseSever { get; set; }

        /// <summary>
        /// Gets or sets the user id.
        /// </summary>
        /// <value>
        /// The user id.
        /// </value>
        public String UserId { get; set; }

        /// <summary>
        /// Gets or sets the Password.
        /// </summary>
        /// <value>
        /// The password.
        /// </value>
        public String Password { get; set; }

        /// <summary>
        /// Gets or sets the connection string.
        /// </summary>
        /// <value>
        /// The connection string.
        /// </value>
        public String ConnectionString => $"Data Source={this.ReadModelDatabaseSever};Initial Catalog={this.ReadModelDatabaseName};User ID={this.UserId};Password={this.Password}";

        public override String ToString()
        {
            return this.Name;
        }

        public String CurrentVersion { get; set; }

        public Boolean DemoApplication { get; set; }
    }
}