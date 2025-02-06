const nodemailer = require('nodemailer');
const fs = require('fs');

async function sendEmail() {
    const transporter = nodemailer.createTransport({
        host: process.env.SMTP_SERVER,
        port: process.env.SMTP_PORT,
        secure: process.env.SMTP_SECURE === 'true',
        auth: {
            user: process.env.SMTP_USERNAME,
            pass: process.env.SMTP_PASSWORD
        },
        tls: {
            rejectUnauthorized: false
        }
    });

    const mailOptions = {
        from: process.env.FROM_EMAIL,
        to: process.env.TO_EMAIL,
        subject: process.env.EMAIL_SUBJECT,
        text: process.env.EMAIL_BODY,
        attachments: [
            {
                filename: process.env.EMAIL_ATTACHMENT_FILENAME,
                path: process.env.EMAIL_ATTACHMENT_PATH
            }
        ]
    };

    try {
        let info = await transporter.sendMail(mailOptions);
        console.log('Email sent: ' + info.response);
    } catch (error) {
        console.error('Error sending email:', error);
    }
}

sendEmail();
