using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace PowerBIReleaseTool
{
    public partial class MainForm : Form, IMainForm
    {
        private MainFormViewModel ViewModel;

        public MainForm()
        {
            InitializeComponent();
            write = (msg, color) => this.txtUpdateTrace.AppendText($"{msg}", color);
            writeNormal = (msg) => write(msg, Color.Black);
            writePositive = (msg) => write(msg, Color.Green);
            writeNegative = (msg) => write(msg, Color.Red);
        }

        public event EventHandler<String>? UpdateApplicationButtonClicked;

        public void Initialise(MainFormViewModel viewModel)
        {
            this.ViewModel = viewModel;
            this.lvAllCustomers.Items.Clear();
            this.btnUpdate.Enabled = true;
            this.cmbAvailableVersions.SelectedItem = 0;
            foreach (PowerBiCustomerConfiguration application in viewModel.PowerBiApplications)
            {
                this.lvAllCustomers.Items.Add(new ListViewItem(new String[] {application.Name, application.OrganisationId, application.CurrentVersion, application.DatasetOwner}));
            }
        }

        private Action<String, Color> write;
        public Action<String> writeNormal { get; set; }
        public Action<String> writePositive { get; set; }
        public Action<String> writeNegative { get; set; }

        public event EventHandler<String>? ApplicationSelected;

        public event EventHandler? FormLoaded;

        public void LoadApplicationDetails()
        {
            IOrderedEnumerable<String> sorted = this.ViewModel.AvailableVersions.OrderByDescending(x => x);
            this.cmbAvailableVersions.Items.Clear();
            foreach (String viewModelAvailableVersion in sorted)
            {
                this.cmbAvailableVersions.Items.Add(viewModelAvailableVersion);
            }
        }

        public void ShowUpdateOptions()
        {
            this.grpUpdateOptions.Visible = true;
            this.chkOverrideCredentials.Visible = true;
        }

        public void EnableUpdatePanel()
        {
            this.grpUpdateOptions.Enabled = true;
        }

        public void DisableUpdatePanel()
        {
            this.grpUpdateOptions.Enabled = false;
        }

        private void btnUpdate_Click(object sender,
                                     EventArgs e)
        {
            this.ViewModel.OverrideUser = this.txtOverideUserName.Text;
            this.ViewModel.OverridePassword = this.txtOveridePassword.Text;
            this.UpdateApplicationButtonClicked.Invoke(sender, this.cmbAvailableVersions.SelectedItem.ToString());
        }

        private void lvAllCustomers_SelectedIndexChanged(object sender,
                                               EventArgs e)
        {
            ListView listView = (ListView)sender;

            if (listView.SelectedItems.Count == 0)
                return;

            ListViewItem? selectedItem = listView.SelectedItems[0];
            this.writeNormal($"You have selected customer {selectedItem.Text}");
            this.ApplicationSelected.Invoke(sender, selectedItem.Text);
        }

        private void MainForm_Load(object sender, EventArgs e)
        {
            this.FormLoaded.Invoke(sender,e);
        }

        public event EventHandler<Boolean>? OverrideCredentialsChecked;

        private void chkOverrideCredentials_CheckedChanged(object sender, EventArgs e)
        {
            this.txtOverideUserName.Text = this.ViewModel.SelectedApplication.DatasetOwner;
            this.OverrideCredentialsChecked.Invoke(sender, this.chkOverrideCredentials.Checked);
        }

        public void ShowCredentialsOverride()
        {
            this.lblUserName.Visible = true;
            this.lblPassword.Visible = true;
            this.txtOverideUserName.Visible = true;
            this.txtOveridePassword.Visible = true;
        }

        public void HideCredentialsOverride()
        {
            this.lblUserName.Visible = false;
            this.lblPassword.Visible = false;
            this.txtOverideUserName.Visible = false;
            this.txtOveridePassword.Visible = false;
        }

        public void InitialiseProgressBar(Int32 maxValue)
        {
            this.progressBar1.Value = 0;
            this.progressBar1.Minimum = 0;
            this.progressBar1.Maximum = maxValue;
        }
        
        public void IncrementProgressBar()
        {
            this.progressBar1.Increment(1);
        }
    }

    public static class RichTextBoxExtensions
    {
        public static void AppendText(this RichTextBox box, string text, Color color)
        {
            box.SelectionStart = box.TextLength;
            box.SelectionLength = 0;

            box.SelectionColor = color;
            box.AppendText(text);
            box.AppendText(Environment.NewLine);
            box.SelectionColor = box.ForeColor;
            box.ScrollToCaret();
        }
    }
}
