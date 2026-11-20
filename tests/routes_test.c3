module httplib_test;

import httplib;

fn void route_get(Request request, Response response) => response.set_content("get", "text/plain");

fn void route_post(Request request, Response response) => response.set_content("post", "text/plain");

fn void route_put(Request request, Response response) => response.set_content("put", "text/plain");

fn void route_delete(Request request, Response response) => response.set_content("delete", "text/plain");

fn Fixture start_routes()
{
	Server server = httplib::create()!!;
	server.get("/item", &route_get).post("/item", &route_post).put("/item", &route_put).delete("/item", &route_delete);
	return start(server);
}

module httplib_test @test;

import httplib;

fn void get_dispatches_to_get_handler()
{
	Fixture fixture = start_routes();
	defer fixture.close();
	String response = fixture.get("/item");
	assert(response.starts_with("HTTP/1.1 200"));
	test::eq(body_of(response), "get");
}

fn void post_dispatches_to_post_handler()
{
	Fixture fixture = start_routes();
	defer fixture.close();
	test::eq(body_of(fixture.with_body("POST", "/item", "x")), "post");
}

fn void put_dispatches_to_put_handler()
{
	Fixture fixture = start_routes();
	defer fixture.close();
	test::eq(body_of(fixture.with_body("PUT", "/item", "x")), "put");
}

fn void delete_dispatches_to_delete_handler()
{
	Fixture fixture = start_routes();
	defer fixture.close();
	test::eq(body_of(fixture.with_body("DELETE", "/item", "")), "delete");
}

fn void unknown_path_returns_404()
{
	Fixture fixture = start_routes();
	defer fixture.close();
	assert(fixture.get("/missing").starts_with("HTTP/1.1 404"));
}

fn void stop_ends_listen_loop()
{
	Fixture fixture = start_routes();
	assert(fixture.server.is_running());
	fixture.server.stop();
	(void)fixture.thread.join();
	assert(!fixture.server.is_running());
	fixture.server.destroy();
}