module httplib;

faultdef CREATE_FAILED, BIND_FAILED, NOT_FOUND;

fn Server? create()
{
	Server server = server_create();
	if (!server) return CREATE_FAILED~;
	return server;
}

extern fn void Server.destroy(self) @cname("server_destroy");

extern fn Server Server.get(self, ZString pattern, Handler handler) @cname("server_get");

extern fn Server Server.post(self, ZString pattern, Handler handler) @cname("server_post");

extern fn Server Server.put(self, ZString pattern, Handler handler) @cname("server_put");

extern fn Server Server.delete(self, ZString pattern, Handler handler) @cname("server_delete");

extern fn void Server.listen(self, ZString host, CInt port) @cname("server_listen");

fn ushort? Server.bind_any(self, ZString host)
{
	CInt port = server_bind_any(self, host);
	if (port < 0) return BIND_FAILED~;
	return (ushort)port;
}

extern fn void Server.listen_after_bind(self) @cname("server_listen_after_bind");

extern fn void Server.stop(self) @cname("server_stop");

fn bool Server.is_running(self) => server_is_running(self) != 0;

fn String? found(ZString value) @local
{
	if (!value) return NOT_FOUND~;
	return value.str_view();
}

fn String? Request.path_param(self, ZString key) => found(request_path_param(self, key));

fn String? Request.param(self, ZString key) => found(request_param(self, key));

extern fn usz Request.param_count(self) @cname("request_param_count");

struct Param
{
	String key;
	String value;
}

fn Param? Request.param_at(self, usz index)
{
	ZString key   = request_param_key_at(self, index);
	ZString value = request_param_value_at(self, index);
	if (!key || !value) return NOT_FOUND~;
	return { key.str_view(), value.str_view() };
}

fn String? Request.header(self, ZString key) => found(request_header(self, key));

fn String Request.body(self)
{
	NativeString body = request_body(self);
	return (String)body.ptr[:body.len];
}

fn String? Request.cookie(self, String name)
{
	String header  = self.header("Cookie")!;
	Splitter pairs = header.tokenize(";");
	while (try raw = pairs.next())
	{
		String pair = raw.trim(" ");
		sz? eq      = pair.index_of_char('=');
		if (catch eq) continue;
		if (pair[:eq] == name) return pair[eq + 1..];
	}
	return NOT_FOUND~;
}

enum SameSite : int (ZString attribute)
{
	STRICT { "Strict" },
	LAX    { "Lax" },
	NONE   { "None" },
}

struct Cookie
{
	ZString name;
	ZString value;
	ZString path;
	int max_age_s;
	bool http_only;
	bool secure;
	SameSite same_site;
}

fn Cookie cookie(ZString name, ZString value)
{
	return {
		.name = name,
		.value = value,
		.path = "/",
		.max_age_s = -1,
		.http_only = true,
		.secure = false,
		.same_site = LAX
	};
}

extern fn void Response.set_redirect(self, ZString url) @cname("response_set_redirect");

fn void Response.set_content(
	self,
	String s,
	ZString content_type
) => response_set_content(self, s.ptr, s.len, content_type);

extern fn void Response.set_header(self, ZString key, ZString value) @cname("response_set_header");

extern fn void Response.set_status(self, CInt status) @cname("response_set_status");

fn void Response.set_cookie(
	self,
	Cookie cookie
) => response_set_cookie(
	self,
	cookie.name,
	cookie.value,
	cookie.path,
	cookie.max_age_s,
	(CInt)cookie.http_only,
	(CInt)cookie.secure,
	cookie.same_site.attribute
);