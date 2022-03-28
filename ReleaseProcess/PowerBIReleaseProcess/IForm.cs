namespace PowerBIReleaseTool
{
    using System;

    public interface IForm
    {
        #region Properties

        Action<String> writeNegative { get; set; }

        Action<String> writeNormal { get; set; }

        Action<String> writePositive { get; set; }

        #endregion
    }
}