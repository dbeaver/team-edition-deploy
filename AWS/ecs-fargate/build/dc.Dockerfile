ARG TEVERSION
FROM dbeaver/cloudbeaver-dc:$TEVERSION
COPY "cert/private" "/etc/cloudbeaver/private"
COPY "cert/public" "/etc/cloudbeaver/public"
