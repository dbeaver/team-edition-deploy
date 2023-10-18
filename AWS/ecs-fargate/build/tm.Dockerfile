ARG TEVERSION
FROM dbeaver/cloudbeaver-tm:$TEVERSION
COPY "cert/public" "/etc/cloudbeaver/public" 
