ARG TEVERSION
FROM dbeaver/team-qm:$TEVERSION
COPY "cert/public" "/etc/cloudbeaver/public"
