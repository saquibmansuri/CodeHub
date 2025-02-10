const nodemailer = require('nodemailer');
const fs = require('fs');
const path = require('path');
const archiver = require('archiver');

// Function to create a zip file from a directory
async function zipDirectory(sourceDir, outPath) {
  const archive = archiver('zip', { zlib: { level: 9 } });
  const stream = fs.createWriteStream(outPath);

  return new Promise((resolve, reject) => {
    archive
      .directory(sourceDir, false)
      .on('error', (err) => reject(err))
      .pipe(stream);

    stream.on('close', () => resolve());
    archive.finalize();
  });
}

// Function to create temporary directory for zip files
function createTempDir() {
  const tempDir = path.join(__dirname, 'temp_attachments');
  if (!fs.existsSync(tempDir)) {
    fs.mkdirSync(tempDir);
  }
  return tempDir;
}

// Function to clean up temporary directory
function cleanupTempDir(tempDir) {
  if (fs.existsSync(tempDir)) {
    fs.readdirSync(tempDir).forEach((file) => {
      const filePath = path.join(tempDir, file);
      fs.unlinkSync(filePath);
    });
    fs.rmdirSync(tempDir);
  }
}

// Function to create attachment objects for nodemailer
async function createAttachments(paths) {
  const attachments = [];
  const tempDir = createTempDir();

  // Split paths by comma and trim whitespace
  const pathsArray = paths.split(',').map((p) => p.trim());

  try {
    for (const itemPath of pathsArray) {
      // Remove trailing slash if present
      const cleanPath = itemPath.replace(/\/$/, '');

      try {
        const stats = fs.statSync(cleanPath);

        if (stats.isDirectory()) {
          // If it's a directory, zip it first
          const dirName = path.basename(cleanPath);
          const zipPath = path.join(tempDir, `${dirName}.zip`);

          await zipDirectory(cleanPath, zipPath);

          attachments.push({
            filename: `${dirName}.zip`,
            path: zipPath,
            contentType: 'application/zip',
          });

          console.log(`Created zip for directory: ${dirName}`);
        } else {
          // If it's a single file, attach as is
          attachments.push({
            filename: path.basename(cleanPath),
            path: cleanPath,
            contentType: 'application/octet-stream',
          });
        }
      } catch (error) {
        console.warn(
          `Warning: Could not process path ${cleanPath}:`,
          error.message
        );
      }
    }

    return attachments;
  } catch (error) {
    cleanupTempDir(tempDir);
    throw error;
  }
}

async function sendEmail() {
  const tempDir = createTempDir();

  try {
    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_SERVER,
      port: process.env.SMTP_PORT,
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USERNAME,
        pass: process.env.SMTP_PASSWORD,
      },
      tls: {
        rejectUnauthorized: false,
      },
    });

    // Get all files from the specified paths
    const attachments = await createAttachments(
      process.env.EMAIL_ATTACHMENT_PATH
    );

    const mailOptions = {
      from: process.env.FROM_EMAIL,
      to: process.env.TO_EMAIL,
      subject: process.env.EMAIL_SUBJECT,
      text: process.env.EMAIL_BODY,
      attachments: attachments,
    };

    let info = await transporter.sendMail(mailOptions);
    console.log('Email sent: ' + info.response);
    console.log(
      `Attached ${attachments.length} items (directories are zipped)`
    );
  } catch (error) {
    console.error('Error sending email:', error);
    process.exit(1); // Exit with error code to indicate failure in CI/CD
  } finally {
    // Clean up temporary directory
    cleanupTempDir(tempDir);
  }
}

sendEmail();
