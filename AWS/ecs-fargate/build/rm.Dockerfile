ARG TEVERSION
FROM dbeaver/team-rm:$TEVERSION
COPY "cert/public" "/etc/cloudbeaver/public" 
