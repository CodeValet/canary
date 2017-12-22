IMAGE_NAME=codevalet/canary

all: check container

check: spec check-container

spec: depends
	./scripts/ruby bundle exec rspec -c \
						--order random \
						--format progress \
						--format html --out rspec.html

rubocop: depends
	./scripts/ruby bundle exec rubocop

depends: Gemfile
	./scripts/ruby bundle install

run: depends
	./scripts/ruby bundle exec puma

check-container: container
	docker run --rm $(IMAGE_NAME):latest bundle exec puma --version

container: depends Dockerfile
	docker build -t $(IMAGE_NAME) .

deploy: container
	docker push $(IMAGE_NAME):latest

clean:
	rm -rf vendor

.PHONY: all depends clean run check container spec check-container rubocop
