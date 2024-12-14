# PostgreSQL Backup with Encryption

Summary
This guide provides instructions on how to generate a GPG key, run a backup script for PostgreSQL databases, and securely manage encryption keys. It also includes steps to decrypt encrypted backups on both Linux and Windows.  
You can use other platforms to dump the encrypted file other than s3, this is just an example.

## Prerequisites
 - PostgreSQL
 - GnuPG
 - AWS CLI configured with access to an S3 bucket
 - Linux or Windows operating system

### Generate GPG Key
Run the following commands to generate a GPG key: 
`gpg --full-generate-key`  
Follow the on-screen prompts to select the key type, size, expiration, and enter user ID information (name, email). Note the key ID or email used for encryption.

### Backup and Encryption Script
The script provided in the repository automates the process of backing up a PostgreSQL database, encrypting the backup, and uploading it to an AWS S3 bucket.  
As mentioned earlier, this is just an example of encryption, you can use other services as well according to your needs.

### Remove GPG Key from Server
After securing a backup of your .gnupg folder somewhere remove the key from the server so nobody can decrypt if server access is compromised (recommended):  
`gpg --delete-secret-keys <key-id>`  
Replace <key-id> with the ID of the key you want to remove.

### Restore Encrypted File
 1. Linux  
      - Install GPG (if not installed):  
        `sudo apt-get install gnupg`
        
      - Decrypt File  
        `gpg --output decrypted_backup.sql --decrypt encrypted_backup.sql.gpg`  


 2. Windows  
      - Install Gpg4win:  
        Download and install from Gpg4win.org.

      - Decrypt File:  
        Use Kleopatra or command line:  
        `gpg --output decrypted_backup.sql --decrypt encrypted_backup.sql.gpg`  

## Conclusion
This covers the essential steps for managing database backups securely, including encryption, storage, and decryption across different platforms.  
Adjust paths and parameters as necessary to fit your environment.  
