
## How to change db password for already deployed clusters


- change passwords value eg. `NewStR0NgP2sSw0rD`:
  * for compose `compose/cbte/.env` value of `CLOUDBEAVER_DB_PASSWORD` variable
  * for k8s in `k8s/cbte/values.yaml` value of `backend.cloudbeaver_db_password` variable.

- login into postgres container:
  * for compose from `compose/cbte/` dir run `docker compose exec -it postgres psql -U postgres`
  * for k8s with kubectl `kubectl-do exec -it postgres-*********-***** psql -U postgres`.

- change postgres password(replace `NewStR0NgP2sSw0rD` with your own strong password):
  * `ALTER USER postgres WITH PASSWORD 'NewStR0NgP2sSw0rD';`

- restart or redeploy cluster services:
  * for compose in `compose/cbte` execute `docker compose up -d` command.
  * for k8s in `k8s/` dir execute `helm upgrade cloudbeaver ./cbte`.
