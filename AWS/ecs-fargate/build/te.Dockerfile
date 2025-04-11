ARG TEVERSION
FROM dbeaver/cloudbeaver-te:$TEVERSION
COPY --chown=8978:8978 "cert/public" "/etc/cloudbeaver/public" 
