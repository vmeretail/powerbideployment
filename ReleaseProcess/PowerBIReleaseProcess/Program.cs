using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace PowerBIReleaseTool
{
    using Microsoft.Extensions.DependencyInjection;
    using Microsoft.Extensions.Logging;
    using NLog;
    using NLog.Config;
    using NLog.Extensions.Logging;
    using System.Diagnostics;
    using System.IO;
    using System.IO.Abstractions;
    using System.Reflection;
    using System.Threading;
    using Microsoft.Extensions.Configuration;
    using Microsoft.Extensions.Hosting;
    using Services;
    using Services.Database;
    using Services.PowerBi;
    using Vme.Configuration;
    using Vme.Logging;
    using Logger = Vme.Logging.Logger;

    internal class Program
    {
        /// <summary>
        /// The services
        /// </summary>
        public static IServiceProvider Services;

        /// <summary>
        ///  The main entry point for the application.
        /// </summary>
        [STAThread]
        static async Task Main()
        {
            CancellationToken cancellationToken = new CancellationToken();

            Application.SetHighDpiMode(HighDpiMode.SystemAware);
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            IHostBuilder builder = Host.CreateDefaultBuilder().ConfigureServices((hostContext,
                                                                                  services) =>
                                                                                 {
                                                                                     Program.SetupConfiguration();
                                                                                     Program.SetupLogging(services);
                                                                                     Program.ConfigureServices(services);
                                                                                 });

            IHost host = builder.Build();

            using (IServiceScope serviceScope = host.Services.CreateScope())
            {
                IServiceProvider services = serviceScope.ServiceProvider;
                try
                {
                    Program.Services = services;
                    
                    IPresenter presenter = services.GetRequiredService<IPresenter>();
                    await presenter.Start(cancellationToken);
                }
                catch (Exception ex)
                {
                    Logger.WriteToLog($"Error creating scope\n{ex.Message}", LoggerCategory.General, TraceEventType.Error);

                    MessageBox.Show(ex.Message, @"Unhandled Exception", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private static void ConfigureServices(IServiceCollection services)
        {
            services.AddSingleton<IMainForm, MainForm>();
            services.AddTransient<MainFormViewModel>();
            services.AddSingleton<IPresenter, Presenter>();
            services.AddSingleton<IGitHubService, GitHubService>();
            //services.AddSingleton<IReleaseProcess, ReleaseProcess>();
            services.AddSingleton<IDatabaseManager, DatabaseManager>();
            services.AddSingleton<IFileSystem, FileSystem>();
            services.AddSingleton<IPowerBiService, PowerBiService>();
            services.AddSingleton<ITokenService, TokenService>();
        }

        public static void SetupConfiguration()
        {
            String path = Assembly.GetExecutingAssembly().Location;
            path = Path.GetDirectoryName(path);
            String localAppsettingsFolder = !String.IsNullOrWhiteSpace(path) ? Path.Combine(path, "..") : String.Empty;

            IConfigurationBuilder builder = new ConfigurationBuilder();
            var a = Directory.GetCurrentDirectory();
            builder.SetBasePath(Directory.GetCurrentDirectory());
            // TODO: Include development files
            builder.AddJsonFile("appsettings.json", true);
            builder.AddJsonFile("appsettings.powerbi.json", true);

            Program.Configuration = builder.Build();

            ConfigurationReader.Initialise(Program.Configuration);
        }

        /// <summary>
        /// The configuration
        /// </summary>
        public static IConfigurationRoot Configuration;

        /// <summary>
        /// Setups the logging.
        /// </summary>
        /// <param name="services">The services.</param>
        private static void SetupLogging(IServiceCollection services)
        {
            services.AddLogging();
            ILoggerFactory loggerFactory = services.BuildServiceProvider()
                                                   .GetRequiredService<ILoggerFactory>();

            loggerFactory.AddNLog();

            LogManager.Configuration = new XmlLoggingConfiguration("nlog.config", true);

            //Logger needs initialised.
            Logger.Initialise(loggerFactory.CreateLogger<Program>());
        }
    }
}

