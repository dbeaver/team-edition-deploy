## CloudBeaver Team Edition

### Deployment 
- [Docker compose deployment](compose)
- [Kubernetes deployment](k8s)

### Initial configuration

1. Go to deployed server URL
1. Login as `cbadmin`, `cbadmin20`
1. Configuire your license

Now you can use web-based or desktop clients to work

### Misc

- [CloudBeaver public repository](https://github.com/dbeaver/cloudbeaver/)
- [DBeaver Team Edition desktop client](https://dbeaver.com/download/team-edition/)


#### How to change db password for already deployed clusters

- change passwords value eg. `NewStR0NgP2sSw0rD`:
  * for compose `compose/cbte/.env` value of `CLOUDBEAVER_DB_PASSWORD` variable
  * for k8s in `k8s/cbte/values.yaml` value of `backend.cloudbeaver_db_password` variable.

- login into postgres container:
  * for compose from `compose/cbte/` dir run `docker compose exec -it postgres psql -U postgres`
  * for k8s with kubectl `kubectl-do exec -it postgres-*********-***** psql -U postgres`.

- change postgres password(replace `NewStR0NgP2sSw0rD` with your own strong password):
  * `ALTER USER postgres IDENTIFIED BY 'NewStR0NgP2sSw0rD';`

- restart or redeploy cluster services:
  * for compose in `compose/cbte` execute `docker compose restart` command.
  * for k8s in `k8s/` dir execute `helm upgrade cloudbeaver ./cbte`.

