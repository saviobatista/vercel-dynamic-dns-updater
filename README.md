# Vercel Dynamic DNS Updater

This script automatically updates a DNS A record on Vercel with the current external IP address of the machine it's run on. It's ideal for use in environments with dynamic IP addresses where you need to maintain a consistent domain pointing to a changing IP.

## Requirements

- `bash`
- `curl`
- `jq`: This script uses `jq` for parsing JSON responses.

## Setup

1. **Install jq**

   - On Ubuntu/Debian:
     ```bash
     sudo apt-get install jq
     ```
   - On CentOS/Fedora:
     ```bash
     sudo yum install jq
     ```
   - On macOS:
     ```bash
     brew install jq
     ```

2. **Clone the Repository**

   Clone this repository to your local machine where you plan to run the script.

   ```bash
   git clone https://github.com/saviobatista/vercel-dynamic-dns-updater.git
   cd vercel-dynamic-dns-updater
   ```

3. **Configure Environment Variables**
Copy the `.env.example` file to a new file named `.env` and fill in your Vercel API token, DNS record ID, and the subdomain you wish to update.

```bash
cp .env.example .env
# Edit .env with your preferred text editor
```

Your `.env` file should look something like this:
```bash
RECORD=<RECORD_ID>
TOKEN=<TOKEN>
SUBDOMAIN=<SUBDOMAIN>
```

4. **Make the Script Executable**
Change the script's permissions to make it executable.
```bash
chmod +x cron.sh
```

*Usage*

Run the script manually to update your DNS record:

```bash
./cron.sh
```

To automate this process, consider adding the script to your crontab. For example, to run the script every hour, edit your crontab with `crontab -e` and add the following line:

```cron
0 * * * * /path/to/cron.sh
```

Make sure to replace `/path/to/cron.sh` with the actual path to the script.

*Troubleshooting*

- Ensure your `.env` file is configured correctly.
- Verify that `jq` is installed and accessible in your PATH.
- Check the script's output for any error messages or HTTP status codes that indicate what might have gone wrong.

*Contributing*

Feel free to fork the repository and submit pull requests with any enhancements or fixes.

*License*

This script is open-sourced software licensed under the MIT license.
