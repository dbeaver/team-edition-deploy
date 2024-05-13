#!/usr/local/bin/python
import os
import sys

compose_project_name = os.environ.get("COMPOSE_PROJECT_NAME")
replica_count_te = int(os.environ.get("REPLICA_COUNT_TE"))

servers_config = "{\n            " + ",\n            ".join(
    f'te{i} = "http://{compose_project_name}-cloudbeaver-te-{i}:8978"' for i in range(1, replica_count_te + 1)
) + "\n        }"

with open("dbeaver-te.locations.template", "r") as file:
    template_content = file.read()

final_content = template_content.replace("{%CLOUDBEAVER_TE_SERVERS%}", servers_config)


with open("dbeaver-te.locations", "w") as file:
    file.write(final_content)