ARG TEVERSION
FROM dbeaver/cloudbeaver-tm:$TEVERSION
COPY --chown=8978:8978 "cert/public" "/etc/cloudbeaver/public" 
