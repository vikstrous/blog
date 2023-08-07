run:
	hugo server -p 3000 --buildDrafts --buildFuture --baseURL https://port3000.viktor.anchorlabs.dev/ --appendPort=false --navigateToChanged --liveReloadPort 443
build:
	hugo
serve-public:
	cd public && python3 -m http.server --bind 0.0.0.0 3000