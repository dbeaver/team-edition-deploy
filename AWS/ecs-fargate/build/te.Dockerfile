ARG TEVERSION
FROM dbeaver/cloudbeaver-te:$TEVERSION
COPY "cert/public" "/etc/cloudbeaver/public" 
