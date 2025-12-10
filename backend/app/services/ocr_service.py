def extract_text_from_image(image_bytes: bytes) -> str:
    try:
        import io
        from PIL import Image
        import pytesseract
        import os
        from app.core.config import settings

        # If a TESSERACT_PATH is provided via env/.env, point pytesseract to it.
        if getattr(settings, 'TESSERACT_PATH', None):
            tpath = settings.TESSERACT_PATH
            # On Windows, users may set the full path to tesseract.exe
            if tpath:
                pytesseract.pytesseract.tesseract_cmd = tpath

        img = Image.open(io.BytesIO(image_bytes))
        text = pytesseract.image_to_string(img)
        return text
    except Exception:
        return '(ocr not available: install pillow and pytesseract)'
