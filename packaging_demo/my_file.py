from my_folder import A  # noqa
from my_folder.my_nested_file import CONSTANT as constant2
from packaging.my_other_file import CONSTANT
import numpy as np

MY_ARRAY = np.array([1, 2, 3])
print(MY_ARRAY)
print(CONSTANT)
print(constant2)
