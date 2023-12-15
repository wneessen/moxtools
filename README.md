Moxtools is a web app for inspecting mail infrastructure, serving as a showcase
for reusing some of the Go packages of https://github.com/mjl-/mox, an email
server.

Moxtools runs at https://tools.xmox.nl, but you can easily run it locally
without the rate limiting.

Similar functionality is also included in mox as subcommands (cli).

# Functionality

- Analyse SMTP server settings for a domain, looking up information in DNS
  (DNSSEC, MX, SPF, DMARC, TLSRPT, DANE, MTA-STS), and connecting to at most 2
  SMTP servers.
- Verify the DKIM signatures in a message.
- Check SPF result for a given sending IP address for a given sender domain name.
- Lookup DKIM record given a selector and domain.

# Running locally

Download the latest version from https://beta.gobuilds.org/github.com/mjl-/moxtools

Or compile it yourself (with a recent Go toolchain):

	go install github.com/mjl-/moxtools@latest

Now run:

	./moxtools
