FROM dbeaver/cloudbeaver-postgres:16
RUN apt update && apt install -y python3-boto3 python3-botocore
