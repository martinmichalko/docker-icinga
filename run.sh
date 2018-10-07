ansible-playbook -i inventory packages-req.yml docker.yml docker-registry.yml

ansible-playbook /data/projects/ansible2-6/pb/ansible-testing_environment/snapshot-create.yml --extra-vars "@/data/projects/ansible2-6/pb/docker-icinga/group_vars/all/test-env-all.yml" --extra-vars "snapshot_name=02-after-docker-reg"

ansible-playbook -i inventory docker-mariadb.yml docker-icinga2.yml
