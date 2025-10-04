#!/bin/bash

# Function to setup .env file
setup_env() {

  chmod +x actions/*.sh

    if [ ! -f .env ]; then
        echo ".env file not found. Setting up..."
        cp env.example .env

        echo ""
        echo "=== VARIABLES SETUP ==="
        echo ""

        # Request API key
        while true; do
            read -p "Enter Grafana API key: " api_key
            # Check if key is not empty
            if [ -z "$api_key" ]; then
                echo "Error: API key cannot be empty!"
                continue
            fi
            # Remove possible spaces
            api_key=$(echo "$api_key" | tr -d ' ')
            break
        done
        sed -i '' "s|KEY=\"your_api_key\"|KEY=\"$api_key\"|g" .env

        # Request server URL
        while true; do
            read -p "Enter Grafana server URL (https://your-grafana.example.com): " host_url
            # Check if URL is not empty
            if [ -z "$host_url" ]; then
                echo "Error: Server URL cannot be empty!"
                continue
            fi
            # Remove possible spaces
            host_url=$(echo "$host_url" | tr -d ' ')
            break
        done
        sed -i '' "s|HOST=\"your_grafana_host\"|HOST=\"$host_url\"|g" .env

        # Request backup path
        while true; do
            read -p "Enter backup storage path: " backup_path

            # Check if path is not empty
            if [ -z "$backup_path" ]; then
                echo "Error: Path cannot be empty!"
                continue
            fi

            # Remove possible spaces
            backup_path=$(echo "$backup_path" | tr -d ' ')

            # Remove trailing slash if exists
            backup_path="${backup_path%/}"

            # Check if path exists
            if [ ! -d "$backup_path" ]; then
                echo "Directory '$backup_path' does not exist."
                read -p "Create directory? (y/n): " create_dir
                if [ "$create_dir" = "y" ] || [ "$create_dir" = "Y" ]; then
                    mkdir -p "$backup_path"
                    if [ $? -eq 0 ]; then
                        echo "Directory created: $backup_path"
                        break
                    else
                        echo "Error: Failed to create directory!"
                        continue
                    fi
                else
                    echo "Please enter an existing path."
                    continue
                fi
            else
                echo "Directory exists: $backup_path"
                break
            fi
        done

        # Replace BCKP_PATH variable
        sed -i '' "s|BCKP_PATH=\"your_backup_path\"|BCKP_PATH=\"$backup_path\"|g" .env
        echo "Backup path set: $backup_path"

        echo ""
        echo "=== SETUP COMPLETED ==="
        echo ".env file created and configured!"
        echo ""

        # Show current settings
        current_key=$(grep '^KEY=' .env | cut -d '"' -f 2)
        current_host=$(grep '^HOST=' .env | cut -d '"' -f 2)
        current_backup_path=$(grep '^BCKP_PATH=' .env | cut -d '"' -f 2)

        echo "Current settings:"
        echo "API Key: $current_key"
        echo "Host URL: $current_host"
        echo "Backup Path: $current_backup_path"
        echo ""

        read -p "Press Enter to continue..."

    else
        echo ".env file already exists."
        echo ""
    fi
}

# Function to edit existing .env file
edit_env_file() {
    echo ""
    echo "=== EDITING .env ==="

    # Current values
    current_key=$(grep '^KEY=' .env | cut -d '"' -f 2)
    current_host=$(grep '^HOST=' .env | cut -d '"' -f 2)
    current_backup_path=$(grep '^BCKP_PATH=' .env | cut -d '"' -f 2)

    echo "Current values:"
    echo "API key: $current_key"
    echo "Server URL: $current_host"
    echo "Backup path: $current_backup_path"
    echo ""

    # Request new values - allow empty to keep current
    read -p "Enter new API key [current: $current_key]: " new_key
    if [ -n "$new_key" ]; then
        new_key=$(echo "$new_key" | tr -d ' ')
    else
        new_key="$current_key"
        echo "Keeping current API key"
    fi

    read -p "Enter new server URL [current: $current_host]: " new_host
    if [ -n "$new_host" ]; then
        new_host=$(echo "$new_host" | tr -d ' ')
    else
        new_host="$current_host"
        echo "Keeping current server URL"
    fi

    read -p "Enter new backup path [current: $current_backup_path]: " new_path
    if [ -n "$new_path" ]; then
        new_path=$(echo "$new_path" | tr -d ' ')
        # Remove trailing slash if exists
        new_path="${new_path%/}"
    else
        new_path="$current_backup_path"
        echo "Keeping current backup path"
    fi

    # Update values
    if [ "$new_key" != "$current_key" ]; then
        sed -i '' "s|KEY=\"$current_key\"|KEY=\"$new_key\"|g" .env
    fi

    if [ "$new_host" != "$current_host" ]; then
        sed -i '' "s|HOST=\"$current_host\"|HOST=\"$new_host\"|g" .env
    fi

    if [ "$new_path" != "$current_backup_path" ]; then
        sed -i '' "s|BCKP_PATH=\"$current_backup_path\"|BCKP_PATH=\"$new_path\"|g" .env
    fi

    echo ""
    echo "Settings updated!"
    echo "New values:"
    echo "API Key: $new_key"
    echo "Host URL: $new_host"
    echo "Backup Path: $new_path"
    echo ""
}

# Check and setup .env on startup
setup_env

# Main menu
while true; do
    echo "=== MAIN MENU ==="
    select script in "Backup Data" "Update Data" "Edit .env" "Show Current Settings" "Exit"; do
        case $script in
            "Backup Data")
                echo "Backing Up..."
                source .env
                ./actions/grafana-backup-all.sh
                break
                ;;
            "Update Data")
                echo "Updating..."
                source .env
                ./actions/grafana-update-all.sh
                break
                ;;
            "Edit .env")
                edit_env_file
                break
                ;;
            "Show Current Settings")
                # Load current values
                current_key=$(grep '^KEY=' .env | cut -d '"' -f 2)
                current_host=$(grep '^HOST=' .env | cut -d '"' -f 2)
                current_backup_path=$(grep '^BCKP_PATH=' .env | cut -d '"' -f 2)

                echo ""
                echo "Current settings:"
                echo "API Key: $current_key"
                echo "Host URL: $current_host"
                echo "Backup Path: $current_backup_path"
                echo ""
                break
                ;;
            "Exit")
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Wrong Choice! Try Again!"
                ;;
        esac
    done
done