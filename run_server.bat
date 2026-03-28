@echo off
cd "C:\Users\igleb\Documents\python"
call venv\Scripts\activate.bat
python -m uvicorn server:app --host 0.0.0.0 --port 8000
pause