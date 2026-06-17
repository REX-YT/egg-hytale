#!/bin/bash
source "/egg-hytale/lib/utilities.sh"
source "/egg-hytale/lib/authentication.sh"
source "/egg-hytale/lib/system.sh"
source "/egg-hytale/lib/downloader.sh"
source "/egg-hytale/lib/plugins.sh"

copy_startup_template() {
    logger info "Copying start.sh template to /home/container..."
    cp -f /usr/local/bin/start.sh start.sh
    chmod 755 start.sh
}

DOWNLOAD_URL="https://downloader.hytale.com/hytale-downloader.zip"
PATCHLINE_CACHE_FILE=".patchline-cache.txt"
DOWNLOAD_FILE="hytale-downloader.zip"
DOWNLOADER_DIR="/egg-hytale/downloader"
DOWNLOAD_CRED_FILE=".hytale-downloader-credentials.json"
AUTH_CACHE_FILE=".hytale-auth-tokens.json"
VERSION_FILE="version.txt"
MODS_FOLDER="mods"

java -version
echo " "

# Initialize system
detect_architecture
setup_environment

setup_backup_directory
ensure_downloader
update_downloader

create_system_files

ensure_system_file_permissions

run_update_process
validate_server_files
ensure_aot_cache
install_sourcequery


# Check if GSP mode (tokens provided externally)
if [ -n "$OVERRIDE_SESSION_TOKEN" ] && [ -n "$OVERRIDE_IDENTITY_TOKEN" ]; then
    logger info "Using provided session and identity tokens..."
    SESSION_TOKEN="$OVERRIDE_SESSION_TOKEN"
    IDENTITY_TOKEN="$OVERRIDE_IDENTITY_TOKEN"
else
    # Default to persistent authentication if not specified, this is needed for backwards combability
    if [ -z "$USE_PERSISTENT_AUTHENTICATION" ]; then
        USE_PERSISTENT_AUTHENTICATION="ENABLED"
    fi

    if [ "$USE_PERSISTENT_AUTHENTICATION" = "ENABLED" ]; then
        # Standard mode: perform authentication
        if check_cached_tokens && load_cached_tokens; then
            logger info "Using cached authentication..."
            if refresh_access_token; then
                # Update cache in case refresh token rotated
                save_auth_tokens
                # Create fresh game session
                if ! create_game_session; then
                    exit 1
                fi
            else
                # Refresh failed, need full re-auth
                logger info "Refresh token expired, re-authenticating..."
                rm -f "$AUTH_CACHE_FILE"
                perform_authentication
            fi
        else
            # Perform full authentication if no valid cache exists
            perform_authentication
        fi
    fi
fi

# Export the session tokens so they're available to start.sh
export SESSION_TOKEN
export IDENTITY_TOKEN

# Enforce file and folder permissions if enabled
enforce_permissions

copy_startup_template

logger info "Starting Hytale server..."

# Convert startup variables from {{VARIABLE}} to ${VARIABLE} for evaluation.
# The managed start.sh is copied after updates, so the default ./start.sh stays egg-owned.
PARSED=$(echo "$STARTUP" | sed -e 's/{{/${/g' -e 's/}}/}/g')
eval "$PARSED"
