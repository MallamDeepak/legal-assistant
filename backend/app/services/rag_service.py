from app.services.vector_search_service import VectorSearchService
from app.services.ollama_service import OllamaService

def generate_answer(query: str) -> str:
    """Generate an answer using local RAG (Retrieval Augmented Generation)."""
    retriever = VectorSearchService.get_instance()
    if not retriever:
        return "System is initializing or legal index is missing. Please check back later."
        
    # Retrieve top relevant passages
    docs = retriever.search(query, top_k=3)
    
    if not docs:
        return "I could not find any specific legal sections related to your query in the database."

    # 1. Try LLM Generation
    if OllamaService.is_available():
        context = ""
        for i, doc in enumerate(docs, 1):
            context += f"Source {i} ({doc.get('title', 'Unknown')}): {doc.get('text', '')}\n\n"
            
        prompt = f"""You are a helpful Indian Legal Assistant. Answer the user's question based ONLY on the following legal context.
        
        Context:
        {context}
        
        Question: {query}
        
        Instructions:
        - Answer directly and concisely.
        - Cite the relevant sections (Source 1, Source 2, etc.) in your answer.
        - If the answer is not in the context, say "I cannot find the answer in the available legal documents."
        - Do not halluncinate laws.
        """
        
        llm_response = OllamaService.generate_text(prompt)
        if llm_response:
             return llm_response + "\n\n*(Answered by Local AI via Ollama)*"

    # 2. Fallback to Simple List
    answer = f"Based on the analysis of Indian Law for query '{query}', here are the relevant sections:\n\n"
    
    for i, doc in enumerate(docs, 1):
        title = doc.get("title", f"Section {doc.get('section_id', 'Unknown')}")
        text = doc.get("text", "")
        
        answer += f"{i}. **{title}**\n"
        answer += f"   > \"{text[:300]}...\"\n\n"
        
    answer += "*Disclaimer: This is an AI-generated summary for informational purposes. Consult a lawyer for legal advice.*"
    return answer
