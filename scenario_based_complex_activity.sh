
#!/bin/bash

# --- SETUP USERS ---
# Ensure both James and Nick exist
id james &>/dev/null || sudo adduser --gecos "" --disabled-password james
id nick &>/dev/null || sudo adduser --gecos "" --disabled-password nick

# Set passwords for realism
echo "james:Password123!" | sudo chpasswd
echo "nick:DevPass123!" | sudo chpasswd

# --- SIMULATE JAMES'S (SYSADMIN) ACTIVITY ---

sysadmin_activity() {
    echo "[+] James (Sysadmin) performing system tasks"

    # Update package lists and install packages
    sudo apt update > /dev/null
    sudo apt install -y vim htop tree curl wget net-tools nc git > /dev/null

    # Configure firewall to allow SSH
    sudo ufw allow ssh
    sudo systemctl restart ufw

    # Restart SSH
    sudo systemctl restart ssh

    # Create a backup cron job (persistence)
    echo "*/15 * * * * james tar -czf /home/james/backup.tar.gz /home/james/documents" | sudo tee /etc/cron.d/backup_job

    # Set up permissions on home directories
    chmod 750 /home/james
    chmod 750 /home/nick

    # Add user to sudo group
    sudo usermod -aG sudo james

    # Restart critical services
    sudo systemctl restart ssh
    sudo systemctl restart cron
}

# --- SIMULATE NICK'S (DEVELOPER) ACTIVITY ---

developer_activity() {
    echo "[+] Nick (Developer) working on a project"

    # Create project directories
    mkdir -p /home/nick/projects/app
    mkdir -p /home/nick/logs

    # Clone a Git repository
    sudo -u nick git clone https://github.com/tensorflow/tensorflow.git /home/nick/projects/tensorflow

    # Create and modify some files
    echo "print('Hello from Nick')" > /home/nick/projects/app/app.py
    chmod 644 /home/nick/projects/app/app.py

    # Run the code
    sudo -u nick python3 /home/nick/projects/app/app.py

    # Create a log file
    sudo -u nick echo "Starting application" >> /home/nick/logs/app.log

    # Make some commits
    cd /home/nick/projects/tensorflow
    sudo -u nick git add .
    sudo -u nick git commit -m "Initial commit"

    # Attempt SSH login (simulate testing)
    sudo -u nick ssh nick@localhost || true

    # Test file permissions
    chmod 777 /home/nick/projects/app/app.py
}

# --- SIMULATE NETWORK ACTIVITY WITH NETCAT ---

netcat_activity() {
    echo "[+] Simulating network traffic with Netcat"

    # James sets up a listener on port 8080 (simulating HTTP service)
    (nc -lvp 8080 &)

    # Nick sends a request to James's port
    echo "GET / HTTP/1.1" | nc localhost 8080

    # James sets up a file transfer listener
    (nc -lvp 9000 > /home/james/received_file.txt &)

    # Nick sends a file
    cat /home/nick/projects/app/app.py | nc localhost 9000

    # Simulate fake FTP traffic (Nick sends FTP-like commands)
    (nc -lvp 21 &)
    echo "USER nick" | nc localhost 21

    # Simulate external HTTP request
    echo "GET / HTTP/1.1" | nc example.com 80 || true
}

# --- SIMULATE FILE SYSTEM ACTIVITY ---

file_activity() {
    echo "[+] Simulating file system activity"

    # Create random files and directories
    touch /home/james/testfile_$(date +%s)
    touch /home/nick/testfile_$(date +%s)

    # Modify timestamps to hide evidence
    touch -d "2022-01-01 00:00:00" /home/james/testfile_*
    touch -d "2022-01-01 00:00:00" /home/nick/testfile_*

    # Create large files to simulate disk activity
    dd if=/dev/zero of=/home/james/bigfile bs=1M count=100
    dd if=/dev/zero of=/home/nick/bigfile bs=1M count=100
}

# --- SIMULATE SUDO COMMANDS ---

sudo_activity() {
    echo "[+] Simulating sudo activity"

    sudo apt install tree -y
    sudo apt remove tree -y

    sudo systemctl restart ssh
    sudo systemctl restart ufw

    sudo chmod 644 /etc/passwd
}

# --- MAIN FUNCTION ---

main() {
    echo "[+] Starting scenario-based activity simulation"

    sysadmin_activity
    developer_activity
    netcat_activity
    file_activity
    sudo_activity

    # Loop activity randomly for persistence
    while true; do
        sleep $((RANDOM % 5 + 5))
        
        # Random activity with different timeframes
        if (( RANDOM % 2 )); then
            developer_activity
        fi

        if (( RANDOM % 3 )); then
            sudo_activity
        fi

        if (( RANDOM % 4 )); then
            netcat_activity
        fi

        if (( RANDOM % 5 )); then
            file_activity
        fi

        sleep $((RANDOM % 15 + 10))
    done
}

# Start activity simulation with nohup for persistence
nohup bash -c "main" &>/dev/null &

echo "[+] Activity simulation running in background"
