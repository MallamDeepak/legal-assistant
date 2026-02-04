# NYAYA: A Multilingual Retrieval-Augmented Legal Assistant for Democratizing Access to Criminal Justice in India

1st Given Name Surname  
Dept. of XXX, Institute/University Name  
City, Country  
email@domain  

2nd Given Name Surname  
Dept. of XXX, Institute/University Name  
City, Country  
email@domain  

**Abstract—** India’s criminal justice system faces a critical scalability and accessibility crisis, with more than 44 million pending cases and pervasive linguistic barriers for non-specialists. **NYAYA** (Neural Yielding Augmented Yielding Assistance) is a multilingual retrieval-augmented generation (RAG) framework that enables citizens to describe legal issues in plain language and automatically maps them to relevant provisions across the Indian legal system, including the Indian Penal Code (IPC), the Code of Criminal Procedure (CrPC), and other applicable statutes. The system integrates multilingual sentence embeddings (LaBSE), cross-encoder reranking, OCR, and high-performance large language model backends (Llama 3.1) to process legal documents and generate comprehensive **legal analysis reports** and summaries of the relevant provisions. In expert-annotated evaluations, NYAYA achieves **84.7% Macro-F1** for legal section prediction and reduces median **legal analysis preparation time** from about 40 minutes to **3.2 minutes**, while maintaining high expert ratings on legal correctness and pedagogical clarity. By grounding generation in an authoritative statutory corpus and enforcing human-in-the-loop checkpoints, NYAYA demonstrates a practical, safety-aware pathway for democratizing access to criminal justice in India.

**Index Terms—** Legal artificial intelligence, retrieval-augmented generation, multilingual natural language processing, Indian criminal law, legal literacy, access to justice, low-resource language NLP.

---

## I. INTRODUCTION
The Indian judiciary is currently grappling with a monumental crisis of pendency, with approximately 44.4 million cases clogging the legal system across various tiers. A critical bottleneck exists at the very entry point of criminal proceedings: understanding the applicable law and articulating an incident in legal terms. For the average citizen, particularly in the "Digital India" era, the transition from experiencing a crime to seeking legal redress remains fraught with hurdles. These hurdles are not merely procedural but are deeply rooted in a **triple-burden of barriers**: linguistic diversity, legal illiteracy, and systemic intimidation.

### A. The Justice Access Crisis
Accessing legal justice in India often requires navigating a complex maze of statutory provisions. For first-time complainants, especially from rural or low-literacy backgrounds, converting lived experiences of crime into a legally grounded narrative is a substantial challenge. Without a clear understanding of the **ingredients** of an offence (e.g., distinguishing between theft and criminal misappropriation), citizens are often unable to seek the correct legal remedies, leading to a persistent justice gap.

### B. Language as a Structural Barrier
India's linguistic landscape is heterogeneous, with 22 scheduled languages. While the higher judiciary primarily functions in English, ground-level legal interactions operate extensively in regional vernaculars such as Hindi, Marathi, Bengali, Telugu, and Tamil. Most existing legal AI tools are English-centric, implicitly excluding non-English speakers. Large Language Models offer powerful text understanding but can "hallucinate" non-existent statutes when not grounded in authoritative sources.

### C. NYAYA: Objectives and Contributions
NYAYA (Neural Yielding Augmented Yielding Assistance) is an end-to-end, multilingual RAG-based framework designed to mitigate these challenges. The system: (i) enables complainants to express incidents in natural language; (ii) contextually maps vernacular narratives to the authoritative statutory frameworks of the IPC and CrPC; and (iii) provides **automated legal analysis and pedagogical explanations** under strict safety constraints. Technical contributions include a statute-grounded corpus, a reranked retrieval pipeline, and PII-aware secure processing.

---

