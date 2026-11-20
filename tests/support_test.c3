module httplib_test;

import httplib, std::thread, std::net::tcp, std::io;

struct Fixture
{
	Server server;
	ushort port;
	Thread thread;
}

fn int run(void* arg)
{
	((Server)arg).listen_after_bind();
	return 0;
}

fn Fixture start(Server server)
{
	Fixture fixture = { .server = server, .port = server.bind_any("127.0.0.1")!! };
	fixture.thread.create(&run, (void*)server)!!;
	while (!server.is_running()) thread::yield();
	return fixture;
}

fn void Fixture.close(&self)
{
	self.server.stop();
	(void)self.thread.join();
	self.server.destroy();
}

fn String Fixture.send(&self, String raw)
{
	TcpSocket socket = tcp::connect("127.0.0.1", self.port)!!;
	defer (void)socket.close();
	socket.write(raw)!!;
	return (String)io::read_fully(tmem, &socket)!!;
}

fn String Fixture.get(&self, String target, String headers = "")
{
	return self.send(
		string::tformat("GET %s HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n%s\r\n", target, headers)
	);
}

fn String Fixture.with_body(&self, String method, String target, String body)
{
	return self.send(
		string::tformat(
			"%s %s HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\nContent-Type: text/plain\r\nContent-Length: %d\r\n\r\n%s",
			method,
			target,
			body.len,
			body
		)
	);
}

fn String body_of(String response)
{
	sz start = response.index_of("\r\n\r\n")!!;
	return response[start + 4..];
}