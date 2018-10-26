branch_name:=$(shell git branch | grep \* | cut -d' ' -f 2)
image_name:=mwauer/ckan:${branch_name}
build:
	docker build -t ${image_name} .

push:
	docker push ${image_name}

test:
	docker run -it --rm -p 80:5000 ${image_name}
