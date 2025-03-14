
#!/bin/bash

LOG_FILE="/activity_log.txt"
> "$LOG_FILE" # Clear previous log

# Ensure both James and Nick exist without password prompts
id james &>/dev/null || adduser --gecos "" --disabled-password james
id nick &>/dev/null || adduser --gecos "" --disabled-password nick

# Set passwords for realism
echo "james:123456789" | chpasswd
passwd -d nick

# Ensure no password is required for sudo commands
echo "james ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/james
echo "nick ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nick

# Initialize summary counters
JAMES_FILE_COUNT=0
NICK_FILE_COUNT=0
DOCKER_CONTAINER_COUNT=0

# --- CREATE DIRECTORIES ---
mkdir -p /home/james/configs /home/james/logs /home/james/backups /home/james/keys
mkdir -p /home/nick/code /home/nick/logs /home/nick/scripts

# --- FILE TYPES FOR JAMES (ADMIN) ---

ADMIN_FILES=(
    "/home/james/configs/nginx_config.conf"
    "/home/james/configs/firewall_rules.json"
    "/home/james/keys/ssh_key.key"
    "/home/james/logs/error_log.log"
    "/home/james/backups/system_backup.conf"
)

# --- FILE TYPES FOR NICK (DEVELOPER) ---
DEV_FILES=(
    "/home/nick/code/app_main.py"
    "/home/nick/code/api_handler.py"
    "/home/nick/scripts/compile_script.sh"
    "/home/nick/logs/debug_log.log"
    "/home/nick/code/database_model.c"
)

# --- SIMULATE JAMES'S (SYSADMIN) ACTIVITY ---

sysadmin_activity() {
    for file in "${ADMIN_FILES[@]}"; do
        TIMESTAMP=$(date -d "$((RANDOM % 180)) days ago" +"%Y-%m-%d %H:%M:%S")
        
        case "$file" in
            *.conf) echo "server_name icarus; location / { allow all; }" > "$file" ;;
            *.json) echo '{"firewall": {"allow": ["ssh", "http"], "deny": ["ftp"]}}' > "$file" ;;
            *.key) echo -e "-----BEGIN PRIVATE KEY-----\nMIICWwIBAAKBgQC8ABCD34F22SSFA64AA....\n-----END PRIVATE KEY-----" > "$file" ;;
            *.log) echo "$(date): ERROR - Service failed to start" > "$file" ;;
        esac

        touch -d "$TIMESTAMP" "$file"
        echo "$file | $TIMESTAMP" >> "$LOG_FILE"
        ((JAMES_FILE_COUNT++))
        echo -ne "\r[James] Creating files... $JAMES_FILE_COUNT/5"
        sleep 0.05
    done
    echo ""

    # Create Docker containers without interactive confirmation
    docker run -d -p 8080:80 nginx &>/dev/null
    docker run -d -p 5000:5000 httpd &>/dev/null
    DOCKER_CONTAINER_COUNT=2
    echo "[+] Docker containers running: nginx, httpd" >> "$LOG_FILE"

    # Manage firewall and services
    systemctl restart ssh &>/dev/null
    echo "[+] Firewall configured and SSH restarted" >> "$LOG_FILE"
}

# --- SIMULATE NICK'S (DEVELOPER) ACTIVITY ---

developer_activity() {
    for file in "${DEV_FILES[@]}"; do
        TIMESTAMP=$(date -d "$((RANDOM % 90)) days ago" +"%Y-%m-%d %H:%M:%S")
        
        case "$file" in
            *.py) echo "def main():\n    print('Hello from developer')" > "$file" ;;
            *.sh) echo "#!/bin/bash\necho 'Compiling project...'" > "$file" ; chmod +x "$file" ;;
            *.log) echo "$(date): DEBUG - Connection successful" > "$file" ;;
            *.c) echo "#include <stdio.h>\nint main() { printf('Database connected!'); return 0; }" > "$file" ;;
        esac

        touch -d "$TIMESTAMP" "$file"
        echo "$file | $TIMESTAMP" >> "$LOG_FILE"
        ((NICK_FILE_COUNT++))
        echo -ne "\r[Nick] Creating files... $NICK_FILE_COUNT/5"
        sleep 0.05
    done
    echo ""

    # Create Git repository and commits
    mkdir -p /home/nick/repo && cd /home/nick/repo && git init &>/dev/null
    for i in {1..10}; do
        echo "Commit $i" >> commit.txt
        git add . &>/dev/null
        git commit -m "Commit $i" &>/dev/null
        echo "[+] Git commit $i added" >> "$LOG_FILE"
    done
}

# --- SIMULATE NETWORK ACTIVITY WITH NETCAT ---

netcat_activity() {
    (echo "Sample file content for transfer" | nc -lvnp 8080 &) &>/dev/null
    sleep 1
    echo "GET / HTTP/1.1" | nc -n localhost 8080 &>/dev/null
    echo "[+] HTTP request sent to port 8080" >> "$LOG_FILE"

    (echo "This is a sample received file from a remote host." | nc -lvnp 9000 > /home/james/received.txt &) &>/dev/null
    sleep 1
    echo "[+] File transfer via Netcat on port 9000" >> "$LOG_FILE"
}

# --- SIMULATE FILE SYSTEM ACTIVITY ---

file_activity() {
    for i in {1..5}; do
        FILE="/home/james/logs/log_file_${i}.log"
        echo "$(date): INFO - Service started successfully" > "$FILE"
        touch -d '2021-01-01' "$FILE"
        echo "$FILE | Log entry $i" >> "$LOG_FILE"
        ((JAMES_FILE_COUNT++))
        echo -ne "\r[James] Creating logs... $i/5"
        sleep 0.05
    done
    echo ""
}

# --- MAIN FUNCTION ---

main() {
    START_TIME=$(date +%s)

    sysadmin_activity
    developer_activity
    netcat_activity
    file_activity

    END_TIME=$(date +%s)
    TOTAL_TIME=$((END_TIME - START_TIME))
    generate_summary
}

# --- SUMMARY FUNCTION ---

generate_summary() {
    echo "" >> "$LOG_FILE"
    echo "========== ACTIVITY SUMMARY ==========" >> "$LOG_FILE"
    echo "[+] James created $JAMES_FILE_COUNT files" >> "$LOG_FILE"
    echo "[+] Nick created $NICK_FILE_COUNT files" >> "$LOG_FILE"
    echo "[+] $DOCKER_CONTAINER_COUNT Docker containers are running" >> "$LOG_FILE"
    echo "[+] Network traffic generated via Netcat" >> "$LOG_FILE"
    echo "[+] Git repository initialized with 10 commits" >> "$LOG_FILE"
    echo "======================================" >> "$LOG_FILE"

    echo ""
    echo "=========================="
    echo "✅ Activity Summary:"
    echo "➡️ James created $JAMES_FILE_COUNT files"
    echo "➡️ Nick created $NICK_FILE_COUNT files"
    echo "➡️ Docker containers: $DOCKER_CONTAINER_COUNT"
    echo "➡️ Git commits: 10"
    echo "➡️ Network traffic generated"
    echo "➡️ Full log saved to $LOG_FILE"
    echo "=========================="
}

# --- CLEANUP ---

cleanup() {
    rm -f /etc/sudoers.d/james
    rm -f /etc/sudoers.d/nick
}

# --- START EXECUTION ---

main
cleanup
