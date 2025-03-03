# GCP Terraria Server Terraform Module

This Terraform module deploys a Terraria server on Google Cloud Platform (GCP). It creates a compute instance with a public IP address, installs the Terraria server software (from here: https://terraria.org/), and configures it to run as a systemd (https://systemd.io/) service.

Run Terraform Init, Plan, Apply and you'll be ready to go! The startup script will install and start the server. I wrote the startup script with the help of my assistent (Claude 3.7) and it includes some handy debugging mechanisms. 

After the Terraform Apply completes you will recieve as output the IP address of your new world. 

I would reccomend that once you have tested and confirmed that it works you go back and change the firewall rules to create an allow list. In fact, before you deploy I would reccomend whitelisting only your own IP address. If you do leave it open to all, be mindful of the kinds of things you do with the server.  

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 or newer)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (gcloud CLI)
- A GCP account with a project and billing enabled
- Appropriate permissions on your GCP account (Compute Admin role or equivalent is sufficient)

## Setup

1. Clone or download this repository
2. Create a `terraform.tfvars` file based on the provided example:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
3. Edit `terraform.tfvars` and set your GCP project ID and any other desired settings
4. Authenticate with GCP using your user account:
   ```bash
   gcloud auth application-default login
   ```
   This will open a browser window for you to log in with your Google account (you'll want to be logged in on the browser).
   The credentials will be saved locally for Terraform to use.
5. Initialize Terraform:
   ```bash
   terraform init
   ```

## Deployment

1. Preview the changes:
   ```bash
   terraform plan --out=tfplan
   ```
2. Apply the changes to create the infrastructure:
   ```bash
   terraform apply "tfplan"
   ```
3. `yes`
4. Wait for the deployment to complete (about 5 min)
5. You'll see the server IP in the Output

## Managing the Server

You can SSH into the server to manage it. For conveniance sake, I prefer to use the built-in ssh feature on the compute instance console in gcp. 

## Here are some useful commands for sever management 

Once connected, you can:

- Check server status: `sudo systemctl status terraria`
- Stop the server: `sudo systemctl stop terraria`
- Start the server: `sudo systemctl start terraria`
- Restart the server: `sudo systemctl restart terraria`
- View logs: `sudo journalctl -u terraria`
- Access the server console: `screen -r terraria`
  - To exit the console without stopping the server: Press `Ctrl+A` then `D`

## Server Files

- Server installation directory: `/opt/terraria`
- World files: `/opt/terraria/worlds`
- Server configuration: `/opt/terraria/serverconfig.txt`

## Customization

You can customize the server by modifying the variables in your `terraform.tfvars` file:

- `machine_type`: Change the VM size for better performance
- `disk_size_gb`: Increase disk space for larger worlds
- `world_size`: Set to 1 (small), 2 (medium), or 3 (large)
- `max_players`: Set the maximum number of concurrent players
- `server_password`: Add a password to restrict access

## Troubleshooting

### Log Files

There are several logs you can check to diagnose issues with the Terraria server:

1. **Installation log**:
   ```bash
   cat /var/log/terraria-startup.log
   ```
   This contains detailed output from the entire installation process, including downloading the server, setting up Mono, and configuring the service.

2. **Systemd service logs**:
   ```bash
   sudo journalctl -u terraria
   ```
   This shows all logs related to the Terraria systemd service, including startup and runtime errors.

3. **Screen session logs** (if the server started but crashed):
   ```bash
   ls -la /opt/terraria/screenlog.*
   ```
   If any screen log files exist, you can view them with:
   ```bash
   cat /opt/terraria/screenlog.0
   ```

4. **Manual testing logs**:
   When you run the server manually using the provided script, it creates a timestamped log file:
   ```bash
   sudo /opt/terraria/manual-start.sh
   ```
   After running the script, you can find the log file at:
   ```bash
   ls -la /opt/terraria/manual-test-*.log
   ```
   And view the most recent log with:
   ```bash
   cat $(ls -t /opt/terraria/manual-test-*.log | head -1)
   ```

### Version Compatibility

This module uses Terraria server version 1.4.4.9 to match the latest client version. This ensures that players with the current version of Terraria can connect to the server without version mismatch errors.

You can check the installed Mono version:

```bash
mono --version
```

The module installs Mono from the official repository and includes fixes to ensure compatibility with Terraria 1.4.4.9 by removing conflicting DLL files.

### Mono Compatibility Issues

The Terraria server sometimes includes its own .NET library files (DLLs) that can conflict with the system's Mono installation. The startup script automatically handles this by:

1. Detecting and renaming any conflicting DLLs (like System.dll, mscorlib.dll)
2. Forcing the server to use the system's Mono runtime libraries instead

If you see errors like "Your mono runtime and class libraries are out of sync" or "The out of sync library is: /opt/terraria/System.dll", it means there's a conflict between the bundled DLLs and the system Mono. You can manually fix this by:

```bash
# Rename the conflicting DLL
sudo mv /opt/terraria/System.dll /opt/terraria/System.dll.bak

# Restart the server
sudo systemctl restart terraria
```

### Server Not Starting

Check the systemd service status and logs:
```bash
sudo systemctl status terraria
sudo journalctl -u terraria
```

If the server fails to start, you can try the included manual start script to diagnose issues:
```bash
sudo /opt/terraria/manual-start.sh
```
This will start the Terraria server in the foreground, allowing you to see any error messages directly. If the server starts successfully with this script but fails when using systemd, there might be an issue with the service configuration.

### Cannot Connect to Server

1. Verify the server is running:
   ```bash
   sudo systemctl status terraria
   ```
   Or use the provided status script:
   ```bash
   terraria-status
   ```
2. Check that the firewall rule was created correctly:
   ```bash
   gcloud compute firewall-rules describe allow-terraria
   ```
3. Ensure you're using the correct IP address and port (7777)
4. Check if you need a password to connect

## Cleanup

To destroy the infrastructure when you're done:

```bash
terraform destroy
```

Confirm by typing `yes` when prompted.

## Notes

- The server will automatically start when the VM boots
- World data is stored on the VM's disk, so it will persist across VM restarts
- If you stop/start the VM using the GCP console or gcloud CLI, the server will automatically restart
- For data backup, consider setting up a cron job to copy world files to a GCP storage bucket

## License

This module is provided under the MIT License.
