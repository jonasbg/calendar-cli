FROM python:alpine3.12

LABEL Author="Jonas Grimsgaard (jonasbg'gmail.com)" 
ENV TZ=Europe/Oslo

RUN apk add --no-cache coreutils=8.32-r0 && \
    apk add --no-cache --virtual .build-deps gcc libc-dev libxslt-dev && \
    apk add --no-cache libxslt && \
    pip install --no-cache-dir lxml>=3.5.0 && \
    apk del .build-deps

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM" > /log

################### SUPERCRONIC ###########################
RUN if [ "$TARGETPLATFORM" == "linux/amd64" ] ;\
    then \
        export SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-amd64; \
        export SUPERCRONIC=supercronic-linux-amd64; \
        export SUPERCRONIC_SHA1SUM=048b95b48b708983effb2e5c935a1ef8483d9e3e; \
    elif [ "$TARGETPLATFORM" == "linux/arm64" ] ;\
    then \
        export SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-arm; \
        export SUPERCRONIC=supercronic-linux-arm; \
        export SUPERCRONIC_SHA1SUM=d72d3d40065c0188b3f1a0e38fe6fecaa098aad5; \
    fi \
    && apk add --no-cache curl tzdata\
    && curl -fsSLO "${SUPERCRONIC_URL}" \
    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
    && chmod +x "${SUPERCRONIC}" \
    && mv "${SUPERCRONIC}" "/usr/local/bin/${SUPERCRONIC}" \
    && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic
################### SUPERCRONIC ###########################

# Create a group and user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
# Tell docker that all future commands should run as the appuser user

WORKDIR /calendar-cli
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

RUN ln -s /calendar-cli/calendar-cli.py /usr/local/bin/calendar
USER appuser
