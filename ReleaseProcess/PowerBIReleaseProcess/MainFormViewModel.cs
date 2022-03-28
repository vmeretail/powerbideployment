namespace PowerBIReleaseTool
{
    using System;
    using System.Collections.Generic;

    public class MainFormViewModel
    {
        #region Constructors

        public MainFormViewModel()
        {
            this.PowerBiApplications = new List<PowerBiCustomerConfiguration>();
        }

        #endregion

        #region Properties

        public List<String> AvailableVersions { get; set; }

        public List<PowerBiCustomerConfiguration> PowerBiApplications { get; set; }

        public PowerBiCustomerConfiguration SelectedApplication { get; set; }

        public String OverrideUser { get; set; }
        public String OverridePassword { get; set; }

        #endregion
    }
}