import time


def slow_add(a: int, b: int) -> int:
    time.sleep(4)
    return a + b
