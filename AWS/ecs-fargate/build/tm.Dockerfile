ARG TEVERSION
FROM dbeaver/team-tm:$TEVERSION
COPY "cert/public" "/etc/cloudbeaver/public" 
