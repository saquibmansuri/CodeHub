# This directory contains python script to copy all data from mssql database to postgresql database

+ main.py - contains code that copies data from mssql to postgres
+ set_sequesnce.py - sets primary key value to max+1 for all tables containing columns with integer datatype 

## STEPS TO RUN THE PYTHON SCRIPTS
Note: If you're going to run this in windows machine then open powershell as admin and execute this command
```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
```
### 1. Go to project directory and create a virtual environment
```
python -m venv venv
```

### 2. Activate virtual environment
+ for windows (cmd)
```
.\venv\Scripts\activate  
```
+ for windows (powershell)
```
.\venv\Scripts\Activate.ps1
```
+ for macos
```
source venv/bin/activate
```

### 3. Install required packages
```
pip install pyodbc psycopg2 psycopg2-binary networkx
```

### 4. Run the script
```
python script_name.py
```

### 5. Deactivate virtual environment
```
deactivate
```

### 6. Remove virtual environment
If you no longer need the environment, you can delete it. 
+ On Windows, you can use rd /s /q venv and
+ On macOS/Linux, use rm -rf venv to remove the environment directory.
