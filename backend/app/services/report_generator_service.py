def create_fir_pdf(data: dict) -> bytes:
    try:
        from reportlab.lib.pagesizes import A4
        from reportlab.pdfgen import canvas
        import io

        buf = io.BytesIO()
        c = canvas.Canvas(buf, pagesize=A4)
        c.drawString(72, 800, data.get('title', 'FIR'))
        c.drawString(72, 780, data.get('body', 'No content'))
        c.showPage()
        c.save()
        buf.seek(0)
        return buf.read()
    except Exception:
        return (data.get('title', '') + '\n' + data.get('body', '')).encode('utf-8')
