.PHONY: format

format:
	shfmt -w entrypoint.sh
	yarn prettier --write . --config .prettierrc
