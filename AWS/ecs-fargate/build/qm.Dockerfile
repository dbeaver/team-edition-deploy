ARG TEVERSION
FROM dbeaver/cloudbeaver-qm:$TEVERSION
COPY "cert/public" "/etc/cloudbeaver/public"
