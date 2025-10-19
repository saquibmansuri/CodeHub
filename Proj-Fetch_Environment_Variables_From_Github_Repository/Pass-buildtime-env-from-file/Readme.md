# 🐳 Pass Environment Variables During Buildtime in Docker with `.env` file Variables (for Frontend Frameworks)

## 📘 Overview

Some frontend frameworks (like **vite**, **astro**, etc.) require environment variables **at build time**, not runtime.
Using `env_file:` in Docker Compose only applies at runtime — so these frameworks won’t pick up the variables during build.

This guide shows how to automatically pass all variables from a `.env` file as Docker build arguments.

Additionally, it handles **Dockerfile preparation** so that ARG + ENV lines are inserted automatically **after each WORKDIR**. This ensures multi-stage builds also get the variables without duplication.

---

## ⚙️ Example `.env`

Note: I have added comment, empty line in the example on purpose to show that this solution also handles such cases

```bash
saquib='mans$uri'
# This is a comment
var1='value1'

var2='value2'
var3=1223
var4=#123
```

---

## 🛠️ Prepare the Dockerfile

Before running the Compose build, you need to **inject ARG + ENV lines** into the Dockerfile for all variables in your `.env` file.
This is done via the `script.sh`:

```bash
#!/bin/bash

DOCKERFILE=${1:-Dockerfile}
ENV_FILE=${2:-.env}

awk -v envfile="$ENV_FILE" '
BEGIN {
    # Read .env and store variable names in env_vars array
    while ((getline line < envfile) > 0) {
        # Skip blank lines and comments
        if (line ~ /^[[:space:]]*$/ || line ~ /^[[:space:]]*#/) continue
        split(line, parts, "=")
        varname = parts[1]
        env_vars[varname] = 1
    }
}
{
    skip = 0
    # Check if current line is ARG/ENV for any of the env_vars
    for (v in env_vars) {
        if ($0 ~ "^ARG[[:space:]]+" v "$" || $0 ~ "^ENV[[:space:]]+" v "[$=]") {
            skip = 1
            break
        }
    }
    if (!skip) print

    # If line is WORKDIR, insert ARG+ENV lines for all env_vars
    if ($1 == "WORKDIR") {
        for (v in env_vars) {
            print "ARG " v
            print "ENV " v "=$" v
        }
    }
}
' "$DOCKERFILE" > "$DOCKERFILE.tmp" && mv "$DOCKERFILE.tmp" "$DOCKERFILE"

rm -f "$DOCKERFILE.tmp"
```

### Purpose of the Script

* Inserts `ARG <var>` and `ENV <var>=$<var>` **after each WORKDIR** in your Dockerfile (to handle multistage scenarios)
* Avoids duplicates for variables already defined from `.env`
* Preserves any **manually defined ARG/ENV** lines in the Dockerfile (pre existing)
* Works for **multi-stage Dockerfiles** automatically

**Usage:**

```bash
chmod +x script.sh
# for using defalt values
./script.sh
# for using custom file names
./script.sh fe.Dockerfile fe.env
```

After running this, your Dockerfile is ready for the build process.
### Example Dockerfile (Single Stage) After Running `script.sh`

```dockerfile
FROM node:24-alpine

WORKDIR /app
ARG saquib
ENV saquib=$saquib
ARG var1
ENV var1=$var1
ARG var2
ENV var2=$var2

ENV PORT=3000 # this already exists and stays untouched
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
```


---

## 🧩 Preview the Build Command

To just **see** the full Docker command that will be executed:

```bash
echo docker compose -f docker-compose-custom.yml build $(grep -vE '^#|^$' .env | xargs -d '\n' -I {} echo --build-arg {}) myapp
```

This prints something like:

```bash
docker compose -f docker-compose-custom.yml build --build-arg saquib='mans$uri' --build-arg var1='value1' --build-arg var2='value2' --build-arg var3=1223 --build-arg var4=#123 myapp
```

---

## 🚀 Build the Image

Once you’ve verified the command looks correct, remove the `echo` to actually build:

```bash
docker compose -f docker-compose-custom.yml build $(grep -vE '^#|^$' .env | xargs -d '\n' -I {} echo --build-arg {}) myapp
```

---

## 🧠 Notes

* Commented lines (`# ...`) and blank lines are ignored.
* Quotes (`'` or `"`) are preserved exactly as written in `.env`.
* Replace `frontend.env` with your actual env file name if different.
* Replace `myapp` with your service name.
* Remove `-f docker-compose-custom.yml`, only use this flag if your file is not named as `docker-compose.yml`.
* Run `script.sh` **before building**, so the Dockerfile has all the required ARG + ENV lines.
* Recommended structure in .env files, var1='value1'

---

## ✅ Result

All `.env` variables are passed to the Docker build automatically, without needing to pass them manually OR adding in compose file manually:

```
--build-arg var1='value1' --build-arg var2='value2' --build-arg var3='value3' ...

# FLOW
build-arg (flag) --> ARG (in dockerfile) --> ENV (in dockerfile)
```

---

This integrates **both the Compose command method and the Dockerfile preparation**, so your frontend builds like Vite can pick up environment variables at build time.  
I HOPE DOCKER GIVES US SOME INBUILT FUNCTIONALITY TO HANDLE THIS IN AN UPDATE, FINGERS CROSSED :)
