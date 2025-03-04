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
app.use(bodyParser.json({ limit: "50mb" }));
app.use(bodyParser.urlencoded({ extended: true, limit: "50mb" }));
app.use(express.static("public"));

// Route to convert HTML to PDF
app.post("/convert-html", async (req, res) => {
  const { html, options = {} } = req.body;

  if (!html) {
    return res.status(400).json({ error: "HTML content is required" });
  }

  try {
    const browser = await puppeteer.launch({
      headless: "new",
      args: ["--no-sandbox", "--disable-setuid-sandbox"],
    });

    const page = await browser.newPage();

    // Set default viewport for better rendering
    await page.setViewport({
      width: 1200,
      height: 800,
      deviceScaleFactor: 1,
    });

    // Set content and wait for network idle
    await page.setContent(html, {
      waitUntil: "networkidle0",
    });

    const timestamp = Date.now();
    const pdfPath = path.join(downloadsDir, `document_${timestamp}.pdf`);

    // Generate PDF with default or custom options
    await page.pdf({
      path: pdfPath,
      format: options.format || "A4",
      margin: options.margin || {
        top: "20mm",
        right: "20mm",
        bottom: "20mm",
        left: "20mm",
      },
      printBackground: options.printBackground !== false,
      landscape: options.landscape || false,
      ...options,
    });

    await browser.close();

    res.download(pdfPath, (err) => {
      if (err) {
        console.error("Error sending file:", err);
        res.status(500).json({ error: "Error sending file" });
      }
      // Clean up: delete the file after sending
      fs.unlinkSync(pdfPath);
    });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Failed to generate PDF" });
  }
});

// Simple frontend for testing
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/index.html"));
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});