from app.services.vector_search_service import VectorSearchService
from app.services.ollama_service import OllamaService
from app.services.groq_service import GroqService
from app.services.gemini_service import GeminiService
from functools import lru_cache
import hashlib

def _generate_answer_internal(query: str, language: str, cache_key: str = None) -> str:
    """Generate an answer using local RAG (Retrieval Augmented Generation)."""
    retriever = VectorSearchService.get_instance()
    if not retriever:
        return "System is initializing or legal index is missing. Please check back later."
        
    # Retrieve top relevant passages (Increased top_k for better context)
    docs = retriever.search(query, top_k=5)
    
    if not docs:
        return "I could not find any specific legal sections related to your query in the database. However, I can help with general legal information about India."

    # Map language codes to identities and instructions
    lang_config = {
        'en': {'name': 'English', 'identity': 'Professional Indian Legal Assistant'},
        'hi': {'name': 'Hindi', 'identity': 'भारतीय कानूनी सहायक (Professional Indian Legal Assistant)'},
        'bn': {'name': 'Bengali', 'identity': 'ভারতীয় আইনি সহকারী (Professional Indian Legal Assistant)'},
        'te': {'name': 'Telugu', 'identity': 'భారతీయ న్యాయ సహాయకుడు (Professional Indian Legal Assistant)'},
        'mr': {'name': 'Marathi', 'identity': 'भारतीय कायदेशीर सहायक (Professional Indian Legal Assistant)'}
    }
    config = lang_config.get(language, lang_config['en'])
    target_lang = config['name']
    identity = config['identity']

    # Prepare Context (Denser context for speed)
    context = ""
    for i, doc in enumerate(docs, 1):
        # Limit each document to 1000 chars (reduced from 2000 for speed)
        full_text = doc.get('text', '')
        truncated_text = full_text[:1000] + "..." if len(full_text) > 1000 else full_text
        context += f"Source {i}: {truncated_text}\n\n"
            
    system_prompt = f"""You are a {identity}.
    
    Your goal is to provide accurate, educational, and helpful answers in {target_lang}.
    
    Instructions:
    1. **Language Precision**: YOU MUST PROVIDE THE ENTIRE RESPONSE IN {target_lang}. Use clear, professional, yet accessible language appropriate for {target_lang} speakers.
    2. **Comprehensiveness**: Use the provided 'Legal Context' to answer the User's Question. If the context contains multiple relevant sections (e.g., from IPC, CrPC, or IT Act), summarize them clearly.
    3. **Legal Terminology**: If a specific legal term in {target_lang} is common but might be confusing, briefly explain it.
    4. **Handling Knowledge Gaps**: If the context doesn't have the exact answer but is related, provide a general explanation of the law based on your internal knowledge while acknowledging it's a general overview.
    5. **IT Act**: Pay special attention to the Information Technology (IT) Act if the question involves digital crimes, fraud, or electronic records.
    6. **Formatting**: Use Markdown for clarity (bolding, bullet points).
    7. **Directness**: Be direct but polite. Do not use filler phrases.
    """
    
    user_prompt = f"""
    Context:
    {context}
    
    Question: {query}
    """

    # 1. Try Groq (Fastest & Reliable)
    if GroqService.is_available():
        groq_resp = GroqService.generate_text(user_prompt, system_prompt=system_prompt)
        if groq_resp:
             return groq_resp + "\n\n*(Answered by Legal Assistant)*"

    # 2. Try Gemini (Backup)
    if GeminiService.is_available():
        gemini_resp = GeminiService.generate_text(user_prompt, system_prompt=system_prompt)
        if gemini_resp:
             return gemini_resp + "\n\n*(Answered by Legal Assistant)*"

    # 2. Try Local LLM (Ollama)
    if OllamaService.is_available():
        full_prompt = f"{system_prompt}\n\n{user_prompt}"
        llm_response = OllamaService.generate_text(full_prompt)
        if llm_response:
             return llm_response + "\n\n*(Answered by Legal Assistant - Local)*"

    # 2. Fallback to Simple List
    answer = f"Based on the analysis of Indian Law for query '{query}', here are the relevant sections:\n\n"
    
    for i, doc in enumerate(docs, 1):
        title = doc.get("title", f"Section {doc.get('section_id', 'Unknown')}")
        text = doc.get("text", "")
        
        answer += f"{i}. **{title}**\n"
        answer += f"   > \"{text[:300]}...\"\n\n"
        
    answer += "*Disclaimer: This is an AI-generated summary for informational purposes. Consult a lawyer for legal advice.*"
    return answer

# simple in-memory cache for speed
_rag_cache = {}

def generate_answer(query: str, language: str = "en") -> str:
    """Wrapper with simple in-memory caching."""
    cache_key = hashlib.md5(f"{query}_{language}".encode()).hexdigest()
    if cache_key in _rag_cache:
        print(f"DEBUG: Returning cached response for: {query[:30]}...")
        return _rag_cache[cache_key]
    
    # Internal function to avoid recursion
    resp = _generate_answer_internal(query, language, cache_key)
    _rag_cache[cache_key] = resp
    return resp
