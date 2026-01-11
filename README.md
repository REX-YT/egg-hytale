# Hytale Server Egg

![GitHub License](https://img.shields.io/github/license/NATroutter/egg-hytale?style=for-the-badge) ![GitHub Issues](https://img.shields.io/github/issues/NATroutter/egg-hytale?style=for-the-badge)
![GitHub Stars](https://img.shields.io/github/stars/NATroutter/egg-hytale?style=for-the-badge) ![GitHub Forks](https://img.shields.io/github/forks/NATroutter/egg-hytale?style=for-the-badge)

A Pelican Panel egg for hosting Hytale game servers.

## Overview

This egg provides an automated installation and startup configuration for Hytale servers on Pelican Panel. It handles downloading the Hytale server files, setting up the environment, and starting the server with customizable parameters.

**Note**: While designed for Pelican Panel, this egg should work with Pterodactyl Panel as well, though it has not been tested on Pterodactyl.

## Features

- Automated Hytale server installation
- Automatic download of server files from official sources
- Configurable server parameters
- Easy setup and deployment
- Support for custom asset packs
- Backup management
- Multiple authentication modes

## Installation

1. Download the `egg-hytale.json` file from this repository
2. In your Pelican Panel, navigate to **Admin Panel** > **Eggs**
3. Click **Import**
4. Select the downloaded JSON file
5. Configure the egg settings as needed

For Pterodactyl Panel users, the process should be similar, though compatibility is untested.

## Server Configuration

The following variables can be configured:

| Variable | Description | Default |
|----------|-------------|---------|
| `ASSET_PACK` | Asset pack to use | `Assets.zip` |
| `ACCEPT_EARLY_PLUGINS` | Accept early-access plugins | `false` |
| `ALLOW_OP` | Allow operator privileges | `true` |
| `AUTH_MODE` | Authentication mode | `authenticated` |
| `ENABLE_BACKUPS` | Enable automatic backups | `false` |
| `BACKUP_DIRECTORY` | Backup directory path | `./backups` |
| `BACKUP_FREQUENCY` | Backup frequency in minutes | `30` |
| `SERVER_IP` | Server bind IP address | `0.0.0.0` |
| `SERVER_PORT` | Server port | `5520` |


## Scripts

### install.sh

Handles the initial installation of the Hytale server:
- Installs required dependencies (curl, unzip)
- Downloads the Hytale downloader
- Extracts server files
- Downloads the start script from GitHub
- Sets executable permissions
- Runs initial server setup

### start.sh

Manages server startup:
- Verifies Hytale downloader exists
- Sets executable permissions if needed
- Runs the Hytale downloader
- Starts the Hytale server with configured parameters

## Usage

Once installed, simply start the server from your Pelican Panel. The egg will handle:
1. Running the Hytale downloader to fetch the latest server files
2. Starting the server with your configured parameters

### First-Time Authentication

During the first installation, the Hytale downloader will require authentication with your Hytale account. You'll see output similar to this in the console:

```
Please visit the following URL to authenticate:
https://oauth.accounts.hytale.com/oauth2/device/verify?user_code=XXXXXXXX
Or visit the following URL and enter the code:
https://oauth.accounts.hytale.com/oauth2/device/verify
Authorization code: XXXXXXXX
```

**To complete authentication:**
1. Open the provided URL in your web browser
2. Enter the authorization code shown in the console
3. Sign in with your Hytale account credentials
4. Authorize the server to download game files
5. Return to the console - the download will continue automatically

This authentication step is only required during initial setup. Subsequent server starts will not require re-authentication.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Hytale team for the game and server software
- Pelican Panel for the hosting platform
- Community contributors

## Links

- [Hytale Official Website](https://hytale.com/)
- [Pelican Panel](https://pelican.dev/)
- [Pterodactyl Panel](https://pterodactyl.io/) (untested compatibility)
- [Report Issues](https://github.com/NATroutter/egg-hytale/issues)

## Support

If you encounter any issues or have questions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review the troubleshooting section above

---

**Note**: This is an unofficial community-created egg and is not officially supported by Hypixel Studios or the Hytale team.
