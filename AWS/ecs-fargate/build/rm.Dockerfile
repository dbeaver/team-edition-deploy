ARG TEVERSION
FROM dbeaver/cloudbeaver-rm:$TEVERSION
COPY "cert/public" "/etc/cloudbeaver/public" 
