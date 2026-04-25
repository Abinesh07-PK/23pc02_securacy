## Threat Summary
The platform currently supports older protocols like TLS 1.2 and potentially TLS 1.0, along with non-AEAD (Authenticated Encryption with Associated Data) cipher suites. This exposes payment and authentication traffic to downgrade attacks and potential decryption or tampering by man-in-the-middle (MitM) attackers. Since the platform processes sensitive financial data, establishing a secure, state-of-the-art cryptographic channel is critical.

## Mitigation Summary
The Azure Application Gateway and API Management have been configured to enforce a minimum of TLS 1.3, explicitly disabling TLS 1.0 through 1.2. Only AEAD cipher suites are permitted. The server enforces Strict-Transport-Security (HSTS), and the mobile applications implement certificate pinning to prevent interception via malicious root CAs.

## Pre-conditions
- Target API endpoint is accessible (e.g., `api.fooddelivery.local`).
- OpenSSL (`openssl`), cURL (`curl`), and Nmap (`nmap`) are installed on the tester's machine.
- Access to the mobile application binary (APK/IPA) running in a test emulator or physical device.
- An interception proxy (e.g., Burp Suite, OWASP ZAP) is configured with its root CA certificate installed on the mobile test device.

## Test Cases

### TC-007-01: Verify rejection of TLS 1.2 handshakes
- **Type:** Negative (attempts to exploit the old vulnerability)
- **Steps:** 
  1. Open a terminal.
  2. Execute the `openssl` client command to forcefully negotiate a TLS 1.2 connection to the API gateway.
- **Expected Result:** The server should immediately terminate the handshake and refuse the connection with a protocol version alert or handshake failure.
- **Pass Criteria:** No certificate is returned, and the output contains an error confirming protocol rejection (e.g., `alert protocol version` or `no protocols available`).
- **Tools/Commands:** 
  ```bash
  openssl s_client -connect api.fooddelivery.local:443 -tls1_2
  ```

### TC-007-02: Verify rejection of TLS 1.0 handshakes
- **Type:** Negative (attempts to exploit the old vulnerability)
- **Steps:**
  1. Open a terminal.
  2. Execute the `openssl` client command to forcefully negotiate a TLS 1.0 connection.
- **Expected Result:** The server terminates the handshake and refuses the connection.
- **Pass Criteria:** Similar to TC-007-01, the server explicitly rejects the TLS 1.0 ClientHello.
- **Tools/Commands:** 
  ```bash
  openssl s_client -connect api.fooddelivery.local:443 -tls1
  ```

### TC-007-03: Verify Strict-Transport-Security (HSTS) header configuration
- **Type:** Positive (verifies mitigation is working)
- **Steps:**
  1. Send a standard GET or HEAD request to the API gateway over HTTPS and inspect the response headers.
- **Expected Result:** The server responds with the `Strict-Transport-Security` header correctly formatted.
- **Pass Criteria:** The header exactly matches `Strict-Transport-Security: max-age=31536000; includeSubDomains`.
- **Tools/Commands:** 
  ```bash
  curl -s -I https://api.fooddelivery.local | grep -i "Strict-Transport-Security"
  ```

### TC-007-04: Verify advertisement of only AEAD cipher suites
- **Type:** Positive (verifies mitigation is working)
- **Steps:**
  1. Run an Nmap SSL enumeration script against the target endpoint to list all supported ciphers.
  2. Review the output for any CBC, RC4, or non-AEAD block ciphers.
- **Expected Result:** The server should only advertise AEAD ciphers (e.g., those using GCM or CHACHA20).
- **Pass Criteria:** No ciphers graded as weak are listed; all listed ciphers for TLS 1.3 are AEAD compliant.
- **Tools/Commands:** 
  ```bash
  nmap --script ssl-enum-ciphers -p 443 api.fooddelivery.local
  ```

### TC-007-05: Verify certificate pinning in mobile application
- **Type:** Negative (attempts to exploit the old vulnerability)
- **Steps:**
  1. Configure the mobile device/emulator to route traffic through the interception proxy (e.g., Burp Suite).
  2. Ensure the proxy's self-signed CA is installed and trusted in the device's system trust store.
  3. Launch the mobile application and attempt to log in.
- **Expected Result:** The application should detect that the certificate presented by the proxy does not match the pinned certificate.
- **Pass Criteria:** The application drops the connection, displays a generic network error to the user, and no HTTP request data is visible in the proxy's HTTP history.
- **Tools/Commands:** Burp Suite Professional / Community, Android Emulator / iOS Simulator.

## Compliance Check
- **PCI-DSS v4.0 Req 4.2.1:** Strong cryptography and security protocols are implemented to safeguard PAN during transmission over open, public networks.
- **SOC 2 CC6.7:** Protection of data during transmission.

## Evidence to Collect
- Terminal output logs (or screenshots) from the `openssl` and `curl` commands.
- The `nmap` output text file showing the enumerated ciphers.
- A screenshot from Burp Suite showing the failed TLS handshake alert from the mobile application (e.g., "The client failed to negotiate a TLS connection").