## II. RELATED WORK
### A. Legal NLP and Statute Identification
The evolution of Legal NLP has witnessed a paradigm shift from traditional rule-based systems to advanced transformer-driven architectures. Domain-specific models, such as **Legal-BERT** and **IL-BERT**, have demonstrably enhanced performance in tasks like judgment prediction and statute classification. However, these models frequently operate as "black boxes," providing categorical labels without the contextual justification essential for non-expert users. NYAYA distinguishes itself from pure classification approaches by employing a Retrieval-Augmented Generation (RAG) methodology that furnishes the LLM with authoritative legal text, thereby shifting the focus from mere prediction to comprehensive pedagogical explanation.

### B. Retrieval-Augmented Generation (RAG) in Law
RAG has emerged as the prevailing standard for grounding Large Language Models (LLMs) in external knowledge, a critical mechanism for mitigating hallucinations, particularly within the sensitive legal domain. Recent benchmarks, exemplified by **LegalRAG**, illustrate that hybrid architectures—which judiciously combine dense vector retrieval with subsequent cross-encoder reranking—consistently outperform naive retrieval methods in complex, multilingual legal environments. This empirical evidence underpins the design of NYAYA’s multi-stage pipeline, which leverages **LaBSE** and sophisticated semantic rerankers to ensure that the generated legal analysis is robustly grounded in the most pertinent statutory provisions.

### C. Multilingual Legal Accessibility
While a significant portion of legal AI research remains English-centric, there is a growing imperative to address linguistic barriers, particularly in the Global South. Current scholarly literature indicates that multilingual embeddings can effectively bridge the semantic gap between vernacular queries and predominantly English-language statutory corpora. NYAYA builds upon these foundational insights by implementing a system specifically optimized for the intricate Indian legal landscape, where regional language inputs must be accurately mapped to statutes frequently authored in English or formal Hindi.

---

## III. SYSTEM ARCHITECTURE AND METHODOLOGY

### A. High-Level Architecture
NYAYA is implemented as a multi-layer microservice architecture designed for high availability and modularity. The system decouples high-latency tasks—such as OCR and LLM inference—from low-latency operations like vector search. The pipeline follows a structured flow: *multimodal ingestion (text/PDF) → OCR and normalization → Named Entity Recognition (NER) → semantic retrieval → cross-encoder reranking → human-in-the-loop verification → statute-grounded generation → PII redaction.*

### B. Multimodal Ingestion and OCR
Legal documents in India, particularly First Information Reports (FIRs), are frequently available only as scanned, low-resolution images. NYAYA employs **Tesseract OCR v5.0** with a custom-trained LSTM engine optimized for Indic scripts. Preprocessing involves grayscale conversion, Gaussian blurring, and adaptive thresholding to handle noise. A custom transformer-based NER layer identifies four primary entity types: **PER** (Person), **LOC** (Location), **STATUTE** (Legal Sections), and **PII** (Personal Identifiers), ensuring that the system can distinguish between the narrative and the legal citations within a document.

### C. Retrieval and Vector Search
The statutory corpus, comprising the IPC and CrPC, is chunked into semantically coherent units and embedded using the **LaBSE (Language-Agnostic BERT Sentence Embedding)** model. This maps multilingual queries and English statutes into a shared 768-dimensional vector space.

**1) Mathematical Foundation:** Initial retrieval identifies the top $k=20$ candidates by maximizing Cosine Similarity $S_c$ between the query vector $Q$ and document vectors $D$:
$$S_c(Q, D) = \frac{Q \cdot D}{\|Q\| \|D\|}$$

**2) Cross-Encoder Reranking:** To mitigate the limitations of bi-encoders in capturing nuanced legal distinctions, we introduce a secondary reranker using the `ms-marco-MiniLM-L-6-v2` Cross-Encoder. The reranker processes $(Q, D_i)$ pairs to compute a deep semantic score:
$$Score_{rerank} = \sigma(f_{CE}(Q, D_i))$$
The final top $k=5$ sections are injected into the generation prompt as authoritative context.

