import pytest

from packaging_demo.states_info import is_city_capitol_of_state


@pytest.mark.parametrize(
    argnames="city_name, state,is_capital",
    argvalues=[
        ("Montgomery", "Alabama", True),
        ("Juneau", "Alaska", True),
        ("Phoenix", "Arizona", True),
        ("Salt Lake City", "Alabama", False),
    ],
)
def test__is_city_capitol_of_state__true_for_correct_city_state_pair(
    city_name, state, is_capital
):
    assert is_city_capitol_of_state(city_name=city_name, state=state) == is_capital


def test__is_city_capitol_of_state__false_for_correct_city_state_pair():
    assert not is_city_capitol_of_state("Salt Lake City", "Alabama")
