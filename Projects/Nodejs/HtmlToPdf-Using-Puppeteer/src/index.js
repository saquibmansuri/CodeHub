const express = require("express");
const puppeteer = require("puppeteer");
const bodyParser = require("body-parser");
const path = require("path");
const fs = require("fs");

const app = express();
const port = process.env.PORT || 3000;

// Create downloads directory if it doesn't exist
const downloadsDir = path.join(__dirname, "../downloads");
if (!fs.existsSync(downloadsDir)) {
  fs.mkdirSync(downloadsDir);
}

// Use body-parser with increased limit for large HTML content
app.use(bodyParser.json({ limit: "100mb" }));
app.use(bodyParser.urlencoded({ extended: true, limit: "100mb" }));
app.use(express.static("public"));

// Route to convert HTML to PDF
app.post("/convert-html", async (req, res) => {
  const { html, options = {}, filename } = req.body;

  if (!html) {
    return res.status(400).json({ error: "HTML content is required" });
  }

  // Sanitize filename to remove invalid characters
  const sanitizedFilename = filename
    ? filename.replace(/[/\\?%*:|"<>]/g, "-")
    : `document-${Date.now()}`;

  // Generate path with sanitized filename
  const pdfPath = path.join(downloadsDir, sanitizedFilename);

  const exportStyles = `
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      margin: 40px;
      max-width: 900px;
      margin: 40px auto;
    }
  
    
  
    /* Images */
    img {
      max-width: 100%;
      height: auto;
      display: block;
      margin: 1em 0;
    }
    
    /* Code blocks */
    pre {
      background-color: #f5f5f5;
      padding: 25px;
      border-radius: 5px;
      font-family: Consolas, monospace;
      white-space: pre-wrap;
      word-wrap: normal;
      max-width: 100%;
      overflow-x: auto;
    }
    
    /* Embedded content placeholders */
    .iframe-placeholder {
      margin: 20px 0;
      padding: 20px;
      background-color: #f8f9fa;
      border: 2px solid #e9ecef;
      border-radius: 8px;
    }
    
    .iframe-title {
      font-weight: bold;
      color: #1a1a1a;
    }
    
    .iframe-link a {
      color: #0066cc;
      text-decoration: underline;
    }
    
    /* Typography */
    h1, h2, h3 { margin-top: 1em; }
    h1 { font-size: 2em; }
    h2 { font-size: 1.5em; }
    h3 { font-size: 1.17em; }
    p { margin: 1em 0; }
  
    /* Lists */
    ul, ol {
      padding-left: 20px;
      margin: 1em 0;
    }
    
    li {
      margin: 0.5em 0;
    }
    
    /* Links */
    a {
      color: #0066cc;
      text-decoration: underline;
    }
  `;

  const pdfSpecificStyles = `
    /* PDF-specific styles */
    @page {
      margin: 40px;
    }
    
    body {
      max-width: none;
      margin: 0;
      padding: 40px;
    }
  `;

  // Launch Puppeteer
  const browser = await puppeteer.launch({
    headless: true,
    args: ["--no-sandbox"],
  });
  const page = await browser.newPage();

  // Set content with proper styling
  await page.setContent(
    `<!DOCTYPE html>
        <html>
          <head>
            <meta charset="UTF-8">
            <title>${sanitizedFilename}</title>
            <style>
              ${exportStyles}
              ${pdfSpecificStyles}
            </style>
          </head>
          <body>
            ${html}
          </body>
        </html>`
  );

  // Generate PDF with optimal settings
  const pdf = await page.pdf({
    format: "A4",
    margin: {
      top: "40px",
      right: "40px",
      bottom: "40px",
      left: "40px",
    },
    printBackground: true,
    displayHeaderFooter: true,
    headerTemplate: "<div></div>",
    footerTemplate: `
          <div style="font-size: 10px; padding: 10px 40px; width: 100%; text-align: center;">
            Page <span class="pageNumber"></span> of <span class="totalPages"></span>
          </div>
        `,
  });

  await browser.close();

  // Set headers and send the PDF directly in the response
  res.setHeader("Content-Type", "application/pdf");
  res.setHeader(
    "Content-Disposition",
    `attachment; filename="${sanitizedFilename || "document"}.pdf"`
  );
  res.send(pdf); // Send PDF data directly
});

// Simple frontend for testing
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/index.html"));
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
