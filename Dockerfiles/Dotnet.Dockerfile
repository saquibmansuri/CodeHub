############################# Base Image ################################
# Use desired/latest version
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app

# Update package lists, install necessary libraries and tools, and cleanup apt cache, etc in base image itself
# Example, installing these for handling image processing, PDF generation
RUN apt update && apt install -y \
    libgdiplus \
    zlib1g \
    fontconfig \
    libfreetype6 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    wget \
    gdebi \
    --no-install-recommends \
    && ln -s /usr/lib/libgdiplus.so /lib/x86_64-linux-gnu/libgdiplus.so \
    && wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb \
    && gdebi --n wkhtmltox_0.12.6.1-3.bookworm_amd64.deb \
    && ln -s /usr/local/lib/libwkhtmltox.so /usr/lib/libwkhtmltox.so \
    && rm -rf /var/lib/apt/lists/* # Remove the apt cache to reduce image size

############################## Server Build ################################
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS serverbuild
WORKDIR /app
COPY . .
WORKDIR "/app/Myproject"
RUN dotnet publish Myproject.csproj -c Release -o /app/publish

############################# Final Image ##################################
FROM base AS final
WORKDIR /app
COPY --from=serverbuild /app/publish .
CMD ["dotnet", "Myproject.dll"]
