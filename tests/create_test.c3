module httplib_test @test;

import httplib;

fn void create_allocates_a_new_server()
{
	Server server = httplib::create()!!;
	assert(server != null);
	assert(!server.is_running());
	server.destroy();
}

fn void create_matches_raw_binding()
{
	Server server = httplib::server_create();
	assert(server != null);
	httplib::server_destroy(server);
}

fn void bind_any_returns_an_ephemeral_port()
{
	Server server = httplib::create()!!;
	ushort port   = server.bind_any("127.0.0.1")!!;
	assert(port > 0);
	server.destroy();
}

fn void bind_any_fails_on_invalid_host()
{
	Server server = httplib::create()!!;
	ushort? port  = server.bind_any("256.256.256.256");
	assert(@catch(port) == httplib::BIND_FAILED);
	server.destroy();
}