FROM alpine:3.20

RUN apk add --no-cache \
    bash \
    curl \
    nginx \
    dcron \
    tzdata \
    && rm -rf /var/cache/apk/*

ENV TZ=Europe/Madrid
ENV REFRESH_INTERVAL=5

WORKDIR /app

COPY Dashboard.sh .
COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /app/Dashboard.sh /entrypoint.sh \
    && mkdir -p /var/www/dashboard \
    && mkdir -p /run/nginx

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
