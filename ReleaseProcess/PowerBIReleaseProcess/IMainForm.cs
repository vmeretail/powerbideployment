namespace PowerBIReleaseTool
{
    using System;

    public interface IMainForm : IForm
    {
        #region Events

        event EventHandler<String> ApplicationSelected;

        event EventHandler FormLoaded;

        event EventHandler<String> UpdateApplicationButtonClicked;

        event EventHandler<Boolean>? OverrideCredentialsChecked;

        #endregion

        #region Methods

        void Initialise(MainFormViewModel viewModel);

        void LoadApplicationDetails();

        void EnableUpdatePanel();

        void DisableUpdatePanel();

        void ShowUpdateOptions();

        void ShowCredentialsOverride();

        void HideCredentialsOverride();

        void InitialiseProgressBar(Int32 maxValue);

        void IncrementProgressBar();
        
        #endregion
    }
}