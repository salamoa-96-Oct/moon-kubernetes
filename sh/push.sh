docker login https://harbor.kuber.kro.kr
[harbor-id]
[harbor-password]

echo ' Private repository Success Login '

docker tag adminportal-tomcat harbor.kuber.kro.kr/test/adminportal-tomcat
docker push harbor.kuber.kro.kr/test/adminportal-tomcat

echo ' docker push success '
