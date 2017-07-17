
cdef extern from "version.h":
    const char* PACKAGE_VERSION

from libtesseract cimport (
    TessBaseAPI,
    PageSegMode,
    PSM_OSD_ONLY, PSM_AUTO_OSD, PSM_AUTO_ONLY, PSM_AUTO, PSM_SINGLE_COLUMN,
    PSM_SINGLE_BLOCK_VERT_TEXT, PSM_SINGLE_BLOCK, PSM_SINGLE_LINE,
    PSM_SINGLE_WORD, PSM_CIRCLE_WORD, PSM_SINGLE_CHAR, PSM_SPARSE_TEXT,
    PSM_SPARSE_TEXT_OSD, PSM_RAW_LINE, PSM_COUNT,

    OEM_TESSERACT_ONLY, OEM_CUBE_ONLY, OEM_TESSERACT_CUBE_COMBINED,
    OEM_DEFAULT)
from libc.stdlib cimport free
from libc.stdio cimport FILE, fopen, fclose
from libcpp cimport bool
cimport numpy as np

ctypedef np.uint8_t DTYPE_UINT8

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

    def clear(self):
        self.api.Clear()
