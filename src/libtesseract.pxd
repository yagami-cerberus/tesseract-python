
from libc.stdio cimport FILE
from libcpp cimport bool


cdef extern from "tesseract/baseapi.h" namespace "tesseract":
    cdef enum PageSegMode:
        PSM_OSD_ONLY,
        PSM_AUTO_OSD,
        PSM_AUTO_ONLY,
        PSM_AUTO,
        PSM_SINGLE_COLUMN,
        PSM_SINGLE_BLOCK_VERT_TEXT,
        PSM_SINGLE_BLOCK,
        PSM_SINGLE_LINE,
        PSM_SINGLE_WORD,
        PSM_CIRCLE_WORD,
        PSM_SINGLE_CHAR,
        PSM_SPARSE_TEXT,
        PSM_SPARSE_TEXT_OSD,
        PSM_RAW_LINE,
        PSM_COUNT

    cdef enum OcrEngineMode:
        OEM_TESSERACT_ONLY,
        OEM_CUBE_ONLY,
        OEM_TESSERACT_CUBE_COMBINED,
        OEM_DEFAULT

    cdef enum PageIteratorLevel:
        RIL_BLOCK,     # Block of text/image/separator line.
        RIL_PARA,      # Paragraph within a block.
        RIL_TEXTLINE,  # Line within a paragraph.
        RIL_WORD,      # Word within a textline.
        RIL_SYMBOL     # Symbol/character within a word.

    cdef cppclass ETEXT_DESC:
        pass

    cdef cppclass ResultIterator:
        bool Next(PageIteratorLevel level)
        float Confidence(PageIteratorLevel level)
        bool BoundingBox(PageIteratorLevel level,
                         int* left, int* top, int* right, int* bottom)
        char* GetUTF8Text(PageIteratorLevel level)

    cdef cppclass TessBaseAPI:
        TessBaseAPI()
        int Init(const char* datapath, const char* language, OcrEngineMode)
        const char* GetInitLanguagesAsString()

        bool SetVariable(const char* name, const char* value)
        const char* GetStringVariable(const char *name) const
        void PrintVariables(FILE *fp)

        PageSegMode GetPageSegMode()
        void SetPageSegMode(PageSegMode mode);

        int MeanTextConf()
        int* AllWordConfidences();

        void SetImage(const unsigned char* imagedata, int width, int height,
                      int bytes_per_pixel, int bytes_per_line);
        void SetRectangle(int left, int top, int width, int height)
        int Recognize(ETEXT_DESC* monitor)
        ResultIterator* GetIterator()
        char* GetUTF8Text()

        void Clear()
        void End()
