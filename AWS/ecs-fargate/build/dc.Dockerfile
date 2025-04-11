ARG TEVERSION
FROM dbeaver/cloudbeaver-dc:$TEVERSION
COPY --chown=8978:8978 "cert/private" "/etc/cloudbeaver/private" 
COPY --chown=8978:8978 "cert/public" "/etc/cloudbeaver/public" 