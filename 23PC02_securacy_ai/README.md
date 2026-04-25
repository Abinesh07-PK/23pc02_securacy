# Securacy Cyber Engineering Intern Assessment

This repository contains the deliverables for the Securacy Cybersecurity Intern Assessment, focusing on Threat Mitigation Validation.

## Overview

The assessment involves writing rigorous, repeatable test cases to verify the implementation of security mitigations for a cloud-hosted food delivery platform running on Azure. Think of these as QA test specifications designed to prove whether a vulnerability is truly closed or a control is correctly applied.

### Directory Structure

- `/tests/`: Contains the Markdown-based test specifications (`T00X_test_spec.md`).
- `/scripts/`: Contains runnable automated test scripts (Bonus Task 2).
- `README.md`: Assessment summary and compliance mapping.

## Implemented Deliverables

1. **T007 / M007 - Cryptography: TLS Version Enforcement**: Thorough test cases to verify the restriction to TLS 1.3, proper HSTS headers, AEAD ciphers, and mobile certificate pinning.
2. **T009 / M009 - Data Protection: Backup Security**: Test cases to validate Azure Backup WORM policies, RBAC access controls, Customer-Managed Key encryption, and RTO recovery drills.
3. **Bonus Task 2: Automated Test Script**: A bash script (`scripts/test_tls_rejection.sh`) that automatically checks for the rejection of TLS 1.2 and TLS 1.0, and outputs `PASS` or `FAIL`.
4. **Bonus Task 3: False Positive Analysis (T010)**: Test cases for an injection threat (WAF) focused on preventing over-blocking of legitimate user inputs.
5. **Bonus Task 4: Compliance Mapping Table**: (See below)

## Bonus Task 4: Compliance Mapping Table

| Mitigation ID & Name | Addressed Standard / Clause | Rationale / How the Test Evidences Compliance |
| :--- | :--- | :--- |
| **M007 - TLS Version Enforcement** | **PCI-DSS v4.0 Req 4.2.1**|Strong cryptography and security protocols are implemented to safeguard PAN during transmission over open, public networks. | The tests (TC-007-01, TC-007-02, TC-007-04) explicitly verify that weak protocols (TLS 1.0, 1.2) and non-AEAD ciphers are disabled. Capturing openssl outputs proves that only strong cryptography (TLS 1.3) is supported for transmission. |
| **M007 - HSTS Enforcement** | **SOC 2 (Security) CC6.7**|The entity restricts logical and physical access to data... | The HSTS test (TC-007-03) proves the server instructs browsers to strictly use HTTPS, minimizing the risk of logical interception via downgrade or man-in-the-middle attacks. |
| **M009 - Backup WORM & RBAC** | **GDPR Article 32(1)(c)**|Ability to restore the availability and access to personal data in a timely manner in the event of a physical or technical incident. | The WORM policy and RBAC access tests (TC-009-01, TC-009-02) prove that the backups cannot be tampered with or deleted by unauthorized actors (e.g., ransomware), ensuring availability. |
| **M009 - Recovery Drills** | **SOC 2 (Availability) A1.3**|The entity tests its recovery plan to determine whether it is capable of meeting its recovery time objectives. | The simulated recovery test (TC-009-03) explicitly measures the Time to Recover (TTR) against the defined 4-hour Recovery Time Objective (RTO) and captures logs as evidence of a successful drill. |
| **M009 - Backup Encryption (CMK)** | **PCI-DSS v4.0 Req 3.5.1**|PAN is secured wherever it is stored using strong cryptography. | The CMK validation test (TC-009-04) inspects the Azure Storage account properties to ensure data at rest is encrypted with a key controlled by the customer, satisfying the requirement for stored data protection. |
