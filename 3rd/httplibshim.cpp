#include "httplibshim.hpp"

#include <iterator>
#include <new>
#include <string>

#include "httplib.h"

struct Server {
  httplib::Server server;
};

struct Request {
  const httplib::Request &request;
};

struct Response {
  httplib::Response &response;
};

namespace {

httplib::Server::Handler wrap(Handler handler) {
  return [handler](const httplib::Request &request,
                   httplib::Response &response) {
    Request shim_request{request};
    Response shim_response{response};
    handler(&shim_request, &shim_response);
  };
}

} // namespace

Server *server_create(void) { return new (std::nothrow) Server{}; }

void server_destroy(Server *server) { delete server; }

Server *server_get(Server *server, const char *pattern, Handler handler) {
  server->server.Get(pattern, wrap(handler));
  return server;
}

Server *server_post(Server *server, const char *pattern, Handler handler) {
  server->server.Post(pattern, wrap(handler));
  return server;
}

Server *server_put(Server *server, const char *pattern, Handler handler) {
  server->server.Put(pattern, wrap(handler));
  return server;
}

Server *server_delete(Server *server, const char *pattern, Handler handler) {
  server->server.Delete(pattern, wrap(handler));
  return server;
}

void server_listen(Server *server, const char *host, int port) {
  server->server.listen(host, port);
}

int server_bind_any(Server *server, const char *host) {
  return server->server.bind_to_any_port(host);
}

void server_listen_after_bind(Server *server) {
  server->server.listen_after_bind();
}

void server_stop(Server *server) { server->server.stop(); }

int server_is_running(Server *server) {
  return server->server.is_running() ? 1 : 0;
}

const char *request_path_param(const Request *request, const char *key) {
  auto it = request->request.path_params.find(key);
  if (it == request->request.path_params.end()) return nullptr;
  return it->second.c_str();
}

const char *request_param(const Request *request, const char *key) {
  auto it = request->request.params.find(key);
  if (it == request->request.params.end()) return nullptr;
  return it->second.c_str();
}

size_t request_param_count(const Request *request) {
  return request->request.params.size();
}

const char *request_param_key_at(const Request *request, size_t index) {
  if (index >= request->request.params.size()) return nullptr;
  auto it = request->request.params.begin();
  std::advance(it, index);
  return it->first.c_str();
}

const char *request_param_value_at(const Request *request, size_t index) {
  if (index >= request->request.params.size()) return nullptr;
  auto it = request->request.params.begin();
  std::advance(it, index);
  return it->second.c_str();
}

const char *request_header(const Request *request, const char *key) {
  auto it = request->request.headers.find(key);
  if (it == request->request.headers.end()) return nullptr;
  return it->second.c_str();
}

String request_body(const Request *request) {
  return String{request->request.body.data(), request->request.body.size()};
}

void response_set_redirect(Response *response, const char *url) {
  response->response.set_redirect(url);
}

void response_set_content(Response *response, const char *s, size_t n,
                          const char *content_type) {
  response->response.set_content(s, n, content_type);
}

void response_set_header(Response *response, const char *key,
                         const char *value) {
  response->response.set_header(key, value);
}

void response_set_status(Response *response, int status) {
  response->response.status = status;
}

void response_set_cookie(Response *response, const char *name,
                         const char *value, const char *path, int max_age_s,
                         int http_only, int secure, const char *same_site) {
  std::string cookie = std::string(name) + "=" + value;
  if (path && *path) cookie += "; Path=" + std::string(path);
  cookie += "; Max-Age=" + std::to_string(max_age_s);
  if (http_only) cookie += "; HttpOnly";
  if (secure) cookie += "; Secure";
  if (same_site && *same_site) cookie += "; SameSite=" + std::string(same_site);
  response->response.set_header("Set-Cookie", cookie);
}
