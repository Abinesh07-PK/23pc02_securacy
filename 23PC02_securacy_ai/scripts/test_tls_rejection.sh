# Description: Automated test script for TC-007-01 and TC-007-02.
#              Verifies that a target endpoint actively rejects TLS 1.2 and 
#              TLS 1.0 connections.
# Usage:       ./test_tls_rejection.sh <target_host> <port>
# Example:     ./test_tls_rejection.sh api.fooddelivery.local 443
# ==============================================================================

TARGET=${1:-"api.fooddelivery.local"}
PORT=${2:-443}

echo " Starting Automated TLS Policy Enforcement Test"
echo " Target: $TARGET:$PORT"

# Function to test a specific TLS version
test_tls_version() {
    local tls_flag=$1
    local tls_name=$2

    echo -n "Testing $tls_name rejection... "
    
    # Run openssl and capture output. Timeout added to prevent hanging.
    OUTPUT=$(timeout 5 openssl s_client -connect $TARGET:$PORT $tls_flag 2>&1 < /dev/null)
    
    # Check for common OpenSSL rejection signatures
    if echo "$OUTPUT" | grep -qiE "handshake failure|no protocols available|alert protocol version|write:errno=0|Connection reset by peer"; then
        echo -e "\033[0;32m[PASS]\033[0m"
        echo "  -> Handshake successfully rejected as expected."
        return 0
    else
        echo -e "\033[0;31m[FAIL]\033[0m"
        echo "  -> Handshake was NOT rejected. Vulnerability may still exist."
        echo "  -> Output snapshot: $(echo "$OUTPUT" | head -n 3 | tr -d '\n')"
        return 1
    fi
}

FAILED=0

# Test TLS 1.0
test_tls_version "-tls1" "TLS 1.0"
if [ $? -ne 0 ]; then FAILED=1; fi

# Test TLS 1.2
test_tls_version "-tls1_2" "TLS 1.2"
if [ $? -ne 0 ]; then FAILED=1; fi

echo "============================================================"
if [ $FAILED -eq 0 ]; then
    echo -e "Overall Status: \033[0;32mPASS\033[0m - Mitigation is effective."
    exit 0
else
    echo -e "Overall Status: \033[0;31mFAIL\033[0m - Vulnerabilities found."
    exit 1
fi
