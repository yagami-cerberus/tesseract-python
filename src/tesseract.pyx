
cdef extern from "version.h":
    const char* PACKAGE_VERSION

from libtesseract cimport (
    TessBaseAPI,
    ResultIterator,

    PageSegMode,
    PSM_OSD_ONLY, PSM_AUTO_OSD, PSM_AUTO_ONLY, PSM_AUTO, PSM_SINGLE_COLUMN,
    PSM_SINGLE_BLOCK_VERT_TEXT, PSM_SINGLE_BLOCK, PSM_SINGLE_LINE,
    PSM_SINGLE_WORD, PSM_CIRCLE_WORD, PSM_SINGLE_CHAR, PSM_SPARSE_TEXT,
    PSM_SPARSE_TEXT_OSD, PSM_RAW_LINE, PSM_COUNT,

    OcrEngineMode,
    OEM_TESSERACT_ONLY, OEM_CUBE_ONLY, OEM_TESSERACT_CUBE_COMBINED,
    OEM_DEFAULT,

    PageIteratorLevel,
    RIL_BLOCK,
    RIL_PARA,
    RIL_TEXTLINE,
    RIL_WORD,
    RIL_SYMBOL)

from libc.stdlib cimport free
from libc.stdio cimport FILE, fopen, fclose
from libcpp cimport bool
cimport numpy as np

ctypedef np.uint8_t DTYPE_UINT8

from collections import namedtuple


__version__ = PACKAGE_VERSION.decode("ascii")

ENUM_PSM_OSD_ONLY = PSM_OSD_ONLY
ENUM_PSM_AUTO_OSD = PSM_AUTO_OSD
ENUM_PSM_AUTO_ONLY = PSM_AUTO_ONLY
ENUM_PSM_AUTO = PSM_AUTO
ENUM_PSM_SINGLE_COLUMN = PSM_SINGLE_COLUMN
ENUM_PSM_SINGLE_BLOCK_VERT_TEXT = PSM_SINGLE_BLOCK_VERT_TEXT
ENUM_PSM_SINGLE_BLOCK = PSM_SINGLE_BLOCK
ENUM_PSM_SINGLE_LINE = PSM_SINGLE_LINE
ENUM_PSM_SINGLE_WORD = PSM_SINGLE_WORD
ENUM_PSM_CIRCLE_WORD = PSM_CIRCLE_WORD
ENUM_PSM_SINGLE_CHAR = PSM_SINGLE_CHAR
ENUM_PSM_SPARSE_TEXT = PSM_SPARSE_TEXT
ENUM_PSM_SPARSE_TEXT_OSD = PSM_SPARSE_TEXT_OSD
ENUM_PSM_RAW_LINE = PSM_RAW_LINE
ENUM_PSM_COUNT = PSM_COUNT

ENUM_OEM_TESSERACT_ONLY = OEM_TESSERACT_ONLY
ENUM_OEM_CUBE_ONLY = OEM_CUBE_ONLY
ENUM_OEM_TESSERACT_CUBE_COMBINED = OEM_TESSERACT_CUBE_COMBINED
ENUM_OEM_DEFAULT = OEM_DEFAULT

ENUM_RIL_BLOCK = RIL_BLOCK
ENUM_RIL_PARA = RIL_PARA
ENUM_RIL_TEXTLINE = RIL_TEXTLINE
ENUM_RIL_WORD = RIL_WORD
ENUM_RIL_SYMBOL = RIL_SYMBOL

TessResult = namedtuple("TessResult", "text confidence x1 y1 x2 y2")


cdef class Tesseract:
    cdef TessBaseAPI *api
    cdef bool has_image

    def __cinit__(self):
        self.api = new TessBaseAPI()

    def __init__(self, lang="eng", datapath=None):
        cdef int ret
        cdef char* dp

        if datapath != None:
            dp = datapath
        else:
            dp = NULL

        ret = self.api.Init(dp, lang.encode()[:], OEM_DEFAULT)
        if ret != 0:
            raise RuntimeError(ret)

    def __dealloc__(self):
        self.api.End()
        del self.api

    def get_lang(self):
        cdef const char* lang
        lang = self.api.GetInitLanguagesAsString()
        return (<bytes>lang).decode()

    cpdef set_grayscale_image(self, np.ndarray[DTYPE_UINT8, ndim=2] image):
        cdef int width, height, bytes_per_pixel, bytes_per_line
        shape = image.shape
        height = shape[0]
        width = shape[1]

        bytes_per_pixel = 1
        bytes_per_line = width * bytes_per_pixel

        self.api.SetImage(image.tobytes(), width, height, bytes_per_pixel, bytes_per_line)

    cpdef set_rgb_image(self, np.ndarray[DTYPE_UINT8, ndim=3] image):
        cdef int d, width, height, bytes_per_pixel, bytes_per_line
        width = len(image[0])
        height = len(image)
        d = image.shape[2]
        if d == 3:
            bytes_per_pixel = 3
        elif d == 4:
            bytes_per_pixel = 4
        else:
            raise ValueError("Image dimension error")
        bytes_per_line = width * bytes_per_pixel

        self.api.SetImage(image.tobytes(), width, height, bytes_per_pixel, bytes_per_line)

    def set_variable(self, name, value):
        cdef bool ret
        ret = self.api.SetVariable(name.encode()[:], value.encode()[:])
        if not ret:
            raise RuntimeError("Set variable %s failed" % name)

    def dump_variable(self, filename):
        cdef FILE *fp
        fp = fopen(filename.encode()[:], "w")
        self.api.PrintVariables(fp)
        fclose(fp)

    property page_seg_mode:
        def __get__(self):
            return self.api.GetPageSegMode()

        def __set__(self, PageSegMode val):
            self.api.SetPageSegMode(val)

    def get_text(self):
        cdef char* output
        output = self.api.GetUTF8Text()
        try:
            ret = output.decode("utf8", "ignore")
            return ret
        finally:
            free(output)

    def mean_text_confidences(self):
        return self.api.MeanTextConf()

    def all_word_confidences(self):
        cdef int *conf, *ptr
        conf = ptr = self.api.AllWordConfidences()
        try:
            ret = []
            while (ptr[0]) != -1:
                ret.append(ptr[0])
                ptr += 1
            return ret
        finally:
            free(conf)

    def set_rectangle(self, int left, int top, int width, int height):
        self.api.SetRectangle(left, top, width, height)

    def recognize(self):
        cdef int ret
        ret = self.api.Recognize(NULL)
        if ret != 0:
            raise RuntimeError("Recognize error")

    def get_results(self, PageIteratorLevel level=RIL_WORD):
        cpdef int x1, y1, x2, y2
        cpdef ResultIterator* ri
        cpdef char* word
        cpdef float conf
        cpdef bool ret

        ri = self.api.GetIterator()
        ret = ri != NULL

        while ret:
            word = ri.GetUTF8Text(level)

            try:
                conf = ri.Confidence(level)
                ri.BoundingBox(level, &x1, &y1, &x2, &y2)
                yield TessResult(word.decode("utf8", "ignore"), conf, x1, y1, x2, y2)
            finally:
                free(word)

            ret = ri.Next(level)

    def clear(self):
        self.api.Clear()
