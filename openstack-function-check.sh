source ~/overcloudrc
openstack network create test-network --share
openstack subnet create test-subnet --subnet-range '192.168.1.0/24' --network test-network
openstack router create test-router
openstack router add subnet test-router test-subnet
openstack network create test-external --external  --provider-network-type flat --provider-physical-network datacentre
openstack subnet create test-external-subnet --subnet-range 192.168.24.0/24  --gateway 192.168.24.1 --allocation-pool start=192.168.24.200,end=192.168.24.240 --no-dhcp --network test-external
openstack router set test-router --external-gateway test-external
sudo yum -y install openstack-tempest python-glance-tests python-keystone-tests python-horizon-tests-tempest python-neutron-tests python-cinder-tests python-nova-tests python-swift-tests python-ceilometer-tests python-gnocchi-tests python-aodh-tests
tempest init overcloud-test
cd overcloud-test/
tempest workspace list
export EXT_NET=$( openstack network list  |grep test-external |awk '{print $2}')
discover-tempest-config --deployer-input ~/tempest-deployer-input.conf --debug --create identity.uri $OS_AUTH_URL identity.admin_password $OS_PASSWORD --network-id $EXT_NET
ostestr '.*smoke'
#Remove the provisioned resources
export TEST_NET=$(openstack network list |grep test-network |awk '{print $2}')
export TEST_SUBNET=$(openstack subnet list |grep $TEST_NET |awk '{print $2}')
for i in $(openstack port list |grep $TEST_SUBNET |awk '{print $2}'); do openstack router remove port test-router $i ; done
openstack router delete test-router
openstack network delete test-network
openstack network delete test-external
