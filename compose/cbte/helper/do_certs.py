import subprocess
import re
import os
import time
import sys

email = sys.argv[1]
domain = sys.argv[2]
rsa_key_size = sys.argv[3]
staging_arg = sys.argv[4]

command = [
    "docker compose", "run", "--rm", "--entrypoint",
    f"certbot certonly --manual --preferred-challenges dns --email {email}  -d {domain} --rsa-key-size {rsa_key_size} {staging_arg} --agree-tos --force-renewal", "certbot"
]


process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE, text=True)


output_lines = []


for line in iter(process.stdout.readline, ''):
    if line.strip(): 
        output_lines.append(line.strip())
        # print(line, end='')
        if "Before continuing, verify the TXT record has been deployed" in line:
            if output_lines:
                dns_key = output_lines[-2]
                print(f"Extracted key: {dns_key}")
                # send to service
            else:
                print("No key found.")
            break


time.sleep(30)
process.stdin.write('\n')
process.stdin.flush()


for i in range(10):
    line = process.stdout.readline()
    if line.strip():
        print(line, end='')


process.terminate()
try:
    process.wait(timeout=10)
except subprocess.TimeoutExpired:
    process.kill()
