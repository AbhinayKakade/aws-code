FROM 387102133919.dkr.ecr.us-east-1.amazonaws.com/python-v3.7-slim:latest

WORKDIR /var/lib/public-dart-api

COPY ./dart_api/requirements.txt  /var/lib/public-dart-api
COPY ./public_dart_api  /var/lib/public-dart-api
COPY ./Docker/publicapi_newrelic/newrelic.ini  /var/lib/

RUN chmod -R 755 /var/lib/public-dart-api && chmod 644 /var/lib/newrelic.ini
RUN  pip install -r requirements.txt

CMD ["python", "app.py"]
