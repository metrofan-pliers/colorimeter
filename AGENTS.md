# Colorimeter Project

## Project Structure
- `.ino` file: ESP32 firmware (main embedded code for the colorimeter device)
- `server.py`: FastAPI server that receives/returns color data from the device
- `run_server.bat`: Windows batch to start the server

## Running the Server
The server requires a Python virtual environment at `C:\Users\igleb\Documents\python\venv`. Use the batch file:
```
run_server.bat
```
Or manually:
```bash
cd C:\Users\igleb\Documents\python
venv\Scripts\activate
python -m uvicorn server:app --host 0.0.0.0 --port 8000
```

## API Endpoints
- `POST /color` - receive color data from device
- `GET /color` - retrieve latest color reading

## No CI/Testing
This repo has no tests, linting, or automated checks configured.
