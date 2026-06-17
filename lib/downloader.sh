#!/bin/bash

ensure_downloader() {
    if [ ! -f "$DOWNLOADER" ]; then
        logger error "Hytale downloader not found!"
        logger error "Please run the installation script first."
        exit 1
    fi

    if [ ! -x "$DOWNLOADER" ]; then
        logger info "Setting executable permissions for downloader..."
        chmod +x "$DOWNLOADER"
    fi
}

update_downloader() {
    local UPDATE_OUTPUT=""
    local TEMP_DIR=""
    local UPDATED=0

    logger info "Checking hytale-downloader for updates..."
    UPDATE_OUTPUT=$($DOWNLOADER -check-update 2>&1)

    if [ $? -ne 0 ]; then
        logger warn "Failed to check hytale-downloader updates; continuing with installed downloader."
        return 0
    fi

    if ! printf "%s" "$UPDATE_OUTPUT" | grep -q "A new version of hytale-downloader is available"; then
        logger info "hytale-downloader is up to date."
        return 0
    fi

    logger warn "A newer hytale-downloader is available, updating..."
    TEMP_DIR=$(mktemp -d)

    if [ -z "$TEMP_DIR" ] || [ ! -d "$TEMP_DIR" ]; then
        logger warn "Failed to create temporary directory for hytale-downloader update."
        return 0
    fi

    if curl -fsSL -o "$TEMP_DIR/$DOWNLOAD_FILE" "$DOWNLOAD_URL" \
        && unzip -oq "$TEMP_DIR/$DOWNLOAD_FILE" -d "$TEMP_DIR"; then

        if [ -f "$TEMP_DIR/hytale-downloader-linux-amd64" ]; then
            cp -f "$TEMP_DIR/hytale-downloader-linux-amd64" ./hytale-downloader-linux-amd64
            chmod +x ./hytale-downloader-linux-amd64
            UPDATED=1
        fi

        if [ -f "$TEMP_DIR/hytale-downloader-linux-arm64" ]; then
            cp -f "$TEMP_DIR/hytale-downloader-linux-arm64" ./hytale-downloader-linux-arm64
            chmod +x ./hytale-downloader-linux-arm64
            UPDATED=1
        elif [ -f ./hytale-downloader-linux-arm64 ]; then
            chmod +x ./hytale-downloader-linux-arm64
        fi
    else
        logger warn "Failed to download or extract hytale-downloader update; continuing with installed downloader."
    fi

    rm -rf "$TEMP_DIR"

    if [ "$UPDATED" = "1" ]; then
        logger success "hytale-downloader updated successfully."
    else
        logger warn "hytale-downloader update did not include an expected linux binary; continuing with installed downloader."
    fi
}

ensure_aot_cache() {
    local AOT_CONFIG_FILE="HytaleServer.aot.config"
    local AOT_CACHE_FILE="HytaleServer.aot"
    local AOT_LOG_FILE=""
    local AOT_STATUS=0

    if [ "$LEVERAGE_AHEAD_OF_TIME_CACHE" != "1" ]; then
        return 0
    fi

    if [ ! -f "$AOT_CONFIG_FILE" ]; then
        logger warn "AOT config not found, skipping AOT cache generation."
        return 0
    fi

    if [ -f "$AOT_CACHE_FILE" ] && [ "$AOT_CACHE_FILE" -nt "$AOT_CONFIG_FILE" ]; then
        logger info "AOT cache is up to date."
        return 0
    fi

    logger info "Generating AOT cache from $AOT_CONFIG_FILE..."
    rm -f "$AOT_CACHE_FILE"

    AOT_LOG_FILE=$(mktemp)
    if [ -z "$AOT_LOG_FILE" ]; then
        logger warn "Failed to create temporary AOT log file."
        return 0
    fi

    java ${AOT_JVM_ARGS} -XX:-AOTClassLinking -XX:AOTMode=create -XX:AOTConfiguration="$AOT_CONFIG_FILE" -XX:AOTCacheOutput="$AOT_CACHE_FILE" -cp HytaleServer.jar 2>&1 | tee "$AOT_LOG_FILE"
    AOT_STATUS=${PIPESTATUS[0]}

    if [ "$AOT_STATUS" -eq 0 ]; then
        logger success "AOT cache generated successfully."
    else
        if grep -q "timestamp has changed" "$AOT_LOG_FILE"; then
            printc "{MAGENTA}╔═════════════════════════════════════════════════════════════════════════════╗"
            printc "{MAGENTA}║               {YELLOW}AOT CACHE SKIPPED: HYTALE FILE MISMATCH                       {MAGENTA}║"
            printc "{MAGENTA}╠═════════════════════════════════════════════════════════════════════════════╣"
            printc "{MAGENTA}║                                                                             ║"
            printc "{MAGENTA}║  {CYAN}The Hytale server files include an AOT config that does not match          {MAGENTA}║"
            printc "{MAGENTA}║  {CYAN}the server jar shipped in this download.                                   {MAGENTA}║"
            printc "{MAGENTA}║                                                                             ║"
            printc "{MAGENTA}║  {CYAN}This usually means the Hytale developers updated HytaleServer.jar          {MAGENTA}║"
            printc "{MAGENTA}║  {CYAN}but shipped an older or mismatched HytaleServer.aot.config file.           {MAGENTA}║"
            printc "{MAGENTA}║                                                                             ║"
            printc "{MAGENTA}║  {CYAN}This is not an egg issue. The server will continue without AOT cache       {MAGENTA}║"
            printc "{MAGENTA}║  {CYAN}and AOT should work once Hytale ships matching files.                      {MAGENTA}║"
            printc "{MAGENTA}║                                                                             ║"
            printc "{MAGENTA}╚═════════════════════════════════════════════════════════════════════════════╝"
        fi

        logger warn "AOT cache generation failed; the server will start without AOT cache."
        rm -f "$AOT_CACHE_FILE"
    fi

    rm -f "$AOT_LOG_FILE"
}

