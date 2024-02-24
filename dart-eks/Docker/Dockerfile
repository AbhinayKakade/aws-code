FROM us-east4-docker.pkg.dev/experiencedotcom-devops/experiencedotcom-dev/python-v3.7-slim:latest

WORKDIR /var/lib/dart-api

COPY ./dart_api  /var/lib/dart-api
COPY ./Docker/newrelic.ini  /var/lib/
# RUN chmod -R 755 /var/lib/dart-api && chmod 644 /var/lib/newrelic.ini
RUN  pip install -r requirements.txt

CMD ["python", "app.py"]
