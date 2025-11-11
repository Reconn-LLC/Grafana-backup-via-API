#!/bin/bash

# Function to setup ./.env file
setup_env() {
  chmod +x actions/*.sh

  if [ ! -f ./.env ]; then
    echo ".env file not found. Setting up..."
    cp env.example ./.env

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
    sed -i "s|KEY=\"your_api_key\"|KEY=\"$api_key\"|g" ./.env

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
    sed -i "s|HOST=\"your_grafana_host\"|HOST=\"$host_url\"|g" ./.env

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
    sed -i "s|BCKP_PATH=\"your_backup_path\"|BCKP_PATH=\"$backup_path\"|g" ./.env
    echo "Backup path set: $backup_path"

    echo ""
    echo "=== SETUP COMPLETED ==="
    echo "./.env file created and configured!"
    echo ""

    # Show current settings
    show_current_settings

    read -p "Press Enter to continue..."

  else
    echo "./.env file already exists."
    echo ""
  fi
}

# Function to show current settings
show_current_settings() {
  if [ -f ./.env ]; then
    # Load current values safely
    source ./.env 2>/dev/null
    current_key="$KEY"
    current_host="$HOST"
    current_backup_path="$BCKP_PATH"

    echo "Current settings:"
    echo "API Key: $current_key"
    echo "Host URL: $current_host"
    echo "Backup Path: $current_backup_path"
    echo ""
  else
    echo "./.env file not found!"
    echo ""
  fi
}

# Function to edit existing ./.env file
edit_env_file() {
  if [ ! -f ./.env ]; then
    echo "./.env file not found! Please run setup first."
    return 1
  fi

  echo ""
  echo "=== EDITING ./.env ==="

  # Load current values safely
  source ./.env 2>/dev/null
  current_key="$KEY"
  current_host="$HOST"
  current_backup_path="$BCKP_PATH"

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

  # Update values using temporary file to avoid sed issues
  if [ "$new_key" != "$current_key" ]; then
    sed -i "s|^KEY=.*|KEY=\"$new_key\"|g" ./.env
  fi

  if [ "$new_host" != "$current_host" ]; then
    sed -i "s|^HOST=.*|HOST=\"$new_host\"|g" ./.env
  fi

  if [ "$new_path" != "$current_backup_path" ]; then
    sed -i "s|^BCKP_PATH=.*|BCKP_PATH=\"$new_path\"|g" ./.env
  fi

  echo ""
  echo "Settings updated!"
  show_current_settings
}

# Function to backup data
backup_data() {
  if [ ! -f ./.env ]; then
    echo "Error: ./.env file not found! Please run setup first."
    return 1
  fi
  
  echo "Backing Up..."
  source ./.env
  if [ -f ./actions/grafana-backup-all.sh ]; then
    ./actions/grafana-backup-all.sh
  else
    echo "Error: grafana-backup-all.sh not found in actions directory!"
  fi
}

# Function to update data
update_data() {
  if [ ! -f ./.env ]; then
    echo "Error: ./.env file not found! Please run setup first."
    return 1
  fi
  
  echo "Updating..."
  source ./.env
  if [ -f ./actions/grafana-update-all.sh ]; then
    ./actions/grafana-update-all.sh
  else
    echo "Error: grafana-update-all.sh not found in actions directory!"
  fi
}

# Check and setup ./.env on startup
setup_env

# Main menu
while true; do
  echo "=== MAIN MENU ==="
  echo "1) Backup Data"
  echo "2) Update Data"
  echo "3) Edit ./.env"
  echo "4) Show Current Settings"
  echo "5) Exit"
  read -p "Select an option [1-5]: " choice

  case $choice in
    1)
      backup_data
      ;;
    2)
      update_data
      ;;
    3)
      edit_env_file
      ;;
    4)
      show_current_settings
      ;;
    5)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Wrong Choice! Try Again!"
      ;;
  esac
  
  echo ""
done
