FROM python:3.9-slim
RUN apt-get update
RUN apt-get install nginx -y
WORKDIR /var/lib/chatbot
COPY ./chatbot  /var/lib/chatbot
COPY ./Docker/newrelic.ini  /var/lib/
RUN pip install -r requirements.txt
RUN pip uninstall jwt==1.3.1 -y
RUN pip uninstall PyJWT==2.8.0 -y
RUN pip install jwt==1.3.1
RUN pip install PyJWT==2.8.0
CMD nginx && python app.py