module httplib_test;

import httplib;

fn void response_status(Request request, Response response)
{
	response.set_status(201);
	response.set_content("{\"ok\":true}", "application/json");
}

fn void response_header(Request request, Response response)
{
	response.set_header("X-Custom", "value");
	response.set_content("", "text/plain");
}

fn void response_redirect(Request request, Response response) => response.set_redirect("/target");

fn void response_cookie_default(Request request, Response response)
{
	response.set_cookie(httplib::cookie("sid", "abc"));
}

fn void response_cookie_strict(Request request, Response response)
{
	Cookie cookie = httplib::cookie("sid", "abc");
	cookie.path = "/app";
	cookie.max_age_s = 3600;
	cookie.http_only = false;
	cookie.secure = true;
	cookie.same_site = STRICT;
	response.set_cookie(cookie);
}

fn void response_cookie_none(Request request, Response response)
{
	Cookie cookie = httplib::cookie("sid", "");
	cookie.max_age_s = 0;
	cookie.secure = true;
	cookie.same_site = NONE;
	response.set_cookie(cookie);
}

fn Fixture start_response()
{
	Server server = httplib::create()!!;
	server.get("/status", &response_status).get("/header", &response_header).get("/redirect", &response_redirect)
		.get("/cookie/default", &response_cookie_default)
		.get("/cookie/strict", &response_cookie_strict)
		.get("/cookie/none", &response_cookie_none);
	return start(server);
}

module httplib_test @test;

import httplib;

fn void status_and_content_type_are_sent()
{
	Fixture fixture = start_response();
	defer fixture.close();
	String response = fixture.get("/status");
	assert(response.starts_with("HTTP/1.1 201"));
	assert(response.contains("Content-Type: application/json\r\n"));
	test::eq(body_of(response), "{\"ok\":true}");
}

fn void custom_header_is_sent()
{
	Fixture fixture = start_response();
	defer fixture.close();
	assert(fixture.get("/header").contains("X-Custom: value\r\n"));
}

fn void redirect_sets_302_and_location()
{
	Fixture fixture = start_response();
	defer fixture.close();
	String response = fixture.get("/redirect");
	assert(response.starts_with("HTTP/1.1 302"));
	assert(response.contains("Location: /target\r\n"));
}

fn void default_cookie_is_lax_http_only()
{
	Fixture fixture = start_response();
	defer fixture.close();
	assert(fixture.get("/cookie/default")
		.contains("Set-Cookie: sid=abc; Path=/; Max-Age=-1; HttpOnly; SameSite=Lax\r\n"));
}

fn void strict_cookie_has_all_attributes()
{
	Fixture fixture = start_response();
	defer fixture.close();
	assert(fixture.get("/cookie/strict")
		.contains("Set-Cookie: sid=abc; Path=/app; Max-Age=3600; Secure; SameSite=Strict\r\n"));
}

fn void none_cookie_expires()
{
	Fixture fixture = start_response();
	defer fixture.close();
	assert(fixture.get("/cookie/none")
		.contains("Set-Cookie: sid=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=None\r\n"));
}