.PHONY: format

format:
	shfmt -w entrypoint.sh src/services/*.sh src/utils/*.sh android-emulator/entrypoint.sh
	yarn format
