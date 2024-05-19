import pytest

from packaging_demo.slow import slow_add


@pytest.mark.slow
def test__slow_add():
    assert slow_add(1, 2) == 3
