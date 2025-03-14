
#!/bin/bash

LOG_FILE="/home/james/activity_log.txt"
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

# --- SIMULATE JAMES'S (SYSADMIN) ACTIVITY ---

sysadmin_activity() {
    for i in {1..50}; do
        TIMESTAMP=$(date -d "$((RANDOM % 180)) days ago" +"%Y-%m-%d %H:%M:%S")
        FILE="/home/james/file_${i}.txt"
        echo 'System file' > "$FILE"
        touch -d "$TIMESTAMP" "$FILE"
        echo "$FILE | $TIMESTAMP" >> "$LOG_FILE"
        ((JAMES_FILE_COUNT++))
        echo -ne "\r[James] Creating files... $JAMES_FILE_COUNT/50"
        sleep 0.1
    done
    echo ""

    # Create Docker containers without interactive confirmation
    docker run -d -p 8080:80 nginx &>/dev/null
    docker run -d -p 5000:5000 httpd &>/dev/null
    DOCKER_CONTAINER_COUNT=2
    echo "[+] Docker containers running: nginx, httpd" >> "$LOG_FILE"

    # Manage firewall and services
    ufw allow ssh &>/dev/null
    systemctl restart ssh &>/dev/null
    echo "[+] Firewall configured and SSH restarted" >> "$LOG_FILE"
}

# --- SIMULATE NICK'S (DEVELOPER) ACTIVITY ---

developer_activity() {
    for i in {1..100}; do
        TIMESTAMP=$(date -d "$((RANDOM % 90)) days ago" +"%Y-%m-%d %H:%M:%S")
        FILE="/home/nick/dev_file_${i}.py"
        echo 'print("Test File")' > "$FILE"
        touch -d "$TIMESTAMP" "$FILE"
        echo "$FILE | $TIMESTAMP" >> "$LOG_FILE"
        ((NICK_FILE_COUNT++))
        echo -ne "\r[Nick] Creating files... $NICK_FILE_COUNT/100"
        sleep 0.05
    done
    echo ""

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
    (nc -lvnp 8080 &)
    sleep 1
    echo "GET / HTTP/1.1" | nc -n localhost 8080 &>/dev/null
    echo "[+] HTTP request sent to port 8080" >> "$LOG_FILE"

    (nc -lvnp 9000 > /home/james/received.txt &)
    echo "Fake file transfer" | nc -n localhost 9000 &>/dev/null
    echo "[+] File transfer via Netcat on port 9000" >> "$LOG_FILE"
}

# --- SIMULATE FILE SYSTEM ACTIVITY ---

file_activity() {
    for i in {1..20}; do
        FILE="/home/james/testfile_${i}.log"
        echo 'Log entry' > "$FILE"
        touch -d '2021-01-01' "$FILE"
        echo "$FILE | Log entry $i" >> "$LOG_FILE"
        echo -ne "\r[James] Creating logs... $i/20"
        sleep 0.05
    done
    echo ""

    for i in {1..30}; do
        FILE="/home/nick/project_${i}.c"
        echo 'int main() { return 0; }' > "$FILE"
        touch -d '2021-01-01' "$FILE"
        echo "$FILE | Code entry $i" >> "$LOG_FILE"
        echo -ne "\r[Nick] Creating project files... $i/30"
        sleep 0.05
    done
    echo ""
}

# --- MAIN FUNCTION ---

main() {
    START_TIME=$(date +%s)

    sysadmin_activity &
    developer_activity &
    netcat_activity &
    file_activity &

    wait

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
