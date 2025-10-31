##Load from python
#FROM python:3.10-slim
##copy all files
#COPY . .
##Run requirements to install packages
#RUN pip install --no-cache-dir -r requirements.txt
#When you run, run check_setup.py
#CMD ["python", "/app/src/app/titanic_pipeline.py"]

FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# install build tools only if you ever hit binary build errors
# RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
#     && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt
RUN pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r /app/requirements.txt

COPY src /app/src

CMD ["python", "/app/src/app/titanic_pipeline.py"]