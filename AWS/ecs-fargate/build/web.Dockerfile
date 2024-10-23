ARG TEVERSION
FROM dbeaver/team-web:$TEVERSION
COPY "cert/public" "/etc/cloudbeaver/public" 
