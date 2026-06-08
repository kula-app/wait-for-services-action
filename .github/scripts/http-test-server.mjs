// Minimal HTTP test server for the test-http.yml workflow.
//
// Mirrors the subset of go-httpbin we rely on: `GET /status/<code>` responds
// with that exact status code (adding a Location header for 3xx so redirect
// assertions can be exercised without following the redirect). Any other path
// returns 200. The port can be overridden via the PORT env var (default 8080).
import { createServer } from 'node:http';

const port = parseInt(process.env.PORT || '8080', 10);

const server = createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${port}`);
  const match = /^\/status\/(\d{3})$/.exec(url.pathname);

  if (match) {
    const code = parseInt(match[1], 10);
    if (code >= 300 && code < 400) {
      res.setHeader('Location', '/');
    }
    res.statusCode = code;
    res.end(`status ${code}\n`);
    return;
  }

  res.statusCode = 200;
  res.end('ok\n');
});

server.listen(port, () => {
  console.log(`http-test-server listening on port ${port}`);
});
