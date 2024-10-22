ARG TEVERSION
FROM dbeaver/team-dc:$TEVERSION
COPY "cert/private" "/etc/cloudbeaver/private" 
COPY "cert/public" "/etc/cloudbeaver/public" 