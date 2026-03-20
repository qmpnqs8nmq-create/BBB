#!/usr/bin/env python3
import socket
import threading
import select

LISTEN_HOST = '0.0.0.0'
LISTEN_PORT = 8888
TARGET_HOST = '127.0.0.1'
TARGET_PORT = 18889
BUFFER = 65536


def pipe(client_sock, target_sock):
    sockets = [client_sock, target_sock]
    try:
        while True:
            readable, _, exceptional = select.select(sockets, [], sockets, 60)
            if exceptional:
                break
            if not readable:
                continue
            for src in readable:
                data = src.recv(BUFFER)
                if not data:
                    return
                dst = target_sock if src is client_sock else client_sock
                dst.sendall(data)
    except Exception:
        pass
    finally:
        for s in sockets:
            try:
                s.shutdown(socket.SHUT_RDWR)
            except Exception:
                pass
            try:
                s.close()
            except Exception:
                pass


def handle(client_sock, client_addr):
    target_sock = None
    try:
        target_sock = socket.create_connection((TARGET_HOST, TARGET_PORT), timeout=10)
        client_sock.settimeout(None)
        target_sock.settimeout(None)
        pipe(client_sock, target_sock)
    except Exception:
        try:
            client_sock.close()
        except Exception:
            pass
        if target_sock is not None:
            try:
                target_sock.close()
            except Exception:
                pass


def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
    except Exception:
        pass
    server.bind((LISTEN_HOST, LISTEN_PORT))
    server.listen(128)
    while True:
        client_sock, client_addr = server.accept()
        t = threading.Thread(target=handle, args=(client_sock, client_addr), daemon=True)
        t.start()


if __name__ == '__main__':
    main()