run_update_process() {
    local INITIAL_SETUP=0

    # Check if credentials file exists, if not run the initial setup
    if [ ! -f "$DOWNLOAD_CRED_FILE" ]; then
        INITIAL_SETUP=1
        run_initial_setup
    fi

    # Check if automatic update is enabled
    if [ "$AUTOMATIC_UPDATE" = "1" ] && [ "$INITIAL_SETUP" = "0" ]; then
        run_auto_update
    fi

    # Check if patchline has changed if so update the server
    if [ -f "$PATCHLINE_CACHE_FILE" ]; then
        local CACHED_PATCHLINE=$(cat $PATCHLINE_CACHE_FILE)

        if [ "$PATCHLINE" != "$CACHED_PATCHLINE" ]; then
            logger warn "Patchline mismatch, running update..."
            $DOWNLOADER -check-update
            $DOWNLOADER -patchline $PATCHLINE -download-path server.zip

            save_patchline_version
            extract_server_files

            logger success "Server has been successfully updated to patchline: $PATCHLINE"
        else
            logger info "Patchline match, skipping change"
        fi
    else
        logger warn "Patchline file not found, Saving patchline!"
        save_patchline_version
    fi
}

run_patchline_change() {
    logger info "Updating server to patchline: $PATCHLINE"

    $DOWNLOADER -check-update
    if ! $DOWNLOADER -patchline $PATCHLINE -download-path server.zip; then
        echo ""
        logger error "Failed to download Hytale server files."
        logger warn "Removing invalid credential file..."
        rm -f $DOWNLOAD_CRED_FILE
        exit 1
    fi

    echo "$PATCHLINE" > "$PATCHLINE_CACHE_FILE"
    logger success "Selected patchline saved!"

    save_downloader_version

    extract_server_files
    logger success "Server has been successfully updated to patchline: $PATCHLINE"
}

run_initial_setup() {
    logger warn "Credentials file not found, running initial setup..."
    logger info "Downloading server files..."

    $DOWNLOADER -check-update

    echo " "
    printc "{MAGENTA}╔══════════════════════════════════════════════════════════════════════════════════════╗"
    printc "{MAGENTA}║  {BLUE}NOTE: You must have purchased Hytale on the account you are using to authenticate.  {MAGENTA}║"
    printc "{MAGENTA}╚══════════════════════════════════════════════════════════════════════════════════════╝"
    echo " "

    if ! $DOWNLOADER -patchline $PATCHLINE -download-path server.zip; then
        echo ""
        logger error "Failed to download Hytale server files."
        logger warn "Removing invalid credential file..."
        rm -f $DOWNLOAD_CRED_FILE
        exit 1
    fi

    save_patchline_version
    save_downloader_version
    extract_server_files
}

run_auto_update() {
    # Run automatic update if enabled
    logger info "Checking for updates..."

    local LOCAL_VERSION=""
    if [ -f "$VERSION_FILE" ]; then
        LOCAL_VERSION=$(cat $VERSION_FILE)
    else
        logger warn "Version file not found, forcing update"
    fi

    local DOWNLOADER_VERSION=$($DOWNLOADER -print-version -skip-update-check 2>&1)

    if [ $? -ne 0 ] || [ -z "$DOWNLOADER_VERSION" ]; then
        logger error "Failed to get downloader version."
        exit 1
    else
        if [ -n "$LOCAL_VERSION" ]; then
            logger info "Local version: $LOCAL_VERSION"
        fi
        logger info "Available version: $DOWNLOADER_VERSION"

        if [ "$LOCAL_VERSION" != "$DOWNLOADER_VERSION" ]; then
            logger warn "Version mismatch, running update..."
            $DOWNLOADER -check-update
            $DOWNLOADER -patchline $PATCHLINE -download-path server.zip

            save_patchline_version
            save_downloader_version

            extract_server_files
            logger success "Server has been updated successfully!"
        else
            logger info "Versions match, skipping update"
        fi
    fi
}

save_patchline_version() {
    echo "$PATCHLINE" > $PATCHLINE_CACHE_FILE
    logger success "Selected patchline saved!"
}

save_downloader_version() {
    local DOWNLOADER_VERSION=$($DOWNLOADER -print-version -skip-update-check 2>&1)
    if [ $? -eq 0 ] && [ -n "$DOWNLOADER_VERSION" ]; then
        echo "$DOWNLOADER_VERSION" > $VERSION_FILE
        logger success "Saved version info!"
    else
        logger error "Failed to get downloader version."
        exit 1
    fi
}

validate_server_files() {
    if [ ! -f "HytaleServer.jar" ]; then
        logger error "HytaleServer.jar not found!"
        logger error "Server files were not downloaded correctly."
        exit 1
    fi
}
