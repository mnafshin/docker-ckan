branch_name:=$(shell git branch | grep \* | cut -d' ' -f 2)
image_name:=earthquakesan/ckan:${branch_name}
build:
	docker build --no-cache -t ${image_name} .

push:
	docker push ${image_name}