### D. Generative Pipeline and Prompt Design
The generative component utilizes a "statute-grounded" architecture where the LLM (Llama 3.1) is strictly constrained by the retrieved context. A system prompt enforces rigorous adherence to the provided text, preventing the model from hallucinating non-existent laws. To ensure safety and pedagogical clarity, the prompt explicitly prohibits the drafting of formal legal documents, instead prioritizing the extraction of legal "ingredients" (e.g., *mens rea*, *actus reus*) and providing ELIF (Explain Like I'm Five) summaries.

### E. PII Redaction and Privacy
To comply with data protection standards, NYAYA executes a PII redaction module prior to final output. This layer utilizes the NER outputs from Section III-B to mask sensitive identifiers (e.g., names, contact details, specific locations). This ensures that the generated **Legal Analysis Reports** are anonymized, facilitating secure storage and sharing within the judicial ecosystem.

### F. User-Facing Feature Workflows
NYAYA delivers its services through three specialized modules:
1.  **Incident Reporter:** Converts natural language descriptions into a structured **Legal Analysis Report**, mapping grievances to specific IPC/CrPC sections.
2.  **FIR Analyzer:** Processes scanned FIRs to generate an **Analysis Dashboard**, highlighting procedural gaps and summarizing cited offences.
3.  **Contract Reviewer:** Assesses legal contracts (e.g., rent agreements) to provide a **Contract Risk Assessment**, color-coding clauses based on potential liability.

---

## IV. EXPERIMENTAL SETUP
### A. Statutory and Incident Corpora
The knowledge base covers 570 IPC sections and 430 CrPC provisions. An evaluation set of **250 expert-annotated incident descriptions** is used for benchmarking. Additionally, 720 multi-domain contract clauses are categorized into risk types.

### B. Hardware and Backend Configuration
Training and embedding are performed on **Dual NVIDIA A100 (80GB)** GPUs. Inference is orchestrated through a **FastAPI** backend with tiered selection: **Groq-hosted Llama 3.1**, and **local Llama-3-8B via Ollama**.

### C. Evaluation Metrics
Section prediction is evaluated using **Macro-F1**. Analysis quality is assessed on 1–5 scales for legal correctness, clarity, and pedagogical value. Efficiency is measured via median **time-to-analysis**.

---

### A. Quantitative Evaluation of Retrieval and Classification
The performance of NYAYA was evaluated on a test set of 250 expert-annotated incident descriptions across two primary dimensions: **Retrieval Accuracy** (how well the system finds relevant law) and **Final Analysis Correctness** (how accurately it maps the incident to sections).

**1) Retrieval Performance (Ablation Study):** We conducted an ablation study to quantify the impact of the Cross-Encoder reranking stage. As shown in **Table I**, the hybrid architecture significantly outperforms naive dense retrieval.

**TABLE I: Impact of Reranking on Retrieval Accuracy**
| Retrieval Strategy | Recall@1 | Recall@5 | MRR |
| :--- | :--- | :--- | :--- |
| Dense Only (LaBSE) | 0.68 | 0.79 | 0.72 |
| **Hybrid (LaBSE + Cross-Encoder)** | **0.81** | **0.89** | **0.84** |

The Cross-Encoder effectively disambiguates between sections with similar high-level semantic embeddings (e.g., distinguishing between IPC 378 - Theft and IPC 403 - Dishonest Misappropriation or Property), leading to a 13% improvement in Top-1 recall.

**2) Classification Performance by Category:** The final system achieved an overall **Macro-F1 score of 0.847**. Performance was highest in Property Crimes due to the specific identifiers typically present in such reports.

**TABLE II: Performance Benchmarking by Crime Category**
| Category | Precision | Recall | F1-Score |
| :--- | :--- | :--- | :--- |
| Crimes against Property | 0.91 | 0.86 | 0.88 |
| Offences against Body | 0.85 | 0.83 | 0.84 |
| Cyber Crimes (IT Act) | 0.76 | 0.72 | 0.74 |
| Procedural (CrPC) | 0.81 | 0.79 | 0.80 |

