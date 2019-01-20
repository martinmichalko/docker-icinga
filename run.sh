set -e

#cd /data/projects/ansible2-6/pb/ansible-testing_environment/
#time ansible-playbook -i /data/projects/ansible2-6/pb/docker-icinga3/inventory \
#create-update-config.yml \
#--extra-vars "@/data/projects/ansible2-6/pb/docker-icinga3/group_vars/all/test-env-all.yml" \
#-e 'ansible_python_interpreter=/usr/bin/python'

cd /data/projects/ansible2-6/pb/docker-icinga3/
time ansible-playbook -i inventory packages-req.yml docker.yml docker-registry.yml

time ansible-playbook /data/projects/ansible2-6/pb/ansible-testing_environment/snapshot-create.yml \
--extra-vars "@/data/projects/ansible2-6/pb/docker-icinga3/group_vars/all/test-env-all.yml" \
--extra-vars "snapshot_name=02-after-docker-reg"

time ansible-playbook -i inventory docker-mariadb.yml && \
time ansible-playbook -i inventory docker-icinga2.yml

time ansible-playbook -i inventory \
/data/projects/ansible2-6/pb/ansible-testing_environment/snapshot-create.yml \
--extra-vars "@group_vars/all/test-env-all.yml" -e "snapshot_name=03-after-icinga-master-config"

###if you would like to apply additional changes to docker files and mariadb and icinga2 playbooks
### it is enough to revert to snapshot 02-after-docker-reg on all nodes as root user
#ansible-playbook /data/projects/ansible2-6/pb/ansible-testing_environment/snapshot-revert.yml \
#--extra-vars "@/data/projects/ansible2-6/pb/docker-icinga3/group_vars/all/test-env-all.yml" \
#--extra-vars "snapshot_name=02-after-docker-reg"
#
####and after that rerun the playbooks
#
#ansible-playbook -i inventory docker-registry.yml docker-mariadb.yml docker-icinga2.yml
#
#
#time ansible-playbook -i inventory  docker-registry.yml && time ansible-playbook -i inventory  docker-mariadb.yml && time ansible-playbook -i inventory  docker-icinga2.yml
