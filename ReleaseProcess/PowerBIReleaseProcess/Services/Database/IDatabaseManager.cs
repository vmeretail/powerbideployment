using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PowerBIReleaseTool.Services.Database
{
    using System.Threading;

    public interface IDatabaseManager
    {
        Task ExecuteScript(String connectionString, String sqlFilePath, CancellationToken cancellationToken);
    }
}
