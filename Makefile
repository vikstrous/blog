run:
	./hugo server -p 3000 --buildDrafts --buildFuture --baseURL https://3000-viktor.cluster-vshwycxzfzanmxri3oyffx7nuq.cloudworkstations.dev/ --appendPort=false --navigateToChanged --liveReloadPort 443
build:
	./hugo
serve-public:
	cd public && python3 -m http.server --bind 0.0.0.0 3000

install-hugo:
	HUGO_VERSION=0.114.0 && \
	curl -sLO https://github.com/gohugoio/hugo/releases/download/v$${HUGO_VERSION}/hugo_$${HUGO_VERSION}_linux-amd64.tar.gz && \
	tar zxvf hugo_$${HUGO_VERSION}_linux-amd64.tar.gz hugo && \
	rm hugo_$${HUGO_VERSION}_linux-amd64.tar.gz

# How to create a new page?
# `hugo new posts/blah-blah.md`