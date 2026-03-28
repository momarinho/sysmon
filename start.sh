#!/user/bin/env bash
cd backend && uvicorn main:app --host 127.0.0.1 --port 8000 &
PYTHON_PID=$!
cd ../frontend && flutter run -d linux
kill $PYTHON_PID
