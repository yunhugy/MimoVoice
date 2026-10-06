FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY story_generator_V2.py .
COPY webapp/ ./webapp/
COPY .env.example .env.example

ENV HOST=0.0.0.0 PORT=5057
EXPOSE 5057

VOLUME ["/app/webapp/data/books"]

CMD ["python", "webapp/app.py"]
