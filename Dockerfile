FROM python:alpine3.12

LABEL Author="Jonas Grimsgaard (jonasbg'gmail.com)" 
ENV TZ=Europe/Oslo

RUN apk add --no-cache coreutils=8.32-r0 && \
    apk add --no-cache --virtual .build-deps gcc libc-dev libxslt-dev && \
    apk add --no-cache libxslt && \
    pip install --no-cache-dir lxml>=3.5.0 && \
    apk del .build-deps

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=048b95b48b708983effb2e5c935a1ef8483d9e3e

RUN apk add --no-cache curl=7.69.1-r3 tzdata\
    && curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
    && chmod +x "$SUPERCRONIC" \
    && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
    && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

# Create a group and user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
RUN mkdir /data && chmod 777 /data
# Tell docker that all future commands should run as the appuser user

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
RUN chmod +x script.sh

USER appuser

RUN ln -s /calendar-cli/calendar-cli.py /bin/calendar