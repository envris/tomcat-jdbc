for file in *.Dockerfile; do
    tag=$(basename $file ".Dockerfile")
    docker build -t "envris/tomcat-jdbc:${tag}" --build-arg http_proxy=$http_proxy --file $file .
done
