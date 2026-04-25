## Threat Summary
Currently, the backup strategy lacks encryption, formal access controls, and recovery testing. This is a critical vulnerability: in the event of a ransomware attack, both production databases and their backups could be encrypted or destroyed simultaneously, leading to catastrophic data loss and inability to recover.

## Mitigation Summary
Azure Backup has been implemented with geo-redundant storage and WORM (Write Once, Read Many) immutable blobs to prevent tampering. Dedicated RBAC (Role-Based Access Control) policies segregate backup management from general administration. Backups are encrypted at rest using Customer-Managed Keys (CMK), and the architecture is designed to support an RPO of 1 hour and an RTO of 4 hours, verified by monthly drills.

## Pre-conditions
- Azure CLI (`az`) is installed and authenticated.
- Tester has access to two distinct Azure AD (Entra ID) accounts: 
  - `User_A`: Standard Contributor (No Backup RBAC).
  - `User_B`: Authorized Backup Operator.
- An active Azure Recovery Services Vault containing recent backups.
- Azure Key Vault containing the Customer-Managed Key used for encryption.
- Target resources (e.g., a non-production test database) are available for a restore drill.

## Test Cases

### TC-009-01: Attempt deletion of an immutable backup blob
- **Type:** Negative (attempts to exploit the old vulnerability)
- **Steps:**
  1. Authenticate to Azure CLI as `User_B` (Authorized Backup Operator).
  2. Attempt to explicitly delete a recovery point (blob) from the vault prior to its retention expiry.
- **Expected Result:** The deletion attempt should be blocked at the storage/vault level due to the WORM/immutability policy.
- **Pass Criteria:** The Azure API returns a clear error indicating the action is forbidden by policy (e.g., "Cannot delete an immutable blob" or Vault protection error).
- **Tools/Commands:** 
  ```bash
  # Attempt to delete the backup data
  az backup disable-protection --resource-group <rg_name> --vault-name <vault_name> \
      --item-name <item> --container-name <container> \
      --backup-management-type AzureIaasVM \
      --delete-backup-data true
  ```

### TC-009-02: Attempt access to Backup Vault without proper RBAC
- **Type:** Negative (attempts to exploit the old vulnerability)
- **Steps:**
  1. Authenticate to Azure CLI or Azure Portal as `User_A` (No Backup RBAC).
  2. Attempt to list recovery points or modify backup policies in the designated Recovery Services Vault.
- **Expected Result:** The platform denies access.
- **Pass Criteria:** Azure API returns a `403 Forbidden` or `AuthorizationFailed` error detailing that the user lacks the `Microsoft.RecoveryServices/vaults/...` action permissions.
- **Tools/Commands:** 
  ```bash
  az backup recoverypoint list --vault-name <vault_name> \
      --resource-group <rg_name> --item-name <item> --container-name <container> \
      --backup-management-type AzureIaasVM
  ```

### TC-009-03: Simulate a database recovery (RTO validation)
- **Type:** Positive (verifies mitigation is working)
- **Steps:**
  1. Authenticate as `User_B`.
  2. Initiate a restore operation for the primary database to an alternate location, selecting a point-in-time exactly 2 hours prior.
  3. Start a timer.
  4. Monitor the restore job until completion and verify the database is online and queryable.
  5. Stop the timer.
- **Expected Result:** The restore completes successfully, and the data matches the 2-hour-ago state.
- **Pass Criteria:** The total time elapsed from starting the restore to the database being fully operational is less than or equal to 4 hours (the defined RTO).
- **Tools/Commands:** 
  ```bash
  az backup restore restore-disks --resource-group <rg_name> --vault-name <vault_name> \
      --container-name <container> --item-name <item> --rp-name <rp_name> \
      --storage-account <storage_account>
  ```
  *(Measure time using the Azure portal job logs or terminal `time` function)*

### TC-009-04: Verify Customer-Managed Key (CMK) encryption configuration
- **Type:** Positive (verifies mitigation is working)
- **Steps:**
  1. Use Azure CLI to inspect the encryption properties of the Recovery Services Vault and underlying storage account.
- **Expected Result:** The vault/storage reports that encryption is enabled and specifies a Key Vault URI rather than a Microsoft-managed key.
- **Pass Criteria:** The `encryption.keyVaultProperties` object in the JSON output contains a valid `keyUri` and state is `Enabled`.
- **Tools/Commands:** 
  ```bash
  az recoveryservices vault show --name <vault_name> --resource-group <rg_name> --query "properties.encryption"
  ```

## Compliance Check
- **GDPR Article 32(1)(c):** Ability to restore the availability and access to personal data in a timely manner.
- **SOC 2 A1.3:** The entity tests its recovery plan to determine whether it is capable of meeting its recovery time objectives.
- **PCI-DSS Req 3.5.1:** PAN is secured wherever it is stored using strong cryptography.

## Evidence to Collect
- JSON error responses from the Azure CLI for the negative test cases (WORM and RBAC checks).
- Timing logs and job completion status screenshots from the Azure Portal for the RTO drill.
- JSON output showing the encryption configuration properties for the vault.
