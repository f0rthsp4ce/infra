#!/usr/bin/env python3

import asyncio
import traceback
import os
import typing
import html
import sys
import json
import re


async def main() -> None:
    aggregator = Aggregator(await tg_sender(sys.argv[1]))
    reader = await connect_stdin()
    while True:
        line = await reader.readline()
        if not line:
            break
        sline = line.rstrip(b"\n").decode("utf-8", "ignore")
        aggregator.notify(sline)
    await aggregator.close()


Flusher = typing.Callable[[str], typing.Awaitable[None]]


async def tg_sender(chat: str) -> Flusher:
    token = os.environ["TG_TOKEN"]

    RE_TOPIC = re.compile(
        r"""
        https://t\.me/c/
        (?P<chat_id> \d+ )
        (?:
            /
            (?P<thread_id> \d+ )
        )?
        """,
        re.VERBOSE,
    )
    if (m := RE_TOPIC.match(chat)) is None:
        raise ValueError("Invalid chat URL")
    chat_id = -1000000000000 - int(m.group("chat_id"))
    if (topic_id := m.group("thread_id")) is not None:
        topic_id = int(topic_id)

    me = await call_tg(token, "getMe", {})
    print(f"Logged in as {me['username']}")

    chat_info = await call_tg(token, "getChat", {"chat_id": chat_id})
    print(f"Chat: {chat_info['title']}")

    async def send(text: str) -> None:
        try:
            await call_tg(
                token,
                "sendMessage",
                {
                    "chat_id": chat_id,
                    "message_thread_id": topic_id,
                    "text": "<pre>" + html.escape(text) + "</pre>",
                    "parse_mode": "HTML",
                },
            )
        except Exception:
            traceback.print_exc()

    return send


async def call_tg(token: str, method: str, data: dict) -> dict:
    proc = await asyncio.create_subprocess_exec(
        "curl",
        f"https://api.telegram.org/bot{token}/{method}",
        "-H",
        "Content-Type: application/json",
        "-d",
        json.dumps(data),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.DEVNULL,
        stdin=asyncio.subprocess.DEVNULL,
    )
    stdout, _ = await proc.communicate()
    try:
        resp = json.loads(stdout)
    except json.JSONDecodeError:
        raise ValueError("Invalid JSON response")
    if not isinstance(resp, dict) or not resp.get("ok") or "result" not in resp:
        raise ValueError(f"Telegram error: {resp.get('description')}")
    return resp["result"]


class Aggregator:
    MAX_MSG_LINES = 100
    MAX_MSG_CHARS = 4000
    MAX_QUEUE_LEN = 500
    WAIT_SECONDS = 1

    def __init__(self, flush: Flusher) -> None:
        self._flush = flush
        self._task: asyncio.Task[None] | None = None
        self._queue = asyncio.Queue[str | None]()
        self._skipped = 0

    async def run(self) -> None:
        start = asyncio.get_event_loop().time()
        lines = list[str]()
        lines_chars = 0

        while True:
            try:
                wait = start + self.WAIT_SECONDS - asyncio.get_event_loop().time()
                line = await asyncio.wait_for(self._queue.get(), timeout=wait)
            except asyncio.TimeoutError:
                await self._flush("\n".join(lines))
                self._skipped = 0
                self._task = None
                return

            if line is None:
                line = f"[[{self._skipped} lines suppressed]]"
                self._skipped = 0

            if (
                lines_chars + len(line) + 1 > self.MAX_MSG_CHARS
                or len(lines) > self.MAX_MSG_LINES
            ):
                await self._flush("\n".join(lines))
                lines.clear()
                lines_chars = 0

            if len(lines) == 0:
                start = asyncio.get_event_loop().time()

            lines.append(line)
            lines_chars += len(line) + 1

    def notify(self, line: str) -> None:
        if self._skipped:
            self._skipped += 1
        elif self._queue.qsize() >= self.MAX_QUEUE_LEN:
            self._skipped = 1
            self._queue.put_nowait(None)
        else:
            self._queue.put_nowait(line)
        if self._task is None:
            self._task = asyncio.create_task(self.run())

    async def close(self) -> None:
        if self._task is not None:
            await self._task


async def connect_stdin() -> asyncio.StreamReader:
    reader = asyncio.StreamReader()
    protocol = asyncio.StreamReaderProtocol(reader)
    await asyncio.get_event_loop().connect_read_pipe(lambda: protocol, sys.stdin)
    return reader


if __name__ == "__main__":
    asyncio.run(main())