echo "-----------------------------"
echo "Deploying datasources"
echo "-----------------------------"
sudo docker-compose exec grafana /var/lib/grafana/ds/files/add_datasources.sh
echo ""
echo "-----------------------------"
echo "Deploying Dashboards"
echo "-----------------------------"
sudo docker-compose exec grafana /var/lib/grafana/ds/files/add_dashboards.sh