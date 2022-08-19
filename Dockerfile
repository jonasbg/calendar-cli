FROM python:3.9-alpine

LABEL Author="Jonas Grimsgaard (jonasbg'gmail.com)" 
ENV TZ=Europe/Oslo

RUN apk add --no-cache coreutils && \
    apk add --no-cache --virtual .build-deps gcc libc-dev libxslt-dev && \
    apk add --no-cache libxslt && \
    pip install --no-cache-dir lxml && \
    apk del .build-deps

WORKDIR /calendar-cli
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

RUN ln -s /calendar-cli/calendar-cli.py /usr/local/bin/calendar
