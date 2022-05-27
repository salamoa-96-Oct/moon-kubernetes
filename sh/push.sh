docker login https://harbor.kuber.kro.kr
harbor
Harbor12345

echo ' Private repository Success Login '

docker tag adminportal-tomcat harbor.kuber.kro.kr/test/adminportal-tomcat
docker push harbor.kuber.kro.kr/test/adminportal-tomcat

echo ' docker push success '
