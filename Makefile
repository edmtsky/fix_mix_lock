init:
	asdf set erlang 24.1.2
	asdf set elixir 1.12.3-otp-24

build:
	rm ./fix_mix_lock-*.ez || true
	MIX_ENV=prod mix archive.build

install:
	mix archive.install ./fix_mix_lock-*.ez

uninstall:
	mix archive.uninstall fix_mix_lock
