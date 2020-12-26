FROM python:alpine3.12

ENV CALDAV_URL=
ENV CALDAV_USER=
ENV CALDAV_PASS=
ENV CALDAV_CALENDAR_URL=
ENV TZ=Europe/Oslo

RUN apk add --no-cache jq && \
    apk add --no-cache --virtual .build-deps gcc libc-dev libxslt-dev && \
    apk add --no-cache libxslt && \
    pip install --no-cache-dir lxml>=3.5.0 && \
    apk del .build-deps

RUN pip install pytz tzlocal icalendar vobject caldav python-dateutil --upgrade

# Create a group and user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
RUN mkdir /data && chmod 777 /data
# Tell docker that all future commands should run as the appuser user

WORKDIR /app
COPY . .
RUN chmod +x entrypoint && chmod +x script.sh
RUN mv entrypoint /etc/periodic/hourly/

RUN ./setup.py install

USER appuser

CMD "crond -f -l 8"