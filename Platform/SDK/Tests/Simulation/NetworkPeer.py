"""Bounded local QEMU peer for the RustServices mixed-language consumer.

Bind only host loopback; QEMU user networking maps it to 10.0.2.2. No ROMs,
network access or persistent guest copy is involved. Run immediately before
the guest consumer; two TCP streams and two UDP messages finish the peer.
"""
import socketserver
import threading
import time

counts = [0, 0]
lock = threading.Lock()


class Tcp(socketserver.BaseRequestHandler):
    def handle(self):
        self.request.settimeout(15)
        total = 0
        while True:
            data = self.request.recv(4096)
            if not data:
                break
            total += len(data)
            for offset in range(0, len(data), 2):
                self.request.sendall(data[offset:offset + 2])
                time.sleep(0.005)
        with lock:
            counts[0] += 1
        print(f"TCP complete bytes={total}", flush=True)


class Udp(socketserver.BaseRequestHandler):
    def handle(self):
        data, connection = self.request
        connection.sendto(data, self.client_address)
        with lock:
            counts[1] += 1
        print(f"UDP echoed bytes={len(data)}", flush=True)


class TcpServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


with TcpServer(("127.0.0.1", 18555), Tcp) as tcp, socketserver.UDPServer(("127.0.0.1", 18556), Udp) as udp:
    threads = [threading.Thread(target=s.serve_forever, daemon=True) for s in (tcp, udp)]
    for thread in threads:
        thread.start()
    print("Local TCP/UDP peer ready", flush=True)
    end = time.monotonic() + 120
    while time.monotonic() < end:
        with lock:
            complete = counts[0] == counts[1] == 2
        if complete:
            break
        time.sleep(0.05)
    tcp.shutdown()
    udp.shutdown()
    if not complete:
        raise SystemExit(f"Incomplete local peers: {counts}")
