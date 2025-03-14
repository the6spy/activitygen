
#!/bin/bash

LOG_FILE="./activity_log.txt"
> "$LOG_FILE" # Clear previous log

# Ensure both James and Nick exist
id james &>/dev/null || sudo adduser --gecos "" --disabled-password james
id nick &>/dev/null || sudo adduser --gecos "" --disabled-password nick

# Set passwords for realism
echo "james:123456789" | sudo chpasswd
passwd -d nick

# Initialize summary counters
JAMES_FILE_COUNT=0
NICK_FILE_COUNT=0
DOCKER_CONTAINER_COUNT=0

# --- SIMULATE JAMES'S (SYSADMIN) ACTIVITY ---

sysadmin_activity() {
    echo "[+] James (Sysadmin) creating system activity..."

    for i in {1..50}; do
        TIMESTAMP=$(date -d "$((RANDOM % 180)) days ago" +"%Y-%m-%d %H:%M:%S")
        FILE="/home/james/file_${i}.txt"
        sudo -u james bash -c "echo 'System file $i' > $FILE"
        sudo -u james bash -c "touch -d '$TIMESTAMP' $FILE"
        echo "$FILE | $TIMESTAMP" >> "$LOG_FILE"
        ((JAMES_FILE_COUNT++))
        echo -ne "\r[James] Creating files... $JAMES_FILE_COUNT/50"
        sleep 0.1
    done
    echo ""

    sudo -u james bash -c 'docker run -d -p 8080:80 nginx' &>/dev/null
    sudo -u james bash -c 'docker run -d -p 5000:5000 httpd' &>/dev/null
    DOCKER_CONTAINER_COUNT=2
    echo "[+] Docker containers running: nginx, httpd" >> "$LOG_FILE"

    sudo -u james bash -c 'sudo systemctl restart ssh' &>/dev/null
    echo "[+] SSH restarted" >> "$LOG_FILE"
}

# --- SIMULATE NICK'S (DEVELOPER) ACTIVITY ---

developer_activity() {
    echo "[+] Nick (Developer) creating development activity..."

    for i in {1..100}; do
        TIMESTAMP=$(date -d "$((RANDOM % 90)) days ago" +"%Y-%m-%d %H:%M:%S")
        FILE="/home/nick/dev_file_${i}.py"
        sudo -u nick bash -c "echo 'print("File $i")' > $FILE"
        sudo -u nick bash -c "touch -d '$TIMESTAMP' $FILE"
        echo "$FILE | $TIMESTAMP" >> "$LOG_FILE"
        ((NICK_FILE_COUNT++))
        echo -ne "\r[Nick] Creating files... $NICK_FILE_COUNT/100"
        sleep 0.05
    done
    echo ""

    sudo -u nick bash -c 'mkdir -p /home/nick/repo && cd /home/nick/repo && git init' &>/dev/null
    for i in {1..10}; do
        sudo -u nick bash -c "echo 'Commit $i' >> /home/nick/repo/commit.txt"
        sudo -u nick bash -c 'cd /home/nick/repo && git add . && git commit -m "Commit $i"' &>/dev/null
        echo "[+] Git commit $i added" >> "$LOG_FILE"
    done
}

# --- SIMULATE NETWORK ACTIVITY WITH NETCAT ---

netcat_activity() {
    echo "[+] Generating network activity..."

    sudo -u james bash -c '(nc -lvp 8080 &)' &>/dev/null
    sleep 1
    sudo -u nick bash -c 'echo "GET / HTTP/1.1" | nc localhost 8080' &>/dev/null
    echo "[+] HTTP request sent to port 8080" >> "$LOG_FILE"

    sudo -u james bash -c '(nc -lvp 9000 > /home/james/received.txt &)' &>/dev/null
    sudo -u nick bash -c 'echo "Fake file transfer" | nc localhost 9000' &>/dev/null
    echo "[+] File transfer via Netcat on port 9000" >> "$LOG_FILE"
}

# --- SIMULATE FILE SYSTEM ACTIVITY ---

file_activity() {
    echo "[+] Creating realistic file activity..."

    for i in {1..20}; do
        FILE="/home/james/testfile_${i}.log"
        sudo -u james bash -c "echo 'Log entry $i' > $FILE"
        sudo -u james bash -c "touch -d '2021-$(shuf -i 01-12 -n 1)-$(shuf -i 01-28 -n 1)' $FILE"
        echo "$FILE | Log entry $i" >> "$LOG_FILE"
        echo -ne "\r[James] Creating logs... $i/20"
        sleep 0.05
    done
    echo ""

    for i in {1..30}; do
        FILE="/home/nick/project_${i}.c"
        sudo -u nick bash -c "echo 'int main() { return $i; }' > $FILE"
        sudo -u nick bash -c "touch -d '2021-$(shuf -i 01-12 -n 1)-$(shuf -i 01-28 -n 1)' $FILE"
        echo "$FILE | Code entry $i" >> "$LOG_FILE"
        echo -ne "\r[Nick] Creating project files... $i/30"
        sleep 0.05
    done
    echo ""
}

# --- MAIN FUNCTION ---

main() {
    START_TIME=$(date +%s)
    echo "[+] Starting simulation... Will complete within 5 minutes."

    sysadmin_activity &
    developer_activity &
    netcat_activity &
    file_activity &

    wait

    END_TIME=$(date +%s)
    TOTAL_TIME=$((END_TIME - START_TIME))
    echo "[+] Simulation completed in $TOTAL_TIME seconds."
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

# --- START EXECUTION ---

main
