namespace PowerBIReleaseTool
{
    partial class MainForm
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.lvAllCustomers = new System.Windows.Forms.ListView();
            this.Customer = new System.Windows.Forms.ColumnHeader();
            this.OrganisationId = new System.Windows.Forms.ColumnHeader();
            this.CurrentVersion = new System.Windows.Forms.ColumnHeader();
            this.DatasetOwner = new System.Windows.Forms.ColumnHeader();
            this.txtUpdateTrace = new System.Windows.Forms.RichTextBox();
            this.grpUpdateOptions = new System.Windows.Forms.GroupBox();
            this.lblPassword = new System.Windows.Forms.Label();
            this.lblUserName = new System.Windows.Forms.Label();
            this.txtOveridePassword = new System.Windows.Forms.TextBox();
            this.txtOverideUserName = new System.Windows.Forms.TextBox();
            this.chkOverrideCredentials = new System.Windows.Forms.CheckBox();
            this.lblVersionUpdate = new System.Windows.Forms.Label();
            this.btnUpdate = new System.Windows.Forms.Button();
            this.cmbAvailableVersions = new System.Windows.Forms.ComboBox();
            this.progressBar1 = new System.Windows.Forms.ProgressBar();
            this.grpUpdateOptions.SuspendLayout();
            this.SuspendLayout();
            // 
            // lvAllCustomers
            // 
            this.lvAllCustomers.Columns.AddRange(new System.Windows.Forms.ColumnHeader[] {
            this.Customer,
            this.OrganisationId,
            this.CurrentVersion,
            this.DatasetOwner});
            this.lvAllCustomers.FullRowSelect = true;
            this.lvAllCustomers.HideSelection = false;
            this.lvAllCustomers.Location = new System.Drawing.Point(12, 12);
            this.lvAllCustomers.MultiSelect = false;
            this.lvAllCustomers.Name = "lvAllCustomers";
            this.lvAllCustomers.Size = new System.Drawing.Size(690, 133);
            this.lvAllCustomers.TabIndex = 9;
            this.lvAllCustomers.UseCompatibleStateImageBehavior = false;
            this.lvAllCustomers.View = System.Windows.Forms.View.Details;
            this.lvAllCustomers.SelectedIndexChanged += new System.EventHandler(this.lvAllCustomers_SelectedIndexChanged);
            // 
            // Customer
            // 
            this.Customer.Text = "Customer";
            this.Customer.Width = 150;
            // 
            // OrganisationId
            // 
            this.OrganisationId.Text = "Organisation Id";
            this.OrganisationId.Width = 240;
            // 
            // CurrentVersion
            // 
            this.CurrentVersion.Text = "Current Version";
            this.CurrentVersion.Width = 100;
            // 
            // DatasetOwner
            // 
            this.DatasetOwner.Text = "Dataset Owner";
            this.DatasetOwner.Width = 180;
            // 
            // txtUpdateTrace
            // 
            this.txtUpdateTrace.Location = new System.Drawing.Point(12, 173);
            this.txtUpdateTrace.Name = "txtUpdateTrace";
            this.txtUpdateTrace.Size = new System.Drawing.Size(1137, 265);
            this.txtUpdateTrace.TabIndex = 10;
            this.txtUpdateTrace.Text = "";
            // 
            // grpUpdateOptions
            // 
            this.grpUpdateOptions.Controls.Add(this.lblPassword);
            this.grpUpdateOptions.Controls.Add(this.lblUserName);
            this.grpUpdateOptions.Controls.Add(this.txtOveridePassword);
            this.grpUpdateOptions.Controls.Add(this.txtOverideUserName);
            this.grpUpdateOptions.Controls.Add(this.chkOverrideCredentials);
            this.grpUpdateOptions.Controls.Add(this.lblVersionUpdate);
            this.grpUpdateOptions.Controls.Add(this.btnUpdate);
            this.grpUpdateOptions.Controls.Add(this.cmbAvailableVersions);
            this.grpUpdateOptions.Location = new System.Drawing.Point(717, 12);
            this.grpUpdateOptions.Name = "grpUpdateOptions";
            this.grpUpdateOptions.Size = new System.Drawing.Size(432, 133);
            this.grpUpdateOptions.TabIndex = 11;
            this.grpUpdateOptions.TabStop = false;
            this.grpUpdateOptions.Text = "Update Options";
            this.grpUpdateOptions.Visible = false;
            // 
            // lblPassword
            // 
            this.lblPassword.AutoSize = true;
            this.lblPassword.Location = new System.Drawing.Point(182, 83);
            this.lblPassword.Name = "lblPassword";
            this.lblPassword.Size = new System.Drawing.Size(57, 15);
            this.lblPassword.TabIndex = 19;
            this.lblPassword.Text = "Password";
            this.lblPassword.Visible = false;
            // 
            // lblUserName
            // 
            this.lblUserName.AutoSize = true;
            this.lblUserName.Location = new System.Drawing.Point(182, 57);
            this.lblUserName.Name = "lblUserName";
            this.lblUserName.Size = new System.Drawing.Size(60, 15);
            this.lblUserName.TabIndex = 18;
            this.lblUserName.Text = "Username";
            this.lblUserName.Visible = false;
            // 
            // txtOveridePassword
            // 
            this.txtOveridePassword.Location = new System.Drawing.Point(248, 84);
            this.txtOveridePassword.Name = "txtOveridePassword";
            this.txtOveridePassword.Size = new System.Drawing.Size(157, 23);
            this.txtOveridePassword.TabIndex = 17;
            this.txtOveridePassword.UseSystemPasswordChar = true;
            this.txtOveridePassword.Visible = false;
            // 
            // txtOverideUserName
            // 
            this.txtOverideUserName.Location = new System.Drawing.Point(248, 55);
            this.txtOverideUserName.Name = "txtOverideUserName";
            this.txtOverideUserName.Size = new System.Drawing.Size(157, 23);
            this.txtOverideUserName.TabIndex = 16;
            this.txtOverideUserName.Visible = false;
            // 
            // chkOverrideCredentials
            // 
            this.chkOverrideCredentials.AutoSize = true;
            this.chkOverrideCredentials.Location = new System.Drawing.Point(182, 30);
            this.chkOverrideCredentials.Name = "chkOverrideCredentials";
            this.chkOverrideCredentials.Size = new System.Drawing.Size(133, 19);
            this.chkOverrideCredentials.TabIndex = 15;
            this.chkOverrideCredentials.Text = "Override Credentials";
            this.chkOverrideCredentials.UseVisualStyleBackColor = true;
            this.chkOverrideCredentials.Visible = false;
            this.chkOverrideCredentials.CheckedChanged += new System.EventHandler(this.chkOverrideCredentials_CheckedChanged);
            // 
            // lblVersionUpdate
            // 
            this.lblVersionUpdate.AutoSize = true;
            this.lblVersionUpdate.Location = new System.Drawing.Point(18, 31);
            this.lblVersionUpdate.Name = "lblVersionUpdate";
            this.lblVersionUpdate.Size = new System.Drawing.Size(149, 15);
            this.lblVersionUpdate.TabIndex = 13;
            this.lblVersionUpdate.Text = "Select Version to Update To";
            // 
            // btnUpdate
            // 
            this.btnUpdate.Location = new System.Drawing.Point(18, 83);
            this.btnUpdate.Name = "btnUpdate";
            this.btnUpdate.Size = new System.Drawing.Size(146, 44);
            this.btnUpdate.TabIndex = 12;
            this.btnUpdate.Text = "Update Application";
            this.btnUpdate.UseVisualStyleBackColor = true;
            this.btnUpdate.Click += new System.EventHandler(this.btnUpdate_Click);
            // 
            // cmbAvailableVersions
            // 
            this.cmbAvailableVersions.FormattingEnabled = true;
            this.cmbAvailableVersions.Location = new System.Drawing.Point(18, 54);
            this.cmbAvailableVersions.Name = "cmbAvailableVersions";
            this.cmbAvailableVersions.Size = new System.Drawing.Size(121, 23);
            this.cmbAvailableVersions.TabIndex = 11;
            // 
            // progressBar1
            // 
            this.progressBar1.Location = new System.Drawing.Point(12, 457);
            this.progressBar1.Name = "progressBar1";
            this.progressBar1.Size = new System.Drawing.Size(1137, 37);
            this.progressBar1.TabIndex = 12;
            // 
            // MainForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(7F, 15F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1178, 506);
            this.Controls.Add(this.progressBar1);
            this.Controls.Add(this.grpUpdateOptions);
            this.Controls.Add(this.txtUpdateTrace);
            this.Controls.Add(this.lvAllCustomers);
            this.Name = "MainForm";
            this.Text = "MainForm";
            this.Load += new System.EventHandler(this.MainForm_Load);
            this.grpUpdateOptions.ResumeLayout(false);
            this.grpUpdateOptions.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion
        private System.Windows.Forms.ListView lvAllCustomers;
        private System.Windows.Forms.ColumnHeader Customer;
        private System.Windows.Forms.ColumnHeader OrganisationId;
        private System.Windows.Forms.ColumnHeader CurrentVersion;
        private System.Windows.Forms.RichTextBox txtUpdateTrace;
        private System.Windows.Forms.GroupBox grpUpdateOptions;
        private System.Windows.Forms.Label lblVersionUpdate;
        private System.Windows.Forms.Button btnUpdate;
        private System.Windows.Forms.ComboBox cmbAvailableVersions;
        private System.Windows.Forms.ColumnHeader DatasetOwner;
        private System.Windows.Forms.TextBox txtOveridePassword;
        private System.Windows.Forms.TextBox txtOverideUserName;
        private System.Windows.Forms.CheckBox chkOverrideCredentials;
        private System.Windows.Forms.Label lblPassword;
        private System.Windows.Forms.Label lblUserName;
        private System.Windows.Forms.ProgressBar progressBar1;
    }
}