
# import matplotlib.image as mpimg
from PIL import Image
import tempfile
import unittest
import numpy
import os

SAMPLE_IMG = os.path.join(os.path.dirname(__file__), "sample.png")


class TestClib(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        import tesseract
        cls._tesseract = tesseract

    def test_config_variable(self):
        config_name = "tessedit_pageseg_mode"

        t = self._tesseract.Tesseract(lang="eng")

        t.set_variable(config_name, "2")
        with self.assertRaises(RuntimeError):
            t.set_variable("not_exist", "1")

        config_filename = tempfile.mktemp()
        t.dump_variable(config_filename)

        with open(config_filename, "r") as f:
            lines = tuple(
                filter((lambda l: config_name in l), f.readlines())
            )
        self.assertEqual(len(lines), 1)
        self.assertEqual(lines[0].split("\t")[1], "2")

    def test_read_image(self):
        t = self._tesseract.Tesseract(lang="eng")
        self.assertEqual(t.get_lang(), "eng")

        image = Image.open(SAMPLE_IMG)
        img = numpy.asarray(image)
        t.set_rgb_image(img)

        self.assertIn("Note", t.get_text())
        self.assertGreater(t.mean_text_confidences(), 50)

        all_word_conf = t.all_word_confidences()
        self.assertEqual(len(all_word_conf), 1)

    def test_recognize(self):
        t = self._tesseract.Tesseract(lang="eng")
        self.assertEqual(t.get_lang(), "eng")

        image = Image.open(SAMPLE_IMG)
        img = numpy.asarray(image)
        t.set_rgb_image(img)

        t.recognize()
        results = list(t.get_results(self._tesseract.ENUM_RIL_SYMBOL))
        self.assertEqual(len(results), 4)
