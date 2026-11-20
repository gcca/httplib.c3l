module httplib_test;

import httplib;

fn void request_path_param(Request request, Response response)
{
	response.set_content(request.path_param("id") ?? "none", "text/plain");
}

fn void request_missing_path_param(Request request, Response response)
{
	response.set_content(request.path_param("other") ?? "none", "text/plain");
}

fn void request_query(Request request, Response response)
{
	if (request.param_count() != 2 || @ok(request.param_at(2)))
	{
		response.set_status(500);
		return;
	}
	Param first  = request.param_at(0)!!;
	Param second = request.param_at(1)!!;
	@pool_init(mem, 4096)
	{
		response.set_content(
			string::tformat(
				"%s=%s,%s=%s,%s,%s",
				first.key,
				first.value,
				second.key,
				second.value,
				request.param("b") ?? "?",
				request.param("z") ?? "none"
			),
			"text/plain"
		);
	};
}

fn void request_header(Request request, Response response)
{
	@pool_init(mem, 4096)
	{
		response.set_content(
			string::tformat("%s|%s", request.header("X-Token") ?? "none", request.header("X-Absent") ?? "none"),
			"text/plain"
		);
	};
}

fn void request_body(Request request, Response response)
{
	response.set_content(request.body(), "text/plain");
}

fn void request_cookie(Request request, Response response)
{
	@pool_init(mem, 4096)
	{
		response.set_content(
			string::tformat(
				"%s|%s|%s",
				request.cookie("session") ?? "none",
				request.cookie("theme") ?? "none",
				request.cookie("absent") ?? "none"
			),
			"text/plain"
		);
	};
}

fn Fixture start_request()
{
	Server server = httplib::create()!!;
	server.get("/users/:id", &request_path_param).get("/orgs/:id", &request_missing_path_param)
		.get("/query", &request_query)
		.get("/header", &request_header)
		.post("/body", &request_body)
		.get("/cookie", &request_cookie);
	return start(server);
}

module httplib_test @test;

import httplib;

fn void path_param_is_extracted()
{
	Fixture fixture = start_request();
	defer fixture.close();
	test::eq(body_of(fixture.get("/users/42")), "42");
}

fn void missing_path_param_is_not_found()
{
	Fixture fixture = start_request();
	defer fixture.close();
	test::eq(body_of(fixture.get("/orgs/7")), "none");
}

fn void query_params_are_listed_and_looked_up()
{
	Fixture fixture = start_request();
	defer fixture.close();
	test::eq(body_of(fixture.get("/query?a=1&b=two")), "a=1,b=two,two,none");
}

fn void header_lookup_is_case_insensitive()
{
	Fixture fixture = start_request();
	defer fixture.close();
	test::eq(body_of(fixture.get("/header", "x-token: abc\r\n")), "abc|none");
}

fn void body_is_echoed()
{
	Fixture fixture = start_request();
	defer fixture.close();
	test::eq(body_of(fixture.with_body("POST", "/body", "hello body")), "hello body");
}

fn void cookie_is_parsed_from_header()
{
	Fixture fixture = start_request();
	defer fixture.close();
	test::eq(body_of(fixture.get("/cookie", "Cookie: theme=dark;  session=s3cr3t ; x=1\r\n")), "s3cr3t|dark|none");
}

fn void cookie_without_header_is_not_found()
{
	Fixture fixture = start_request();
	defer fixture.close();
	test::eq(body_of(fixture.get("/cookie")), "none|none|none");
}