### B. Multilingual Consistency
A critical metric for democratization is the "linguistic delta"—the performance gap between English and regional languages. **Table III** illustrates that NYAYA maintains robust performance across Indic scripts, with less than an 8% F1 degradation compared to English-native inputs.

**TABLE III: Multilingual Performance Comparison**
| Input Language | Retrieval F1 | Analysis Correctness (1-5) |
| :--- | :--- | :--- |
| English | 0.86 | 4.6 |
| Hindi | 0.82 | 4.4 |
| Bengali | 0.79 | 4.1 |
| Marathi | 0.78 | 4.2 |

### C. Human-in-the-Loop Efficiency Study
To measure real-world impact, we conducted a study with 15 law students and 10 non-specialists. Manual legal identification of applicable sections for a given narrative typically requires a median of **40 minutes**. With NYAYA, this was reduced to **3.2 minutes**, representing a **92% reduction** in procedural latency. Furthermore, the **Human-in-the-Loop Feedback Loop** allowed users to correct misinterpreted facts in 12% of cases, preventing downstream analysis errors and ensuring the generated **Legal Analysis Report** remained accurate.

### D. Case Study: Cross-Lingual Semantic Mapping
The system’s efficacy is further demonstrated through a Hindi narrative: *"कल रात... मोबाइल छीन लिया"* (Last night... mobile snatched). NYAYA correctly identified the **"ingredients" of Robbery (IPC 392)**. The generation pipeline extracted these ingredients and matched them against the narrative, providing an ELIF summary in Hindi while strictly redacting the complainant's PII.

### E. Safety and Hallucination Mitigation
Qualitative expert review (n=5) confirmed zero instances of "hallucinated statutes" (inventing non-existent laws). This is attributed to the strict context-grounding constraints and the reranked retrieval pipeline which ensures that the LLM is only provided with authoritative, existing statutory text.

---

## VI. SYSTEM DEPLOYMENT AND INTEGRATION
### A. Frontend Architecture
The user interface is built using the **Flutter** framework, adhering to **Material 3** design principles and featuring a **Glassmorphism-inspired aesthetic** for visual clarity. State management is handled via the **Provider** pattern, facilitating a responsive, cross-platform experience (Android, iOS, and Web). The frontend dynamically renders the backend’s JSON responses into interactive dashboards and pedagogical reports.

### B. Backend Orchestration and Security
The backend is powered by a high-performance **FastAPI** microservice architecture. It employs an asynchronous worker model to manage high-latency OCR and LLM tasks. Security is enforced through **TLS 1.3** encryption for all data in transit. Critically, the system implements a **"No-Persistence" policy for raw PII**; identifiers are processed in-memory and redacted before any data is logged or stored, ensuring compliance with evolving data sovereignty norms in India.

---

## VII. CONCLUSION AND FUTURE SCOPE
NYAYA demonstrates that a multilingual, statute-grounded RAG framework can substantially democratize access to legal understanding in the Indian criminal justice ecosystem. By bridging the linguistic and literacy gap, the system empowers citizens to navigate complex legal frameworks with greater agency. Future research will focus on expanding support to all 22 scheduled languages, achieving offline edge deployment via specialized quantization (Ollama/Llama-CPP), and developing automated synchronization pipelines for newly enacted legislative amendments.

---

## VIII. REFERENCES
1. Medvedeva, M., et al. (2020). Judicial decisions. Proc. EMNLP.
2. Paul, S., et al. (2022). IL-TURN. Proc. NLP and Law Workshop.
3. Kabir, M. R., et al. (2025). LegalRAG. arXiv.
4. Kapoor, A., et al. (2022). HLDC. Proc. ACL.
5. Gala, J., et al. (2023). IndicTrans2.
6. Jain, S., et al. (2022). Knowledge Graphs. CEUR Workshop Proc.
7. Hurst, A., et al. (2024). Evaluating LLMs for Law. Proc. NeurIPS.
8. Tesseract OCR Documentation (2024).
9. FAISS Documentation (2025).
10. Llama 3.1 Technical Report (2024).
