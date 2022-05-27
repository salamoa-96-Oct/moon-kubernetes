docker ps -a

# tomcat image 생성 #

echo ' tomcat image pull'
docker image pull tomcat
docker images | grep -i tomcat

# tomcat container excution #

echo ' tomcat container excution '
docker run -d --name adminportal -p 8081:8080 tomcat
echo ' deploy.war -> tomcat container '
docker cp /home/ubuntu/workspace/war/hello.war adminportal:/usr/local/tomcat/webapps/
echo ' container stop for custom image '
docker stop adminportal
echo ' custom-image build '
docker commit -a 'deploy-container' adminportal adminportal-tomcat
#docker run -d --name adminportal-tomcat -p 8081:8080 adminportal-tomcat 

echo ' tomcat-container remove '
docker rm adminportal

docker ps -a
docker images
