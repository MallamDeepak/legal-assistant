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


from app.services.ollama_service import OllamaService
from app.services.groq_service import GroqService
from app.services.gemini_service import GeminiService

class ReportGeneratorService:
    def generate_fir(self, text: str, sections: list, language: str = "en") -> str:
        """Generate a structured FIR report text (LLM-enhanced)."""
        
        # 1. Prepare context from sections
        formatted_sections = ""
        if not sections:
            formatted_sections = "No specific IPC/CrPC sections identified automatically."
        else:
            for s in sections:
                sid = s.get('section_id', 'Unknown')
                title = s.get('title', '')
                full_text = s.get('text', '') # Full legal text
                # Truncate to avoid huge token usage
                truncated_text = full_text[:1500] + "..." if len(full_text) > 1500 else full_text
                # Include full info in context for LLM
                formatted_sections += f"- SECTION: {sid}\n  TITLE: {title}\n  CONTENT: {truncated_text}\n\n"

        # Map language codes to full names for the prompt
        lang_map = {
            'en': 'English',
            'hi': 'Hindi',
            'bn': 'Bengali',
            'te': 'Telugu',
            'mr': 'Marathi'
        }
        target_lang = lang_map.get(language, 'English')

        system_prompt = f"You are a helpful and educational Legal Assistant. You must respond in {target_lang}."
        
        user_prompt = f"""
        INCIDENT FACTS:
        "{text}"
        
        POTENTIAL LEGAL SECTIONS (Retrieved from Database):
        {formatted_sections}
        
        YOUR TASK:
        Explain which legal sections apply to this incident in simple, easy-to-understand language.
        YOU MUST WRITE THE ENTIRE EXPLANATION IN {target_lang}.
        
        1. **Select Relevant Sections**: 
           - Evaluated the provided 'POTENTIAL LEGAL SECTIONS'. 
           - **CRITICAL**: If the provided sections are NOT relevant to the crime described (e.g. Theft, Murder, Cheating), you MUST ignore them and identify the correct Indian Penal Code (IPC) sections from your own internal legal knowledge (e.g. IPC 379 for Theft, IPC 302 for Murder).
        
        2. **Explain Like I'm Five (ELIF)**: For each section, explain:
           - **Concept**: What does this law mean? (e.g., "Theft involves dishonestly moving property...")
           - **Application**: Why does it apply here? Match specific facts to the law's ingredients (e.g., "Moving the ring without consent...").
           - **Reference**: If an 'Illustration' or 'Explanation' in the provided text matches the incident, cite it.
        
        FORMATTING RULES:
        - Use clear bullet points.
        - **Do NOT** use complex legal jargon without explaining it.
        - **IMPORTANT**: If the incident involves **online fraud, OTP theft, or digital personation**, explicitely check for **IT Act Section 66C** (Identity Theft) and **Section 66D** (Cheating by Personation) even if not in the list.
        - **Do NOT** draft a formal FIR.
        - **Keep it CONCISE**: Max 2 sentences per section explanation.
        """

        # 2. Try Groq first (Fast)
        if GroqService.is_available():
            groq_resp = GroqService.generate_text(user_prompt, system_prompt=system_prompt)
            if groq_resp:
                return groq_resp + "\n\n*(Answered by Legal Assistant)*"

        # 3. Try Gemini (Backup)
        if GeminiService.is_available():
            gemini_resp = GeminiService.generate_text(user_prompt, system_prompt=system_prompt)
            if gemini_resp:
                return gemini_resp + "\n\n*(Answered by Legal Assistant)*"

        # 3. Try Local LLM (Ollama) as fallback
        if OllamaService.is_available():
            full_prompt = f"{system_prompt}\n\n{user_prompt}"
            llm_response = OllamaService.generate_text(full_prompt)
            if llm_response:
                return llm_response

        # 3. No Fallback allowed
        return "Error: Legal Analysis could not be generated. Please ensure the AI service is running."
