namespace PowerBiReleaseProcess.DatabaseTests
{
    using System;
    using Microsoft.Extensions.Configuration;

    public static class ConfigurationReader
    {
        #region Fields

        /// <summary>
        /// The configuration root
        /// </summary>
        private static IConfigurationRoot ConfigurationRoot;

        #endregion

        #region Properties

        /// <summary>
        /// Gets or sets a value indicating whether this instance is initialised.
        /// </summary>
        /// <value>
        /// <c>true</c> if this instance is initialised; otherwise, <c>false</c>.
        /// </value>
        public static Boolean IsInitialised { get; private set; }

        #endregion

        #region Methods

        /// <summary>
        /// Gets the base server URI.
        /// </summary>
        /// <param name="endpointName">Name of the endpoint.</param>
        /// <returns></returns>
        public static Uri GetBaseServerUri(String endpointName)
        {
            // Key name is always {BoundedContextName}Server
            String keyName = $"{endpointName}{ConfigurationReader.HostKeySuffix}";

            UriBuilder uriBuilder = new UriBuilder(ConfigurationReader.ConfigurationRoot.GetSection("AppSettings")[keyName]);

            // Ensure that even if a path is supplied that it is trimmed
            if (uriBuilder.Path.Contains("/api"))
            {
                uriBuilder.Path = uriBuilder.Path.Substring(0, uriBuilder.Path.IndexOf("/api", StringComparison.Ordinal));
            }

            return uriBuilder.Uri;
        }

        /// <summary>
        /// Gets the connection string.
        /// </summary>
        /// <param name="keyName">Name of the key.</param>
        /// <returns>String.</returns>
        public static String GetConnectionString(String keyName)
        {
            return ConfigurationReader.GetValueFromSection(ConfigurationReader.ConnectionStrings, keyName);
        }

        /// <summary>
        /// Gets the connection string or default.
        /// </summary>
        /// <param name="keyName">Name of the key.</param>
        /// <param name="defaultValue">The default value.</param>
        /// <returns></returns>
        public static String GetConnectionStringOrDefault(String keyName,
                                                          String defaultValue = null)
        {
            try
            {
                return ConfigurationReader.GetValueFromSection(ConfigurationReader.ConnectionStrings, keyName);
            }
            catch(NotConfiguredException)
            {
                return defaultValue;
            }
        }

        /// <summary>
        /// Gets the value.
        /// </summary>
        /// <param name="keyName">Name of the key.</param>
        /// <returns>String.</returns>
        public static String GetValue(String keyName)
        {
            return ConfigurationReader.GetValueFromSection(ConfigurationReader.AppSettings, keyName);
        }

        /// <summary>
        /// Gets the value or default.
        /// </summary>
        /// <param name="keyName">Name of the key.</param>
        /// <param name="defaultValue">The default value.</param>
        /// <returns></returns>
        public static String GetValueOrDefault(String keyName,
                                               String defaultValue = null)
        {
            try
            {
                return ConfigurationReader.GetValueFromSection(ConfigurationReader.AppSettings, keyName);
            }
            catch(NotConfiguredException)
            {
                return defaultValue;
            }
        }

        /// <summary>
        /// Initialises the specified configuration root.
        /// </summary>
        /// <param name="configurationRoot">The configuration root.</param>
        public static void Initialise(IConfigurationRoot configurationRoot)
        {
            if (configurationRoot != null)
            {
                ConfigurationReader.ConfigurationRoot = configurationRoot;
                ConfigurationReader.IsInitialised = true;

                return;
            }

            ConfigurationReader.ConfigurationRoot = null;
            ConfigurationReader.IsInitialised = false;
        }

        /// <summary>
        /// Gets the value from section.
        /// </summary>
        /// <param name="sectionName">Name of the section.</param>
        /// <param name="keyName">Name of the key.</param>
        /// <returns></returns>
        /// <exception cref="NotConfiguredException">No configuration value was found for key [{keyName}]</exception>
        private static String GetValueFromSection(String sectionName,
                                                  String keyName)
        {
            ConfigurationReader.GuardAgainstNoConfigurationReader();

            IConfigurationSection section = ConfigurationReader.ConfigurationRoot.GetSection(sectionName);

            if (section != null)
            {
                //Check we have a key matching the keyName
                if (section[keyName] == null)
                {
                    throw new NotConfiguredException($"No configuration value was found for key [{sectionName}:{keyName}]");
                }

                return section[keyName];
            }

            throw new NotConfiguredException($"Section [{sectionName}] not found.");
        }

        /// <summary>
        /// Guards the against no configuration reader.
        /// </summary>
        private static void GuardAgainstNoConfigurationReader()
        {
            if (ConfigurationReader.ConfigurationRoot == null)
            {
                throw new InvalidOperationException("ConfigurationRoot has not been set");
            }
        }

        #endregion

        #region Others

        /// <summary>
        /// The application settings
        /// </summary>
        private const String AppSettings = "AppSettings";

        /// <summary>
        /// The connection strings
        /// </summary>
        private const String ConnectionStrings = "ConnectionStrings";

        /// <summary>
        /// The suffix attached to bounded context names in order to identify the host
        /// </summary>
        private const String HostKeySuffix = "Server";

        #endregion
    }
}