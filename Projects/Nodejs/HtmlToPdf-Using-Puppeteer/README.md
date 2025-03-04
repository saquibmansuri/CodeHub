# PDF Downloader

A Node.js application using Puppeteer to download PDFs from web pages. This application provides a simple API endpoint to convert HTML content to PDF files.

## Features

- Convert HTML content to PDF
- Customizable PDF options (format, margins, orientation)
- Express.js server for handling HTTP requests
- Puppeteer for web page rendering and PDF generation
- Docker support for easy deployment
- Automatic downloads directory management
- Simple test frontend included

## Prerequisites

- Node.js v20 or higher
- npm (Node Package Manager)
- Docker and Docker Compose (for containerized deployment)
- Chrome/Chromium (for local development without Docker)

## Installation and Running (Without Docker)

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd <project-directory>
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. **Important: Verify Source Files**
   Make sure your `src/index.js` file contains the proper Express.js server code. If you see any issues with the file content, you can find the correct code in our repository.

4. Start the application:
   - For production:
     ```bash
     npm start
     ```
   - For development (with auto-reload):
     ```bash
     npm run dev
     ```

The server will start on port 3000 by default, and you should see the message: `Server running at http://localhost:3000`

## Running with Docker (Recommended)

The application comes with a Docker Compose configuration which handles all dependencies automatically. This is the recommended way to run the application as it ensures all requirements (including Chromium) are properly set up.

1. Start the application using Docker Compose:

   ```bash
   docker compose up
   ```

   Or to build/rebuild the images before starting:

   ```bash
   docker compose up --build
   ```

2. To run the application in detached mode (background):

   ```bash
   docker compose up -d
   ```

3. To stop the application:
   ```bash
   docker compose down
   ```

## API Usage

The application exposes the following endpoints:

### 1. Web Interface

- **Endpoint**: GET `/`
- Access the simple testing interface by opening `http://localhost:3000` in your browser

### 2. Convert HTML to PDF

- **Endpoint**: POST `/convert-html`
- **Content-Type**: `application/json`
- **Request Body**:
  ```json
  {
    "html": "<html>Your HTML content here</html>",
    "options": {
      "format": "A4",
      "margin": {
        "top": "20mm",
        "right": "20mm",
        "bottom": "20mm",
        "left": "20mm"
      },
      "printBackground": true,
      "landscape": false
    }
  }
  ```
- **Options** (all optional):
  - `format`: Page format (A4, Letter, etc.)
  - `margin`: Page margins in millimeters
  - `printBackground`: Include background graphics (default: true)
  - `landscape`: Page orientation (default: false)
- **Response**: PDF file download

Example using curl:

```bash
curl -X POST \
     -H "Content-Type: application/json" \
     -d '{"html": "<h1>Hello World</h1>", "options": {"format": "A4"}}' \
     http://localhost:3000/convert-html \
     --output output.pdf
```

## Project Structure

```

## Common Issues and Troubleshooting

1. **Application Won't Start**
   - Verify the content of `src/index.js` is correct
   - Check if all dependencies are installed (`npm install`)
   - Ensure port 3000 is not in use by another application

2. **PDF Generation Issues**
   - When running locally, ensure Chrome/Chromium is installed
   - Check if the downloads directory exists and has write permissions
   - Verify the HTML content is valid

3. **Docker Issues**
   - Ensure Docker daemon is running
   - Check if port 3000 is available
   - Verify volume mounting permissions
   - Run `docker compose down` and then `docker compose up --build` to rebuild from scratch

## Environment Variables

The application uses the following environment variables:

- `PORT`: Server port (default: 3000)
- `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD`: Set to true in Docker environment
- `PUPPETEER_EXECUTABLE_PATH`: Path to Chromium executable in Docker environment

## Development Notes

- The application automatically creates a `downloads` directory if it doesn't exist
- PDF files are automatically deleted after being sent to the client
- The development mode (`npm run dev`) uses nodemon for auto-reloading
- The Docker setup includes all necessary dependencies and configurations

## License

This project is free and open-source! You can:
- ✅ Use it for personal projects
- ✅ Use it for commercial projects
- ✅ Modify it as you need
- ✅ Share it with others

Just remember to give credit where it's due and be awesome to others!

## Contributing

Hey there! Want to make this project even better? Awesome! Here's how:

1. 🍴 Fork it
2. 🔨 Make your changes
3. 🎯 Test your changes
4. 💝 Share it back through a pull request

Got ideas? Found a bug? Just want to say hi?
Open an issue and let's chat! All friendly contributions are welcome!

Remember:
- Keep it simple
- Keep it working
- Have fun!
```
