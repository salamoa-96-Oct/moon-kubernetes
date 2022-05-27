docker rm adminportal
docker stop adminportal-tomcat
docker rm adminportal-tomcat

docker rmi tomcat
docker rmi adminportal-tomcat
docker rmi harbor.kuber.kro.kr/test/adminportal-tomcat
