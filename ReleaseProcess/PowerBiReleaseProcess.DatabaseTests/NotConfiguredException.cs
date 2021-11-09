namespace PowerBiReleaseProcess.DatabaseTests
{
    using System;

    /// <summary>
    /// Thrown when a mandatory configuration value is not found when in fact it must be set
    /// </summary>
    public class NotConfiguredException : Exception
    {
        #region Constructors

        /// <summary>
        /// Initializes a new instance of the <see cref="NotConfiguredException"/> class.
        /// </summary>
        /// <param name="message">The message that describes the error.</param>
        public NotConfiguredException(String message) : base(message)
        {
        }

        #endregion
    }
}