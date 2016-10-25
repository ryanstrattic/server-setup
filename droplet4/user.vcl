# Default backend definition. Set this to point to your content server.
backend default {
	.host = "127.0.0.1";
	.port = "8080";
}

sub vcl_recv {
	# Happens before we check if we have this in cache already.
	#
	# Typically you clean up the request here, removing cookies you don't need,
	# rewriting the request, etc.

	# Redirect http to https
	if ( (req.http.host ~ "^(?i)droplet6.hellyer.kiwi") && req.http.X-Forwarded-Proto !~ "(?i)https") {
			return (synth(750, ""));
	}

}

sub vcl_backend_response {
	# Happens after we have read the response headers from the backend.
	#
	# Here you clean the response headers, removing silly Set-Cookie headers
	# and other mistakes your backend does.

	set beresp.ttl = 10s;
	set beresp.grace = 1h;

}

sub vcl_deliver {
	# Happens when we have all the pieces we need, and are about to send the
	# response to the client.
	#
	# You can do accounting or modifying the final object here.
}

sub vcl_synth {

	# Redirect http to https
	if (resp.status == 750) {
			set resp.status = 301;
			set resp.http.Location = "https://droplet6.hellyer.kiwi" + req.url;
			return(deliver);
	}

}