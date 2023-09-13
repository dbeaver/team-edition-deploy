FROM postgres:14
RUN apt update && apt install -y python3-boto3 python3-botocore
COPY "cloudbeaver-db-init.sql" "/docker-entrypoint-initdb.d/cb-init.sql" 
