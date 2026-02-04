import io
from PIL import Image
import pytesseract
import os
from app.core.config import settings

def extract_text_from_image(image_bytes: bytes) -> str:
    try:
        # If a TESSERACT_PATH is provided via env/.env, point pytesseract to it.
        if getattr(settings, 'TESSERACT_PATH', None):
            tpath = settings.TESSERACT_PATH
            # On Windows, users may set the full path to tesseract.exe
            if tpath:
                pytesseract.pytesseract.tesseract_cmd = tpath

        img = Image.open(io.BytesIO(image_bytes))
        text = pytesseract.image_to_string(img)
        return text
    except Exception as e:
        print(f"OCR Error: {e}")
        return f'(ocr failed: {str(e)})'

def extract_text_from_pdf(pdf_bytes: bytes) -> str:
    try:
        import pypdf
        reader = pypdf.PdfReader(io.BytesIO(pdf_bytes))
        text = ""
        for page in reader.pages:
            content = page.extract_text()
            if content:
                text += content + "\n"
        
        text = text.strip()
        
        # Fallback: If no text was extracted (e.g. scanned PDF), try OCR on pages
        if not text or len(text) < 50:
            print("Digital PDF extraction returned very little text. Falling back to OCR...")
            try:
                from pdf2image import convert_from_bytes
                # Convert only the first 3 pages to avoid memory issues and long waits
                images = convert_from_bytes(pdf_bytes, first_page=1, last_page=3)
                ocr_text = ""
                for i, img in enumerate(images):
                    # Convert PIL image to bytes for our existing OCR method
                    img_byte_arr = io.BytesIO()
                    img.save(img_byte_arr, format='PNG')
                    page_text = extract_text_from_image(img_byte_arr.getvalue())
                    if page_text:
                        ocr_text += f"\n--- Page {i+1} ---\n" + page_text
                
                if ocr_text.strip():
                    return ocr_text.strip()
            except Exception as e:
                print(f"PDF OCR Fallback failed: {e}")
                # If OCR fallback fails, just return whatever little digital text we had
        
        return text
    except Exception as e:
        print(f"PDF Extraction Error: {e}")
        return f'(pdf extraction failed: {str(e)})'

def extract_text(content: bytes, filename: str = "") -> str:
    if filename.lower().endswith('.pdf'):
        return extract_text_from_pdf(content)
    # Default to OCR for everything else
    return extract_text_from_image(content)
